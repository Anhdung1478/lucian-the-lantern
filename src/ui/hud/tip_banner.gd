class_name TipBanner
extends PanelContainer
## Act 1's tips under the stage info: one at a time, each shown once for
## TIME seconds; later ones wait their turn. The time only runs while the
## game does.

const TIME := 7.0

var label := UiStyle.label("", 20, UiStyle.TEXT_COLOR)

var _queue: Array[String] = []
var _shown := {}
var _left := 0.0


func _ready() -> void:
	process_mode = PROCESS_MODE_PAUSABLE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
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


## Shrinks to the new text around the same center (the banner grows both
## ways from it).
func _fit() -> void:
	var middle := (offset_left + offset_right) * 0.5
	offset_left = middle
	offset_right = middle
	offset_bottom = offset_top
