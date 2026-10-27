class_name ScreenSwitcher
extends Node
## Opens and closes the pause screens: the backpack on P and the menu on ESC.
## The only place that pauses the game. Keys are read in _input, so a focused
## text field can never swallow them.

signal backpack_toggled(open: bool)

@onready var menu: GameMenu = $Menu
@onready var backpack: BackpackScreen = $Backpack


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	menu.resume_requested.connect(set_menu_open.bind(false))


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"open_menu"):
		# ESC closes the backpack first; the menu only opens over the game.
		if backpack.visible:
			set_backpack_open(false)
		else:
			set_menu_open(not menu.visible)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"open_backpack") and not menu.visible:
		set_backpack_open(not backpack.visible)
		get_viewport().set_input_as_handled()


func set_menu_open(open: bool) -> void:
	menu.visible = open
	_update_pause()


func set_backpack_open(open: bool) -> void:
	if open:
		backpack.open()
	else:
		backpack.close()
	_update_pause()
	backpack_toggled.emit(open)


func _update_pause() -> void:
	get_tree().paused = menu.visible or backpack.visible
