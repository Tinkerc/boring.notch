# App Slimming Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Strip down Boring Notch to minimal Apps + Music functionality, removing ~50% of codebase.

**Architecture:** Delete entire feature modules (Shelf, ClaudeTasks, Webcam, Calendar, HUDs) and simplify core files to only support Apps launcher and basic music display.

**Tech Stack:** SwiftUI, Swift 5.9, macOS 14+

**Rollback Procedure:**
```bash
# If build fails or runtime crashes, revert to backup branch
git checkout slimming-backup-2026-03-15
# Or reset specific commits
git reset --hard HEAD~N  # where N = number of slimming commits
```

---

## Phase 1: Create Backup Branch

### Task 1: Create backup branch

**Step 1: Create backup branch**

```bash
git checkout -b slimming-backup-2026-03-15
git push origin slimming-backup-2026-03-15
```

Expected: Branch created and pushed to remote

**Step 2: Return to main branch**

```bash
git checkout main
```

---

## Phase 2: Delete Entire Module Directories

### Task 2: Delete Shelf module (13 files)

**Files:**
- Delete: `boringNotch/components/Shelf/Models/Bookmark.swift`
- Delete: `boringNotch/components/Shelf/Models/ShelfItem.swift`
- Delete: `boringNotch/components/Shelf/Services/ImageProcessingService.swift`
- Delete: `boringNotch/components/Shelf/Services/QuickLookService.swift`
- Delete: `boringNotch/components/Shelf/Services/QuickShareService.swift`
- Delete: `boringNotch/components/Shelf/Services/ShareServiceFinder.swift`
- Delete: `boringNotch/components/Shelf/Services/ShelfActionService.swift`
- Delete: `boringNotch/components/Shelf/Services/ShelfDropService.swift`
- Delete: `boringNotch/components/Shelf/Services/ShelfPersistenceService.swift`
- Delete: `boringNotch/components/Shelf/Services/TemporaryFileStorageService.swift`
- Delete: `boringNotch/components/Shelf/Services/ThumbnailService.swift`
- Delete: `boringNotch/components/Shelf/ViewModels/ShelfItemViewModel.swift`
- Delete: `boringNotch/components/Shelf/ViewModels/ShelfSelectionModel.swift`
- Delete: `boringNotch/components/Shelf/ViewModels/ShelfStateViewModel.swift`
- Delete: `boringNotch/components/Shelf/Views/DragPreviewView.swift`
- Delete: `boringNotch/components/Shelf/Views/FileShareView.swift`
- Delete: `boringNotch/components/Shelf/Views/ShelfItemView.swift`
- Delete: `boringNotch/components/Shelf/Views/ShelfView.swift`

**Step 1: Delete Shelf directory**

```bash
rm -rf boringNotch/components/Shelf
```

**Step 2: Commit deletion**

```bash
git add -A
git commit -m "refactor: remove Shelf module (18 files)"
```

---

### Task 3: Delete ClaudeTasks module (6 files)

**Files:**
- Delete: `boringNotch/components/ClaudeTasks/ClaudeTasksBadge.swift`
- Delete: `boringNotch/components/ClaudeTasks/PaginationControl.swift`
- Delete: `boringNotch/components/ClaudeTasks/RepoPageCard.swift`
- Delete: `boringNotch/components/ClaudeTasks/TaskRow.swift`
- Delete: `boringNotch/components/ClaudeTasks/ClaudeTasksOverlay.swift`
- Delete: `boringNotch/components/ClaudeTasks/ClaudeTasksExpandedView.swift`

**Step 1: Delete ClaudeTasks directory**

```bash
rm -rf boringNotch/components/ClaudeTasks
```

**Step 2: Commit deletion**

```bash
git add -A
git commit -m "refactor: remove ClaudeTasks module (6 files)"
```

---

### Task 4: Delete Webcam and Calendar modules (2 files)

**Files:**
- Delete: `boringNotch/components/Webcam/WebcamView.swift`
- Delete: `boringNotch/components/Calendar/BoringCalendar.swift`

**Step 1: Delete Webcam directory**

```bash
rm -rf boringNotch/components/Webcam
```

**Step 2: Delete Calendar file**

```bash
rm boringNotch/components/Calendar/BoringCalendar.swift
```

**Step 3: Commit deletions**

```bash
git add -A
git commit -m "refactor: remove Webcam and Calendar modules"
```

---

### Task 5: Delete Manager files (6 files)

