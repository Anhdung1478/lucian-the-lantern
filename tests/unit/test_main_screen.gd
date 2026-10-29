extends GutTest

const PREFIX := "user://test_main_screen_save_slot_"

var main: MainScreen
var _prefix := ""
## What the pop-up called back, in order.
var _calls: Array[String] = []


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new(PREFIX)
	_prefix = SaveGame.instance().prefix
	SaveGame.instance().reset()
	SaveGame.instance().slot = 1
	_remove_files()
	_calls.clear()
	main = MainScreen.new()
	add_child_autofree(main)


func after_each() -> void:
	SaveGame.instance().prefix = _prefix
	_remove_files()


func _remove_files() -> void:
	for n in range(1, SaveGame.SLOTS + 1):
		for file in [SaveGame.instance().path(n), SaveGame.instance().backup_path(n)]:
			if FileAccess.file_exists(file):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


func _press(text: String) -> void:
	var button := main.gear.find_button(text)
	assert_not_null(button, "button %s" % text)
	button.pressed.emit()


func _esc() -> void:
	var event := InputEventAction.new()
	event.action = &"open_menu"
	event.pressed = true
	main._input(event)


## The pop-up's buttons on screen, in order: "Yes / No / Cancel".
func _choices(popup: ConfirmPopup) -> String:
	var labels := PackedStringArray()
	for button: Button in popup.find_children("*", "Button", true, false):
		if button.visible:
			labels.append(button.text)
	return " / ".join(labels)


func _choice(popup: ConfirmPopup, text: String) -> Button:
	for button: Button in popup.find_children("*", "Button", true, false):
		if button.visible and button.text == text:
			return button
	return null


func _record(what: String) -> void:
	_calls.append(what)


## The ESC key, straight to the pop-up.
func _esc_key(popup: ConfirmPopup) -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.physical_keycode = KEY_ESCAPE
	key.pressed = true
	popup._input(key)


func test_opens_on_journey() -> void:
	assert_eq(main.sections.size(), 3)
	assert_true(main.sections[MainScreen.SECTION_JOURNEY].visible)
	assert_false(main.sections[MainScreen.SECTION_TREE].visible)
	assert_false(main.sections[MainScreen.SECTION_SKINS].visible)


func test_show_section_shows_only_that_one() -> void:
	main.show_section(MainScreen.SECTION_TREE)
	assert_true(main.sections[MainScreen.SECTION_TREE].visible)
	assert_false(main.sections[MainScreen.SECTION_JOURNEY].visible)


func test_essence_labels_follow_the_amounts() -> void:
	var essences := SaveGame.instance().essences
	assert_eq(main.essence_bar.amount_label(Essences.BLUE).text, "0")
	essences.add(Essences.BLUE, 120)
	essences.add(Essences.PURPLE, 7)
	assert_eq(main.essence_bar.amount_label(Essences.BLUE).text, "120")
	assert_eq(main.essence_bar.amount_label(Essences.ORANGE).text, "0")
	assert_eq(main.essence_bar.amount_label(Essences.PURPLE).text, "7")


func test_save_writes_slot_one_and_toasts() -> void:
	_press("Save")
	assert_true(FileAccess.file_exists(SaveGame.instance().path(1)))
	assert_eq(main.toast_text(), "Saved to slot 1")


func test_a_failed_save_shows_a_red_toast() -> void:
	# A folder that doesn't exist: the save fails.
	SaveGame.instance().prefix = "user://no_such_dir/test_main_screen_save_slot_"
	_press("Save")
	assert_eq(main.toast_text(), "Could not save")
	assert_eq(main._toast.get_theme_color(&"font_color"), UiStyle.ERROR_COLOR)
	assert_push_warning_count(1)


