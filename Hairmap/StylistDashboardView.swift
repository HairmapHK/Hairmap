import PhotosUI
import SwiftUI
import UIKit

struct StylistDashboardView: View {
    @Environment(HairmapStore.self) private var store
    let stylistID: String

    @State private var tab: StylistWorkTab = .bookings
    @State private var selectedThreadID: String?
    @State private var didLoadProfile = false

    @State private var profileName = ""
    @State private var profileTitle = ""
    @State private var profilePhone = ""
    @State private var profileBio = ""
    @State private var profileExperience = "10年以上與合夥"
    @State private var profileLanguages = "中 / 英"
    @State private var profileAvatarURL = ""
    @State private var profileServices: [DashboardServiceDraft] = []
    @State private var selectedTags: Set<String> = ["挑染專家", "經典剪髮"]
    @State private var profileWorks: [PortfolioWork] = []
    @State private var customServiceName = ""
    @State private var customServiceCategory = "剪髮"
    @State private var customServiceDescription = ""
    @State private var customServicePrice = ""
    @State private var customWorkTitle = ""
    @State private var customWorkURL = ""
    @State private var instagramURL = ""
    @State private var pickedAvatarItem: PhotosPickerItem?
    @State private var pickedWorkItems: [PhotosPickerItem] = []
    @State private var uploadedAvatarData: Data?
    @State private var profileSubmissionNotice = ""
    @State private var isProfileSubmissionAlertPresented = false

    private var stylist: Stylist { store.dashboardStylist(id: stylistID) }
    private var hasApprovedProfile: Bool { store.isApprovedDashboardStylist(id: stylistID) }

    var body: some View {
        GeometryReader { proxy in
            let contentWidth = min(proxy.size.width, 430)
            ZStack {
                DashboardPalette.chrome.ignoresSafeArea()

                VStack(spacing: 0) {
                    DashboardHeader(stylist: stylist) {
                        Task { await store.logout() }
                    }
                    .padding(.top, max(proxy.safeAreaInsets.top, 12))
                    .frame(width: contentWidth)

                    DashboardSyncBar()
                        .frame(width: contentWidth)

                    tabContent
                        .frame(width: contentWidth)
                        .frame(maxHeight: .infinity)
                        .background(DashboardPalette.canvas)

                    DashboardBottomBar(selection: $tab, stylistID: stylistID) {
                        selectedThreadID = nil
                    }
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom, 8))
                    .frame(width: contentWidth)
                }
                .frame(width: contentWidth, height: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom)
                .clipShape(RoundedRectangle(cornerRadius: proxy.size.width > contentWidth ? 30 : 0, style: .continuous))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.container, edges: [.top, .bottom])
        }
        .preferredColorScheme(.light)
        .tint(.black)
        .onAppear {
            if !hasApprovedProfile {
                tab = .profile
            }
            loadProfileIfNeeded()
        }
        .onChange(of: pickedAvatarItem) { _, newItem in
            Task { await loadAvatar(newItem) }
        }
        .onChange(of: pickedWorkItems) { _, newItems in
            Task { await loadPortfolioWorks(newItems) }
        }
        .alert("提交成功", isPresented: $isProfileSubmissionAlertPresented) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("已提交，等待審批。審批通過後才會公開到 Hairmap 顧客端。")
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        if !hasApprovedProfile && tab != .profile {
            StylistProfileRequiredPage {
                withAnimation(.snappy(duration: 0.22)) {
                    tab = .profile
                }
            }
        } else {
            switch tab {
            case .bookings:
                StylistTodayBookingsPage(stylistID: stylistID) { threadID in
                    selectedThreadID = threadID
                    withAnimation(.snappy(duration: 0.22)) {
                        tab = .messages
                    }
                }
            case .messages:
                StylistMessagesWorkspace(
                    stylistID: stylistID,
                    selectedThreadID: $selectedThreadID
                )
            case .schedule:
                StylistScheduleWorkspace(stylistID: stylistID)
            case .profile:
                StylistProfileWorkspace(
                    stylistID: stylistID,
                    hasApprovedProfile: hasApprovedProfile,
                    name: $profileName,
                    title: $profileTitle,
                    phone: $profilePhone,
                    bio: $profileBio,
                    experience: $profileExperience,
                    languages: $profileLanguages,
                    avatarURL: $profileAvatarURL,
                    services: $profileServices,
                    selectedTags: $selectedTags,
                    works: $profileWorks,
                    customServiceName: $customServiceName,
                    customServiceCategory: $customServiceCategory,
                    customServiceDescription: $customServiceDescription,
                    customServicePrice: $customServicePrice,
                    customWorkTitle: $customWorkTitle,
                    customWorkURL: $customWorkURL,
                    instagramURL: $instagramURL,
                    pickedAvatarItem: $pickedAvatarItem,
                    pickedWorkItems: $pickedWorkItems,
                    uploadedAvatarData: uploadedAvatarData,
                    applicationNotice: profileSubmissionNotice,
                    onSubmitForReview: submitStylistProfileForReview
                )
            }
        }
    }

    private func loadProfileIfNeeded() {
        guard !didLoadProfile else { return }
        didLoadProfile = true
        let stylist = stylist
        let cleanProfileName = store.currentProfile?.displayName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        profileName = hasApprovedProfile ? stylist.name : (cleanProfileName == "待建立髮型師" ? "" : cleanProfileName)
        profileTitle = hasApprovedProfile ? stylist.title : ""
        profilePhone = hasApprovedProfile ? stylist.phone : ""
        profileBio = hasApprovedProfile ? stylist.bio : ""
        profileExperience = stylist.experience
        profileLanguages = stylist.languages
        instagramURL = hasApprovedProfile ? stylist.instagramURL : ""
        profileAvatarURL = hasApprovedProfile ? stylist.avatarURL : (store.currentProfile?.avatarURL.nilIfEmpty ?? stylist.avatarURL)
        selectedTags = hasApprovedProfile ? Set(stylist.specialties) : ["挑染專家", "經典剪髮"]
        profileWorks = hasApprovedProfile ? stylist.works : []
        let loadedServices = stylist.services.map { service in
            DashboardServiceDraft(
                id: service.id,
                name: service.name,
                category: service.category,
                duration: service.duration,
                description: service.description,
                price: service.price,
                isSelected: true
            )
        }
        profileServices = loadedServices.isEmpty
            ? DashboardServiceDraft.starterDefaults(stylistID: stylistID)
            : loadedServices + DashboardServiceDraft.optionalDefaults(stylistID: stylistID)
    }

    private func loadAvatar(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
        uploadedAvatarData = data
        if let savedURL = saveDashboardUploadedImage(data, prefix: "dashboard-avatar") {
            profileAvatarURL = savedURL
        }
    }

    private func loadPortfolioWorks(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        let availableSlots = max(0, 10 - profileWorks.count)
        guard availableSlots > 0 else {
            pickedWorkItems = []
            return
        }

        let title = customWorkTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        var newWorks: [PortfolioWork] = []

        for (index, item) in items.prefix(availableSlots).enumerated() {
            guard
                let data = try? await item.loadTransferable(type: Data.self),
                let savedURL = saveDashboardUploadedImage(data, prefix: "dashboard-work")
            else { continue }

            let defaultTitle = items.count == 1 ? "自訂上載作品" : "自訂上載作品 \(index + 1)"
            let workTitle = title.isEmpty
                ? defaultTitle
                : (items.count == 1 ? title : "\(title) \(index + 1)")
            newWorks.append(
                PortfolioWork(
                    id: "dash_work_\(UUID().uuidString)",
                    stylistID: stylistID,
                    title: workTitle,
                    imageURL: savedURL
                )
            )
        }

        if !newWorks.isEmpty {
            profileWorks.insert(contentsOf: newWorks, at: 0)
            customWorkTitle = ""
        }
        pickedWorkItems = []
    }

    private func saveProfile() {
        submitStylistProfileForReview()
    }

    private func submitStylistProfileForReview() {
        Task {
            let draft = await editedStylistDraft()
            let didSubmit = await store.submitStylistApplication(draft)
            if didSubmit {
                profileSubmissionNotice = "已提交，等待審批"
                isProfileSubmissionAlertPresented = true
            }
        }
    }

    private func editedStylistDraft() async -> Stylist {
        var updated = stylist
        updated.name = profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? updated.name : profileName
        updated.title = profileTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? updated.title : profileTitle
        updated.phone = profilePhone.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.bio = profileBio
        updated.experience = profileExperience
        updated.languages = profileLanguages
        updated.instagramURL = instagramURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let avatarSource = profileAvatarURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? updated.avatarURL : profileAvatarURL
        updated.avatarURL = await store.uploadProfileMediaIfNeeded(avatarSource, folder: "dashboard-avatars")
        updated.specialties = Array(selectedTags).sorted()
        updated.services = profileServices
            .filter(\.isSelected)
            .map {
                ServiceItem(
                    id: $0.id,
                    stylistID: stylistID,
                    name: $0.name,
                    category: $0.category,
                    duration: $0.duration,
                    description: $0.description,
                    price: $0.price
                )
            }
        updated.works = await store.uploadPortfolioWorksIfNeeded(profileWorks, folder: "dashboard-portfolio")
        return updated
    }
}

