import SwiftUI
import PhotosUI
import AVKit
import AVFoundation

// MARK: - ChatDetailView
struct ChatDetailView: View {
    let chat: Chat
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var messageText = ""
    @State private var showCallSheet = false
    @State private var showUserProfile = false
    @FocusState private var isTextFieldFocused: Bool

    // Attachment popup
    @State private var showAttachmentPopup = false

    // PhotosPicker
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showPhotoPicker = false

    // File picker
    @State private var showFilePicker = false

    // Voice recording
    @State private var isRecording = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var recordingTimer: Timer?

    // Full-screen media viewer
    @State private var selectedMessageForViewer: Message?
    
    // Group management
    @State private var showGroupManagement = false
    
    // Message actions
    @State private var selectedMessage: Message?
    @State private var showDeleteConfirmation = false
    @State private var deleteForEveryone = false
    @State private var showEditMessage = false
    @State private var editText = ""
    
    // Pinned messages viewer
    @State private var showPinnedMessages = false
    
    // Pending photos (for photo+text grouped sending)
    @State private var pendingPhotos: [Data] = []

    var currentChat: Chat {
        appState.chats.first { $0.id == chat.id } ?? chat
    }
    
    /// Messages visible to the user (not deleted for them or everyone)
    var visibleMessages: [Message] {
        currentChat.messages.filter { !$0.isDeletedForMe && !$0.isDeletedForEveryone }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Pinned message banner
            if let pinnedMsg = currentChat.pinnedMessages.last {
                PinnedMessageBanner(message: pinnedMsg, chatId: chat.id)
            }
            
            // Typing indicator
            if appState.isTyping(chatId: chat.id) {
                TypingIndicatorBar(userName: chat.participant.displayName)
            }
            
            messagesList
            inputBar
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showUserProfile) {
            UserProfileView(user: chat.participant)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItems, maxSelectionCount: 5, matching: .any(of: [.images, .videos]))
        .onChange(of: selectedPhotoItems) { _, newItems in
            handleSelectedPhotos(newItems)
        }
        .fullScreenCover(item: $selectedMessageForViewer) { message in
            MediaFullViewerView(message: message, dismissAction: { selectedMessageForViewer = nil })
        }
        .sheet(isPresented: $showGroupManagement) {
            GroupManagementView(chat: chat)
        }
        .sheet(isPresented: $showPinnedMessages) {
            PinnedMessagesView(chatId: chat.id)
        }
        // Delete confirmation
        .alert("Удалить сообщение", isPresented: $showDeleteConfirmation) {
            Button("Удалить у меня", role: .destructive) {
                if let msg = selectedMessage {
                    appState.deleteMessageForMe(chatId: chat.id, messageId: msg.id)
                }
            }
            Button("Удалить у всех", role: .destructive) {
                if let msg = selectedMessage {
                    appState.deleteMessageForEveryone(chatId: chat.id, messageId: msg.id)
                }
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Выберите способ удаления. Удаление у всех — анонимно, собеседник не увидит что сообщение было удалено.")
        }
        // Edit message
        .alert("Редактировать сообщение", isPresented: $showEditMessage) {
            TextField("Новое сообщение", text: $editText)
            Button("Сохранить") {
                if let msg = selectedMessage, !editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    appState.editMessage(chatId: chat.id, messageId: msg.id, newText: editText)
                }
            }
            Button("Отмена", role: .cancel) { }
        }
    }

    // MARK: - Subviews

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(visibleMessages) { message in
                        MessageBubbleView(message: message, isOutgoing: message.senderId == appState.currentUser.id, chatId: chat.id, isFirstInGroup: isFirstMessageInGroup(message))
                            .id(message.id)
                            .onTapGesture { handleMediaTap(message) }
                            .onLongPressGesture {
                                selectedMessage = message
                            }
                            .contextMenu { messageContextMenu(message) }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .background(themeManager.wallpaperView())
            .onAppear {
                if let lastMessage = visibleMessages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
                appState.markAsRead(chatId: chat.id)
            }
            .onChange(of: visibleMessages.count) { _, _ in
                if let lastMessage = visibleMessages.last {
                    withAnimation { proxy.scrollTo(lastMessage.id, anchor: .bottom) }
                }
            }
            .onChange(of: appState.isTyping(chatId: chat.id)) { _, isTyping in
                if isTyping {
                    withAnimation { proxy.scrollTo(visibleMessages.last?.id ?? UUID(), anchor: .bottom) }
                }
            }
        }
    }
    
    /// Check if this message is the first from its sender in a consecutive group
    private func isFirstMessageInGroup(_ message: Message) -> Bool {
        guard let index = visibleMessages.firstIndex(where: { $0.id == message.id }) else { return true }
        if index == 0 { return true }
        let previousMessage = visibleMessages[index - 1]
        return previousMessage.senderId != message.senderId
    }
    
    // MARK: - Context Menu for Messages
    @ViewBuilder
    private func messageContextMenu(_ message: Message) -> some View {
        // Reply
        Button {
            // Reply placeholder
        } label: {
            Label("Ответить", systemImage: "arrowshape.turn.up.left")
        }
        
        // Edit (only own messages)
        if message.senderId == appState.currentUser.id {
            Button {
                selectedMessage = message
                editText = message.text
                showEditMessage = true
            } label: {
                Label("Редактировать", systemImage: "pencil")
            }
        }
        
        // Pin / Unpin
        Button {
            appState.togglePinMessage(chatId: chat.id, messageId: message.id)
        } label: {
            Label(message.isPinned ? "Открепить" : "Закрепить", systemImage: message.isPinned ? "pin.slash" : "pin")
        }
        
        // Copy
        Button {
            UIPasteboard.general.string = message.text
        } label: {
            Label("Копировать", systemImage: "doc.on.doc")
        }
        
        // Delete
        Button(role: .destructive) {
            selectedMessage = message
            showDeleteConfirmation = true
        } label: {
            Label("Удалить", systemImage: "trash")
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            // Pending photos strip
            if !pendingPhotos.isEmpty {
                PendingPhotosStrip(photos: pendingPhotos) {
                    pendingPhotos.removeAll()
                }
            }
            
            // Attachment popup menu (redesigned - Telegram style)
            if showAttachmentPopup {
                RedesignedAttachmentPopupView(
                    onSelectCamera: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showAttachmentPopup = false
                        }
                        showPhotoPicker = true
                    },
                    onSelectPhoto: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showAttachmentPopup = false
                        }
                        showPhotoPicker = true
                    },
                    onSelectFile: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showAttachmentPopup = false
                        }
                        showFilePicker = true
                    },
                    onSelectVoice: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showAttachmentPopup = false
                        }
                        startVoiceRecording()
                    },
                    onDismiss: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showAttachmentPopup = false
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            MessageInputBar(
                text: $messageText,
                isRecording: $isRecording,
                recordingDuration: $recordingDuration,
                onSend: sendMessage,
                onAttachment: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showAttachmentPopup.toggle()
                    }
                },
                onVoiceRecordToggle: toggleVoiceRecording
            )
            .focused($isTextFieldFocused)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Button {
                if currentChat.chatType != .personal {
                    showGroupManagement = true
                } else {
                    showUserProfile = true
                }
            } label: {
                VStack(spacing: 1) {
                    Text(chat.displayName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    if chat.chatType == .personal {
                        if appState.isTyping(chatId: chat.id) {
                            Text("печатает...")
                                .font(.caption2)
                                .foregroundStyle(themeManager.accentColor)
                        } else if themeManager.showOnlineStatus {
                            Text(chat.participant.isOnline ? "в сети" : lastSeenText)
                                .font(.caption2)
                                .foregroundStyle(.gray)
                        }
                    } else if chat.chatType == .group {
                        Text("\(currentChat.members.count) участников")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    } else if chat.chatType == .channel {
                        Text("\(currentChat.members.count) подписчиков")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 12) {
                Button {
                    startCall(type: .voice)
                } label: {
                    Image(systemName: "phone.fill")
                        .foregroundStyle(.gray)
                }
                
                Button {
                    startCall(type: .video)
                } label: {
                    Image(systemName: "video.fill")
                        .foregroundStyle(.gray)
                }
                
                if !currentChat.pinnedMessages.isEmpty {
                    Button {
                        showPinnedMessages = true
                    } label: {
                        Image(systemName: "pin.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var lastSeenText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.unitsStyle = .short
        return "был(а) " + formatter.localizedString(for: chat.participant.lastSeen, relativeTo: Date())
    }

    private func handleMediaTap(_ message: Message) {
        if message.mediaData != nil || message.mediaType == .image || message.mediaType == .video {
            selectedMessageForViewer = message
        }
    }

    private func handleSelectedPhotos(_ items: [PhotosPickerItem]) {
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    pendingPhotos.append(data)
                }
            }
            selectedPhotoItems = []
        }
    }

    private func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Send pending photos as grouped message with text
        if !pendingPhotos.isEmpty {
            for (index, photoData) in pendingPhotos.enumerated() {
                let isLast = index == pendingPhotos.count - 1
                let caption = isLast ? (trimmedText.isEmpty ? "📷" : trimmedText) : "📷"
                appState.sendMessage(to: chat.id, text: caption, mediaType: .image, mediaData: photoData)
            }
            pendingPhotos.removeAll()
            messageText = ""
            return
        }
        
        guard !trimmedText.isEmpty else { return }
        appState.sendMessage(to: chat.id, text: trimmedText)
        messageText = ""
    }

    // MARK: - Voice Recording

    private func startVoiceRecording() {
        isRecording = true
        recordingDuration = 0
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
        }
    }

    private func toggleVoiceRecording() {
        if isRecording { stopVoiceRecording() } else { startVoiceRecording() }
    }

    private func stopVoiceRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false

        let duration = recordingDuration
        guard duration > 0.5 else { recordingDuration = 0; return }

        let text = String(format: "Голосовое %.0fс", duration)
        appState.sendMessage(to: chat.id, text: text, mediaType: .voice)
        recordingDuration = 0
    }

    private func startCall(type: CallRecord.CallType) {
        // Record the call
        appState.addCallRecord(participant: chat.participant, callType: type, isOutgoing: true, duration: 0, isMissed: false)
        
        // Attempt real phone call via tel:// URL scheme
        let phoneNumber = chat.participant.phoneNumber
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        if !phoneNumber.isEmpty, let url = URL(string: "tel://\(phoneNumber)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Typing Indicator Bar (smooth animated dots — no blocky artifacts)
struct TypingIndicatorBar: View {
    let userName: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 10) {
            // Three animated bouncing dots using TimelineView for smooth animation
            TypingDotsView(color: themeManager.accentColor)
            
            Text("\(userName) печатает...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
                .opacity(0.9)
        )
    }
}

// MARK: - Animated Typing Dots
struct TypingDotsView: View {
    let color: Color
    @State private var phase: Double = 0
    
    private let dotSize: CGFloat = 7
    private let bounceHeight: CGFloat = 5
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: dotSize, height: dotSize)
                    .offset(y: sin(phase + Double(index) * .pi * 0.6) * bounceHeight)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

// MARK: - Pending Photos Strip
struct PendingPhotosStrip: View {
    let photos: [Data]
    let onClear: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(photos.indices, id: \.self) { index in
                    if let uiImage = UIImage(data: photos[index]) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGray6).opacity(0.5))
    }
}

