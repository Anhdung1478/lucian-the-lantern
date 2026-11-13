class_name CostBar
extends Button
## The info panel's one action, at the panel's foot in the same place for
## every node and state. While a level can be bought it reads "Buy" and the
## level's price, once ("Buy 350 [blue] 3 [orange]"); an amount the player is
## short of is red, the bar is off and a faint fill shows how close they are.
## A level that costs nothing reads "Claim for free"; a maxed node "Maxed",
## a closed or hidden level "Locked". A click asks first (buy_asked:
## TreeSection opens a TreePurchasePopup), so a double-click buys one level.
## A new price crossfades in its place (a price is a new fact, not a count).

## The bar was clicked: ask before buying node `id`'s next level.
signal buy_asked(id: StringName)

const SIZE := Vector2(400, 56)
const ICON_SIZE := 28.0
const FONT_SIZE := 22
const INSET := 4.0
const FILL_COLOR := Color(UiStyle.GOLD_COLOR, 0.16)
const LOCKED_COLOR := Color("8a93a3")
const ICONS := {
	Essences.BLUE: preload("res://assets/art/ui/essence_blue.svg"),
	Essences.ORANGE: preload("res://assets/art/ui/essence_orange.svg"),
}

var id: StringName
var tree: EvolutionTree
var essences: Essences
## Maxed, Locked or "Claim for free"; hidden while the price shows.
var status: Label
## "Buy", leading the price.
var verb: Label

var _row: HBoxContainer
var _amounts := {}
## What the row last read, so a new price crossfades.
var _shown := ""
var _fade: Tween


func _init(evolution_tree: EvolutionTree, owned: Essences) -> void:
	tree = evolution_tree
	essences = owned
	custom_minimum_size = SIZE
	size = SIZE
	# Journey's Start: the one filled gold button on the screen.
	UiStyle.style_button(self, FONT_SIZE, true)
	pressed.connect(func() -> void: buy_asked.emit(id))
	_row = HBoxContainer.new()
	_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override(&"separation", UiStyle.GAP_L)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	verb = UiStyle.label(Lang.t("Buy"), FONT_SIZE, UiStyle.TITLE_COLOR)
	verb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(verb)
	for kind: StringName in ICONS:
		var item := HBoxContainer.new()
		item.add_theme_constant_override(&"separation", 6)
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_row.add_child(item)
		var amount := UiStyle.label("", FONT_SIZE)
		amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(amount)
		var icon := TextureRect.new()
		icon.texture = ICONS[kind]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(icon)
		_amounts[kind] = amount
	status = UiStyle.label("", FONT_SIZE)
	status.set_anchors_preset(Control.PRESET_FULL_RECT)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(status)


## Shows the next level of node `node_id`.
func show_node(node_id: StringName) -> void:
	id = node_id
	refresh()


## Rereads the price and the essences.
func refresh() -> void:
	if id == &"":
		return
	var price := tree.cost(id)
	disabled = not tree.can_buy(id, essences)
	var text := ""
	var color := UiStyle.GOLD_COLOR
	if tree.is_maxed(id):
		text = Lang.t("Maxed")
		color = UiStyle.GOOD_COLOR
	elif not tree.next_level_open(id):
		text = Lang.t("Locked")
		color = LOCKED_COLOR
	elif price == Vector2i.ZERO:
		text = Lang.t("Claim for free")
	status.text = text
	status.add_theme_color_override(&"font_color", color)
	status.visible = text != ""
	_row.visible = text == ""
	verb.add_theme_color_override(&"font_color", UiStyle.TITLE_COLOR if not disabled else UiStyle.DISABLED_FONT)
	var needs := {Essences.BLUE: price.x, Essences.ORANGE: price.y}
	var reads := text
	for kind: StringName in _amounts:
		var label: Label = _amounts[kind]
		var need: int = needs[kind]
		label.get_parent().visible = need > 0
		label.text = str(need)
		label.add_theme_color_override(&"font_color", UiStyle.ERROR_COLOR if essences.amount(kind) < need else UiStyle.TEXT_COLOR)
		reads += " %d" % need
	reads = "%s %s" % [id, reads]
	if reads != _shown:
		var first := _shown == ""
		_shown = reads
		if not first:
			_crossfade()
	queue_redraw()


## The amount label of `kind` (the price, "350").
func amount_label(kind: StringName) -> Label:
	return _amounts[kind]


## How much of the price is owned: the smallest share over the kinds needed,
## 1.0 when the price is 0.
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


## The words and price fade in where the old ones were.
func _crossfade() -> void:
	if _fade and _fade.is_valid():
		_fade.kill()
	for part: CanvasItem in [_row, status]:
		part.modulate.a = 1.0
	if UiMotion.off() or not is_inside_tree():
		return
	_fade = UiMotion.tween(self)
	_fade.set_parallel(true)
	for part: CanvasItem in [_row, status]:
		part.modulate.a = 0.2
		_fade.tween_property(part, ^"modulate:a", 1.0, UiMotion.FAST)


func _draw() -> void:
	if id == &"" or not disabled or tree.is_maxed(id) or not tree.next_level_open(id):
		return
	# Short of essence: how close, as a faint fill.
	var inner := Rect2(Vector2.ONE * INSET, size - Vector2.ONE * INSET * 2.0)
	inner.size.x *= clampf(fill(), 0.0, 1.0)
	draw_rect(inner, FILL_COLOR)
