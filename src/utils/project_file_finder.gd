class_name ProjectFileFinder
extends RefCounted
## Locates Godot project files on disk.


static func find_project_godot_files(directory_path: String) -> Array[edir.DirListResult]:
	var project_files := edir.list_recursive(
		ProjectSettings.globalize_path(directory_path),
		false,
		func(listed_entry: edir.DirListResult) -> bool:
			return listed_entry.is_file and listed_entry.file == "project.godot",
		func(listed_path: String) -> bool:
			return not listed_path.get_file().begins_with("."),
	)
	return project_files