private enum StylistWorkTab: CaseIterable, Identifiable, Hashable {
    case bookings
    case messages
    case schedule
    case profile

    var id: Self { self }

    var title: String {
        switch self {
        case .bookings: "今日預約"
        case .messages: "顧客訊息"
        case .schedule: "檔期管理"
        case .profile: "個人檔案"
        }
    }

    var symbol: String {
        switch self {
        case .bookings: "calendar"
        case .messages: "message"
        case .schedule: "clock"
        case .profile: "person"
        }
    }
}

private enum DashboardPalette {
    static let chrome = Color(red: 0.075, green: 0.073, blue: 0.067)
    static let panel = Color(red: 0.98, green: 0.985, blue: 0.99)
    static let canvas = Color(red: 0.965, green: 0.972, blue: 0.98)
    static let line = Color.black.opacity(0.16)
    static let muted = Color(red: 0.47, green: 0.49, blue: 0.52)
    static let gold = Color(red: 0.96, green: 0.71, blue: 0.06)
    static let green = Color(red: 0.02, green: 0.66, blue: 0.43)
}

private struct DashboardHeader: View {
    let stylist: Stylist
    let onLogout: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(urlString: stylist.avatarURL, height: 44, cornerRadius: 22)
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(Circle().stroke(DashboardPalette.gold, lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(stylist.name)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text("髮型師後台")
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(DashboardPalette.gold.opacity(0.9), in: RoundedRectangle(cornerRadius: 4))
                        .foregroundStyle(.black)
                }

                Text(stylist.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onLogout) {
                Text("安全登出")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 78, height: 38)
                    .background(Color(red: 0.47, green: 0.04, blue: 0.05), in: RoundedRectangle(cornerRadius: 9))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 14)
        .background(DashboardPalette.chrome)
    }
}

private struct DashboardSyncBar: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(DashboardPalette.green.opacity(0.35))
                .frame(width: 8, height: 8)

            Text("[SUPABASE SYNC]: ")
                .foregroundStyle(.white.opacity(0.82))
            + Text("[Supabase Connection] Connected to postgres-api client")
                .foregroundStyle(Color(red: 0.31, green: 0.95, blue: 0.62))

            Spacer(minLength: 8)

            Text("查看\n快照")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(Color(red: 0.23, green: 0.93, blue: 0.62))
                .multilineTextAlignment(.center)
        }
        .font(.system(size: 9, weight: .bold, design: .monospaced))
        .lineLimit(1)
        .minimumScaleFactor(0.58)
        .padding(.horizontal, 16)
        .frame(height: 36)
        .background(Color.black)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(red: 0.16, green: 0.86, blue: 0.62))
                .frame(height: 2)
        }
    }
}

private struct DashboardBottomBar: View {
    @Environment(HairmapStore.self) private var store
    @Binding var selection: StylistWorkTab
    let stylistID: String
    let resetNestedRoute: () -> Void

    private var hasCustomerMessage: Bool {
        store.stylistUnreadMessageCount(stylistID: stylistID) > 0
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(StylistWorkTab.allCases) { tab in
                Button {
                    resetNestedRoute()
                    withAnimation(.snappy(duration: 0.2)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tab.symbol)
                                .font(.system(size: 20, weight: selection == tab ? .semibold : .regular))
                            if tab == .messages && hasCustomerMessage {
                                Circle()
                                    .fill(Color(red: 0.94, green: 0.05, blue: 0.22))
                                    .frame(width: 7, height: 7)
                                    .offset(x: 6, y: -3)
                            }
                        }
                        Text(tab.title)
                            .font(.system(size: 10, weight: selection == tab ? .black : .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        if selection == tab {
                            Circle()
                                .fill(DashboardPalette.gold)
                                .frame(width: 4, height: 4)
                        } else {
                            Color.clear.frame(width: 4, height: 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .foregroundStyle(selection == tab ? DashboardPalette.gold : .white.opacity(0.58))
                    .overlay {
                        if selection == tab {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(DashboardPalette.gold, lineWidth: 1)
                                .frame(width: 58, height: 48)
                        }
                    }
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .background(DashboardPalette.chrome)
    }
}

private struct DashboardSectionHeader: View {
    let eyebrow: String
    let title: String
    var trailing: String?

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(eyebrow.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.system(size: 21, weight: .black))
                    .foregroundStyle(.black)
            }
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 12, weight: .black))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color(red: 0.9, green: 0.97, blue: 1), in: Capsule())
                    .overlay(Capsule().stroke(Color(red: 0.05, green: 0.42, blue: 0.62), lineWidth: 1))
                    .foregroundStyle(Color(red: 0.05, green: 0.42, blue: 0.62))
            }
        }
    }
}

private struct StylistProfileRequiredPage: View {
    let openProfile: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 48)
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 46, weight: .bold))
                .foregroundStyle(DashboardPalette.gold)
            VStack(spacing: 8) {
                Text("請先建立髮型師檔案")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(.black)
                Text("完成姓名、頭像、服務項目和作品集後，提交給管理員審批。批准後才會開放預約、訊息與檔期管理。")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 28)
            }
            Button(action: openProfile) {
                Text("立即填寫個人檔案")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 220, height: 50)
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(PressableButtonStyle())
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DashboardPalette.canvas)
    }
}

private struct StylistTodayBookingsPage: View {
    @Environment(HairmapStore.self) private var store
    let stylistID: String
    let openThread: (String) -> Void

    private var rows: [DashboardBookingRow] {
        store.bookings
            .filter { $0.stylistID == stylistID && $0.status != .cancelled && $0.status != .completed }
            .sorted {
                if $0.bookingDate == $1.bookingDate {
                    return $0.startTime < $1.startTime
                }
                return $0.bookingDate < $1.bookingDate
            }
            .map(DashboardBookingRow.init)
    }

    private var pendingRows: [DashboardBookingRow] {
        rows.filter { $0.status == .pending }
    }

