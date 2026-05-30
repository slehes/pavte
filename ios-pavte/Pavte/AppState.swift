import SwiftUI
import Combine

// MARK: - Account Model
struct Account: Identifiable, Codable, Equatable {
    let id: UUID
    var login: String
    var password: String
    var displayName: String
    var username: String
    var bio: String
    var avatarName: String
    var avatarData: Data?
    var phoneNumber: String
    
    static let predefinedAccounts: [Account] = [
        Account(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            login: "slehes",
            password: "12345678",
            displayName: "slehes",
            username: "@slehes",
            bio: "Пользователь Pavte",
            avatarName: "person.circle.fill",
            avatarData: nil,
            phoneNumber: "+7 999 123-45-67"
        ),
        Account(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            login: "faxter",
            password: "12345678",
            displayName: "faxter",
            username: "@faxter",
            bio: "Пользователь Pavte",
            avatarName: "person.circle.fill",
            avatarData: nil,
            phoneNumber: "+7 999 765-43-21"
        )
    ]
}

class AppState: ObservableObject {
    @Published var currentUser: User
    @Published var contacts: [User]
    @Published var chats: [Chat]
    @Published var callHistory: [CallRecord]
    
    // Auth & accounts
    @Published var isLoggedIn: Bool = false
    @Published var currentAccount: Account?
    @Published var savedAccounts: [Account] = Account.predefinedAccounts
    @AppStorage("lastLoggedInAccountId") private var lastLoggedInAccountId: String = ""
    
    private var favoriteChatId: UUID?
    
    init() {
        let currentUserId = UUID()
        self.currentUser = User(
            id: currentUserId,
            username: "@myusername",
            displayName: "Имя",
            bio: "Люблю программировать",
            avatarName: "person.circle.fill",
            isOnline: true,
            lastSeen: Date(),
            phoneNumber: "номер можно изменить"
        )

        self.contacts = []

        // Create "Избранное" chat — NO auto-reply timer
        let favoriteUser = User(
            id: UUID(),
            username: "@favorites",
            displayName: "Избранное",
            bio: "",
            avatarName: "star.fill",
            isOnline: false,
            lastSeen: Date(),
            phoneNumber: ""
        )

        let favChatId = UUID()
        self.favoriteChatId = favChatId

        let initialMessages = [
            Message(id: UUID(), senderId: currentUserId, text: "Добро пожаловать в Избранное!", timestamp: Date().addingTimeInterval(-30), isRead: true)
        ]

        let favoriteChat = Chat(id: favChatId, participant: favoriteUser, messages: initialMessages, isPinned: true, isMuted: false, unreadCount: 0)

        self.chats = [favoriteChat]
        self.callHistory = []
        
        // Try to restore last logged in account
        if !lastLoggedInAccountId.isEmpty,
           let uuid = UUID(uuidString: lastLoggedInAccountId),
           let account = savedAccounts.first(where: { $0.id == uuid }) {
            loginAs(account)
        }
    }
    
    // MARK: - Auth
    func login(login: String, password: String) -> Bool {
        if let account = savedAccounts.first(where: { $0.login.lowercased() == login.lowercased() && $0.password == password }) {
            loginAs(account)
            return true
        }
        return false
    }
    
    func loginAs(_ account: Account) {
        currentAccount = account
        isLoggedIn = true
        lastLoggedInAccountId = account.id.uuidString
        
        currentUser = User(
            id: account.id,
            username: account.username,
            displayName: account.displayName,
            bio: account.bio,
            avatarName: account.avatarName,
            avatarData: account.avatarData,
            isOnline: true,
            lastSeen: Date(),
            phoneNumber: account.phoneNumber
        )
    }
    
    func logout() {
        // Save current profile changes to account
        if let account = currentAccount {
            updateAccountData(account.id)
        }
        isLoggedIn = false
        currentAccount = nil
        lastLoggedInAccountId = ""
    }
    
    func addAccount(_ account: Account) {
        if !savedAccounts.contains(where: { $0.login.lowercased() == account.login.lowercased() }) {
            savedAccounts.append(account)
        }
    }
    
    func removeAccount(_ account: Account) {
        savedAccounts.removeAll { $0.id == account.id }
        if currentAccount?.id == account.id {
            logout()
        }
    }
    
    func updateAccountData(_ accountId: UUID) {
        guard let idx = savedAccounts.firstIndex(where: { $0.id == accountId }) else { return }
        savedAccounts[idx].displayName = currentUser.displayName
        savedAccounts[idx].username = currentUser.username
        savedAccounts[idx].bio = currentUser.bio
        savedAccounts[idx].avatarName = currentUser.avatarName
        savedAccounts[idx].avatarData = currentUser.avatarData
        savedAccounts[idx].phoneNumber = currentUser.phoneNumber
    }
    
    // MARK: - Chat Methods
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
        // Persist to account
        if let account = currentAccount {
            updateAccountData(account.id)
        }
    }
    
    func updateAvatar(avatarData: Data?) {
        currentUser.avatarData = avatarData
        if avatarData != nil {
            currentUser.avatarName = "custom"
        } else {
            currentUser.avatarName = "person.circle.fill"
        }
        if let account = currentAccount {
            updateAccountData(account.id)
        }
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
