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
