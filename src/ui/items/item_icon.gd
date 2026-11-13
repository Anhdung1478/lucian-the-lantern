class_name ItemIcon
extends Control
## Draws an item's icon. Items without an icon yet get a colored tile with
## their code. Hovering shows the item card when `tooltips` is on. When
## `framed`, the icon sits in a dark well whose rim follows the item
## (UiStyle.item_rim) and is gold while `lit` (unless `show_lit` is off: the
## recipe lines keep every rim its kind's colour).

## Tile colors by fragment code; legendaries use LEGENDARY_COLOR.
const CODE_COLORS := {
	"AD": Color("b8452e"), "AS": Color("c99a2e"), "AP": Color("7a4cc2"), "AR": Color("6f7884"),
	"CR": Color("d9d2b0"), "HP": Color("a83248"), "MP": Color("2f6fc4"), "MR": Color("6a3f8f"),
}
const LEGENDARY_COLOR := Color("8a6a2a")
const BOOTS_COLOR := Color("5c4a36")
const BORDER_COLOR := Color(0.07, 0.08, 0.1)
## A corner tag (a stack count, a cell's key): its plate and thin rim, its
## text size, the room beside the text, its height and its rounded corner.
const TAG_COLOR := Color(0.02, 0.03, 0.05, 0.9)
const TAG_RIM := Color(1, 1, 1, 0.16)
const TAG_FONT := 13
const TAG_PAD := 5.0
const TAG_HEIGHT := 18.0
const TAG_RADIUS := 5
## A framed icon: the room between the well's rim and the icon, and the
## well's corner.
const FRAME_INSET := 3.0
const FRAME_RADIUS := 4

var item: ItemData:
	set(value):
		item = value
		queue_redraw()
## Used by the card to name a legendary's recipe.
var catalog: ItemCatalog
var tooltips := true
var framed := false:
	set(value):
		framed = value
		queue_redraw()
var lit := false:
	set(value):
		lit = value
		queue_redraw()
var show_lit := true


func _init(icon_item: ItemData = null, item_catalog: ItemCatalog = null) -> void:
	item = icon_item
	catalog = item_catalog
	mouse_filter = MOUSE_FILTER_PASS


func tooltip_content() -> Control:
	return TooltipCard.item(item, catalog) if tooltips and item else null


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if framed:
		draw_style_box(UiStyle.cell_style(UiStyle.item_rim(item), lit and show_lit, FRAME_RADIUS), rect)
		rect = rect.grow(-FRAME_INSET)
	draw_item(self, item, rect)


## Shared with cells that draw an item inside their own frame. `tint` fades
## an empty cell's placeholder.
static func draw_item(canvas: CanvasItem, shown: ItemData, rect: Rect2, tint := Color.WHITE) -> void:
	if shown == null:
		return
	if shown.icon:
		canvas.draw_texture_rect(shown.icon, rect, false, tint)
		return
	var fill := LEGENDARY_COLOR
	if shown.is_fragment():
		fill = CODE_COLORS.get(shown.code, LEGENDARY_COLOR)
	elif shown.is_boots():
		fill = BOOTS_COLOR
	canvas.draw_rect(rect, fill * tint)
	canvas.draw_rect(rect.grow(-1.0), BORDER_COLOR * tint, false, 2.0)
	var font := ThemeDB.fallback_font
	var font_size := int(rect.size.y * 0.3)
	var text_color := Color.BLACK if fill.get_luminance() > 0.6 else Color.WHITE
	canvas.draw_string(font, Vector2(rect.position.x, rect.get_center().y + font_size * 0.35), shown.code,
		HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, text_color)


## A stack count (only above 1), in the top-left or bottom-right of `rect`.
static func draw_count(canvas: CanvasItem, count: int, rect: Rect2, top_left := false) -> void:
	if count <= 1:
		return
	var font := ThemeDB.fallback_font
	var font_size := int(clampf(rect.size.y * 0.32, 11.0, 18.0))
	var at := Vector2(rect.position.x, rect.end.y - 3.0)
	if top_left:
		at = Vector2(rect.position.x + 3.0, rect.position.y + font_size)
	var align := HORIZONTAL_ALIGNMENT_LEFT if top_left else HORIZONTAL_ALIGNMENT_RIGHT
	var width := rect.size.x - 3.0
	canvas.draw_string_outline(font, at, str(count), align, width, font_size, 5, Color.BLACK)
	canvas.draw_string(font, at, str(count), align, width, font_size, Color.WHITE)


## A small dark tag with `text` in a corner of `rect` (a cell): its own
## corner there follows the cell's (`radius`), the opposite one is rounded.
## Nothing is drawn for "".
static func draw_tag(canvas: CanvasItem, text: String, rect: Rect2, corner: Corner, color := Color.WHITE, radius := 4) -> void:
	if text == "":
		return
	var font := ThemeDB.fallback_font
	var tag := tag_rect(text, rect, corner)
	var box := StyleBoxFlat.new()
	box.bg_color = TAG_COLOR
	box.border_color = TAG_RIM
	box.set_border_width_all(1)
	box.set_corner_radius(corner, radius)
	var opposite := ((corner + 2) % 4) as Corner
	box.set_corner_radius(opposite, TAG_RADIUS)
	canvas.draw_style_box(box, tag)
	canvas.draw_string(font, Vector2(tag.position.x, tag.end.y - 4.5), text, HORIZONTAL_ALIGNMENT_CENTER, tag.size.x, TAG_FONT, color)


## Where draw_tag puts the tag for `text`: flush in `corner` of `rect`.
static func tag_rect(text: String, rect: Rect2, corner: Corner) -> Rect2:
	var width := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, TAG_FONT).x + TAG_PAD * 2.0
	var at := rect.position
	if corner == CORNER_TOP_RIGHT or corner == CORNER_BOTTOM_RIGHT:
		at.x = rect.end.x - width
	if corner == CORNER_BOTTOM_LEFT or corner == CORNER_BOTTOM_RIGHT:
		at.y = rect.end.y - TAG_HEIGHT
	return Rect2(at, Vector2(width, TAG_HEIGHT))
