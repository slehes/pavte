import SwiftUI
import PhotosUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showAccountSwitcher = false
    @State private var navigateToSupportChat = false
    
    var body: some View {
        NavigationStack {
            List {
                // Profile section
                Section {
                    NavigationLink(destination: ProfileSettingsView()) {
                        HStack(spacing: 16) {
                            if let avatarData = appState.currentUser.avatarData,
                               let uiImage = UIImage(data: avatarData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: appState.currentUser.avatarName)
                                    .font(.system(size: 60))
                                    .foregroundStyle(themeManager.accentColor)
                            }
                            
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
                        // Open support chat with @slehes
                        let _ = appState.openSupportChat()
                        navigateToSupportChat = true
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
                        Text(AppState.appVersion)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Настройки")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAccountSwitcher = true
                    } label: {
                        Image(systemName: "person.crop.circle.badge.plus")
                    }
                }
            }
            .contextMenu {
                Button {
                    showAccountSwitcher = true
                } label: {
                    Label("Сменить аккаунт", systemImage: "person.2.circle")
                }
            }
        }
        // Account switcher modal — appears on long press / button tap
        .sheet(isPresented: $showAccountSwitcher) {
            AccountSwitcherView()
        }
        .background(
            NavigationLink(
                destination: ChatDetailView(chat: appState.openSupportChat()),
                isActive: $navigateToSupportChat,
                label: { EmptyView() }
            )
            .hidden()
        )
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

// MARK: - Account Switcher (Modal)
struct AccountSwitcherView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    @State private var showLoginSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dimmed background
                Color.black.opacity(0.01).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    
                    // Account list card
                    VStack(spacing: 0) {
                        // Add account button
                        Button {
                            showLoginSheet = true
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .strokeBorder(themeManager.accentColor, lineWidth: 2)
                                        .frame(width: 46, height: 46)
                                    Image(systemName: "plus")
                                        .font(.title3)
                                        .foregroundStyle(themeManager.accentColor)
                                }
                                Text("Добавить аккаунт")
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                        }
                        
                        if !appState.savedAccounts.isEmpty {
                            Divider().padding(.horizontal, 18)
                        }
                        
                        // Account list
                        ForEach(appState.savedAccounts) { account in
                            Button {
                                appState.loginAs(account)
                                dismiss()
                            } label: {
                                HStack(spacing: 14) {
                                    if let avatarData = account.avatarData,
                                       let uiImage = UIImage(data: avatarData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 46, height: 46)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 46))
                                            .foregroundStyle(themeManager.accentColor)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(account.displayName)
                                            .font(.body)
                                            .foregroundStyle(.primary)
                                        Text(account.username)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if appState.currentAccount?.id == account.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(themeManager.accentColor)
                                            .font(.title3)
                                    }
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                            }
                            
                            if account.id != appState.savedAccounts.last?.id {
                                Divider().padding(.horizontal, 18)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemGray5))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationTitle("")
            .sheet(isPresented: $showLoginSheet) {
                LoginView(onDismiss: { dismiss() })
            }
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    let onDismiss: () -> Void
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    @State private var loginText = ""
    @State private var passwordText = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showRegister = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Logo above title
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: themeManager.accentColor.opacity(0.2), radius: 8, x: 0, y: 2)
                    .padding(.top, 40)
                
                Text("Pavte")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Войдите в свой аккаунт")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Login field
                VStack(spacing: 14) {
                    HStack {
                        Image(systemName: "person")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField("Логин или эл. почта", text: $loginText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    HStack {
                        Image(systemName: "lock")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        SecureField("Пароль", text: $passwordText)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                
                // Login button
                Button {
                    performLogin()
                } label: {
                    Text("Войти")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(themeManager.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Register link
                Button {
                    showRegister = true
                } label: {
                    HStack(spacing: 4) {
                        Text("Нет аккаунта?")
                            .foregroundStyle(.secondary)
                        Text("Зарегистрироваться")
                            .foregroundStyle(themeManager.accentColor)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
            }
            .alert("Ошибка", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showRegister) {
                RegisterView(onDismiss: onDismiss)
            }
        }
    }
    
    private func performLogin() {
        guard !loginText.isEmpty && !passwordText.isEmpty else {
            errorMessage = "Введите логин и пароль"
            showError = true
            return
        }
        
        let success = appState.login(login: loginText, password: passwordText)
        if success {
            onDismiss()
        } else {
            errorMessage = "Неверный логин или пароль"
            showError = true
        }
    }
}

// MARK: - Register View
struct RegisterView: View {
    let onDismiss: () -> Void
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    @State private var loginText = ""
    @State private var passwordText = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Logo above title
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: themeManager.accentColor.opacity(0.2), radius: 8, x: 0, y: 2)
                    .padding(.top, 40)
                
                Text("Регистрация")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Fields
                VStack(spacing: 14) {
                    HStack {
                        Image(systemName: "person")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField("Имя", text: $displayName)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    HStack {
                        Image(systemName: "at")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField("Логин", text: $loginText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    HStack {
                        Image(systemName: "lock")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        SecureField("Пароль", text: $passwordText)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        SecureField("Повторите пароль", text: $confirmPassword)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                
                // Register button
                Button {
                    performRegister()
                } label: {
                    Text("Зарегистрироваться")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(themeManager.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Назад") { dismiss() }
                }
            }
            .alert("Ошибка", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func performRegister() {
        guard !loginText.isEmpty && !passwordText.isEmpty && !displayName.isEmpty else {
            errorMessage = "Заполните все поля"
            showError = true
            return
        }
        
        guard passwordText == confirmPassword else {
            errorMessage = "Пароли не совпадают"
            showError = true
            return
        }
        
        guard passwordText.count >= 6 else {
            errorMessage = "Пароль должен быть не менее 6 символов"
            showError = true
            return
        }
        
        // Check if login already exists
        if appState.savedAccounts.contains(where: { $0.login.lowercased() == loginText.lowercased() }) {
            errorMessage = "Этот логин уже занят"
            showError = true
            return
        }
        
        let newAccount = Account(
            id: UUID(),
            login: loginText,
            password: passwordText,
            displayName: displayName,
            username: "@\(loginText)",
            bio: "",
            avatarName: "person.circle.fill",
            avatarData: nil,
            phoneNumber: ""
        )
        
        appState.addAccount(newAccount)
        appState.loginAs(newAccount)
        onDismiss()
    }
}

// MARK: - Profile Settings (with Avatar Upload)
struct ProfileSettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var showSavedAlert = false
    
    // Avatar picker
    @State private var showAvatarPicker = false
    @State private var selectedAvatarItem: PhotosPickerItem?
    
    var body: some View {
        Form {
            Section {
                VStack {
                    Button {
                        showAvatarPicker = true
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            if let avatarData = appState.currentUser.avatarData,
                               let uiImage = UIImage(data: avatarData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .font(.system(size: 80))
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: appState.currentUser.avatarName)
                                    .font(.system(size: 80))
                                    .foregroundStyle(themeManager.accentColor)
                            }
                            
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
        .photosPicker(isPresented: $showAvatarPicker, selection: $selectedAvatarItem, matching: .images)
        .onChange(of: selectedAvatarItem) { _, newItem in
            guard let newItem = newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    appState.updateAvatar(avatarData: data)
                }
                selectedAvatarItem = nil
            }
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

// MARK: - Wallpaper Settings (with custom photo upload)
struct WallpaperSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let wallpapers = ThemeManager.wallpapers
    
    // Custom wallpaper picker
    @State private var showCustomPicker = false
    @State private var selectedWallpaperItem: PhotosPickerItem?
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(wallpapers, id: \.self) { wallpaper in
                    Button {
                        if wallpaper == "custom" {
                            showCustomPicker = true
                        } else {
                            withAnimation {
                                themeManager.chatWallpaper = wallpaper
                            }
                        }
                    } label: {
                        if wallpaper == "custom" {
                            // Custom wallpaper tile
                            ZStack {
                                if let data = themeManager.customWallpaperData,
                                   let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.3)))
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 150)
                                        .overlay(
                                            VStack(spacing: 4) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.title)
                                                    .foregroundStyle(themeManager.accentColor)
                                                Text("Своё фото")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        )
                                }
                                
                                if themeManager.chatWallpaper == "custom" {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title)
                                        .foregroundStyle(themeManager.accentColor)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                        .padding(8)
                                }
                            }
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(themeManager.chatWallpaper == "custom" ? themeManager.accentColor : Color.clear, lineWidth: 3)
                            )
                        } else {
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
            }
            .padding()
        }
        .navigationTitle("Фон чатов")
        .navigationBarTitleDisplayMode(.inline)
        .photosPicker(isPresented: $showCustomPicker, selection: $selectedWallpaperItem, matching: .any(of: [.images, .videos]))
        .onChange(of: selectedWallpaperItem) { _, newItem in
            guard let newItem = newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    themeManager.customWallpaperData = data
                    withAnimation {
                        themeManager.chatWallpaper = "custom"
                    }
                }
                selectedWallpaperItem = nil
            }
        }
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
    @State private var isPasscodeEnabled = false
    @State private var passcode = ""
    
    var body: some View {
        Form {
            Section {
                Toggle("Код-пароль", isOn: $isPasscodeEnabled)
            }
            
            if isPasscodeEnabled {
                Section {
                    SecureField("Введите код-пароль", text: $passcode)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Установить код-пароль")
                }
            }
        }
        .navigationTitle("Код-пароль")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Two Factor Auth
struct TwoFactorAuthView: View {
    @State private var is2FAEnabled = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Двухфакторная аутентификация", isOn: $is2FAEnabled)
            }
            
            if is2FAEnabled {
                Section {
                    Text("Настройки двухфакторной аутентификации будут доступны в следующей версии.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Двухфакторная аутентификация")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Blocked Users
struct BlockedUsersView: View {
    @State private var blockedUsers: [String] = []
    
    var body: some View {
        Form {
            if blockedUsers.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Нет заблокированных пользователей")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
            } else {
                ForEach(blockedUsers, id: \.self) { user in
                    Text(user)
                }
            }
        }
        .navigationTitle("Заблокированные")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Storage Settings
struct StorageSettingsView: View {
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Использовано")
                    Spacer()
                    Text("12 МБ")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Свободно")
                    Spacer()
                    Text("Неограничено")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                Button("Очистить кэш") { }
                    .foregroundStyle(.red)
            }
        }
        .navigationTitle("Хранилище")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Network Settings
struct NetworkSettingsView: View {
    @State private var useMobileData = true
    @State private var autoDownloadPhotos = true
    @State private var autoDownloadVideos = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Использовать мобильную сеть", isOn: $useMobileData)
            } header: {
                Text("Подключение")
            }
            
            Section {
                Toggle("Автозагрузка фото", isOn: $autoDownloadPhotos)
                Toggle("Автозагрузка видео", isOn: $autoDownloadVideos)
            } header: {
                Text("Автозагрузка медиа")
            }
        }
        .navigationTitle("Сеть и загрузка")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - FAQ
struct FAQView: View {
    let faqItems = [
        ("Как изменить имя пользователя?", "Перейдите в Настройки → Профиль и измените поле «Имя пользователя». Изменения сохраняются автоматически."),
        ("Как создать группу?", "Перейдите на вкладку «Контакты» и нажмите «Создать группу». Введите название, выберите аватарку и добавьте участников."),
        ("Как установить фон чата?", "Перейдите в Настройки → Фон чатов и выберите один из предустановленных фонов или загрузите своё фото."),
        ("Как заблокировать пользователя?", "Откройте профиль пользователя и нажмите «Заблокировать». Заблокированные пользователи не смогут вам писать."),
        ("Как сменить аккаунт?", "В Настройках нажмите на иконку аккаунта в правом верхнем углу или удерживайте палец на настройках для вызова меню смены аккаунта."),
        ("Как написать в поддержку?", "Перейдите в Настройки → Связаться с поддержкой. Откроется чат с @slehes — разработчиком Pavte.")
    ]
    
    var body: some View {
        List {
            ForEach(faqItems, id: \.0) { question, answer in
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(question)
                            .font(.headline)
                        Text(answer)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Часто задаваемые вопросы")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(ThemeManager())
}
