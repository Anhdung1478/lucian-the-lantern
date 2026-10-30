class_name SectionBar
extends HBoxContainer
## The bottom bar: Evolution Tree, Skin Shop and Journey. The chosen one
## stays lit.

signal section_chosen(index: int)

const NAMES: Array[String] = ["Evolution Tree", "Skin Shop", "Journey"]
const BUTTON_SIZE := Vector2(280, 60)
## The FREE badge's distance from a button's top-right corner.
const BADGE_MARGIN := Vector2(8, 4)

var selected := -1
var _buttons: Array[Button] = []
## One FREE badge per button, hidden until `set_badge`.
var badges: Array[FreeBadge] = []


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
		var free := FreeBadge.new()
		free.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		free.offset_left = -FreeBadge.SIZE.x - BADGE_MARGIN.x
		free.offset_right = -BADGE_MARGIN.x
		free.offset_top = BADGE_MARGIN.y
		free.offset_bottom = BADGE_MARGIN.y + FreeBadge.SIZE.y
		free.visible = false
		button.add_child(free)
		badges.append(free)


## Lights `index` and dims the others. Does not emit.
func select(index: int) -> void:
	selected = index
	for i in _buttons.size():
		UiStyle.style_button(_buttons[i], 24, i == index)


## Shows or hides button `index`'s FREE badge.
func set_badge(index: int, on: bool) -> void:
	badges[index].visible = on
