import SwiftUI
import Combine

@MainActor
class ThemeManager: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    @AppStorage("themeColorRaw") private var themeColorRaw: String = ThemeColor.blue.rawValue
    @AppStorage("bubbleStyleRaw") private var bubbleStyleRaw: String = ChatBubbleStyle.rounded.rawValue
    @AppStorage("fontSizeRaw") private var fontSizeRaw: String = FontSize.medium.rawValue
    @AppStorage("showOnlineStatus") var showOnlineStatus: Bool = true
    @AppStorage("showReadReceipts") var showReadReceipts: Bool = true
    @AppStorage("enableNotifications") var enableNotifications: Bool = true
    @AppStorage("enableSounds") var enableSounds: Bool = true
    @AppStorage("enableVibration") var enableVibration: Bool = true
    @AppStorage("chatWallpaper") var chatWallpaper: String = "default"
    @AppStorage("selectedWallpaperIndex") var selectedWallpaperIndex: Int = 0
    
    // Multiple custom wallpapers (stored in UserDefaults as base64-encoded array)
    @AppStorage("customWallpapersData") var customWallpapersDataBase64: String = ""
    
    // Legacy single custom wallpaper
    @AppStorage("customWallpaperData") var customWallpaperDataBase64: String = ""
    
    var customWallpapers: [Data] {
        get {
            guard !customWallpapersDataBase64.isEmpty else { return [] }
            guard let combinedData = Data(base64Encoded: customWallpapersDataBase64) else { return [] }
            do {
                return try JSONDecoder().decode([Data].self, from: combinedData)
            } catch {
                return []
            }
        }
        set {
            do {
                let encoded = try JSONEncoder().encode(newValue)
                customWallpapersDataBase64 = encoded.base64EncodedString()
            } catch {
                customWallpapersDataBase64 = ""
            }
            objectWillChange.send()
        }
    }
    
    // Legacy single wallpaper support
    var customWallpaperData: Data? {
        get {
            guard !customWallpaperDataBase64.isEmpty else { return nil }
            return Data(base64Encoded: customWallpaperDataBase64)
        }
        set {
            if let data = newValue {
                customWallpaperDataBase64 = data.base64EncodedString()
            } else {
                customWallpaperDataBase64 = ""
            }
            objectWillChange.send()
        }
    }
    
    func addCustomWallpaper(_ data: Data) {
        var wallpapers = customWallpapers
        wallpapers.insert(data, at: 0)
        customWallpapers = wallpapers
        // Auto-select the newly added wallpaper
        selectedWallpaperIndex = 1 // first custom = index 1 (0 = default)
    }
    
    func removeCustomWallpaper(at index: Int) {
        var wallpapers = customWallpapers
        guard index >= 0 && index < wallpapers.count else { return }
        let removedIndex = index + 1 // offset by 1 (0 = default)
        wallpapers.remove(at: index)
        customWallpapers = wallpapers
        // Adjust selection if needed
        if selectedWallpaperIndex == removedIndex {
            selectedWallpaperIndex = 0
        } else if selectedWallpaperIndex > removedIndex {
            selectedWallpaperIndex -= 1
        }
    }
    
    func removeAllCustomWallpapers() {
        customWallpapers = []
        if selectedWallpaperIndex > 0 {
            selectedWallpaperIndex = 0
        }
    }
    
    var themeColor: ThemeColor {
        get { ThemeColor(rawValue: themeColorRaw) ?? .blue }
        set { themeColorRaw = newValue.rawValue; objectWillChange.send() }
    }
    
    var bubbleStyle: ChatBubbleStyle {
        get { ChatBubbleStyle(rawValue: bubbleStyleRaw) ?? .rounded }
        set { bubbleStyleRaw = newValue.rawValue; objectWillChange.send() }
    }
    
    var fontSize: FontSize {
        get { FontSize(rawValue: fontSizeRaw) ?? .medium }
        set { fontSizeRaw = newValue.rawValue; objectWillChange.send() }
    }
    
    var accentColor: Color {
        themeColor.color
    }
    
    var outgoingBubbleColor: Color {
        themeColor.color.opacity(0.9)
    }
    
    var incomingBubbleColor: Color {
        isDarkMode ? Color(.systemGray5) : Color(.systemGray6)
    }
    
    var backgroundColor: Color {
        isDarkMode ? Color(.systemBackground) : Color(.systemGroupedBackground)
    }
    
    var bubbleCornerRadius: CGFloat {
        switch bubbleStyle {
        case .rounded: return 20
        case .classic: return 12
        case .minimal: return 8
        }
    }
    
    static let wallpapers = ["default", "gradient1", "gradient2", "gradient3", "pattern1", "pattern2", "custom"]
    
    func wallpaperView() -> some View {
        Group {
            if selectedWallpaperIndex > 0 {
                // Custom wallpaper (index - 1 = position in customWallpapers array)
                let customIndex = selectedWallpaperIndex - 1
                let wallpapers = customWallpapers
                if customIndex < wallpapers.count,
                   let uiImage = UIImage(data: wallpapers[customIndex]) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                        .opacity(0.4)
                } else {
                    Color(.systemGroupedBackground)
                }
            } else if chatWallpaper == "custom", let data = customWallpaperData,
               let uiImage = UIImage(data: data) {
                // Legacy single custom wallpaper fallback
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .opacity(0.4)
            } else {
                switch chatWallpaper {
                case "gradient1":
                    LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                case "gradient2":
                    LinearGradient(colors: [.green.opacity(0.3), .teal.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                case "gradient3":
                    LinearGradient(colors: [.orange.opacity(0.3), .pink.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                case "pattern1":
                    Color(.systemGray6).overlay(
                        GeometryReader { geo in
                            Path { path in
                                let size: CGFloat = 30
                                for x in stride(from: 0, to: geo.size.width, by: size) {
                                    for y in stride(from: 0, to: geo.size.height, by: size) {
                                        path.addEllipse(in: CGRect(x: x, y: y, width: 4, height: 4))
                                    }
                                }
                            }
                            .fill(Color.gray.opacity(0.2))
                        }
                    )
                case "pattern2":
                    Color(.systemGray6).overlay(
                        GeometryReader { geo in
                            Path { path in
                                for x in stride(from: 0, to: geo.size.width, by: 40) {
                                    path.move(to: CGPoint(x: x, y: 0))
                                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                                }
                            }
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        }
                    )
                default:
                    Color(.systemGroupedBackground)
                }
            }
        }
    }
}
