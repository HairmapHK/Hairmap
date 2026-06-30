import SwiftUI
import PhotosUI
import UIKit

struct BookingView: View {
    @Environment(HairmapStore.self) private var store
    @State private var stage: BookingStage = .selectStylist
    @State private var selectedStylistID = "master-leo"
    @State private var selectedServiceID = ""
    @State private var selectedDate = BookingDate.today()
    @State private var selectedTime = "10:00"
    @State private var clientName = ""
    @State private var clientPhone = ""
    @State private var searchText = ""
    @State private var selectedSpecialty = "全部專長"
    @State private var showMonthGrid = false
    @State private var isSubmitting = false
    @State private var successBooking: Appointment?
    @State private var didSendProgress = false

    private var stylist: Stylist {
        store.stylists.first { $0.id == selectedStylistID } ?? store.stylist()
    }

    private var salon: Salon {
        store.salon(id: stylist.salonID)
    }

    private var service: ServiceItem {
        if let picked = stylist.services.first(where: { $0.id == selectedServiceID }) {
            return picked
        }
        return store.selectedService ?? stylist.services.first ?? SeedData.services[0]
    }

    private var selectedDateKey: String {
        DateFormatter.hmDate.string(from: selectedDate)
    }

    private var filteredStylists: [Stylist] {
        let cleanSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return store.stylists.filter { item in
            let specialtyMatches = selectedSpecialty == "全部專長" || item.specialties.contains(selectedSpecialty)
            guard specialtyMatches else { return false }
            guard !cleanSearch.isEmpty else { return true }
            let salon = store.salon(id: item.salonID)
            let source = ([item.name, item.title, item.district, item.location, salon.name, salon.district, salon.location] + item.specialties).joined(separator: " ").lowercased()
            return source.contains(cleanSearch)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let contentWidth = min(proxy.size.width, 430)
            ZStack {
                HMTheme.paper.ignoresSafeArea()

                Group {
                    switch stage {
                    case .selectStylist:
                        BookingStylistSelectionPage(
                            contentWidth: contentWidth,
                            stylists: filteredStylists,
                            salons: store.salons,
                            searchText: $searchText,
                            selectedSpecialty: $selectedSpecialty,
                            onBack: { store.selectedTab = .discovery },
                            onSelect: chooseStylist
                        )
                    case .schedule:
                        BookingSchedulePage(
                            contentWidth: contentWidth,
                            stylist: stylist,
                            salon: salon,
                            selectedServiceID: selectedServiceID,
                            selectedDate: selectedDate,
                            selectedTime: selectedTime,
                            clientName: $clientName,
                            clientPhone: $clientPhone,
                            showMonthGrid: $showMonthGrid,
                            isSubmitting: isSubmitting,
                            onBack: { stage = .selectStylist },
                            onReselectStylist: { stage = .selectStylist },
                            onSelectService: selectService,
                            onSelectDate: selectDate,
                            onSelectTime: selectTime,
                            isDateFull: isDateFull,
                            isSlotFull: isSlotFull,
                            isSlotNearlyFull: isSlotNearlyFull,
                            onSubmit: { Task { await submit() } }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let successBooking {
                    BookingSuccessOverlay(
                        booking: successBooking,
                        contentWidth: contentWidth,
                        didSendProgress: didSendProgress,
                        onSendProgress: { Task { await sendProgress(booking: successBooking) } },
                        onDone: closeSuccess
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            selectedStylistID = store.selectedStylistID
            if let service = store.selectedService {
                selectedServiceID = service.id
                stage = .schedule
            } else {
                selectedServiceID = stylist.services.first?.id ?? ""
            }
            selectedTime = firstAvailableTime() ?? selectedTime
        }
        .task {
            await store.refreshCatalog()
            selectedTime = firstAvailableTime() ?? selectedTime
        }
        .animation(.snappy(duration: 0.28), value: stage)
        .animation(.snappy(duration: 0.22), value: successBooking)
        .premiumBackground()
    }

    private func chooseStylist(_ item: Stylist) {
        selectedStylistID = item.id
        selectedServiceID = item.services.first?.id ?? ""
        store.selectedStylistID = item.id
        store.selectedService = item.services.first
        selectedTime = firstAvailableTime() ?? selectedTime
        stage = .schedule
    }

    private func selectService(_ item: ServiceItem) {
        selectedServiceID = item.id
        store.selectedService = item
    }

    private func selectDate(_ date: Date) {
        selectedDate = date
        if isSlotFull(selectedTime) {
            selectedTime = firstAvailableTime() ?? selectedTime
        }
    }

    private func selectTime(_ time: String) {
        guard !isSlotFull(time) else { return }
        selectedTime = time
    }

    private func submit() async {
        guard !isSubmitting else { return }
        let cleanName = clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPhone = clientPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        let phoneDigits = cleanPhone.filter(\.isNumber)
        guard !cleanName.isEmpty, phoneDigits.count >= 8 else {
            store.statusMessage = "請先填寫姓名及有效聯絡電話"
            return
        }
        clientName = cleanName
        clientPhone = cleanPhone
        isSubmitting = true
        defer { isSubmitting = false }
        let endTime = addMinutes(selectedTime, service.duration)
        let booking = await store.submitBooking(
            service: service,
            stylist: stylist,
            date: selectedDateKey,
            startTime: selectedTime,
            endTime: endTime,
            clientName: clientName,
            clientPhone: clientPhone
        )
        didSendProgress = false
        successBooking = booking
    }

    private func sendProgress(booking: Appointment) async {
        let text = """
        預約進度通知：\(booking.clientName) 已完成 \(booking.serviceName) 預約。
        日期時間：\(booking.bookingDate) \(booking.timeSlot)
        到店付款：HK$ \(booking.price)
        """
        await store.sendMessage(text: text, stylistID: booking.stylistID, sender: .customer)
        didSendProgress = true
    }

    private func closeSuccess() {
        successBooking = nil
        didSendProgress = false
    }

    private func isDateFull(_ date: Date) -> Bool {
        BookingDate.slotGroups
            .flatMap(\.times)
            .allSatisfy { isSlotFull($0, on: date) }
    }

    private func isSlotFull(_ time: String) -> Bool {
        isSlotFull(time, on: selectedDate)
    }

    private func isSlotFull(_ time: String, on date: Date) -> Bool {
        let dateKey = DateFormatter.hmDate.string(from: date)
        let hasActiveBooking = store.bookings.contains { booking in
            booking.stylistID == selectedStylistID &&
                booking.bookingDate == dateKey &&
                booking.startTime.hmTimeKey == time.hmTimeKey &&
                booking.status != .cancelled &&
                booking.status != .completed
        }
        return store.isBlocked(stylistID: selectedStylistID, date: dateKey, time: time) || hasActiveBooking
    }

    private func isSlotNearlyFull(_ time: String) -> Bool {
        false
    }

    private func firstAvailableTime() -> String? {
        BookingDate.slotGroups
            .flatMap(\.times)
            .first { !isSlotFull($0) }
    }

    private func addMinutes(_ time: String, _ minutes: Int) -> String {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return time }
        var comps = DateComponents()
        comps.hour = parts[0]
        comps.minute = parts[1]
        let date = Calendar.hairmap.date(from: comps) ?? Date()
        let end = Calendar.hairmap.date(byAdding: .minute, value: minutes, to: date) ?? date
        return DateFormatter.hmTime.string(from: end)
    }
}

private enum BookingStage: Hashable {
    case selectStylist
    case schedule
}

private enum BookingDate {
    static let specialtyFilters = ["全部專長", "挑染專家", "經典剪髮", "歐美挑染", "漸層推剪", "韓式燙髮", "縮毛矯正", "女神大波浪", "深層護理"]

    static let slotGroups = [
        BookingSlotGroup(title: "早上時段", range: "09:00 - 12:00", icon: "sun.max.fill", times: ["09:00", "10:00", "11:00"]),
        BookingSlotGroup(title: "下午時段", range: "12:00 - 17:00", icon: "sun.haze.fill", times: ["13:30", "14:30", "15:30"]),
        BookingSlotGroup(title: "晚間時段", range: "17:00 - 21:30", icon: "moon.stars.fill", times: ["17:30", "18:30", "19:30", "20:00", "20:30"])
    ]

    static func today() -> Date {
        Calendar.hairmap.startOfDay(for: Date())
    }

    static func quickDays() -> [Date] {
        (0..<14).compactMap { Calendar.hairmap.date(byAdding: .day, value: $0, to: today()) }
    }

    static func monthDays(for selectedDate: Date) -> [Date?] {
        let components = Calendar.hairmap.dateComponents([.year, .month], from: selectedDate)
        guard let monthStart = Calendar.hairmap.date(from: components),
              let range = Calendar.hairmap.range(of: .day, in: .month, for: monthStart) else {
            return []
        }
        let firstWeekday = Calendar.hairmap.component(.weekday, from: monthStart)
        let mondayBasedOffset = (firstWeekday + 5) % 7
        var days = Array(repeating: Optional<Date>.none, count: mondayBasedOffset)
        days.append(contentsOf: range.compactMap { day in
            Calendar.hairmap.date(byAdding: .day, value: day - 1, to: monthStart)
        })
        let remainder = days.count % 7
        if remainder != 0 {
            days.append(contentsOf: Array(repeating: Optional<Date>.none, count: 7 - remainder))
        }
        return days
    }

    static func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hant_HK")
        formatter.timeZone = TimeZone(identifier: "Asia/Hong_Kong")
        formatter.dateFormat = "yyyy 年 M 月"
        return formatter.string(from: date)
    }

    static func weekdayText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hant_HK")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    static func monthDayText(_ date: Date) -> String {
        let month = Calendar.hairmap.component(.month, from: date)
        let day = Calendar.hairmap.component(.day, from: date)
        return "\(month)/\(day)"
    }

    static func displayDateText(_ date: Date) -> String {
        let month = Calendar.hairmap.component(.month, from: date)
        let day = Calendar.hairmap.component(.day, from: date)
        return "\(month)/\(day)"
    }
}

private struct BookingSlotGroup: Identifiable {
    let title: String
    let range: String
    let icon: String
    let times: [String]

    var id: String { title }
}

private struct BookingTopBar: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(HMTheme.ink)
                    .frame(width: 44, height: 44)
                    .background(Color.white, in: Circle())
            }
            .buttonStyle(PressableButtonStyle())

            Spacer()

            Text(title)
                .font(.headline.weight(.black))
                .foregroundStyle(HMTheme.ink)

            Spacer()

            Image(systemName: "info.circle")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(HMTheme.amber)
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .frame(height: 72)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.black.opacity(0.06))
                .frame(height: 1)
        }
    }
}

private struct BookingStylistSelectionPage: View {
    let contentWidth: CGFloat
    let stylists: [Stylist]
    let salons: [Salon]
    @Binding var searchText: String
    @Binding var selectedSpecialty: String
    let onBack: () -> Void
    let onSelect: (Stylist) -> Void

    var body: some View {
        VStack(spacing: 0) {
            BookingTopBar(title: "挑選髮型設計師", onBack: onBack)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("尋找您今天的命定髮型師 ✨")
                            .font(.title3.weight(.black))
                            .foregroundStyle(HMTheme.ink)
                            .lineLimit(2)
                        Text("為您篩選香港、九龍區最具人氣的高明度挑染、韓式燙髮名師，可直接一鍵預訂。")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("輸入大師名字 / 標籤查找...", text: $searchText)
                            .font(.callout.weight(.medium))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(HMTheme.ink, lineWidth: 1.1))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(BookingDate.specialtyFilters, id: \.self) { specialty in
                                Button {
                                    selectedSpecialty = specialty
                                } label: {
                                    Text(specialty)
                                        .font(.caption.weight(.black))
                                        .lineLimit(3)
                                        .minimumScaleFactor(0.75)
                                        .multilineTextAlignment(.center)
                                        .frame(width: specialty == "全部專長" ? 42 : 46, height: 84)
                                        .background(selectedSpecialty == specialty ? HMTheme.ink : Color.white, in: Capsule())
                                        .foregroundStyle(selectedSpecialty == specialty ? HMTheme.amber : HMTheme.ink)
                                        .overlay(Capsule().stroke(HMTheme.ink.opacity(0.82), lineWidth: 1))
                                }
                                .buttonStyle(PressableButtonStyle())
                            }
                        }
                        .padding(.horizontal, 1)
                    }

                    VStack(spacing: 14) {
                        ForEach(stylists) { item in
                            BookingStylistSelectCard(
                                stylist: item,
                                salon: salon(for: item),
                                onSelect: { onSelect(item) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 108)
                .frame(width: contentWidth)
            }
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.985, green: 0.985, blue: 0.98))
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Text("請在上方挑選您心儀的髮型設計師\n支援香港四大核心沙龍，100% 真實客戶評價。")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .overlay(alignment: .top) { Rectangle().fill(.black.opacity(0.08)).frame(height: 1) }
        }
    }

    private func salon(for stylist: Stylist) -> Salon? {
        salons.first { $0.id == stylist.salonID }
    }
}

private struct BookingStylistSelectCard: View {
    let stylist: Stylist
    let salon: Salon?
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                RemoteImage(urlString: stylist.avatarURL, height: 68, cornerRadius: 34)
                    .frame(width: 68)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .shadow(color: .black.opacity(0.14), radius: 8, y: 4)

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(stylist.name)
                            .font(.headline.weight(.black))
                            .lineLimit(1)
                        Text("(\(stylist.experience))")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Text("🏷 \(stylist.title)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(HMTheme.ink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 1, green: 0.96, blue: 0.78), in: Capsule())

                    HStack(spacing: 12) {
                        RatingView(rating: stylist.rating)
                        Text("語言: \(stylist.languages)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 6) {
                        ForEach(stylist.specialties.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2.weight(.black))
                                .lineLimit(1)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(Color(red: 1, green: 0.96, blue: 0.78), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                        }
                    }
                }

                Spacer(minLength: 6)

                VStack(spacing: 18) {
                    Text("PRO")
                        .font(.caption2.monospacedDigit().weight(.black))
                        .foregroundStyle(HMTheme.ink)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(HMTheme.amber, in: RoundedRectangle(cornerRadius: 4, style: .continuous))

                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(HMTheme.ink)
                        .frame(width: 36, height: 36)
                        .background(Color.white, in: Circle())
                        .overlay(Circle().stroke(HMTheme.ink, lineWidth: 1))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 130)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(HMTheme.ink, lineWidth: 1.05))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("選擇 \(stylist.name)")
    }
}

private struct BookingSchedulePage: View {
    let contentWidth: CGFloat
    let stylist: Stylist
    let salon: Salon
    let selectedServiceID: String
    let selectedDate: Date
    let selectedTime: String
    @Binding var clientName: String
    @Binding var clientPhone: String
    @Binding var showMonthGrid: Bool
    let isSubmitting: Bool
    let onBack: () -> Void
    let onReselectStylist: () -> Void
    let onSelectService: (ServiceItem) -> Void
    let onSelectDate: (Date) -> Void
    let onSelectTime: (String) -> Void
    let isDateFull: (Date) -> Bool
    let isSlotFull: (String) -> Bool
    let isSlotNearlyFull: (String) -> Bool
    let onSubmit: () -> Void

    private var selectedService: ServiceItem {
        stylist.services.first { $0.id == selectedServiceID } ?? stylist.services.first ?? SeedData.services[0]
    }

    private var hasValidContact: Bool {
        let cleanName = clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        let phoneDigits = clientPhone.filter(\.isNumber)
        return !cleanName.isEmpty && phoneDigits.count >= 8
    }

