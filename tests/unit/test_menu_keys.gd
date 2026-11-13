extends GutTest
## Item 33: arrow keys and Enter in the menus (MenuKeys).

var page: VBoxContainer
var entries: Array[Button] = []
var keys: MenuKeys
## The rows pressed, by text, in order.
var _pressed: Array[String] = []


func before_each() -> void:
	_pressed.clear()
	page = VBoxContainer.new()
	add_child_autofree(page)
	entries.clear()
	for text in ["Resume", "Settings", "Leave", "Exit"]:
		var entry := MenuEntry.new(text)
		entry.pressed.connect(func() -> void: _pressed.append(text))
		page.add_child(entry)
		entries.append(entry)
	keys = MenuKeys.new()
	keys.set_buttons(MenuKeys.buttons_in(page))


func _key(code: Key, echo := false) -> InputEventKey:
	var key := InputEventKey.new()
	key.keycode = code
	key.physical_keycode = code
	key.pressed = true
	key.echo = echo
	return key


func _lit_text() -> String:
	return keys.lit_button().text if keys.lit_button() else ""


func test_buttons_in_finds_a_page_in_order() -> void:
	var nested := VBoxContainer.new()
	page.add_child(nested)
	page.move_child(nested, 1)
	var inner := Button.new()
	inner.text = "Inner"
	nested.add_child(inner)
	var texts: Array[String] = []
	for button in MenuKeys.buttons_in(page):
		texts.append(button.text)
	assert_eq(texts, ["Resume", "Inner", "Settings", "Leave", "Exit"] as Array[String])


func test_down_down_enter_presses_the_second_entry() -> void:
	var sfx := Sfx.new()
	add_child_autofree(sfx)
	assert_eq(keys.lit, -1, "nothing is lit before an arrow key")
	assert_true(keys.handle(_key(KEY_DOWN)))
	assert_eq(_lit_text(), "Resume")
	assert_true(keys.handle(_key(KEY_DOWN)))
	assert_eq(_lit_text(), "Settings")
	assert_true(keys.handle(_key(KEY_ENTER)))
	assert_eq(_pressed, ["Settings"] as Array[String])
	assert_true(sfx._last_played.has(&"click"), "with its click")
	assert_true(keys.handle(_key(KEY_KP_ENTER)), "the keypad's Enter too")
	assert_eq(_pressed, ["Settings", "Settings"] as Array[String])


func test_enter_needs_a_lit_button_and_other_keys_are_not_used() -> void:
	assert_false(keys.handle(_key(KEY_ENTER)), "nothing lit")
	assert_false(keys.handle(_key(KEY_SPACE)), "Space is Center camera")
	assert_false(keys.handle(_key(KEY_ESCAPE)))
	assert_false(keys.handle(InputEventMouseMotion.new()))
	keys.handle(_key(KEY_DOWN))
	assert_false(keys.handle(_key(KEY_ENTER, true)), "a held Enter presses once")
	var release := _key(KEY_ENTER)
	release.pressed = false
	assert_false(keys.handle(release))
	assert_eq(_pressed.size(), 0)


func test_disabled_and_hidden_rows_are_skipped() -> void:
	(entries[1] as MenuEntry).disable("Not available yet")
	entries[2].visible = false
	keys.handle(_key(KEY_DOWN))
	keys.handle(_key(KEY_DOWN))
	assert_eq(_lit_text(), "Exit")
	keys.handle(_key(KEY_UP))
	assert_eq(_lit_text(), "Resume")
	entries[1].pressed.connect(func() -> void: fail_test("a disabled row is never pressed"))
	keys.light(1)
	assert_false(keys.handle(_key(KEY_ENTER)), "a lit row that became disabled")


func test_it_wraps_around_both_ways() -> void:
	keys.handle(_key(KEY_UP))
	assert_eq(_lit_text(), "Exit", "Up starts at the bottom")
	keys.handle(_key(KEY_DOWN))
	assert_eq(_lit_text(), "Resume", "past the last is the first")
	keys.handle(_key(KEY_UP))
	assert_eq(_lit_text(), "Exit", "before the first is the last")
	keys.handle(_key(KEY_LEFT))
	assert_eq(_lit_text(), "Leave", "Left and Right move too")
	keys.handle(_key(KEY_RIGHT))
	assert_eq(_lit_text(), "Exit")


func test_the_mouse_moves_the_light() -> void:
	entries[2].mouse_entered.emit()
	assert_eq(keys.lit, -1, "the mouse alone lights nothing")
	keys.handle(_key(KEY_DOWN))
	entries[2].mouse_entered.emit()
	assert_eq(_lit_text(), "Leave")
	assert_false(entries[0].has_meta(MenuKeys.UNLIT_META), "the old one is put out")
	keys.handle(_key(KEY_DOWN))
	assert_eq(_lit_text(), "Exit", "the keys go on from the mouse")


