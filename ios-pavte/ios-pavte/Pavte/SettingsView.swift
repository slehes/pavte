import SwiftUI
import PhotosUI
import AVKit

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showAccountSwitcher = false
    @State private var navigateToSupportChat = false
    
    var body: some View {
        NavigationStack {
            List {
                // Profile section with video background
                Section {
                    NavigationLink(destination: ProfileSettingsView()) {
                        HStack(spacing: 16) {
                            AvatarWithVideoBackground(user: appState.currentUser, size: 60)
                            
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
                
                // Privacy & Security
                Section {
                    NavigationLink(destination: PasscodeSettingsView()) {
                        SettingsRow(icon: "lock.shield.fill", color: .indigo, title: "Код-пароль")
                    }
                    
                    NavigationLink(destination: TwoFASettingsView()) {
                        SettingsRow(icon: "lock.doublefill", color: .green, title: "Двухфакторная аутентификация")
                    }
                    
                    NavigationLink(destination: ActiveSessionsView()) {
                        SettingsRow(icon: "laptopcomputer.and.iphone", color: .blue, title: "Активные сессии")
                    }
                    
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
                
                // Help — Support is @slehes by username, not "Поддержка Pavte"
                Section {
                    NavigationLink(destination: FAQView()) {
                        SettingsRow(icon: "questionmark.circle.fill", color: .blue, title: "Часто задаваемые вопросы")
                    }
                    
                    Button {
                        let _ = appState.openSupportChat()
                        navigateToSupportChat = true
                    } label: {
                        SettingsRow(icon: "envelope.fill", color: .green, title: "Связаться с @slehes")
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

// MARK: - Avatar with Video Background
struct AvatarWithVideoBackground: View {
    let user: User
    var size: CGFloat = 60
    @EnvironmentObject var themeManager: ThemeManager
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            // Video background (circle area behind avatar)
            if let videoData = user.avatarVideoBackgroundData {
                VideoBackgroundCircle(videoData: videoData, size: size + 16)
            } else {
                // Default gray circle
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: size + 16, height: size + 16)
            }
            
            // Avatar on top
            if let avatarData = user.avatarData, let uiImage = UIImage(data: avatarData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: user.avatarName)
                    .font(.system(size: size * 0.65))
                    .foregroundStyle(themeManager.accentColor)
                    .frame(width: size, height: size)
            }
        }
    }
}

// MARK: - Video Background Circle (plays video in a circle behind avatar)
struct VideoBackgroundCircle: View {
    let videoData: Data
    var size: CGFloat
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
                    .disabled(true) // No user controls
            } else {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: size, height: size)
                    .onAppear { setupPlayer() }
            }
        }
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private func setupPlayer() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("avatar_bg_\(UUID().uuidString).mp4")
        do {
            try videoData.write(to: tempURL)
            let newPlayer = AVPlayer(url: tempURL)
            newPlayer.actionAtItemEnd = .none
            // Loop the video
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: newPlayer.currentItem, queue: .main) { _ in
                newPlayer.seek(to: .zero)
                newPlayer.play()
            }
            player = newPlayer
        } catch { }
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
                Color.black.opacity(0.01).ignoresSafeArea()
                
                VStack(spacing: 0) {
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
                    
                    VStack(spacing: 0) {
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

// MARK: - Profile Settings (with Avatar Upload + Video Background)
struct ProfileSettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var showSavedAlert = false
    
    @State private var showAvatarPicker = false
    @State private var selectedAvatarItem: PhotosPickerItem?
    
    // Video background
    @State private var showVideoBgPicker = false
    @State private var selectedVideoBgItem: PhotosPickerItem?
    
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
            
            // Video background for avatar area
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Видео-фон аватара")
                            .font(.body)
                        Text("Видео вокруг аватарки вместо серого фона")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        showVideoBgPicker = true
                    } label: {
                        if appState.currentUser.avatarVideoBackgroundData != nil {
                            Text("Изменить")
                                .font(.caption)
                                .foregroundStyle(themeManager.accentColor)
                        } else {
                            Text("Добавить")
                                .font(.caption)
                                .foregroundStyle(themeManager.accentColor)
                        }
                    }
                }
                
                if appState.currentUser.avatarVideoBackgroundData != nil {
                    Button(role: .destructive) {
                        appState.updateAvatarVideoBackground(nil)
                    } label: {
                        Text("Удалить видео-фон")
                    }
                }
            } header: {
                Text("Видео-фон")
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
        .photosPicker(isPresented: $showVideoBgPicker, selection: $selectedVideoBgItem, matching: .videos)
        .onChange(of: selectedVideoBgItem) { _, newItem in
            guard let newItem = newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    appState.updateAvatarVideoBackground(data)
                }
                selectedVideoBgItem = nil
            }
        }
    }
}

