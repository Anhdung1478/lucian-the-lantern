class_name CostBar
extends Button
## The buy button of the node info panel. It shows the essence owned against
## the next level's cost for each kind needed ("120 / 350", red when short)
## over a fill of how much of it is there; when the level can be bought the
## verb leads ("Buy  9000 / 200"). A click asks first (buy_asked:
## TreeSection opens a TreePurchasePopup), so a double-click buys one level.
## A maxed node reads Maxed, a hidden one Locked, a cost of 0 Free. The
## amounts count and the fill eases when the essences change.

## The bar was clicked: ask before buying node `id`'s next level.
signal buy_asked(id: StringName)

const SIZE := Vector2(400, 56)
const ICON_SIZE := 30.0
const FONT_SIZE := 22
const INSET := 4.0
const FILL_COLOR := Color(UiStyle.GOLD_COLOR, 0.22)
const MAXED_FILL := Color(TreeNodeView.MAXED_COLOR, 0.22)
const LOCKED_COLOR := Color("8a93a3")
const ICONS := {
	Essences.BLUE: preload("res://assets/art/ui/essence_blue.svg"),
	Essences.ORANGE: preload("res://assets/art/ui/essence_orange.svg"),
}

var id: StringName
var tree: EvolutionTree
var essences: Essences
## Maxed, Locked or Free; hidden while the amounts show.
var status: Label
## "Buy", leading the amounts while the level can be bought.
var verb: Label

var _row: HBoxContainer
var _verb_gap := Control.new()
var _amounts := {}
## The fill drawn now (eases to fill()).
var _fill_shown := -1.0
var _fill_tween: Tween
## The node the fill was last drawn for (a new node snaps it).
var _fill_id: StringName


func _init(evolution_tree: EvolutionTree, owned: Essences) -> void:
	tree = evolution_tree
	essences = owned
	custom_minimum_size = SIZE
	UiStyle.style_button(self, FONT_SIZE)
	pressed.connect(func() -> void: buy_asked.emit(id))
	_row = HBoxContainer.new()
	_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override(&"separation", 0)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	verb = UiStyle.label(Lang.t("Buy"), FONT_SIZE, UiStyle.TITLE_COLOR)
	verb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(verb)
	_verb_gap.custom_minimum_size.x = UiStyle.GAP_L
	_verb_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(_verb_gap)
	var items := HBoxContainer.new()
	items.add_theme_constant_override(&"separation", 28)
	items.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(items)
	for kind: StringName in ICONS:
		var item := HBoxContainer.new()
		item.add_theme_constant_override(&"separation", 8)
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		items.add_child(item)
		var icon := TextureRect.new()
		icon.texture = ICONS[kind]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(icon)
		var amount := CountLabel.new()
		amount.add_theme_font_size_override(&"font_size", FONT_SIZE)
		amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(amount)
		_amounts[kind] = amount
	status = UiStyle.label("", FONT_SIZE + 2)
	status.set_anchors_preset(Control.PRESET_FULL_RECT)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(status)


## Shows the cost of node `node_id`.
func show_node(node_id: StringName) -> void:
	id = node_id
	refresh()


## Rereads the cost and the essences.
func refresh() -> void:
	if id == &"":
		return
	var price := tree.cost(id)
	disabled = not tree.can_buy(id, essences)
	var text := ""
	var color := UiStyle.GOLD_COLOR
	if tree.is_maxed(id):
		text = Lang.t("Maxed")
		color = TreeNodeView.MAXED_COLOR
	elif not tree.next_level_open(id):
		text = Lang.t("Locked")
		color = LOCKED_COLOR
	elif price == Vector2i.ZERO:
		text = Lang.t("Free")
	status.text = text
	status.add_theme_color_override(&"font_color", color)
	status.visible = text != ""
	_row.visible = text == ""
	# Short of essence the red amount is the message; otherwise the verb leads.
	verb.visible = not disabled
	_verb_gap.visible = not disabled
	var needs := {Essences.BLUE: price.x, Essences.ORANGE: price.y}
	var new_node := _fill_id != id
	for kind: StringName in _amounts:
		var label: CountLabel = _amounts[kind]
		var owned := essences.amount(kind)
		var need: int = needs[kind]
		label.get_parent().visible = need > 0
		label.formatter = func(v: int) -> String: return "%d / %d" % [v, need]
		label.set_value(owned, new_node)
		label.add_theme_color_override(&"font_color", UiStyle.ERROR_COLOR if owned < need else UiStyle.TEXT_COLOR)
	_ease_fill(new_node)
	queue_redraw()


## The fill eases to the share owned over UiMotion.BASE (a new node snaps).
func _ease_fill(snap: bool) -> void:
	_fill_id = id
	var target := fill()
	if _fill_tween and _fill_tween.is_valid():
		_fill_tween.kill()
	if snap or _fill_shown < 0.0 or UiMotion.off() or not is_inside_tree():
		_fill_shown = target
		return
	_fill_tween = UiMotion.tween(self)
	_fill_tween.tween_method(_set_fill, _fill_shown, target, UiMotion.BASE)


func _set_fill(share: float) -> void:
	_fill_shown = share
	queue_redraw()


## The amount label of `kind` ("120 / 350").
func amount_label(kind: StringName) -> Label:
	return _amounts[kind]


## How much of the cost is owned: the smallest share over the kinds needed,
## 1.0 when the cost is 0.
func fill() -> float:
	var price := tree.cost(id)
	var share := 1.0
	if price.x > 0:
		share = minf(share, float(essences.amount(Essences.BLUE)) / price.x)
	if price.y > 0:
		share = minf(share, float(essences.amount(Essences.ORANGE)) / price.y)
	return share


## Buys the next level at once (TreeSection, once the question is answered);
## false when it can't. Everything redraws from the tree's and the essences'
## changed signals.
func buy() -> bool:
	if not tree.buy(id, essences):
		return false
	Sfx.play(&"coin")
	return true


func _draw() -> void:
	if id == &"":
		return
	var color := FILL_COLOR
	if tree.is_maxed(id):
		color = MAXED_FILL
	elif not tree.next_level_open(id):
		color = Color(LOCKED_COLOR, 0.12)
	var inner := Rect2(Vector2.ONE * INSET, size - Vector2.ONE * INSET * 2.0)
	inner.size.x *= clampf(_fill_shown, 0.0, 1.0)
	draw_rect(inner, color)