    private var acceptedRows: [DashboardBookingRow] {
        rows.filter { $0.status == .accepted || $0.status == .inProgress }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                DashboardSectionHeader(
                    eyebrow: "🧾 Today Bookings",
                    title: "今日預約接單表",
                    trailing: "\(rows.count) 堂待辦"
                )

                if rows.isEmpty {
                    DashboardEmptyNotice(
                        systemImage: "calendar.badge.clock",
                        title: "暫時沒有預約",
                        message: "顧客完成預約後，會即時同步到這裡。"
                    )
                } else {
                    DashboardBookingGroupTitle(color: DashboardPalette.gold, title: "待確認預約", count: pendingRows.count)
                    ForEach(pendingRows) { row in
                        DashboardBookingCard(
                            row: row,
                            accent: DashboardPalette.gold,
                            confirmTitle: "確認預約",
                            onMessage: { openThread(row.threadID) },
                            onConfirm: { update(row, to: .accepted) }
                        )
                    }

                    DashboardBookingGroupTitle(color: DashboardPalette.green, title: "已確認預約", count: acceptedRows.count)
                    ForEach(acceptedRows) { row in
                        DashboardBookingCard(
                            row: row,
                            accent: DashboardPalette.green,
                            confirmTitle: "完成服務",
                            onMessage: { openThread(row.threadID) },
                            onConfirm: { update(row, to: .completed) }
                        )
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(DashboardPalette.canvas)
        .task(id: stylistID) {
            while !Task.isCancelled {
                await store.refreshCatalog()
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }

    private func update(_ row: DashboardBookingRow, to status: BookingStatus) {
        if let booking = store.bookings.first(where: { $0.id.uuidString == row.id }) {
            Task { await store.updateBooking(booking, status: status) }
        }
    }
}

private struct DashboardBookingGroupTitle: View {
    let color: Color
    let title: String
    let count: Int

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(title) (\(count))")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(color)
            Spacer()
        }
        .padding(.top, 4)
    }
}

private struct DashboardEmptyNotice: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(DashboardPalette.gold)
            Text(title)
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(.black)
            Text(message)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .background(.white, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DashboardPalette.line, lineWidth: 1))
    }
}

private struct DashboardBookingCard: View {
    let row: DashboardBookingRow
    let accent: Color
    let confirmTitle: String
    let onMessage: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 10)
                .fill(accent)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Label(row.timeSlot, systemImage: "clock")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundStyle(.black)
                    Text(row.status == .pending ? "顧客待確認" : "已確定")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(accent.opacity(0.12), in: Capsule())
                        .foregroundStyle(accent)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(row.clientName)
                            .font(.system(size: 18, weight: .black))
                        Text(row.phone)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 5) {
                        Image(systemName: "doc.text")
                        Text("服務：\(row.service)")
                            .lineLimit(1)
                        Text("HK$ \(row.price)")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundStyle(Color(red: 0.55, green: 0.34, blue: 0.02))
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    Button(action: onMessage) {
                        Text("發送訊息")
                            .font(.system(size: 13, weight: .black))
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(.white, in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black, lineWidth: 1))
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(PressableButtonStyle())

                    Button(action: onConfirm) {
                        Text(confirmTitle)
                            .font(.system(size: 13, weight: .black))
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(row.status == .pending ? Color.black : DashboardPalette.green, in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(14)
        }
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(DashboardPalette.line, lineWidth: 1))
    }
}

private struct DashboardBookingRow: Identifiable, Hashable {
    var id: String
    var threadID: String
    var timeSlot: String
    var clientName: String
    var phone: String
    var service: String
    var price: Int
    var status: BookingStatus

    init(booking: Appointment) {
        id = booking.id.uuidString
        threadID = booking.customerID?.uuidString ?? booking.id.uuidString
        timeSlot = "\(booking.startTime) - \(booking.endTime)"
        clientName = booking.clientName
        phone = booking.clientPhone
        service = booking.serviceName
        price = booking.price
        status = booking.status
    }

}

private struct StylistMessagesWorkspace: View {
    @Environment(HairmapStore.self) private var store
    let stylistID: String
    @Binding var selectedThreadID: String?

    @State private var replyDraft = ""
    @State private var reportDraft: ReportDraft?

    private var threads: [DashboardThread] {
        let groupedMessages = Dictionary(grouping: store.messages.filter { $0.stylistID == stylistID }) { message in
            message.customerID?.uuidString ?? "guest-\(message.senderName)"
        }

        var mapped = groupedMessages.map { key, messages in
            DashboardThread(id: key, messages: messages, bookings: bookings(for: key), profiles: store.customerProfilesByID)
        }

        let messageThreadIDs = Set(mapped.map(\.id))
        let bookingThreads = store.bookings
            .filter { $0.stylistID == stylistID && $0.status != .cancelled && $0.status != .completed }
            .compactMap { booking -> DashboardThread? in
                guard let customerID = booking.customerID else { return nil }
                let id = customerID.uuidString
                guard !messageThreadIDs.contains(id) else { return nil }
                return DashboardThread(id: id, booking: booking, profiles: store.customerProfilesByID)
            }

        mapped.append(contentsOf: bookingThreads)
        return mapped.sorted { lhs, rhs in
            lhs.sortKey > rhs.sortKey
        }
    }

    private var selectedThread: DashboardThread? {
        guard let selectedThreadID else { return nil }
        return threads.first { $0.id == selectedThreadID }
    }

    private func messages(for thread: DashboardThread) -> [DashboardChatLine] {
        store.messages
            .filter { $0.stylistID == stylistID && ($0.customerID?.uuidString ?? "guest-\($0.senderName)") == thread.id }
            .sorted { $0.sortKey < $1.sortKey }
            .map(DashboardChatLine.init)
    }

    var body: some View {
        Group {
            if let selectedThread {
                DashboardChatDetailPage(
                    thread: selectedThread,
                    messages: messages(for: selectedThread),
                    replyDraft: $replyDraft,
                    onBack: {
                        withAnimation(.snappy(duration: 0.22)) {
                            selectedThreadID = nil
                        }
                    },
                    onSend: sendReply,
                    onReport: reportMessage
                )
            } else {
                DashboardChatInboxPage(threads: threads) { thread in
                    store.markStylistThreadRead(stylistID: stylistID, threadID: thread.id)
                    withAnimation(.snappy(duration: 0.22)) {
                        selectedThreadID = thread.id
                    }
                }
            }
        }
        .background(DashboardPalette.canvas)
        .task(id: stylistID) {
            while !Task.isCancelled {
                await store.refreshCatalog()
                try? await Task.sleep(nanoseconds: 4_000_000_000)
            }
        }
        .sheet(item: $reportDraft) { draft in
            ReportSheet(draft: draft) { reason, details in
                store.submitReport(entityType: draft.entityType, entityID: draft.entityID, reason: reason, details: details)
            }
        }
    }

    private func sendReply() {
        let clean = replyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, let thread = selectedThread else { return }
        replyDraft = ""
        Task {
            await store.sendMessage(text: clean, stylistID: stylistID, sender: .stylist, customerID: thread.customerID)
            await store.refreshCatalog()
        }
    }

    private func reportMessage(_ message: DashboardChatLine) {
        reportDraft = ReportDraft(
            entityType: .message,
            entityID: message.id,
            title: "檢舉顧客訊息",
            subtitle: message.text
        )
    }

    private func bookings(for threadID: String) -> [Appointment] {
        store.bookings.filter { booking in
            booking.stylistID == stylistID && booking.customerID?.uuidString == threadID
        }
    }
}

private struct DashboardChatInboxPage: View {
    let threads: [DashboardThread]
    let openThread: (DashboardThread) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    DashboardSectionHeader(eyebrow: "💬 Chat Inbox", title: "客戶對話信箱")

                    if threads.isEmpty {
                        DashboardEmptyNotice(
                            systemImage: "message",
                            title: "暫時沒有顧客訊息",
                            message: "顧客從髮型師檔案或預約進度傳訊後，會出現在這裡。"
                        )
                    } else {
                        ForEach(threads) { thread in
                            Button {
                                openThread(thread)
                            } label: {
                                DashboardThreadCard(thread: thread)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }

                    Spacer(minLength: 260)
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            Text("🔒 全程對講均支持 AES-256 永久子加密傳輸")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.black.opacity(0.75))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(.white)
        }
    }
}

private struct DashboardCustomerAvatar: View {
    let urlString: String
    let size: CGFloat

