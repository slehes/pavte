import SwiftUI
import Combine
import AVKit

// MARK: - Wallpaper Item Model
struct WallpaperItem: Identifiable, Equatable {
    let id: UUID
    var name: String
    var imageData: Data?
    var videoData: Data?
    var isBuiltIn: Bool
    var builtInId: String?
    
    var isVideo: Bool { videoData != nil }
    
    static func builtIn(id: String, name: String) -> WallpaperItem {
        WallpaperItem(id: UUID(), name: name, imageData: nil, videoData: nil, isBuiltIn: true, builtInId: id)
    }
    
    static func customPhoto(id: UUID = UUID(), name: String, imageData: Data) -> WallpaperItem {
        WallpaperItem(id: id, name: name, imageData: imageData, videoData: nil, isBuiltIn: false, builtInId: nil)
    }
    
    static func customVideo(id: UUID = UUID(), name: String, videoData: Data) -> WallpaperItem {
        WallpaperItem(id: id, name: name, imageData: nil, videoData: videoData, isBuiltIn: false, builtInId: nil)
    }
}

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
    
    // Selected wallpaper ID
    @AppStorage("selectedWallpaperId") var selectedWallpaperId: String = ""
    
    // Custom wallpapers stored as base64 JSON array
    @AppStorage("customWallpapersJSON") var customWallpapersJSON: String = ""
    
    // All wallpapers (built-in + custom)
    @Published var wallpapers: [WallpaperItem] = []
    
    // The currently active wallpaper
    var selectedWallpaper: WallpaperItem? {
        guard !selectedWallpaperId.isEmpty, let uuid = UUID(uuidString: selectedWallpaperId) else { return nil }
        return wallpapers.first { $0.id == uuid }
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
    
    init() {
        loadWallpapers()
    }
    
    // MARK: - Wallpaper Management
    
    private func loadWallpapers() {
        // Built-in wallpapers
        let builtIn: [WallpaperItem] = [
            .builtIn(id: "default", name: "По умолчанию"),
            .builtIn(id: "gradient1", name: "Градиент синий"),
            .builtIn(id: "gradient2", name: "Градиент зелёный"),
            .builtIn(id: "gradient3", name: "Градиент розовый"),
            .builtIn(id: "pattern1", name: "Точки"),
            .builtIn(id: "pattern2", name: "Линии"),
        ]
        
        // Load custom wallpapers from JSON
        var customs: [WallpaperItem] = []
        if !customWallpapersJSON.isEmpty,
           let data = customWallpapersJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([WallpaperItemData].self, from: data) {
            for item in decoded {
                if let videoData = item.videoData {
                    customs.append(.customVideo(id: item.id, name: item.name, videoData: videoData))
                } else if let imageData = item.imageData {
                    customs.append(.customPhoto(id: item.id, name: item.name, imageData: imageData))
                }
            }
        }
        
        // Custom wallpapers first, then built-in
        wallpapers = customs + builtIn
    }
    
    private func saveCustomWallpapers() {
        let customs = wallpapers.filter { !$0.isBuiltIn }
        let items = customs.map { item -> WallpaperItemData in
            WallpaperItemData(
                id: item.id,
                name: item.name,
                imageData: item.imageData,
                videoData: item.videoData
            )
        }
        if let data = try? JSONEncoder().encode(items),
           let json = String(data: data, encoding: .utf8) {
            customWallpapersJSON = json
        }
    }
    
    func addCustomWallpaper(name: String, imageData: Data?) {
        let item = WallpaperItem.customPhoto(name: name, imageData: imageData ?? Data())
        wallpapers.insert(item, at: 0) // Custom wallpapers go first
        saveCustomWallpapers()
        objectWillChange.send()
    }
    
    func addCustomVideoWallpaper(name: String, videoData: Data) {
        let item = WallpaperItem.customVideo(name: name, videoData: videoData)
        wallpapers.insert(item, at: 0) // Custom wallpapers go first
        saveCustomWallpapers()
        objectWillChange.send()
    }
    
    func deleteWallpaper(at indexSet: IndexSet) {
        for index in indexSet {
            let item = wallpapers[index]
            if !item.isBuiltIn {
                // If deleting selected wallpaper, reset to default
                if selectedWallpaperId == item.id.uuidString {
                    selectedWallpaperId = ""
                }
                wallpapers.remove(at: index)
                break
            }
        }
        saveCustomWallpapers()
        objectWillChange.send()
    }
    
    func selectWallpaper(_ item: WallpaperItem?) {
        selectedWallpaperId = item?.id.uuidString ?? ""
        objectWillChange.send()
    }
    
    // MARK: - Wallpaper View (used in chat AND globally)
    
    @ViewBuilder
    func wallpaperView() -> some View {
        if let selected = selectedWallpaper {
            if let videoData = selected.videoData {
                // Video wallpaper
                VideoWallpaperView(videoData: videoData)
            } else if let imageData = selected.imageData,
                      let uiImage = UIImage(data: imageData) {
                // Custom photo wallpaper
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .opacity(0.4)
            } else if let builtInId = selected.builtInId {
                // Built-in wallpaper
                builtInWallpaperView(builtInId)
            }
        } else {
            Color(.systemGroupedBackground)
        }
    }
    
    @ViewBuilder
    private func builtInWallpaperView(_ id: String) -> some View {
        switch id {
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

// MARK: - Codable helper for custom wallpaper persistence
struct WallpaperItemData: Codable {
    let id: UUID
    let name: String
    let imageData: Data?
    let videoData: Data?
}

// MARK: - Video Wallpaper View
struct VideoWallpaperView: View {
    let videoData: Data
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
            if let player = player {
                VideoPlayer(player: player)
                    .disabled(true)
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
            } else {
                Color(.systemGroupedBackground)
                    .onAppear { setupPlayer() }
            }
        }
        .opacity(0.4)
        .ignoresSafeArea()
    }
    
    private func setupPlayer() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("wallpaper_\(UUID().uuidString).mp4")
        do {
            try videoData.write(to: tempURL)
            let newPlayer = AVPlayer(url: tempURL)
            newPlayer.actionAtItemEnd = .none
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: newPlayer.currentItem, queue: .main) { _ in
                newPlayer.seek(to: .zero)
                newPlayer.play()
            }
            player = newPlayer
        } catch { }
    }
}
