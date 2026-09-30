class_name utils
extends RefCounted
## Provides utils.


static var _version_pattern := _compile_regex(r"godot[-_]?v?(\d+(?:\.\d+)+)")
static var _channel_pattern := _compile_regex(r"-(pre-alpha|alpha|beta|rc|stable|dev)(\d*)")
static var _any_version_pattern := _compile_regex(r"(\d+(?:\.\d+)+)")
static var _mono_pattern := _compile_regex(r"(?:^|[-_.])mono(?:$|[-_.])")
# An extension starts with a letter, so the dot in "Godot_v4.8-dev6_mono_linux_x86_64" is kept.
static var _file_extension_pattern := _compile_regex(r"\.[a-zA-Z][a-zA-Z0-9_]*$")
static var _legacy_channel_pattern := _compile_regex(r"-(alpha|beta|rc|stable)(\d*)")
static var _legacy_extension_pattern := _compile_regex(r"\.[^.]*$")


static func _compile_regex(pattern: String) -> RegEx:
	var compiled_pattern := RegEx.new()
	compiled_pattern.compile(pattern)
	return compiled_pattern


static func guess_editor_name(file_name: String) -> String:
	# Prefer the file name so a folder such as "game-dev" cannot set the channel.
	var guessed_name := _guess_editor_name_from_text(
		file_name.get_file(), _file_extension_pattern, _channel_pattern
	)
	if guessed_name.is_empty():
		guessed_name = _guess_editor_name_from_text(
			file_name, _file_extension_pattern, _channel_pattern
		)
	if guessed_name.is_empty():
		return _remove_trailing_extension(file_name, _file_extension_pattern)
	return guessed_name


## Whether [param editor_name] contains a version, like the names produced by
## [method guess_editor_name] for versioned files.
static func names_version(editor_name: String) -> bool:
	return _any_version_pattern.search(editor_name) != null


## Guesses a name the way older releases did. They missed "dev" builds and cut
## names without an extension at the version dot. Only used to recognize names
## stored by older versions.
static func legacy_guess_editor_name(file_name: String) -> String:
	var guessed_name := _guess_editor_name_from_text(
		file_name, _legacy_extension_pattern, _legacy_channel_pattern
	)
	if guessed_name.is_empty():
		return _remove_trailing_extension(file_name, _legacy_extension_pattern)
	return guessed_name


## Returns an empty string when [param file_name] has no version.
static func _guess_editor_name_from_text(
	file_name: String,
	extension_pattern: RegEx,
	channel_pattern: RegEx
) -> String:
	var base_name := _remove_trailing_extension(file_name, extension_pattern).to_lower()
	var version_match := _version_pattern.search(base_name)
	var version := version_match.get_string(1) if version_match else ""
	if version.is_empty():
		var any_version_match := _any_version_pattern.search(base_name)
		version = any_version_match.get_string(1) if any_version_match else ""
	if version.is_empty():
		return ""
	var channel_match := channel_pattern.search(base_name)
	var channel := channel_match.get_string(1) if channel_match else ""
	var channel_number := channel_match.get_string(2) if channel_match else ""
	var name_suffix := ""
	if not channel.is_empty():
		name_suffix = " " + channel
		if not channel_number.is_empty():
			name_suffix += channel_number
	var editor_name := "Godot v%s%s" % [version, name_suffix]
	if _mono_pattern.search(base_name.get_file()) != null:
		editor_name += " mono"
	return editor_name


static func _remove_trailing_extension(file_name: String, extension_pattern: RegEx) -> String:
	var extension_match := extension_pattern.search(file_name)
	if extension_match:
		return file_name.substr(0, extension_match.get_start())
	return file_name


static func find_project_godot_files(dir_path: String) -> Array[edir.DirListResult]:
	var project_configs := edir.list_recursive(
		ProjectSettings.globalize_path(dir_path), 
		false,
		(func(x: edir.DirListResult) -> bool: 
			return x.is_file and x.file == "project.godot"),
		(func(x: String) -> bool: 
			return not x.get_file().begins_with("."))
	)
	return project_configs


static func response_to_json(response: Variant, safe:=true) -> Variant:
	var body := response[3] as PackedByteArray
	var string := body.get_string_from_utf8()
	if safe:
		return parse_json_safe(string)
	else:
		return JSON.parse_string(string)


static func parse_json_safe(string: String) -> Variant:
	var json := JSON.new()
	var err := json.parse(string)
	if err != OK:
		return null
	else:
		return json.data


static func fit_height(max_height: float, cur_size: Vector2i, callback: Callable) -> void:
	var scale_ratio := max_height / (cur_size.y * Config.EDSCALE)
	if scale_ratio < 1:
		callback.call(Vector2i(
			int(cur_size.x * Config.EDSCALE * scale_ratio),
			int(cur_size.y * Config.EDSCALE * scale_ratio)
		))


static func disconnect_all(obj: Object) -> void:
	for obj_signal in obj.get_signal_list():
		for connection in obj.get_signal_connection_list(obj_signal.name as StringName):
			obj.disconnect(obj_signal.name as StringName, connection.callable as Callable)


static func prop_is_readonly() -> void:
	assert(false, "Property is readonly")


static func not_implemeted() -> Variant:
	assert(false, "Not Implemented")
	return null


static func empty_func() -> void:
	pass


static func obj_has_method(obj: Variant, method: StringName) -> bool:
	if obj is Object:
		return (obj as Object).has_method(method)
	else:
		return false