    private var hasImage: Bool {
        !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Group {
            if hasImage {
                RemoteImage(urlString: urlString, height: size, cornerRadius: size / 2)
            } else {
                Circle()
                    .fill(Color.black.opacity(0.08))
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: size * 0.42, weight: .bold))
                            .foregroundStyle(.black.opacity(0.62))
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

private struct DashboardThreadCard: View {
    let thread: DashboardThread

    var body: some View {
        HStack(spacing: 14) {
            DashboardCustomerAvatar(urlString: thread.avatarURL, size: 54)
                .overlay(alignment: .bottomTrailing) {
                    Circle()
                        .fill(DashboardPalette.green)
                        .frame(width: 11, height: 11)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(thread.name)
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.black)
                    Text(thread.tag)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(thread.time)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    if thread.isUnread {
                        Circle()
                            .fill(Color(red: 1, green: 0.1, blue: 0.2))
                            .frame(width: 9, height: 9)
                            .shadow(color: .red.opacity(0.7), radius: 5)
                    }
                }

                Text(thread.lastMessage)
                    .font(.system(size: 13, weight: thread.isUnread ? .bold : .medium))
                    .foregroundStyle(.black)
                    .lineLimit(2)

                HStack {
                    ForEach(thread.chips, id: \.self) { chip in
                        Text(chip)
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(DashboardPalette.canvas, in: Capsule())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(thread.seenText)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(thread.isUnread ? .black : .secondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.black, lineWidth: 1))
    }
}

private struct DashboardChatDetailPage: View {
    let thread: DashboardThread
    let messages: [DashboardChatLine]
    @Binding var replyDraft: String
    let onBack: () -> Void
    let onSend: () -> Void
    let onReport: (DashboardChatLine) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Label("返回收件箱", systemImage: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.black)
                }
                .buttonStyle(PressableButtonStyle())

                Spacer()

                DashboardCustomerAvatar(urlString: thread.avatarURL, size: 32)

                Text(thread.name)
                    .font(.system(size: 15, weight: .black))

                Spacer()
            }
            .padding(.horizontal, 18)
            .frame(height: 58)
            .background(.white)
            .overlay(alignment: .bottom) { Rectangle().fill(.black.opacity(0.9)).frame(height: 1) }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    ForEach(messages) { message in
                        DashboardChatBubble(
                            message: message,
                            avatarURL: message.isStylist ? "https://images.unsplash.com/photo-1615109398623-88346a601842?auto=format&fit=crop&w=400&q=80" : thread.avatarURL,
                            onReport: { onReport(message) }
                        )
                    }
                    Spacer(minLength: 210)
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
            }

            HStack(spacing: 10) {
                TextField("回覆給 \(thread.name)...", text: $replyDraft, axis: .vertical)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1...3)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 42)
                    .background(.white, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black.opacity(0.12), lineWidth: 1))

                Button(action: onSend) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(.black, in: Circle())
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(.white)
        }
    }
}

private struct DashboardChatBubble: View {
    let message: DashboardChatLine
    let avatarURL: String
    let onReport: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 9) {
            if !message.isStylist {
                DashboardCustomerAvatar(urlString: avatarURL, size: 28)
            } else {
                Spacer(minLength: 38)
            }

            VStack(alignment: message.isStylist ? .trailing : .leading, spacing: 5) {
                messageBody
                    .contextMenu {
                        Button("檢舉訊息", role: .destructive) {
                            onReport()
                        }
                    }

                Text(message.isStylist && message.isSeen ? "\(message.time) · 已讀" : message.time)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 320, alignment: message.isStylist ? .trailing : .leading)

            if message.isStylist {
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    private var messageBody: some View {
        if let photoURL = message.photoURL {
            RemoteImage(urlString: photoURL, height: 170, cornerRadius: 14)
                .frame(width: 230)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(message.isStylist ? .clear : .black, lineWidth: 1))
        } else {
            Text(message.text)
                .font(.system(size: 14, weight: .medium))
                .lineSpacing(3)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .foregroundStyle(message.isStylist ? .white : .black)
                .background(message.isStylist ? .black : .white, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(message.isStylist ? .clear : .black, lineWidth: 1))
        }
    }
}

private struct DashboardThread: Identifiable, Hashable {
    var id: String
    var customerID: UUID?
    var name: String
    var tag: String
    var avatarURL: String
    var lastMessage: String
    var time: String
    var isUnread: Bool
    var seenText: String
    var chips: [String]
    var sortKey: TimeInterval

    init(id: String, messages: [ChatMessageItem], bookings: [Appointment], profiles: [UUID: HairmapProfile]) {
        let sortedMessages = messages.sorted { $0.sortKey < $1.sortKey }
        let last = sortedMessages.last
        let firstCustomerMessage = sortedMessages.first { $0.senderRole == .customer }
        let customerBooking = bookings.sorted { $0.bookingDate + $0.startTime > $1.bookingDate + $1.startTime }.first
        let fallbackCustomerID = messages.compactMap(\.customerID).first ?? customerBooking?.customerID
        let profile = fallbackCustomerID.flatMap { profiles[$0] }

        self.id = id
        self.customerID = fallbackCustomerID
        name = Self.customerName(profile: profile, booking: customerBooking, message: firstCustomerMessage)
        tag = customerBooking?.serviceName ?? ""
        avatarURL = profile?.avatarURL.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        lastMessage = last?.displayText ?? "已建立預約，尚未開始對話"
        time = last?.displayTime ?? customerBooking?.bookingDate ?? "剛剛"
        isUnread = last?.senderRole == .customer
        seenText = isUnread ? "未讀 ☐" : "已讀"
        chips = Array(Set(bookings.map(\.serviceName))).prefix(2).map { $0 }
        sortKey = last?.sortKey ?? Self.bookingSortKey(customerBooking)
    }

    init(id: String, booking: Appointment, profiles: [UUID: HairmapProfile]) {
        let profile = booking.customerID.flatMap { profiles[$0] }
        self.id = id
        customerID = booking.customerID
        name = Self.customerName(profile: profile, booking: booking, message: nil)
        tag = booking.serviceName
        avatarURL = profile?.avatarURL.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        lastMessage = "\(booking.bookingDate) \(booking.timeSlot) 的預約已建立"
        time = booking.bookingDate
        isUnread = false
        seenText = "已讀"
        chips = [booking.serviceName]
        sortKey = Self.bookingSortKey(booking)
    }

    private static func bookingSortKey(_ booking: Appointment?) -> TimeInterval {
        guard let booking else { return 0 }
        let value = "\(booking.bookingDate) \(booking.startTime.hmTimeKey)"
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: value)?.timeIntervalSince1970 ?? 0
    }

    private static func customerName(profile: HairmapProfile?, booking: Appointment?, message: ChatMessageItem?) -> String {
        let candidates = [
            profile?.displayName,
            booking?.clientName,
            message?.senderName
        ]
        for candidate in candidates {
            let clean = candidate?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if isUsefulCustomerName(clean, email: profile?.email) {
                return clean
            }
        }
        return "Hairmap 顧客"
    }

    private static func isUsefulCustomerName(_ name: String, email: String?) -> Bool {
        guard !name.isEmpty else { return false }
        let lower = name.lowercased()
        let emailLower = email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let genericNames: Set<String> = [
            "hairmap guest",
            "hairmap 顧客",
            "hairmap 會員",
            "google guest",
            "apple guest"
        ]
        return !name.contains("@") && lower != emailLower && !genericNames.contains(lower)
    }
}

private struct DashboardChatLine: Identifiable, Hashable {
    var id: String
    var text: String
    var time: String
    var isStylist: Bool
    var isSeen: Bool
    var photoURL: String?

    init(id: String, text: String, time: String, isStylist: Bool, isSeen: Bool, photoURL: String? = nil) {
        self.id = id
        self.text = text
        self.time = time
        self.isStylist = isStylist
        self.isSeen = isSeen
        self.photoURL = photoURL
    }

    init(message: ChatMessageItem) {
        id = message.id
        text = message.displayText
        time = message.displayTime
        isStylist = message.senderRole == .stylist
        isSeen = true
        photoURL = message.photoURL
    }
}

private struct StylistScheduleWorkspace: View {
    @Environment(HairmapStore.self) private var store
    let stylistID: String

