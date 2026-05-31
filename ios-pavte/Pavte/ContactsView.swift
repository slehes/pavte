import SwiftUI
import PhotosUI

struct ContactsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var searchText = ""
    @State private var showAddContact = false
    @State private var showCreateGroup = false
    @State private var showCreateChannel = false
    
    var filteredContacts: [User] {
        if searchText.isEmpty {
            return appState.contacts.sorted { $0.displayName < $1.displayName }
        }
        return appState.contacts.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.username.localizedCaseInsensitiveContains(searchText) ||
            $0.phoneNumber.contains(searchText)
        }.sorted { $0.displayName < $1.displayName }
    }
    
    var groupedContacts: [String: [User]] {
        Dictionary(grouping: filteredContacts) { contact in
            String(contact.displayName.prefix(1)).uppercased()
        }
    }
    
    var sortedKeys: [String] {
        groupedContacts.keys.sorted()
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Quick actions
                Section {
                    Button {
                        showAddContact = true
                    } label: {
                        Label("Добавить контакт", systemImage: "person.badge.plus")
                    }
                    
                    Button {
                        showCreateGroup = true
                    } label: {
                        Label("Создать группу", systemImage: "person.3.fill")
                    }
                    
                    Button {
                        showCreateChannel = true
                    } label: {
                        Label("Создать канал", systemImage: "megaphone.fill")
                    }
                }
                
                // Online contacts
                let onlineContacts = filteredContacts.filter { $0.isOnline }
                if !onlineContacts.isEmpty {
                    Section("Онлайн — \(onlineContacts.count)") {
                        ForEach(onlineContacts) { contact in
                            ContactRowView(contact: contact)
                        }
                    }
                }
                
                // All contacts grouped by letter
                ForEach(sortedKeys, id: \.self) { key in
                    Section(key) {
                        ForEach(groupedContacts[key] ?? []) { contact in
                            ContactRowView(contact: contact)
                        }
                    }
                }
            }
            .navigationTitle("Контакты")
            .searchable(text: $searchText, prompt: "Поиск контактов")
            .sheet(isPresented: $showAddContact) {
                AddContactView()
            }
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupView()
            }
            .sheet(isPresented: $showCreateChannel) {
                CreateChannelView()
            }
        }
        .background(themeManager.wallpaperView().ignoresSafeArea())
    }
}

struct ContactRowView: View {
    let contact: User
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showProfile = false
    
    var body: some View {
        Button {
            showProfile = true
        } label: {
            HStack(spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    if let avatarData = contact.avatarData,
                       let uiImage = UIImage(data: avatarData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: contact.avatarName)
                            .font(.system(size: 44))
                            .foregroundStyle(themeManager.accentColor)
                    }
                    
                    if themeManager.showOnlineStatus && contact.isOnline {
                        Circle()
                            .fill(.green)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemBackground), lineWidth: 2)
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(contact.isOnline ? "в сети" : lastSeenText)
                        .font(.subheadline)
                        .foregroundStyle(contact.isOnline ? .green : .secondary)
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showProfile) {
            ContactDetailView(contact: contact)
        }
    }
    
    private var lastSeenText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.unitsStyle = .short
        return "был(а) " + formatter.localizedString(for: contact.lastSeen, relativeTo: Date())
    }
}

struct ContactDetailView: View {
    let contact: User
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    @State private var navigateToChat = false
    
