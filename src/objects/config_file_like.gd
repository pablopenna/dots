class_name IConfigFileLike
extends RefCounted
## Provides i config file like.


func set_value(section: String, key: String, value: Variant) -> void:
	return ObjectHelpers.not_implemented()


func get_value(section: String, key: String, default: Variant = null) -> Variant:
	return ObjectHelpers.not_implemented()


func has_section_key(section: String, key: String) -> bool:
	return ObjectHelpers.not_implemented()


func save(path: String) -> Error:
	return ObjectHelpers.not_implemented()


static func of_config(cfg: ConfigFile) -> IConfigFileLike:
	return _OfConfig.new(cfg)


class _OfConfig extends IConfigFileLike:
	var _origin: ConfigFile
	
	func _init(origin: ConfigFile) -> void:
		_origin = origin
	
	func set_value(section: String, key: String, value: Variant) -> void:
		_origin.set_value(section, key, value)

	func get_value(section: String, key: String, default: Variant = null) -> Variant:
		return _origin.get_value(section, key, default)

	func save(path: String) -> Error:
		return _origin.save(path)

	func has_section_key(section: String, key: String) -> bool:
		return _origin.has_section_key(section, key)
