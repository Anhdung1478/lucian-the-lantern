extends GutTest

const PREFIX := "user://test_save_slot_"

var save_game: SaveGame


func before_each() -> void:
	_delete_all()
	save_game = SaveGame.new(PREFIX)


func after_each() -> void:
	_delete_all()


func _delete_all() -> void:
	var probe := SaveGame.new(PREFIX)
	for n in range(1, SaveGame.SLOTS + 1):
		for file in [probe.path(n), probe.backup_path(n), probe.path(n) + ".tmp"]:
			if FileAccess.file_exists(file) or DirAccess.dir_exists_absolute(file):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


func _write_text(file_path: String, text: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _blue_in(file_path: String) -> int:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(file_path))
	return int(data.essences.blue)


func test_new_game_defaults() -> void:
	assert_eq(save_game.essences.amount(Essences.BLUE), 0)
	assert_eq(save_game.essences.amount(Essences.ORANGE), 0)
	assert_eq(save_game.essences.amount(Essences.PURPLE), 0)
	assert_eq(save_game.owned_skins, [&"classic"] as Array[StringName])
	assert_eq(save_game.skin, &"classic")
	assert_eq(save_game.loadout, [&"", &""] as Array[StringName])
	assert_eq(save_game.cleared.size(), 0)
	assert_eq(save_game.endless_best, 0)
	assert_false(save_game.slot_exists(1))


func test_save_then_load_restores_everything() -> void:
	save_game.essences.add(Essences.BLUE, 250)
	save_game.essences.add(Essences.ORANGE, 4)
	save_game.essences.add(Essences.PURPLE, 2)
	save_game.owned_skins = [&"classic", &"high_noon"]
	save_game.skin = &"high_noon"
	save_game.loadout = [&"flash", &"heal"]
	save_game.cleared = ["1-1"]
	save_game.endless_best = 7
	assert_true(save_game.save())
	var loaded := SaveGame.new(PREFIX)
	loaded.load_slot(1)
	assert_eq(loaded.essences.to_dict(), {"blue": 250, "orange": 4, "purple": 2})
	assert_typeof(loaded.essences.amount(Essences.BLUE), TYPE_INT)
	assert_eq(loaded.owned_skins, [&"classic", &"high_noon"] as Array[StringName])
	assert_eq(loaded.skin, &"high_noon")
	assert_eq(loaded.loadout, [&"flash", &"heal"] as Array[StringName])
	assert_eq(loaded.cleared, ["1-1"] as Array[String])
	assert_eq(loaded.endless_best, 7)
	assert_typeof(loaded.endless_best, TYPE_INT)


func test_save_copies_the_old_file_to_the_backup() -> void:
	save_game.essences.add(Essences.BLUE, 100)
	save_game.save()
	save_game.essences.set_amount(Essences.BLUE, 200)
	save_game.save()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save_game.backup_path(1)))
	assert_eq(int(data.essences.blue), 100)


func test_broken_main_file_loads_the_backup() -> void:
	save_game.essences.add(Essences.BLUE, 100)
	save_game.save()
	save_game.essences.set_amount(Essences.BLUE, 200)
	save_game.save()
	_write_text(save_game.path(1), "{not json")
	var loaded := SaveGame.new(PREFIX)
	loaded.load_slot(1)
	assert_eq(loaded.essences.amount(Essences.BLUE), 100)
	assert_push_warning_count(1)


func test_a_broken_main_file_never_replaces_a_good_backup() -> void:
	save_game.essences.add(Essences.BLUE, 100)
	save_game.save()
	save_game.essences.set_amount(Essences.BLUE, 200)
	save_game.save()
	_write_text(save_game.path(1), "{not json")
	save_game.essences.set_amount(Essences.BLUE, 300)
	assert_true(save_game.save())
	assert_eq(_blue_in(save_game.backup_path(1)), 100, "the backup keeps the last good copy")
	assert_eq(_blue_in(save_game.path(1)), 300)
	assert_false(FileAccess.file_exists(save_game.path(1) + ".tmp"), "no temp file left")
	assert_push_warning_count(1)