    var body: some View {
        VStack(spacing: 0) {
            BookingTopBar(title: "選擇日期與完成預約", onBack: onBack)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    selectedStylistCard
                    serviceSection
                    dateSection
                    timeSection
                    contactSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 164)
                .frame(width: contentWidth)
            }
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.985, green: 0.985, blue: 0.98))
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BookingStickySummary(
                stylist: stylist,
                service: selectedService,
                date: selectedDate,
                time: selectedTime,
                isSubmitting: isSubmitting,
                canSubmit: hasValidContact,
                onSubmit: onSubmit
            )
        }
    }

    private var selectedStylistCard: some View {
        HStack(spacing: 12) {
            RemoteImage(urlString: stylist.avatarURL, height: 54, cornerRadius: 27)
                .frame(width: 54)
                .clipShape(Circle())
                .overlay(alignment: .bottomTrailing) {
                    Circle()
                        .fill(HMTheme.emerald)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(.white, lineWidth: 1.5))
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("當前選擇")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Text(stylist.name)
                        .font(.headline.weight(.black))
                    Text("大師級")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(HMTheme.ink)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(HMTheme.amber, in: Capsule())
                }
                Label("\(salon.name) (\(salon.displayLocation))", systemImage: "mappin")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onReselectStylist) {
                Text("重選設計師")
                    .font(.caption.weight(.black))
                    .foregroundStyle(HMTheme.ink)
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .background(HMTheme.soft.opacity(0.58), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(HMTheme.ink, lineWidth: 1.05))
    }

    private var serviceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BookingStepTitle(number: "第一步", title: "選擇預訂之沙龍項目", trailing: "免押預付")

            VStack(spacing: 10) {
                ForEach(stylist.services) { item in
                    BookingServiceOption(
                        service: item,
                        isSelected: item.id == selectedService.id,
                        onSelect: { onSelectService(item) }
                    )
                }
            }
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BookingStepTitle(
                number: "第二步",
                title: "選擇服務日期",
                trailing: showMonthGrid ? "收起月曆" : "展開完整日曆",
                systemImage: "calendar"
            ) {
                showMonthGrid.toggle()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BookingDate.quickDays(), id: \.self) { date in
                        BookingDateCell(
                            date: date,
                            isSelected: DateFormatter.hmDate.string(from: date) == DateFormatter.hmDate.string(from: selectedDate),
                            isFull: isDateFull(date),
                            onSelect: { onSelectDate(date) }
                        )
                    }
                }
                .padding(.horizontal, 1)
            }

            if showMonthGrid {
                BookingMonthGrid(
                    selectedDate: selectedDate,
                    isDateFull: isDateFull,
                    onSelectDate: onSelectDate
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                BookingStepTitle(number: "第三步", title: "選擇預約時段", systemImage: "clock")
                Spacer()
                Text("目前選擇：\(selectedTime)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                ForEach(BookingDate.slotGroups) { group in
                    BookingTimeSlotGroupView(
                        group: group,
                        selectedTime: selectedTime,
                        isFull: isSlotFull,
                        isNearlyFull: isSlotNearlyFull,
                        onSelect: onSelectTime
                    )
                }
            }
        }
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BookingStepTitle(number: "第四步", title: "填寫預約客戶聯絡資料", systemImage: "person")

            VStack(spacing: 14) {
                BookingFormField(
                    title: "客戶姓名（預約人全名）",
                    placeholder: "例如：Kelvin Fung",
                    systemImage: "person",
                    text: $clientName
                )
                BookingFormField(
                    title: "聯絡電話（自動配信用於簡訊認證）",
                    placeholder: "+852 6123 4567",
                    systemImage: "phone",
                    keyboard: .phonePad,
                    text: $clientPhone
                )
            }
            .padding(16)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(HMTheme.ink, lineWidth: 1.05))

            if !hasValidContact {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption.weight(.black))
                    Text("請先填寫預約人姓名及有效聯絡電話，才可以確認預約。")
                        .font(.caption.weight(.bold))
                        .lineSpacing(2)
                }
                .foregroundStyle(Color(red: 0.58, green: 0.37, blue: 0.05))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 1.0, green: 0.972, blue: 0.86), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(HMTheme.amber.opacity(0.55), lineWidth: 1))
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.black))
                    .foregroundStyle(HMTheme.emerald)
                Text("到店付款與安全交易承諾\n本平台不預先收取任何取消費用，費用一律於到店完成沙龍體驗後直接支付。")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HMTheme.ink.opacity(0.75))
                    .lineSpacing(2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HMTheme.emerald.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(HMTheme.emerald.opacity(0.5), lineWidth: 1))
        }
    }
}

private struct BookingStepTitle: View {
    let number: String
    let title: String
    var trailing: String?
    var systemImage: String = "lightbulb"
    var action: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.black))
                .foregroundStyle(HMTheme.amber)
            Text("\(number)： \(title)")
                .font(.subheadline.weight(.black))
                .foregroundStyle(HMTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
            Spacer(minLength: 8)
            if let trailing {
                Button(action: { action?() }) {
                    Text(trailing)
                        .font(.caption.weight(.black))
                        .foregroundStyle(HMTheme.amber)
                        .padding(.horizontal, 10)
                        .frame(height: 30)
                        .background(Color(red: 1, green: 0.96, blue: 0.82), in: Capsule())
                        .overlay(Capsule().stroke(HMTheme.amber.opacity(0.45), lineWidth: 1))
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }
}

private struct BookingServiceOption: View {
    let service: ServiceItem
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 6) {
                        Text(service.name)
                            .font(.subheadline.weight(.black))
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        Text("\(service.duration) 分鐘")
                            .font(.caption2.monospacedDigit().weight(.black))
                            .foregroundStyle(isSelected ? HMTheme.ink : .secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(HMTheme.amber, in: Capsule())
                    }
                    Text("\(service.description)・\(service.duration) 分鐘")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isSelected ? .white.opacity(0.68) : .secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text("HK$  \(service.price)")
                    .font(.caption.monospacedDigit().weight(.black))
                    .foregroundStyle(isSelected ? HMTheme.amber : HMTheme.ink)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(isSelected ? HMTheme.ink : Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .foregroundStyle(isSelected ? .white : HMTheme.ink)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(HMTheme.ink, lineWidth: isSelected ? 0 : 1))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct BookingDateCell: View {
    let date: Date
    let isSelected: Bool
    let isFull: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 5) {
                Text(BookingDate.weekdayText(date))
                    .font(.caption2.weight(.black))
                Text("\(Calendar.hairmap.component(.day, from: date))")
                    .font(.title3.monospacedDigit().weight(.black))
                Text(isFull ? "約滿" : "\(Calendar.hairmap.component(.month, from: date))月")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isSelected ? .white.opacity(0.72) : (isFull ? .red.opacity(0.7) : .secondary))
            }
            .frame(width: 58, height: 74)
            .background(isSelected ? HMTheme.ink : (isFull ? HMTheme.soft.opacity(0.68) : Color.white), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .foregroundStyle(isSelected ? .white : (isFull ? .secondary : HMTheme.ink))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(HMTheme.ink.opacity(isSelected ? 0 : 0.86), lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isFull)
    }
}

private struct BookingMonthGrid: View {
    let selectedDate: Date
    let isDateFull: (Date) -> Bool
    let onSelectDate: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(BookingDate.monthTitle(selectedDate))
                    .font(.caption.weight(.black))
                    .foregroundStyle(HMTheme.ink)
                Spacer()
                Text("雙向同步")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(HMTheme.amber)
            }

            HStack(spacing: 6) {
                ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { day in
                    Text(day)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(BookingDate.monthDays(for: selectedDate).enumerated()), id: \.offset) { _, item in
                    if let date = item {
                        let selected = DateFormatter.hmDate.string(from: date) == DateFormatter.hmDate.string(from: selectedDate)
                        let full = isDateFull(date)
                        Button {
                            onSelectDate(date)
                        } label: {
                            VStack(spacing: 2) {
                                Text("\(Calendar.hairmap.component(.day, from: date))")
                                    .font(.caption.monospacedDigit().weight(.black))
                                Circle()
                                    .fill(full ? .red.opacity(0.6) : HMTheme.emerald.opacity(0.75))
                                    .frame(width: 4, height: 4)
                            }
                            .frame(height: 42)
                            .frame(maxWidth: .infinity)
                            .background(selected ? HMTheme.ink : Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .foregroundStyle(selected ? .white : (full ? .secondary : HMTheme.ink))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.08), lineWidth: 1))
                        }
                        .buttonStyle(PressableButtonStyle())
                        .disabled(full)
                    } else {
                        Color.clear.frame(height: 42)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(HMTheme.ink.opacity(0.85), lineWidth: 1))
    }
}

private struct BookingTimeSlotGroupView: View {
    let group: BookingSlotGroup
    let selectedTime: String
    let isFull: (String) -> Bool
    let isNearlyFull: (String) -> Bool
    let onSelect: (String) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: group.icon)
                    .font(.caption.weight(.black))
                    .foregroundStyle(HMTheme.amber)
                Text("\(group.title) (\(group.range))")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(group.times, id: \.self) { time in
                    BookingTimeButton(
                        time: time,
                        isSelected: selectedTime == time,
                        isFull: isFull(time),
                        isNearlyFull: isNearlyFull(time),
                        onSelect: { onSelect(time) }
                    )
                }
            }
        }
    }
}

private struct BookingTimeButton: View {
    let time: String
    let isSelected: Bool
    let isFull: Bool
    let isNearlyFull: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                Text(time)
                    .font(.callout.monospacedDigit().weight(.black))
                if isFull {
                    Text("已約滿")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.secondary.opacity(0.8))
                } else if isNearlyFull {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(.red)
                            .frame(width: 5, height: 5)
                        Text("快約滿")
                            .font(.caption2.weight(.black))
                    }
                    .foregroundStyle(HMTheme.amber)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .foregroundStyle(foreground)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(stroke, lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isFull)
    }

    private var background: Color {
        if isSelected { return HMTheme.ink }
        if isFull { return HMTheme.soft.opacity(0.5) }
        return Color.white
    }

    private var foreground: Color {
        if isSelected { return .white }
        if isFull { return .secondary.opacity(0.55) }
        return HMTheme.ink
    }

    private var stroke: Color {
        if isSelected { return HMTheme.ink }
        if isFull { return .clear }
        return HMTheme.ink.opacity(0.85)
    }
}

private struct BookingFormField: View {
    let title: String
    let placeholder: String
    let systemImage: String
    var keyboard: UIKeyboardType = .default
    var footer: String?
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                TextField(placeholder, text: $text)
                    .font(.callout.weight(.semibold))
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 12)
            .frame(height: 50)
            .background(Color(red: 0.985, green: 0.985, blue: 0.98), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(HMTheme.ink, lineWidth: 1.05))

            if let footer {
                Text(footer)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(HMTheme.emerald)
            }
        }
    }
}

private struct BookingStickySummary: View {
    let stylist: Stylist
    let service: ServiceItem
    let date: Date
    let time: String
    let isSubmitting: Bool
    let canSubmit: Bool
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("預約服務 / 設計師")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.secondary)
                    Text("\(service.name) (\(stylist.name))")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(HMTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("預約時間")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.secondary)
                    Text("\(BookingDate.displayDateText(date))  \(time)")
                        .font(.caption.monospacedDigit().weight(.black))
                        .foregroundStyle(.brown)
                }
            }

            HStack {
                Text("應付金額（到店直接結帳）")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("HK$  \(service.price)")
                    .font(.subheadline.monospacedDigit().weight(.black))
                    .foregroundStyle(HMTheme.ink)
            }
            .padding(12)
            .background(Color(red: 0.99, green: 0.99, blue: 0.985), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            Button(action: onSubmit) {
                HStack {
                    Spacer()
                    Text(isSubmitting ? "確認中..." : (canSubmit ? "立即預約確認時間" : "請先填寫聯絡資料"))
                        .font(.callout.weight(.black))
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.black))
                    Spacer()
                }
                .foregroundStyle(HMTheme.ink)
                .frame(height: 52)
                .background(canSubmit ? HMTheme.amber : Color.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .shadow(color: (canSubmit ? HMTheme.amber.opacity(0.28) : .clear), radius: 10, y: 5)
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(isSubmitting || !canSubmit)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(Color.white)
        .overlay(alignment: .top) { Rectangle().fill(.black.opacity(0.08)).frame(height: 1) }
    }
}

private struct BookingSuccessOverlay: View {
    let booking: Appointment
    let contentWidth: CGFloat
    let didSendProgress: Bool
    let onSendProgress: () -> Void
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.54)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.78, green: 1, blue: 0.91))
                        .frame(width: 62, height: 62)
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(HMTheme.emerald)
                }

                VStack(spacing: 8) {
                    Text("預約成功！髮型師會收到通知")
                        .font(.headline.weight(.black))
                        .foregroundStyle(HMTheme.ink)
                        .multilineTextAlignment(.center)
                    Text("已將預約資訊提交至系統並同步至髮型師管理後台。")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }

                VStack(alignment: .leading, spacing: 9) {
                    Text("👩‍🎨 髮型師： \(booking.stylistName)")
                    Text("✂️ 服務項目： \(booking.serviceName)")
                    Text("🗓 預約日期： \(booking.bookingDate)")
                    Text("⏱ 預定時段： \(booking.timeSlot)")
                    Text("💰 到店付款： HK$ \(booking.price)")
                        .font(.callout.monospacedDigit().weight(.black))
                        .foregroundStyle(HMTheme.emerald)
                }
                .font(.callout.weight(.semibold))
                .foregroundStyle(HMTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(red: 0.985, green: 0.985, blue: 0.98), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                Button(action: onSendProgress) {
                    HStack {
                        Image(systemName: didSendProgress ? "checkmark.circle.fill" : "paperplane.fill")
                        Text(didSendProgress ? "已發送到一對一設計師後台" : "發送進度到一對一設計師後台")
                    }
                    .font(.caption.weight(.black))
                    .foregroundStyle(didSendProgress ? HMTheme.emerald : HMTheme.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.1), lineWidth: 1))
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(didSendProgress)

                Button(action: onDone) {
                    Text("確定")
                        .font(.callout.weight(.black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(HMTheme.ink, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(22)
            .frame(width: min(contentWidth - 64, 330))
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 28, y: 16)
        }
        .preferredColorScheme(.light)
    }
}

struct ChatView: View {
    @Environment(HairmapStore.self) private var store
    @State private var stage: ConsultationStage = .inbox
    @State private var selectedStylistID = "master-leo"
    @State private var draft = ""
    @State private var reportDraft: ReportDraft?

    private var thread: [ChatMessageItem] {
        store.customerMessages
            .filter { $0.stylistID == selectedStylistID }
            .sorted { $0.sortKey < $1.sortKey }
    }

    private var conversationStylists: [Stylist] {
        let contactedIDs = Set(store.customerMessages.map(\.stylistID))
        return store.stylists.filter { contactedIDs.contains($0.id) }.sorted {
            (lastMessage(for: $0.id)?.sortKey ?? 0) > (lastMessage(for: $1.id)?.sortKey ?? 0)
        }
    }

    private var unreadStylistIDs: Set<String> {
        store.customerUnreadStylistIDs()
    }

    private var selectedStylist: Stylist {
        store.stylist(id: selectedStylistID)
    }

    private var selectedSalon: Salon {
        store.salon(id: selectedStylist.salonID)
    }

    private var isBlocked: Bool {
        store.isChatBlocked(stylistID: selectedStylistID)
    }

