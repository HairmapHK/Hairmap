import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit
import AVKit

private enum HairmapUI {
    static let background = Color(red: 0.965, green: 0.972, blue: 0.982)
    static let ink = Color(red: 0.04, green: 0.055, blue: 0.09)
    static let muted = Color(red: 0.55, green: 0.58, blue: 0.64)
    static let line = Color.black.opacity(0.08)
    static let amber600 = Color(red: 0.82, green: 0.54, blue: 0.08)
    static let amberSoft = Color(red: 1.0, green: 0.94, blue: 0.64)

    static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }

    static var contentWidth: CGFloat {
        max(screenWidth - 40, 300)
    }

    static var twoColumnTileWidth: CGFloat {
        (contentWidth - 16) / 2
    }

    static let discoveryGridGap: CGFloat = 14

    static var discoveryCardWidth: CGFloat {
        (contentWidth - discoveryGridGap) / 2
    }

    static var portfolioGridTileWidth: CGFloat {
        (contentWidth - 16) / 3
    }

    static var portfolioGridTileHeight: CGFloat {
        portfolioGridTileWidth * 0.75
    }

    static var inspirationCardWidth: CGFloat {
        (contentWidth - 14) / 2
    }

    static var inspirationImageHeight: CGFloat {
        inspirationCardWidth * 0.75
    }

    static var lightboxImageWidth: CGFloat {
        min(screenWidth - 32, 390)
    }

    static var lightboxImageHeight: CGFloat {
        lightboxImageWidth * 0.75
    }

    static var detailHeroHeight: CGFloat {
        let height = UIScreen.main.bounds.height
        return min(max(height * 0.285, 232), 254)
    }

    static var salonHeroHeight: CGFloat {
        let height = UIScreen.main.bounds.height
        return min(max(height * 0.30, 244), 268)
    }

    static var profileWorkHeight: CGFloat {
        let height = UIScreen.main.bounds.height
        return min(max(height * 0.18, 150), 168)
    }

    static var salonWorkHeight: CGFloat {
        let height = UIScreen.main.bounds.height
        return min(max(height * 0.195, 160), 178)
    }
}

private enum DiscoveryFilterPanel: String {
    case district = "地區"
    case style = "髮型風格"
    case price = "價格範圍"
    case rating = "評分"
}

private enum DiscoveryContentPage: String, CaseIterable, Identifiable {
    case stylists = "髮型師"
    case salons = "沙龍"
    case rankings = "排行榜"

    var id: String { rawValue }
}

private struct DiscoveryDistrictRegion: Identifiable {
    let name: String
    let districts: [String]

    var id: String { name }
}

private struct PortfolioGalleryState: Identifiable {
    let id = UUID()
    let works: [PortfolioWork]
    let initialIndex: Int
}

private struct LookZoomState: Identifiable {
    let id = UUID()
    let slides: [LookMediaSlide]
    let initialIndex: Int
}

struct DiscoveryView: View {
    @Environment(HairmapStore.self) private var store
    @State private var searchText = ""
    @State private var selectedPage: DiscoveryContentPage = .stylists
    @State private var activePanel: DiscoveryFilterPanel?
    @State private var selectedDistrict: String?
    @State private var selectedDistrictRegion = "香港島"
    @State private var selectedStyle: String?
    @State private var selectedPriceRange: String?
    @State private var selectedRating: Double?

    private let districtRegions: [DiscoveryDistrictRegion] = [
        DiscoveryDistrictRegion(name: "香港島", districts: ["中環", "金鐘", "灣仔", "銅鑼灣", "天后", "北角", "鰂魚涌", "太古", "西灣河", "筲箕灣", "柴灣", "上環", "西營盤", "堅尼地城", "香港仔", "黃竹坑", "鴨脷洲", "赤柱"]),
        DiscoveryDistrictRegion(name: "九龍", districts: ["尖沙咀", "佐敦", "油麻地", "旺角", "太子", "深水埗", "長沙灣", "荔枝角", "九龍塘", "石硤尾", "何文田", "土瓜灣", "紅磡", "黃埔", "九龍城", "樂富", "黃大仙", "鑽石山", "彩虹", "九龍灣", "牛頭角", "觀塘", "藍田", "油塘"]),
        DiscoveryDistrictRegion(name: "新界", districts: ["荃灣", "葵芳", "青衣", "沙田", "大圍", "火炭", "馬鞍山", "大埔", "粉嶺", "上水", "元朗", "天水圍", "屯門", "將軍澳", "坑口", "寶琳", "西貢", "清水灣"]),
        DiscoveryDistrictRegion(name: "離島", districts: ["東涌", "愉景灣", "迪士尼", "長洲", "坪洲", "南丫島", "梅窩", "大澳"])
    ]
    private let styleKeywords = ["歐美染髮", "手刷染", "男士理髮", "漸層推剪", "韓式燙髮", "縮毛矯正", "女神大波浪", "線條感挑染"]
    private let priceRanges = ["HK$600以下", "HK$600 - HK$1200", "HK$1200以上"]
    private let ratingOptions: [(String, Double)] = [("4.9星以上", 4.9), ("4.8星以上", 4.8), ("4.7星以上", 4.7)]

    private var discoveryColumns: [GridItem] {
        [
            GridItem(.fixed(HairmapUI.discoveryCardWidth), spacing: HairmapUI.discoveryGridGap),
            GridItem(.fixed(HairmapUI.discoveryCardWidth), spacing: HairmapUI.discoveryGridGap)
        ]
    }

    private var selectedRegionDistricts: [String] {
        districtRegions.first { $0.name == selectedDistrictRegion }?.districts ?? districtRegions[0].districts
    }

    private var filteredStylists: [Stylist] {
        store.stylists.filter { stylist in
            let salon = salonFor(stylist)
            let text = [
                stylist.name,
                stylist.title,
                stylist.specialties.joined(separator: " "),
                salon?.name ?? "",
                salon?.location ?? ""
            ].joined(separator: " ")
            let searchMatches = searchText.isEmpty || text.localizedCaseInsensitiveContains(searchText)
            let districtMatches = selectedDistrict == nil || (salon?.location.localizedCaseInsensitiveContains(selectedDistrict ?? "") ?? false)
            let styleMatches = selectedStyle == nil
                || stylist.specialties.contains(selectedStyle ?? "")
                || (salon?.tags.contains(selectedStyle ?? "") ?? false)
            let ratingMatches = selectedRating == nil || stylist.rating >= (selectedRating ?? 0)
            let priceMatches = matchesPriceRange(stylist.basePrice)
            return searchMatches && districtMatches && styleMatches && ratingMatches && priceMatches
        }
    }

    private var filteredSalons: [Salon] {
        store.salons.filter { salon in
            let text = [salon.name, salon.location, salon.tags.joined(separator: " ")].joined(separator: " ")
            let searchMatches = searchText.isEmpty || text.localizedCaseInsensitiveContains(searchText)
            let districtMatches = selectedDistrict == nil || salon.location.localizedCaseInsensitiveContains(selectedDistrict ?? "")
            let styleMatches = selectedStyle == nil || salon.tags.contains(selectedStyle ?? "")
            let ratingMatches = selectedRating == nil || salon.rating >= (selectedRating ?? 0)
            let priceMatches = matchesPriceRange(salon.startPrice)
            return searchMatches && districtMatches && styleMatches && ratingMatches && priceMatches
        }
    }

    private var rankedStylists: [Stylist] {
        let overrides = rankingOverrides(for: "stylist_hot", itemType: "stylist")
        return filteredStylists.sorted { lhs, rhs in
            let left = overrides[lhs.id]
            let right = overrides[rhs.id]
            let leftRank = left?.manualRank ?? Int.max
            let rightRank = right?.manualRank ?? Int.max
            if leftRank != rightRank { return leftRank < rightRank }
            if (left?.isPinned ?? false) != (right?.isPinned ?? false) {
                return left?.isPinned == true
            }
            let leftScore = left?.scoreOverride ?? lhs.rating
            let rightScore = right?.scoreOverride ?? rhs.rating
            if leftScore != rightScore { return leftScore > rightScore }
            if lhs.reviewsCount != rhs.reviewsCount { return lhs.reviewsCount > rhs.reviewsCount }
            return lhs.name < rhs.name
        }
    }