func test_a_failed_write_keeps_the_main_file_and_the_backup() -> void:
	save_game.essences.add(Essences.BLUE, 100)
	save_game.save()
	save_game.essences.set_amount(Essences.BLUE, 200)
	save_game.save()
	var main_text := FileAccess.get_file_as_string(save_game.path(1))
	var backup_text := FileAccess.get_file_as_string(save_game.backup_path(1))
	# A folder where the temp file goes: the write can't open it.
	var blocker := ProjectSettings.globalize_path(save_game.path(1) + ".tmp")
	DirAccess.make_dir_absolute(blocker)
	save_game.essences.set_amount(Essences.BLUE, 300)
	var saved := save_game.save()
	DirAccess.remove_absolute(blocker)
	assert_false(saved)
	assert_eq(FileAccess.get_file_as_string(save_game.path(1)), main_text)
	assert_eq(FileAccess.get_file_as_string(save_game.backup_path(1)), backup_text)
	assert_push_warning_count(1)


func test_saving_into_a_missing_folder_fails() -> void:
	var nowhere := SaveGame.new("user://no_such_dir/save_slot_")
	assert_false(nowhere.save())
	assert_false(nowhere.copy_to(2))
	assert_false(nowhere.slot_exists(1))
	assert_push_warning_count(2)


func test_a_leftover_temp_file_is_replaced() -> void:
	_write_text(save_game.path(1) + ".tmp", "half a save")
	save_game.essences.add(Essences.BLUE, 40)
	assert_true(save_game.save())
	assert_false(FileAccess.file_exists(save_game.path(1) + ".tmp"))
	assert_eq(_blue_in(save_game.path(1)), 40)


func test_both_files_broken_is_a_new_game() -> void:
	_write_text(save_game.path(1), "{not json")
	_write_text(save_game.backup_path(1), "[1, 2")
	save_game.essences.add(Essences.BLUE, 50)
	save_game.load_slot(1)
	assert_eq(save_game.essences.amount(Essences.BLUE), 0)
	assert_eq(save_game.skin, &"classic")
	assert_push_warning_count(2)


func test_copy_to_writes_another_slot_and_keeps_the_current_one() -> void:
	save_game.essences.add(Essences.BLUE, 321)
	assert_true(save_game.copy_to(2))
	assert_true(save_game.slot_exists(2))
	assert_eq(save_game.slot, 1)
	var loaded := SaveGame.new(PREFIX)
	loaded.load_slot(2)
	assert_eq(loaded.essences.amount(Essences.BLUE), 321)


func test_finish_stage_saves() -> void:
	assert_true(save_game.finish_stage(&"left"))
	assert_true(FileAccess.file_exists(save_game.path(1)))
	assert_eq(save_game.cleared.size(), 0)
	save_game.finish_stage(&"cleared", "1-1")
	save_game.finish_stage(&"cleared", "1-1")
	assert_eq(save_game.cleared, ["1-1"] as Array[String])


func test_loading_ignores_unknown_keys() -> void:
	_write_text(save_game.path(1), JSON.stringify({"version": 1, "foo": 3}))
	save_game.load_slot(1)
	assert_eq(save_game.endless_best, 0)
	assert_eq(save_game.skin, &"classic")


func test_saved_at_reads_the_time_written() -> void:
	save_game.save()
	assert_ne(save_game.saved_at(1), "")
	assert_eq(save_game.saved_at(2), "")


func test_instance_uses_the_test_prefix() -> void:
	assert_eq(SaveGame.instance().prefix, "user://test_run_save_slot_")


func test_tree_levels_round_trip() -> void:
	save_game.tree.max_all()
	save_game.save()
	var loaded := SaveGame.new(PREFIX)
	loaded.load_slot(1)
	assert_true(loaded.tree.is_maxed(&"skill_r"))
	assert_eq(loaded.tree.to_dict(), save_game.tree.to_dict())


func test_unknown_skin_is_dropped() -> void:
	_write_text(save_game.path(1), JSON.stringify({"skins": {"owned": ["high_noon", "golden", "Vampire", "vampire"], "equipped": "golden"}}))
	save_game.load_slot(1)
	assert_eq(save_game.owned_skins, [&"classic", &"high_noon", &"vampire"] as Array[StringName])
	assert_eq(save_game.skin, &"classic")


