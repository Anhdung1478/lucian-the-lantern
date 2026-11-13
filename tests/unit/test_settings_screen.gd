extends GutTest
## The Settings screen: its tab rail and pages, the shared theme on its
## sliders, dropdowns (and their pop-up lists), switches and scroll bar, and
## that every control still writes GameSettings.

const PATH := "user://test_settings_screen.json"

var settings: CountingSettings
var screen: SettingsScreen


## Counts its saves.
class CountingSettings extends GameSettings:
	var saves := 0

	func save() -> void:
		saves += 1
		super()


func before_each() -> void:
	_delete()
	settings = CountingSettings.new(PATH)
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
	for file in [PATH, PATH + ".tmp"]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


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
		assert_eq(screen._rail_highlight.target, screen._tab_buttons[tab], "the gold bar sits on the open tab")
		for i in 4:
			var lit: bool = screen._tab_buttons[i].get_theme_color(&"font_color") == UiStyle.TITLE_COLOR
			assert_eq(lit, i == tab, "only the open tab's name is lit")


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


## A step with no drag (the mouse wheel, a key) is saved at once.
func test_a_slider_writes_its_volume_and_letting_go_plays_a_test_sound() -> void:
	var slider := _control("Master volume", "HSlider") as HSlider
	slider.value = 35
	assert_eq(settings.get_value(&"master_volume"), 35)
	assert_eq(GameSettings.new(PATH).get_value(&"master_volume"), 35, "saved")
	assert_eq(settings.saves, 1)
	var sfx := Sfx.new()
	add_child_autofree(sfx)
	sfx._last_played.clear()
	slider.drag_ended.emit(true)
	assert_true(sfx._last_played.has(&"coin"))


## B19: a drag applies every step at once (the bus volume follows) and is
## saved once, when let go.
func test_a_slider_drag_applies_every_step_and_saves_once() -> void:
	var slider := _control("Master volume", "HSlider") as HSlider
	var bus := AudioServer.get_bus_index("Master")
	slider.drag_started.emit()
	for volume in [10, 20, 30]:
		slider.value = volume
	assert_eq(settings.get_value(&"master_volume"), 30)
	assert_almost_eq(AudioServer.get_bus_volume_db(bus), linear_to_db(0.3), 0.01, "live")
	assert_eq(settings.saves, 0, "nothing written while dragging")
	assert_eq(GameSettings.new(PATH).get_value(&"master_volume"), 80)
	slider.drag_ended.emit(true)
	assert_eq(settings.saves, 1, "once, when let go")
	assert_eq(GameSettings.new(PATH).get_value(&"master_volume"), 30)
	slider.drag_started.emit()
	slider.drag_ended.emit(false)
	assert_eq(settings.saves, 1, "a drag that changed nothing writes nothing")


## N25: there is music now. Its slider moves the Music bus, and its row no
## longer says there is none.
func test_the_music_slider_moves_the_music_bus_and_its_row_names_the_score() -> void:
	var slider := _control("Music volume", "HSlider") as HSlider
	slider.value = 40
	assert_almost_eq(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), linear_to_db(0.4), 0.01)
	var texts: Array[String] = []
	for label: Label in screen.find_children("*", "Label", true, false):
		texts.append(label.text)
	assert_has(texts, "Each act's score, which follows the fight.")
	for text in texts:
		assert_false(text.containsn("no music"), text)


func test_closing_the_screen_mid_drag_saves_it() -> void:
	var slider := _control("Sound effects volume", "HSlider") as HSlider
	slider.drag_started.emit()
	slider.value = 25
	screen.close()
	assert_eq(settings.saves, 1)
	assert_eq(GameSettings.new(PATH).get_value(&"sfx_volume"), 25)
	slider.value = 26
	assert_eq(settings.saves, 2, "the drag is over: a later step saves at once")


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
	var queue := _control("Cast queue", "CheckButton") as CheckButton
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


## A mouse press over the Skill Q binding button, sent straight to the screen.
func _click_binding(double_click: bool) -> void:
	var button: Button = screen._bind_buttons[&"skill_q"]
	button.global_position = button.get_global_mouse_position() - Vector2(2, 2)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.double_click = double_click
	screen._input(click)


