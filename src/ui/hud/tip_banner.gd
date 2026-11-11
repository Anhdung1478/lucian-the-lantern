class_name TipBanner
extends Plate
## Act 1's tips (and Endless's milestones) under the stage info, on a plain
## plate with a gold diamond before the text: one at a time, each shown once
## for TIME seconds; later ones wait their turn. The time only runs while
## the game does.

const TIME := 7.0
const PAD := 14.0
const FONT := 20
## The diamond before the text, and the room the text leaves it.
const MARK := 5.0
const MARK_ROOM := 22.0

var label := UiStyle.label("", FONT, UiStyle.TEXT_COLOR)

var _queue: Array[String] = []
var _shown := {}
var _left := 0.0


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


func _process(delta: float) -> void:
	if _left > 0.0:
		_left -= delta
		if _left <= 0.0:
			visible = false
	elif not _queue.is_empty():
		label.text = _queue.pop_front()
		_fit()
		visible = true
		_left = TIME


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