    var body: some View {
        GeometryReader { proxy in
            let contentWidth = min(proxy.size.width, 430)
            ZStack {
                Color(red: 0.985, green: 0.985, blue: 0.98)
                    .ignoresSafeArea()

                switch stage {
                case .inbox:
                    ConsultationInboxPage(
                        contentWidth: contentWidth,
                        stylists: conversationStylists,
                        salons: store.salons,
                        unreadStylistIDs: unreadStylistIDs,
                        lastMessage: lastMessage(for:),
                        onBack: { store.selectedTab = .discovery },
                        onSelect: openThread
                    )
                case .chat:
                    OneOnOneChatPage(
                        contentWidth: contentWidth,
                        stylists: conversationStylists,
                        selectedStylistID: selectedStylistID,
                        stylist: selectedStylist,
                        salon: selectedSalon,
                        messages: thread,
                        draft: $draft,
                        isBlocked: isBlocked,
                        onBack: { stage = .inbox },
                        onSelectStylist: openThread,
                        onSend: sendDraft,
                        onPickPhoto: sendPhoto,
                        onRecall: recallMessage,
                        onReport: reportMessage,
                        onToggleBlock: toggleBlock
                    )
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            selectedStylistID = store.selectedStylistID
        }
        .animation(.snappy(duration: 0.28), value: stage)
        .animation(.snappy(duration: 0.24), value: unreadStylistIDs)
        .premiumBackground()
        .sheet(item: $reportDraft) { draft in
            ReportSheet(draft: draft) { reason, details in
                store.submitReport(entityType: draft.entityType, entityID: draft.entityID, reason: reason, details: details)
            }
        }
    }

    private func lastMessage(for stylistID: String) -> ChatMessageItem? {
        store.customerMessages
            .filter { $0.stylistID == stylistID }
            .max { $0.sortKey < $1.sortKey }
    }

    private func openThread(_ stylistID: String) {
        selectedStylistID = stylistID
        store.selectedStylistID = stylistID
        store.markCustomerThreadRead(stylistID: stylistID)
        stage = .chat
    }

    private func sendDraft() {
        guard !isBlocked else { return }
        let sending = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sending.isEmpty else { return }
        draft = ""
        Task { await store.sendMessage(text: sending, stylistID: selectedStylistID) }
    }

    private func sendPhoto(_ item: PhotosPickerItem?) {
        guard !isBlocked, let item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                await MainActor.run {
                    store.statusMessage = "未能讀取照片，請重新選擇"
                }
                return
            }
            await store.sendChatPhoto(data: data, stylistID: selectedStylistID)
        }
    }

    private func recallMessage(_ message: ChatMessageItem) {
        guard message.senderRole == .customer else { return }
        store.recallMessage(id: message.id)
    }

    private func reportMessage(_ message: ChatMessageItem) {
        reportDraft = ReportDraft(
            entityType: .message,
            entityID: message.id,
            title: "檢舉聊天室訊息",
            subtitle: message.text
        )
    }

    private func toggleBlock() {
        store.toggleChatBlock(stylistID: selectedStylistID)
    }
}

private enum ConsultationStage: Hashable {
    case inbox
    case chat
}

private struct ConsultationInboxPage: View {
    let contentWidth: CGFloat
    let stylists: [Stylist]
    let salons: [Salon]
    let unreadStylistIDs: Set<String>
    let lastMessage: (String) -> ChatMessageItem?
    let onBack: () -> Void
    let onSelect: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(HMTheme.ink)
                        .frame(width: 44, height: 44)
                        .background(Color.white, in: Circle())
                }
                .buttonStyle(PressableButtonStyle())

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(HMTheme.amber)
                    Text("髮型師諮詢對話盒 (INBOX)")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(HMTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .frame(maxWidth: 270)
                .multilineTextAlignment(.center)

                Spacer()

                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 16)
            .frame(height: 70)
            .background(Color.white.ignoresSafeArea(edges: .top))
            .overlay(alignment: .bottom) { Rectangle().fill(.black).frame(height: 1) }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("聯絡與行程諮詢對話")
                                .font(.subheadline.weight(.black))
                                .foregroundStyle(HMTheme.ink)
                            Spacer()
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(HMTheme.ink)
                                    .frame(width: 7, height: 7)
                                Text("點對話已加密")
                                    .font(.caption2.weight(.black))
                            }
                            .padding(.horizontal, 10)
                            .frame(height: 24)
                            .background(Color.white, in: Capsule())
                            .overlay(Capsule().stroke(HMTheme.ink, lineWidth: 1))
                        }

                        Text("您在此處可以與為您服務過的設計師安全、即時在線聊天，無需跳轉 WhatsApp、LINE 或其他軟體。")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 14) {
                        ForEach(stylists) { stylist in
                            ConsultationThreadCard(
                                stylist: stylist,
                                salon: salons.first { $0.id == stylist.salonID },
                                message: lastMessage(stylist.id),
                                isUnread: unreadStylistIDs.contains(stylist.id),
                                onTap: { onSelect(stylist.id) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 92)
                .frame(width: contentWidth)
            }
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Label("全程對講均支持 AES-256 水分子加密傳輸", systemImage: "lock.fill")
                .font(.caption.weight(.black))
                .foregroundStyle(HMTheme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.white)
                .overlay(alignment: .top) { Rectangle().fill(.black.opacity(0.08)).frame(height: 1) }
        }
    }
}

private struct ConsultationThreadCard: View {
    let stylist: Stylist
    let salon: Salon?
    let message: ChatMessageItem?
    let isUnread: Bool
    let onTap: () -> Void
    @State private var glow = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 13) {
                RemoteImage(urlString: stylist.avatarURL, height: 58, cornerRadius: 29)
                    .frame(width: 58)
                    .clipShape(Circle())
                    .overlay(alignment: .bottomTrailing) {
                        Circle()
                            .fill(HMTheme.emerald)
                            .frame(width: 11, height: 11)
                            .overlay(Circle().stroke(.white, lineWidth: 1.6))
                    }

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline, spacing: 7) {
                        Text(stylist.name)
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(HMTheme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .fixedSize(horizontal: true, vertical: false)
                            .layoutPriority(2)
                        Text(stylist.title)
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.56)
                    }

                    Text(message?.displayText ?? "尚未開始對話，點擊立即諮詢。")
                        .font(.system(size: 13, weight: isUnread ? .black : .semibold))
                        .foregroundStyle(HMTheme.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        ForEach(stylist.specialties.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.965, green: 0.965, blue: 0.965), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                        }
                    }
                }

                Spacer(minLength: 6)

                VStack(alignment: .trailing, spacing: 18) {
                    HStack(spacing: 7) {
                        Text(message?.displayTime ?? "剛剛")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.secondary)
                        if isUnread {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.24))
                                    .frame(width: 20, height: 20)
                                    .scaleEffect(glow ? 1.22 : 0.78)
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 9, height: 9)
                            }
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true)) {
                                    glow.toggle()
                                }
                            }
                        }
                    }

                    Text(isUnread ? "未讀 ⌁" : "已讀 ✓✓")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(isUnread ? HMTheme.ink : .secondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 118)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(HMTheme.ink, lineWidth: 1.05))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("開啟 \(stylist.name) 一對一對話")
    }
}

private struct OneOnOneChatPage: View {
    @Environment(\.openURL) private var openURL
    let contentWidth: CGFloat
    let stylists: [Stylist]
    let selectedStylistID: String
    let stylist: Stylist
    let salon: Salon
    let messages: [ChatMessageItem]
    @Binding var draft: String
    let isBlocked: Bool
    let onBack: () -> Void
    let onSelectStylist: (String) -> Void
    let onSend: () -> Void
    let onPickPhoto: (PhotosPickerItem?) -> Void
    let onRecall: (ChatMessageItem) -> Void
    let onReport: (ChatMessageItem) -> Void
    let onToggleBlock: () -> Void

    private var threadSignature: String {
        messages.map { "\($0.id):\($0.text):\($0.createdAt ?? "")" }.joined(separator: "|")
    }

    var body: some View {
        VStack(spacing: 0) {
            chatSwitcher
            chatHeader

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        securityBadge

                        ForEach(messages) { message in
                            ImmersiveMessageBubble(
                                message: message,
                                stylist: stylist,
                                contentWidth: contentWidth,
                                onRecall: { onRecall(message) },
                                onReport: { onReport(message) }
                            )
                            .id(message.id)
                        }

                        stylistHintBox
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 112)
                    .frame(width: contentWidth)
                }
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.985, green: 0.985, blue: 0.98))
                .onAppear {
                    scrollToBottom(proxy)
                }
                .onChange(of: threadSignature) {
                    scrollToBottom(proxy)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ChatInputBar(
                draft: $draft,
                isBlocked: isBlocked,
                onPickPhoto: onPickPhoto,
                onSend: onSend
            )
        }
    }

    private var chatSwitcher: some View {
        HStack(spacing: 10) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(HMTheme.ink)
                    .frame(width: 42, height: 42)
                    .background(Color.white, in: Circle())
            }
            .buttonStyle(PressableButtonStyle())

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(stylists) { item in
                        Button {
                            onSelectStylist(item.id)
                        } label: {
                            HStack(spacing: 7) {
                                RemoteImage(urlString: item.avatarURL, height: 24, cornerRadius: 12)
                                    .frame(width: 24)
                                    .clipShape(Circle())
                                Text(item.name)
                                    .font(.caption.weight(.black))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(item.id == selectedStylistID ? .white : HMTheme.ink)
                            .padding(.horizontal, 12)
                            .frame(height: 42)
                            .background(item.id == selectedStylistID ? HMTheme.ink : Color.white, in: Capsule())
                            .overlay(Capsule().stroke(HMTheme.ink.opacity(0.9), lineWidth: 1))
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.trailing, 8)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color.white.ignoresSafeArea(edges: .top))
        .overlay(alignment: .bottom) { Rectangle().fill(.black).frame(height: 1) }
    }

    private var chatHeader: some View {
        HStack(spacing: 12) {
            RemoteImage(urlString: stylist.avatarURL, height: 54, cornerRadius: 27)
                .frame(width: 54)
                .clipShape(Circle())
                .overlay(alignment: .bottomTrailing) {
                    Circle()
                        .fill(isBlocked ? .gray : HMTheme.emerald)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(.white, lineWidth: 1.8))
                }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text(stylist.name)
                        .font(.headline.weight(.black))
                        .foregroundStyle(HMTheme.ink)
                    Text("PRO")
                        .font(.caption2.monospacedDigit().weight(.black))
                        .foregroundStyle(HMTheme.ink)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(HMTheme.amber, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                }

                HStack(spacing: 5) {
                    Circle()
                        .fill(isBlocked ? .gray : .green)
                        .frame(width: 9, height: 9)
                    Text(isBlocked ? "已封鎖 · 唯讀模式" : "在線 · \(stylist.experience)專業設計師")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button(action: callStylist) {
                Image(systemName: "phone")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(HMTheme.ink)
                    .frame(width: 40, height: 40)
                    .background(Color.white, in: Circle())
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(stylist.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(stylist.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.35 : 1)

            Menu {
                Button(isBlocked ? "解除封鎖" : "封鎖此髮型師", role: isBlocked ? nil : .destructive) {
                    onToggleBlock()
                }
                Button("檢視 \(salon.name)") {}
                Button("清除未讀提示") {}
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(HMTheme.ink)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal, 18)
        .frame(height: 82)
        .background(Color.white)
        .overlay(alignment: .bottom) { Rectangle().fill(.black.opacity(0.06)).frame(height: 1) }
    }

    private var securityBadge: some View {
        HStack(spacing: 7) {
            Image(systemName: "shield.lefthalf.filled")
                .foregroundStyle(.red.opacity(0.82))
            Text(isBlocked ? "聊天室已封鎖，訊息只可檢視不可發送" : "點對點超高安全私密通道保障中")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .frame(height: 28)
        .background(Color.white.opacity(0.7), in: Capsule())
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var stylistHintBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("髮型師諮詢提示 Box", systemImage: "info.circle")
                .font(.caption.weight(.black))
                .foregroundStyle(Color(red: 0.55, green: 0.36, blue: 0.1))
            Text("點擊下方的「+」圖案，可直接分享精簡的髮型照片、分享已有行程的「預約明細卡片」或索取專業折扣報價「報價單」。")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 1, green: 0.985, blue: 0.9), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(HMTheme.amber.opacity(0.35), lineWidth: 1))
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let last = messages.last else { return }
        DispatchQueue.main.async {
            withAnimation(.snappy(duration: 0.24)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
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
}

private struct ImmersiveMessageBubble: View {
    let message: ChatMessageItem
    let stylist: Stylist
    let contentWidth: CGFloat
    let onRecall: () -> Void
    let onReport: () -> Void

    private var isMe: Bool { message.senderRole == .customer }
    private var isRecalled: Bool { message.text.hasPrefix("⚠️") }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if isMe {
                Spacer(minLength: max(contentWidth * 0.18, 56))
            } else {
                RemoteImage(urlString: stylist.avatarURL, height: 34, cornerRadius: 17)
                    .frame(width: 34)
                    .clipShape(Circle())
            }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 7) {
                messageContent
                    .contextMenu {
                        if isMe && !isRecalled {
                            Button(role: .destructive) {
                                onRecall()
                            } label: {
                                Label("撒回 (Recall)", systemImage: "arrow.uturn.backward.circle")
                            }
                        }
                        Button(role: .destructive) {
                            onReport()
                        } label: {
                            Label("檢舉訊息", systemImage: "exclamationmark.bubble")
                        }
                    }

                Text(message.displayTime)
                    .font(.caption2.monospacedDigit().weight(.medium))
                    .foregroundStyle(.secondary)
            }

            if !isMe {
                Spacer(minLength: max(contentWidth * 0.18, 56))
            }
        }
        .frame(maxWidth: .infinity, alignment: isMe ? .trailing : .leading)
    }

    @ViewBuilder
    private var messageContent: some View {
        if let photoURL = message.photoURL {
            RemoteImage(urlString: photoURL, height: 188, cornerRadius: 14)
                .frame(width: min(contentWidth * 0.72, 260))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(strokeColor, lineWidth: isMe ? 0 : 1))
        } else {
            Text(message.displayText)
                .font(.callout.weight(isMe ? .bold : .medium))
                .lineSpacing(4)
                .foregroundStyle(textColor)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: contentWidth * 0.72, alignment: isMe ? .trailing : .leading)
                .background(bubbleBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(strokeColor, lineWidth: isMe ? 0 : 1))
        }
    }

    private var textColor: Color {
        if isRecalled { return .secondary }
        return isMe ? .white : HMTheme.ink
    }

    private var bubbleBackground: Color {
        if isRecalled { return HMTheme.soft.opacity(0.68) }
        return isMe ? HMTheme.ink : Color.white
    }

    private var strokeColor: Color {
        isRecalled ? .black.opacity(0.06) : .black.opacity(0.04)
    }
}

