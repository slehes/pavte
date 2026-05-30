import SwiftUI
import Combine

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
    
    static let wallpapers = ["default", "gradient1", "gradient2", "gradient3", "pattern1", "pattern2"]
    
    func wallpaperView() -> some View {
        Group {
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
