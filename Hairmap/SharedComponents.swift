import SwiftUI
import UIKit
import ImageIO
import Combine

enum HMTheme {
    static let ink = Color(red: 0.06, green: 0.055, blue: 0.05)
    static let paper = Color(red: 0.98, green: 0.965, blue: 0.94)
    static let soft = Color(red: 0.945, green: 0.935, blue: 0.91)
    static let emerald = Color(red: 0.02, green: 0.48, blue: 0.31)
    static let amber = Color(red: 0.92, green: 0.67, blue: 0.23)
}

enum RemoteImageContentMode: Equatable {
    case fill
    case fit

    var resizeMode: String {
        switch self {
        case .fill: "cover"
        case .fit: "contain"
        }
    }
}

private enum RemoteImageLoadPhase {
    case idle
    case loading
    case success(UIImage)
    case failure
}

@MainActor
private final class RemoteImageLoader: ObservableObject {
    @Published var phase: RemoteImageLoadPhase = .idle
    private var activeKey = ""

    func load(urlString: String, size: CGSize, contentMode: RemoteImageContentMode) async {
        let width = max(size.width, 1)
        let height = max(size.height, 1)
        guard width > 1, height > 1 else { return }
        guard let originalURL = RemoteImageURLBuilder.originalURL(from: urlString) else {
            phase = .failure
            return
        }

        let scale = UIScreen.main.scale
        let pixelSize = CGSize(width: width * scale, height: height * scale)
        let displayURL = RemoteImageURLBuilder.displayURL(
            from: originalURL,
            pixelSize: pixelSize,
            contentMode: contentMode
        )
        let key = "\(displayURL.absoluteString)|\(Int(pixelSize.width))x\(Int(pixelSize.height))|\(contentMode.resizeMode)"
        guard activeKey != key || !phase.isSuccess else { return }
        activeKey = key

        if let cached = RemoteImagePipeline.shared.cachedImage(forKey: key) {
            phase = .success(cached)
            return
        }

        phase = .loading
        do {
            let image = try await RemoteImagePipeline.shared.image(
                primaryURL: displayURL,
                fallbackURL: displayURL == originalURL ? nil : originalURL,
                cacheKey: key,
                targetPixelSize: pixelSize
            )
            guard activeKey == key else { return }
            phase = .success(image)
        } catch {
            guard activeKey == key else { return }
            phase = .failure
        }
    }
}

private extension RemoteImageLoadPhase {
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

private enum RemoteImageURLBuilder {
    static func originalURL(from rawValue: String) -> URL? {
        let clean = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }
        if let url = URL(string: clean), url.scheme != nil {
            return url
        }
        guard let encoded = clean.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) else {
            return nil
        }
        return URL(string: encoded)
    }

    static func displayURL(from originalURL: URL, pixelSize: CGSize, contentMode: RemoteImageContentMode) -> URL {
        guard isSupabasePublicImageURL(originalURL),
              var components = URLComponents(url: originalURL, resolvingAgainstBaseURL: false)
        else {
            return originalURL
        }

        components.path = components.path.replacingOccurrences(
            of: "/storage/v1/object/public/",
            with: "/storage/v1/render/image/public/"
        )
        components.queryItems = [
            URLQueryItem(name: "width", value: "\(clampedPixel(pixelSize.width))"),
            URLQueryItem(name: "height", value: "\(clampedPixel(pixelSize.height))"),
            URLQueryItem(name: "quality", value: contentMode == .fit ? "78" : "68"),
            URLQueryItem(name: "resize", value: contentMode.resizeMode)
        ]
        return components.url ?? originalURL
    }

    private static func isSupabasePublicImageURL(_ url: URL) -> Bool {
        let path = url.path.lowercased()
        let imageExtensions = ["jpg", "jpeg", "png", "webp", "heic"]
        return url.host?.contains("supabase.co") == true
            && path.contains("/storage/v1/object/public/")
            && imageExtensions.contains(url.pathExtension.lowercased())
    }

    private static func clampedPixel(_ value: CGFloat) -> Int {
        min(max(Int(value.rounded(.up)), 120), 1400)
    }
}

private final class RemoteImagePipeline {
    static let shared = RemoteImagePipeline()

    private let imageCache = NSCache<NSString, UIImage>()
    private let session: URLSession

