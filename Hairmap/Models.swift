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

struct HairmapProfile: Identifiable, Codable, Hashable {
    var id: UUID
    var displayName: String
    var email: String
    var role: UserRole
    var stylistID: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case email
        case role
        case stylistID = "stylist_id"
    }
}

struct Salon: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var location: String
    var distance: Double
    var rating: Double
    var tags: [String]
    var openHours: String
    var phone: String
    var startPrice: Int
    var imageURL: String
    var isActive: Bool = true
    var isFeatured: Bool = false
    var displayOrder: Int = 100

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case location
        case distance
        case rating
        case tags
        case openHours = "open_hours"
        case phone
        case startPrice = "start_price"
        case imageURL = "image_url"
        case isActive = "is_active"
        case isFeatured = "is_featured"
        case displayOrder = "display_order"
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

struct PortfolioWork: Identifiable, Codable, Hashable {
    var id: String
    var stylistID: String
    var title: String
    var imageURL: String

    enum CodingKeys: String, CodingKey {
        case id
        case stylistID = "stylist_id"
        case title
        case imageURL = "image_url"
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
    var name: String
    var title: String
    var rating: Double
    var reviewsCount: Int
    var languages: String
    var experience: String
    var specialties: [String]
    var avatarURL: String
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
        case name
        case title
        case rating
        case reviewsCount = "reviews_count"
        case languages
        case experience
        case specialties
        case avatarURL = "avatar_url"
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
        name: String,
        title: String,
        rating: Double,
        reviewsCount: Int,
        languages: String,
        experience: String,
        specialties: [String],
        avatarURL: String,
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
        self.name = name
        self.title = title
        self.rating = rating
        self.reviewsCount = reviewsCount
        self.languages = languages
        self.experience = experience
        self.specialties = specialties
        self.avatarURL = avatarURL
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
        name = try container.decode(String.self, forKey: .name)
        title = try container.decode(String.self, forKey: .title)
        rating = try container.decode(Double.self, forKey: .rating)
        reviewsCount = try container.decode(Int.self, forKey: .reviewsCount)
        languages = try container.decode(String.self, forKey: .languages)
        experience = try container.decode(String.self, forKey: .experience)
        specialties = try container.decode([String].self, forKey: .specialties)
        avatarURL = try container.decode(String.self, forKey: .avatarURL)
        bio = try container.decodeIfPresent(String.self, forKey: .bio) ?? ""
        basePrice = try container.decodeIfPresent(Int.self, forKey: .basePrice) ?? 0
        works = []
        services = []
        reviews = []
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        isFeatured = try container.decodeIfPresent(Bool.self, forKey: .isFeatured) ?? false
        displayOrder = try container.decodeIfPresent(Int.self, forKey: .displayOrder) ?? 100
    }
}

enum CatalogApplicationStatus: String, Codable, Hashable {
    case pending
    case approved
    case rejected

    var title: String {
        switch self {
        case .pending: "待審批"
        case .approved: "已批准"
        case .rejected: "已拒絕"
        }
    }
}

struct StylistApplication: Identifiable, Codable, Hashable {
    var id: String
    var submittedBy: UUID
    var stylistID: String
    var ownerID: UUID
    var salonID: String
    var name: String
    var title: String
    var rating: Double
    var reviewsCount: Int
    var languages: String
    var experience: String
    var specialties: [String]
    var avatarURL: String
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
        case salonID = "salon_id"
        case name
        case title
        case rating
        case reviewsCount = "reviews_count"
        case languages
        case experience
        case specialties
        case avatarURL = "avatar_url"
        case bio
        case basePrice = "base_price"
        case servicesPayload = "services_payload"
        case worksPayload = "works_payload"
        case status
        case adminNote = "admin_note"
    }

    init(id: String, submittedBy: UUID, stylist: Stylist) {
        self.id = id
        self.submittedBy = submittedBy
        stylistID = stylist.id
        ownerID = submittedBy
        salonID = stylist.salonID
        name = stylist.name
        title = stylist.title
        rating = stylist.rating
        reviewsCount = stylist.reviewsCount
        languages = stylist.languages
        experience = stylist.experience
        specialties = stylist.specialties
        avatarURL = stylist.avatarURL
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
            name: name,
            title: title,
            rating: rating,
            reviewsCount: reviewsCount,
            languages: languages,
            experience: experience,
            specialties: specialties,
            avatarURL: avatarURL,
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
}

struct SalonApplication: Identifiable, Codable, Hashable {
    var id: String
    var submittedBy: UUID
    var salonID: String
    var name: String
    var location: String
    var distance: Double
    var rating: Double
    var tags: [String]
    var openHours: String
    var phone: String
    var startPrice: Int
    var imageURL: String
    var worksPayload: [PortfolioWork]
    var status: CatalogApplicationStatus
    var adminNote: String

    enum CodingKeys: String, CodingKey {
        case id
        case submittedBy = "submitted_by"
        case salonID = "salon_id"
        case name
        case location
        case distance
        case rating
        case tags
        case openHours = "open_hours"
        case phone
        case startPrice = "start_price"
        case imageURL = "image_url"
        case worksPayload = "works_payload"
        case status
        case adminNote = "admin_note"
    }

    init(id: String, submittedBy: UUID, salon: Salon, works: [PortfolioWork]) {
        self.id = id
        self.submittedBy = submittedBy
        salonID = salon.id
        name = salon.name
        location = salon.location
        distance = salon.distance
        rating = salon.rating
        tags = salon.tags
        openHours = salon.openHours
        phone = salon.phone
        startPrice = salon.startPrice
        imageURL = salon.imageURL
        worksPayload = works
        status = .pending
        adminNote = ""
    }

    func asSalon() -> Salon {
        Salon(
            id: salonID,
            name: name,
            location: location,
            distance: distance,
            rating: rating,
            tags: tags,
            openHours: openHours,
            phone: phone,
            startPrice: startPrice,
            imageURL: imageURL,
            isActive: true,
            isFeatured: false,
            displayOrder: 100
        )
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
    var author: String
    var studio: String
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
    var stylistID: String
    var salonID: String
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

    enum CodingKeys: String, CodingKey {
        case id
        case customerID = "customer_id"
        case stylistID = "stylist_id"
        case salonID = "salon_id"
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
    }

    var timeSlot: String { "\(startTime) - \(endTime)" }
}

struct ChatMessageItem: Identifiable, Codable, Hashable {
    var id: String
    var customerID: UUID?
    var stylistID: String
    var senderRole: UserRole
    var senderName: String
    var text: String
    var sentAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case customerID = "customer_id"
        case stylistID = "stylist_id"
        case senderRole = "sender_role"
        case senderName = "sender_name"
        case text
        case sentAt = "sent_at"
    }
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
    var salons: [Salon]
    var stylists: [Stylist]
    var inspiration: [InspirationItem]
    var bookings: [Appointment]
    var messages: [ChatMessageItem]
    var blockedSlots: [BlockedSlot]
    var salonWorks: [String: [PortfolioWork]] = [:]
    var rankingOverrides: [RankingOverride] = []
    var stylistApplications: [StylistApplication] = []
    var salonApplications: [SalonApplication] = []
    var inspirationComments: [String: [LookCommentItem]] = [:]
    var likedLookIDs: Set<String> = []
    var likedCommentIDs: Set<String> = []
    var blockedChatStylistIDs: Set<String> = []
}
