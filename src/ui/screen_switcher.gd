class_name ScreenSwitcher
extends Node
## Opens and closes the pause screens: the backpack on P and the menu on ESC.
## The only place that pauses the game. Keys are read in _input, so a focused
## text field can never swallow them.

@onready var menu: GameMenu = $Menu


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	menu.resume_requested.connect(set_menu_open.bind(false))


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"open_menu"):
		set_menu_open(not menu.visible)
		get_viewport().set_input_as_handled()


func set_menu_open(open: bool) -> void:
	menu.visible = open
	_update_pause()


func _update_pause() -> void:
	get_tree().paused = menu.visible
