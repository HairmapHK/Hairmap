import Foundation

enum UserRole: String, Codable, CaseIterable, Identifiable, Hashable {
    case customer
    case stylist

    var id: String { rawValue }

    var label: String {
        switch self {
        case .customer: "我是顧客"
        case .stylist: "我是髮型師"
        }
    }
}

enum CustomerTab: String, CaseIterable, Identifiable, Hashable {
    case discovery
    case inspiration
    case booking
    case chat
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .discovery: "探索"
        case .inspiration: "靈感"
        case .booking: "預約"
        case .chat: "訊息"
        case .profile: "個人"
        }
    }

    var symbol: String {
        switch self {
        case .discovery: "magnifyingglass"
        case .inspiration: "sparkles"
        case .booking: "calendar"
        case .chat: "message"
        case .profile: "person"
        }
    }
}

enum CustomerRoute: Hashable {
    case stylist(String)
    case salon(String)
}

enum ReportEntityType: String, Codable, CaseIterable, Identifiable, Hashable {
    case stylist
    case salon
    case review
    case inspiration
    case message
    case profile

    var id: String { rawValue }
}

enum BookingStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case pending
    case accepted
    case inProgress = "in_progress"
    case completed
    case cancelled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending: "待確認"
        case .accepted: "已接受"
        case .inProgress: "進行中"
        case .completed: "已完成"
        case .cancelled: "已取消"
        }
    }
}

enum BookingAssignmentMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case stylistSelected = "stylist_selected"
    case salonAssigns = "salon_assigns"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stylistSelected: "指定髮型師"
        case .salonAssigns: "由店舖安排"
        }
    }
}

enum SalonChatSenderRole: String, Codable, Hashable {
    case customer
    case salon
    case admin
}

struct HairmapProfile: Identifiable, Codable, Hashable {
    var id: UUID
    var displayName: String
    var email: String
    var role: UserRole
    var stylistID: String?
    var avatarURL: String = ""

    init(
        id: UUID,
        displayName: String,
        email: String,
        role: UserRole,
        stylistID: String? = nil,
        avatarURL: String = ""
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.role = role
        self.stylistID = stylistID
        self.avatarURL = avatarURL
    }

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case email
        case role
        case stylistID = "stylist_id"
        case avatarURL = "avatar_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        email = try container.decode(String.self, forKey: .email)
        role = try container.decode(UserRole.self, forKey: .role)
        stylistID = try container.decodeIfPresent(String.self, forKey: .stylistID)
        avatarURL = try container.decodeIfPresent(String.self, forKey: .avatarURL) ?? ""
    }
}

struct SalonBrand: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var ownerID: UUID?
    var primarySalonID: String
    var description: String
    var imageURL: String
    var instagramURL: String
    var phone: String
    var isActive: Bool
    var displayOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case ownerID = "owner_id"
        case primarySalonID = "primary_salon_id"
        case description
        case imageURL = "image_url"
        case instagramURL = "instagram_url"
        case phone
        case isActive = "is_active"
        case displayOrder = "display_order"
    }

    init(
        id: String,
        name: String,
        ownerID: UUID? = nil,
        primarySalonID: String = "",
        description: String = "",
        imageURL: String = "",
        instagramURL: String = "",
        phone: String = "",
        isActive: Bool = true,
        displayOrder: Int = 100
    ) {
        self.id = id
        self.name = name
        self.ownerID = ownerID
        self.primarySalonID = primarySalonID
        self.description = description
        self.imageURL = imageURL
        self.instagramURL = instagramURL
        self.phone = phone
        self.isActive = isActive
        self.displayOrder = displayOrder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        ownerID = try container.decodeIfPresent(UUID.self, forKey: .ownerID)
        primarySalonID = try container.decodeIfPresent(String.self, forKey: .primarySalonID) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL) ?? ""
        instagramURL = try container.decodeIfPresent(String.self, forKey: .instagramURL) ?? ""
        phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? ""
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        displayOrder = try container.decodeIfPresent(Int.self, forKey: .displayOrder) ?? 100
    }
}

enum HairmapDistricts {
    static let regions: [(name: String, districts: [String])] = [
        ("香港島", ["中環", "金鐘", "灣仔", "銅鑼灣", "天后", "北角", "鰂魚涌", "太古", "西灣河", "筲箕灣", "柴灣", "上環", "西營盤", "堅尼地城", "香港仔", "黃竹坑", "鴨脷洲", "赤柱"]),
        ("九龍", ["尖沙咀", "佐敦", "油麻地", "旺角", "太子", "深水埗", "長沙灣", "荔枝角", "九龍塘", "石硤尾", "何文田", "土瓜灣", "紅磡", "黃埔", "九龍城", "樂富", "黃大仙", "鑽石山", "彩虹", "九龍灣", "牛頭角", "觀塘", "藍田", "油塘"]),
        ("新界", ["荃灣", "葵芳", "青衣", "沙田", "大圍", "火炭", "馬鞍山", "大埔", "粉嶺", "上水", "元朗", "天水圍", "屯門", "將軍澳", "坑口", "寶琳", "西貢", "清水灣"]),
        ("離島", ["東涌", "愉景灣", "迪士尼", "長洲", "坪洲", "南丫島", "梅窩", "大澳"])
    ]

    static let all = regions.flatMap { $0.districts }

