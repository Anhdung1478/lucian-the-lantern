class_name TitleScreen
extends Control
## The screen the game opens on: Thresh's lantern, the title, and Start new
## game, Load game, Settings and Exit the game; top right, the languages
## (LanguagePicker). The two game buttons turn
## the panel into the slot list. A new game in a used slot asks first, then
## the difficulty page picks Easy, Normal, Hard or Extreme and the slot is
## written at once (if it can't be, a red notice says so and the player stays
## on that page). Nothing is unsaved here, so Exit (and the
## window's X) only ask "Exit the game?": Exit / Cancel, from the game root.
## The arrow keys and Enter work each page as the mouse does (MenuKeys).
## The lantern, the name and the subtitle never move: the page under them
## (menu, slots, difficulty) is a fixed slot as tall as the tallest page, and
## a page change swaps only that slot's content (a short fade and rise).
## Behind it all, the TitleBackdrop tells the story: Lucian and Senna facing
## Thresh under the Shadow Isles moon.

signal new_game_started
signal game_loaded
signal exit_requested

const LANTERN := preload("res://assets/art/ui/title_lantern.svg")
const BUTTON_SIZE := Vector2(420, 64)
## The lantern's top edge on the 1920x1080 canvas (57 px on screen), on every page.
const COLUMN_TOP := 68.0
## The space between "THE LANTERN" and the page under it (48 px on screen).
const PAGE_GAP := 58.0
## Where the difficulty tip opens: right of the buttons, this far from them (12 px).
const TIP_GAP := 14.0
## The difficulty note's width (420 px on screen) and the tip's (340).
const NOTE_WIDTH := 504.0
const TIP_WIDTH := 408.0
## The intro: the first beat after the screen fade, and the rise.
const INTRO_START := 0.1
const INTRO_RISE := 12.0
## The language picker's gap from the screen's corner.
const LANGUAGE_MARGIN := 24
const COULD_NOT_START := "Could not write slot %d. The game can't start until it can save."
const BROKEN_LOAD := "Slot %d's save can't be read, so it can't be loaded.
You can only overwrite it with a new game."
const BROKEN_OVERWRITE := "Slot %d's save can't be read. Overwrite it with a new game?"

## The night scene behind everything: Lucian and Senna facing Thresh.
var backdrop := TitleBackdrop.new()
var settings := SettingsScreen.new()
var confirm := ConfirmPopup.new()
var slot_list := SlotList.new()
## Top right: the languages, each named in itself.
var language_picker := LanguagePicker.new()
## The centred column: the lantern, the title and the menu or the slot page.
var column: VBoxContainer
var load_button: Button
var error_label := UiStyle.label("", 20, UiStyle.ERROR_COLOR)
## Under the title, in red: "Could not save" after a game over whose save failed.
var notice_label := UiStyle.label("", 22, UiStyle.ERROR_COLOR)

## The difficulty page's buttons, by Difficulty level.
var difficulty_buttons: Array[Button] = []
## Arrow keys and Enter on the page shown.
var keys := MenuKeys.new()

var _menu: VBoxContainer
var _slots_page: VBoxContainer
var _slots_title: Label
var _difficulty_page: VBoxContainer
## The fixed slot under the title, and the page in it.
var _slot: Control
var _page: Control
var _loading := false
## The slot the difficulty page starts a new game in.
var _new_slot := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	_fit_slot()
	_go(_menu, false)
	_prepare_menu()
	_intro()


func show_menu() -> void:
	_go(_menu)
	_prepare_menu()


func _prepare_menu() -> void:
	error_label.text = ""
	load_button.disabled = not SaveGame.instance().any_slot_exists()
	if load_button.disabled:
		load_button.set_meta(&"hover_text", Lang.t("No saved games yet"))
	elif load_button.has_meta(&"hover_text"):
		load_button.remove_meta(&"hover_text")
	keys.set_buttons(MenuKeys.buttons_in(_menu))


## The slot list: for a new game (every slot), or to load (used slots only).
## It clears an old error, such as a new game that could not be written.
func show_slots(loading: bool) -> void:
	_loading = loading
	error_label.text = ""
	notice_label.text = ""
	_slots_title.text = Lang.t("LOAD GAME") if loading else Lang.t("START NEW GAME")
	slot_list.refresh(0, not loading)
	_go(_slots_page)
	keys.set_buttons(MenuKeys.buttons_in(_slots_page))


func is_showing_slots() -> bool:
	return _page == _slots_page


## The new game's last step: its difficulty, for slot `slot`.
func show_difficulty(slot: int) -> void:
	_new_slot = slot
	error_label.text = ""
	_go(_difficulty_page)
	keys.set_buttons(MenuKeys.buttons_in(_difficulty_page))


