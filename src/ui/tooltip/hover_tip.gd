class_name HoverTip
extends CanvasLayer
## Shows a tooltip card once the mouse has rested on a control for DELAY
## seconds, small movements inside it included. A control opts in with
## tooltip_content() -> Control (null for nothing to show) and may pick a
## placement with tooltip_place() -> Place. A "hover_text" meta gives a small
## note at the cursor. Hidden while the left button is held, so drags never
## show tooltips.

enum Place { BESIDE, ABOVE, CURSOR }

const DELAY := 1.0
const GAP := 8.0
const CURSOR_OFFSET := Vector2(16, 20)
const MARGIN := 8.0

var _source: Control
var _hover_time := 0.0
var _card: Control
var _place := Place.BESIDE


func _ready() -> void:
	layer = 100
	process_mode = PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	var source: Control = null
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		source = _find_source(get_viewport().gui_get_hovered_control())
	if source != _source:
		_source = source
		_hover_time = 0.0
		_hide()
	if _source == null:
		return
	_hover_time += delta
	if _card == null and _hover_time >= DELAY:
		show_for(_source)
	if _card:
		_position_card()


## Opens the card for `source` right away.
func show_for(source: Control) -> void:
	_hide()
	_source = source
	_hover_time = DELAY
	if source.has_method(&"tooltip_content"):
		_card = source.tooltip_content()
		_place = source.tooltip_place() if source.has_method(&"tooltip_place") else Place.BESIDE
	else:
		_card = TooltipCard.note(source.get_meta(&"hover_text"))
		_place = Place.CURSOR
	if _card == null:
		return
	# Invisible until its size is known, so it never shows up in the wrong place.
	_card.modulate.a = 0.0
	add_child(_card)
	_card.reset_size()
	_position_card.call_deferred()


func is_showing() -> bool:
	return _card != null


func _hide() -> void:
	if _card:
		_card.queue_free()
		_card = null


func _position_card() -> void:
	if _card == null or not is_instance_valid(_source):
		return
	var size := _card.get_combined_minimum_size()
	var screen := get_viewport().get_visible_rect().grow(-MARGIN)
	var anchor := _source.get_global_rect()
	var at: Vector2
	match _place:
		Place.ABOVE:
			at = Vector2(anchor.get_center().x - size.x * 0.5, anchor.position.y - GAP - size.y)
		Place.BESIDE:
			at = Vector2(anchor.end.x + GAP, anchor.position.y)
			if at.x + size.x > screen.end.x:
				at.x = anchor.position.x - GAP - size.x
		Place.CURSOR:
			at = get_viewport().get_mouse_position() + CURSOR_OFFSET
	_card.position = at.clamp(screen.position, screen.end - size)
	_card.modulate.a = 1.0


static func _find_source(control: Control) -> Control:
	while control:
		if control.has_method(&"tooltip_content") or control.has_meta(&"hover_text"):
			return control
		control = control.get_parent() as Control
	return null