    static func inferredDistrict(from text: String) -> String {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return "" }
        return all
            .sorted { $0.count > $1.count }
            .first { cleanText.localizedCaseInsensitiveContains($0) } ?? ""
    }

    static func displayDistrict(district: String, location: String = "") -> String {
        let cleanDistrict = district.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanDistrict.isEmpty { return cleanDistrict }
        let inferred = inferredDistrict(from: location)
        if !inferred.isEmpty { return inferred }
        let cleanLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanLocation.isEmpty ? "香港" : cleanLocation
    }

    static func displayLocation(district: String, location: String) -> String {
        let cleanDistrict = displayDistrict(district: district, location: location)
        let cleanLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanLocation.isEmpty, cleanLocation != "香港" else { return cleanDistrict }
        guard !cleanLocation.localizedCaseInsensitiveContains(cleanDistrict) else { return cleanLocation }
        return "\(cleanDistrict) · \(cleanLocation)"
    }
}

enum HairmapExternalLinks {
    static func normalizedInstagramWebURL(from rawValue: String) -> URL? {
        let cleanValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanValue.isEmpty else { return nil }

        if let url = URL(string: cleanValue),
           let scheme = url.scheme?.lowercased(),
           ["http", "https"].contains(scheme),
           let host = url.host?.lowercased(),
           host.contains("instagram.com") || host.contains("instagr.am") {
            return url
        }

        if let handle = instagramHandle(from: cleanValue) {
            return URL(string: "https://www.instagram.com/\(handle)")
        }

        let withScheme = "https://\(cleanValue)"
        if let url = URL(string: withScheme),
           let host = url.host?.lowercased(),
           host.contains("instagram.com") || host.contains("instagr.am") {
            return url
        }

        return nil
    }

    static func instagramAppURL(from rawValue: String) -> URL? {
        guard let handle = instagramHandle(from: rawValue) else { return nil }
        return URL(string: "instagram://user?username=\(handle)")
    }

    static func instagramDisplayText(from rawValue: String) -> String {
        if let handle = instagramHandle(from: rawValue) {
            return "@\(handle)"
        }
        return "Instagram"
    }

    private static func instagramHandle(from rawValue: String) -> String? {
        let cleanValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanValue.isEmpty else { return nil }

        if let url = URL(string: cleanValue),
           url.scheme?.lowercased() == "instagram",
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let username = components.queryItems?.first(where: { $0.name == "username" })?.value {
            return sanitizedInstagramHandle(username)
        }

        let urlCandidate = cleanValue.contains("://") ? cleanValue : "https://\(cleanValue)"
        if let components = URLComponents(string: urlCandidate),
           let host = components.host?.lowercased(),
           host.contains("instagram.com") || host.contains("instagr.am") {
            let firstPathComponent = components.path
                .split(separator: "/")
                .first
                .map(String.init)
            return firstPathComponent.flatMap(sanitizedInstagramHandle)
        }

        let withoutAt = cleanValue.hasPrefix("@") ? String(cleanValue.dropFirst()) : cleanValue
        return sanitizedInstagramHandle(withoutAt)
    }

    private static func sanitizedInstagramHandle(_ rawValue: String) -> String? {
        let cleanValue = rawValue.trimmingCharacters(in: CharacterSet(charactersIn: " /?\n\r\t"))
        guard (1...30).contains(cleanValue.count) else { return nil }
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._")
        guard cleanValue.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return nil }
        return cleanValue
    }
}

struct Salon: Identifiable, Codable, Hashable {
    var id: String
    var brandID: String?
    var branchName: String
    var name: String
    var location: String
    var district: String
    var distance: Double
    var rating: Double
    var tags: [String]
    var openHours: String
    var phone: String
    var instagramURL: String
    var startPrice: Int
    var imageURL: String
    var isActive: Bool = true
    var isFeatured: Bool = false
    var displayOrder: Int = 100
    var bookingEnabled: Bool = true
    var chatEnabled: Bool = true

    enum CodingKeys: String, CodingKey {
        case id
        case brandID = "brand_id"
        case branchName = "branch_name"
        case name
        case location
        case district
        case distance
        case rating
        case tags
        case openHours = "open_hours"
        case phone
        case instagramURL = "instagram_url"
        case startPrice = "start_price"
        case imageURL = "image_url"
        case isActive = "is_active"
        case isFeatured = "is_featured"
        case displayOrder = "display_order"
        case bookingEnabled = "booking_enabled"
        case chatEnabled = "chat_enabled"
    }

    init(
        id: String,
        brandID: String? = nil,
        branchName: String = "",
        name: String,
        location: String,
        district: String = "",
        distance: Double,
        rating: Double,
        tags: [String],
        openHours: String,
        phone: String,
        instagramURL: String = "",
        startPrice: Int,
        imageURL: String,
        isActive: Bool = true,
        isFeatured: Bool = false,
        displayOrder: Int = 100,
        bookingEnabled: Bool = true,
        chatEnabled: Bool = true
    ) {
        self.id = id
        self.brandID = brandID?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.branchName = branchName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.name = name
        self.location = location
        self.district = district.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? HairmapDistricts.inferredDistrict(from: location)
        self.distance = distance
        self.rating = rating
        self.tags = tags
        self.openHours = openHours
        self.phone = phone
        self.instagramURL = instagramURL.trimmingCharacters(in: .whitespacesAndNewlines)
        self.startPrice = startPrice
        self.imageURL = imageURL
        self.isActive = isActive
        self.isFeatured = isFeatured
        self.displayOrder = displayOrder
        self.bookingEnabled = bookingEnabled
        self.chatEnabled = chatEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        brandID = try container.decodeIfPresent(String.self, forKey: .brandID)?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        branchName = try container.decodeIfPresent(String.self, forKey: .branchName) ?? ""
        name = try container.decode(String.self, forKey: .name)
        location = try container.decode(String.self, forKey: .location)
        let decodedDistrict = try container.decodeIfPresent(String.self, forKey: .district) ?? ""
        district = decodedDistrict.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? HairmapDistricts.inferredDistrict(from: location)
        distance = try container.decode(Double.self, forKey: .distance)
        rating = try container.decode(Double.self, forKey: .rating)
        tags = try container.decode([String].self, forKey: .tags)
        openHours = try container.decode(String.self, forKey: .openHours)
        phone = try container.decode(String.self, forKey: .phone)
        instagramURL = try container.decodeIfPresent(String.self, forKey: .instagramURL) ?? ""
        startPrice = try container.decode(Int.self, forKey: .startPrice)
        imageURL = try container.decode(String.self, forKey: .imageURL)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        isFeatured = try container.decodeIfPresent(Bool.self, forKey: .isFeatured) ?? false
        displayOrder = try container.decodeIfPresent(Int.self, forKey: .displayOrder) ?? 100
        bookingEnabled = try container.decodeIfPresent(Bool.self, forKey: .bookingEnabled) ?? true
        chatEnabled = try container.decodeIfPresent(Bool.self, forKey: .chatEnabled) ?? true
    }

