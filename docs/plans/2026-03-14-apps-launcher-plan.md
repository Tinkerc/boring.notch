# Apps Launcher Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` to implement this plan task-by-task.

**Goal:** Add a new Apps tab to the notch header that displays a grid of user's favorite applications with launch functionality.

**Architecture:** Create a new AppsManager singleton to handle app discovery and favorites management, build SwiftUI views for the Apps grid and Settings panel, integrate with existing tab navigation.

**Tech Stack:** SwiftUI, AppKit (NSWorkspace), Defaults framework

---

### Task 1: Add `apps` case to `NotchViews` enum

**Files:**
- Modify: `boringNotch/enums/generic.swift`

**Step 1: Add apps case to enum**

Edit line 27-30 to add `.apps` case:

```swift
public enum NotchViews {
    case home
    case shelf
    case apps  // NEW
}
```

**Step 2: Commit**

```bash
git add boringNotch/enums/generic.swift
git commit -m "feat: add apps case to NotchViews enum"
```

---

### Task 2: Create AppsManager singleton

**Files:**
- Create: `boringNotch/managers/AppsManager.swift`

**Step 1: Write manager with app discovery**

```swift
import AppKit
import Defaults
import Foundation

@MainActor
class AppsManager: ObservableObject {
    static let shared = AppsManager()

    @Published var favoriteApps: [String] = []
    @Published var discoveredApps: [AppEntry] = []

    struct AppEntry: Identifiable, Hashable {
        let id = UUID()
        let bundleID: String
        let displayName: String
        let path: String

        func hash(into hasher: inout Hasher) {
            hasher.combine(bundleID)
        }

        static func == (lhs: AppEntry, rhs: AppEntry) -> Bool {
            lhs.bundleID == rhs.bundleID
        }
    }

    private let commonApps = [
        "com.apple.Safari",
        "com.google.Chrome",
        "org.mozilla.firefox",
        "com.microsoft.Edge",
        "company.thebrowser.Browser",
        "com.apple.mail",
        "com.apple.MobileMessages",
        "com.apple.Notes",
        "com.apple.reminders",
        "com.apple.iCal",
        "com.apple.Photos",
        "com.apple.Music",
        "com.spotify.client",
        "com.tinyspeck.slackmacgap",
        "com.hnc.Discord",
        "us.zoom.xos",
        "com.microsoft.teams",
        "com.figma.Desktop",
        "com.microsoft.VSCode",
        "com.jetbrains.intellij",
        "com.runningwithcrayons.Alfred"
    ]

    private init() {
        loadFavorites()
        discoverApps()
    }

    func loadFavorites() {
        favoriteApps = Defaults[.favoriteApps]
    }

    func discoverApps() {
        var apps: [AppEntry] = []

        for bundleID in commonApps {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                if let bundle = Bundle(url: url) {
                    let name = bundle.infoDictionary?["CFBundleName"] as? String
                        ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String
                        ?? (bundleID as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")

                    apps.append(AppEntry(bundleID: bundleID, displayName: name, path: url.path))
                }
            }
        }

        discoveredApps = apps
    }

    func addFavorite(_ bundleID: String) {
        if !favoriteApps.contains(bundleID) {
            favoriteApps.append(bundleID)
            Defaults[.favoriteApps] = favoriteApps
        }
    }

    func removeFavorite(_ bundleID: String) {
        favoriteApps.removeAll { $0 == bundleID }
        Defaults[.favoriteApps] = favoriteApps
    }

    func isFavorite(_ bundleID: String) -> Bool {
        favoriteApps.contains(bundleID)
    }

    func getFavoriteEntries() -> [AppEntry] {
        favoriteApps.compactMap { bundleID -> AppEntry? in
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
                return nil
            }

            let name = Bundle(url: url)?.infoDictionary?["CFBundleName"] as? String
                ?? (bundleID as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")

            return AppEntry(bundleID: bundleID, displayName: name, path: url.path)
        }
    }

    func launchApp(bundleID: String) {
        NSWorkspace.shared.launchApplication(withBundleIdentifier: bundleID, options: [])
    }

    func getAppIcon(bundleID: String) -> NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 64, height: 64)
        return icon
    }
}
```

**Step 2: Commit**

```bash
git add boringNotch/managers/AppsManager.swift
git commit -m "feat: create AppsManager singleton with app discovery"
```

---

### Task 3: Add `favoriteApps` to Defaults keys

**Files:**
- Modify: `boringNotch/extensions/ClaudeTasksDefaults.swift`

**Step 1: Add default key**