private struct ChatInputBar: View {
    @Binding var draft: String
    let isBlocked: Bool
    let onPickPhoto: (PhotosPickerItem?) -> Void
    let onSend: () -> Void
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        HStack(spacing: 10) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Image(systemName: isBlocked ? "lock.fill" : "camera")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(isBlocked ? .secondary : HMTheme.ink)
                    .frame(width: 52, height: 52)
                    .background(Color(red: 1, green: 0.965, blue: 0.78), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(isBlocked)

            TextField(isBlocked ? "已封鎖此對話，無法發送新言論" : "發送對話訊息或輸入關鍵字「價/髮/漂…」", text: $draft, axis: .vertical)
                .lineLimit(1...3)
                .font(.callout.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white, in: Capsule())
                .overlay(Capsule().stroke(.black.opacity(0.08), lineWidth: 1))
                .disabled(isBlocked)

            Button(action: onSend) {
                Image(systemName: isBlocked ? "lock.fill" : "paperplane.fill")
                    .font(.system(size: 19, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(isBlocked ? .gray : .black, in: Circle())
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(isBlocked || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(alignment: .top) { Rectangle().fill(.black.opacity(0.08)).frame(height: 1) }
        .onChange(of: selectedPhotoItem) { _, item in
            onPickPhoto(item)
            selectedPhotoItem = nil
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessageItem

    private var isMe: Bool { message.senderRole == .customer }

    var body: some View {
        HStack {
            if isMe { Spacer(minLength: 44) }
            VStack(alignment: isMe ? .trailing : .leading, spacing: 5) {
                Text(message.senderName)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                if let photoURL = message.photoURL {
                    RemoteImage(urlString: photoURL, height: 160, cornerRadius: 8)
                        .frame(width: 220)
                } else {
                    Text(message.displayText)
                        .font(.callout)
                        .foregroundStyle(isMe ? .white : HMTheme.ink)
                        .padding(12)
                        .background(isMe ? HMTheme.ink : Color.white, in: RoundedRectangle(cornerRadius: 8))
                }
                Text(message.displayTime)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            if !isMe { Spacer(minLength: 44) }
        }
    }
}

struct UserProfileView: View {
    @Environment(HairmapStore.self) private var store
    @State private var panel: ProfilePanel = .account
    @State private var bookingScope: ProfileBookingScope = .active
    @State private var submissionNotice: ProfileSubmissionNotice?

    @State private var stylistName = ""
    @State private var stylistTitle = ""
    @State private var stylistPhone = ""
    @State private var stylistBio = ""
    @State private var stylistExperience = "5年資歷"
    @State private var stylistLanguages = "中 / 粵 / 英"
    @State private var stylistDistrict = "尖沙咀"
    @State private var stylistAddress = ""
    @State private var stylistInstagramURL = ""
    @State private var stylistTags: Set<String> = ["挑染專家", "經典剪髮", "歐美挑染"]
    @State private var selectedAvatarURL = ProfileSeed.avatarChoices[0].url
    @State private var customAvatarURL = ""
    @State private var stylistServiceDrafts = ProfileSeed.stylistServices
    @State private var extraServiceName = ""
    @State private var extraServiceCategory = "剪髮"
    @State private var extraServiceDescription = ""
    @State private var extraServicePrice = ""
    @State private var customStylistWorkName = ""
    @State private var customStylistWorkURL = ""
    @State private var uploadedStylistWorkURLs: [String] = []
    @State private var selectedStylistSamples: Set<String> = []

    @State private var salonName = ""
    @State private var salonDistrict = "尖沙咀"
    @State private var salonAddress = ""
    @State private var salonInstagramURL = ""
    @State private var salonPhone = "+852 2345 6789"
    @State private var salonHours = "11:00 - 20:00"
    @State private var salonStartPrice = "480"
    @State private var salonTags: Set<String> = ["歐美染髮", "手刷染", "韓式燙髮"]
    @State private var salonFeatureDrafts = ProfileSeed.salonFeatures
    @State private var assignedStylistIDs: Set<String> = []
    @State private var customSalonWorkName = ""
    @State private var customSalonWorkURL = ""
    @State private var uploadedSalonWorkURLs: [String] = []
    @State private var selectedSalonSamples: Set<String> = []
    @State private var salonPackageName = ""
    @State private var salonPackagePrice = ""
    @State private var salonPackages = ProfileSeed.salonPackages
    @State private var selectedCoverURL = ProfileSeed.coverChoices[0].url
    @State private var customCoverURL = ""

    private var shownBookings: [Appointment] {
        switch bookingScope {
        case .active:
            activeBookings
        case .history:
            historyBookings
        }
    }

    private var activeBookings: [Appointment] {
        store.customerBookings.filter { $0.status != .completed && $0.status != .cancelled }
    }

    private var historyBookings: [Appointment] {
        store.customerBookings.filter { $0.status == .completed || $0.status == .cancelled }
    }

    var body: some View {
        GeometryReader { proxy in
            let contentWidth = min(proxy.size.width, 430)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    ProfileHeader {
                        Task { await store.logout() }
                    }

                    ProfilePanelTabs(selected: $panel, isAdmin: store.isAdmin)

                    Group {
                        switch panel {
                        case .account:
                            CustomerProfilePanel()
                        case .bookings:
                            ProfileBookingsPanel(
                                scope: $bookingScope,
                                bookings: shownBookings,
                                activeCount: activeBookings.count,
                                historyCount: historyBookings.count
                            )
                        case .stylist:
                            ProfileStylistCreatePanel(
                                name: $stylistName,
                                title: $stylistTitle,
                                phone: $stylistPhone,
                                bio: $stylistBio,
                                district: $stylistDistrict,
                                address: $stylistAddress,
                                instagramURL: $stylistInstagramURL,
                                experience: $stylistExperience,
                                languages: $stylistLanguages,
                                services: $stylistServiceDrafts,
                                extraServiceName: $extraServiceName,
                                extraServiceCategory: $extraServiceCategory,
                                extraServiceDescription: $extraServiceDescription,
                                extraServicePrice: $extraServicePrice,
                                selectedTags: $stylistTags,
                                selectedAvatarURL: $selectedAvatarURL,
                                customAvatarURL: $customAvatarURL,
                                selectedSamples: $selectedStylistSamples,
                                customWorkName: $customStylistWorkName,
                                customWorkURL: $customStylistWorkURL,
                                uploadedWorkURLs: $uploadedStylistWorkURLs,
                                onAddExtraService: addStylistExtraService,
                                onCreate: createStylistProfile
                            )
                        case .salon:
                            ProfileSalonCreatePanel(
                                name: $salonName,
                                district: $salonDistrict,
                                address: $salonAddress,
                                instagramURL: $salonInstagramURL,
                                phone: $salonPhone,
                                hours: $salonHours,
                                startPrice: $salonStartPrice,
                                selectedTags: $salonTags,
                                features: $salonFeatureDrafts,
                                stylists: store.stylists,
                                assignedStylistIDs: $assignedStylistIDs,
                                selectedSamples: $selectedSalonSamples,
                                customWorkName: $customSalonWorkName,
                                customWorkURL: $customSalonWorkURL,
                                uploadedWorkURLs: $uploadedSalonWorkURLs,
                                packages: $salonPackages,
                                packageName: $salonPackageName,
                                packagePrice: $salonPackagePrice,
                                selectedCoverURL: $selectedCoverURL,
                                customCoverURL: $customCoverURL,
                                onAddPackage: addSalonPackage,
                                onCreate: createSalonProfile
                            )
                        case .admin:
                            ProfileAdminPanel(stylists: store.stylists, salons: store.salons)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 108)
                .frame(width: contentWidth)
            }
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.985, green: 0.985, blue: 0.98).ignoresSafeArea())
        }
        .premiumBackground()
        .alert(item: $submissionNotice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text("知道了"))
            )
        }
    }

    private func addStylistExtraService() {
        let cleanName = extraServiceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        stylistServiceDrafts.append(
            ProfileServiceDraft(
                name: cleanName,
                category: extraServiceCategory,
                detail: extraServiceDescription.isEmpty ? "自訂沙龍服務項目" : extraServiceDescription,
                duration: 90,
                priceText: extraServicePrice.isEmpty ? "680" : extraServicePrice,
                isEnabled: true
            )
        )
        extraServiceName = ""
        extraServiceDescription = ""
        extraServicePrice = ""
    }

    private func addSalonPackage() {
        let cleanName = salonPackageName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        salonPackages.append(
            ProfileSalonPackage(
                title: cleanName,
                priceText: salonPackagePrice.isEmpty ? "880" : salonPackagePrice
            )
        )
        salonPackageName = ""
        salonPackagePrice = ""
    }

    private func createStylistProfile() {
        Task { await createStylistProfileAsync() }
    }

    private func createStylistProfileAsync() async {
        let cleanAddress = stylistAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanAddress.isEmpty else {
            submissionNotice = ProfileSubmissionNotice(
                title: "請補充地址",
                message: "髮型師檔案需要填寫服務地址，客戶才可以在檔案和地區篩選中清楚看到位置。"
            )
            return
        }

        let now = Int(Date().timeIntervalSince1970)
        let stylistID = "new-stylist-\(now)"
        let avatarSource = customAvatarURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? selectedAvatarURL : customAvatarURL
        let avatar = await store.uploadProfileMediaIfNeeded(avatarSource, folder: "profile-avatars")
        let enabledServices = stylistServiceDrafts.filter(\.isEnabled)
        let services = enabledServices.enumerated().map { index, item in
            ServiceItem(
                id: "\(stylistID)-service-\(index)",
                stylistID: stylistID,
                name: item.name,
                category: item.category,
                duration: item.duration,
                description: item.detail,
                price: Int(item.priceText) ?? 680
            )
        }
        let selectedWorks = ProfileSeed.stylistWorks.filter { selectedStylistSamples.contains($0.id) }
        let works = selectedWorks.enumerated().map { index, item in
            PortfolioWork(id: "\(stylistID)-work-\(index)", stylistID: stylistID, title: item.title, imageURL: item.url)
        }
        let customWorkURL = customStylistWorkURL.trimmingCharacters(in: .whitespacesAndNewlines)
        var customWorks = uploadedStylistWorkURLs.enumerated().map { index, url in
            PortfolioWork(
                id: "\(stylistID)-uploaded-work-\(index)",
                stylistID: stylistID,
                title: customStylistWorkName.isEmpty ? "本機上載作品 \(index + 1)" : "\(customStylistWorkName) \(index + 1)",
                imageURL: url
            )
        }
        if !customWorkURL.isEmpty, !uploadedStylistWorkURLs.contains(customWorkURL) {
            customWorks.append(
                PortfolioWork(
                    id: "\(stylistID)-custom-work",
                    stylistID: stylistID,
                    title: customStylistWorkName.isEmpty ? "自訂作品" : customStylistWorkName,
                    imageURL: customWorkURL
                )
            )
        }
        let finalWorks = await store.uploadPortfolioWorksIfNeeded(
            Array((works + customWorks).prefix(10)),
            folder: "stylist-portfolio"
        )

        let stylist = Stylist(
            id: stylistID,
            ownerID: store.currentProfile?.id,
            salonID: store.salons.first?.id ?? "s1",
            district: stylistDistrict,
            location: cleanAddress,
            name: stylistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Leo Master" : stylistName,
            title: stylistTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "首席名店設計師" : stylistTitle,
            rating: 5.0,
            reviewsCount: 0,
            languages: stylistLanguages,
            experience: stylistExperience,
            specialties: Array(stylistTags),
            avatarURL: avatar,
            phone: stylistPhone.trimmingCharacters(in: .whitespacesAndNewlines),
            instagramURL: stylistInstagramURL.trimmingCharacters(in: .whitespacesAndNewlines),
            bio: stylistBio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "擁有多年沙龍經驗，擅長依照個人頭骨與臉型設計專屬層次剪裁。" : stylistBio,
            basePrice: services.first?.price ?? 380,
            works: finalWorks,
            services: services.isEmpty ? SeedData.services.filter { $0.stylistID == "master-leo" } : services,
            reviews: []
        )
        let didSubmitForReview = await store.submitStylistApplication(stylist)
        if didSubmitForReview {
            submissionNotice = ProfileSubmissionNotice(
                title: "提交成功",
                message: "已提交，等待審批。審批通過後會公開到 Hairmap。"
            )
        }
    }

    private func createSalonProfile() {
        Task { await createSalonProfileAsync() }
    }

    private func createSalonProfileAsync() async {
        let cleanAddress = salonAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanAddress.isEmpty else {
            submissionNotice = ProfileSubmissionNotice(
                title: "請補充地址",
                message: "沙龍檔案需要填寫完整地址，客戶才可以在檔案和地區篩選中清楚看到位置。"
            )
            return
        }

        let now = Int(Date().timeIntervalSince1970)
        let salonID = "new-salon-\(now)"
        let cleanCover = customCoverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let coverSource = cleanCover.isEmpty ? selectedCoverURL : cleanCover
        let coverURL = await store.uploadProfileMediaIfNeeded(coverSource, folder: "salon-covers")
        let salon = Salon(
            id: salonID,
            name: salonName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Artisan Space" : salonName,
            location: cleanAddress,
            district: salonDistrict,
            distance: 0.8,
            rating: 5.0,
            tags: Array(salonTags),
            openHours: salonHours,
            phone: salonPhone,
            instagramURL: salonInstagramURL.trimmingCharacters(in: .whitespacesAndNewlines),
            startPrice: Int(salonStartPrice) ?? 480,
            imageURL: coverURL
        )
        let selectedWorks = ProfileSeed.salonWorks.filter { selectedSalonSamples.contains($0.id) }
        var salonPortfolio = selectedWorks.enumerated().map { index, item in
            PortfolioWork(id: "\(salonID)-sample-work-\(index)", stylistID: salonID, title: item.title, imageURL: item.url)
        }
        salonPortfolio += uploadedSalonWorkURLs.enumerated().map { index, url in
            PortfolioWork(
                id: "\(salonID)-uploaded-work-\(index)",
                stylistID: salonID,
                title: customSalonWorkName.isEmpty ? "沙龍本機上載作品 \(index + 1)" : "\(customSalonWorkName) \(index + 1)",
                imageURL: url
            )
        }
        let customWorkURL = customSalonWorkURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !customWorkURL.isEmpty, !uploadedSalonWorkURLs.contains(customWorkURL) {
            salonPortfolio.append(
                PortfolioWork(
                    id: "\(salonID)-custom-work",
                    stylistID: salonID,
                    title: customSalonWorkName.isEmpty ? "沙龍自訂作品" : customSalonWorkName,
                    imageURL: customWorkURL
                )
            )
        }
        salonPortfolio = await store.uploadPortfolioWorksIfNeeded(
            Array(salonPortfolio.prefix(10)),
            folder: "salon-portfolio"
        )
        await store.saveSalon(salon, works: salonPortfolio)
        let selectedStylists = store.stylists.filter { assignedStylistIDs.contains($0.id) }
        for var stylist in selectedStylists {
            stylist.salonID = salonID
            await store.saveStylist(stylist)
        }
        if !selectedStylists.isEmpty {
            await store.refreshCatalog()
        }
        submissionNotice = ProfileSubmissionNotice(
            title: "提交成功",
            message: "沙龍檔案已自動儲存並公開到 Hairmap 顧客端。"
        )
    }
}

private struct ProfileSubmissionNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private enum ProfilePanel: String, CaseIterable, Identifiable {
    case account
    case bookings
    case stylist
    case salon
    case admin

    var id: String { rawValue }

    static func visiblePanels(isAdmin: Bool) -> [ProfilePanel] {
        isAdmin ? [.account, .bookings, .salon, .admin] : [.account, .bookings]
    }

    var title: String {
        switch self {
        case .account: "顧客檔案"
        case .bookings: "我的預約"
        case .stylist: "新增髮型師"
        case .salon: "新增沙龍"
        case .admin: "管理"
        }
    }
}

private enum ProfileBookingScope: String {
    case active
    case history
}

private struct ProfileHeader: View {
    let onLogout: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Text("Hairmap")
                .font(.system(size: 28, weight: .black, design: .serif))
                .foregroundStyle(HMTheme.ink)
                .lineLimit(1)

            Spacer()

            Button(action: onLogout) {
                Text("登出")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(HMTheme.ink)
                    .padding(.horizontal, 16)
                    .frame(height: 34)
                    .background(Color.white, in: Capsule())
                    .overlay(Capsule().stroke(.black.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.top, 6)
        .padding(.bottom, 12)
    }
}

private struct ProfilePanelTabs: View {
    @Binding var selected: ProfilePanel
    let isAdmin: Bool

    var body: some View {
        HStack(spacing: 4) {
            ForEach(ProfilePanel.visiblePanels(isAdmin: isAdmin)) { panel in
                Button {
                    selected = panel
                } label: {
                    Text(panel.title)
                        .font(.caption.weight(.black))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .foregroundStyle(selected == panel ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(selected == panel ? Color.black : .clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(5)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.black.opacity(0.08), lineWidth: 1))
    }
}

private struct CustomerProfilePanel: View {
    @Environment(HairmapStore.self) private var store
    @State private var nickname = ""
    @State private var pickedAvatarItem: PhotosPickerItem?
    @State private var avatarData: Data?
    @State private var isSaving = false
    @State private var isDeleteAlertPresented = false
    @State private var isDeletingAccount = false

    private var emailText: String {
        let email = store.currentProfile?.email.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return email.isEmpty ? "訪客體驗" : email
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ProfileFormIntro(
                title: "顧客檔案資料",
                subtitle: "設定暱稱與頭像後，發表髮型師/沙龍評論、靈感留言及上傳靈感卡片時會自動代入。"
            )

            ProfileBox {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 14) {
                        ProfileUploadedImage(
                            data: avatarData,
                            fallbackURL: store.commentAvatarURL,
                            height: 76,
                            cornerRadius: 38
                        )
                        .frame(width: 76, height: 76)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.black.opacity(0.12), lineWidth: 1))

                        VStack(alignment: .leading, spacing: 8) {
                            Text(store.commentDisplayName)
                                .font(.headline.weight(.black))
                                .foregroundStyle(HMTheme.ink)
                                .lineLimit(1)
                            Text(emailText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            PhotosPicker(selection: $pickedAvatarItem, matching: .images) {
                                Label("選擇頭像照片", systemImage: "photo")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(HMTheme.ink)
                                    .padding(.horizontal, 12)
                                    .frame(height: 34)
                                    .background(Color.white, in: Capsule())
                                    .overlay(Capsule().stroke(.black.opacity(0.14), lineWidth: 1))
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }

                    ProfileField(
                        title: "顧客暱稱",
                        required: true,
                        placeholder: "例如：Kelvin、Winnie",
                        text: $nickname
                    )

                    Button {
                        saveProfile()
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isSaving ? "正在儲存..." : "儲存顧客檔案資料")
                        }
                        .font(.callout.weight(.black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.black, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(PressableButtonStyle())
                    .disabled(isSaving)

                    Divider()
                        .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("帳號管理")
                            .font(.callout.weight(.black))
                            .foregroundStyle(HMTheme.ink)
                        Text("如需離開 Hairmap，可在此永久刪除帳號、個人檔案及相關登入資料。")
                            .font(.caption.weight(.semibold))
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
                            .font(.callout.weight(.black))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.24), lineWidth: 1))
                        }
                        .buttonStyle(PressableButtonStyle())
                        .disabled(isDeletingAccount)
                    }
                }
            }
        }
        .onAppear(perform: syncFromStore)
        .onChange(of: pickedAvatarItem) { _, item in
            Task { await loadAvatar(item) }
        }
        .alert("永久刪除 Hairmap 帳號？", isPresented: $isDeleteAlertPresented) {
            Button("取消", role: .cancel) {}
            Button("刪除帳號", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("這會刪除您的登入帳號並登出此裝置。刪除後如要再次使用 Hairmap，需要重新註冊。")
        }
    }

    private func syncFromStore() {
        let name = store.commentDisplayName
        nickname = name == "訪客" ? "" : name
    }

    private func loadAvatar(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        avatarData = try? await item.loadTransferable(type: Data.self)
    }

    private func saveProfile() {
        Task {
            isSaving = true
            await store.updateCustomerProfile(displayName: nickname, avatarData: avatarData)
            isSaving = false
            avatarData = nil
            syncFromStore()
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

private struct ProfileAdminPanel: View {
    @Environment(HairmapStore.self) private var store
    let stylists: [Stylist]
    let salons: [Salon]
    @State private var adminSearchText = ""

    private var trimmedSearchText: String {
        adminSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredStylists: [Stylist] {
        guard !trimmedSearchText.isEmpty else { return stylists }
        return stylists.filter { stylist in
            stylistSearchIndex(stylist).localizedCaseInsensitiveContains(trimmedSearchText)
        }
    }

    private var filteredSalons: [Salon] {
        guard !trimmedSearchText.isEmpty else { return salons }
        return salons.filter { salon in
            salonSearchIndex(salon).localizedCaseInsensitiveContains(trimmedSearchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label("平台營運管理", systemImage: "slider.horizontal.3")
                    .font(.title3.weight(.black))
                    .foregroundStyle(HMTheme.ink)
                Text("審批新申請、調整首頁優先顯示、排行榜置頂與上下架。所有操作會直接寫入 Supabase。")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)

                Label("目前資料環境：\(store.supabaseEnvironmentName)", systemImage: "server.rack")
                    .font(.caption.weight(.black))
                    .foregroundStyle(store.supabaseEnvironmentName == "production" ? HMTheme.amber : HMTheme.emerald)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white, in: Capsule())
                    .overlay(Capsule().stroke(.black.opacity(0.08), lineWidth: 1))
            }
            .padding(.top, 12)

            ProfileAdminSection(title: "申請審批狀態") {
                ForEach(CatalogApplicationStatus.adminDisplayOrder) { status in
                    ProfileAdminApplicationStatusBlock(
                        status: status,
                        stylistApplications: store.pendingStylistApplications.filter { $0.status == status },
                        salonApplications: store.pendingSalonApplications.filter { $0.status == status }
                    )
                }
            }

            ProfileAdminSearchField(text: $adminSearchText)

            if !trimmedSearchText.isEmpty {
                HStack(spacing: 8) {
                    Label("找到 \(filteredStylists.count) 位髮型師", systemImage: "person.crop.circle")
                    Text("·")
                    Label("\(filteredSalons.count) 間沙龍", systemImage: "building.2.crop.circle")
                }
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
            }

            ProfileAdminSection(title: "髮型師檔案") {
                if filteredStylists.isEmpty {
                    ProfileAdminEmptySearchResult(title: "沒有符合的髮型師")
                }
                ForEach(filteredStylists) { stylist in
                    ProfileAdminStylistRow(stylist: stylist)
                }
            }

            ProfileAdminSection(title: "沙龍檔案") {
                if filteredSalons.isEmpty {
                    ProfileAdminEmptySearchResult(title: "沒有符合的沙龍")
                }
                ForEach(filteredSalons) { salon in
                    ProfileAdminSalonRow(salon: salon)
                }
            }

            Text(store.statusMessage)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black.opacity(0.06), lineWidth: 1))
        }
    }

    private func stylistSearchIndex(_ stylist: Stylist) -> String {
        [
            stylist.name,
            stylist.title,
            stylist.phone,
            stylist.district,
            stylist.experience,
            stylist.languages,
            stylist.salonID,
            salons.first(where: { $0.id == stylist.salonID })?.name ?? "",
            salons.first(where: { $0.id == stylist.salonID })?.district ?? "",
            salons.first(where: { $0.id == stylist.salonID })?.location ?? "",
            stylist.specialties.joined(separator: " "),
            stylist.bio
        ].joined(separator: " ")
    }

    private func salonSearchIndex(_ salon: Salon) -> String {
        [
            salon.name,
            salon.district,
            salon.location,
            salon.openHours,
            salon.phone,
            salon.tags.joined(separator: " ")
        ].joined(separator: " ")
    }
}

private struct ProfileAdminSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.secondary)
            TextField("搜尋髮型師 / 沙龍 / 地區 / 標籤...", text: $text)
                .font(.subheadline.weight(.semibold))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.black.opacity(0.12), lineWidth: 1))
    }
}

