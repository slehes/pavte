import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var currentUser: User
    @Published var contacts: [User]
    @Published var chats: [Chat]
    @Published var callHistory: [CallRecord]
    private var autoChatTimer: Timer?
    
    init() {
        // Initialize current user with simplified default name/number
        let currentUserId = UUID()
        self.currentUser = User(
            id: currentUserId,
            username: "@myusername",
            displayName: "Имя",
            bio: "Люблю программировать 💻",
            avatarName: "person.circle.fill",
            isOnline: true,
            lastSeen: Date(),
            phoneNumber: "номер можно изменить"
        )

        // Clear contacts and call history per request
        self.contacts = []

        // Create a single auto-chat "Избранное"
        let favoriteUser = User(
            id: UUID(),
            username: "@favorites",
            displayName: "Избранное",
            bio: "Авто-чат",
            avatarName: "star.fill",
            isOnline: true,
            lastSeen: Date(),
            phoneNumber: ""
        )

        let favoriteChatId = UUID()
        let initialMessages = [
            Message(id: UUID(), senderId: favoriteUser.id, text: "Привет! Я чат Избранное.", timestamp: Date().addingTimeInterval(-60), isRead: true),
            Message(id: UUID(), senderId: currentUserId, text: "Тестовый ответ", timestamp: Date().addingTimeInterval(-30), isRead: true)
        ]

        let favoriteChat = Chat(id: favoriteChatId, participant: favoriteUser, messages: initialMessages, isPinned: false, isMuted: false, unreadCount: 0)

        self.chats = [favoriteChat]

        // Clear call history
        self.callHistory = []

        // Start a timer to append automated incoming messages to the "Избранное" чат
        self.autoChatTimer = Timer.scheduledTimer(withTimeInterval: 12, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard let idx = self.chats.firstIndex(where: { $0.id == favoriteChatId }) else { return }
            let replies = [
                "Напоминание: проверить заметки",
                "Авто-уведомление: всё в порядке",
                "Тестовое сообщение от Избранного"
            ]
            let msg = Message(id: UUID(), senderId: favoriteUser.id, text: replies.randomElement() ?? "Пинг", timestamp: Date(), isRead: false)
            DispatchQueue.main.async {
                self.chats[idx].messages.append(msg)
                self.chats[idx].unreadCount += 1
            }
        }
    }
    
    // MARK: - Methods
    func sendMessage(to chatId: UUID, text: String, mediaType: Message.MediaType? = nil, mediaData: Data? = nil) {
        guard let index = chats.firstIndex(where: { $0.id == chatId }) else { return }
        
        let newMessage = Message(
            id: UUID(),
            senderId: currentUser.id,
            text: text,
            timestamp: Date(),
            isRead: false,
            mediaType: mediaType,
            mediaURL: nil,
            mediaData: mediaData
        )
        
        chats[index].messages.append(newMessage)
    }
    
    func markAsRead(chatId: UUID) {
        guard let index = chats.firstIndex(where: { $0.id == chatId }) else { return }
        chats[index].unreadCount = 0
        for i in 0..<chats[index].messages.count {
            chats[index].messages[i].isRead = true
        }
    }
    
    func togglePin(chatId: UUID) {
        guard let index = chats.firstIndex(where: { $0.id == chatId }) else { return }
        chats[index].isPinned.toggle()
    }
    
    func toggleMute(chatId: UUID) {
        guard let index = chats.firstIndex(where: { $0.id == chatId }) else { return }
        chats[index].isMuted.toggle()
    }
    
    func updateProfile(displayName: String, bio: String, username: String) {
        currentUser.displayName = displayName
        currentUser.bio = bio
        currentUser.username = username
    }
    
    func addCallRecord(participant: User, callType: CallRecord.CallType, isOutgoing: Bool, duration: TimeInterval, isMissed: Bool) {
        let record = CallRecord(
            id: UUID(),
            participant: participant,
            timestamp: Date(),
            duration: duration,
            callType: callType,
            isOutgoing: isOutgoing,
            isMissed: isMissed
        )
        callHistory.insert(record, at: 0)
    }
    
    func getOrCreateChat(with user: User) -> Chat {
        if let existingChat = chats.first(where: { $0.participant.id == user.id }) {
            return existingChat
        }
        
        let newChat = Chat(
            id: UUID(),
            participant: user,
            messages: [],
            isPinned: false,
            isMuted: false,
            unreadCount: 0
        )
        chats.append(newChat)
        return newChat
    }
}