    private var rankedSalons: [Salon] {
        let overrides = rankingOverrides(for: "salon_hot", itemType: "salon")
        return filteredSalons.sorted { lhs, rhs in
            let left = overrides[lhs.id]
            let right = overrides[rhs.id]
            let leftRank = left?.manualRank ?? Int.max
            let rightRank = right?.manualRank ?? Int.max
            if leftRank != rightRank { return leftRank < rightRank }
            if (left?.isPinned ?? false) != (right?.isPinned ?? false) {
                return left?.isPinned == true
            }
            let leftScore = left?.scoreOverride ?? lhs.rating
            let rightScore = right?.scoreOverride ?? rhs.rating
            if leftScore != rightScore { return leftScore > rightScore }
            if lhs.startPrice != rhs.startPrice { return lhs.startPrice > rhs.startPrice }
            return lhs.name < rhs.name
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                discoveryHeader
                searchAndFilters
                discoveryTabs
                discoveryContent
            }
            .padding(.bottom, 92)
        }
        .refreshable {
            await store.refreshCatalog()
        }
        .background(HairmapUI.background.ignoresSafeArea())
    }

    @ViewBuilder
    private var discoveryContent: some View {
        switch selectedPage {
        case .stylists:
            LazyVGrid(columns: discoveryColumns, alignment: .center, spacing: 16) {
                ForEach(filteredStylists) { stylist in
                    Button {
                        store.showStylist(stylist.id)
                    } label: {
                        DiscoveryStylistGridCard(stylist: stylist, salon: salonFor(stylist))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .frame(width: HairmapUI.screenWidth)

        case .salons:
            LazyVGrid(columns: discoveryColumns, alignment: .center, spacing: 16) {
                ForEach(filteredSalons) { salon in
                    Button {
                        store.showSalon(salon.id)
                    } label: {
                        DiscoverySalonGridCard(salon: salon)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .frame(width: HairmapUI.screenWidth)

        case .rankings:
            DiscoveryRankingsView(
                stylists: rankedStylists,
                salons: rankedSalons,
                onStylistTap: store.showStylist,
                onSalonTap: store.showSalon
            )
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .frame(width: HairmapUI.screenWidth)
        }
    }

    private var discoveryHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(.black)
                Text("H")
                    .font(.system(size: 14, weight: .black, design: .serif))
                    .foregroundStyle(.white)
            }
            .frame(width: 32, height: 32)

            Text("Hairmap")
                .font(.system(size: 31, weight: .black, design: .serif))
                .foregroundStyle(.black)

            Spacer()

            Button {
                Task { await store.refreshCatalog() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color.gray.opacity(0.45))
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(.white)
    }

    private var searchAndFilters: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜尋沙龍、設計專長、風格造型、地區...", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(Color.white, in: Capsule())
            .overlay(Capsule().stroke(.black, lineWidth: 1))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    FilterPill(
                        title: selectedDistrict ?? "地區",
                        isExpanded: activePanel == .district,
                        hasValue: selectedDistrict != nil
                    ) {
                        togglePanel(.district)
                    }
                    FilterPill(
                        title: selectedStyle ?? "髮型風格",
                        isExpanded: activePanel == .style,
                        hasValue: selectedStyle != nil
                    ) {
                        togglePanel(.style)
                    }
                    FilterPill(
                        title: selectedPriceRange ?? "價格範圍",
                        isExpanded: activePanel == .price,
                        hasValue: selectedPriceRange != nil
                    ) {
                        togglePanel(.price)
                    }
                    FilterPill(
                        title: selectedRatingLabel ?? "評分",
                        isExpanded: activePanel == .rating,
                        hasValue: selectedRating != nil
                    ) {
                        togglePanel(.rating)
                    }
                }
            }

            if let activePanel {
                filterPanel(activePanel)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(.white)
        .animation(.snappy(duration: 0.22), value: activePanel)
    }

    private var discoveryTabs: some View {
        HStack(spacing: 0) {
            ForEach(DiscoveryContentPage.allCases) { page in
                Button {
                    selectedPage = page
                } label: {
                    VStack(spacing: 9) {
                        Text(page.rawValue)
                            .font(.system(size: 14, weight: selectedPage == page ? .black : .bold))
                            .foregroundStyle(selectedPage == page ? .black : HairmapUI.muted)
                        Capsule()
                            .fill(selectedPage == page ? Color.yellow.opacity(0.9) : .clear)
                            .frame(width: 34, height: 3)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .background(.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(HairmapUI.line)
                .frame(height: 1)
        }
    }

    private var selectedRatingLabel: String? {
        guard let selectedRating else { return nil }
        return String(format: "%.1f星以上", selectedRating)
    }

    @ViewBuilder
    private func filterPanel(_ panel: DiscoveryFilterPanel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("篩選 \(panel.rawValue) 關鍵字", systemImage: "sparkles")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(HairmapUI.ink)
                Spacer()
                Button("重設此項") {
                    reset(panel)
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
            }

            switch panel {
            case .district:
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 9) {
                        ForEach(districtRegions) { region in
                            Button {
                                selectedDistrictRegion = region.name
                            } label: {
                                Text(region.name)
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundStyle(selectedDistrictRegion == region.name ? .white : HairmapUI.ink)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 30)
                                    .background(selectedDistrictRegion == region.name ? .black : Color.gray.opacity(0.08), in: Capsule())
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }

                    Divider()

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(selectedRegionDistricts, id: \.self) { district in
                            DiscoveryOptionButton(title: district, isSelected: selectedDistrict == district) {
                                selectedDistrict = selectedDistrict == district ? nil : district
                            }
                        }
                    }
                }
            case .style:
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 8)], spacing: 8) {
                    ForEach(styleKeywords, id: \.self) { keyword in
                        DiscoveryOptionButton(title: keyword, isSelected: selectedStyle == keyword) {
                            selectedStyle = selectedStyle == keyword ? nil : keyword
                        }
                    }
                }
            case .price:
                VStack(spacing: 8) {
                    ForEach(priceRanges, id: \.self) { range in
                        DiscoveryOptionButton(title: range, isSelected: selectedPriceRange == range, alignment: .leading) {
                            selectedPriceRange = selectedPriceRange == range ? nil : range
                        }
                    }
                }
            case .rating:
                VStack(spacing: 8) {
                    ForEach(ratingOptions, id: \.0) { option in
                        DiscoveryOptionButton(title: "★ \(option.0)", isSelected: selectedRating == option.1, alignment: .leading) {
                            selectedRating = selectedRating == option.1 ? nil : option.1
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.black, lineWidth: 1))
    }

    private func salonFor(_ stylist: Stylist) -> Salon? {
        store.salons.first { $0.id == stylist.salonID }
    }

    private func rankingOverrides(for key: String, itemType: String) -> [String: RankingOverride] {
        Dictionary(
            uniqueKeysWithValues: store.rankingOverrides
                .filter { $0.rankingKey == key && $0.itemType == itemType }
                .map { ($0.itemID, $0) }
        )
    }

    private func togglePanel(_ panel: DiscoveryFilterPanel) {
        activePanel = activePanel == panel ? nil : panel
    }

    private func reset(_ panel: DiscoveryFilterPanel) {
        switch panel {
        case .district:
            selectedDistrict = nil
        case .style:
            selectedStyle = nil
        case .price:
            selectedPriceRange = nil
        case .rating:
            selectedRating = nil
        }
    }

    private func matchesPriceRange(_ price: Int) -> Bool {
        switch selectedPriceRange {
        case "HK$600以下":
            price <= 600
        case "HK$600 - HK$1200":
            price >= 600 && price <= 1200
        case "HK$1200以上":
            price >= 1200
        default:
            true
        }
    }

    private func clearFilters() {
        searchText = ""
        activePanel = nil
        selectedDistrict = nil
        selectedDistrictRegion = "香港島"
        selectedStyle = nil
        selectedPriceRange = nil
        selectedRating = nil
    }
}

private struct FilterPill: View {
    let title: String
    let isExpanded: Bool
    let hasValue: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 9, weight: .black))
            }
            .font(.system(size: 12, weight: .black))
            .foregroundStyle(isExpanded ? .white : HairmapUI.ink)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(isExpanded ? .black : Color(red: 0.95, green: 0.95, blue: 0.95), in: Capsule())
            .overlay(Capsule().stroke(hasValue && !isExpanded ? HairmapUI.amber600.opacity(0.55) : .clear, lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct DiscoveryOptionButton: View {
    let title: String
    let isSelected: Bool
    var alignment: Alignment = .center
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(isSelected ? .white : HairmapUI.ink)
                .frame(maxWidth: .infinity, alignment: alignment)
                .frame(height: 32)
                .padding(.horizontal, alignment == .leading ? 14 : 0)
                .background(isSelected ? .black : Color.white, in: Capsule())
                .overlay(Capsule().stroke(HairmapUI.line, lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct DiscoveryStylistGridCard: View {
    let stylist: Stylist
    let salon: Salon?

    private var cardWidth: CGFloat { HairmapUI.discoveryCardWidth }
    private var imageHeight: CGFloat { min(max(cardWidth * 1.34, 228), 262) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RemoteImage(urlString: stylist.avatarURL, height: imageHeight, cornerRadius: 12)
                .frame(width: cardWidth, height: imageHeight)
                .overlay(alignment: .topTrailing) {
                    RatingBadge(value: stylist.rating)
                        .padding(8)
                }

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(stylist.name)
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.black)
                        .lineLimit(1)
                    Spacer(minLength: 6)
                    Text(shortLocation)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(red: 0.48, green: 0.35, blue: 0.16))
                        .lineLimit(1)
                }

                Text("\(stylist.title) · \(stylist.experience)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    ForEach(stylist.specialties.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(Color(red: 0.48, green: 0.32, blue: 0.08))
                            .lineLimit(1)
                    }
                }

                Divider()

                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.black.opacity(0.72))
                    Text("駐店精選")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("↗ \(max(92, stylist.reviewsCount * 2)) Likes")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
        }
        .frame(width: cardWidth, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .shadow(color: .black.opacity(0.055), radius: 12, y: 8)
    }

    private var shortLocation: String {
        guard let location = salon?.location else { return "香港" }
        return location
            .replacingOccurrences(of: "海港城", with: "")
            .replacingOccurrences(of: "國際金融中心", with: "")
            .replacingOccurrences(of: "時代廣場", with: "")
            .replacingOccurrences(of: "朗豪坊", with: "")
    }
}

private struct DiscoverySalonGridCard: View {
    let salon: Salon

    private var cardWidth: CGFloat { HairmapUI.discoveryCardWidth }
    private var imageHeight: CGFloat { min(max(cardWidth * 0.78, 136), 154) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RemoteImage(urlString: salon.imageURL, height: imageHeight, cornerRadius: 12)
                .frame(width: cardWidth, height: imageHeight)
                .overlay(alignment: .bottomLeading) {
                    RatingBadge(value: salon.rating)
                        .padding(8)
                }
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.black.opacity(0.58))
                        .frame(width: 30, height: 30)
                        .background(.white.opacity(0.78), in: Circle())
                        .padding(8)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(salon.name)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.black)
                    .lineLimit(1)

                Label("\(salon.location) · \(String(format: "%.1f", salon.distance))km", systemImage: "mappin.circle.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    ForEach(salon.tags.prefix(2), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color(red: 0.48, green: 0.32, blue: 0.08))
                            .lineLimit(1)
                    }
                }

                Divider()

                HStack {
                    Text("服務起價")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("HK$ \(salon.startPrice)")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(red: 0.48, green: 0.29, blue: 0.06))
                }
            }
            .padding(12)
        }
        .frame(width: cardWidth, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .shadow(color: .black.opacity(0.055), radius: 12, y: 8)
    }
}

private struct RatingBadge: View {
    let value: Double

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.yellow)
            Text(String(format: value == 5 ? "%.0f" : "%.1f", value))
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.black.opacity(0.72), in: Capsule())
    }
}

private struct DiscoveryRankingsView: View {
    let stylists: [Stylist]
    let salons: [Salon]
    let onStylistTap: (String) -> Void
    let onSalonTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            rankingSectionTitle("香港殿堂級「超人氣髮型師」熱度榜", systemImage: "crown.fill")

            VStack(spacing: 10) {
                ForEach(Array(stylists.prefix(5).enumerated()), id: \.element.id) { index, stylist in
                    Button {
                        onStylistTap(stylist.id)
                    } label: {
                        DiscoveryRankingRow(
                            rank: index + 1,
                            imageURL: stylist.avatarURL,
                            title: stylist.name,
                            subtitle: "\(stylist.title) · \(stylist.experience)",
                            detail: "\(stylist.reviewsCount) 條精緻點評",
                            rating: stylist.rating
                        )
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }

            rankingSectionTitle("香港奢華高口碑「頂配沙龍」榮譽榜", systemImage: "trophy.fill")

            VStack(spacing: 10) {
                ForEach(Array(salons.prefix(5).enumerated()), id: \.element.id) { index, salon in
                    Button {
                        onSalonTap(salon.id)
                    } label: {
                        DiscoveryRankingRow(
                            rank: index + 1,
                            imageURL: salon.imageURL,
                            title: salon.name,
                            subtitle: "\(salon.location) · \(String(format: "%.1f", salon.distance))km",
                            detail: "HK$ \(salon.startPrice) 起",
                            rating: salon.rating
                        )
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
    }

    private func rankingSectionTitle(_ title: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(HairmapUI.ink)
                .lineLimit(2)
            Rectangle()
                .fill(.black)
                .frame(height: 1)
        }
    }
}

private struct DiscoveryRankingRow: View {
    let rank: Int
    let imageURL: String
    let title: String
    let subtitle: String
    let detail: String
    let rating: Double

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                if rank <= 3 {
                    Image(systemName: rank == 1 ? "trophy.fill" : "medal.fill")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(rank == 1 ? Color.yellow.opacity(0.95) : Color(red: 0.36, green: 0.58, blue: 0.78))
                } else {
                    Text("#\(rank)")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 34)

            RemoteImage(urlString: imageURL, height: 52, cornerRadius: 12)
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.black)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 5) {
                RatingBadge(value: rating)
                Text(detail)
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(width: HairmapUI.contentWidth)
        .frame(minHeight: 76)
        .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(rank == 1 ? Color.yellow.opacity(0.36) : HairmapUI.line, lineWidth: 1))
    }

}

struct FeaturedStylistCard: View {
    let stylist: Stylist

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RemoteImage(urlString: stylist.avatarURL, height: 132, cornerRadius: 10)
                .frame(width: 132)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.yellow)
                        Text(String(format: "%.1f", stylist.rating))
                            .font(.system(size: 11, weight: .black))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.74), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(8)
                }

            Text(stylist.name)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.black)
                .lineLimit(1)

            Text(stylist.title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(stylist.specialties.first ?? "高級設計")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(HairmapUI.muted)
                .lineLimit(1)
        }
        .frame(width: 132, alignment: .leading)
    }
}

private struct DiscoverySection<Content: View>: View {
    let title: String
    let countText: String
    let showsSparkle: Bool
    let content: Content

    init(title: String, countText: String, showsSparkle: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.countText = countText
        self.showsSparkle = showsSparkle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 5) {
                    if showsSparkle {
                        Image(systemName: "sparkles")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(.yellow)
                    }
                    Text(title)
                        .font(.system(size: 19, weight: .black))
                        .foregroundStyle(HairmapUI.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
                Spacer()
                Text(countText)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.secondary)
            }
            content
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 16)
        .background(HairmapUI.background)
    }
}

struct SalonRow: View {
    let salon: Salon

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(urlString: salon.imageURL, height: 156, cornerRadius: 16)
            LinearGradient(colors: [.clear, .black.opacity(0.68)], startPoint: .center, endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    ForEach(salon.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(HairmapUI.amber600, in: Capsule())
                            .foregroundStyle(.black)
                    }
                }
                Text(salon.name)
                    .font(.system(size: 24, weight: .black, design: .serif))
                    .foregroundStyle(.white)
                Text("\(salon.location) · 約 \(String(format: "%.1f", salon.distance)) 公里")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.86))
            }
            .padding(16)
        }
    }
}

struct InspirationView: View {
    @Environment(HairmapStore.self) private var store
    @State private var activeCategory = "熱門搜尋"
    @State private var showingShareSheet = false
    @State private var selectedLook: SharedHairLook?

    private var columns: [GridItem] {
        [
            GridItem(.fixed(HairmapUI.inspirationCardWidth), spacing: 14),
            GridItem(.fixed(HairmapUI.inspirationCardWidth), spacing: 14)
        ]
    }

    private var categories: [String] {
        ["熱門搜尋", "最新髮型"]
    }

    private var looks: [SharedHairLook] {
        let catalogLooks = store.inspiration.map { item in
            let mediaURLs = item.mediaURLs.isEmpty ? [item.imageURL] : item.mediaURLs
            let mediaItems = mediaURLs.enumerated().map { index, url in
                let rawKind = item.mediaKinds.indices.contains(index) ? item.mediaKinds[index] : "photo"
                let mediaKind = SharedLookMediaKind(rawValue: rawKind) ?? .photo
                return SharedLookMedia(imageURL: url, mediaData: nil, mediaKind: mediaKind)
            }

            return SharedHairLook(
                id: item.id,
                title: item.title,
                authorID: item.authorID,
                author: item.authorName.isEmpty ? item.salonName : item.authorName,
                authorAvatarURL: resolvedAuthorAvatar(for: item),
                studio: item.studio.isEmpty ? item.salonName : item.studio,
                location: item.location,
                tags: item.tags.map { $0.hasPrefix("#") ? $0 : "#\($0)" },
                imageURL: mediaURLs.first ?? item.imageURL,
                mediaData: nil,
                mediaKind: mediaItems.first?.mediaKind ?? .photo,
                mediaItems: mediaItems,
                stylistID: item.stylistID,
                faceShape: item.faceShape.isEmpty ? "適合多數臉型" : item.faceShape,
                hairType: item.hairType.isEmpty ? "依髮質由設計師調整" : item.hairType,
                specs: item.specs.isEmpty ? "建議預約前先收藏靈感照，方便與設計師討論。" : item.specs,
                details: item.details.isEmpty ? "由 Hairmap 精選設計師作品轉化為靈感參考。" : item.details,
                likes: item.likeCount,
                commentCount: item.commentCount,
                shareCount: item.shareCount,
                category: item.category,
                isUserPost: item.isUserPost
            )
        }
        let allLooks = store.sharedLooks + catalogLooks
        switch activeCategory {
        case "最新髮型":
            return allLooks.filter { $0.category == "最新髮型" || $0.isUserPost }
        default:
            return allLooks
        }
    }

