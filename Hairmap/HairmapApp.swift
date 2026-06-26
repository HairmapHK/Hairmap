import SwiftUI
import UIKit
import UserNotifications

final class HairmapAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}

@main
struct HairmapApp: App {
    @UIApplicationDelegateAdaptor(HairmapAppDelegate.self) private var appDelegate
    @State private var store = HairmapStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .task {
                    await store.bootstrap()
                }
                .onOpenURL { url in
                    store.handleDeepLink(url)
                }
        }
    }
}

struct RootView: View {
    @Environment(HairmapStore.self) private var store

    var body: some View {
        @Bindable var store = store

        Group {
            if store.isBootstrapping {
                HairmapLaunchLoadingView()
                    .transition(.opacity)
            } else if let profile = store.currentProfile {
                switch profile.role {
                case .customer:
                    CustomerShellView()
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                case .stylist:
                    StylistDashboardView(stylistID: store.currentStylistDashboardID)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            } else {
                OnboardingView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.snappy(duration: 0.32), value: store.currentProfile?.role)
        .animation(.snappy(duration: 0.28), value: store.isBootstrapping)
        .preferredColorScheme(.light)
        .sheet(isPresented: $store.isPasswordResetSheetPresented) {
            PasswordResetSheet()
                .presentationDetents([.height(430)])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct HairmapLaunchLoadingView: View {
    var body: some View {
        ZStack {
            Color(red: 0.985, green: 0.985, blue: 0.98)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Hairmap")
                    .font(.system(size: 42, weight: .black, design: .serif))
                    .foregroundStyle(.black)

                ProgressView()
                    .tint(.black)

                Text("同步最新資料...")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct PasswordResetSheet: View {
    @Environment(HairmapStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var isSubmitting = false

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.black.opacity(0.12))
                .frame(width: 44, height: 4)
                .padding(.top, 8)

            VStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color(red: 0.76, green: 0.5, blue: 0.04))
                    .frame(width: 58, height: 58)
                    .background(Color(red: 1, green: 0.96, blue: 0.78), in: Circle())

                Text("設定新的登入密碼")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(HMTheme.ink)

                Text("請輸入新密碼。完成後您可以用新密碼登入 Hairmap。")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            VStack(spacing: 12) {
                resetPasswordField("新密碼", text: $password)
                resetPasswordField("再次輸入新密碼", text: $confirmPassword)
            }

            Text(store.statusMessage)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(red: 0.45, green: 0.31, blue: 0.05))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .padding(.horizontal, 12)
                .background(Color(red: 1, green: 0.986, blue: 0.9), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.93, green: 0.8, blue: 0.37), lineWidth: 1))

            HStack(spacing: 12) {
                Button {
                    store.isPasswordResetSheetPresented = false
                    dismiss()
                } label: {
                    Text("稍後")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(HMTheme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.black.opacity(0.16), lineWidth: 1))
                }
                .buttonStyle(PressableButtonStyle())

                Button {
                    Task {
                        isSubmitting = true
                        await store.completePasswordReset(password: password, confirmPassword: confirmPassword)
                        isSubmitting = false
                    }
                } label: {
                    Text(isSubmitting ? "更新中" : "確認更新密碼")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(.black, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(isSubmitting)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 22)
        .preferredColorScheme(.light)
    }

    private func resetPasswordField(_ placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .font(.system(size: 15, weight: .semibold))
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
            .font(.system(size: 15, weight: .semibold))
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
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 1.05))
    }
}

struct CustomerShellView: View {
    @Environment(HairmapStore.self) private var store

    var body: some View {
        @Bindable var store = store

        NavigationStack(path: $store.customerPath) {
            TabView(selection: $store.selectedTab) {
                DiscoveryView()
                    .tabItem { Label(CustomerTab.discovery.title, systemImage: CustomerTab.discovery.symbol) }
                    .tag(CustomerTab.discovery)

                InspirationView()
                    .tabItem { Label(CustomerTab.inspiration.title, systemImage: CustomerTab.inspiration.symbol) }
                    .tag(CustomerTab.inspiration)

                BookingView()
                    .tabItem { Label(CustomerTab.booking.title, systemImage: CustomerTab.booking.symbol) }
                    .tag(CustomerTab.booking)

                ChatView()
                    .tabItem { Label(CustomerTab.chat.title, systemImage: CustomerTab.chat.symbol) }
                    .badge(store.customerUnreadMessageCount)
                    .tag(CustomerTab.chat)

                UserProfileView()
                    .tabItem { Label(CustomerTab.profile.title, systemImage: CustomerTab.profile.symbol) }
                    .tag(CustomerTab.profile)
            }
            .tint(HMTheme.ink)
            .preferredColorScheme(.light)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: CustomerRoute.self) { route in
                switch route {
                case .stylist(let id):
                    StylistProfileView(stylistID: id)
                case .salon(let id):
                    SalonProfileView(salonID: id)
                }
            }
        }
    }
}
