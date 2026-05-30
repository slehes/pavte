import SwiftUI

// MARK: - AI Chat Model
struct AIChatMessage: Identifiable {
    let id: UUID
    let isUser: Bool
    var text: String
    let timestamp: Date
    var isTyping: Bool = false
    
    init(id: UUID = UUID(), isUser: Bool, text: String, timestamp: Date = Date(), isTyping: Bool = false) {
        self.id = id
        self.isUser = isUser
        self.text = text
        self.timestamp = timestamp
        self.isTyping = isTyping
    }
}

// MARK: - AI Chat View (Modal — dark theme, ChatGPT-style)
struct AIChatView: View {
    @Environment(\.dismiss) var dismiss
    @State private var messages: [AIChatMessage] = []
    @State private var inputText = ""
    @State private var isAITyping = false
    @State private var displayedText = ""
    @State private var currentTypingMessageId: UUID?
    @FocusState private var isInputFocused: Bool
    
    // AI personality responses
    private let aiResponses: [String] = [
        "Привет! Я ИИ-ассистент Pavte. Чем могу помочь?",
        "Это отличный вопрос! Давайте разберёмся вместе.",
        "Я могу помочь с настройками мессенджера, ответить на вопросы о функциях или просто поболтать.",
        "Интересная мысль! Расскажите подробнее.",
        "Я всегда рад помочь. Спрашивайте что угодно!",
        "Pavte — это современный мессенджер с защитой данных и удобным интерфейсом.",
        "Хороший вопрос! Вот что я думаю по этому поводу...",
        "Давайте рассмотрим это с разных сторон.",
        "Я понимаю вашу точку зрения. Вот альтернативный подход.",
        "Спасибо за вопрос! Это одна из самых частых тем."
    ]
    
    private let suggestionChips: [String] = [
        "Что умеет Pavte?",
        "Как настроить тему?",
        "Как изменить номер?",
        "Расскажи о себе"
    ]
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                aiHeader
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Welcome message if no messages
                            if messages.isEmpty {
                                aiWelcomeSection
                            }
                            
                            ForEach(messages) { message in
                                AIChatBubbleView(
                                    message: message,
                                    displayedText: message.id == currentTypingMessageId ? displayedText : message.text
                                )
                                .id(message.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastMsg = messages.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastMsg.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: displayedText) { _, _ in
                        if let typingId = currentTypingMessageId {
                            withAnimation(.easeOut(duration: 0.1)) {
                                proxy.scrollTo(typingId, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Suggestion chips
                if messages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(suggestionChips, id: \.self) { chip in
                                Button {
                                    sendUserMessage(chip)
                                } label: {
                                    Text(chip)
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.1))
                                                .overlay(
                                                    Capsule()
                                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                )
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
                
                // Input bar
                aiInputBar
            }
        }
    }
    
    // MARK: - Header
    private var aiHeader: some View {
        HStack(spacing: 12) {
            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            
            // AI Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple, Color.indigo, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Pavte AI")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                    Text("В сети")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
            
            Spacer()
            
            // New chat button
            Button {
                messages.removeAll()
                displayedText = ""
                currentTypingMessageId = nil
            } label: {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.8))
    }
    
    // MARK: - Welcome Section
    private var aiWelcomeSection: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.6), Color.indigo.opacity(0.6), Color.blue.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .blur(radius: 2)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Text("Pavte AI")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text("ИИ-ассистент мессенджера Pavte.\nЗадайте любой вопрос или попросите помощи.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer().frame(height: 20)
        }
    }
    
    // MARK: - Input Bar
    private var aiInputBar: some View {
        HStack(spacing: 12) {
            // Text field
            HStack(spacing: 8) {
                TextField("Спросите что-нибудь...", text: $inputText)
                    .font(.body)
                    .foregroundStyle(.white)
                    .tint(.purple)
                    .focused($isInputFocused)
                
                if !inputText.isEmpty {
                    Button {
                        inputText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            
            // Send button
            Button {
                sendUserMessage(inputText)
            } label: {
                Image(systemName: "arrow.up")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Group {
                            if inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                                Circle().fill(Color.white.opacity(0.1))
                            } else {
                                Circle().fill(LinearGradient(
                                    colors: [Color.purple, Color.indigo],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                            }
                        }
                    )
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isAITyping)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.8))
    }
    
    // MARK: - Message Sending
    private func sendUserMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isAITyping else { return }
        
        let userMsg = AIChatMessage(isUser: true, text: trimmed, timestamp: Date())
        messages.append(userMsg)
        inputText = ""
        
        // AI response with typing animation
        generateAIResponse(for: trimmed)
    }
    
    private func generateAIResponse(for userText: String) {
        isAITyping = true
        
        // Create a placeholder AI message
        let aiMsgId = UUID()
        let aiMsg = AIChatMessage(id: aiMsgId, isUser: false, text: "", timestamp: Date(), isTyping: true)
        messages.append(aiMsg)
        currentTypingMessageId = aiMsgId
        displayedText = ""
        
        // Determine AI response
        let response = pickResponse(for: userText)
        
        // Simulate typing with 1-3 character chunks
        var charIndex = 0
        let chars = Array(response)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { timer in
                if charIndex < chars.count {
                    // Add 1-3 characters at a time
                    let chunkSize = min(Int.random(in: 1...3), chars.count - charIndex)
                    for i in 0..<chunkSize {
                        if charIndex + i < chars.count {
                            displayedText.append(chars[charIndex + i])
                        }
                    }
                    charIndex += chunkSize
                    
                    // Update the message text progressively
                    if let idx = messages.firstIndex(where: { $0.id == aiMsgId }) {
                        messages[idx].text = displayedText
                    }
                } else {
                    timer.invalidate()
                    // Finalize the message
                    if let idx = messages.firstIndex(where: { $0.id == aiMsgId }) {
                        messages[idx].isTyping = false
                        messages[idx].text = response
                    }
                    displayedText = response
                    isAITyping = false
                    currentTypingMessageId = nil
                }
            }
        }
    }
    
