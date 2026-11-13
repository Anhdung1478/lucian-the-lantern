class_name HoverTip
extends CanvasLayer
## Shows a tooltip card once the mouse has rested on a control for DELAY
## seconds, small movements inside it included. A control opts in with
## tooltip_content() -> Control (null for nothing to show) and may pick a
## placement with tooltip_place() -> Place. A "hover_text" meta gives a small
## note at the cursor (wrapped at NOTE_MAX_WIDTH; a "hover_place" meta may
## place it like a card). Hidden while the left button is held, so drags never
## show tooltips. A control whose card can change while it is shown (a
## skill's cooldown with ability haste, a buff's time left, a stat's value)
## adds tooltip_version() -> Variant: when the value changes, the card is
## built again in place, with no blink. A control may add tooltip_anchor() ->
## Rect2 (screen coordinates): ABOVE and BESIDE then measure from that rect
## instead of its own, e.g. a HUD cell's card hangs above the whole bar.
## A card fades in with a small rise (FADE_IN, RISE) once placed and fades out
## (FADE_OUT) when it goes; is_showing() turns false at once. While
## UiMotion.off() it shows and goes at once.

## BESIDE: right of the source, else left of it, else above it, else below.
## ABOVE: above the source, else below it. CURSOR: at the mouse.
enum Place { BESIDE, ABOVE, CURSOR }

const DELAY := 1.0
const GAP := 8.0
const CURSOR_OFFSET := Vector2(16, 20)
const MARGIN := 8.0
## A placed card fades in over FADE_IN while rising RISE into place; a card
## that goes fades out over FADE_OUT.
const FADE_IN := 0.1
const RISE := 5.0
const FADE_OUT := 0.08
## The widest a hover_text note gets (340 px on screen); longer notes wrap.
const NOTE_MAX_WIDTH := 408.0

var _source: Control
var _hover_time := 0.0
var _card: Control
## The card being replaced: it stays until the new one is placed.
var _old_card: Control
var _place := Place.BESIDE
## The source's tooltip_version() when its card was built.
var _version: Variant
## How far the shown card has faded in (0 to 1); a rebuilt card keeps it.
var _appear := 1.0
var _appear_tween: Tween
## The card was built from nothing and is not placed yet: it fades in.
var _fresh := false


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
	_build(true)


func is_showing() -> bool:
	return _card != null


## The card on show, or null.
func card() -> Control:
	return _card


## Builds the card again when its source's tooltip_version() changed.
func refresh_card() -> void:
	if _card and is_instance_valid(_source) and _source.has_method(&"tooltip_version") 			and _source.tooltip_version() != _version:
		_rebuild()


## The source's card changed: the new one replaces it once it is placed, with
## no fade.
func _rebuild() -> void:
	if _old_card:
		_old_card.queue_free()
	_old_card = _card
	_card = null
	_build(false)
	if _card == null:
		_hide()


func _build(fresh: bool) -> void:
	var source := _source
	_version = source.tooltip_version() if source.has_method(&"tooltip_version") else null
	if source.has_method(&"tooltip_content"):
		_card = source.tooltip_content()
		_place = source.tooltip_place() if source.has_method(&"tooltip_place") else Place.BESIDE
	else:
		_card = TooltipCard.note(source.get_meta(&"hover_text"))
		_place = source.get_meta(&"hover_place", Place.CURSOR)
	if _card == null:
		return
	# Invisible until its size is known, so it never shows up in the wrong place.
	_card.modulate.a = 0.0
	add_child(_card)
	if not source.has_method(&"tooltip_content"):
		_wrap_note(_card)
	_card.reset_size()
	if fresh:
		_fresh = true
	_position_card.call_deferred()


## A long note wraps at NOTE_MAX_WIDTH.
static func _wrap_note(note: Control) -> void:
	for label: Label in note.find_children("*", "Label", true, false):
		var room := NOTE_MAX_WIDTH - (note.get_combined_minimum_size().x - label.get_combined_minimum_size().x)
		if label.get_combined_minimum_size().x > room:
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.custom_minimum_size.x = room


func _hide() -> void:
	_fresh = false
	if _card:
		_let_go(_card)
		_card = null
	if _old_card:
		_let_go(_old_card)
		_old_card = null


## A card that goes fades out first (at once while UiMotion.off()).
func _let_go(gone: Control) -> void:
	if UiMotion.off() or not gone.is_inside_tree() or gone.modulate.a <= 0.0:
		gone.queue_free()
		return
	gone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fade := UiMotion.tween(gone)
	fade.tween_property(gone, ^"modulate:a", 0.0, FADE_OUT * gone.modulate.a)
	fade.tween_callback(gone.queue_free)


func _position_card() -> void:
	if _card == null or not is_instance_valid(_source):
		return
	var size := _card.get_combined_minimum_size()
	var screen := get_viewport().get_visible_rect().grow(-MARGIN)
	var anchor: Rect2 = _source.tooltip_anchor() if _source.has_method(&"tooltip_anchor") else _source.get_global_rect()
	var at: Vector2
	match _place:
		Place.ABOVE:
			at = _above(anchor, size, screen)
		Place.BESIDE:
			at = Vector2(anchor.end.x + GAP, anchor.position.y)
			if at.x + size.x > screen.end.x:
				at.x = anchor.position.x - GAP - size.x
				if at.x < screen.position.x:
					at = _above(anchor, size, screen)
		Place.CURSOR:
			at = Pointer.on_screen(self) + CURSOR_OFFSET
	if _fresh:
		_fresh = false
		_fade_in()
	_card.position = at.clamp(screen.position, screen.end - size) + Vector2(0.0, RISE * (1.0 - _appear))
	_card.modulate.a = _appear
	if _old_card:
		_old_card.queue_free()
		_old_card = null


## Centred above `anchor`, or below it when there is no room above.
static func _above(anchor: Rect2, size: Vector2, screen: Rect2) -> Vector2:
	var at := Vector2(anchor.get_center().x - size.x * 0.5, anchor.position.y - GAP - size.y)
	if at.y < screen.position.y:
		at.y = anchor.end.y + GAP
	return at


## A new card fades in from 0 (at once while UiMotion.off()).
func _fade_in() -> void:
	if _appear_tween and _appear_tween.is_valid():
		_appear_tween.kill()
	_appear_tween = null
	if UiMotion.off() or not is_inside_tree():
		_appear = 1.0
		return
	_appear = 0.0
	_appear_tween = UiMotion.tween(self)
	_appear_tween.tween_method(_set_appear, 0.0, 1.0, FADE_IN)


func _set_appear(t: float) -> void:
	_appear = t
	_position_card()


static func _find_source(control: Control) -> Control:
	while control:
		if control.has_method(&"tooltip_content") or control.has_meta(&"hover_text"):
			return control
		control = control.get_parent() as Control
	return null
