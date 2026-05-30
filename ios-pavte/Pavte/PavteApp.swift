import SwiftUI

@main
struct PavteApp: App {
    @StateObject private var appState: AppState = AppState()
    @StateObject private var themeManager: ThemeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        }
    }
}
