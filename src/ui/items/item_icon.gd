class_name ItemIcon
extends Control
## Draws an item's icon. Items without an icon yet get a colored tile with
## their code. Hovering shows the item card when `tooltips` is on.

## Tile colors by fragment code; legendaries use LEGENDARY_COLOR.
const CODE_COLORS := {
	"AD": Color("b8452e"), "AS": Color("c99a2e"), "AP": Color("7a4cc2"), "AR": Color("6f7884"),
	"CR": Color("d9d2b0"), "HP": Color("a83248"), "MP": Color("2f6fc4"), "MR": Color("6a3f8f"),
}
const LEGENDARY_COLOR := Color("8a6a2a")
const BORDER_COLOR := Color(0.07, 0.08, 0.1)

var item: ItemData:
	set(value):
		item = value
		queue_redraw()
## Used by the card to name a legendary's recipe.
var catalog: ItemCatalog
var tooltips := true


func _init(icon_item: ItemData = null, item_catalog: ItemCatalog = null) -> void:
	item = icon_item
	catalog = item_catalog
	mouse_filter = MOUSE_FILTER_PASS


func tooltip_content() -> Control:
	return TooltipCard.item(item, catalog) if tooltips and item else null


func _draw() -> void:
	draw_item(self, item, Rect2(Vector2.ZERO, size))


## Shared with cells that draw an item inside their own frame.
static func draw_item(canvas: CanvasItem, shown: ItemData, rect: Rect2) -> void:
	if shown == null:
		return
	if shown.icon:
		canvas.draw_texture_rect(shown.icon, rect, false)
		return
	var fill: Color = CODE_COLORS.get(shown.code, LEGENDARY_COLOR) if shown.is_fragment() else LEGENDARY_COLOR
	canvas.draw_rect(rect, fill)
	canvas.draw_rect(rect.grow(-1.0), BORDER_COLOR, false, 2.0)
	var font := ThemeDB.fallback_font
	var font_size := int(rect.size.y * 0.3)
	var text_color := Color.BLACK if fill.get_luminance() > 0.6 else Color.WHITE
	canvas.draw_string(font, Vector2(rect.position.x, rect.get_center().y + font_size * 0.35), shown.code,
		HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, text_color)