func test_a_double_click_on_the_row_does_not_bind_the_left_button() -> void:
	screen.show_tab(1)
	screen.listen(&"skill_q")
	await wait_process_frames(1)
	_click_binding(true)
	assert_true(screen.is_listening(), "still waiting")
	assert_eq(settings.key_label(&"skill_q"), "Q")


func test_a_single_press_over_the_row_binds_the_mouse_button() -> void:
	screen.show_tab(1)
	screen.listen(&"skill_q")
	await wait_process_frames(1)
	_click_binding(false)
	assert_false(screen.is_listening())
	assert_eq(settings.key_label(&"skill_q"), "LMB")


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


func test_a_row_card_steps_to_the_raised_surface_on_hover() -> void:
	var slider := _control("Music volume", "HSlider")
	var card := slider.get_parent()
	while not card is PanelContainer:
		card = card.get_parent()
	var box := card.get_theme_stylebox(&"panel") as StyleBoxFlat
	var before := box.bg_color
	assert_eq(box.border_width_left, 0, "the fill alone, no border")
	card.mouse_entered.emit()
	assert_eq(box.bg_color, UiStyle.SURFACE_RAISED)
	card.mouse_exited.emit()
	assert_eq(box.bg_color, before)


func test_a_cards_controls_let_the_mouse_reach_the_card() -> void:
	# A STOP control would end the hover chain, and the card would go dark
	# (and the wheel would not scroll the Controls list) over it.
	for control: Control in [_control("Music volume", "HSlider"), _control("Window mode", "OptionButton"),
			_control("VSync", "CheckButton"), screen._bind_buttons[&"skill_q"], _control("Skill Q", "OptionButton")]:
		assert_eq(control.mouse_filter, Control.MOUSE_FILTER_PASS, control.get_class())


## Review r2 E2-2: every row of Controls shares one column template.
func test_every_controls_row_shares_one_column_template() -> void:
	screen.show_tab(1)
	await wait_process_frames(3)
	var keys := {}
	var thirds := {}
	for action in GameSettings.REBINDABLE:
		var button: Button = screen._bind_buttons[action]
		keys[snappedf(button.global_position.x, 0.5)] = true
		var row := button.get_parent()
		var last := row.get_child(row.get_child_count() - 1) as Control
		thirds[snappedf(last.global_position.x, 0.5)] = true
		assert_eq(last.size.x, (row.get_child(row.get_child_count() - 1) as Control).custom_minimum_size.x)
	assert_eq(keys.size(), 1, "one left edge for the key buttons")
	assert_eq(thirds.size(), 1, "one left edge for the third column")


## Review r3 E3-1: in both languages no page is wider than its column, and the
## Controls header's reset button ends on the page's right edge.
func test_every_page_fits_its_column_in_both_languages() -> void:
	var original := Lang.code()
	for language in ["en", "vi"]:
		Lang.use(language)
		var other := SettingsScreen.new()
		add_child_autofree(other)
		other.setup(settings)
		other.open()
		await wait_process_frames(3)
		for tab in 4:
			other.show_tab(tab)
			await wait_process_frames(2)
			var page: Control = other._pages[tab]
			assert_lte(page.get_combined_minimum_size().x, page.size.x + 0.5, "%s page %d min width fits" % [language, tab])
		other.show_tab(1)
		await wait_process_frames(2)
		var page: Control = other._pages[1]
		var reset: Control = page.get_child(0).get_child(1)
		assert_lte(reset.global_position.x + reset.size.x, page.global_position.x + page.size.x + 0.5, "%s: reset inside" % language)
	Lang.use(original)


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


## R1: the Gameplay page turns Resolve off and on.
func test_the_gameplay_page_has_a_resolve_switch_that_starts_on() -> void:
	var toggle := _control("Resolve", "CheckButton") as CheckButton
	assert_true(screen._pages[3].is_ancestor_of(toggle), "on the Gameplay page")
	assert_true(toggle.button_pressed, "on by default")
	var notes := toggle.get_parent().find_children("*", "Label", true, false).map(func(label: Label) -> String: return label.text)
	assert_has(notes, "After each defeat on a stage, Lucian deals more damage and takes less there (up to 5 times).")
	toggle.button_pressed = false
	assert_eq(settings.get_value(Resolve.SETTING), false)
	toggle.button_pressed = true
	assert_eq(settings.get_value(Resolve.SETTING), true)
