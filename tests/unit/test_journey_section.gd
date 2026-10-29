extends GutTest

const PREFIX := "user://test_journey_section_save_slot_"
const SETTINGS_PATH := "user://test_journey_section_settings.json"

var section: JourneySection
## The shared settings, while a test uses scratch ones.
var _settings: GameSettings


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new(PREFIX)
	SaveGame.instance().reset()
	section = JourneySection.new()
	add_child_autofree(section)


func after_each() -> void:
	if _settings:
		GameSettings._instance = _settings
		_settings = null
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))


func _save() -> SaveGame:
	return SaveGame.instance()


func test_a_new_save_locks_acts_two_to_six_and_endless() -> void:
	assert_eq(section.tabs.size(), 8)
	assert_false(section.tabs[0].locked)
	for i in range(1, 6):
		assert_true(section.tabs[i].locked, "act %d" % (i + 1))
		assert_true(section.tabs[i].disabled)
	assert_false(section.tabs[JourneySection.TRAINING_TAB].locked)
	assert_true(section.tabs[JourneySection.ENDLESS_TAB].locked)


func test_a_new_game_opens_on_act_one() -> void:
	assert_eq(section.current, 0)
	assert_true(section.act_pages[0].visible)
	assert_false(section.training_page.visible)


func test_a_locked_tab_label_starts_right_of_its_chain() -> void:
	var endless := section.tabs[JourneySection.ENDLESS_TAB]
	assert_eq(endless.get_theme_stylebox(&"disabled").content_margin_left, JourneyTab.CHAIN_ROOM)
	_save().set_cleared(Journey.all_stage_ids(Journey.ENDLESS_ACT))
	assert_lt(endless.get_theme_stylebox(&"normal").content_margin_left, JourneyTab.CHAIN_ROOM)


func test_locked_tabs_say_what_to_clear() -> void:
	assert_eq(section.tabs[1].get_meta(&"hover_text"), "Clear Act 1 first")
	assert_eq(section.tabs[JourneySection.ENDLESS_TAB].get_meta(&"hover_text"), "Clear Act 3 first")


func test_clearing_three_acts_opens_act_four_and_endless() -> void:
	_save().set_cleared(Journey.all_stage_ids(3))
	assert_false(section.tabs[3].locked)
	assert_true(section.tabs[4].locked)
	assert_false(section.tabs[JourneySection.ENDLESS_TAB].locked)


func test_act_three_shows_skulls_on_stages_two_four_and_five() -> void:
	var cards := section.act_pages[2].cards
	assert_eq(cards.size(), 5)
	var skulls: Array[bool] = []
	for card in cards:
		skulls.append(card.skull.visible)
	assert_eq(skulls, [false, true, false, true, true] as Array[bool])
	assert_eq(cards[1].skull.modulate, StageCard.MINI_BOSS_COLOR)
	assert_eq(cards[4].skull.modulate, StageCard.BOSS_COLOR)


func test_act_one_stage_one_is_open_and_a_cleared_card_is_marked() -> void:
	var card: StageCard = section.act_pages[0].cards[0]
	assert_false(card.locked)
	assert_false(card.cleared)
	_save().set_cleared(["1-1"] as Array[String])
	assert_true(section.act_pages[0].cards[0].cleared)


func test_later_stages_are_locked_until_the_one_before_is_cleared() -> void:
	var cards := section.act_pages[1].cards
	assert_true(cards[0].locked)
	_save().set_cleared(Journey.all_stage_ids(1))
	cards = section.act_pages[1].cards
	assert_false(cards[0].locked)
	assert_true(cards[1].locked)


func test_cards_say_their_waves() -> void:
	assert_eq(section.act_pages[1].cards[0].waves_label.text, "2 waves")
	assert_eq(section.act_pages[1].cards[2].waves_label.text, "3 waves + boss wave")


func test_start_training_emits_the_signal() -> void:
	watch_signals(section)
	section.training_page.start_button.pressed.emit()
	assert_signal_emitted(section, "start_training")


func test_main_screen_sends_a_setup_with_one_equip_slot() -> void:
	var main := MainScreen.new()
	add_child_autofree(main)
	var got: Array[StageSetup] = []
	main.start_requested.connect(func(run: StageSetup) -> void: got.append(run))
	main.sections[MainScreen.SECTION_JOURNEY].start_training.emit()
	assert_eq(got.size(), 1)
	assert_eq(got[0].equip_slots, 1)


func test_tabs_switch_pages_and_never_save() -> void:
	_save().set_cleared(Journey.all_stage_ids(3))
	section.show_tab(JourneySection.ENDLESS_TAB)
	assert_true(section.endless_page.visible)
	section.show_tab(JourneySection.TRAINING_TAB)
	assert_true(section.training_page.visible)
	assert_false(section.endless_page.visible)
	assert_false(FileAccess.file_exists(_save().path(1)))


func test_a_locked_tab_cannot_be_shown() -> void:
	section.show_tab(3)
	assert_false(section.act_pages[3].visible)


func test_act_one_start_is_enabled_on_a_new_game() -> void:
	assert_false(section.act_pages[0].start_button.disabled)


