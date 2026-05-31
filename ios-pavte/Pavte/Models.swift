import SwiftUI

// MARK: - User Model
struct User: Identifiable, Codable, Equatable {
    let id: UUID
    var username: String
    var displayName: String
    var bio: String
    var avatarName: String
    var avatarData: Data? = nil
    var isOnline: Bool
    var lastSeen: Date
    var phoneNumber: String
    // Video background around avatar
    var avatarVideoBackgroundData: Data? = nil
    
    static let currentUser = User(
        id: UUID(),
        username: "@me",
        displayName: "Я",
        bio: "Мой статус",
        avatarName: "person.circle.fill",
        avatarData: nil,
        isOnline: true,
        lastSeen: Date(),
        phoneNumber: "+7 999 123-45-67",
        avatarVideoBackgroundData: nil
    )
}

// MARK: - Message Model
struct Message: Identifiable, Codable, Equatable {
    let id: UUID
    let senderId: UUID
    var text: String
    let timestamp: Date
    var isRead: Bool
    var mediaType: MediaType?
    var mediaURL: String?
    var mediaData: Data?
    // Editing
    var isEdited: Bool
    var originalText: String?
    // Deletion
    var isDeletedForMe: Bool          // deleted only for current user
    var isDeletedForEveryone: Bool    // deleted for all — anonymous, message disappears
    // Pinning
    var isPinned: Bool
    
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
    
    // Convenience init for new messages
    init(id: UUID = UUID(), senderId: UUID, text: String, timestamp: Date = Date(), isRead: Bool = false, mediaType: MediaType? = nil, mediaURL: String? = nil, mediaData: Data? = nil, isEdited: Bool = false, originalText: String? = nil, isDeletedForMe: Bool = false, isDeletedForEveryone: Bool = false, isPinned: Bool = false) {
        self.id = id
        self.senderId = senderId
        self.text = text
        self.timestamp = timestamp
        self.isRead = isRead
        self.mediaType = mediaType
        self.mediaURL = mediaURL
        self.mediaData = mediaData
        self.isEdited = isEdited
        self.originalText = originalText
        self.isDeletedForMe = isDeletedForMe
        self.isDeletedForEveryone = isDeletedForEveryone
        self.isPinned = isPinned
    }
}

// MARK: - Chat Type
enum ChatType: String, Codable {
    case personal
    case group
    case channel
}

// MARK: - Group/Channel Member Role
enum MemberRole: String, Codable {
    case owner
    case admin
    case member
}

// MARK: - Group Member
struct GroupMember: Identifiable, Codable, Equatable {
    let id: UUID
    var user: User
    var role: MemberRole
    var joinedAt: Date
    
