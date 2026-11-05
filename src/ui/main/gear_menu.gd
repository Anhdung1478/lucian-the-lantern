class_name GearMenu
extends CanvasLayer
## The gear button's menu: an ornate card (MenuCard) over the blurred main
## screen, the slot and its play time under MENU, then Close, Save, Save as
## copy, Difficulty, Settings, Leave to main menu and Exit the game. Save as
## copy swaps the rows for a slot list, Difficulty for the four levels (the
## change is in memory, like the tree's). Only Save and Save as copy write
## files.

signal settings_requested
signal exit_requested
signal leave_requested
signal saved(ok: bool)
signal copied(slot: int, ok: bool)
signal difficulty_changed(level: int)

const CLOSE_ICON := preload("res://assets/art/ui/menu_close.svg")
const SAVE_ICON := preload("res://assets/art/ui/menu_save.svg")
const COPY_ICON := preload("res://assets/art/ui/menu_copy.svg")
const BACK_ICON := preload("res://assets/art/ui/menu_back.svg")
const DIFFICULTY_ICON := preload("res://assets/art/ui/skull.svg")

## Asked "Overwrite slot N?"; the main screen sets it. Without one the copy just happens.
var confirm: ConfirmPopup
var card := MenuCard.new()

var _menu_page: VBoxContainer
var _slot_page: VBoxContainer
var _slot_list := SlotList.new()
var _save_entry: MenuEntry
var _showing_slots := false
var _difficulty_page: VBoxContainer
var _difficulty_entry: MenuEntry
## The difficulty page's rows, by Difficulty level.
var _level_entries: Array[MenuEntry] = []


func _ready() -> void:
	layer = 40
	visible = false
	_build()


## Opens on the menu page.
func open() -> void:
	_show_menu()
	visible = true


func close() -> void:
	visible = false


## True while the slot list is the page shown.
func is_showing_slots() -> bool:
	return visible and _showing_slots


## The slot list, with "Slot 1 (current)" disabled.
func show_slots() -> void:
	_showing_slots = true
	card.set_title("SAVE AS COPY")
	card.set_subtitle("Pick a slot")
	_menu_page.visible = false
	_slot_page.visible = true
	_slot_list.refresh(SaveGame.instance().slot)
	visible = true


## The four levels; the current one is greyed with "Current".
func show_difficulty() -> void:
	_showing_slots = false
	card.set_title("DIFFICULTY")
	card.set_subtitle("Enemy HP and damage")
	var current := SaveGame.instance().difficulty
	for level in Difficulty.LEVELS:
		var entry := _level_entries[level]
		if level == current:
			entry.disable(Difficulty.describe(level))
			entry.set_hint("Current · %s" % Difficulty.scale_text(level))
		else:
			entry.enable()
			entry.set_meta(&"hover_text", Difficulty.describe(level))
			entry.set_hint(Difficulty.scale_text(level))
	_menu_page.visible = false
	_slot_page.visible = false
	_difficulty_page.visible = true
	visible = true


## True while the difficulty page is the page shown.
func is_showing_difficulty() -> bool:
	return visible and _difficulty_page.visible


## The button with this text on the page shown, or null.
func find_button(text: String) -> Button:
	var page := _menu_page
	if _slot_page.visible:
		page = _slot_page
	elif _difficulty_page.visible:
		page = _difficulty_page
	for button: Button in page.find_children("*", "Button", true, false):
		if button.text == text:
			return button
	return null


func _build() -> void:
	var backdrop := MenuBackdrop.new()
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)
	center.add_child(card)
	_menu_page = _page()
	_entry(_menu_page, "Close", CLOSE_ICON, MenuEntry.Kind.PRIMARY, "", close)
	_save_entry = _entry(_menu_page, "Save", SAVE_ICON, MenuEntry.Kind.NORMAL, "", _save)
	_entry(_menu_page, "Save as copy", COPY_ICON, MenuEntry.Kind.NORMAL, "To another slot", show_slots)
	_difficulty_entry = _entry(_menu_page, "Difficulty", DIFFICULTY_ICON, MenuEntry.Kind.NORMAL, "", show_difficulty)
	_entry(_menu_page, "Settings", GameMenu.SETTINGS_ICON, MenuEntry.Kind.NORMAL, GameMenu.SETTINGS_HINT, settings_requested.emit)
	_entry(_menu_page, "Leave to main menu", GameMenu.LEAVE_ICON, MenuEntry.Kind.DANGER, "Title screen", leave_requested.emit)
	_entry(_menu_page, "Exit the game", GameMenu.EXIT_ICON, MenuEntry.Kind.DANGER, "", exit_requested.emit)
	_slot_page = _page()
	_slot_list.picked.connect(_copy)
	_slot_page.add_child(_slot_list)
	_entry(_slot_page, "Back", BACK_ICON, MenuEntry.Kind.NORMAL, "", _show_menu)
	_difficulty_page = _page()
	for level in Difficulty.LEVELS:
		_level_entries.append(_entry(_difficulty_page, Difficulty.name_of(level), DIFFICULTY_ICON, MenuEntry.Kind.NORMAL, "", _pick_difficulty.bind(level)))
	_entry(_difficulty_page, "Back", BACK_ICON, MenuEntry.Kind.NORMAL, "", _show_menu)
	_show_menu()


func _page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override(&"separation", 12)
	card.content.add_child(page)
	return page


## MENU, with the slot and its play time under it.
func _show_menu() -> void:
	_showing_slots = false
	var save := SaveGame.instance()
	card.set_title("MENU")
	card.set_subtitle("Slot %d · %s" % [save.slot, SaveGame.play_time_text(int(save.play_time))])
	_save_entry.set_hint("Slot %d" % save.slot)
	_difficulty_entry.set_hint(Difficulty.name_of(save.difficulty))
	_menu_page.visible = true
	_slot_page.visible = false
	_difficulty_page.visible = false


func _entry(parent: Control, label: String, icon: Texture2D, kind: MenuEntry.Kind, hint: String, action: Callable) -> MenuEntry:
	var entry := MenuEntry.new(label, icon, kind, hint)
	entry.pressed.connect(action)
	parent.add_child(entry)
	return entry


func _save() -> void:
	close()
	saved.emit(SaveGame.instance().save())


## Back to the menu page, its Difficulty row showing the new level.
func _pick_difficulty(level: int) -> void:
	if SaveGame.instance().set_difficulty(level):
		difficulty_changed.emit(level)
	_show_menu()


func _copy(slot: int, exists: bool) -> void:
	if exists and confirm:
		confirm.ask("Overwrite slot %d?" % slot, _write_copy.bind(slot))
	else:
		_write_copy(slot)


func _write_copy(slot: int) -> void:
	close()
	copied.emit(slot, SaveGame.instance().copy_to(slot))