// MARK: - Pinned Message Banner
struct PinnedMessageBanner: View {
    let message: Message
    let chatId: UUID
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "pin.fill")
                .font(.caption)
                .foregroundStyle(.orange)
            Text(message.text)
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
    }
}

// MARK: - Pinned Messages View
struct PinnedMessagesView: View {
    let chatId: UUID
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var currentChat: Chat {
        appState.chats.first { $0.id == chatId } ?? Chat(id: chatId, participant: User(id: UUID(), username: "", displayName: "", bio: "", avatarName: "person.circle.fill", isOnline: false, lastSeen: Date(), phoneNumber: "", avatarVideoBackgroundData: nil), messages: [], isPinned: false, isMuted: false, unreadCount: 0)
    }
    
    var pinnedMessages: [Message] {
        currentChat.pinnedMessages
    }
    
    var body: some View {
        NavigationStack {
            List(pinnedMessages) { message in
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
                        .font(.body)
                    HStack {
                        Text(message.formattedTime)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if message.isEdited {
                            Text("изменено")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .swipeActions {
                    Button {
                        appState.togglePinMessage(chatId: chatId, messageId: message.id)
                    } label: {
                        Label("Открепить", systemImage: "pin.slash")
                    }
                    .tint(.orange)
                }
            }
            .navigationTitle("Закреплённые")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Redesigned Attachment Popup View (Telegram-style grid with rounded rectangle icons)
struct RedesignedAttachmentPopupView: View {
    let onSelectCamera: () -> Void
    let onSelectPhoto: () -> Void
    let onSelectFile: () -> Void
    let onSelectVoice: () -> Void
    let onDismiss: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    /// Attachment options matching Telegram exactly
    private let attachmentOptions: [(icon: String, title: String, color: Color)] = [
        ("camera.fill", "Камера", Color(red: 0.20, green: 0.60, blue: 0.86)),
        ("photo.on.rectangle.angled", "Фото", Color(red: 0.30, green: 0.70, blue: 0.40)),
        ("doc.badge.plus", "Файл", Color(red: 0.60, green: 0.35, blue: 0.85)),
        ("mic.fill", "Голосовое", Color(red: 0.90, green: 0.40, blue: 0.30)),
        ("location.fill", "Геолокация", Color(red: 0.25, green: 0.55, blue: 0.90)),
        ("person.crop.circle.badge.plus", "Контакт", Color(red: 0.95, green: 0.60, blue: 0.20))
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Top row: Camera, Photo, File
            HStack(spacing: 0) {
                attachmentButton(
                    icon: attachmentOptions[0].icon,
                    title: attachmentOptions[0].title,
                    color: attachmentOptions[0].color,
                    action: onSelectCamera
                )
                attachmentButton(
                    icon: attachmentOptions[1].icon,
                    title: attachmentOptions[1].title,
                    color: attachmentOptions[1].color,
                    action: onSelectPhoto
                )
                attachmentButton(
                    icon: attachmentOptions[2].icon,
                    title: attachmentOptions[2].title,
                    color: attachmentOptions[2].color,
                    action: onSelectFile
                )
            }
            
            // Bottom row: Voice, Location, Contact
            HStack(spacing: 0) {
                attachmentButton(
                    icon: attachmentOptions[3].icon,
                    title: attachmentOptions[3].title,
                    color: attachmentOptions[3].color,
                    action: onSelectVoice
                )
                attachmentButton(
                    icon: attachmentOptions[4].icon,
                    title: attachmentOptions[4].title,
                    color: attachmentOptions[4].color,
                    action: onDismiss
                )
                attachmentButton(
                    icon: attachmentOptions[5].icon,
                    title: attachmentOptions[5].title,
                    color: attachmentOptions[5].color,
                    action: onDismiss
                )
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }
    
    // MARK: - Telegram-style rounded rectangle attachment button
    @ViewBuilder
    private func attachmentButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color)
                        .frame(width: 52, height: 52)
                        .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                }
                
                Text(title)
                    .font(.system(size: 11))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style (press animation)
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Read Receipt View (2 gray = sent, 1 blue = read, 2 blue = typing)
struct ReadReceiptView: View {
    let state: ReadReceiptState
    
    var body: some View {
        switch state {
        case .sent:
            // Two gray checkmarks
            HStack(spacing: -4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.gray.opacity(0.6))
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.gray.opacity(0.6))
            }
        case .read:
            // One blue checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(.blue)
        case .typing:
            // Two blue checkmarks
            HStack(spacing: -4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.blue)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.blue)
            }
        }
    }
}

// MARK: - MessageBubbleView (Telegram-like with tail, shadow, improved spacing)
struct MessageBubbleView: View {
    let message: Message
    let isOutgoing: Bool
    let chatId: UUID
    var isFirstInGroup: Bool = true
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appState: AppState