private struct ProfileAdminEmptySearchResult: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption.weight(.black))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.black.opacity(0.06), lineWidth: 1))
    }
}

private struct ProfileAdminSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline.weight(.black))
                .foregroundStyle(HMTheme.ink)
            VStack(spacing: 10) {
                content
            }
        }
    }
}

private struct ProfileAdminStylistRow: View {
    @Environment(HairmapStore.self) private var store
    let stylist: Stylist

    private var displayLocation: String {
        let salon = store.salon(id: stylist.salonID)
        return HairmapDistricts.displayLocation(
            district: stylist.district.nilIfEmpty ?? salon.district,
            location: stylist.location.nilIfEmpty ?? salon.displayLocation
        )
    }

    var body: some View {
        ProfileAdminEntityRow(
            imageURL: stylist.avatarURL,
            title: stylist.name,
            subtitle: "\(displayLocation) · \(stylist.title) · \(String(format: "%.1f", stylist.rating)) 星",
            meta: stylist.specialties.prefix(2).joined(separator: " / "),
            homePosition: stylist.isFeatured ? max(1, stylist.displayOrder) : 0,
            rankingPosition: store.rankingPosition(itemID: stylist.id, itemType: "stylist", rankingKey: "stylist_hot"),
            onSavePlacement: { homePosition, rankingPosition in
                Task { await store.updateStylistAdminPlacement(stylist, homePosition: homePosition, rankingPosition: rankingPosition) }
            },
            onPromote: { Task { await store.promoteStylistOnHome(stylist) } },
            onRank: { Task { await store.pinRanking(itemID: stylist.id, itemType: "stylist", rankingKey: "stylist_hot", title: stylist.name, score: stylist.rating) } },
            onHide: { Task { await store.hideStylistFromCatalog(stylist) } }
        )
    }
}

private struct ProfileAdminSalonRow: View {
    @Environment(HairmapStore.self) private var store
    let salon: Salon

    var body: some View {
        ProfileAdminEntityRow(
            imageURL: salon.imageURL,
            title: salon.name,
            subtitle: "\(salon.displayDistrict) · HK$\(salon.startPrice) 起",
            meta: salon.tags.prefix(2).joined(separator: " / "),
            homePosition: salon.isFeatured ? max(1, salon.displayOrder) : 0,
            rankingPosition: store.rankingPosition(itemID: salon.id, itemType: "salon", rankingKey: "salon_hot"),
            onSavePlacement: { homePosition, rankingPosition in
                Task { await store.updateSalonAdminPlacement(salon, homePosition: homePosition, rankingPosition: rankingPosition) }
            },
            onPromote: { Task { await store.promoteSalonOnHome(salon) } },
            onRank: { Task { await store.pinRanking(itemID: salon.id, itemType: "salon", rankingKey: "salon_hot", title: salon.name, score: salon.rating) } },
            onHide: { Task { await store.hideSalonFromCatalog(salon) } }
        )
    }
}

private extension CatalogApplicationStatus {
    var adminTint: Color {
        switch self {
        case .pending:
            HMTheme.amber
        case .approved:
            HMTheme.emerald
        case .rejected:
            .red
        case .hidden:
            .secondary
        }
    }

    var adminIconName: String {
        switch self {
        case .pending:
            "clock.badge.exclamationmark"
        case .approved:
            "checkmark.seal.fill"
        case .rejected:
            "xmark.seal.fill"
        case .hidden:
            "eye.slash.fill"
        }
    }
}

private struct ProfileAdminApplicationStatusBlock: View {
    let status: CatalogApplicationStatus
    let stylistApplications: [StylistApplication]
    let salonApplications: [SalonApplication]

    private var totalCount: Int {
        stylistApplications.count + salonApplications.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(status.title, systemImage: status.adminIconName)
                    .font(.caption.weight(.black))
                    .foregroundStyle(status.adminTint)
                Spacer()
                Text("\(totalCount) 宗")
                    .font(.caption2.monospacedDigit().weight(.black))
                    .foregroundStyle(status.adminTint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(status.adminTint.opacity(0.1), in: Capsule())
            }

            if totalCount == 0 {
                Text("暫時沒有\(status.title)記錄")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            } else {
                ForEach(stylistApplications) { application in
                    ProfileAdminStylistApplicationRow(application: application)
                }
                ForEach(salonApplications) { application in
                    ProfileAdminSalonApplicationRow(application: application)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(status.adminTint.opacity(0.22), lineWidth: 1))
    }
}

private struct ProfileAdminStylistApplicationRow: View {
    @Environment(HairmapStore.self) private var store
    let application: StylistApplication

    var body: some View {
        ProfileAdminApplicationRow(
            imageURL: application.avatarURL,
            badge: "髮型師申請",
            title: application.name,
            subtitle: "\(HairmapDistricts.displayLocation(district: application.district, location: application.location)) · \(application.title) · \(application.experience)",
            meta: [
                application.phone?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "未填電話",
                "\(application.servicesPayload.count) 項服務",
                "\(application.worksPayload.count) 張作品"
            ].joined(separator: " · "),
            status: application.status,
            onApprove: { Task { await store.approveStylistApplication(application) } },
            onReject: { Task { await store.rejectStylistApplication(application) } }
        )
    }
}

private struct ProfileAdminSalonApplicationRow: View {
    @Environment(HairmapStore.self) private var store
    let application: SalonApplication

    var body: some View {
        ProfileAdminApplicationRow(
            imageURL: application.imageURL,
            badge: "沙龍申請",
            title: application.name,
            subtitle: "\(HairmapDistricts.displayLocation(district: application.district, location: application.location)) · HK$\(application.startPrice) 起",
            meta: "\(application.tags.prefix(3).joined(separator: " / ")) · \(application.worksPayload.count) 張作品",
            status: application.status,
            onApprove: { Task { await store.approveSalonApplication(application) } },
            onReject: { Task { await store.rejectSalonApplication(application) } }
        )
    }
}

private struct ProfileAdminApplicationRow: View {
    let imageURL: String
    let badge: String
    let title: String
    let subtitle: String
    let meta: String
    let status: CatalogApplicationStatus
    let onApprove: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ProfileAdminThumbnail(urlString: imageURL)
                VStack(alignment: .leading, spacing: 5) {
                    Text(badge)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(status.adminTint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(status.adminTint.opacity(0.12), in: Capsule())
                    Text(title)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(HMTheme.ink)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(meta)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text(status.title)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(status.adminTint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(status.adminTint.opacity(0.1), in: Capsule())
            }

            if status == .pending {
                HStack(spacing: 8) {
                    ProfileAdminButton(title: "批准公開", isPrimary: true, action: onApprove)
                    ProfileAdminButton(title: "拒絕", isDestructive: true, action: onReject)
                }
            }
        }
        .padding(12)
        .background(status == .pending ? Color(red: 1.0, green: 0.985, blue: 0.94) : Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(status.adminTint.opacity(status == .pending ? 0.5 : 0.18), lineWidth: 1))
    }
}

private struct ProfileAdminEntityRow: View {
    let imageURL: String
    let title: String
    let subtitle: String
    let meta: String
    let onSavePlacement: (Int, Int) -> Void
    let onPromote: () -> Void
    let onRank: () -> Void
    let onHide: () -> Void
    @State private var homePosition: Int
    @State private var rankingPosition: Int

