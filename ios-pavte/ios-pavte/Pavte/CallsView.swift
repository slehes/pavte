import SwiftUI

struct CallsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var searchText = ""
    @State private var showingCall = false
    @State private var selectedContact: User?
    @State private var callType: CallRecord.CallType = .voice
    
    var filteredCalls: [CallRecord] {
        if searchText.isEmpty {
            return appState.callHistory
        }
        return appState.callHistory.filter {
            $0.participant.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var groupedCalls: [(String, [CallRecord])] {
        let grouped = Dictionary(grouping: filteredCalls) { call -> String in
            let calendar = Calendar.current
            if calendar.isDateInToday(call.timestamp) {
                return "Сегодня"
            } else if calendar.isDateInYesterday(call.timestamp) {
                return "Вчера"
            } else if calendar.isDate(call.timestamp, equalTo: Date(), toGranularity: .weekOfYear) {
                return "На этой неделе"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                formatter.locale = Locale(identifier: "ru_RU")
                return formatter.string(from: call.timestamp).capitalized
            }
        }
        
        let order = ["Сегодня", "Вчера", "На этой неделе"]
        return grouped.sorted { first, second in
            let firstIndex = order.firstIndex(of: first.key) ?? Int.max
            let secondIndex = order.firstIndex(of: second.key) ?? Int.max
            if firstIndex != secondIndex {
                return firstIndex < secondIndex
            }
            return first.key < second.key
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedCalls, id: \.0) { section, calls in
                    Section(section) {
                        ForEach(calls) { call in
                            CallRowView(call: call) {
                                selectedContact = call.participant
                                callType = call.callType
                                showingCall = true
                            }
                        }
                        .onDelete { indexSet in
                            // Delete calls
                        }
                    }
                }
            }
            .navigationTitle("Звонки")
            .searchable(text: $searchText, prompt: "Поиск")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Start new call
                    } label: {
                        Image(systemName: "phone.badge.plus")
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCall) {
                if let contact = selectedContact {
                    ActiveCallView(participant: contact, callType: callType)
                }
            }
        }
    }
}

struct CallRowView: View {
    let call: CallRecord
    let onCallBack: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let avatarData = call.participant.avatarData,
               let uiImage = UIImage(data: avatarData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } else {
                Image(systemName: call.participant.avatarName)
                    .font(.system(size: 44))
                    .foregroundStyle(themeManager.accentColor)
            }
            