func test_equipped_skin_not_owned_is_classic() -> void:
	_write_text(save_game.path(1), JSON.stringify({"skins": {"owned": ["high_noon"], "equipped": "vampire"}}))
	save_game.load_slot(1)
	assert_eq(save_game.owned_skins, [&"classic", &"high_noon"] as Array[StringName])
	assert_eq(save_game.skin, &"classic")


func test_wrong_types_fall_back_to_a_new_game() -> void:
	_write_text(save_game.path(1), JSON.stringify({"skins": 5, "loadout": ["flash"], "cleared": "1-1", "endless_best": "7"}))
	save_game.load_slot(1)
	assert_eq(save_game.owned_skins, [&"classic"] as Array[StringName])
	assert_eq(save_game.skin, &"classic")
	assert_eq(save_game.loadout, [&"", &""] as Array[StringName], "a loadout of the wrong length")
	assert_eq(save_game.cleared.size(), 0)
	assert_eq(save_game.endless_best, 0)
	_write_text(save_game.path(1), JSON.stringify({"skins": {"owned": 5, "equipped": "vampire"}, "loadout": "flash"}))
	save_game.load_slot(1)
	assert_eq(save_game.owned_skins, [&"classic"] as Array[StringName])
	assert_eq(save_game.skin, &"classic", "an equipped skin that isn't owned")
	assert_eq(save_game.loadout, [&"", &""] as Array[StringName])


func test_loadout_keeps_only_known_spells_once() -> void:
	_write_text(save_game.path(1), JSON.stringify({"loadout": ["warp", "heal"]}))
	save_game.load_slot(1)
	assert_eq(save_game.loadout, [&"", &"heal"] as Array[StringName], "unknown id")
	_write_text(save_game.path(1), JSON.stringify({"loadout": ["flash", "flash"]}))
	save_game.load_slot(1)
	assert_eq(save_game.loadout, [&"flash", &""] as Array[StringName], "a duplicate on F")
	_write_text(save_game.path(1), JSON.stringify({"loadout": ["Smite", 5]}))
	save_game.load_slot(1)
	assert_eq(save_game.loadout, [&"", &""] as Array[StringName], "wrong case and not a string")
	_write_text(save_game.path(1), JSON.stringify({"loadout": ["", "ghost"]}))
	save_game.load_slot(1)
	assert_eq(save_game.loadout, [&"", &"ghost"] as Array[StringName], "none on D")


func test_unknown_cleared_id_is_dropped() -> void:
	_write_text(save_game.path(1), JSON.stringify({"cleared": ["1-1", "9-9", "x"]}))
	save_game.load_slot(1)
	assert_eq(save_game.cleared, ["1-1"] as Array[String])


func test_set_cleared_keeps_tree_acts_in_step() -> void:
	save_game.set_cleared(Journey.all_stage_ids(1))
	assert_eq(save_game.tree.acts_cleared, 1)
	save_game.reset()
	assert_eq(save_game.tree.acts_cleared, 0)


func test_buy_skin_spends_purple_and_owns_it() -> void:
	save_game.essences.add(Essences.PURPLE, 30)
	watch_signals(save_game)
	assert_true(save_game.buy_skin(&"high_noon"))
	assert_eq(save_game.essences.amount(Essences.PURPLE), 5)
	assert_true(&"high_noon" in save_game.owned_skins)
	assert_eq(save_game.skin, SaveGame.CLASSIC, "buying does not equip")
	assert_signal_emitted(save_game, "changed")


func test_buy_skin_fails_when_short_owned_or_unknown() -> void:
	save_game.essences.add(Essences.PURPLE, 24)
	assert_false(save_game.buy_skin(&"high_noon"))
	assert_eq(save_game.essences.amount(Essences.PURPLE), 24)
	save_game.essences.add(Essences.PURPLE, 100)
	assert_true(save_game.buy_skin(&"high_noon"))
	var left := save_game.essences.amount(Essences.PURPLE)
	assert_false(save_game.buy_skin(&"high_noon"), "already owned")
	assert_eq(save_game.essences.amount(Essences.PURPLE), left)
	assert_false(save_game.buy_skin(&"nope"))
	assert_false(save_game.buy_skin(SaveGame.CLASSIC))


