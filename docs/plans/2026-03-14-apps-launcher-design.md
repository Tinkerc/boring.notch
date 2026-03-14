# Apps Launcher Design Document

**Date:** 2026-03-14
**Feature:** Apps Launcher - Quick app access from notch
**Status:** Design Approved

---

## Overview

Add a new "Apps" tab to the notch header that displays a grid of user's favorite applications. Users can click app icons to launch them directly from the notch. Similar to Launchpad but integrated into the boring.notch interface.

---

## Navigation Structure

### Tab Configuration
Replace current 2-tab structure (Home/Shelf) with 3 tabs:
- **Home** (house.fill) - Music player, calendar, camera
- **Shelf** (tray.fill) - File shelf with AirDrop
- **Apps** (app.badge.fill) - App launcher grid

### Implementation Location
- `boringNotch/components/Tabs/TabSelectionView.swift` - Update tabs array
- `boringNotch/enums/generic.swift` - Add `.apps` case to `NotchViews`

---

## Apps View Design

### Layout
```
┌─────────────────────────────────────┐
│  [App1]  [App2]  [App3]  [App4]     │
│  Name1   Name2   Name3   Name4      │
│                                     │
│  [App5]  [App6]  [App7]  [App8]     │
│  Name5   Name6   Name7   Name8      │
│                                     │
│  [App9]  [App10] [App11] [App12]    │
│  Name9   Name10  Name11  Name12     │
└─────────────────────────────────────┘
```

### Specifications
- **Grid:** 4 columns fixed
- **Icon size:** 64x64 points
- **Spacing:** 12pt horizontal, 16pt vertical
- **App name:** 11pt system font, centered below icon
- **Container:** ScrollView with LazyVGrid
- **Interaction:** Click icon → NSWorkspace.openApplication

### Empty State
When no apps are added:
- Centered message: "No apps added yet"
- Subtitle: "Add your favorite apps in Settings"
- Button: "Open Settings" → Opens Settings window
- Icon: Large app.badge SF Symbol (60pt)

---

## Settings Integration

### New Settings Section
Add "Apps" section to Settings sidebar (uses existing `SettingsEnum` pattern)

### Two-Panel Interface

```
┌──────────────────┬──────────────────┐
│  Available Apps  │    My Apps       │
├──────────────────┼──────────────────┤
│ [Safari]    (+)  │ [Chrome]    (x)  │
│ [Chrome]    (+)  │ [VS Code]   (x)  │
│ [Mail]      (+)  │ [Figma]     (x)  │
│ [Notes]     (+)  │                  │
│ [Photos]    (+)  │                  │
│ [Music]     (+)  │                  │
│ [Messages]  (+)  │                  │
│ [Slack]     (+)  │                  │
│ [Spotify]   (+)  │                  │
└──────────────────┴──────────────────┘
```

### Left Panel: Available Apps
- Auto-discover apps from `/Applications` folder
- Filter to common/popular apps (exclude system utilities)
- Show app icon + name
- "(+)" button adds to My Apps
- Search bar at top for filtering

### Right Panel: My Apps
- List of user's favorite apps (from UserDefaults)
- Show app icon + name
- "(x)" button removes from favorites
- Drag handle for reordering (future enhancement)

### Discovery Logic
Apps to suggest (hardcoded bundle IDs):
- Safari: `com.apple.Safari`
- Chrome: `com.google.Chrome`
- Firefox: `org.mozilla.firefox`
- Edge: `com.microsoft.Edge`
- Mail: `com.apple.mail`
- Messages: `com.apple.MobileMessages`
- Notes: `com.apple.Notes`
- Reminders: `com.apple.reminders`
- Calendar: `com.apple.iCal`
- Photos: `com.apple.Photos`
- Music: `com.apple.Music`
- Spotify: `com.spotify.client`
- Slack: `com.tinyspeck.slackmacgap`
- Discord: `com.hnc.Discord`
- Zoom: `us.zoom.xos`
- Teams: `com.microsoft.teams`
- Figma: `com.figma.Desktop`
- VS Code: `com.microsoft.VSCode`
- IntelliJ: `com.jetbrains.intellij`
- Alfred: `com.runningwithcrayons.Alfred`
- Arc: `company.thebrowser.Browser`

