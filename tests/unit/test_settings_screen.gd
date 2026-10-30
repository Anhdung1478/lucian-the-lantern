extends GutTest
## The Settings screen: its tab rail and pages, the shared theme on its
## sliders, dropdowns (and their pop-up lists), switches and scroll bar, and
## that every control still writes GameSettings.

const PATH := "user://test_settings_screen.json"

var settings: GameSettings
var screen: SettingsScreen


func before_each() -> void:
	_delete()
	settings = GameSettings.new(PATH)
	screen = SettingsScreen.new()
	add_child_autofree(screen)
	screen.setup(settings)
	screen.back_requested.connect(screen.close)
	screen.open()


func after_each() -> void:
	# The screen pushed this test's settings into the engine: put the shared ones back.
	GameSettings.instance().apply_input()
	GameSettings.instance().apply_audio()
	_delete()


func _delete() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


## The control of type `type` on the row card labelled `text`.
func _control(text: String, type: String) -> Control:
	for label: Label in screen.find_children("*", "Label", true, false):
		if label.text == text:
			var card := label.get_parent()
			while not card is PanelContainer:
				card = card.get_parent()
			return card.find_children("*", type, true, false)[0]
	return null


## A real key press and release, through the viewport.
func _press(code: Key) -> void:
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.keycode = code
		key.physical_keycode = code
		key.pressed = pressed
		Input.parse_input_event(key)
	Input.flush_buffered_events()


func _visible_pages() -> Array[int]:
	var shown: Array[int] = []
	for i in screen._pages.size():
		if screen._pages[i].visible:
			shown.append(i)
	return shown


func test_four_tabs_with_icons_in_the_rail() -> void:
	assert_eq(screen._tab_buttons.size(), 4)
	var names: Array[String] = []
	for button in screen._tab_buttons:
		names.append(button.text)
		assert_not_null(button.icon, button.text + " has an icon")
	assert_eq(names, ["Audio", "Controls", "Graphics", "Gameplay"] as Array[String])


func test_show_tab_shows_one_page_and_lights_its_tab() -> void:
	assert_eq(_visible_pages(), [0] as Array[int], "open() starts on Audio")
	for tab in 4:
		screen.show_tab(tab)
		assert_eq(_visible_pages(), [tab] as Array[int])
		for i in 4:
			var style := screen._tab_buttons[i].get_theme_stylebox(&"normal") as StyleBoxFlat
			assert_eq(style.border_color == UiStyle.GOLD_COLOR, i == tab, "only the open tab has the gold accent bar")


func test_a_tab_click_opens_its_page() -> void:
	screen._tab_buttons[2].pressed.emit()
	assert_eq(_visible_pages(), [2] as Array[int])


func test_the_theme_is_built_once() -> void:
	assert_same(UiStyle.theme(), UiStyle.theme())


func test_the_theme_reaches_the_sliders() -> void:
	var slider := _control("Master volume", "HSlider") as HSlider
	var theme := UiStyle.theme()
	assert_same(slider.get_theme_stylebox(&"slider"), theme.get_stylebox(&"slider", &"HSlider"))
	assert_same(slider.get_theme_stylebox(&"grabber_area"), theme.get_stylebox(&"grabber_area", &"HSlider"))
	assert_same(slider.get_theme_icon(&"grabber"), theme.get_icon(&"grabber", &"HSlider"))
	assert_same(slider.get_theme_icon(&"grabber_highlight"), theme.get_icon(&"grabber_highlight", &"HSlider"))


func test_the_theme_reaches_the_dropdowns_and_their_popup() -> void:
	var option := _control("Window mode", "OptionButton") as OptionButton
	var theme := UiStyle.theme()
	assert_same(option.get_theme_stylebox(&"normal"), theme.get_stylebox(&"normal", &"OptionButton"))
	assert_same(option.get_theme_icon(&"arrow"), theme.get_icon(&"arrow", &"OptionButton"))
	var popup := option.get_popup()
	assert_same(popup.get_theme_stylebox(&"panel"), theme.get_stylebox(&"panel", &"PopupMenu"))
	assert_same(popup.get_theme_stylebox(&"hover"), theme.get_stylebox(&"hover", &"PopupMenu"))
	assert_same(popup.get_theme_icon(&"radio_checked"), theme.get_icon(&"radio_checked", &"PopupMenu"))
	assert_eq(popup.get_theme_color(&"font_hover_color"), UiStyle.TITLE_COLOR)


func test_the_theme_reaches_the_switches_and_the_scroll_bar() -> void:
	var toggle := _control("VSync", "CheckButton") as CheckButton
	var theme := UiStyle.theme()
	assert_same(toggle.get_theme_icon(&"checked"), theme.get_icon(&"checked", &"CheckButton"))
	assert_same(toggle.get_theme_icon(&"unchecked"), theme.get_icon(&"unchecked", &"CheckButton"))
	var scroll: ScrollContainer = screen.find_children("*", "ScrollContainer", true, false)[0]
	assert_same(scroll.get_v_scroll_bar().get_theme_stylebox(&"grabber"), theme.get_stylebox(&"grabber", &"VScrollBar"))


