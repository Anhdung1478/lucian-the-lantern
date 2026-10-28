class_name JourneyTab
extends Button
## One tab of the Journey section. A locked tab is disabled, wears a chain
## and says in its hover text what to clear first.

const SIZE := Vector2(150, 48)
const CHAIN := preload("res://assets/art/ui/chain.svg")
## A locked tab's label starts this far in, clear of the chain (6 to 34).
const CHAIN_ROOM := 40.0

var locked := false
var _selected := false
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
	_restyle()


## Locks or opens the tab. `hint` is the hover text a locked tab shows.
func set_locked(is_locked: bool, hint := "") -> void:
	locked = is_locked
	disabled = is_locked
	_chain.visible = is_locked
	_restyle()
	if is_locked:
		set_meta(&"hover_text", hint)
	else:
		remove_meta(&"hover_text")


## Lights the tab while its page is open.
func set_selected(selected: bool) -> void:
	_selected = selected
	_restyle()


## The button look; a locked tab's label moves right of its chain.
func _restyle() -> void:
	UiStyle.style_button(self, 22, _selected)
	if locked:
		for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
			get_theme_stylebox(state).content_margin_left = CHAIN_ROOM
