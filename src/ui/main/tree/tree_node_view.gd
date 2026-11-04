class_name TreeNodeView
extends Control
## One Evolution Tree node on its branch page: a 96 px square frame with the
## node's icon, a level badge tucked under it and the node's name below. The
## look tells its progress at a glance:
## - hidden: a "?" on a dark frame;
## - not bought (open, or poor when too dear): a greyscale icon in a thin
##   silver frame, its level bar empty;
## - in progress (bought): full colour in a gold frame with a gold glow, the
##   bar lit gold up to the level;
## - done (maxed): a green frame and glow, the bar all green, "MAX" and a
##   check crest at the top-right corner.
## A gold ▲ at the top-left says the next level can be bought now (FREE
## shows at the top-right instead when it costs nothing); a lock at the
## bottom-right says a bought node's next level is closed. A left press
## picks it.

signal chosen(id: StringName)

const SIZE := 96.0
const ICON_INSET := 6.0
const CORNER := 10
## The frame's border: thick once bought, thin before.
const BORDER := 3
const THIN_BORDER := 2
## The level badge: a pill tucked under the frame, its number on top and a
## level bar along its bottom. How far it tucks under, its font and the
## number's height; the bar's height, its gap to the pill's bottom, its side
## inset and the gap between segments.
const BADGE_SIZE := Vector2(76, 32)
const BADGE_TUCK := 14.0
const BADGE_FONT := 17
const BADGE_TEXT_HEIGHT := 23.0
const BAR_HEIGHT := 4.0
const BAR_BOTTOM := 5.0
const BAR_INSET := 10.0
const BAR_GAP := 2.0
## The name under the badge, on a dark plate so boughs and vines never cross
## it: its font, the gap above it and the plate's padding.
const NAME_FONT := 17
const NAME_GAP := 4.0
const NAME_PAD := Vector2(8, 1)
const NAME_PLATE := Color(0.015, 0.025, 0.03, 0.78)
## The lock at the bottom-right corner.
const LOCK_RADIUS := 13.0
const LOCK_AT := Vector2(SIZE - 4.0, SIZE - 12.0)
## The ready ▲ (top-left) and the crest (top-right): their radius and where
## their middles sit, poking past the corners like FREE.
const CHIP_RADIUS := 12.0
const READY_AT := Vector2(2.0, 2.0)
const CREST_AT := Vector2(SIZE - 2.0, 2.0)
## The FREE badge at the top-right corner: how far it pokes past the frame.
const FREE_POKE := Vector2(10.0, 10.0)
const LOCK := preload("res://assets/art/ui/lock.svg")
const GREY_SHADER := preload("res://src/ui/hud/grey_icon.gdshader")
const HIDDEN_COLOR := Color("2a2f3a")
const SILVER_COLOR := Color("aeb6c4")
const BOUGHT_COLOR := UiStyle.GOLD_COLOR
const MAXED_COLOR := Color("6fd36f")
const QUESTION_COLOR := Color("6b7280")
const FILL_COLOR := Color("10141b")
const HIDDEN_FILL := Color("0b0e13")
const BADGE_FILL := Color(0.03, 0.04, 0.06, 0.94)
const SEGMENT_OFF := Color(1, 1, 1, 0.13)
const CHIP_FILL := Color(0.04, 0.05, 0.07, 0.95)

## Shared by every greyscale icon (grey_material()).
static var _grey: ShaderMaterial

var data: TreeNodeData
var tree: EvolutionTree
var essences: Essences
## Drawn with an extra white outline.
var selected := false:
	set(value):
		selected = value
		queue_redraw()
## The level's number ("2/5", "MAX"); not shown on a hidden node.
var badge: Label
## At the top-right corner while the next level is free.
var free_badge := FreeBadge.new()
## The gold ▲ at the top-left: the next level can be bought now.
var ready_chip := Control.new()
## The green check at the top-right: every level bought.
var crest := Control.new()

var _icon: TextureRect
var _question: Label
## The pill under the frame and its level bar; the badge's number is over it.
var _pill := Control.new()
## Over the icon, so it is a child of its own.
var _lock := Control.new()
var _hovered := false


