extends GutTest
## The kit's parts in UiStyle: a styled button's hover look eases and is the
## same at rest as before, set_selected eases a tab's look, price_row groups a
## price inside a button, and the type and space tokens.

var _renders: bool
var root: Control


func before_each() -> void:
	_renders = UiMotion.renders
	root = Control.new()
	add_child_autofree(root)


func after_each() -> void:
	UiMotion.renders = _renders


func _button(selected := false) -> Button:
	var button := Button.new()
	button.text = "Tab"
	root.add_child(button)
	UiStyle.style_button(button, 22, selected)
	return button


func _box(button: Button, state: StringName) -> StyleBoxFlat:
	return button.get_theme_stylebox(state) as StyleBoxFlat


func test_at_rest_the_looks_are_unchanged() -> void:
	var button := _button()
	var rest := UiStyle.button_style(&"normal")
	var hover := UiStyle.button_style(&"hover")
	assert_ne(_box(button, &"normal"), _box(button, &"hover"), "two boxes")
	assert_eq(_box(button, &"normal").bg_color, rest.bg_color)
	assert_eq(_box(button, &"hover").bg_color, hover.bg_color)
	assert_eq(_box(button, &"hover").border_color, hover.border_color)
	assert_eq(button.get_child_count(), 0, "no extra child")


func test_off_a_hover_changes_nothing() -> void:
	UiMotion.renders = false
	var button := _button()
	button.mouse_entered.emit()
	assert_eq(_box(button, &"normal").bg_color, UiStyle.button_style(&"normal").bg_color)
	assert_eq(_box(button, &"hover").bg_color, UiStyle.button_style(&"hover").bg_color)


func test_a_hover_eases_both_boxes_and_settles_back() -> void:
	UiMotion.renders = true
	var button := _button()
	var rest := UiStyle.button_style(&"normal").bg_color
	var peak := UiStyle.button_style(&"hover").bg_color
	button.mouse_entered.emit()
	assert_eq(_box(button, &"hover").bg_color, rest, "the hover box starts from the rest look")
	UiStyle.ButtonLook.of(button)._hover_tween.custom_step(UiMotion.FAST * 0.5)
	var mid := _box(button, &"hover").bg_color
	assert_ne(mid, peak, "the hover box eases in")
	assert_ne(mid, rest)
	assert_eq(_box(button, &"normal").bg_color, mid, "the rest box carries it too")
	await wait_seconds(UiMotion.FAST)
	assert_eq(_box(button, &"hover").bg_color, peak)
	assert_eq(_box(button, &"normal").bg_color, rest, "settled: each box its own colour")
	button.mouse_exited.emit()
	assert_eq(_box(button, &"normal").bg_color, peak, "the rest box starts from the hover look")
	await wait_seconds(UiMotion.FAST + 0.05)
	assert_eq(_box(button, &"normal").bg_color, rest)
	assert_eq(_box(button, &"hover").bg_color, peak)


func test_a_box_shaped_in_place_keeps_its_shape_and_colours() -> void:
	UiMotion.renders = true
	var button := _button()
	var normal := _box(button, &"normal")
	normal.bg_color = Color(0.3, 0.1, 0.1)
	normal.corner_radius_top_left = 0
	button.mouse_entered.emit()
	button.mouse_exited.emit()
	await wait_seconds(UiMotion.FAST + 0.05)
	assert_eq(normal.bg_color, Color(0.3, 0.1, 0.1), "read again at the ease's start")
	assert_eq(normal.corner_radius_top_left, 0)


func test_a_restyle_while_hovered_takes_the_new_boxes() -> void:
	UiMotion.renders = true
	var button := _button()
	button.mouse_entered.emit()
	UiStyle.style_button(button, 22, true)
	var fresh := _box(button, &"normal")
	assert_eq(fresh.bg_color, UiStyle.button_style(&"normal", true).bg_color)
	await wait_seconds(UiMotion.FAST + 0.05)
	assert_eq(fresh.bg_color, UiStyle.button_style(&"normal", true).bg_color, "the old ease leaves it alone")


func test_set_selected_off_lands_at_once() -> void:
	UiMotion.renders = false
	var button := _button()
	UiStyle.set_selected(button, true)
	assert_eq(_box(button, &"normal").border_color, UiStyle.BORDER_COLOR)
	assert_eq(_box(button, &"normal").bg_color, UiStyle.button_style(&"normal", true).bg_color)
	assert_eq(button.get_theme_color(&"font_color"), UiStyle.TITLE_COLOR)
	UiStyle.set_selected(button, false)
	assert_eq(_box(button, &"normal").bg_color, UiStyle.button_style(&"normal").bg_color)
	assert_eq(button.get_theme_color(&"font_color"), UiStyle.TEXT_COLOR)


func test_set_selected_eases_the_fill_and_font() -> void:
	UiMotion.renders = true
	var button := _button()
	var normal := _box(button, &"normal")
	UiStyle.set_selected(button, true)
	UiStyle.ButtonLook.of(button)._select_tween.custom_step(UiMotion.FAST * 0.5)
	assert_ne(normal.bg_color, UiStyle.button_style(&"normal", true).bg_color, "on its way")
	await wait_seconds(UiMotion.FAST)
	assert_same(_box(button, &"normal"), normal, "no restyle")
	assert_eq(normal.bg_color, UiStyle.button_style(&"normal", true).bg_color)
	assert_eq(button.get_theme_color(&"font_color"), UiStyle.TITLE_COLOR)


