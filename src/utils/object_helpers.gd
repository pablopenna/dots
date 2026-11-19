class_name ObjectHelpers
extends RefCounted
## Small helpers for working with Godot objects and unimplemented overrides.


static func disconnect_all_signals(object: Object) -> void:
	for signal_info in object.get_signal_list():
		var signal_name := signal_info.name as StringName
		for connection in object.get_signal_connection_list(signal_name):
			object.disconnect(signal_name, connection.callable as Callable)


static func value_has_method(value: Variant, method_name: StringName) -> bool:
	return value is Object and (value as Object).has_method(method_name)


static func reject_read_only_property_assignment() -> void:
	assert(false, "Property is readonly")


static func not_implemented() -> Variant:
	assert(false, "Not implemented")
	return null


static func do_nothing() -> void:
	pass
