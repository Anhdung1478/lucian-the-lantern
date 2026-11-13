extends GutTest

const PREFIX := "user://test_main_screen_save_slot_"

var main: MainScreen
var _prefix := ""
## What the pop-up called back, in order.
var _calls: Array[String] = []


## Whether the extras drew before: the pulses and drifts run only with Juice on.
var _renders := Juice.renders


func before_each() -> void:
	Juice.renders = true
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
	Juice.renders = _renders
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


func test_start_writes_the_save_before_the_stage_opens() -> void:
	var essences := SaveGame.instance().essences
	essences.add(Essences.BLUE, 1000)
	assert_true(SaveGame.instance().tree.buy(&"stat_ad", essences))
	assert_false(SaveGame.instance().slot_exists(1), "nothing on disk yet")
	var runs: Array[StageSetup] = []
	main.start_requested.connect(runs.append)
	main._start_training()
	assert_eq(runs.size(), 1)
	var loaded := SaveGame.new(SaveGame.instance().prefix)
	loaded.load_slot(1)
	assert_eq(loaded.tree.level(&"stat_ad"), 1, "the purchase is on disk")


func test_a_failed_save_stops_every_kind_of_start_with_a_red_toast() -> void:
	SaveGame.instance().prefix = "user://no_such_dir/test_main_screen_save_slot_"
	var runs: Array[StageSetup] = []
	main.start_requested.connect(runs.append)
	main._start_training()
	main._start_stage(1, 1)
	main._start_endless(1)
	assert_eq(runs.size(), 0, "nothing starts")
	assert_eq(main.toast_text(), "Could not save, so the stage didn't start")
	assert_eq(main._toast.get_theme_color(&"font_color"), UiStyle.ERROR_COLOR)
	assert_push_warning_count(3)


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


## A key press, as the pop-up or the main screen reads it.
func _key(code: Key) -> InputEventKey:
	var key := InputEventKey.new()
	key.keycode = code
	key.physical_keycode = code
	key.pressed = true
	return key


## Item 33: the confirm button starts lit, so Enter confirms at once; the
## arrow keys move across the buttons shown.
func test_enter_confirms_a_popup_and_the_arrows_move_across_it() -> void:
	_ask_to_save()
	main.confirm._input(_key(KEY_SPACE))
	assert_true(main.confirm.is_open(), "Space is not Enter")
	main.confirm._input(_key(KEY_ENTER))
	assert_false(main.confirm.is_open())
	_ask_to_save()
	main.confirm._input(_key(KEY_RIGHT))
	main.confirm._input(_key(KEY_RIGHT))
	main.confirm._input(_key(KEY_ENTER))
	_ask_to_exit()
	main.confirm._input(_key(KEY_LEFT))
	assert_eq(main.confirm._keys.lit_button().text, "Cancel", "the hidden No is skipped")
	main.confirm._input(_key(KEY_RIGHT))
	main.confirm._input(_key(KEY_KP_ENTER))
	assert_eq(_calls, ["yes", "cancel", "exit"] as Array[String])


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
	var essences := SaveGame.instance().essences
	essences.add(Essences.BLUE, 1000)
	essences.add(Essences.PURPLE, EvolutionTree.RESET_COST)
	assert_true(SaveGame.instance().tree.buy(&"stat_ad", essences))
	(main.sections[MainScreen.SECTION_TREE] as TreeSection).reset_button.pressed.emit()
	assert_true(main.confirm.is_open())
	assert_eq(_choices(main.confirm), "Yes / No")
	main.confirm.answer(false)


func test_the_toast_stays_in_the_top_bar() -> void:
	main.show_toast("Saved to slot 1")
	await wait_process_frames(1)
	assert_lte(main._toast.get_global_rect().end.y, MainScreen.TOP_BAR)


## Item 33: the gear menu takes the arrow keys and Enter while it is open,
## skipping, on its slot page, the current slot.
func test_the_gear_menu_works_with_the_arrow_keys_and_enter() -> void:
	main._input(_key(KEY_DOWN))
	assert_eq(main.gear.keys.lit, -1, "closed, it reads no keys")
	main.gear.open()
	for i in 4:
		main._input(_key(KEY_DOWN))
	assert_eq(main.gear.keys.lit_button().text, "Settings", "Close, Save, Save as copy, Settings")
	main._input(_key(KEY_UP))
	main._input(_key(KEY_ENTER))
	assert_true(main.gear.is_showing_slots(), "Save as copy")
	assert_eq(main.gear.keys.lit, -1, "the slot page starts unlit")
	main._input(_key(KEY_DOWN))
	assert_eq(main.gear.keys.lit_button().text, "Slot 2 · empty", "the current slot is skipped")
	main._input(_key(KEY_ENTER))
	assert_false(main.gear.visible)
	assert_true(SaveGame.instance().slot_exists(2))
	assert_eq(main.toast_text(), "Copied to slot 2")


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


