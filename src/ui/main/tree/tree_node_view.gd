class_name TreeNodeView
extends Control
## One Evolution Tree node on its branch page: a lantern of the tree. At rest
## it is three parts: the 96 px tile, one level mark under it (a pip per
## level, none for a one-level node) and the name. The tile carries the state:
## - hidden: dark glass with a small lock; where the name goes, the rule that
##   opens it ("Clear Act 1", "Any 2 spells"; nothing when a drawn link says it);
## - open: the icon in greyscale on blue-grey glass in a silver rim, dimmed
##   (rim and icon) while the next level is too dear;
## - lit (bought): the icon in colour on warm glass, a warm edge over the
##   icon's own edge so the tile is lit whatever the icon; brighter while
##   levels are left, calm once done (all pips filled).
## One badge at most: FREE in the level mark's place while the next level
## costs nothing, or a lock in the tile's corner while it is closed. The
## page's next step wears a gold rim and a soft gold light (`next`); the
## picked node a pale ring 8 px out. Hover and selection ease in and out.
## A left press picks it.

signal chosen(id: StringName)

const SIZE := 96.0
const ICON_INSET := 6.0
const CORNER := 10
## The level mark: a pip per level, under the tile.
const PIP := 8.0
const PIP_STEP := 14.0
const PIP_TOP := 10.0
## The name's (or the rule tag's) top, under the tile, the same on every node
## of a row; fonts.
const NAME_TOP := SIZE + 30.0
const NAME_FONT := 17
const TAG_FONT := 15
const NAME_LINE := 24.0
## The FREE pill, in the level mark's place.
const FREE_TOP := SIZE + 4.0
## The picked (and hovered) ring: how far out of the tile and how wide.
const RING_OUT := 8.0
const RING_WIDTH := 2.5
## The lock in the tile's corner and the hidden tile's lock.
const LOCK_RADIUS := 12.0
const LOCK_AT := Vector2(SIZE - 17.0, SIZE - 17.0)
const HIDDEN_LOCK := 30.0
## The hover card starts this far from the tile (12 px on screen, with
## HoverTip's own gap).
const CARD_GAP := 14.0
const LOCK := preload("res://assets/art/ui/lock.svg")
const GREY_SHADER := preload("res://src/ui/hud/grey_icon.gdshader")

const HIDDEN_FILL := Color("1a222c")
const HIDDEN_RIM := Color("3d4857")
const FILL_COLOR := Color("232e3b")
const SILVER_COLOR := Color("aeb6c4")
## Warm glass: its middle and its edge; the warm edge over the icon.
const GLASS_MIDDLE := Color("c08a34")
const GLASS_EDGE := Color("4d3818")
const WARM_EDGE := Color("ffd98a")
const NEXT_COLOR := UiStyle.GOLD_COLOR
const PIP_LIT := Color("ffd98a")
const PIP_OFF := Color(0.6, 0.64, 0.7, 0.6)
## A too-dear icon's tint.
const DIM_ICON := Color(0.7, 0.7, 0.72)
## Older looks still read by the info column.
const BOUGHT_COLOR := UiStyle.GOLD_COLOR
const MAXED_COLOR := Color("6fd36f")
const QUESTION_COLOR := Color("6b7280")
## Short rules for the nodes whose rule is a count ("any 2 of ...").
const RULE_TAGS := {
	&"passive": "Any of Q, W, E",
	&"summoner_slot_2": "Any 2 spells",
}

## Shared by every greyscale icon (grey_material()).
static var _grey: ShaderMaterial

var data: TreeNodeData
var tree: EvolutionTree
var essences: Essences
## Drawn with the picked ring (it eases in and out).
var selected := false:
	set(value):
		if selected == value:
			return
		selected = value
		_ease_selected()
## The page's next step: the gold rim and light.
var next := false:
	set(value):
		if next == value:
			return
		next = value
		_redraw()
## 0 at rest, 1 hovered (UiMotion.lit).
var lit_t := 0.0
## How much of the picked ring shows (eases to `selected`).
var selected_t := 0.0
## In the level mark's place while the next level is free.
var free_badge := FreeBadge.new()

var _icon: TextureRect
## Over the icon: the warm edge, the gold rim, the locks.
var _over := Control.new()
var _select_tween: Tween


func _init(node_data: TreeNodeData, evolution_tree: EvolutionTree, owned: Essences) -> void:
	data = node_data
	tree = evolution_tree
	essences = owned
	size = Vector2.ONE * SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func() -> void: UiMotion.lit(self, true))
	mouse_exited.connect(func() -> void: UiMotion.lit(self, false))
	_icon = TextureRect.new()
	_icon.texture = data.icon
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_SCALE
	_icon.position = Vector2(ICON_INSET, ICON_INSET)
	_icon.size = Vector2.ONE * (SIZE - ICON_INSET * 2.0)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	_over.size = size
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over.draw.connect(_draw_over)
	add_child(_over)
	free_badge.position = Vector2((SIZE - FreeBadge.SIZE.x) * 0.5, FREE_TOP)
	add_child(free_badge)
	refresh()


