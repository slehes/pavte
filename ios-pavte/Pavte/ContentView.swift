import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0
    
    var body: some View {
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

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(ThemeManager())
}