    init(
        imageURL: String,
        title: String,
        subtitle: String,
        meta: String,
        homePosition: Int,
        rankingPosition: Int,
        onSavePlacement: @escaping (Int, Int) -> Void,
        onPromote: @escaping () -> Void,
        onRank: @escaping () -> Void,
        onHide: @escaping () -> Void
    ) {
        self.imageURL = imageURL
        self.title = title
        self.subtitle = subtitle
        self.meta = meta
        self.onSavePlacement = onSavePlacement
        self.onPromote = onPromote
        self.onRank = onRank
        self.onHide = onHide
        _homePosition = State(initialValue: homePosition)
        _rankingPosition = State(initialValue: rankingPosition)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ProfileAdminThumbnail(urlString: imageURL)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(HMTheme.ink)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if !meta.isEmpty {
                        Text(meta)
                            .font(.caption2.weight(.black))
                            .foregroundStyle(Color(red: 0.56, green: 0.36, blue: 0.05))
                            .lineLimit(1)
                    }
                }
                Spacer()
            }

            HStack(spacing: 8) {
                ProfileAdminPositionMenu(
                    title: "首頁",
                    noun: "位",
                    maxValue: 6,
                    selection: $homePosition
                )
                ProfileAdminPositionMenu(
                    title: "榜單",
                    noun: "名",
                    maxValue: 10,
                    selection: $rankingPosition
                )
                Button {
                    onSavePlacement(homePosition, rankingPosition)
                } label: {
                    Text("保存")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .frame(width: 58, height: 34)
                        .background(Color.black, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(PressableButtonStyle())
            }

            HStack(spacing: 8) {
                ProfileAdminButton(title: "首頁優先", isPrimary: true, action: onPromote)
                ProfileAdminButton(title: "排行榜", isPrimary: false, action: onRank)
                ProfileAdminButton(title: "下架", isDestructive: true, action: onHide)
            }
        }
        .padding(12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.black.opacity(0.1), lineWidth: 1))
    }
}

private struct ProfileAdminPositionMenu: View {
    let title: String
    let noun: String
    let maxValue: Int
    @Binding var selection: Int

    private var displayText: String {
        selection == 0 ? "\(title)：不設定" : "\(title)：第\(selection)\(noun)"
    }

    var body: some View {
        Menu {
            Button("不設定") {
                selection = 0
            }
            ForEach(1...maxValue, id: \.self) { value in
                Button("第\(value)\(noun)") {
                    selection = value
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(displayText)
                    .font(.caption2.weight(.black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .black))
            }
            .foregroundStyle(HMTheme.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .padding(.horizontal, 8)
            .background(Color(red: 0.975, green: 0.976, blue: 0.98), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.1), lineWidth: 1))
        }
    }
}

private struct ProfileAdminThumbnail: View {
    let urlString: String

    var body: some View {
        RemoteImage(urlString: urlString, height: 56, cornerRadius: 10)
        .frame(width: 56, height: 56)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black.opacity(0.08), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct ProfileAdminButton: View {
    let title: String
    var isPrimary = false
    var isDestructive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(isPrimary ? .white : (isDestructive ? Color(red: 0.78, green: 0.1, blue: 0.18) : HMTheme.ink))
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(isPrimary ? Color.black : Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isDestructive ? Color(red: 0.95, green: 0.45, blue: 0.52) : .black.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct ProfileBookingsPanel: View {
    @Binding var scope: ProfileBookingScope
    let bookings: [Appointment]
    let activeCount: Int
    let historyCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .bottom) {
                Text("預約行程紀錄")
                    .font(.title3.weight(.black))
                    .foregroundStyle(HMTheme.ink)
                Spacer()
                HStack(spacing: 14) {
                    ProfileScopeButton(title: "進行中", count: activeCount, isSelected: scope == .active) {
                        scope = .active
                    }
                    ProfileScopeButton(title: "歷史紀錄", count: historyCount, isSelected: scope == .history) {
                        scope = .history
                    }
                }
            }
            .padding(.top, 12)

            Divider()

            if bookings.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(scope == .active ? "目前沒有進行中預約" : "暫時沒有歷史紀錄")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 52)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.black.opacity(0.06), lineWidth: 1))
            } else {
                VStack(spacing: 14) {
                    ForEach(bookings) { booking in
                        ProfileBookingCard(booking: booking)
                    }
                }
            }
        }
    }
}

private struct ProfileScopeButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(title) (\(count))")
                .font(.caption.weight(.black))
                .foregroundStyle(isSelected ? HMTheme.ink : .secondary)
                .padding(.bottom, 5)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(isSelected ? HMTheme.ink : .clear)
                        .frame(height: 1.4)
                }
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct ProfileBookingCard: View {
    @Environment(HairmapStore.self) private var store
    let booking: Appointment

    private var dateParts: (month: String, day: String) {
        guard let date = DateFormatter.hmDate.date(from: booking.bookingDate) else { return ("10月", "24") }
        let month = Calendar.hairmap.component(.month, from: date)
        let day = Calendar.hairmap.component(.day, from: date)
        return ("\(month)月", "\(day)")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(store.salon(id: booking.salonID).location) - \(booking.salonName)")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(HMTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Label("專屬髮型師: \(booking.stylistName)", systemImage: "sparkle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text(booking.status == .pending ? "即將到來" : booking.status.title)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(Color(red: 0.5, green: 0.34, blue: 0.05))
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(Color(red: 1, green: 0.94, blue: 0.68), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
            .padding(14)

            Divider()

            HStack(spacing: 14) {
                VStack(spacing: 2) {
                    Text(dateParts.month)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text(dateParts.day)
                        .font(.title3.monospacedDigit().weight(.black))
                        .foregroundStyle(HMTheme.ink)
                }
                .frame(width: 54, height: 54)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black.opacity(0.08), lineWidth: 1))

                VStack(alignment: .leading, spacing: 5) {
                    Label(booking.timeSlot, systemImage: "clock")
                        .font(.callout.monospacedDigit().weight(.black))
                        .foregroundStyle(HMTheme.ink)
                    Text("\(booking.serviceName) · HK$\(booking.price)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                }
                Spacer()
            }
            .padding(14)
            .background(Color(red: 0.988, green: 0.988, blue: 0.985))

            HStack(spacing: 10) {
                Button {
                    let stylist = store.stylist(id: booking.stylistID)
                    let service = stylist.services.first { $0.id == booking.serviceID || $0.name == booking.serviceName }
                    store.startBooking(stylistID: booking.stylistID, service: service)
                } label: {
                    Text("變更預約")
                        .font(.caption.weight(.black))
                        .foregroundStyle(HMTheme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(.black.opacity(0.08), lineWidth: 1))
                }
                .buttonStyle(PressableButtonStyle())

                Button {
                    Task { await store.cancelBooking(booking) }
                } label: {
                    Text("取消預約")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(Color.black, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(booking.status == .cancelled || booking.status == .completed)
            }
            .padding(14)
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.black, lineWidth: 1))
    }
}

private struct ProfileStylistCreatePanel: View {
    @Binding var name: String
    @Binding var title: String
    @Binding var phone: String
    @Binding var bio: String
    @Binding var district: String
    @Binding var address: String
    @Binding var instagramURL: String
    @Binding var experience: String
    @Binding var languages: String
    @Binding var services: [ProfileServiceDraft]
    @Binding var extraServiceName: String
    @Binding var extraServiceCategory: String
    @Binding var extraServiceDescription: String
    @Binding var extraServicePrice: String
    @Binding var selectedTags: Set<String>
    @Binding var selectedAvatarURL: String
    @Binding var customAvatarURL: String
    @Binding var selectedSamples: Set<String>
    @Binding var customWorkName: String
    @Binding var customWorkURL: String
    @Binding var uploadedWorkURLs: [String]
    let onAddExtraService: () -> Void
    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ProfileFormIntro(
                title: "新增專業髮型師檔案",
                subtitle: "填寫髮型師個人檔案與主要剪/燙/染/護服務。提交後會進入平台審批，批准後才會公開給客戶預約。"
            )

            ProfileField(title: "設計師姓名", required: true, placeholder: "例如: Leo Master, Marcus Lam", text: $name)
            ProfileField(title: "頭銜職稱", required: true, placeholder: "例如: 歐美挑染專家 / 首席設計師", text: $title)
            ProfileField(title: "髮型師聯絡電話", required: true, placeholder: "+852 6123 4567", text: $phone, keyboard: .phonePad)
            ProfileMenuField(title: "主要地區", value: $district, options: HairmapDistricts.all)
            ProfileField(title: "服務地址", required: true, placeholder: "例如: 尖沙咀海港城3樓3045號舖", text: $address)
            ProfileInstagramField(placeholder: "@hairmaphk 或 https://instagram.com/hairmaphk", text: $instagramURL)
            ProfileTextArea(title: "個人簡介", placeholder: "例如: 擁有10年以上沙龍經驗，擅長歐美漸層手刷染、Balayage，針對個人頭骨與臉型設計專屬層次剪裁。", text: $bio)

            HStack(spacing: 10) {
                ProfileMenuField(title: "工作資歷", value: $experience, options: ProfileSeed.experiences)
                ProfileMenuField(title: "溝通語言", value: $languages, options: ProfileSeed.languages)
            }

            ProfileServiceEditor(
                services: $services,
                extraName: $extraServiceName,
                extraCategory: $extraServiceCategory,
                extraDescription: $extraServiceDescription,
                extraPrice: $extraServicePrice,
                onAdd: onAddExtraService
            )

            ProfileTagSelector(
                title: "設計師擅長技術（可選多項）",
                tags: ProfileSeed.stylistTags,
                selection: $selectedTags
            )

            ProfileAvatarSelector(
                selectedAvatarURL: $selectedAvatarURL,
                customAvatarURL: $customAvatarURL
            )

            ProfilePortfolioEditor(
                title: "設計師作品剪染展示集",
                limitLabel: "上限10張",
                samples: ProfileSeed.stylistWorks,
                selectedSamples: $selectedSamples,
                customWorkName: $customWorkName,
                customWorkURL: $customWorkURL,
                uploadedWorkURLs: $uploadedWorkURLs,
                uploadTitle: "上載本機作品照片",
                addTitle: "加入此項剪染作品"
            )

            Button(action: onCreate) {
                Text("提交髮型師檔案審批")
                    .font(.callout.weight(.black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(PressableButtonStyle())
        }
    }
}

private struct ProfileSalonCreatePanel: View {
    @Binding var name: String
    @Binding var district: String
    @Binding var address: String
    @Binding var instagramURL: String
    @Binding var phone: String
    @Binding var hours: String
    @Binding var startPrice: String
    @Binding var selectedTags: Set<String>
    @Binding var features: [ProfileToggleOption]
    let stylists: [Stylist]
    @Binding var assignedStylistIDs: Set<String>
    @Binding var selectedSamples: Set<String>
    @Binding var customWorkName: String
    @Binding var customWorkURL: String
    @Binding var uploadedWorkURLs: [String]
    @Binding var packages: [ProfileSalonPackage]
    @Binding var packageName: String
    @Binding var packagePrice: String
    @Binding var selectedCoverURL: String
    @Binding var customCoverURL: String
    let onAddPackage: () -> Void
    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ProfileFormIntro(
                title: "新增實體沙龍館檔案",
                subtitle: "登記沙龍名稱、地址、營業時間與最低起跳預算。管理員建立後會直接儲存到 Supabase 並公開展示。"
            )

            ProfileField(title: "沙龍名稱", required: true, placeholder: "例如: Artisan Space, Noir Prestige Salon", text: $name)
            ProfileMenuField(title: "主要地區", value: $district, options: HairmapDistricts.all)
            ProfileField(title: "沙龍地址", required: true, placeholder: "例如: 尖沙咀海港城3樓3045號舖", text: $address)
            ProfileInstagramField(placeholder: "@salonhk 或 https://instagram.com/salonhk", text: $instagramURL)

            HStack(spacing: 10) {
                ProfileField(title: "聯絡電話", placeholder: "+852 2345 6789", text: $phone, keyboard: .phonePad)
                ProfileField(title: "營業時段", placeholder: "11:00 - 20:00", text: $hours)
            }

            ProfileField(title: "最低預估起價 (HKD)", placeholder: "480", text: $startPrice, keyboard: .numberPad)

            ProfileTagSelector(
                title: "沙龍館核心特色風格樣式（可多選）",
                tags: ProfileSeed.salonTags,
                selection: $selectedTags
            )

            ProfileFeatureEditor(features: $features)

            ProfileAssignedStylists(stylists: stylists, selection: $assignedStylistIDs)

            ProfilePortfolioEditor(
                title: "沙龍裝潢環境與技術實拍作品集",
                limitLabel: "上限10張",
                samples: ProfileSeed.salonWorks,
                selectedSamples: $selectedSamples,
                customWorkName: $customWorkName,
                customWorkURL: $customWorkURL,
                uploadedWorkURLs: $uploadedWorkURLs,
                uploadTitle: "上載本機裝修或實境照片",
                addTitle: "加入此空間網址作品"
            )

            ProfileSalonPackageEditor(packages: $packages, name: $packageName, price: $packagePrice, onAdd: onAddPackage)

            ProfileCoverSelector(selectedCoverURL: $selectedCoverURL, customCoverURL: $customCoverURL)

            Button(action: onCreate) {
                Text("確認建立並公開沙龍檔案")
                    .font(.callout.weight(.black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(PressableButtonStyle())
        }
    }
}

private struct ProfileFormIntro: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: "plus.circle")
                .font(.headline.weight(.black))
                .foregroundStyle(HMTheme.ink)
            Text(subtitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineSpacing(3)
            Divider()
                .padding(.top, 8)
        }
        .padding(.top, 10)
    }
}

private struct ProfileField: View {
    let title: String
    var required = false
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 3) {
                Text(title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
                if required {
                    Text("*")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.red)
                }
            }

            TextField(placeholder, text: $text)
                .font(.callout.weight(.semibold))
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ProfileInstagramField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Instagram 連結 / @帳號")
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                HairmapInstagramGlyph(color: .secondary.opacity(0.75))
                TextField(placeholder, text: $text)
                    .font(.callout.weight(.semibold))
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(HMTheme.amber, lineWidth: 2)
            )
            .shadow(color: HMTheme.amber.opacity(0.12), radius: 10, y: 4)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ProfileTextArea: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("選填")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(3...5)
                .font(.callout.weight(.semibold))
                .padding(14)
                .frame(minHeight: 86, alignment: .topLeading)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 1))
        }
    }
}