## B15: only the section shown animates; the Journey stops while the Tree or
## the Skin Shop is open.
func test_another_section_stops_the_journey_animating() -> void:
	var journey := main.sections[MainScreen.SECTION_JOURNEY] as JourneySection
	var stage := journey.map.node_for("1-1")
	assert_true(stage.is_processing(), "an open stage pulses")
	assert_true(journey.map.is_processing(), "the token bobs")
	for index in [MainScreen.SECTION_TREE, MainScreen.SECTION_SKINS]:
		main.show_section(index)
		assert_false(stage.is_processing(), "section %d shown" % index)
		assert_false(journey.map.is_processing(), "section %d shown" % index)
	main.show_section(MainScreen.SECTION_JOURNEY)
	assert_true(stage.is_processing())
	assert_true(journey.map.is_processing())


## B15: Settings only dims the main screen, so the sections stand still under
## it (nothing in them processes) and go on once it closes.
func test_settings_stops_every_section_until_it_closes() -> void:
	main.gear.open()
	_press("Settings")
	for i in main.sections.size():
		assert_false(main.sections[i].can_process(), "section %d under Settings" % i)
	main.settings.back_requested.emit()
	for i in main.sections.size():
		assert_true(main.sections[i].can_process(), "section %d after Settings" % i)
	main.gear.close()
	main.settings.open()
	assert_false(main.sections[MainScreen.SECTION_JOURNEY].can_process(), "however Settings opens")
	main.settings.close()
	assert_true(main.sections[MainScreen.SECTION_JOURNEY].can_process())


func test_under_settings_the_journey_and_the_tree_neither_move_nor_redraw() -> void:
	var stage := (main.sections[MainScreen.SECTION_JOURNEY] as JourneySection).map.node_for("1-1")
	var tree := main.sections[MainScreen.SECTION_TREE] as TreeSection
	var page: TreePage = tree.pages[tree.branch]
	await _check_settings_freezes("the Journey's 1-1", stage, stage)
	main.show_section(MainScreen.SECTION_TREE)
	await _check_settings_freezes("the Tree's motes", page, page._motes)


## While Settings is open, `node`'s clock stands still and `canvas` is not
## redrawn; after it closes both go on.
func _check_settings_freezes(what: String, node: Node, canvas: CanvasItem) -> void:
	await wait_process_frames(2)
	main.settings.open()
	var before: float = node._time
	watch_signals(canvas)
	await wait_process_frames(3)
	assert_eq(node._time, before, "%s stand still under Settings" % what)
	assert_signal_emit_count(canvas, "draw", 0, "%s are not redrawn" % what)
	main.settings.close()
	await wait_process_frames(3)
	assert_gt(node._time, before, "%s go on after Settings" % what)
	assert_signal_emitted(canvas, "draw", "%s are redrawn again" % what)


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


func test_esc_closes_the_skin_purchase_pop_up_and_not_the_menu() -> void:
	main.show_section(MainScreen.SECTION_SKINS)
	var shop: SkinShop = main.sections[MainScreen.SECTION_SKINS]
	SaveGame.instance().essences.add(Essences.PURPLE, 100)
	shop.cards[1].button.pressed.emit()
	assert_not_null(shop.purchase, "Purchase asks first")
	_esc()
	assert_null(shop.purchase, "the first ESC closes the pop-up")
	assert_false(main.gear.visible, "and does not open the menu")


func test_esc_closes_the_tree_purchase_pop_up_and_not_the_menu() -> void:
	main.show_section(MainScreen.SECTION_TREE)
	var section: TreeSection = main.sections[MainScreen.SECTION_TREE]
	SaveGame.instance().tree.acts_cleared = 1
	SaveGame.instance().essences.add(Essences.BLUE, 1000)
	section.select(&"skill_q")
	section.info.cost_bar.pressed.emit()
	assert_not_null(section.purchase, "the cost bar asks first")
	_esc()
	assert_null(section.purchase, "the first ESC closes the pop-up")
	assert_eq(section.info.id, &"skill_q", "and keeps the pick")
	assert_false(main.gear.visible, "and does not open the menu")


func test_buying_a_tree_node_writes_no_file() -> void:
	var save := SaveGame.instance()
	save.essences.add(Essences.BLUE, 1000)
	save.tree.buy(save.tree.nodes()[0].id, save.essences)
	assert_false(FileAccess.file_exists(save.path(1)))
	assert_false(save.slot_exists(2))


