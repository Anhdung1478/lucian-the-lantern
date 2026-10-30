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


func _node(stage_id: String) -> JourneyNode:
	return section.map.node_for(stage_id)


## Acts 1..`acts` cleared, plus the stage ids in `more`.
func _clear(acts: int, more: Array[String] = []) -> void:
	var ids := Journey.all_stage_ids(acts)
	ids.append_array(more)
	_save().set_cleared(ids)


func _click() -> InputEventMouseButton:
	var click := InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	return click


func _name(node: JourneyNode) -> String:
	return node.stage_id if node.stage_id != "" else String(node.kind)


# --- The map: places, layout, locks ---------------------------------------------


func test_the_map_has_22_stages_training_and_endless() -> void:
	var map := section.map
	var ids: Array[String] = []
	for node in map.nodes:
		ids.append(node.stage_id)
	assert_eq(ids, Journey.all_stage_ids(6))
	assert_eq(map.training.kind, JourneyNode.TRAINING)
	assert_eq(map.endless.kind, JourneyNode.ENDLESS)
	assert_eq(JourneyMap.NODES.size(), 22)
	for id: String in JourneyMap.NODES:
		assert_true(Journey.is_stage_id(id), id)


func test_the_map_and_the_panel_share_the_content_area() -> void:
	assert_eq(section.map.get_rect(), JourneySection.MAP_RECT)
	assert_eq(section.panel.get_rect(), JourneySection.PANEL_RECT)
	assert_eq(JourneySection.MAP_RECT.position.x, 32.0)
	assert_eq(JourneySection.MAP_RECT.end.x, 1448.0)
	assert_eq(JourneySection.PANEL_RECT.position.x, 1448.0)
	assert_eq(JourneySection.PANEL_RECT.end.x, 1888.0)
	assert_lt(JourneySection.MAP_RECT.end.y, 920.0, "inside the content area (y 72–992)")


func test_every_place_fits_on_the_map_clear_of_the_panel_and_of_each_other() -> void:
	var places: Array[JourneyNode] = []
	places.assign(section.map.nodes)
	places.append(section.map.training)
	places.append(section.map.endless)
	assert_eq(places.size(), 24)
	var map_rect := section.map.get_global_rect()
	var panel_rect := section.panel.get_global_rect()
	for i in places.size():
		var rect := places[i].get_global_rect()
		assert_true(map_rect.encloses(rect), "%s inside the map" % _name(places[i]))
		assert_false(rect.intersects(panel_rect), "%s clear of the panel" % _name(places[i]))
		for j in range(i + 1, places.size()):
			assert_false(rect.intersects(places[j].get_global_rect()), "%s overlaps %s" % [_name(places[i]), _name(places[j])])


func test_a_new_save_locks_acts_two_to_six_and_endless() -> void:
	assert_false(_node("1-1").locked)
	for act in range(2, 7):
		for stage in Journey.stage_count(act):
			var node := _node(Journey.stage_id(act, stage + 1))
			assert_true(node.locked, node.stage_id)
			assert_true(node.fogged, node.stage_id)
	assert_false(section.map.training.locked)
	assert_true(section.map.endless.locked)


## The fog and chain over a locked act (the old chained tab).
func test_locked_acts_are_fogged_until_their_act_opens() -> void:
	for act in range(1, 7):
		assert_eq(section.map.is_fogged(act), act > 1, "act %d" % act)
	_clear(3)
	for act in range(1, 7):
		assert_eq(section.map.is_fogged(act), act > 4, "act %d" % act)


func test_locked_places_say_what_to_clear() -> void:
	assert_eq(_node("2-1").get_meta(&"hover_text"), "Clear Act 1 first")
	assert_eq(_node("3-4").get_meta(&"hover_text"), "Clear Act 2 first")
	assert_eq(section.map.endless.get_meta(&"hover_text"), "Clear Act 3 first")
	assert_eq(section.map.regions[1].get_meta(&"hover_text"), "Clear Act 1 first", "the fogged region too")
	assert_false(section.map.regions[0].has_meta(&"hover_text"), "act 1 is open")
	_clear(1)
	assert_false(section.map.regions[1].has_meta(&"hover_text"))


