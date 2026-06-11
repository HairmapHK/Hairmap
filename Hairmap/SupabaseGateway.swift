import Foundation
import Storage
import Supabase

struct SupabaseSettings {
    let url: URL
    let publishableKey: String
    let redirectURL: URL

    nonisolated static func load() -> SupabaseSettings? {
        let info = Bundle.main.infoDictionary ?? [:]
        let urlString = (
            info["SUPABASE_URL"] as? String
            ?? ProcessInfo.processInfo.environment["SUPABASE_URL"]
            ?? ""
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        let key = (
            info["SUPABASE_PUBLISHABLE_KEY"] as? String
            ?? ProcessInfo.processInfo.environment["SUPABASE_PUBLISHABLE_KEY"]
            ?? ""
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        let redirect = (
            info["SUPABASE_REDIRECT_URL"] as? String
            ?? ProcessInfo.processInfo.environment["SUPABASE_REDIRECT_URL"]
            ?? "hairmap://auth-callback"
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            !urlString.isEmpty,
            !key.isEmpty,
            let url = URL(string: urlString),
            let redirectURL = URL(string: redirect)
        else {
            return nil
        }

        return SupabaseSettings(url: url, publishableKey: key, redirectURL: redirectURL)
    }
}

@MainActor
final class SupabaseGateway {
    private static let mediaBucket = "hairmap-media"

    private let settings: SupabaseSettings?
    private let client: SupabaseClient?

    private struct SalonPortfolioRow: Codable {
        var id: String
        var salonID: String
        var title: String
        var imageURL: String

        enum CodingKeys: String, CodingKey {
            case id
            case salonID = "salon_id"
            case title
            case imageURL = "image_url"
        }

        init(work: PortfolioWork) {
            id = work.id
            salonID = work.stylistID
            title = work.title
            imageURL = work.imageURL
        }

        func asPortfolioWork() -> PortfolioWork {
            PortfolioWork(id: id, stylistID: salonID, title: title, imageURL: imageURL)
        }
    }

    private struct InspirationCommentRow: Codable {
        var id: String
        var inspirationID: String
        var parentID: String?
        var authorID: UUID?
        var authorName: String
        var authorAvatar: String
        var body: String
        var likeCount: Int
        var isCreator: Bool

        enum CodingKeys: String, CodingKey {
            case id
            case inspirationID = "inspiration_id"
            case parentID = "parent_id"
            case authorID = "author_id"
            case authorName = "author_name"
            case authorAvatar = "author_avatar"
            case body
            case likeCount = "like_count"
            case isCreator = "is_creator"
        }

        init(comment: LookCommentItem, authorID: UUID, inspirationID: String, parentID: String?) {
            id = comment.id
            self.inspirationID = inspirationID
            self.parentID = parentID
            self.authorID = authorID
            authorName = comment.author
            authorAvatar = comment.avatarURL
            body = comment.text
            likeCount = comment.likes
            isCreator = comment.isCreator
        }

        func asComment() -> LookCommentItem {
            LookCommentItem(
                id: id,
                inspirationID: inspirationID,
                parentID: parentID,
                authorID: authorID,
                author: authorName,
                avatarURL: authorAvatar.isEmpty ? "https://images.unsplash.com/photo-1527980965255-d3b416303d12?auto=format&fit=crop&w=120&q=80" : authorAvatar,
                timeAgo: "剛剛",
                text: body,
                likes: likeCount,
                replies: [],
                isCreator: isCreator
            )
        }
    }

    private struct InspirationReactionRow: Codable {
        var inspirationID: String

        enum CodingKeys: String, CodingKey {
            case inspirationID = "inspiration_id"
        }
    }

    private struct CommentReactionRow: Codable {
        var commentID: String

        enum CodingKeys: String, CodingKey {
            case commentID = "comment_id"
        }
    }

    private struct ConversationBlockRow: Codable {
        var customerID: UUID
        var stylistID: String

        enum CodingKeys: String, CodingKey {
            case customerID = "customer_id"
            case stylistID = "stylist_id"
        }
    }

    private struct ApplicationReviewPayload: Encodable {
        let status: String
        let reviewedBy: UUID
        let reviewedAt: String

        enum CodingKeys: String, CodingKey {
            case status
            case reviewedBy = "reviewed_by"
            case reviewedAt = "reviewed_at"
        }
    }

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    var isConfigured: Bool { client != nil }

    init(settings: SupabaseSettings? = .load()) {
        self.settings = settings
        if let settings {
            client = SupabaseClient(
                supabaseURL: settings.url,
                supabaseKey: settings.publishableKey,
                options: SupabaseClientOptions(
                    auth: .init(
                        redirectToURL: settings.redirectURL,
                        flowType: .pkce,
                        emitLocalSessionAsInitialSession: true
                    )
                )
            )
        } else {
            client = nil
        }
    }

    func handle(url: URL) {
        client?.auth.handle(url)
    }

    func session(from url: URL) async throws -> Session? {
        guard let client else { return nil }
        return try await client.auth.session(from: url)
    }

    func authStateChanges() -> AsyncStream<(event: AuthChangeEvent, session: Session?)>? {
        guard let client else { return nil }
        return client.auth.authStateChanges
    }

    func currentSession() async throws -> Session? {
        guard let client else { return nil }
        return try? await client.auth.session
    }

    func sendMagicLink(email: String, displayName: String, role: UserRole) async throws {
        guard let client, let settings else { return }
        try await client.auth.signInWithOTP(
            email: email,
            redirectTo: settings.redirectURL,
            shouldCreateUser: true,
            data: [
                "display_name": .string(displayName),
                "role": .string(role.rawValue),
                "stylist_id": .string(role == .stylist ? "master-leo" : "")
            ]
        )
    }

    func signUp(email: String, password: String, displayName: String, role: UserRole) async throws -> AuthResponse? {
        guard let client, let settings else { return nil }
        return try await client.auth.signUp(
            email: email,
            password: password,
            data: [
                "display_name": .string(displayName),
                "role": .string(role.rawValue),
                "stylist_id": .string(role == .stylist ? "master-leo" : "")
            ],
            redirectTo: settings.redirectURL
        )
    }

    func signIn(email: String, password: String) async throws -> Session? {
        guard let client else { return nil }
        return try await client.auth.signIn(email: email, password: password)
    }

    func signInWithOAuth(provider: Provider) async throws -> Session? {
        guard let client, let settings else { return nil }
        return try await client.auth.signInWithOAuth(
            provider: provider,
            redirectTo: settings.redirectURL
        )
    }

    func resetPassword(email: String) async throws {
        guard let client, let settings else { return }
        try await client.auth.resetPasswordForEmail(email, redirectTo: settings.redirectURL)
    }

    func updatePassword(_ password: String) async throws {
        guard let client else { return }
        try await client.auth.update(user: UserAttributes(password: password))
    }

    func signOut() async {
        guard let client else { return }
        try? await client.auth.signOut()
    }

    func upsertProfile(_ profile: HairmapProfile) async throws {
        guard let client else { return }
        try await client.from("profiles")
            .upsert(profile, onConflict: "id")
            .execute()
    }

    func currentAdminRole() async throws -> String? {
        guard let client else { return nil }
        let session = try await client.auth.session
        struct AdminRow: Decodable { let role: String }
        let rows: [AdminRow] = try await client.from("admin_users")
            .select("role")
            .eq("user_id", value: session.user.id.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first?.role
    }

    func loadCatalog() async throws -> CatalogPayload {
        guard let client else { return SeedData.catalog }

        let salons: [Salon] = try await client.from("salons")
            .select()
            .eq("is_active", value: true)
            .order("display_order", ascending: true)
            .order("rating", ascending: false)
            .execute()
            .value

        let stylistRows: [Stylist] = try await client.from("stylists")
            .select()
            .eq("is_active", value: true)
            .order("display_order", ascending: true)
            .order("rating", ascending: false)
            .execute()
            .value

        let services: [ServiceItem] = try await client.from("services")
            .select()
            .eq("is_active", value: true)
            .order("display_order", ascending: true)
            .order("price", ascending: true)
            .execute()
            .value

        let works: [PortfolioWork] = try await client.from("portfolio_works")
            .select()
            .eq("is_active", value: true)
            .order("display_order", ascending: true)
            .execute()
            .value

        let salonWorkRows: [SalonPortfolioRow] = (try? await client.from("salon_portfolio_works")
            .select()
            .eq("is_active", value: true)
            .order("display_order", ascending: true)
            .execute()
            .value) ?? []

        let reviews: [ReviewItem] = try await client.from("reviews")
            .select()
            .eq("is_hidden", value: false)
            .order("created_at", ascending: false)
            .execute()
            .value

        let inspiration: [InspirationItem] = try await client.from("inspiration_items")
            .select()
            .eq("is_active", value: true)
            .order("display_order", ascending: true)
            .order("created_at", ascending: false)
            .execute()
            .value

        let commentRows: [InspirationCommentRow] = (try? await client.from("inspiration_comments")
            .select()
            .eq("is_hidden", value: false)
            .order("created_at", ascending: false)
            .execute()
            .value) ?? []

        let rankingOverrides: [RankingOverride] = (try? await client.from("ranking_overrides")
            .select()
            .eq("is_active", value: true)
            .order("manual_rank", ascending: true)
            .execute()
            .value) ?? []

        let stylistApplications: [StylistApplication] = (try? await client.from("stylist_applications")
            .select()
            .eq("status", value: CatalogApplicationStatus.pending.rawValue)
            .order("created_at", ascending: false)
            .execute()
            .value) ?? []

        let salonApplications: [SalonApplication] = (try? await client.from("salon_applications")
            .select()
            .eq("status", value: CatalogApplicationStatus.pending.rawValue)
            .order("created_at", ascending: false)
            .execute()
            .value) ?? []

        let session = try? await client.auth.session
        let likedLooks: [InspirationReactionRow]
        let likedComments: [CommentReactionRow]
        let blockedConversations: [ConversationBlockRow]
        if let session {
            likedLooks = (try? await client.from("inspiration_reactions")
                .select("inspiration_id")
                .eq("user_id", value: session.user.id.uuidString)
                .eq("reaction_type", value: "like")
                .execute()
                .value) ?? []
            likedComments = (try? await client.from("inspiration_comment_reactions")
                .select("comment_id")
                .eq("user_id", value: session.user.id.uuidString)
                .eq("reaction_type", value: "like")
                .execute()
                .value) ?? []
            blockedConversations = (try? await client.from("conversation_blocks")
                .select("customer_id,stylist_id")
                .eq("customer_id", value: session.user.id.uuidString)
                .execute()
                .value) ?? []
        } else {
            likedLooks = []
            likedComments = []
            blockedConversations = []
        }

        let bookings: [Appointment] = (try? await client.from("bookings")
            .select()
            .order("booking_date", ascending: true)
            .execute()
            .value) ?? []

        let messages: [ChatMessageItem] = (try? await client.from("messages")
            .select()
            .order("sent_at", ascending: true)
            .execute()
            .value) ?? []

        let blockedSlots: [BlockedSlot] = try await client.from("blocked_slots")
            .select()
            .execute()
            .value

        let stylists = stylistRows.map { stylist in
            var hydrated = stylist
            hydrated.services = services.filter { $0.stylistID == stylist.id }
            hydrated.works = works.filter { $0.stylistID == stylist.id }
            hydrated.reviews = reviews.filter { $0.stylistID == stylist.id }
            return hydrated
        }

        let salonWorks = Dictionary(grouping: salonWorkRows.map { $0.asPortfolioWork() }, by: \.stylistID)

        return CatalogPayload(
            salons: salons.isEmpty ? SeedData.salons : salons,
            stylists: stylists.isEmpty ? SeedData.stylists : stylists,
            inspiration: inspiration.isEmpty ? SeedData.inspiration : inspiration,
            bookings: bookings,
            messages: messages.isEmpty ? SeedData.messages : messages,
            blockedSlots: blockedSlots,
            salonWorks: salonWorks,
            rankingOverrides: rankingOverrides,
            stylistApplications: stylistApplications,
            salonApplications: salonApplications,
            inspirationComments: threadComments(commentRows),
            likedLookIDs: Set(likedLooks.map(\.inspirationID)),
            likedCommentIDs: Set(likedComments.map(\.commentID)),
            blockedChatStylistIDs: Set(blockedConversations.map(\.stylistID))
        )
    }

    private func threadComments(_ rows: [InspirationCommentRow]) -> [String: [LookCommentItem]] {
        let groupedByParent = Dictionary(grouping: rows, by: { $0.parentID ?? "" })

        func buildChildren(parentID: String) -> [LookCommentItem] {
            (groupedByParent[parentID] ?? []).map { row in
                var comment = row.asComment()
                comment.replies = buildChildren(parentID: row.id)
                return comment
            }
        }

        var result: [String: [LookCommentItem]] = [:]
        for row in groupedByParent[""] ?? [] {
            var comment = row.asComment()
            comment.replies = buildChildren(parentID: row.id)
            result[row.inspirationID, default: []].append(comment)
        }
        return result
    }

    func uploadMedia(data: Data, folder: String, mediaKind: SharedLookMediaKind) async throws -> String? {
        guard let client else { return nil }
        let session = try await client.auth.session
        let safeFolder = folder
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "-")
        let fileExtension = mediaKind == .video ? "mov" : "jpg"
        let contentType = mediaKind == .video ? "video/quicktime" : "image/jpeg"
        let path = "uploads/\(session.user.id.uuidString)/\(safeFolder)/\(UUID().uuidString).\(fileExtension)"

        try await client.storage
            .from(Self.mediaBucket)
            .upload(
                path,
                data: data,
                options: FileOptions(contentType: contentType)
            )

        return try client.storage
            .from(Self.mediaBucket)
            .getPublicURL(path: path)
            .absoluteString
    }

    func createReview(_ review: ReviewItem, reviewerID: UUID, reviewPhotoURL: String?) async throws {
        guard let client else { return }
        struct Payload: Encodable {
            let id: String
            let stylistID: String
            let reviewerID: UUID
            let reviewerName: String
            let reviewerAvatar: String
            let text: String
            let stars: Int
            let timeAgo: String
            let reviewPhotoURL: String?
            let isHidden: Bool
            let moderationStatus: String

            enum CodingKeys: String, CodingKey {
                case id
                case stylistID = "stylist_id"
                case reviewerID = "reviewer_id"
                case reviewerName = "reviewer_name"
                case reviewerAvatar = "reviewer_avatar"
                case text
                case stars
                case timeAgo = "time_ago"
                case reviewPhotoURL = "review_photo_url"
                case isHidden = "is_hidden"
                case moderationStatus = "moderation_status"
            }
        }

        let payload = Payload(
            id: review.id,
            stylistID: review.stylistID,
            reviewerID: reviewerID,
            reviewerName: review.reviewerName,
            reviewerAvatar: review.reviewerAvatar,
            text: review.text,
            stars: review.stars,
            timeAgo: review.timeAgo,
            reviewPhotoURL: reviewPhotoURL,
            isHidden: false,
            moderationStatus: "approved"
        )

        try await client.from("reviews")
            .insert(payload)
            .execute()
    }

    func createInspirationPost(_ look: SharedHairLook, authorID: UUID, mediaURLs: [String], mediaKinds: [SharedLookMediaKind]) async throws {
        guard let client else { return }
        guard let primaryURL = mediaURLs.first ?? look.imageURL else { return }

        struct Payload: Encodable {
            let id: String
            let stylistID: String
            let title: String
            let salonName: String
            let location: String
            let tags: [String]
            let imageURL: String
            let category: String
            let authorID: UUID
            let authorName: String
            let studio: String
            let mediaURLs: [String]
            let mediaKinds: [String]
            let faceShape: String
            let hairType: String
            let specs: String
            let details: String
            let likeCount: Int
            let commentCount: Int
            let shareCount: Int
            let isUserPost: Bool
            let isActive: Bool

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
                case isActive = "is_active"
            }
        }

        let payload = Payload(
            id: look.id,
            stylistID: look.stylistID ?? "master-leo",
            title: look.title,
            salonName: look.studio,
            location: "香港",
            tags: look.tags,
            imageURL: primaryURL,
            category: look.category,
            authorID: authorID,
            authorName: look.author,
            studio: look.studio,
            mediaURLs: mediaURLs.isEmpty ? [primaryURL] : mediaURLs,
            mediaKinds: mediaKinds.map(\.rawValue),
            faceShape: look.faceShape,
            hairType: look.hairType,
            specs: look.specs,
            details: look.details,
            likeCount: look.likes,
            commentCount: 0,
            shareCount: 0,
            isUserPost: true,
            isActive: true
        )

        try await client.from("inspiration_items")
            .insert(payload)
            .execute()
    }

    func addInspirationComment(_ comment: LookCommentItem, inspirationID: String, parentID: String?) async throws {
        guard let client else { return }
        let session = try await client.auth.session
        let payload = InspirationCommentRow(
            comment: comment,
            authorID: session.user.id,
            inspirationID: inspirationID,
            parentID: parentID
        )
        try await client.from("inspiration_comments")
            .insert(payload)
            .execute()
    }

    func toggleInspirationLike(inspirationID: String, isLiked: Bool) async throws {
        guard let client else { return }
        let session = try await client.auth.session
        struct Payload: Encodable {
            let inspirationID: String
            let userID: UUID
            let reactionType: String

            enum CodingKeys: String, CodingKey {
                case inspirationID = "inspiration_id"
                case userID = "user_id"
                case reactionType = "reaction_type"
            }
        }

        if isLiked {
            try await client.from("inspiration_reactions")
                .upsert(
                    Payload(inspirationID: inspirationID, userID: session.user.id, reactionType: "like"),
                    onConflict: "inspiration_id,user_id,reaction_type"
                )
                .execute()
        } else {
            try await client.from("inspiration_reactions")
                .delete()
                .eq("inspiration_id", value: inspirationID)
                .eq("user_id", value: session.user.id.uuidString)
                .eq("reaction_type", value: "like")
                .execute()
        }
    }

    func toggleInspirationCommentLike(commentID: String, isLiked: Bool) async throws {
        guard let client else { return }
        let session = try await client.auth.session
        struct Payload: Encodable {
            let commentID: String
            let userID: UUID
            let reactionType: String

            enum CodingKeys: String, CodingKey {
                case commentID = "comment_id"
                case userID = "user_id"
                case reactionType = "reaction_type"
            }
        }

        if isLiked {
            try await client.from("inspiration_comment_reactions")
                .upsert(
                    Payload(commentID: commentID, userID: session.user.id, reactionType: "like"),
                    onConflict: "comment_id,user_id,reaction_type"
                )
                .execute()
        } else {
            try await client.from("inspiration_comment_reactions")
                .delete()
                .eq("comment_id", value: commentID)
                .eq("user_id", value: session.user.id.uuidString)
                .eq("reaction_type", value: "like")
                .execute()
        }
    }

    func recordInspirationShare(inspirationID: String) async throws {
        guard let client else { return }
        struct Payload: Encodable {
            let inspirationID: String
            let userID: UUID?

            enum CodingKeys: String, CodingKey {
                case inspirationID = "inspiration_id"
                case userID = "user_id"
            }
        }
        let session = try? await client.auth.session
        try await client.from("inspiration_shares")
            .insert(Payload(inspirationID: inspirationID, userID: session?.user.id))
            .execute()
    }

    func updateProfileDisplayName(_ displayName: String) async throws {
        guard let client else { return }
        let session = try await client.auth.session
        struct Payload: Encodable {
            let displayName: String

            enum CodingKeys: String, CodingKey {
                case displayName = "display_name"
            }
        }
        try await client.from("profiles")
            .update(Payload(displayName: displayName))
            .eq("id", value: session.user.id.uuidString)
            .execute()
    }

    func createBooking(_ booking: Appointment) async throws {
        guard let client else { return }
        try await client.from("bookings")
            .insert(booking)
            .execute()
    }

    func updateBookingStatus(id: UUID, status: BookingStatus) async throws {
        guard let client else { return }
        struct Payload: Encodable { let status: BookingStatus }
        try await client.from("bookings")
            .update(Payload(status: status))
            .eq("id", value: id.uuidString)
            .execute()
    }

    func saveStylist(_ stylist: Stylist) async throws {
        guard let client else { return }
        try await client.from("stylists")
            .upsert(stylist, onConflict: "id")
            .execute()

        try await client.from("services")
            .delete()
            .eq("stylist_id", value: stylist.id)
            .execute()
        if !stylist.services.isEmpty {
            try await client.from("services")
                .insert(stylist.services)
                .execute()
        }

        try await client.from("portfolio_works")
            .delete()
            .eq("stylist_id", value: stylist.id)
            .execute()
        if !stylist.works.isEmpty {
            try await client.from("portfolio_works")
                .insert(stylist.works)
                .execute()
        }
    }

    func saveSalon(_ salon: Salon, works: [PortfolioWork]) async throws {
        guard let client else { return }
        try await client.from("salons")
            .upsert(salon, onConflict: "id")
            .execute()

        try await client.from("salon_portfolio_works")
            .delete()
            .eq("salon_id", value: salon.id)
            .execute()

        let rows = works.map { work in
            SalonPortfolioRow(
                work: PortfolioWork(
                    id: work.id,
                    stylistID: salon.id,
                    title: work.title,
                    imageURL: work.imageURL
                )
            )
        }
        if !rows.isEmpty {
            try await client.from("salon_portfolio_works")
                .insert(rows)
                .execute()
        }
    }

    func submitStylistApplication(_ stylist: Stylist) async throws {
        guard let client else { return }
        let session = try await client.auth.session
        let application = StylistApplication(
            id: "stylist-application-\(stylist.id)",
            submittedBy: session.user.id,
            stylist: stylist
        )
        try await client.from("stylist_applications")
            .upsert(application, onConflict: "id")
            .execute()
    }

    func submitSalonApplication(_ salon: Salon, works: [PortfolioWork]) async throws {
        guard let client else { return }
        let session = try await client.auth.session
        let application = SalonApplication(
            id: "salon-application-\(salon.id)",
            submittedBy: session.user.id,
            salon: salon,
            works: works
        )
        try await client.from("salon_applications")
            .upsert(application, onConflict: "id")
            .execute()
    }

    func approveStylistApplication(_ application: StylistApplication) async throws {
        let stylist = application.asStylist()
        try await saveStylist(stylist)
        try await setStylistApplicationStatus(id: application.id, status: .approved)
    }

    func rejectStylistApplication(_ application: StylistApplication) async throws {
        try await setStylistApplicationStatus(id: application.id, status: .rejected)
    }

    func approveSalonApplication(_ application: SalonApplication) async throws {
        let salon = application.asSalon()
        try await saveSalon(salon, works: application.worksPayload)
        try await setSalonApplicationStatus(id: application.id, status: .approved)
    }

    func rejectSalonApplication(_ application: SalonApplication) async throws {
        try await setSalonApplicationStatus(id: application.id, status: .rejected)
    }

    private func setStylistApplicationStatus(id: String, status: CatalogApplicationStatus) async throws {
        guard let client else { return }
        let session = try await client.auth.session
        let payload = ApplicationReviewPayload(
            status: status.rawValue,
            reviewedBy: session.user.id,
            reviewedAt: Self.iso8601.string(from: Date())
        )
        try await client.from("stylist_applications")
            .update(payload)
            .eq("id", value: id)
            .execute()
    }

    private func setSalonApplicationStatus(id: String, status: CatalogApplicationStatus) async throws {
        guard let client else { return }
        let session = try await client.auth.session
        let payload = ApplicationReviewPayload(
            status: status.rawValue,
            reviewedBy: session.user.id,
            reviewedAt: Self.iso8601.string(from: Date())
        )
        try await client.from("salon_applications")
            .update(payload)
            .eq("id", value: id)
            .execute()
    }

    func updateStylistAdminState(id: String, isActive: Bool, isFeatured: Bool, displayOrder: Int) async throws {
        guard let client else { return }
        struct Payload: Encodable {
            let isActive: Bool
            let isFeatured: Bool
            let displayOrder: Int

            enum CodingKeys: String, CodingKey {
                case isActive = "is_active"
                case isFeatured = "is_featured"
                case displayOrder = "display_order"
            }
        }
        try await client.from("stylists")
            .update(Payload(isActive: isActive, isFeatured: isFeatured, displayOrder: displayOrder))
            .eq("id", value: id)
            .execute()
    }

    func updateSalonAdminState(id: String, isActive: Bool, isFeatured: Bool, displayOrder: Int) async throws {
        guard let client else { return }
        struct Payload: Encodable {
            let isActive: Bool
            let isFeatured: Bool
            let displayOrder: Int

            enum CodingKeys: String, CodingKey {
                case isActive = "is_active"
                case isFeatured = "is_featured"
                case displayOrder = "display_order"
            }
        }
        try await client.from("salons")
            .update(Payload(isActive: isActive, isFeatured: isFeatured, displayOrder: displayOrder))
            .eq("id", value: id)
            .execute()
    }

    func pinRankingItem(rankingKey: String, itemType: String, itemID: String, manualRank: Int, scoreOverride: Double?) async throws {
        try await setRankingItem(
            rankingKey: rankingKey,
            itemType: itemType,
            itemID: itemID,
            manualRank: manualRank,
            scoreOverride: scoreOverride
        )
    }

    func setRankingItem(rankingKey: String, itemType: String, itemID: String, manualRank: Int?, scoreOverride: Double?) async throws {
        guard let client else { return }
        struct Payload: Encodable {
            let id: UUID
            let rankingKey: String
            let itemType: String
            let itemID: String
            let manualRank: Int?
            let scoreOverride: Double?
            let isPinned: Bool
            let isActive: Bool

            enum CodingKeys: String, CodingKey {
                case id
                case rankingKey = "ranking_key"
                case itemType = "item_type"
                case itemID = "item_id"
                case manualRank = "manual_rank"
                case scoreOverride = "score_override"
                case isPinned = "is_pinned"
                case isActive = "is_active"
            }
        }

        let payload = Payload(
            id: UUID(),
            rankingKey: rankingKey,
            itemType: itemType,
            itemID: itemID,
            manualRank: manualRank,
            scoreOverride: scoreOverride,
            isPinned: manualRank != nil,
            isActive: manualRank != nil
        )

        try await client.from("ranking_overrides")
            .upsert(payload, onConflict: "ranking_key,item_type,item_id")
            .execute()
    }

    func insertMessage(_ message: ChatMessageItem) async throws {
        guard let client else { return }
        try await client.from("messages")
            .insert(message)
            .execute()
    }

    func recallMessage(id: String, replacementText: String) async throws {
        guard let client else { return }
        struct Payload: Encodable {
            let text: String
            let isRecalled: Bool
            let recalledAt: String

            enum CodingKeys: String, CodingKey {
                case text
                case isRecalled = "is_recalled"
                case recalledAt = "recalled_at"
            }
        }

        try await client.from("messages")
            .update(Payload(text: replacementText, isRecalled: true, recalledAt: ISO8601DateFormatter().string(from: Date())))
            .eq("id", value: id)
            .execute()
    }

    func setConversationBlocked(stylistID: String, isBlocked: Bool) async throws {
        guard let client else { return }
        let session = try await client.auth.session
        if isBlocked {
            try await client.from("conversation_blocks")
                .upsert(
                    ConversationBlockRow(customerID: session.user.id, stylistID: stylistID),
                    onConflict: "customer_id,stylist_id"
                )
                .execute()
        } else {
            try await client.from("conversation_blocks")
                .delete()
                .eq("customer_id", value: session.user.id.uuidString)
                .eq("stylist_id", value: stylistID)
                .execute()
        }
    }

    func toggleBlockedSlot(_ slot: BlockedSlot, shouldBlock: Bool) async throws {
        guard let client else { return }
        if shouldBlock {
            try await client.from("blocked_slots")
                .insert(slot)
                .execute()
        } else {
            try await client.from("blocked_slots")
                .delete()
                .eq("stylist_id", value: slot.stylistID)
                .eq("work_date", value: slot.workDate)
                .eq("start_time", value: slot.startTime)
                .execute()
        }
    }
}