Find where other Defaults keys are defined and add:

```swift
extension Defaults.Keys {
    // ... existing keys ...
    static let favoriteApps = Key<[String]>("favoriteApps", default: [])
}
```

**Step 2: Commit**

```bash
git add boringNotch/extensions/ClaudeTasksDefaults.swift
git commit -m "feat: add favoriteApps default key"
```

---

### Task 4: Create AppIconView component

**Files:**
- Create: `boringNotch/components/Apps/AppIconView.swift`

**Step 1: Write reusable icon component**

```swift
import SwiftUI
import AppKit

struct AppIconView: View {
    let bundleID: String
    let displayName: String
    let onLaunch: () -> Void

    @State private var icon: NSImage?

    var body: some View {
        Button(action: onLaunch) {
            VStack(spacing: 8) {
                if let icon = icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)
                        .shadow(radius: 2)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: "app.badge")
                                .foregroundColor(.gray)
                                .font(.system(size: 24))
                        )
                }

                Text(displayName)
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(width: 80)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadIcon()
        }
    }

    private func loadIcon() {
        if let loadedIcon = AppsManager.shared.getAppIcon(bundleID: bundleID) {
            icon = loadedIcon
        }
    }
}

#Preview {
    AppIconView(
        bundleID: "com.apple.Safari",
        displayName: "Safari",
        onLaunch: {}
    )
    .frame(width: 100, height: 100)
    .background(Color.black)
}
```

**Step 2: Commit**

```bash
git add boringNotch/components/Apps/AppIconView.swift
git commit -m "feat: create reusable AppIconView component"
```

---

### Task 5: Create AppsEmptyState component

**Files:**
- Create: `boringNotch/components/Apps/AppsEmptyState.swift`

**Step 1: Write empty state view**

```swift
import SwiftUI

struct AppsEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "app.badge")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No apps added yet")
                .font(.headline)
                .foregroundColor(.white)

            Text("Add your favorite apps in Settings")
                .font(.subheadline)
                .foregroundColor(.gray)

            Button(action: {
                SettingsWindowController.shared.showWindow()
            }) {
                Text("Open Settings")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

#Preview {
    AppsEmptyState()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}
```

**Step 2: Commit**

```bash
git add boringNotch/components/Apps/AppsEmptyState.swift
git commit -m "feat: create AppsEmptyState component"
```

---

### Task 6: Create AppsView main component

**Files:**
- Create: `boringNotch/components/Apps/AppsView.swift`

**Step 1: Write main Apps grid view**

```swift
import SwiftUI

struct AppsView: View {
    @StateObject private var appsManager = AppsManager.shared
    private let columns = [
        GridItem(.fixed(80), spacing: 12),
        GridItem(.fixed(80), spacing: 12),
        GridItem(.fixed(80), spacing: 12),
        GridItem(.fixed(80), spacing: 12)
    ]

    var body: some View {
        Group {
            if appsManager.favoriteApps.isEmpty {
                AppsEmptyState()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(appsManager.getFavoriteEntries()) { entry in
                            AppIconView(
                                bundleID: entry.bundleID,
                                displayName: entry.displayName,
                                onLaunch: {
                                    appsManager.launchApp(bundleID: entry.bundleID)
                                }
                            )
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AppsView()
        .frame(width: 400, height: 300)
        .background(Color.black)
}
```

**Step 2: Commit**

```bash
git add boringNotch/components/Apps/AppsView.swift
git commit -m "feat: create AppsView with grid layout"
```

---

### Task 7: Update TabSelectionView with Apps tab

**Files:**
- Modify: `boringNotch/components/Tabs/TabSelectionView.swift`

**Step 1: Add Apps tab to tabs array**

Edit lines 17-20:

```swift
let tabs = [
    TabModel(label: "Home", icon: "house.fill", view: .home),
    TabModel(label: "Shelf", icon: "tray.fill", view: .shelf),
    TabModel(label: "Apps", icon: "app.badge.fill", view: .apps)  // NEW
]
```

**Step 2: Commit**

```bash
git add boringNotch/components/Tabs/TabSelectionView.swift
git commit -m "feat: add Apps tab to navigation"
```

---

### Task 8: Update ContentView to handle Apps view

**Files:**
- Modify: `boringNotch/ContentView.swift`

**Step 1: Add Apps case to view switch**

Find the switch statement around line 369 and add apps case:

```swift
switch coordinator.currentView {
case .home:
    NotchHomeView(albumArtNamespace: albumArtNamespace)
case .shelf:
    ShelfView()
case .apps:  // NEW
    AppsView()
}
```

