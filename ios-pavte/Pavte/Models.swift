import SwiftUI

// MARK: - User Model
struct User: Identifiable, Codable, Equatable {
    let id: UUID
    var username: String
    var displayName: String
    var bio: String
    var avatarName: String
    var avatarData: Data?
    var isOnline: Bool
    var lastSeen: Date
    var phoneNumber: String
    
    static let currentUser = User(
        id: UUID(),
        username: "@me",
        displayName: "Я",
        bio: "Мой статус",
        avatarName: "person.circle.fill",
        avatarData: nil,
        isOnline: true,
        lastSeen: Date(),
        phoneNumber: "+7 999 123-45-67"
    )
}

// MARK: - Message Model
struct Message: Identifiable, Codable, Equatable {
    let id: UUID
    let senderId: UUID
    let text: String
    let timestamp: Date
    var isRead: Bool
    var mediaType: MediaType?
    var mediaURL: String?
    var mediaData: Data?
    
    enum MediaType: String, Codable {
        case image
        case video
        case voice
        case document
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

// MARK: - Chat Model
struct Chat: Identifiable, Equatable {
    let id: UUID
    var participant: User
    var messages: [Message]
    var isPinned: Bool
    var isMuted: Bool
    var unreadCount: Int
    
    var lastMessage: Message? {
        messages.last
    }
    
    var lastMessagePreview: String {
        guard let last = lastMessage else { return "" }
        if last.mediaType != nil {
            switch last.mediaType {
            case .image: return "📷 Фото"
            case .video: return "🎬 Видео"
            case .voice: return "🎤 Голосовое"
            case .document: return "📄 Документ"
            case .none: return last.text
            }
        }
        return last.text
    }
}

// MARK: - Call Model
struct CallRecord: Identifiable {
    let id: UUID
    let participant: User
    let timestamp: Date
    let duration: TimeInterval
    let callType: CallType
    let isOutgoing: Bool
    let isMissed: Bool
    
    enum CallType {
        case voice
        case video
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(timestamp) {
            formatter.timeStyle = .short
            return formatter.string(from: timestamp)
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: timestamp)
        }
    }
}

// MARK: - Settings Models
enum ChatBubbleStyle: String, CaseIterable, Codable {
    case rounded = "Скруглённые"
    case classic = "Классические"
    case minimal = "Минималистичные"
}

enum FontSize: String, CaseIterable, Codable {
    case small = "Маленький"
    case medium = "Средний"
    case large = "Большой"
    
    var size: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        }
    }
}

// MARK: - Theme Colors
enum ThemeColor: String, CaseIterable, Codable {
    case blue = "Синий"
    case green = "Зелёный"
    case purple = "Фиолетовый"
    case orange = "Оранжевый"
    case pink = "Розовый"
    case teal = "Бирюзовый"
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        case .pink: return .pink
        case .teal: return .teal
        }
    }
}
