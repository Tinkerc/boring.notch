#!/usr/bin/env python3
"""
Add ClaudeTasks files to Xcode project using text manipulation.
Uses hardcoded group IDs for reliability.
"""

import re
import hashlib
import uuid

def gen_id():
    """Generate a 24-character hex ID like Xcode does"""
    return hashlib.md5(str(uuid.uuid4()).encode()).hexdigest()[:24].upper()

def main():
    project_path = "boringNotch.xcodeproj/project.pbxproj"

    with open(project_path, 'r') as f:
        content = f.read()

    # Known group IDs (from grep/search)
    group_ids = {
        'managers': '147163B52C5D804B0068B555',
        'extensions': 'B15063502C63D3F600EBB0E3',
        'components': '147163B42C5D804B0068B555',  # Parent for ClaudeTasks
    }

    # Files to add: (path, group_name, file_name)
    files_to_add = [
        ("boringNotch/managers/ClaudeTasksManager.swift", "managers", "ClaudeTasksManager.swift"),
        ("boringNotch/components/ClaudeTasks/ClaudeTasksBadge.swift", "ClaudeTasks", "ClaudeTasksBadge.swift"),
        ("boringNotch/components/ClaudeTasks/ClaudeTasksOverlay.swift", "ClaudeTasks", "ClaudeTasksOverlay.swift"),
        ("boringNotch/components/ClaudeTasks/ClaudeTasksExpandedView.swift", "ClaudeTasks", "ClaudeTasksExpandedView.swift"),
        ("boringNotch/extensions/ClaudeTasksDefaults.swift", "extensions", "ClaudeTasksDefaults.swift"),
    ]

    # Generate IDs for all new entries
    file_entries = []
    for file_path, group_name, file_name in files_to_add:
        file_entries.append({
            'path': file_path,
            'group': group_name,
            'name': file_name,
            'file_id': gen_id(),
            'build_id': gen_id()
        })

    # Find the end of PBXBuildFile section
    build_file_section_end = re.search(r'/\* End PBXBuildFile section \*/', content)
    if not build_file_section_end:
        print("Error: Could not find end of PBXBuildFile section")
        return

    # Find the end of PBXFileReference section
    file_ref_section_end = re.search(r'/\* End PBXFileReference section \*/', content)
    if not file_ref_section_end:
        print("Error: Could not find end of PBXFileReference section")
        return

    # Sources build phase for boringNotch target
    sources_phase_id = "14CEF40E2C5CAED300855D72"
    print(f"Using sources phase: {sources_phase_id}")

    # Check if ClaudeTasks group already exists
    claudetasks_group_match = re.search(r'(\w+) = \{isa = PBXGroup;.*?path = ClaudeTasks;', content, re.DOTALL)
    if claudetasks_group_match:
        claudetasks_group_id = claudetasks_group_match.group(1)
        print("Found existing ClaudeTasks group")
    else:
        # Create new ClaudeTasks group under components
        claudetasks_group_id = gen_id()
        group_ids['ClaudeTasks'] = claudetasks_group_id
        print(f"Creating new ClaudeTasks group with ID: {claudetasks_group_id}")

    # Build new entries
    new_build_files = []
    new_file_refs = []

    for entry in file_entries:
        # PBXBuildFile entry
        build_entry = f'\t\t{entry["build_id"]} /* {entry["name"]} in Sources */ = {{isa = PBXBuildFile; fileRef = {entry["file_id"]} /* {entry["name"]} */; }};\n'
        new_build_files.append(build_entry)

        # PBXFileReference entry
        file_ref_entry = f'\t\t{entry["file_id"]} /* {entry["name"]} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {entry["name"]}; sourceTree = "<group>"; }};\n'
        new_file_refs.append(file_ref_entry)

    # Insert PBXBuildFile entries before end of section
    insert_pos = build_file_section_end.start()
    for entry in reversed(new_build_files):
        content = content[:insert_pos] + entry + content[insert_pos:]

    # Insert PBXFileReference entries before end of section
    file_ref_section_end = re.search(r'/\* End PBXFileReference section \*/', content)
    insert_pos = file_ref_section_end.start()
    for entry in reversed(new_file_refs):
        content = content[:insert_pos] + entry + content[insert_pos:]

    # Add files to sources build phase
    sources_phase_pattern = rf'({sources_phase_id} = \{{isa = PBXSourcesBuildPhase;.*?files = \()'
    sources_phase_end_match = re.search(sources_phase_pattern, content, re.DOTALL)
    if sources_phase_end_match:
        insert_pos = sources_phase_end_match.end()
        new_refs = ', '.join([f'{e["build_id"]} /* {e["name"]} in Sources */' for e in file_entries])
        content = content[:insert_pos] + new_refs + ', ' + content[insert_pos:]

    # Add ClaudeTasks group if it doesn't exist
    if not claudetasks_group_match:
        # Add ClaudeTasks group to components group's children
        components_children_pattern = r'(147163B42C5D804B0068B555 = \{isa = PBXGroup;.*?children = \()'
        components_children_match = re.search(components_children_pattern, content, re.DOTALL)
        if components_children_match:
            insert_pos = components_children_match.end()
            content = content[:insert_pos] + f'{claudetasks_group_id} /* ClaudeTasks */, ' + content[insert_pos:]
            print("Added ClaudeTasks group to components")

        # Find end of PBXGroup section and add new group definition
        group_section_end = re.search(r'/\* End PBXGroup section \*/', content)
        if group_section_end:
            new_group_def = f'\t\t{claudetasks_group_id} /* ClaudeTasks */ = {{isa = PBXGroup; children = (); path = ClaudeTasks; sourceTree = "<group>"; }};\n'
            insert_pos = group_section_end.start()
            content = content[:insert_pos] + new_group_def + content[insert_pos:]

    # Add files to their respective groups using hardcoded IDs
    for entry in file_entries:
        group_name = entry['group']

        if group_name in group_ids:
            group_id = group_ids[group_name]
            # Find children array in this group - simpler pattern
            children_pattern = group_id + r'.*?children\s*='
            children_match = re.search(children_pattern, content, re.DOTALL)
            if children_match:
                insert_pos = children_match.end()
                content = content[:insert_pos] + f' {entry["file_id"]} /* {entry["name"]} */, ' + content[insert_pos:]
                print(f"Added {entry['name']} to group {group_name}")
            else:
                print(f"Warning: Could not find children array for group {group_name}")
        else:
            print(f"Warning: No ID known for group {group_name}")

    # Save the modified content
    with open(project_path, 'w') as f:
        f.write(content)

    print(f"Added {len(file_entries)} files to the project.")
    print("Now try building in Xcode.")

if __name__ == "__main__":
    main()
