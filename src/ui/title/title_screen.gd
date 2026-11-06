class_name TitleScreen
extends Control
## The screen the game opens on: Thresh's lantern, the title, and Start new
## game, Load game, Settings and Exit the game. The two game buttons turn
## the panel into the slot list. A new game in a used slot asks first, then
## the difficulty page picks Easy, Normal, Hard or Extreme and the slot is
## written at once. Nothing is unsaved here, so Exit (and the
## window's X) only ask "Exit the game?": Exit / Cancel, from the game root.
## Behind it all, the TitleBackdrop tells the story: Lucian and Senna facing
## Thresh under the Shadow Isles moon.

signal new_game_started
signal game_loaded
signal exit_requested

const LANTERN := preload("res://assets/art/ui/title_lantern.svg")
const BUTTON_SIZE := Vector2(420, 64)
const BROKEN_LOAD := "Slot %d's save can't be read, so it can't be loaded.
You can only overwrite it with a new game."
const BROKEN_OVERWRITE := "Slot %d's save can't be read. Overwrite it with a new game?"

## The night scene behind everything: Lucian and Senna facing Thresh.
var backdrop := TitleBackdrop.new()
var settings := SettingsScreen.new()
var confirm := ConfirmPopup.new()
var slot_list := SlotList.new()
## The centred column: the lantern, the title and the menu or the slot page.
var column: VBoxContainer
var load_button: Button
var error_label := UiStyle.label("", 20, UiStyle.ERROR_COLOR)
## Under the title, in red: "Could not save" after a game over whose save failed.
var notice_label := UiStyle.label("", 22, UiStyle.ERROR_COLOR)

## The difficulty page's buttons, by Difficulty level.
var difficulty_buttons: Array[Button] = []

var _menu: VBoxContainer
var _slots_page: VBoxContainer
var _slots_title: Label
var _difficulty_page: VBoxContainer
var _loading := false
## The slot the difficulty page starts a new game in.
var _new_slot := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	show_menu()


func show_menu() -> void:
	_slots_page.visible = false
	_difficulty_page.visible = false
	_menu.visible = true
	error_label.text = ""
	load_button.disabled = not SaveGame.instance().any_slot_exists()
	if load_button.disabled:
		load_button.set_meta(&"hover_text", "No saved games yet")
	elif load_button.has_meta(&"hover_text"):
		load_button.remove_meta(&"hover_text")


## The slot list: for a new game (every slot), or to load (used slots only).
func show_slots(loading: bool) -> void:
	_loading = loading
	_slots_title.text = "LOAD GAME" if loading else "START NEW GAME"
	slot_list.refresh(0, not loading)
	_menu.visible = false
	_difficulty_page.visible = false
	_slots_page.visible = true


func is_showing_slots() -> bool:
	return _slots_page.visible


## The new game's last step: its difficulty, for slot `slot`.
func show_difficulty(slot: int) -> void:
	_new_slot = slot
	error_label.text = ""
	_menu.visible = false
	_slots_page.visible = false
	_difficulty_page.visible = true


func is_showing_difficulty() -> bool:
	return _difficulty_page.visible


func find_button(text: String) -> Button:
	for button: Button in find_children("*", "Button", true, false):
		if button.text == text and button.is_visible_in_tree():
			return button
	return null


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"open_menu") or settings.visible or confirm.is_open():
		return
	if is_showing_difficulty():
		show_slots(false)
		get_viewport().set_input_as_handled()
	elif is_showing_slots():
		show_menu()
		get_viewport().set_input_as_handled()


## A broken slot (SaveGame.slot_broken) is never loaded: the player is told
## and offered only to overwrite it with a new game.
func _on_picked(slot: int, used: bool) -> void:
	var broken := used and SaveGame.instance().slot_broken(slot)
	if _loading and broken:
		confirm.confirm(BROKEN_LOAD % slot, "New game", show_difficulty.bind(slot))
	elif _loading:
		if SaveGame.instance().load_slot(slot):
			game_loaded.emit()
		else:
			error_label.text = "Could not read slot %d" % slot
	elif broken:
		confirm.ask(BROKEN_OVERWRITE % slot, show_difficulty.bind(slot))
	elif used:
		confirm.ask("Overwrite slot %d? Its progress will be lost." % slot, show_difficulty.bind(slot))
	else:
		show_difficulty(slot)


func _start_new(level: int) -> void:
	if SaveGame.instance().start_new(_new_slot, level):
		new_game_started.emit()
	else:
		error_label.text = "Could not write slot %d" % _new_slot


func _build() -> void:
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	column = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override(&"separation", 18)
	center.add_child(column)
	var lantern := TextureRect.new()
	lantern.texture = LANTERN
	lantern.custom_minimum_size = Vector2(200, 200)
	lantern.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lantern.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(lantern)
	var title := UiStyle.label("LUCIAN", 84, UiStyle.GOLD_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var subtitle := UiStyle.label("THE LANTERN", 34, Color("8fe3b0"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(notice_label)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override(&"separation", 14)
	column.add_child(_menu)
	_button(_menu, "Start new game", show_slots.bind(false))
	load_button = _button(_menu, "Load game", show_slots.bind(true))
	_button(_menu, "Settings", _open_settings)
	_button(_menu, "Exit game", exit_requested.emit)
	_slots_page = VBoxContainer.new()
	_slots_page.add_theme_constant_override(&"separation", 14)
	column.add_child(_slots_page)
	_slots_title = UiStyle.label("", 28, UiStyle.TITLE_COLOR)
	_slots_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slots_page.add_child(_slots_title)
	slot_list.picked.connect(_on_picked)
	_slots_page.add_child(slot_list)
	_slots_page.add_child(error_label)
	_button(_slots_page, "Back", show_menu)
	_build_difficulty_page()
	settings.setup(GameSettings.instance())
	settings.back_requested.connect(func() -> void: settings.close())
	add_child(settings)
	add_child(confirm)
	add_child(HoverTip.new())


## CHOOSE DIFFICULTY: a button per level ("Hard  ×1.2", the full
## effect on hover), Normal in gold, then Back to the slots.
func _build_difficulty_page() -> void:
	_difficulty_page = VBoxContainer.new()
	_difficulty_page.add_theme_constant_override(&"separation", 14)
	column.add_child(_difficulty_page)
	var heading := UiStyle.label("CHOOSE DIFFICULTY", 28, UiStyle.TITLE_COLOR)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_difficulty_page.add_child(heading)
	var note := UiStyle.label("Enemy HP and damage. You can change it later from the gear menu.", 18, UiStyle.DIM_COLOR)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = BUTTON_SIZE.x
	_difficulty_page.add_child(note)
	for level in Difficulty.LEVELS:
		var button := _button(_difficulty_page, "%s   %s" % [Difficulty.name_of(level), Difficulty.scale_text(level)], _start_new.bind(level))
		button.set_meta(&"hover_text", Difficulty.describe(level))
		if level == Difficulty.NORMAL:
			button.add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR)
		difficulty_buttons.append(button)
	_button(_difficulty_page, "Back", show_slots.bind(false))
	_difficulty_page.visible = false


func _open_settings() -> void:
	settings.open()


func _button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = BUTTON_SIZE
	UiStyle.style_button(button, 26)
	button.pressed.connect(action)
	parent.add_child(button)
	return button