private struct ProfileMenuField: View {
    let title: String
    @Binding var value: String
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) { value = option }
                }
            } label: {
                HStack {
                    Text(value)
                        .font(.callout.weight(.bold))
                        .foregroundStyle(HMTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.black))
                        .foregroundStyle(HMTheme.ink)
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 1))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ProfileServiceEditor: View {
    @Binding var services: [ProfileServiceDraft]
    @Binding var extraName: String
    @Binding var extraCategory: String
    @Binding var extraDescription: String
    @Binding var extraPrice: String
    let onAdd: () -> Void

    var body: some View {
        ProfileBox {
            VStack(alignment: .leading, spacing: 14) {
                Label("設定精選服務項目與價格名冊", systemImage: "medal")
                    .font(.caption.weight(.black))
                    .foregroundStyle(HMTheme.ink)
                Text("勾選您要提供的項目並自由訂定價格。未勾選的項目將不會顯示在您的服務項目中。")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach($services) { $service in
                    ProfileServiceRow(service: $service)
                }

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("+ 新增與目前額外剪染項目")
                        .font(.caption.weight(.black))
                        .foregroundStyle(HMTheme.ink)
                    HStack(spacing: 8) {
                        ProfileCompactTextField(placeholder: "服務名稱（如: 護理救韓式劉海）", text: $extraName)
                        ProfileMenuField(title: "", value: $extraCategory, options: ["剪髮", "染髮", "燙髮", "護髮", "直髮"])
                    }
                    HStack(spacing: 8) {
                        ProfileCompactTextField(placeholder: "簡略花時與服務細節描述", text: $extraDescription)
                        ProfileCompactTextField(placeholder: "定價金額", text: $extraPrice, keyboard: .numberPad)
                            .frame(width: 118)
                    }
                    Button(action: onAdd) {
                        Text("加入此項自訂服務定價")
                            .font(.caption.weight(.black))
                            .foregroundStyle(HMTheme.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(Color.black.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
    }
}

private struct ProfileServiceRow: View {
    @Binding var service: ProfileServiceDraft

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                service.isEnabled.toggle()
            } label: {
                Image(systemName: service.isEnabled ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(service.isEnabled ? HMTheme.ink : .secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(PressableButtonStyle())

            VStack(alignment: .leading, spacing: 6) {
                Text(service.name)
                    .font(.caption.weight(.black))
                    .foregroundStyle(HMTheme.ink)
                    .lineLimit(2)
                Text(service.detail + "・\(service.duration) 分鐘")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 6)

            HStack(spacing: 6) {
                Text("HK$")
                    .font(.caption2.monospacedDigit().weight(.black))
                    .foregroundStyle(.secondary)
                TextField("380", text: $service.priceText)
                    .keyboardType(.numberPad)
                    .font(.caption.monospacedDigit().weight(.black))
                    .multilineTextAlignment(.center)
                    .frame(width: 70, height: 32)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(.black.opacity(0.08), lineWidth: 1))
            }
        }
        .padding(12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black.opacity(0.04), lineWidth: 1))
    }
}

private struct ProfileCompactTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.caption.weight(.semibold))
            .keyboardType(keyboard)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.horizontal, 11)
            .frame(height: 36)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(.black.opacity(0.08), lineWidth: 1))
    }
}

private struct ProfileTagSelector: View {
    let title: String
    let tags: [String]
    @Binding var selection: Set<String>
    @State private var customTag = ""

    private var customSelections: [String] {
        selection
            .filter { !tags.contains($0) }
            .sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Button {
                        if selection.contains(tag) {
                            selection.remove(tag)
                        } else {
                            selection.insert(tag)
                        }
                    } label: {
                        Text(tag)
                            .font(.caption.weight(.black))
                            .foregroundStyle(selection.contains(tag) ? .white : HMTheme.ink)
                            .padding(.horizontal, 13)
                            .frame(height: 32)
                            .background(selection.contains(tag) ? Color.black : Color.white, in: Capsule())
                            .overlay(Capsule().stroke(.black.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                ForEach(customSelections, id: \.self) { tag in
                    Button {
                        selection.remove(tag)
                    } label: {
                        HStack(spacing: 6) {
                            Text(tag)
                                .font(.caption.weight(.black))
                                .lineLimit(1)
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .black))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 13)
                        .frame(height: 32)
                        .background(Color.black, in: Capsule())
                        .overlay(Capsule().stroke(Color.black, lineWidth: 1))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }

            HStack(spacing: 8) {
                ProfileCompactTextField(placeholder: "輸入自訂風格（例如: 港風層次剪）", text: $customTag)
                Button {
                    addCustomTag()
                } label: {
                    Text("加入")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .frame(height: 36)
                        .background(Color.black, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(customTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(customTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            }
        }
    }

    private func addCustomTag() {
        let clean = customTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        selection.insert(clean)
        customTag = ""
    }
}

private struct ProfileAvatarSelector: View {
    @Binding var selectedAvatarURL: String
    @Binding var customAvatarURL: String
    @State private var pickedAvatarItem: PhotosPickerItem?
    @State private var uploadedAvatarData: Data?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    private let diceColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        ProfileBox {
            VStack(alignment: .leading, spacing: 14) {
                Text("設計師個人頭像自訂")
                    .font(.caption.weight(.black))
                    .foregroundStyle(HMTheme.ink)
                Text("選擇設計師主打人臉預設、虛擬角色圖標，或者直接上載自訂圖片。")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("選項 A. 經典真人肖像預設")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(ProfileSeed.avatarChoices) { avatar in
                        ProfileSelectableImage(
                            title: avatar.title,
                            url: avatar.url,
                            isSelected: selectedAvatarURL == avatar.url
                        ) {
                            selectedAvatarURL = avatar.url
                        }
                    }
                }

                Text("選項 B. 韓日系潮流虛擬人物 (DiceBear)")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: diceColumns, spacing: 8) {
                    ForEach(ProfileSeed.dicebearChoices) { avatar in
                        ProfileAvatarChip(url: avatar.url, isSelected: selectedAvatarURL == avatar.url) {
                            selectedAvatarURL = avatar.url
                        }
                    }
                }

                Divider()

                Text("選項 C. 從手機相簿或本機自訂上載")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    ProfileUploadedImage(data: uploadedAvatarData, fallbackURL: customAvatarURL.isEmpty ? selectedAvatarURL : customAvatarURL, height: 44, cornerRadius: 22)
                        .frame(width: 44)
                        .clipShape(Circle())
                    PhotosPicker(selection: $pickedAvatarItem, matching: .images) {
                        Label("選擇並上載設計師照片", systemImage: "square.and.arrow.up")
                            .font(.caption.weight(.black))
                            .foregroundStyle(HMTheme.ink)
                            .padding(.horizontal, 14)
                            .frame(height: 38)
                            .background(Color.white, in: Capsule())
                            .overlay(Capsule().stroke(.black.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                if uploadedAvatarData != nil {
                    Label("已選擇本機設計師照片，建立檔案時會套用此頭像", systemImage: "checkmark.circle.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(HMTheme.emerald)
                }
                ProfileCompactTextField(placeholder: "https://example.com/custom-stylist-avatar.jpg", text: $customAvatarURL)
            }
        }
        .onChange(of: pickedAvatarItem) { _, newItem in
            Task { await loadAvatar(newItem) }
        }
    }

    private func loadAvatar(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
        uploadedAvatarData = data
        if let savedURL = saveProfileUploadedImage(data, prefix: "stylist-avatar") {
            customAvatarURL = savedURL
        }
    }
}

private struct ProfilePortfolioEditor: View {
    let title: String
    let limitLabel: String
    let samples: [ProfileImageOption]
    @Binding var selectedSamples: Set<String>
    @Binding var customWorkName: String
    @Binding var customWorkURL: String
    @Binding var uploadedWorkURLs: [String]
    let uploadTitle: String
    let addTitle: String
    @State private var pickedWorkItems: [PhotosPickerItem] = []
    @State private var uploadedWorkDataItems: [Data] = []
    @State private var uploadStatus = ""

    private var selectedSampleItems: [ProfileImageOption] {
        samples.filter { selectedSamples.contains($0.id) }
    }

    private var cleanCustomWorkURL: String {
        customWorkURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasDistinctCustomWorkURL: Bool {
        !cleanCustomWorkURL.isEmpty && !uploadedWorkURLs.contains(cleanCustomWorkURL)
    }

    private var totalWorkCount: Int {
        selectedSampleItems.count + uploadedWorkURLs.count + (hasDistinctCustomWorkURL ? 1 : 0)
    }

    private var remainingSlots: Int {
        max(0, 10 - totalWorkCount)
    }

    var body: some View {
        ProfileBox {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("\(title) (\(min(totalWorkCount, 10)) / 10)", systemImage: "photo")
                        .font(.caption.weight(.black))
                        .foregroundStyle(HMTheme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.74)
                    Spacer()
                    Text(limitLabel)
                        .font(.caption2.weight(.black))
                        .padding(.horizontal, 8)
                        .frame(height: 24)
                        .background(Color.black.opacity(0.06), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }

                if selectedSampleItems.isEmpty && uploadedWorkURLs.isEmpty && cleanCustomWorkURL.isEmpty {
                    Text("尚未加入作品，請從範本或本機相簿選擇。")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.06), lineWidth: 1))
                } else if !selectedSampleItems.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(selectedSampleItems) { sample in
                                ProfileMiniWork(url: sample.url, title: sample.title) {
                                    removeSample(sample.id)
                                }
                            }
                        }
                    }
                }

                Divider()

                Text("本機直接多選作品上載：")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(HMTheme.ink)
                VStack(alignment: .leading, spacing: 10) {
                    if !uploadedWorkDataItems.isEmpty || !uploadedWorkURLs.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(uploadedWorkURLs.enumerated()), id: \.offset) { index, url in
                                    ZStack(alignment: .topTrailing) {
                                        ProfileUploadedImage(
                                            data: index < uploadedWorkDataItems.count ? uploadedWorkDataItems[index] : nil,
                                            fallbackURL: url,
                                            height: 58,
                                            cornerRadius: 8
                                        )
                                        .frame(width: 76)
                                        .overlay(alignment: .bottomLeading) {
                                            Text("本機 \(index + 1)")
                                                .font(.caption2.weight(.black))
                                                .foregroundStyle(.white)
                                                .lineLimit(1)
                                                .padding(.horizontal, 6)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .frame(height: 18)
                                                .background(.black.opacity(0.58))
                                        }

                                        Button {
                                            removeUploadedWork(at: index)
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 10, weight: .black))
                                                .foregroundStyle(.white)
                                                .frame(width: 26, height: 26)
                                                .background(Color(red: 1, green: 0.17, blue: 0.34), in: Circle())
                                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                        }
                                        .buttonStyle(PressableButtonStyle())
                                        .offset(x: 6, y: -6)
                                    }
                                }
                            }
                        }
                    }

                    PhotosPicker(selection: $pickedWorkItems, maxSelectionCount: max(1, remainingSlots), matching: .images) {
                        Label(uploadTitle, systemImage: "square.and.arrow.up")
                            .font(.caption.weight(.black))
                            .foregroundStyle(HMTheme.ink)
                            .padding(.horizontal, 14)
                            .frame(height: 36)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.12), lineWidth: 1))
                    }
                    .buttonStyle(PressableButtonStyle())
                    .disabled(remainingSlots == 0)
                    .opacity(remainingSlots == 0 ? 0.45 : 1)
                }
                if !uploadStatus.isEmpty {
                    Label(uploadStatus, systemImage: "checkmark.circle.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(HMTheme.emerald)
                }

                Text("或快速勾選加入優秀髮型作品範本：")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(samples) { sample in
                            ProfileWorkSample(url: sample.url, title: sample.title, isSelected: selectedSamples.contains(sample.id)) {
                                toggle(sample.id)
                            }
                        }
                    }
                }

                HStack(spacing: 8) {
                    ProfileCompactTextField(placeholder: "作品名稱（如: 漸層挑染）", text: $customWorkName)
                    ProfileCompactTextField(placeholder: "自訂圖片網址/連結", text: $customWorkURL)
                }

                Button {
                    if customWorkName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        customWorkName = "本機上載作品"
                    }
                    uploadStatus = customWorkURL.isEmpty && uploadedWorkURLs.isEmpty ? "請先選擇或輸入作品圖片" : "已加入作品草稿"
                } label: {
                    Text(addTitle)
                        .font(.caption.weight(.black))
                        .foregroundStyle(HMTheme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1))
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .onChange(of: pickedWorkItems) { _, newItems in
            Task { await loadWorks(newItems) }
        }
    }

    private func toggle(_ id: String) {
        if selectedSamples.contains(id) {
            removeSample(id)
        } else if remainingSlots > 0 {
            selectedSamples.insert(id)
            uploadStatus = ""
        } else {
            uploadStatus = "作品已達 10 張上限"
        }
    }

    private func removeSample(_ id: String) {
        selectedSamples.remove(id)
        uploadStatus = "已移除作品範本"
    }

    private func removeUploadedWork(at index: Int) {
        guard uploadedWorkURLs.indices.contains(index) else { return }
        let removedURL = uploadedWorkURLs.remove(at: index)
        if uploadedWorkDataItems.indices.contains(index) {
            uploadedWorkDataItems.remove(at: index)
        }
        if cleanCustomWorkURL == removedURL {
            customWorkURL = uploadedWorkURLs.last ?? ""
        }
        uploadStatus = uploadedWorkURLs.isEmpty ? "已移除本機作品照片" : "已選擇 \(uploadedWorkURLs.count) 張本機作品照片"
    }

    private func loadWorks(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        let capacity = remainingSlots
        guard capacity > 0 else {
            uploadStatus = "作品已達 10 張上限"
            pickedWorkItems = []
            return
        }
        var newURLs: [String] = []
        var newDataItems: [Data] = []
        for item in items.prefix(capacity) {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let savedURL = saveProfileUploadedImage(data, prefix: "portfolio-work") else { continue }
            newDataItems.append(data)
            newURLs.append(savedURL)
        }
        guard !newURLs.isEmpty else { return }
        uploadedWorkURLs.append(contentsOf: newURLs)
        uploadedWorkDataItems.append(contentsOf: newDataItems)
        if customWorkName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            customWorkName = "本機上載作品"
        }
        customWorkURL = newURLs.last ?? customWorkURL
        uploadStatus = newURLs.count < items.count ? "已加入 \(newURLs.count) 張，作品上限為 10 張" : "已選擇 \(uploadedWorkURLs.count) 張本機作品照片"
        pickedWorkItems = []
    }
}

private struct ProfileFeatureEditor: View {
    @Binding var features: [ProfileToggleOption]
    @State private var customFeature = ""