func test_equip_skin_needs_ownership() -> void:
	assert_false(save_game.equip_skin(&"vampire"))
	assert_eq(save_game.skin, SaveGame.CLASSIC)
	save_game.essences.add(Essences.PURPLE, 25)
	save_game.buy_skin(&"vampire")
	watch_signals(save_game)
	assert_true(save_game.equip_skin(&"vampire"))
	assert_eq(save_game.skin, &"vampire")
	assert_signal_emitted(save_game, "changed")


func test_buy_and_equip_write_no_file() -> void:
	save_game.essences.add(Essences.PURPLE, 25)
	save_game.buy_skin(&"vampire")
	save_game.equip_skin(&"vampire")
	assert_false(save_game.slot_exists(1))


func test_award_boss_gives_the_first_amount_once_then_the_repeat() -> void:
	assert_eq(save_game.award_boss("akshan", 10, 2), 10)
	assert_eq(save_game.award_boss("akshan", 10, 2), 2)
	assert_eq(save_game.bosses, ["akshan"] as Array[String])
	assert_push_warning_count(0)


func test_award_boss_warns_about_a_boss_missing_from_boss_ids() -> void:
	assert_eq(save_game.award_boss("teemo", 10, 2), 10)
	assert_push_warning("teemo")


func test_bosses_round_trip_and_unknown_ids_are_dropped() -> void:
	save_game.award_boss("thresh_1", 10, 0)
	save_game.save()
	var data := JSON.parse_string(FileAccess.get_file_as_string(save_game.path(1))) as Dictionary
	data["bosses"] = ["thresh_1", "teemo"]
	var file := FileAccess.open(save_game.path(1), FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	var loaded := SaveGame.new(PREFIX)
	loaded.load_slot(1)
	assert_eq(loaded.bosses, ["thresh_1"] as Array[String])


func test_a_file_without_bosses_loads() -> void:
	save_game.save()
	var loaded := SaveGame.new(PREFIX)
	loaded.load_slot(1)
	assert_true(loaded.bosses.is_empty())


func test_start_new_writes_that_slot_and_makes_it_current() -> void:
	save_game.essences.add(Essences.BLUE, 500)
	assert_true(save_game.start_new(2))
	assert_eq(save_game.slot, 2)
	assert_true(save_game.slot_exists(2))
	assert_eq(save_game.essences.amount(Essences.BLUE), 0)


func test_any_slot_exists() -> void:
	assert_false(save_game.any_slot_exists())
	save_game.copy_to(3)
	assert_true(save_game.any_slot_exists())


func test_play_time_round_trips_and_reads_per_slot() -> void:
	save_game.add_play_time(5025.4)
	save_game.save()
	assert_eq(save_game.play_time_of(1), 5025)
	assert_eq(save_game.play_time_of(2), 0)
	var loaded := SaveGame.new(PREFIX)
	loaded.load_slot(1)
	assert_almost_eq(loaded.play_time, 5025.0, 0.001)


func test_play_time_text() -> void:
	assert_eq(SaveGame.play_time_text(5025), "1h 23m")
	assert_eq(SaveGame.play_time_text(59), "0m")
	assert_eq(SaveGame.play_time_text(600), "10m")


func test_clearing_act_1_puts_e_at_level_1_for_free() -> void:
	save_game.finish_stage(&"cleared", "1-1")
	assert_eq(save_game.tree.level(&"skill_e"), 1)
	assert_eq(save_game.essences.amount(Essences.BLUE), 0)


func test_e_is_given_only_when_act_1_becomes_cleared() -> void:
	save_game.finish_stage(&"cleared", "1-1")
	save_game.tree.clear()
	save_game.finish_stage(&"cleared", "2-1")
	assert_eq(save_game.tree.level(&"skill_e"), 0, "after a tree reset it is free to buy again, not given")


func test_losing_act_1_gives_nothing() -> void:
	save_game.finish_stage(&"failed", "1-1")
	assert_eq(save_game.tree.level(&"skill_e"), 0)


func test_debug_acts_cleared_gives_e_too() -> void:
	save_game.set_cleared(Journey.all_stage_ids(1))
	assert_eq(save_game.tree.level(&"skill_e"), 1)