func test_hover_says_the_stage_and_its_waves() -> void:
	_clear(2)
	assert_eq(_node("3-1").get_meta(&"hover_text"), "Stage 3-1 · The Jungle\n3 waves")
	assert_eq(_node("3-2").get_meta(&"hover_text"), "Stage 3-2 · The Jungle\n4 waves + mini boss\nClear 3-1 first",
		"a locked stage in an open act")
	assert_eq(_node("1-1").get_meta(&"hover_text"), "Act 1 · The Loss\n2 waves + boss wave")


func test_clearing_three_acts_opens_act_four_and_endless() -> void:
	_clear(3)
	assert_false(_node("4-1").locked)
	assert_false(_node("4-1").fogged)
	assert_true(_node("5-1").locked)
	assert_false(section.map.endless.locked)
	assert_ne(section.map.endless.get_meta(&"hover_text", ""), "Clear Act 3 first")


func test_later_stages_are_locked_until_the_one_before_is_cleared() -> void:
	assert_true(_node("2-1").locked)
	_clear(1)
	assert_false(_node("2-1").locked)
	assert_true(_node("2-2").locked)
	assert_false(_node("2-2").fogged, "locked inside an open act: dim with a lock, no fog")


# --- Kinds, art and waves ------------------------------------------------------


func test_act_three_has_mini_bosses_on_two_and_four_and_its_boss_on_five() -> void:
	var kinds: Array[StringName] = []
	for stage in 5:
		kinds.append(_node(Journey.stage_id(3, stage + 1)).kind)
	assert_eq(kinds, [JourneyNode.NORMAL, JourneyNode.MINI_BOSS, JourneyNode.NORMAL, JourneyNode.MINI_BOSS, JourneyNode.BOSS] as Array[StringName])
	assert_eq(_node("3-2").ring_color(), JourneyNode.MINI_BOSS_COLOR)
	assert_eq(_node("3-5").ring_color(), JourneyNode.BOSS_COLOR)
	assert_eq(_node("3-1").diameter(), 56.0)
	assert_eq(_node("3-2").diameter(), 76.0)
	assert_eq(_node("3-5").diameter(), 100.0)


func test_mini_boss_and_boss_places_show_their_art() -> void:
	for act in range(1, 7):
		for stage in range(1, Journey.stage_count(act) + 1):
			var id := Journey.stage_id(act, stage)
			var node := _node(id)
			match Journey.boss_kind(act, stage):
				&"boss":
					assert_eq(node.enemy.id, WavePlan.boss(id), id)
					assert_eq(node.art, node.enemy.art, id)
				&"mini_boss":
					assert_eq(node.enemy.id, WavePlan.mini_boss(id), id)
					assert_eq(node.art, node.enemy.art, id)
				_:
					assert_null(node.enemy, id)
					assert_null(node.art, id)
	assert_eq(_node("3-2").enemy.display_name, "Infernal Drake")
	assert_eq(_node("6-5").enemy.id, &"thresh_final")


func test_places_say_their_waves() -> void:
	assert_eq(_node("2-1").waves_text, "2 waves")
	assert_eq(_node("2-3").waves_text, "3 waves + boss wave")


## A drake comes last in its stage's last wave, not in a wave of its own.
func test_a_mini_boss_place_puts_it_in_the_last_wave() -> void:
	assert_eq(_node("3-2").waves_text, "4 waves + mini boss")
	assert_eq(_node("3-4").waves_text, "5 waves + mini boss")
	assert_eq(_node("3-5").waves_text, "5 waves + boss wave")


# --- Cleared marks, the road and the token ---------------------------------------


func test_act_one_stage_one_is_open_and_a_cleared_place_is_marked() -> void:
	assert_false(_node("1-1").locked)
	assert_false(_node("1-1").cleared)
	_clear(1)
	assert_true(_node("1-1").cleared)
	assert_false(_node("2-1").cleared)


func test_the_road_glows_up_to_the_latest_clear() -> void:
	var map := section.map
	assert_eq(map.lit_stage, "")
	assert_eq(map.lit_offset, 0.0)
	_clear(1, ["2-1", "2-2"] as Array[String])
	assert_eq(map.lit_stage, "2-2")
	assert_almost_eq(map.lit_offset, map.road.get_closest_offset(_node("2-2").center), 1.0)
	assert_gt(map.lit_offset, map.road.get_closest_offset(_node("2-1").center))
	assert_lt(map.lit_offset, map.road.get_closest_offset(_node("2-3").center))
	_clear(6)
	assert_eq(map.lit_stage, "6-5")
	assert_almost_eq(map.lit_offset, map.road.get_baked_length(), 1.0, "the whole road")


