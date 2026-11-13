class_name MainScreen
extends Control
## The screen after a slot is picked: essences and the gear menu on top, the
## Evolution Tree / Skin Shop / Journey sections in the middle, their buttons
## at the bottom. Nothing here saves by itself; only Start (which saves the
## slot before the stage) and the gear menu's Save and Save as copy write files.
## Only the section shown animates, and none does while Settings is open.
##
## ESC: while the gear menu shows it goes first (back from its slot list,
## else close), even over a section's pop-up hidden beneath it. Otherwise a
## section's open pop-up closes (a section opts in with `close_popup() -> bool`,
## true when it closed something); with none open ESC opens the gear menu.
## While the gear menu is open, the arrow keys and Enter work its page.

signal start_requested(run: StageSetup)
signal exit_requested
signal leave_requested

const SECTION_TREE := 0
const SECTION_SKINS := 1
const SECTION_JOURNEY := 2
const TOP_BAR := 72.0
const BOTTOM_BAR := 88.0
const COULD_NOT_START := "Could not save, so the stage didn't start"
const TOAST_TIME := 1.6

## The Evolution Tree, Skin Shop and Journey pages, in that order.
var sections: Array[Control] = []
## Drawn behind every section: the night grove, or the Skin Shop's gallery.
var backdrop := MainBackdrop.new()
var essence_bar := EssenceBar.new()
var section_bar := SectionBar.new()
var gear := GearMenu.new()
var settings := SettingsScreen.new()
var confirm := ConfirmPopup.new()

## Holds the three sections; it stops processing while Settings is open.
var _section_area := Control.new()
var _toast: Label
var _toast_tween: Tween
## Rolls an Endless run's map when the choice is Random.
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	show_section(SECTION_JOURNEY)


## Shows one section and lights its button; the Skin Shop stands in the
## backdrop's gallery, the others in its night grove.
func show_section(index: int) -> void:
	for i in sections.size():
		sections[i].visible = i == index
	section_bar.select(index)
	backdrop.scene = MainBackdrop.Scene.GALLERY if index == SECTION_SKINS else MainBackdrop.Scene.GROVE


## A short message at the top center that fades away.
func show_toast(text: String, error := false) -> void:
	_toast.text = text
	_toast.add_theme_color_override(&"font_color", UiStyle.ERROR_COLOR if error else UiStyle.TITLE_COLOR)
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast.visible = true
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, TOAST_TIME)
	_toast_tween.tween_callback(_toast.hide)


## The toast's current text, "" once it has faded.
func toast_text() -> String:
	return _toast.text if _toast.visible else ""


func _input(event: InputEvent) -> void:
	# Settings and the Yes / No pop-up read their own keys.
	if settings.visible or confirm.is_open():
		return
	if gear.visible and gear.keys.handle(event):
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed(&"open_menu"):
		return
	# The gear menu is on top of a section's pop-up (its button is in the top
	# bar), so while it shows ESC belongs to it first.
	if gear.is_showing_slots():
		gear.open()
	elif gear.visible:
		gear.close()
	elif not _close_section_popup():
		gear.open()
	get_viewport().set_input_as_handled()


func _close_section_popup() -> bool:
	for section in sections:
		if section.visible and section.has_method(&"close_popup") and section.close_popup():
			return true
	return false


