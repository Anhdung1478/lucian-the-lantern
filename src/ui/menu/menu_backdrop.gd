class_name MenuBackdrop
extends Control
## Behind a menu or pop-up, filling the screen: what is behind it, blurred,
## darkened and vignetted (menu_backdrop.gdshader). It stops clicks. The
## menu's own controls go in as its children, over the blur. A BackBufferCopy
## takes a fresh copy of the screen first, so a pop-up over another menu
## blurs that menu too. `strength` fades the dim and blur in and out
## (UiMotion.open_overlay and close_overlay tween it).

const SHADER := preload("res://src/ui/menu/menu_backdrop.gdshader")

## Shared by every backdrop (shared_material()).
static var _material: ShaderMaterial

var blur := ColorRect.new()
## How much of the dim and blur shows: 0 the screen as it is, 1 fully blurred
## and darkened. It fades the blur layer only, never the menu on it.
var strength := 1.0:
	set(value):
		strength = clampf(value, 0.0, 1.0)
		blur.modulate.a = strength


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var copy := BackBufferCopy.new()
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(copy)
	blur.color = Color.BLACK
	blur.set_anchors_preset(Control.PRESET_FULL_RECT)
	blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blur.material = shared_material()
	add_child(blur)


static func shared_material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = SHADER
	return _material
