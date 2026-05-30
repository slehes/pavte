import SwiftUI
import PhotosUI
import AVKit
import AVFoundation
import UniformTypeIdentifiers

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

    var currentChat: Chat {
        appState.chats.first { $0.id == chat.id } ?? chat
    }

    var body: some View {
        VStack(spacing: 0) {
            messagesList
            inputBar
        }
        .navigationTitle(chat.displayName)
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
    }

    // MARK: - Subviews

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(currentChat.messages) { message in
                        MessageBubbleView(message: message, isOutgoing: message.senderId == appState.currentUser.id)
                            .id(message.id)
                            .onTapGesture { handleMediaTap(message) }
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
                    withAnimation { proxy.scrollTo(lastMessage.id, anchor: .bottom) }
                }
            }
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            // Attachment popup menu — appears just above the input bar
            if showAttachmentPopup {
                AttachmentPopupView(
                    onSelectPhoto: {
                        showAttachmentPopup = false
                        showPhotoPicker = true
                    },
                    onSelectFile: {
                        showAttachmentPopup = false
                        showFilePicker = true
                    },
                    onSelectVoice: {
                        showAttachmentPopup = false
                        startVoiceRecording()
                    },
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.2)) {
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
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAttachmentPopup.toggle()
                    }
                },
                onVoiceRecordToggle: toggleVoiceRecording,
                onVoiceCall: { startCall(type: .voice) },
                onVideoCall: { startCall(type: .video) }
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
                VStack(spacing: 0) {
                    Text(chat.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if chat.chatType == .personal && themeManager.showOnlineStatus {
                        Text(chat.participant.isOnline ? "в сети" : lastSeenText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if chat.chatType == .group {
                        Text("\(currentChat.members.count) участников")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if chat.chatType == .channel {
                        Text("\(currentChat.members.count) подписчиков")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
                    let identifier = item.itemIdentifier ?? ""
                    let isVideo = identifier.hasPrefix("Video") ||
                        (item.supportedContentTypes.first?.identifier.contains("video") ?? false)
                    let mediaType: Message.MediaType = isVideo ? .video : .image
                    let text = isVideo ? "Видео" : "Фото"
                    appState.sendMessage(to: chat.id, text: text, mediaType: mediaType, mediaData: data)
                    // NO auto-reply — messages are truly sent
                }
            }
            selectedPhotoItems = []
        }
    }

    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        appState.sendMessage(to: chat.id, text: messageText)
        messageText = ""
        // NO auto-reply — messages are truly sent
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
        // NO auto-reply — messages are truly sent
    }

    private func startCall(type: CallRecord.CallType) {
        appState.addCallRecord(participant: chat.participant, callType: type, isOutgoing: true, duration: 0, isMissed: false)
    }
}

// MARK: - Attachment Popup View (appears near the paperclip button)
struct AttachmentPopupView: View {
    let onSelectPhoto: () -> Void
    let onSelectFile: () -> Void
    let onSelectVoice: () -> Void
    let onDismiss: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            // Dark rounded popup menu
            VStack(spacing: 0) {
                Button {
                    onSelectPhoto()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title3)
                            .foregroundStyle(themeManager.accentColor)
                            .frame(width: 32, height: 32)
                        Text("Фото / Видео из галереи")
                            .font(.body)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }

                Divider().padding(.horizontal, 12)

                Button {
                    onSelectFile()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.badge.plus")
                            .font(.title3)
                            .foregroundStyle(themeManager.accentColor)
                            .frame(width: 32, height: 32)
                        Text("Файл из проводника")
                            .font(.body)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }

                Divider().padding(.horizontal, 12)

                Button {
                    onSelectVoice()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mic.fill")
                            .font(.title3)
                            .foregroundStyle(themeManager.accentColor)
                            .frame(width: 32, height: 32)
                        Text("Голосовое сообщение")
                            .font(.body)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray5))
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - MessageBubbleView
struct MessageBubbleView: View {
    let message: Message
    let isOutgoing: Bool
    @EnvironmentObject var themeManager: ThemeManager

    /// Whether this message has visual media (image or video)
    private var hasVisualMedia: Bool {
        if let mt = message.mediaType {
            return (mt == .image || mt == .video) && message.mediaData != nil
        }
        return false
    }

