class_name TreeNodeView
extends Control
## One Evolution Tree node on its branch page: a lantern of the tree. At rest
## it is three parts: the 96 px tile, one level mark under it (a pip per
## level, none for a one-level node) and the name. The tile carries the state,
## in four steps of light that read in greyscale too:
## - hidden: the darkest glass, a faint lock; where the name goes, the rule
##   that opens it ("Clear Act 1", "Any 2 spells"; nothing when a drawn link
##   says it);
## - too dear: the icon in greyscale, a step down, in a faint silver rim;
## - can buy: the icon in greyscale in a silver rim;
## - lit (bought): the icon in colour under a warm wash of light, with a warm
##   edge; brighter while levels are left, a quieter edge once done.
## One badge at most: FREE in the level mark's place while the next level
## costs nothing, or a lock in a lower corner while it is closed. The page's
## next step wears a gold rim and a soft gold light (`next`); the picked node
## a pale ring 8 px out. Hover and selection ease in and out.
## The look follows three eased values (light_t, known_t, pips_t): refresh()
## sets them at once, or, from the page's purchase and reset (play()), eases
## them from where they are, after a delay. A left press picks the node.

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
## The lock in a lower corner and the hidden tile's lock.
const LOCK_RADIUS := 12.0
const LOCK_RIGHT := Vector2(SIZE - 17.0, SIZE - 17.0)
const LOCK_LEFT := Vector2(17.0, SIZE - 17.0)
## The nodes whose icon's subject sits in its lower right: their lock goes left.
const LOCK_ON_LEFT: Array[StringName] = [&"equip_slots"]
const HIDDEN_LOCK := 28.0
## The hover card starts this far from the tile (12 px on screen, with
## HoverTip's own gap).
const CARD_GAP := 14.0
## The purchase's beats: the light and the pip.
const LIGHT_TIME := 0.18
const PIP_TIME := 0.15
const PIP_DELAY := 0.05
## A node unveiling as it opens.
const UNVEIL_TIME := 0.25
const LOCK := preload("res://assets/art/ui/lock.svg")
const GREY_SHADER := preload("res://src/ui/hud/grey_icon.gdshader")

const HIDDEN_FILL := Color("10151b")
const HIDDEN_RIM := Color("2c3542")
const FILL_COLOR := Color("1b2430")
const SILVER_COLOR := Color("aeb6c4")
## A greyscale icon's brightness: can buy, and too dear.
const OPEN_ICON := Color(0.8, 0.8, 0.82)
const DIM_ICON := Color(0.5, 0.5, 0.53)
## The warm wash over a lit icon (added light), and its warm edge.
const WASH := Color("ffb84a")
const WASH_ALPHA := 0.3
const WARM_EDGE := Color("ffd98a")
const NEXT_COLOR := UiStyle.GOLD_COLOR
const PIP_LIT := Color("ffd98a")
const PIP_OFF := Color(0.6, 0.64, 0.7, 0.6)
## Older looks still read by the info column.
const BOUGHT_COLOR := UiStyle.GOLD_COLOR
const MAXED_COLOR := Color("6fd36f")
const QUESTION_COLOR := Color("6b7280")
## Short rules for the nodes whose rule is a count ("any 2 of ...").
const RULE_TAGS := {
	&"passive": "Any of Q, W, E",
	&"summoner_slot_2": "Any 2 spells",
}
## Word pairs a name never breaks between (Vietnamese compounds).
const KEEP_TOGETHER: Array[String] = ["Năng Lượng", "Bổ Trợ", "Thứ Hai", "Cơ Bản", "Nâng Cấp", "Xạ Thủ", "Ánh Sáng", "Tia Sáng", "Minh Mẫn"]