    /// Whether this message has visual media (image or video)
    private var hasVisualMedia: Bool {
        if let mt = message.mediaType {
            return (mt == .image || mt == .video) && message.mediaData != nil
        }
        return false
    }
    
    /// Read receipt state
    private var readReceiptState: ReadReceiptState {
        ReadReceiptState.forMessage(message, isOutgoing: isOutgoing, isContactTyping: appState.isTyping(chatId: chatId))
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            // Avatar for incoming messages
            if !isOutgoing {
                if isFirstInGroup {
                    avatarView
                } else {
                    Color.clear.frame(width: 28, height: 28)
                }
            }
            
            if isOutgoing { Spacer(minLength: 60) }

            VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 0) {
                // Media fills full width
                if hasVisualMedia {
                    if let mediaType = message.mediaType, let mediaData = message.mediaData {
                        FullWidthMediaPreview(message: message, mediaType: mediaType, mediaData: mediaData, isOutgoing: isOutgoing)
                    }
                    HStack(spacing: 4) {
                        Spacer()
                        Text(message.formattedTime)
                            .font(.caption2)
                            .foregroundStyle(.white)
                        if message.isEdited {
                            Text("изменено")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        if isOutgoing && themeManager.showReadReceipts {
                            ReadReceiptView(state: readReceiptState)
                        }
                        if message.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
                    .offset(y: -8)
                } else {
                    // Non-visual media or text-only
                    if let mediaType = message.mediaType {
                        if let mediaData = message.mediaData {
                            RealMediaPreviewView(message: message, mediaType: mediaType, mediaData: mediaData)
                        } else {
                            PlaceholderMediaPreviewView(mediaType: mediaType, text: message.text)
                        }
                    }

                    if !message.text.isEmpty && message.mediaType == nil {
                        Text(message.text)
                            .font(.system(size: themeManager.fontSize.size))
                            .foregroundStyle(isOutgoing ? .white : .primary)
                    }

                    HStack(spacing: 4) {
                        Text(message.formattedTime)
                            .font(.caption2)
                            .foregroundStyle(isOutgoing ? .white.opacity(0.7) : .secondary)
                        if message.isEdited {
                            Text("изменено")
                                .font(.caption2)
                                .foregroundStyle(isOutgoing ? .white.opacity(0.7) : .secondary)
                        }
                        if message.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                        if isOutgoing && themeManager.showReadReceipts {
                            ReadReceiptView(state: readReceiptState)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .padding(hasVisualMedia ? EdgeInsets() : EdgeInsets(top: 8, leading: 12, bottom: 6, trailing: 12))
            // Incoming messages: always gray (NO blue/themed background)
            .background(hasVisualMedia ? Color.clear : (isOutgoing ? themeManager.outgoingBubbleColor : Color(.systemGray6)))
            // Telegram-like bubble shape with tail on first message
            .clipShape(
                MessageBubbleShape(
                    isOutgoing: isOutgoing,
                    showTail: isFirstInGroup,
                    cornerRadius: themeManager.bubbleCornerRadius
                )
            )
            .shadow(
                color: isOutgoing && !hasVisualMedia ? themeManager.outgoingBubbleColor.opacity(0.25) : Color.clear,
                radius: 4, x: 0, y: 2
            )
            .overlay(
                hasVisualMedia ? MessageBubbleShape(
                    isOutgoing: isOutgoing,
                    showTail: isFirstInGroup,
                    cornerRadius: themeManager.bubbleCornerRadius
                )
                .stroke(Color(.systemGray4), lineWidth: 0.5) : nil
            )

            if !isOutgoing { Spacer(minLength: 60) }
            
            // Avatar for outgoing (none shown)
            if isOutgoing {
                Color.clear.frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, isFirstInGroup ? 4 : 0)
    }
    
    // MARK: - Avatar View (for incoming messages)
    @ViewBuilder
    private var avatarView: some View {
        // Show the chat participant's avatar for incoming messages
        if let avatarData = appState.globalUsers.first(where: { $0.id == message.senderId })?.avatarData,
           let uiImage = UIImage(data: avatarData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .clipShape(Circle())
        } else if let chat = appState.chats.first(where: { $0.id == chatId }),
                  let avatarData = chat.participant.avatarData,
                  let uiImage = UIImage(data: avatarData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .clipShape(Circle())
        } else {
            // Default avatar for incoming messages
            Image(systemName: "person.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.gray)
        }
    }
}

// MARK: - Message Bubble Shape (with tail/arrow like Telegram)
struct MessageBubbleShape: Shape {
    let isOutgoing: Bool
    let showTail: Bool
    let cornerRadius: CGFloat
    
    var animatableData: CGFloat {
        get { cornerRadius }
        set { }
    }
    
    func path(in rect: CGRect) -> Path {
        let r = cornerRadius
        let tailWidth: CGFloat = showTail ? 8 : 0
        let tailHeight: CGFloat = showTail ? 10 : 0
        
        var path = Path()
        
        if isOutgoing {
            // Outgoing: tail on bottom-right
            let bottomRightX = rect.maxX - tailWidth
            
            path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + r), control: CGPoint(x: rect.maxX, y: rect.minY))
            
            if showTail {
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r - tailHeight))
                path.addLine(to: CGPoint(x: rect.maxX + tailWidth, y: rect.maxY - tailHeight/2))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
            } else {
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
            }
            
            path.addQuadCurve(to: CGPoint(x: rect.maxX - r, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - r), control: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
            path.addQuadCurve(to: CGPoint(x: rect.minX + r, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        } else {
            // Incoming: tail on bottom-left
            path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + r), control: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - r, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
            
            if showTail {
                path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
                path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - r), control: CGPoint(x: rect.minX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - r - tailHeight))
                path.addLine(to: CGPoint(x: rect.minX - tailWidth, y: rect.maxY - tailHeight/2))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
            } else {
                path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
                path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - r), control: CGPoint(x: rect.minX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
            }
            
            path.addQuadCurve(to: CGPoint(x: rect.minX + r, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Full-Width Media Preview
struct FullWidthMediaPreview: View {
    let message: Message
    let mediaType: Message.MediaType
    let mediaData: Data
    let isOutgoing: Bool
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Group {
            switch mediaType {
            case .image:
                if let uiImage = UIImage(data: mediaData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: themeManager.bubbleCornerRadius))
                } else {
                    PlaceholderMediaPreviewView(mediaType: .image, text: "Фото")
                }
            case .video:
                FullWidthVideoThumbnail(videoData: mediaData, cornerRadius: themeManager.bubbleCornerRadius)
            case .voice, .document:
                EmptyView()
            }
        }
    }
}

// MARK: - Full-Width Video Thumbnail
struct FullWidthVideoThumbnail: View {
    let videoData: Data
    let cornerRadius: CGFloat
    @State private var thumbnailImage: UIImage?

    var body: some View {
        ZStack {
            if let thumb = thumbnailImage {
                Image(uiImage: thumb)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .overlay(RoundedRectangle(cornerRadius: cornerRadius).fill(Color.black.opacity(0.15)))
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gray.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            }
            Circle().fill(.black.opacity(0.5)).frame(width: 54, height: 54)
            Image(systemName: "play.fill").font(.title).foregroundStyle(.white)
        }
        .onAppear { generateThumbnail() }
    }

    private func generateThumbnail() {
        DispatchQueue.global(qos: .userInitiated).async {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("video_\(UUID().uuidString).mp4")
            do {
                try videoData.write(to: tempURL)
                let asset = AVAsset(url: tempURL)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                if let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil) {
                    DispatchQueue.main.async { thumbnailImage = UIImage(cgImage: cgImage) }
                }
                try? FileManager.default.removeItem(at: tempURL)
            } catch { }
        }
    }
}

// MARK: - Real Media Preview
struct RealMediaPreviewView: View {
    let message: Message
    let mediaType: Message.MediaType
    let mediaData: Data
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isPlayingVoice = false
    @State private var voiceProgress: Double = 0
    @State private var voiceTimer: Timer?

    var body: some View {
        Group {
            switch mediaType {
            case .image:
                if let uiImage = UIImage(data: mediaData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 240, maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    PlaceholderMediaPreviewView(mediaType: .image, text: "Фото")
                }
            case .video:
                VideoThumbnailView(videoData: mediaData)
            case .voice:
                voiceWaveformView
            case .document:
                documentView
            }
        }
    }

    private var voiceWaveformView: some View {
        HStack(spacing: 8) {
            Button { toggleVoicePlayback() } label: {
                Image(systemName: isPlayingVoice ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.gray)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    HStack(spacing: 2) {
                        ForEach(0..<25, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 3, height: CGFloat.random(in: 8...24))
                        }
                    }
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: geo.size.width * voiceProgress, height: geo.size.height)
                }
            }
            .frame(height: 28)
            .frame(maxWidth: 140)

            Text(message.text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: 220)
    }

    private var documentView: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .font(.title)
                .foregroundStyle(.gray)
            VStack(alignment: .leading) {
                Text("Документ").font(.subheadline).lineLimit(1)
                Text(ByteCountFormatter.string(fromByteCount: Int64(mediaData.count), countStyle: .file))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 180, alignment: .leading)
    }