    var displayDistrict: String {
        HairmapDistricts.displayDistrict(district: district, location: location)
    }

    var displayLocation: String {
        HairmapDistricts.displayLocation(district: district, location: location)
    }

    var displayBranchName: String {
        let cleanBranch = branchName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanBranch.isEmpty { return cleanBranch }
        return displayDistrict
    }
}

struct ServiceItem: Identifiable, Codable, Hashable {
    var id: String
    var stylistID: String
    var name: String
    var category: String
    var duration: Int
    var description: String
    var price: Int

    enum CodingKeys: String, CodingKey {
        case id
        case stylistID = "stylist_id"
        case name
        case category
        case duration
        case description
        case price
    }
}

struct SalonServiceItem: Identifiable, Codable, Hashable {
    var id: String
    var salonID: String
    var name: String
    var category: String
    var duration: Int
    var description: String
    var price: Int
    var isActive: Bool
    var displayOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case salonID = "salon_id"
        case name
        case category
        case duration
        case description
        case price
        case isActive = "is_active"
        case displayOrder = "display_order"
    }

    init(
        id: String,
        salonID: String,
        name: String,
        category: String,
        duration: Int,
        description: String,
        price: Int,
        isActive: Bool = true,
        displayOrder: Int = 100
    ) {
        self.id = id
        self.salonID = salonID
        self.name = name
        self.category = category
        self.duration = duration
        self.description = description
        self.price = price
        self.isActive = isActive
        self.displayOrder = displayOrder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        salonID = try container.decode(String.self, forKey: .salonID)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        duration = try container.decodeIfPresent(Int.self, forKey: .duration) ?? 60
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        price = try container.decodeIfPresent(Int.self, forKey: .price) ?? 0
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        displayOrder = try container.decodeIfPresent(Int.self, forKey: .displayOrder) ?? 100
    }
}

enum PortfolioMediaKind: String, Codable, Hashable {
    case photo
    case video
}

struct PortfolioWork: Identifiable, Codable, Hashable {
    var id: String
    var stylistID: String
    var title: String
    var imageURL: String
    var mediaKind: PortfolioMediaKind = .photo
    var videoURL: String = ""
    var thumbnailURL: String = ""

    enum CodingKeys: String, CodingKey {
        case id
        case stylistID = "stylist_id"
        case title
        case imageURL = "image_url"
        case mediaKind = "media_kind"
        case videoURL = "video_url"
        case thumbnailURL = "thumbnail_url"
    }

    init(
        id: String,
        stylistID: String,
        title: String,
        imageURL: String,
        mediaKind: PortfolioMediaKind = .photo,
        videoURL: String = "",
        thumbnailURL: String = ""
    ) {
        self.id = id
        self.stylistID = stylistID
        self.title = title
        self.imageURL = imageURL
        self.mediaKind = mediaKind
        self.videoURL = videoURL
        self.thumbnailURL = thumbnailURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        stylistID = try container.decode(String.self, forKey: .stylistID)
        title = try container.decode(String.self, forKey: .title)
        imageURL = try container.decode(String.self, forKey: .imageURL)
        mediaKind = try container.decodeIfPresent(PortfolioMediaKind.self, forKey: .mediaKind) ?? .photo
        videoURL = try container.decodeIfPresent(String.self, forKey: .videoURL) ?? ""
        thumbnailURL = try container.decodeIfPresent(String.self, forKey: .thumbnailURL) ?? ""
    }

    var displayImageURL: String {
        let cleanThumbnail = thumbnailURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanThumbnail.isEmpty { return cleanThumbnail }
        return imageURL
    }

    var playableVideoURL: String {
        videoURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isVideo: Bool {
        mediaKind == .video && !playableVideoURL.isEmpty
    }
}

struct ReviewItem: Identifiable, Codable, Hashable {
    var id: String
    var stylistID: String
    var reviewerID: UUID? = nil
    var reviewerName: String
    var reviewerAvatar: String
    var text: String
    var stars: Int
    var timeAgo: String
    var reviewPhotoData: Data? = nil
    var reviewPhotoURL: String? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case stylistID = "stylist_id"
        case reviewerID = "reviewer_id"
        case reviewerName = "reviewer_name"
        case reviewerAvatar = "reviewer_avatar"
        case text
        case stars
        case timeAgo = "time_ago"
        case reviewPhotoData = "review_photo_data"
        case reviewPhotoURL = "review_photo_url"
    }
}