    private func pickResponse(for userText: String) -> String {
        let lower = userText.lowercased()
        
        if lower.contains("pavte") || lower.contains("умеет") || lower.contains("может") {
            return "Pavte — это современный мессенджер с множеством функций:\n\n• Отправка текстовых сообщений, фото, видео и файлов\n• Голосовые и видеозвонки\n• Групповые чаты и каналы\n• Настраиваемые темы и обои\n• Видео-фон для профиля\n• Защита кодом-паролем и 2FA\n• Поиск по юзернейму\n\nВсе данные хранятся локально на вашем устройстве."
        } else if lower.contains("тема") || lower.contains("оформлен") || lower.contains("цвет") {
            return "Чтобы настроить тему мессенджера:\n\n1. Откройте Настройки\n2. Выберите «Тема и цвета»\n3. Переключите тёмную/светлую тему\n4. Выберите цвет акцента\n\nТакже вы можете настроить фон чатов в разделе «Фон чатов» — доступны градиенты, узоры и свои фото."
        } else if lower.contains("номер") || lower.contains("телефон") {
            return "Чтобы изменить номер телефона:\n\n1. Откройте Настройки → Профиль\n2. Нажмите на «Номер телефона»\n3. Введите любой новый номер\n4. Нажмите «Сохранить»\n\nНомер можно изменить на абсолютно любой — формат не ограничен."
        } else if lower.contains("привет") || lower.contains("здравствуй") || lower.contains("хай") {
            return "Привет! 👋 Я ИИ-ассистент Pavte. Рад вас видеть!\n\nМогу помочь с настройками мессенджера, ответить на вопросы о функциях или просто поболтать. Что вас интересует?"
        } else if lower.contains("расскажи о себе") || lower.contains("кто ты") || lower.contains("что ты") {
            return "Я — ИИ-ассистент встроенный в мессенджер Pavte. Я создан чтобы помочь вам:\n\n• Разобраться в функциях мессенджера\n• Настроить приложение под себя\n• Ответить на частые вопросы\n• Поддержать разговор\n\nЯ работаю прямо на вашем устройстве и всегда готов помочь!"
        } else if lower.contains("звонк") || lower.contains("позвонить") {
            return "Чтобы совершить звонок в Pavte:\n\n1. Откройте чат с контактом\n2. Нажмите на иконку телефона (аудио) или камеры (видео) в правом верхнем углу\n3. Также можно позвонить из раздела «Звонки» или из профиля контакта\n\nPavte использует системный набор номера для реальных звонков."
        } else if lower.contains("фон") || lower.contains("обои") || lower.contains("видео фон") {
            return "Настройка фона в Pavte:\n\n• Глобальный фон: Настройки → Фон чатов — выберите градиент, узор или загрузите своё фото/видео\n• Видео-фон профиля: Настройки → Профиль → Видео-фон — добавьте видео на фон аватара\n\nВидео автоматически зацикливается и воспроизводится в фоне."
        } else {
            return aiResponses.randomElement() ?? "Интересный вопрос! Я помогу вам разобраться. Спрашивайте что угодно о мессенджере Pavte или его функциях."
        }
    }
}

// MARK: - AI Chat Bubble View
struct AIChatBubbleView: View {
    let message: AIChatMessage
    let displayedText: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if !message.isUser {
                // AI avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            
            if message.isUser { Spacer(minLength: 60) }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(displayedText)
                    .font(.body)
                    .foregroundStyle(.white)
                    .lineLimit(nil)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(message.isUser ? Color.indigo : Color.white.opacity(0.08))
                    )
                    .overlay(
                        !message.isUser
                        ? RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        : nil
                    )
                
                // Timestamp
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.3))
            }
            
            if !message.isUser { Spacer(minLength: 60) }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    AIChatView()
}