    private func toggleVoicePlayback() {
        if isPlayingVoice {
            voiceTimer?.invalidate(); voiceTimer = nil; isPlayingVoice = false
        } else {
            isPlayingVoice = true; voiceProgress = 0
            voiceTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                voiceProgress += 0.02
                if voiceProgress >= 1.0 {
                    voiceTimer?.invalidate(); voiceTimer = nil; isPlayingVoice = false; voiceProgress = 0
                }
            }
        }
    }
}

// MARK: - Video Thumbnail View
struct VideoThumbnailView: View {
    let videoData: Data
    @State private var thumbnailImage: UIImage?

    var body: some View {
        ZStack {
            if let thumb = thumbnailImage {
                Image(uiImage: thumb)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 260, maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.2)))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 240, height: 160)
            }
            Circle().fill(.black.opacity(0.5)).frame(width: 50, height: 50)
            Image(systemName: "play.fill").font(.title2).foregroundStyle(.white)
        }
        .onAppear { generateThumbnail() }
    }

    private func generateThumbnail() {
        DispatchQueue.global(qos: .userInitiated).async {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("video_\(UUID().uuidString).mp4")
            do {
                try videoData.write(to: tempURL)
                let asset = AVAsset(url: tempURL)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                if let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil) {
                    DispatchQueue.main.async { thumbnailImage = UIImage(cgImage: cgImage) }
                }
                try? FileManager.default.removeItem(at: tempURL)
            } catch { }
        }
    }
}

