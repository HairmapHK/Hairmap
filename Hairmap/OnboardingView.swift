import AuthenticationServices
import SwiftUI

private enum OnboardingMode {
    case welcome
    case customerRegister
    case stylistPortal
    case login
    case stylistRegister
}

struct OnboardingView: View {
    @Environment(HairmapStore.self) private var store
    @Environment(\.openURL) private var openURL
    @State private var role: UserRole = .customer
    @State private var mode: OnboardingMode = .welcome
    @State private var displayName = ""
    @State private var stylistName = ""
    @State private var stylistTitle = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var isSubmitting = false
    @State private var showAuthStatus = false
    @State private var hasAcceptedTerms = false

    private static let termsURL = URL(string: "https://kelvinfung398398-sudo.github.io/Hairmap/terms.html")!
    private static let privacyURL = URL(string: "https://kelvinfung398398-sudo.github.io/Hairmap/privacy.html")!

    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.965, green: 0.968, blue: 0.972)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                hero
                Spacer(minLength: 0)
            }
            .ignoresSafeArea(edges: .top)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: topSpacer)

                    onboardingCard
                        .padding(.horizontal, horizontalInset)
                        .padding(.bottom, 34)
                }
            }

            if showsBackButton {
                Button {
                    withAnimation(.snappy(duration: 0.28)) {
                        mode = role == .stylist ? .stylistPortal : .welcome
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.leading, 16)
                .padding(.top, 42)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .preferredColorScheme(.light)
        .animation(.snappy(duration: 0.28), value: mode)
        .animation(.snappy(duration: 0.28), value: role)
    }

    private var hero: some View {
        ZStack(alignment: .top) {
            Image("SalonHero")
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width, height: heroHeight)
                .clipped()

            LinearGradient(
                colors: [
                    .black.opacity(0.18),
                    .black.opacity(0.04),
                    .white.opacity(0.08),
                    .white.opacity(0.96)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: heroHeight)

        }
    }

    @ViewBuilder
    private var onboardingCard: some View {
        VStack(spacing: 0) {
            roleSwitch
                .padding(.top, 48)

            content
                .padding(.top, 34)
                .padding(.horizontal, 26)
                .padding(.bottom, 14)

            statusBanner
                .padding(.horizontal, 26)
                .padding(.bottom, bottomPadding)
        }
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.11), radius: 24, y: 14)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .welcome:
            welcomeContent
        case .customerRegister:
            customerRegisterContent
        case .stylistPortal:
            stylistPortalContent
        case .login:
            loginContent
        case .stylistRegister:
            stylistRegisterContent
        }
    }

    private var roleSwitch: some View {
        HStack(spacing: 4) {
            roleSegment(title: "我是顧客", systemImage: "person.crop.circle", role: .customer)
            roleSegment(title: "髮型師工作台", systemImage: "scissors", role: .stylist)
        }
        .padding(4)
        .background(Color(red: 0.965, green: 0.965, blue: 0.965), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.black.opacity(0.1), lineWidth: 1))
        .padding(.horizontal, 28)
    }

    private func roleSegment(title: String, systemImage: String, role segmentRole: UserRole) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.28)) {
                role = segmentRole
                mode = segmentRole == .customer ? .welcome : .stylistPortal
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(role == segmentRole ? (segmentRole == .stylist ? .white : HMTheme.ink) : .secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                role == segmentRole ? (segmentRole == .stylist ? .black : .white) : .clear,
                in: RoundedRectangle(cornerRadius: 11, style: .continuous)
            )
            .shadow(color: role == segmentRole ? .black.opacity(0.08) : .clear, radius: 9, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var welcomeContent: some View {
        VStack(spacing: 24) {
            titleBlock(
                title: "歡迎來到 Hairmap",
                subtitle: "探索頂尖設計師，打造您的專屬造型"
            )

            VStack(spacing: 16) {
                blackButton("註冊新帳號") {
                    showAuthStatus = false
                    mode = .customerRegister
                }

                lightButton("已有 Gmail / Email 帳號登入") {
                    showAuthStatus = false
                    role = .customer
                    mode = .login
                }

                lightButton("直接以訪客身分體驗") {
                    quickStart(role: .customer)
                }
            }

            dividerText("或透過以下方式繼續")
            termsAgreementRow
            socialLoginStack(googleTitle: "使用 Google 登入")

            footerLinks
        }
    }

    private var customerRegisterContent: some View {
        VStack(spacing: 18) {
            titleBlock(
                title: "歡迎註冊新帳號",
                subtitle: "請填寫下方資料，完成您在 Hairmap 的專屬帳號"
            )

            VStack(spacing: 14) {
                authField(label: "使用者暱稱", placeholder: "例如：王小明", text: $displayName, systemImage: "person")
                authField(label: "電子郵箱", placeholder: "name@example.com", text: $email, systemImage: "envelope", keyboard: .emailAddress)
                passwordField(label: "設定密碼", placeholder: "請輸入密碼（至少 6 位字元）", text: $password)
                passwordField(label: "確認密碼", placeholder: "請再次輸入密碼二次確認", text: $confirmPassword)
            }

            termsAgreementRow

            blackButton(isSubmitting ? "註冊中" : "註冊帳號並寄出確認信", disabled: !hasAcceptedTerms) {
                submitRegister(
                    role: .customer,
                    displayName: displayName.isEmpty ? "Hairmap 顧客" : displayName,
                    email: email,
                    password: password,
                    confirmPassword: confirmPassword
                )
            }

            confirmationResendBlock(email: email)

            Button("已經有帳號？跳轉登入") {
                mode = .login
            }
            .font(.footnote.weight(.bold))
            .foregroundStyle(Color(red: 0.32, green: 0.36, blue: 0.42))
            .padding(.top, 10)

            footerLinks
        }
    }

    private var stylistPortalContent: some View {
        VStack(spacing: 22) {
            titleBlock(
                title: "髮型師專業管理工作台",
                subtitle: "在線管理預約排程，實時進行顧客一對一諮詢對話，快速設置 Supabase blocked_slots 忙碌檔期與修改名片作品集。"
            )

            VStack(spacing: 14) {
                blackButton("髮型師電子郵箱登入") {
                    mode = .login
                }

                lightButton("註冊創立髮型師帳號") {
                    mode = .stylistRegister
                }
            }

            dividerText("或透過以下方式登入工作台")
            termsAgreementRow
            socialLoginStack(googleTitle: "髮型師使用 Google 登入")

            footerLinks
        }
    }

    private var loginContent: some View {
        VStack(spacing: 18) {
            titleBlock(
                title: "會員登入",
                subtitle: "登入您的帳號，預約最契合的明星設計師"
            )

            VStack(spacing: 14) {
                authField(label: "電子郵箱", placeholder: "name@example.com", text: $email, systemImage: "envelope", keyboard: .emailAddress)
                passwordField(
                    label: "輸入密碼",
                    placeholder: "請輸入密碼",
                    text: $password,
                    showsForgot: true,
                    forgotAction: { submitForgotPassword() }
                )
            }

            termsAgreementRow

            blackButton(isSubmitting ? "登入中" : "使用密碼登入", disabled: !hasAcceptedTerms) {
                submitLogin(
                    role: role,
                    email: email,
                    password: password
                )
            }

            Button("還沒有帳號嗎？申請註冊") {
                mode = role == .stylist ? .stylistRegister : .customerRegister
            }
            .font(.footnote.weight(.bold))
            .foregroundStyle(Color(red: 0.32, green: 0.36, blue: 0.42))
            .padding(.top, 10)

            dividerText(role == .stylist ? "或使用社交帳號登入工作台" : "或透過以下方式繼續")
            socialLoginStack(googleTitle: role == .stylist ? "髮型師使用 Google 登入" : "使用 Google 登入")

            footerLinks
        }
    }

    private var stylistRegisterContent: some View {
        VStack(spacing: 18) {
            titleBlock(
                title: "歡迎註冊新帳號",
                subtitle: "請填寫下方資料，完成您在 Hairmap 的專屬帳號"
            )

            VStack(spacing: 14) {
                authField(label: "髮型師專業暱稱（暱稱）", placeholder: "例如：Leo 老師", text: $stylistName, systemImage: "person")
                authField(label: "髮型師專業職稱", placeholder: "例如：首席名店設計師 / 漫髮專家", text: $stylistTitle, systemImage: "person")
                authField(label: "電子郵箱", placeholder: "name@example.com", text: $email, systemImage: "envelope", keyboard: .emailAddress)
                passwordField(label: "設定密碼", placeholder: "請輸入密碼（至少 6 位字元）", text: $password)
                passwordField(label: "確認密碼", placeholder: "請再次輸入密碼二次確認", text: $confirmPassword)
            }

            termsAgreementRow

            blackButton(isSubmitting ? "註冊中" : "註冊帳號並寄出確認信", disabled: !hasAcceptedTerms) {
                submitRegister(
                    role: .stylist,
                    displayName: stylistName.isEmpty ? "待建立髮型師" : stylistName,
                    email: email,
                    password: password,
                    confirmPassword: confirmPassword
                )
            }

            confirmationResendBlock(email: email)

            Button("已經有帳號？跳轉登入") {
                mode = .login
            }
            .font(.footnote.weight(.bold))
            .foregroundStyle(Color(red: 0.32, green: 0.36, blue: 0.42))
            .padding(.top, 10)
        }
    }

    private func titleBlock(title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 29, weight: .black))
                .tracking(0)
                .foregroundStyle(Color(red: 0.08, green: 0.11, blue: 0.17))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.78)

            Text(subtitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(red: 0.43, green: 0.47, blue: 0.54))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    private func authField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        systemImage: String,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(red: 0.56, green: 0.6, blue: 0.66))

            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(red: 0.58, green: 0.62, blue: 0.68))
                    .frame(width: 18)

                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HMTheme.ink)
            }
            .frame(height: 54)
            .padding(.horizontal, 14)
            .background(Color(red: 0.972, green: 0.976, blue: 0.982), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 1.1))
        }
    }

    private func passwordField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        showsForgot: Bool = false,
        forgotAction: (() -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(red: 0.56, green: 0.6, blue: 0.66))

                Spacer()

                if showsForgot {
                    Button("忘記密碼？") {
                        forgotAction?()
                    }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(red: 0.55, green: 0.32, blue: 0.1))
                        .disabled(isSubmitting)
                }
            }

            HStack(spacing: 12) {
                Image(systemName: "lock")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(red: 0.58, green: 0.62, blue: 0.68))
                    .frame(width: 18)

                Group {
                    if isPasswordVisible {
                        TextField(placeholder, text: text)
                    } else {
                        SecureField(placeholder, text: text)
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(HMTheme.ink)

                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(red: 0.58, green: 0.62, blue: 0.68))
                }
                .buttonStyle(PressableButtonStyle())
            }
            .frame(height: 54)
            .padding(.horizontal, 14)
            .background(Color(red: 0.972, green: 0.976, blue: 0.982), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 1.1))
        }
    }

    private func blackButton(_ title: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity)
                .frame(height: 68)
                .background(.black, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 12, y: 8)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isSubmitting || disabled)
        .opacity(disabled ? 0.58 : 1)
    }

    private func lightButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(Color(red: 0.2, green: 0.25, blue: 0.33))
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .background(Color(red: 0.978, green: 0.98, blue: 0.984), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.black.opacity(0.06), lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isSubmitting)
    }

    private func amberButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .font(.system(size: 15, weight: .black))
            .foregroundStyle(Color(red: 0.5, green: 0.32, blue: 0.04))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color(red: 1, green: 0.985, blue: 0.88), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.95, green: 0.82, blue: 0.34), lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isSubmitting)
    }

    private var appleSocialButton: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.email, .fullName]
        } onCompletion: { result in
            handleAppleAuthorization(result)
        }
        .signInWithAppleButtonStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.black.opacity(0.11), lineWidth: 1))
        .frame(maxWidth: .infinity)
        .accessibilityLabel("使用 Apple 登入")
        .disabled(isSubmitting || !hasAcceptedTerms)
        .opacity(hasAcceptedTerms ? 1 : 0.58)
    }

    private func socialLoginStack(googleTitle: String) -> some View {
        VStack(spacing: 12) {
            appleSocialButton
            googleSocialButton(title: googleTitle) {
                submitSocial(.google)
            }
        }
        .padding(.bottom, 4)
    }

    private func googleSocialButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "g.circle")
                    .font(.system(size: 20, weight: .bold))
                Text(title)
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(HMTheme.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.black.opacity(0.11), lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(title)
        .disabled(isSubmitting || !hasAcceptedTerms)
        .opacity(hasAcceptedTerms ? 1 : 0.58)
    }

    private func dividerText(_ text: String) -> some View {
        HStack(spacing: 14) {
            Rectangle()
                .fill(Color(red: 0.86, green: 0.88, blue: 0.91))
                .frame(height: 1)
            Text(text)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(red: 0.6, green: 0.64, blue: 0.7))
                .fixedSize(horizontal: true, vertical: false)
            Rectangle()
                .fill(Color(red: 0.86, green: 0.88, blue: 0.91))
                .frame(height: 1)
        }
    }

    private var footerLinks: some View {
        Text("繼續使用即代表您同意 Hairmap 的\n服務條款 與 隱私權政策")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color(red: 0.68, green: 0.72, blue: 0.78))
            .multilineTextAlignment(.center)
            .padding(.top, 6)
    }

    private var termsAgreementRow: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                hasAcceptedTerms.toggle()
            } label: {
                Image(systemName: hasAcceptedTerms ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(hasAcceptedTerms ? .black : Color(red: 0.48, green: 0.52, blue: 0.6))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel(hasAcceptedTerms ? "已同意服務條款" : "同意服務條款")

            VStack(alignment: .leading, spacing: 6) {
                Text("我已閱讀並同意 Hairmap 服務條款 / EULA 與隱私權政策")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(red: 0.22, green: 0.26, blue: 0.32))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Button("服務條款 / EULA") {
                        openURL(Self.termsURL)
                    }
                    Button("隱私權政策") {
                        openURL(Self.privacyURL)
                    }
                }
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(Color(red: 0.58, green: 0.34, blue: 0.06))
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.97, green: 0.975, blue: 0.985), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.black.opacity(0.1), lineWidth: 1))
    }

    @ViewBuilder
    private func confirmationResendBlock(email: String) -> some View {
        if !store.pendingConfirmationEmail.isEmpty {
            VStack(spacing: 10) {
                Text("未收到確認信？請先檢查垃圾郵件，或 60 秒後重新寄出。")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(red: 0.48, green: 0.52, blue: 0.6))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                lightButton(isSubmitting ? "寄送中" : "重新寄出確認信") {
                    submitResendConfirmation(email: email)
                }
            }
            .padding(.top, 2)
        }
    }

    @ViewBuilder
    private var statusBanner: some View {
        if shouldShowStatus && showAuthStatus {
            Text(store.statusMessage)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(red: 0.45, green: 0.31, blue: 0.05))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color(red: 1, green: 0.986, blue: 0.9), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.93, green: 0.8, blue: 0.37), lineWidth: 1))
        }
    }

    private var shouldShowStatus: Bool {
        mode == .welcome || mode == .stylistPortal || mode == .login || mode == .customerRegister || mode == .stylistRegister
    }

    private var showsBackButton: Bool {
        mode == .login || mode == .customerRegister || mode == .stylistRegister
    }

    private var heroHeight: CGFloat {
        let height = UIScreen.main.bounds.height
        return min(max(height * 0.34, 258), 306)
    }

    private var topSpacer: CGFloat {
        let height = UIScreen.main.bounds.height
        switch mode {
        case .welcome:
            return min(max(height * 0.275, 222), 254)
        case .stylistPortal:
            return min(max(height * 0.268, 218), 248)
        case .login:
            return min(max(height * 0.262, 214), 244)
        case .customerRegister, .stylistRegister:
            return min(max(height * 0.205, 164), 198)
        }
    }

    private var horizontalInset: CGFloat {
        UIScreen.main.bounds.width < 380 ? 18 : 28
    }

    private var bottomPadding: CGFloat {
        mode == .stylistRegister ? 24 : 30
    }

    private func quickStart(role: UserRole) {
        guard role == .customer else { return }
        store.startLocal(
            displayName: "訪客",
            role: role
        )
    }

    private func submitRegister(role: UserRole, displayName: String, email: String, password: String, confirmPassword: String) {
        showAuthStatus = true
        guard guardTermsAccepted() else { return }
        guard password == confirmPassword else {
            store.statusMessage = "兩次密碼不一致，請重新輸入"
            return
        }

        Task {
            isSubmitting = true
            await store.register(displayName: displayName, email: email, password: password, role: role)
            isSubmitting = false
        }
    }

    private func submitResendConfirmation(email: String) {
        showAuthStatus = true
        Task {
            isSubmitting = true
            await store.resendConfirmationEmail(email: email.isEmpty ? nil : email)
            isSubmitting = false
        }
    }

    private func submitLogin(role: UserRole, email: String, password: String) {
        showAuthStatus = true
        guard guardTermsAccepted() else { return }
        Task {
            isSubmitting = true
            await store.login(email: email, password: password, role: role)
            isSubmitting = false
        }
    }

    private func submitForgotPassword() {
        showAuthStatus = true
        Task {
            isSubmitting = true
            await store.sendPasswordReset(email: email)
            isSubmitting = false
        }
    }

    private func submitSocial(_ provider: SocialAuthProvider) {
        showAuthStatus = true
        guard guardTermsAccepted() else { return }
        Task {
            isSubmitting = true
            await store.loginWithSocial(provider, role: role)
            isSubmitting = false
        }
    }

    private func handleAppleAuthorization(_ result: Result<ASAuthorization, Error>) {
        showAuthStatus = true
        guard guardTermsAccepted() else { return }

        switch result {
        case .failure(let error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                store.statusMessage = "Apple 登入已取消"
            } else {
                store.statusMessage = "Apple 登入未能完成，請稍後再試"
            }
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                store.statusMessage = "Apple 登入憑證格式不正確"
                return
            }
            guard
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8)
            else {
                store.statusMessage = "Apple 登入未能取得身份憑證"
                return
            }

            let fullName = credential.fullName?.formatted()
                .trimmingCharacters(in: .whitespacesAndNewlines)

            Task {
                isSubmitting = true
                await store.loginWithAppleIDToken(
                    idToken,
                    fullName: fullName?.isEmpty == false ? fullName : nil,
                    role: role
                )
                isSubmitting = false
            }
        }
    }

    private func guardTermsAccepted() -> Bool {
        guard hasAcceptedTerms else {
            store.statusMessage = "請先閱讀並同意服務條款 / EULA 與隱私權政策"
            return false
        }
        return true
    }
}
