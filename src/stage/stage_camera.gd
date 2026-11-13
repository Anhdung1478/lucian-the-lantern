class_name StageCamera
extends Camera2D
## Free-cam with edge panning by default; the toggle_camera action (Y) switches
## to following Lucian. center_camera (Space) jumps back over him, and keeps
## the camera on him while it is held.
## The position is clamped by hand because Camera2D limits only clamp the
## view, which makes panning back from an edge feel sticky.
##
## The mouse wheel zooms, a notch a step: up closer, down wider, between
## ZOOM_MIN and ZOOM_MAX and never wider than the map. The view eases to the
## level asked for. The level is a setting (SETTING), so the next stage opens
## at it; it is saved once the wheel rests. A `zoom` set by hand (the
## screenshot tool, plain_view) stays until the next notch.

enum Mode { FREE, FOLLOW }

## The widest and the closest view; 1.0 is the plain one.
const ZOOM_MIN := 0.7
const ZOOM_MAX := 1.4
const ZOOM_STEP := 0.1
## How fast the view closes on its level: the share of the gap left after a
## second is e^-ZOOM_EASE.
const ZOOM_EASE := 14.0
## Nearer its level than this, the view is there.
const ZOOM_SNAP := 0.002
## The wheel at rest this long saves the level.
const SAVE_DELAY := 0.6
const SETTING := &"camera_zoom"

@export var edge_margin := 20.0
## Edge panning in screen pixels a second, at any view.
@export var pan_speed := 1600.0

var mode := Mode.FREE
## The level the wheel asked for; `zoom` eases to it.
var zoom_level := 1.0
## Where the level is kept; the game's own settings unless set before setup.
var settings: GameSettings

var _target: Node2D
var _bounds: Rect2
var _window_active := true
## The view is on its way to zoom_level.
var _easing := false
## The level changed and is not saved yet; it is in `_save_in` seconds.
var _unsaved := false
var _save_in := 0.0
## The view before plain_view(true), given back after it.
var _before_plain := Vector2.ZERO


func setup(target: Node2D, bounds: Rect2) -> void:
	_target = target
	_bounds = bounds
	if settings == null:
		settings = GameSettings.instance()
	zoom_level = clampf(float(settings.get_value(SETTING)), min_zoom(), ZOOM_MAX)
	zoom = Vector2.ONE * zoom_level
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
		NOTIFICATION_EXIT_TREE:
			_save_level()


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom_by(1)
		get_viewport().set_input_as_handled()
	elif button and button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom_by(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"toggle_camera"):
		mode = Mode.FOLLOW if mode == Mode.FREE else Mode.FREE
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"center_camera"):
		center_on_target()
		get_viewport().set_input_as_handled()


## Jumps back over Lucian once. Free-cam stays free, so edge panning moves
## it away again.
func center_on_target() -> void:
	global_position = _clamped(_target.global_position)


## `steps` notches closer (wider when negative), kept between the widest view
## this map allows and the closest. The new level is a setting at once and is
## saved once the wheel rests.
func zoom_by(steps: int) -> void:
	var level := clampf(snappedf(zoom_level + steps * ZOOM_STEP, 0.01), min_zoom(), ZOOM_MAX)
	_easing = not is_equal_approx(level, zoom.x)
	if is_equal_approx(level, zoom_level):
		return
	zoom_level = level
	settings.set_value(SETTING, level, false)
	_unsaved = true
	_save_in = SAVE_DELAY


## The widest view here: ZOOM_MIN, or closer on a map (or a screen) where
## that would show past the map's bounds.
func min_zoom() -> float:
	if not _bounds.has_area() or not is_inside_tree():
		return ZOOM_MIN
	var view := get_viewport_rect().size
	return clampf(maxf(view.x / _bounds.size.x, view.y / _bounds.size.y), ZOOM_MIN, ZOOM_MAX)


## A cutscene plays at the plain view (1.0), whatever the player's; theirs
## comes back after it.
func plain_view(on: bool) -> void:
	if on:
		_before_plain = zoom
		zoom = Vector2.ONE
	elif _before_plain != Vector2.ZERO:
		zoom = _before_plain
		_before_plain = Vector2.ZERO
		global_position = _clamped(global_position)


func _physics_process(delta: float) -> void:
	if _target == null:
		return
	_ease_zoom(delta)
	if _unsaved:
		_save_in -= delta
		if _save_in <= 0.0:
			_save_level()
	if mode == Mode.FOLLOW or Input.is_action_pressed(&"center_camera"):
		global_position = _clamped(_target.global_position)
	elif _window_active:
		global_position = _clamped(global_position + _edge_direction() * pan_speed / zoom.x * delta)


## A step of the view toward its level; the camera stays inside the map as
## the view grows.
func _ease_zoom(delta: float) -> void:
	if not _easing:
		return
	var next := lerpf(zoom.x, zoom_level, 1.0 - exp(-ZOOM_EASE * delta))
	if absf(next - zoom_level) < ZOOM_SNAP:
		next = zoom_level
		_easing = false
	zoom = Vector2.ONE * next
	global_position = _clamped(global_position)


## Saves a level still waiting to be (the wheel has rested, or the stage is
## closing).
func _save_level() -> void:
	if _unsaved:
		_unsaved = false
		settings.save()


func _edge_direction() -> Vector2:
	var mouse := Pointer.on_screen(self)
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
