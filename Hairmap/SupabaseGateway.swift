import Foundation
import Storage
import Supabase

struct SupabaseSettings {
    let environment: String
    let url: URL
    let publishableKey: String
    let redirectURL: URL

    nonisolated static func load(
        info: [String: Any] = Bundle.main.infoDictionary ?? [:],
        environment processEnvironment: [String: String] = ProcessInfo.processInfo.environment,
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> SupabaseSettings? {
        if arguments.contains("--hairmap-local-mode") || processEnvironment["HAIRMAP_DISABLE_SUPABASE"] == "1" {
            return nil
        }

        let rawEnvironment = (
            info["APP_ENVIRONMENT"] as? String
            ?? processEnvironment["APP_ENVIRONMENT"]
            ?? "development"
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        let urlString = (
            info["SUPABASE_URL"] as? String
            ?? processEnvironment["SUPABASE_URL"]
            ?? ""
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        let key = (
            info["SUPABASE_PUBLISHABLE_KEY"] as? String
            ?? processEnvironment["SUPABASE_PUBLISHABLE_KEY"]
            ?? ""
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        let redirect = (
            info["SUPABASE_REDIRECT_URL"] as? String
            ?? processEnvironment["SUPABASE_REDIRECT_URL"]
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

        let environment = rawEnvironment.isEmpty || rawEnvironment.hasPrefix("$(") ? "development" : rawEnvironment
        return SupabaseSettings(environment: environment, url: url, publishableKey: key, redirectURL: redirectURL)
    }
}

struct StylistApplicationClaimResult: Decodable, Hashable {
    var claimStatus: String
    var applicationID: String?
    var stylistID: String?

    enum CodingKeys: String, CodingKey {
        case claimStatus = "claim_status"
        case applicationID = "application_id"
        case stylistID = "stylist_id"
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
        var mediaKind: PortfolioMediaKind
        var videoURL: String
        var thumbnailURL: String

        enum CodingKeys: String, CodingKey {
            case id
            case salonID = "salon_id"
            case title
            case imageURL = "image_url"
            case mediaKind = "media_kind"
            case videoURL = "video_url"
            case thumbnailURL = "thumbnail_url"
        }

        init(work: PortfolioWork) {
            id = work.id
            salonID = work.stylistID
            title = work.title
            imageURL = work.imageURL
            mediaKind = work.mediaKind
            videoURL = work.videoURL
            thumbnailURL = work.thumbnailURL
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            salonID = try container.decode(String.self, forKey: .salonID)
            title = try container.decode(String.self, forKey: .title)
            imageURL = try container.decode(String.self, forKey: .imageURL)
            mediaKind = try container.decodeIfPresent(PortfolioMediaKind.self, forKey: .mediaKind) ?? .photo
            videoURL = try container.decodeIfPresent(String.self, forKey: .videoURL) ?? ""
            thumbnailURL = try container.decodeIfPresent(String.self, forKey: .thumbnailURL) ?? ""
        }

        func asPortfolioWork() -> PortfolioWork {
            PortfolioWork(
                id: id,
                stylistID: salonID,
                title: title,
                imageURL: imageURL,
                mediaKind: mediaKind,
                videoURL: videoURL,
                thumbnailURL: thumbnailURL
            )
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

    private struct MessageReadReceiptRow: Codable {
        var messageID: String
        var profileID: UUID
        var readAt: String

        enum CodingKeys: String, CodingKey {
            case messageID = "message_id"
            case profileID = "profile_id"
            case readAt = "read_at"
        }
    }

    private struct UserBlockRow: Decodable {
        var blockedID: UUID

        enum CodingKeys: String, CodingKey {
            case blockedID = "blocked_id"
        }
    }

    private struct UserBlockPayload: Encodable {
        var blockerID: UUID
        var blockedID: UUID
        var sourceEntityType: String
        var sourceEntityID: String
        var reason: String
        var details: String

        enum CodingKeys: String, CodingKey {
            case blockerID = "blocker_id"
            case blockedID = "blocked_id"
            case sourceEntityType = "source_entity_type"
            case sourceEntityID = "source_entity_id"
            case reason
            case details
        }
    }

    private struct ReportPayload: Encodable {
        let reporterID: UUID
        let entityType: String
        let entityID: String
        let reason: String
        let details: String

        enum CodingKeys: String, CodingKey {
            case reporterID = "reporter_id"
            case entityType = "entity_type"
            case entityID = "entity_id"
            case reason
            case details
        }
    }

    private struct EdgeFunctionError: LocalizedError {
        let statusCode: Int
        let message: String

        var errorDescription: String? {
            statusCode > 0 ? "\(message) (\(statusCode))" : message
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

    private struct StylistApplicationReviewPayload: Encodable {
        let status: String
        let reviewedBy: UUID
        let reviewedAt: String
        let stylistID: String
        let ownerID: UUID?

        enum CodingKeys: String, CodingKey {
            case status
            case reviewedBy = "reviewed_by"
            case reviewedAt = "reviewed_at"
            case stylistID = "stylist_id"
            case ownerID = "owner_id"
        }
    }

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    var isConfigured: Bool { client != nil }
    var environmentName: String { settings?.environment ?? "local" }

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

    func catalogRealtimeChanges() -> AsyncStream<Void>? {
        guard let client else { return nil }
        let tables = [
            "profiles",
            "stylists",
            "salons",
            "services",
            "portfolio_works",
            "salon_portfolio_works",
            "reviews",
            "bookings",
            "messages",
            "blocked_slots",
            "conversation_blocks",
            "user_blocks",
            "inspiration_items",
            "inspiration_comments",
            "inspiration_reactions",
            "inspiration_comment_reactions",
            "inspiration_shares",
            "stylist_applications",
            "salon_applications",
            "ranking_overrides"
        ]

        return AsyncStream { continuation in
            let channel = client.channel("hairmap-live-\(UUID().uuidString)")
            let listeners = tables.map { table in
                let changes = channel.postgresChange(AnyAction.self, schema: "public", table: table)
                return Task {
                    for await _ in changes {
                        continuation.yield(())
                    }
                }
            }
            let subscribeTask = Task {
                try? await channel.subscribeWithError()
            }

            continuation.onTermination = { _ in
                listeners.forEach { $0.cancel() }
                subscribeTask.cancel()
                Task {
                    await client.removeChannel(channel)
                }
            }
        }
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
                "stylist_id": .string("")
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
                "stylist_id": .string("")
            ],
            redirectTo: settings.redirectURL
        )
    }

    func resendSignupConfirmation(email: String) async throws {
        guard let client, let settings else { return }
        try await client.auth.resend(
            email: email,
            type: .signup,
            emailRedirectTo: settings.redirectURL
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

    func updateAuthMetadata(displayName: String, role: UserRole, stylistID: String? = nil) async throws -> Session? {
        guard let client else { return nil }
        let metadata: [String: AnyJSON] = [
            "display_name": .string(displayName),
            "role": .string(role.rawValue),
            "stylist_id": .string(role == .stylist ? (stylistID ?? "") : "")
        ]
        _ = try await client.auth.update(user: UserAttributes(data: metadata))
        return try await client.auth.session
    }

    func signInWithAppleIDToken(idToken: String, fullName: String?, role: UserRole) async throws -> Session? {
        guard let client else { return nil }

        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken
            )
        )

        let existingDisplayName = session.user.userMetadata["display_name"]?.stringValue?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedDisplayName = [
            fullName?.trimmingCharacters(in: .whitespacesAndNewlines),
            existingDisplayName,
            session.user.email,
            "Apple Guest"
        ]
        .compactMap { $0 }
        .first { !$0.isEmpty } ?? "Apple Guest"

        let metadata: [String: AnyJSON] = [
            "display_name": .string(resolvedDisplayName),
            "role": .string(role.rawValue),
            "stylist_id": .string("")
        ]

        _ = try await client.auth.update(user: UserAttributes(data: metadata))
        return try await client.auth.session
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

    func deleteCurrentAccount() async throws {
        guard let client, let settings else { return }
        let session = try await client.auth.session
        let endpoint = URL(string: "/functions/v1/delete-account", relativeTo: settings.url)?.absoluteURL
        guard let endpoint else {
            throw EdgeFunctionError(statusCode: -1, message: "刪除帳號服務網址無效")
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = Data("{}".utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EdgeFunctionError(statusCode: -1, message: "刪除帳號服務沒有回應")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw EdgeFunctionError(
                statusCode: httpResponse.statusCode,
                message: message?.isEmpty == false ? message! : "刪除帳號失敗"
            )
        }

        try? await client.auth.signOut()
    }

    func upsertProfile(_ profile: HairmapProfile) async throws {
        guard let client else { return }
        try await client.from("profiles")
            .upsert(profile, onConflict: "id")
            .execute()
    }

    func currentProfile() async throws -> HairmapProfile? {
        guard let client else { return nil }
        let session = try await client.auth.session
        let rows: [HairmapProfile] = try await client.from("profiles")
            .select()
            .eq("id", value: session.user.id.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
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

        let salonBrands: [SalonBrand] = (try? await client.from("salon_brands")
            .select()
            .eq("is_active", value: true)
            .order("display_order", ascending: true)
            .execute()
            .value) ?? []

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

        let salonServiceRows: [SalonServiceItem] = (try? await client.from("salon_services")
            .select()
            .eq("is_active", value: true)
            .order("display_order", ascending: true)
            .order("price", ascending: true)
            .execute()
            .value) ?? []

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

        let profiles: [HairmapProfile] = (try? await client.from("profiles")
            .select("id,display_name,email,role,stylist_id,avatar_url")
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
            .order("created_at", ascending: false)
            .execute()
            .value) ?? []

        let salonApplications: [SalonApplication] = (try? await client.from("salon_applications")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value) ?? []

        let session = try? await client.auth.session
        let likedLooks: [InspirationReactionRow]
        let likedComments: [CommentReactionRow]
        let blockedConversations: [ConversationBlockRow]
        let blockedUsers: [UserBlockRow]
        let readReceipts: [MessageReadReceiptRow]
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
            blockedUsers = (try? await client.from("user_blocks")
                .select("blocked_id")
                .eq("blocker_id", value: session.user.id.uuidString)
                .execute()
                .value) ?? []
            readReceipts = (try? await client.from("message_read_receipts")
                .select("message_id,profile_id,read_at")
                .eq("profile_id", value: session.user.id.uuidString)
                .execute()
                .value) ?? []
        } else {
            likedLooks = []
            likedComments = []
            blockedConversations = []
            blockedUsers = []
            readReceipts = []
        }

        let bookings: [Appointment] = (try? await client.from("bookings")
            .select()
            .order("booking_date", ascending: true)
            .execute()
            .value) ?? []

        let messages: [ChatMessageItem] = (try? await client.from("messages")
            .select()
            .order("created_at", ascending: true)
            .execute()
            .value) ?? []

        let salonMessages: [SalonChatMessageItem] = (try? await client.from("salon_chat_messages")
            .select()
            .order("created_at", ascending: true)
            .execute()
            .value) ?? []

        let blockedSlots: [BlockedSlot] = try await client.from("blocked_slots")
            .select()
            .execute()
            .value
        let normalizedBlockedSlots = blockedSlots.map { slot in
            var normalized = slot
            normalized.startTime = slot.startTime.hmTimeKey
            return normalized
        }

        let stylists = stylistRows.map { stylist in
            var hydrated = stylist
            hydrated.services = services.filter { $0.stylistID == stylist.id }
            hydrated.works = works.filter { $0.stylistID == stylist.id }
            hydrated.reviews = reviews.filter { $0.stylistID == stylist.id }
            return hydrated
        }
        let hydratedSalons = salons.map { salon in
            var hydrated = salon
            hydrated.reviews = reviews.filter { $0.salonID == salon.id }
            hydrated.reviewsCount = max(hydrated.reviewsCount, hydrated.reviews.count)
            return hydrated
        }

        let salonWorks = Dictionary(grouping: salonWorkRows.map { $0.asPortfolioWork() }, by: \.stylistID)
        let salonServices = Dictionary(grouping: salonServiceRows, by: \.salonID)

        return CatalogPayload(
            salonBrands: salonBrands,
            salons: hydratedSalons.isEmpty ? SeedData.salons : hydratedSalons,
            stylists: stylists.isEmpty ? SeedData.stylists : stylists,
            inspiration: inspiration,
            profiles: profiles,
            bookings: bookings,
            messages: messages,
            salonMessages: salonMessages,
            blockedSlots: normalizedBlockedSlots,
            salonServices: salonServices,
            salonWorks: salonWorks,
            rankingOverrides: rankingOverrides,
            stylistApplications: stylistApplications,
            salonApplications: salonApplications,
            inspirationComments: threadComments(commentRows),
            likedLookIDs: Set(likedLooks.map(\.inspirationID)),
            likedCommentIDs: Set(likedComments.map(\.commentID)),
            blockedChatStylistIDs: Set(blockedConversations.map(\.stylistID)),
            blockedUserIDs: Set(blockedUsers.map(\.blockedID)),
            readMessageIDs: Set(readReceipts.map(\.messageID))
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

    func uploadMedia(
        data: Data,
        folder: String,
        mediaKind: SharedLookMediaKind,
        fileExtension preferredFileExtension: String? = nil,
        contentType preferredContentType: String? = nil
    ) async throws -> String? {
        guard let client else { return nil }
        let session = try await client.auth.session
        let safeFolder = folder
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "-")
        let fileExtension = preferredFileExtension?.nilIfEmpty ?? (mediaKind == .video ? "mov" : "jpg")
        let contentType = preferredContentType?.nilIfEmpty ?? (mediaKind == .video ? "video/quicktime" : "image/jpeg")
        let ownerFolder = session.user.id.uuidString.lowercased()
        let path = "uploads/\(ownerFolder)/\(safeFolder)/\(UUID().uuidString).\(fileExtension)"

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
            let stylistID: String?
            let salonID: String?
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
                case salonID = "salon_id"
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

        let targetStylistID = review.stylistID.nilIfEmpty
        let targetSalonID = review.salonID
        guard (targetStylistID != nil) != (targetSalonID != nil) else { return }

        let payload = Payload(
            id: review.id,
            stylistID: targetStylistID,
            salonID: targetSalonID,
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
            let authorAvatar: String
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
                case isActive = "is_active"
            }
        }

        let payload = Payload(
            id: look.id,
            stylistID: look.stylistID ?? "master-leo",
            title: look.title,
            salonName: look.studio,
            location: look.location,
            tags: look.tags,
            imageURL: primaryURL,
            category: look.category,
            authorID: authorID,
            authorName: look.author,
            authorAvatar: look.authorAvatarURL,
            studio: look.studio,
            mediaURLs: mediaURLs.isEmpty ? [primaryURL] : mediaURLs,
            mediaKinds: mediaKinds.isEmpty ? [look.mediaKind.rawValue] : mediaKinds.map(\.rawValue),
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
        try await updateProfile(displayName: displayName, avatarURL: nil)
    }

    func updateProfile(displayName: String? = nil, avatarURL: String? = nil) async throws {
        guard let client else { return }
        let session = try await client.auth.session
        struct Payload: Encodable {
            let displayName: String?
            let avatarURL: String?

            enum CodingKeys: String, CodingKey {
                case displayName = "display_name"
                case avatarURL = "avatar_url"
            }
        }
        try await client.from("profiles")
            .update(Payload(displayName: displayName, avatarURL: avatarURL))
            .eq("id", value: session.user.id.uuidString)
            .execute()
    }

    func createBooking(_ booking: Appointment) async throws {
        guard let client else { return }
        try await client.from("bookings")
            .insert(booking)
            .execute()
    }

    func salonChatThreadID(customerID: UUID, salonID: String, salonBrandID: String?, subject: String) async throws -> UUID {
        guard let client else { return UUID() }
        struct ThreadIDRow: Decodable {
            let id: UUID
        }
        struct ThreadPayload: Encodable {
            let id: UUID
            let customerID: UUID
            let salonID: String
            let salonBrandID: String?
            let subject: String

            enum CodingKeys: String, CodingKey {
                case id
                case customerID = "customer_id"
                case salonID = "salon_id"
                case salonBrandID = "salon_brand_id"
                case subject
            }
        }

        let existing: [ThreadIDRow] = try await client.from("salon_chat_threads")
            .select("id")
            .eq("customer_id", value: customerID.uuidString)
            .eq("salon_id", value: salonID)
            .limit(1)
            .execute()
            .value
        if let id = existing.first?.id {
            return id
        }

        let threadID = UUID()
        try await client.from("salon_chat_threads")
            .insert(ThreadPayload(id: threadID, customerID: customerID, salonID: salonID, salonBrandID: salonBrandID, subject: subject))
            .execute()
        return threadID
    }

    func insertSalonMessage(_ message: SalonChatMessageItem) async throws {
        guard let client else { return }
        try await client.from("salon_chat_messages")
            .insert(message)
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

    func saveSalon(_ salon: Salon, works: [PortfolioWork], services: [SalonServiceItem] = []) async throws {
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
                    imageURL: work.imageURL,
                    mediaKind: work.mediaKind,
                    videoURL: work.videoURL,
                    thumbnailURL: work.thumbnailURL
                )
            )
        }
        if !rows.isEmpty {
            try await client.from("salon_portfolio_works")
                .insert(rows)
                .execute()
        }

        try await client.from("salon_services")
            .delete()
            .eq("salon_id", value: salon.id)
            .execute()
        if !services.isEmpty {
            try await client.from("salon_services")
                .insert(services)
                .execute()
        }
    }

    func submitStylistApplication(_ stylist: Stylist) async throws {
        guard let client else { return }
        let session = try await client.auth.session
        let application = StylistApplication(
            id: "stylist-application-\(stylist.id)-\(UUID().uuidString.lowercased())",
            submittedBy: session.user.id,
            stylist: stylist,
            contactEmail: session.user.email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        )
        try await client.from("stylist_applications")
            .insert(application)
            .execute()
    }

    func submitSalonApplication(_ salon: Salon, works: [PortfolioWork], services: [SalonServiceItem] = []) async throws {
        guard let client else { return }
        let session = try await client.auth.session
        let application = SalonApplication(
            id: "salon-application-\(salon.id)-\(UUID().uuidString.lowercased())",
            submittedBy: session.user.id,
            salon: salon,
            works: works,
            services: services
        )
        try await client.from("salon_applications")
            .insert(application)
            .execute()
    }

    func approveStylistApplication(_ application: StylistApplication, replacing existingStylist: Stylist? = nil) async throws {
        var stylist = application.asStylist()
        if let existingStylist {
            stylist.id = existingStylist.id
            if stylist.salonID == "independent-stylist-studio" {
                stylist.salonID = existingStylist.salonID
            }
            stylist.ownerID = application.ownerID ?? existingStylist.ownerID
            stylist.rating = existingStylist.rating
            stylist.reviewsCount = existingStylist.reviewsCount
            stylist.isFeatured = existingStylist.isFeatured
            stylist.displayOrder = existingStylist.displayOrder
            stylist.services = stylist.services.map { service in
                var updated = service
                updated.stylistID = existingStylist.id
                return updated
            }
            stylist.works = stylist.works.map { work in
                var updated = work
                updated.stylistID = existingStylist.id
                return updated
            }
        }
        try await saveStylist(stylist)
        try await setStylistApplicationStatus(
            id: application.id,
            status: .approved,
            stylistID: stylist.id,
            ownerID: stylist.ownerID
        )
        if stylist.ownerID != nil {
            try await linkApprovedStylistProfile(
                ownerID: stylist.ownerID,
                displayName: application.name,
                stylistID: stylist.id,
                avatarURL: application.avatarURL
            )
        }
    }

    func rejectStylistApplication(_ application: StylistApplication) async throws {
        try await setStylistApplicationStatus(id: application.id, status: .rejected)
    }

    func approveSalonApplication(_ application: SalonApplication) async throws {
        let salon = application.asSalon()
        try await saveSalon(salon, works: application.worksPayload, services: application.servicesPayload)
        try await setSalonApplicationStatus(id: application.id, status: .approved)
    }

    func rejectSalonApplication(_ application: SalonApplication) async throws {
        try await setSalonApplicationStatus(id: application.id, status: .rejected)
    }

    func markStylistApplicationsHidden(stylistID: String) async throws {
        guard let client else { return }
        let session = try await client.auth.session
        let payload = ApplicationReviewPayload(
            status: CatalogApplicationStatus.hidden.rawValue,
            reviewedBy: session.user.id,
            reviewedAt: Self.iso8601.string(from: Date())
        )
        try await client.from("stylist_applications")
            .update(payload)
            .eq("stylist_id", value: stylistID)
            .eq("status", value: CatalogApplicationStatus.approved.rawValue)
            .execute()
    }

    func markSalonApplicationsHidden(salonID: String) async throws {
        guard let client else { return }
        let session = try await client.auth.session
        let payload = ApplicationReviewPayload(
            status: CatalogApplicationStatus.hidden.rawValue,
            reviewedBy: session.user.id,
            reviewedAt: Self.iso8601.string(from: Date())
        )
        try await client.from("salon_applications")
            .update(payload)
            .eq("salon_id", value: salonID)
            .eq("status", value: CatalogApplicationStatus.approved.rawValue)
            .execute()
    }

    private func setStylistApplicationStatus(
        id: String,
        status: CatalogApplicationStatus,
        stylistID: String? = nil,
        ownerID: UUID? = nil
    ) async throws {
        guard let client else { return }
        let session = try await client.auth.session
        let reviewedAt = Self.iso8601.string(from: Date())
        if let stylistID {
            let payload = StylistApplicationReviewPayload(
                status: status.rawValue,
                reviewedBy: session.user.id,
                reviewedAt: reviewedAt,
                stylistID: stylistID,
                ownerID: ownerID
            )
            try await client.from("stylist_applications")
                .update(payload)
                .eq("id", value: id)
                .execute()
        } else {
            let payload = ApplicationReviewPayload(
                status: status.rawValue,
                reviewedBy: session.user.id,
                reviewedAt: reviewedAt
            )
            try await client.from("stylist_applications")
                .update(payload)
                .eq("id", value: id)
                .execute()
        }
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

    private func linkApprovedStylistProfile(ownerID: UUID?, displayName: String, stylistID: String, avatarURL: String) async throws {
        guard let client, let ownerID else { return }
        struct Payload: Encodable {
            let displayName: String
            let stylistID: String
            let avatarURL: String

            enum CodingKeys: String, CodingKey {
                case displayName = "display_name"
                case stylistID = "stylist_id"
                case avatarURL = "avatar_url"
            }
        }

        try await client.from("profiles")
            .update(
                Payload(
                    displayName: displayName,
                    stylistID: stylistID,
                    avatarURL: avatarURL
                )
            )
            .eq("id", value: ownerID.uuidString)
            .execute()
    }

    func claimApprovedStylistApplication() async throws -> StylistApplicationClaimResult? {
        guard let client else { return nil }
        let rows: [StylistApplicationClaimResult] = try await client
            .rpc("claim_approved_stylist_application")
            .execute()
            .value
        return rows.first
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

    func markMessagesRead(_ messageIDs: Set<String>) async throws {
        guard let client, !messageIDs.isEmpty else { return }
        let session = try await client.auth.session
        let now = ISO8601DateFormatter().string(from: Date())
        let rows = messageIDs.map { messageID in
            MessageReadReceiptRow(messageID: messageID, profileID: session.user.id, readAt: now)
        }
        try await client.from("message_read_receipts")
            .upsert(rows, onConflict: "message_id,profile_id")
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

    func setUserBlocked(
        blockedUserID: UUID,
        sourceEntityType: ReportEntityType,
        sourceEntityID: String,
        reason: String,
        details: String,
        isBlocked: Bool
    ) async throws {
        guard let client else { return }
        let session = try await client.auth.session

        if isBlocked {
            let payload = UserBlockPayload(
                blockerID: session.user.id,
                blockedID: blockedUserID,
                sourceEntityType: sourceEntityType.rawValue,
                sourceEntityID: sourceEntityID,
                reason: reason,
                details: details
            )

            try await client.from("user_blocks")
                .upsert(payload, onConflict: "blocker_id,blocked_id")
                .execute()

            let reportDetails = [
                details,
                "Blocked user: \(blockedUserID.uuidString)",
                "Source: \(sourceEntityType.rawValue):\(sourceEntityID)"
            ]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")

            let reportPayload = ReportPayload(
                reporterID: session.user.id,
                entityType: sourceEntityType.rawValue,
                entityID: sourceEntityID,
                reason: reason,
                details: reportDetails
            )

            try await client.from("reports")
                .insert(reportPayload)
                .execute()
        } else {
            try await client.from("user_blocks")
                .delete()
                .eq("blocker_id", value: session.user.id.uuidString)
                .eq("blocked_id", value: blockedUserID.uuidString)
                .execute()
        }
    }

    func createReport(entityType: ReportEntityType, entityID: String, reason: String, details: String) async throws {
        guard let client else { return }
        let session = try await client.auth.session
        let payload = ReportPayload(
            reporterID: session.user.id,
            entityType: entityType.rawValue,
            entityID: entityID,
            reason: reason,
            details: details
        )

        try await client.from("reports")
            .insert(payload)
            .execute()
    }

    func toggleBlockedSlot(_ slot: BlockedSlot, shouldBlock: Bool) async throws {
        guard let client else { return }
        var normalizedSlot = slot
        normalizedSlot.startTime = slot.startTime.hmTimeKey
        if shouldBlock {
            try await client.from("blocked_slots")
                .upsert(normalizedSlot, onConflict: "stylist_id,work_date,start_time")
                .execute()
        } else {
            try await client.from("blocked_slots")
                .delete()
                .eq("stylist_id", value: normalizedSlot.stylistID)
                .eq("work_date", value: normalizedSlot.workDate)
                .eq("start_time", value: normalizedSlot.startTime)
                .execute()
        }
    }
}
