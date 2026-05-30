import SwiftUI

struct ChatsListView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var searchText = ""
    @State private var showNewChat = false
    @Binding var showAIChat: Bool
    
    var sortedChats: [Chat] {
        let filtered = searchText.isEmpty ? appState.chats : appState.chats.filter {
            $0.participant.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.participant.username.localizedCaseInsensitiveContains(searchText) ||
            $0.lastMessagePreview.localizedCaseInsensitiveContains(searchText)
        }
        
        return filtered.sorted { chat1, chat2 in
            if chat1.isPinned != chat2.isPinned {
                return chat1.isPinned
            }
            return (chat1.lastMessage?.timestamp ?? .distantPast) > (chat2.lastMessage?.timestamp ?? .distantPast)
        }
    }
    
    /// Global search results for username search
    var searchResults: [User] {
        guard !searchText.isEmpty else { return [] }
        return appState.searchUsers(query: searchText)
    }
    
    /// Search results from existing chats
    var searchChatResults: [Chat] {
        guard !searchText.isEmpty else { return [] }
        return appState.searchChats(query: searchText)
    }
    
    var isSearching: Bool {
        !searchText.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    // Search: Found users by username
                    if !searchResults.isEmpty {
                        Section("Найденные пользователи") {
                            ForEach(searchResults) { user in
                                NavigationLink(destination: ChatDetailView(chat: appState.getOrCreateChat(with: user))) {
                                    HStack(spacing: 12) {
                                        // Smaller avatar
                                        if let avatarData = user.avatarData,
                                           let uiImage = UIImage(data: avatarData) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 40, height: 40)
                                                .clipShape(Circle())
                                        } else {
                                            Image(systemName: user.avatarName)
                                                .font(.system(size: 40))
                                                .foregroundStyle(themeManager.accentColor)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(user.displayName)
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                            Text(user.username)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "message.fill")
                                            .font(.caption)
                                            .foregroundStyle(themeManager.accentColor)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Search: Found chats
                    if !searchChatResults.isEmpty {
                        Section("Чаты") {
                            ForEach(searchChatResults) { chat in
                                NavigationLink(destination: ChatDetailView(chat: chat)) {
                                    ChatRowView(chat: chat)
                                }
                            }
                        }
                    }
                    
                    if searchResults.isEmpty && searchChatResults.isEmpty {
                        Section {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.secondary)
                                Text("Ничего не найдено")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Text("Попробуйте другой запрос")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        }
                    }
                } else {
                    // Normal chat list — Telegram-like compact rows
                    ForEach(sortedChats) { chat in
                        NavigationLink(destination: ChatDetailView(chat: chat)) {
                            ChatRowView(chat: chat)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                appState.togglePin(chatId: chat.id)
                            } label: {
                                Label(chat.isPinned ? "Открепить" : "Закрепить",
                                      systemImage: chat.isPinned ? "pin.slash" : "pin")
                            }
                            .tint(.orange)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                appState.leaveChat(chatId: chat.id)
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                            
                            Button {
                                appState.toggleMute(chatId: chat.id)
                            } label: {
                                Label(chat.isMuted ? "Включить звук" : "Без звука",
                                      systemImage: chat.isMuted ? "bell" : "bell.slash")
                            }
                            .tint(.gray)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Чаты")
            .searchable(text: $searchText, prompt: "Поиск по юзернейму или чату")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showAIChat = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple, Color.indigo],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 30, height: 30)
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            simulateIncomingMessage()
                        } label: {
                            Image(systemName: "bell.badge.fill")
                                .foregroundStyle(.gray)
                        }
                        
                        Button {
                            showNewChat = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
            }
            .sheet(isPresented: $showNewChat) {
                NewChatView()
            }
        }
        .background(themeManager.wallpaperView().ignoresSafeArea())
    }
    
    private func simulateIncomingMessage() {
        // Find or create a chat with faxter for the demo
        let faxterUser = User(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID(),
            username: "@faxter",
            displayName: "faxter",
            bio: "",
            avatarName: "person.circle.fill",
            isOnline: true,
            lastSeen: Date(),
            phoneNumber: "+7 999 765-43-21",
            avatarVideoBackgroundData: nil
        )
        
        let chat = appState.getOrCreateChat(with: faxterUser)
        
        // First show typing indicator
        appState.simulateTyping(chatId: chat.id)
        
        let messages = [
            "Привет! Как дела?",
            "Что делаешь?",
            "Давай встретимся завтра",
            "Посмотри это фото!",
            "Ты свободен сегодня?",
            "Хахаха, точно!",
            "Отправь мне файл",
            "Ладно, договорились 👍"
        ]
        
        // Then send the message after typing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [self] in
            appState.receiveMessage(
                from: faxterUser,
                chatId: chat.id,
                text: messages.randomElement() ?? "Привет!"
            )
        }
    }
}

