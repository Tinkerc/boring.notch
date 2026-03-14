#!/usr/bin/env python3
"""
Add ClaudeTasks files to Xcode project by directly editing the pbxproj file.
"""

import re
import hashlib
import uuid
from openstep_parser import openstep_parser

def gen_id():
    """Generate a 24-character hex ID like Xcode does"""
    return hashlib.md5(str(uuid.uuid4()).encode()).hexdigest()[:24].upper()

def main():
    project_path = "boringNotch.xcodeproj/project.pbxproj"

    with open(project_path, 'r') as f:
        content = f.read()

    if not content.strip():
        print("Error: Project file is empty!")
        return

    # Parse using openstep-parser
    decoder = openstep_parser.OpenStepDecoder()
    plist = decoder.ParseFromString(content)
    objects = plist['objects']

    # Find groups by name
    groups = {}
    for key, obj in objects.items():
        if isinstance(obj, dict) and obj.get('isa') == 'PBXGroup':
            name = obj.get('path', '') or obj.get('name', '')
            if name:
                groups[name] = key

    print(f"Found groups: {list(groups.keys())}")

    # Files to add
    files_to_add = [
        ("boringNotch/managers/ClaudeTasksManager.swift", "managers", "ClaudeTasksManager.swift"),
        ("boringNotch/components/ClaudeTasks/ClaudeTasksBadge.swift", "ClaudeTasks", "ClaudeTasksBadge.swift"),
        ("boringNotch/components/ClaudeTasks/ClaudeTasksOverlay.swift", "ClaudeTasks", "ClaudeTasksOverlay.swift"),
        ("boringNotch/components/ClaudeTasks/ClaudeTasksExpandedView.swift", "ClaudeTasks", "ClaudeTasksExpandedView.swift"),
        ("boringNotch/extensions/ClaudeTasksDefaults.swift", "extensions", "ClaudeTasksDefaults.swift"),
    ]

    # Find target
    target_id = None
    for key, obj in objects.items():
        if isinstance(obj, dict) and obj.get('isa') == 'PBXNativeTarget' and obj.get('name') == 'boringNotch':
            target_id = key
            break

    if not target_id:
        print("Error: Could not find boringNotch target")
        return

    print(f"Found target: {target_id}")

    # Find build phases
    build_phases = objects.get(target_id, {}).get('buildPhases', [])
    sources_phase_id = None
    for phase_id in build_phases:
        phase = objects.get(phase_id, {})
        if phase.get('isa') == 'PBXSourcesBuildPhase':
            sources_phase_id = phase_id
            break

    if not sources_phase_id:
        print("Error: Could not find sources build phase")
        return

    print(f"Found sources phase: {sources_phase_id}")

    # Check if ClaudeTasks group exists, if not create it
    if "ClaudeTasks" not in groups:
        # Find the main components group
        components_group = groups.get("components")
        if components_group:
            # Generate ID for new group
            claudetasks_group_id = gen_id()
            objects[claudetasks_group_id] = {
                'isa': 'PBXGroup',
                'children': [],
                'path': 'ClaudeTasks',
                'sourceTree': '<group>'
            }
            # Add to components group
            components = objects.get(components_group, {})
            if 'children' not in components:
                components['children'] = []
            components['children'].append(claudetasks_group_id)
            groups["ClaudeTasks"] = claudetasks_group_id
            print("Created ClaudeTasks group")

    # Add files
    added = 0
    for file_path, group_name, file_name in files_to_add:
        file_id = gen_id()
        build_file_id = gen_id()

        # Create PBXFileReference
        objects[file_id] = {
            'isa': 'PBXFileReference',
            'lastKnownFileType': 'sourcecode.swift',
            'path': file_name,
            'sourceTree': '<group>'
        }

        # Create PBXBuildFile
        objects[build_file_id] = {
            'isa': 'PBXBuildFile',
            'fileRef': file_id
        }

        # Add to sources build phase
        sources_phase = objects.get(sources_phase_id, {})
        if 'files' not in sources_phase:
            sources_phase['files'] = []
        sources_phase['files'].append(build_file_id)

        # Add to group
        group_id = groups.get(group_name)
        if group_id:
            group = objects.get(group_id, {})
            if 'children' not in group:
                group['children'] = []
            group['children'].append(file_id)
            print(f"Added {file_name} to group {group_name}")
            added += 1
        else:
            print(f"Warning: Group {group_name} not found")

    if added == 0:
        print("No files were added, aborting save.")
        return

    # Save the file manually - need to preserve the Xcode format
    # The pbxproj format is ASCII plist with specific formatting

    # Build the output manually
    output_lines = ["// !$*UTF8*$!", "{"]

    # We need to preserve the original structure but with updated objects
    # For safety, let's just update the objects section

    # Find where objects start and end
    objects_start = content.find('objects = {')
    objects_end = content.rfind('};') + 2

    if objects_start == -1 or objects_end == -1:
        print("Error: Could not find objects section")
        return

    # Write header
    output_lines.append(content[:objects_start].rstrip())
    output_lines.append("")
    output_lines.append("objects = {")

    # Write all objects
    def format_value(v, indent=3):
        """Format a value for ASCII plist"""
        if isinstance(v, dict):
            if not v:
                return '{}'
            lines = ['{']
            for key, val in v.items():
                formatted_val = format_value(val, indent + 1)
                lines.append(f'\t' * indent + f'{key} = {formatted_val};')
            lines.append('\t' * (indent - 1) + '}')
            return '\n'.join(lines)
        elif isinstance(v, list):
            if not v:
                return '()'
            lines = ['(']
            for item in v:
                formatted_item = format_value(item, indent + 1)
                lines.append(f'\t' * indent + f'{formatted_item},')
            lines.append('\t' * (indent - 1) + ')')
            return '\n'.join(lines)
        elif isinstance(v, str):
            # Check if needs quoting
            if re.match(r'^[a-zA-Z0-9_.\-/]+$', v) and not any(kw in v for kw in [' ', '//', '/*']):
                return v
            # Escape special characters
            escaped = v.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')
            return f'"{escaped}"'
        else:
            return str(v)

    for key, obj in objects.items():
        comment = ""
        if isinstance(obj, dict):
            if 'isa' in obj:
                isa = obj['isa']
                if isa == 'PBXFileReference':
                    comment = f" /* {obj.get('path', '')} */"
                elif isa == 'PBXBuildFile':
                    fileRef = obj.get('fileRef', '')
                    # Try to find the file name
                    if fileRef in objects:
                        comment = f" /* {objects[fileRef].get('path', 'Unknown')} in Sources */"
        output_lines.append(f'\t\t{key}{comment} = {format_value(obj)};')

    output_lines.append("};")
    output_lines.append("}")

    # Write the file
    with open(project_path, 'w') as f:
        f.write('\n'.join(output_lines))

    print(f"\nDone! Added {added} files to the project.")
    print("Please rebuild in Xcode.")

if __name__ == "__main__":
    main()