    private func resolvedAuthorAvatar(for item: InspirationItem) -> String {
        let storedAvatar = item.authorAvatar.trimmingCharacters(in: .whitespacesAndNewlines)
        if !storedAvatar.isEmpty {
            return storedAvatar
        }
        if item.authorID == store.currentProfile?.id {
            return store.commentAvatarURL
        }
        if let stylist = store.stylists.first(where: { $0.id == item.stylistID }) {
            return stylist.avatarURL
        }
        return ""
    }

    var body: some View {
        VStack(spacing: 0) {
            InspirationTopBar()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 22) {
                    InspirationUploadBanner {
                        showingShareSheet = true
                    }

                    HStack(alignment: .bottom) {
                        InspirationTabs(categories: categories, activeCategory: $activeCategory)
                        Spacer()
                        Button {
                            showingShareSheet = true
                        } label: {
                            Label("上傳", systemImage: "plus")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .frame(height: 34)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.08, blue: 0.35), Color(red: 1.0, green: 0.55, blue: 0.02)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                    .frame(width: HairmapUI.contentWidth)

                    LazyVGrid(columns: columns, alignment: .center, spacing: 16) {
                        ForEach(looks) { look in
                            SharedLookCard(
                                look: look,
                                isLiked: store.likedLookIDs.contains(look.id),
                                onOpen: {
                                    selectedLook = look
                                },
                                onToggleLike: {
                                    store.toggleInspirationLike(look)
                                }
                            )
                            .frame(width: HairmapUI.inspirationCardWidth)
                        }
                    }
                    .frame(width: HairmapUI.contentWidth)
                    .padding(.bottom, 104)
                }
                .padding(.top, 18)
                .frame(width: HairmapUI.screenWidth)
            }
        }
        .background(Color(red: 0.965, green: 0.968, blue: 0.972).ignoresSafeArea())
        .sheet(isPresented: $showingShareSheet) {
            HairShareSheet { look in
                store.shareHairLook(look)
            }
        }
        .sheet(item: $selectedLook) { look in
            HairLookDetailSheet(
                look: look,
                isLiked: store.likedLookIDs.contains(look.id),
                onToggleLike: {
                    store.toggleInspirationLike(look)
                },
                onShare: {
                    store.recordInspirationShare(look)
                }
            )
        }
    }
}

private struct InspirationTopBar: View {
    var body: some View {
        HStack {
            Button {} label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color(red: 0.43, green: 0.46, blue: 0.52))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(PressableButtonStyle())

            Spacer()

            HStack(spacing: 7) {
                Circle()
                    .fill(Color(red: 1.0, green: 0.86, blue: 0.9))
                    .frame(width: 13, height: 13)
                Text("髮型風格設計誌")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(HairmapUI.ink)
            }

            Spacer()

            Button {} label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(red: 0.43, green: 0.46, blue: 0.52))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal, 20)
        .frame(height: 64)
        .background(.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(HairmapUI.line)
                .frame(height: 1)
        }
    }
}

private struct InspirationUploadBanner: View {
    let onUpload: () -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.05, blue: 0.36), Color(red: 1.0, green: 0.55, blue: 0.02)],
                startPoint: .leading,
                endPoint: .trailing
            )

            VStack(alignment: .leading, spacing: 12) {
                Text("MULTI-MEDIA SHOWCASE")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.2), in: Capsule())

                VStack(alignment: .leading, spacing: 6) {
                    Text("秀出多圖與現場美髮短影音！")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.white)
                    Text("不限單一照片，自由上傳多張設計相片與短影片，完整模擬極致高雅的橫向滑動、撰寫評論與心儀髮譜的超凡沉浸設計！")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.86))
                        .lineSpacing(3)
                        .lineLimit(3)
                }

                Button(action: onUpload) {
                    Label("立即建立我的多媒體卡片", systemImage: "plus")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .frame(height: 34)
                        .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(20)
        }
        .frame(width: HairmapUI.contentWidth, height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color(red: 1.0, green: 0.25, blue: 0.28).opacity(0.22), radius: 18, y: 8)
    }
}

private struct InspirationTabs: View {
    let categories: [String]
    @Binding var activeCategory: String

    var body: some View {
        HStack(spacing: 22) {
            ForEach(categories, id: \.self) { category in
                Button {
                    activeCategory = category
                } label: {
                    VStack(spacing: 8) {
                        Text(category)
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(activeCategory == category ? HairmapUI.ink : Color(red: 0.58, green: 0.6, blue: 0.66))
                        Rectangle()
                            .fill(activeCategory == category ? .black : .clear)
                            .frame(height: 2)
                    }
                    .fixedSize()
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }
}

private struct SharedLookCard: View {
    let look: SharedHairLook
    let isLiked: Bool
    let onOpen: () -> Void
    let onToggleLike: () -> Void

    private var imageHeight: CGFloat {
        HairmapUI.inspirationImageHeight
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onOpen) {
                cardContent
            }
            .buttonStyle(PressableButtonStyle())

            Button(action: onToggleLike) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isLiked ? .red : HairmapUI.ink)
                    .frame(width: 32, height: 32)
                    .background(.white.opacity(0.88), in: Circle())
                    .overlay(Circle().stroke(.black.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(PressableButtonStyle())
            .padding(8)
        }
        .frame(width: HairmapUI.inspirationCardWidth)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                SharedLookImage(look: look, height: imageHeight)
                    .overlay(alignment: .topLeading) {
                        Text(look.mediaKind == .video ? "VIDEO 影片" : "1/4")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 5)
                            .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                            .padding(8)
                    }

                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.white)
                    Text("\(look.likes + (isLiked ? 1 : 0))")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 8)
                .frame(height: 22)
                .background(.black.opacity(0.42), in: Capsule())
                .padding(10)
            }
            .frame(width: HairmapUI.inspirationCardWidth, height: imageHeight)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                Text(look.title)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(HairmapUI.ink)
                    .lineLimit(2)

                Label(look.studio, systemImage: "mappin")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(red: 0.52, green: 0.55, blue: 0.61))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    RemoteImage(urlString: look.authorAvatarURL, height: 18, cornerRadius: 9)
                        .frame(width: 18, height: 18)
                    Text(look.author)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isLiked ? Color(red: 1.0, green: 0.08, blue: 0.35) : .secondary)
                }
            }
            .padding(12)
            .frame(width: HairmapUI.inspirationCardWidth, alignment: .leading)
        }
        .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(HairmapUI.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

}

private struct SharedLookImage: View {
    let look: SharedHairLook
    let height: CGFloat

    var body: some View {
        ZStack {
            if look.mediaKind == .photo, let data = look.mediaData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if look.mediaKind == .video, let imageURL = look.imageURL {
                RemoteVideoPlayer(urlString: imageURL, width: HairmapUI.inspirationCardWidth, height: height)
                    .allowsHitTesting(false)
            } else if look.mediaKind == .video, look.mediaData != nil {
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.08, blue: 0.09), Color(red: 0.24, green: 0.24, blue: 0.26)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
            } else if let imageURL = look.imageURL {
                RemoteImage(urlString: imageURL, height: height)
            } else {
                Color(red: 0.93, green: 0.94, blue: 0.96)
                Image(systemName: "photo")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: HairmapUI.inspirationCardWidth, height: height)
        .clipped()
    }
}

private struct LookMediaSlide: Identifiable, Hashable {
    var id: String
    var title: String
    var imageURL: String?
    var mediaData: Data?
    var mediaKind: SharedLookMediaKind
}

private func mediaSlides(for look: SharedHairLook) -> [LookMediaSlide] {
    var slides: [LookMediaSlide]
    if look.mediaItems.isEmpty {
        slides = [
            LookMediaSlide(
                id: "\(look.id)-primary",
                title: look.title,
                imageURL: look.imageURL,
                mediaData: look.mediaData,
                mediaKind: look.mediaKind
            )
        ]
    } else {
        slides = look.mediaItems.enumerated().map { index, item in
            LookMediaSlide(
                id: item.id,
                title: "\(look.title) \(index + 1)",
                imageURL: item.imageURL,
                mediaData: item.mediaData,
                mediaKind: item.mediaKind
            )
        }
    }

    let related = [
        ("現場設計側拍", "https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=1200&q=80"),
        ("完成後髮色細節", "https://images.unsplash.com/photo-1522338242992-e1a54906a8da?auto=format&fit=crop&w=1200&q=80"),
        ("整理後自然光澤", "https://images.unsplash.com/photo-1519699047748-de8e457a634e?auto=format&fit=crop&w=1200&q=80")
    ]

    if look.mediaItems.isEmpty {
        for (index, item) in related.enumerated() {
            guard item.1 != (look.imageURL ?? "") else { continue }
            slides.append(
                LookMediaSlide(
                    id: "\(look.id)-related-\(index)",
                    title: item.0,
                    imageURL: item.1,
                    mediaData: nil,
                    mediaKind: .photo
                )
            )
        }
    }

    return slides
}