// MARK: - Passcode Settings
struct PasscodeSettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isPasscodeOn = false
    @State private var showSetPasscode = false
    @State private var newPasscode = ""
    @State private var confirmPasscode = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Form {
            Section {
                Toggle("Код-пароль", isOn: $isPasscodeOn)
                    .onChange(of: isPasscodeOn) { _, newValue in
                        if newValue {
                            showSetPasscode = true
                        } else {
                            appState.removePasscode()
                        }
                    }
            } header: {
                Text("Защита приложения")
            } footer: {
                Text("При включении приложение будет требовать ввод кода-пароля при запуске")
            }
            
            if isPasscodeOn {
                Section {
                    Button("Изменить код-пароль") {
                        showSetPasscode = true
                    }
                }
            }
        }
        .navigationTitle("Код-пароль")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isPasscodeOn = appState.isPasscodeEnabled
        }
        .alert("Установить код-пароль", isPresented: $showSetPasscode) {
            SecureField("4-значный код", text: $newPasscode)
                .keyboardType(.numberPad)
            SecureField("Подтвердите код", text: $confirmPasscode)
                .keyboardType(.numberPad)
            Button("Сохранить") {
                if newPasscode.count == 4 && newPasscode == confirmPasscode {
                    appState.setPasscode(newPasscode)
                    newPasscode = ""
                    confirmPasscode = ""
                } else {
                    errorMessage = "Код должен быть 4 цифры и совпадать"
                    showError = true
                    isPasscodeOn = false
                }
            }
            Button("Отмена", role: .cancel) {
                if !appState.isPasscodeEnabled {
                    isPasscodeOn = false
                }
                newPasscode = ""
                confirmPasscode = ""
            }
        } message: {
            Text("Введите 4-значный код-пароль")
        }
        .alert("Ошибка", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - 2FA Settings
struct TwoFASettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var is2FAOn = false
    @State private var showSetup = false
    @State private var secretCode = ""
    @State private var verifyCode = ""
    @State private var showSuccess = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Двухфакторная аутентификация", isOn: $is2FAOn)
                    .onChange(of: is2FAOn) { _, newValue in
                        if newValue && !appState.is2FAEnabledForCurrentAccount {
                            secretCode = appState.enable2FA()
                            showSetup = true
                        } else if !newValue {
                            appState.disable2FA()
                        }
                    }
            } header: {
                Text("Безопасность")
            } footer: {
                Text("Дополнительный уровень защиты: при входе потребуется ввести код из приложения-аутентификатора")
            }
            
            if appState.is2FAEnabledForCurrentAccount {
                Section {
                    HStack {
                        Text("Статус")
                        Spacer()
                        Label("Включена", systemImage: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                    }
                } header: {
                    Text("Текущее состояние")
                }
            }
        }
        .navigationTitle("Двухфакторная аутентификация")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            is2FAOn = appState.is2FAEnabledForCurrentAccount
        }
        .alert("Настройка 2FA", isPresented: $showSetup) {
            SecureField("Введите код для подтверждения", text: $verifyCode)
                .keyboardType(.numberPad)
            Button("Подтвердить") {
                if verifyCode == secretCode {
                    showSuccess = true
                    verifyCode = ""
                } else {
                    is2FAOn = false
                    appState.disable2FA()
                }
            }
            Button("Отмена", role: .cancel) {
                is2FAOn = false
                appState.disable2FA()
                verifyCode = ""
            }
        } message: {
            Text("Ваш секретный код: \(secretCode)\nВведите этот код для подтверждения настройки 2FA")
        }
        .alert("2FA включена", isPresented: $showSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Двухфакторная аутентификация успешно включена")
        }
    }
}