func test_answer_does_nothing_while_the_popup_is_closed() -> void:
	var answers: Array[bool] = []
	main.confirm.answer(true)
	main.confirm.ask("Sure?", func() -> void: answers.append(true), func() -> void: answers.append(false))
	main.confirm.answer(true)
	main.confirm.answer(true)
	main.confirm.answer(false)
	assert_eq(answers, [true] as Array[bool], "no stale answer once closed")


func test_cancel_does_nothing_while_closed_or_on_a_yes_no_question() -> void:
	main.confirm.cancel()
	main.confirm.ask("Sure?", _record.bind("yes"), _record.bind("no"))
	main.confirm.cancel()
	assert_true(main.confirm.is_open(), "Yes / No has no Cancel")
	main.confirm.answer(false)
	assert_eq(_calls, ["no"] as Array[String])


func _ask_to_save() -> void:
	main.confirm.ask_or_cancel("Save before leaving?", _record.bind("yes"), _record.bind("no"), _record.bind("cancel"))


func _ask_to_exit() -> void:
	main.confirm.confirm("Exit the game?", "Exit", _record.bind("exit"), _record.bind("cancel"))


func test_ask_or_cancel_offers_yes_no_and_cancel() -> void:
	_ask_to_save()
	assert_eq(_choices(main.confirm), "Yes / No / Cancel")
	_choice(main.confirm, "Cancel").pressed.emit()
	assert_false(main.confirm.is_open())
	main.confirm.cancel()
	assert_eq(_calls, ["cancel"] as Array[String], "no stale cancel once closed")
	_ask_to_save()
	_choice(main.confirm, "No").pressed.emit()
	_ask_to_save()
	_choice(main.confirm, "Yes").pressed.emit()
	assert_eq(_calls, ["cancel", "no", "yes"] as Array[String])


func test_confirm_offers_its_action_and_cancel() -> void:
	_ask_to_exit()
	assert_eq(_choices(main.confirm), "Exit / Cancel")
	main.confirm.answer(false)
	assert_true(main.confirm.is_open(), "no No to answer")
	main.confirm.cancel()
	_ask_to_exit()
	_choice(main.confirm, "Exit").pressed.emit()
	assert_eq(_calls, ["cancel", "exit"] as Array[String])


func test_the_buttons_are_built_once_and_relabeled() -> void:
	_ask_to_exit()
	main.confirm.cancel()
	main.confirm.ask("Overwrite slot 2?", Callable())
	assert_eq(_choices(main.confirm), "Yes / No")
	main.confirm.answer(false)
	_ask_to_save()
	assert_eq(_choices(main.confirm), "Yes / No / Cancel")
	assert_eq(main.confirm.find_children("*", "Button", true, false).size(), 3)
	main.confirm.cancel()


func test_esc_is_cancel_when_the_question_has_one() -> void:
	_ask_to_save()
	_esc_key(main.confirm)
	assert_false(main.confirm.is_open())
	_ask_to_exit()
	_esc_key(main.confirm)
	assert_false(main.confirm.is_open())
	assert_eq(_calls, ["cancel", "cancel"] as Array[String])


func test_esc_on_a_yes_no_question_is_still_no_or_nothing() -> void:
	main.confirm.ask("Overwrite slot 2?", Callable(), _record.bind("no"))
	_esc_key(main.confirm)
	assert_false(main.confirm.is_open())
	main.confirm.ask("Could not save. Quit anyway?", Callable(), _record.bind("no"), false)
	_esc_key(main.confirm)
	assert_true(main.confirm.is_open(), "ESC doesn't answer this one")
	main.confirm.answer(false)
	assert_eq(_calls, ["no", "no"] as Array[String])


func test_overwrite_and_reset_tree_still_ask_yes_or_no() -> void:
	SaveGame.instance().copy_to(2)
	main.gear.show_slots()
	main.gear.find_button("Slot 2 · 0m · saved %s" % SaveGame.instance().saved_at(2).substr(0, 16)).pressed.emit()
	assert_true(main.confirm.is_open())
	assert_eq(_choices(main.confirm), "Yes / No")
	main.confirm.answer(false)
	(main.sections[MainScreen.SECTION_TREE] as TreeSection).reset_button.pressed.emit()
	assert_true(main.confirm.is_open())
	assert_eq(_choices(main.confirm), "Yes / No")
	main.confirm.answer(false)