private struct HairLookDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(HairmapStore.self) private var store
    let look: SharedHairLook
    let isLiked: Bool
    let onToggleLike: () -> Void
    let onShare: () -> Void
    @State private var selectedMediaIndex = 0
    @State private var commentText = ""
    @State private var replyingTo: LookCommentItem?
    @State private var isSaved = false
    @State private var showingNicknamePrompt = false
    @State private var zoomState: LookZoomState?
    @State private var reportDraft: ReportDraft?
    @FocusState private var isCommentFieldFocused: Bool

    private var detailMediaWidth: CGFloat {
        HairmapUI.contentWidth
    }

    private var detailMediaHeight: CGFloat {
        detailMediaWidth * 0.75
    }

    private var heroHeight: CGFloat {
        detailMediaHeight
    }

    private var slides: [LookMediaSlide] {
        mediaSlides(for: look)
    }

    private var comments: [LookCommentItem] {
        store.comments(for: look.id)
    }

    private var commentTotal: Int {
        store.totalCommentCount(for: look.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            detailAuthorBar

            Divider()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    detailMediaStage

                    VStack(alignment: .leading, spacing: 20) {
                        detailTitleBlock
                        tagsSection
                        commentsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 106)
                    .frame(width: HairmapUI.screenWidth, alignment: .leading)
                }
                .frame(width: HairmapUI.screenWidth, alignment: .leading)
            }
        }
        .safeAreaInset(edge: .bottom) {
            commentComposerBar
        }
        .background(.white)
        .presentationDetents([.large])
        .presentationCornerRadius(26)
        .preferredColorScheme(.light)
        .onAppear {
            if store.needsCommentNickname {
                showingNicknamePrompt = true
            }
        }
        .sheet(isPresented: $showingNicknamePrompt) {
            NicknamePromptSheet(currentName: store.commentDisplayName) { nickname in
                store.updateCommentNickname(nickname)
            }
        }
        .sheet(item: $reportDraft) { draft in
            ReportSheet(draft: draft) { reason, details in
                store.submitReport(entityType: draft.entityType, entityID: draft.entityID, reason: reason, details: details)
            }
        }
        .fullScreenCover(item: $zoomState) { state in
            InspirationMediaLightbox(slides: state.slides, initialIndex: state.initialIndex)
        }
    }

    private var detailAuthorBar: some View {
        HStack(spacing: 12) {
            RemoteImage(urlString: look.authorAvatarURL, height: 36, cornerRadius: 18)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(look.author)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(HairmapUI.ink)
                    .lineLimit(1)
                Text(look.isUserPost ? "用戶分享" : "設計達人分享")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Menu {
                Button("檢舉此靈感內容", role: .destructive) {
                    reportDraft = ReportDraft(
                        entityType: .inspiration,
                        entityID: look.id,
                        title: "檢舉靈感內容",
                        subtitle: look.title
                    )
                }
                if let authorID = look.authorID, store.canBlockUser(authorID) {
                    Button("封鎖並檢舉此作者", role: .destructive) {
                        store.blockUser(
                            authorID,
                            sourceEntityType: .inspiration,
                            sourceEntityID: look.id,
                            sourceTitle: "\(look.author)：\(look.title)"
                        )
                        dismiss()
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(HairmapUI.ink)
                    .frame(width: 40, height: 40)
                    .background(Color.gray.opacity(0.09), in: Circle())
            }
            .buttonStyle(PressableButtonStyle())

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.black.opacity(0.52), in: Circle())
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal, 20)
        .frame(height: 74)
        .background(.white)
    }

    private var detailMediaStage: some View {
        ZStack {
            Color.black

            TabView(selection: $selectedMediaIndex) {
                ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                    Button {
                        zoomState = LookZoomState(slides: slides, initialIndex: index)
                    } label: {
                        SharedLookDetailSlideImage(slide: slide, width: detailMediaWidth, height: detailMediaHeight)
                            .frame(width: detailMediaWidth, height: detailMediaHeight)
                            .clipShape(Rectangle())
                            .overlay(alignment: .topTrailing) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundStyle(.white)
                                    .frame(width: 30, height: 30)
                                    .background(.black.opacity(0.45), in: Circle())
                                    .padding(10)
                            }
                    }
                    .buttonStyle(.plain)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(width: HairmapUI.screenWidth, height: detailMediaHeight)

            HStack {
                Button {
                    selectedMediaIndex = max(0, selectedMediaIndex - 1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.black.opacity(0.45), in: Circle())
                }
                .buttonStyle(PressableButtonStyle())
                .opacity(selectedMediaIndex == 0 ? 0.35 : 1)

                Spacer()

                Button {
                    selectedMediaIndex = min(slides.count - 1, selectedMediaIndex + 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.black.opacity(0.45), in: Circle())
                }
                .buttonStyle(PressableButtonStyle())
                .opacity(selectedMediaIndex == slides.count - 1 ? 0.35 : 1)
            }
            .padding(.horizontal, 10)
            .frame(width: HairmapUI.screenWidth, height: detailMediaHeight)

            HStack(spacing: 5) {
                ForEach(Array(slides.enumerated()), id: \.element.id) { index, _ in
                    Capsule()
                        .fill(index == selectedMediaIndex ? .white : .white.opacity(0.42))
                        .frame(width: index == selectedMediaIndex ? 18 : 6, height: 5)
                }
            }
            .frame(width: HairmapUI.screenWidth, height: detailMediaHeight, alignment: .bottom)
            .padding(.bottom, 10)
        }
        .frame(width: HairmapUI.screenWidth, height: detailMediaHeight)
        .animation(.snappy(duration: 0.22), value: selectedMediaIndex)
    }

    private var postActionBar: some View {
        HStack(spacing: 26) {
            Button(action: onToggleLike) {
                Label("\(look.likes + (isLiked ? 1 : 0))", systemImage: isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(isLiked ? Color(red: 1.0, green: 0.08, blue: 0.35) : HairmapUI.ink)
            }
            .buttonStyle(PressableButtonStyle())

            Button {
                replyingTo = nil
            } label: {
                Label("\(commentTotal)", systemImage: "bubble")
            }
            .buttonStyle(PressableButtonStyle())

            Spacer()

            Button {
                isSaved.toggle()
            } label: {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
            }
            .buttonStyle(PressableButtonStyle())
        }
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(HairmapUI.ink)
        .labelStyle(.titleAndIcon)
        .padding(.horizontal, 20)
        .frame(width: HairmapUI.screenWidth, height: 52)
        .background(.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(HairmapUI.line)
                .frame(height: 1)
        }
    }

    private var commentComposerBar: some View {
        VStack(spacing: 8) {
            if let replyingTo {
                HStack {
                    Text("回覆 \(replyingTo.author)")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        self.replyingTo = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                .padding(.horizontal, 20)
            }

            HStack(spacing: 12) {
                TextField(replyingTo == nil ? "說點什麼..." : "回覆 \(replyingTo?.author ?? "")...", text: $commentText)
                    .font(.system(size: 14, weight: .semibold))
                    .textInputAutocapitalization(.sentences)
                    .focused($isCommentFieldFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        submitComment()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(Color.gray.opacity(0.11), in: Capsule())

                bottomActionButton(
                    systemImage: isLiked ? "heart.fill" : "heart",
                    count: look.likes + (isLiked ? 1 : 0),
                    isActive: isLiked,
                    action: onToggleLike
                )

                Button {
                    if canSubmitComment {
                        submitComment()
                    } else {
                        onShare()
                    }
                } label: {
                    CommentSendGlyph()
                        .fill(.black)
                        .frame(width: 24, height: 22)
                        .frame(width: 70, height: 44)
                        .background(.white, in: Capsule())
                        .overlay(Capsule().stroke(HairmapUI.line, lineWidth: 1))
                        .shadow(color: .black.opacity(0.14), radius: 10, x: 2, y: 4)
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 10)
        .padding(.bottom, 10)
        .frame(width: HairmapUI.screenWidth)
        .background(.white)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(HairmapUI.line)
                .frame(height: 1)
        }
    }

    private func bottomActionButton(systemImage: String, count: Int, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                Text("\(count)")
                    .font(.system(size: 10, weight: .black))
            }
            .foregroundStyle(isActive ? Color(red: 1.0, green: 0.08, blue: 0.35) : HairmapUI.ink)
            .frame(width: 42, height: 44)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var detailTitleBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(look.title)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(HairmapUI.ink)
                .lineLimit(2)

            Text(look.details.isEmpty ? "跟大家分享美髮心得、髮型重點與日常整理技巧。" : look.details)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(red: 0.28, green: 0.31, blue: 0.37))
                .lineSpacing(4)
                .lineLimit(3)
        }
        .frame(width: HairmapUI.contentWidth, alignment: .leading)
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("共 \(commentTotal) 條評論")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(HairmapUI.ink)
                Spacer()
                Menu {
                    Button("最相關") {}
                    Button("最新") {}
                    Button("最多互動") {}
                } label: {
                    HStack(spacing: 4) {
                        Text("最相關")
                        Image(systemName: "chevron.down")
                    }
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 16) {
                ForEach(comments) { comment in
                    InspirationCommentThreadRow(
                        comment: comment,
                        likedIDs: store.likedCommentIDs,
                        onLike: { store.toggleInspirationCommentLike($0) },
                        onReply: {
                            replyingTo = $0
                            isCommentFieldFocused = true
                        },
                        canBlock: { store.canBlockUser($0.authorID) },
                        onBlock: { comment in
                            guard let authorID = comment.authorID else {
                                store.statusMessage = "暫時無法封鎖此留言作者"
                                return
                            }
                            store.blockUser(
                                authorID,
                                sourceEntityType: .inspiration,
                                sourceEntityID: "comment:\(comment.id)",
                                sourceTitle: "\(comment.author)：\(comment.text)"
                            )
                            if replyingTo?.authorID == authorID {
                                replyingTo = nil
                            }
                        },
                        onReport: { comment in
                            reportDraft = ReportDraft(
                                entityType: .inspiration,
                                entityID: "comment:\(comment.id)",
                                title: "檢舉留言",
                                subtitle: comment.text
                            )
                        }
                    )
                    if comment.id != comments.last?.id {
                        Divider()
                    }
                }
            }
        }
        .frame(width: HairmapUI.contentWidth, alignment: .leading)
    }

    private var canSubmitComment: Bool {
        !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submitComment() {
        let cleanText = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }
        if store.needsCommentNickname {
            showingNicknamePrompt = true
            return
        }
        store.addInspirationComment(lookID: look.id, parentID: replyingTo?.id, text: cleanText)
        replyingTo = nil
        commentText = ""
        isCommentFieldFocused = false
    }

    private var detailHero: some View {
        ZStack(alignment: .bottomLeading) {
            SharedLookDetailImage(look: look, width: HairmapUI.screenWidth, height: heroHeight)

            LinearGradient(
                colors: [.clear, .black.opacity(0.72)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(width: HairmapUI.screenWidth, height: heroHeight)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.46), in: Circle())
            }
            .buttonStyle(PressableButtonStyle())
            .frame(width: HairmapUI.screenWidth, height: heroHeight, alignment: .topTrailing)
            .padding(.top, 18)
            .padding(.trailing, 18)

            VStack(alignment: .leading, spacing: 8) {
                Text(look.isUserPost ? "用戶人氣分享" : "熱門靈感範本")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(HairmapUI.amber600, in: RoundedRectangle(cornerRadius: 5, style: .continuous))

                Text(look.title)
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text("由 \(look.author) 分享於 \(look.studio)")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .frame(width: HairmapUI.screenWidth, alignment: .bottomLeading)
        }
        .frame(width: HairmapUI.screenWidth, height: heroHeight)
        .clipped()
    }

    private var likePanel: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                Text("\(look.likes + (isLiked ? 1 : 0)) 個人說讚")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(HairmapUI.ink)
            }

            Spacer()

            Button(action: onToggleLike) {
                Text(isLiked ? "已說讚" : "點擊點讚")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(HairmapUI.ink)
                    .frame(width: 92, height: 38)
                    .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(HairmapUI.line, lineWidth: 1))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(18)
        .background(Color(red: 0.985, green: 0.986, blue: 0.988), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .frame(width: HairmapUI.contentWidth)
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("髮型設計標籤", systemImage: "tag")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(look.tags.prefix(8), id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(Color(red: 0.42, green: 0.27, blue: 0.04))
                        .padding(.horizontal, 11)
                        .frame(height: 30)
                        .background(Color(red: 1.0, green: 0.97, blue: 0.84), in: Capsule())
                }
            }
        }
        .frame(width: HairmapUI.contentWidth, alignment: .leading)
    }

    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("造型亮點與說明 HIGHLIGHTS")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.secondary)
            Text(look.details.isEmpty ? "這款髮型能突顯輪廓與髮絲線條，出門前只需簡單整理即可，非常適合追求精緻隨性風格的您！" : look.details)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(red: 0.25, green: 0.28, blue: 0.34))
                .lineSpacing(5)
        }
        .frame(width: HairmapUI.contentWidth, alignment: .leading)
    }

    private var fitAssessmentCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("髮型細節適配評估", systemImage: "info.circle")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(HairmapUI.ink)

            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("適配臉型")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.secondary)
                    Text(look.faceShape)
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(HairmapUI.ink)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 6) {
                    Text("適配髮質")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.secondary)
                    Text(look.hairType)
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(HairmapUI.ink)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            VStack(alignment: .leading, spacing: 7) {
                Text("設計師建議整理技巧")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.secondary)
                Text(look.specs)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(red: 0.34, green: 0.36, blue: 0.42))
                    .lineSpacing(4)
            }
        }
        .padding(18)
        .frame(width: HairmapUI.contentWidth, alignment: .leading)
        .background(Color(red: 0.985, green: 0.986, blue: 0.988), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(HairmapUI.line, lineWidth: 1))
    }

}

private struct RemoteAspectFitImage: View {
    let urlString: String
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .overlay(ProgressView().tint(.white))
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure:
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .overlay(Image(systemName: "photo").foregroundStyle(.white.opacity(0.7)))
            @unknown default:
                Rectangle().fill(Color.white.opacity(0.08))
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }
}

private struct RemoteVideoPlayer: View {
    let urlString: String
    let width: CGFloat
    let height: CGFloat
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            if URL(string: urlString) != nil {
                VideoPlayer(player: player)
                    .background(Color.black)
                    .onAppear {
                        guard player == nil, let url = URL(string: urlString) else { return }
                        let nextPlayer = AVPlayer(url: url)
                        nextPlayer.isMuted = true
                        player = nextPlayer
                        nextPlayer.play()
                    }
                    .onDisappear {
                        player?.pause()
                        player = nil
                    }
                    .overlay(alignment: .topLeading) {
                        Label("VIDEO", systemImage: "play.fill")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .frame(height: 22)
                            .background(.black.opacity(0.6), in: Capsule())
                            .padding(8)
                    }
            } else {
                Rectangle()
                    .fill(Color.black)
                    .overlay(Image(systemName: "play.slash").foregroundStyle(.white.opacity(0.72)))
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }
}

private struct SharedLookDetailImage: View {
    let look: SharedHairLook
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            if look.mediaKind == .photo, let data = look.mediaData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if look.mediaKind == .video, let imageURL = look.imageURL {
                RemoteVideoPlayer(urlString: imageURL, width: width, height: height)
            } else if look.mediaKind == .video, look.mediaData != nil {
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.08, blue: 0.09), Color(red: 0.24, green: 0.24, blue: 0.26)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 58, weight: .bold))
                    .foregroundStyle(.white)
            } else if let imageURL = look.imageURL {
                RemoteAspectFitImage(urlString: imageURL, width: width, height: height)
            } else {
                Color(red: 0.93, green: 0.94, blue: 0.96)
                Image(systemName: "photo")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }
}

private struct SharedLookDetailSlideImage: View {
    let slide: LookMediaSlide
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            if slide.mediaKind == .photo, let data = slide.mediaData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if slide.mediaKind == .video, let imageURL = slide.imageURL {
                RemoteVideoPlayer(urlString: imageURL, width: width, height: height)
            } else if slide.mediaKind == .video, slide.mediaData != nil {
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.08, blue: 0.09), Color(red: 0.24, green: 0.24, blue: 0.26)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 58, weight: .bold))
                    .foregroundStyle(.white)
            } else if let imageURL = slide.imageURL {
                RemoteAspectFitImage(urlString: imageURL, width: width, height: height)
            } else {
                Color(red: 0.93, green: 0.94, blue: 0.96)
                Image(systemName: "photo")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }
}

private struct InspirationMediaLightbox: View {
    @Environment(\.dismiss) private var dismiss
    let slides: [LookMediaSlide]
    @State private var selectedIndex: Int

