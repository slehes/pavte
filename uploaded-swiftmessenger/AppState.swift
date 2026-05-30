import SwiftUI

class AppState: ObservableObject {
    @Published var currentUser: User
    @Published var contacts: [User]
    @Published var chats: [Chat]
    @Published var callHistory: [CallRecord]
    
    init() {
        // Initialize current user
        let currentUserId = UUID()
        self.currentUser = User(
            id: currentUserId,
            username: "@myusername",
            displayName: "Александр",
            bio: "Люблю программировать 💻",
            avatarName: "person.circle.fill",
            isOnline: true,
            lastSeen: Date(),
            phoneNumber: "+7 999 123-45-67"
        )
        
        // Test contacts
        let contact1 = User(
            id: UUID(),
            username: "@anna_design",
            displayName: "Анна",
            bio: "UI/UX дизайнер",
            avatarName: "person.crop.circle.fill",
            isOnline: true,
            lastSeen: Date(),
            phoneNumber: "+7 999 111-22-33"
        )
        
        let contact2 = User(
            id: UUID(),
            username: "@dmitry_dev",
            displayName: "Дмитрий",
            bio: "iOS разработчик",
            avatarName: "person.crop.circle.fill",
            isOnline: false,
            lastSeen: Date().addingTimeInterval(-3600),
            phoneNumber: "+7 999 444-55-66"
        )
        
        let contact3 = User(
            id: UUID(),
            username: "@maria_pm",
            displayName: "Мария",
            bio: "Project Manager",
            avatarName: "person.crop.circle.fill",
            isOnline: true,
            lastSeen: Date(),
            phoneNumber: "+7 999 777-88-99"
        )
        
        let contact4 = User(
            id: UUID(),
            username: "@ivan_backend",
            displayName: "Иван",
            bio: "Backend разработчик",
            avatarName: "person.crop.circle.fill",
            isOnline: false,
            lastSeen: Date().addingTimeInterval(-7200),
            phoneNumber: "+7 999 222-33-44"
        )
        
        let contact5 = User(
            id: UUID(),
            username: "@elena_qa",
            displayName: "Елена",
            bio: "QA инженер",
            avatarName: "person.crop.circle.fill",
            isOnline: true,
            lastSeen: Date(),
            phoneNumber: "+7 999 555-66-77"
        )
        
        self.contacts = [contact1, contact2, contact3, contact4, contact5]
        
        // Test chats with messages
        let myUserId = currentUserId
        
        let chat1Messages = [
            Message(id: UUID(), senderId: contact1.id, text: "Привет! Как дела?", timestamp: Date().addingTimeInterval(-3600), isRead: true),
            Message(id: UUID(), senderId: myUserId, text: "Привет! Всё отлично, работаю над проектом", timestamp: Date().addingTimeInterval(-3500), isRead: true),
            Message(id: UUID(), senderId: contact1.id, text: "Круто! Покажи потом что получилось", timestamp: Date().addingTimeInterval(-3400), isRead: true),
            Message(id: UUID(), senderId: myUserId, text: "Обязательно! 👍", timestamp: Date().addingTimeInterval(-3300), isRead: true),
            Message(id: UUID(), senderId: contact1.id, text: "Посмотри новый дизайн", timestamp: Date().addingTimeInterval(-300), isRead: false, mediaType: .image, mediaURL: "design_preview"),
        ]
        
        let chat2Messages = [
            Message(id: UUID(), senderId: contact2.id, text: "Ты уже посмотрел SwiftUI 5?", timestamp: Date().addingTimeInterval(-7200), isRead: true),
            Message(id: UUID(), senderId: myUserId, text: "Да, очень крутые обновления!", timestamp: Date().addingTimeInterval(-7100), isRead: true),
            Message(id: UUID(), senderId: contact2.id, text: "Согласен, особенно новые анимации", timestamp: Date().addingTimeInterval(-7000), isRead: true),
            Message(id: UUID(), senderId: myUserId, text: "Голосовое сообщение", timestamp: Date().addingTimeInterval(-600), isRead: true, mediaType: .voice),
            Message(id: UUID(), senderId: contact2.id, text: "Давай созвонимся обсудим", timestamp: Date().addingTimeInterval(-100), isRead: false),
        ]
        
        let chat3Messages = [
            Message(id: UUID(), senderId: contact3.id, text: "Митинг в 15:00, не забудь", timestamp: Date().addingTimeInterval(-1800), isRead: true),
            Message(id: UUID(), senderId: myUserId, text: "Буду!", timestamp: Date().addingTimeInterval(-1700), isRead: true),
            Message(id: UUID(), senderId: contact3.id, text: "Отправила документы", timestamp: Date().addingTimeInterval(-500), isRead: false, mediaType: .document),
        ]
        
        let chat4Messages = [
            Message(id: UUID(), senderId: contact4.id, text: "API готов к интеграции", timestamp: Date().addingTimeInterval(-86400), isRead: true),
            Message(id: UUID(), senderId: myUserId, text: "Супер, начну сегодня", timestamp: Date().addingTimeInterval(-86300), isRead: true),
        ]
        
        let chat5Messages = [
            Message(id: UUID(), senderId: contact5.id, text: "Нашла пару багов, отписала в Jira", timestamp: Date().addingTimeInterval(-172800), isRead: true),
            Message(id: UUID(), senderId: myUserId, text: "Спасибо! Исправлю", timestamp: Date().addingTimeInterval(-172700), isRead: true),
            Message(id: UUID(), senderId: contact5.id, text: "Скриншот бага", timestamp: Date().addingTimeInterval(-172600), isRead: true, mediaType: .image, mediaURL: "bug_screenshot"),
        ]
        
        self.chats = [
            Chat(id: UUID(), participant: contact1, messages: chat1Messages, isPinned: true, isMuted: false, unreadCount: 1),
            Chat(id: UUID(), participant: contact2, messages: chat2Messages, isPinned: false, isMuted: false, unreadCount: 1),
            Chat(id: UUID(), participant: contact3, messages: chat3Messages, isPinned: false, isMuted: true, unreadCount: 1),
            Chat(id: UUID(), participant: contact4, messages: chat4Messages, isPinned: false, isMuted: false, unreadCount: 0),
            Chat(id: UUID(), participant: contact5, messages: chat5Messages, isPinned: false, isMuted: false, unreadCount: 0),
        ]
        
        // Test call history
        self.callHistory = [
            CallRecord(id: UUID(), participant: contact1, timestamp: Date().addingTimeInterval(-1800), duration: 320, callType: .video, isOutgoing: false, isMissed: false),
            CallRecord(id: UUID(), participant: contact2, timestamp: Date().addingTimeInterval(-7200), duration: 0, callType: .voice, isOutgoing: true, isMissed: true),
            CallRecord(id: UUID(), participant: contact3, timestamp: Date().addingTimeInterval(-86400), duration: 180, callType: .voice, isOutgoing: true, isMissed: false),
            CallRecord(id: UUID(), participant: contact4, timestamp: Date().addingTimeInterval(-172800), duration: 540, callType: .video, isOutgoing: false, isMissed: false),
            CallRecord(id: UUID(), participant: contact2, timestamp: Date().addingTimeInterval(-259200), duration: 120, callType: .voice, isOutgoing: true, isMissed: false),
        ]
    }
    
    // MARK: - Methods
    func sendMessage(to chatId: UUID, text: String, mediaType: Message.MediaType? = nil) {
        guard let index = chats.firstIndex(where: { $0.id == chatId }) else { return }
        
        let newMessage = Message(
            id: UUID(),
            senderId: currentUser.id,
            text: text,
            timestamp: Date(),
            isRead: false,
            mediaType: mediaType
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