func test_the_toast_stays_in_the_top_bar() -> void:
	main.show_toast("Saved to slot 1")
	await wait_process_frames(1)
	assert_lte(main._toast.get_global_rect().end.y, MainScreen.TOP_BAR)


func test_copy_to_an_empty_slot_writes_without_asking() -> void:
	_press("Save as copy")
	_press("Slot 2 · empty")
	assert_false(main.confirm.is_open())
	assert_true(SaveGame.instance().slot_exists(2))
	assert_eq(main.toast_text(), "Copied to slot 2")
	assert_eq(SaveGame.instance().slot, 1)


func test_the_current_slot_is_disabled_in_the_list() -> void:
	main.gear.show_slots()
	assert_true(main.gear.find_button("Slot 1 (current)").disabled)


func test_copy_over_an_existing_slot_asks_first() -> void:
	SaveGame.instance().copy_to(2)
	var stamp := SaveGame.instance().saved_at(2).substr(0, 16)
	main.gear.show_slots()
	main.gear.find_button("Slot 2 · 0m · saved %s" % stamp).pressed.emit()
	assert_true(main.confirm.is_open())
	SaveGame.instance().essences.add(Essences.BLUE, 5)
	main.confirm.answer(true)
	assert_false(main.confirm.is_open())
	assert_eq(main.toast_text(), "Copied to slot 2")


func test_answering_no_keeps_the_slot() -> void:
	SaveGame.instance().copy_to(2)
	main.gear.show_slots()
	main.gear.find_button("Slot 2 · 0m · saved %s" % SaveGame.instance().saved_at(2).substr(0, 16)).pressed.emit()
	main.confirm.answer(false)
	assert_ne(main.toast_text(), "Copied to slot 2")


func test_leave_to_main_menu_asks_the_game() -> void:
	watch_signals(main)
	main.gear.open()
	_press("Leave to main menu")
	assert_signal_emitted(main, "leave_requested")


func test_exit_emits_exit_requested() -> void:
	watch_signals(main)
	main.gear.open()
	_press("Exit the game")
	assert_signal_emitted(main, "exit_requested")


func test_settings_hides_the_menu_and_back_returns() -> void:
	main.gear.open()
	_press("Settings")
	assert_false(main.gear.visible)
	assert_true(main.settings.visible)
	main.settings.back_requested.emit()
	assert_false(main.settings.visible)
	assert_true(main.gear.visible)


func test_esc_opens_and_closes_the_gear_menu() -> void:
	_esc()
	assert_true(main.gear.visible)
	_esc()
	assert_false(main.gear.visible)


func test_esc_in_the_slot_list_goes_back_to_the_menu() -> void:
	main.gear.open()
	main.gear.show_slots()
	_esc()
	assert_true(main.gear.visible)
	assert_not_null(main.gear.find_button("Save as copy"))
	_esc()
	assert_false(main.gear.visible)


func test_esc_is_ignored_while_settings_or_the_popup_are_open() -> void:
	main.settings.open()
	_esc()
	assert_false(main.gear.visible)
	main.settings.close()
	main.confirm.ask("Sure?", Callable())
	_esc()
	assert_false(main.gear.visible)
	main.confirm.answer(false)


func test_buying_a_tree_node_writes_no_file() -> void:
	var save := SaveGame.instance()
	save.essences.add(Essences.BLUE, 1000)
	save.tree.buy(save.tree.nodes()[0].id, save.essences)
	assert_false(FileAccess.file_exists(save.path(1)))
	assert_false(save.slot_exists(2))