**Step 2: Commit**

```bash
git add boringNotch/ContentView.swift
git commit -m "feat: integrate AppsView into ContentView"
```

---

### Task 9: Create AppsSettingsView for Settings

**Files:**
- Create: `boringNotch/components/Settings/AppsSettingsView.swift`

**Step 1: Write two-panel settings view**

```swift
import SwiftUI

struct AppsSettingsView: View {
    @StateObject private var appsManager = AppsManager.shared
    @State private var searchText = ""

    var filteredApps: [AppsManager.AppEntry] {
        if searchText.isEmpty {
            return appsManager.discoveredApps
        }
        return appsManager.discoveredApps.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left Panel: Available Apps
            VStack(alignment: .leading, spacing: 0) {
                Text("Available Apps")
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                TextField("Search apps...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)

                List(filteredApps) { app in
                    HStack {
                        if let icon = appsManager.getAppIcon(bundleID: app.bundleID) {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 24, height: 24)
                        }

                        Text(app.displayName)
                            .lineLimit(1)

                        Spacer()

                        if !appsManager.isFavorite(app.bundleID) {
                            Button(action: {
                                appsManager.addFavorite(app.bundleID)
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.system(size: 18))
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 18))
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset)
            }
            .frame(width: 250)

            Divider()
                .frame(height: 300)

            // Right Panel: My Apps
            VStack(alignment: .leading, spacing: 0) {
                Text("My Apps")
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                List(appsManager.getFavoriteEntries()) { app in
                    HStack {
                        if let icon = appsManager.getAppIcon(bundleID: app.bundleID) {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 24, height: 24)
                        }

                        Text(app.displayName)
                            .lineLimit(1)

                        Spacer()

                        Button(action: {
                            appsManager.removeFavorite(app.bundleID)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 18))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset)
            }
            .frame(width: 250)
        }
        .padding()
        .onAppear {
            appsManager.loadFavorites()
        }
    }
}

#Preview {
    AppsSettingsView()
        .frame(width: 520, height: 400)
}
```

**Step 2: Commit**

```bash
git add boringNotch/components/Settings/AppsSettingsView.swift
git commit -m "feat: create AppsSettingsView two-panel interface"
```

---

### Task 10: Update SettingsView to include Apps section

**Files:**
- Modify: `boringNotch/components/Settings/SettingsView.swift`

**Step 1: Add Apps navigation link**

Find the NavigationSplitView List and add after existing items:

```swift
NavigationLink(value: "Apps") {
    Label("Apps", systemImage: "app.badge.fill")
}
```

**Step 2: Add Apps case to switch statement**

Find the switch/content area and add:

```swift
case "Apps":
    AppsSettingsView()
```

**Step 3: Commit**

```bash
git add boringNotch/components/Settings/SettingsView.swift
git commit -m "feat: add Apps section to Settings"
```

---

### Task 11: Build and test

**Step 1: Build project**

```bash
xcodebuild -scheme boringNotch -configuration Debug build
```

Expected: BUILD SUCCEEDED

**Step 2: Run manual tests**

1. Open the app in Xcode (Cmd+R)
2. Click Apps tab in header → verify grid appears
3. Verify empty state shows with no apps
4. Click "Open Settings" → verify Settings opens
5. Go to Settings > Apps
6. Add 2-3 apps from Available list
7. Verify they appear in My Apps
8. Navigate back to Apps tab → verify icons display
9. Click an app icon → verify app launches
10. Remove app from Settings → verify it disappears from Apps tab

**Step 3: If all tests pass, commit**

```bash
git commit --allow-empty -m "test: verify Apps Launcher functionality"
```

---

### Task 12: Update design document

**Files:**
- Modify: `docs/plans/2026-03-14-apps-launcher-design.md`

**Step 1: Add completion notes**

Add at the end:

```markdown
---

## Implementation Complete

**Date Completed:** YYYY-MM-DD
**Build Status:** Passing
**Test Status:** Manual testing completed

### Changes from Design

[List any deviations from original design]
```

**Step 2: Commit**

```bash
git add docs/plans/2026-03-14-apps-launcher-design.md
git commit -m "docs: mark apps launcher design as complete"
```

---

## Post-Plan Instructions

**Plan complete.** To implement:

**Option 1: Subagent-Driven (recommended)**
- Stay in this session
- I'll dispatch a subagent to execute each task with code review between tasks

**Option 2: Parallel Session**
- Open a new Claude Code session
- Use `/gsd:execute-phase` or implement task-by-task

**Which approach?**