func test_the_road_runs_through_every_stage_in_order() -> void:
	var road := section.map.road
	var last := -1.0
	for node in section.map.nodes:
		var at := road.get_closest_offset(node.center)
		assert_lt(road.sample_baked(at).distance_to(node.center), 2.0, node.stage_id)
		assert_gt(at, last, node.stage_id)
		last = at


func test_lucians_token_sits_on_the_next_stage() -> void:
	var map := section.map
	assert_eq(map.token_node, _node("1-1"))
	assert_true(map.token.visible)
	_clear(1)
	assert_eq(map.token_node, _node("2-1"))
	_clear(2, ["3-1"] as Array[String])
	assert_eq(map.token_node, _node("3-2"))
	_clear(6)
	assert_null(map.token_node, "every stage is cleared")
	assert_false(map.token.visible)


func test_the_token_wears_the_equipped_skin() -> void:
	assert_eq(section.map.token_texture, Skins.find(SaveGame.CLASSIC).portrait)
	_save().owned_skins.append(&"high_noon")
	_save().equip_skin(&"high_noon")
	assert_eq(section.map.token_texture, Skins.find(&"high_noon").portrait)


# --- Picking and the panel ---------------------------------------------------------


func test_a_new_game_opens_on_act_one() -> void:
	assert_eq(section.picked, _node("1-1"))
	assert_true(_node("1-1").selected)
	assert_true(section.panel.stage_box.visible)
	assert_false(section.panel.training_box.visible)
	assert_false(section.panel.endless_box.visible)


func test_act_one_start_is_enabled_on_a_new_game() -> void:
	var panel := section.panel
	assert_false(panel.start_button.disabled)
	assert_eq(panel.start_button.text, "Start", "one stage in the act")
	assert_eq(panel.act_label.text, "ACT 1 · THE LOSS")
	assert_eq(panel.title_label.text, "Stage 1-1")
	assert_eq(panel.boss_name_label.text, "Thresh")
	assert_eq(panel.tag_label.text, "Boss")
	assert_eq(panel.purple_label.text, "First kill: +10")


func test_act_one_replays_have_no_boss() -> void:
	_clear(1)
	_save().bosses.append("thresh_1")
	section.pick(_node("1-1"))
	assert_false(section.panel.boss_row.visible)
	assert_eq(section.panel.purple_label.text, "No boss on replays")
	assert_eq(section.panel.status_label.text, "Cleared")


func test_picking_a_mini_boss_stage_fills_the_panel() -> void:
	_clear(2, ["3-1", "3-2", "3-3"] as Array[String])
	section.pick(_node("3-4"))
	var panel := section.panel
	assert_eq(section.picked, _node("3-4"))
	assert_eq(panel.act_label.text, "ACT 3 · THE JUNGLE")
	assert_eq(panel.title_label.text, "Stage 3-4")
	assert_true(panel.boss_row.visible)
	assert_eq(panel.portrait_texture(), _node("3-4").enemy.art)
	assert_eq(panel.boss_name_label.text, "Ocean Drake")
	assert_eq(panel.tag_label.text, "Mini boss")
	assert_eq(panel.waves_label.text, "5 waves + mini boss")
	assert_eq(panel.story_label.text, Journey.ACTS[2]["story"])
	assert_eq(panel.status_label.text, "Not cleared yet")
	assert_eq(panel.purple_label.text, "First kill: +5")
	assert_eq(panel.start_button.text, "Start stage 4")
	assert_false(panel.start_button.disabled)
	assert_false(panel.start_button.has_meta(&"hover_text"))
	# Beaten once: the panel follows the save.
	_save().bosses.append("ocean_drake")
	_clear(2, ["3-1", "3-2", "3-3", "3-4"] as Array[String])
	assert_eq(section.picked, _node("3-4"), "a refresh keeps an open pick")
	assert_eq(panel.status_label.text, "Cleared")
	assert_eq(panel.purple_label.text, "+1 again")


func test_picking_a_boss_stage_shows_the_boss() -> void:
	_clear(1, ["2-1", "2-2"] as Array[String])
	section.pick(_node("2-3"))
	var panel := section.panel
	assert_eq(panel.boss_name_label.text, "Akshan")
	assert_eq(panel.tag_label.text, "Boss")
	assert_eq(panel.waves_label.text, "3 waves + boss wave")
	assert_eq(panel.purple_label.text, "First kill: +10")
	assert_eq(panel.start_button.text, "Start stage 3")


