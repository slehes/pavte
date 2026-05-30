---
Task ID: 1
Agent: Main Agent
Task: Implement all requested features for Pavte iOS messenger app

Work Log:
- Cloned repo from GitHub and read all 10+ Swift source files
- Removed "Пользователь Pavte" bio text from both predefined accounts
- Removed "О себе" (About) section from Profile Settings view
- Added phone number changing functionality (any number) with alert input
- Fixed typing indicator - replaced blocky timer-based animation with smooth SwiftUI .repeatForever bouncing dots
- Redesigned + attachment popup menu to Telegram-style grid with rounded rectangle icons (Camera, Photo, File, Voice, Location, Contact)
- Changed video background from full-screen to rectangular area only (profile avatar section)
- Reduced chat list item sizes by ~2x (avatar 52→40px, online indicator 14→10px, padding reduced)
- Added real calling via tel:// URL scheme in ChatDetailView and CallsView
- Added global video wallpaper for entire messenger in ThemeManager
- Added video wallpaper picker in WallpaperSettingsView
- Committed and pushed all changes to GitHub

Stage Summary:
- 6 files modified: AppState.swift, CallsView.swift, ChatDetailView.swift, ChatsListView.swift, SettingsView.swift, ThemeManager.swift
- All changes pushed to https://github.com/slehes/pavte.git
- Key features implemented: phone number editing, real calls, video wallpaper, compact chat list, Telegram attachment menu, smooth typing indicator
