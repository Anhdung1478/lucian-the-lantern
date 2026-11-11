class_name HudCell
extends RefCounted
## What the HUD's cells share (skills, summoner spells, items, potions, boots
## and buffs): UiStyle's dark well with a thin rim that turns gold when
## hovered, the key in a small dark tab in the bottom-right corner, and the
## seconds left on a cooldown.

## What a cell holds sits this far inside it, clear of the rim.
const INSET := 2.0
const RADIUS := 4
## The key's tab: its fill, the room beside the key and above and under it.
const TAB_COLOR := Color(0.03, 0.04, 0.06, 0.92)
const TAB_PAD := Vector2(4.0, 1.0)
const KEY_FONT := 13
const KEY_COLOR := UiStyle.TITLE_COLOR
## A capital's height as a share of the font size, to center a key in its tab.
const CAP_HEIGHT := 0.72
const OUTLINE := 4


## The cell's well and rim over `rect`: the rim is `rim`, or gold when `lit`.
static func draw_box(canvas: CanvasItem, rect: Rect2, rim := UiStyle.CELL_BORDER, lit := false, radius := RADIUS) -> void:
	canvas.draw_style_box(UiStyle.cell_style(rim, lit, radius), rect)


## The key in a dark tab in the bottom-right corner of the cell at `rect`.
static func draw_key(canvas: CanvasItem, rect: Rect2, key: String, font_size := KEY_FONT) -> void:
	if key == "":
		return
	var font := ThemeDB.fallback_font
	var cap := font_size * CAP_HEIGHT
	var tab_size := Vector2(font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + TAB_PAD.x * 2.0, cap + TAB_PAD.y * 2.0 + 2.0).ceil()
	var tab := Rect2(rect.end - tab_size - Vector2.ONE, tab_size)
	var style := StyleBoxFlat.new()
	style.bg_color = TAB_COLOR
	style.corner_radius_top_left = RADIUS
	style.corner_radius_bottom_right = RADIUS - 1
	canvas.draw_style_box(style, tab)
	var baseline := tab.get_center().y + cap * 0.5
	canvas.draw_string(font, Vector2(tab.position.x + TAB_PAD.x, baseline), key, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, KEY_COLOR)


## A cooldown's seconds as its cell shows them: tenths under a second, whole
## seconds (rounded up) above.
static func seconds_text(remaining: float) -> String:
	return "%.1f" % remaining if remaining < 1.0 else str(ceili(remaining))


## White text with a black outline, aligned within `width` from `at` (its
## baseline's left end).
static func draw_text(canvas: CanvasItem, at: Vector2, text: String, align: HorizontalAlignment, width: float, font_size: int) -> void:
	var font := ThemeDB.fallback_font
	canvas.draw_string_outline(font, at, text, align, width, font_size, OUTLINE, Color.BLACK)
	canvas.draw_string(font, at, text, align, width, font_size, Color.WHITE)