## Shared by every greyscale icon (grey_material()).
static var _grey: ShaderMaterial
static var _add: CanvasItemMaterial

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
## 0 unlit, 1 lit (bought).
var light_t := 0.0
## 0 hidden, 1 known.
var known_t := 0.0
## The level the pips show (eases to the level).
var pips_t := 0.0
## In the level mark's place while the next level is free.
var free_badge := FreeBadge.new()

## The icon in colour, and in greyscale under it.
var _icon: TextureRect
var _grey_icon: TextureRect
## Over the icons: the warm wash (added light).
var _wash := Control.new()
## Over the wash: the warm edge, the gold rim, the locks.
var _over := Control.new()
var _select_tween: Tween
var _play: Tween
## The state the eased values were last aimed at: (light, known, level).
var _aim := Vector3(-1, -1, -1)


func _init(node_data: TreeNodeData, evolution_tree: EvolutionTree, owned: Essences) -> void:
	data = node_data
	tree = evolution_tree
	essences = owned
	size = Vector2.ONE * SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func() -> void: UiMotion.lit(self, true))
	mouse_exited.connect(func() -> void: UiMotion.lit(self, false))
	_grey_icon = _icon_rect()
	_grey_icon.material = grey_material()
	add_child(_grey_icon)
	_icon = _icon_rect()
	add_child(_icon)
	if _add == null:
		_add = CanvasItemMaterial.new()
		_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_wash.material = _add
	_wash.size = size
	_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wash.draw.connect(_draw_wash)
	add_child(_wash)
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


## `text` with the spaces inside its KEEP_TOGETHER pairs made no-break, so a
## label that wraps it never breaks a compound.
static func glued(text: String) -> String:
	for pair in KEEP_TOGETHER:
		text = text.replace(pair, pair.replace(" ", "\u00a0"))
	return text


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


## Bought, but its next level is closed: the lock shows in a lower corner.
func locked() -> bool:
	return tree.level(data.id) > 0 and not tree.is_maxed(data.id) and not tree.next_level_open(data.id)


## The icon shows in greyscale: open or too dear, nothing bought yet.
func is_grey() -> bool:
	return state() in [&"open", &"poor"]


## Lit: bought (in progress or done).
func is_lit() -> bool:
	return state() in [&"bought", &"maxed"]


## The words under the tile: the name, or a hidden node's rule tag.
func shown_name() -> String:
	return rule_tag(tree, data.id) if state() == &"hidden" else Lang.t(data.display_name)


## The words under the tile in lines: a long name wraps (two lines at most),
## never inside a compound word.
func name_lines() -> PackedStringArray:
	return _lines(shown_name(), _name_size())


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


## Rereads the state from the tree, at once.
func refresh() -> void:
	play(-1.0)


## Rereads the state from the tree and eases the look there, starting after
## `delay` seconds; a negative delay (or UiMotion.off()) sets it at once. A
## look already easing to the same state keeps going; a new state retargets
## from where the look is now.
func play(delay := 0.0) -> void:
	var current := state()
	var aim := Vector3(1.0 if current in [&"bought", &"maxed"] else 0.0, 0.0 if current == &"hidden" else 1.0, tree.level(data.id))
	var tint := DIM_ICON if current == &"poor" else OPEN_ICON
	free_badge.visible = tree.is_free(data.id)
	if delay < 0.0 or UiMotion.off() or not is_inside_tree():
		_kill_play()
		_aim = aim
		_grey_icon.modulate = tint
		_set_look(aim.x, aim.y, aim.z)
		return
	if aim == _aim:
		_grey_icon.modulate = tint
		_redraw()
		return
	_aim = aim
	_kill_play()
	_play = UiMotion.tween(self)
	_play.set_parallel(true)
	var time := UNVEIL_TIME if aim.y != known_t else LIGHT_TIME
	_play.tween_method(func(t: float) -> void: _set_look(t, known_t, pips_t), light_t, aim.x, LIGHT_TIME).set_delay(delay)
	_play.tween_method(func(t: float) -> void: _set_look(light_t, t, pips_t), known_t, aim.y, time).set_delay(delay)
	_play.tween_method(func(t: float) -> void: _set_look(light_t, known_t, t), pips_t, aim.z, PIP_TIME).set_delay(delay + PIP_DELAY)
	_play.tween_property(_grey_icon, ^"modulate", tint, LIGHT_TIME).set_delay(delay)