// MARK: - Placeholder Media Preview
struct PlaceholderMediaPreviewView: View {
    let mediaType: Message.MediaType
    let text: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Group {
            switch mediaType {
            case .image:
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.3)).frame(width: 200, height: 150)
                    Image(systemName: "photo.fill").font(.system(size: 40)).foregroundStyle(.gray)
                }
            case .video:
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.3)).frame(width: 200, height: 150)
                    Circle().fill(.black.opacity(0.5)).frame(width: 50, height: 50)
                    Image(systemName: "play.fill").font(.title2).foregroundStyle(.white)
                }
            case .voice:
                HStack(spacing: 8) {
                    Image(systemName: "play.circle.fill").font(.title2).foregroundStyle(.gray)
                    HStack(spacing: 2) {
                        ForEach(0..<20, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.gray.opacity(0.6))
                                .frame(width: 3, height: CGFloat.random(in: 8...24))
                        }
                    }
                    Text(text).font(.caption).foregroundStyle(.secondary)
                }
                .frame(width: 180)
            case .document:
                HStack(spacing: 12) {
                    Image(systemName: "doc.fill").font(.title).foregroundStyle(.gray)
                    VStack(alignment: .leading) { Text(text).font(.subheadline).lineLimit(1) }
                }
                .frame(width: 180, alignment: .leading)
            }
        }
    }
}