    var body: some View {
        NavigationStack {
            List {
                // Profile header
                Section {
                    VStack(spacing: 16) {
                        if let avatarData = contact.avatarData,
                           let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: contact.avatarName)
                                .font(.system(size: 80))
                                .foregroundStyle(themeManager.accentColor)
                        }
                        
                        VStack(spacing: 4) {
                            Text(contact.displayName)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(contact.username)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                Circle()
                                    .fill(contact.isOnline ? .green : .gray)
                                    .frame(width: 8, height: 8)
                                Text(contact.isOnline ? "в сети" : "не в сети")
                                    .font(.caption)
                                    .foregroundStyle(contact.isOnline ? .green : .secondary)
                            }
                        }
                        
                        // Action buttons
                        HStack(spacing: 40) {
                            VStack {
                                Button {
                                    _ = appState.getOrCreateChat(with: contact)
                                    navigateToChat = true
                                    dismiss()
                                } label: {
                                    Image(systemName: "message.fill")
                                        .font(.title2)
                                        .frame(width: 50, height: 50)
                                        .background(themeManager.accentColor.opacity(0.1))
                                        .clipShape(Circle())
                                }
                                Text("Чат")
                                    .font(.caption)
                            }
                            
                            VStack {
                                Button {
                                    appState.addCallRecord(participant: contact, callType: .voice, isOutgoing: true, duration: 0, isMissed: false)
                                } label: {
                                    Image(systemName: "phone.fill")
                                        .font(.title2)
                                        .frame(width: 50, height: 50)
                                        .background(themeManager.accentColor.opacity(0.1))
                                        .clipShape(Circle())
                                }
                                Text("Звонок")
                                    .font(.caption)
                            }
                            
                            VStack {
                                Button {
                                    appState.addCallRecord(participant: contact, callType: .video, isOutgoing: true, duration: 0, isMissed: false)
                                } label: {
                                    Image(systemName: "video.fill")
                                        .font(.title2)
                                        .frame(width: 50, height: 50)
                                        .background(themeManager.accentColor.opacity(0.1))
                                        .clipShape(Circle())
                                }
                                Text("Видео")
                                    .font(.caption)
                            }
                        }
                        .foregroundStyle(themeManager.accentColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                .listRowBackground(Color.clear)
                
                Section("Информация") {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundStyle(themeManager.accentColor)
                        VStack(alignment: .leading) {
                            Text(contact.phoneNumber)
                            Text("Мобильный")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "at")
                            .foregroundStyle(themeManager.accentColor)
                        VStack(alignment: .leading) {
                            Text(contact.username)
                            Text("Имя пользователя")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if !contact.bio.isEmpty {
                        HStack(alignment: .top) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(themeManager.accentColor)
                            VStack(alignment: .leading) {
                                Text(contact.bio)
                                Text("О себе")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                Section {
                    Button {
                        // Share contact
                    } label: {
                        Label("Поделиться контактом", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        // Edit contact
                    } label: {
                        Label("Редактировать", systemImage: "pencil")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        // Block contact
                    } label: {
                        Label("Заблокировать", systemImage: "hand.raised.fill")
                    }
                    
                    Button(role: .destructive) {
                        // Delete contact
                    } label: {
                        Label("Удалить контакт", systemImage: "trash.fill")
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

struct AddContactView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var username = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Имя", text: $name)
                    TextField("Телефон", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Дополнительно") {
                    TextField("Имя пользователя", text: $username)
                }
            }
            .navigationTitle("Новый контакт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Создать") {
                        // Create contact
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Create Group View
struct CreateGroupView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    @State private var groupName = ""
    @State private var groupDescription = ""
    @State private var selectedAvatarItem: PhotosPickerItem?
    @State private var groupAvatarData: Data?
    @State private var showAvatarPicker = false
    @State private var selectedMemberIds: Set<UUID> = []
    
    private var canCreate: Bool {
        !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Avatar & name
                Section {
                    HStack(spacing: 16) {
                        Button {
                            showAvatarPicker = true
                        } label: {
                            ZStack(alignment: .bottomTrailing) {
                                if let avatarData = groupAvatarData,
                                   let uiImage = UIImage(data: avatarData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 64, height: 64)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(themeManager.accentColor.opacity(0.15))
                                        .frame(width: 64, height: 64)
                                        .overlay(
                                            Image(systemName: "person.3.fill")
                                                .font(.title2)
                                                .foregroundStyle(themeManager.accentColor)
                                        )
                                }
                                
                                Image(systemName: "camera.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .background(Circle().fill(themeManager.accentColor))
                            }
                        }
                        
                        TextField("Название группы", text: $groupName)
                            .font(.headline)
                    }
                }
                
                Section {
                    TextField("Описание (необязательно)", text: $groupDescription, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Описание")
                }
                
                // Add members
                Section {
                    ForEach(appState.contacts) { contact in
                        Button {
                            if selectedMemberIds.contains(contact.id) {
                                selectedMemberIds.remove(contact.id)
                            } else {
                                selectedMemberIds.insert(contact.id)
                            }
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
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedMemberIds.contains(contact.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(themeManager.accentColor)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Добавить участников")
                } footer: {
                    Text("Выбрано: \(selectedMemberIds.count) участников")
                }
            }
            .navigationTitle("Создать группу")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Создать") {
                        createGroup()
                    }
                    .disabled(!canCreate)
                    .fontWeight(.semibold)
                }
            }
            .photosPicker(isPresented: $showAvatarPicker, selection: $selectedAvatarItem, matching: .images)
            .onChange(of: selectedAvatarItem) { _, newItem in
                guard let newItem = newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        groupAvatarData = data
                    }
                    selectedAvatarItem = nil
                }
            }
        }
    }
    
    private func createGroup() {
        let selectedMembers = appState.contacts.filter { selectedMemberIds.contains($0.id) }
        let group = Chat.createGroup(
            name: groupName,
            avatarData: groupAvatarData,
            description: groupDescription.isEmpty ? nil : groupDescription,
            owner: appState.currentUser,
            members: selectedMembers
        )
        appState.chats.append(group)
        dismiss()
    }
}

// MARK: - Create Channel View
struct CreateChannelView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    @State private var channelName = ""
    @State private var channelDescription = ""
    @State private var selectedAvatarItem: PhotosPickerItem?
    @State private var channelAvatarData: Data?
    @State private var showAvatarPicker = false
    @State private var isPublic = true
    
    private var canCreate: Bool {
        !channelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        Button {
                            showAvatarPicker = true
                        } label: {
                            ZStack(alignment: .bottomTrailing) {
                                if let avatarData = channelAvatarData,
                                   let uiImage = UIImage(data: avatarData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 64, height: 64)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(themeManager.accentColor.opacity(0.15))
                                        .frame(width: 64, height: 64)
                                        .overlay(
                                            Image(systemName: "megaphone.fill")
                                                .font(.title2)
                                                .foregroundStyle(themeManager.accentColor)
                                        )
                                }
                                
                                Image(systemName: "camera.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .background(Circle().fill(themeManager.accentColor))
                            }
                        }
                        
                        TextField("Название канала", text: $channelName)
                            .font(.headline)
                    }
                }
                
                Section {
                    TextField("Описание (необязательно)", text: $channelDescription, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Описание")
                }
                
                Section {
                    Toggle("Публичный канал", isOn: $isPublic)
                } header: {
                    Text("Тип канала")
                } footer: {
                    Text(isPublic ? "Канал будет виден в поиске, любой может подписаться" : "Только по пригласительной ссылке")
                }
            }
            .navigationTitle("Создать канал")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Создать") {
                        createChannel()
                    }
                    .disabled(!canCreate)
                    .fontWeight(.semibold)
                }
            }
            .photosPicker(isPresented: $showAvatarPicker, selection: $selectedAvatarItem, matching: .images)
            .onChange(of: selectedAvatarItem) { _, newItem in
                guard let newItem = newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        channelAvatarData = data
                    }
                    selectedAvatarItem = nil
                }
            }
        }
    }
    
    private func createChannel() {
        let channel = Chat.createChannel(
            name: channelName,
            avatarData: channelAvatarData,
            description: channelDescription.isEmpty ? nil : channelDescription,
            owner: appState.currentUser
        )
        appState.chats.append(channel)
        dismiss()
    }
}