struct Stylist: Identifiable, Codable, Hashable {
    var id: String
    var ownerID: UUID?
    var salonID: String
    var district: String
    var location: String
    var name: String
    var title: String
    var rating: Double
    var reviewsCount: Int
    var languages: String
    var experience: String
    var specialties: [String]
    var avatarURL: String
    var phone: String
    var instagramURL: String
    var bio: String
    var basePrice: Int
    var works: [PortfolioWork]
    var services: [ServiceItem]
    var reviews: [ReviewItem]
    var isActive: Bool
    var isFeatured: Bool
    var displayOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case salonID = "salon_id"
        case district
        case location
        case name
        case title
        case rating
        case reviewsCount = "reviews_count"
        case languages
        case experience
        case specialties
        case avatarURL = "avatar_url"
        case phone
        case instagramURL = "instagram_url"
        case bio
        case basePrice = "base_price"
        case isActive = "is_active"
        case isFeatured = "is_featured"
        case displayOrder = "display_order"
    }

    init(
        id: String,
        ownerID: UUID? = nil,
        salonID: String,
        district: String = "",
        location: String = "",
        name: String,
        title: String,
        rating: Double,
        reviewsCount: Int,
        languages: String,
        experience: String,
        specialties: [String],
        avatarURL: String,
        phone: String = "",
        instagramURL: String = "",
        bio: String,
        basePrice: Int,
        works: [PortfolioWork] = [],
        services: [ServiceItem] = [],
        reviews: [ReviewItem] = [],
        isActive: Bool = true,
        isFeatured: Bool = false,
        displayOrder: Int = 100
    ) {
        self.id = id
        self.ownerID = ownerID
        self.salonID = salonID
        self.district = district.trimmingCharacters(in: .whitespacesAndNewlines)
        self.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        self.name = name
        self.title = title
        self.rating = rating
        self.reviewsCount = reviewsCount
        self.languages = languages
        self.experience = experience
        self.specialties = specialties
        self.avatarURL = avatarURL
        self.phone = phone
        self.instagramURL = instagramURL.trimmingCharacters(in: .whitespacesAndNewlines)
        self.bio = bio
        self.basePrice = basePrice
        self.works = works
        self.services = services
        self.reviews = reviews
        self.isActive = isActive
        self.isFeatured = isFeatured
        self.displayOrder = displayOrder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        ownerID = try container.decodeIfPresent(UUID.self, forKey: .ownerID)
        salonID = try container.decode(String.self, forKey: .salonID)
        let decodedDistrict = try container.decodeIfPresent(String.self, forKey: .district) ?? ""
        location = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
        district = decodedDistrict.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? HairmapDistricts.inferredDistrict(from: location)
        name = try container.decode(String.self, forKey: .name)
        title = try container.decode(String.self, forKey: .title)
        rating = try container.decode(Double.self, forKey: .rating)
        reviewsCount = try container.decode(Int.self, forKey: .reviewsCount)
        languages = try container.decode(String.self, forKey: .languages)
        experience = try container.decode(String.self, forKey: .experience)
        specialties = try container.decode([String].self, forKey: .specialties)
        avatarURL = try container.decode(String.self, forKey: .avatarURL)
        phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? ""
        instagramURL = try container.decodeIfPresent(String.self, forKey: .instagramURL) ?? ""
        bio = try container.decodeIfPresent(String.self, forKey: .bio) ?? ""
        basePrice = try container.decodeIfPresent(Int.self, forKey: .basePrice) ?? 0
        works = []
        services = []
        reviews = []
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        isFeatured = try container.decodeIfPresent(Bool.self, forKey: .isFeatured) ?? false
        displayOrder = try container.decodeIfPresent(Int.self, forKey: .displayOrder) ?? 100
    }

    var displayDistrict: String {
        HairmapDistricts.displayDistrict(district: district, location: location)
    }

    var displayLocation: String {
        HairmapDistricts.displayLocation(district: district, location: location)
    }
}

enum CatalogApplicationStatus: String, Codable, Hashable, CaseIterable, Identifiable {
    case pending
    case approved
    case rejected
    case hidden

    var id: String { rawValue }

    static var adminDisplayOrder: [CatalogApplicationStatus] {
        [.pending, .approved, .rejected, .hidden]
    }

    var title: String {
        switch self {
        case .pending: "待審批"
        case .approved: "已批准"
        case .rejected: "已拒絕"
        case .hidden: "已下架"
        }
    }
}

struct StylistApplication: Identifiable, Codable, Hashable {
    var id: String
    var submittedBy: UUID?
    var stylistID: String
    var ownerID: UUID?
    var contactEmail: String
    var claimedBy: UUID?
    var claimedAt: String?
    var salonID: String
    var district: String
    var location: String
    var name: String
    var title: String
    var rating: Double
    var reviewsCount: Int
    var languages: String
    var experience: String
    var specialties: [String]
    var avatarURL: String
    var phone: String?
    var instagramURL: String
    var bio: String
    var basePrice: Int
    var servicesPayload: [ServiceItem]
    var worksPayload: [PortfolioWork]
    var status: CatalogApplicationStatus
    var adminNote: String

    enum CodingKeys: String, CodingKey {
        case id
        case submittedBy = "submitted_by"
        case stylistID = "stylist_id"
        case ownerID = "owner_id"
        case contactEmail = "contact_email"
        case claimedBy = "claimed_by"
        case claimedAt = "claimed_at"
        case salonID = "salon_id"
        case district
        case location
        case name
        case title
        case rating
        case reviewsCount = "reviews_count"
        case languages
        case experience
        case specialties
        case avatarURL = "avatar_url"
        case phone
        case instagramURL = "instagram_url"
        case bio
        case basePrice = "base_price"
        case servicesPayload = "services_payload"
        case worksPayload = "works_payload"
        case status
        case adminNote = "admin_note"
    }