// MARK: - Full-screen Media Viewer
struct MediaFullViewerView: View {
    let message: Message
    let dismissAction: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isPlayingVoice = false
    @State private var voiceProgress: Double = 0
    @State private var voiceTimer: Timer?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                HStack {
                    Spacer()
                    Button {
                        voiceTimer?.invalidate(); dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill").font(.title).foregroundStyle(.white).padding()
                    }
                }
                Spacer()
                mediaContent
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var mediaContent: some View {
        if let mediaType = message.mediaType {
            switch mediaType {
            case .image:
                if let data = message.mediaData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage).resizable().aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            case .video:
                if let data = message.mediaData {
                    VideoPlayerView(videoData: data).frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            case .voice:
                VStack(spacing: 24) {
                    Image(systemName: "waveform").font(.system(size: 60)).foregroundStyle(.white)
                    Text(message.text).font(.headline).foregroundStyle(.white)
                    Button { toggleVoicePlayback() } label: {
                        Image(systemName: isPlayingVoice ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64)).foregroundStyle(.white)
                    }
                    ProgressView(value: voiceProgress).progressViewStyle(.linear).tint(.white).padding(.horizontal, 40)
                }
            case .document:
                VStack(spacing: 16) {
                    Image(systemName: "doc.fill").font(.system(size: 60)).foregroundStyle(.white)
                    Text(message.text).font(.headline).foregroundStyle(.white)
                    if let data = message.mediaData {
                        Text("Размер: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
    }

    private func toggleVoicePlayback() {
        if isPlayingVoice {
            voiceTimer?.invalidate(); voiceTimer = nil; isPlayingVoice = false
        } else {
            isPlayingVoice = true; voiceProgress = 0
            voiceTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                voiceProgress += 0.01
                if voiceProgress >= 1.0 {
                    voiceTimer?.invalidate(); voiceTimer = nil; isPlayingVoice = false; voiceProgress = 0
                }
            }
        }
    }
}

// MARK: - Video Player View
struct VideoPlayerView: View {
    let videoData: Data
    @State private var player: AVPlayer?

    var body: some View {
        VStack {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
            } else {
                ZStack {
                    Color.black
                    ProgressView().progressViewStyle(.circular).tint(.white)
                }
                .onAppear { setupPlayer() }
            }
        }
    }

    private func setupPlayer() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("playback_\(UUID().uuidString).mp4")
        do {
            try videoData.write(to: tempURL)
            player = AVPlayer(url: tempURL)
        } catch { }
    }
}

// MARK: - Message Input Bar (Telegram-like: pill shape, gray + button, clean mic)
struct MessageInputBar: View {
    @Binding var text: String
    @Binding var isRecording: Bool
    @Binding var recordingDuration: TimeInterval
    let onSend: () -> Void
    let onAttachment: () -> Void
    let onVoiceRecordToggle: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    private var formattedDuration: String {
        String(format: "%d:%02d", Int(recordingDuration) / 60, Int(recordingDuration) % 60)
    }