    @State private var selectedDate = DashboardCalendar.today()
    @State private var isCalendarOpen = false
    @State private var optimisticBlockedSlots: Set<String> = []
    @State private var batchStartDate = DashboardCalendar.today()
    @State private var batchEndDate = DashboardCalendar.today()
    @State private var batchStartTime = "13:30"
    @State private var batchEndTime = "17:30"
    @State private var isSyncing = false
    @State private var syncNotice = "檔期會自動同步到 Supabase"

    private let times = ["09:00", "10:00", "11:00", "13:30", "14:30", "15:30", "17:30", "18:30", "19:30", "20:00", "20:30"]
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                DashboardSectionHeader(eyebrow: "🔒 Block Schedule", title: "檔期管理")

                VStack(alignment: .leading, spacing: 12) {
                    Text("1. 選擇要關閉設定日期")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.secondary)
                    DashboardDatePickerField(
                        selectedDate: $selectedDate,
                        isOpen: $isCalendarOpen
                    )
                }
                .padding(14)
                .background(.white, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.black, lineWidth: 1))

                HStack {
                    Text("時段切換")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label(isSyncing ? "同步中..." : "已連接 Supabase", systemImage: "circle.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(DashboardPalette.green)
                }

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(times, id: \.self) { time in
                        let blocked = isBlocked(time)
                        Button {
                            toggle(time)
                        } label: {
                            VStack(spacing: 6) {
                                Text(time)
                                    .font(.system(size: 16, weight: .black, design: .monospaced))
                                Text(blocked ? "忙碌 ⃠" : "開放 ✅")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(blocked ? .red : DashboardPalette.green)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                            .background(blocked ? Color.red.opacity(0.08) : .white, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(blocked ? Color.red.opacity(0.28) : .black, lineWidth: 1))
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }

                DashboardScheduleSyncStatus(
                    isSyncing: isSyncing,
                    notice: syncNotice
                )

                DashboardBatchBlockCard(
                    startDate: $batchStartDate,
                    endDate: $batchEndDate,
                    startTime: $batchStartTime,
                    endTime: $batchEndTime,
                    times: times,
                    action: batchBlock
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(DashboardPalette.canvas)
        .task {
            await store.refreshCatalog()
        }
    }

    private var selectedDateKey: String {
        DashboardCalendar.key(from: selectedDate)
    }

    private func isBlocked(_ time: String) -> Bool {
        optimisticBlockedSlots.contains(slotKey(dateKey: selectedDateKey, time: time)) ||
            store.isBlocked(stylistID: stylistID, date: selectedDateKey, time: time)
    }

    private func toggle(_ time: String) {
        let dateKey = selectedDateKey
        let key = slotKey(dateKey: dateKey, time: time)
        let shouldBlock = !isBlocked(time)
        if shouldBlock {
            optimisticBlockedSlots.insert(key)
        } else {
            optimisticBlockedSlots.remove(key)
        }

        isSyncing = true
        syncNotice = "正在同步 \(DashboardCalendar.display(selectedDate)) \(time)..."
        Task {
            let didSync = await store.setBlockedSlot(stylistID: stylistID, date: dateKey, time: time, shouldBlock: shouldBlock)
            if didSync {
                optimisticBlockedSlots.remove(key)
                await store.refreshCatalog()
                syncNotice = shouldBlock ? "\(dateKey) \(time) 已標記忙碌" : "\(dateKey) \(time) 已重新開放"
            } else {
                if shouldBlock {
                    optimisticBlockedSlots.remove(key)
                } else {
                    optimisticBlockedSlots.insert(key)
                }
                syncNotice = "同步失敗，請重新登入後再試"
            }
            isSyncing = false
        }
    }

    private func batchBlock() {
        let startIndex = times.firstIndex(of: batchStartTime) ?? 0
        let endIndex = times.firstIndex(of: batchEndTime) ?? startIndex
        let selectedTimes = Array(times[min(startIndex, endIndex)...max(startIndex, endIndex)])
        let dateKeys = DashboardCalendar.keys(from: batchStartDate, to: batchEndDate)

        isSyncing = true
        syncNotice = "正在批量同步 \(dateKeys.count) 日檔期..."
        Task {
            var syncedCount = 0
            for dateKey in dateKeys {
                for time in selectedTimes where !store.isBlocked(stylistID: stylistID, date: dateKey, time: time) {
                    optimisticBlockedSlots.insert(slotKey(dateKey: dateKey, time: time))
                    let didSync = await store.setBlockedSlot(stylistID: stylistID, date: dateKey, time: time, shouldBlock: true)
                    if didSync {
                        syncedCount += 1
                        optimisticBlockedSlots.remove(slotKey(dateKey: dateKey, time: time))
                    }
                }
            }
            await store.refreshCatalog()
            syncNotice = "已同步 \(syncedCount) 個忙碌時段到 Supabase"
            isSyncing = false
        }
    }

    private func slotKey(dateKey: String, time: String) -> String {
        "\(dateKey)|\(time)"
    }
}

private struct DashboardDatePickerField: View {
    @Binding var selectedDate: Date
    @Binding var isOpen: Bool
    @State private var visibleMonth = DashboardCalendar.monthStart(for: Date())

    var body: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.snappy(duration: 0.22)) {
                    visibleMonth = DashboardCalendar.monthStart(for: selectedDate)
                    isOpen.toggle()
                }
            } label: {
                HStack {
                    Text(DashboardCalendar.display(selectedDate))
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                    Spacer()
                    Image(systemName: isOpen ? "chevron.up" : "calendar")
                        .font(.system(size: 15, weight: .black))
                }
                .padding(.horizontal, 13)
                .frame(height: 42)
                .background(.white, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black, lineWidth: 1))
                .foregroundStyle(.black)
            }
            .buttonStyle(PressableButtonStyle())

            if isOpen {
                DashboardMonthCalendar(
                    selectedDate: $selectedDate,
                    visibleMonth: $visibleMonth,
                    onSelect: {
                        withAnimation(.snappy(duration: 0.2)) {
                            isOpen = false
                        }
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onAppear {
            visibleMonth = DashboardCalendar.monthStart(for: selectedDate)
        }
    }
}

private struct DashboardScheduleSyncStatus: View {
    let isSyncing: Bool
    let notice: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isSyncing ? "arrow.triangle.2.circlepath" : "checkmark.seal.fill")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(isSyncing ? DashboardPalette.gold : DashboardPalette.green)
            VStack(alignment: .leading, spacing: 3) {
                Text(isSyncing ? "正在儲存檔期" : "檔期已連接資料庫")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.black)
                Text(notice)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(12)
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSyncing ? DashboardPalette.gold.opacity(0.6) : DashboardPalette.green.opacity(0.45), lineWidth: 1))
    }
}

private struct DashboardMonthCalendar: View {
    @Binding var selectedDate: Date
    @Binding var visibleMonth: Date
    let onSelect: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    moveMonth(-1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .black))
                        .frame(width: 34, height: 34)
                        .background(DashboardPalette.canvas, in: Circle())
                }
                .buttonStyle(PressableButtonStyle())

                Spacer()

                Text(DashboardCalendar.monthTitle(visibleMonth))
                    .font(.system(size: 16, weight: .black, design: .serif))

                Spacer()

                Button {
                    moveMonth(1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .black))
                        .frame(width: 34, height: 34)
                        .background(DashboardPalette.canvas, in: Circle())
                }
                .buttonStyle(PressableButtonStyle())
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 20)
                }

                ForEach(Array(DashboardCalendar.days(for: visibleMonth).enumerated()), id: \.offset) { _, date in
                    if let date {
                        DashboardCalendarDayButton(
                            date: date,
                            isSelected: DashboardCalendar.isSameDay(date, selectedDate),
                            isToday: DashboardCalendar.isSameDay(date, Date())
                        ) {
                            selectedDate = date
                            onSelect()
                        }
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(red: 0.985, green: 0.985, blue: 0.975), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.black.opacity(0.18), lineWidth: 1))
    }

    private func moveMonth(_ value: Int) {
        visibleMonth = DashboardCalendar.calendar.date(byAdding: .month, value: value, to: visibleMonth) ?? visibleMonth
    }
}

