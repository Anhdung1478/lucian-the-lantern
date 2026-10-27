class_name CraftPopup
extends Control
## Crafting preview shown while a fragment is held over its recipe partner:
## the legendary's card, with a line running clockwise around the border from
## the top-left corner. Once the line closes, releasing crafts.

const LINE_COLOR := Color("fff1c2")
const LINE_WIDTH := 4.0
const GAP := 10.0
const MARGIN := 8.0

## 0..1, how far the line has gone around.
var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		_line.queue_redraw()
## The target cell's rectangle; the popup sits beside it.
var anchor := Rect2()

var _card: Control
var _line := Control.new()


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	visible = false
	_line.mouse_filter = MOUSE_FILTER_IGNORE
	_line.draw.connect(_draw_line)
	add_child(_line)


func show_result(item: ItemData, catalog: ItemCatalog, target_rect: Rect2) -> void:
	if _card:
		_card.queue_free()
	_card = TooltipCard.item(item, catalog)
	add_child(_card)
	move_child(_card, 0)
	anchor = target_rect
	progress = 0.0
	visible = true
	_fit()


func _process(_delta: float) -> void:
	if visible and _card:
		_fit()


## Follows the card's size (rich text settles a frame late) and stays beside
## the target cell, flipping left when there is no room on the right.
func _fit() -> void:
	size = _card.size
	_line.size = size
	var screen := get_viewport().get_visible_rect().grow(-MARGIN)
	var at := Vector2(anchor.end.x + GAP, anchor.position.y)
	if at.x + size.x > screen.end.x:
		at.x = anchor.position.x - GAP - size.x
	position = at.clamp(screen.position, screen.end - size)


func _draw_line() -> void:
	var rect := Rect2(Vector2.ZERO, size).grow(-LINE_WIDTH * 0.5)
	var corners: Array[Vector2] = [
		rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y), rect.position]
	var left := progress * 2.0 * (rect.size.x + rect.size.y)
	var points := PackedVector2Array([corners[0]])
	for i in 4:
		var side := corners[i + 1] - corners[i]
		if left >= side.length():
			points.append(corners[i + 1])
			left -= side.length()
		else:
			points.append(corners[i] + side.normalized() * left)
			break
	if points.size() >= 2:
		_line.draw_polyline(points, LINE_COLOR, LINE_WIDTH, true)