    var body: some View {
        HStack(spacing: 6) {
            // Gray + button (Telegram style)
            Button(action: onAttachment) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(.systemGray))
            }

            if isRecording {
                HStack(spacing: 8) {
                    Circle().fill(.red).frame(width: 8, height: 8)
                        .pulseAnimation()
                    Text(formattedDuration).font(.body.monospacedDigit()).foregroundStyle(.primary)
                    Text("Голосовое сообщение...").font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color(.systemGray5))
                )
            } else {
                // Pill-shaped text field
                TextField("Сообщение", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray5))
                    )
                    .lineLimit(1...5)
            }

            // Voice / Send button (gray when voice, themed when send)
            Button {
                if isRecording || text.isEmpty { onVoiceRecordToggle() } else { onSend() }
            } label: {
                ZStack {
                    if isRecording {
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 36, height: 36)
                    } else if !text.isEmpty {
                        Circle()
                            .fill(themeManager.accentColor)
                            .frame(width: 36, height: 36)
                    }
                    
                    Image(systemName: isRecording ? "stop.circle.fill" : (text.isEmpty ? "mic.fill" : "arrow.up"))
                        .font(.system(size: text.isEmpty ? 20 : 16, weight: .semibold))
                        .foregroundStyle(isRecording ? .red : (text.isEmpty ? Color(.systemGray) : .white))
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
    }
}

