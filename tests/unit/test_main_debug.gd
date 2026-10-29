extends GutTest

const PREFIX := "user://test_main_debug_save_slot_"

var main: MainScreen
var table: MainDebugTable


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new(PREFIX)
	SaveGame.instance().reset()
	SaveGame.instance().slot = 1
	main = MainScreen.new()
	add_child_autofree(main)
	table = main.get_node("MainDebugTable") as MainDebugTable


func after_each() -> void:
	Input.parse_input_event(_key(KEY_F3, false))
	Input.flush_buffered_events()


func _key(code: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	return event


func _toggle() -> void:
	Input.parse_input_event(_key(KEY_F3, true))
	Input.flush_buffered_events()
	table._input(_key(KEY_Q, true))
	Input.parse_input_event(_key(KEY_F3, false))
	Input.flush_buffered_events()


func _press(text: String, row := 0) -> void:
	var found: Array[Button] = []
	_collect(table, text, found)
	assert_gt(found.size(), row, "button %s" % text)
	found[row].pressed.emit()


func _collect(node: Node, text: String, into: Array[Button]) -> void:
	var button := node as Button
	if button and button.text == text and not button is OptionButton:
		into.append(button)
	for child in node.get_children():
		_collect(child, text, into)


func _find_spin(node: Node) -> SpinBox:
	if node is SpinBox:
		return node
	for child in node.get_children():
		var found := _find_spin(child)
		if found:
			return found
	return null


func test_starts_hidden() -> void:
	assert_not_null(table)
	assert_false(table.visible)


func test_f3_q_shows_and_hides_it() -> void:
	_toggle()
	assert_true(table.visible)
	_toggle()
	assert_false(table.visible)


func test_q_alone_does_nothing() -> void:
	table._input(_key(KEY_Q, true))
	assert_false(table.visible)


func test_blue_plus_1000() -> void:
	_press("+1000")
	assert_eq(SaveGame.instance().essences.amount(Essences.BLUE), 1000)
	assert_eq(main.essence_bar.amount_label(Essences.BLUE).text, "1000")


func test_orange_and_purple_buttons_and_reset() -> void:
	_press("+10", 0)
	_press("+100", 2)
	var essences := SaveGame.instance().essences
	assert_eq(essences.amount(Essences.ORANGE), 10)
	assert_eq(essences.amount(Essences.PURPLE), 100)
	_press("Reset", 1)
	assert_eq(essences.amount(Essences.ORANGE), 0)
	assert_eq(essences.amount(Essences.PURPLE), 100)


func test_acts_cleared_three_opens_endless() -> void:
	var journey := main.sections[MainScreen.SECTION_JOURNEY] as JourneySection
	assert_true(journey.map.endless.locked)
	var spin := _find_spin(table)
	spin.value = 3
	assert_false(journey.map.endless.locked)
	assert_eq(SaveGame.instance().tree.acts_cleared, 3)


func test_max_tree_maxes_every_node() -> void:
	_press("Max tree (free)")
	var tree_section := main.sections[MainScreen.SECTION_TREE] as TreeSection
	for id in tree_section.map.views:
		assert_eq(tree_section.map.views[id].state(), &"maxed", str(id))


func test_clear_tree_empties_it() -> void:
	SaveGame.instance().tree.max_all()
	_press("Clear tree (no refund)")
	var tree_section := main.sections[MainScreen.SECTION_TREE] as TreeSection
	for id in tree_section.map.views:
		assert_ne(tree_section.map.views[id].state(), &"maxed", str(id))


func test_reset_progress_is_a_new_game_in_memory() -> void:
	var save := SaveGame.instance()
	save.essences.add(Essences.BLUE, 500)
	save.owned_skins.append(&"other")
	save.skin = &"other"
	_press("Reset progress")
	assert_eq(save.essences.amount(Essences.BLUE), 0)
	assert_eq(save.skin, SaveGame.CLASSIC)
	assert_false(FileAccess.file_exists(save.path(1)), "nothing is written")


func test_forget_boss_purple_empties_bosses() -> void:
	var save := SaveGame.instance()
	save.award_boss("akshan", 10, 2)
	_press("Forget boss purple")
	assert_true(save.bosses.is_empty())