**Files:**
- Delete: `boringNotch/managers/WebcamManager.swift`
- Delete: `boringNotch/managers/ClaudeTasksManager.swift`
- Delete: `boringNotch/managers/BatteryActivityManager.swift`
- Delete: `boringNotch/managers/BrightnessManager.swift`
- Delete: `boringNotch/managers/VolumeManager.swift`
- Delete: `boringNotch/managers/NotchSpaceManager.swift`

**Step 1: Delete manager files**

```bash
rm boringNotch/managers/WebcamManager.swift
rm boringNotch/managers/ClaudeTasksManager.swift
rm boringNotch/managers/BatteryActivityManager.swift
rm boringNotch/managers/BrightnessManager.swift
rm boringNotch/managers/VolumeManager.swift
rm boringNotch/managers/NotchSpaceManager.swift
```

**Step 2: Commit deletions**

```bash
git add -A
git commit -m "refactor: remove unused managers (6 files)"
```

---

### Task 6: Delete Live Activities files (3 files)

**Files:**
- Delete: `boringNotch/components/Live activities/DownloadView.swift`
- Delete: `boringNotch/components/Live activities/OpenNotchHUD.swift`
- Delete: `boringNotch/components/Live activities/SystemEventIndicatorModifier.swift`

**Step 1: Delete HUD-related files**

```bash
rm "boringNotch/components/Live activities/DownloadView.swift"
rm "boringNotch/components/Live activities/OpenNotchHUD.swift"
rm "boringNotch/components/Live activities/SystemEventIndicatorModifier.swift"
```

**Step 2: Commit deletions**

```bash
git add -A
git commit -m "refactor: remove HUD and download live activity views"
```

---

### Task 7: Build checkpoint - verify no broken imports

**Step 1: Clean build**

```bash
xcodebuild -scheme boringNotch -configuration Debug clean build 2>&1 | tee /tmp/build1.log
```

Expected: FAIL with undefined type errors

**Step 2: Analyze errors**

```bash
grep -E "error:|cannot find|use of undeclared" /tmp/build1.log | head -30
```

Document which files reference deleted types.

---

## Phase 3: Fix Core Files (Remove Dependencies)

### Task 8: Fix `BoringViewCoordinator.swift`

**Modify:** `boringNotch/BoringViewCoordinator.swift`

**Changes needed:**
1. Remove `SneakContentType` cases: `.brightness`, `.volume`, `.backlight`, `.mic`, `.battery`, `.download`
2. Keep only: `.music`
3. Remove `sneakPeek` properties (no longer used)
4. Remove `expandingView` properties (no longer used)
5. Remove HUD-related methods

**Step 1: Simplify SneakContentType enum**

Replace lines 13-21:
```swift
enum SneakContentType {
    case music
}
```

**Step 2: Remove sneakPeek struct (lines 23-28)**

Delete:
```swift
struct sneakPeek {
    var show: Bool = false
    var type: SneakContentType = .music
    var value: CGFloat = 0
    var icon: String = ""
}
```

**Step 3: Remove SharedSneakPeek struct (lines 30-35)**

**Step 4: Remove BrowserType and ExpandedItem (lines 37-47)**

**Step 5: Simplify BoringViewCoordinator properties**

Remove:
- `sneakPeekDispatch`
- `expandingViewDispatch`
- `hudEnableTask`
- `musicLiveActivityEnabled`
- `currentMicStatus`
- `@Default(.hudReplacement)`
- All HUD-related properties and methods

**Step 6: Remove methods:**
- `sneakPeekEvent(_:)`
- `toggleSneakPeek(...)`
- `scheduleSneakPeekHide(...)`
- `toggleExpandingView(...)`

**Step 7: Commit**

```bash
git add boringNotch/BoringViewCoordinator.swift
git commit -m "refactor: simplify BoringViewCoordinator to music-only"
```

---

### Task 9: Fix `TabSelectionView.swift`

**Modify:** `boringNotch/components/Tabs/TabSelectionView.swift`

**Step 1: Update tabs array (lines 17-21)**

Replace:
```swift
let tabs = [
    TabModel(label: "Apps", icon: "app.badge.fill", view: .apps),
    TabModel(label: "Music", icon: "music.note", view: .home)
]
```

**Step 2: Commit**

```bash
git add boringNotch/components/Tabs/TabSelectionView.swift
git commit -m "refactor: update tabs to Apps and Music only"
```

---

### Task 10: Fix `enums/generic.swift`

**Modify:** `boringNotch/boringNotch/enums/generic.swift`

**Step 1: Simplify NotchViews enum (lines 27-31)**

The enum is fine, but remove `.shelf` if referenced elsewhere.

