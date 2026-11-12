class_name RecipeChoice
extends Control
## One cell of a recipe line that takes either of several items: the two
## starting boots of a second-tier boots line, which make the same boots. The
## items share one dark well, stepping down its diagonal, and each has its
## own card. The rim is the first item's kind, gold while `lit`.

## Each item's side, as a share of the room inside the well.
const SHARE := 0.6

var icons: Array[ItemIcon] = []
var lit := false:
	set(value):
		lit = value
		queue_redraw()


func _init(options: Array[ItemData], catalog: ItemCatalog) -> void:
	mouse_filter = MOUSE_FILTER_PASS
	for option in options:
		var icon := ItemIcon.new(option, catalog)
		add_child(icon)
		icons.append(icon)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_place()


func _draw() -> void:
	draw_style_box(UiStyle.cell_style(UiStyle.item_rim(icons[0].item), lit, ItemIcon.FRAME_RADIUS), Rect2(Vector2.ZERO, size))


## The items from the well's top-left corner to its bottom-right one.
func _place() -> void:
	var inner := Rect2(Vector2.ZERO, size).grow(-ItemIcon.FRAME_INSET)
	var side := inner.size * SHARE
	var step := (inner.size - side) / maxf(icons.size() - 1, 1.0)
	for i in icons.size():
		icons[i].position = inner.position + step * i
		icons[i].size = side
