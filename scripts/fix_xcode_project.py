#!/usr/bin/env python3
"""
Clean Xcode project file of deleted files
Uses a proper parser approach to handle the plist-like format
"""

import re
import sys
from pathlib import Path

# Deleted files to remove
DELETED_FILES = [
    # Shelf module
    "ShelfItemView.swift", "ShelfPersistenceService.swift", "ShelfItem.swift",
    "ShelfSelectionModel.swift", "QuickLookService.swift", "ShelfDropService.swift",
    "ShelfActionService.swift", "ThumbnailService.swift", "ShelfStateViewModel.swift",
    "ShelfItemViewModel.swift", "ShelfView.swift", "Bookmark.swift",
    "URL+SecurityScoped.swift", "SharingStateManager.swift", "ImageProcessingService.swift",
    "FileShareView.swift", "QuickShareService.swift", "TemporaryFileStorageService.swift",
    "ShareServiceFinder.swift", "DragPreviewView.swift",

    # ClaudeTasks module
    "ClaudeTasksBadge.swift", "ClaudeTasksExpandedView.swift", "ClaudeTasksOverlay.swift",
    "TaskRow.swift", "RepoPageCard.swift", "PaginationControl.swift",
    "ClaudeTasksDefaults.swift", "ClaudeTasksManager.swift", "ClaudeTask.swift",

    # Webcam
    "WebcamManager.swift", "WebcamView.swift",

    # Calendar
    "BoringCalendar.swift", "CalendarManager.swift", "CalendarModel.swift",
    "CalendarServiceProviding.swift", "EventModel.swift",

    # Managers
    "BatteryActivityManager.swift", "BrightnessManager.swift", "VolumeManager.swift",
    "NotchSpaceManager.swift",

    # HUD Live Activities
    "DownloadView.swift", "OpenNotchHUD.swift", "SystemEventIndicatorModifier.swift",
]

def main():
    project_path = Path(__file__).parent.parent / "boringNotch.xcodeproj" / "project.pbxproj"
    backup_path = Path(__file__).parent.parent / "boringNotch.xcodeproj" / "project.pbxproj.backup"

    # Read original file
    content = project_path.read_text()

    # Create backup
    backup_path.write_text(content)
    print(f"✅ Backup created: {backup_path}")

    # Count before
    before_count = content.count(".swift")
    print(f"Swift references before: {before_count}")

    # Build pattern for deleted files
    for deleted_file in DELETED_FILES:
        # Remove PBXBuildFile entries (entire line with the file reference)
        pattern = r'\t\w+ /\* ' + re.escape(deleted_file) + r' in Sources \*/ = \{[^}]+\};\n'
        content = re.sub(pattern, '', content)

        # Remove PBXFileReference entries
        pattern = r'\t\w+ /\* ' + re.escape(deleted_file) + r' \*/ = \{[^}]+\};\n'
        content = re.sub(pattern, '', content)

        # Remove from PBXGroup file lists (entries like "1113ABB72E80E27000EC13B2 /* ShelfItem.swift */,)
        pattern = r'\t\w+ /\* ' + re.escape(deleted_file) + r' \*/,\n'
        content = re.sub(pattern, '', content)

    # Remove entire directory groups that are now empty
    # Shelf group
    content = re.sub(r'\t9A987A042C73CA66005CA465 /\* Shelf \*/ = \{\s*isa = PBXGroup;.*?\t\};\n', '', content, flags=re.DOTALL)
    # ClaudeTasks group
    content = re.sub(r'\tBEABE88F709D97559C33A262 /\* ClaudeTasks \*/ = \{\s*isa = PBXGroup;.*?\t\};\n', '', content, flags=re.DOTALL)
    # Webcam group
    content = re.sub(r'\t149E0B982C737D26006418B1 /\* Webcam \*/ = \{\s*isa = PBXGroup;.*?\t\};\n', '', content, flags=re.DOTALL)
    # Calendar group
    content = re.sub(r'\t14C08BB72C8DE49E000F8AA0 /\* Calendar \*/ = \{\s*isa = PBXGroup;.*?\t\};\n', '', content, flags=re.DOTALL)

    # Write cleaned content
    project_path.write_text(content)

    # Count after
    after_count = content.count(".swift")
    print(f"Swift references after: {after_count}")
    print(f"Removed: {before_count - after_count} references")

    # Verify file structure
    if "archiveVersion = 1" in content and "objectVersion" in content:
        print("✅ Project file structure looks valid")
        return 0
    else:
        print("❌ Project file may be corrupted!")
        return 1

if __name__ == "__main__":
    sys.exit(main())
