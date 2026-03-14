#!/usr/bin/env python3
"""
Add ClaudeTasks files to Xcode project using careful text manipulation.
Preserves the exact ASCII plist format.
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
        lines = f.readlines()

    # Known group IDs
    group_ids = {
        'managers': '147163B52C5D804B0068B555',
        'extensions': 'B15063502C63D3F600EBB0E3',
        'components': '1471639B2C5D362F0068B555',
    }

    # Files to add
    files_to_add = [
        ("ClaudeTasksManager.swift", "managers"),
        ("ClaudeTasksBadge.swift", "ClaudeTasks"),
        ("ClaudeTasksOverlay.swift", "ClaudeTasks"),
        ("ClaudeTasksExpandedView.swift", "ClaudeTasks"),
        ("ClaudeTasksDefaults.swift", "extensions"),
    ]

    # Generate IDs
    file_entries = []
    for file_name, group_name in files_to_add:
        file_entries.append({
            'name': file_name,
            'group': group_name,
            'file_id': gen_id(),
            'build_id': gen_id()
        })

    # Find section ends and insert points
    build_file_end_idx = None
    file_ref_end_idx = None
    group_end_idx = None
    sources_phase_idx = None
    claude_tasks_group_idx = None

    # Group children insertion points
    managers_children_idx = None
    extensions_children_idx = None
    components_children_idx = None
    claude_tasks_children_idx = None

    for i, line in enumerate(lines):
        if '/* End PBXBuildFile section */' in line:
            build_file_end_idx = i
        elif '/* End PBXFileReference section */' in line:
            file_ref_end_idx = i
        elif '/* End PBXGroup section */' in line:
            group_end_idx = i
        elif '14CEF40E2C5CAED300855D72 = {' in line:
            sources_phase_idx = i
        elif '147163B52C5D804B0068B555 /* managers */ = {' in line:
            managers_children_idx = i + 1  # children array starts after isa
        elif 'B15063502C63D3F600EBB0E3 /* extensions */ = {' in line:
            extensions_children_idx = i + 1
        elif '1471639B2C5D362F0068B555 /* components */ = {' in line:
            components_children_idx = i + 1
        elif re.search(r'\w+ = \{isa = PBXGroup;.*?path = ClaudeTasks;', line, re.DOTALL):
            claude_tasks_group_idx = i

    if not all([build_file_end_idx, file_ref_end_idx, group_end_idx, sources_phase_idx]):
        print("Error: Could not find required sections")
        return

    # Check if ClaudeTasks group exists, if not create ID
    if claude_tasks_group_idx is None:
        claudetasks_group_id = gen_id()
    else:
        claudetasks_group_id = None  # Already exists

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
    for entry in reversed(new_build_files):
        lines.insert(build_file_end_idx, entry)

    # Find file_ref_end again (may have shifted)
    file_ref_end_idx = None
    for i, line in enumerate(lines):
        if '/* End PBXFileReference section */' in line:
            file_ref_end_idx = i
            break

    # Insert PBXFileReference entries
    for entry in reversed(new_file_refs):
        lines.insert(file_ref_end_idx, entry)

    # Find sources build phase and add files
    sources_phase_pattern = r'14CEF40E2C5CAED300855D72 = \{isa = PBXSourcesBuildPhase;.*?files = \('
    sources_match = re.search(''.join([re.escape(str(lines[i])) for i in range(sources_phase_idx, min(sources_phase_idx+20, len(lines)))]), re.DOTALL)

    # Simpler approach: find the files = ( line after sources_phase_idx
    files_line_idx = None
    for i in range(sources_phase_idx, min(sources_phase_idx + 10, len(lines))):
        if 'files = (' in lines[i]:
            files_line_idx = i
            break

    if files_line_idx:
        new_refs = ', '.join([f'{e["build_id"]} /* {e["name"]} in Sources */' for e in file_entries])
        # Insert at the start of files array
        lines[files_line_idx] = lines[files_line_idx].rstrip()[:-1] + new_refs + ', ' + lines[files_line_idx][-1]

    # Add ClaudeTasks group if needed
    if claudetasks_group_id:
        # Add to components children
        if components_children_idx is not None:
            for i in range(components_children_idx, min(components_children_idx + 20, len(lines))):
                if 'children = (' in lines[i]:
                    lines[i] = lines[i].rstrip()[:-1] + f'{claudetasks_group_id} /* ClaudeTasks */, ' + lines[i][-1]
                    break

        # Add group definition before end of PBXGroup section
        group_end_idx = None
        for i, line in enumerate(lines):
            if '/* End PBXGroup section */' in line:
                group_end_idx = i
                break

        if group_end_idx:
            new_group_def = f'\t\t{claudetasks_group_id} /* ClaudeTasks */ = {{isa = PBXGroup; children = (); path = ClaudeTasks; sourceTree = "<group>"; }};\n'
            lines.insert(group_end_idx, new_group_def)

    # Add files to their groups
    for entry in file_entries:
        group_name = entry['group']

        if group_name == 'ClaudeTasks' and claudetasks_group_id:
            # Find the ClaudeTasks group we just created
            for i in range(len(lines)):
                if f'{claudetasks_group_id} /* ClaudeTasks */' in lines[i] and 'children = (' in lines[i]:
                    lines[i] = lines[i].rstrip()[:-1] + f'{entry["file_id"]} /* {entry["name"]} */, ' + lines[i][-1]
                    break
        elif group_name in group_ids:
            group_id = group_ids[group_name]
            for i in range(len(lines)):
                if f'{group_id} /* {group_name} */' in lines[i] and 'children = (' in lines[i]:
                    lines[i] = lines[i].rstrip()[:-1] + f'{entry["file_id"]} /* {entry["name"]} */, ' + lines[i][-1]
                    break

    # Save
    with open(project_path, 'w') as f:
        f.writelines(lines)

    print(f"Added {len(file_entries)} files to the project.")

if __name__ == "__main__":
    main()