private struct DashboardCalendarDayButton: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(DashboardCalendar.day(date))")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                if isToday {
                    Circle()
                        .fill(isSelected ? .white : DashboardPalette.gold)
                        .frame(width: 4, height: 4)
                } else {
                    Color.clear.frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(isSelected ? .black : .white, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isToday ? DashboardPalette.gold : .black.opacity(0.08), lineWidth: 1))
            .foregroundStyle(isSelected ? .white : .black)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private enum DashboardCalendar {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_Hant_HK")
        calendar.timeZone = TimeZone(identifier: "Asia/Hong_Kong") ?? .current
        return calendar
    }

    static func date(from key: String) -> Date? {
        keyFormatter.date(from: key)
    }

    static func today() -> Date {
        calendar.startOfDay(for: Date())
    }

    static func key(from date: Date) -> String {
        keyFormatter.string(from: date)
    }

    static func display(_ date: Date) -> String {
        displayFormatter.string(from: date)
    }

    static func monthTitle(_ date: Date) -> String {
        monthFormatter.string(from: date)
    }

    static func day(_ date: Date) -> Int {
        calendar.component(.day, from: date)
    }

    static func monthStart(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    static func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    static func days(for month: Date) -> [Date?] {
        let start = monthStart(for: month)
        guard let range = calendar.range(of: .day, in: .month, for: start) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: start)
        var days = Array(repeating: Optional<Date>.none, count: max(0, firstWeekday - 1))
        for day in range {
            let date = calendar.date(byAdding: .day, value: day - 1, to: start)
            days.append(date)
        }
        let remainder = days.count % 7
        if remainder != 0 {
            days.append(contentsOf: Array(repeating: Optional<Date>.none, count: 7 - remainder))
        }
        return days
    }

    static func keys(from startDate: Date, to endDate: Date) -> [String] {
        let lower = min(startDate, endDate)
        let upper = max(startDate, endDate)
        let start = calendar.startOfDay(for: lower)
        let end = calendar.startOfDay(for: upper)
        var cursor = start
        var keys: [String] = []

        while cursor <= end {
            keys.append(key(from: cursor))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        return keys
    }

    private static let keyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Hong_Kong")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Hong_Kong")
        formatter.dateFormat = "dd / MM / yyyy"
        return formatter
    }()

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hant_HK")
        formatter.timeZone = TimeZone(identifier: "Asia/Hong_Kong")
        formatter.dateFormat = "yyyy 年 M 月"
        return formatter
    }()
}

private struct DashboardBatchBlockCard: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var startTime: String
    @Binding var endTime: String
    let times: [String]
    let action: () -> Void
    @State private var isStartCalendarOpen = false
    @State private var isEndCalendarOpen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                Text("💡 批量標記忙碌時段")
                    .font(.system(size: 16, weight: .black))
            }

            Rectangle()
                .fill(.black.opacity(0.85))
                .frame(height: 1)

            Text("挑選日期範圍與每天的可預約時段，一鍵快速同步為忙碌，顧客預約頁會即時避開這些時段。")
                .font(.system(size: 12, weight: .medium))
                .lineSpacing(3)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                DashboardBatchDateSelector(
                    label: "開始日期",
                    selectedDate: $startDate,
                    isOpen: $isStartCalendarOpen,
                    onOpen: { isEndCalendarOpen = false }
                )
                DashboardBatchDateSelector(
                    label: "結束日期",
                    selectedDate: $endDate,
                    isOpen: $isEndCalendarOpen,
                    onOpen: { isStartCalendarOpen = false }
                )
            }

            HStack(spacing: 10) {
                DashboardMenuField(label: "每日開始時段", selection: $startTime, options: times)
                DashboardMenuField(label: "每日結束時段", selection: $endTime, options: times)
            }

            Button(action: action) {
                Label("一鍵批量標記忙碌", systemImage: "bolt.fill")
                    .font(.system(size: 14, weight: .black))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(.black, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.black, lineWidth: 1))
    }
}

private struct DashboardBatchDateSelector: View {
    let label: String
    @Binding var selectedDate: Date
    @Binding var isOpen: Bool
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)

            DashboardDatePickerField(
                selectedDate: $selectedDate,
                isOpen: Binding(
                    get: { isOpen },
                    set: { newValue in
                        if newValue { onOpen() }
                        isOpen = newValue
                    }
                )
            )
        }
    }
}

private struct StylistProfileWorkspace: View {
    @Environment(HairmapStore.self) private var store
    let stylistID: String
    let hasApprovedProfile: Bool
    @Binding var name: String
    @Binding var title: String
    @Binding var phone: String
    @Binding var bio: String
    @Binding var experience: String
    @Binding var languages: String
    @Binding var avatarURL: String
    @Binding var services: [DashboardServiceDraft]
    @Binding var selectedTags: Set<String>
    @Binding var works: [PortfolioWork]
    @Binding var customServiceName: String
    @Binding var customServiceCategory: String
    @Binding var customServiceDescription: String
    @Binding var customServicePrice: String
    @Binding var customWorkTitle: String
    @Binding var customWorkURL: String
    @Binding var instagramURL: String
    @Binding var pickedAvatarItem: PhotosPickerItem?
    @Binding var pickedWorkItems: [PhotosPickerItem]
    let uploadedAvatarData: Data?
    let applicationNotice: String
    let onSubmitForReview: () -> Void
    @State private var isDeleteAlertPresented = false
    @State private var isDeletingAccount = false