// MARK: - Chat Row View (Telegram-like with blue dot for unread)
struct ChatRowView: View {
    let chat: Chat
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 10) {
            // Avatar with online indicator (compact — reduced size by half)
            ZStack(alignment: .bottomTrailing) {
                if let avatarData = chat.displayAvatarData,
                   let uiImage = UIImage(data: avatarData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Image(systemName: chat.displayAvatar)
                        .font(.system(size: 40))
                        .foregroundStyle(themeManager.accentColor)
                }
                
                // Online indicator
                if themeManager.showOnlineStatus && chat.participant.isOnline && chat.chatType == .personal {
                    Circle()
                        .fill(.green)
                        .frame(width: 9, height: 9)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 1.5)
                        )
                }
                
                // Chat type badge
                if chat.chatType == .group {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(.white)
                        .padding(1.5)
                        .background(Circle().fill(themeManager.accentColor))
                } else if chat.chatType == .channel {
                    Image(systemName: "megaphone.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(.white)
                        .padding(1.5)
                        .background(Circle().fill(themeManager.accentColor))
                }
            }
            
            // Chat content
            VStack(alignment: .leading, spacing: 2) {
                // First row: name + time
                HStack(alignment: .firstTextBaseline) {
                    // Blue dot for unread messages
                    if chat.unreadCount > 0 {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }
                    
                    Text(chat.displayName)
                        .font(.subheadline)
                        .fontWeight(chat.unreadCount > 0 ? .semibold : .regular)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    if chat.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    
                    if chat.isMuted {
                        Image(systemName: "bell.slash.fill")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                    
                    Spacer()
                    
                    if let timestamp = chat.lastMessage?.timestamp {
                        Text(formatTimestamp(timestamp))
                            .font(.caption2)
                            .foregroundStyle(chat.unreadCount > 0 ? Color.blue : .secondary)
                    }
                }
                
                // Second row: last message + unread badge / read receipts
                HStack(alignment: .center) {
                    Text(chat.lastMessagePreview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if chat.unreadCount > 0 {
                        // New message indicator: blue badge with count
                        Text("\(chat.unreadCount)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.blue))
                    } else if let lastMessage = chat.lastMessage,
                              lastMessage.senderId == appState.currentUser.id {
                        // Read receipts in chat list
                        if lastMessage.isRead {
                            // 1 blue checkmark = read
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        } else {
                            // 2 gray checkmarks = sent not read
                            HStack(spacing: -4) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.gray.opacity(0.6))
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.gray.opacity(0.6))
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Вчера"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            formatter.locale = Locale(identifier: "ru_RU")
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM"
            return formatter.string(from: date)
        }
    }
}

struct NewChatView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    var filteredContacts: [User] {
        if searchText.isEmpty {
            return appState.contacts
        }
        return appState.contacts.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var globalSearchResults: [User] {
        guard !searchText.isEmpty else { return [] }
        return appState.searchUsers(query: searchText)
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !searchText.isEmpty && !globalSearchResults.isEmpty {
                    Section("Найдено по юзернейму") {
                        ForEach(globalSearchResults) { user in
                            NavigationLink(destination: ChatDetailView(chat: appState.getOrCreateChat(with: user))) {
                                HStack(spacing: 12) {
                                    if let avatarData = user.avatarData,
                                       let uiImage = UIImage(data: avatarData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: user.avatarName)
                                            .font(.system(size: 40))
                                            .foregroundStyle(themeManager.accentColor)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(user.displayName)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text(user.username)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section("Контакты") {
                    ForEach(filteredContacts) { contact in
                        Button {
                            _ = appState.getOrCreateChat(with: contact)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                if let avatarData = contact.avatarData,
                                   let uiImage = UIImage(data: avatarData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: contact.avatarName)
                                        .font(.system(size: 40))
                                        .foregroundStyle(themeManager.accentColor)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(contact.displayName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(contact.username)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Новый чат")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Поиск по юзернейму")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ChatsListView(showAIChat: .constant(false))
        .environmentObject(AppState())
        .environmentObject(ThemeManager())
}
