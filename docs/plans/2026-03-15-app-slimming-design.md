# App Slimming Design Document

**Date:** 2026-03-15
**Feature:** Minimalist Boring Notch - Apps + Music Only
**Status:** Design Approved

---

## Overview

Strip down the Boring Notch application to its absolute minimum: a notch-based app launcher and music player. All other features will be removed to improve performance, reduce code complexity, and maintain focus on core functionality.

---

## Goals

1. **Performance** - Reduce launch time by 30-40%, memory by 15-25MB
2. **Simplicity** - Reduce codebase by ~50% (5000+ lines → ~2500 lines)
3. **Maintainability** - Remove unused/legacy code paths
4. **Focus** - Keep only what users actually use daily

---

## Tab Structure

### Before (3 tabs)
```
Apps → Shelf → Home
```

### After (2 tabs)
```
Apps → Music
```

---

## Retained Features

### Apps Launcher (Full)
- App grid display (4 columns)
- App discovery from /Applications
- Favorites management
- One-click app launching
- Empty state with Settings CTA

### Music Player (Minimal)
- Song title + Artist name display
- Album artwork
- Play/pause state indicator
- Single audio source (Apple Music or NowPlaying - user configurable)
- No visualizer effects
- No album art color extraction
- No multi-source switching UI

---

## Removed Features

### Entire Modules (directories to delete)

| Directory | Files | Description |
|-----------|-------|-------------|
| `components/Shelf/` | 13+ | File shelf, AirDrop, drag-drop |
| `components/ClaudeTasks/` | 7 | Claude Tasks monitoring overlay |
| `components/Webcam/` | 1 | Camera mirror |
| `components/Calendar/` | 1 | Calendar integration |

### Managers (single files to delete)

| File | Purpose |
|------|---------|
| `WebcamManager.swift` | Camera session management |
| `ClaudeTasksManager.swift` | Task monitoring |
| `BatteryActivityManager.swift` | Battery notifications |
| `BrightnessManager.swift` | Brightness HUD |
| `VolumeManager.swift` | Volume HUD |
| `NotchSpaceManager.swift` | Multi-display window management |

### Live Activities (partial removal)

| File | Action |
|------|--------|
| `DownloadView.swift` | DELETE |
| `OpenNotchHUD.swift` | DELETE |
| `SystemEventIndicatorModifier.swift` | DELETE |
| `InlineHUD.swift` | KEEP (may be used elsewhere) |
| `LiveActivityModifier.swift` | KEEP (core infrastructure) |

### Settings Pages

| Page | Status |
|------|--------|
| General | KEEP |
| Appearance | KEEP |
| Media | KEEP (simplified) |
| Calendar | DELETE |
| HUDs | DELETE |
| Battery | DELETE |
| Shelf | DELETE |
| Shortcuts | DELETE |
| Advanced | KEEP (minimal) |
| About | KEEP |

---

## File Changes Summary

### Files to Create

1. `boringNotch/components/Music/MusicMinimalView.swift` - Simplified music display
2. `boringNotch/components/Music/MinimalMusicViewModel.swift` - Stripped view model

### Files to Delete