# --- FREE badge on the Evolution Tree button ----------------------------------------


func test_the_tree_button_shows_free_only_while_something_is_free() -> void:
	assert_false(main.section_bar.badges[MainScreen.SECTION_TREE].visible)
	SaveGame.instance().set_cleared(Journey.all_stage_ids(1))
	assert_true(main.section_bar.badges[MainScreen.SECTION_TREE].visible)
	assert_false(main.section_bar.badges[MainScreen.SECTION_SKINS].visible)
	assert_true(SaveGame.instance().tree.buy(&"ghost", SaveGame.instance().essences))
	assert_false(main.section_bar.badges[MainScreen.SECTION_TREE].visible)


func test_a_freed_main_screen_leaves_no_connection_on_the_save_tree() -> void:
	var tree := SaveGame.instance().tree
	var before := tree.changed.get_connections().size()
	var screen := MainScreen.new()
	add_child(screen)
	assert_gt(tree.changed.get_connections().size(), before)
	screen.free()
	assert_eq(tree.changed.get_connections().size(), before)


func test_the_gear_menu_shows_the_slot_and_its_rows() -> void:
	main.gear.open()
	var save := SaveGame.instance()
	assert_eq(main.gear.card.title_label.text, "MENU")
	assert_eq(main.gear.card.subtitle_label.text, "Slot 1 · %s" % SaveGame.play_time_text(int(save.play_time)))
	assert_eq((main.gear.find_button("Close") as MenuEntry).kind, MenuEntry.Kind.PRIMARY)
	assert_eq((main.gear.find_button("Save") as MenuEntry).hint_label.text, "Slot 1")
	assert_eq((main.gear.find_button("Leave to main menu") as MenuEntry).kind, MenuEntry.Kind.DANGER)
	assert_eq((main.gear.find_button("Exit the game") as MenuEntry).kind, MenuEntry.Kind.DANGER)
	main.gear.show_slots()
	assert_eq(main.gear.card.title_label.text, "SAVE AS COPY")
	assert_eq(main.gear.card.subtitle_label.text, "Pick a slot")
	assert_true(main.gear.find_button("Back") is MenuEntry)
	main.gear.find_button("Back").pressed.emit()
	assert_eq(main.gear.card.title_label.text, "MENU")


## Change 1: difficulty is picked only on the title screen when a new game
## starts; the gear menu has no Difficulty row, not even a greyed one.
func test_the_gear_menu_has_no_difficulty_row() -> void:
	SaveGame.instance().difficulty = Difficulty.EXTREME
	main.gear.open()
	var rows: Array[String] = []
	for button in main.gear.keys.buttons:
		rows.append(button.text)
		assert_false((button as MenuEntry).disabled, "%s can be pressed" % button.text)
		assert_ne((button as MenuEntry).hint_label.text, "Extreme", "%s does not show the level" % button.text)
	assert_eq(rows, ["Close", "Save", "Save as copy", "Settings", "Leave to main menu", "Exit the game"] as Array[String])
	assert_null(main.gear.find_button("Difficulty"))


func test_esc_has_no_difficulty_page_to_go_back_from() -> void:
	main.gear.open()
	_esc()
	assert_false(main.gear.visible, "ESC closes the menu page")
	assert_eq(SaveGame.instance().difficulty, Difficulty.NORMAL)


func test_the_gear_menu_card_fits_on_screen() -> void:
	main.gear.open()
	await wait_process_frames(2)
	var screen := main.get_viewport_rect()
	var card := main.gear.card.get_global_rect()
	assert_true(screen.encloses(card), "the menu page: %s in %s" % [card, screen])


func test_the_yes_no_popup_sits_on_a_card_over_the_blur() -> void:
	var cards := main.confirm.find_children("*", "PanelContainer", true, false).filter(func(node: Node) -> bool: return node is MenuCard)
	assert_eq(cards.size(), 1)
	assert_true(main.confirm.get_child(0) is MenuBackdrop)


func test_esc_closes_the_gear_menu_before_a_pop_up_hidden_under_it() -> void:
	main.show_section(MainScreen.SECTION_TREE)
	var section: TreeSection = main.sections[MainScreen.SECTION_TREE]
	SaveGame.instance().tree.acts_cleared = 1
	SaveGame.instance().essences.add(Essences.BLUE, 1000)
	section.select(&"skill_q")
	section.info.cost_bar.pressed.emit()
	assert_not_null(section.purchase, "the cost bar asks first")
	main.gear.open()
	_esc()
	assert_false(main.gear.visible, "the first ESC closes the menu")
	assert_not_null(section.purchase, "the pop-up under it stays")
	_esc()
	assert_null(section.purchase, "the next ESC closes the pop-up")