func test_a_normal_stage_has_no_boss_row() -> void:
	_clear(1)
	section.pick(_node("2-1"))
	assert_false(section.panel.boss_row.visible)
	assert_false(section.panel.purple_row.visible)
	assert_eq(section.panel.waves_label.text, "2 waves")
	assert_eq(section.panel.start_button.text, "Start stage 1")


## The roster: each enemy of the stage's waves once, in order; the mini boss
## has the portrait.
func test_the_panel_lists_the_stages_enemies() -> void:
	assert_eq(section.panel.enemy_ids, [&"melee_minion", &"ranged_minion", &"siege_minion"] as Array[StringName])
	_clear(2, ["3-1"] as Array[String])
	section.pick(_node("3-2"))
	var ids := section.panel.enemy_ids
	assert_false(&"infernal_drake" in ids)
	assert_eq(ids[0], &"raptor_big", "a pack brings its members")
	assert_eq(ids.size(), section.panel.roster.get_child_count())
	assert_eq(section.panel.roster.get_child(0).get_meta(&"hover_text"), "Crimson Raptor")
	assert_no_new_orphans()


func test_endless_chips_light_only_the_chosen_map() -> void:
	_clear(3)
	section.pick(section.map.endless)
	section.panel.map_buttons[4].pressed.emit()
	for i in section.panel.map_buttons.size():
		assert_eq(section.panel.map_buttons[i].button_pressed, i == 4, Journey.ENDLESS_MAPS[i])


func test_start_training_emits_the_signal() -> void:
	section.pick(section.map.training)
	assert_true(section.panel.training_box.visible)
	assert_eq(section.panel.start_button.text, "Start Training")
	watch_signals(section)
	section.panel.start_button.pressed.emit()
	assert_signal_emitted(section, "start_training")


func test_main_screen_sends_a_setup_with_one_equip_slot() -> void:
	var main := MainScreen.new()
	add_child_autofree(main)
	var got: Array[StageSetup] = []
	main.start_requested.connect(func(run: StageSetup) -> void: got.append(run))
	main.sections[MainScreen.SECTION_JOURNEY].start_training.emit()
	assert_eq(got.size(), 1)
	assert_eq(got[0].equip_slots, 1)


func test_picking_switches_the_panel_and_never_saves() -> void:
	_clear(3)
	section.pick(section.map.endless)
	assert_true(section.panel.endless_box.visible)
	assert_false(section.panel.stage_box.visible)
	section.pick(section.map.training)
	assert_true(section.panel.training_box.visible)
	assert_false(section.panel.endless_box.visible)
	assert_true(section.map.training.selected)
	assert_false(section.map.endless.selected)
	assert_false(FileAccess.file_exists(_save().path(1)))


func test_a_locked_place_cannot_be_picked() -> void:
	section.pick(_node("4-1"))
	assert_eq(section.picked, _node("1-1"))
	assert_false(_node("4-1").selected)
	section.pick(section.map.endless)
	assert_eq(section.picked, _node("1-1"))


## Each act's first stage starts once its act opens (every act has its waves).
func test_start_works_once_each_act_opens() -> void:
	for act in range(2, 7):
		var first := _node(Journey.stage_id(act, 1))
		section.pick(first)
		assert_ne(section.picked, first, "act %d is locked" % act)
		_clear(act - 1)
		section.pick(first)
		assert_eq(section.picked, first, "act %d opens" % act)
		assert_false(section.panel.start_button.disabled, "act %d starts" % act)
		assert_false(section.panel.start_button.has_meta(&"hover_text"))


func test_endless_start_works_once_act_three_is_cleared_and_starts_the_chosen_map() -> void:
	var panel := section.panel
	assert_eq(panel.map_buttons.size(), 7)
	assert_eq(panel.map_choice(), 0, "Random")
	_clear(2)
	section.pick(section.map.endless)
	assert_ne(section.picked, section.map.endless, "Endless opens with Act 3")
	_clear(3)
	section.pick(section.map.endless)
	assert_eq(section.picked, section.map.endless)
	assert_eq(panel.start_button.text, "Start")
	assert_false(panel.start_button.disabled)
	assert_false(panel.start_button.has_meta(&"hover_text"))
	panel.map_buttons[3].pressed.emit()
	assert_eq(panel.map_choice(), 3)
	assert_eq(panel.thumbnail.choice, 3, "the thumbnail follows the chip")
	watch_signals(section)
	panel.start_button.pressed.emit()
	assert_signal_emitted_with_parameters(section, "start_endless", [3])


