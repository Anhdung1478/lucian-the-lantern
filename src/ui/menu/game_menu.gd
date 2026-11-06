class_name GameMenu
extends CanvasLayer
## The ESC menu of a stage: an ornate card (MenuCard) over the blurred game,
## the stage's name under MENU, then Resume, Settings, Leave this stage and
## Exit the game. The last two only emit; under the game root they ask first
## (Leave / Cancel, Yes / No / Cancel), and Cancel comes back to this menu,
## still paused. The ScreenSwitcher passes it the arrow keys and Enter
## (`keys`); nothing is lit each time it opens.

signal resume_requested
signal settings_requested
signal leave_requested
signal exit_requested

const NOT_AVAILABLE := "Not available yet"
const SETTINGS_HINT := "Audio, controls, graphics"
const RESUME_ICON := preload("res://assets/art/ui/menu_resume.svg")
const SETTINGS_ICON := preload("res://assets/art/ui/menu_settings.svg")
const LEAVE_ICON := preload("res://assets/art/ui/menu_leave.svg")
const EXIT_ICON := preload("res://assets/art/ui/menu_exit.svg")

var card := MenuCard.new("MENU")
## Arrow keys and Enter on the entries.
var keys := MenuKeys.new()

var _leave: MenuEntry


func _ready() -> void:
	layer = 40
	visible = false
	_build()


## The line under MENU: the stage's name (Stage sets it).
func set_subtitle(text: String) -> void:
	card.set_subtitle(text)


## Leave this stage is shown disabled, with a hover note, when nothing would
## take the player anywhere (the stage running alone).
func set_leave_enabled(enabled: bool) -> void:
	if enabled:
		_leave.enable()
	else:
		_leave.disable(NOT_AVAILABLE)


func _build() -> void:
	var backdrop := MenuBackdrop.new()
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)
	center.add_child(card)
	_entry("Resume", RESUME_ICON, MenuEntry.Kind.PRIMARY, "", resume_requested.emit)
	_entry("Settings", SETTINGS_ICON, MenuEntry.Kind.NORMAL, SETTINGS_HINT, settings_requested.emit)
	_leave = _entry("Leave this stage", LEAVE_ICON, MenuEntry.Kind.DANGER, "", leave_requested.emit)
	_entry("Exit the game", EXIT_ICON, MenuEntry.Kind.DANGER, "", exit_requested.emit)
	keys.set_buttons(MenuKeys.buttons_in(card.content))
	visibility_changed.connect(keys.clear)


func _entry(label: String, icon: Texture2D, kind: MenuEntry.Kind, hint: String, action: Callable) -> MenuEntry:
	var entry := MenuEntry.new(label, icon, kind, hint)
	entry.pressed.connect(action)
	card.content.add_child(entry)
	return entry