func test_start_is_disabled_for_locked_and_unbuilt_acts_and_endless() -> void:
	assert_true(section.act_pages[1].start_button.disabled, "act 2 is locked")
	_save().set_cleared(Journey.all_stage_ids(2))
	assert_false(section.act_pages[2].start_button.disabled, "act 3 starts: 3-1 has its waves")
	assert_false(section.act_pages[2].start_button.has_meta(&"hover_text"))
	_save().set_cleared(Journey.all_stage_ids(3))
	assert_false(section.act_pages[3].start_button.disabled, "act 4 starts: 4-1 has its waves")
	assert_false(section.act_pages[3].start_button.has_meta(&"hover_text"))
	_save().set_cleared(Journey.all_stage_ids(4))
	assert_true(section.act_pages[4].start_button.disabled)
	assert_eq(section.act_pages[4].start_button.get_meta(&"hover_text"), "Act 5 comes in a later phase")
	assert_true(section.endless_page.start_button.disabled)
	assert_eq(section.endless_page.map_buttons.size(), 7)
	assert_eq(section.endless_page.map_index(), 0)


func test_a_locked_card_cannot_be_chosen() -> void:
	_save().set_cleared(["1-1"] as Array[String])
	var page := section.act_pages[1]
	assert_eq(page.selected, 1)
	page.cards[1].chosen.emit()
	page.select(2)
	assert_eq(page.selected, 1)


func test_the_default_stage_is_the_first_open_uncleared_one() -> void:
	_save().set_cleared(["1-1", "2-1"] as Array[String])
	assert_eq(section.act_pages[1].selected, 2)


func test_start_emits_the_act_and_stage() -> void:
	_save().set_cleared(["1-1", "2-1"] as Array[String])
	watch_signals(section)
	section.act_pages[1].select(2)
	section.act_pages[1].start_button.pressed.emit()
	assert_signal_emitted_with_parameters(section, "start_stage", [2, 2])


func test_clicking_a_card_selects_it() -> void:
	_save().set_cleared(["1-1", "2-1"] as Array[String])
	var click := InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	section.act_pages[1].select(2)
	section.act_pages[1].cards[0]._gui_input(click)
	assert_eq(section.act_pages[1].selected, 1)
	assert_true(section.act_pages[1].cards[0].selected)


func test_it_opens_on_the_first_act_with_work_to_do() -> void:
	assert_eq(section.current, 0)
	_save().set_cleared(["1-1"] as Array[String])
	section.open_on()
	assert_eq(section.current, 1)
	_save().set_cleared(Journey.all_stage_ids(2))
	section.open_on()
	assert_eq(section.current, 2, "act 3 can be played")
	_save().set_cleared(Journey.all_stage_ids(3))
	section.open_on()
	assert_eq(section.current, 3, "act 4 can be played")
	_save().set_cleared(Journey.all_stage_ids(4))
	section.open_on()
	assert_eq(section.current, JourneySection.TRAINING_TAB, "act 5 can't yet")
	section.open_on(1)
	assert_eq(section.current, 0)


func test_endless_shows_the_best_wave() -> void:
	_save().endless_best = 17
	_save().changed.emit()
	assert_eq(section.endless_page.best_label.text, "Best wave: 17")


func test_f_is_chained_until_the_second_slot_is_bought() -> void:
	var picks := section.loadout.picks
	assert_false(picks[0].disabled)
	assert_true(picks[1].disabled)
	assert_eq(picks[1].get_meta(&"hover_text"), "Buy the 2nd summoner slot in the Evolution Tree")
	_save().tree._levels[&"summoner_slot_2"] = 1
	_save().tree.changed.emit()
	assert_false(section.loadout.picks[1].disabled)


func test_the_menu_lists_only_bought_spells() -> void:
	section.loadout.open_menu(0)
	assert_eq(section.loadout.menu.spell_ids(), [] as Array[StringName])
	assert_true(section.loadout.menu.empty_label.visible)
	_save().tree._levels[&"flash"] = 1
	_save().tree._levels[&"heal"] = 1
	section.loadout.close_menu()
	section.loadout.open_menu(0)
	assert_eq(section.loadout.menu.spell_ids(), [&"flash", &"heal"] as Array[StringName])
	assert_false(section.loadout.menu.empty_label.visible)


func test_picking_flash_on_d_then_f_swaps() -> void:
	_save().tree._levels[&"flash"] = 1
	_save().tree._levels[&"summoner_slot_2"] = 1
	section.loadout.open_menu(0)
	section.loadout.menu.pick(&"flash")
	assert_eq(_save().loadout, [&"flash", &""] as Array[StringName])
	assert_false(section.loadout.menu.visible)
	section.loadout.open_menu(1)
	section.loadout.menu.pick(&"flash")
	assert_eq(_save().loadout, [&"", &"flash"] as Array[StringName])


func test_a_spell_no_longer_bought_shows_as_empty() -> void:
	var essences := _save().essences
	essences.add(Essences.BLUE, 1000)
	essences.add(Essences.PURPLE, EvolutionTree.RESET_COST)
	_save().tree.buy(&"flash", essences)
	_save().set_loadout(0, &"flash")
	assert_not_null(section.loadout.picks[0].icon)
	_save().tree.reset(essences)
	assert_eq(_save().loadout[0], &"flash", "the save keeps the pick")
	assert_null(section.loadout.picks[0].icon)
	assert_eq(section.loadout.picks[0].text, "None")
	assert_false(section.loadout.picks[0].has_meta(&"hover_text"))


func test_key_labels_follow_a_rebind() -> void:
	# Scratch settings, so the rebind never reaches a real settings file.
	_settings = GameSettings.instance()
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	GameSettings._instance = GameSettings.new(SETTINGS_PATH)
	var panel := LoadoutPanel.new()
	add_child_autofree(panel)
	assert_eq(panel._key_labels[0].text, "D")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_Z
	GameSettings.instance().rebind(&"summoner_d", key)
	assert_eq(panel._key_labels[0].text, "Z")


func test_escape_closes_the_menu_first() -> void:
	assert_false(section.close_popup())
	section.loadout.open_menu(0)
	assert_true(section.close_popup())
	assert_false(section.loadout.menu.visible)
