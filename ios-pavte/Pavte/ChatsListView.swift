import SwiftUI

struct ChatsListView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var searchText = ""
    @State private var showNewChat = false
    
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
                                Button {
                                    let chat = appState.getOrCreateChat(with: user)
                                    searchText = ""
                                    // Navigate handled by NavigationLink
                                } label: {
                                    HStack(spacing: 12) {
                                        if let avatarData = user.avatarData,
                                           let uiImage = UIImage(data: avatarData) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 44, height: 44)
                                                .clipShape(Circle())
                                        } else {
                                            Image(systemName: user.avatarName)
                                                .font(.system(size: 44))
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
                    // Normal chat list
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
                                // Delete chat
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewChat = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showNewChat) {
                NewChatView()
            }
        }
    }
}

struct ChatRowView: View {
    let chat: Chat
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar — supports custom image, groups, channels
            ZStack(alignment: .bottomTrailing) {
                if let avatarData = chat.displayAvatarData,
                   let uiImage = UIImage(data: avatarData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Image(systemName: chat.displayAvatar)
                        .font(.system(size: 50))
                        .foregroundStyle(themeManager.accentColor)
                }
                
                if themeManager.showOnlineStatus && chat.participant.isOnline && chat.chatType == .personal {
                    Circle()
                        .fill(.green)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                }
                
                // Group/Channel badge
                if chat.chatType == .group {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(Circle().fill(themeManager.accentColor))
                } else if chat.chatType == .channel {
                    Image(systemName: "megaphone.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(Circle().fill(themeManager.accentColor))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.displayName)
                        .font(.headline)
                    
                    if chat.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    
                    if chat.isMuted {
                        Image(systemName: "bell.slash.fill")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    
                    Spacer()
                    
                    if let timestamp = chat.lastMessage?.timestamp {
                        Text(formatTimestamp(timestamp))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack {
                    Text(chat.lastMessagePreview)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if chat.unreadCount > 0 {
                        Text("\(chat.unreadCount)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(chat.isMuted ? Color.gray : themeManager.accentColor)
                            .clipShape(Capsule())
                    } else if let lastMessage = chat.lastMessage,
                              lastMessage.senderId == appState.currentUser.id {
                        Image(systemName: lastMessage.isRead ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.caption)
                            .foregroundStyle(lastMessage.isRead ? themeManager.accentColor : .gray)
                    }
                }
            }
        }
        .padding(.vertical, 4)
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
    
    /// Also search in global user directory
    var globalSearchResults: [User] {
        guard !searchText.isEmpty else { return [] }
        return appState.searchUsers(query: searchText)
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Global search results (search by username)
                if !searchText.isEmpty && !globalSearchResults.isEmpty {
                    Section("Найдено в каталоге") {
                        ForEach(globalSearchResults) { user in
                            Button {
                                _ = appState.getOrCreateChat(with: user)
                                dismiss()
                            } label: {
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
                
                // Contacts
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
    ChatsListView()
        .environmentObject(AppState())
        .environmentObject(ThemeManager())
}
