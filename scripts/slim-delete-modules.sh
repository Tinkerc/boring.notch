#!/bin/bash
# App Slimming - Delete Unused Modules
# Date: 2026-03-15

set -e

cd "$(dirname "$0")/.."

echo "=== App Slimming - Module Deletion ==="
echo ""

# Task 2: Delete Shelf module
echo "Task 2: Deleting Shelf module..."
rm -rf boringNotch/components/Shelf
git add -A
git commit -m "refactor: remove Shelf module (18 files)"
echo "✅ Shelf module deleted"
echo ""

# Task 3: Delete ClaudeTasks module
echo "Task 3: Deleting ClaudeTasks module..."
rm -rf boringNotch/components/ClaudeTasks
git add -A
git commit -m "refactor: remove ClaudeTasks module (6 files)"
echo "✅ ClaudeTasks module deleted"
echo ""

# Task 4: Delete Webcam and Calendar modules
echo "Task 4: Deleting Webcam and Calendar modules..."
rm -rf boringNotch/components/Webcam
rm boringNotch/components/Calendar/BoringCalendar.swift
git add -A
git commit -m "refactor: remove Webcam and Calendar modules"
echo "✅ Webcam and Calendar modules deleted"
echo ""

# Task 5: Delete unused managers
echo "Task 5: Deleting unused managers..."
rm boringNotch/managers/WebcamManager.swift
rm boringNotch/managers/ClaudeTasksManager.swift
rm boringNotch/managers/BatteryActivityManager.swift
rm boringNotch/managers/BrightnessManager.swift
rm boringNotch/managers/VolumeManager.swift
rm boringNotch/managers/NotchSpaceManager.swift
git add -A
git commit -m "refactor: remove unused managers (6 files)"
echo "✅ Managers deleted"
echo ""

# Task 6: Delete HUD live activity files
echo "Task 6: Deleting HUD live activity files..."
rm "boringNotch/components/Live activities/DownloadView.swift"
rm "boringNotch/components/Live activities/OpenNotchHUD.swift"
rm "boringNotch/components/Live activities/SystemEventIndicatorModifier.swift"
git add -A
git commit -m "refactor: remove HUD and download live activity views"
echo "✅ HUD files deleted"
echo ""

echo "=== All module deletions complete ==="
echo ""
echo "Next step: Run build checkpoint (Task 7)"
echo "  xcodebuild -scheme boringNotch -configuration Debug clean build"
