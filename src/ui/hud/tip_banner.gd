class_name TipBanner
extends Plate
## Act 1's tips (and Endless's milestones) under the stage info, on a plain
## plate with a gold diamond before the text: one at a time, each shown once
## for TIME seconds; later ones wait their turn, and a new one waits while
## `held` says so (the HUD: while a wave's banner is up). The plate comes down
## into place and leaves the same way (UiMotion); the next tip in line
## crossfades into the same plate. The time only runs while the game does.

const TIME := 7.0
const PAD := 14.0
const FONT := 20
## The diamond before the text, and the room the text leaves it.
const MARK := 5.0
const MARK_ROOM := 22.0
## The next tip's crossfade: the old text out, then the new one in.
const SWAP_OUT := 0.08
const SWAP_IN := 0.15

var label := UiStyle.label("", FONT, UiStyle.TEXT_COLOR)
## () -> bool: true while a new tip must wait. Optional.
var held := Callable()

var _queue: Array[String] = []
var _shown := {}
var _left := 0.0
var _swap: Tween


func _init() -> void:
	super(PAD, false)


func _ready() -> void:
	# The plate's own frame, whatever panel the HUD gave it before adding it.
	pad = PAD
	process_mode = PROCESS_MODE_PAUSABLE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var room := StyleBoxEmpty.new()
	room.content_margin_left = MARK_ROOM
	label.add_theme_stylebox_override(&"normal", room)
	add_child(label)
	visible = false


func show_tip(id: StringName, text: String) -> void:
	if _shown.has(id):
		return
	_shown[id] = true
	_queue.append(text)


## A tip is on show (its time is running).
func is_showing() -> bool:
	return _left > 0.0


func _process(delta: float) -> void:
	if _left > 0.0:
		_left -= delta
		if _left > 0.0:
			return
		if _queue.is_empty() or _waits():
			UiMotion.exit(self, Callable(), -UiMotion.DROP)
			return
		_next(true)
	elif not _queue.is_empty() and not _waits():
		_next(false)


func _waits() -> bool:
	return held.is_valid() and held.call()


## Shows the next tip: into the plate on show (`swap`), or on a plate that
## comes down into place.
func _next(swap: bool) -> void:
	var text: String = _queue.pop_front()
	_left = TIME
	if not swap or UiMotion.off() or not visible:
		_set_text(text)
		label.modulate.a = 1.0
		UiMotion.enter(self, -UiMotion.RISE)
		return
	if _swap and _swap.is_valid():
		_swap.kill()
	_swap = UiMotion.tween(label)
	_swap.tween_property(label, ^"modulate:a", 0.0, SWAP_OUT * label.modulate.a)
	_swap.tween_callback(_set_text.bind(text))
	_swap.tween_property(label, ^"modulate:a", 1.0, SWAP_IN)


func _set_text(text: String) -> void:
	label.text = text
	_fit()


## The plate, and the diamond in the room before the text.
func _draw() -> void:
	super()
	draw_colored_polygon(Plate.diamond(Vector2(pad + MARK, size.y * 0.5), MARK), UiStyle.GOLD_COLOR)


## Shrinks to the new text around the same center (the banner grows both
## ways from it).
func _fit() -> void:
	var middle := (offset_left + offset_right) * 0.5
	offset_left = middle
	offset_right = middle
	offset_bottom = offset_top