    init(id: String, submittedBy: UUID, stylist: Stylist, contactEmail: String = "") {
        self.id = id
        self.submittedBy = submittedBy
        stylistID = stylist.id
        ownerID = submittedBy
        self.contactEmail = contactEmail
        claimedBy = nil
        claimedAt = nil
        salonID = stylist.salonID
        district = stylist.district
        location = stylist.location
        name = stylist.name
        title = stylist.title
        rating = stylist.rating
        reviewsCount = stylist.reviewsCount
        languages = stylist.languages
        experience = stylist.experience
        specialties = stylist.specialties
        avatarURL = stylist.avatarURL
        phone = stylist.phone
        instagramURL = stylist.instagramURL
        bio = stylist.bio
        basePrice = stylist.basePrice
        servicesPayload = stylist.services
        worksPayload = stylist.works
        status = .pending
        adminNote = ""
    }

    func asStylist() -> Stylist {
        Stylist(
            id: stylistID,
            ownerID: ownerID,
            salonID: salonID,
            district: district,
            location: location,
            name: name,
            title: title,
            rating: rating,
            reviewsCount: reviewsCount,
            languages: languages,
            experience: experience,
            specialties: specialties,
            avatarURL: avatarURL,
            phone: phone ?? "",
            instagramURL: instagramURL,
            bio: bio,
            basePrice: basePrice,
            works: worksPayload,
            services: servicesPayload,
            reviews: [],
            isActive: true,
            isFeatured: false,
            displayOrder: 100
        )
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        submittedBy = try container.decodeIfPresent(UUID.self, forKey: .submittedBy)
        stylistID = try container.decode(String.self, forKey: .stylistID)
        ownerID = try container.decodeIfPresent(UUID.self, forKey: .ownerID)
        contactEmail = try container.decodeIfPresent(String.self, forKey: .contactEmail) ?? ""
        claimedBy = try container.decodeIfPresent(UUID.self, forKey: .claimedBy)
        claimedAt = try container.decodeIfPresent(String.self, forKey: .claimedAt)
        salonID = try container.decode(String.self, forKey: .salonID)
        adminNote = try container.decodeIfPresent(String.self, forKey: .adminNote) ?? ""
        location = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
        let decodedDistrict = try container.decodeIfPresent(String.self, forKey: .district) ?? ""
        district = decodedDistrict.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? HairmapDistricts.inferredDistrict(from: "\(location)\n\(adminNote)")
        name = try container.decode(String.self, forKey: .name)
        title = try container.decode(String.self, forKey: .title)
        rating = try container.decode(Double.self, forKey: .rating)
        reviewsCount = try container.decode(Int.self, forKey: .reviewsCount)
        languages = try container.decode(String.self, forKey: .languages)
        experience = try container.decode(String.self, forKey: .experience)
        specialties = try container.decode([String].self, forKey: .specialties)
        avatarURL = try container.decode(String.self, forKey: .avatarURL)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        instagramURL = try container.decodeIfPresent(String.self, forKey: .instagramURL) ?? ""
        bio = try container.decodeIfPresent(String.self, forKey: .bio) ?? ""
        basePrice = try container.decodeIfPresent(Int.self, forKey: .basePrice) ?? 0
        servicesPayload = try container.decodeIfPresent([ServiceItem].self, forKey: .servicesPayload) ?? []
        worksPayload = try container.decodeIfPresent([PortfolioWork].self, forKey: .worksPayload) ?? []
        status = try container.decodeIfPresent(CatalogApplicationStatus.self, forKey: .status) ?? .pending
    }
}

struct SalonApplication: Identifiable, Codable, Hashable {
    var id: String
    var submittedBy: UUID?
    var salonID: String
    var brandName: String
    var branchName: String
    var name: String
    var location: String
    var district: String
    var distance: Double
    var rating: Double
    var tags: [String]
    var openHours: String
    var phone: String
    var instagramURL: String
    var startPrice: Int
    var imageURL: String
    var worksPayload: [PortfolioWork]
    var servicesPayload: [SalonServiceItem]
    var status: CatalogApplicationStatus
    var adminNote: String

    enum CodingKeys: String, CodingKey {
        case id
        case submittedBy = "submitted_by"
        case salonID = "salon_id"
        case brandName = "brand_name"
        case branchName = "branch_name"
        case name
        case location
        case district
        case distance
        case rating
        case tags
        case openHours = "open_hours"
        case phone
        case instagramURL = "instagram_url"
        case startPrice = "start_price"
        case imageURL = "image_url"
        case worksPayload = "works_payload"
        case servicesPayload = "services_payload"
        case status
        case adminNote = "admin_note"
    }

    init(id: String, submittedBy: UUID, salon: Salon, works: [PortfolioWork], services: [SalonServiceItem] = []) {
        self.id = id
        self.submittedBy = submittedBy
        salonID = salon.id
        brandName = salon.name
        branchName = salon.branchName
        name = salon.name
        location = salon.location
        district = salon.district
        distance = salon.distance
        rating = salon.rating
        tags = salon.tags
        openHours = salon.openHours
        phone = salon.phone
        instagramURL = salon.instagramURL
        startPrice = salon.startPrice
        imageURL = salon.imageURL
        worksPayload = works
        servicesPayload = services
        status = .pending
        adminNote = ""
    }

