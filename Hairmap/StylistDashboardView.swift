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
    @State private var instagramURL = "https://images.unsplash.com/portfolio-balayage-hairs"
    @State private var pickedAvatarItem: PhotosPickerItem?
    @State private var pickedWorkItem: PhotosPickerItem?
    @State private var uploadedAvatarData: Data?
    @State private var uploadedWorkData: Data?

    private var stylist: Stylist { store.stylist(id: stylistID) }

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

                    DashboardBottomBar(selection: $tab) {
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
        .onAppear(perform: loadProfileIfNeeded)
        .onChange(of: pickedAvatarItem) { _, newItem in
            Task { await loadAvatar(newItem) }
        }
        .onChange(of: pickedWorkItem) { _, newItem in
            Task { await loadPortfolioWork(newItem) }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
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
                name: $profileName,
                title: $profileTitle,
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
                pickedWorkItem: $pickedWorkItem,
                uploadedAvatarData: uploadedAvatarData,
                uploadedWorkData: uploadedWorkData,
                onSave: saveProfile
            )
        }
    }

    private func loadProfileIfNeeded() {
        guard !didLoadProfile else { return }
        didLoadProfile = true
        let stylist = stylist
        profileName = stylist.name
        profileTitle = stylist.title
        profileBio = stylist.bio
        profileExperience = stylist.experience
        profileLanguages = stylist.languages
        profileAvatarURL = stylist.avatarURL
        selectedTags = Set(stylist.specialties)
        profileWorks = stylist.works
        profileServices = stylist.services.map { service in
            DashboardServiceDraft(
                id: service.id,
                name: service.name,
                category: service.category,
                duration: service.duration,
                description: service.description,
                price: service.price,
                isSelected: true
            )
        } + DashboardServiceDraft.optionalDefaults(stylistID: stylistID)
    }

    private func loadAvatar(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
        uploadedAvatarData = data
        if let savedURL = saveDashboardUploadedImage(data, prefix: "dashboard-avatar") {
            profileAvatarURL = savedURL
        }
    }

    private func loadPortfolioWork(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
        uploadedWorkData = data
        if let savedURL = saveDashboardUploadedImage(data, prefix: "dashboard-work") {
            let title = customWorkTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            profileWorks.insert(
                PortfolioWork(
                    id: "dash_work_\(Int(Date().timeIntervalSince1970 * 1000))",
                    stylistID: stylistID,
                    title: title.isEmpty ? "自訂上載作品" : title,
                    imageURL: savedURL
                ),
                at: 0
            )
            customWorkTitle = ""
        }
    }

    private func saveProfile() {
        Task { await saveProfileAsync() }
    }

    private func saveProfileAsync() async {
        var updated = stylist
        updated.name = profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? updated.name : profileName
        updated.title = profileTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? updated.title : profileTitle
        updated.bio = profileBio
        updated.experience = profileExperience
        updated.languages = profileLanguages
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

        await store.saveStylist(updated)
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
        case .profile: "我的檔案"
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
    @Binding var selection: StylistWorkTab
    let resetNestedRoute: () -> Void

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
                            if tab == .messages {
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

private struct StylistTodayBookingsPage: View {
    @Environment(HairmapStore.self) private var store
    let stylistID: String
    let openThread: (String) -> Void

    @State private var rows = DashboardBookingRow.demo

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
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(DashboardPalette.canvas)
        .onAppear(perform: mergeStoreBookings)
    }

    private func mergeStoreBookings() {
        let liveRows = store.bookings
            .filter { $0.stylistID == stylistID && $0.status != .cancelled && $0.status != .completed }
            .map { booking in
                DashboardBookingRow(booking: booking)
            }

        guard !liveRows.isEmpty else { return }
        var merged = liveRows
        for row in rows where !merged.contains(where: { $0.id == row.id }) {
            merged.append(row)
        }
        rows = merged
    }

    private func update(_ row: DashboardBookingRow, to status: BookingStatus) {
        if let index = rows.firstIndex(where: { $0.id == row.id }) {
            rows[index].status = status
        }

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
        threadID = "thread-alex"
        timeSlot = "\(booking.startTime) - \(booking.endTime)"
        clientName = booking.clientName
        phone = booking.clientPhone
        service = booking.serviceName
        price = booking.price
        status = booking.status
    }

    init(id: String, threadID: String, timeSlot: String, clientName: String, phone: String, service: String, price: Int, status: BookingStatus) {
        self.id = id
        self.threadID = threadID
        self.timeSlot = timeSlot
        self.clientName = clientName
        self.phone = phone
        self.service = service
        self.price = price
        self.status = status
    }

    static let demo = [
        DashboardBookingRow(id: "demo-lily", threadID: "thread-alex", timeSlot: "09:30 - 11:00", clientName: "廖小莉 (Lily)", phone: "+852 9112 3456", service: "招牌剪髮 & 頭皮舒壓洗", price: 120, status: .pending),
        DashboardBookingRow(id: "demo-jane", threadID: "thread-mandy", timeSlot: "18:00 - 19:30", clientName: "王阿珍 (Jane)", phone: "+852 9876 5432", service: "巴西生命果抗毛躁護髮", price: 180, status: .pending),
        DashboardBookingRow(id: "demo-chris", threadID: "thread-chris", timeSlot: "11:00 - 13:00", clientName: "陳俊言 (Chris)", phone: "+852 6224 8890", service: "自然漸層推剪 & 特色漸層染", price: 260, status: .accepted),
        DashboardBookingRow(id: "demo-mandy", threadID: "thread-mandy", timeSlot: "14:30 - 17:30", clientName: "Mandy Lee", phone: "+852 6022 1834", service: "頂級日系高感立體單色染髮", price: 150, status: .accepted)
    ]
}

private struct StylistMessagesWorkspace: View {
    @Environment(HairmapStore.self) private var store
    let stylistID: String
    @Binding var selectedThreadID: String?

    @State private var threads = DashboardThread.demo
    @State private var threadMessages = DashboardThread.demoMessages
    @State private var replyDraft = ""

    private var selectedThread: DashboardThread? {
        guard let selectedThreadID else { return nil }
        return threads.first { $0.id == selectedThreadID }
    }

    var body: some View {
        Group {
            if let selectedThread {
                DashboardChatDetailPage(
                    thread: selectedThread,
                    messages: threadMessages[selectedThread.id] ?? [],
                    replyDraft: $replyDraft,
                    onBack: {
                        withAnimation(.snappy(duration: 0.22)) {
                            selectedThreadID = nil
                        }
                    },
                    onSend: sendReply
                )
            } else {
                DashboardChatInboxPage(threads: threads) { thread in
                    markSeen(thread.id)
                    withAnimation(.snappy(duration: 0.22)) {
                        selectedThreadID = thread.id
                    }
                }
            }
        }
        .background(DashboardPalette.canvas)
    }

    private func markSeen(_ id: String) {
        if let index = threads.firstIndex(where: { $0.id == id }) {
            threads[index].isUnread = false
            threads[index].seenText = "已讀"
        }
    }

    private func sendReply() {
        let clean = replyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, let thread = selectedThread else { return }
        replyDraft = ""
        let message = DashboardChatLine(
            id: "reply_\(Int(Date().timeIntervalSince1970 * 1000))",
            text: clean,
            time: DateFormatter.hmTime.string(from: Date()),
            isStylist: true,
            isSeen: true
        )
        threadMessages[thread.id, default: []].append(message)
        if let index = threads.firstIndex(where: { $0.id == thread.id }) {
            threads[index].lastMessage = clean
            threads[index].time = "剛剛"
            threads[index].seenText = "已讀"
        }
        Task { await store.sendMessage(text: clean, stylistID: stylistID, sender: .stylist) }
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

                    ForEach(threads) { thread in
                        Button {
                            openThread(thread)
                        } label: {
                            DashboardThreadCard(thread: thread)
                        }
                        .buttonStyle(PressableButtonStyle())
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

private struct DashboardThreadCard: View {
    let thread: DashboardThread

    var body: some View {
        HStack(spacing: 14) {
            RemoteImage(urlString: thread.avatarURL, height: 54, cornerRadius: 27)
                .frame(width: 54, height: 54)
                .clipShape(Circle())
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

                RemoteImage(urlString: thread.avatarURL, height: 32, cornerRadius: 16)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())

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
                            avatarURL: message.isStylist ? "https://images.unsplash.com/photo-1615109398623-88346a601842?auto=format&fit=crop&w=400&q=80" : thread.avatarURL
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

    var body: some View {
        HStack(alignment: .bottom, spacing: 9) {
            if !message.isStylist {
                RemoteImage(urlString: avatarURL, height: 28, cornerRadius: 14)
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
            } else {
                Spacer(minLength: 38)
            }

            VStack(alignment: message.isStylist ? .trailing : .leading, spacing: 5) {
                Text(message.text)
                    .font(.system(size: 14, weight: .medium))
                    .lineSpacing(3)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .foregroundStyle(message.isStylist ? .white : .black)
                    .background(message.isStylist ? .black : .white, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(message.isStylist ? .clear : .black, lineWidth: 1))

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
}

private struct DashboardThread: Identifiable, Hashable {
    var id: String
    var name: String
    var tag: String
    var avatarURL: String
    var lastMessage: String
    var time: String
    var isUnread: Bool
    var seenText: String
    var chips: [String]

    static let demo = [
        DashboardThread(id: "thread-alex", name: "Alex Chen", tag: "", avatarURL: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=300&q=80", lastMessage: "巴黎畫染適合我的髮質嗎？", time: "15:09", isUnread: true, seenText: "未讀 ☐", chips: ["挑染諮詢"]),
        DashboardThread(id: "thread-chris", name: "Chris Wong", tag: "", avatarURL: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80", lastMessage: "謝謝老師，今天的新層推修飾十分清爽！", time: "昨日", isUnread: false, seenText: "已讀", chips: ["男士剪髮"]),
        DashboardThread(id: "thread-mandy", name: "Mandy Lee", tag: "", avatarURL: "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=300&q=80", lastMessage: "好，到時候再見！", time: "2天前", isUnread: false, seenText: "已讀", chips: ["深層護理"])
    ]

    static let demoMessages: [String: [DashboardChatLine]] = [
        "thread-alex": [
            DashboardChatLine(id: "a1", text: "老師你好，我預約了下星期六下午的畫染。", time: "14:59", isStylist: false, isSeen: false),
            DashboardChatLine(id: "a2", text: "您好！沒問題，看到您的預約了。可以分享一下您目前的髮色照片嗎？", time: "14:55", isStylist: true, isSeen: true),
            DashboardChatLine(id: "a3", text: "好呀，目前的髮尾有點漂過，退成橘黃色，巴黎畫染適合我的髮質嗎？", time: "15:16", isStylist: false, isSeen: false)
        ],
        "thread-chris": [
            DashboardChatLine(id: "c1", text: "謝謝老師，今天的新層推修飾十分清爽！", time: "昨日", isStylist: false, isSeen: false),
            DashboardChatLine(id: "c2", text: "保持兩側乾淨線條，下次四至五週回來修一修就剛好。", time: "昨日", isStylist: true, isSeen: true)
        ],
        "thread-mandy": [
            DashboardChatLine(id: "m1", text: "好，到時候再見！", time: "2天前", isStylist: false, isSeen: false)
        ]
    ]
}

private struct DashboardChatLine: Identifiable, Hashable {
    var id: String
    var text: String
    var time: String
    var isStylist: Bool
    var isSeen: Bool
}

private struct StylistScheduleWorkspace: View {
    @Environment(HairmapStore.self) private var store
    let stylistID: String

    @State private var selectedDate = DashboardCalendar.date(from: "2026-06-06") ?? Date()
    @State private var isCalendarOpen = false
    @State private var blockedTimes: Set<String> = ["12:00", "13:00"]
    @State private var batchStartDate = DashboardCalendar.date(from: "2026-06-06") ?? Date()
    @State private var batchEndDate = DashboardCalendar.date(from: "2026-06-08") ?? Date()
    @State private var batchStartTime = "13:00"
    @State private var batchEndTime = "17:00"

    private let times = ["09:00", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00", "18:00", "19:00", "20:00"]
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                DashboardSectionHeader(eyebrow: "🔒 Block Schedule", title: "檔期管理 (塞迷忙碌)")

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
                    Text("時段切換 (點擊切換「可約」/「忙碌」)")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label("系統與 Supabase 自主連機", systemImage: "circle.fill")
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
    }

    private var selectedDateKey: String {
        DashboardCalendar.key(from: selectedDate)
    }

    private func isBlocked(_ time: String) -> Bool {
        blockedTimes.contains(time) || store.isBlocked(stylistID: stylistID, date: selectedDateKey, time: time)
    }

    private func toggle(_ time: String) {
        if blockedTimes.contains(time) {
            blockedTimes.remove(time)
        } else {
            blockedTimes.insert(time)
        }
        Task { await store.toggleBlockedSlot(stylistID: stylistID, date: selectedDateKey, time: time) }
    }

    private func batchBlock() {
        let startIndex = times.firstIndex(of: batchStartTime) ?? 0
        let endIndex = times.firstIndex(of: batchEndTime) ?? startIndex
        let selectedTimes = Array(times[min(startIndex, endIndex)...max(startIndex, endIndex)])
        let dateKeys = DashboardCalendar.keys(from: batchStartDate, to: batchEndDate)

        for dateKey in dateKeys {
            for time in selectedTimes where !store.isBlocked(stylistID: stylistID, date: dateKey, time: time) {
                if dateKey == selectedDateKey {
                    blockedTimes.insert(time)
                }
                Task { await store.toggleBlockedSlot(stylistID: stylistID, date: dateKey, time: time) }
            }
        }
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

            Text("挑選日期範圍與每天的特定小時時段，一鍵快速於 Supabase 寫入 blocked_slots 表以阻擋顧客惡意預約。")
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
    let stylistID: String
    @Binding var name: String
    @Binding var title: String
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
    @Binding var pickedWorkItem: PhotosPickerItem?
    let uploadedAvatarData: Data?
    let uploadedWorkData: Data?
    let onSave: () -> Void

    private let tags = ["挑染專家", "經典剪髮", "歐美挑染", "漸層推剪", "韓式燙髮", "縮毛矯正", "女神大波浪", "深層護理", "直髮柔順"]
    private let avatarPresets = [
        DashboardImageChoice(title: "美髮現代女設計師", url: "https://images.unsplash.com/photo-1556157382-97eda2d62296?auto=format&fit=crop&w=600&q=80"),
        DashboardImageChoice(title: "經驗紳士男設計師", url: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=600&q=80"),
        DashboardImageChoice(title: "韓系甜美女設計師", url: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=600&q=80")
    ]
    private let portfolioPresets = SeedData.works

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                DashboardSectionHeader(eyebrow: "🟡 My Stylist Profile", title: "我的檔案名片管理")

                DashboardFormCard {
                    DashboardInputField(label: "設計師姓名 *", placeholder: "Master Leo", text: $name)
                    DashboardInputField(label: "頭銜職稱 *", placeholder: "首席設計師", text: $title)
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
                        works: $works,
                        customWorkTitle: $customWorkTitle,
                        customWorkURL: $customWorkURL,
                        pickedWorkItem: $pickedWorkItem,
                        uploadedWorkData: uploadedWorkData,
                        presets: Array(portfolioPresets.prefix(8))
                    )

                    DashboardInputField(label: "設計師線上 IG 專案作品連結", placeholder: "https://...", text: $instagramURL)

                    Button(action: onSave) {
                        Text("儲存名片並更新 Supabase 表")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(.black, in: RoundedRectangle(cornerRadius: 9))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(DashboardPalette.canvas)
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
    @Binding var works: [PortfolioWork]
    @Binding var customWorkTitle: String
    @Binding var customWorkURL: String
    @Binding var pickedWorkItem: PhotosPickerItem?
    let uploadedWorkData: Data?
    let presets: [PortfolioWork]

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

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
                    ForEach(works.prefix(4)) { work in
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

            Text("熱門風格快速加入項目")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(presets) { work in
                    Button {
                        addPreset(work)
                    } label: {
                        ZStack(alignment: .bottom) {
                            RemoteImage(urlString: work.imageURL, height: 82, cornerRadius: 8)
                            Text(work.title)
                                .font(.system(size: 9, weight: .black))
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .foregroundStyle(.white)
                                .background(.black.opacity(0.5))
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(.black.opacity(0.4), in: Circle())
                        }
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }

            PhotosPicker(selection: $pickedWorkItem, matching: .images) {
                Label("自手機相簿選擇作品", systemImage: "square.and.arrow.up")
                    .font(.system(size: 13, weight: .black))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(.white, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.12), lineWidth: 1))
                    .foregroundStyle(.black)
            }
            .buttonStyle(PressableButtonStyle())

            if let uploadedWorkData {
                DashboardUploadedImage(data: uploadedWorkData, urlString: "", height: 86, cornerRadius: 8)
            }

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
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.black.opacity(0.08), lineWidth: 1))
    }

    private func addPreset(_ work: PortfolioWork) {
        guard !works.contains(where: { $0.id == work.id }) else { return }
        works.append(work)
    }

    private func addURLWork() {
        let url = customWorkURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty else { return }
        let title = customWorkTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        works.append(
            PortfolioWork(
                id: "dash_url_work_\(Int(Date().timeIntervalSince1970 * 1000))",
                stylistID: "master-leo",
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
