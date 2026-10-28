class_name EndlessPage
extends VBoxContainer
## The Endless tab: the rules, a map choice (kept here only, not saved yet),
## the best wave and a Start button for a later phase.

const RULES := "Waves never end. A mini boss comes every 5 waves and an act boss every 10. Every 10 waves you pick a modifier."

var map_buttons: Array[Button] = []
var best_label: Label
var start_button: Button
var _selected := 0


func _init() -> void:
	add_theme_constant_override(&"separation", 18)
	add_child(UiStyle.label("ENDLESS", 34, UiStyle.TITLE_COLOR))
	var rules := UiStyle.label(RULES, 22, UiStyle.TEXT_COLOR)
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.custom_minimum_size.x = 900.0
	add_child(rules)
	add_child(UiStyle.label("Map", 24, UiStyle.DIM_COLOR))
	var grid := HFlowContainer.new()
	grid.add_theme_constant_override(&"h_separation", 12)
	grid.add_theme_constant_override(&"v_separation", 12)
	grid.custom_minimum_size.x = 900.0
	add_child(grid)
	var group := ButtonGroup.new()
	for i in Journey.ENDLESS_MAPS.size():
		var button := Button.new()
		button.text = Journey.ENDLESS_MAPS[i]
		button.toggle_mode = true
		button.button_group = group
		button.custom_minimum_size = Vector2(190, 48)
		button.button_pressed = i == 0
		button.pressed.connect(_choose.bind(i))
		grid.add_child(button)
		map_buttons.append(button)
	_style_maps()
	best_label = UiStyle.label("", 26, UiStyle.GOLD_COLOR)
	add_child(best_label)
	start_button = Button.new()
	start_button.text = "Start"
	start_button.custom_minimum_size = Vector2(320, 64)
	start_button.disabled = true
	start_button.set_meta(&"hover_text", "Endless comes in a later phase")
	UiStyle.style_button(start_button, 28)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add_child(start_button)


## Index in Journey.ENDLESS_MAPS of the chosen map (0 is Random).
func map_index() -> int:
	return _selected


## Shows the best wave of this save.
func refresh(best: int) -> void:
	best_label.text = "Best wave: %d" % best


func _choose(index: int) -> void:
	_selected = index
	_style_maps()


func _style_maps() -> void:
	for i in map_buttons.size():
		UiStyle.style_button(map_buttons[i], 20, i == _selected)