    func asSalon() -> Salon {
        Salon(
            id: salonID,
            brandID: nil,
            branchName: branchName,
            name: name,
            location: location,
            district: district,
            distance: distance,
            rating: rating,
            tags: tags,
            openHours: openHours,
            phone: phone,
            instagramURL: instagramURL,
            startPrice: startPrice,
            imageURL: imageURL,
            isActive: true,
            isFeatured: false,
            displayOrder: 100,
            bookingEnabled: true,
            chatEnabled: true
        )
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        submittedBy = try container.decodeIfPresent(UUID.self, forKey: .submittedBy)
        salonID = try container.decode(String.self, forKey: .salonID)
        brandName = try container.decodeIfPresent(String.self, forKey: .brandName) ?? ""
        branchName = try container.decodeIfPresent(String.self, forKey: .branchName) ?? ""
        name = try container.decode(String.self, forKey: .name)
        location = try container.decode(String.self, forKey: .location)
        adminNote = try container.decodeIfPresent(String.self, forKey: .adminNote) ?? ""
        let decodedDistrict = try container.decodeIfPresent(String.self, forKey: .district) ?? ""
        district = decodedDistrict.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? HairmapDistricts.inferredDistrict(from: "\(location)\n\(adminNote)")
        distance = try container.decode(Double.self, forKey: .distance)
        rating = try container.decode(Double.self, forKey: .rating)
        tags = try container.decode([String].self, forKey: .tags)
        openHours = try container.decode(String.self, forKey: .openHours)
        phone = try container.decode(String.self, forKey: .phone)
        instagramURL = try container.decodeIfPresent(String.self, forKey: .instagramURL) ?? ""
        startPrice = try container.decode(Int.self, forKey: .startPrice)
        imageURL = try container.decode(String.self, forKey: .imageURL)
        worksPayload = try container.decodeIfPresent([PortfolioWork].self, forKey: .worksPayload) ?? []
        servicesPayload = try container.decodeIfPresent([SalonServiceItem].self, forKey: .servicesPayload) ?? []
        status = try container.decodeIfPresent(CatalogApplicationStatus.self, forKey: .status) ?? .pending
    }
}

struct InspirationItem: Identifiable, Codable, Hashable {
    var id: String
    var stylistID: String
    var title: String
    var salonName: String
    var location: String
    var tags: [String]
    var imageURL: String
    var category: String
    var authorID: UUID?
    var authorName: String
    var authorAvatar: String
    var studio: String
    var mediaURLs: [String]
    var mediaKinds: [String]
    var faceShape: String
    var hairType: String
    var specs: String
    var details: String
    var likeCount: Int
    var commentCount: Int
    var shareCount: Int
    var isUserPost: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case stylistID = "stylist_id"
        case title
        case salonName = "salon_name"
        case location
        case tags
        case imageURL = "image_url"
        case category
        case authorID = "author_id"
        case authorName = "author_name"
        case authorAvatar = "author_avatar"
        case studio
        case mediaURLs = "media_urls"
        case mediaKinds = "media_kinds"
        case faceShape = "face_shape"
        case hairType = "hair_type"
        case specs
        case details
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case shareCount = "share_count"
        case isUserPost = "is_user_post"
    }

    init(
        id: String,
        stylistID: String,
        title: String,
        salonName: String,
        location: String,
        tags: [String],
        imageURL: String,
        category: String,
        authorID: UUID? = nil,
        authorName: String = "",
        authorAvatar: String = "",
        studio: String = "",
        mediaURLs: [String] = [],
        mediaKinds: [String] = [],
        faceShape: String = "",
        hairType: String = "",
        specs: String = "",
        details: String = "",
        likeCount: Int = 0,
        commentCount: Int = 0,
        shareCount: Int = 0,
        isUserPost: Bool = false
    ) {
        self.id = id
        self.stylistID = stylistID
        self.title = title
        self.salonName = salonName
        self.location = location
        self.tags = tags
        self.imageURL = imageURL
        self.category = category
        self.authorID = authorID
        self.authorName = authorName
        self.authorAvatar = authorAvatar
        self.studio = studio
        self.mediaURLs = mediaURLs
        self.mediaKinds = mediaKinds
        self.faceShape = faceShape
        self.hairType = hairType
        self.specs = specs
        self.details = details
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.shareCount = shareCount
        self.isUserPost = isUserPost
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        stylistID = try container.decode(String.self, forKey: .stylistID)
        title = try container.decode(String.self, forKey: .title)
        salonName = try container.decode(String.self, forKey: .salonName)
        location = try container.decode(String.self, forKey: .location)
        tags = try container.decode([String].self, forKey: .tags)
        imageURL = try container.decode(String.self, forKey: .imageURL)
        category = try container.decode(String.self, forKey: .category)
        authorID = try container.decodeIfPresent(UUID.self, forKey: .authorID)
        authorName = try container.decodeIfPresent(String.self, forKey: .authorName) ?? ""
        authorAvatar = try container.decodeIfPresent(String.self, forKey: .authorAvatar) ?? ""
        studio = try container.decodeIfPresent(String.self, forKey: .studio) ?? ""
        mediaURLs = try container.decodeIfPresent([String].self, forKey: .mediaURLs) ?? []
        mediaKinds = try container.decodeIfPresent([String].self, forKey: .mediaKinds) ?? []
        faceShape = try container.decodeIfPresent(String.self, forKey: .faceShape) ?? ""
        hairType = try container.decodeIfPresent(String.self, forKey: .hairType) ?? ""
        specs = try container.decodeIfPresent(String.self, forKey: .specs) ?? ""
        details = try container.decodeIfPresent(String.self, forKey: .details) ?? ""
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        commentCount = try container.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0
        shareCount = try container.decodeIfPresent(Int.self, forKey: .shareCount) ?? 0
        isUserPost = try container.decodeIfPresent(Bool.self, forKey: .isUserPost) ?? false
    }
}

enum SharedLookMediaKind: String, Hashable {
    case photo
    case video
}

struct SharedLookMedia: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var imageURL: String?
    var mediaData: Data?
    var mediaKind: SharedLookMediaKind
}

struct SharedHairLook: Identifiable, Hashable {
    var id: String
    var title: String
    var authorID: UUID? = nil
    var author: String
    var authorAvatarURL: String = ""
    var studio: String
    var location: String = "香港"
    var tags: [String]
    var imageURL: String?
    var mediaData: Data?
    var mediaKind: SharedLookMediaKind
    var mediaItems: [SharedLookMedia] = []
    var stylistID: String?
    var faceShape: String
    var hairType: String
    var specs: String
    var details: String
    var likes: Int
    var commentCount: Int = 0
    var shareCount: Int = 0
    var category: String
    var isUserPost: Bool
}