    init(slides: [LookMediaSlide], initialIndex: Int) {
        self.slides = slides
        _selectedIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $selectedIndex) {
                ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                    GeometryReader { proxy in
                        SharedLookDetailSlideImage(
                            slide: slide,
                            width: proxy.size.width,
                            height: proxy.size.height
                        )
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .tag(index)
                    }
                    .ignoresSafeArea()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack {
                HStack {
                    Text("\(selectedIndex + 1) / \(max(slides.count, 1))")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.82))
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(.white.opacity(0.16), in: Capsule())
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.18), in: Circle())
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)

                Spacer()

                HStack(spacing: 5) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { index, _ in
                        Capsule()
                            .fill(index == selectedIndex ? .white : .white.opacity(0.34))
                            .frame(width: index == selectedIndex ? 22 : 7, height: 5)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct InspirationCommentThreadRow: View {
    let comment: LookCommentItem
    let likedIDs: Set<String>
    let onLike: (LookCommentItem) -> Void
    let onReply: (LookCommentItem) -> Void
    let canBlock: (LookCommentItem) -> Bool
    let onBlock: (LookCommentItem) -> Void
    let onReport: (LookCommentItem) -> Void
    var isReply = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            InspirationCommentContentRow(
                comment: comment,
                isLiked: likedIDs.contains(comment.id),
                isReply: isReply,
                onLike: { onLike(comment) },
                onReply: { onReply(comment) },
                canBlock: canBlock(comment),
                onBlock: { onBlock(comment) },
                onReport: { onReport(comment) }
            )

            if !comment.replies.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(comment.replies) { reply in
                        InspirationCommentThreadRow(
                            comment: reply,
                            likedIDs: likedIDs,
                            onLike: onLike,
                            onReply: onReply,
                            canBlock: canBlock,
                            onBlock: onBlock,
                            onReport: onReport,
                            isReply: true
                        )
                    }
                }
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(HairmapUI.line)
                        .frame(width: 2)
                        .padding(.leading, 15)
                }
                .padding(.leading, 24)
            }
        }
    }
}

private struct CommentSendGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: w * 0.16, y: h * 0.16))
        path.addQuadCurve(to: CGPoint(x: w * 0.88, y: h * 0.50), control: CGPoint(x: w * 0.54, y: h * 0.14))
        path.addQuadCurve(to: CGPoint(x: w * 0.16, y: h * 0.84), control: CGPoint(x: w * 0.54, y: h * 0.86))
        path.addQuadCurve(to: CGPoint(x: w * 0.34, y: h * 0.52), control: CGPoint(x: w * 0.20, y: h * 0.69))
        path.addLine(to: CGPoint(x: w * 0.34, y: h * 0.48))
        path.addQuadCurve(to: CGPoint(x: w * 0.16, y: h * 0.16), control: CGPoint(x: w * 0.20, y: h * 0.31))
        path.closeSubpath()

        return path
    }
}

private struct InspirationCommentContentRow: View {
    let comment: LookCommentItem
    let isLiked: Bool
    var isReply = false
    let onLike: () -> Void
    let onReply: () -> Void
    let canBlock: Bool
    let onBlock: () -> Void
    let onReport: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RemoteImage(urlString: comment.avatarURL, height: isReply ? 26 : 34, cornerRadius: isReply ? 13 : 17)
                .frame(width: isReply ? 26 : 34, height: isReply ? 26 : 34)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 5) {
                    Text(comment.author)
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(HairmapUI.ink)
                        .lineLimit(1)
                    Text(comment.timeAgo)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                    if comment.isCreator {
                        Text("作者")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .frame(height: 18)
                            .background(.black, in: Capsule())
                    }
                    Spacer()
                    Menu {
                        Button("檢舉此留言", role: .destructive) {
                            onReport()
                        }
                        if canBlock {
                            Button("封鎖並檢舉此用戶", role: .destructive) {
                                onBlock()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 30, height: 28)
                    }
                }

                Text(comment.text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(red: 0.24, green: 0.26, blue: 0.31))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 22) {
                    Button(action: onLike) {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                            if comment.likes > 0 {
                                Text("\(comment.likes)")
                            }
                        }
                        .foregroundStyle(isLiked ? Color(red: 1.0, green: 0.08, blue: 0.35) : .secondary)
                    }
                    .buttonStyle(PressableButtonStyle())

                    Button(action: onReply) {
                        Image(systemName: "bubble")
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            }
        }
    }
}

private struct HairShareTemplate: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let imageURL: String
    let tags: [String]
    let faceShape: String
    let hairType: String
    let specs: String
    let details: String
}

private struct HairShareSheet: View {
    @Environment(HairmapStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let onPublish: (SharedHairLook) -> Void

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedMediaItems: [SharedLookMedia] = []
    @State private var selectedPreviewImages: [UIImage] = []
    @State private var selectedMediaKind: SharedLookMediaKind = .photo
    @State private var selectedTemplate: HairShareTemplate?
    @State private var title = ""
    @State private var studio = "311 SALON 男士燙染造型"
    @State private var location = "深圳 · 福田區"
    @State private var tags = ["#日系羊毛卷", "#巴黎挑染", "#縮毛矯正", "#裙擺染", "#高層次氣墊燙", "#經典漸層油頭", "#線條感挑染"]
    @State private var selectedTags: Set<String> = ["#日系羊毛卷"]
    @State private var customTag = ""
    @State private var faceShape = "鵝蛋臉、圓臉皆適合"
    @State private var hairType = "一般髮質、中等或細軟髮量"
    @State private var specs = "整理非常簡單，吹乾後抹上少許免沖洗護髮油即可。"
    @State private var details = ""

    private let templates = [
        HairShareTemplate(
            id: "soft_perm",
            title: "日系捲古羊毛卷",
            subtitle: "日系捲古羊毛卷",
            imageURL: "https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=600&q=80",
            tags: ["#日系羊毛卷", "#高層次氣墊燙"],
            faceShape: "鵝蛋臉、圓臉皆適合",
            hairType: "中等髮量或細軟髮量",
            specs: "吹乾時用手繞出捲度，再用輕質造型乳定型。",
            details: "自然蓬鬆又不厚重，適合想保留甜美感的中長髮。"
        ),
        HairShareTemplate(
            id: "paris_blonde",
            title: "巴黎冷色手刷染",
            subtitle: "巴黎冷色手刷染",
            imageURL: "https://images.unsplash.com/photo-1522338242992-e1a54906a8da?auto=format&fit=crop&w=600&q=80",
            tags: ["#巴黎挑染", "#線條感挑染"],
            faceShape: "長臉、心形臉適合",
            hairType: "中等或偏厚髮量",
            specs: "每週使用護色髮膜，避免色素快速流失。",
            details: "冷色手刷染能保留髮根深度，讓髮尾更有空氣感。"
        ),
        HairShareTemplate(
            id: "french_bob",
            title: "法式柔霧鮑伯",
            subtitle: "法式柔霧鮑伯",
            imageURL: "https://images.unsplash.com/photo-1519699047748-de8e457a634e?auto=format&fit=crop&w=600&q=80",
            tags: ["#短髮造型", "#法式鮑伯"],
            faceShape: "小臉、鵝蛋臉適合",
            hairType: "一般髮質",
            specs: "瀏海處用圓梳吹出弧度，髮尾保留自然內彎。",
            details: "乾淨利落又有高級感，適合日常與職場造型。"
        )
    ]

    private var canPublish: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (!selectedMediaItems.isEmpty || selectedTemplate != nil)
    }

    private var selectedFileCount: Int {
        selectedMediaItems.count + (selectedTemplate == nil ? 0 : 1)
    }

    private var uploadTileWidth: CGFloat {
        (HairmapUI.contentWidth - 12) / 2
    }

    private var uploadTileHeight: CGFloat {
        uploadTileWidth * 0.75
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("發布美髮靈感", systemImage: "camera")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(HairmapUI.ink)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("關閉")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(Color.gray.opacity(0.08), in: Capsule())
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.horizontal, 20)
            .frame(height: 68)

            Divider()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text("選擇照片或短影音（可多選，不限張數/短片）")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("已選：\(selectedFileCount) 檔案")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(Color(red: 0.0, green: 0.56, blue: 0.42))
                            .padding(.horizontal, 8)
                            .frame(height: 24)
                            .background(Color(red: 0.88, green: 1.0, blue: 0.95), in: Capsule())
                    }

                    HStack(spacing: 12) {
                        PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .any(of: [.images, .videos])) {
                            UploadDropZone(width: uploadTileWidth, height: uploadTileHeight)
                        }
                        .buttonStyle(PressableButtonStyle())

                        UploadPreviewTile(
                            image: selectedPreviewImages.first,
                            template: selectedTemplate,
                            mediaKind: selectedMediaKind,
                            count: selectedFileCount,
                            width: uploadTileWidth,
                            height: uploadTileHeight
                        )
                    }

                    VStack(alignment: .leading, spacing: 9) {
                        Label("快速模板：導入預設高畫質美髮照片與短影片", systemImage: "bolt.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(red: 0.48, green: 0.29, blue: 0.06))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(templates) { template in
                                    Button {
                                        apply(template)
                                    } label: {
                                        QuickTemplateCard(template: template, isSelected: selectedTemplate == template)
                                    }
                                    .buttonStyle(PressableButtonStyle())
                                }
                            }
                        }
                    }

                    sheetTextField(label: "分享標題 TITLE（必填）", placeholder: "例如：誠意推薦！這家男士英斯利冷燙真的毫無強制推銷…", text: $title)

                    HStack(spacing: 12) {
                        sheetTextField(label: "定位門店 / 創作主題", placeholder: "311 SALON 男士燙染造型", text: $studio)
                        sheetTextField(label: "地理位置地區 LOCATION", placeholder: "深圳 · 福田區", text: $location)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        sheetLabel("標記您的髮型特點（可多選）")
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                Button {
                                    toggleTag(tag)
                                } label: {
                                    Text(tag)
                                        .font(.system(size: 11, weight: .bold))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.72)
                                        .foregroundStyle(selectedTags.contains(tag) ? .white : HairmapUI.ink)
                                        .padding(.horizontal, 10)
                                        .frame(height: 30)
                                        .background(selectedTags.contains(tag) ? Color.black : .white, in: Capsule())
                                        .overlay(Capsule().stroke(selectedTags.contains(tag) ? Color.black : HairmapUI.line, lineWidth: 1))
                                }
                                .buttonStyle(PressableButtonStyle())
                            }
                        }

                        HStack(spacing: 10) {
                            TextField("輸入自訂標籤（例如：日系小狼尾）", text: $customTag)
                                .font(.system(size: 13, weight: .medium))
                                .padding(.horizontal, 12)
                                .frame(height: 44)
                                .background(Color(red: 0.973, green: 0.977, blue: 0.984), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 1))
                            Button("加入") {
                                addCustomTag()
                            }
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(.black)
                            .frame(width: 44)
                        }
                    }

                    HStack(spacing: 12) {
                        sheetTextField(label: "適配臉型", placeholder: "鵝蛋臉、圓臉皆適合", text: $faceShape)
                        sheetTextField(label: "適配髮質", placeholder: "一般髮質、中等髮量", text: $hairType)
                    }

                    sheetTextField(label: "日常保養與整理技巧 SPECS", placeholder: "整理非常簡單，吹乾後抹上少許免沖洗護髮油即可。", text: $specs)

                    VStack(alignment: .leading, spacing: 8) {
                        sheetLabel("心得說明與推薦 DETAILS")
                        TextEditor(text: $details)
                            .font(.system(size: 13, weight: .medium))
                            .scrollContentBackground(.hidden)
                            .overlay(alignment: .topLeading) {
                                if details.isEmpty {
                                    Text("跟大家分享這個髮型您最喜歡的地方，或者整理保養心得吧！")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Color.gray.opacity(0.62))
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 9)
                                        .allowsHitTesting(false)
                                }
                            }
                            .frame(height: 96)
                            .padding(8)
                            .background(Color(red: 0.973, green: 0.977, blue: 0.984), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 1))
                    }

                    HStack(spacing: 16) {
                        Button {
                            dismiss()
                        } label: {
                            Text("取消")
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 1))
                        }
                        .buttonStyle(PressableButtonStyle())

                        Button {
                            publish()
                        } label: {
                            Text("確認發布靈感卡片")
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.08, blue: 0.35), Color(red: 1.0, green: 0.55, blue: 0.02)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                )
                        }
                        .buttonStyle(PressableButtonStyle())
                        .disabled(!canPublish)
                        .opacity(canPublish ? 1 : 0.45)
                    }
                    .padding(.top, 12)
                }
                .padding(20)
                .frame(width: HairmapUI.screenWidth)
            }
        }
        .background(.white)
        .presentationDetents([.large])
        .presentationCornerRadius(28)
        .preferredColorScheme(.light)
        .onChange(of: selectedItems) { _, items in
            Task { await loadSelectedItems(items) }
        }
    }

    @ViewBuilder
    private func sheetTextField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sheetLabel(label)
            TextField(placeholder, text: text)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 12)
                .frame(height: 46)
                .background(Color(red: 0.973, green: 0.977, blue: 0.984), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 1))
        }
    }

    private func sheetLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .black))
            .foregroundStyle(.secondary)
    }

    private func apply(_ template: HairShareTemplate) {
        selectedTemplate = template
        selectedItems = []
        selectedMediaItems = []
        selectedPreviewImages = []
        selectedMediaKind = .photo
        title = template.title
        tags = Array(Set(tags + template.tags)).sorted()
        selectedTags.formUnion(template.tags)
        faceShape = template.faceShape
        hairType = template.hairType
        specs = template.specs
        details = template.details
    }

    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    private func addCustomTag() {
        let clean = customTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let tag = clean.hasPrefix("#") ? clean : "#\(clean)"
        if !tags.contains(tag) { tags.append(tag) }
        selectedTags.insert(tag)
        customTag = ""
    }

    private func loadSelectedItems(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        selectedTemplate = nil
        var mediaItems: [SharedLookMedia] = []
        var previewImages: [UIImage] = []

        for item in items {
            let isVideo = item.supportedContentTypes.contains { $0.conforms(to: .movie) }
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            mediaItems.append(
                SharedLookMedia(
                    imageURL: nil,
                    mediaData: data,
                    mediaKind: isVideo ? .video : .photo
                )
            )
            if !isVideo, let image = UIImage(data: data) {
                previewImages.append(image)
            }
        }

        guard !mediaItems.isEmpty else { return }
        selectedMediaItems = mediaItems
        selectedPreviewImages = previewImages
        selectedMediaKind = mediaItems.first?.mediaKind ?? .photo
    }

    private func publish() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canPublish else { return }
        let primaryMedia = selectedMediaItems.first
        let look = SharedHairLook(
            id: "user_\(Int(Date().timeIntervalSince1970 * 1000))",
            title: cleanTitle,
            authorID: store.currentProfile?.id,
            author: store.commentDisplayName,
            authorAvatarURL: store.commentAvatarURL,
            studio: studio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Hairmap Community" : studio,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "香港" : location,
            tags: selectedTags.isEmpty ? ["#我的髮型"] : Array(selectedTags).sorted(),
            imageURL: selectedMediaItems.isEmpty ? selectedTemplate?.imageURL : nil,
            mediaData: primaryMedia?.mediaData,
            mediaKind: primaryMedia?.mediaKind ?? selectedMediaKind,
            mediaItems: selectedMediaItems,
            stylistID: selectedTemplate == nil ? nil : "master-leo",
            faceShape: faceShape,
            hairType: hairType,
            specs: specs,
            details: details,
            likes: 0,
            category: "最新髮型",
            isUserPost: true
        )
        onPublish(look)
        dismiss()
    }
}

