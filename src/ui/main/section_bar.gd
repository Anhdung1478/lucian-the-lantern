class_name SectionBar
extends HBoxContainer
## The bottom bar: Evolution Tree, Skin Shop and Journey. The chosen one
## stays lit.

signal section_chosen(index: int)

const NAMES: Array[String] = ["Evolution Tree", "Skin Shop", "Journey"]
const BUTTON_SIZE := Vector2(280, 60)

var selected := -1
var _buttons: Array[Button] = []


func _init() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override(&"separation", 24)
	for i in NAMES.size():
		var button := Button.new()
		button.text = NAMES[i]
		button.custom_minimum_size = BUTTON_SIZE
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.pressed.connect(section_chosen.emit.bind(i))
		add_child(button)
		_buttons.append(button)
		UiStyle.style_button(button, 24)


## Lights `index` and dims the others. Does not emit.
func select(index: int) -> void:
	selected = index
	for i in _buttons.size():
		UiStyle.style_button(_buttons[i], 24, i == index)