## True while the look eases.
func is_playing() -> bool:
	return _play != null and _play.is_valid() and _play.is_running()


## Picks this node: emits chosen.
func click() -> void:
	chosen.emit(data.id)


## The hover card: what the node gives now, and what its next level still
## needs; a hidden node says what opens it.
func tooltip_content() -> Control:
	if state() == &"hidden":
		return TooltipCard.note(tree.requirement_text(data.id, 0))
	var text := data.value_text(tree.level(data.id))
	var needs := tree.next_requirement_text(data.id)
	if needs != "":
		text += "\n" + needs
	return TooltipCard.note(text)


## The card measures from the tile (not the name under it), CARD_GAP off.
func tooltip_anchor() -> Rect2:
	var frame := get_global_transform() * Rect2(Vector2.ZERO, Vector2.ONE * SIZE)
	return frame.grow(CARD_GAP - HoverTip.GAP)


## Kept for callers of the old bump: the page plays a purchase now.
func bump() -> void:
	pass


func _gui_input(event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	if press and press.pressed and press.button_index == MOUSE_BUTTON_LEFT:
		Sfx.play(&"click", UiStyle.CLICK_DB)
		click()
		accept_event()


func _icon_rect() -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = data.icon
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.position = Vector2(ICON_INSET, ICON_INSET)
	rect.size = Vector2.ONE * (SIZE - ICON_INSET * 2.0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _set_look(light: float, known: float, pips: float) -> void:
	light_t = light
	known_t = known
	pips_t = pips
	_icon.modulate.a = light
	_icon.visible = light > 0.0
	_grey_icon.modulate.a = known * (1.0 - light)
	_grey_icon.visible = _grey_icon.modulate.a > 0.0
	_redraw()


func _kill_play() -> void:
	if _play and _play.is_valid():
		_play.kill()
	_play = null


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
	_wash.queue_redraw()
	_over.queue_redraw()


func _font() -> Font:
	return get_theme_default_font()


func _name_size() -> int:
	return TAG_FONT if state() == &"hidden" else NAME_FONT


## `text` in one line, or two where they are most even (never inside a
## KEEP_TOGETHER pair), when wider than the page's NAME_MAX.
func _lines(text: String, font_size: int) -> PackedStringArray:
	if text == "":
		return PackedStringArray()
	var font := _font()
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= TreePage.NAME_MAX:
		return PackedStringArray([text])
	var words := glued(text).split(" ")
	var best := PackedStringArray([text])
	var best_width := INF
	for cut in range(1, words.size()):
		var first := " ".join(words.slice(0, cut)).replace("\u00a0", " ")
		var second := " ".join(words.slice(cut)).replace("\u00a0", " ")
		var wider := maxf(font.get_string_size(first, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x,
			font.get_string_size(second, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
		if wider < best_width:
			best_width = wider
			best = PackedStringArray([first, second])
	return best


func _tile() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2.ONE * SIZE)


func _draw() -> void:
	var current := state()
	var tile := _tile()
	if next:
		draw_texture_rect(JourneyMap.glow(), tile.grow(SIZE * 0.55), false, Color(NEXT_COLOR, 0.4))
	var frame := StyleBoxFlat.new()
	frame.set_corner_radius_all(CORNER)
	frame.bg_color = HIDDEN_FILL.lerp(FILL_COLOR, known_t)
	var rim := Color(SILVER_COLOR, 0.75 if current == &"open" else 0.4)
	frame.border_color = HIDDEN_RIM.lerp(rim, known_t)
	frame.set_border_width_all(2)
	draw_style_box(frame, tile)
	# The picked ring, over the hover one, each eased by its own value.
	var hover_a := 0.4 * lit_t * (1.0 - selected_t)
	if selected_t > 0.0 or hover_a > 0.0:
		var ring := StyleBoxFlat.new()
		ring.draw_center = false
		ring.border_color = Color(UiStyle.TITLE_COLOR, maxf(selected_t, hover_a))
		ring.set_border_width_all(int(RING_WIDTH + 0.5) if selected_t >= 0.5 else 2)
		ring.set_corner_radius_all(CORNER + int(RING_OUT))
		draw_style_box(ring, tile.grow(RING_OUT))
	# The level mark: lit pips up to the level, the last one growing in.
	if not free_badge.visible and known_t > 0.0:
		var pips := pip_centers(data.max_level)
		for i in pips.size():
			var fill := clampf(pips_t - i, 0.0, 1.0)
			draw_arc(pips[i], PIP * 0.5 - 0.75, 0.0, TAU, 16, Color(PIP_OFF, PIP_OFF.a * known_t * (1.0 - fill)), 1.5, true)
			if fill > 0.0:
				draw_circle(pips[i], PIP * 0.5 * lerpf(0.6, 1.0, fill), Color(PIP_LIT, fill * known_t))
	# The name, or the rule tag: they cross over as the node opens.
	var color := UiStyle.DIM_COLOR if current == &"poor" else UiStyle.TEXT_COLOR
	_draw_words(Lang.t(data.display_name), NAME_FONT, color, known_t)
	if known_t < 1.0:
		_draw_words(rule_tag(tree, data.id), TAG_FONT, UiStyle.DIM_COLOR, 1.0 - known_t)


func _draw_words(text: String, font_size: int, color: Color, alpha: float) -> void:
	if alpha <= 0.0 or text == "":
		return
	var font := _font()
	var lines := _lines(text, font_size)
	for i in lines.size():
		var width := font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var baseline := Vector2((SIZE - width) * 0.5, NAME_TOP + i * NAME_LINE + font.get_ascent(font_size))
		draw_string_outline(font, baseline, lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, Color(0, 0, 0, 0.75 * alpha))
		draw_string(font, baseline, lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(color, alpha))


## The warm light added over a lit icon, strongest in its middle.
func _draw_wash() -> void:
	if light_t <= 0.0:
		return
	_wash.draw_texture_rect(JourneyMap.glow(), _tile().grow(-2.0), false, Color(WASH, WASH_ALPHA * light_t))


## Over the icon: a lit tile's warm edge (quieter once done), the next step's
## gold rim, and the locks.
func _draw_over() -> void:
	var current := state()
	var tile := _tile()
	var edge := StyleBoxFlat.new()
	edge.draw_center = false
	edge.set_corner_radius_all(CORNER)
	if next:
		edge.border_color = NEXT_COLOR
		edge.set_border_width_all(3)
		_over.draw_style_box(edge, tile)
	elif light_t > 0.0:
		var done := current == &"maxed"
		edge.border_color = Color(WARM_EDGE, (0.32 if done else 0.75) * light_t)
		edge.set_border_width_all(1 if done else 2)
		_over.draw_style_box(edge, tile)
	if known_t < 1.0:
		_over.draw_texture_rect(LOCK, Rect2(tile.get_center() - Vector2.ONE * HIDDEN_LOCK * 0.5, Vector2.ONE * HIDDEN_LOCK), false, Color(1, 1, 1, 0.3 * (1.0 - known_t)))
	if locked():
		var at := LOCK_LEFT if data.id in LOCK_ON_LEFT else LOCK_RIGHT
		_over.draw_circle(at, LOCK_RADIUS, Color(0.05, 0.06, 0.08, 0.95))
		_over.draw_texture_rect(LOCK, Rect2(at - Vector2.ONE * 8.0, Vector2.ONE * 16.0), false, Color(1, 1, 1, 0.9))