    private let tags = ["挑染專家", "經典剪髮", "歐美挑染", "漸層推剪", "韓式燙髮", "縮毛矯正", "女神大波浪", "深層護理", "直髮柔順"]
    private let avatarPresets = [
        DashboardImageChoice(title: "美髮現代女設計師", url: "https://images.unsplash.com/photo-1556157382-97eda2d62296?auto=format&fit=crop&w=600&q=80"),
        DashboardImageChoice(title: "經驗紳士男設計師", url: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=600&q=80"),
        DashboardImageChoice(title: "韓系甜美女設計師", url: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=600&q=80")
    ]
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                DashboardSectionHeader(
                    eyebrow: "🟡 My Stylist Profile",
                    title: hasApprovedProfile ? "個人檔案更新" : "建立髮型師檔案",
                    trailing: hasApprovedProfile ? "需審批" : "待建立"
                )

                DashboardFormCard {
                    Text(hasApprovedProfile ? "如需更改公開名片資料，請在此更新並提交審批；管理員批准後才會同步到顧客端 app 頁面。" : "首次登入後請先建立髮型師檔案。提交後會進入管理員審批，批准前不會公開到顧客端。")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                        .padding(12)
                        .background(Color(red: 1.0, green: 0.985, blue: 0.9), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(DashboardPalette.gold.opacity(0.35), lineWidth: 1))

                    DashboardInputField(label: "設計師姓名 *", placeholder: "Master Leo", text: $name)
                    DashboardInputField(label: "頭銜職稱 *", placeholder: "首席設計師", text: $title)
                    DashboardInputField(label: "髮型師聯絡電話 *", placeholder: "+852 6123 4567", text: $phone, keyboard: .phonePad)
                    DashboardTextArea(label: "個人簡介", placeholder: "10年以上明星美髮經驗。擅長巴黎 Balayage 手刷漸層挑染...", text: $bio, height: 110)

                    HStack(spacing: 10) {
                        DashboardMenuField(label: "工作資歷", selection: $experience, options: ["5年資歷", "8年資歷", "10年以上", "10年以上與合夥"])
                        DashboardMenuField(label: "溝通語言", selection: $languages, options: ["中 / 英", "中 / 粵 / 英", "中 / 韓", "中 / 粵"])
                    }

                    DashboardServiceEditor(
                        services: $services,
                        customName: $customServiceName,
                        customCategory: $customServiceCategory,
                        customDescription: $customServiceDescription,
                        customPrice: $customServicePrice
                    )

                    DashboardTagEditor(tags: tags, selected: $selectedTags)

                    DashboardAvatarEditor(
                        avatarURL: $avatarURL,
                        pickedAvatarItem: $pickedAvatarItem,
                        uploadedAvatarData: uploadedAvatarData,
                        presets: avatarPresets
                    )

                    DashboardPortfolioEditor(
                        stylistID: stylistID,
                        works: $works,
                        customWorkTitle: $customWorkTitle,
                        customWorkURL: $customWorkURL,
                        pickedWorkItems: $pickedWorkItems
                    )

                    DashboardInstagramField(text: $instagramURL)

                    Button(action: onSubmitForReview) {
                        Text(hasApprovedProfile ? "提交個人檔案更新審批" : "提交髮型師檔案審批")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(.black, in: RoundedRectangle(cornerRadius: 9))
                    }
                    .buttonStyle(PressableButtonStyle())

                    DashboardApplicationReviewCard(notice: applicationNotice)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("帳號管理")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(.black)
                        Text("如不再使用 Hairmap，可永久刪除髮型師登入帳號。此動作會登出並移除您的登入資料。")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Button(role: .destructive) {
                            isDeleteAlertPresented = true
                        } label: {
                            HStack {
                                if isDeletingAccount {
                                    ProgressView()
                                        .tint(.red)
                                }
                                Label(isDeletingAccount ? "正在刪除帳號..." : "永久刪除帳號", systemImage: "trash")
                            }
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.red.opacity(0.24), lineWidth: 1))
                        }
                        .buttonStyle(PressableButtonStyle())
                        .disabled(isDeletingAccount)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(DashboardPalette.canvas)
        .alert("永久刪除 Hairmap 帳號？", isPresented: $isDeleteAlertPresented) {
            Button("取消", role: .cancel) {}
            Button("刪除帳號", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("這會刪除您的登入帳號並登出此裝置。刪除後如要再次使用 Hairmap，需要重新註冊。")
        }
    }

    private func deleteAccount() {
        Task {
            isDeletingAccount = true
            _ = await store.deleteAccount()
            isDeletingAccount = false
        }
    }
}

private struct DashboardApplicationReviewCard: View {
    let notice: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("提交平台審批", systemImage: "checkmark.seal")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(Color(red: 0.67, green: 0.47, blue: 0.05))
            Text("新增或更新公開檔案時會先儲存在 Supabase 申請表，等管理員批准後才會出現在顧客端。")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .lineSpacing(2)

            if !notice.isEmpty {
                Label(notice, systemImage: "clock.badge.checkmark")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(DashboardPalette.green)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(Color(red: 1.0, green: 0.985, blue: 0.9), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DashboardPalette.gold.opacity(0.45), lineWidth: 1))
    }
}

private extension Text {
    func reviewSubmitButtonStyle(filled: Bool) -> some View {
        self
            .font(.system(size: 12, weight: .black))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(filled ? .white : .black)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(filled ? Color.black : Color.white, in: RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(.black, lineWidth: 1))
    }
}

private struct DashboardFormCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(14)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.black, lineWidth: 1))
    }
}

private struct DashboardInputField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 13)
                .frame(height: 48)
                .background(.white, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 1))
        }
    }
}

private struct DashboardInstagramField: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Instagram 連結 / @帳號")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                HairmapInstagramGlyph(color: .secondary.opacity(0.75))
                TextField("@hairmaphk 或 https://instagram.com/hairmaphk", text: $text)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DashboardPalette.gold, lineWidth: 2)
            )
            .shadow(color: DashboardPalette.gold.opacity(0.12), radius: 10, y: 4)
        }
    }
}

private struct DashboardTextArea: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let height: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("必填")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .font(.system(size: 14, weight: .medium))
                    .padding(8)
                    .frame(height: height)
                    .scrollContentBackground(.hidden)

                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
            .background(.white, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 1))
        }
    }
}

private struct DashboardLabeledField: View {
    let label: String
    @Binding var text: String
    var icon: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
            HStack {
                TextField(label, text: $text)
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold))
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 38)
            .background(.white, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black, lineWidth: 1))
        }
    }
}

private struct DashboardMenuField: View {
    let label: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) { selection = option }
                }
            } label: {
                HStack {
                    Text(selection)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .black))
                }
                .font(.system(size: 14, weight: .black))
                .padding(.horizontal, 12)
                .frame(height: 46)
                .background(.white, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 1))
                .foregroundStyle(.black)
            }
            .buttonStyle(PressableButtonStyle())
        }
    }
}

private struct DashboardServiceEditor: View {
    @Binding var services: [DashboardServiceDraft]
    @Binding var customName: String
    @Binding var customCategory: String
    @Binding var customDescription: String
    @Binding var customPrice: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Label("設定精選服務項目與價格名冊", systemImage: "rosette")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(Color(red: 0.67, green: 0.47, blue: 0.05))
                Text("勾選您要提供的項目並自訂價格。未勾選的項目將不會顯示在您的服務項目中。")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            ForEach($services) { $service in
                HStack(alignment: .top, spacing: 10) {
                    Button {
                        service.isSelected.toggle()
                    } label: {
                        Image(systemName: service.isSelected ? "checkmark.square.fill" : "square")
                            .font(.system(size: 19, weight: .black))
                            .foregroundStyle(service.isSelected ? .black : .secondary)
                    }
                    .buttonStyle(PressableButtonStyle())

                    VStack(alignment: .leading, spacing: 6) {
                        Text(service.name)
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(.black)
                        Text("\(service.description)・\(service.duration) 分鐘")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 6)

                    HStack(spacing: 6) {
                        Text("HK$")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(.secondary)
                        TextField("0", value: $service.price, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .frame(width: 64)
                            .frame(height: 32)
                            .background(.white, in: RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(.black.opacity(0.1), lineWidth: 1))
                    }
                }
                .padding(12)
                .background(.white, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.black.opacity(0.06), lineWidth: 1))
            }

            Divider()

            Text("+ 新增與目前額外剪染項目")
                .font(.system(size: 13, weight: .black))
            HStack(spacing: 8) {
                TextField("服務名稱", text: $customName)
                    .dashboardMiniField()
                Menu {
                    ForEach(["剪髮", "染髮", "燙髮", "護髮", "直髮"], id: \.self) { category in
                        Button(category) { customCategory = category }
                    }
                } label: {
                    Text(customCategory)
                        .font(.system(size: 12, weight: .black))
                        .frame(width: 92, height: 38)
                        .background(.white, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.12), lineWidth: 1))
                        .foregroundStyle(.black)
                }
            }
            HStack(spacing: 8) {
                TextField("簡略耗時與服務細節描述", text: $customDescription)
                    .dashboardMiniField()
                TextField("定價金額", text: $customPrice)
                    .keyboardType(.numberPad)
                    .dashboardMiniField(width: 92)
            }
            Button {
                addCustomService()
            } label: {
                Text("加入此項自訂服務定價")
                    .font(.system(size: 13, weight: .black))
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(Color.black.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.black)
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(14)
        .background(Color(red: 0.985, green: 0.985, blue: 0.975), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.black.opacity(0.08), lineWidth: 1))
    }

    private func addCustomService() {
        let name = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        services.append(
            DashboardServiceDraft(
                id: "dash_custom_\(Int(Date().timeIntervalSince1970 * 1000))",
                name: name,
                category: customCategory,
                duration: 60,
                description: customDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "髮型師自訂服務" : customDescription,
                price: Int(customPrice) ?? 0,
                isSelected: true
            )
        )
        customName = ""
        customDescription = ""
        customPrice = ""
    }
}

private struct DashboardTagEditor: View {
    let tags: [String]
    @Binding var selected: Set<String>

