class_name Plate
extends PanelContainer
## The stage screens' frame, in the menus' look (MenuCard) without the
## medallion or the title: a navy-to-teal gradient, a gold line around it
## and, when `ornate`, a fainter line inside with a gold diamond at each of
## its corners. The HUD's bars, the backpack, the merchant's shop and the
## end screen sit on one. `draw_on` paints the same frame on any CanvasItem.

## The inner line, this far inside the outer one, and how faint it is.
const INNER_INSET := 5.0
const INNER_ALPHA := 0.4
const DIAMOND := 4.0
const SHADOW := Color(0, 0, 0, 0.5)
const SHADOW_SIZE := 14

## The room between the frame and what it holds, on every side.
var pad := 14.0:
	set(value):
		pad = value
		_apply_pad()
var radius := 10.0:
	set(value):
		radius = value
		queue_redraw()
## The inner line and its corner diamonds.
var ornate := true:
	set(value):
		ornate = value
		queue_redraw()
## 1.0 hides what is behind; the HUD's plates let a little of the fight through.
var opacity := 0.96:
	set(value):
		opacity = value
		queue_redraw()
var shadow := true:
	set(value):
		shadow = value
		queue_redraw()


func _init(content_pad := 14.0, with_ornaments := true) -> void:
	ornate = with_ornaments
	pad = content_pad


func _apply_pad() -> void:
	var style := StyleBoxEmpty.new()
	style.set_content_margin_all(pad)
	add_theme_stylebox_override(&"panel", style)


func _draw() -> void:
	draw_on(self, Rect2(Vector2.ZERO, size), radius, ornate, opacity, shadow)


## Paints a plate over `rect` on `canvas` (call it from its _draw).
static func draw_on(canvas: CanvasItem, rect: Rect2, corner := 10.0, with_ornaments := true, alpha := 0.96, with_shadow := true) -> void:
	var top := Color(UiStyle.PLATE_TOP, alpha)
	var bottom := Color(UiStyle.PLATE_BOTTOM, alpha)
	var back := StyleBoxFlat.new()
	back.bg_color = top
	back.set_corner_radius_all(int(corner))
	if with_shadow:
		back.shadow_color = SHADOW
		back.shadow_size = SHADOW_SIZE
		back.shadow_offset = Vector2(0, 4)
	canvas.draw_style_box(back, rect)
	var inside := rect.grow(-2.0)
	if inside.size.x > corner * 2.0 and inside.size.y > corner * 2.0:
		var points := MenuCard.rounded_rect(inside, maxf(corner - 2.0, 1.0))
		var colors := PackedColorArray()
		for point in points:
			colors.append(top.lerp(bottom, inverse_lerp(inside.position.y, inside.end.y, point.y)))
		canvas.draw_polygon(points, colors)
	var outer := StyleBoxFlat.new()
	outer.draw_center = false
	outer.border_color = UiStyle.BORDER_COLOR
	outer.set_border_width_all(2)
	outer.set_corner_radius_all(int(corner))
	canvas.draw_style_box(outer, rect)
	if not with_ornaments:
		return
	var inner_rect := rect.grow(-INNER_INSET)
	var inner := StyleBoxFlat.new()
	inner.draw_center = false
	inner.border_color = Color(UiStyle.BORDER_COLOR, INNER_ALPHA)
	inner.set_border_width_all(1)
	inner.set_corner_radius_all(int(maxf(corner - INNER_INSET + 2.0, 1.0)))
	canvas.draw_style_box(inner, inner_rect)
	for at: Vector2 in [inner_rect.position, Vector2(inner_rect.end.x, inner_rect.position.y), inner_rect.end, Vector2(inner_rect.position.x, inner_rect.end.y)]:
		canvas.draw_colored_polygon(diamond(at, DIAMOND), UiStyle.GOLD_COLOR)


## A diamond of `size` around `at`.
static func diamond(at: Vector2, size: float) -> PackedVector2Array:
	return PackedVector2Array([at + Vector2(0, -size), at + Vector2(size, 0), at + Vector2(0, size), at + Vector2(-size, 0)])
