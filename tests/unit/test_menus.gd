extends GutTest


func test_the_backdrop_copies_the_screen_then_blurs_it() -> void:
	var backdrop := MenuBackdrop.new()
	add_child_autofree(backdrop)
	assert_is(backdrop.get_child(0), BackBufferCopy, "a fresh copy first")
	assert_eq((backdrop.get_child(0) as BackBufferCopy).copy_mode, BackBufferCopy.COPY_MODE_VIEWPORT)
	assert_eq(backdrop.get_child(1), backdrop.blur)
	assert_eq((backdrop.blur.material as ShaderMaterial).shader, MenuBackdrop.SHADER)
	assert_eq(backdrop.mouse_filter, Control.MOUSE_FILTER_STOP, "clicks stop at it")


func test_a_card_has_a_title_a_subtitle_and_no_buttons_of_its_own() -> void:
	var card := MenuCard.new("MENU", "Stage 2-3")
	add_child_autofree(card)
	assert_eq(card.title_label.text, "MENU")
	assert_eq(card.subtitle_label.text, "Stage 2-3")
	assert_true(card.subtitle_label.is_visible_in_tree())
	card.set_subtitle("")
	assert_false(card.subtitle_label.is_visible_in_tree(), "no subtitle, no rules")
	card.set_title("")
	assert_false(card.title_label.visible)
	assert_eq(card.find_children("*", "Button", true, false).size(), 0)
	assert_true(card.is_ancestor_of(card.content))


func test_a_rounded_rect_stays_inside_its_rect() -> void:
	var rect := Rect2(10, 20, 300, 200)
	var points := MenuCard.rounded_rect(rect, 12.0)
	assert_eq(points.size(), 28)
	for point in points:
		assert_true(rect.grow(0.01).has_point(point), str(point))


func test_an_entry_keeps_its_label_icon_kind_and_hint() -> void:
	var entry := MenuEntry.new("Resume", preload("res://assets/art/ui/menu_resume.svg"), MenuEntry.Kind.PRIMARY, "Back to the fight")
	add_child_autofree(entry)
	assert_eq(entry.text, "Resume")
	assert_not_null(entry.icon)
	assert_eq(entry.kind, MenuEntry.Kind.PRIMARY)
	assert_eq(entry.hint_label.text, "Back to the fight")
	assert_true(entry.hint_label.visible)
	assert_eq(entry.custom_minimum_size, MenuEntry.SIZE)
	var plain := MenuEntry.new("Settings")
	add_child_autofree(plain)
	assert_false(plain.hint_label.visible, "no hint")
	plain.set_hint("Audio")
	assert_true(plain.hint_label.visible)


func test_each_kind_has_its_colours() -> void:
	var primary := MenuEntry.new("Close", null, MenuEntry.Kind.PRIMARY)
	var normal := MenuEntry.new("Save")
	var danger := MenuEntry.new("Exit the game", null, MenuEntry.Kind.DANGER)
	for entry in [primary, normal, danger]:
		add_child_autofree(entry)
	assert_eq((primary.get_theme_stylebox(&"normal") as StyleBoxFlat).border_color, UiStyle.GOLD_COLOR, "the main choice is gold")
	assert_eq((normal.get_theme_stylebox(&"hover") as StyleBoxFlat).border_color, UiStyle.GOLD_COLOR)
	assert_eq((normal.get_theme_stylebox(&"hover") as StyleBoxFlat).border_width_left, MenuEntry.BAR_WIDTH, "a bar at its left")
	assert_eq((danger.get_theme_stylebox(&"hover") as StyleBoxFlat).border_color, UiStyle.ERROR_COLOR, "red on hover")
	assert_eq(danger.get_theme_color(&"icon_hover_color"), UiStyle.ERROR_COLOR)


func test_a_disabled_entry_keeps_a_hover_note() -> void:
	var entry := MenuEntry.new("Leave this stage", null, MenuEntry.Kind.DANGER)
	add_child_autofree(entry)
	entry.disable("Not available yet")
	assert_true(entry.disabled)
	assert_eq(entry.get_meta(&"hover_text", ""), "Not available yet")
	entry.enable()
	assert_false(entry.disabled)
	assert_false(entry.has_meta(&"hover_text"))


func test_the_click_sound_is_connected_once() -> void:
	var entry := MenuEntry.new("Save")
	add_child_autofree(entry)
	assert_eq(entry.pressed.get_connections().size(), 1)
	UiStyle.add_click(entry)
	assert_eq(entry.pressed.get_connections().size(), 1, "a second add_click adds nothing")


func _entries(node: Node) -> Dictionary:
	var out := {}
	for button: Button in node.find_children("*", "Button", true, false):
		if button is MenuEntry and button.is_visible_in_tree():
			out[button.text] = button
	return out


