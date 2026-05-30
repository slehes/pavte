<div align="center">

<img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Objects/Mobile%20Phone.png" alt="logo" width="80" height="80" />

# Pavte

**Современный мессенджер для iOS, построенный на SwiftUI**

Чаты · Звонки · Контакты · Настройки

[![iOS](https://img.shields.io/badge/iOS-26-blue?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.1-F05138?logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5-0F7FFF?logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![Xcode](https://img.shields.io/badge/Xcode-26-147EFB?logo=xcode&logoColor=white)](https://developer.apple.com/xcode/)
[![Platform](https://img.shields.io/badge/Platform-iPhone-lightgrey?logo=apple&logoColor=white)](https://www.apple.com/iphone/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[![Telegram](https://img.shields.io/badge/Telegram-@slehes-26A5E4?logo=telegram&logoColor=white)](https://t.me/slehes)
[![Channel](https://img.shields.io/badge/Channel-@slehesdev-2AABEE?logo=telegram&logoColor=white)](https://t.me/slehesdev)
[![GitHub](https://img.shields.io/badge/GitHub-slehes-181717?logo=github&logoColor=white)](https://github.com/slehes)

</div>

---

## ✨ Возможности

- 💬 **Чаты** — отправка текстовых сообщений, фото, видео, голосовых и документов
- 📞 **Звонки** — голосовые и видеозвонки с интерфейсом управления
- 👥 **Контакты** — список контактов с онлайн-статусами
- 🎨 **Темы** — тёмная/светлая тема, 6 акцентных цветов, 3 стиля пузырьков
- 🖼️ **Медиа** — реальные фото/видео из галереи, запись голосовых, полноэкранный просмотр
- 🔒 **Приватность** — настройка видимости, блокировка, 2FA
- 🎨 **Glassmorphism** — дизайн с эффектом «жидкого стекла» и градиентными фонами

## 📱 Скриншоты

<table>
  <tr>
    <td align="center"><b>Чаты</b></td>
    <td align="center"><b>Диалог</b></td>
    <td align="center"><b>Звонки</b></td>
    <td align="center"><b>Настройки</b></td>
  </tr>
  <tr>
    <td><img src="https://via.placeholder.com/250x540/0B1120/26A5E4?text=Чаты" width="200"/></td>
    <td><img src="https://via.placeholder.com/250x540/0B1120/26A5E4?text=Диалог" width="200"/></td>
    <td><img src="https://via.placeholder.com/250x540/0B1120/26A5E4?text=Звонки" width="200"/></td>
    <td><img src="https://via.placeholder.com/250x540/0B1120/26A5E4?text=Настройки" width="200"/></td>
  </tr>
</table>

## 🛠 Технологии

| Компонент | Технология |
|-----------|-----------|
| Язык | Swift 6.1 |
| UI Фреймворк | SwiftUI |
| Платформа | iOS 26 |
| Архитектура | MVVM |
| Хранение | @AppStorage / UserDefaults |
| Дизайн | Glassmorphism + Liquid Glass |

## 🚀 Установка

### Требования

- macOS 26 (Tahoe) или новее
- Xcode 26 или новее
- iOS 26 SDK

### Сборка из исходников

```bash
# Клонировать репозиторий
git clone https://github.com/slehes/pavte.git

# Перейти в папку проекта
cd pavte/ios-pavte

# Открыть в Xcode
open Pavte.xcodeproj
```

### Сборка через CLI

```bash
xcodebuild \
  -project Pavte.xcodeproj \
  -scheme Pavte \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO
```

## 📂 Структура проекта

```
ios-pavte/
├── Pavte/
│   ├── PavteApp.swift          # Точка входа
│   ├── AppState.swift          # Состояние приложения
│   ├── ContentView.swift       # Главный TabView
│   ├── ChatsListView.swift     # Список чатов
│   ├── ChatDetailView.swift    # Диалог чата
│   ├── ContactsView.swift      # Контакты
│   ├── CallsView.swift         # Звонки
│   ├── SettingsView.swift      # Настройки
│   ├── Models.swift            # Модели данных
│   ├── ThemeManager.swift      # Управление темой
│   ├── LiquidGlassSupport.swift # Glassmorphism эффекты
│   └── Assets.xcassets/        # Ресурсы
├── PavteTests/
├── PavteUITests/
└── .github/workflows/
    └── ios-ipa.yml             # CI/CD сборка
```

## 🤝 Вклад

Приветствуются любые вклады! Форкайте, создавайте ветки и отправляйте Pull Request.

1. Fork проекта
2. Создать feature-ветку (`git checkout -b feature/amazing`)
3. Коммит (`git commit -m 'Add amazing feature'`)
4. Push (`git push origin feature/amazing`)
5. Открыть Pull Request

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. Подробности в файле [LICENSE](LICENSE).

---

<div align="center">

**Сделано с ❤️ на SwiftUI**

[Telegram](https://t.me/slehes) · [Канал](https://t.me/slehesdev) · [GitHub](https://github.com/slehes)

</div>