func is_showing_difficulty() -> bool:
	return _page == _difficulty_page


## Shows `page` in the slot: the one before fades out and the new one rises in
## (`animate` false: at once, the first page). Going back moves the same way.
func _go(page: Control, animate := true) -> void:
	var old := _page
	_page = page
	for other: Control in [_menu, _slots_page, _difficulty_page]:
		if other != page and (other != old or not animate):
			other.visible = false
	_place_pages()
	if animate and old != page:
		UiMotion.swap_body(old, page)
	else:
		page.visible = true


func find_button(text: String) -> Button:
	for button: Button in find_children("*", "Button", true, false):
		if button.text == text and button.is_visible_in_tree():
			return button
	return null


## The arrow keys and Enter work the page shown; ESC goes back a page.
## Settings and the pop-up read their own keys.
func _input(event: InputEvent) -> void:
	if settings.visible or confirm.is_open():
		return
	# Enter may swap this screen out (a game loaded), so the viewport is kept.
	var viewport := get_viewport()
	if keys.handle(event):
		viewport.set_input_as_handled()
		return
	if not event.is_action_pressed(&"open_menu"):
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
		confirm.confirm(Lang.t(BROKEN_LOAD) % slot, Lang.t("New game"), show_difficulty.bind(slot))
	elif _loading:
		if SaveGame.instance().load_slot(slot):
			game_loaded.emit()
		else:
			error_label.text = Lang.t("Could not read slot %d") % slot
	elif broken:
		confirm.ask(Lang.t(BROKEN_OVERWRITE) % slot, show_difficulty.bind(slot))
	elif used:
		confirm.ask(Lang.t("Overwrite slot %d? Its progress will be lost.") % slot, show_difficulty.bind(slot))
	else:
		show_difficulty(slot)


## Writes the new game. If the slot can't be written the game doesn't start:
## the player stays on the difficulty page with a red notice and the error
## sound, as the main screen does for a stage.
func _start_new(level: int) -> void:
	if SaveGame.instance().start_new(_new_slot, level):
		new_game_started.emit()
	else:
		notice_label.text = Lang.t(COULD_NOT_START) % _new_slot
		Sfx.play(&"error")