func _init(node_data: TreeNodeData, evolution_tree: EvolutionTree, owned: Essences) -> void:
	data = node_data
	tree = evolution_tree
	essences = owned
	size = Vector2(SIZE, SIZE + BADGE_SIZE.y - BADGE_TUCK)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	_icon = TextureRect.new()
	_icon.texture = data.icon
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_SCALE
	_icon.position = Vector2(ICON_INSET, ICON_INSET)
	_icon.size = Vector2.ONE * (SIZE - ICON_INSET * 2.0)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	_question = UiStyle.label("?", 44, QUESTION_COLOR)
	_question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_question.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_question.size = Vector2(SIZE, SIZE)
	_question.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_question)
	var badge_at := Vector2((SIZE - BADGE_SIZE.x) * 0.5, SIZE - BADGE_TUCK)
	_pill.position = badge_at
	_pill.size = BADGE_SIZE
	_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pill.draw.connect(_draw_pill)
	add_child(_pill)
	badge = UiStyle.label("", BADGE_FONT, UiStyle.TITLE_COLOR)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.position = badge_at
	badge.size = Vector2(BADGE_SIZE.x, BADGE_TEXT_HEIGHT)
	badge.add_theme_constant_override(&"outline_size", 4)
	badge.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.8))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(badge)
	_lock.position = LOCK_AT - Vector2.ONE * LOCK_RADIUS
	_lock.size = Vector2.ONE * LOCK_RADIUS * 2.0
	_lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock.draw.connect(_draw_lock)
	add_child(_lock)
	for chip: Control in [ready_chip, crest]:
		chip.position = (READY_AT if chip == ready_chip else CREST_AT) - Vector2.ONE * CHIP_RADIUS
		chip.size = Vector2.ONE * CHIP_RADIUS * 2.0
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(chip)
	ready_chip.draw.connect(_draw_ready)
	crest.draw.connect(_draw_crest)
	free_badge.position = Vector2(SIZE + FREE_POKE.x - FreeBadge.SIZE.x, -FREE_POKE.y)
	add_child(free_badge)
	refresh()


## Whether node `id` shows as a "?": not open and nothing bought yet (a
## level bought through the debug tools still shows).
static func is_hidden(evolution_tree: EvolutionTree, id: StringName) -> bool:
	return evolution_tree.level(id) == 0 and not evolution_tree.is_open(id)


## &"hidden", &"open", &"poor" (open but too dear), &"bought" (more levels
## left) or &"maxed", for node `id`.
static func state_of(evolution_tree: EvolutionTree, owned: Essences, id: StringName) -> StringName:
	if is_hidden(evolution_tree, id):
		return &"hidden"
	if evolution_tree.is_maxed(id):
		return &"maxed"
	if evolution_tree.level(id) > 0:
		return &"bought"
	return &"open" if evolution_tree.can_buy(id, owned) else &"poor"


## The frame's border for a state: silver until bought, gold in progress,
## green when done.
static func state_color(state_name: StringName) -> Color:
	match state_name:
		&"hidden":
			return HIDDEN_COLOR
		&"bought":
			return BOUGHT_COLOR
		&"maxed":
			return MAXED_COLOR
	return SILVER_COLOR


## The frame's border width for a state: thick once bought.
static func border_width(state_name: StringName) -> int:
	return BORDER if state_name in [&"bought", &"maxed"] else THIN_BORDER


## The greyscale look of an icon not bought yet, shared.
static func grey_material() -> ShaderMaterial:
	if _grey == null:
		_grey = ShaderMaterial.new()
		_grey.shader = GREY_SHADER
	return _grey


## The level bar's segments for `count` levels, in the pill's coordinates.
static func segment_rects(count: int) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var width := (BADGE_SIZE.x - BAR_INSET * 2.0 - BAR_GAP * (count - 1)) / count
	var y := BADGE_SIZE.y - BAR_BOTTOM - BAR_HEIGHT
	for i in count:
		out.append(Rect2(BAR_INSET + i * (width + BAR_GAP), y, width, BAR_HEIGHT))
	return out


func state() -> StringName:
	return state_of(tree, essences, data.id)


## Bought, but its next level is closed: the lock shows at the corner.
func locked() -> bool:
	return tree.level(data.id) > 0 and not tree.is_maxed(data.id) and not tree.next_level_open(data.id)


## The next level can be bought now and costs something: the ▲ shows.
func can_upgrade() -> bool:
	return tree.can_buy(data.id, essences) and not tree.is_free(data.id)


## The icon shows in greyscale: open or too dear, nothing bought yet.
func is_grey() -> bool:
	return _icon.material != null


## The name under the badge: "???" while hidden.
func shown_name() -> String:
	return "???" if state() == &"hidden" else data.display_name


## Everything this view draws (frame, badge and name), in its own coordinates;
## the name may be wider than the frame.
func footprint() -> Rect2:
	var plate := _name_plate()
	var width := maxf(SIZE, plate.size.x)
	return Rect2((SIZE - width) * 0.5, 0.0, width, plate.end.y)


## The plate under the name.
func _name_plate() -> Rect2:
	var font := _font()
	var width := font.get_string_size(shown_name(), HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT).x
	var size_with_pad := Vector2(width, font.get_height(NAME_FONT)) + NAME_PAD * 2.0
	return Rect2(Vector2((SIZE - size_with_pad.x) * 0.5, _name_top()), size_with_pad)


## Redraws the frame, icon, badge and chips from the tree.
func refresh() -> void:
	var current := state()
	var hidden := current == &"hidden"
	var lit := current in [&"bought", &"maxed"]
	_icon.visible = not hidden
	_icon.material = null if lit or hidden else grey_material()
	_question.visible = hidden
	badge.visible = not hidden
	_pill.visible = not hidden
	badge.text = "MAX" if current == &"maxed" else "%d/%d" % [tree.level(data.id), data.max_level]
	badge.add_theme_color_override(&"font_color", state_color(current) if lit else UiStyle.TEXT_COLOR)
	_lock.visible = locked()
	free_badge.visible = tree.is_free(data.id)
	ready_chip.visible = can_upgrade()
	crest.visible = current == &"maxed"
	_pill.queue_redraw()
	queue_redraw()


