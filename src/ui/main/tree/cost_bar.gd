class_name CostBar
extends Button
## The buy button of the node info panel. It shows the essence owned against
## the next level's cost for each kind needed ("120 / 350", red when short)
## over a fill of how much of it is there, and buys on a click when it can.
## A maxed node reads MAXED, a hidden one LOCKED, a cost of 0 Free.

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
## MAXED, LOCKED or Free; hidden while the amounts show.
var status: Label

var _row: HBoxContainer
var _amounts := {}


func _init(evolution_tree: EvolutionTree, owned: Essences) -> void:
	tree = evolution_tree
	essences = owned
	custom_minimum_size = SIZE
	UiStyle.style_button(self, FONT_SIZE)
	pressed.connect(buy)
	_row = HBoxContainer.new()
	_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override(&"separation", 28)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	for kind: StringName in ICONS:
		var item := HBoxContainer.new()
		item.add_theme_constant_override(&"separation", 8)
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_row.add_child(item)
		var icon := TextureRect.new()
		icon.texture = ICONS[kind]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(icon)
		var amount := UiStyle.label("", FONT_SIZE)
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
		text = "MAXED"
		color = TreeNodeView.MAXED_COLOR
	elif not tree.next_level_open(id):
		text = "LOCKED"
		color = LOCKED_COLOR
	elif price == Vector2i.ZERO:
		text = "Free"
	status.text = text
	status.add_theme_color_override(&"font_color", color)
	status.visible = text != ""
	_row.visible = text == ""
	var needs := {Essences.BLUE: price.x, Essences.ORANGE: price.y}
	for kind: StringName in _amounts:
		var label: Label = _amounts[kind]
		var owned := essences.amount(kind)
		label.get_parent().visible = needs[kind] > 0
		label.text = "%d / %d" % [owned, needs[kind]]
		label.add_theme_color_override(&"font_color", UiStyle.ERROR_COLOR if owned < needs[kind] else UiStyle.TEXT_COLOR)
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


## Buys the next level; false when it can't. Everything redraws from the
## tree's and the essences' changed signals.
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
	inner.size.x *= fill()
	draw_rect(inner, color)
