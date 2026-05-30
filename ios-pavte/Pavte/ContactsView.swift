import SwiftUI

struct ContactsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var searchText = ""
    @State private var showAddContact = false
    
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
                        // Create group
                    } label: {
                        Label("Создать группу", systemImage: "person.3.fill")
                    }
                    
                    Button {
                        // Create channel
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
        }
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

#Preview {
    ContactsView()
        .environmentObject(AppState())
        .environmentObject(ThemeManager())
}
