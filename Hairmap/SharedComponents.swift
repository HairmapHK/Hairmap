import SwiftUI

enum HMTheme {
    static let ink = Color(red: 0.06, green: 0.055, blue: 0.05)
    static let paper = Color(red: 0.98, green: 0.965, blue: 0.94)
    static let soft = Color(red: 0.945, green: 0.935, blue: 0.91)
    static let emerald = Color(red: 0.02, green: 0.48, blue: 0.31)
    static let amber = Color(red: 0.92, green: 0.67, blue: 0.23)
}

struct RemoteImage: View {
    let urlString: String
    var height: CGFloat? = nil
    var cornerRadius: CGFloat = 0

    var body: some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [HMTheme.soft, .white],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(ProgressView().tint(HMTheme.ink))
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                Rectangle()
                    .fill(HMTheme.soft)
                    .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
            @unknown default:
                Rectangle().fill(HMTheme.soft)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
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