func _build() -> void:
	add_child(backdrop)
	column = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 18)
	add_child(column)
	# Centred across, its top pinned: the lantern is 57 px down on screen.
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.offset_top = COLUMN_TOP
	var lantern := TextureRect.new()
	lantern.texture = LANTERN
	lantern.custom_minimum_size = Vector2(200, 200)
	lantern.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lantern.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var title := UiStyle.label("LUCIAN", 84, UiStyle.GOLD_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subtitle := UiStyle.label("THE LANTERN", 34, Color("8fe3b0"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for part: Control in [lantern, title, subtitle]:
		_hold(part)
	# The red notice sits in the gap under the title; it never changes the layout.
	var gap := Control.new()
	gap.custom_minimum_size.y = PAGE_GAP - 36.0
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notice_label.anchor_left = 0.0
	notice_label.anchor_right = 1.0
	notice_label.anchor_top = 0.5
	notice_label.anchor_bottom = 0.5
	notice_label.offset_left = -200.0
	notice_label.offset_right = 200.0
	notice_label.offset_top = -20.0
	notice_label.offset_bottom = 20.0
	gap.add_child(notice_label)
	column.add_child(gap)
	_slot = Control.new()
	_slot.resized.connect(_place_pages)
	column.add_child(_slot)
	_menu = _page_box()
	_menu.add_theme_constant_override(&"separation", 14)
	_button(_menu, Lang.t("Start new game"), show_slots.bind(false), true)
	load_button = _button(_menu, Lang.t("Load game"), show_slots.bind(true), true)
	_button(_menu, Lang.t("Settings"), _open_settings, true)
	_button(_menu, Lang.t("Exit game"), exit_requested.emit, true)
	_slots_page = _page_box()
	_slots_page.add_theme_constant_override(&"separation", 14)
	_slots_title = UiStyle.label("", UiStyle.FONT_LEAD, UiStyle.TITLE_COLOR)
	_slots_page.add_child(_heading(_slots_title))
	slot_list.parts = true
	slot_list.picked.connect(_on_picked)
	_slots_page.add_child(slot_list)
	_slots_page.add_child(error_label)
	_button(_slots_page, Lang.t("Back"), show_menu)
	_build_difficulty_page()
	language_picker.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, LANGUAGE_MARGIN)
	language_picker.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(language_picker)
	settings.setup(GameSettings.instance())
	settings.back_requested.connect(func() -> void: settings.close())
	add_child(settings)
	add_child(confirm)
	add_child(HoverTip.new())


## A page of the slot: placed by hand (see _place_pages), so it can rise.
func _page_box() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.minimum_size_changed.connect(_place_pages)
	_slot.add_child(page)
	return page


## Puts `part` in the column inside a plain Control as big as it is, so it can
## rise as well as fade (a child of a Container only fades).
func _hold(part: Control) -> void:
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.set_meta(&"held", true)
	column.add_child(holder)
	holder.add_child(part)
	holder.custom_minimum_size = part.get_combined_minimum_size()
	part.set_anchors_preset(Control.PRESET_FULL_RECT)


## A page heading: spaced capitals in pale gold between two short rules, like
## the pick screens' headings.
func _heading(label: Label) -> Control:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ornament.space_out(label, 4)
	return Ornament.between_rules(label)


## The slot is as wide and as tall as the widest and tallest page.
func _fit_slot() -> void:
	var need := Vector2.ZERO
	for page: Control in [_menu, _slots_page, _difficulty_page]:
		need = need.max(page.get_combined_minimum_size())
	_slot.custom_minimum_size = need
	_place_pages()


## Every page at the slot's top, centred across it.
func _place_pages() -> void:
	if _slot == null:
		return
	for page: Control in [_menu, _slots_page, _difficulty_page]:
		if page == null or UiMotion.is_moving(page):
			continue
		var wide := page.get_combined_minimum_size()
		page.size = wide
		page.position = Vector2((_slot.size.x - wide.x) * 0.5, 0.0)


## Lantern, name, subtitle and the four buttons arrive one after the other, once
## per visit to the title (not on a way back from a page).
func _intro() -> void:
	var parts: Array = []
	for holder in column.get_children():
		if holder.has_meta(&"held"):
			parts.append(holder)
	for holder in _menu.get_children():
		parts.append(holder)
	UiMotion.stagger(parts, UiMotion.STAGGER + 0.01, INTRO_START, INTRO_RISE, UiMotion.STORY)


## CHOOSE DIFFICULTY: a button per level ("Hard  x1.2"), Normal in gold, then
## Back to the slots. A level's full effect (Resolve's too) opens in a tip
## to the right of the column, on the hovered button's top.
func _build_difficulty_page() -> void:
	_difficulty_page = _page_box()
	_difficulty_page.add_theme_constant_override(&"separation", 14)
	var heading := UiStyle.label(Lang.t("CHOOSE DIFFICULTY"), UiStyle.FONT_LEAD, UiStyle.TITLE_COLOR)
	_difficulty_page.add_child(_heading(heading))
	var note := UiStyle.note(Lang.t("Enemy HP and damage. It can't be changed later."), UiStyle.DIM_COLOR, NOTE_WIDTH)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_difficulty_page.add_child(note)
	for level in Difficulty.LEVELS:
		var button := DifficultyButton.new()
		button.tip_text = Difficulty.describe(level)
		button.set_meta(&"hover_text", button.tip_text)
		button.text = "%s   %s" % [Lang.t(Difficulty.name_of(level)), Difficulty.scale_text(level)]
		_style_page_button(button, _start_new.bind(level))
		_difficulty_page.add_child(button)
		if level == Difficulty.NORMAL:
			button.add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR)
		difficulty_buttons.append(button)
	_button(_difficulty_page, Lang.t("Back"), show_slots.bind(false))
	_difficulty_page.visible = false


## A level's button: its tip opens beside the column, 12 px off it.
class DifficultyButton extends Button:
	var tip_text := ""

	func tooltip_content() -> Control:
		var card := TooltipCard.note(tip_text)
		for label in card.get_child(0).get_children():
			if label is Label:
				label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				label.custom_minimum_size.x = TIP_WIDTH - 24.0
		return card

	func tooltip_place() -> HoverTip.Place:
		return HoverTip.Place.BESIDE

	func tooltip_anchor() -> Rect2:
		var rect := get_global_rect()
		rect.size.x += TIP_GAP - HoverTip.GAP
		return rect


func _open_settings() -> void:
	open_settings()


## Settings over the screen, on tab `at`.
func open_settings(at := 0) -> void:
	settings.open(at)


func _button(parent: Control, text: String, action: Callable, held := false) -> Button:
	var button := Button.new()
	button.text = text
	_style_page_button(button, action)
	if held:
		parent.add_child(_held_button(button))
	else:
		parent.add_child(button)
	return button


func _style_page_button(button: Button, action: Callable) -> void:
	button.custom_minimum_size = BUTTON_SIZE
	UiStyle.style_button(button, 26)
	button.pressed.connect(action)


## A menu button in a plain Control of its size, so the intro can lift it.
func _held_button(button: Button) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = BUTTON_SIZE
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(button)
	return holder
