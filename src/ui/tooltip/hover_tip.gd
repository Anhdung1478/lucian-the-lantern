class_name HoverTip
extends CanvasLayer
## Shows a tooltip card once the mouse has rested on a control for DELAY
## seconds, small movements inside it included. A control opts in with
## tooltip_content() -> Control (null for nothing to show) and may pick a
## placement with tooltip_place() -> Place. A "hover_text" meta gives a small
## note at the cursor. Hidden while the left button is held, so drags never
## show tooltips. A control whose card can change while it is shown (a
## skill's cooldown with ability haste) adds tooltip_version() -> Variant:
## when the value changes, the card is built again in place, with no blink.

enum Place { BESIDE, ABOVE, CURSOR }

const DELAY := 1.0
const GAP := 8.0
const CURSOR_OFFSET := Vector2(16, 20)
const MARGIN := 8.0

var _source: Control
var _hover_time := 0.0
var _card: Control
## The card being replaced: it stays until the new one is placed.
var _old_card: Control
var _place := Place.BESIDE
## The source's tooltip_version() when its card was built.
var _version: Variant


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
	elif _card:
		refresh_card()
	if _card:
		_position_card()


## Opens the card for `source` right away.
func show_for(source: Control) -> void:
	_hide()
	_source = source
	_hover_time = DELAY
	_build()


func is_showing() -> bool:
	return _card != null


## The card on show, or null.
func card() -> Control:
	return _card


## Builds the card again when its source's tooltip_version() changed.
func refresh_card() -> void:
	if _card and is_instance_valid(_source) and _source.has_method(&"tooltip_version") 			and _source.tooltip_version() != _version:
		_rebuild()


## The source's card changed: the new one replaces it once it is placed.
func _rebuild() -> void:
	if _old_card:
		_old_card.queue_free()
	_old_card = _card
	_card = null
	_build()
	if _card == null:
		_hide()


func _build() -> void:
	var source := _source
	_version = source.tooltip_version() if source.has_method(&"tooltip_version") else null
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


func _hide() -> void:
	if _card:
		_card.queue_free()
		_card = null
	if _old_card:
		_old_card.queue_free()
		_old_card = null


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
	if _old_card:
		_old_card.queue_free()
		_old_card = null


static func _find_source(control: Control) -> Control:
	while control:
		if control.has_method(&"tooltip_content") or control.has_meta(&"hover_text"):
			return control
		control = control.get_parent() as Control
	return null