**Step 2: Simplify SettingsEnum (lines 33-42)**

Replace:
```swift
enum SettingsEnum {
    case general
    case about
    case mediaPlayback
}
```

**Step 3: Remove unused enums (lines 44-70)**

Delete:
- `DownloadIndicatorStyle`
- `DownloadIconStyle`
- `MirrorShapeEnum`
- `WindowHeightMode`
- `SliderColorEnum`

**Step 4: Commit**

```bash
git add boringNotch/enums/generic.swift
git commit -m "refactor: remove unused enum types"
```

---

### Task 11: Fix `ContentView.swift`

**Modify:** `boringNotch/ContentView.swift`

This is the most complex file. Key changes:

**Step 1: Remove unused environment objects (lines 19-25)**

Keep only:
```swift
@ObservedObject var musicManager = MusicManager.shared
```

Remove:
- `webcamManager`
- `batteryModel`
- `brightnessManager`
- `volumeManager`

**Step 2: Remove computed properties referencing deleted types (lines 46-81)**

Simplify `currentNotchShape` and remove `computedChinWidth` logic for battery/face animations.

**Step 3: Simplify NotchLayout (lines 250-388)**

Remove cases for:
- Battery notifications
- Inline HUD
- System event indicators
- Boring face animation fallback

Keep only:
- Music live activity
- Open state with tab content

**Step 4: Remove drag detector (lines 514-527)**

**Step 5: Remove gesture handlers (lines 584-635)**

Keep only basic hover handling.

**Step 6: Commit**

```bash
git add boringNotch/ContentView.swift
git commit -m "refactor: simplify ContentView to Apps+Music only"
```

---

### Task 12: Fix `boringNotchApp.swift`

**Modify:** `boringNotch/boringNotchApp.swift`

**Step 1: Remove ClaudeTasksManager calls (lines 84, 425-427)**

Delete:
```swift
ClaudeTasksManager.shared.stopMonitoring()
// and
if Defaults[.claudeTasksEnabled] {
    ClaudeTasksManager.shared.startMonitoring()
}
```

**Step 2: Remove screen lock observers (lines 63-65, 75-144)**

Delete:
- `screenLockedObserver`
- `screenUnlockedObserver`
- `isScreenLocked`
- `onScreenLocked(_:)`
- `onScreenUnlocked(_:)`
- `enableSkyLightOnAllWindows()`
- `disableSkyLightOnAllWindows()`

**Step 3: Simplify window management**

Remove multi-display support:
- `windows` dictionary
- `viewModels` dictionary
- `dragDetectors` dictionary
- All related cleanup methods

**Step 4: Remove drag detector setup (lines 167-231)**

**Step 5: Commit**

```bash
git add boringNotch/boringNotchApp.swift
git commit -m "refactor: simplify app delegate to single display"
```

---

### Task 13: Fix `SettingsView.swift`

**Modify:** `boringNotch/components/Settings/SettingsView.swift`

**Step 1: Simplify navigation list (lines 28-66)**

Keep only:
```swift
NavigationLink(value: "General") {
    Label("General", systemImage: "gear")
}
NavigationLink(value: "Appearance") {
    Label("Appearance", systemImage: "eye")
}
NavigationLink(value: "Media") {
    Label("Media", systemImage: "play.laptopcomputer")
}
NavigationLink(value: "About") {
    Label("About", systemImage: "info.circle")
}
```

**Step 2: Remove corresponding switch cases**

Delete switch cases for:
- "Calendar"
- "HUD"
- "Battery"
- "Downloads"
- "Shelf"
- "Shortcuts"
- "Extensions"

**Step 3: Commit**

```bash
git add boringNotch/components/Settings/SettingsView.swift
git commit -m "refactor: simplify settings to 4 pages"
```

---

### Task 14: Simplify `MusicManager.swift`

**Modify:** `boringNotch/managers/MusicManager.swift`

**Step 1: Remove visualizer-related properties**

Delete:
- `avgColor` property (line 39)
- `calculateAverageColor()` method (lines 575-583)

**Step 2: Remove lyrics support**

Delete:
- `currentLyrics`, `isFetchingLyrics`, `syncedLyrics` properties
- `fetchLyricsIfAvailable()`, `fetchLyricsFromWeb()`, `parseLRC()`, `lyricLine(at:)` methods

**Step 3: Remove unused playback properties**

Delete:
- `canFavoriteTrack`, `isFavoriteTrack`
- `toggleFavoriteTrack()`, `setFavorite()`, `dislikeCurrentTrack()`, `toggleAppleMusicFavorite()`
- `volume`, `volumeControlSupported`
- `syncVolumeFromActiveApp()`