    var roleLabel: String {
        switch role {
        case .owner: return "Владелец"
        case .admin: return "Админ"
        case .member: return "Участник"
        }
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
    
    // Group / Channel fields
    var chatType: ChatType
    var groupName: String?
    var groupAvatarData: Data?
    var groupDescription: String?
    var members: [GroupMember]
    var inviteLink: String?
    var isPublic: Bool
    var allowReactions: Bool
    var allowMembersToInvite: Bool
    var allowMembersToEditInfo: Bool
    var allowMembersToPinMessages: Bool
    var historyVisibleToNewMembers: Bool
    var slowMode: Bool
    
    // Convenience
    var displayName: String {
        switch chatType {
        case .personal: return participant.displayName
        case .group: return groupName ?? participant.displayName
        case .channel: return groupName ?? participant.displayName
        }
    }
    
    var displayAvatar: String {
        switch chatType {
        case .personal: return participant.avatarName
        case .group: return "person.3.fill"
        case .channel: return "megaphone.fill"
        }
    }
    
    var displayAvatarData: Data? {
        switch chatType {
        case .personal: return participant.avatarData
        case .group: return groupAvatarData
        case .channel: return groupAvatarData
        }
    }
    
    var lastMessage: Message? {
        messages.last { !$0.isDeletedForMe && !$0.isDeletedForEveryone }
    }
    
    var lastMessagePreview: String {
        guard let last = lastMessage else { return "" }
        if last.isDeletedForMe || last.isDeletedForEveryone { return "" }
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
    
    // Pinned messages
    var pinnedMessages: [Message] {
        messages.filter { $0.isPinned && !$0.isDeletedForMe && !$0.isDeletedForEveryone }
    }
    
    // Default init for personal chats
    init(id: UUID = UUID(), participant: User, messages: [Message], isPinned: Bool, isMuted: Bool, unreadCount: Int) {
        self.id = id
        self.participant = participant
        self.messages = messages
        self.isPinned = isPinned
        self.isMuted = isMuted
        self.unreadCount = unreadCount
        self.chatType = .personal
        self.groupName = nil
        self.groupAvatarData = nil
        self.groupDescription = nil
        self.members = []
        self.inviteLink = nil
        self.isPublic = false
        self.allowReactions = true
        self.allowMembersToInvite = true
        self.allowMembersToEditInfo = false
        self.allowMembersToPinMessages = false
        self.historyVisibleToNewMembers = true
        self.slowMode = false
    }
    
    // Group init
    static func createGroup(id: UUID = UUID(), name: String, avatarData: Data?, description: String?, owner: User, members: [User]) -> Chat {
        let groupUser = User(
            id: UUID(),
            username: "@group_\(UUID().uuidString.prefix(8))",
            displayName: name,
            bio: description ?? "",
            avatarName: "person.3.fill",
            avatarData: avatarData,
            isOnline: false,
            lastSeen: Date(),
            phoneNumber: "",
            avatarVideoBackgroundData: nil
        )
        
        var groupMembers: [GroupMember] = [
            GroupMember(id: owner.id, user: owner, role: .owner, joinedAt: Date())
        ]
        for member in members {
            groupMembers.append(GroupMember(id: member.id, user: member, role: .member, joinedAt: Date()))
        }
        
        var chat = Chat(id: id, participant: groupUser, messages: [], isPinned: false, isMuted: false, unreadCount: 0)
        chat.chatType = .group
        chat.groupName = name
        chat.groupAvatarData = avatarData
        chat.groupDescription = description
        chat.members = groupMembers
        chat.inviteLink = "https://t.me/join/\(UUID().uuidString.prefix(10))"
        chat.isPublic = false
        chat.allowReactions = true
        chat.allowMembersToInvite = true
        chat.allowMembersToEditInfo = false
        chat.allowMembersToPinMessages = false
        chat.historyVisibleToNewMembers = true
        chat.slowMode = false
        return chat
    }
    
    // Channel init
    static func createChannel(id: UUID = UUID(), name: String, avatarData: Data?, description: String?, owner: User) -> Chat {
        let channelUser = User(
            id: UUID(),
            username: "@channel_\(UUID().uuidString.prefix(8))",
            displayName: name,
            bio: description ?? "",
            avatarName: "megaphone.fill",
            avatarData: avatarData,
            isOnline: false,
            lastSeen: Date(),
            phoneNumber: "",
            avatarVideoBackgroundData: nil
        )
        
        var chat = Chat(id: id, participant: channelUser, messages: [], isPinned: false, isMuted: false, unreadCount: 0)
        chat.chatType = .channel
        chat.groupName = name
        chat.groupAvatarData = avatarData
        chat.groupDescription = description
        chat.members = [GroupMember(id: owner.id, user: owner, role: .owner, joinedAt: Date())]
        chat.inviteLink = "https://t.me/join/\(UUID().uuidString.prefix(10))"
        chat.isPublic = true
        chat.allowReactions = true
        chat.allowMembersToInvite = false
        chat.allowMembersToEditInfo = false
        chat.allowMembersToPinMessages = false
        chat.historyVisibleToNewMembers = true
        chat.slowMode = false
        return chat
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

// MARK: - Passcode / 2FA / Active Sessions Models

// MARK: - Read Receipt State
enum ReadReceiptState {
    case sent    // 2 gray checkmarks
    case read    // 1 blue checkmark
    case typing  // 2 blue checkmarks
    
    static func forMessage(_ message: Message, isOutgoing: Bool, isContactTyping: Bool) -> ReadReceiptState {
        guard isOutgoing else { return .sent }
        if isContactTyping { return .typing }
        if message.isRead { return .read }
        return .sent
    }
}

struct ActiveSession: Identifiable, Codable, Equatable {
    let id: UUID
    var deviceName: String
    var deviceModel: String
    var platform: String
    var appVersion: String
    var lastActiveDate: Date
    var ipAddress: String
    var location: String
    var isCurrent: Bool
    
    @MainActor
    static func currentSession(appVersion: String) -> ActiveSession {
        ActiveSession(
            id: UUID(),
            deviceName: UIDevice.current.name,
            deviceModel: UIDevice.current.model,
            platform: "iOS \(UIDevice.current.systemVersion)",
            appVersion: appVersion,
            lastActiveDate: Date(),
            ipAddress: "192.168.1.\(Int.random(in: 1...254))",
            location: "Москва, Россия",
            isCurrent: true
        )
    }
    
    @MainActor
    static func mockSessions(appVersion: String) -> [ActiveSession] {
        [
            currentSession(appVersion: appVersion),
            ActiveSession(
                id: UUID(),
                deviceName: "iPhone",
                deviceModel: "iPhone 15 Pro",
                platform: "iOS 18.0",
                appVersion: appVersion,
                lastActiveDate: Date().addingTimeInterval(-3600),
                ipAddress: "10.0.0.\(Int.random(in: 1...254))",
                location: "Санкт-Петербург, Россия",
                isCurrent: false
            ),
            ActiveSession(
                id: UUID(),
                deviceName: "iPad",
                deviceModel: "iPad Air",
                platform: "iPadOS 18.0",
                appVersion: appVersion,
                lastActiveDate: Date().addingTimeInterval(-86400),
                ipAddress: "172.16.0.\(Int.random(in: 1...254))",
                location: "Казань, Россия",
                isCurrent: false
            )
        ]
    }
}

// MARK: - Notification Banner Model
struct NotificationBanner: Identifiable, Equatable {
    let id = UUID()
    let senderName: String
    let messageText: String
    let chatId: UUID
    let timestamp: Date = Date()
    
    static func == (lhs: NotificationBanner, rhs: NotificationBanner) -> Bool {
        lhs.id == rhs.id
    }
}
