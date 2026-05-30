import SwiftUI

struct ChatDetailView: View {
    let chat: Chat
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var messageText = ""
    @State private var showAttachmentMenu = false
    @State private var showCallSheet = false
    @State private var showUserProfile = false
    @FocusState private var isTextFieldFocused: Bool
    
    var currentChat: Chat {
        appState.chats.first { $0.id == chat.id } ?? chat
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(currentChat.messages) { message in
                            MessageBubbleView(message: message, isOutgoing: message.senderId == appState.currentUser.id)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .background(themeManager.wallpaperView())
                .onAppear {
                    if let lastMessage = currentChat.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                    appState.markAsRead(chatId: chat.id)
                }
                .onChange(of: currentChat.messages.count) { _, _ in
                    if let lastMessage = currentChat.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input bar
            MessageInputBar(
                text: $messageText,
                onSend: sendMessage,
                onAttachment: { showAttachmentMenu = true }
            )
            .focused($isTextFieldFocused)
        }
        .navigationTitle(chat.participant.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button {
                    showUserProfile = true
                } label: {
                    VStack(spacing: 0) {
                        Text(chat.participant.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if themeManager.showOnlineStatus {
                            Text(chat.participant.isOnline ? "в сети" : lastSeenText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        showCallSheet = true
                    } label: {
                        Image(systemName: "phone.fill")
                    }
                    
                    Button {
                        showCallSheet = true
                    } label: {
                        Image(systemName: "video.fill")
                    }
                }
            }
        }
        .confirmationDialog("Прикрепить", isPresented: $showAttachmentMenu) {
            Button("Фото") {
                sendMediaMessage(.image)
            }
            Button("Видео") {
                sendMediaMessage(.video)
            }
            Button("Голосовое сообщение") {
                sendMediaMessage(.voice)
            }
            Button("Документ") {
                sendMediaMessage(.document)
            }
            Button("Отмена", role: .cancel) {}
        }
        .confirmationDialog("Позвонить", isPresented: $showCallSheet) {
            Button("Голосовой звонок") {
                startCall(type: .voice)
            }
            Button("Видеозвонок") {
                startCall(type: .video)
            }
            Button("Отмена", role: .cancel) {}
        }
        .sheet(isPresented: $showUserProfile) {
            UserProfileView(user: chat.participant)
        }
    }
    
    private var lastSeenText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.unitsStyle = .short
        return "был(а) " + formatter.localizedString(for: chat.participant.lastSeen, relativeTo: Date())
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        appState.sendMessage(to: chat.id, text: messageText)
        messageText = ""
        
        // Simulate reply after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let replies = [
                "Понял!",
                "Отлично 👍",
                "Хорошо, сделаю",
                "Ок!",
                "Спасибо!",
                "Договорились"
            ]
            if let reply = replies.randomElement() {
                simulateReply(reply)
            }
        }
    }
    
    private func sendMediaMessage(_ type: Message.MediaType) {
        let text: String
        switch type {
        case .image: text = "Отправлено фото"
        case .video: text = "Отправлено видео"
        case .voice: text = "Голосовое сообщение"
        case .document: text = "Отправлен документ"
        }
        appState.sendMessage(to: chat.id, text: text, mediaType: type)
    }
    
    private func simulateReply(_ text: String) {
        guard let index = appState.chats.firstIndex(where: { $0.id == chat.id }) else { return }
        let replyMessage = Message(
            id: UUID(),
            senderId: chat.participant.id,
            text: text,
            timestamp: Date(),
            isRead: false
        )
        appState.chats[index].messages.append(replyMessage)
    }
    
    private func startCall(type: CallRecord.CallType) {
        // Add to call history and show call screen
        appState.addCallRecord(
            participant: chat.participant,
            callType: type,
            isOutgoing: true,
            duration: 0,
            isMissed: false
        )
    }
}

struct MessageBubbleView: View {
    let message: Message
    let isOutgoing: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            if isOutgoing { Spacer(minLength: 60) }
            
            VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 4) {
                // Media content
                if let mediaType = message.mediaType {
                    MediaPreviewView(mediaType: mediaType)
                }
                
                // Text content
                if !message.text.isEmpty && message.mediaType == nil {
                    Text(message.text)
                        .font(.system(size: themeManager.fontSize.size))
                        .foregroundStyle(isOutgoing ? .white : .primary)
                }
                
                // Timestamp and status
                HStack(spacing: 4) {
                    Text(message.formattedTime)
                        .font(.caption2)
                        .foregroundStyle(isOutgoing ? .white.opacity(0.7) : .secondary)
                    
                    if isOutgoing && themeManager.showReadReceipts {
                        Image(systemName: message.isRead ? "checkmark.circle.fill" : "checkmark")
                            .font(.caption2)
                            .foregroundStyle(isOutgoing ? .white.opacity(0.7) : .secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isOutgoing ? themeManager.outgoingBubbleColor : themeManager.incomingBubbleColor)
            .clipShape(RoundedRectangle(cornerRadius: themeManager.bubbleCornerRadius))
            
            if !isOutgoing { Spacer(minLength: 60) }
        }
    }
}

struct MediaPreviewView: View {
    let mediaType: Message.MediaType
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Group {
            switch mediaType {
            case .image:
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 200, height: 150)
                    
                    Image(systemName: "photo.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.gray)
                }
                
            case .video:
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 200, height: 150)
                    
                    Circle()
                        .fill(.black.opacity(0.5))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "play.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                
            case .voice:
                HStack(spacing: 8) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(themeManager.accentColor)
                    
                    // Waveform visualization
                    HStack(spacing: 2) {
                        ForEach(0..<20, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(themeManager.accentColor.opacity(0.6))
                                .frame(width: 3, height: CGFloat.random(in: 8...24))
                        }
                    }
                    
                    Text("0:12")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 180)
                
            case .document:
                HStack(spacing: 12) {
                    Image(systemName: "doc.fill")
                        .font(.title)
                        .foregroundStyle(themeManager.accentColor)
                    
                    VStack(alignment: .leading) {
                        Text("Документ.pdf")
                            .font(.subheadline)
                            .lineLimit(1)
                        Text("125 KB")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 180, alignment: .leading)
            }
        }
    }
}

struct MessageInputBar: View {
    @Binding var text: String
    let onSend: () -> Void
    let onAttachment: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onAttachment) {
                Image(systemName: "paperclip")
                    .font(.title2)
                    .foregroundStyle(themeManager.accentColor)
            }
            
            TextField("Сообщение", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .lineLimit(1...5)
            
            Button(action: onSend) {
                Image(systemName: text.isEmpty ? "mic.fill" : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(themeManager.accentColor)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

struct UserProfileView: View {
    let user: User
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: user.avatarName)
                            .font(.system(size: 80))
                            .foregroundStyle(themeManager.accentColor)
                        
                        Text(user.displayName)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if user.isOnline {
                            Text("в сети")
                                .foregroundStyle(.green)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                .listRowBackground(Color.clear)
                
                Section("Информация") {
                    LabeledContent("Никнейм", value: user.username)
                    LabeledContent("Телефон", value: user.phoneNumber)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("О себе")
                            .foregroundStyle(.secondary)
                        Text(user.bio)
                    }
                }
                
                Section {
                    Button {
                        // Start chat
                    } label: {
                        Label("Написать сообщение", systemImage: "message.fill")
                    }
                    
                    Button {
                        // Voice call
                    } label: {
                        Label("Позвонить", systemImage: "phone.fill")
                    }
                    
                    Button {
                        // Video call
                    } label: {
                        Label("Видеозвонок", systemImage: "video.fill")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        // Block user
                    } label: {
                        Label("Заблокировать", systemImage: "hand.raised.fill")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChatDetailView(chat: Chat(
            id: UUID(),
            participant: User(
                id: UUID(),
                username: "@test",
                displayName: "Тест",
                bio: "Тестовый пользователь",
                avatarName: "person.circle.fill",
                isOnline: true,
                lastSeen: Date(),
                phoneNumber: "+7 999 000-00-00"
            ),
            messages: [
                Message(id: UUID(), senderId: UUID(), text: "Привет!", timestamp: Date(), isRead: true),
                Message(id: UUID(), senderId: UUID(), text: "Как дела?", timestamp: Date(), isRead: true, mediaType: .image),
            ],
            isPinned: false,
            isMuted: false,
            unreadCount: 0
        ))
    }
    .environmentObject(AppState())
    .environmentObject(ThemeManager())
}
