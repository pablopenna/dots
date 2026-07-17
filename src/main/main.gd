class_name Main
extends Node
## Main entry point for the application.
##
## Handles CLI vs GUI mode detection and initialization.


## Packed scene for gui scene path.
@export_file() var gui_scene_path: String

const APP_ICON: Texture2D = preload("res://assets/logo/logo_256.webp")


func _ready() -> void:
	var args := OS.get_cmdline_args()
	var user_args := OS.get_cmdline_user_args()

	if _is_cli_mode(args):
		Output.push("Run cli mode")
		CliMain.main(args, user_args)
		_exit()
	else:
		Output.push("Run window mode")
		DisplayServer.set_icon(APP_ICON.get_image())
		add_child.call_deferred((load(gui_scene_path) as PackedScene).instantiate())
	pass


func _is_cli_mode(args: PackedStringArray) -> bool:
	if args.is_empty():
		return false

	var grammar := CliGrammar.new(GodotsCommands.commands)
	var first := args[0]

	if first.begins_with("-"):
		return grammar.supports_flag("", "", first)

	return grammar.supports_verb("", first) or grammar.supports_namespace(first)


func _exit() -> void:
	get_tree().quit()
