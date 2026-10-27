class_name ScreenSwitcher
extends Node
## Opens and closes the pause screens: the backpack on P, the merchant's shop
## (the backpack in shop mode, opened by walking to the merchant), the menu on
## ESC and the settings over the menu. The only place that pauses the game.
## Keys are read in _input, so a focused text field can never swallow them.

## The plain backpack opened or closed. The shop never docks the debug table
## right, since the shop panel takes that side.
signal backpack_toggled(open: bool)

@onready var menu: GameMenu = $Menu
@onready var backpack: BackpackScreen = $Backpack
@onready var settings: SettingsScreen = $Settings


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	menu.resume_requested.connect(set_menu_open.bind(false))
	menu.settings_requested.connect(set_settings_open.bind(true))
	settings.back_requested.connect(set_settings_open.bind(false))


func _input(event: InputEvent) -> void:
	# The settings screen reads its own keys (ESC goes back to the menu).
	if settings.visible:
		return
	if event.is_action_pressed(&"open_menu"):
		# ESC closes the backpack or shop first; the menu only opens over the game.
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


## Opens the settings in place of the menu; closing goes back to the menu.
func set_settings_open(open: bool) -> void:
	if open:
		settings.open()
	else:
		settings.close()
	menu.visible = not open
	_update_pause()


func set_backpack_open(open: bool) -> void:
	if open:
		backpack.open()
	else:
		backpack.close()
	_update_pause()
	backpack_toggled.emit(open)


## Opens the merchant's shop beside the backpack. Not over the menu.
func open_shop(shop: Shop) -> void:
	if menu.visible:
		return
	backpack.open_shop(shop)
	_update_pause()
	backpack_toggled.emit(false)


func is_shopping() -> bool:
	return backpack.visible and backpack.is_shopping()


func _update_pause() -> void:
	get_tree().paused = menu.visible or backpack.visible or settings.visible