// MARK: - Active Sessions View
struct ActiveSessionsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showTerminateAll = false
    
    var body: some View {
        List {
            ForEach(appState.activeSessions) { session in
                HStack(spacing: 14) {
                    Image(systemName: session.isCurrent ? "iphone" : "desktopcomputer")
                        .font(.title2)
                        .foregroundStyle(session.isCurrent ? .green : themeManager.accentColor)
                        .frame(width: 36, height: 36)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(session.deviceName)
                                .font(.headline)
                            if session.isCurrent {
                                Text("эта сессия")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.green)
                                    .clipShape(Capsule())
                            }
                        }
                        Text("\(session.platform) · Pavte \(session.appVersion)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(session.location) · \(formatDate(session.lastActiveDate))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    
                    Spacer()
                    
                    if !session.isCurrent {
                        Button(role: .destructive) {
                            appState.terminateSession(session.id)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            if appState.activeSessions.filter({ !$0.isCurrent }).count > 1 {
                Section {
                    Button(role: .destructive) {
                        showTerminateAll = true
                    } label: {
                        Text("Завершить все другие сессии")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationTitle("Активные сессии")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Завершить все сессии?", isPresented: $showTerminateAll) {
            Button("Завершить", role: .destructive) {
                appState.terminateAllOtherSessions()
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Вы будете разлогинены на всех устройствах кроме текущего")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
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
    @State private var showAddPhotoPicker = false
    @State private var showAddVideoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedVideoItem: PhotosPickerItem?
    
    var body: some View {
        List {
            // + Add button at top
            Section {
                HStack(spacing: 16) {
                    // Add photo
                    Button {
                        showAddPhotoPicker = true
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray5))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundStyle(.gray)
                            }
                            Text("Фото")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Add video
                    Button {
                        showAddVideoPicker = true
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray5))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundStyle(.gray)
                            }
                            Text("Видео")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Добавить фон")
            } footer: {
                Text("Поддерживаются фото и видео. Добавленный фон будет первым в списке.")
            }
            
            // Custom wallpapers (first in list)
            let customWallpapers = themeManager.wallpapers.filter { !$0.isBuiltIn }
            if !customWallpapers.isEmpty {
                Section("Мои фоны") {
                    ForEach(customWallpapers) { wallpaper in
                        wallpaperRow(wallpaper)
                    }
                    .onDelete { indexSet in
                        // Map from custom-only index to full wallpapers index
                        let customs = themeManager.wallpapers.indices.filter { !themeManager.wallpapers[$0].isBuiltIn }
                        for idx in indexSet {
                            if idx < customs.count {
                                themeManager.deleteWallpaper(at: IndexSet(integer: customs[idx]))
                            }
                        }
                    }
                }
            }
            
            // Built-in wallpapers
            Section("Стандартные") {
                ForEach(themeManager.wallpapers.filter { $0.isBuiltIn }) { wallpaper in
                    wallpaperRow(wallpaper)
                }
            }
        }
        .navigationTitle("Фон чатов")
        .navigationBarTitleDisplayMode(.inline)
        .photosPicker(isPresented: $showAddPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .photosPicker(isPresented: $showAddVideoPicker, selection: $selectedVideoItem, matching: .videos)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem = newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    themeManager.addCustomWallpaper(name: "Мой фон", imageData: data)
                    // Auto-select the newly added wallpaper
                    if let first = themeManager.wallpapers.first {
                        themeManager.selectWallpaper(first)
                    }
                }
                selectedPhotoItem = nil
            }
        }
        .onChange(of: selectedVideoItem) { _, newItem in
            guard let newItem = newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    themeManager.addCustomVideoWallpaper(name: "Мой видео-фон", videoData: data)
                    if let first = themeManager.wallpapers.first {
                        themeManager.selectWallpaper(first)
                    }
                }
                selectedVideoItem = nil
            }
        }
    }
    
    @ViewBuilder
    private func wallpaperRow(_ wallpaper: WallpaperItem) -> some View {
        Button {
            themeManager.selectWallpaper(wallpaper)
        } label: {
            HStack(spacing: 12) {
                // Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(width: 56, height: 56)
                    
                    if let imageData = wallpaper.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else if wallpaper.isVideo {
                        Image(systemName: "video.fill")
                            .foregroundStyle(.gray)
                    } else if let builtInId = wallpaper.builtInId {
                        builtInThumbnail(builtInId)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(wallpaper.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                    if wallpaper.isVideo {
                        Text("Видео")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if themeManager.selectedWallpaperId == wallpaper.id.uuidString {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(themeManager.accentColor)
                }
            }
        }
    }
    
    @ViewBuilder
    private func builtInThumbnail(_ id: String) -> some View {
        switch id {
        case "default":
            Color(.systemGroupedBackground)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        case "gradient1":
            LinearGradient(colors: [.blue.opacity(0.5), .purple.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        case "gradient2":
            LinearGradient(colors: [.green.opacity(0.5), .teal.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        case "gradient3":
            LinearGradient(colors: [.orange.opacity(0.5), .pink.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        case "pattern1":
            Image(systemName: "circle.grid.3x3.fill").foregroundStyle(.gray)
        case "pattern2":
            Image(systemName: "lines.measurement.vertical").foregroundStyle(.gray)
        default:
            Color(.systemGray5)
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
    @State private var channelNotifications = false
    @State private var soundEnabled = true
    @State private var vibrationEnabled = true
    @State private var previewEnabled = true
    
    var body: some View {
        Form {
            Section {
                Toggle("Личные чаты", isOn: $privateChatsNotifications)
                Toggle("Группы", isOn: $groupNotifications)
                Toggle("Каналы", isOn: $channelNotifications)
            } header: {
                Text("Уведомления чатов")
            }
            
            Section {
                Toggle("Звук", isOn: $soundEnabled)
                Toggle("Вибрация", isOn: $vibrationEnabled)
                Toggle("Предпросмотр сообщений", isOn: $previewEnabled)
            } header: {
                Text("Настройки")
            }
        }
        .navigationTitle("Уведомления")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Privacy Settings
struct PrivacySettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var lastSeenEveryone = true
    @State private var readReceipts = true
    @State private var onlineStatus = true
    @State private var profilePhotoEveryone = true
    
    var body: some View {
        Form {
            Section {
                Toggle("Показывать «был(а) в сети»", isOn: $lastSeenEveryone)
                Toggle("Отчёты о прочтении", isOn: $readReceipts)
                Toggle("Статус «в сети»", isOn: $onlineStatus)
            } header: {
                Text("Приватность")
            }
            
            Section {
                Toggle("Фото профиля видно всем", isOn: $profilePhotoEveryone)
            } header: {
                Text("Видимость профиля")
            }
        }
        .navigationTitle("Приватность")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Blocked Users
struct BlockedUsersView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Нет заблокированных пользователей")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
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
                    Text("Кэш")
                    Spacer()
                    Text("12.3 МБ")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Фотографии")
                    Spacer()
                    Text("45.7 МБ")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Видео")
                    Spacer()
                    Text("128.5 МБ")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Документы")
                    Spacer()
                    Text("3.2 МБ")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Использование хранилища")
            }
            
            Section {
                Button("Очистить кэш") { }
            }
        }
        .navigationTitle("Хранилище")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Network Settings
struct NetworkSettingsView: View {
    @State private var useCellular = true
    @State private var autoDownloadPhotos = true
    @State private var autoDownloadVideos = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Использовать мобильную сеть", isOn: $useCellular)
                Toggle("Автозагрузка фото", isOn: $autoDownloadPhotos)
                Toggle("Автозагрузка видео", isOn: $autoDownloadVideos)
            } header: {
                Text("Сеть")
            } footer: {
                Text("Автозагрузка работает только при подключении к Wi-Fi, если мобильная сеть отключена")
            }
        }
        .navigationTitle("Сеть и загрузка")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - FAQ
struct FAQView: View {
    let faqs = [
        ("Как найти пользователя?", "Войдите в раздел Чаты, нажмите на строку поиска и введите юзернейм пользователя (например @slehes). В результатах появится пользователь, нажмите на него чтобы начать чат."),
        ("Как изменить фото профиля?", "Настройки → Профиль → нажмите на аватар. Выберите фото из галереи."),
        ("Как установить видео-фон аватара?", "Настройки → Профиль → Видео-фон аватара → Добавить. Выберите видео из галереи — оно будет проигрываться вокруг вашей аватарки."),
        ("Как установить код-пароль?", "Настройки → Код-пароль → включите переключатель и введите 4-значный код."),
        ("Как включить 2FA?", "Настройки → Двухфакторная аутентификация → включите и подтвердите секретный код."),
        ("Как удалить сообщение?", "Зажмите сообщение в чате. Выберите «Удалить». Можно удалить «У меня» (только у вас) или «У всех» (анонимно — сообщение исчезнет без следа)."),
        ("Как редактировать сообщение?", "Зажмите своё сообщение и выберите «Редактировать». Измените текст и нажмите «Сохранить». Рядом с сообщением появится пометка «изменено»."),
        ("Как закрепить сообщение?", "Зажмите сообщение и выберите «Закрепить». Закреплённые сообщения отображаются вверху чата."),
        ("Как связаться с поддержкой?", "Настройки → Связаться с @slehes — откроется чат с разработчиком."),
        ("Как сменить аккаунт?", "Нажмите иконку аккаунта в правом верхнем углу Настроек или зажмите экран Настроек.")
    ]
    
    var body: some View {
        List {
            ForEach(faqs, id: \.0) { question, answer in
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
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}