## Picks this node: emits chosen.
func click() -> void:
	chosen.emit(data.id)


## The hover card: the name and what the node gives now.
func tooltip_content() -> Control:
	if state() == &"hidden":
		return TooltipCard.note("???")
	return TooltipCard.note("%s\n%s" % [data.display_name, data.value_text(tree.level(data.id))])


func _gui_input(event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	if press and press.pressed and press.button_index == MOUSE_BUTTON_LEFT:
		Sfx.play(&"click", UiStyle.CLICK_DB)
		click()
		accept_event()


func _set_hovered(on: bool) -> void:
	_hovered = on
	queue_redraw()


func _font() -> Font:
	return get_theme_default_font()


func _name_top() -> float:
	return SIZE - BADGE_TUCK + BADGE_SIZE.y + NAME_GAP


func _draw() -> void:
	var current := state()
	var frame := StyleBoxFlat.new()
	frame.bg_color = HIDDEN_FILL if current == &"hidden" else FILL_COLOR
	frame.set_border_width_all(border_width(current))
	frame.set_corner_radius_all(CORNER)
	frame.border_color = state_color(current)
	if current in [&"bought", &"maxed"]:
		frame.shadow_color = Color(state_color(current), 0.4)
		frame.shadow_size = 16
	else:
		frame.shadow_color = Color(0, 0, 0, 0.55)
		frame.shadow_size = 8
		frame.shadow_offset = Vector2(0, 4)
	draw_style_box(frame, Rect2(0, 0, SIZE, SIZE))
	if selected or _hovered:
		var outline := StyleBoxFlat.new()
		outline.draw_center = false
		outline.border_color = Color.WHITE if selected else Color(1, 1, 1, 0.45)
		outline.set_border_width_all(3 if selected else 2)
		outline.set_corner_radius_all(CORNER + 4)
		draw_style_box(outline, Rect2(-6, -6, SIZE + 12, SIZE + 12))
	var plate := _name_plate()
	var back := StyleBoxFlat.new()
	back.bg_color = NAME_PLATE
	back.set_corner_radius_all(int(plate.size.y * 0.5))
	draw_style_box(back, plate)
	var font := _font()
	var baseline := plate.position + Vector2(NAME_PAD.x, NAME_PAD.y + font.get_ascent(NAME_FONT))
	draw_string(font, baseline, shown_name(), HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT,
		UiStyle.DIM_COLOR if current == &"hidden" else UiStyle.TEXT_COLOR)


## The pill under the frame: bordered in the state's colour once bought, and
## a segment per level, lit up to the level.
func _draw_pill() -> void:
	var current := state()
	var lit := current in [&"bought", &"maxed"]
	var border := state_color(current) if lit else Color(SILVER_COLOR, 0.55)
	_pill.draw_style_box(UiStyle.panel(BADGE_FILL, border, 2, 0.0, 10), Rect2(Vector2.ZERO, BADGE_SIZE))
	var level := tree.level(data.id)
	var segments := segment_rects(data.max_level)
	for i in segments.size():
		_pill.draw_rect(segments[i], state_color(current) if i < level else SEGMENT_OFF)


func _draw_lock() -> void:
	var middle := Vector2.ONE * LOCK_RADIUS
	_lock.draw_circle(middle, LOCK_RADIUS, Color("101114"))
	_lock.draw_arc(middle, LOCK_RADIUS, 0.0, TAU, 28, Color(0.6, 0.62, 0.68), 2.0, true)
	_lock.draw_texture_rect(LOCK, Rect2(middle - Vector2.ONE * 9.0, Vector2.ONE * 18.0), false)


## A dark disc with a gold ring and a gold ▲.
func _draw_ready() -> void:
	var middle := Vector2.ONE * CHIP_RADIUS
	ready_chip.draw_circle(middle, CHIP_RADIUS, CHIP_FILL)
	ready_chip.draw_arc(middle, CHIP_RADIUS - 1.0, 0.0, TAU, 28, UiStyle.GOLD_COLOR, 2.0, true)
	ready_chip.draw_colored_polygon(PackedVector2Array([middle + Vector2(0, -6), middle + Vector2(6, 4), middle + Vector2(-6, 4)]), UiStyle.GOLD_COLOR)


## A green disc with a white check.
func _draw_crest() -> void:
	var middle := Vector2.ONE * CHIP_RADIUS
	crest.draw_circle(middle, CHIP_RADIUS, MAXED_COLOR)
	crest.draw_arc(middle, CHIP_RADIUS - 1.0, 0.0, TAU, 28, MAXED_COLOR.darkened(0.45), 2.0, true)
	crest.draw_polyline(PackedVector2Array([middle + Vector2(-5, 0), middle + Vector2(-1.5, 4), middle + Vector2(5, -4)]), Color.WHITE, 2.5, true)