            // Call info
            VStack(alignment: .leading, spacing: 4) {
                Text(call.participant.displayName)
                    .font(.headline)
                    .foregroundStyle(call.isMissed ? .red : .primary)
                
                HStack(spacing: 4) {
                    Image(systemName: call.isOutgoing ? "arrow.up.right" : "arrow.down.left")
                        .font(.caption)
                        .foregroundStyle(call.isMissed ? .red : .secondary)
                    
                    Image(systemName: call.callType == .video ? "video.fill" : "phone.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if !call.isMissed {
                        Text(call.formattedDuration)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Пропущен")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            
            Spacer()
            
            // Time and call button
            VStack(alignment: .trailing, spacing: 8) {
                Text(call.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button(action: onCallBack) {
                    Image(systemName: call.callType == .video ? "video.fill" : "phone.fill")
                        .foregroundStyle(themeManager.accentColor)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ActiveCallView: View {
    let participant: User
    let callType: CallRecord.CallType
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var isMuted = false
    @State private var isSpeakerOn = false
    @State private var isVideoEnabled = true
    @State private var callDuration: TimeInterval = 0
    @State private var callState: CallState = .connecting
    @State private var timer: Timer?
    
    enum CallState {
        case connecting
        case ringing
        case active
        case ended
    }
    
    var body: some View {
        ZStack {
            // Background
            if callType == .video && isVideoEnabled {
                // Simulated video background
                LinearGradient(
                    colors: [.black, Color(.systemGray)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            } else {
                themeManager.accentColor
                    .opacity(0.9)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                // Participant info
                VStack(spacing: 16) {
                    if callType != .video || !isVideoEnabled {
                        if let avatarData = participant.avatarData,
                           let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: participant.avatarName)
                                .font(.system(size: 100))
                                .foregroundStyle(.white)
                        }
                    }
                    
                    Text(participant.displayName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text(callStatusText)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Self video preview (for video calls)
                if callType == .video && isVideoEnabled {
                    HStack {
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 100, height: 140)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.white.opacity(0.5))
                            )
                            .padding()
                    }
                }
                
                Spacer()
                
                // Call controls
                VStack(spacing: 24) {
                    HStack(spacing: 40) {
                        // Mute button
                        CallControlButton(
                            icon: isMuted ? "mic.slash.fill" : "mic.fill",
                            label: isMuted ? "Вкл. микрофон" : "Выкл. звук",
                            isActive: isMuted
                        ) {
                            isMuted.toggle()
                        }
                        
                        // Speaker button
                        CallControlButton(
                            icon: isSpeakerOn ? "speaker.wave.3.fill" : "speaker.fill",
                            label: isSpeakerOn ? "Выкл. динамик" : "Динамик",
                            isActive: isSpeakerOn
                        ) {
                            isSpeakerOn.toggle()
                        }
                        
                        // Video toggle (only for video calls)
                        if callType == .video {
                            CallControlButton(
                                icon: isVideoEnabled ? "video.fill" : "video.slash.fill",
                                label: isVideoEnabled ? "Выкл. видео" : "Вкл. видео",
                                isActive: !isVideoEnabled
                            ) {
                                isVideoEnabled.toggle()
                            }
                        }
                    }
                    
                    HStack(spacing: 40) {
                        // Flip camera (for video)
                        if callType == .video {
                            CallControlButton(
                                icon: "camera.rotate.fill",
                                label: "Камера"
                            ) {
                                // Flip camera
                            }
                        }
                        
                        // Add person
                        CallControlButton(
                            icon: "person.badge.plus",
                            label: "Добавить"
                        ) {
                            // Add person
                        }
                        
                        // Keypad
                        CallControlButton(
                            icon: "circle.grid.3x3.fill",
                            label: "Клавиши"
                        ) {
                            // Show keypad
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // End call button
                Button {
                    endCall()
                } label: {
                    Image(systemName: "phone.down.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .frame(width: 70, height: 70)
                        .background(.red)
                        .clipShape(Circle())
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startCall()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private var callStatusText: String {
        switch callState {
        case .connecting:
            return "Подключение..."
        case .ringing:
            return "Вызов..."
        case .active:
            return formatDuration(callDuration)
        case .ended:
            return "Завершён"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startCall() {
        // Simulate call connection
        callState = .connecting
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            callState = .ringing
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            callState = .active
            startTimer()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            callDuration += 1
        }
    }
    
    private func endCall() {
        timer?.invalidate()
        callState = .ended
        
        // Add to call history
        appState.addCallRecord(
            participant: participant,
            callType: callType,
            isOutgoing: true,
            duration: callDuration,
            isMissed: callDuration == 0
        )
        
        dismiss()
    }
}

struct CallControlButton: View {
    let icon: String
    let label: String
    var isActive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 50, height: 50)
                    .background(isActive ? .white : .white.opacity(0.2))
                    .foregroundStyle(isActive ? .black : .white)
                    .clipShape(Circle())
                
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
}

// Incoming call view
struct IncomingCallView: View {
    let participant: User
    let callType: CallRecord.CallType
    let onAccept: () -> Void
    let onDecline: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            themeManager.accentColor
                .opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 16) {
                    if let avatarData = participant.avatarData,
                       let uiImage = UIImage(data: avatarData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: participant.avatarName)
                            .font(.system(size: 100))
                            .foregroundStyle(.white)
                    }
                    
                    Text(participant.displayName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text(callType == .video ? "Видеозвонок" : "Аудиозвонок")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Answer buttons
                HStack(spacing: 60) {
                    // Decline
                    Button(action: onDecline) {
                        VStack(spacing: 8) {
                            Image(systemName: "phone.down.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .frame(width: 70, height: 70)
                                .background(.red)
                                .clipShape(Circle())
                            
                            Text("Отклонить")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    
                    // Accept
                    Button(action: onAccept) {
                        VStack(spacing: 8) {
                            Image(systemName: callType == .video ? "video.fill" : "phone.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .frame(width: 70, height: 70)
                                .background(.green)
                                .clipShape(Circle())
                            
                            Text("Ответить")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }
}

#Preview {
    CallsView()
        .environmentObject(AppState())
        .environmentObject(ThemeManager())
}
