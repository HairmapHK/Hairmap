import Foundation
import Observation
import Supabase
import UIKit
import UserNotifications

enum SocialAuthProvider {
    case apple
    case google

    var title: String {
        switch self {
        case .apple:
            return "Apple"
        case .google:
            return "Google"
        }
    }

    var supabaseProvider: Provider {
        switch self {
        case .apple:
            return .apple
        case .google:
            return .google
        }
    }
}

@MainActor
@Observable
final class HairmapStore {
    private let gateway: SupabaseGateway
    private var authTask: Task<Void, Never>?
    private var realtimeTask: Task<Void, Never>?
    private var realtimeRefreshTask: Task<Void, Never>?
    private let pendingSocialRoleKey = "hairmap.pending-social-auth-role"
    private var hasCompletedInitialCatalogSync = false
    private var didRequestNotificationPermission = false
    private var isResolvingAuthenticatedRole = false

    var salons: [Salon] = SeedData.salons
    var stylists: [Stylist] = SeedData.stylists
    var inspiration: [InspirationItem] = SeedData.inspiration
    var sharedLooks: [SharedHairLook] = []
    var bookings: [Appointment] = []
    var messages: [ChatMessageItem] = []
    var blockedSlots: [BlockedSlot] = []
    var customerProfilesByID: [UUID: HairmapProfile] = [:]
    var salonWorks: [String: [PortfolioWork]] = [:]
    var rankingOverrides: [RankingOverride] = []
    var pendingStylistApplications: [StylistApplication] = []
    var pendingSalonApplications: [SalonApplication] = []
    var inspirationComments: [String: [LookCommentItem]] = [:]
    var likedLookIDs: Set<String> = []
    var likedCommentIDs: Set<String> = []
    var blockedChatStylistIDs: Set<String> = []
    var blockedUserIDs: Set<UUID> = []
    var customerReadMessageIDs: Set<String> = []
    var stylistReadMessageIDs: Set<String> = []

    var currentProfile: HairmapProfile?
    var selectedTab: CustomerTab = .discovery
    var customerPath: [CustomerRoute] = []
    var selectedStylistID = "master-leo"
    var selectedSalonID = "s1"
    var selectedService: ServiceItem?
    var bookingSourceFromTab = false
    var statusMessage = "本地種子資料模式"
    var isLoading = false
    var isBootstrapping = true
    var isPasswordResetSheetPresented = false
    var isAdmin = false
    var pendingConfirmationEmail = ""
    var isSupabaseConfigured: Bool { gateway.isConfigured }
    var supabaseEnvironmentName: String { gateway.environmentName }
    private var expectsPasswordReset = false
    private var isLocalExperience = false

    init() {
        self.gateway = SupabaseGateway()
        statusMessage = gateway.isConfigured ? "Supabase 已配置（\(gateway.environmentName)）" : "未配置 Supabase，使用本地種子資料"
    }

    init(gateway: SupabaseGateway) {
        self.gateway = gateway
        statusMessage = gateway.isConfigured ? "Supabase 已配置（\(gateway.environmentName)）" : "未配置 Supabase，使用本地種子資料"
    }

    func bootstrap() async {
        isBootstrapping = true
        hasCompletedInitialCatalogSync = false
        clearPrivateSessionState()

        if let session = try? await gateway.currentSession() {
            applySession(session)
            await refreshCurrentProfile()
            await refreshAdminStatus()
        } else {
            currentProfile = nil
            isLocalExperience = false
            isAdmin = false
        }

        listenForAuthChanges()
        listenForRealtimeChanges()
        await refreshCatalog(showLoading: false)
        isBootstrapping = false
    }

    func refreshCatalog(showLoading: Bool = true) async {
        if showLoading {
            isLoading = true
        }
        defer {
            if showLoading {
                isLoading = false
            }
        }

        do {
            let payload = try await gateway.loadCatalog()
            let previousBookings = bookings
            let previousMessages = messages
            let activeBlockedUserIDs = isLocalExperience ? blockedUserIDs : payload.blockedUserIDs

            salons = payload.salons
            stylists = filterBlockedReviews(in: payload.stylists, blockedUserIDs: activeBlockedUserIDs)
            inspiration = payload.inspiration.filter { !isProfileBlocked($0.authorID, in: activeBlockedUserIDs) }
            customerProfilesByID = Dictionary(uniqueKeysWithValues: payload.profiles.map { ($0.id, $0) })
            let scopedPrivateData = scopedPrivateCatalog(
                bookings: isLocalExperience ? bookings : payload.bookings,
                messages: isLocalExperience ? messages : payload.messages
            )
            bookings = scopedPrivateData.bookings
            messages = scopedPrivateData.messages
            blockedSlots = payload.blockedSlots
            salonWorks = payload.salonWorks
            rankingOverrides = payload.rankingOverrides
            pendingStylistApplications = payload.stylistApplications
            pendingSalonApplications = payload.salonApplications
            inspirationComments = filterBlockedComments(payload.inspirationComments, blockedUserIDs: activeBlockedUserIDs)
            if isLocalExperience {
                likedLookIDs = []
                likedCommentIDs = []
                blockedChatStylistIDs = []
                customerReadMessageIDs = []
                stylistReadMessageIDs = []
            } else {
                likedLookIDs = payload.likedLookIDs
                likedCommentIDs = payload.likedCommentIDs
                blockedChatStylistIDs = payload.blockedChatStylistIDs
            }
            blockedUserIDs = activeBlockedUserIDs
            syncCurrentStylistProfileFromCatalog()
            notifyForCatalogChanges(
                previousBookings: previousBookings,
                previousMessages: previousMessages,
                updatedBookings: bookings,
                updatedMessages: messages
            )
            hasCompletedInitialCatalogSync = true
            statusMessage = gateway.isConfigured ? "Supabase 同步完成（\(gateway.environmentName)）" : "本地種子資料模式"
        } catch {
            statusMessage = "Supabase 讀取失敗，已保留本地資料"
        }
    }

    private func scopedPrivateCatalog(
        bookings sourceBookings: [Appointment],
        messages sourceMessages: [ChatMessageItem]
    ) -> (bookings: [Appointment], messages: [ChatMessageItem]) {
        guard let profile = currentProfile else {
            return ([], [])
        }

        switch profile.role {
        case .customer:
            let scopedBookings = sourceBookings
                .filter { $0.customerID == profile.id }
                .sorted { lhs, rhs in
                    "\(lhs.bookingDate) \(lhs.startTime)" > "\(rhs.bookingDate) \(rhs.startTime)"
                }
            let scopedMessages = sourceMessages
                .filter { $0.customerID == profile.id }
                .sorted { $0.sortKey < $1.sortKey }
            return (scopedBookings, scopedMessages)

        case .stylist:
            let stylistID = currentStylistDashboardID
            let scopedBookings = sourceBookings
                .filter { $0.stylistID == stylistID }
                .sorted { lhs, rhs in
                    "\(lhs.bookingDate) \(lhs.startTime)" > "\(rhs.bookingDate) \(rhs.startTime)"
                }
            let scopedMessages = sourceMessages
                .filter { $0.stylistID == stylistID }
                .sorted { $0.sortKey < $1.sortKey }
            return (scopedBookings, scopedMessages)
        }
    }

    private func notifyForCatalogChanges(
        previousBookings: [Appointment],
        previousMessages: [ChatMessageItem],
        updatedBookings: [Appointment],
        updatedMessages: [ChatMessageItem]
    ) {
        guard hasCompletedInitialCatalogSync, !isBootstrapping, !isLocalExperience, let profile = currentProfile else { return }

        let previousMessageIDs = Set(previousMessages.map(\.id))
        let newMessages = updatedMessages.filter { !previousMessageIDs.contains($0.id) }
        for message in newMessages {
            switch profile.role {
            case .customer where message.senderRole == .stylist:
                postLocalNotification(
                    title: "Hairmap 新訊息",
                    body: "\(message.senderName)：\(message.displayText)",
                    identifier: "hairmap.message.\(message.id)"
                )
            case .stylist where message.senderRole == .customer:
                postLocalNotification(
                    title: "Hairmap 顧客訊息",
                    body: "\(message.senderName)：\(message.displayText)",
                    identifier: "hairmap.message.\(message.id)"
                )
            default:
                break
            }
        }

        let previousBookingsByID = Dictionary(uniqueKeysWithValues: previousBookings.map { ($0.id, $0) })
        let newBookings = updatedBookings.filter { previousBookingsByID[$0.id] == nil }
        if profile.role == .stylist {
            for booking in newBookings {
                postLocalNotification(
                    title: "Hairmap 新預約",
                    body: "\(booking.clientName) 預約了 \(booking.serviceName)，\(booking.bookingDate) \(booking.startTime)",
                    identifier: "hairmap.booking.new.\(booking.id.uuidString)"
                )
            }
        }

        guard profile.role == .customer else { return }
        for booking in updatedBookings {
            guard let previous = previousBookingsByID[booking.id],
                  previous.status != booking.status,
                  [.accepted, .completed, .cancelled].contains(booking.status)
            else { continue }
            postLocalNotification(
                title: "Hairmap 預約更新",
                body: "\(booking.stylistName) 的 \(booking.serviceName) 已更新為「\(booking.status.title)」",
                identifier: "hairmap.booking.status.\(booking.id.uuidString).\(booking.status.rawValue)"
            )
        }
    }

