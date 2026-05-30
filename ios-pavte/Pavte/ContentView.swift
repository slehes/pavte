import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0
    
    var body: some View {
        if appState.isLoggedIn {
            mainAppView
        } else {
            WelcomeView()
        }
    }
    
    private var mainAppView: some View {
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
        .background(PavteBackground().ignoresSafeArea())
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
                // Background gradient
                LinearGradient(
                    colors: [themeManager.accentColor.opacity(0.3), Color(.systemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Logo
                    VStack(spacing: 12) {
                        Image(systemName: "message.circle.fill")
                            .font(.system(size: 90))
                            .foregroundStyle(themeManager.accentColor)
                        
                        Text("Pavte")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                        
                        Text("Быстрый и безопасный мессенджер")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                    
                    // Buttons
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
                    
                    // Predefined account hint
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
