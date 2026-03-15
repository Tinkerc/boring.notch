#!/bin/bash
# Clean Xcode project file of deleted files
# Date: 2026-03-15

set -e

cd "$(dirname "$0")/.."

PROJECT_FILE="boringNotch.xcodeproj/project.pbxproj"

echo "=== Cleaning Xcode Project File ==="
echo ""

# Create backup
cp "$PROJECT_FILE" "${PROJECT_FILE}.backup"
echo "✅ Backup created: ${PROJECT_FILE}.backup"

# List of deleted files to remove from project
DELETED_FILES=(
    # Shelf module
    "ShelfItemView.swift"
    "ShelfPersistenceService.swift"
    "ShelfItem.swift"
    "ShelfSelectionModel.swift"
    "QuickLookService.swift"
    "ShelfDropService.swift"
    "ShelfActionService.swift"
    "ThumbnailService.swift"
    "ShelfStateViewModel.swift"
    "ShelfItemViewModel.swift"
    "ShelfView.swift"
    "Bookmark.swift"
    "URL+SecurityScoped.swift"
    "SharingStateManager.swift"
    "ImageProcessingService.swift"
    "FileShareView.swift"
    "QuickShareService.swift"
    "TemporaryFileStorageService.swift"
    "ShareServiceFinder.swift"

    # ClaudeTasks module
    "ClaudeTasksBadge.swift"
    "ClaudeTasksExpandedView.swift"
    "ClaudeTasksOverlay.swift"
    "TaskRow.swift"
    "RepoPageCard.swift"
    "PaginationControl.swift"
    "ClaudeTasksDefaults.swift"
    "ClaudeTasksManager.swift"
    "ClaudeTask.swift"

    # Webcam
    "WebcamManager.swift"
    "WebcamView.swift"

    # Calendar
    "BoringCalendar.swift"
    "CalendarManager.swift"
    "CalendarModel.swift"
    "CalendarServiceProviding.swift"
    "EventModel.swift"

    # Managers
    "BatteryActivityManager.swift"
    "BrightnessManager.swift"
    "VolumeManager.swift"
    "NotchSpaceManager.swift"

    # HUD Live Activities
    "DownloadView.swift"
    "OpenNotchHUD.swift"
    "SystemEventIndicatorModifier.swift"
)

# Count before
BEFORE_COUNT=$(grep -c "\.swift" "$PROJECT_FILE" || true)
echo "Swift file references before cleanup: $BEFORE_COUNT"

# Remove PBXBuildFile entries (/* Begin PBXBuildFile section */ to /* End PBXBuildFile section */)
echo ""
echo "Removing PBXBuildFile entries..."

# Create a temporary file for processing
TEMP_FILE=$(mktemp)
cp "$PROJECT_FILE" "$TEMP_FILE"

# For each deleted file, remove the PBXBuildFile entry
for file in "${DELETED_FILES[@]}"; do
    # Remove lines containing the file in PBXBuildFile section
    sed -i '' "/\/\* ${file} in Sources \*\//d" "$TEMP_FILE" 2>/dev/null || true
done

# Remove PBXFileReference entries
echo "Removing PBXFileReference entries..."
for file in "${DELETED_FILES[@]}"; do
    # Remove lines containing the file in PBXFileReference section
    sed -i '' "/\/\* ${file} \*\//d" "$TEMP_FILE" 2>/dev/null || true
done

# Remove group entries for entire directories
echo "Removing Shelf directory group..."
# Find and remove the Shelf group block
sed -i '' '/9A987A042C73CA66005CA465 \/\* Shelf \*/,/^$/d' "$TEMP_FILE" 2>/dev/null || true

echo "Removing ClaudeTasks directory group..."
sed -i '' '/BEABE88F709D97559C33A262 \/\* ClaudeTasks \*/,/^$/d' "$TEMP_FILE" 2>/dev/null || true

echo "Removing Webcam directory group..."
sed -i '' '/149E0B982C737D26006418B1 \/\* Webcam \*/,/^$/d' "$TEMP_FILE" 2>/dev/null || true

echo "Removing Calendar directory group..."
sed -i '' '/14C08BB72C8DE49E000F8AA0 \/\* Calendar \*/,/^$/d' "$TEMP_FILE" 2>/dev/null || true

# Copy back
cp "$TEMP_FILE" "$PROJECT_FILE"
rm "$TEMP_FILE"

# Count after
AFTER_COUNT=$(grep -c "\.swift" "$PROJECT_FILE" || true)
echo ""
echo "Swift file references after cleanup: $AFTER_COUNT"
echo "Removed: $((BEFORE_COUNT - AFTER_COUNT)) references"
echo ""

# Verify the file is still valid
if grep -q "archiveVersion = 1" "$PROJECT_FILE"; then
    echo "✅ Project file appears valid"
else
    echo "❌ Project file may be corrupted!"
    exit 1
fi

echo ""
echo "=== Cleanup Complete ==="
echo ""
echo "Next: Commit the project file change"
echo "  git add boringNotch.xcodeproj/project.pbxproj"
echo "  git commit -m \"refactor: remove deleted file references from Xcode project\""