    private let columns = [
        GridItem(.adaptive(minimum: 84), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("設計師擅長技術（可選多項）")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Button {
                        if selected.contains(tag) {
                            selected.remove(tag)
                        } else {
                            selected.insert(tag)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            if selected.contains(tag) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .black))
                            }
                            Text(tag)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }
                        .font(.system(size: 12, weight: .black))
                        .padding(.horizontal, 11)
                        .frame(height: 32)
                        .background(selected.contains(tag) ? DashboardPalette.gold : .white, in: Capsule())
                        .overlay(Capsule().stroke(.black.opacity(0.14), lineWidth: 1))
                        .foregroundStyle(.black)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
    }
}

private struct DashboardAvatarEditor: View {
    @Binding var avatarURL: String
    @Binding var pickedAvatarItem: PhotosPickerItem?
    let uploadedAvatarData: Data?
    let presets: [DashboardImageChoice]

    private let avatarColumns = [
        GridItem(.flexible(), spacing: 9),
        GridItem(.flexible(), spacing: 9),
        GridItem(.flexible(), spacing: 9)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("設計師個人頭像自訂")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: avatarColumns, spacing: 9) {
                ForEach(presets) { preset in
                    Button {
                        avatarURL = preset.url
                    } label: {
                        ZStack(alignment: .bottom) {
                            RemoteImage(urlString: preset.url, height: 86, cornerRadius: 8)
                            Text(preset.title)
                                .font(.system(size: 9, weight: .black))
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .background(.black.opacity(0.52))
                        }
                        .overlay(alignment: .topTrailing) {
                            if avatarURL == preset.url {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.black, DashboardPalette.gold)
                                    .padding(5)
                            }
                        }
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }

            HStack(spacing: 10) {
                DashboardUploadedImage(data: uploadedAvatarData, urlString: avatarURL, height: 42, cornerRadius: 21)
                    .frame(width: 42)
                    .clipShape(Circle())

                PhotosPicker(selection: $pickedAvatarItem, matching: .images) {
                    Label("選擇並上載設計師照片", systemImage: "square.and.arrow.up")
                        .font(.system(size: 13, weight: .black))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(.white, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.12), lineWidth: 1))
                        .foregroundStyle(.black)
                }
                .buttonStyle(PressableButtonStyle())
            }

            DashboardInputField(label: "或輸入自訂第三方照片網址", placeholder: "https://example.com/custom-stylist-avatar.jpg", text: $avatarURL)
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.black.opacity(0.08), lineWidth: 1))
    }
}

private struct DashboardPortfolioEditor: View {
    let stylistID: String
    @Binding var works: [PortfolioWork]
    @Binding var customWorkTitle: String
    @Binding var customWorkURL: String
    @Binding var pickedWorkItems: [PhotosPickerItem]

    private var remainingSlots: Int { max(0, 10 - works.count) }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Label("設計師作品剪染展示集 (\(min(works.count, 10)) / 10)", systemImage: "photo.on.rectangle.angled")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(Color(red: 0.68, green: 0.49, blue: 0.07))
                Spacer()
                Text("上限10張")
                    .font(.system(size: 10, weight: .black))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.08), in: Capsule())
            }

            if !works.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(works.prefix(10)) { work in
                        ZStack(alignment: .topTrailing) {
                            DashboardUploadedImage(data: nil, urlString: work.imageURL, height: 74, cornerRadius: 8)
                            Button {
                                works.removeAll { $0.id == work.id }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Color(red: 0.95, green: 0.05, blue: 0.28), in: Circle())
                            }
                            .padding(4)
                        }
                    }
                }
            }

            PhotosPicker(selection: $pickedWorkItems, maxSelectionCount: max(1, remainingSlots), matching: .images) {
                Label(remainingSlots == 0 ? "已達作品上限" : "自手機相簿選擇多張作品", systemImage: "square.and.arrow.up")
                    .font(.system(size: 13, weight: .black))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(.white, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.12), lineWidth: 1))
                    .foregroundStyle(.black)
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(remainingSlots == 0)
            .opacity(remainingSlots == 0 ? 0.45 : 1)

            Text("可一次選擇多張相片；提交時只會使用您上載或手動加入的作品，不會自動加入示範作品。")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                TextField("作品標題", text: $customWorkTitle)
                    .dashboardMiniField()
                TextField("https://...jpg", text: $customWorkURL)
                    .dashboardMiniField()
            }

            Button {
                addURLWork()
            } label: {
                Text("加入此作品項目")
                    .font(.system(size: 13, weight: .black))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(.black, in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.white)
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(remainingSlots == 0)
            .opacity(remainingSlots == 0 ? 0.45 : 1)
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.black.opacity(0.08), lineWidth: 1))
    }

    private func addURLWork() {
        guard remainingSlots > 0 else { return }
        let url = customWorkURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty else { return }
        let title = customWorkTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        works.append(
            PortfolioWork(
                id: "dash_url_work_\(Int(Date().timeIntervalSince1970 * 1000))",
                stylistID: stylistID,
                title: title.isEmpty ? "自訂作品" : title,
                imageURL: url
            )
        )
        customWorkTitle = ""
        customWorkURL = ""
    }
}

private struct DashboardServiceDraft: Identifiable, Hashable {
    var id: String
    var name: String
    var category: String
    var duration: Int
    var description: String
    var price: Int
    var isSelected: Bool

    static func optionalDefaults(stylistID: String) -> [DashboardServiceDraft] {
        [
            DashboardServiceDraft(id: "\(stylistID)_optional_perm", name: "韓系免整理慵懶潤雲朵燙 (漫髮)", category: "燙髮", duration: 150, description: "客製化修飾臉型大波浪，自然蓬鬆彈力", price: 980, isSelected: false),
            DashboardServiceDraft(id: "\(stylistID)_optional_straight", name: "日本膠原蛋白極上縮毛離子矯正 (直髮)", category: "直髮", duration: 180, description: "拯救嚴重自然捲與毛躁粗硬，重現瀑布柔順", price: 1380, isSelected: false),
            DashboardServiceDraft(id: "\(stylistID)_optional_color", name: "明星巴黎手刷多層次手感挑色漂染 (染髮)", category: "染髮", duration: 180, description: "高質感 3D 立體手畫染，打造歐美時間漸層", price: 1680, isSelected: false)
        ]
    }

    static func starterDefaults(stylistID: String) -> [DashboardServiceDraft] {
        [
            DashboardServiceDraft(id: "\(stylistID)_starter_cut", name: "招牌精修剪髮", category: "剪髮", duration: 60, description: "包含洗髮、頭型修飾與基礎造型", price: 380, isSelected: true),
            DashboardServiceDraft(id: "\(stylistID)_starter_color", name: "質感染髮與光澤護理", category: "染髮", duration: 120, description: "依髮質調配色調，附基礎護理", price: 880, isSelected: true),
            DashboardServiceDraft(id: "\(stylistID)_starter_treatment", name: "深層護髮修復", category: "護髮", duration: 90, description: "改善毛躁與受損髮尾", price: 680, isSelected: true)
        ] + optionalDefaults(stylistID: stylistID)
    }
}

private struct DashboardImageChoice: Identifiable, Hashable {
    var id: String { url }
    let title: String
    let url: String
}

private struct DashboardUploadedImage: View {
    let data: Data?
    let urlString: String
    let height: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        Group {
            if let data, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                RemoteImage(urlString: urlString, height: height, cornerRadius: cornerRadius)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .clipped()
    }
}

private extension View {
    func dashboardMiniField(width: CGFloat? = nil) -> some View {
        self
            .font(.system(size: 12, weight: .medium))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.horizontal, 10)
            .frame(width: width)
            .frame(height: 38)
            .background(.white, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.12), lineWidth: 1))
    }
}

private func saveDashboardUploadedImage(_ data: Data, prefix: String) -> String? {
    guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
    let url = documents.appendingPathComponent("\(prefix)-\(UUID().uuidString).jpg")
    do {
        try data.write(to: url, options: [.atomic])
        return url.absoluteString
    } catch {
        return nil
    }
}
