class_name utils
extends RefCounted
## Provides utils.


static var _re_version := _compile_re(r"godot[-_]?v?(\d+(?:\.\d+)+)")
static var _re_channel := _compile_re(r"-(pre-alpha|alpha|beta|rc|stable|dev)(\d*)")
static var _re_any_version := _compile_re(r"(\d+(?:\.\d+)+)")
static var _re_mono := _compile_re(r"(?:^|[-_.])mono(?:$|[-_.])")

static func _compile_re(pattern: String) -> RegEx:
	var re := RegEx.new()
	re.compile(pattern)
	return re


static func guess_editor_name(file_name: String) -> String:
	var base := _strip_known_extensions(file_name.get_file())
	var lower := base.to_lower()
	var version_match := _re_version.search(lower)
	var channel_match := _re_channel.search(lower)
	var version := version_match.get_string(1) if version_match else ""
	var channel := channel_match.get_string(1) if channel_match else ""
	var channel_number := channel_match.get_string(2) if channel_match else ""
	if version.is_empty():
		var any_version_match := _re_any_version.search(lower)
		version = any_version_match.get_string(1) if any_version_match else ""
	if version.is_empty():
		return base
	var suffix := ""
	if not channel.is_empty():
		suffix = " " + channel
		if not channel_number.is_empty():
			suffix += channel_number
	var editor_name := "Godot v%s%s" % [version, suffix]
	if _re_mono.search(lower) != null:
		editor_name += " mono"
	return editor_name


static func _strip_known_extensions(base: String) -> String:
	var lower_base := base.to_lower()
	var compound_extensions: PackedStringArray = [
		".exe.zip", ".universal.dmg", ".universal.zip",
		".x86_64", ".x86_32", ".arm64", ".arm32",
	]
	for ext: String in compound_extensions:
		if lower_base.ends_with(ext):
			return base.substr(0, base.length() - ext.length())
	var simple_extensions: PackedStringArray = [
		".exe", ".zip", ".dmg", ".tpz", ".aab", ".apk", ".aar",
		".xz", ".sha256", ".tar",
	]
	for ext: String in simple_extensions:
		if lower_base.ends_with(ext):
			return base.substr(0, base.length() - ext.length())
	return base


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
