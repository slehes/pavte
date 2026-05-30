import SwiftUI

struct ChatsListView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var searchText = ""
    @State private var showNewChat = false
    
    var sortedChats: [Chat] {
        let filtered = searchText.isEmpty ? appState.chats : appState.chats.filter {
            $0.participant.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.lastMessagePreview.localizedCaseInsensitiveContains(searchText)
        }
        
        return filtered.sorted { chat1, chat2 in
            if chat1.isPinned != chat2.isPinned {
                return chat1.isPinned
            }
            return (chat1.lastMessage?.timestamp ?? .distantPast) > (chat2.lastMessage?.timestamp ?? .distantPast)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
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
            .listStyle(.plain)
            .navigationTitle("Чаты")
            .searchable(text: $searchText, prompt: "Поиск")
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
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar — supports custom image
            ZStack(alignment: .bottomTrailing) {
                if let avatarData = chat.participant.avatarData,
                   let uiImage = UIImage(data: avatarData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Image(systemName: chat.participant.avatarName)
                        .font(.system(size: 50))
                        .foregroundStyle(themeManager.accentColor)
                }
                
                if themeManager.showOnlineStatus && chat.participant.isOnline {
                    Circle()
                        .fill(.green)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.participant.displayName)
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
    
    @EnvironmentObject var appState: AppState
    
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
    
    var body: some View {
        NavigationStack {
            List(filteredContacts) { contact in
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
            .navigationTitle("Новый чат")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Поиск контактов")
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
