---
Task ID: 1
Agent: Main
Task: Major Pavte v1.1.0 update - Telegram-like UI, AI chat overhaul, and all requested features

Work Log:
- Cloned Pavte repo from GitHub and read all 14 Swift source files
- Cloned Telegram-iOS repo (shallow clone, 28K+ files) and studied UI patterns
- Studied Telegram's chat bubble design (ASDisplayNode-based), notification banners (GlassBackgroundView), photo crop (UIScrollView zoom), attachment menu, and chat input bar
- Adapted Telegram patterns to SwiftUI for Pavte
- Fixed AI button color: changed from purple gradient to gray (Color(.systemGray))
- Removed "Пользователь Pavte" from bio in both predefined accounts
- Moved video background settings from Profile to ChatAppearanceView (Оформление чатов section)
- Added Developer section in Settings with modal showing: Pavte logo, "Проект под ключ, любой сложности", social links
- Added social media links section: Telegram (@slehes), GitHub (slehes), ЛС в Pavte
- Complete AI Chat overhaul:
  - Chat history with persistence (AppStorage)
  - Model switching with 6 models: Llama 3.3 70B, Mixtral 8x7B, GPT-4o, Claude 3.5 Sonnet, Gemini 1.5 Pro, Grok-2
  - API key input (AppStorage)
  - Custom provider with Base URL
  - Liquid glass effect on all AI chat buttons (.ultraThinMaterial)
  - Pavte messenger logo (Image("icon")) in AI chat header
  - Theme-adaptive (follows messenger dark/light theme)
  - Real provider icons with colored backgrounds
- Telegram-style notification banner with glass effect and slide-in animation
- Custom deep link scheme: pvt:// (like t.me but for Pavte), registered in project.yml CFBundleURLTypes
- Added pvt.me/@username display in Settings About section
- Created PhotoCropEditorView.swift (Telegram-style with rotate, flip, zoom, drag gestures)
- Updated project.yml: added CFBundleURLTypes for pvt:// scheme, version 1.1.0
- Removed hardcoded Groq API key (GitHub push protection blocked it)
- Pushed all changes to GitHub

Stage Summary:
- 8 files changed, 998 insertions, 184 deletions
- New file: PhotoCropEditorView.swift
- Version bumped to 1.1.0
- Commit: cc53008 pushed to main
