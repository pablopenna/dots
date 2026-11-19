class_name UiLayout
extends RefCounted
## Helpers for laying out controls at the project's editor scale.


## Passes a size no taller than [param max_height] to [param on_fitted_size],
## keeping the aspect ratio of [param current_size]. Does nothing when the size
## already fits.
static func fit_size_to_max_height(
	max_height: float,
	current_size: Vector2i,
	editor_scale: float,
	on_fitted_size: Callable
) -> void:
	var scaled_height := current_size.y * editor_scale
	var scale_ratio := max_height / scaled_height
	if scale_ratio >= 1:
		return
	on_fitted_size.call(Vector2i(
		int(current_size.x * editor_scale * scale_ratio),
		int(current_size.y * editor_scale * scale_ratio),
	))
