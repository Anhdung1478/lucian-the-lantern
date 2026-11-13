class_name GearMenu
extends CanvasLayer
## The gear button's menu: an ornate card (MenuCard) over the blurred main
## screen, the slot and its play time under MENU, then Close, Save, Save as
## copy, Settings, Leave to main menu and Exit the game. Save as copy swaps
## the rows for a slot list. Difficulty is not here: it is picked only on the
## title screen when a new game starts. Only Save and Save as copy write
## files. The main screen passes it the arrow keys and Enter (`keys`).
## It opens and closes with UiMotion's overlay motion; is_open() flips at
## once. Its two pages swap inside the one card (the old fades out, the new
## rises in) while the card eases to the new page's height.

signal settings_requested
signal exit_requested
signal leave_requested
signal saved(ok: bool)
signal copied(slot: int, ok: bool)

const CLOSE_ICON := preload("res://assets/art/ui/menu_close.svg")
const SAVE_ICON := preload("res://assets/art/ui/menu_save.svg")
const COPY_ICON := preload("res://assets/art/ui/menu_copy.svg")
const BACK_ICON := preload("res://assets/art/ui/menu_back.svg")

## Asked "Overwrite slot N?"; the main screen sets it. Without one the copy just happens.
var confirm: ConfirmPopup
var card := MenuCard.new()
## Arrow keys and Enter on the page shown.
var keys := MenuKeys.new()

var _menu_page: VBoxContainer
var _slot_page: VBoxContainer
var _slot_list := SlotList.new()
var _save_entry: MenuEntry
var _showing_slots := false
var _open := false
var _backdrop := MenuBackdrop.new()
var _center := CenterContainer.new()
## Holds the two pages on a plain Control, so they can cross over and the
## card can ease its height (a Container would snap both).
var _pages := Control.new()
var _page_shown: Control
var _height: Tween


func _ready() -> void:
	layer = 40
	visible = false
	_build()


## Opens on the menu page (or goes back to it when open).
func open() -> void:
	_show_menu()
	_appear()


func close() -> void:
	if not _open:
		return
	_open = false
	UiMotion.close_overlay(_backdrop, _center, func() -> void: visible = false)


## True from open() to close(), even while it fades in or out.
func is_open() -> bool:
	return _open


## True while the slot list is the page shown.
func is_showing_slots() -> bool:
	return _open and _showing_slots


## The slot list, with "Slot 1 (current)" disabled.
func show_slots() -> void:
	_showing_slots = true
	_set_title(Lang.t("SAVE AS COPY"), Lang.t("Pick a slot"))
	_slot_list.refresh(SaveGame.instance().slot)
	_show_page(_slot_page)
	keys.set_buttons(MenuKeys.buttons_in(_slot_page))
	_appear()


## The button with this text on the page shown, or null.
func find_button(text: String) -> Button:
	var page := _slot_page if _showing_slots else _menu_page
	for button: Button in page.find_children("*", "Button", true, false):
		if button.text == text:
			return button
	# A slot row is three labels, not text: found by its one-line wording.
	if _showing_slots:
		for i in _slot_list.buttons.size():
			if _slot_list.row_text(i) == text:
				return _slot_list.buttons[i]
	return null