func test_main_screen_starts_endless_on_the_chosen_map() -> void:
	_save().set_cleared(Journey.all_stage_ids(3))
	var main := MainScreen.new()
	add_child_autofree(main)
	var got: Array[StageSetup] = []
	main.start_requested.connect(func(run: StageSetup) -> void: got.append(run))
	main.sections[MainScreen.SECTION_JOURNEY].start_endless.emit(3)
	main.sections[MainScreen.SECTION_JOURNEY].start_endless.emit(EndlessPlan.RANDOM)
	assert_eq(got.size(), 2)
	assert_true(got[0].endless)
	assert_eq(got[0].map_choice, 3)
	assert_eq(got[0].stage_id, EndlessPlan.STAGE_ID)
	assert_eq(got[0].display_name, "Endless · Jungle")
	assert_eq(got[1].map_choice, EndlessPlan.RANDOM, "kept, so Retry rolls again")
	assert_between(got[1].act, 1, Journey.ACTS.size(), "Random rolled a map")


func test_the_main_screen_can_open_the_journey_on_endless() -> void:
	_save().set_cleared(Journey.all_stage_ids(3))
	var main := MainScreen.new()
	main.focus_endless = true
	add_child_autofree(main)
	var journey := main.sections[MainScreen.SECTION_JOURNEY] as JourneySection
	assert_eq(journey.picked, journey.map.endless)
	assert_true(journey.panel.endless_box.visible)
	assert_false(journey.panel.stage_box.visible)


func test_focus_on_a_locked_endless_opens_as_usual() -> void:
	var journey := JourneySection.new()
	journey.focus_endless = true
	add_child_autofree(journey)
	assert_eq(journey.picked, journey.map.node_for("1-1"), "act 1, where the work is")
	assert_true(journey.panel.stage_box.visible)


func test_a_locked_stage_cannot_be_chosen() -> void:
	_clear(1)
	assert_eq(section.picked, _node("1-1"), "a refresh keeps an open pick")
	section.open_on()
	assert_eq(section.picked, _node("2-1"))
	_node("2-2").chosen.emit()
	_node("2-2")._gui_input(_click())
	section.pick(_node("2-2"))
	assert_eq(section.picked, _node("2-1"))


func test_the_default_stage_is_the_first_open_uncleared_one() -> void:
	_save().set_cleared(["1-1", "2-1"] as Array[String])
	section.open_on(2)
	assert_eq(section.picked, _node("2-2"))
	section.open_on()
	assert_eq(section.picked, _node("2-2"))


func test_a_pick_that_locks_falls_back_to_the_next_stage() -> void:
	_clear(3)
	section.pick(_node("4-1"))
	_save().reset()
	assert_eq(section.picked, _node("1-1"))


func test_start_emits_the_act_and_stage() -> void:
	_save().set_cleared(["1-1", "2-1"] as Array[String])
	watch_signals(section)
	section.pick(_node("2-2"))
	section.panel.start_button.pressed.emit()
	assert_signal_emitted_with_parameters(section, "start_stage", [2, 2])


func test_clicking_a_place_picks_it() -> void:
	_save().set_cleared(["1-1", "2-1"] as Array[String])
	section.pick(_node("2-2"))
	_node("2-1")._gui_input(_click())
	assert_eq(section.picked, _node("2-1"))
	assert_true(_node("2-1").selected)
	assert_false(_node("2-2").selected)
	section.map.training._gui_input(_click())
	assert_eq(section.picked, section.map.training)


func test_it_opens_on_the_next_stage() -> void:
	assert_eq(section.picked, _node("1-1"))
	_save().set_cleared(["1-1"] as Array[String])
	section.open_on()
	assert_eq(section.picked, _node("2-1"))
	for act in range(2, 6):
		_clear(act)
		section.open_on()
		assert_eq(section.picked, _node(Journey.stage_id(act + 1, 1)), "act %d can be played" % (act + 1))
	_clear(6)
	section.open_on()
	assert_eq(section.picked, section.map.training, "the story is done")
	section.open_on(1)
	assert_eq(section.picked, _node("1-1"), "the act just played")
	section.open_on(6)
	assert_eq(section.picked, _node("6-5"), "an act all cleared: its last stage")