func _key(code: Key) -> InputEventKey:
	var key := InputEventKey.new()
	key.keycode = code
	key.physical_keycode = code
	key.pressed = true
	return key


## Item 33: the stage's ESC menu takes the arrow keys and Enter, and opens
## unlit each time. Run alone, the stage greys Leave this stage: it is skipped.
func test_the_stage_menu_works_with_the_arrow_keys_and_enter() -> void:
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	add_child_autofree(stage)
	var screens := stage.screens
	screens._input(_key(KEY_DOWN))
	assert_eq(screens.menu.keys.lit, -1, "closed, it reads no keys")
	screens.set_menu_open(true)
	screens._input(_key(KEY_UP))
	assert_eq(screens.menu.keys.lit_button().text, "Exit the game", "Up starts at the bottom")
	screens._input(_key(KEY_UP))
	assert_eq(screens.menu.keys.lit_button().text, "Settings", "past the greyed Leave this stage")
	screens._input(_key(KEY_ENTER))
	assert_true(screens.settings.visible)
	assert_false(screens.menu.visible)
	screens.set_settings_open(false)
	assert_true(screens.menu.visible)
	assert_eq(screens.menu.keys.lit, -1, "it opens unlit")
	screens._input(_key(KEY_DOWN))
	screens._input(_key(KEY_ENTER))
	assert_false(screens.menu.visible, "Resume")
	assert_false(get_tree().paused)
	get_tree().paused = false


func test_the_stage_menu_is_a_card_with_resume_first() -> void:
	var menu := GameMenu.new()
	add_child_autofree(menu)
	menu.visible = true
	var entries := _entries(menu)
	assert_eq(entries.keys(), ["Resume", "Settings", "Leave this stage", "Exit the game"])
	assert_eq(entries["Resume"].kind, MenuEntry.Kind.PRIMARY)
	assert_eq(entries["Settings"].hint_label.text, GameMenu.SETTINGS_HINT)
	assert_eq(entries["Leave this stage"].kind, MenuEntry.Kind.DANGER)
	assert_eq(entries["Exit the game"].kind, MenuEntry.Kind.DANGER)
	for entry: MenuEntry in entries.values():
		assert_not_null(entry.icon, entry.text)
	assert_eq(menu.card.title_label.text, "MENU")
	menu.set_subtitle("Stage 2-3")
	assert_eq(menu.card.subtitle_label.text, "Stage 2-3")
	watch_signals(menu)
	entries["Resume"].pressed.emit()
	assert_signal_emitted(menu, "resume_requested")


## Review E4: a hint closer than HINT_GAP to its label is hidden.
func test_a_hint_with_no_room_is_hidden() -> void:
	var tight := MenuEntry.new("Leave to main menu", preload("res://assets/art/ui/menu_leave.svg"), MenuEntry.Kind.DANGER, "Title screen")
	add_child_autofree(tight)
	assert_false(tight.hint_label.visible, "no room: no hint")
	var roomy := MenuEntry.new("Save", preload("res://assets/art/ui/menu_resume.svg"), MenuEntry.Kind.NORMAL, "Slot 1")
	add_child_autofree(roomy)
	assert_true(roomy.hint_label.visible)


## Review E6: a card with no title is tighter above and below.
func test_a_card_with_no_title_is_tighter() -> void:
	var bare := MenuCard.new()
	var titled := MenuCard.new("MENU")
	for card in [bare, titled]:
		add_child_autofree(card)
	assert_lt(bare.get_theme_stylebox(&"panel").content_margin_top, titled.get_theme_stylebox(&"panel").content_margin_top)
	assert_eq(bare.get_theme_stylebox(&"panel").content_margin_top, MenuCard.BARE_PAD.x)
	assert_eq(bare.get_theme_stylebox(&"panel").content_margin_bottom, MenuCard.BARE_PAD.y)
	titled.set_title("")
	assert_eq(titled.get_theme_stylebox(&"panel").content_margin_top, MenuCard.BARE_PAD.x, "the title taken away")


## Review E5: a long question wraps at WRAP_WIDTH and the card stays under CARD_MAX.
func test_a_long_question_wraps_and_the_card_stays_narrow() -> void:
	var popup := ConfirmPopup.new()
	add_child_autofree(popup)
	popup.ask("Craft a Hextech Gunblade from a B.F. Sword and a Needlessly Large Rod for a price of 1150 gold?", Callable())
	await wait_process_frames(2)
	assert_lte(popup._message.custom_minimum_size.x, ConfirmPopup.WRAP_WIDTH)
	assert_gt(popup._message.get_line_count(), 1, "it wraps")
	assert_lte(popup._message.get_parent().get_parent().size.x, ConfirmPopup.CARD_MAX)
	popup.answer(true)
	assert_false(popup.is_open())
