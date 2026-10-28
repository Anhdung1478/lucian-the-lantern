class_name SettingsScreen
extends CanvasLayer
## Settings, opened from the ESC menu: Audio (volumes), Controls (rebinding),
## Graphics (window, resolution, VSync, FPS cap, quality, FPS counter) and Gameplay
## (skill queue). Every change applies at once and is saved. ESC or Back
## returns to the menu; while waiting for a new key, ESC cancels instead.
##
## Rebinding: click a binding, then press a key, or click the same binding
## again with the mouse button to bind. A click anywhere else cancels.

signal back_requested

const PANEL_SIZE := Vector2(760, 640)
const TAB_NAMES := ["Audio", "Controls", "Graphics", "Gameplay"]
const ROW_HEIGHT := 40.0
const BIND_WIDTH := 170.0
## Pressed alone, these never become a binding.
const MODIFIER_KEYS := [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]
const WHEEL_BUTTONS := [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]

var settings: GameSettings

var _tab_buttons: Array[Button] = []
var _pages: Array[Control] = []
var _bind_buttons := {}
## Greyed out unless the window mode is windowed.
var _resolution: OptionButton
## The action waiting for a new key, or &"".
var _listening: StringName = &""
var _listen_frame := -1


func _ready() -> void:
	layer = 45
	visible = false


func setup(game_settings: GameSettings) -> void:
	settings = game_settings
	settings.changed.connect(_on_changed)
	_build()


func open() -> void:
	visible = true
	_stop_listening()
	show_tab(0)


func close() -> void:
	_stop_listening()
	visible = false


func show_tab(tab: int) -> void:
	for i in _pages.size():
		_pages[i].visible = i == tab
		UiStyle.style_button(_tab_buttons[i], 18, i == tab)


func is_listening() -> bool:
	return _listening != &""


## Starts waiting for the next key or mouse button for `action`.
func listen(action: StringName) -> void:
	_stop_listening()
	_listening = action
	_bind_buttons[action].text = "Press a key..."
	# The click that started listening must not bind itself.
	_listen_frame = Engine.get_process_frames()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if is_listening():
		var key := event as InputEventKey
		var mouse := event as InputEventMouseButton
		if key and key.pressed and not key.echo:
			if key.physical_keycode == KEY_ESCAPE:
				_stop_listening()
			elif not MODIFIER_KEYS.has(key.physical_keycode):
				_bind(key)
			get_viewport().set_input_as_handled()
		elif mouse and mouse.pressed and not WHEEL_BUTTONS.has(mouse.button_index) \
				and Engine.get_process_frames() != _listen_frame:
			var button: Button = _bind_buttons[_listening]
			if button.get_global_rect().has_point(button.get_global_mouse_position()):
				_bind(mouse)
				get_viewport().set_input_as_handled()
			else:
				_stop_listening()
	elif event.is_action_pressed(&"open_menu"):
		back_requested.emit()
		get_viewport().set_input_as_handled()


func _bind(event: InputEvent) -> void:
	var action := _listening
	_listening = &""
	settings.rebind(action, event)


func _stop_listening() -> void:
	_listening = &""
	_refresh_bindings()


func _on_changed(key: StringName) -> void:
	match key:
		&"bindings":
			_refresh_bindings()
			settings.apply_input()
		&"master_volume", &"music_volume", &"sfx_volume":
			settings.apply_audio()
		&"window_mode":
			settings.apply_display()
			settings.apply_resolution()
			_resolution.disabled = settings.get_value(&"window_mode") != "windowed"
		&"resolution":
			settings.apply_resolution()
		&"vsync", &"max_fps", &"quality":
			settings.apply_display()