```
boringNotch/components/Shelf/Models/Bookmark.swift
boringNotch/components/Shelf/Models/ShelfItem.swift
boringNotch/components/Shelf/Services/ImageProcessingService.swift
boringNotch/components/Shelf/Services/QuickLookService.swift
boringNotch/components/Shelf/Services/QuickShareService.swift
boringNotch/components/Shelf/Services/ShareServiceFinder.swift
boringNotch/components/Shelf/Services/ShelfActionService.swift
boringNotch/components/Shelf/Services/ShelfDropService.swift
boringNotch/components/Shelf/Services/ShelfPersistenceService.swift
boringNotch/components/Shelf/Services/TemporaryFileStorageService.swift
boringNotch/components/Shelf/Services/ThumbnailService.swift
boringNotch/components/Shelf/ViewModels/ShelfItemViewModel.swift
boringNotch/components/Shelf/ViewModels/ShelfSelectionModel.swift
boringNotch/components/Shelf/ViewModels/ShelfStateViewModel.swift
boringNotch/components/Shelf/Views/DragPreviewView.swift
boringNotch/components/Shelf/Views/FileShareView.swift
boringNotch/components/Shelf/Views/ShelfItemView.swift
boringNotch/components/Shelf/Views/ShelfView.swift

boringNotch/components/ClaudeTasks/ClaudeTasksBadge.swift
boringNotch/components/ClaudeTasks/PaginationControl.swift
boringNotch/components/ClaudeTasks/RepoPageCard.swift
boringNotch/components/ClaudeTasks/TaskRow.swift
boringNotch/components/ClaudeTasks/ClaudeTasksOverlay.swift
boringNotch/components/ClaudeTasks/ClaudeTasksExpandedView.swift

boringNotch/components/Webcam/WebcamView.swift
boringNotch/components/Calendar/BoringCalendar.swift

boringNotch/managers/WebcamManager.swift
boringNotch/managers/ClaudeTasksManager.swift
boringNotch/managers/BatteryActivityManager.swift
boringNotch/managers/BrightnessManager.swift
boringNotch/managers/VolumeManager.swift
boringNotch/managers/NotchSpaceManager.swift

boringNotch/components/Live activities/DownloadView.swift
boringNotch/components/Live activities/OpenNotchHUD.swift
boringNotch/components/Live activities/SystemEventIndicatorModifier.swift
```

### Files to Modify

| File | Changes |
|------|---------|
| `ContentView.swift` | Remove HUD, battery, download, Shelf logic; simplify NotchLayout |
| `TabSelectionView.swift` | Remove Shelf tab; change Home → Music |
| `BoringViewCoordinator.swift` | Remove `.shelf`, `.home` states; remove Claude Tasks properties |
| `SettingsView.swift` | Remove Calendar/HUD/Battery/Shelf/Shortcuts pages |
| `boringNotchApp.swift` | Remove ClaudeTasksManager, multi-display, screen lock handling |
| `NotchHomeView.swift` | Convert to MusicMinimalView or delete |
| `MusicManager.swift` | Simplify to single source; remove visualizer logic |
| `enums/generic.swift` | Remove unused enum cases |

---

## Music Player Simplification

### Current Implementation
- Multi-source support (Apple Music, Spotify, YouTube Music, NowPlaying)
- Album art color extraction for theming
- Audio visualizer effects
- Complex state management

### Target Implementation
- Single source: `NowPlayingController` (recommended) or `AppleMusicController`
- Fixed gray/white color scheme
- No visualizer
- Simple play/pause state

### Migration Path
1. Keep `MusicManager.swift` as central coordinator
2. Remove visualizer-related properties
3. Remove `avgColor` extraction
4. Default to `NowPlayingController` for macOS 15.4+
5. Fall back to `AppleMusicController` for older systems

---

## Error Handling

### App Launch Failures
- Keep existing pattern: show alert, offer to remove from favorites

### Music Player Edge Cases
- No music playing: show "No music playing" or minimal face animation
- Music app not installed: show "Open Music app to start" CTA

---

## Testing Checklist

- [ ] Apps view loads correctly
- [ ] App launching works
- [ ] Music display updates on play/pause
- [ ] Music display updates on track change
- [ ] Settings opens and shows retained pages
- [ ] No console errors on launch
- [ ] Memory usage < 50MB at idle
- [ ] Launch time < 1 second

---

## Success Criteria

1. ✅ Apps tab functional (add/remove/launch apps)
2. ✅ Music tab displays current track
3. ✅ All removed features confirmed gone
4. ✅ No build errors
5. ✅ No runtime crashes
6. ✅ Settings only shows retained pages

---

## Implementation Notes

- Create backup branch before starting: `slimming-backup-2026-03-15`
- Delete files in batches to track progress
- Test after each batch deletion
- Update Xcode project file if needed

---

## Files Summary

### Create
```
boringNotch/components/Music/MusicMinimalView.swift
boringNotch/components/Music/MinimalMusicViewModel.swift
```

### Delete
35+ files across Shelf, ClaudeTasks, Webcam, Calendar, Managers, LiveActivities

### Modify
8-10 core files (ContentView, TabSelection, Coordinator, Settings, App delegate, MusicManager)

---

## Design Approved

**Date Approved:** 2026-03-15
**Approved By:** User confirmed via chat