func test_a_slider_writes_its_volume_and_letting_go_plays_a_test_sound() -> void:
	var slider := _control("Master volume", "HSlider") as HSlider
	slider.value = 35
	assert_eq(settings.get_value(&"master_volume"), 35)
	assert_eq(GameSettings.new(PATH).get_value(&"master_volume"), 35, "saved")
	var sfx := Sfx.new()
	add_child_autofree(sfx)
	sfx._last_played.clear()
	slider.drag_ended.emit(true)
	assert_true(sfx._last_played.has(&"coin"))


func test_a_dropdown_writes_its_value_and_greys_the_resolution() -> void:
	var option := _control("Window mode", "OptionButton") as OptionButton
	assert_false(screen._resolution.disabled, "windowed: the resolution can change")
	option.get_popup().index_pressed.emit(2)
	assert_eq(settings.get_value(&"window_mode"), "fullscreen")
	assert_eq(option.selected, 2)
	assert_true(screen._resolution.disabled, "fullscreen uses the screen's resolution")


func test_a_switch_writes_its_value() -> void:
	var toggle := _control("VSync", "CheckButton") as CheckButton
	assert_true(toggle.button_pressed)
	toggle.button_pressed = false
	assert_eq(settings.get_value(&"vsync"), false)
	var queue := _control("Skill queue", "CheckButton") as CheckButton
	queue.button_pressed = false
	assert_eq(settings.get_value(&"queue_casts"), false)


func test_a_cast_mode_picker_writes_the_cast_mode() -> void:
	var picker := _control("Skill W", "OptionButton") as OptionButton
	picker.get_popup().index_pressed.emit(2)
	assert_eq(settings.cast_mode(&"skill_w"), "normal")


func test_rebinding_a_key() -> void:
	screen.show_tab(1)
	screen._bind_buttons[&"skill_q"].pressed.emit()
	assert_true(screen.is_listening())
	assert_eq(screen._bind_buttons[&"skill_q"].text, "Press a key...")
	_press(KEY_Z)
	assert_false(screen.is_listening())
	assert_eq(settings.key_label(&"skill_q"), "Z")
	assert_eq(screen._bind_buttons[&"skill_q"].text, "Z")
	assert_eq(InputMap.action_get_events(&"skill_q")[0].physical_keycode, KEY_Z, "applied at once")


func test_reset_to_defaults_restores_keys_and_cast_modes() -> void:
	screen.show_tab(1)
	screen.listen(&"skill_q")
	_press(KEY_Z)
	settings.set_cast_mode(&"skill_e", "normal")
	var reset: Button
	for button: Button in screen.find_children("*", "Button", true, false):
		if button.text == "Reset to defaults":
			reset = button
	reset.pressed.emit()
	assert_eq(settings.key_label(&"skill_q"), "Q")
	assert_eq(screen._bind_buttons[&"skill_q"].text, "Q")
	assert_eq(settings.cast_mode(&"skill_e"), "quick")


func test_back_emits_back_requested() -> void:
	watch_signals(screen)
	var back: Button
	for button: Button in screen.find_children("*", "Button", true, false):
		if button.text == "Back":
			back = button
	back.pressed.emit()
	assert_signal_emitted(screen, "back_requested")
	assert_false(screen.visible)


func test_esc_closes() -> void:
	_press(KEY_ESCAPE)
	assert_false(screen.visible)


func test_esc_while_listening_only_cancels_the_rebind() -> void:
	screen.show_tab(1)
	screen.listen(&"skill_q")
	_press(KEY_ESCAPE)
	assert_true(screen.visible)
	assert_false(screen.is_listening())
	assert_eq(settings.key_label(&"skill_q"), "Q")
	assert_eq(screen._bind_buttons[&"skill_q"].text, "Q")


func test_a_row_card_brightens_on_hover() -> void:
	var slider := _control("Music volume", "HSlider")
	var card := slider.get_parent()
	while not card is PanelContainer:
		card = card.get_parent()
	var before := (card.get_theme_stylebox(&"panel") as StyleBoxFlat).border_color.a
	card.mouse_entered.emit()
	assert_gt((card.get_theme_stylebox(&"panel") as StyleBoxFlat).border_color.a, before)
	card.mouse_exited.emit()
	assert_eq((card.get_theme_stylebox(&"panel") as StyleBoxFlat).border_color.a, before)


func test_a_cards_controls_let_the_mouse_reach_the_card() -> void:
	# A STOP control would end the hover chain, and the card would go dark
	# (and the wheel would not scroll the Controls list) over it.
	for control: Control in [_control("Music volume", "HSlider"), _control("Window mode", "OptionButton"),
			_control("VSync", "CheckButton"), screen._bind_buttons[&"skill_q"], _control("Skill Q", "OptionButton")]:
		assert_eq(control.mouse_filter, Control.MOUSE_FILTER_PASS, control.get_class())


func test_the_panel_and_every_page_fit_the_screen() -> void:
	await wait_process_frames(2)
	var panel := screen._panel
	assert_lte(panel.size.x, 1920.0)
	assert_lte(panel.size.y, 1080.0)
	assert_eq(panel.size, SettingsScreen.PANEL_SIZE, "nothing pushes the panel past its size")
	for tab in 4:
		screen.show_tab(tab)
		var page := screen._pages[tab]
		assert_lte(page.get_combined_minimum_size().y, page.size.y, "page %d fits" % tab)
