import Foundation
import Observation
import Supabase
import UIKit

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

    var salons: [Salon] = SeedData.salons
    var stylists: [Stylist] = SeedData.stylists
    var inspiration: [InspirationItem] = SeedData.inspiration
    var sharedLooks: [SharedHairLook] = SeedData.sharedLooks
    var bookings: [Appointment] = SeedData.bookings
    var messages: [ChatMessageItem] = SeedData.messages
    var blockedSlots: [BlockedSlot] = SeedData.blockedSlots
    var salonWorks: [String: [PortfolioWork]] = [:]
    var rankingOverrides: [RankingOverride] = []
    var pendingStylistApplications: [StylistApplication] = []
    var pendingSalonApplications: [SalonApplication] = []
    var inspirationComments: [String: [LookCommentItem]] = [:]
    var likedLookIDs: Set<String> = []
    var likedCommentIDs: Set<String> = []
    var blockedChatStylistIDs: Set<String> = []

    var currentProfile: HairmapProfile?
    var selectedTab: CustomerTab = .discovery
    var customerPath: [CustomerRoute] = []
    var selectedStylistID = "master-leo"
    var selectedSalonID = "s1"
    var selectedService: ServiceItem?
    var bookingSourceFromTab = false
    var statusMessage = "本地種子資料模式"
    var isLoading = false
    var isPasswordResetSheetPresented = false
    var isAdmin = false
    var isSupabaseConfigured: Bool { gateway.isConfigured }
    private var expectsPasswordReset = false

    init() {
        self.gateway = SupabaseGateway()
        statusMessage = gateway.isConfigured ? "Supabase 已配置" : "未配置 Supabase，使用本地種子資料"
    }

    init(gateway: SupabaseGateway) {
        self.gateway = gateway
        statusMessage = gateway.isConfigured ? "Supabase 已配置" : "未配置 Supabase，使用本地種子資料"
    }

    func bootstrap() async {
        listenForAuthChanges()
        await refreshCatalog()
        guard let session = try? await gateway.currentSession() else { return }
        applySession(session)
    }

    func refreshCatalog() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let payload = try await gateway.loadCatalog()
            salons = payload.salons
            stylists = payload.stylists
            inspiration = payload.inspiration
            if !payload.bookings.isEmpty { bookings = payload.bookings }
            messages = payload.messages
            blockedSlots = payload.blockedSlots
            salonWorks = payload.salonWorks
            rankingOverrides = payload.rankingOverrides
            pendingStylistApplications = payload.stylistApplications
            pendingSalonApplications = payload.salonApplications
            inspirationComments = payload.inspirationComments
            likedLookIDs = payload.likedLookIDs
            likedCommentIDs = payload.likedCommentIDs
            blockedChatStylistIDs = payload.blockedChatStylistIDs
            statusMessage = gateway.isConfigured ? "Supabase 同步完成" : "本地種子資料模式"
        } catch {
            statusMessage = "Supabase 讀取失敗，已保留本地資料"
        }
    }

    func start(displayName: String, email: String, role: UserRole) async {
        let cleanName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
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
            try await gateway.sendMagicLink(email: cleanEmail, displayName: displayName, role: role)
            currentProfile = nil
            statusMessage = "登入連結已寄出，請打開最新 Email 連結返回 Hairmap"
        } catch {
            statusMessage = authErrorMessage(for: error)
        }
    }

    func register(displayName: String, email: String, password: String, role: UserRole) async {
        let cleanName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
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
                await refreshCatalog()
            } else {
                currentProfile = nil
                statusMessage = "確認信已寄出，請完成 Email 確認後再用密碼登入"
            }
        } catch {
            statusMessage = authErrorMessage(for: error)
        }
    }

    func login(email: String, password: String, role: UserRole) async {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
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
            startLocal(displayName: role == .stylist ? "Master Leo" : "Hairmap 會員", email: cleanEmail, role: role)
            return
        }

        do {
            let session = try await gateway.signIn(email: cleanEmail, password: cleanPassword)
            if let session {
                applySession(session)
            } else if let current = try await gateway.currentSession() {
                applySession(current)
            }
            await refreshCatalog()
        } catch {
            statusMessage = authErrorMessage(for: error)
        }
    }

    func loginWithSocial(_ provider: SocialAuthProvider, role: UserRole = .customer) async {
        guard gateway.isConfigured else {
            startLocal(displayName: "\(provider.title) Guest", role: role)
            return
        }

        do {
            let session = try await gateway.signInWithOAuth(provider: provider.supabaseProvider)
            if let session {
                applySession(session)
            } else if let current = try await gateway.currentSession() {
                applySession(current)
            }
            await refreshCatalog()
        } catch {
            statusMessage = authErrorMessage(for: error, provider: provider)
        }
    }

    func sendPasswordReset(email: String) async {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

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
        isAdmin = false
        currentProfile = HairmapProfile(
            id: UUID(),
            displayName: cleanName.isEmpty ? "Hairmap Guest" : cleanName,
            email: email,
            role: role,
            stylistID: role == .stylist ? "master-leo" : nil
        )
        selectedTab = .discovery
        customerPath = []
        statusMessage = "訪客體驗模式：資料只會保留在本機"
    }

    func logout() async {
        await gateway.signOut()
        currentProfile = nil
        isAdmin = false
        selectedTab = .discovery
        selectedService = nil
        customerPath = []
        likedLookIDs = []
        likedCommentIDs = []
        blockedChatStylistIDs = []
        statusMessage = gateway.isConfigured ? "已登出 Supabase" : "已登出"
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

    func salon(id: String? = nil) -> Salon {
        let targetID = id ?? stylist().salonID
        return salons.first { $0.id == targetID } ?? salons[0]
    }

    var commentDisplayName: String {
        let name = normalizedDisplayName
        return name.isEmpty ? "訪客" : name
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
            guard gateway.isConfigured, (try? await gateway.currentSession()) != nil else { return }
            try? await gateway.updateProfileDisplayName(clean)
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
        let salon = salon(id: stylist.salonID)
        let session = try? await gateway.currentSession()
        let booking = Appointment(
            id: UUID(),
            customerID: session?.user.id ?? currentProfile?.id,
            stylistID: stylist.id,
            salonID: salon.id,
            serviceID: service.id,
            salonName: salon.name,
            stylistName: stylist.name,
            clientName: clientName,
            clientPhone: clientPhone,
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
        if isAdmin {
            await insertOrSaveStylist(stylist)
            return true
        }

        guard gateway.isConfigured, currentProfile != nil else {
            statusMessage = "請先登入正式帳號，才可以提交髮型師申請"
            return false
        }

        do {
            try await gateway.submitStylistApplication(stylist)
            statusMessage = "髮型師檔案已提交，待平台審批後才會公開"
            await refreshCatalog()
        } catch {
            statusMessage = "髮型師申請提交失敗，請稍後再試"
        }
        return false
    }

    @discardableResult
    func submitSalonApplication(_ salon: Salon, works: [PortfolioWork]) async -> Bool {
        if isAdmin {
            await saveSalon(salon, works: works)
            return true
        }

        guard gateway.isConfigured, currentProfile != nil else {
            statusMessage = "請先登入正式帳號，才可以提交沙龍申請"
            return false
        }

        do {
            try await gateway.submitSalonApplication(salon, works: works)
            statusMessage = "沙龍檔案已提交，待平台審批後才會公開"
            await refreshCatalog()
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
            uploaded.append(mutable)
        }
        return uploaded
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
            pendingStylistApplications.removeAll { $0.id == application.id }
            statusMessage = "\(application.name) 已批准並公開到 Supabase"
            await refreshCatalog()
        } catch {
            statusMessage = "髮型師申請批准失敗"
        }
    }

    func rejectStylistApplication(_ application: StylistApplication) async {
        do {
            try await gateway.rejectStylistApplication(application)
            pendingStylistApplications.removeAll { $0.id == application.id }
            statusMessage = "\(application.name) 申請已拒絕"
        } catch {
            statusMessage = "髮型師申請拒絕失敗"
        }
    }

    func approveSalonApplication(_ application: SalonApplication) async {
        do {
            try await gateway.approveSalonApplication(application)
            pendingSalonApplications.removeAll { $0.id == application.id }
            statusMessage = "\(application.name) 已批准並公開到 Supabase"
            await refreshCatalog()
        } catch {
            statusMessage = "沙龍申請批准失敗"
        }
    }

    func rejectSalonApplication(_ application: SalonApplication) async {
        do {
            try await gateway.rejectSalonApplication(application)
            pendingSalonApplications.removeAll { $0.id == application.id }
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
            stylists.removeAll { $0.id == stylist.id }
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
            salons.removeAll { $0.id == salon.id }
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
            reviewerAvatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80",
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
            avatarURL: "https://images.unsplash.com/photo-1527980965255-d3b416303d12?auto=format&fit=crop&w=120&q=80",
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

    func sendMessage(text: String, stylistID: String = "master-leo", sender: UserRole = .customer) async {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let session = try? await gateway.currentSession()
        let message = ChatMessageItem(
            id: "msg_\(Int(Date().timeIntervalSince1970 * 1000))",
            customerID: session?.user.id ?? currentProfile?.id,
            stylistID: stylistID,
            senderRole: sender,
            senderName: sender == .stylist ? stylist(id: stylistID).name : (currentProfile?.displayName ?? "Alex"),
            text: clean,
            sentAt: DateFormatter.hmTime.string(from: Date())
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

    func recallMessage(id: String) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        let replacementText = "⚠️ 此則訊息已被您成功撒回"
        messages[index].text = replacementText
        statusMessage = "訊息已撒回"

        Task {
            guard gateway.isConfigured else { return }
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

    func toggleBlockedSlot(stylistID: String, date: String, time: String) async {
        if let index = blockedSlots.firstIndex(where: { $0.stylistID == stylistID && $0.workDate == date && $0.startTime == time }) {
            let removed = blockedSlots.remove(at: index)
            try? await gateway.toggleBlockedSlot(removed, shouldBlock: false)
        } else {
            let slot = BlockedSlot(id: UUID(), stylistID: stylistID, workDate: date, startTime: time)
            blockedSlots.append(slot)
            try? await gateway.toggleBlockedSlot(slot, shouldBlock: true)
        }
    }

    func isBlocked(stylistID: String, date: String, time: String) -> Bool {
        blockedSlots.contains { $0.stylistID == stylistID && $0.workDate == date && $0.startTime == time }
    }

    func handleDeepLink(_ url: URL) {
        let isRecovery = isPasswordRecoveryURL(url)
        statusMessage = "正在完成 Supabase 登入..."
        Task { [weak self] in
            do {
                guard let self else { return }
                if let session = try await self.gateway.session(from: url) {
                    self.applySession(session)
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
                        self?.applySession(session)
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

    private func applySession(_ session: Session) {
        let metadata = session.user.userMetadata
        let name = metadata["display_name"]?.stringValue ?? session.user.email ?? "Hairmap User"
        let roleValue = metadata["role"]?.stringValue ?? UserRole.customer.rawValue
        let role = UserRole(rawValue: roleValue) ?? .customer
        currentProfile = HairmapProfile(
            id: session.user.id,
            displayName: name,
            email: session.user.email ?? "",
            role: role,
            stylistID: role == .stylist ? (metadata["stylist_id"]?.stringValue ?? "master-leo") : nil
        )
        statusMessage = "Supabase session 已啟用"
        Task { await refreshAdminStatus() }
    }

    private func finishDeepLinkSignIn() async {
        guard let session = try? await gateway.currentSession() else {
            statusMessage = "未能建立登入 session，請使用最新一封 Email 連結再試"
            return
        }
        applySession(session)
        await refreshCatalog()
    }

    private func isRealEmail(_ email: String) -> Bool {
        email.contains("@") &&
            email.contains(".") &&
            !email.lowercased().hasSuffix(".local")
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
        if text.contains("429") || text.contains("rate") {
            return "登入信寄送太頻密，請稍後再試或先用訪客體驗"
        }
        if let provider, text.contains("cancel") {
            return "\(provider.title) 登入已取消"
        }
        if let provider, text.contains("provider") || text.contains("oauth") || text.contains("unsupported") {
            return "請先到 Supabase Dashboard 開啟 \(provider.title) 登入 Provider"
        }
        if text.contains("email not confirmed") || text.contains("not confirmed") {
            return "請先完成 Email 確認，再使用密碼登入"
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
