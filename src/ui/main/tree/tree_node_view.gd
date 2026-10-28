class_name TreeNodeView
extends Control
## One Evolution Tree node on the map: a 72 px square frame with the node's
## icon and a level badge under it. The frame tells the state: hidden (a
## "?"), open, too dear (red), bought (lit, with a glow) or maxed (green).
## The TreeMap turns a click into click(), so a drag never selects.

signal chosen(id: StringName)

const SIZE := 72.0
const BADGE_HEIGHT := 22.0
const BADGE_WIDTH := 40.0
const ICON_INSET := 4.0
const HIDDEN_COLOR := Color("2a2f3a")
const POOR_COLOR := Color("ff6a5a")
const BOUGHT_COLOR := Color("ffe9a8")
const MAXED_COLOR := Color("6fd36f")
const QUESTION_COLOR := Color("6b7280")
const FILL_COLOR := Color("10141b")
const HIDDEN_FILL := Color("0b0e13")

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


func _init(node_data: TreeNodeData, evolution_tree: EvolutionTree, owned: Essences) -> void:
	data = node_data
	tree = evolution_tree
	essences = owned
	size = Vector2(SIZE, SIZE + BADGE_HEIGHT)
	# Clicks and drags go on to the TreeMap, which decides which one it was.
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_icon = TextureRect.new()
	_icon.texture = data.icon
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_SCALE
	_icon.position = Vector2(ICON_INSET, ICON_INSET)
	_icon.size = Vector2.ONE * (SIZE - ICON_INSET * 2.0)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	_question = UiStyle.label("?", 32, QUESTION_COLOR)
	_question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_question.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_question.size = Vector2(SIZE, SIZE)
	_question.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_question)
	badge = UiStyle.label("", 15, UiStyle.TITLE_COLOR)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.position = Vector2((SIZE - BADGE_WIDTH) * 0.5, SIZE + 3.0)
	badge.size = Vector2(BADGE_WIDTH, BADGE_HEIGHT - 3.0)
	badge.add_theme_stylebox_override(&"normal", UiStyle.panel(Color(0.03, 0.04, 0.06, 0.9), Color(0.36, 0.4, 0.48), 1, 0.0, 9))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(badge)
	refresh()


## Whether node `id` shows as a "?": not open and nothing bought yet (a
## level bought through the debug tools still shows).
static func is_hidden(evolution_tree: EvolutionTree, id: StringName) -> bool:
	return evolution_tree.level(id) == 0 and not evolution_tree.is_open(id)


## &"hidden", &"open", &"poor" (open but too dear), &"bought" (more levels
## left) or &"maxed".
func state() -> StringName:
	if is_hidden(tree, data.id):
		return &"hidden"
	if tree.is_maxed(data.id):
		return &"maxed"
	if tree.level(data.id) > 0:
		return &"bought"
	return &"open" if tree.can_buy(data.id, essences) else &"poor"


## Redraws the frame, icon and badge from the tree.
func refresh() -> void:
	var hidden := state() == &"hidden"
	_icon.visible = not hidden
	_question.visible = hidden
	badge.visible = not hidden
	badge.text = "%d/%d" % [tree.level(data.id), data.max_level]
	queue_redraw()


## A click on this node (from the TreeMap): emits chosen.
func click() -> void:
	chosen.emit(data.id)


## The hover card: the name and what the node gives now.
func tooltip_content() -> Control:
	if state() == &"hidden":
		return TooltipCard.note("???")
	return TooltipCard.note("%s\n%s" % [data.display_name, data.value_text(tree.level(data.id))])


func _draw() -> void:
	var current := state()
	var frame := StyleBoxFlat.new()
	frame.bg_color = HIDDEN_FILL if current == &"hidden" else FILL_COLOR
	frame.set_border_width_all(3)
	frame.set_corner_radius_all(6)
	match current:
		&"hidden":
			frame.border_color = HIDDEN_COLOR
		&"open":
			frame.border_color = UiStyle.BORDER_COLOR
		&"poor":
			frame.border_color = POOR_COLOR
		&"bought":
			frame.border_color = BOUGHT_COLOR
			frame.shadow_color = Color(BOUGHT_COLOR, 0.45)
			frame.shadow_size = 14
		&"maxed":
			frame.border_color = MAXED_COLOR
	draw_style_box(frame, Rect2(0, 0, SIZE, SIZE))
	if selected:
		var outline := StyleBoxFlat.new()
		outline.draw_center = false
		outline.border_color = Color.WHITE
		outline.set_border_width_all(3)
		outline.set_corner_radius_all(9)
		draw_style_box(outline, Rect2(-6, -6, SIZE + 12, SIZE + 12))
