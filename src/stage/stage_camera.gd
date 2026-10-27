class_name StageCamera
extends Camera2D
## Free-cam with edge panning by default; the toggle_camera action (Y) switches
## to following Lucian. The position is clamped by hand because Camera2D limits
## only clamp the view, which makes panning back from an edge feel sticky.

enum Mode { FREE, FOLLOW }

@export var edge_margin := 20.0
@export var pan_speed := 1600.0

var mode := Mode.FREE
var _target: Node2D
var _bounds: Rect2
var _window_active := true


func setup(target: Node2D, bounds: Rect2) -> void:
	_target = target
	_bounds = bounds
	global_position = _clamped(target.global_position)
	reset_smoothing()


func _ready() -> void:
	process_callback = CAMERA2D_PROCESS_PHYSICS


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_WM_MOUSE_ENTER:
			_window_active = true
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_MOUSE_EXIT:
			_window_active = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_camera"):
		mode = Mode.FOLLOW if mode == Mode.FREE else Mode.FREE
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if _target == null:
		return
	if mode == Mode.FOLLOW:
		global_position = _clamped(_target.global_position)
	elif _window_active:
		global_position = _clamped(global_position + _edge_direction() * pan_speed * delta)


func _edge_direction() -> Vector2:
	var mouse := get_viewport().get_mouse_position()
	var view := get_viewport().get_visible_rect().size
	var direction := Vector2.ZERO
	if mouse.x <= edge_margin:
		direction.x = -1.0
	elif mouse.x >= view.x - edge_margin:
		direction.x = 1.0
	if mouse.y <= edge_margin:
		direction.y = -1.0
	elif mouse.y >= view.y - edge_margin:
		direction.y = 1.0
	return direction.normalized()


func _clamped(point: Vector2) -> Vector2:
	var half := get_viewport_rect().size * 0.5 / zoom
	var low := _bounds.position + half
	var high := _bounds.end - half
	return Vector2(
		clampf(point.x, low.x, high.x) if low.x <= high.x else _bounds.get_center().x,
		clampf(point.y, low.y, high.y) if low.y <= high.y else _bounds.get_center().y
	)
