class_name LucianController
extends Node
## Turns player input into Lucian commands. Uses _unhandled_input so clicks
## that land on the HUD or the debug table never reach the world.

## Holding move re-issues the order once the cursor has moved this far.
const REISSUE_DISTANCE := 8.0

var _move_held := false
var _last_move_point := Vector2.ZERO

@onready var lucian: Lucian = get_parent()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"move"):
		_move_held = true
		_issue_move()
		get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if not _move_held:
		return
	# Polled so a release eaten by the GUI still ends the hold.
	if not Input.is_action_pressed(&"move"):
		_move_held = false
	elif _cursor().distance_to(_last_move_point) > REISSUE_DISTANCE:
		_issue_move()


func _issue_move() -> void:
	_last_move_point = _cursor()
	lucian.command_move(_last_move_point)


func _cursor() -> Vector2:
	return lucian.get_global_mouse_position()