    private func requestNotificationPermissionIfNeeded() {
        guard !didRequestNotificationPermission else { return }
        didRequestNotificationPermission = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    private func postLocalNotification(title: String, body: String, identifier: String) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            let allowedStatuses: Set<UNAuthorizationStatus> = [.authorized, .provisional, .ephemeral]
            guard allowedStatuses.contains(settings.authorizationStatus) else { return }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            )
            center.add(request)
        }
    }

    func start(displayName: String, email: String, role: UserRole) async {
        let cleanName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = normalizedEmail(email)
        let displayName = cleanName.isEmpty ? "Hairmap Guest" : cleanName

        guard isRealEmail(cleanEmail) else {
            statusMessage = "請輸入可接收登入連結的真實 Email"
            return
        }

        guard gateway.isConfigured else {
            startLocal(displayName: displayName, email: cleanEmail, role: role)
            return
        }

        do {
            pendingSocialRole = role
            try await gateway.sendMagicLink(email: cleanEmail, displayName: displayName, role: role)
            currentProfile = nil
            pendingConfirmationEmail = ""
            clearPrivateSessionState()
            statusMessage = "登入連結已寄出，請打開最新 Email 連結返回 Hairmap"
        } catch {
            statusMessage = authErrorMessage(for: error)
        }
    }

    func register(displayName: String, email: String, password: String, role: UserRole) async {
        let cleanName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = normalizedEmail(email)
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = cleanName.isEmpty ? "Hairmap Guest" : cleanName

        guard isRealEmail(cleanEmail) else {
            statusMessage = "請輸入可接收確認信的真實 Email"
            return
        }

        guard cleanPassword.count >= 6 else {
            statusMessage = "密碼至少需要 6 位字元"
            return
        }

        guard gateway.isConfigured else {
            startLocal(displayName: displayName, email: cleanEmail, role: role)
            return
        }

        do {
            _ = try await gateway.signUp(email: cleanEmail, password: cleanPassword, displayName: displayName, role: role)
            if let session = try await gateway.currentSession() {
                applySession(session)
                pendingConfirmationEmail = ""
                await refreshCurrentProfile()
                await refreshAdminStatus()
                await refreshCatalog(showLoading: false)
            } else {
                currentProfile = nil
                pendingConfirmationEmail = cleanEmail
                clearPrivateSessionState()
                statusMessage = "確認信請求已送出。請檢查收件箱/垃圾郵件；未收到可等 60 秒後重寄"
            }
        } catch {
            statusMessage = authErrorMessage(for: error)
        }
    }

    func resendConfirmationEmail(email: String? = nil) async {
        let cleanEmail = normalizedEmail(email ?? pendingConfirmationEmail)

        guard isRealEmail(cleanEmail) else {
            statusMessage = "請先輸入要接收確認信的 Email"
            return
        }

        guard gateway.isConfigured else {
            statusMessage = "本地模式不需要 Email 確認"
            return
        }

        do {
            try await gateway.resendSignupConfirmation(email: cleanEmail)
            pendingConfirmationEmail = cleanEmail
            statusMessage = "確認信已重新請求寄出。請檢查收件箱/垃圾郵件；太快重寄會被限制"
        } catch {
            statusMessage = authErrorMessage(for: error)
        }
    }

    func login(email: String, password: String, role: UserRole) async {
        let cleanEmail = normalizedEmail(email)
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isRealEmail(cleanEmail) else {
            statusMessage = "請輸入已註冊的真實 Email"
            return
        }

        guard !cleanPassword.isEmpty else {
            statusMessage = "請輸入密碼"
            return
        }

        guard gateway.isConfigured else {
            startLocal(displayName: role == .stylist ? "待建立髮型師" : "Hairmap 會員", email: cleanEmail, role: role)
            return
        }

        do {
            clearPrivateSessionState()
            isResolvingAuthenticatedRole = true
            isLoading = true
            defer {
                isResolvingAuthenticatedRole = false
                isLoading = false
            }
            let session = try await gateway.signIn(email: cleanEmail, password: cleanPassword)
            if let session {
                let resolvedSession = try await enforceAuthenticatedRole(role, session: session, provider: nil)
                applySession(resolvedSession)
                pendingConfirmationEmail = ""
            } else if let current = try await gateway.currentSession() {
                let resolvedSession = try await enforceAuthenticatedRole(role, session: current, provider: nil)
                applySession(resolvedSession)
                pendingConfirmationEmail = ""
            }
            await refreshCurrentProfile()
            await refreshAdminStatus()
            await refreshCatalog(showLoading: false)
        } catch {
            statusMessage = authErrorMessage(for: error)
        }
    }

    func loginWithSocial(_ provider: SocialAuthProvider, role: UserRole = .customer) async {
        guard gateway.isConfigured else {
            startLocal(displayName: "\(provider.title) Guest", role: role)
            return
        }

        pendingSocialRole = role
        do {
            clearPrivateSessionState()
            isResolvingAuthenticatedRole = true
            isLoading = true
            defer {
                isResolvingAuthenticatedRole = false
                isLoading = false
            }
            let session = try await gateway.signInWithOAuth(provider: provider.supabaseProvider)
            if let session {
                let resolvedSession = try await enforceAuthenticatedRole(role, session: session, provider: provider)
                pendingSocialRole = nil
                applySession(resolvedSession)
            } else if let current = try await gateway.currentSession() {
                let resolvedSession = try await enforceAuthenticatedRole(role, session: current, provider: provider)
                pendingSocialRole = nil
                applySession(resolvedSession)
            }
            await refreshCurrentProfile()
            await refreshAdminStatus()
            await refreshCatalog(showLoading: false)
        } catch {
            pendingSocialRole = nil
            statusMessage = authErrorMessage(for: error, provider: provider)
        }
    }

    func loginWithAppleIDToken(_ idToken: String, fullName: String?, role: UserRole = .customer) async {
        guard gateway.isConfigured else {
            startLocal(displayName: fullName ?? "Apple Guest", role: role)
            return
        }

        do {
            clearPrivateSessionState()
            isResolvingAuthenticatedRole = true
            isLoading = true
            defer {
                isResolvingAuthenticatedRole = false
                isLoading = false
            }
            if let session = try await gateway.signInWithAppleIDToken(idToken: idToken, fullName: fullName, role: role) {
                let resolvedSession = try await enforceAuthenticatedRole(role, session: session, provider: .apple)
                applySession(resolvedSession)
            } else if let current = try await gateway.currentSession() {
                let resolvedSession = try await enforceAuthenticatedRole(role, session: current, provider: .apple)
                applySession(resolvedSession)
            }
            await refreshCurrentProfile()
            await refreshAdminStatus()
            await refreshCatalog(showLoading: false)
        } catch {
            statusMessage = authErrorMessage(for: error, provider: .apple)
        }
    }

    func sendPasswordReset(email: String) async {
        let cleanEmail = normalizedEmail(email)

        guard isRealEmail(cleanEmail) else {
            statusMessage = "請先輸入要重設密碼的 Gmail / Email"
            return
        }

        guard gateway.isConfigured else {
            statusMessage = "目前是本地模式，未連接 Supabase 重設密碼"
            return
        }

        do {
            try await gateway.resetPassword(email: cleanEmail)
            expectsPasswordReset = true
            statusMessage = "重設密碼連結已寄出，請在模擬器打開最新 Email link 返回 Hairmap"
        } catch {
            statusMessage = authErrorMessage(for: error)
        }
    }

    func completePasswordReset(password: String, confirmPassword: String) async {
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanConfirm = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanPassword.count >= 6 else {
            statusMessage = "新密碼至少需要 6 位字元"
            return
        }

        guard cleanPassword == cleanConfirm else {
            statusMessage = "兩次新密碼不一致，請重新輸入"
            return
        }

        do {
            try await gateway.updatePassword(cleanPassword)
            expectsPasswordReset = false
            isPasswordResetSheetPresented = false
            statusMessage = "密碼已更新成功，可以用新密碼登入"
            if let session = try await gateway.currentSession() {
                applySession(session)
                await refreshCatalog()
            }
        } catch {
            statusMessage = authErrorMessage(for: error)
        }
    }

    func startLocal(displayName: String, email: String = "", role: UserRole) {
        let cleanName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            await gateway.signOut()
        }
        isLocalExperience = true
        isAdmin = false
        clearPrivateSessionState()
        currentProfile = HairmapProfile(
            id: UUID(),
            displayName: cleanName.isEmpty ? "Hairmap Guest" : cleanName,
            email: email,
            role: role,
            stylistID: nil
        )
        requestNotificationPermissionIfNeeded()
        pendingConfirmationEmail = ""
        selectedTab = .discovery
        customerPath = []
        statusMessage = "訪客體驗模式：資料只會保留在本機"
    }

    private func clearPrivateSessionState() {
        hasCompletedInitialCatalogSync = false
        bookings = []
        messages = []
        customerProfilesByID = [:]
        likedLookIDs = []
        likedCommentIDs = []
        blockedChatStylistIDs = []
        blockedUserIDs = []
        customerReadMessageIDs = []
        stylistReadMessageIDs = []
    }

    func logout() async {
        await gateway.signOut()
        pendingSocialRole = nil
        pendingConfirmationEmail = ""
        currentProfile = nil
        isLocalExperience = false
        isAdmin = false
        hasCompletedInitialCatalogSync = false
        selectedTab = .discovery
        selectedService = nil
        customerPath = []
        clearPrivateSessionState()
        statusMessage = gateway.isConfigured ? "已登出 Supabase" : "已登出"
    }

    func deleteAccount() async -> Bool {
        if isLocalExperience || !gateway.isConfigured {
            await logout()
            statusMessage = "訪客資料已清除"
            return true
        }

        do {
            try await gateway.deleteCurrentAccount()
            pendingSocialRole = nil
            pendingConfirmationEmail = ""
            currentProfile = nil
            isLocalExperience = false
            isAdmin = false
            selectedTab = .discovery
            selectedService = nil
            customerPath = []
            clearPrivateSessionState()
            statusMessage = "帳號已永久刪除"
            return true
        } catch {
            statusMessage = "帳號刪除失敗，請稍後再試"
            return false
        }
    }

    func showStylist(_ id: String) {
        selectedStylistID = id
        customerPath.append(.stylist(id))
    }

    func showSalon(_ id: String) {
        selectedSalonID = id
        customerPath.append(.salon(id))
    }

    func startBooking(stylistID: String, service: ServiceItem?, fromTab: Bool = false) {
        selectedStylistID = stylistID
        selectedService = service
        bookingSourceFromTab = fromTab
        customerPath = []
        selectedTab = .booking
    }

    func stylist(id: String? = nil) -> Stylist {
        stylists.first { $0.id == (id ?? selectedStylistID) } ?? stylists[0]
    }

    var currentStylistDashboardID: String {
        guard currentProfile?.role == .stylist else { return selectedStylistID }
        if let owned = currentApprovedStylistProfile {
            return owned.id
        }
        return currentProfile?.stylistID?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? draftStylistID
    }

    var currentApprovedStylistProfile: Stylist? {
        guard let profile = currentProfile, profile.role == .stylist else { return nil }
        if let stylistID = profile.stylistID,
           let stylist = stylists.first(where: { $0.id == stylistID && $0.ownerID == profile.id }) {
            return stylist
        }
        return stylists.first { $0.ownerID == profile.id }
    }

    func isApprovedDashboardStylist(id: String) -> Bool {
        guard let profile = currentProfile, profile.role == .stylist else { return false }
        return stylists.contains { $0.id == id && $0.ownerID == profile.id }
    }

    func dashboardStylist(id: String) -> Stylist {
        if let stylist = stylists.first(where: { $0.id == id && ($0.ownerID == currentProfile?.id || currentProfile?.role != .stylist) }) {
            return stylist
        }
        if let owned = currentApprovedStylistProfile {
            return owned
        }
        return draftStylistProfile(id: id)
    }

    func salon(id: String? = nil) -> Salon {
        let targetID = id ?? stylist().salonID
        return salons.first { $0.id == targetID } ?? salons[0]
    }

    private var currentCustomerID: UUID? {
        guard currentProfile?.role == .customer else { return nil }
        return currentProfile?.id
    }

    var customerBookings: [Appointment] {
        guard let customerID = currentCustomerID else { return [] }
        return bookings.filter { $0.customerID == customerID }
    }

    var customerMessages: [ChatMessageItem] {
        guard let customerID = currentCustomerID else { return [] }
        return messages.filter { $0.customerID == customerID }
    }

    var commentDisplayName: String {
        let name = normalizedDisplayName
        return name.isEmpty ? "訪客" : name
    }

    var commentAvatarURL: String {
        let avatar = currentProfile?.avatarURL.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return avatar.isEmpty ? "https://images.unsplash.com/photo-1527980965255-d3b416303d12?auto=format&fit=crop&w=120&q=80" : avatar
    }

    var needsCommentNickname: Bool {
        guard let profile = currentProfile else { return false }
        let email = profile.email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else { return false }
        return normalizedDisplayName.isEmpty
    }

    func updateCommentNickname(_ nickname: String) {
        let clean = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        currentProfile?.displayName = clean
        statusMessage = "暱稱已更新，之後發表評論會自動代入"
        Task {
            await updateCustomerProfile(displayName: clean)
        }
    }

    func updateCustomerProfile(displayName: String, avatarData: Data? = nil) async {
        let clean = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            statusMessage = "請先輸入暱稱"
            return
        }

        currentProfile?.displayName = clean
        var uploadedAvatarURL: String?
        if let avatarData {
            do {
                guard gateway.isConfigured, (try? await gateway.currentSession()) != nil else {
                    statusMessage = "頭像已暫存；登入正式帳號後可同步到 Supabase"
                    return
                }
                let uploadData = UIImage(data: avatarData)?.jpegData(compressionQuality: 0.88) ?? avatarData
                uploadedAvatarURL = try await gateway.uploadMedia(data: uploadData, folder: "customer-avatars", mediaKind: .photo)
                if let uploadedAvatarURL {
                    currentProfile?.avatarURL = uploadedAvatarURL
                }
            } catch {
                statusMessage = "頭像上載失敗，請稍後再試"
                return
            }
        }

        guard gateway.isConfigured, (try? await gateway.currentSession()) != nil else {
            statusMessage = "顧客檔案已保留在本機"
            return
        }

        do {
            try await gateway.updateProfile(displayName: clean, avatarURL: uploadedAvatarURL)
            await refreshCurrentProfile()
            statusMessage = "顧客檔案已更新，評論和靈感發佈會自動代入"
        } catch {
            statusMessage = "顧客檔案同步失敗，請稍後再試"
        }
    }

    func submitBooking(
        service: ServiceItem,
        stylist: Stylist,
        date: String,
        startTime: String,
        endTime: String,
        clientName: String,
        clientPhone: String
    ) async -> Appointment {
        let cleanClientName = clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanClientPhone = clientPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        let salon = salon(id: stylist.salonID)
        let session = isLocalExperience ? nil : (try? await gateway.currentSession())
        let booking = Appointment(
            id: UUID(),
            customerID: session?.user.id ?? currentProfile?.id,
            stylistID: stylist.id,
            salonID: salon.id,
            serviceID: service.id,
            salonName: salon.name,
            stylistName: stylist.name,
            clientName: cleanClientName,
            clientPhone: cleanClientPhone,
            bookingDate: date,
            startTime: startTime,
            endTime: endTime,
            serviceName: service.name,
            price: service.price,
            status: .pending
        )
        bookings.insert(booking, at: 0)

        guard !gateway.isConfigured || session != nil else {
            statusMessage = "訪客預約已保留在本機；正式寫入請先完成 Email 登入"
            return booking
        }

        do {
            try await gateway.createBooking(booking)
            statusMessage = "預約已寫入 Supabase"
        } catch {
            statusMessage = "預約已保留在本地，Supabase 寫入待重試"
        }

        return booking
    }

    func updateBooking(_ booking: Appointment, status: BookingStatus) async {
        guard let idx = bookings.firstIndex(where: { $0.id == booking.id }) else { return }
        bookings[idx].status = status

        do {
            try await gateway.updateBookingStatus(id: booking.id, status: status)
            statusMessage = "預約狀態已同步"
        } catch {
            statusMessage = "狀態已在本地更新，Supabase 同步失敗"
        }
    }

    func cancelBooking(_ booking: Appointment) async {
        await updateBooking(booking, status: .cancelled)
    }

    func saveStylist(_ stylist: Stylist) async {
        guard let idx = stylists.firstIndex(where: { $0.id == stylist.id }) else { return }
        stylists[idx] = stylist

        do {
            try await gateway.saveStylist(stylist)
            statusMessage = "髮型師名片已同步到 Supabase"
        } catch {
            statusMessage = "名片已本地更新，Supabase 同步失敗"
        }
    }

    func insertOrSaveStylist(_ stylist: Stylist) async {
        if let index = stylists.firstIndex(where: { $0.id == stylist.id }) {
            stylists[index] = stylist
        } else {
            stylists.insert(stylist, at: 0)
        }

        do {
            try await gateway.saveStylist(stylist)
            statusMessage = "髮型師檔案已同步到 Supabase"
        } catch {
            statusMessage = "髮型師檔案已本地建立，Supabase 同步失敗"
        }
    }

    func saveSalon(_ salon: Salon, works: [PortfolioWork]) async {
        if let index = salons.firstIndex(where: { $0.id == salon.id }) {
            salons[index] = salon
        } else {
            salons.insert(salon, at: 0)
        }
        salonWorks[salon.id] = works

        do {
            try await gateway.saveSalon(salon, works: works)
            statusMessage = "沙龍檔案已同步到 Supabase"
        } catch {
            statusMessage = "沙龍檔案已本地建立，Supabase 同步失敗"
        }
    }

    @discardableResult
    func submitStylistApplication(_ stylist: Stylist) async -> Bool {
        guard gateway.isConfigured, currentProfile != nil else {
            statusMessage = "請先登入正式帳號，才可以提交髮型師申請"
            return false
        }

        do {
            try await gateway.submitStylistApplication(stylist)
            currentProfile?.displayName = stylist.name
            currentProfile?.avatarURL = stylist.avatarURL
            try? await gateway.updateProfile(displayName: stylist.name, avatarURL: stylist.avatarURL)
            await refreshCatalog()
            statusMessage = "已提交，等待審批"
            return true
        } catch {
            statusMessage = "髮型師申請提交失敗，請稍後再試"
        }
        return false
    }

    @discardableResult
    func submitSalonApplication(_ salon: Salon, works: [PortfolioWork]) async -> Bool {
        guard gateway.isConfigured, currentProfile != nil else {
            statusMessage = "請先登入正式帳號，才可以提交沙龍申請"
            return false
        }

        do {
            try await gateway.submitSalonApplication(salon, works: works)
            await refreshCatalog()
            statusMessage = "已提交，等待審批"
            return true
        } catch {
            statusMessage = "沙龍申請提交失敗，請稍後再試"
        }
        return false
    }

    func uploadProfileMediaIfNeeded(_ urlString: String, folder: String) async -> String {
        let clean = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.hasPrefix("file://"), let fileURL = URL(string: clean) else { return clean }
        guard gateway.isConfigured, (try? await gateway.currentSession()) != nil else { return clean }
        do {
            let originalData = try Data(contentsOf: fileURL)
            let uploadData = UIImage(data: originalData)?.jpegData(compressionQuality: 0.88) ?? originalData
            return try await gateway.uploadMedia(data: uploadData, folder: folder, mediaKind: .photo) ?? clean
        } catch {
            statusMessage = "圖片上載失敗，已保留本機圖片"
            return clean
        }
    }

    func uploadPortfolioWorksIfNeeded(_ works: [PortfolioWork], folder: String) async -> [PortfolioWork] {
        var uploaded: [PortfolioWork] = []
        for work in works {
            var mutable = work
            mutable.imageURL = await uploadProfileMediaIfNeeded(work.imageURL, folder: folder)
            guard isPersistableRemoteMediaURL(mutable.imageURL) else { continue }
            uploaded.append(mutable)
        }
        return uploaded
    }

    private func isPersistableRemoteMediaURL(_ urlString: String) -> Bool {
        let clean = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return false }
        guard let url = URL(string: clean), let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    func refreshAdminStatus() async {
        guard gateway.isConfigured else {
            isAdmin = false
            return
        }
        do {
            isAdmin = try await gateway.currentAdminRole() != nil
        } catch {
            isAdmin = false
        }
    }

    func approveStylistApplication(_ application: StylistApplication) async {
        do {
            try await gateway.approveStylistApplication(application)
            await refreshCatalog()
            statusMessage = "\(application.name) 已批准並公開到 Supabase"
        } catch {
            statusMessage = "髮型師申請批准失敗"
        }
    }

    func rejectStylistApplication(_ application: StylistApplication) async {
        do {
            try await gateway.rejectStylistApplication(application)
            await refreshCatalog()
            statusMessage = "\(application.name) 申請已拒絕"
        } catch {
            statusMessage = "髮型師申請拒絕失敗"
        }
    }

    func approveSalonApplication(_ application: SalonApplication) async {
        do {
            try await gateway.approveSalonApplication(application)
            await refreshCatalog()
            statusMessage = "\(application.name) 已批准並公開到 Supabase"
        } catch {
            statusMessage = "沙龍申請批准失敗"
        }
    }

    func rejectSalonApplication(_ application: SalonApplication) async {
        do {
            try await gateway.rejectSalonApplication(application)
            await refreshCatalog()
            statusMessage = "\(application.name) 申請已拒絕"
        } catch {
            statusMessage = "沙龍申請拒絕失敗"
        }
    }

    func promoteStylistOnHome(_ stylist: Stylist) async {
        do {
            try await gateway.updateStylistAdminState(id: stylist.id, isActive: true, isFeatured: true, displayOrder: 1)
            statusMessage = "\(stylist.name) 已設為首頁優先髮型師"
            await refreshCatalog()
        } catch {
            statusMessage = "首頁排序更新失敗"
        }
    }

    func hideStylistFromCatalog(_ stylist: Stylist) async {
        do {
            try await gateway.updateStylistAdminState(id: stylist.id, isActive: false, isFeatured: false, displayOrder: 999)
            try await gateway.markStylistApplicationsHidden(stylistID: stylist.id)
            await refreshCatalog()
            statusMessage = "\(stylist.name) 已下架"
        } catch {
            statusMessage = "髮型師下架失敗"
        }
    }

    func promoteSalonOnHome(_ salon: Salon) async {
        do {
            try await gateway.updateSalonAdminState(id: salon.id, isActive: true, isFeatured: true, displayOrder: 1)
            statusMessage = "\(salon.name) 已設為首頁優先沙龍"
            await refreshCatalog()
        } catch {
            statusMessage = "沙龍排序更新失敗"
        }
    }

    func hideSalonFromCatalog(_ salon: Salon) async {
        do {
            try await gateway.updateSalonAdminState(id: salon.id, isActive: false, isFeatured: false, displayOrder: 999)
            try await gateway.markSalonApplicationsHidden(salonID: salon.id)
            await refreshCatalog()
            statusMessage = "\(salon.name) 已下架"
        } catch {
            statusMessage = "沙龍下架失敗"
        }
    }

    func pinRanking(itemID: String, itemType: String, rankingKey: String, title: String, score: Double?) async {
        do {
            try await gateway.pinRankingItem(
                rankingKey: rankingKey,
                itemType: itemType,
                itemID: itemID,
                manualRank: 1,
                scoreOverride: score
            )
            statusMessage = "\(title) 已置頂排行榜"
            await refreshCatalog()
        } catch {
            statusMessage = "排行榜置頂失敗"
        }
    }

    func rankingPosition(itemID: String, itemType: String, rankingKey: String) -> Int {
        rankingOverrides.first {
            $0.itemID == itemID && $0.itemType == itemType && $0.rankingKey == rankingKey
        }?.manualRank ?? 0
    }

    func updateStylistAdminPlacement(_ stylist: Stylist, homePosition: Int, rankingPosition: Int) async {
        do {
            let normalizedHomePosition = max(0, min(12, homePosition))
            let normalizedRankingPosition = max(0, min(20, rankingPosition))

            try await gateway.updateStylistAdminState(
                id: stylist.id,
                isActive: true,
                isFeatured: normalizedHomePosition > 0,
                displayOrder: normalizedHomePosition > 0 ? normalizedHomePosition : 100
            )
            try await gateway.setRankingItem(
                rankingKey: "stylist_hot",
                itemType: "stylist",
                itemID: stylist.id,
                manualRank: normalizedRankingPosition > 0 ? normalizedRankingPosition : nil,
                scoreOverride: normalizedRankingPosition > 0 ? stylist.rating : nil
            )

            statusMessage = "\(stylist.name) 排序已更新"
            await refreshCatalog()
        } catch {
            statusMessage = "髮型師排序保存失敗"
        }
    }

    func updateSalonAdminPlacement(_ salon: Salon, homePosition: Int, rankingPosition: Int) async {
        do {
            let normalizedHomePosition = max(0, min(12, homePosition))
            let normalizedRankingPosition = max(0, min(20, rankingPosition))

            try await gateway.updateSalonAdminState(
                id: salon.id,
                isActive: true,
                isFeatured: normalizedHomePosition > 0,
                displayOrder: normalizedHomePosition > 0 ? normalizedHomePosition : 100
            )
            try await gateway.setRankingItem(
                rankingKey: "salon_hot",
                itemType: "salon",
                itemID: salon.id,
                manualRank: normalizedRankingPosition > 0 ? normalizedRankingPosition : nil,
                scoreOverride: normalizedRankingPosition > 0 ? salon.rating : nil
            )

            statusMessage = "\(salon.name) 排序已更新"
            await refreshCatalog()
        } catch {
            statusMessage = "沙龍排序保存失敗"
        }
    }

    func addReview(stylistID: String, reviewerName: String, text: String, stars: Int, reviewPhotoData: Data? = nil) {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty, let idx = stylists.firstIndex(where: { $0.id == stylistID }) else { return }

        let cleanName = reviewerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let review = ReviewItem(
            id: "rev_\(Int(Date().timeIntervalSince1970 * 1000))",
            stylistID: stylistID,
            reviewerName: cleanName.isEmpty ? commentDisplayName : cleanName,
            reviewerAvatar: commentAvatarURL,
            text: cleanText,
            stars: max(1, min(5, stars)),
            timeAgo: "剛剛",
            reviewPhotoData: reviewPhotoData
        )

        stylists[idx].reviews.insert(review, at: 0)
        stylists[idx].reviewsCount = stylists[idx].reviews.count
        let total = stylists[idx].reviews.reduce(0) { $0 + $1.stars }
        stylists[idx].rating = Double(total) / Double(max(1, stylists[idx].reviews.count))
        statusMessage = "評價已發表"

        Task {
            guard gateway.isConfigured else { return }
            guard let session = try? await gateway.currentSession() else {
                statusMessage = "訪客評價已保留在本機；登入後可同步到 Supabase"
                return
            }

            do {
                let photoURL: String?
                if let reviewPhotoData {
                    photoURL = try await gateway.uploadMedia(data: reviewPhotoData, folder: "reviews", mediaKind: .photo)
                } else {
                    photoURL = nil
                }

                var persistedReview = review
                persistedReview.reviewerID = session.user.id
                persistedReview.reviewPhotoURL = photoURL
                try await gateway.createReview(persistedReview, reviewerID: session.user.id, reviewPhotoURL: photoURL)

                if let stylistIndex = stylists.firstIndex(where: { $0.id == stylistID }),
                   let reviewIndex = stylists[stylistIndex].reviews.firstIndex(where: { $0.id == review.id }) {
                    stylists[stylistIndex].reviews[reviewIndex].reviewerID = session.user.id
                    stylists[stylistIndex].reviews[reviewIndex].reviewPhotoURL = photoURL
                }
                await refreshCatalog()
                statusMessage = "評價已同步到 Supabase"
            } catch {
                statusMessage = "評價已本地發表，Supabase 同步失敗"
            }
        }
    }

    func shareHairLook(_ look: SharedHairLook) {
        sharedLooks.insert(look, at: 0)
        statusMessage = "髮型分享已發佈到靈感頁"

        Task {
            guard gateway.isConfigured else { return }
            guard let session = try? await gateway.currentSession() else {
                statusMessage = "訪客靈感已保留在本機；登入後可同步到 Supabase"
                return
            }

            do {
                var mediaURLs: [String] = []
                var mediaKinds: [SharedLookMediaKind] = []
                let mediaItems = look.mediaItems.isEmpty
                    ? [SharedLookMedia(imageURL: look.imageURL, mediaData: look.mediaData, mediaKind: look.mediaKind)]
                    : look.mediaItems

                for item in mediaItems {
                    if let data = item.mediaData,
                       let publicURL = try await gateway.uploadMedia(data: data, folder: "inspiration", mediaKind: item.mediaKind) {
                        mediaURLs.append(publicURL)
                        mediaKinds.append(item.mediaKind)
                    } else if let imageURL = item.imageURL {
                        mediaURLs.append(imageURL)
                        mediaKinds.append(item.mediaKind)
                    }
                }

                if mediaURLs.isEmpty, let imageURL = look.imageURL {
                    mediaURLs.append(imageURL)
                    mediaKinds.append(look.mediaKind)
                }

                let persistedKinds = mediaKinds.isEmpty ? mediaURLs.map { _ in look.mediaKind } : mediaKinds

                try await gateway.createInspirationPost(
                    look,
                    authorID: session.user.id,
                    mediaURLs: mediaURLs,
                    mediaKinds: persistedKinds
                )

                if let index = sharedLooks.firstIndex(where: { $0.id == look.id }) {
                    sharedLooks[index].imageURL = mediaURLs.first ?? sharedLooks[index].imageURL
                    sharedLooks[index].mediaItems = zip(mediaURLs, persistedKinds).map { url, kind in
                        SharedLookMedia(imageURL: url, mediaData: nil, mediaKind: kind)
                    }
                }
                await refreshCatalog()
                if inspiration.contains(where: { $0.id == look.id }) {
                    sharedLooks.removeAll { $0.id == look.id }
                }
                statusMessage = "靈感分享已同步到 Supabase"
            } catch {
                statusMessage = "靈感已本地發佈，Supabase 同步失敗"
            }
        }
    }

    func comments(for lookID: String) -> [LookCommentItem] {
        inspirationComments[lookID] ?? []
    }

    func totalCommentCount(for lookID: String) -> Int {
        comments(for: lookID).reduce(0) { $0 + flattenedCommentCount($1) }
    }

    func toggleInspirationLike(_ look: SharedHairLook) {
        let willLike = !likedLookIDs.contains(look.id)
        if willLike {
            likedLookIDs.insert(look.id)
            updateInspirationEngagement(lookID: look.id, likeDelta: 1)
        } else {
            likedLookIDs.remove(look.id)
            updateInspirationEngagement(lookID: look.id, likeDelta: -1)
        }

        Task {
            guard gateway.isConfigured else { return }
            guard (try? await gateway.currentSession()) != nil else {
                statusMessage = "訪客讚好已保留在本機；登入後可同步到 Supabase"
                return
            }
            do {
                try await gateway.toggleInspirationLike(inspirationID: look.id, isLiked: willLike)
            } catch {
                statusMessage = "讚好同步失敗，已暫存在本機"
            }
        }
    }

    func recordInspirationShare(_ look: SharedHairLook) {
        updateInspirationEngagement(lookID: look.id, shareDelta: 1)
        Task {
            guard gateway.isConfigured else { return }
            do {
                try await gateway.recordInspirationShare(inspirationID: look.id)
                statusMessage = "分享數已同步"
            } catch {
                statusMessage = "分享已記錄在本機，Supabase 同步失敗"
            }
        }
    }

    func addInspirationComment(lookID: String, parentID: String?, text: String) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        if inspirationComments[lookID] == nil {
            inspirationComments[lookID] = []
        }

        let persistedParentID = parentID.flatMap { containsComment(id: $0, in: inspirationComments[lookID] ?? []) ? $0 : nil }
        let comment = LookCommentItem(
            id: "comment_\(Int(Date().timeIntervalSince1970 * 1000))",
            inspirationID: lookID,
            parentID: persistedParentID,
            authorID: currentProfile?.id,
            author: commentDisplayName,
            avatarURL: commentAvatarURL,
            timeAgo: "剛剛",
            text: clean,
            likes: 0,
            replies: [],
            isCreator: false
        )

        appendComment(comment, lookID: lookID, parentID: persistedParentID)
        updateInspirationEngagement(lookID: lookID, commentDelta: 1)
        statusMessage = "留言已發表"

        Task {
            guard gateway.isConfigured else { return }
            guard (try? await gateway.currentSession()) != nil else {
                statusMessage = "訪客留言已保留在本機；登入後可同步到 Supabase"
                return
            }
            do {
                try await gateway.addInspirationComment(comment, inspirationID: lookID, parentID: persistedParentID)
                statusMessage = "留言已同步到 Supabase"
            } catch {
                statusMessage = "留言已本地發表，Supabase 同步失敗"
            }
        }
    }

    func toggleInspirationCommentLike(_ comment: LookCommentItem) {
        let willLike = !likedCommentIDs.contains(comment.id)
        if willLike {
            likedCommentIDs.insert(comment.id)
            mutateComment(comment.id) { $0.likes += 1 }
        } else {
            likedCommentIDs.remove(comment.id)
            mutateComment(comment.id) { $0.likes = max(0, $0.likes - 1) }
        }

        Task {
            guard gateway.isConfigured else { return }
            guard (try? await gateway.currentSession()) != nil else {
                statusMessage = "訪客留言讚好已保留在本機"
                return
            }
            do {
                try await gateway.toggleInspirationCommentLike(commentID: comment.id, isLiked: willLike)
            } catch {
                statusMessage = "留言讚好同步失敗，已暫存在本機"
            }
        }
    }

    private func updateInspirationEngagement(lookID: String, likeDelta: Int = 0, commentDelta: Int = 0, shareDelta: Int = 0) {
        if let index = inspiration.firstIndex(where: { $0.id == lookID }) {
            inspiration[index].likeCount = max(0, inspiration[index].likeCount + likeDelta)
            inspiration[index].commentCount = max(0, inspiration[index].commentCount + commentDelta)
            inspiration[index].shareCount = max(0, inspiration[index].shareCount + shareDelta)
        }
        if let index = sharedLooks.firstIndex(where: { $0.id == lookID }) {
            sharedLooks[index].likes = max(0, sharedLooks[index].likes + likeDelta)
            sharedLooks[index].commentCount = max(0, sharedLooks[index].commentCount + commentDelta)
            sharedLooks[index].shareCount = max(0, sharedLooks[index].shareCount + shareDelta)
        }
    }

    private func appendComment(_ comment: LookCommentItem, lookID: String, parentID: String?) {
        var current = inspirationComments[lookID] ?? []
        guard let parentID else {
            current.insert(comment, at: 0)
            inspirationComments[lookID] = current
            return
        }
        if !appendNestedComment(comment, parentID: parentID, comments: &current) {
            current.insert(comment, at: 0)
        }
        inspirationComments[lookID] = current
    }

    private func appendNestedComment(_ comment: LookCommentItem, parentID: String, comments: inout [LookCommentItem]) -> Bool {
        for index in comments.indices {
            if comments[index].id == parentID {
                comments[index].replies.append(comment)
                return true
            }
            if appendNestedComment(comment, parentID: parentID, comments: &comments[index].replies) {
                return true
            }
        }
        return false
    }

    private func mutateComment(_ commentID: String, mutate: (inout LookCommentItem) -> Void) {
        for lookID in Array(inspirationComments.keys) {
            var current = inspirationComments[lookID] ?? []
            if mutateNestedComment(commentID, comments: &current, mutate: mutate) {
                inspirationComments[lookID] = current
                return
            }
        }
    }

    private func mutateNestedComment(_ commentID: String, comments: inout [LookCommentItem], mutate: (inout LookCommentItem) -> Void) -> Bool {
        for index in comments.indices {
            if comments[index].id == commentID {
                mutate(&comments[index])
                return true
            }
            if mutateNestedComment(commentID, comments: &comments[index].replies, mutate: mutate) {
                return true
            }
        }
        return false
    }

    private func containsComment(id: String, in comments: [LookCommentItem]) -> Bool {
        comments.contains { comment in
            comment.id == id || containsComment(id: id, in: comment.replies)
        }
    }

    private func flattenedCommentCount(_ comment: LookCommentItem) -> Int {
        1 + comment.replies.reduce(0) { $0 + flattenedCommentCount($1) }
    }

    func sendMessage(text: String, stylistID: String = "master-leo", sender: UserRole = .customer, customerID: UUID? = nil) async {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let session = isLocalExperience ? nil : (try? await gateway.currentSession())
        let resolvedCustomerID: UUID?
        if sender == .stylist {
            resolvedCustomerID = customerID
        } else {
            resolvedCustomerID = customerID ?? session?.user.id ?? currentProfile?.id
        }
        let now = Date()
        let message = ChatMessageItem(
            id: "msg_\(Int(Date().timeIntervalSince1970 * 1000))",
            customerID: resolvedCustomerID,
            stylistID: stylistID,
            senderRole: sender,
            senderName: sender == .stylist ? stylist(id: stylistID).name : (currentProfile?.displayName.nilIfEmpty ?? "Hairmap 顧客"),
            text: clean,
            sentAt: DateFormatter.hmTime.string(from: now),
            createdAt: ISO8601DateFormatter().string(from: now)
        )
        messages.append(message)

        guard !gateway.isConfigured || session != nil else {
            statusMessage = "訪客訊息已保留在本機；正式同步請先完成 Email 登入"
            return
        }

        do {
            try await gateway.insertMessage(message)
            statusMessage = "訊息已同步"
        } catch {
            statusMessage = "訊息已本地送出，Supabase 同步失敗"
        }
    }

    func sendChatPhoto(data: Data, stylistID: String, sender: UserRole = .customer, customerID: UUID? = nil) async {
        guard !isLocalExperience, gateway.isConfigured, (try? await gateway.currentSession()) != nil else {
            statusMessage = "請先登入，才可以分享照片給髮型師"
            return
        }

        do {
            let uploadData = UIImage(data: data)?.jpegData(compressionQuality: 0.88) ?? data
            guard let url = try await gateway.uploadMedia(data: uploadData, folder: "chat", mediaKind: .photo) else {
                statusMessage = "照片上載失敗，請稍後再試"
                return
            }
            await sendMessage(text: ChatMessageItem.photoMessageText(url: url), stylistID: stylistID, sender: sender, customerID: customerID)
            statusMessage = "照片已傳送"
        } catch {
            statusMessage = "照片上載失敗，請稍後再試"
        }
    }

    var customerUnreadMessageCount: Int {
        guard currentProfile?.role == .customer else { return 0 }
        return customerMessages
            .filter { $0.senderRole == .stylist && !customerReadMessageIDs.contains($0.id) }
            .count
    }

    func customerUnreadStylistIDs() -> Set<String> {
        Set(customerMessages.filter { $0.senderRole == .stylist && !customerReadMessageIDs.contains($0.id) }.map(\.stylistID))
    }

    func markCustomerThreadRead(stylistID: String) {
        let ids = customerMessages
            .filter { $0.stylistID == stylistID && $0.senderRole == .stylist }
            .map(\.id)
        customerReadMessageIDs.formUnion(ids)
    }

    func stylistUnreadMessageCount(stylistID: String) -> Int {
        messages
            .filter { $0.stylistID == stylistID && $0.senderRole == .customer && !stylistReadMessageIDs.contains($0.id) }
            .count
    }

    func isStylistMessageUnread(_ message: ChatMessageItem) -> Bool {
        message.senderRole == .customer && !stylistReadMessageIDs.contains(message.id)
    }

    func markStylistThreadRead(stylistID: String, threadID: String) {
        let ids = messages
            .filter {
                $0.stylistID == stylistID &&
                $0.senderRole == .customer &&
                ($0.customerID?.uuidString ?? "guest-\($0.senderName)") == threadID
            }
            .map(\.id)
        stylistReadMessageIDs.formUnion(ids)
    }

    func submitReport(entityType: ReportEntityType, entityID: String, reason: String, details: String = "") {
        Task {
            guard gateway.isConfigured else {
                statusMessage = "檢舉已記錄在本機；正式同步請先連接 Supabase"
                return
            }
            guard !isLocalExperience else {
                statusMessage = "訪客檢舉已記錄在本機；登入後可同步到 Supabase"
                return
            }
            guard (try? await gateway.currentSession()) != nil else {
                statusMessage = "請先登入，才可以提交檢舉"
                return
            }

            do {
                try await gateway.createReport(entityType: entityType, entityID: entityID, reason: reason, details: details)
                statusMessage = "檢舉已提交，我們會盡快審查"
            } catch {
                statusMessage = "檢舉提交失敗，請稍後再試"
            }
        }
    }

    func canBlockUser(_ userID: UUID?) -> Bool {
        guard let userID else { return false }
        guard userID != currentProfile?.id else { return false }
        return !blockedUserIDs.contains(userID)
    }

    func blockUser(
        _ userID: UUID,
        sourceEntityType: ReportEntityType,
        sourceEntityID: String,
        sourceTitle: String
    ) {
        guard userID != currentProfile?.id else {
            statusMessage = "不能封鎖自己的帳號"
            return
        }

        blockedUserIDs.insert(userID)
        applyBlockedUserFilter()
        statusMessage = "已封鎖此用戶，相關內容已即時移除"

        let cleanTitle = sourceTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let details = cleanTitle.isEmpty ? "User blocked from Hairmap app." : cleanTitle

        Task {
            guard gateway.isConfigured else {
                statusMessage = "封鎖已保留在本機；正式同步請先連接 Supabase"
                return
            }
            guard !isLocalExperience else {
                statusMessage = "訪客封鎖已保留在本機"
                return
            }
            guard (try? await gateway.currentSession()) != nil else {
                statusMessage = "請先登入，才可以同步封鎖"
                return
            }

            do {
                try await gateway.setUserBlocked(
                    blockedUserID: userID,
                    sourceEntityType: sourceEntityType,
                    sourceEntityID: sourceEntityID,
                    reason: "封鎖並檢舉用戶",
                    details: details,
                    isBlocked: true
                )
                statusMessage = "已封鎖並提交檢舉，我們會盡快審查"
            } catch {
                statusMessage = "已本地封鎖，伺服器同步失敗"
            }
        }
    }

    private func applyBlockedUserFilter() {
        inspiration.removeAll { isProfileBlocked($0.authorID, in: blockedUserIDs) }
        sharedLooks.removeAll { isProfileBlocked($0.authorID, in: blockedUserIDs) }
        inspirationComments = filterBlockedComments(inspirationComments, blockedUserIDs: blockedUserIDs)
        stylists = filterBlockedReviews(in: stylists, blockedUserIDs: blockedUserIDs)
    }

    private func filterBlockedReviews(in stylists: [Stylist], blockedUserIDs: Set<UUID>) -> [Stylist] {
        stylists.map { stylist in
            var filtered = stylist
            filtered.reviews.removeAll { isProfileBlocked($0.reviewerID, in: blockedUserIDs) }
            filtered.reviewsCount = filtered.reviews.count
            return filtered
        }
    }

    private func filterBlockedComments(
        _ commentsByLookID: [String: [LookCommentItem]],
        blockedUserIDs: Set<UUID>
    ) -> [String: [LookCommentItem]] {
        commentsByLookID.reduce(into: [:]) { result, pair in
            let comments = pair.value.compactMap { filterBlockedComment($0, blockedUserIDs: blockedUserIDs) }
            if !comments.isEmpty {
                result[pair.key] = comments
            }
        }
    }

    private func filterBlockedComment(_ comment: LookCommentItem, blockedUserIDs: Set<UUID>) -> LookCommentItem? {
        guard !isProfileBlocked(comment.authorID, in: blockedUserIDs) else { return nil }
        var filtered = comment
        filtered.replies = comment.replies.compactMap { filterBlockedComment($0, blockedUserIDs: blockedUserIDs) }
        return filtered
    }

    private func isProfileBlocked(_ userID: UUID?, in blockedUserIDs: Set<UUID>) -> Bool {
        guard let userID else { return false }
        return blockedUserIDs.contains(userID)
    }

    func recallMessage(id: String) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        let replacementText = "⚠️ 此則訊息已被您成功撒回"
        messages[index].text = replacementText
        statusMessage = "訊息已撒回"

        Task {
            guard gateway.isConfigured else { return }
            guard !isLocalExperience else {
                statusMessage = "訪客訊息撤回已保留在本機"
                return
            }
            guard (try? await gateway.currentSession()) != nil else {
                statusMessage = "訪客訊息撤回已保留在本機"
                return
            }
            do {
                try await gateway.recallMessage(id: id, replacementText: replacementText)
                statusMessage = "訊息撤回已同步"
            } catch {
                statusMessage = "訊息已本地撤回，Supabase 同步失敗"
            }
        }
    }

    func isChatBlocked(stylistID: String) -> Bool {
        blockedChatStylistIDs.contains(stylistID)
    }

    func toggleChatBlock(stylistID: String) {
        let willBlock = !blockedChatStylistIDs.contains(stylistID)
        if willBlock {
            blockedChatStylistIDs.insert(stylistID)
        } else {
            blockedChatStylistIDs.remove(stylistID)
        }

        Task {
            guard gateway.isConfigured else { return }
            guard !isLocalExperience else {
                statusMessage = willBlock ? "訪客封鎖已保留在本機" : "訪客已解除本機封鎖"
                return
            }
            guard (try? await gateway.currentSession()) != nil else {
                statusMessage = willBlock ? "訪客封鎖已保留在本機" : "訪客已解除本機封鎖"
                return
            }
            do {
                try await gateway.setConversationBlocked(stylistID: stylistID, isBlocked: willBlock)
                statusMessage = willBlock ? "聊天室封鎖已同步" : "聊天室已解除封鎖"
            } catch {
                statusMessage = "封鎖狀態已本地更新，Supabase 同步失敗"
            }
        }
    }

    @discardableResult
    func setBlockedSlot(stylistID: String, date: String, time: String, shouldBlock: Bool) async -> Bool {
        let normalizedTime = time.hmTimeKey
        let existingIndex = blockedSlots.firstIndex {
            $0.stylistID == stylistID && $0.workDate == date && $0.startTime.hmTimeKey == normalizedTime
        }
        let slot = existingIndex.map { blockedSlots[$0] }
            ?? BlockedSlot(id: UUID(), stylistID: stylistID, workDate: date, startTime: normalizedTime)
        let previousSlots = blockedSlots

        if shouldBlock {
            if existingIndex == nil {
                blockedSlots.append(slot)
            }
        } else if let existingIndex {
            blockedSlots.remove(at: existingIndex)
        }

        guard gateway.isConfigured else {
            statusMessage = shouldBlock ? "時段已在本機標記忙碌" : "時段已在本機重新開放"
            return true
        }

        guard (try? await gateway.currentSession()) != nil else {
            blockedSlots = previousSlots
            statusMessage = "請先登入髮型師帳號，才可以同步檔期"
            return false
        }

        do {
            try await gateway.toggleBlockedSlot(slot, shouldBlock: shouldBlock)
            statusMessage = shouldBlock ? "忙碌時段已同步到 Supabase" : "時段已重新開放並同步"
            return true
        } catch {
            blockedSlots = previousSlots
            statusMessage = "檔期同步失敗，請稍後再試"
            return false
        }
    }

    func toggleBlockedSlot(stylistID: String, date: String, time: String) async {
        let normalizedTime = time.hmTimeKey
        if let index = blockedSlots.firstIndex(where: { $0.stylistID == stylistID && $0.workDate == date && $0.startTime.hmTimeKey == normalizedTime }) {
            let removed = blockedSlots.remove(at: index)
            try? await gateway.toggleBlockedSlot(removed, shouldBlock: false)
        } else {
            let slot = BlockedSlot(id: UUID(), stylistID: stylistID, workDate: date, startTime: normalizedTime)
            blockedSlots.append(slot)
            try? await gateway.toggleBlockedSlot(slot, shouldBlock: true)
        }
    }

    func isBlocked(stylistID: String, date: String, time: String) -> Bool {
        let normalizedTime = time.hmTimeKey
        return blockedSlots.contains { $0.stylistID == stylistID && $0.workDate == date && $0.startTime.hmTimeKey == normalizedTime }
    }

    func handleDeepLink(_ url: URL) {
        let isRecovery = isPasswordRecoveryURL(url)
        statusMessage = "正在完成 Supabase 登入..."
        Task { [weak self] in
            do {
                guard let self else { return }
                if let session = try await self.gateway.session(from: url) {
                    let resolvedSession = await self.completePendingSocialRoleIfNeeded(session)
                    self.applySession(resolvedSession)
                    if isRecovery || self.expectsPasswordReset {
                        self.expectsPasswordReset = true
                        self.isPasswordResetSheetPresented = true
                        self.statusMessage = "請設定新的登入密碼"
                    } else {
                        await self.refreshCatalog()
                    }
                } else {
                    await self.finishDeepLinkSignIn()
                }
            } catch {
                self?.statusMessage = self?.deepLinkErrorMessage(for: error) ?? "登入連結無效，請重新發送"
            }
        }
    }

    private func listenForAuthChanges() {
        guard authTask == nil, let stream = gateway.authStateChanges() else { return }
        authTask = Task { [weak self] in
            for await (event, session) in stream {
                await MainActor.run {
                    if let session {
                        guard self?.isResolvingAuthenticatedRole != true,
                              self?.pendingSocialRole == nil
                        else { return }
                        self?.applySession(session)
                    } else if self?.isLocalExperience != true {
                        self?.clearPrivateSessionState()
                        self?.currentProfile = nil
                        self?.isAdmin = false
                        self?.isLocalExperience = false
                    }
                    if event == .passwordRecovery {
                        self?.expectsPasswordReset = true
                        self?.isPasswordResetSheetPresented = true
                        self?.statusMessage = "請設定新的登入密碼"
                    }
                }
            }
        }
    }

    private func listenForRealtimeChanges() {
        guard realtimeTask == nil, let stream = gateway.catalogRealtimeChanges() else { return }
        realtimeTask = Task { [weak self] in
            for await _ in stream {
                self?.scheduleRealtimeRefresh()
            }
        }
    }

    private func scheduleRealtimeRefresh() {
        realtimeRefreshTask?.cancel()
        realtimeRefreshTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 650_000_000)
            await self?.refreshCatalog(showLoading: false)
        }
    }

    private func applySession(_ session: Session) {
        isLocalExperience = false
        let metadata = session.user.userMetadata
        let name = metadata["display_name"]?.stringValue ?? session.user.email ?? "Hairmap User"
        let roleValue = metadata["role"]?.stringValue ?? UserRole.customer.rawValue
        let role = UserRole(rawValue: roleValue) ?? .customer
        currentProfile = HairmapProfile(
            id: session.user.id,
            displayName: name,
            email: session.user.email ?? "",
            role: role,
            stylistID: role == .stylist ? metadata["stylist_id"]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty : nil
        )
        requestNotificationPermissionIfNeeded()
        statusMessage = "Supabase session 已啟用"
        Task {
            await refreshCurrentProfile()
            await refreshAdminStatus()
        }
    }

    private func finishDeepLinkSignIn() async {
        guard let session = try? await gateway.currentSession() else {
            statusMessage = "未能建立登入 session，請使用最新一封 Email 連結再試"
            return
        }
        let resolvedSession = await completePendingSocialRoleIfNeeded(session)
        applySession(resolvedSession)
        await refreshCatalog()
    }

    private var pendingSocialRole: UserRole? {
        get {
            guard let raw = UserDefaults.standard.string(forKey: pendingSocialRoleKey) else { return nil }
            return UserRole(rawValue: raw)
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue.rawValue, forKey: pendingSocialRoleKey)
            } else {
                UserDefaults.standard.removeObject(forKey: pendingSocialRoleKey)
            }
        }
    }

    private func completePendingSocialRoleIfNeeded(_ session: Session) async -> Session {
        guard let role = pendingSocialRole else { return session }
        do {
            let resolvedSession = try await enforceAuthenticatedRole(role, session: session, provider: nil)
            pendingSocialRole = nil
            return resolvedSession
        } catch {
            statusMessage = authErrorMessage(for: error)
            return session
        }
    }

    private func enforceAuthenticatedRole(_ role: UserRole, session: Session, provider: SocialAuthProvider?) async throws -> Session {
        let existingProfile = try? await gateway.currentProfile()
        let metadata = session.user.userMetadata
        let metadataName = metadata["display_name"]?.stringValue?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let providerName = metadata["full_name"]?.stringValue?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let email = session.user.email ?? existingProfile?.email ?? ""
        let fallbackName = role == .stylist ? "待建立髮型師" : "\(provider?.title ?? "Hairmap") 會員"
        let resolvedName = [
            existingProfile?.displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            metadataName,
            providerName,
            email,
            fallbackName
        ]
            .compactMap { $0 }
            .first { !$0.isEmpty } ?? fallbackName
        let resolvedStylistID = role == .stylist ? existingProfile?.stylistID : nil
        let profile = HairmapProfile(
            id: session.user.id,
            displayName: resolvedName,
            email: email,
            role: role,
            stylistID: resolvedStylistID,
            avatarURL: existingProfile?.avatarURL ?? ""
        )

        try await gateway.upsertProfile(profile)
        return try await gateway.updateAuthMetadata(
            displayName: resolvedName,
            role: role,
            stylistID: resolvedStylistID
        ) ?? session
    }

    private func refreshCurrentProfile() async {
        guard gateway.isConfigured else { return }
        guard let profile = try? await gateway.currentProfile() else { return }
        currentProfile = profile
        syncCurrentStylistProfileFromCatalog()
    }

    private var draftStylistID: String {
        guard let profileID = currentProfile?.id.uuidString.lowercased() else { return "pending-stylist-local" }
        return "pending-stylist-\(profileID.prefix(8))"
    }

    private func draftStylistProfile(id: String) -> Stylist {
        let displayName = normalizedDisplayName
        let avatar = currentProfile?.avatarURL.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return Stylist(
            id: id.isEmpty ? draftStylistID : id,
            ownerID: currentProfile?.id,
            salonID: salons.first?.id ?? "s1",
            name: displayName.isEmpty ? "待建立髮型師" : displayName,
            title: "請先提交髮型師檔案",
            rating: 0,
            reviewsCount: 0,
            languages: "中 / 粵 / 英",
            experience: "5年資歷",
            specialties: ["待審批"],
            avatarURL: avatar.isEmpty ? "https://api.dicebear.com/8.x/personas/png?seed=hairmap-stylist" : avatar,
            phone: "",
            bio: "",
            basePrice: 0,
            works: [],
            services: [],
            reviews: [],
            isActive: false,
            isFeatured: false,
            displayOrder: 999
        )
    }

    private func syncCurrentStylistProfileFromCatalog() {
        guard var profile = currentProfile, profile.role == .stylist else { return }
        if let stylistID = profile.stylistID,
           let linkedStylist = stylists.first(where: { $0.id == stylistID }) {
            if linkedStylist.ownerID == profile.id {
                profile.displayName = linkedStylist.name
                profile.avatarURL = linkedStylist.avatarURL
                currentProfile = profile
            } else {
                profile.stylistID = nil
                currentProfile = profile
            }
            return
        }

        if let owned = stylists.first(where: { $0.ownerID == profile.id }) {
            profile.stylistID = owned.id
            profile.displayName = owned.name
            profile.avatarURL = owned.avatarURL
            currentProfile = profile
        } else if profile.stylistID != nil {
            profile.stylistID = nil
            currentProfile = profile
        }
    }

    private func isRealEmail(_ email: String) -> Bool {
        email.contains("@") &&
            email.contains(".") &&
            !email.lowercased().hasSuffix(".local")
    }

    private func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var normalizedDisplayName: String {
        guard let profile = currentProfile else { return "" }
        let name = profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = profile.email.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = name.lowercased()
        let genericNames = [
            "hairmap guest",
            "google guest",
            "apple guest",
            "hairmap user",
            "hairmap 會員"
        ]

        if name.isEmpty || name == email || name.contains("@") || genericNames.contains(lower) {
            return ""
        }
        return name
    }

    private func isPasswordRecoveryURL(_ url: URL) -> Bool {
        let raw = (url.absoluteString.removingPercentEncoding ?? url.absoluteString).lowercased()
        return raw.contains("type=recovery") || raw.contains("recovery")
    }

    private func authErrorMessage(for error: Error, provider: SocialAuthProvider? = nil) -> String {
        let text = String(describing: error).lowercased()
        if text.contains("429") || text.contains("rate") || text.contains("over_email_send_rate_limit") || text.contains("email rate limit") {
            return "Email 寄送太頻密，請等 60 秒後再試，或先用 Google / Apple 登入"
        }
        if text.contains("smtp") || text.contains("email provider") || text.contains("send email") {
            return "確認信暫時未能送出，請檢查 Supabase SMTP 設定或稍後再試"
        }
        if let provider, text.contains("cancel") {
            return "\(provider.title) 登入已取消"
        }
        if let provider, text.contains("provider") || text.contains("oauth") || text.contains("unsupported") {
            return "請先到 Supabase Dashboard 開啟 \(provider.title) 登入 Provider"
        }
        if text.contains("email not confirmed") || text.contains("not confirmed") {
            return "請先完成 Email 確認，再使用密碼登入；未收到可在註冊頁重寄"
        }
        if text.contains("invalid login") || text.contains("invalid_credentials") || text.contains("credentials") {
            return "Email 或密碼不正確，請檢查後再試"
        }
        if text.contains("already registered") || text.contains("already exists") || text.contains("user already") {
            return "此 Email 已註冊，請直接登入"
        }
        if text.contains("redirect") {
            return "請先到 Supabase Redirect URLs 加入 hairmap://auth-callback"
        }
        if text.contains("invalid") || text.contains("email") {
            return "Email 無效，請輸入可接收確認信的真實 Email"
        }
        return "Supabase 登入請求失敗，請稍後再試"
    }

    private func deepLinkErrorMessage(for error: Error) -> String {
        let text = String(describing: error).lowercased()
        if text.contains("expired") || text.contains("otp") {
            return "重設密碼連結已過期，請重新按忘記密碼發送"
        }
        if text.contains("pkce") || text.contains("code") || text.contains("invalid") {
            return "這條重設連結無效，請用 App 內忘記密碼重新發送"
        }
        return "未能打開登入連結，請重新發送最新 Email link"
    }
}

extension String {
    var nilIfEmpty: String? {
        let clean = trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? nil : clean
    }

    var hmTimeKey: String {
        let clean = trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count >= 5 else { return clean }
        return String(clean.prefix(5))
    }
}

extension DateFormatter {
    static let hmTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hant_HK")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static let hmDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

extension Calendar {
    static let hairmap = Calendar(identifier: .gregorian)
}