func test_a_lit_entry_wears_its_hover_look() -> void:
	var entry := entries[1] as MenuEntry
	var hover := entry.get_theme_stylebox(&"hover") as StyleBoxFlat
	keys.light(1)
	assert_eq(UiMotion.lit_t(entry), 1.0, "it eases to its lit look")
	var normal := entry.get_theme_stylebox(&"normal") as StyleBoxFlat
	assert_eq(normal.bg_color, hover.bg_color)
	assert_eq(normal.border_color, hover.border_color)
	assert_eq(entry.get_theme_color(&"font_color"), entry.get_theme_color(&"font_hover_color"))
	assert_eq(entry.get_theme_color(&"icon_normal_color"), entry.get_theme_color(&"icon_hover_color"))


func test_originals_are_restored() -> void:
	var entry := entries[0] as MenuEntry
	var fill := (entry.get_theme_stylebox(&"normal") as StyleBoxFlat).bg_color
	var font := entry.get_theme_color(&"font_color")
	var icon := entry.get_theme_color(&"icon_normal_color")
	var second_fill := (entries[1].get_theme_stylebox(&"normal") as StyleBoxFlat).bg_color
	keys.handle(_key(KEY_DOWN))
	assert_ne((entry.get_theme_stylebox(&"normal") as StyleBoxFlat).bg_color, fill)
	keys.handle(_key(KEY_DOWN))
	assert_eq((entry.get_theme_stylebox(&"normal") as StyleBoxFlat).bg_color, fill)
	assert_eq(entry.get_theme_color(&"font_color"), font)
	assert_eq(entry.get_theme_color(&"icon_normal_color"), icon)
	assert_false(entry.has_meta(MenuKeys.UNLIT_META))
	keys.set_buttons(MenuKeys.buttons_in(page))
	assert_eq(keys.lit, -1, "a page shown again starts unlit")
	assert_eq((entries[1].get_theme_stylebox(&"normal") as StyleBoxFlat).bg_color, second_fill, "set_buttons puts the light out")
	assert_false(entries[1].has_meta(MenuKeys.UNLIT_META))


func test_a_styled_button_lights_and_a_missing_original_is_removed_again() -> void:
	var styled := Button.new()
	UiStyle.style_button(styled)
	var plain := Button.new()
	plain.add_theme_stylebox_override(&"hover", UiStyle.button_style(&"hover"))
	plain.add_theme_color_override(&"font_hover_color", UiStyle.GOLD_COLOR)
	for button in [styled, plain]:
		page.add_child(button)
	keys.set_buttons([styled, plain] as Array[Button])
	keys.light(0)
	assert_eq(styled.get_theme_stylebox(&"normal"), styled.get_theme_stylebox(&"hover"))
	assert_eq(styled.get_theme_color(&"font_color"), UiStyle.TITLE_COLOR)
	keys.light(1)
	assert_eq(styled.get_theme_color(&"font_color"), UiStyle.TEXT_COLOR, "put back")
	assert_eq(plain.get_theme_color(&"font_color"), UiStyle.GOLD_COLOR)
	keys.clear()
	assert_false(plain.has_theme_stylebox_override(&"normal"), "it had none")
	assert_false(plain.has_theme_color_override(&"font_color"))


## A slot list refresh restyles its buttons (a broken slot turns red).
func test_a_restyle_while_lit_is_kept() -> void:
	var slot := Button.new()
	UiStyle.style_button(slot)
	page.add_child(slot)
	keys.set_buttons([slot] as Array[Button])
	keys.light(0)
	slot.add_theme_color_override(&"font_color", UiStyle.ERROR_COLOR)
	keys.clear()
	assert_eq(slot.get_theme_color(&"font_color"), UiStyle.ERROR_COLOR, "the restyle stays")
	assert_ne(slot.get_theme_stylebox(&"normal"), slot.get_theme_stylebox(&"hover"), "the rest is put back")


func test_a_new_page_drops_the_old_mouse_hooks() -> void:
	var old := entries[3]
	keys.set_buttons([entries[0], entries[1]] as Array[Button])
	keys.handle(_key(KEY_DOWN))
	old.mouse_entered.emit()
	assert_eq(_lit_text(), "Resume", "a button off the page moves nothing")
	keys.set_buttons([entries[0], entries[1]] as Array[Button])
	# The row's own hover ease is the other connection.
	assert_eq(entries[0].mouse_entered.get_connections().size(), 2, "one hook per button")
