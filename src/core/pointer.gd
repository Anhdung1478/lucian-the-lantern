class_name Pointer
extends RefCounted
## Where the mouse is. The game asks here, never the viewport, so the
## screenshot tool can place a pretend mouse without moving the real one.

## The pretend mouse in the root viewport's canvas units; null means the
## real mouse. Only tools and tests set it.
static var pretend: Variant = null


## The mouse in `node`'s viewport, in canvas units.
static func on_screen(node: Node) -> Vector2:
	if pretend != null:
		return pretend
	return node.get_viewport().get_mouse_position()


## The mouse in `item`'s own canvas: world units for a node under the camera.
static func in_world(item: CanvasItem) -> Vector2:
	if pretend != null:
		return item.get_canvas_transform().affine_inverse() * (pretend as Vector2)
	return item.get_global_mouse_position()