func _refresh_bindings() -> void:
	for action: StringName in _bind_buttons:
		_bind_buttons[action].text = settings.key_label(action)


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.55)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = PANEL_SIZE
	panel.add_theme_stylebox_override(&"panel", UiStyle.panel())
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 14)
	panel.add_child(box)
	var title := UiStyle.label("SETTINGS", 30, UiStyle.TITLE_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override(&"separation", 8)
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(tabs)
	for i in TAB_NAMES.size():
		var button := Button.new()
		button.text = TAB_NAMES[i]
		button.custom_minimum_size = Vector2(150, 42)
		button.pressed.connect(show_tab.bind(i))
		tabs.add_child(button)
		_tab_buttons.append(button)
	box.add_child(HSeparator.new())

	var pages := Control.new()
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(pages)
	for build in [_build_audio, _build_controls, _build_graphics, _build_gameplay]:
		var page: Control = build.call()
		page.set_anchors_preset(Control.PRESET_FULL_RECT)
		pages.add_child(page)
		_pages.append(page)

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(bottom)
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(160, 46)
	UiStyle.style_button(back, 20)
	back.pressed.connect(func() -> void: back_requested.emit())
	bottom.add_child(back)


func _build_audio() -> Control:
	var page := _page()
	for pair in [["Master volume", &"master_volume"], ["Music volume", &"music_volume"], ["Sound effects volume", &"sfx_volume"]]:
		var row := _row(page, pair[0])
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.custom_minimum_size = Vector2(300, ROW_HEIGHT)
		slider.focus_mode = Control.FOCUS_NONE
		slider.value = settings.get_value(pair[1])
		row.add_child(slider)
		var value := UiStyle.label(str(slider.value), 18, UiStyle.GOLD_COLOR)
		value.custom_minimum_size.x = 48
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(value)
		var key: StringName = pair[1]
		slider.value_changed.connect(func(volume: float) -> void:
			value.text = str(int(volume))
			settings.set_value(key, int(volume)))
		slider.drag_ended.connect(func(_changed: bool) -> void: Sfx.play(&"coin"))
	page.add_child(UiStyle.label("No music yet: the Music slider is ready for it.", 14, UiStyle.DIM_COLOR))
	return page


func _build_controls() -> Control:
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override(&"separation", 10)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var page := _page()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(page)
	for action in GameSettings.REBINDABLE:
		var row := _row(page, GameSettings.ACTION_NAMES[action])
		var button := Button.new()
		button.custom_minimum_size = Vector2(BIND_WIDTH, ROW_HEIGHT - 4.0)
		UiStyle.style_button(button, 17)
		button.pressed.connect(listen.bind(action))
		row.add_child(button)
		_bind_buttons[action] = button
	_refresh_bindings()
	var bottom := HBoxContainer.new()
	outer.add_child(bottom)
	var hint := UiStyle.label("Click a binding, then press a key (or click it again with a mouse\nbutton). ESC or a click elsewhere cancels. Ctrl + a skill key ranks it up.\nCtrl + the stats key toggles the stats panel; hold it for more stats.", 14, UiStyle.DIM_COLOR)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(hint)
	var reset := Button.new()
	reset.text = "Reset to defaults"
	reset.custom_minimum_size = Vector2(200, 40)
	UiStyle.style_button(reset, 16)
	reset.pressed.connect(func() -> void: settings.reset_bindings())
	bottom.add_child(reset)
	return outer


func _build_graphics() -> Control:
	var page := _page()
	_option(page, "Window mode", &"window_mode", ["Windowed", "Borderless fullscreen", "Fullscreen"], GameSettings.WINDOW_MODES)
	var sizes := _fitting_resolutions()
	_resolution = _option(page, "Resolution", &"resolution", sizes.map(func(size: String) -> String: return size.replace("x", " × ")), sizes)
	_resolution.disabled = settings.get_value(&"window_mode") != "windowed"
	page.add_child(UiStyle.label("Borderless and fullscreen use the screen's resolution.", 14, UiStyle.DIM_COLOR))
	_toggle(page, "VSync", &"vsync")
	_option(page, "FPS cap", &"max_fps", ["30", "60", "120", "144", "Unlimited"], GameSettings.FPS_CAPS)
	_option(page, "Quality", &"quality", ["Low", "Medium", "High"], GameSettings.QUALITIES)
	page.add_child(UiStyle.label("Low turns off anti-aliasing, dash trails and muzzle flashes; Medium uses 2x anti-aliasing.", 14, UiStyle.DIM_COLOR))
	_toggle(page, "Show FPS", &"show_fps")
	return page


## The resolutions that fit on the screen (all of them without a display).
func _fitting_resolutions() -> Array:
	if DisplayServer.get_name() == "headless":
		return GameSettings.RESOLUTIONS
	var screen := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	return GameSettings.RESOLUTIONS.filter(func(size: String) -> bool:
		var parsed := GameSettings.parse_resolution(size)
		return parsed.x <= screen.x and parsed.y <= screen.y)


func _build_gameplay() -> Control:
	var page := _page()
	_toggle(page, "Skill queue", &"queue_casts")
	var note := UiStyle.label("A skill pressed during another skill's cast time or the E dash is cast as soon as it ends, aimed where the key was pressed. Only the latest press is kept.", 14, UiStyle.DIM_COLOR)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = PANEL_SIZE.x - 80.0
	page.add_child(note)
	return page


func _page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override(&"separation", 10)
	return page


func _row(page: Control, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 16)
	page.add_child(row)
	var label := UiStyle.label(text, 18)
	label.custom_minimum_size = Vector2(280, ROW_HEIGHT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	return row


func _option(page: Control, text: String, key: StringName, labels: Array, values: Array) -> OptionButton:
	var row := _row(page, text)
	var option := OptionButton.new()
	option.focus_mode = Control.FOCUS_NONE
	option.custom_minimum_size = Vector2(260, ROW_HEIGHT - 4.0)
	option.add_theme_font_size_override(&"font_size", 17)
	for label: String in labels:
		option.add_item(label)
	option.selected = maxi(values.find(settings.get_value(key)), 0)
	option.item_selected.connect(func(index: int) -> void: settings.set_value(key, values[index]))
	row.add_child(option)
	return option


func _toggle(page: Control, text: String, key: StringName) -> CheckButton:
	var row := _row(page, text)
	var toggle := CheckButton.new()
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.button_pressed = settings.get_value(key)
	toggle.toggled.connect(func(on: bool) -> void: settings.set_value(key, on))
	row.add_child(toggle)
	return toggle