// MARK: - Pulse Animation Modifier
extension View {
    func pulseAnimation() -> some View {
        self.modifier(PulseModifier())
    }
}

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.3 : 1.0)
            .opacity(isPulsing ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

// MARK: - User Profile View
struct UserProfileView: View {
    let user: User
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Profile header
                Section {
                    VStack(spacing: 16) {
                        if let avatarData = user.avatarData,
                           let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: user.avatarName)
                                .font(.system(size: 80))
                                .foregroundStyle(.gray)
                        }
                        
                        VStack(spacing: 4) {
                            Text(user.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(user.username)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                Circle()
                                    .fill(user.isOnline ? .green : .gray)
                                    .frame(width: 8, height: 8)
                                Text(user.isOnline ? "в сети" : "не в сети")
                                    .font(.caption)
                                    .foregroundStyle(user.isOnline ? .green : .secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                .listRowBackground(Color.clear)
                
                Section("Информация") {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundStyle(.gray)
                        VStack(alignment: .leading) {
                            Text(user.phoneNumber)
                            Text("Мобильный")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "at")
                            .foregroundStyle(.gray)
                        VStack(alignment: .leading) {
                            Text(user.username)
                            Text("Имя пользователя")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if !user.bio.isEmpty {
                        HStack(alignment: .top) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.gray)
                            VStack(alignment: .leading) {
                                Text(user.bio)
                                Text("О себе")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}