func _build() -> void:
	add_child(_backdrop)
	_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.add_child(_center)
	_center.add_child(card)
	_pages.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pages.resized.connect(_fit_pages)
	card.content.add_child(_pages)
	_menu_page = _page()
	_entry(_menu_page, Lang.t("Close"), CLOSE_ICON, MenuEntry.Kind.PRIMARY, "", close)
	_save_entry = _entry(_menu_page, Lang.t("Save"), SAVE_ICON, MenuEntry.Kind.NORMAL, "", _save)
	_entry(_menu_page, Lang.t("Save as copy"), COPY_ICON, MenuEntry.Kind.NORMAL, Lang.t("To another slot"), show_slots)
	_entry(_menu_page, Lang.t("Settings"), GameMenu.SETTINGS_ICON, MenuEntry.Kind.NORMAL, Lang.t(GameMenu.SETTINGS_HINT), settings_requested.emit)
	# No hint: "Title screen" only repeated the label (review r1 E4).
	_entry(_menu_page, Lang.t("Leave to main menu"), GameMenu.LEAVE_ICON, MenuEntry.Kind.DANGER, "", leave_requested.emit)
	_entry(_menu_page, Lang.t("Exit the game"), GameMenu.EXIT_ICON, MenuEntry.Kind.DANGER, "", exit_requested.emit)
	_slot_page = _page()
	# The title's three-part row, not one centred line.
	_slot_list.parts = true
	_slot_list.picked.connect(_copy)
	_slot_page.add_child(_slot_list)
	_entry(_slot_page, Lang.t("Back"), BACK_ICON, MenuEntry.Kind.NORMAL, "", _show_menu)
	_slot_page.visible = false
	_show_menu()


func _page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override(&"separation", 12)
	_pages.add_child(page)
	return page


## Shows the layer and fades the overlay in, unless it is open already.
func _appear() -> void:
	if _open:
		return
	_open = true
	visible = true
	UiMotion.open_overlay(_backdrop, _center)


## MENU, with the slot and its play time under it.
func _show_menu() -> void:
	_showing_slots = false
	var save := SaveGame.instance()
	_set_title(Lang.t("MENU"), Lang.t("Slot %d · %s") % [save.slot, SaveGame.play_time_text(int(save.play_time))])
	_save_entry.set_hint(Lang.t("Slot %d") % save.slot)
	_show_page(_menu_page)
	keys.set_buttons(MenuKeys.buttons_in(_menu_page))


## The card's title and subtitle; a new title fades in where the old was.
func _set_title(title: String, subtitle: String) -> void:
	var changed := card.title_label.text != title
	card.set_title(title)
	card.set_subtitle(subtitle)
	if changed and _open:
		UiMotion.enter(card.title_label, 0.0, UiMotion.SWAP_IN)


## `page` becomes the one shown: while open the old one fades out, the new
## one rises in and the card eases to its height; closed, it is at once.
func _show_page(page: Control) -> void:
	var old := _page_shown
	_page_shown = page
	var width := 0.0
	for each: Control in [_menu_page, _slot_page]:
		width = maxf(width, each.get_combined_minimum_size().x)
	var goal := page.get_combined_minimum_size().y
	if _height and _height.is_valid():
		_height.kill()
	if not _open or UiMotion.off() or old == page or not _pages.is_inside_tree():
		_pages.custom_minimum_size = Vector2(width, goal)
		for each: Control in [_menu_page, _slot_page]:
			UiMotion.finish(each)
			each.visible = each == page
		_fit_pages()
		return
	_pages.custom_minimum_size.x = width
	_height = UiMotion.tween(_pages)
	_height.tween_property(_pages, ^"custom_minimum_size:y", goal, UiMotion.BASE)
	_fit_pages()
	UiMotion.swap_body(old, page)


## Each page takes the holder's width and its own height.
func _fit_pages() -> void:
	for page: Control in [_menu_page, _slot_page]:
		page.size = Vector2(_pages.size.x, page.get_combined_minimum_size().y)


func _entry(parent: Control, label: String, icon: Texture2D, kind: MenuEntry.Kind, hint: String, action: Callable) -> MenuEntry:
	var entry := MenuEntry.new(label, icon, kind, hint)
	entry.pressed.connect(action)
	parent.add_child(entry)
	return entry


func _save() -> void:
	close()
	saved.emit(SaveGame.instance().save())


func _copy(slot: int, exists: bool) -> void:
	if exists and confirm:
		confirm.ask(Lang.t("Overwrite slot %d?") % slot, _write_copy.bind(slot))
	else:
		_write_copy(slot)


func _write_copy(slot: int) -> void:
	close()
	copied.emit(slot, SaveGame.instance().copy_to(slot))