    var body: some View {
        HStack {
            if isOutgoing { Spacer(minLength: 60) }

            VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 0) {
                // Media fills full width — no padding around it
                if hasVisualMedia {
                    if let mediaType = message.mediaType, let mediaData = message.mediaData {
                        FullWidthMediaPreview(message: message, mediaType: mediaType, mediaData: mediaData, isOutgoing: isOutgoing)
                    }
                    // Time overlay at the bottom of media
                    HStack(spacing: 4) {
                        Spacer()
                        Text(message.formattedTime)
                            .font(.caption2)
                            .foregroundStyle(.white)
                        if isOutgoing && themeManager.showReadReceipts {
                            Image(systemName: message.isRead ? "checkmark.circle.fill" : "checkmark")
                                .font(.caption2)
                                .foregroundStyle(.white)
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
                    // Non-visual media (voice, document) or text-only
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
                        if isOutgoing && themeManager.showReadReceipts {
                            Image(systemName: message.isRead ? "checkmark.circle.fill" : "checkmark")
                                .font(.caption2)
                                .foregroundStyle(isOutgoing ? .white.opacity(0.7) : .secondary)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(hasVisualMedia ? .zero : EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            .background(hasVisualMedia ? Color.clear : (isOutgoing ? themeManager.outgoingBubbleColor : themeManager.incomingBubbleColor))
            .clipShape(RoundedRectangle(cornerRadius: themeManager.bubbleCornerRadius))
            .overlay(
                // Border for media-only bubbles
                hasVisualMedia ? RoundedRectangle(cornerRadius: themeManager.bubbleCornerRadius)
                    .stroke(Color(.systemGray4), lineWidth: 0.5) : nil
            )

            if !isOutgoing { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Full-Width Media Preview (fills entire bubble)
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
                    .foregroundStyle(themeManager.accentColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    HStack(spacing: 2) {
                        ForEach(0..<25, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(themeManager.accentColor.opacity(0.3))
                                .frame(width: 3, height: CGFloat.random(in: 8...24))
                        }
                    }
                    Rectangle()
                        .fill(themeManager.accentColor.opacity(0.15))
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
                .foregroundStyle(themeManager.accentColor)
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
                    Image(systemName: "play.circle.fill").font(.title2).foregroundStyle(themeManager.accentColor)
                    HStack(spacing: 2) {
                        ForEach(0..<20, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(themeManager.accentColor.opacity(0.6))
                                .frame(width: 3, height: CGFloat.random(in: 8...24))
                        }
                    }
                    Text(text).font(.caption).foregroundStyle(.secondary)
                }
                .frame(width: 180)
            case .document:
                HStack(spacing: 12) {
                    Image(systemName: "doc.fill").font(.title).foregroundStyle(themeManager.accentColor)
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

// MARK: - Message Input Bar (Redesigned: +, text, mic, phone, video)
struct MessageInputBar: View {
    @Binding var text: String
    @Binding var isRecording: Bool
    @Binding var recordingDuration: TimeInterval
    let onSend: () -> Void
    let onAttachment: () -> Void
    let onVoiceRecordToggle: () -> Void
    let onVoiceCall: () -> Void
    let onVideoCall: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    private var formattedDuration: String {
        String(format: "%d:%02d", Int(recordingDuration) / 60, Int(recordingDuration) % 60)
    }

    var body: some View {
        HStack(spacing: 8) {
            // + button (attachment)
            Button(action: onAttachment) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(themeManager.accentColor)
            }

            if isRecording {
                HStack(spacing: 8) {
                    Circle().fill(.red).frame(width: 8, height: 8)
                    Text(formattedDuration).font(.body.monospacedDigit()).foregroundStyle(.primary)
                    Text("Голосовое сообщение...").font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                TextField("Сообщение", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 20))
                    .lineLimit(1...5)
            }

            // Voice message / Send button
            Button {
                if isRecording || text.isEmpty { onVoiceRecordToggle() } else { onSend() }
            } label: {
                Image(systemName: isRecording ? "stop.circle.fill" : (text.isEmpty ? "mic.fill" : "arrow.up.circle.fill"))
                    .font(.title2)
                    .foregroundStyle(isRecording ? .red : themeManager.accentColor)
            }

            // Phone call button
            Button(action: onVoiceCall) {
                Image(systemName: "phone.fill")
                    .font(.body)
                    .foregroundStyle(themeManager.accentColor)
                    .frame(width: 32, height: 32)
                    .background(themeManager.accentColor.opacity(0.12))
                    .clipShape(Circle())
            }

            // Video call button
            Button(action: onVideoCall) {
                Image(systemName: "video.fill")
                    .font(.body)
                    .foregroundStyle(themeManager.accentColor)
                    .frame(width: 32, height: 32)
                    .background(themeManager.accentColor.opacity(0.12))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
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
                Section {
                    VStack(spacing: 16) {
                        if let avatarData = user.avatarData, let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: user.avatarName).font(.system(size: 80)).foregroundStyle(themeManager.accentColor)
                        }
                        Text(user.displayName).font(.title).fontWeight(.bold)
                        if user.isOnline { Text("в сети").foregroundStyle(.green) }
                    }
                    .frame(maxWidth: .infinity).padding(.vertical)
                }
                .listRowBackground(Color.clear)

                Section("Информация") {
                    LabeledContent("Никнейм", value: user.username)
                    LabeledContent("Телефон", value: user.phoneNumber)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("О себе").foregroundStyle(.secondary)
                        Text(user.bio)
                    }
                }

                Section {
                    Button { } label: { Label("Написать сообщение", systemImage: "message.fill") }
                    Button { } label: { Label("Позвонить", systemImage: "phone.fill") }
                    Button { } label: { Label("Видеозвонок", systemImage: "video.fill") }
                }

                Section {
                    Button(role: .destructive) { } label: { Label("Заблокировать", systemImage: "hand.raised.fill") }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Готово") { dismiss() } }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChatDetailView(chat: Chat(
            id: UUID(),
            participant: User(
                id: UUID(), username: "@test", displayName: "Тест",
                bio: "Тестовый пользователь", avatarName: "person.circle.fill",
                isOnline: true, lastSeen: Date(), phoneNumber: "+7 999 000-00-00"
            ),
            messages: [
                Message(id: UUID(), senderId: UUID(), text: "Привет!", timestamp: Date(), isRead: true),
            ],
            isPinned: false, isMuted: false, unreadCount: 0
        ))
    }
    .environmentObject(AppState())
    .environmentObject(ThemeManager())
}
