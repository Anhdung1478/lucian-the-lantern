class_name HudCell
extends RefCounted
## What the HUD's cells share (skills, summoner spells, items, potions, boots
## and buffs): UiStyle's dark well with a thin rim that eases to gold while
## hovered (UiMotion.lit), small dark tabs in the corners (the key bottom
## right, a mana cost or a stack count top left), the seconds left on a
## cooldown, and where their hover cards hang: above the plate they sit on.

## What a cell holds sits this far inside it, clear of the rim.
const INSET := 2.0
const RADIUS := 4
## A corner tab: its fill, the room beside its text and above and under it.
const TAB_COLOR := Color(0.03, 0.04, 0.06, 0.92)
const TAB_PAD := Vector2(4.0, 1.0)
const KEY_FONT := UiStyle.FONT_TAG
const KEY_COLOR := UiStyle.TITLE_COLOR
## A capital's height as a share of the font size, to center a key in its tab.
const CAP_HEIGHT := 0.72
const OUTLINE := 4
## The meta a HUD plate carries so its cells' cards hang above it; its value
## is a Control whose top counts too when it shows something (the buff row
## above the bottom bar), or true for none (a null meta is no meta).
const TIP_PLATE := &"hud_tip_plate"
## The meta a HUD plate beside another may carry: that other Control, which
## its cells' cards keep clear of (the stats panel's cards stay left of the
## bottom bar, centred in the room between the screen's edge and the bar).
const TIP_CLEAR := &"hud_tip_clear"
## A card's bottom sits this far above the plate (8 px on screen), less the
## gap HoverTip leaves itself.
const TIP_GAP := 10.0


## The cell's well and rim over `rect`: the rim is `rim`, eased toward gold by
## `lit_t` (0 to 1, UiMotion.lit_t()).
static func draw_box(canvas: CanvasItem, rect: Rect2, rim := UiStyle.CELL_BORDER, lit_t := 0.0, radius := RADIUS) -> void:
	canvas.draw_style_box(UiStyle.cell_style_t(rim, lit_t, radius), rect)


## The key in a dark tab in the bottom-right corner of the cell at `rect`.
static func draw_key(canvas: CanvasItem, rect: Rect2, key: String, font_size := KEY_FONT) -> void:
	draw_tab(canvas, rect, key, CORNER_BOTTOM_RIGHT, KEY_COLOR, font_size)


## `text` in a dark tab flush in `corner` (top left or bottom right) of the
## cell at `rect`, inside its rim. Nothing for "".
static func draw_tab(canvas: CanvasItem, rect: Rect2, text: String, corner: Corner, color := KEY_COLOR, font_size := KEY_FONT) -> void:
	if text == "":
		return
	var font := ThemeDB.fallback_font
	var tab := tab_rect(rect, text, corner, font_size)
	var style := StyleBoxFlat.new()
	style.bg_color = TAB_COLOR
	# Its own corner follows the cell's; the one toward the icon is rounded.
	style.set_corner_radius(corner, RADIUS - 1)
	style.set_corner_radius(((corner + 2) % 4) as Corner, RADIUS)
	canvas.draw_style_box(style, tab)
	var baseline := tab.get_center().y + font_size * CAP_HEIGHT * 0.5
	canvas.draw_string(font, Vector2(tab.position.x + TAB_PAD.x, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


## Where draw_tab puts the tab for `text`: one pixel inside the rim in
## `corner` of `rect`.
static func tab_rect(rect: Rect2, text: String, corner: Corner, font_size := KEY_FONT) -> Rect2:
	var font := ThemeDB.fallback_font
	var tab_size := Vector2(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + TAB_PAD.x * 2.0,
		font_size * CAP_HEIGHT + TAB_PAD.y * 2.0 + 2.0).ceil()
	var at := rect.position + Vector2.ONE
	if corner == CORNER_TOP_RIGHT or corner == CORNER_BOTTOM_RIGHT:
		at.x = rect.end.x - tab_size.x - 1.0
	if corner == CORNER_BOTTOM_LEFT or corner == CORNER_BOTTOM_RIGHT:
		at.y = rect.end.y - tab_size.y - 1.0
	return Rect2(at, tab_size)


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


## Where the hover card of `cell` (whose cell is `cell_rect`, in its own
## coordinates) hangs, for HoverTip's tooltip_anchor(): over the cell's
## columns, TIP_GAP above the plate it sits on (and above that plate's buff
## row when the row shows icons). Just the cell when it is on no HUD plate.
static func tip_anchor(cell: Control, cell_rect := Rect2()) -> Rect2:
	var own := cell.get_global_transform() * (cell_rect if cell_rect.has_area() else Rect2(Vector2.ZERO, cell.size))
	var plate := cell.get_parent() as Control
	while plate and not plate.has_meta(TIP_PLATE):
		plate = plate.get_parent() as Control
	if plate == null:
		return own
	var top := plate.get_global_rect().position.y
	var above: Variant = plate.get_meta(TIP_PLATE)
	if is_instance_valid(above) and above is Control and (above as Control).is_visible_in_tree():
		for child: Control in (above as Control).get_children():
			if child.visible:
				top = minf(top, child.get_global_rect().position.y)
	top -= TIP_GAP - HoverTip.GAP
	var clear: Variant = plate.get_meta(TIP_CLEAR) if plate.has_meta(TIP_CLEAR) else null
	if is_instance_valid(clear) and clear is Control and (clear as Control).is_visible_in_tree():
		var other := (clear as Control).get_global_rect()
		if own.get_center().x < other.position.x:
			return Rect2(0.0, top, other.position.x - TIP_GAP, 0.0)
	return Rect2(own.position.x, top, own.size.x, 0.0)
