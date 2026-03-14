# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Boring Notch is a macOS SwiftUI application that transforms the MacBook notch into a dynamic control center. It features music visualizations, calendar integration, file shelf with AirDrop support, and system HUD replacements.

## Build & Development

### Prerequisites
- macOS 14 (Sonoma) or later
- Xcode 16 or later
- Apple Silicon or Intel Mac

### Build and Run
```bash
# Open in Xcode
open boringNotch.xcodeproj

# Build and run with Cmd+R in Xcode
# Or use xcodebuild:
xcodebuild -scheme boringNotch -configuration Debug build
```

### Testing
```bash
xcodebuild -scheme boringNotch test
```

### Branch Guidelines
- **Code contributions**: Base on `dev` branch (NOT `main`)
- **Documentation changes**: Base on `main` branch

## Architecture

### Project Structure

```
boring.notch/
├── boringNotch/              # Main SwiftUI application
│   ├── components/           # UI components (notch, shelf, calendar, settings)
│   ├── managers/             # Business logic managers
│   ├── MediaControllers/     # Music service controllers (Spotify, Apple Music, YouTube Music)
│   ├── extensions/           # Swift type extensions
│   ├── helpers/              # Utility helpers
│   ├── models/               # Data models
│   ├── observers/            # System observers
│   └── animations/           # Animation implementations
├── BoringNotchXPCHelper/     # XPC service for privileged operations
├── mediaremote-adapter/      # MediaRemote framework adapter
├── Configuration/            # Build configuration (DMG, Sparkle updates)
└── .github/workflows/        # CI/CD pipelines
```

### Key Components

**Main App Entry**: `boringNotchApp.swift` - SwiftUI app lifecycle

**Core Views**:
- `ContentView.swift` - Root view coordinator
- `BoringViewCoordinator.swift` - Manages notch view hierarchy
- `components/Notch/` - Notch rendering and interaction

**Music Integration** (`MediaControllers/`):
- Protocol-based architecture via `MediaControllerProtocol.swift`
- Controllers: `AppleMusicController`, `SpotifyController`, `NowPlayingController`, `YouTubeMusicController`

**Shelf Feature** (`components/Shelf/`):
- MVVM pattern with ViewModels (`ShelfStateViewModel`, `ShelfSelectionModel`)
- Services for file handling (AirDrop, QuickLook, thumbnails)

**Settings** (`components/Settings/`):
- `SettingsView.swift` - Preferences UI
- `SettingsWindowController.swift` - AppKit window management

### External Dependencies

Managed via Xcode Package Dependencies (not SPM manifest):
- **Sparkle** - Auto-updates
- **LaunchAtLogin** - Login item management
- **Lottie** - Animations
- **MediaRemoteAdapter** - Now Playing source (macOS 15.4+)
- **MacroVisionKit** - Display management
- **AsyncXPCConnection** - XPC communication
- **SkyLightWindow** - Low-level window management

### Localization

Uses Crowdin for translations. Strings are synchronized via `crowdin.yml`. Do NOT translate directly in PRs—submit translations to Crowdin instead.

## Contributing Guidelines

- All code changes target the `dev` branch
- Test changes on actual macOS hardware
- Include screenshots/recordings for UI changes in PRs
- Translations must go through Crowdin, not direct PRs
- See `CONTRIBUTING.md` for full contribution workflow