**Step 4: Simplify controller options**

Keep only `NowPlayingController` and `AppleMusicController`. Remove:
- `SpotifyController`
- `YouTubeMusicController`

**Step 5: Commit**

```bash
git add boringNotch/managers/MusicManager.swift
git commit -m "refactor: simplify MusicManager to basic playback"
```

---

### Task 15: Delete MusicController files

**Files:**
- Delete: `boringNotch/MediaControllers/SpotifyController.swift`
- Delete: `boringNotch/MediaControllers/YouTube Music Controller/` (entire directory)

**Step 1: Delete Spotify controller**

```bash
rm boringNotch/MediaControllers/SpotifyController.swift
```

**Step 2: Delete YouTube Music directory**

```bash
rm -rf "boringNotch/MediaControllers/YouTube Music Controller"
```

**Step 3: Commit**

```bash
git add -A
git commit -m "refactor: remove Spotify and YouTube Music controllers"
```

---

## Phase 4: Create Minimal Music View

### Task 16: Create MusicMinimalView

**Create:** `boringNotch/components/Music/MusicMinimalView.swift`

```swift
//
//  MusicMinimalView.swift
//  boringNotch
//
//  Created on 2026-03-15.
//

import SwiftUI

struct MusicMinimalView: View {
    @ObservedObject var musicManager = MusicManager.shared

    var body: some View {
        HStack(spacing: 12) {
            // Album art
            Image(nsImage: musicManager.albumArt)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            // Track info
            VStack(alignment: .leading, spacing: 2) {
                Text(musicManager.songTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(musicManager.artistName)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()

            // Play/pause indicator
            Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    MusicMinimalView()
}
```

**Step 1: Create file and commit**

```bash
git add boringNotch/components/Music/MusicMinimalView.swift
git commit -m "feat: add minimal music view"
```

---

### Task 17: Update `NotchHomeView.swift` to use MusicMinimalView

**Modify:** `boringNotch/components/Notch/NotchHomeView.swift`

**Step 1: Replace content with MusicMinimalView**

The file should now simply wrap `MusicMinimalView` for the "Music" tab.

**Step 2: Commit**

```bash
git add boringNotch/components/Notch/NotchHomeView.swift
git commit -m "refactor: simplify NotchHomeView to MusicMinimalView wrapper"
```

---

## Phase 5: Final Cleanup

### Task 18: Remove unused Default keys

**Search for and remove:**

```bash
grep -r "Defaults\[\\." boringNotch/ | grep -E "shelf|hud|battery|calendar|webcam|claude" | head -20
```

**Modify:** Files with unused Defaults keys to remove them.

**Step 1: Commit each cleanup**

```bash
git add -A
git commit -m "refactor: remove unused Defaults keys"
```

---

### Task 19: Final build and fix errors

**Step 1: Clean build**

```bash
xcodebuild -scheme boringNotch -configuration Debug clean build 2>&1 | tee /tmp/build-final.log
```

**Step 2: Fix any remaining errors**

Address errors one at a time, committing after each fix:

```bash
git add <fixed-file>
git commit -m "fix: resolve <specific-error>"
```

---

### Task 20: Build and run verification

**Step 1: Build and run**

```bash
xcodebuild -scheme boringNotch -configuration Debug build
```

**Step 2: Verify functionality**

Manual testing checklist:
- [ ] App launches without crashes
- [ ] Apps tab shows (empty state if no apps added)
- [ ] Can add apps in Settings
- [ ] Can launch apps from Apps tab
- [ ] Music tab shows current track
- [ ] Music display updates on play/pause
- [ ] Settings opens with 4 pages only (General, Appearance, Media, About)
- [ ] No console errors

**Step 3: Final commit**

```bash
git add -A
git commit -m "chore: final slimming cleanup"
```

---

## Verification Checklist

After completing all phases:

- [ ] Build passes without errors
- [ ] App launches successfully
- [ ] Apps tab functional
- [ ] Music tab functional
- [ ] Settings has 4 pages only
- [ ] No Shelf/ClaudeTasks/Webcam/Calendar references in code
- [ ] Memory usage < 50MB at idle
- [ ] Launch time < 1 second

---

## Summary of Changes

**Files Deleted:** ~40
**Files Modified:** ~10
**Files Created:** 1 (MusicMinimalView.swift)
**Lines Removed:** ~5000
**Lines Added:** ~100

---

**Plan complete and saved to `docs/plans/2026-03-15-app-slimming-plan.md`. Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?**