    private init() {
        imageCache.countLimit = 360
        imageCache.totalCostLimit = 90 * 1024 * 1024

        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: 48 * 1024 * 1024,
            diskCapacity: 320 * 1024 * 1024,
            diskPath: "hairmap-remote-images"
        )
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 18
        config.timeoutIntervalForResource = 35
        session = URLSession(configuration: config)
    }

    func cachedImage(forKey key: String) -> UIImage? {
        imageCache.object(forKey: key as NSString)
    }

    func image(primaryURL: URL, fallbackURL: URL?, cacheKey: String, targetPixelSize: CGSize) async throws -> UIImage {
        if let cached = cachedImage(forKey: cacheKey) {
            return cached
        }

        do {
            return try await fetchImage(url: primaryURL, cacheKey: cacheKey, targetPixelSize: targetPixelSize)
        } catch {
            guard let fallbackURL, fallbackURL != primaryURL else { throw error }
            return try await fetchImage(url: fallbackURL, cacheKey: cacheKey, targetPixelSize: targetPixelSize)
        }
    }

    private func fetchImage(url: URL, cacheKey: String, targetPixelSize: CGSize) async throws -> UIImage {
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        let (data, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            throw URLError(.badServerResponse)
        }

        let maxPixelSize = max(max(targetPixelSize.width, targetPixelSize.height), 240)
        let image = try await Task.detached(priority: .utility) {
            try Self.downsample(data: data, maxPixelSize: maxPixelSize)
        }.value
        imageCache.setObject(image, forKey: cacheKey as NSString, cost: image.memoryCost)
        return image
    }

    private static func downsample(data: Data, maxPixelSize: CGFloat) throws -> UIImage {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            if let image = UIImage(data: data) { return image }
            throw URLError(.cannotDecodeContentData)
        }

        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else {
            if let image = UIImage(data: data) { return image }
            throw URLError(.cannotDecodeContentData)
        }
        return UIImage(cgImage: cgImage)
    }
}

private extension UIImage {
    var memoryCost: Int {
        guard let cgImage else { return 1 }
        return max(cgImage.bytesPerRow * cgImage.height, 1)
    }
}

struct RemoteImage: View {
    let urlString: String
    var height: CGFloat? = nil
    var cornerRadius: CGFloat = 0
    var contentMode: RemoteImageContentMode = .fill
    @StateObject private var loader = RemoteImageLoader()

    var body: some View {
        GeometryReader { proxy in
            content
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .task(id: loadID(for: proxy.size)) {
                await loader.load(urlString: urlString, size: proxy.size, contentMode: contentMode)
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private var content: some View {
        switch loader.phase {
        case .idle, .loading:
            placeholder(isLoading: true)
        case .success(let image):
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: contentMode == .fit ? .fit : .fill)
        case .failure:
            placeholder(isLoading: false)
        }
    }

    private func placeholder(isLoading: Bool) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [HMTheme.soft, .white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                if isLoading {
                    ProgressView().tint(HMTheme.ink)
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
    }

    private func loadID(for size: CGSize) -> String {
        "\(urlString)|\(Int(size.width.rounded()))x\(Int(size.height.rounded()))|\(contentMode.resizeMode)"
    }
}

struct PremiumHeader: View {
    let title: String
    var subtitle: String?
    var trailing: AnyView?

    init(title: String, subtitle: String? = nil, trailing: AnyView? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.system(.largeTitle, design: .serif, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(HMTheme.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            trailing
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
    }
}

struct TagPill: View {
    let text: String
    var isSelected = false

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? HMTheme.ink : Color.white.opacity(0.82), in: Capsule())
            .foregroundStyle(isSelected ? .white : HMTheme.ink)
            .overlay(Capsule().stroke(.black.opacity(isSelected ? 0 : 0.08), lineWidth: 1))
    }
}

struct RatingView: View {
    let rating: Double
    var reviews: Int?

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundStyle(HMTheme.amber)
            Text(String(format: "%.1f", rating))
                .font(.caption.monospacedDigit().weight(.bold))
            if let reviews {
                Text("(\(reviews))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct StatusCapsule: View {
    let status: BookingStatus

    var body: some View {
        Text(status.title)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12), in: Capsule())
            .foregroundStyle(color)
    }

    private var color: Color {
        switch status {
        case .pending: HMTheme.amber
        case .accepted: HMTheme.emerald
        case .inProgress: .blue
        case .completed: .secondary
        case .cancelled: .red
        }
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.callout.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(HMTheme.ink, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct SectionBand<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
                .foregroundStyle(HMTheme.ink)
            content
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

struct HairmapTextField: View {
    let title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            TextField(title, text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.callout)
                .padding(14)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.08)))
        }
    }
}

extension View {
    func premiumBackground() -> some View {
        background(HMTheme.paper.ignoresSafeArea())
    }
}