func test_esc_closes_the_gear_menu_before_a_picked_node() -> void:
	main.show_section(MainScreen.SECTION_TREE)
	var section: TreeSection = main.sections[MainScreen.SECTION_TREE]
	SaveGame.instance().tree.acts_cleared = 1
	section.select(&"skill_q")
	main.gear.open()
	_esc()
	assert_false(main.gear.visible, "the first ESC closes the menu")
	assert_eq(section.info.id, &"skill_q", "the pick stays")


func test_esc_in_the_slot_list_over_a_pop_up_goes_back_first() -> void:
	main.show_section(MainScreen.SECTION_SKINS)
	var shop: SkinShop = main.sections[MainScreen.SECTION_SKINS]
	SaveGame.instance().essences.add(Essences.PURPLE, 100)
	shop.cards[1].button.pressed.emit()
	main.gear.open()
	_press("Save as copy")
	assert_true(main.gear.is_showing_slots())
	_esc()
	assert_false(main.gear.is_showing_slots(), "back to the menu page")
	assert_true(main.gear.visible)
	assert_not_null(shop.purchase)


# --- Motion (review r1 D15, D16, D18, D21) -----------------------------------------


## Runs `body` with the motion on (as in a real window), then puts it back.
func _with_motion() -> void:
	UiMotion.renders = true
	await wait_process_frames(1)


func test_a_section_swaps_while_the_bars_stay() -> void:
	var renders := UiMotion.renders
	await _with_motion()
	main.show_section(MainScreen.SECTION_TREE)
	var tree: Control = main.sections[MainScreen.SECTION_TREE]
	var journey: Control = main.sections[MainScreen.SECTION_JOURNEY]
	assert_true(tree.visible, "the new section shows at once")
	assert_true(journey.visible, "the old one fades out first")
	assert_true(main.section_bar.highlight.is_sliding(), "the section bar's highlight slides")
	await wait_seconds(UiMotion.SWAP_IN + 0.1)
	assert_false(journey.visible)
	assert_eq(tree.modulate.a, 1.0)
	assert_eq(main.section_bar.highlight.target, main.section_bar._buttons[MainScreen.SECTION_TREE])
	UiMotion.renders = renders


func test_the_gear_menu_closes_at_once_and_fades_after() -> void:
	var renders := UiMotion.renders
	await _with_motion()
	main.gear.open()
	assert_true(main.gear.is_open())
	await wait_seconds(UiMotion.BASE + 0.1)
	main.gear.close()
	assert_false(main.gear.is_open(), "closed for the logic at once")
	assert_true(main.gear.visible, "the look trails")
	await wait_seconds(UiMotion.EXIT + 0.1)
	assert_false(main.gear.visible)
	UiMotion.renders = renders


func test_the_gear_menu_pages_swap_inside_one_card_that_eases_its_height() -> void:
	var renders := UiMotion.renders
	await _with_motion()
	main.gear.open()
	await wait_seconds(UiMotion.BASE + 0.1)
	var menu_height: float = main.gear._pages.custom_minimum_size.y
	main.gear.show_slots()
	assert_true(main.gear.is_showing_slots())
	assert_almost_eq(main.gear._pages.custom_minimum_size.y, menu_height, 1.0, "the card starts at the menu page's height")
	await wait_seconds(UiMotion.BASE + 0.1)
	assert_almost_eq(main.gear._pages.custom_minimum_size.y, main.gear._slot_page.get_combined_minimum_size().y, 0.5, "and ends at the slot page's")
	assert_false(main.gear._menu_page.visible)
	UiMotion.renders = renders


func test_the_essences_count_and_flash() -> void:
	var renders := UiMotion.renders
	await _with_motion()
	var blue := main.essence_bar.amount_label(Essences.BLUE)
	SaveGame.instance().essences.add(Essences.BLUE, 500)
	assert_true(blue.is_counting(), "it counts instead of jumping")
	assert_eq(blue.final_text(), "500")
	await wait_seconds(CountLabel.COUNT_MAX + 0.1)
	assert_eq(blue.text, "500")
	UiMotion.renders = renders


func test_the_toast_sits_on_a_plate_and_leaves() -> void:
	main.show_toast("Saved to slot 1")
	assert_true(main._toast_plate.visible)
	assert_true(main._toast_plate is Plate)
	assert_eq(main._toast.get_parent(), main._toast_plate)
	assert_eq(main.toast_text(), "Saved to slot 1")
