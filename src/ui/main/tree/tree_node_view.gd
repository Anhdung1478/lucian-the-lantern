class_name TreeNodeView
extends Control
## One Evolution Tree node on its branch page: a 96 px square frame with the
## node's icon, a level badge tucked under it and the node's name below. The
## frame tells the state: hidden (a "?"), open, too dear (red), bought (lit,
## with a glow) or maxed (green). A small lock sits at the bottom-right corner
## while a bought node's next level is closed. A left press picks it.

signal chosen(id: StringName)

const SIZE := 96.0
const ICON_INSET := 6.0
const CORNER := 10
const BORDER := 3
## The level badge: its size, how far it tucks under the frame, its font.
const BADGE_SIZE := Vector2(58, 28)
const BADGE_TUCK := 14.0
const BADGE_FONT := 18
## The name under the badge, on a dark plate so limbs and vines never cross
## it: its font, the gap above it and the plate's padding.
const NAME_FONT := 17
const NAME_GAP := 4.0
const NAME_PAD := Vector2(8, 1)
const NAME_PLATE := Color(0.015, 0.025, 0.03, 0.78)
## The lock at the bottom-right corner.
const LOCK_RADIUS := 13.0
const LOCK_AT := Vector2(SIZE - 4.0, SIZE - 12.0)
const LOCK := preload("res://assets/art/ui/lock.svg")
const HIDDEN_COLOR := Color("2a2f3a")
const POOR_COLOR := Color("ff6a5a")
const BOUGHT_COLOR := Color("ffe9a8")
const MAXED_COLOR := Color("6fd36f")
const QUESTION_COLOR := Color("6b7280")
const FILL_COLOR := Color("10141b")
const HIDDEN_FILL := Color("0b0e13")
const BADGE_FILL := Color(0.03, 0.04, 0.06, 0.94)

var data: TreeNodeData
var tree: EvolutionTree
var essences: Essences
## Drawn with an extra white outline.
var selected := false:
	set(value):
		selected = value
		queue_redraw()
## The level under the frame ("2/5"); not shown on a hidden node.
var badge: Label

var _icon: TextureRect
var _question: Label
var _badge_style: StyleBoxFlat
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
	badge = UiStyle.label("", BADGE_FONT, UiStyle.TITLE_COLOR)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.position = Vector2((SIZE - BADGE_SIZE.x) * 0.5, SIZE - BADGE_TUCK)
	badge.size = BADGE_SIZE
	_badge_style = UiStyle.panel(BADGE_FILL, Color(0.36, 0.4, 0.48), 2, 0.0, 10)
	badge.add_theme_stylebox_override(&"normal", _badge_style)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(badge)
	_lock.position = LOCK_AT - Vector2.ONE * LOCK_RADIUS
	_lock.size = Vector2.ONE * LOCK_RADIUS * 2.0
	_lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock.draw.connect(_draw_lock)
	add_child(_lock)
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


## The frame's border for a state.
static func state_color(state_name: StringName) -> Color:
	match state_name:
		&"hidden":
			return HIDDEN_COLOR
		&"poor":
			return POOR_COLOR
		&"bought":
			return BOUGHT_COLOR
		&"maxed":
			return MAXED_COLOR
	return UiStyle.BORDER_COLOR


func state() -> StringName:
	return state_of(tree, essences, data.id)


## Bought, but its next level is closed: the lock shows at the corner.
func locked() -> bool:
	return tree.level(data.id) > 0 and not tree.is_maxed(data.id) and not tree.next_level_open(data.id)


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


## Redraws the frame, icon and badge from the tree.
func refresh() -> void:
	var current := state()
	var hidden := current == &"hidden"
	_icon.visible = not hidden
	_question.visible = hidden
	badge.visible = not hidden
	badge.text = "%d/%d" % [tree.level(data.id), data.max_level]
	var lit := current in [&"bought", &"maxed"]
	_badge_style.border_color = state_color(current) if lit else Color(0.36, 0.4, 0.48)
	badge.add_theme_color_override(&"font_color", state_color(current) if lit else UiStyle.TEXT_COLOR)
	_lock.visible = locked()
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
	frame.set_border_width_all(BORDER)
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


func _draw_lock() -> void:
	var middle := Vector2.ONE * LOCK_RADIUS
	_lock.draw_circle(middle, LOCK_RADIUS, Color("101114"))
	_lock.draw_arc(middle, LOCK_RADIUS, 0.0, TAU, 28, Color(0.6, 0.62, 0.68), 2.0, true)
	_lock.draw_texture_rect(LOCK, Rect2(middle - Vector2.ONE * 9.0, Vector2.ONE * 18.0), false)