struct LookCommentItem: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var inspirationID: String = ""
    var parentID: String?
    var authorID: UUID?
    var author: String
    var avatarURL: String
    var timeAgo: String
    var text: String
    var likes: Int
    var replies: [LookCommentItem] = []
    var isCreator: Bool = false

    static let seed: [LookCommentItem] = [
        LookCommentItem(
            inspirationID: "seed",
            author: "_crystalfer",
            avatarURL: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=120&q=80",
            timeAgo: "3 小時",
            text: "推推\n最緊要人冇事",
            likes: 5,
            replies: [
                LookCommentItem(
                    inspirationID: "seed",
                    parentID: "seed-parent",
                    author: "3nya_meow",
                    avatarURL: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=120&q=80",
                    timeAgo: "3 小時",
                    text: "但啲真係好好人路，唔順路都送我地返去",
                    likes: 1,
                    isCreator: true
                )
            ]
        ),
        LookCommentItem(
            inspirationID: "seed",
            author: "coolleung114",
            avatarURL: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=120&q=80",
            timeAgo: "3 小時",
            text: "香港男士抵讚\n希望你將人幫你！你再去幫返人嘅心態傳播開去",
            likes: 4
        ),
        LookCommentItem(
            inspirationID: "seed",
            author: "jayfish0402",
            avatarURL: "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=120&q=80",
            timeAgo: "2 小時",
            text: "呢個髮色好靚，想問褪色之後會唔會偏黃？",
            likes: 2
        )
    ]
}

struct Appointment: Identifiable, Codable, Hashable {
    var id: UUID
    var customerID: UUID?
    var stylistID: String?
    var salonID: String
    var salonBrandID: String?
    var serviceID: String?
    var salonName: String
    var stylistName: String
    var clientName: String
    var clientPhone: String
    var bookingDate: String
    var startTime: String
    var endTime: String
    var serviceName: String
    var price: Int
    var status: BookingStatus
    var branchName: String
    var assignmentMode: BookingAssignmentMode
    var assignedStylistID: String?
    var bookingNote: String

    enum CodingKeys: String, CodingKey {
        case id
        case customerID = "customer_id"
        case stylistID = "stylist_id"
        case salonID = "salon_id"
        case salonBrandID = "salon_brand_id"
        case serviceID = "service_id"
        case salonName = "salon_name"
        case stylistName = "stylist_name"
        case clientName = "client_name"
        case clientPhone = "client_phone"
        case bookingDate = "booking_date"
        case startTime = "start_time"
        case endTime = "end_time"
        case serviceName = "service_name"
        case price
        case status
        case branchName = "branch_name"
        case assignmentMode = "assignment_mode"
        case assignedStylistID = "assigned_stylist_id"
        case bookingNote = "booking_note"
    }

    init(
        id: UUID,
        customerID: UUID?,
        stylistID: String?,
        salonID: String,
        salonBrandID: String? = nil,
        serviceID: String?,
        salonName: String,
        stylistName: String,
        clientName: String,
        clientPhone: String,
        bookingDate: String,
        startTime: String,
        endTime: String,
        serviceName: String,
        price: Int,
        status: BookingStatus,
        branchName: String = "",
        assignmentMode: BookingAssignmentMode = .stylistSelected,
        assignedStylistID: String? = nil,
        bookingNote: String = ""
    ) {
        self.id = id
        self.customerID = customerID
        self.stylistID = stylistID
        self.salonID = salonID
        self.salonBrandID = salonBrandID
        self.serviceID = serviceID
        self.salonName = salonName
        self.stylistName = stylistName
        self.clientName = clientName
        self.clientPhone = clientPhone
        self.bookingDate = bookingDate
        self.startTime = startTime
        self.endTime = endTime
        self.serviceName = serviceName
        self.price = price
        self.status = status
        self.branchName = branchName
        self.assignmentMode = assignmentMode
        self.assignedStylistID = assignedStylistID
        self.bookingNote = bookingNote
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        customerID = try container.decodeIfPresent(UUID.self, forKey: .customerID)
        stylistID = try container.decodeIfPresent(String.self, forKey: .stylistID)
        salonID = try container.decode(String.self, forKey: .salonID)
        salonBrandID = try container.decodeIfPresent(String.self, forKey: .salonBrandID)
        serviceID = try container.decodeIfPresent(String.self, forKey: .serviceID)
        salonName = try container.decode(String.self, forKey: .salonName)
        stylistName = try container.decode(String.self, forKey: .stylistName)
        clientName = try container.decode(String.self, forKey: .clientName)
        clientPhone = try container.decode(String.self, forKey: .clientPhone)
        bookingDate = try container.decode(String.self, forKey: .bookingDate)
        startTime = try container.decode(String.self, forKey: .startTime)
        endTime = try container.decode(String.self, forKey: .endTime)
        serviceName = try container.decode(String.self, forKey: .serviceName)
        price = try container.decode(Int.self, forKey: .price)
        status = try container.decodeIfPresent(BookingStatus.self, forKey: .status) ?? .pending
        branchName = try container.decodeIfPresent(String.self, forKey: .branchName) ?? ""
        assignmentMode = try container.decodeIfPresent(BookingAssignmentMode.self, forKey: .assignmentMode) ?? .stylistSelected
        assignedStylistID = try container.decodeIfPresent(String.self, forKey: .assignedStylistID)
        bookingNote = try container.decodeIfPresent(String.self, forKey: .bookingNote) ?? ""
    }

