class_name GearMenu
extends CanvasLayer
## The gear button's menu: Close, Save, Save as copy, Settings, Leave to main
## menu and Exit the game. Save as copy swaps the panel for a
## slot list. Only Save and Save as copy write files.

signal settings_requested
signal exit_requested
signal leave_requested
signal saved(ok: bool)
signal copied(slot: int, ok: bool)

const BUTTON_SIZE := Vector2(340, 56)

## Asked "Overwrite slot N?"; the main screen sets it. Without one the copy just happens.
var confirm: ConfirmPopup

var _menu_page: VBoxContainer
var _slot_page: VBoxContainer
var _slot_list := SlotList.new()
var _title: Label
var _showing_slots := false


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
	_title.text = "SAVE AS COPY"
	_menu_page.visible = false
	_slot_page.visible = true
	_slot_list.refresh(SaveGame.instance().slot)
	visible = true


## The button with this text on the page shown, or null.
func find_button(text: String) -> Button:
	for button: Button in (_slot_page if _slot_page.visible else _menu_page).find_children("*", "Button", true, false):
		if button.text == text:
			return button
	return null


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.55)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", UiStyle.panel())
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 14)
	panel.add_child(column)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_color_override(&"font_color", UiStyle.TITLE_COLOR)
	_title.add_theme_font_size_override(&"font_size", 30)
	column.add_child(_title)
	column.add_child(HSeparator.new())
	_menu_page = _page(column)
	_button(_menu_page, "Close", close)
	_button(_menu_page, "Save", _save)
	_button(_menu_page, "Save as copy", show_slots)
	_button(_menu_page, "Settings", settings_requested.emit)
	_button(_menu_page, "Leave to main menu", leave_requested.emit)
	_button(_menu_page, "Exit the game", exit_requested.emit)
	_slot_page = _page(column)
	_slot_list.picked.connect(_copy)
	_slot_page.add_child(_slot_list)
	_button(_slot_page, "Back", _show_menu)
	_show_menu()


func _page(parent: Control) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override(&"separation", 14)
	parent.add_child(page)
	return page


func _show_menu() -> void:
	_showing_slots = false
	_title.text = "MENU"
	_menu_page.visible = true
	_slot_page.visible = false


## A button without an action is shown disabled.
func _button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = BUTTON_SIZE
	UiStyle.style_button(button)
	if action.is_valid():
		button.pressed.connect(action)
	else:
		button.disabled = true
	parent.add_child(button)
	return button


func _save() -> void:
	close()
	saved.emit(SaveGame.instance().save())


func _copy(slot: int, exists: bool) -> void:
	if exists and confirm:
		confirm.ask("Overwrite slot %d?" % slot, _write_copy.bind(slot))
	else:
		_write_copy(slot)


func _write_copy(slot: int) -> void:
	close()
	copied.emit(slot, SaveGame.instance().copy_to(slot))
