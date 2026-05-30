import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            List {
                // Profile section
                Section {
                    NavigationLink(destination: ProfileSettingsView()) {
                        HStack(spacing: 16) {
                            Image(systemName: appState.currentUser.avatarName)
                                .font(.system(size: 60))
                                .foregroundStyle(themeManager.accentColor)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(appState.currentUser.displayName)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text(appState.currentUser.username)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Text(appState.currentUser.phoneNumber)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Appearance
                Section {
                    NavigationLink(destination: AppearanceSettingsView()) {
                        SettingsRow(icon: "paintbrush.fill", color: .purple, title: "Тема и цвета")
                    }
                    
                    NavigationLink(destination: ChatAppearanceView()) {
                        SettingsRow(icon: "bubble.left.and.bubble.right.fill", color: .blue, title: "Оформление чатов")
                    }
                    
                    NavigationLink(destination: WallpaperSettingsView()) {
                        SettingsRow(icon: "photo.fill", color: .green, title: "Фон чатов")
                    }
                } header: {
                    Text("Оформление")
                }
                
                // Notifications
                Section {
                    NavigationLink(destination: NotificationSettingsView()) {
                        SettingsRow(icon: "bell.fill", color: .red, title: "Уведомления")
                    }
                } header: {
                    Text("Уведомления")
                }
                
                // Privacy
                Section {
                    NavigationLink(destination: PrivacySettingsView()) {
                        SettingsRow(icon: "lock.fill", color: .gray, title: "Приватность")
                    }
                    
                    NavigationLink(destination: BlockedUsersView()) {
                        SettingsRow(icon: "hand.raised.fill", color: .orange, title: "Заблокированные")
                    }
                } header: {
                    Text("Конфиденциальность")
                }
                
                // Data
                Section {
                    NavigationLink(destination: StorageSettingsView()) {
                        SettingsRow(icon: "internaldrive.fill", color: .cyan, title: "Хранилище")
                    }
                    
                    NavigationLink(destination: NetworkSettingsView()) {
                        SettingsRow(icon: "wifi", color: .blue, title: "Сеть и загрузка")
                    }
                } header: {
                    Text("Данные")
                }
                
                // Help
                Section {
                    NavigationLink(destination: FAQView()) {
                        SettingsRow(icon: "questionmark.circle.fill", color: .blue, title: "Часто задаваемые вопросы")
                    }
                    
                    Button {
                        // Contact support
                    } label: {
                        SettingsRow(icon: "envelope.fill", color: .green, title: "Связаться с поддержкой")
                    }
                } header: {
                    Text("Помощь")
                }
                
                // About
                Section {
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Настройки")
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let color: Color
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            Text(title)
        }
    }
}

// MARK: - Profile Settings
struct ProfileSettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var showSavedAlert = false
    
    var body: some View {
        Form {
            Section {
                VStack {
                    Button {
                        // Image picker
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            Image(systemName: appState.currentUser.avatarName)
                                .font(.system(size: 80))
                                .foregroundStyle(themeManager.accentColor)
                            
                            Image(systemName: "camera.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .background(Circle().fill(themeManager.accentColor))
                        }
                    }
                    
                    Text("Нажмите чтобы изменить фото")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            
            Section {
                TextField("Имя", text: $displayName)
                TextField("Имя пользователя", text: $username)
                    .textInputAutocapitalization(.never)
            } header: {
                Text("Основная информация")
            }
            
            Section {
                TextField("Расскажите о себе", text: $bio, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Text("О себе")
            }
            
            Section {
                HStack {
                    Text("Телефон")
                    Spacer()
                    Text(appState.currentUser.phoneNumber)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                Button("Сохранить изменения") {
                    appState.updateProfile(
                        displayName: displayName.isEmpty ? appState.currentUser.displayName : displayName,
                        bio: bio,
                        username: username.isEmpty ? appState.currentUser.username : username
                    )
                    showSavedAlert = true
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(themeManager.accentColor)
            }
        }
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            displayName = appState.currentUser.displayName
            username = appState.currentUser.username
            bio = appState.currentUser.bio
        }
        .alert("Сохранено", isPresented: $showSavedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Ваш профиль был обновлён")
        }
    }
}

// MARK: - Appearance Settings
struct AppearanceSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Form {
            Section {
                Toggle("Тёмная тема", isOn: $themeManager.isDarkMode)
            } header: {
                Text("Тема")
            }
            
            Section {
                ForEach(ThemeColor.allCases, id: \.self) { color in
                    Button {
                        withAnimation {
                            themeManager.themeColor = color
                        }
                    } label: {
                        HStack {
                            Circle()
                                .fill(color.color)
                                .frame(width: 24, height: 24)
                            
                            Text(color.rawValue)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if themeManager.themeColor == color {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(themeManager.accentColor)
                            }
                        }
                    }
                }
            } header: {
                Text("Цвет акцента")
            }
            
            Section {
                VStack(spacing: 12) {
                    HStack {
                        Text("Входящее сообщение")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(themeManager.incomingBubbleColor)
                            .clipShape(RoundedRectangle(cornerRadius: themeManager.bubbleCornerRadius))
                        Spacer()
                    }
                    
                    HStack {
                        Spacer()
                        Text("Исходящее сообщение")
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(themeManager.outgoingBubbleColor)
                            .clipShape(RoundedRectangle(cornerRadius: themeManager.bubbleCornerRadius))
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Предпросмотр")
            }
        }
        .navigationTitle("Тема и цвета")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Chat Appearance
struct ChatAppearanceView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Form {
            Section {
                ForEach(ChatBubbleStyle.allCases, id: \.self) { style in
                    Button {
                        withAnimation {
                            themeManager.bubbleStyle = style
                        }
                    } label: {
                        HStack {
                            Text(style.rawValue)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if themeManager.bubbleStyle == style {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(themeManager.accentColor)
                            }
                        }
                    }
                }
            } header: {
                Text("Стиль сообщений")
            }
            
            Section {
                ForEach(FontSize.allCases, id: \.self) { size in
                    Button {
                        withAnimation {
                            themeManager.fontSize = size
                        }
                    } label: {
                        HStack {
                            Text(size.rawValue)
                                .font(.system(size: size.size))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if themeManager.fontSize == size {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(themeManager.accentColor)
                            }
                        }
                    }
                }
            } header: {
                Text("Размер шрифта")
            }
            
            Section {
                VStack(spacing: 12) {
                    HStack {
                        Text("Пример текста сообщения")
                            .font(.system(size: themeManager.fontSize.size))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(themeManager.incomingBubbleColor)
                            .clipShape(RoundedRectangle(cornerRadius: themeManager.bubbleCornerRadius))
                        Spacer()
                    }
                    
                    HStack {
                        Spacer()
                        Text("Ответное сообщение")
                            .font(.system(size: themeManager.fontSize.size))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(themeManager.outgoingBubbleColor)
                            .clipShape(RoundedRectangle(cornerRadius: themeManager.bubbleCornerRadius))
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Предпросмотр")
            }
        }
        .navigationTitle("Оформление чатов")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Wallpaper Settings
struct WallpaperSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let wallpapers = ThemeManager.wallpapers
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(wallpapers, id: \.self) { wallpaper in
                    Button {
                        withAnimation {
                            themeManager.chatWallpaper = wallpaper
                        }
                    } label: {
                        WallpaperPreview(wallpaperId: wallpaper)
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(themeManager.chatWallpaper == wallpaper ? themeManager.accentColor : Color.clear, lineWidth: 3)
                            )
                            .overlay(
                                Group {
                                    if themeManager.chatWallpaper == wallpaper {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title)
                                            .foregroundStyle(themeManager.accentColor)
                                    }
                                }
                            )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Фон чатов")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WallpaperPreview: View {
    let wallpaperId: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Group {
            switch wallpaperId {
            case "gradient1":
                LinearGradient(colors: [.blue.opacity(0.5), .purple.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "gradient2":
                LinearGradient(colors: [.green.opacity(0.5), .teal.opacity(0.5)], startPoint: .top, endPoint: .bottom)
            case "gradient3":
                LinearGradient(colors: [.orange.opacity(0.5), .pink.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
            case "pattern1":
                ZStack {
                    Color.gray.opacity(0.2)
                    Image(systemName: "circle.grid.3x3.fill")
                        .resizable()
                        .scaledToFit()
                        .opacity(0.1)
                }
            case "pattern2":
                ZStack {
                    Color.gray.opacity(0.2)
                    Image(systemName: "line.3.horizontal")
                        .resizable()
                        .scaledToFit()
                        .opacity(0.1)
                }
            default:
                Color(.systemGray5)
            }
        }
    }
}

// MARK: - Notification Settings
struct NotificationSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var privateChatsNotifications = true
    @State private var groupNotifications = true
    @State private var channelNotifications = true
    @State private var showPreview = true
    
    var body: some View {
        Form {
            Section {
                Toggle("Уведомления", isOn: $themeManager.enableNotifications)
            }
            
            Section {
                Toggle("Звук", isOn: $themeManager.enableSounds)
                Toggle("Вибрация", isOn: $themeManager.enableVibration)
            } header: {
                Text("Оповещения")
            }
            
            Section {
                Toggle("Личные чаты", isOn: $privateChatsNotifications)
                Toggle("Группы", isOn: $groupNotifications)
                Toggle("Каналы", isOn: $channelNotifications)
            } header: {
                Text("Типы уведомлений")
            }
            
            Section {
                Toggle("Предпросмотр сообщений", isOn: $showPreview)
            } header: {
                Text("Отображение")
            }
            
            Section {
                Button("Сбросить все настройки уведомлений") {
                    themeManager.enableNotifications = true
                    themeManager.enableSounds = true
                    themeManager.enableVibration = true
                    privateChatsNotifications = true
                    groupNotifications = true
                    channelNotifications = true
                    showPreview = true
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Уведомления")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Privacy Settings
struct PrivacySettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var lastSeenVisibility = "Все"
    @State private var profilePhotoVisibility = "Все"
    @State private var canAddToGroups = "Все"
    
    let visibilityOptions = ["Все", "Мои контакты", "Никто"]
    
    var body: some View {
        Form {
            Section {
                Toggle("Показывать онлайн статус", isOn: $themeManager.showOnlineStatus)
                Toggle("Показывать прочитанность", isOn: $themeManager.showReadReceipts)
            } header: {
                Text("Видимость")
            }
            
            Section {
                Picker("Последний визит", selection: $lastSeenVisibility) {
                    ForEach(visibilityOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                
                Picker("Фото профиля", selection: $profilePhotoVisibility) {
                    ForEach(visibilityOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
            } header: {
                Text("Кто может видеть")
            }
            
            Section {
                Picker("Кто может добавлять", selection: $canAddToGroups) {
                    ForEach(visibilityOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
            } header: {
                Text("Группы")
            }
            
            Section {
                NavigationLink(destination: PasscodeSettingsView()) {
                    Text("Код-пароль")
                }
                
                NavigationLink(destination: TwoFactorAuthView()) {
                    Text("Двухфакторная аутентификация")
                }
            } header: {
                Text("Безопасность")
            }
            
            Section {
                Button("Удалить аккаунт") {
                    // Delete account
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Приватность")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Passcode Settings
struct PasscodeSettingsView: View {
    @State private var passcodeEnabled = false
    @State private var autoLock = "1 минута"
    
    let autoLockOptions = ["Выключено", "1 минута", "5 минут", "1 час", "5 часов"]
    
    var body: some View {
        Form {
            Section {
                Toggle("Код-пароль", isOn: $passcodeEnabled)
            }
            
            if passcodeEnabled {
                Section {
                    Button("Изменить код-пароль") {
                        // Change passcode
                    }
                }
                
                Section {
                    Picker("Блокировать через", selection: $autoLock) {
                        ForEach(autoLockOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                } header: {
                    Text("Автоблокировка")
                }
                
                Section {
                    Toggle("Разблокировка Face ID", isOn: .constant(true))
                }
            }
        }
        .navigationTitle("Код-пароль")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Two Factor Auth
struct TwoFactorAuthView: View {
    @State private var twoFactorEnabled = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Двухфакторная аутентификация", isOn: $twoFactorEnabled)
            } footer: {
                Text("При входе в аккаунт на новом устройстве потребуется ввести дополнительный пароль.")
            }
            
            if twoFactorEnabled {
                Section {
                    Button("Изменить пароль") {
                        // Change 2FA password
                    }
                    
                    Button("Установить email для восстановления") {
                        // Set recovery email
                    }
                }
            }
        }
        .navigationTitle("Двухфакторная аутентификация")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Blocked Users
struct BlockedUsersView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        List {
            Section {
                Text("Заблокированные пользователи не могут отправлять вам сообщения и видеть вашу информацию.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "hand.raised.slash")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)
                    Text("Список пуст")
                        .font(.headline)
                    Text("У вас нет заблокированных пользователей")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
        .navigationTitle("Заблокированные")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Storage Settings
struct StorageSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var storageUsed: Double = 256.5
    @State private var photosSize: Double = 128.2
    @State private var videosSize: Double = 89.1
    @State private var documentsSize: Double = 25.8
    @State private var voiceSize: Double = 13.4
    @State private var showClearAlert = false
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                            .frame(width: 150, height: 150)
                        
                        Circle()
                            .trim(from: 0, to: 0.6)
                            .stroke(themeManager.accentColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                            .frame(width: 150, height: 150)
                            .rotationEffect(.degrees(-90))
                        
                        VStack {
                            Text(String(format: "%.1f", storageUsed))
                                .font(.title)
                                .fontWeight(.bold)
                            Text("МБ")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Text("Использовано хранилище")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            
            Section {
                StorageRow(icon: "photo.fill", color: .blue, title: "Фото", size: photosSize)
                StorageRow(icon: "video.fill", color: .purple, title: "Видео", size: videosSize)
                StorageRow(icon: "doc.fill", color: .orange, title: "Документы", size: documentsSize)
                StorageRow(icon: "mic.fill", color: .green, title: "Голосовые", size: voiceSize)
            } header: {
                Text("По категориям")
            }
            
            Section {
                Button("Очистить кэш") {
                    showClearAlert = true
                }
                
                Button("Очистить все данные") {
                    // Clear all
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Хранилище")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Очистить кэш?", isPresented: $showClearAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Очистить", role: .destructive) {
                // Clear cache
            }
        } message: {
            Text("Это удалит все кэшированные данные. Медиафайлы будут загружены заново при просмотре.")
        }
    }
}

struct StorageRow: View {
    let icon: String
    let color: Color
    let title: String
    let size: Double
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 30)
            
            Text(title)
            
            Spacer()
            
            Text(String(format: "%.1f МБ", size))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Network Settings
struct NetworkSettingsView: View {
    @State private var autoDownloadPhotos = true
    @State private var autoDownloadVideos = false
    @State private var autoDownloadDocuments = true
    @State private var useLessData = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Фото", isOn: $autoDownloadPhotos)
                Toggle("Видео", isOn: $autoDownloadVideos)
                Toggle("Документы", isOn: $autoDownloadDocuments)
            } header: {
                Text("Автозагрузка медиа")
            }
            
            Section {
                Toggle("Режим экономии данных", isOn: $useLessData)
            } header: {
                Text("Экономия трафика")
            } footer: {
                Text("Снижает качество медиа для экономии трафика")
            }
            
            Section {
                Toggle("Использовать меньше данных для звонков", isOn: .constant(false))
            } header: {
                Text("Звонки")
            }
        }
        .navigationTitle("Сеть и загрузка")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - FAQ View
struct FAQView: View {
    var body: some View {
        List {
            Section {
                FAQItem(question: "Как изменить тему приложения?", answer: "Перейдите в Настройки → Оформление → Тема и цвета")
                FAQItem(question: "Как заблокировать пользователя?", answer: "Откройте профиль пользователя и нажмите «Заблокировать»")
                FAQItem(question: "Как включить двухфакторную аутентификацию?", answer: "Перейдите в Настройки → Конфиденциальность → Двухфакторная аутентификация")
                FAQItem(question: "Как очистить кэш?", answer: "Перейдите в Настройки → Данные → Хранилище → Очистить кэш")
                FAQItem(question: "Как изменить размер шрифта?", answer: "Перейдите в Настройки → Оформление → Оформление чатов → Размер шрифта")
            }
        }
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(answer)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
        } label: {
            Text(question)
                .font(.headline)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(ThemeManager())
}