func _build() -> void:
	add_child(backdrop)

	_section_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	_section_area.offset_top = TOP_BAR
	_section_area.offset_bottom = -BOTTOM_BAR
	_section_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_section_area)
	var tree_section := TreeSection.new()
	tree_section.confirm = confirm
	_section_area.add_child(tree_section)
	sections.append(tree_section)
	var skin_shop := SkinShop.new()
	_section_area.add_child(skin_shop)
	sections.append(skin_shop)
	var journey := JourneySection.new()
	journey.start_training.connect(_start_training)
	journey.start_stage.connect(_start_stage)
	journey.start_endless.connect(_start_endless)
	_section_area.add_child(journey)
	sections.append(journey)

	var top := Control.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = TOP_BAR
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	essence_bar.position = Vector2(16, 12)
	essence_bar.gear_pressed.connect(gear.open)
	essence_bar.setup(SaveGame.instance().essences)
	top.add_child(essence_bar)

	var bottom := Control.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -BOTTOM_BAR
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom)
	section_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	section_bar.section_chosen.connect(show_section)
	bottom.add_child(section_bar)
	SaveGame.instance().tree.changed.connect(_refresh_free_badge)
	_refresh_free_badge()

	_toast = UiStyle.label("", 28, UiStyle.TITLE_COLOR)
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	# Inside the top bar, so it never sits on the Journey map.
	_toast.offset_top = 16.0
	_toast.visible = false
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast)

	gear.confirm = confirm
	gear.settings_requested.connect(_open_settings)
	gear.exit_requested.connect(exit_requested.emit)
	gear.leave_requested.connect(leave_requested.emit)
	gear.saved.connect(_on_saved)
	gear.copied.connect(_on_copied)
	add_child(gear)
	settings.setup(GameSettings.instance())
	settings.back_requested.connect(_close_settings)
	add_child(settings)
	# The pop-up and the tooltip come last, so they read input first.
	add_child(confirm)
	for cover: CanvasLayer in [gear, settings, confirm]:
		cover.visibility_changed.connect(_update_covered)
	add_child(HoverTip.new())
	var debug := MainDebugTable.new()
	debug.name = &"MainDebugTable"
	add_child(debug)


## The Evolution Tree button's FREE badge: on while any upgrade is free.
func _refresh_free_badge() -> void:
	section_bar.set_badge(SECTION_TREE, SaveGame.instance().tree.has_free())


func _start_training() -> void:
	_request_start(StageSetup.from_save(SaveGame.instance()))


func _start_stage(act: int, stage: int) -> void:
	_request_start(StageSetup.for_stage(SaveGame.instance(), act, stage))


## `map_choice` is a Journey.ENDLESS_MAPS index; Random rolls its map here.
func _start_endless(map_choice: int) -> void:
	_request_start(StageSetup.for_endless(SaveGame.instance(), map_choice, _rng))


## Pressing Start writes the save first (the tree, the gear and the stage
## progress are on disk before the stage opens). If it can't be written the
## stage doesn't start: a red toast says so and the main screen stays.
func _request_start(run: StageSetup) -> void:
	if not SaveGame.instance().save():
		show_toast(COULD_NOT_START, true)
		Sfx.play(&"error")
		return
	start_requested.emit(run)


## The Skin Shop's preview stands still while the gear menu, Settings or a
## Yes / No pop-up covers it. Settings only dims the screen (the sections
## still show under it), so while it is open every section stands still: no
## section processes or redraws (the Tree's motes, the Journey's pulses and
## token) until it closes.
func _update_covered() -> void:
	var shop := sections[SECTION_SKINS] as SkinShop
	shop.set_covered(gear.visible or settings.visible or confirm.is_open())
	_section_area.process_mode = Node.PROCESS_MODE_DISABLED if settings.visible else Node.PROCESS_MODE_INHERIT


func _open_settings() -> void:
	open_settings()


## Settings over the screen, on tab `at`.
func open_settings(at := 0) -> void:
	gear.close()
	settings.open(at)


func _close_settings() -> void:
	settings.close()
	gear.open()


func _on_saved(ok: bool) -> void:
	_report(ok, "Saved to slot %d" % SaveGame.instance().slot)


func _on_copied(slot: int, ok: bool) -> void:
	_report(ok, "Copied to slot %d" % slot)


func _report(ok: bool, text: String) -> void:
	show_toast(text if ok else "Could not save", not ok)
	Sfx.play(&"coin" if ok else &"error")