private struct UploadDropZone: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "arrow.up")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.secondary)
            Text("上傳手機照片 / 相片")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(HairmapUI.ink)
            Text("支援多媒體，單手短片上載")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .frame(width: width, height: height)
        .background(Color(red: 0.973, green: 0.977, blue: 0.984), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(style: StrokeStyle(lineWidth: 1.4, dash: [5, 5]))
                .foregroundStyle(.secondary)
        )
    }
}

private struct UploadPreviewTile: View {
    let image: UIImage?
    let template: HairShareTemplate?
    let mediaKind: SharedLookMediaKind
    let count: Int
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if mediaKind == .video {
                Color(red: 0.08, green: 0.08, blue: 0.09)
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
            } else if let template {
                RemoteImage(urlString: template.imageURL, height: height, cornerRadius: 0)
            } else {
                Color(red: 0.973, green: 0.977, blue: 0.984)
                VStack(spacing: 8) {
                    Image(systemName: "camera")
                        .font(.system(size: 22, weight: .bold))
                    Text("尚未添加多媒體檔案\n點擊左側或下方預設快速導入")
                        .multilineTextAlignment(.center)
                }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(12)
            }

            if count > 1 {
                Text("\(count) 張")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .frame(height: 26)
                    .background(.black.opacity(0.68), in: Capsule())
                    .frame(width: width - 14, height: height - 14, alignment: .topTrailing)
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.black, lineWidth: 1))
    }
}

private struct QuickTemplateCard: View {
    let template: HairShareTemplate
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            RemoteImage(urlString: template.imageURL, height: 84, cornerRadius: 8)
                .frame(width: 112, height: 84)
            Text(template.title)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(HairmapUI.ink)
                .lineLimit(1)
            Text(template.subtitle)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(6)
        .frame(width: 126, height: 122)
        .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? .black : HairmapUI.line, lineWidth: isSelected ? 1.4 : 1))
    }
}

private let portfolioFallbackPresets: [(String, String)] = [
    ("霧感冷灰層次", "https://images.unsplash.com/photo-1522338242992-e1a54906a8da?auto=format&fit=crop&w=900&q=80"),
    ("日系柔光剪裁", "https://images.unsplash.com/photo-1527799820374-dcf8d9d4a388?auto=format&fit=crop&w=900&q=80"),
    ("法式蓬鬆線條", "https://images.unsplash.com/photo-1519699047748-de8e457a634e?auto=format&fit=crop&w=900&q=80"),
    ("高層次空氣感", "https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=900&q=80"),
    ("亮澤順滑護理", "https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?auto=format&fit=crop&w=900&q=80"),
    ("香氛造型護理", "https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?auto=format&fit=crop&w=900&q=80"),
    ("店內設計項目", "https://images.unsplash.com/photo-1522338242992-e1a54906a8da?auto=format&fit=crop&w=900&q=80")
]

private let brokenPortfolioImageURLFragments: Set<String> = [
    "photo-1595959183075-c1d0a174db24"
]

private func isDisplayablePortfolioImageURL(_ urlString: String) -> Bool {
    let clean = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !clean.isEmpty else { return false }
    guard !brokenPortfolioImageURLFragments.contains(where: { clean.contains($0) }) else { return false }
    guard let url = URL(string: clean), let scheme = url.scheme?.lowercased() else { return false }
    return scheme == "http" || scheme == "https"
}

private func displayablePortfolioWorks(_ works: [PortfolioWork], limit: Int? = nil) -> [PortfolioWork] {
    var seen = Set<String>()
    let filtered = works.compactMap { work -> PortfolioWork? in
        let cleanURL = work.imageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isDisplayablePortfolioImageURL(cleanURL), seen.insert(cleanURL).inserted else { return nil }
        var cleaned = work
        cleaned.imageURL = cleanURL
        return cleaned
    }
    if let limit {
        return Array(filtered.prefix(limit))
    }
    return filtered
}

private func expandedPortfolioWorks(
    base: [PortfolioWork],
    stylistID: String,
    titlePrefix: String,
    inspiration: [InspirationItem],
    sharedLooks: [SharedHairLook],
    limit: Int = 9,
    allowDemoExpansion: Bool = false
) -> [PortfolioWork] {
    var works = displayablePortfolioWorks(base)
    var seen = Set(works.map(\.imageURL))

    guard allowDemoExpansion else {
        return Array(works.prefix(limit))
    }

    for item in inspiration where item.stylistID == stylistID {
        let imageURL = item.imageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isDisplayablePortfolioImageURL(imageURL), !seen.contains(imageURL) else { continue }
        works.append(PortfolioWork(id: "inspiration-\(item.id)", stylistID: stylistID, title: item.title, imageURL: imageURL))
        seen.insert(imageURL)
    }

    for look in sharedLooks where look.stylistID == stylistID {
        guard let rawURL = look.imageURL else { continue }
        let imageURL = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isDisplayablePortfolioImageURL(imageURL), !seen.contains(imageURL) else { continue }
        works.append(PortfolioWork(id: "shared-\(look.id)", stylistID: stylistID, title: look.title, imageURL: imageURL))
        seen.insert(imageURL)
    }

    var fallbackIndex = 0
    while works.count < limit {
        let preset = portfolioFallbackPresets[fallbackIndex % portfolioFallbackPresets.count]
        works.append(PortfolioWork(id: "\(stylistID)-fallback-\(fallbackIndex)", stylistID: stylistID, title: "\(titlePrefix) \(preset.0)", imageURL: preset.1))
        fallbackIndex += 1
    }

    return Array(works.prefix(limit))
}

private func expandedSalonWorks(
    salon: Salon,
    team: [Stylist],
    inspiration: [InspirationItem],
    sharedLooks: [SharedHairLook],
    limit: Int = 9,
    allowDemoFallback: Bool = false
) -> [PortfolioWork] {
    let stylistIDs = Set(team.map(\.id))
    var works = displayablePortfolioWorks(team.flatMap(\.works))
    var seen = Set(works.map(\.imageURL))

    for item in inspiration where stylistIDs.contains(item.stylistID) {
        let imageURL = item.imageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isDisplayablePortfolioImageURL(imageURL), !seen.contains(imageURL) else { continue }
        works.append(PortfolioWork(id: "salon-inspiration-\(item.id)", stylistID: item.stylistID, title: item.title, imageURL: imageURL))
        seen.insert(imageURL)
    }

    for look in sharedLooks where look.stylistID.map({ stylistIDs.contains($0) }) == true {
        guard let rawURL = look.imageURL else { continue }
        let imageURL = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isDisplayablePortfolioImageURL(imageURL), !seen.contains(imageURL) else { continue }
        works.append(PortfolioWork(id: "salon-shared-\(look.id)", stylistID: look.stylistID ?? salon.id, title: look.title, imageURL: imageURL))
        seen.insert(imageURL)
    }

    if allowDemoFallback {
        var fallbackIndex = 0
        while works.count < limit {
            let preset = portfolioFallbackPresets[fallbackIndex % portfolioFallbackPresets.count]
            works.append(PortfolioWork(id: "\(salon.id)-fallback-\(fallbackIndex)", stylistID: salon.id, title: "店內設計項目 \(fallbackIndex + 1)", imageURL: preset.1))
            fallbackIndex += 1
        }
    }

    return Array(works.prefix(limit))
}

struct StylistProfileView: View {
    @Environment(HairmapStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    let stylistID: String
    @State private var selectedServiceID = ""
    @State private var selectedGallery: PortfolioGalleryState?
    @State private var reportDraft: ReportDraft?

    private var stylist: Stylist { store.stylist(id: stylistID) }
    private var selectedService: ServiceItem? {
        stylist.services.first { $0.id == selectedServiceID } ?? stylist.services.first
    }
    private var profileWorks: [PortfolioWork] {
        let isSeedStylist = stylist.ownerID == nil && SeedData.stylists.contains { $0.id == stylist.id }
        return expandedPortfolioWorks(
            base: stylist.works,
            stylistID: stylist.id,
            titlePrefix: stylist.name,
            inspiration: store.inspiration,
            sharedLooks: store.sharedLooks,
            allowDemoExpansion: isSeedStylist
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            DetailTopBar(
                title: "Hairmap",
                onBack: { dismiss() },
                onReport: {
                    reportDraft = ReportDraft(
                        entityType: .stylist,
                        entityID: stylist.id,
                        title: "檢舉髮型師檔案",
                        subtitle: stylist.name
                    )
                },
                onBlock: store.canBlockUser(stylist.ownerID) ? {
                    blockStylistOwner()
                } : nil
            )

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    stylistHero

                    ProfileStatsRow(stylist: stylist)
                        .frame(width: HairmapUI.contentWidth)
                        .padding(.horizontal, 20)
                        .offset(y: -36)

                    VStack(alignment: .leading, spacing: 26) {
                        stylistBioSection
                        stylistContactSection
                        portfolioSection
                        servicesSection
                        reviewsSection
                        ReviewComposer(
                            title: "發表您對設計師的珍貴評價",
                            placeholder: "分享您在髮型微調、燙髮、漂染染髮過程中的心得...",
                            buttonTitle: "送出並發表此設計師評價"
                        ) { name, stars, text, photoData in
                            store.addReview(stylistID: stylist.id, reviewerName: name, text: text, stars: stars, reviewPhotoData: photoData)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, -12)
                    .padding(.bottom, 118)
                }
                .frame(width: HairmapUI.screenWidth, alignment: .leading)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            FloatingCircleButton(systemImage: "message") {
                store.selectedTab = .chat
                store.customerPath = []
            }
            .padding(.trailing, 26)
            .padding(.bottom, 96)
        }
        .safeAreaInset(edge: .bottom) {
            if let service = selectedService {
                StickyBookingBar(
                    eyebrow: "已選服務",
                    price: String(format: "$%.2f", Double(service.price)),
                    buttonTitle: "立即預約",
                    buttonSystemImage: "calendar"
                ) {
                    store.startBooking(stylistID: stylist.id, service: service)
                }
                .frame(width: HairmapUI.screenWidth)
            }
        }
        .onAppear {
            selectedServiceID = selectedServiceID.isEmpty ? (stylist.services.first?.id ?? "") : selectedServiceID
        }
        .fullScreenCover(item: $selectedGallery) { gallery in
            PortfolioLightbox(works: gallery.works, initialIndex: gallery.initialIndex)
        }
        .sheet(item: $reportDraft) { draft in
            ReportSheet(draft: draft) { reason, details in
                store.submitReport(entityType: draft.entityType, entityID: draft.entityID, reason: reason, details: details)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .background(HairmapUI.background.ignoresSafeArea())
    }

    private func blockStylistOwner() {
        guard let ownerID = stylist.ownerID else {
            store.statusMessage = "暫時無法封鎖此髮型師帳號"
            return
        }
        store.blockUser(
            ownerID,
            sourceEntityType: .profile,
            sourceEntityID: ownerID.uuidString,
            sourceTitle: stylist.name
        )
        dismiss()
    }

    private var stylistContactSection: some View {
        let phone = stylist.phone.trimmingCharacters(in: .whitespacesAndNewlines)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(Color(red: 0.58, green: 0.34, blue: 0.06))
                Text("髮型師聯絡電話")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(HairmapUI.ink)
            }

            Button(action: callStylist) {
                HStack(spacing: 12) {
                    Image(systemName: phone.isEmpty ? "phone.slash" : "phone")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(phone.isEmpty ? Color.secondary : Color.black)
                        .frame(width: 36, height: 36)
                        .background(Color(red: 1.0, green: 0.95, blue: 0.76), in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(phone.isEmpty ? "暫未提供電話" : phone)
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundStyle(HairmapUI.ink)
                        Text(phone.isEmpty ? "髮型師更新檔案後會顯示" : "點擊直接聯絡此髮型師")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .frame(width: HairmapUI.contentWidth)
                .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(HairmapUI.line, lineWidth: 1))
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(phone.isEmpty)
        }
        .frame(width: HairmapUI.contentWidth, alignment: .leading)
    }

    private func callStylist() {
        let allowed = CharacterSet(charactersIn: "+0123456789")
        let phone = stylist.phone.unicodeScalars
            .filter { allowed.contains($0) }
            .map(String.init)
            .joined()
        guard !phone.isEmpty, let url = URL(string: "tel://\(phone)") else { return }
        openURL(url)
    }

    private var stylistHero: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(urlString: stylist.avatarURL, height: HairmapUI.detailHeroHeight)
                .frame(width: HairmapUI.screenWidth)
            LinearGradient(
                colors: [.black.opacity(0.08), .clear, .black.opacity(0.76)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: HairmapUI.screenWidth, height: HairmapUI.detailHeroHeight)

            VStack(alignment: .leading, spacing: 10) {
                Text(stylist.name)
                    .font(.system(size: 33, weight: .black, design: .serif))
                    .foregroundStyle(.white)
                    .shadow(radius: 5)
                HStack(spacing: 8) {
                    ForEach(stylist.specialties.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 12, weight: .black))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.18), in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(0.34), lineWidth: 1))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 56)
            .frame(width: HairmapUI.screenWidth, alignment: .bottomLeading)
        }
        .frame(width: HairmapUI.screenWidth, height: HairmapUI.detailHeroHeight)
        .clipped()
    }

    private var stylistBioSection: some View {
        let bio = stylist.bio.trimmingCharacters(in: .whitespacesAndNewlines)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(Color(red: 0.58, green: 0.34, blue: 0.06))
                Text("個人簡介 Bio")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(HairmapUI.ink)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(bio.isEmpty ? "這位髮型師尚未填寫個人簡介。審批通過後，新增或更新髮型師檔案內的個人簡介會同步顯示在這裡。" : bio)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(red: 0.32, green: 0.35, blue: 0.4))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                    ForEach(stylist.specialties.prefix(4), id: \.self) { specialty in
                        Text(specialty)
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(HairmapUI.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color(red: 1.0, green: 0.95, blue: 0.76), in: Capsule())
                    }
                }
            }
            .frame(width: HairmapUI.contentWidth - 36, alignment: .leading)
            .padding(18)
            .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(HairmapUI.line, lineWidth: 1))
        }
        .frame(width: HairmapUI.contentWidth, alignment: .leading)
    }

    private var portfolioSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("作品集展示")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(HairmapUI.ink)
                    Text("最多容納 9+ 精選髮型照片，點擊即可放大橫向移動瀏覽")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Text("\(profileWorks.count) 件設計")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(Color(red: 0.54, green: 0.32, blue: 0.06))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(HairmapUI.portfolioGridTileWidth), spacing: 8), count: 3),
                spacing: 8
            ) {
                ForEach(Array(profileWorks.enumerated()), id: \.element.id) { index, work in
                    Button {
                        selectedGallery = PortfolioGalleryState(works: profileWorks, initialIndex: index)
                    } label: {
                        PortfolioTile(work: work, height: HairmapUI.portfolioGridTileHeight)
                            .frame(width: HairmapUI.portfolioGridTileWidth, height: HairmapUI.portfolioGridTileHeight)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .frame(width: HairmapUI.contentWidth, alignment: .leading)
        }
    }

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("服務項目")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(HairmapUI.ink)

            VStack(spacing: 0) {
                ForEach(stylist.services) { service in
                    ServiceSelectionRow(
                        service: service,
                        isSelected: service.id == selectedService?.id
                    ) {
                        selectedServiceID = service.id
                    }
                    if service.id != stylist.services.last?.id {
                        Divider().padding(.leading, 2)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("顧客評價")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(HairmapUI.ink)
                Spacer()
                Text("\(stylist.reviews.count) 則評價")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Color(red: 0.58, green: 0.34, blue: 0.06))
            }

            VStack(spacing: 14) {
                ForEach(stylist.reviews) { review in
                    ReviewRow(
                        review: review,
                        onReport: { review in
                        reportDraft = ReportDraft(
                            entityType: .review,
                            entityID: review.id,
                            title: "檢舉顧客評價",
                            subtitle: review.text
                        )
                        },
                        onBlock: store.canBlockUser(review.reviewerID) ? { selectedReview in
                            blockReview(selectedReview)
                        } : nil
                    )
                }
            }
        }
    }

    private func blockReview(_ review: ReviewItem) {
        guard let reviewerID = review.reviewerID else {
            store.statusMessage = "暫時無法封鎖此評價作者"
            return
        }
        store.blockUser(
            reviewerID,
            sourceEntityType: .review,
            sourceEntityID: review.id,
            sourceTitle: "\(review.reviewerName)：\(review.text)"
        )
    }
}

