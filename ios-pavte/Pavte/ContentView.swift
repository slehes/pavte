import SwiftUI
import PhotosUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var navigateToChatId: UUID? = nil
    
    var body: some View {
        if !appState.isPasscodeUnlocked && appState.isPasscodeRequired {
            PasscodeLockView()
        } else if appState.isLoggedIn {
            if hasCompletedOnboarding {
                mainAppView
            } else {
                OnboardingView(onComplete: {
                    withAnimation {
                        hasCompletedOnboarding = true
                    }
                })
            }
        } else {
            WelcomeView()
        }
    }
    
    private var mainAppView: some View {
        ZStack {
            themeManager.wallpaperView().ignoresSafeArea()
            TabView(selection: $selectedTab) {
                ChatsListView()
                    .tabItem {
                        Label("Чаты", systemImage: "message.fill")
                    }
                    .tag(0)
                
                ContactsView()
                    .tabItem {
                        Label("Контакты", systemImage: "person.2.fill")
                    }
                    .tag(1)
                
                CallsView()
                    .tabItem {
                        Label("Звонки", systemImage: "phone.fill")
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        Label("Настройки", systemImage: "gearshape.fill")
                    }
                    .tag(3)
            }
            .tint(themeManager.accentColor)
            
            // Incoming message notification banner
            if let banner = appState.notificationBanner {
                NotificationBannerView(banner: banner) {
                    navigateToChatId = banner.chatId
                    appState.dismissNotificationBanner()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appState.notificationBanner != nil)
            }
        }
    }
}

// MARK: - Passcode Lock View
struct PasscodeLockView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var passcode = ""
    @State private var showError = false
    @State private var shakeOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [themeManager.accentColor.opacity(0.3), Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: themeManager.accentColor.opacity(0.3), radius: 12, x: 0, y: 4)
                
                Text("Pavte")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                
                Text("Введите код-пароль")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Passcode dots
                HStack(spacing: 16) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index < passcode.count ? themeManager.accentColor : Color.clear)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(themeManager.accentColor, lineWidth: 2)
                            )
                    }
                }
                .offset(x: shakeOffset)
                .animation(.default, value: shakeOffset)
                
                if showError {
                    Text("Неверный код")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
                Spacer()
                
                // Number pad
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    ForEach(1...9, id: \.self) { number in
                        numberButton("\(number)")
                    }
                    // Empty
                    Color.clear.frame(height: 60)
                    numberButton("0")
                    // Delete
                    Button {
                        if !passcode.isEmpty {
                            passcode.removeLast()
                        }
                    } label: {
                        Image(systemName: "delete.left.fill")
                            .font(.title2)
                            .foregroundStyle(.primary)
                            .frame(width: 60, height: 60)
                    }
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 32)
            }
        }
    }
    
    private func numberButton(_ number: String) -> some View {
        Button {
            if passcode.count < 4 {
                passcode.append(number)
                if passcode.count == 4 {
                    verifyPasscode()
                }
            }
        } label: {
            Text(number)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 60, height: 60)
                .background(Circle().fill(Color(.systemGray5)))
        }
    }
    
    private func verifyPasscode() {
        if appState.verifyPasscode(passcode) {
            showError = false
        } else {
            showError = true
            shakeOffset = 20
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                shakeOffset = -20
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                shakeOffset = 0
            }
            passcode = ""
        }
    }
}

// MARK: - Notification Banner View
struct NotificationBannerView: View {
    let banner: NotificationBanner
    let onTap: () -> Void
    @EnvironmentObject var appState: AppState
    @State private var offset: CGFloat = 0
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(banner.senderName.prefix(1)).uppercased())
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.blue)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(banner.senderName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(banner.messageText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
            )
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Welcome / Auth Screen
struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showLogin = false
    @State private var showRegister = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [themeManager.accentColor.opacity(0.3), Color(.systemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Logo + Name
                    VStack(spacing: 12) {
                        Image("icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .shadow(color: themeManager.accentColor.opacity(0.3), radius: 12, x: 0, y: 4)
                        
                        Text("Pavte")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                        
                        Text("Быстрый и безопасный мессенджер")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 14) {
                        Button {
                            showLogin = true
                        } label: {
                            Text("Войти")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(themeManager.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        Button {
                            showRegister = true
                        } label: {
                            Text("Зарегистрироваться")
                                .font(.headline)
                                .foregroundStyle(themeManager.accentColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    VStack(spacing: 4) {
                        Text("Тестовые аккаунты:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("slehes / 12345678")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text("faxter / 12345678")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.bottom, 24)
                }
            }
            .sheet(isPresented: $showLogin) {
                LoginView(onDismiss: { })
            }
            .sheet(isPresented: $showRegister) {
                RegisterView(onDismiss: { })
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(ThemeManager())
}
