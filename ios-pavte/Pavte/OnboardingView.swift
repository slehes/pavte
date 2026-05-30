import SwiftUI

// MARK: - Onboarding Data
struct OnboardingSlide: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let subtitle: String
    let features: [OnboardingFeature]
}

struct OnboardingFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let onComplete: () -> Void
    
    @State private var currentPage = 0
    @Namespace private var namespace
    
    private let slides: [OnboardingSlide] = [
        OnboardingSlide(
            image: "Onboarding1",
            title: "Добро пожаловать в Pavte!",
            subtitle: "Ваш новый мессенджер для общения",
            features: [
                OnboardingFeature(icon: "message.circle.fill", title: "Быстрые сообщения", description: "Отправляйте текст, фото, видео и голосовые сообщения мгновенно"),
                OnboardingFeature(icon: "magnifyingglass", title: "Поиск по юзернейму", description: "Находите людей по имени пользователя и начинайте общение"),
                OnboardingFeature(icon: "shield.checkered", title: "Безопасность", description: "Ваши данные под надёжной защитой с приватными чатами")
            ]
        ),
        OnboardingSlide(
            image: "Onboarding2",
            title: "Ваш профиль",
            subtitle: "Настройте всё под себя",
            features: [
                OnboardingFeature(icon: "person.circle.fill", title: "Фото профиля", description: "Загрузите своё фото — нажмите на аватар в настройках профиля"),
                OnboardingFeature(icon: "pencil", title: "Имя и никнейм", description: "Измените отображаемое имя и username в любое время"),
                OnboardingFeature(icon: "paintbrush.fill", title: "Тема и цвета", description: "Выберите тёмную или светлую тему и цвет акцента на свой вкус")
            ]
        ),
        OnboardingSlide(
            image: "Onboarding3",
            title: "Чаты и сообщения",
            subtitle: "Общайтесь без ограничений",
            features: [
                OnboardingFeature(icon: "plus.circle.fill", title: "Вложения", description: "Нажмите «+» чтобы отправить фото, видео, файл или записать голосовое"),
                OnboardingFeature(icon: "phone.fill", title: "Звонки", description: "Позвоните голосом или видео прямо из чата — кнопки рядом с микрофоном"),
                OnboardingFeature(icon: "photo.fill", title: "Фон чатов", description: "Установите своё фото как фон — Настройки → Фон чатов → Своё фото")
            ]
        ),
        OnboardingSlide(
            image: "Onboarding4",
            title: "Группы и контакты",
            subtitle: "Создавайте сообщества",
            features: [
                OnboardingFeature(icon: "person.3.fill", title: "Создайте группу", description: "Контакты → Создать группу — добавьте участников и установите аватарку"),
                OnboardingFeature(icon: "megaphone.fill", title: "Создайте канал", description: "Контакты → Создать канал — публикуйте сообщения для подписчиков"),
                OnboardingFeature(icon: "headphones.circle.fill", title: "Поддержка", description: "Настройки → Связаться с @slehes — чат с разработчиком")
            ]
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [themeManager.accentColor.opacity(0.15), Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Пропустить") {
                        onComplete()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(slides.enumerated()), id: \.offset) { index, slide in
                        slideView(slide: slide)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? themeManager.accentColor : Color(.systemGray4))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 20)
                
                // Navigation button
                Button {
                    if currentPage < slides.count - 1 {
                        withAnimation(.easeInOut) {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(currentPage < slides.count - 1 ? "Далее" : "Начать")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Image(systemName: currentPage < slides.count - 1 ? "arrow.right" : "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(themeManager.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
    
    // MARK: - Slide View
    @ViewBuilder
    private func slideView(slide: OnboardingSlide) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Screenshot image
                Image(slide.image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
                    .padding(.horizontal, 24)
                
                // Title & subtitle
                VStack(spacing: 8) {
                    Text(slide.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(slide.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                
                // Feature cards
                VStack(spacing: 12) {
                    ForEach(slide.features) { feature in
                        HStack(spacing: 14) {
                            Image(systemName: feature.icon)
                                .font(.title2)
                                .foregroundStyle(themeManager.accentColor)
                                .frame(width: 36, height: 36)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(feature.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                Text(feature.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.systemGray6))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 8)
        }
    }
}

#Preview {
    OnboardingView(onComplete: { })
        .environmentObject(ThemeManager())
}
