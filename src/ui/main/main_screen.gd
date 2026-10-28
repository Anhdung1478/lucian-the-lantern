class_name MainScreen
extends Control
## The screen the game opens on: essences and the gear menu on top, the
## Evolution Tree / Skin Shop / Journey sections in the middle, their buttons
## at the bottom. Nothing here saves by itself; only the gear menu's Save and
## Save as copy write files.
##
## ESC: a section's open pop-up closes first (a section opts in with
## `close_popup() -> bool`, true when it closed something), then the slot
## list, then the gear menu; otherwise ESC opens the gear menu.

signal start_requested(run: StageSetup)
signal exit_requested

const SECTION_TREE := 0
const SECTION_SKINS := 1
const SECTION_JOURNEY := 2
const TOP_BAR := 72.0
const BOTTOM_BAR := 88.0
const TOAST_TIME := 1.6

## The Evolution Tree, Skin Shop and Journey pages, in that order.
var sections: Array[Control] = []
var essence_bar := EssenceBar.new()
var section_bar := SectionBar.new()
var gear := GearMenu.new()
var settings := SettingsScreen.new()
var confirm := ConfirmPopup.new()

var _toast: Label
var _toast_tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	show_section(SECTION_JOURNEY)


## Shows one section and lights its button.
func show_section(index: int) -> void:
	for i in sections.size():
		sections[i].visible = i == index
	section_bar.select(index)


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
	if not event.is_action_pressed(&"open_menu"):
		return
	# Settings and the Yes / No pop-up read their own ESC.
	if settings.visible or confirm.is_open():
		return
	if not _close_section_popup():
		if gear.is_showing_slots():
			gear.open()
		elif gear.visible:
			gear.close()
		else:
			gear.open()
	get_viewport().set_input_as_handled()


func _close_section_popup() -> bool:
	for section in sections:
		if section.visible and section.has_method(&"close_popup") and section.close_popup():
			return true
	return false


func _build() -> void:
	var background := TextureRect.new()
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.12, 0.14, 0.2), Color(0.03, 0.035, 0.05)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	background.texture = texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var area := Control.new()
	area.set_anchors_preset(Control.PRESET_FULL_RECT)
	area.offset_top = TOP_BAR
	area.offset_bottom = -BOTTOM_BAR
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(area)
	sections.append(_placeholder(area, "Evolution Tree"))
	sections.append(_placeholder(area, "Skin Shop"))
	var journey := JourneySection.new()
	journey.start_training.connect(_start_training)
	area.add_child(journey)
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

	_toast = UiStyle.label("", 28, UiStyle.TITLE_COLOR)
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.offset_top = TOP_BAR + 12
	_toast.visible = false
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast)

	gear.confirm = confirm
	gear.settings_requested.connect(_open_settings)
	gear.exit_requested.connect(exit_requested.emit)
	gear.saved.connect(_on_saved)
	gear.copied.connect(_on_copied)
	add_child(gear)
	settings.setup(GameSettings.instance())
	settings.back_requested.connect(_close_settings)
	add_child(settings)
	# The pop-up and the tooltip come last, so they read input first.
	add_child(confirm)
	add_child(HoverTip.new())


## A stand-in page until the section is built.
func _placeholder(parent: Control, text: String) -> Control:
	var page := CenterContainer.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(UiStyle.label(text, 36, UiStyle.DIM_COLOR))
	parent.add_child(page)
	return page


func _start_training() -> void:
	start_requested.emit(StageSetup.from_save(SaveGame.instance()))


func _open_settings() -> void:
	gear.close()
	settings.open()


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