func test_set_selected_without_fill_clears_the_rest_box() -> void:
	UiMotion.renders = false
	var button := _button()
	UiStyle.set_selected(button, true, false)
	assert_eq(_box(button, &"normal").bg_color.a, 0.0)
	assert_eq(_box(button, &"normal").border_color.a, 0.0)
	assert_eq(button.get_theme_color(&"font_color"), UiStyle.TITLE_COLOR)
	assert_eq(_box(button, &"hover").bg_color, UiStyle.button_style(&"hover").bg_color, "hover keeps its look")


func test_set_selected_styles_a_plain_button() -> void:
	UiMotion.renders = false
	var button := Button.new()
	root.add_child(button)
	UiStyle.set_selected(button, true)
	assert_eq(_box(button, &"normal").border_color, UiStyle.BORDER_COLOR)


func test_menu_keys_lighting_still_works() -> void:
	UiMotion.renders = true
	var button := _button()
	var keys := MenuKeys.new()
	keys.set_buttons([button] as Array[Button])
	keys.light(0)
	assert_eq(_box(button, &"normal"), _box(button, &"hover"))
	button.mouse_entered.emit()
	button.mouse_exited.emit()
	await wait_seconds(UiMotion.FAST + 0.05)
	assert_eq(_box(button, &"hover").bg_color, UiStyle.button_style(&"hover").bg_color, "lit look kept")
	keys.clear()
	assert_ne(_box(button, &"normal"), _box(button, &"hover"))
	assert_eq(_box(button, &"normal").bg_color, UiStyle.button_style(&"normal").bg_color)


func test_price_row_is_one_centred_group_in_its_button() -> void:
	UiMotion.renders = false
	var button := _button()
	button.custom_minimum_size = Vector2(260, 56)
	var icon := PlaceholderTexture2D.new()
	icon.size = Vector2(32, 32)
	var row := UiStyle.price_row("Purchase", 25, icon)
	button.add_child(row)
	await wait_process_frames(3)
	assert_eq(row.alignment, BoxContainer.ALIGNMENT_CENTER)
	assert_eq(row.size, button.size, "fills the button")
	assert_eq(UiStyle.price_text(row).text, "Purchase")
	assert_eq(UiStyle.price_amount(row).text, "25")
	var words := UiStyle.price_text(row)
	var amount := UiStyle.price_amount(row)
	var picture := row.get_node(^"Icon") as Control
	assert_eq(amount.position.x - words.get_rect().end.x, float(UiStyle.PRICE_GAP))
	assert_eq(picture.position.x - amount.get_rect().end.x, float(UiStyle.PRICE_ICON_GAP))
	assert_eq(picture.size.y, UiStyle.PRICE_ICON)
	var left := words.position.x
	var right := button.size.x - picture.get_rect().end.x
	assert_almost_eq(left, right, 1.0, "centred as one group")
	UiStyle.price_amount(row).set_value(40)
	assert_eq(UiStyle.price_amount(row).text, "40")


func test_price_row_follows_its_buttons_state() -> void:
	var button := _button()
	var row := UiStyle.price_row("Buy", "100", null)
	button.add_child(row)
	button.disabled = true
	await wait_process_frames(3)
	assert_eq(UiStyle.price_text(row).get_theme_color(&"font_color"), UiStyle.DISABLED_FONT)
	assert_eq(UiStyle.price_amount(row).text, "100")
	assert_false(row.get_node(^"Icon").visible, "no icon, no room for one")
	button.disabled = false
	await wait_process_frames(3)
	assert_eq(UiStyle.price_text(row).get_theme_color(&"font_color"), UiStyle.TEXT_COLOR)


func test_tokens() -> void:
	assert_true(UiStyle.FONT_TAG < UiStyle.FONT_NOTE and UiStyle.FONT_NOTE < UiStyle.FONT_BODY)
	assert_true(UiStyle.FONT_BODY < UiStyle.FONT_ROW and UiStyle.FONT_ROW < UiStyle.FONT_LEAD)
	assert_eq(UiStyle.INSET, 14)
	var note := UiStyle.note("A note that wraps.", UiStyle.DIM_COLOR, 200.0)
	add_child_autofree(note)
	assert_eq(note.get_theme_font_size(&"font_size"), UiStyle.FONT_NOTE)
	var font := note.get_theme_font(&"font")
	var line := font.get_height(UiStyle.FONT_NOTE) + note.get_theme_constant(&"line_spacing")
	assert_gte(line / UiStyle.FONT_NOTE, 1.3, "a note's line height")


func test_cell_style_t_runs_from_rim_to_gold() -> void:
	var rest := UiStyle.cell_style_t(UiStyle.RIM_LEGENDARY, 0.0)
	assert_eq(rest.border_color, UiStyle.RIM_LEGENDARY)
	assert_eq(rest.border_width_left, 1)
	var lit := UiStyle.cell_style_t(UiStyle.RIM_LEGENDARY, 1.0)
	assert_eq(lit.border_color, UiStyle.GOLD_COLOR)
	assert_eq(lit.border_width_left, 2)
	var half := UiStyle.cell_style_t(UiStyle.CELL_BORDER, 0.5)
	assert_eq(half.border_color, UiStyle.CELL_BORDER.lerp(UiStyle.GOLD_COLOR, 0.5))
	assert_eq(UiStyle.cell_style(UiStyle.RIM_BOOTS, true).border_color, UiStyle.cell_style_t(UiStyle.RIM_BOOTS, 1.0).border_color)
