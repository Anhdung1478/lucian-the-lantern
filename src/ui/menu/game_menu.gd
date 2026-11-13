class_name GameMenu
extends CanvasLayer
## The ESC menu of a stage: an ornate card (MenuCard) over the blurred game,
## the stage's name under MENU, then Resume, Settings, Leave this stage and
## Exit the game. The last two only emit; under the game root they ask first
## (Leave / Cancel, Yes / No / Cancel), and Cancel comes back to this menu,
## still paused. The ScreenSwitcher passes it the arrow keys and Enter
## (`keys`); nothing is lit each time it opens. open() and close() flip
## is_open() at once; the card and the dim fade (UiMotion overlay), so `visible`
## trails by a moment while it closes.

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

var card := MenuCard.new(Lang.t("MENU"))
## Arrow keys and Enter on the entries.
var keys := MenuKeys.new()

var _leave: MenuEntry
var _backdrop: MenuBackdrop
var _center: CenterContainer
var _is_open := false


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
		_leave.disable(Lang.t(NOT_AVAILABLE))


## True from open() to close(), whatever the look is doing.
func is_open() -> bool:
	return _is_open


## Shows the menu: the dim fades in, the card rises in.
func open() -> void:
	if _is_open:
		return
	_is_open = true
	visible = true
	UiMotion.open_overlay(_backdrop, _center)


## Hides the menu: the card and the dim fade out, then the layer is hidden.
func close() -> void:
	if not _is_open:
		return
	_is_open = false
	keys.clear()
	UiMotion.close_overlay(_backdrop, _center, func() -> void: visible = false)


func _build() -> void:
	_backdrop = MenuBackdrop.new()
	add_child(_backdrop)
	_center = CenterContainer.new()
	_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.add_child(_center)
	_center.add_child(card)
	_entry(Lang.t("Resume"), RESUME_ICON, MenuEntry.Kind.PRIMARY, "", resume_requested.emit)
	_entry(Lang.t("Settings"), SETTINGS_ICON, MenuEntry.Kind.NORMAL, Lang.t(SETTINGS_HINT), settings_requested.emit)
	_leave = _entry(Lang.t("Leave this stage"), LEAVE_ICON, MenuEntry.Kind.DANGER, "", leave_requested.emit)
	_entry(Lang.t("Exit the game"), EXIT_ICON, MenuEntry.Kind.DANGER, "", exit_requested.emit)
	keys.set_buttons(MenuKeys.buttons_in(card.content))
	visibility_changed.connect(keys.clear)


func _entry(label: String, icon: Texture2D, kind: MenuEntry.Kind, hint: String, action: Callable) -> MenuEntry:
	var entry := MenuEntry.new(label, icon, kind, hint)
	entry.pressed.connect(action)
	card.content.add_child(entry)
	return entry