## Whether node `id` shows as hidden: not open and nothing bought yet (a
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


## The info column's frame colour for a state (its portrait; until it is rebuilt).
static func state_color(state_name: StringName) -> Color:
	match state_name:
		&"hidden":
			return HIDDEN_RIM
		&"bought":
			return BOUGHT_COLOR
		&"maxed":
			return MAXED_COLOR
	return SILVER_COLOR


static func border_width(state_name: StringName) -> int:
	return 3 if state_name in [&"bought", &"maxed"] else 2


## The greyscale look of an icon not bought yet, shared.
static func grey_material() -> ShaderMaterial:
	if _grey == null:
		_grey = ShaderMaterial.new()
		_grey.shader = GREY_SHADER
	return _grey


## The short rule a hidden node waits for, for its page: the act to clear, or
## a counted rule; "" when a drawn link (or R's ring) says it, or when it is
## open.
static func rule_tag(evolution_tree: EvolutionTree, id: StringName) -> String:
	var node_data := evolution_tree.node(id)
	var parts: PackedStringArray = []
	var act := maxi(node_data.requires_act, node_data.act_needed(0))
	if evolution_tree.acts_cleared < act:
		parts.append(Lang.t("Clear Act %d") % act)
	if node_data.requires_count > 0:
		var met := 0
		for required in node_data.requires:
			met += int(evolution_tree.level(required) > 0)
		if met < node_data.requires_count:
			parts.append(Lang.t(RULE_TAGS.get(id, "")))
	return " · ".join(parts)


