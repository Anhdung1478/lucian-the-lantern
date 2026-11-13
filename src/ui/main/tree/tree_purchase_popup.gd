class_name TreePurchasePopup
extends Control
## The Evolution Tree's question before buying a level: an ornate card
## (MenuCard) over the tree with a table of the node's level now and after,
## its effect now and after, the price, the essence owned and what is left
## after buying. Buy emits `confirmed` once and closes, and is off while the
## level can't be bought; Cancel or ESC (TreeSection.close_popup) closes it.
## It buys nothing itself and saves nothing. The cost bar's click opens it,
## so the second click of a double-click lands on it and buys nothing.

signal confirmed(id: StringName)
signal closed

## The table: the keys' column and the values' width.
const KEY_WIDTH := 170.0
const VALUE_WIDTH := 300.0
const ROW_FONT := 19
const KEY_FONT := 16
const ICON_SIZE := 22.0
const BUTTON_WIDTH := 240.0
const NOTE := "Only Reset tree gives essence back."
## The essences a level costs, in the table's order.
const KINDS: Array[StringName] = [Essences.BLUE, Essences.ORANGE]

var tree: EvolutionTree
var id: StringName
var essences: Essences
var card: MenuCard
var buy_button: MenuEntry
var cancel_button: MenuEntry
## "LVL 2 → 3 / 5".
var level_label: Label
## "+8 AD → +16 AD".
var effect_label: Label
## "Free" in the Price row, shown when the level costs nothing.
var free_label: Label
## Kind -> its amount in the Price, You have and After purchase rows.
var price_labels := {}
var owned_labels := {}
var after_labels := {}

## The You have and After purchase rows (keys and values), hidden when free.
var _money_rows: Array[Control] = []


func _init(evolution_tree: EvolutionTree = null, node_id := &"", owned: Essences = null) -> void:
	tree = evolution_tree
	id = node_id
	essences = owned


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Clicks outside the card stop here (the second click of a double-click).
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	essences.changed.connect(refresh)
	refresh()


## Rereads the level, the price and the essence owned: the table and Buy
## follow them.
func refresh() -> void:
	var data := tree.node(id)
	var level := tree.level(id)
	level_label.text = Lang.t("LVL %d → %d / %d") % [level, level + 1, data.max_level]
	effect_label.text = "%s → %s" % [data.value_text(level), data.value_text(mini(level + 1, data.max_level))]
	var price := tree.cost(id)
	var needs := {Essences.BLUE: price.x, Essences.ORANGE: price.y}
	var free := price == Vector2i.ZERO
	free_label.visible = free
	for row in _money_rows:
		row.visible = not free
	for kind: StringName in KINDS:
		var owned := essences.amount(kind)
		var shown: bool = needs[kind] > 0
		for labels: Dictionary in [price_labels, owned_labels, after_labels]:
			(labels[kind] as Label).get_parent().visible = shown
		price_labels[kind].text = str(needs[kind])
		owned_labels[kind].text = str(owned)
		after_labels[kind].text = str(owned - needs[kind])
		after_labels[kind].add_theme_color_override(&"font_color",
			UiStyle.ERROR_COLOR if owned < needs[kind] else UiStyle.TITLE_COLOR)
	buy_button.disabled = not tree.can_buy(id, essences)


## Closes and frees it.
func close() -> void:
	if is_queued_for_deletion():
		return
	closed.emit()
	queue_free()


## Once: a second press in the same frame finds it closing.
func _buy() -> void:
	if buy_button.disabled or is_queued_for_deletion():
		return
	confirmed.emit(id)
	close()


func _build() -> void:
	var backdrop := MenuBackdrop.new()
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(center)
	card = MenuCard.new(Lang.t("BUY UPGRADE"), Lang.t(tree.node(id).display_name))
	center.add_child(card)
	var table := GridContainer.new()
	table.columns = 2
	table.add_theme_constant_override(&"h_separation", 16)
	table.add_theme_constant_override(&"v_separation", 10)
	table.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.content.add_child(table)
	level_label = UiStyle.label("", ROW_FONT, UiStyle.TITLE_COLOR)
	_row(table, Lang.t("Level"), level_label)
	effect_label = UiStyle.label("", ROW_FONT, UiStyle.TEXT_COLOR)
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.custom_minimum_size.x = VALUE_WIDTH
	_row(table, Lang.t("Effect"), effect_label)
	var price_row: HBoxContainer = _amounts(table, Lang.t("Price"), price_labels)[1]
	free_label = UiStyle.label(Lang.t("Free"), ROW_FONT, UiStyle.TITLE_COLOR)
	price_row.add_child(free_label)
	price_row.move_child(free_label, 0)
	_money_rows.append_array(_amounts(table, Lang.t("You have"), owned_labels))
	_money_rows.append_array(_amounts(table, Lang.t("After purchase"), after_labels))
	var note := UiStyle.label(Lang.t(NOTE), 16, UiStyle.DIM_COLOR)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.content.add_child(note)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override(&"separation", 16)
	card.content.add_child(buttons)
	buy_button = MenuEntry.new(Lang.t("Buy"), null, MenuEntry.Kind.PRIMARY)
	buy_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	buy_button.custom_minimum_size.x = BUTTON_WIDTH
	buy_button.pressed.connect(_buy)
	buttons.add_child(buy_button)
	cancel_button = MenuEntry.new(Lang.t("Cancel"))
	cancel_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	cancel_button.custom_minimum_size.x = BUTTON_WIDTH * 0.75
	cancel_button.pressed.connect(close)
	buttons.add_child(cancel_button)


## A row of the table: its key (dim) and its value. Returns the key's label.
func _row(table: GridContainer, key: String, value: Control) -> Label:
	var label := UiStyle.label(key, KEY_FONT, UiStyle.DIM_COLOR)
	label.custom_minimum_size.x = KEY_WIDTH
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	table.add_child(label)
	table.add_child(value)
	return label


## A row with an amount and its icon for each kind, the labels kept in
## `labels` by kind. Returns the row's key and its line of amounts.
func _amounts(table: GridContainer, key: String, labels: Dictionary) -> Array[Control]:
	var line := HBoxContainer.new()
	line.add_theme_constant_override(&"separation", 20)
	for kind: StringName in KINDS:
		var item := HBoxContainer.new()
		item.add_theme_constant_override(&"separation", 8)
		line.add_child(item)
		var label := UiStyle.label("", ROW_FONT, UiStyle.TITLE_COLOR)
		item.add_child(label)
		var icon := TextureRect.new()
		icon.texture = CostBar.ICONS[kind]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2.ONE * ICON_SIZE
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item.add_child(icon)
		labels[kind] = label
	return [_row(table, key, line), line]
