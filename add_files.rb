#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'boringNotch.xcodeproj/project.pbxproj'
project = Xcodeproj::Project.open('boringNotch.xcodeproj')

# Find the main target
target = project.targets.find { |t| t.name == 'boringNotch' }

if target.nil?
  puts "Error: Could not find boringNotch target"
  exit 1
end

puts "Found target: #{target.name}"

# Files to add: [file_name, group_name, full_path_from_project_root]
files_to_add = [
  # Models
  ['ClaudeTask.swift', 'models', 'boringNotch/models/ClaudeTask.swift'],
  # Manager
  ['ClaudeTasksManager.swift', 'managers', 'boringNotch/managers/ClaudeTasksManager.swift'],
  # ClaudeTasks components
  ['ClaudeTasksBadge.swift', 'ClaudeTasks', 'boringNotch/components/ClaudeTasks/ClaudeTasksBadge.swift'],
  ['ClaudeTasksOverlay.swift', 'ClaudeTasks', 'boringNotch/components/ClaudeTasks/ClaudeTasksOverlay.swift'],
  ['ClaudeTasksExpandedView.swift', 'ClaudeTasks', 'boringNotch/components/ClaudeTasks/ClaudeTasksExpandedView.swift'],
  ['PaginationControl.swift', 'ClaudeTasks', 'boringNotch/components/ClaudeTasks/PaginationControl.swift'],
  ['RepoPageCard.swift', 'ClaudeTasks', 'boringNotch/components/ClaudeTasks/RepoPageCard.swift'],
  ['TaskRow.swift', 'ClaudeTasks', 'boringNotch/components/ClaudeTasks/TaskRow.swift'],
  # Extension
  ['ClaudeTasksDefaults.swift', 'extensions', 'boringNotch/extensions/ClaudeTasksDefaults.swift'],
]

# Find or create groups
def find_or_create_group(parent, name)
  existing = parent.groups.find { |g| g.path == name || g.name == name }
  return existing if existing

  group = parent.new_group(name)
  puts "Created group: #{name}"
  group
end

# Get the main group
main_group = project.main_group

# Find existing groups
managers_group = nil
extensions_group = nil
components_group = nil
claudetasks_group = nil
models_group = nil

main_group.recursive_children_groups.each do |group|
  case group.path || group.name
  when 'managers'
    managers_group = group
  when 'extensions'
    extensions_group = group
  when 'components'
    components_group = group
  when 'ClaudeTasks'
    claudetasks_group = group
  when 'models'
    models_group = group
  end
end

puts "Found groups: managers=#{!managers_group.nil?}, extensions=#{!extensions_group.nil?}, components=#{!components_group.nil?}, ClaudeTasks=#{!claudetasks_group.nil?}"

# Create ClaudeTasks group if it doesn't exist
if claudetasks_group.nil? && components_group
  claudetasks_group = find_or_create_group(components_group, 'ClaudeTasks')
end

added_count = 0

files_to_add.each do |file_name, group_name, full_path|
  # Check if file already exists
  existing_file = project.files.find { |f| f.path == full_path || f.path == file_name }

  if existing_file
    puts "File already exists in project: #{full_path}"
    # Check if it's in the target
    unless target.source_build_phase.files.any? { |bf| bf.file_ref == existing_file }
      target.source_build_phase.add_file_reference(existing_file)
      puts "  Added to target build phase"
    end
    next
  end

  # Determine the target group
  target_group = case group_name
                 when 'ClaudeTasks'
                   claudetasks_group
                 when 'models'
                   models_group
                 else
                   eval("#{group_name}_group")
                 end

  if target_group.nil?
    puts "Warning: Could not find group for #{group_name}, adding to main group"
    target_group = main_group
  end

  # Add the file to the group with full path
  # For files in ClaudeTasks group, the path should be relative to components parent
  file_path = case group_name
              when 'ClaudeTasks'
                "ClaudeTasks/#{file_name}"
              else
                file_name
              end

  file_ref = target_group.new_file(file_path)

  # Add to target build phase
  target.source_build_phase.add_file_reference(file_ref)

  puts "Added: #{file_path} -> #{group_name} (full: #{full_path})"
  added_count += 1
end

# Save the project
project.save
puts "\nDone! Added #{added_count} files to the project."