func test_endless_shows_the_best_wave() -> void:
	_save().endless_best = 17
	_save().changed.emit()
	assert_eq(section.panel.best_label.text, "Best wave: 17")
	assert_eq(section.map.endless.best, 17)


# --- The Endless map thumbnail ----------------------------------------------------


func test_the_thumbnail_draws_each_map_without_adding_it_to_the_tree() -> void:
	var thumbnail := MapThumbnail.new()
	add_child_autofree(thumbnail)
	assert_eq(thumbnail.size, MapThumbnail.SIZE)
	assert_eq(MapThumbnail.SIZE, Vector2(400, 180))
	var nodes_before := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var navigation_map := get_viewport().world_2d.navigation_map
	var regions_before := NavigationServer2D.map_get_regions(navigation_map).size()
	var frame := Rect2(Vector2.ZERO, MapThumbnail.SIZE).grow(0.5)
	for choice in range(1, Journey.ENDLESS_MAPS.size()):
		var map_name: String = Journey.ENDLESS_MAPS[choice]
		thumbnail.show_choice(choice)
		assert_eq(thumbnail.choice, choice)
		assert_false(thumbnail.is_random())
		assert_gt(thumbnail.walls.size() + thumbnail.circles.size() + thumbnail.chasms.size(), 0, map_name)
		assert_true(frame.encloses(thumbnail.ground), map_name)
		for polygon: PackedVector2Array in thumbnail.walls + thumbnail.chasms:
			for point in polygon:
				assert_true(frame.has_point(point), "%s fits the frame" % map_name)
	assert_gt(thumbnail.chasms.size(), 0, "Thresh's domain has its abyss")
	assert_eq(Performance.get_monitor(Performance.OBJECT_NODE_COUNT), nodes_before, "every map freed at once")
	assert_eq(NavigationServer2D.map_get_regions(navigation_map).size(), regions_before, "no navigation baked")
	assert_eq(thumbnail.get_child_count(), 0)
	thumbnail.show_choice(EndlessPlan.RANDOM)
	assert_true(thumbnail.is_random(), "Random shows a ? card")
	assert_eq(thumbnail.walls.size(), 0)
	assert_no_new_orphans()


func test_the_endless_panel_starts_on_random() -> void:
	_clear(3)
	section.pick(section.map.endless)
	assert_true(section.panel.thumbnail.is_random())
	assert_true(section.panel.thumbnail.is_visible_in_tree())


# --- The summoner spells -------------------------------------------------------------


func test_the_spells_sit_compact_at_the_bottom_of_the_panel() -> void:
	assert_eq(LoadoutPanel.PICK_SIZE, 64.0)
	assert_eq(section.loadout, section.panel.loadout)
	var panel_rect := section.panel.get_global_rect()
	var loadout_rect := section.loadout.get_global_rect()
	assert_true(panel_rect.encloses(loadout_rect))
	assert_gt(loadout_rect.position.y, panel_rect.get_center().y, "in the lower half")
	assert_lt(section.panel.start_button.get_global_rect().end.y, loadout_rect.position.y, "Start sits above them")


func test_the_spell_menu_opens_left_of_the_panel_on_screen() -> void:
	_save().tree._levels[&"flash"] = 1
	_save().tree._levels[&"heal"] = 1
	_save().tree._levels[&"summoner_slot_2"] = 1
	_save().tree.changed.emit()
	section.loadout.open_menu(1)
	var menu := section.loadout.menu.get_global_rect()
	assert_lt(menu.end.x, section.panel.get_global_rect().position.x)
	assert_true(get_viewport().get_visible_rect().encloses(menu), "never off the bottom")


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


func test_picking_a_place_clicks_but_a_locked_one_stays_silent() -> void:
	var sfx := Sfx.new()
	add_child_autofree(sfx)
	sfx._last_played.clear()
	_node("1-1")._gui_input(_click())
	assert_true(sfx._last_played.has(&"click"), "an open place clicks")
	sfx._last_played.clear()
	_node("2-1")._gui_input(_click())
	assert_false(sfx._last_played.has(&"click"), "a locked place refuses silently")