    var timeSlot: String { "\(startTime) - \(endTime)" }

    var effectiveStylistID: String? { assignedStylistID ?? stylistID }

    var isSalonAssignedBooking: Bool { assignmentMode == .salonAssigns }
}

struct ChatMessageItem: Identifiable, Codable, Hashable {
    var id: String
    var customerID: UUID?
    var stylistID: String
    var senderRole: UserRole
    var senderName: String
    var text: String
    var sentAt: String
    var createdAt: String? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case customerID = "customer_id"
        case stylistID = "stylist_id"
        case senderRole = "sender_role"
        case senderName = "sender_name"
        case text
        case sentAt = "sent_at"
        case createdAt = "created_at"
    }

    static let photoPrefix = "hairmap-photo::"

    var photoURL: String? {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.hasPrefix(Self.photoPrefix) else { return nil }
        return String(clean.dropFirst(Self.photoPrefix.count)).trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    var displayText: String {
        photoURL == nil ? text : "已分享髮型參考照片"
    }

    var displayTime: String {
        if let date = chronologicalDate, createdAt != nil {
            return DateFormatter.hmTime.string(from: date)
        }
        return sentAt
    }

    var chronologicalDate: Date? {
        if let createdAt,
           let date = Self.iso8601.date(from: createdAt) ?? Self.fractionalISO8601.date(from: createdAt) {
            return date
        }
        if let date = Self.iso8601.date(from: sentAt) ?? Self.fractionalISO8601.date(from: sentAt) {
            return date
        }
        if let timeOnly = DateFormatter.hmTime.date(from: sentAt.hmTimeKey) {
            let now = Date()
            let calendar = Calendar.hairmap
            let timeParts = calendar.dateComponents([.hour, .minute], from: timeOnly)
            var dayParts = calendar.dateComponents([.year, .month, .day], from: now)
            dayParts.hour = timeParts.hour
            dayParts.minute = timeParts.minute
            return calendar.date(from: dayParts)
        }
        return nil
    }

    var sortKey: TimeInterval {
        chronologicalDate?.timeIntervalSince1970 ?? 0
    }

    static func photoMessageText(url: String) -> String {
        "\(photoPrefix)\(url)"
    }

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let fractionalISO8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

struct BlockedSlot: Identifiable, Codable, Hashable {
    var id: UUID
    var stylistID: String
    var workDate: String
    var startTime: String

    enum CodingKeys: String, CodingKey {
        case id
        case stylistID = "stylist_id"
        case workDate = "work_date"
        case startTime = "start_time"
    }
}

struct SalonChatMessageItem: Identifiable, Codable, Hashable {
    var id: String
    var threadID: UUID
    var customerID: UUID
    var salonID: String
    var salonBrandID: String?
    var senderRole: SalonChatSenderRole
    var senderName: String
    var text: String
    var sentAt: String
    var createdAt: String? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case threadID = "thread_id"
        case customerID = "customer_id"
        case salonID = "salon_id"
        case salonBrandID = "salon_brand_id"
        case senderRole = "sender_role"
        case senderName = "sender_name"
        case text
        case sentAt = "sent_at"
        case createdAt = "created_at"
    }

    var displayText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var displayTime: String {
        if let date = chronologicalDate, createdAt != nil {
            return DateFormatter.hmTime.string(from: date)
        }
        return sentAt
    }

    var chronologicalDate: Date? {
        if let createdAt,
           let date = Self.iso8601.date(from: createdAt) ?? Self.fractionalISO8601.date(from: createdAt) {
            return date
        }
        if let date = Self.iso8601.date(from: sentAt) ?? Self.fractionalISO8601.date(from: sentAt) {
            return date
        }
        if let timeOnly = DateFormatter.hmTime.date(from: sentAt.hmTimeKey) {
            let now = Date()
            let calendar = Calendar.hairmap
            let timeParts = calendar.dateComponents([.hour, .minute], from: timeOnly)
            var dayParts = calendar.dateComponents([.year, .month, .day], from: now)
            dayParts.hour = timeParts.hour
            dayParts.minute = timeParts.minute
            return calendar.date(from: dayParts)
        }
        return nil
    }

    var sortKey: TimeInterval {
        chronologicalDate?.timeIntervalSince1970 ?? 0
    }

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let fractionalISO8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

struct RankingOverride: Identifiable, Codable, Hashable {
    var id: UUID
    var rankingKey: String
    var itemType: String
    var itemID: String
    var manualRank: Int?
    var scoreOverride: Double?
    var isPinned: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case rankingKey = "ranking_key"
        case itemType = "item_type"
        case itemID = "item_id"
        case manualRank = "manual_rank"
        case scoreOverride = "score_override"
        case isPinned = "is_pinned"
    }
}

struct CatalogPayload {
    var salonBrands: [SalonBrand] = []
    var salons: [Salon]
    var stylists: [Stylist]
    var inspiration: [InspirationItem]
    var profiles: [HairmapProfile] = []
    var bookings: [Appointment]
    var messages: [ChatMessageItem]
    var salonMessages: [SalonChatMessageItem] = []
    var blockedSlots: [BlockedSlot]
    var salonServices: [String: [SalonServiceItem]] = [:]
    var salonWorks: [String: [PortfolioWork]] = [:]
    var rankingOverrides: [RankingOverride] = []
    var stylistApplications: [StylistApplication] = []
    var salonApplications: [SalonApplication] = []
    var inspirationComments: [String: [LookCommentItem]] = [:]
    var likedLookIDs: Set<String> = []
    var likedCommentIDs: Set<String> = []
    var blockedChatStylistIDs: Set<String> = []
    var blockedUserIDs: Set<UUID> = []
    var readMessageIDs: Set<String> = []
}