// MARK: - Group/Channel Management View
struct GroupManagementView: View {
    let chat: Chat
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showEditInfo = false
    @State private var showInviteLink = false
    
    var currentChat: Chat {
        appState.chats.first { $0.id == chat.id } ?? chat
    }
    
    var currentUserRole: MemberRole? {
        currentChat.members.first { $0.user.id == appState.currentUser.id }?.role
    }
    
    var isOwnerOrAdmin: Bool {
        currentUserRole == .owner || currentUserRole == .admin
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Group header
                Section {
                    VStack(spacing: 16) {
                        if let avatarData = currentChat.displayAvatarData,
                           let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: currentChat.displayAvatar)
                                .font(.system(size: 80))
                                .foregroundStyle(themeManager.accentColor)
                        }
                        
                        Text(currentChat.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if currentChat.chatType == .group {
                            Text("\(currentChat.members.count) участников")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("\(currentChat.members.count) подписчиков")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                .listRowBackground(Color.clear)
                
                // Group info
                if let desc = currentChat.groupDescription, !desc.isEmpty {
                    Section {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("Описание")
                    }
                }
                
                // Invite link
                if let link = currentChat.inviteLink {
                    Section {
                        Button {
                            UIPasteboard.general.string = link
                            showInviteLink = true
                        } label: {
                            HStack {
                                Image(systemName: "link")
                                    .foregroundStyle(themeManager.accentColor)
                                VStack(alignment: .leading) {
                                    Text("Пригласительная ссылка")
                                        .foregroundStyle(.primary)
                                    Text(link)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    } header: {
                        Text("Ссылка")
                    }
                }
                
                // Members
                Section {
                    ForEach(currentChat.members) { member in
                        HStack(spacing: 12) {
                            if let avatarData = member.user.avatarData,
                               let uiImage = UIImage(data: avatarData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: member.user.avatarName)
                                    .font(.system(size: 40))
                                    .foregroundStyle(themeManager.accentColor)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(member.user.displayName)
                                    .font(.headline)
                                Text(member.roleLabel)
                                    .font(.caption)
                                    .foregroundStyle(member.role == .owner ? .orange : (member.role == .admin ? .blue : .secondary))
                            }
                            
                            Spacer()
                            
                            if isOwnerOrAdmin && member.role == .member {
                                Menu {
                                    Button("Сделать админом") {
                                        promoteToAdmin(memberId: member.id)
                                    }
                                    Button("Удалить из группы", role: .destructive) {
                                        removeMember(memberId: member.id)
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text(currentChat.chatType == .group ? "Участники" : "Подписчики")
                }
                
                // Chat history
                Section {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(themeManager.accentColor)
                        Text("История чатов")
                        Spacer()
                        Text("\(currentChat.messages.count) сообщений")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("История")
                }
                
                // Permissions (only for owner/admin)
                if isOwnerOrAdmin {
                    Section {
                        Toggle("Реакции", isOn: Binding(
                            get: { currentChat.allowReactions },
                            set: { appState.updateChatPermission(chatId: chat.id, allowReactions: $0) }
                        ))
                        
                        Toggle("Участники могут приглашать", isOn: Binding(
                            get: { currentChat.allowMembersToInvite },
                            set: { appState.updateChatPermission(chatId: chat.id, allowMembersToInvite: $0) }
                        ))
                        
                        Toggle("Участники могут редактировать инфо", isOn: Binding(
                            get: { currentChat.allowMembersToEditInfo },
                            set: { appState.updateChatPermission(chatId: chat.id, allowMembersToEditInfo: $0) }
                        ))
                        
                        Toggle("Участники могут закреплять", isOn: Binding(
                            get: { currentChat.allowMembersToPinMessages },
                            set: { appState.updateChatPermission(chatId: chat.id, allowMembersToPinMessages: $0) }
                        ))
                        
                        Toggle("История видна новым", isOn: Binding(
                            get: { currentChat.historyVisibleToNewMembers },
                            set: { appState.updateChatPermission(chatId: chat.id, historyVisibleToNewMembers: $0) }
                        ))
                        
                        Toggle("Медленный режим", isOn: Binding(
                            get: { currentChat.slowMode },
                            set: { appState.updateChatPermission(chatId: chat.id, slowMode: $0) }
                        ))
                    } header: {
                        Text("Разрешения")
                    } footer: {
                        Text("Медленный режим — участники могут отправлять сообщение раз в 10 секунд")
                    }
                    
                    // Group type
                    Section {
                        HStack {
                            Image(systemName: currentChat.isPublic ? "globe" : "lock.fill")
                                .foregroundStyle(themeManager.accentColor)
                            Text(currentChat.isPublic ? "Публичная" : "Приватная")
                            Spacer()
                        }
                    } header: {
                        Text("Тип")
                    }
                }
                
                // Danger zone
                Section {
                    if currentChat.chatType == .group {
                        Button(role: .destructive) {
                            appState.leaveChat(chatId: chat.id)
                            dismiss()
                        } label: {
                            Label("Покинуть группу", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } else {
                        Button(role: .destructive) {
                            appState.leaveChat(chatId: chat.id)
                            dismiss()
                        } label: {
                            Label("Отписаться от канала", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }
            }
            .navigationTitle(currentChat.chatType == .group ? "Управление группой" : "Управление каналом")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
            .alert("Ссылка скопирована", isPresented: $showInviteLink) {
                Button("OK", role: .cancel) { }
            }
        }
    }
    
    private func promoteToAdmin(memberId: UUID) {
        guard let idx = appState.chats.firstIndex(where: { $0.id == chat.id }) else { return }
        if let memberIdx = appState.chats[idx].members.firstIndex(where: { $0.id == memberId }) {
            appState.chats[idx].members[memberIdx].role = .admin
        }
    }
    
    private func removeMember(memberId: UUID) {
        guard let idx = appState.chats.firstIndex(where: { $0.id == chat.id }) else { return }
        appState.chats[idx].members.removeAll { $0.id == memberId }
    }
}

#Preview {
    ContactsView()
        .environmentObject(AppState())
        .environmentObject(ThemeManager())
}