private struct DetailTopBar: View {
    let title: String
    let onBack: () -> Void
    var onReport: (() -> Void)?
    var onBlock: (() -> Void)?

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .black))
                    .frame(width: 44, height: 44)
                    .foregroundStyle(.black)
            }
            .buttonStyle(PressableButtonStyle())

            Spacer()
            Text(title)
                .font(.system(size: 23, weight: .black, design: .serif))
                .foregroundStyle(.black)
            Spacer()

            if let onReport {
                Menu {
                    Button("檢舉此檔案", role: .destructive) {
                        onReport()
                    }
                    if let onBlock {
                        Button("封鎖並檢舉此用戶", role: .destructive) {
                            onBlock()
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 44, height: 44)
                        .foregroundStyle(.black)
                }
                .buttonStyle(PressableButtonStyle())
            } else {
                Button {} label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .bold))
                        .frame(width: 44, height: 44)
                        .foregroundStyle(.black)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 62)
        .background(.white)
    }
}

private struct ProfileStatsRow: View {
    let stylist: Stylist

    var body: some View {
        HStack(spacing: 0) {
            ProfileStat(value: String(format: "%.1f", stylist.rating), title: "評分", systemImage: "star.fill")
            Divider().frame(height: 44)
            ProfileStat(value: stylist.experience, title: "資歷")
            Divider().frame(height: 44)
            ProfileStat(value: stylist.languages, title: "語言")
        }
        .frame(height: 86)
        .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
    }
}

private struct ProfileStat: View {
    let value: String
    let title: String
    var systemImage: String?

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(.yellow)
                }
                Text(value)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .font(.system(size: 15, weight: .black))
            .foregroundStyle(HairmapUI.ink)

            Text(title)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PortfolioTile: View {
    let work: PortfolioWork
    var height: CGFloat

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottomLeading) {
                RemoteImage(urlString: work.imageURL, height: proxy.size.height, cornerRadius: 12)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                LinearGradient(colors: [.clear, .black.opacity(0.58)], startPoint: .center, endPoint: .bottom)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text(work.title)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(10)
                    .frame(width: proxy.size.width, alignment: .leading)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.white.opacity(0.72), lineWidth: 1))
        }
        .frame(height: height)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct PortfolioAllSheet: View {
    let stylist: Stylist
    @Environment(\.dismiss) private var dismiss
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(stylist.works) { work in
                        PortfolioTile(work: work, height: 210)
                    }
                }
                .padding(16)
            }
            .navigationTitle("全部作品集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.light)
    }
}

private struct PortfolioLightbox: View {
    let works: [PortfolioWork]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIndex: Int

    init(works: [PortfolioWork], initialIndex: Int) {
        self.works = works
        _selectedIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $selectedIndex) {
                ForEach(Array(works.enumerated()), id: \.element.id) { index, work in
                    VStack(spacing: 16) {
                        LightboxRemoteImage(urlString: work.imageURL)
                            .frame(width: HairmapUI.lightboxImageWidth, height: HairmapUI.lightboxImageHeight)
                            .background(.black, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .clipped()

                        VStack(spacing: 6) {
                            Text(work.title)
                                .font(.system(size: 18, weight: .black))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                            Text("\(index + 1) / \(works.count)")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.62))
                        }
                        .padding(.horizontal, 28)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.18), in: Circle())
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct LightboxRemoteImage: View {
    let urlString: String

    var body: some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failure:
                Image(systemName: "photo")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.white.opacity(0.55))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            @unknown default:
                EmptyView()
            }
        }
    }
}

private struct ServiceSelectionRow: View {
    let service: ServiceItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(service.name)
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(HairmapUI.ink)
                    Text("\(service.description) · \(service.duration) 分鐘")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text("$\(service.price)")
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .foregroundStyle(HairmapUI.ink)
                Image(systemName: isSelected ? "checkmark" : "plus")
                    .font(.system(size: 17, weight: .black))
                    .frame(width: 42, height: 42)
                    .foregroundStyle(isSelected ? .white : .black)
                    .background(isSelected ? .black : .clear, in: Circle())
                    .overlay(Circle().stroke(.black, lineWidth: 1))
            }
            .padding(.vertical, 16)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct ReviewRow: View {
    let review: ReviewItem
    var onReport: ((ReviewItem) -> Void)?
    var onBlock: ((ReviewItem) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 11) {
                RemoteImage(urlString: review.reviewerAvatar, height: 42, cornerRadius: 21)
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                VStack(alignment: .leading, spacing: 3) {
                    Text(review.reviewerName)
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(HairmapUI.ink)
                    Text(review.timeAgo)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StarLine(stars: review.stars, size: 12)
                if let onReport {
                    Menu {
                        Button("檢舉此評價", role: .destructive) {
                            onReport(review)
                        }
                        if let onBlock {
                            Button("封鎖並檢舉此用戶", role: .destructive) {
                                onBlock(review)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 30, height: 30)
                    }
                }
            }

            Text(review.text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(red: 0.28, green: 0.31, blue: 0.37))
                .lineSpacing(3)

            if let photoURL = review.reviewPhotoURL, !photoURL.isEmpty {
                ReviewPhotoThumbnail(photoURL: photoURL)
            } else if let data = review.reviewPhotoData, let image = UIImage(data: data) {
                ReviewPhotoThumbnail(image: image)
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(HairmapUI.line, lineWidth: 1))
    }
}

private struct ReviewPhotoThumbnail: View {
    var photoURL: String? = nil
    var image: UIImage? = nil

    private var width: CGFloat {
        min(152, HairmapUI.contentWidth * 0.43)
    }

    private var height: CGFloat {
        width * 0.75
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let photoURL {
                RemoteImage(urlString: photoURL, height: height, cornerRadius: 12)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .clipped()
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(HairmapUI.line, lineWidth: 1))
    }
}

private struct StarLine: View {
    let stars: Int
    var size: CGFloat

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= stars ? "star.fill" : "star")
                    .font(.system(size: size, weight: .black))
                    .foregroundStyle(.yellow)
            }
        }
    }
}

private struct ReviewComposer: View {
    @Environment(HairmapStore.self) private var store
    let title: String
    let placeholder: String
    let buttonTitle: String
    let onSubmit: (String, Int, String, Data?) -> Void
    @State private var reviewerName = ""
    @State private var rating = 5
    @State private var text = ""
    @State private var reviewPhotoItem: PhotosPickerItem?
    @State private var reviewPhotoData: Data?
    @State private var showingNicknamePrompt = false

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label(title, systemImage: "pencil.and.outline")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(HairmapUI.ink)

            Divider()

            HStack {
                FieldLabel("發表身份")
                Spacer()
                Button {
                    showingNicknamePrompt = true
                } label: {
                    Text(store.commentDisplayName == "訪客" ? "設定暱稱" : "更改暱稱")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.black)
                }
                .buttonStyle(PressableButtonStyle())
            }

            HStack(spacing: 9) {
                Image(systemName: store.commentDisplayName == "訪客" ? "person.crop.circle" : "checkmark.seal.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(store.commentDisplayName == "訪客" ? .secondary : Color(red: 0.02, green: 0.48, blue: 0.31))
                Text(store.needsCommentNickname ? "請先設定暱稱，之後會自動代入評論。" : "\(store.commentDisplayName) 將會作為評論名稱")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(HairmapUI.ink)
                    .lineLimit(2)
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(Color(red: 0.973, green: 0.977, blue: 0.984), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 1))

            FieldLabel("評分等級")
            HStack(spacing: 14) {
                ForEach(1...5, id: \.self) { index in
                    Button {
                        rating = index
                    } label: {
                        Image(systemName: index <= rating ? "star.fill" : "star")
                            .font(.system(size: 25, weight: .black))
                            .foregroundStyle(.yellow)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }

            FieldLabel("評價說明內容（必填）")
            TextEditor(text: $text)
                .font(.system(size: 14, weight: .medium))
                .scrollContentBackground(.hidden)
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.gray.opacity(0.62))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 9)
                            .allowsHitTesting(false)
                    }
                }
                .frame(height: 86)
                .padding(8)
                .background(Color(red: 0.973, green: 0.977, blue: 0.984), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 1))

            FieldLabel("上載照片（可選）")
            HStack(spacing: 12) {
                PhotosPicker(selection: $reviewPhotoItem, matching: .images) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                        Text(reviewPhotoData == nil ? "上載評論照片" : "更換照片")
                    }
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(red: 0.973, green: 0.977, blue: 0.984), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 1))
                }
                .buttonStyle(PressableButtonStyle())

                if let data = reviewPhotoData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 54, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(HairmapUI.line, lineWidth: 1))
                }
            }

            Button {
                if store.needsCommentNickname {
                    showingNicknamePrompt = true
                    return
                }
                reviewerName = store.commentDisplayName
                onSubmit(store.commentDisplayName, rating, text, reviewPhotoData)
                rating = 5
                text = ""
                reviewPhotoItem = nil
                reviewPhotoData = nil
            } label: {
                Text(buttonTitle)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(.black, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(HairmapUI.line, lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 12, y: 6)
        .task(id: reviewPhotoItem) {
            guard let reviewPhotoItem else { return }
            reviewPhotoData = try? await reviewPhotoItem.loadTransferable(type: Data.self)
        }
        .onAppear {
            reviewerName = store.commentDisplayName
            if store.needsCommentNickname {
                showingNicknamePrompt = true
            }
        }
        .sheet(isPresented: $showingNicknamePrompt) {
            NicknamePromptSheet(currentName: store.commentDisplayName) { nickname in
                store.updateCommentNickname(nickname)
                reviewerName = store.commentDisplayName
            }
        }
    }
}

