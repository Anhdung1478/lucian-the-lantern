class_name JourneyTab
extends Button
## One tab of the Journey section. A locked tab is disabled, wears a chain
## and says in its hover text what to clear first.

const SIZE := Vector2(150, 48)
const CHAIN := preload("res://assets/art/ui/chain.svg")

var locked := false
var _chain: TextureRect


func _init(title: String) -> void:
	text = title
	custom_minimum_size = SIZE
	_chain = TextureRect.new()
	_chain.texture = CHAIN
	_chain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_chain.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_chain.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chain.offset_left = 6.0
	_chain.offset_right = -(SIZE.x - 34.0)
	_chain.offset_top = 8.0
	_chain.offset_bottom = -8.0
	_chain.modulate = Color(1, 1, 1, 0.85)
	_chain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chain.visible = false
	add_child(_chain)
	UiStyle.style_button(self, 22)


## Locks or opens the tab. `hint` is the hover text a locked tab shows.
func set_locked(is_locked: bool, hint := "") -> void:
	locked = is_locked
	disabled = is_locked
	_chain.visible = is_locked
	if is_locked:
		set_meta(&"hover_text", hint)
	else:
		remove_meta(&"hover_text")


## Lights the tab while its page is open.
func set_selected(selected: bool) -> void:
	UiStyle.style_button(self, 22, selected)
