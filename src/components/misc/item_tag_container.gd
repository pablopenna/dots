class_name ItemTagContainer
extends HBoxContainer
## Container for displaying and managing item tags.


## Emitted when tag clicked.
signal tag_clicked(tag: String)

## Packed scene for tag scene.
@export var _tag_scene: PackedScene = preload("res://src/components/tags/tag/tag.tscn")


func set_tags(tags: Array) -> void:
	for child: Node in get_children():
		child.queue_free()
	for tag: String in tags:
		var tag_control: TagControl = _tag_scene.instantiate()
		add_child(tag_control)
		tag_control.init(tag)
		tag_control.pressed.connect(func() -> void: tag_clicked.emit(tag))