private struct NicknamePromptSheet: View {
    @Environment(\.dismiss) private var dismiss
    let currentName: String
    let onSave: (String) -> Void
    @State private var nickname = ""

    private var canSave: Bool {
        !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("設定您的評論暱稱", systemImage: "person.text.rectangle")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(HairmapUI.ink)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .background(Color.gray.opacity(0.1), in: Circle())
                }
                .buttonStyle(PressableButtonStyle())
            }

            Text("Google 或 Apple 登入後只需要設定一次，之後髮型師檔案、沙龍檔案同靈感評論都會自動代入。")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineSpacing(3)

            TextField("例如: Kelvin, Winnie, Alex", text: $nickname)
                .font(.system(size: 15, weight: .bold))
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(Color(red: 0.973, green: 0.977, blue: 0.984), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.black, lineWidth: 1))

            Button {
                onSave(nickname)
                dismiss()
            } label: {
                Text("儲存暱稱")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(canSave ? .black : Color.gray.opacity(0.35), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!canSave)
        }
        .padding(22)
        .presentationDetents([.height(300)])
        .presentationCornerRadius(24)
        .preferredColorScheme(.light)
        .onAppear {
            nickname = currentName == "訪客" ? "" : currentName
        }
    }
}

private struct FieldLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .black))
            .foregroundStyle(.secondary)
    }
}

private extension View {
    func reviewFieldStyle(height: CGFloat) -> some View {
        self
            .font(.system(size: 14, weight: .semibold))
            .padding(.horizontal, 12)
            .frame(height: height)
            .background(Color(red: 0.973, green: 0.977, blue: 0.984), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 1))
    }
}

private struct FloatingCircleButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 58, height: 58)
                .background(.white, in: Circle())
                .shadow(color: .black.opacity(0.18), radius: 14, y: 7)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct StickyBookingBar: View {
    let eyebrow: String
    let price: String
    let buttonTitle: String
    let buttonSystemImage: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(eyebrow)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.secondary)
                Text(price)
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundStyle(HairmapUI.ink)
            }
            Spacer()
            Button(action: action) {
                HStack(spacing: 8) {
                    Text(buttonTitle)
                    Image(systemName: buttonSystemImage)
                }
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.black)
                .frame(width: 146, height: 56)
                .background(HairmapUI.amberSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow.opacity(0.45), lineWidth: 1))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .frame(width: HairmapUI.screenWidth)
        .background(.white)
    }
}

private struct SalonProfileFooter: View {
    let salon: Salon

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("店家服務起價")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.secondary)
                Text("HK$ \(salon.startPrice)")
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundStyle(HairmapUI.ink)
            }
            Spacer()
            Text("歡迎電話諮詢或細看設計師檔案")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(Color(red: 0.56, green: 0.35, blue: 0.08))
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
                .padding(.horizontal, 12)
                .frame(width: 174, height: 48)
                .background(Color.yellow.opacity(0.13), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .frame(width: HairmapUI.screenWidth)
        .background(.white)
    }
}

struct SalonProfileView: View {
    @Environment(HairmapStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    let salonID: String
    @State private var selectedGallery: PortfolioGalleryState?
    @State private var reportDraft: ReportDraft?

    private var salon: Salon { store.salon(id: salonID) }
    private var team: [Stylist] { store.stylists.filter { $0.salonID == salonID } }
    private var featuredStylist: Stylist { team.first ?? store.stylist() }
    private var salonWorks: [PortfolioWork] {
        let savedWorks = displayablePortfolioWorks(store.salonWorks[salonID] ?? [])
        let isSeedSalon = SeedData.salons.contains { $0.id == salon.id }
        let expandedWorks = expandedSalonWorks(
            salon: salon,
            team: team,
            inspiration: store.inspiration,
            sharedLooks: store.sharedLooks,
            allowDemoFallback: isSeedSalon
        )
        var seen = Set(savedWorks.map(\.imageURL))
        return displayablePortfolioWorks(savedWorks + expandedWorks.filter { seen.insert($0.imageURL).inserted }, limit: 9)
    }
    private var salonServices: [ServiceItem] { Array(team.flatMap { $0.services }.prefix(3)) }
    private var salonReviews: [ReviewItem] { Array(team.flatMap { $0.reviews }.prefix(4)) }

    var body: some View {
        VStack(spacing: 0) {
            DetailTopBar(
                title: "沙龍檔案詳情",
                onBack: { dismiss() },
                onReport: {
                    reportDraft = ReportDraft(
                        entityType: .salon,
                        entityID: salon.id,
                        title: "檢舉沙龍檔案",
                        subtitle: salon.name
                    )
                }
            )

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    salonHero

                    SalonStatsRow(salon: salon)
                        .frame(width: HairmapUI.contentWidth)
                        .padding(.horizontal, 20)
                        .offset(y: -36)

                    VStack(alignment: .leading, spacing: 28) {
                        salonInfo
                        teamSection
                        latestWorksSection
                        selectedServicesSection
                        salonReviewsSection
                        ReviewComposer(
                            title: "發表您的真實優質評價",
                            placeholder: "分享您的剪髮、諮詢或環境享受等真實體驗心得...",
                            buttonTitle: "送出並發佈沙龍評價"
                        ) { name, stars, text, photoData in
                            store.addReview(stylistID: featuredStylist.id, reviewerName: name, text: text, stars: stars, reviewPhotoData: photoData)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, -10)
                    .padding(.bottom, 118)
                }
                .frame(width: HairmapUI.screenWidth, alignment: .leading)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            FloatingCircleButton(systemImage: "phone", action: callSalon)
                .background(HairmapUI.amber600, in: Circle())
                .padding(.trailing, 26)
                .padding(.bottom, 98)
        }
        .safeAreaInset(edge: .bottom) {
            SalonProfileFooter(salon: salon)
                .frame(width: HairmapUI.screenWidth)
        }
        .fullScreenCover(item: $selectedGallery) { gallery in
            PortfolioLightbox(works: gallery.works, initialIndex: gallery.initialIndex)
        }
        .sheet(item: $reportDraft) { draft in
            ReportSheet(draft: draft) { reason, details in
                store.submitReport(entityType: draft.entityType, entityID: draft.entityID, reason: reason, details: details)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .background(HairmapUI.background.ignoresSafeArea())
    }

    private func callSalon() {
        let allowed = CharacterSet(charactersIn: "+0123456789")
        let phone = salon.phone.unicodeScalars
            .filter { allowed.contains($0) }
            .map(String.init)
            .joined()
        guard let url = URL(string: "tel://\(phone)") else { return }
        openURL(url)
    }

    private var salonHero: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(urlString: salon.imageURL, height: HairmapUI.salonHeroHeight)
                .frame(width: HairmapUI.screenWidth)
            LinearGradient(colors: [.clear, .black.opacity(0.72)], startPoint: .center, endPoint: .bottom)
                .frame(width: HairmapUI.screenWidth, height: HairmapUI.salonHeroHeight)

            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 6) {
                    ForEach(salon.tags.prefix(2), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(HairmapUI.amber600, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                            .foregroundStyle(.black)
                    }
                }
                Text(salon.name)
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Label("\(salon.location)（距離您大約 \(String(format: "%.1f", salon.distance)) 公里）", systemImage: "mappin.circle")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.84))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
            .frame(width: HairmapUI.screenWidth, alignment: .bottomLeading)
        }
        .frame(width: HairmapUI.screenWidth, height: HairmapUI.salonHeroHeight)
        .clipped()
    }

    private var salonInfo: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("沙龍優勢與特徵 Info")
                .font(.system(size: 20, weight: .black))
            VStack(alignment: .leading, spacing: 12) {
                Text("歡迎光臨 \(salon.name)！我們店內空間皆經過精緻設計，為每位尊貴顧客提供舒壓的洗浴、按摩及造型時光。全店均採用日本及義大利進口頂級有機染護專利產品。")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(red: 0.32, green: 0.35, blue: 0.4))
                    .lineSpacing(5)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 148), spacing: 8)], spacing: 8) {
                    ForEach(["免費進口氣泡水/手沖咖啡", "專屬充電牆座與千兆 Wi-Fi", "頭皮敏感隔離修護與音樂舒壓"], id: \.self) { item in
                        Text("✓ \(item)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 7)
                            .background(Color.gray.opacity(0.08), in: Capsule())
                    }
                }
            }
            .padding(18)
            .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(HairmapUI.line, lineWidth: 1))
        }
    }

    private var teamSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("本沙龍精選「駐店設計師」", systemImage: "sparkles")
                .font(.system(size: 19, weight: .black))
                .foregroundStyle(HairmapUI.ink)
            VStack(spacing: 12) {
                ForEach(team) { stylist in
                    Button { store.showStylist(stylist.id) } label: {
                        SalonStylistRow(stylist: stylist)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
    }

    private var latestWorksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("沙龍最新作品展示")
                        .font(.system(size: 20, weight: .black))
                    Text("最高支援 9+ 作品展示，點選照片可放大橫向移動瀏覽")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Text("\(salonWorks.count) 件作品")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(Color(red: 0.54, green: 0.32, blue: 0.06))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(HairmapUI.portfolioGridTileWidth), spacing: 8), count: 3),
                spacing: 8
            ) {
                ForEach(Array(salonWorks.enumerated()), id: \.element.id) { index, work in
                    Button {
                        selectedGallery = PortfolioGalleryState(works: salonWorks, initialIndex: index)
                    } label: {
                        PortfolioTile(work: work, height: HairmapUI.portfolioGridTileHeight)
                            .frame(width: HairmapUI.portfolioGridTileWidth, height: HairmapUI.portfolioGridTileHeight)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .frame(width: HairmapUI.contentWidth, alignment: .leading)
        }
    }

    private var selectedServicesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("沙龍精選定價項目")
                .font(.system(size: 20, weight: .black))
            VStack(spacing: 0) {
                ForEach(salonServices) { service in
                    HStack {
                        Text(service.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(red: 0.25, green: 0.27, blue: 0.32))
                            .lineLimit(1)
                        Spacer()
                        Text("HK$ \(max(service.price, salon.startPrice)) 起")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                    }
                    .padding(.vertical, 14)
                    if service.id != salonServices.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(HairmapUI.line, lineWidth: 1))
        }
    }

    private var salonReviewsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("顧客評價 Reviews")
                    .font(.system(size: 20, weight: .black))
                Spacer()
                Text("平均 \(String(format: "%.1f", salon.rating)) 星")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(Color(red: 0.58, green: 0.34, blue: 0.06))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.1), in: Capsule())
                    .overlay(Capsule().stroke(Color.yellow.opacity(0.35), lineWidth: 1))
            }

            VStack(spacing: 14) {
                ForEach(salonReviews) { review in
                    ReviewRow(
                        review: review,
                        onReport: { review in
                        reportDraft = ReportDraft(
                            entityType: .review,
                            entityID: review.id,
                            title: "檢舉沙龍評價",
                            subtitle: review.text
                        )
                        },
                        onBlock: store.canBlockUser(review.reviewerID) ? { selectedReview in
                            blockReview(selectedReview)
                        } : nil
                    )
                }
            }
        }
    }

    private func blockReview(_ review: ReviewItem) {
        guard let reviewerID = review.reviewerID else {
            store.statusMessage = "暫時無法封鎖此評價作者"
            return
        }
        store.blockUser(
            reviewerID,
            sourceEntityType: .review,
            sourceEntityID: review.id,
            sourceTitle: "\(review.reviewerName)：\(review.text)"
        )
    }
}

private struct SalonStatsRow: View {
    let salon: Salon

    var body: some View {
        HStack(spacing: 0) {
            ProfileStat(value: String(format: "%.1f", salon.rating), title: "評分（2 則）", systemImage: "star.fill")
            Divider().frame(height: 44)
            ProfileStat(value: salon.openHours, title: "營業時間", systemImage: "clock")
            Divider().frame(height: 44)
            ProfileStat(value: salon.phone, title: "聯絡電話", systemImage: "phone")
        }
        .frame(height: 86)
        .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
    }
}

private struct SalonStylistRow: View {
    let stylist: Stylist

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(urlString: stylist.avatarURL, height: 58, cornerRadius: 29)
                .frame(width: 58)
            VStack(alignment: .leading, spacing: 4) {
                Text(stylist.name)
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(HairmapUI.ink)
                Text("\(stylist.title) · \(stylist.experience)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text(String(format: "%.1f", stylist.rating))
                    .font(.system(size: 12, weight: .black))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.white, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(red: 0.55, green: 0.32, blue: 0.08), lineWidth: 1))
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(HairmapUI.line, lineWidth: 1))
    }
}