---

## Data Model

### UserDefaults Key
```swift
@Default(.favoriteApps) var favoriteApps: [String]  // Array of bundle IDs
```

### Storage Location
- `boringNotch/extensions/DefaultsKeys.swift` (or equivalent)
- Key: `"favoriteApps"`
- Type: `[String]` (bundle IDs)
- Default: `[]`

### App Metadata (computed)
```swift
struct AppEntry: Identifiable {
    let id = UUID()
    let bundleID: String
    let displayName: String
    let icon: NSImage
    let path: String
}
```

---

## Component Architecture

### New Files

1. **`boringNotch/components/Apps/AppsView.swift`**
   - Main Apps tab view
   - Grid layout with LazyVGrid
   - Empty state handling

2. **`boringNotch/components/Apps/AppIconView.swift`**
   - Reusable app icon component
   - Displays icon + name
   - Click handler for launching

3. **`boringNotch/components/Apps/AppsEmptyState.swift`**
   - Empty state view with CTA button

4. **`boringNotch/components/Settings/AppsSettingsView.swift`**
   - Two-panel settings interface
   - App discovery and management

5. **`boringNotch/managers/AppsManager.swift`**
   - Singleton manager for app operations
   - Discovers available apps
   - Manages favorite apps list
   - Handles app launching

### Modified Files

1. **`boringNotch/enums/generic.swift`**
   - Add `case apps` to `NotchViews`

2. **`boringNotch/components/Tabs/TabSelectionView.swift`**
   - Add Apps tab to tabs array

3. **`boringNotch/ContentView.swift`**
   - Add Apps case to view switch

4. **`boringNotch/components/Settings/SettingsView.swift`**
   - Add "Apps" navigation item
   - Add Apps settings view to tab content

5. **`boringNotch/extensions/DefaultsKeys.swift`** (or equivalent)
   - Add `favoriteApps` default key

---

## Error Handling

### App Launch Failures
- If app cannot be launched (bundle ID not found):
  - Show system alert: "Unable to open [App Name]"
  - Offer to remove from favorites

### Missing Icons
- Fallback to generic app icon if icon cannot be loaded
- Use `NSWorkspace.icon(for: .applicationBundle)`

### Data Migration
- If UserDefaults key doesn't exist, initialize empty array
- No migration needed (new feature)

---

## Dependencies

- `Defaults` framework (already in use)
- `AppKit` for `NSWorkspace` app launching
- `SwiftUI` for views

---

## Future Enhancements (Out of Scope)

- Custom app nicknames
- App grouping/folders
- Usage-based sorting
- iCloud sync
- App-specific notifications
- Quick actions (right-click menu)

---

## Success Criteria

1. User can add apps from Settings
2. User can remove apps from Settings
3. Apps grid displays added apps correctly
4. Clicking app icon launches the application
5. Empty state shows when no apps added
6. Settings shows available system apps

---

## Files Summary

### Create
```
boringNotch/components/Apps/AppsView.swift
boringNotch/components/Apps/AppIconView.swift
boringNotch/components/Apps/AppsEmptyState.swift
boringNotch/components/Settings/AppsSettingsView.swift
boringNotch/managers/AppsManager.swift
```

### Modify
```
boringNotch/enums/generic.swift
boringNotch/components/Tabs/TabSelectionView.swift
boringNotch/ContentView.swift
boringNotch/components/Settings/SettingsView.swift
boringNotch/extensions/DefaultsKeys.swift (or ClaudeTasksDefaults.swift)
```

---

## Implementation Complete

**Date Completed:** 2026-03-15
**Build Status:** Passing
**Test Status:** Build verified, manual testing ready

### Changes from Design

- Used `NSWorkspace.openApplication(at:configuration:)` instead of deprecated `launchApplication(withBundleIdentifier:options:)` API
- Xcode project file (project.pbxproj) updated to properly register all new Apps components
