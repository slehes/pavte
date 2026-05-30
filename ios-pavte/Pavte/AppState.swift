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
    // Video background for avatar area
    var avatarVideoBackgroundData: Data?
    // Passcode & 2FA
    var passcode: String?
    var is2FAEnabled: Bool
    var twoFASecret: String?
    
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
            phoneNumber: "+7 999 123-45-67",
            avatarVideoBackgroundData: nil,
            passcode: nil,
            is2FAEnabled: false,
            twoFASecret: nil
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
            phoneNumber: "+7 999 765-43-21",
            avatarVideoBackgroundData: nil,
            passcode: nil,
            is2FAEnabled: false,
            twoFASecret: nil
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
    
    // Global user directory (for search)
    @Published var globalUsers: [User] = []
    
    // Passcode lock
    @Published var isPasscodeRequired: Bool = false
    @Published var isPasscodeUnlocked: Bool = true // Start unlocked, will check on appear
    @AppStorage("appPasscode") private var appPasscode: String = ""
    @AppStorage("isPasscodeEnabled") private var isPasscodeEnabled: Bool = false
    
    // Active sessions
    @Published var activeSessions: [ActiveSession] = []
    
    // App version
    static let appVersion = "1.0.3"
    
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

        // Create "Избранное" chat — NO welcome message, NO auto-reply
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

        let favoriteChat = Chat(id: favChatId, participant: favoriteUser, messages: [], isPinned: true, isMuted: false, unreadCount: 0)

        self.chats = [favoriteChat]
        self.callHistory = []
        
        // Populate global user directory with predefined accounts
        self.globalUsers = Account.predefinedAccounts.map { account in
            User(
                id: account.id,
                username: account.username,
                displayName: account.displayName,
                bio: account.bio,
                avatarName: account.avatarName,
                avatarData: account.avatarData,
                isOnline: false,
                lastSeen: Date(),
                phoneNumber: account.phoneNumber
            )
        }
        
        // Active sessions
        self.activeSessions = ActiveSession.mockSessions(appVersion: AppState.appVersion)
        
        // Check passcode lock
        checkPasscodeLock()
        
        // Try to restore last logged in account
        if !lastLoggedInAccountId.isEmpty,
           let uuid = UUID(uuidString: lastLoggedInAccountId),
           let account = savedAccounts.first(where: { $0.id == uuid }) {
            loginAs(account)
        }
    }
    
    // MARK: - Passcode Lock
    private func checkPasscodeLock() {
        if isPasscodeEnabled && !appPasscode.isEmpty {
            isPasscodeRequired = true
            isPasscodeUnlocked = false
        } else {
            isPasscodeRequired = false
            isPasscodeUnlocked = true
        }
    }
    
    func setPasscode(_ code: String) {
        appPasscode = code
        isPasscodeEnabled = !code.isEmpty
        isPasscodeRequired = !code.isEmpty
        isPasscodeUnlocked = code.isEmpty
        // Save to account
        if let account = currentAccount {
            updateAccountPasscode(account.id, passcode: code)
        }
    }
    
    func removePasscode() {
        appPasscode = ""
        isPasscodeEnabled = false
        isPasscodeRequired = false
        isPasscodeUnlocked = true
        if let account = currentAccount {
            updateAccountPasscode(account.id, passcode: nil)
        }
    }
    
    func verifyPasscode(_ code: String) -> Bool {
        if code == appPasscode {
            isPasscodeUnlocked = true
            return true
        }
        return false
    }
    
    private func updateAccountPasscode(_ accountId: UUID, passcode: String?) {
        guard let idx = savedAccounts.firstIndex(where: { $0.id == accountId }) else { return }
        savedAccounts[idx].passcode = passcode
    }
    
    // MARK: - 2FA
    func enable2FA() -> String {
        // Generate a 6-digit secret for demo
        let secret = String(format: "%06d", Int.random(in: 100000...999999))
        if let account = currentAccount {
            guard let idx = savedAccounts.firstIndex(where: { $0.id == account.id }) else { return secret }
            savedAccounts[idx].is2FAEnabled = true
            savedAccounts[idx].twoFASecret = secret
        }
        return secret
    }
    
    func disable2FA() {
        if let account = currentAccount {
            guard let idx = savedAccounts.firstIndex(where: { $0.id == account.id }) else { return }
            savedAccounts[idx].is2FAEnabled = false
            savedAccounts[idx].twoFASecret = nil
        }
    }
    
    var is2FAEnabledForCurrentAccount: Bool {
        guard let account = currentAccount else { return false }
        return savedAccounts.first(where: { $0.id == account.id })?.is2FAEnabled ?? false
    }
    
    func verify2FA(_ code: String) -> Bool {
        guard let account = currentAccount else { return false }
        let secret = savedAccounts.first(where: { $0.id == account.id })?.twoFASecret ?? ""
        return code == secret
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
        // Save current profile changes before switching
        if let current = currentAccount {
            updateAccountData(current.id)
        }
        
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
            phoneNumber: account.phoneNumber,
            avatarVideoBackgroundData: account.avatarVideoBackgroundData
        )
        
        // Restore passcode for this account
        if let passcode = account.passcode, !passcode.isEmpty {
            appPasscode = passcode
            isPasscodeEnabled = true
        } else {
            appPasscode = ""
            isPasscodeEnabled = false
        }
        checkPasscodeLock()
    }
    
    func logout() {
        // Save current profile changes to account
        if let account = currentAccount {
            updateAccountData(account.id)
        }
        isLoggedIn = false
        currentAccount = nil
        lastLoggedInAccountId = ""
        isPasscodeUnlocked = true
    }
    
    func addAccount(_ account: Account) {
        if !savedAccounts.contains(where: { $0.login.lowercased() == account.login.lowercased() }) {
            savedAccounts.append(account)
        }
        // Add to global directory
        let user = User(
            id: account.id,
            username: account.username,
            displayName: account.displayName,
            bio: account.bio,
            avatarName: account.avatarName,
            avatarData: account.avatarData,
            isOnline: false,
            lastSeen: Date(),
            phoneNumber: account.phoneNumber
        )
        if !globalUsers.contains(where: { $0.id == account.id }) {
            globalUsers.append(user)
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
        savedAccounts[idx].avatarVideoBackgroundData = currentUser.avatarVideoBackgroundData
    }
    
    // MARK: - Search
    func searchUsers(query: String) -> [User] {
        guard !query.isEmpty else { return [] }
        let lowerQuery = query.lowercased()
        // Remove @ prefix if present for matching
        let cleanQuery = lowerQuery.hasPrefix("@") ? String(lowerQuery.dropFirst()) : lowerQuery
        return globalUsers.filter { user in
            user.id != currentUser.id &&
            (user.displayName.lowercased().contains(lowerQuery) ||
             user.username.lowercased().contains(lowerQuery) ||
             user.username.lowercased().contains(cleanQuery))
        }
    }
    
    func searchChats(query: String) -> [Chat] {
        guard !query.isEmpty else { return [] }
        let lowerQuery = query.lowercased()
        return chats.filter { chat in
            chat.displayName.lowercased().contains(lowerQuery) ||
            chat.participant.username.lowercased().contains(lowerQuery) ||
            chat.lastMessagePreview.lowercased().contains(lowerQuery)
        }
    }
    
    // MARK: - Support Chat — opens chat with @slehes by username
    func openSupportChat() -> Chat {
        // Find @slehes user from global directory
        let supportUser: User
        if let existing = globalUsers.first(where: { $0.username == "@slehes" }) {
            supportUser = existing
        } else {
            supportUser = User(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                username: "@slehes",
                displayName: "slehes",
                bio: "Разработчик Pavte",
                avatarName: "person.circle.fill",
                isOnline: true,
                lastSeen: Date(),
                phoneNumber: ""
            )
        }
        return getOrCreateChat(with: supportUser)
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
    
    // MARK: - Message Actions
    func deleteMessageForMe(chatId: UUID, messageId: UUID) {
        guard let chatIdx = chats.firstIndex(where: { $0.id == chatId }),
              let msgIdx = chats[chatIdx].messages.firstIndex(where: { $0.id == messageId }) else { return }
        chats[chatIdx].messages[msgIdx].isDeletedForMe = true
    }
    
    func deleteMessageForEveryone(chatId: UUID, messageId: UUID) {
        guard let chatIdx = chats.firstIndex(where: { $0.id == chatId }),
              let msgIdx = chats[chatIdx].messages.firstIndex(where: { $0.id == messageId }) else { return }
        chats[chatIdx].messages[msgIdx].isDeletedForEveryone = true
        // Anonymous — no trace left, message simply disappears
    }
    
    func editMessage(chatId: UUID, messageId: UUID, newText: String) {
        guard let chatIdx = chats.firstIndex(where: { $0.id == chatId }),
              let msgIdx = chats[chatIdx].messages.firstIndex(where: { $0.id == messageId }) else { return }
        let original = chats[chatIdx].messages[msgIdx].text
        chats[chatIdx].messages[msgIdx].originalText = original
        chats[chatIdx].messages[msgIdx].text = newText
        chats[chatIdx].messages[msgIdx].isEdited = true
    }
    
    func togglePinMessage(chatId: UUID, messageId: UUID) {
        guard let chatIdx = chats.firstIndex(where: { $0.id == chatId }),
              let msgIdx = chats[chatIdx].messages.firstIndex(where: { $0.id == messageId }) else { return }
        chats[chatIdx].messages[msgIdx].isPinned.toggle()
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
        // Update in global directory
        if let idx = globalUsers.firstIndex(where: { $0.id == currentUser.id }) {
            globalUsers[idx].displayName = displayName
            globalUsers[idx].bio = bio
            globalUsers[idx].username = username
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
        // Update in global directory
        if let idx = globalUsers.firstIndex(where: { $0.id == currentUser.id }) {
            globalUsers[idx].avatarData = avatarData
            globalUsers[idx].avatarName = currentUser.avatarName
        }
    }
    
    func updateAvatarVideoBackground(_ data: Data?) {
        currentUser.avatarVideoBackgroundData = data
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
    
    // MARK: - Group/Channel Management
    func updateChatPermission(chatId: UUID, allowReactions: Bool? = nil, allowMembersToInvite: Bool? = nil, allowMembersToEditInfo: Bool? = nil, allowMembersToPinMessages: Bool? = nil, historyVisibleToNewMembers: Bool? = nil, slowMode: Bool? = nil) {
        guard let idx = chats.firstIndex(where: { $0.id == chatId }) else { return }
        if let v = allowReactions { chats[idx].allowReactions = v }
        if let v = allowMembersToInvite { chats[idx].allowMembersToInvite = v }
        if let v = allowMembersToEditInfo { chats[idx].allowMembersToEditInfo = v }
        if let v = allowMembersToPinMessages { chats[idx].allowMembersToPinMessages = v }
        if let v = historyVisibleToNewMembers { chats[idx].historyVisibleToNewMembers = v }
        if let v = slowMode { chats[idx].slowMode = v }
    }
    
    func leaveChat(chatId: UUID) {
        chats.removeAll { $0.id == chatId }
    }
    
    // MARK: - Active Sessions
    func terminateSession(_ sessionId: UUID) {
        activeSessions.removeAll { $0.id == sessionId }
    }
    
    func terminateAllOtherSessions() {
        activeSessions.removeAll { !$0.isCurrent }
    }
}