## The level mark's pips for `count` levels, in the view's coordinates (none
## for a one-level node).
static func pip_centers(count: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	if count < 2:
		return out
	var left := SIZE * 0.5 - (count - 1) * PIP_STEP * 0.5
	for i in count:
		out.append(Vector2(left + i * PIP_STEP, SIZE + PIP_TOP + PIP * 0.5))
	return out


func state() -> StringName:
	return state_of(tree, essences, data.id)


## Bought, but its next level is closed: the lock shows in the corner.
func locked() -> bool:
	return tree.level(data.id) > 0 and not tree.is_maxed(data.id) and not tree.next_level_open(data.id)


## The icon shows in greyscale: open or too dear, nothing bought yet.
func is_grey() -> bool:
	return _icon.material != null


## Lit: bought (in progress or done).
func is_lit() -> bool:
	return state() in [&"bought", &"maxed"]


## The words under the tile: the name, or a hidden node's rule tag.
func shown_name() -> String:
	return rule_tag(tree, data.id) if state() == &"hidden" else Lang.t(data.display_name)


## The words under the tile in lines: a long name wraps (two lines at most).
func name_lines() -> PackedStringArray:
	var text := shown_name()
	if text == "":
		return PackedStringArray()
	var font := _font()
	var font_size := _name_size()
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= TreePage.NAME_MAX:
		return PackedStringArray([text])
	# Break where the two lines are most even.
	var words := text.split(" ")
	var best := PackedStringArray([text])
	var best_width := INF
	for cut in range(1, words.size()):
		var first := " ".join(words.slice(0, cut))
		var second := " ".join(words.slice(cut))
		var wider := maxf(font.get_string_size(first, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x,
			font.get_string_size(second, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
		if wider < best_width:
			best_width = wider
			best = PackedStringArray([first, second])
	return best


## Everything this view draws at rest (tile, level mark and name), in its
## own coordinates; the name may be wider than the tile.
func footprint() -> Rect2:
	var font := _font()
	var lines := name_lines()
	var width := SIZE
	for line in lines:
		width = maxf(width, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, _name_size()).x)
	var bottom := SIZE + PIP_TOP + PIP
	if free_badge.visible:
		bottom = FREE_TOP + FreeBadge.SIZE.y
	if not lines.is_empty():
		bottom = NAME_TOP + NAME_LINE * lines.size()
	return Rect2((SIZE - width) * 0.5, 0.0, width, bottom)


## Rereads the state from the tree.
func refresh() -> void:
	var current := state()
	var hidden := current == &"hidden"
	var lit := current in [&"bought", &"maxed"]
	_icon.visible = not hidden
	_icon.material = null if lit or hidden else grey_material()
	_icon.modulate = DIM_ICON if current == &"poor" else Color.WHITE
	free_badge.visible = tree.is_free(data.id)
	_redraw()


## Picks this node: emits chosen.
func click() -> void:
	chosen.emit(data.id)


## The hover card: what the node gives now, and what its next level still
## needs; a hidden node says what opens it.
func tooltip_content() -> Control:
	var needs := tree.next_requirement_text(data.id)
	if state() == &"hidden":
		return TooltipCard.note(tree.requirement_text(data.id, 0))
	var text := data.value_text(tree.level(data.id))
	if needs != "":
		text += "\n" + needs
	return TooltipCard.note(text)


## The card measures from the tile (not the name under it), CARD_GAP off.
func tooltip_anchor() -> Rect2:
	var frame := get_global_transform() * Rect2(Vector2.ZERO, Vector2.ONE * SIZE)
	return frame.grow(CARD_GAP - HoverTip.GAP)


## A level was bought (the purchase's light is the page's; nothing here yet).
func bump() -> void:
	pass


func _gui_input(event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	if press and press.pressed and press.button_index == MOUSE_BUTTON_LEFT:
		Sfx.play(&"click", UiStyle.CLICK_DB)
		click()
		accept_event()


func _ease_selected() -> void:
	if _select_tween and _select_tween.is_valid():
		_select_tween.kill()
	var target := 1.0 if selected else 0.0
	if UiMotion.off() or not is_inside_tree():
		_set_selected_t(target)
		return
	_select_tween = UiMotion.tween(self)
	_select_tween.tween_method(_set_selected_t, selected_t, target, UiMotion.FAST)


func _set_selected_t(t: float) -> void:
	selected_t = t
	queue_redraw()


func _redraw() -> void:
	queue_redraw()
	_over.queue_redraw()


func _font() -> Font:
	return get_theme_default_font()


func _name_size() -> int:
	return TAG_FONT if state() == &"hidden" else NAME_FONT


func _tile() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2.ONE * SIZE)


func _draw() -> void:
	var current := state()
	var tile := _tile()
	if next:
		draw_texture_rect(JourneyMap.glow(), tile.grow(SIZE * 0.55), false, Color(NEXT_COLOR, 0.4))
	var frame := StyleBoxFlat.new()
	frame.set_corner_radius_all(CORNER)
	match current:
		&"hidden":
			frame.bg_color = HIDDEN_FILL
			frame.border_color = HIDDEN_RIM
			frame.set_border_width_all(2)
		&"open", &"poor":
			frame.bg_color = FILL_COLOR
			frame.border_color = Color(SILVER_COLOR, 0.8 if current == &"open" else 0.5)
			frame.set_border_width_all(2)
		_:
			frame.bg_color = GLASS_EDGE
	draw_style_box(frame, tile)
	if current in [&"bought", &"maxed"]:
		draw_texture_rect(JourneyMap.glow(), tile.grow(-2.0), false, Color(GLASS_MIDDLE, 0.9))
	# The picked ring, over the hover one, each eased by its own value.
	var hover_a := 0.4 * lit_t * (1.0 - selected_t)
	if selected_t > 0.0 or hover_a > 0.0:
		var ring := StyleBoxFlat.new()
		ring.draw_center = false
		ring.border_color = Color(UiStyle.TITLE_COLOR, maxf(selected_t, hover_a))
		ring.set_border_width_all(int(RING_WIDTH + 0.5) if selected_t >= 0.5 else 2)
		ring.set_corner_radius_all(CORNER + int(RING_OUT))
		draw_style_box(ring, tile.grow(RING_OUT))
	# The level mark.
	if not free_badge.visible and current != &"hidden":
		var level := tree.level(data.id)
		var pips := pip_centers(data.max_level)
		for i in pips.size():
			if i < level:
				draw_circle(pips[i], PIP * 0.5, PIP_LIT)
			else:
				draw_arc(pips[i], PIP * 0.5 - 0.75, 0.0, TAU, 16, PIP_OFF, 1.5, true)
	# The name, or the rule tag.
	var lines := name_lines()
	var font := _font()
	var font_size := _name_size()
	var color := UiStyle.DIM_COLOR if current in [&"hidden", &"poor"] else UiStyle.TEXT_COLOR
	for i in lines.size():
		var width := font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var baseline := Vector2((SIZE - width) * 0.5, NAME_TOP + i * NAME_LINE + font.get_ascent(font_size))
		draw_string_outline(font, baseline, lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, Color(0, 0, 0, 0.75))
		draw_string(font, baseline, lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


## Over the icon: a lit tile's warm edge, the next step's gold rim, and the
## locks.
func _draw_over() -> void:
	var current := state()
	var tile := _tile()
	var edge := StyleBoxFlat.new()
	edge.draw_center = false
	edge.set_corner_radius_all(CORNER)
	var has_edge := true
	if next:
		edge.border_color = NEXT_COLOR
		edge.set_border_width_all(3)
	elif current == &"bought":
		edge.border_color = Color(WARM_EDGE, 0.6)
		edge.set_border_width_all(2)
	elif current == &"maxed":
		edge.border_color = Color(WARM_EDGE, 0.42)
		edge.set_border_width_all(2)
	else:
		has_edge = false
	if has_edge:
		_over.draw_style_box(edge, tile)
	if current == &"hidden":
		_over.draw_texture_rect(LOCK, Rect2(tile.get_center() - Vector2.ONE * HIDDEN_LOCK * 0.5, Vector2.ONE * HIDDEN_LOCK), false, Color(1, 1, 1, 0.45))
	elif locked():
		_over.draw_circle(LOCK_AT, LOCK_RADIUS, Color(0.05, 0.06, 0.08, 0.95))
		_over.draw_texture_rect(LOCK, Rect2(LOCK_AT - Vector2.ONE * 8.0, Vector2.ONE * 16.0), false, Color(1, 1, 1, 0.9))