    var body: some View {
        ProfileBox {
            VStack(alignment: .leading, spacing: 12) {
                Label("沙龍特色服務特徵與優勢細項", systemImage: "sparkles")
                    .font(.caption.weight(.black))
                    .foregroundStyle(HMTheme.ink)
                Text("勾選此院所提供給消費者的頂級硬軟體亮點，將同步顯示在沙龍詳情頁面。")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach($features) { $feature in
                    Button {
                        feature.isSelected.toggle()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: feature.isSelected ? "checkmark.square.fill" : "square")
                                .font(.system(size: 18, weight: .black))
                                .foregroundStyle(feature.isSelected ? HMTheme.amber : .secondary)
                            Text(feature.title)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(HMTheme.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 38)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(feature.isSelected ? HMTheme.amber : .black.opacity(0.06), lineWidth: 1))
                    }
                    .buttonStyle(PressableButtonStyle())
                }

                HStack(spacing: 8) {
                    ProfileCompactTextField(placeholder: "自訂其他沙龍優勢（如: 提供單一座位電視影音）", text: $customFeature)
                    Button {
                        let clean = customFeature.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !clean.isEmpty else { return }
                        features.append(ProfileToggleOption(title: clean, isSelected: true))
                        customFeature = ""
                    } label: {
                        Text("加入此特徵")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .frame(height: 36)
                            .background(Color.black, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
    }
}

private struct ProfileAssignedStylists: View {
    let stylists: [Stylist]
    @Binding var selection: Set<String>
    @State private var searchText = ""

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)

    private var filteredStylists: [Stylist] {
        let sortedStylists = stylists.sorted { lhs, rhs in
            let lhsSelected = selection.contains(lhs.id)
            let rhsSelected = selection.contains(rhs.id)
            if lhsSelected != rhsSelected { return lhsSelected && !rhsSelected }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        let cleanQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else { return sortedStylists }
        return sortedStylists.filter { stylist in
            [
                stylist.name,
                stylist.title,
                stylist.experience,
                stylist.languages,
                stylist.specialties.joined(separator: " ")
            ]
            .joined(separator: " ")
            .localizedCaseInsensitiveContains(cleanQuery)
        }
    }

    var body: some View {
        ProfileBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("認證在店服務髮型設計師名單", systemImage: "person.2")
                        .font(.caption.weight(.black))
                        .foregroundStyle(HMTheme.ink)
                    Spacer()
                    Text("已選 \(selection.count)")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(HMTheme.amber)
                        .padding(.horizontal, 8)
                        .frame(height: 24)
                        .background(Color.yellow.opacity(0.14), in: Capsule())
                }
                Text("點按連結此沙龍內入駐的專業髮型技術人員，消費者將能在店內直接點選與其檔案。")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                ProfileSearchField(
                    placeholder: "搜尋髮型師姓名、頭銜或專長",
                    text: $searchText
                )
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(filteredStylists) { stylist in
                        Button {
                            if selection.contains(stylist.id) {
                                selection.remove(stylist.id)
                            } else {
                                selection.insert(stylist.id)
                            }
                        } label: {
                            HStack(spacing: 9) {
                                RemoteImage(urlString: stylist.avatarURL, height: 34, cornerRadius: 17)
                                    .frame(width: 34)
                                    .clipShape(Circle())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(stylist.name)
                                        .font(.caption.weight(.black))
                                        .foregroundStyle(HMTheme.ink)
                                        .lineLimit(1)
                                    Text(stylist.title)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: selection.contains(stylist.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(selection.contains(stylist.id) ? HMTheme.ink : .secondary.opacity(0.35))
                            }
                            .padding(10)
                            .frame(height: 58)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(selection.contains(stylist.id) ? Color.black : .black.opacity(0.06), lineWidth: 1))
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                if filteredStylists.isEmpty {
                    Text("未找到符合條件的髮型師。新髮型師檔案通過審批後，會自動出現在此名單供搜尋加入。")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.06), lineWidth: 1))
                }
            }
        }
    }
}

private struct ProfileSearchField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .font(.caption.weight(.semibold))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(.horizontal, 11)
        .frame(height: 38)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(.black.opacity(0.12), lineWidth: 1))
    }
}

private struct ProfileSalonPackageEditor: View {
    @Binding var packages: [ProfileSalonPackage]
    @Binding var name: String
    @Binding var price: String
    let onAdd: () -> Void

    var body: some View {
        ProfileBox {
            VStack(alignment: .leading, spacing: 12) {
                Label("沙龍院內主打精選特色主題服務與定價目錄", systemImage: "medal")
                    .font(.caption.weight(.black))
                    .foregroundStyle(HMTheme.ink)
                Text("設計多元的主題套餐，以便客戶挑選。")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                VStack(spacing: 0) {
                    ForEach(packages) { package in
                        HStack {
                            Text(package.title)
                                .font(.caption.weight(.black))
                                .foregroundStyle(HMTheme.ink)
                                .lineLimit(1)
                            Spacer()
                            Text("HK$\(package.priceText)")
                                .font(.caption.monospacedDigit().weight(.black))
                            Button {
                                packages.removeAll { $0.id == package.id }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption2.weight(.black))
                                    .foregroundStyle(.pink)
                                    .frame(width: 24, height: 24)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                        .padding(.vertical, 10)
                        .overlay(alignment: .bottom) { Rectangle().fill(.black.opacity(0.06)).frame(height: 1) }
                    }
                }
                .padding(.horizontal, 10)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                HStack(spacing: 8) {
                    ProfileCompactTextField(placeholder: "主題套組名稱（如: 頂級AVEDA全效深護）", text: $name)
                    ProfileCompactTextField(placeholder: "預估定價", text: $price, keyboard: .numberPad)
                        .frame(width: 116)
                }

                Button(action: onAdd) {
                    Text("+ 加入此項主題精選定價")
                        .font(.caption.weight(.black))
                        .foregroundStyle(HMTheme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(Color.black.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }
}

private struct ProfileCoverSelector: View {
    @Binding var selectedCoverURL: String
    @Binding var customCoverURL: String
    @State private var pickedCoverItem: PhotosPickerItem?
    @State private var uploadedCoverData: Data?
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        ProfileBox {
            VStack(alignment: .leading, spacing: 14) {
                Text("沙龍外在招牌與實物封面設置")
                    .font(.caption.weight(.black))
                    .foregroundStyle(HMTheme.ink)
                Text("用於展示在搜尋探索頁面的主視覺實拍卡片封面。")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(ProfileSeed.coverChoices) { cover in
                        ProfileSelectableImage(title: cover.title, url: cover.url, isSelected: selectedCoverURL == cover.url) {
                            selectedCoverURL = cover.url
                        }
                    }
                }
                Divider()
                Text("自訂封面檔案上載")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    ProfileUploadedImage(data: uploadedCoverData, fallbackURL: customCoverURL.isEmpty ? selectedCoverURL : customCoverURL, height: 44, cornerRadius: 8)
                        .frame(width: 64)
                    PhotosPicker(selection: $pickedCoverItem, matching: .images) {
                        Label("選擇並上載沙龍封面", systemImage: "square.and.arrow.up")
                            .font(.caption.weight(.black))
                            .foregroundStyle(HMTheme.ink)
                            .padding(.horizontal, 14)
                            .frame(height: 38)
                            .background(Color.white, in: Capsule())
                            .overlay(Capsule().stroke(.black.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                if uploadedCoverData != nil {
                    Label("已選擇本機沙龍封面", systemImage: "checkmark.circle.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(HMTheme.emerald)
                }
                ProfileCompactTextField(placeholder: "https://example.com/your-salon-cover.jpg", text: $customCoverURL)
            }
        }
        .onChange(of: pickedCoverItem) { _, newItem in
            Task { await loadCover(newItem) }
        }
    }

    private func loadCover(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
        uploadedCoverData = data
        if let savedURL = saveProfileUploadedImage(data, prefix: "salon-cover") {
            customCoverURL = savedURL
        }
    }
}

private struct ProfileBox<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.99, green: 0.99, blue: 0.985), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.black.opacity(0.08), lineWidth: 1))
    }
}

private struct ProfileUploadedImage: View {
    let data: Data?
    let fallbackURL: String
    let height: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RemoteImage(urlString: fallbackURL, height: height, cornerRadius: cornerRadius)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

private func saveProfileUploadedImage(_ data: Data, prefix: String) -> String? {
    do {
        let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("HairmapUploads", isDirectory: true)
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        let fileURL = baseURL.appendingPathComponent("\(prefix)-\(UUID().uuidString).jpg")
        try data.write(to: fileURL, options: .atomic)
        return fileURL.absoluteString
    } catch {
        return nil
    }
}

private struct ProfileSelectableImage: View {
    let title: String
    let url: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                RemoteImage(urlString: url, height: 78, cornerRadius: 9)
                LinearGradient(colors: [.clear, .black.opacity(0.64)], startPoint: .top, endPoint: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                Text(title)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .padding(7)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(HMTheme.amber)
                        .padding(6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
            .frame(height: 78)
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(isSelected ? Color.black : .clear, lineWidth: 2))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct ProfileAvatarChip: View {
    let url: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RemoteImage(urlString: url, height: 54, cornerRadius: 8)
                .frame(height: 54)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.black : .black.opacity(0.08), lineWidth: isSelected ? 2 : 1))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct ProfileMiniWork: View {
    let url: String
    let title: String
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .bottomLeading) {
                RemoteImage(urlString: url, height: 62, cornerRadius: 8)
                    .frame(width: 72)
                Text(title)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 20)
                    .background(.black.opacity(0.55))
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.1), lineWidth: 1))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(.pink)
                    .background(.white, in: Circle())
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(PressableButtonStyle())
            .offset(x: 8, y: -8)
        }
        .frame(width: 76, height: 66)
    }
}

private struct ProfileWorkSample: View {
    let url: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .center) {
                RemoteImage(urlString: url, height: 62, cornerRadius: 8)
                    .frame(width: 64)
                if !isSelected {
                    Circle()
                        .fill(.black.opacity(0.46))
                        .frame(width: 30, height: 30)
                    Image(systemName: "plus")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                }
            }
            .overlay(alignment: .bottomLeading) {
                Text(title)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.black.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.black : .clear, lineWidth: 2))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX > 0 && currentX + size.width > maxWidth {
                currentX = 0
                currentY += rowHeight + rowSpacing
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: maxWidth, height: currentY + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX > bounds.minX && currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += rowHeight + rowSpacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

private struct ProfileServiceDraft: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var category: String
    var detail: String
    var duration: Int
    var priceText: String
    var isEnabled: Bool
}

private struct ProfileToggleOption: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var isSelected: Bool
}

private struct ProfileSalonPackage: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var priceText: String
}

private struct ProfileImageOption: Identifiable, Hashable {
    var id: String
    var title: String
    var url: String
}

private enum ProfileSeed {
    static let experiences = ["3年資歷", "5年資歷", "8年資歷", "10年以上"]
    static let languages = ["中 / 粵", "中 / 粵 / 英", "中 / 英", "中 / 韓"]
    static let stylistTags = ["挑染專家", "經典剪髮", "歐美挑染", "漸層推剪", "韓式燙髮", "縮毛矯正", "女神大波浪", "深層護理", "直髮柔順"]
    static let salonTags = ["歐美染髮", "手刷染", "男士理髮", "漸層推剪", "韓式燙髮", "縮毛矯正", "女神大波浪", "線條感挑染"]

    static let stylistServices = [
        ProfileServiceDraft(name: "招牌日本系統沙龍精修剪裁（剪髮）", category: "剪髮", detail: "包含精油洗髮、髮絲整理與精修剪裁造型", duration: 60, priceText: "380", isEnabled: true),
        ProfileServiceDraft(name: "頂級日系高成文體單色染髮（染髮）", category: "染髮", detail: "低損害染髮配方，打造透亮顯白光澤染髮", duration: 120, priceText: "880", isEnabled: true),
        ProfileServiceDraft(name: "深海泥極致深層細胞保濕護理（護髮）", category: "護髮", detail: "鎖水因子深層滲透，回復彈亮柔順質感", duration: 90, priceText: "680", isEnabled: true),
        ProfileServiceDraft(name: "韓系免整理慵懶澎潤雲朵燙（燙髮）", category: "燙髮", detail: "客製化修飾臉型大波浪，自然蓬鬆彈力", duration: 150, priceText: "1280", isEnabled: false),
        ProfileServiceDraft(name: "日本膠原蛋白極上縮毛離子矯正（直髮）", category: "直髮", detail: "柔順撫平自然捲與毛躁，重現瀑布柔順", duration: 180, priceText: "1580", isEnabled: false),
        ProfileServiceDraft(name: "明星巴黎手刷多層次手感桃色漂染（染髮）", category: "染髮", detail: "高階3D立體手畫染，打造歐美時尚漸層", duration: 180, priceText: "1880", isEnabled: false)
    ]

    static let salonFeatures = [
        ProfileToggleOption(title: "提供手沖精品咖啡與精緻法式點心", isSelected: true),
        ProfileToggleOption(title: "奢華 VVIP 尊爵獨立包廂隱私空間", isSelected: false),
        ProfileToggleOption(title: "全座位配置高速無充電座與無限千兆 Wi-Fi", isSelected: true),
        ProfileToggleOption(title: "全店採用 AVEDA / Oway 專利有機植物性染膏", isSelected: false),
        ProfileToggleOption(title: "毛孩店長駐店等待，提供完全寵物友善空間", isSelected: false),
        ProfileToggleOption(title: "日系肩頸精油舒壓氣泡頭皮舒壓 SPA 療程", isSelected: false),
        ProfileToggleOption(title: "現場附設專業美甲與定製新娘化妝服務", isSelected: false)
    ]

    static let salonPackages = [
        ProfileSalonPackage(title: "經典日系精緻剪髮與香氛洗吹", priceText: "580"),
        ProfileSalonPackage(title: "巴黎極地無損手刷極致染護療程", priceText: "1280"),
        ProfileSalonPackage(title: "明星柔順木馬氣墊燙髮一體套餐", priceText: "1580"),
        ProfileSalonPackage(title: "膠原離子無痕縮毛矯正抗燥療程", priceText: "1880")
    ]

    static let avatarChoices = [
        ProfileImageOption(id: "avatar_1", title: "美髮現代女設計師", url: "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=500&q=80"),
        ProfileImageOption(id: "avatar_2", title: "精緻紳士男設計師", url: "https://images.unsplash.com/photo-1615109398623-88346a601842?auto=format&fit=crop&w=500&q=80"),
        ProfileImageOption(id: "avatar_3", title: "韓系甜美女設計師", url: "https://images.unsplash.com/photo-1580618672591-eb180b1a973f?auto=format&fit=crop&w=500&q=80")
    ]

    static let dicebearChoices = [
        ProfileImageOption(id: "dice_1", title: "A", url: "https://api.dicebear.com/8.x/adventurer/png?seed=hairmap-a"),
        ProfileImageOption(id: "dice_2", title: "B", url: "https://api.dicebear.com/8.x/adventurer/png?seed=hairmap-b"),
        ProfileImageOption(id: "dice_3", title: "C", url: "https://api.dicebear.com/8.x/bottts/png?seed=hairmap-c"),
        ProfileImageOption(id: "dice_4", title: "D", url: "https://api.dicebear.com/8.x/adventurer/png?seed=hairmap-d"),
        ProfileImageOption(id: "dice_5", title: "E", url: "https://api.dicebear.com/8.x/adventurer/png?seed=hairmap-e")
    ]

    static let stylistWorks = [
        ProfileImageOption(id: "profile_work_1", title: "色映美", url: "https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=500&q=80"),
        ProfileImageOption(id: "profile_work_2", title: "日系線條木馬燙", url: "https://images.unsplash.com/photo-1519699047748-de8e457a634e?auto=format&fit=crop&w=500&q=80"),
        ProfileImageOption(id: "profile_work_3", title: "經典冷灰立體", url: "https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?auto=format&fit=crop&w=500&q=80"),
        ProfileImageOption(id: "profile_work_4", title: "日系勸感高", url: "https://images.unsplash.com/photo-1527799820374-dcf8d9d4a388?auto=format&fit=crop&w=500&q=80"),
        ProfileImageOption(id: "profile_work_5", title: "男士漸層", url: "https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=500&q=80")
    ]

    static let salonWorks = [
        ProfileImageOption(id: "salon_work_1", title: "現代北歐概念店", url: "https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=500&q=80"),
        ProfileImageOption(id: "salon_work_2", title: "大理石香氛SPA", url: "https://images.unsplash.com/photo-1633681926022-84c23e8cb2d6?auto=format&fit=crop&w=500&q=80"),
        ProfileImageOption(id: "salon_work_3", title: "日系木質專區", url: "https://images.unsplash.com/photo-1522338242992-e1a54906a8da?auto=format&fit=crop&w=500&q=80")
    ]

    static let coverChoices = [
        ProfileImageOption(id: "cover_1", title: "北歐奢華概念白", url: "https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=700&q=80"),
        ProfileImageOption(id: "cover_2", title: "奢侈時尚工具牆", url: "https://images.unsplash.com/photo-1522338242992-e1a54906a8da?auto=format&fit=crop&w=700&q=80"),
        ProfileImageOption(id: "cover_3", title: "日系木質環境", url: "https://images.unsplash.com/photo-1633681926022-84c23e8cb2d6?auto=format&fit=crop&w=700&q=80")
    ]
}
