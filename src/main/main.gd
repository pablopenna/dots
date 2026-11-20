class_name Main extends Node
## Main entry point for the application.
##
## Handles CLI vs GUI mode detection and initialization.

@export_file() var gui_scene_path: String

const APP_ICON: Texture2D = preload("res://assets/logo/logo_256.webp")

func _ready() -> void:
	var args := OS.get_cmdline_args()
	var user_args := OS.get_cmdline_user_args()

	if _is_cli_mode(args):
		Output.push("Run cli mode")
		CliMain.main(args, user_args)
		_exit()
	
	Output.push("Run window mode")
	_handle_app_icon()
	add_child.call_deferred((load(gui_scene_path) as PackedScene).instantiate())

func _handle_app_icon() -> void:
	# On macOS the Dock shows the app bundle's icon; setting one here would swap it
	# for the bare logo, so leave it alone like the engine does for bundle icons.
	if OS.has_feature("macos"):
		return
	
	var app_icon_image := APP_ICON.get_image()
	if OS.has_feature("linux"):
		# A 256x256 _NET_WM_ICON exceeds X11's core request limit.
		app_icon_image.resize(192, 192, Image.INTERPOLATE_LANCZOS)
	DisplayServer.set_icon(app_icon_image)

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
