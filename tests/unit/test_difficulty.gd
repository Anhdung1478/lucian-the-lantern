extends GutTest
## V1.3's difficulty: Easy ×0.8, Normal ×1.0, Hard ×1.1, Extreme ×1.3 on
## every enemy's HP and on all the damage Lucian takes, blue ×1.2 and ×1.5
## on Hard and Extreme, kept in the save.

const PREFIX := "user://test_difficulty_slot_"


func before_each() -> void:
	_delete_all()
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_difficulty_stage_slot_")


func after_each() -> void:
	get_tree().paused = false
	_delete_all()


func _delete_all() -> void:
	var probe := SaveGame.new(PREFIX)
	for n in range(1, SaveGame.SLOTS + 1):
		for file in [probe.path(n), probe.backup_path(n)]:
			if FileAccess.file_exists(file):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


func _stage(level: int, act: int, stage_number: int) -> Stage:
	var save := SaveGame.instance()
	save.reset()
	save.difficulty = level
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(save, act, stage_number))
	add_child_autofree(stage)
	await wait_process_frames(2)
	return stage


# --- The levels ----------------------------------------------------------------


func test_four_levels_with_their_numbers() -> void:
	assert_eq(Difficulty.LEVELS.map(func(level: int) -> String: return Difficulty.name_of(level)), ["Easy", "Normal", "Hard", "Extreme"])
	assert_eq(Difficulty.LEVELS.map(func(level: int) -> float: return Difficulty.scale(level)), [0.8, 1.0, 1.1, 1.3])
	assert_eq(Difficulty.LEVELS.map(func(level: int) -> String: return Difficulty.scale_text(level)), ["×0.8", "×1.0", "×1.1", "×1.3"])
	assert_eq(Difficulty.LEVELS.map(func(level: int) -> float: return Difficulty.essence_scale(level)), [1.0, 1.0, 1.2, 1.5])
	assert_eq(Difficulty.describe(Difficulty.EASY), "Enemies have 80% HP and deal 80% damage.")
	assert_eq(Difficulty.describe(Difficulty.HARD), "Enemies have 110% HP and deal 110% damage. Blue and orange essence ×1.2.")
	assert_eq(Difficulty.describe(Difficulty.EXTREME), "Enemies have 130% HP and deal 130% damage. Blue and orange essence ×1.5.")


func test_an_unknown_level_or_key_is_normal() -> void:
	assert_eq(Difficulty.scale(7), 1.0)
	assert_eq(Difficulty.essence_scale(-1), 1.0)
	assert_eq(Difficulty.name_of(-1), "Normal")
	assert_eq(Difficulty.from_key("extreme"), Difficulty.EXTREME)
	for key: Variant in ["", "nightmare", 3, null]:
		assert_eq(Difficulty.from_key(key), Difficulty.NORMAL, str(key))


# --- The save --------------------------------------------------------------------


func test_a_new_game_is_normal_unless_another_is_picked() -> void:
	var save := SaveGame.new(PREFIX)
	assert_eq(save.difficulty, Difficulty.NORMAL)
	assert_true(save.start_new(1))
	assert_eq(save.difficulty, Difficulty.NORMAL)
	assert_true(save.start_new(2, Difficulty.EXTREME))
	assert_eq(save.difficulty, Difficulty.EXTREME)
	save.reset()
	assert_eq(save.difficulty, Difficulty.NORMAL, "a reset is a new game")


func test_the_difficulty_is_saved_and_loaded() -> void:
	var save := SaveGame.new(PREFIX)
	save.start_new(2, Difficulty.HARD)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save.path(2)))
	assert_eq(data.difficulty, "hard", "written as a word")
	var loaded := SaveGame.new(PREFIX)
	loaded.load_slot(2)
	assert_eq(loaded.difficulty, Difficulty.HARD)
	loaded.load_slot(1)
	assert_eq(loaded.difficulty, Difficulty.NORMAL, "an empty slot is a new game")


func test_a_save_from_before_difficulties_or_a_broken_one_plays_on_normal() -> void:
	var save := SaveGame.new(PREFIX)
	for value: Variant in [null, "nightmare", 2]:
		var data := save.to_dict()
		if value == null:
			data.erase("difficulty")
		else:
			data.difficulty = value
		var file := FileAccess.open(save.path(1), FileAccess.WRITE)
		file.store_string(JSON.stringify(data))
		file.close()
		var loaded := SaveGame.new(PREFIX)
		loaded.difficulty = Difficulty.EASY
		loaded.load_slot(1)
		assert_eq(loaded.difficulty, Difficulty.NORMAL, str(value))


func test_every_kind_of_run_takes_the_saves_difficulty() -> void:
	var save := SaveGame.new(PREFIX)
	save.difficulty = Difficulty.HARD
	assert_eq(StageSetup.new().difficulty, Difficulty.NORMAL, "the sandbox")
	assert_eq(StageSetup.from_save(save).difficulty, Difficulty.HARD, "Training")
	assert_eq(StageSetup.for_stage(save, 1, 1).difficulty, Difficulty.HARD, "the tutorial too")
	assert_eq(StageSetup.for_stage(save, 4, 2).difficulty, Difficulty.HARD)
	assert_eq(StageSetup.for_endless(save, 2, RandomNumberGenerator.new()).difficulty, Difficulty.HARD)


# --- In a stage ------------------------------------------------------------------


func test_every_enemy_has_its_hp_scaled_bosses_too() -> void:
	for level in [Difficulty.EASY, Difficulty.EXTREME]:
		var stage: Stage = await _stage(level, 2, 2)
		var scale := Difficulty.scale(level)
		var minion := stage.spawn_enemy(&"melee_minion", Vector2(300, 300), 2)
		assert_almost_eq(minion.max_hp, minion.data.max_hp * minion.data.hp_scale(2, 2) * WavePlan.hp_share("2-2", minion.data.id) * scale, 0.01, "a minion on %s" % Difficulty.name_of(level))
		assert_almost_eq(minion.hp, minion.max_hp, 0.01, "full HP")
		var boss := stage.spawn_enemy(&"akshan", Vector2(700, 300))
		assert_almost_eq(boss.max_hp, boss.data.max_hp * scale, 0.01, "Akshan on %s" % Difficulty.name_of(level))
		assert_almost_eq(minion.damage, minion.data.damage * minion.data.damage_scale(2, 2), 0.001, "the damage is on Lucian's side")
		stage.queue_free()
		await wait_process_frames(1)


func test_lucian_takes_the_difficultys_share_of_every_hit() -> void:
	for level in Difficulty.LEVELS:
		var stage: Stage = await _stage(level, 2, 2)
		var lucian := stage.lucian
		assert_eq(lucian.damage_taken_scale, Difficulty.scale(level))
		var before := lucian.hp
		lucian.take_damage(DamageInfo.create(100.0, DamageInfo.Type.TRUE, &"test"))
		assert_almost_eq(before - lucian.hp, 100.0 * Difficulty.scale(level), 0.01, Difficulty.name_of(level))
		stage.queue_free()
		await wait_process_frames(1)


func test_hard_and_extreme_pay_more_blue_and_orange_and_the_same_gold_and_xp() -> void:
	var data: EnemyData = load("res://data/enemies/siege_minion.tres")
	var rng := RandomNumberGenerator.new()
	var normal := StageSetup.new()
	for level in Difficulty.LEVELS:
		var run := StageSetup.new()
		run.difficulty = level
		rng.seed = 7
		var reward := KillRewards.roll(data, 4, run, rng)
		rng.seed = 7
		var base := KillRewards.roll(data, 4, normal, rng)
		assert_eq(reward.blue, roundi(base.blue * Difficulty.essence_scale(level)), Difficulty.name_of(level))
		assert_eq([reward.gold, reward.xp], [base.gold, base.xp], Difficulty.name_of(level))
		assert_almost_eq(KillRewards.orange_chance(data.kind, 4, run), KillRewards.orange_chance(data.kind, 4, normal) * Difficulty.essence_scale(level),
			0.00001, "the orange chance on %s" % Difficulty.name_of(level))
	var hard := StageSetup.new()
	hard.difficulty = Difficulty.HARD
	hard.blue_mult = 1.15
	assert_eq(KillRewards.roll(data, 4, hard, rng).blue, roundi(20 * 1.15 * 1.2), "on top of an Endless modifier")


## V1.5 (P8): a boss's 5 and a mini boss's 3 sure orange, and the data's
## extra (the Rift Scuttler's 4), × the essence scale, rounded.
func test_hard_and_extreme_raise_a_boss_s_and_a_mini_boss_s_sure_orange() -> void:
	var rng := RandomNumberGenerator.new()
	var boss: EnemyData = load("res://data/enemies/akshan.tres")
	var mini_boss: EnemyData = load("res://data/enemies/infernal_drake.tres")
	var scuttler: EnemyData = load("res://data/enemies/rift_scuttler.tres")
	var expected := {Difficulty.EASY: [5, 3, 4], Difficulty.NORMAL: [5, 3, 4], Difficulty.HARD: [6, 4, 5], Difficulty.EXTREME: [8, 5, 6]}
	for level: int in expected:
		var run := StageSetup.new()
		run.difficulty = level
		run.orange_mult = 0.0
		var got := [KillRewards.roll(boss, 2, run, rng).orange, KillRewards.roll(mini_boss, 3, run, rng).orange,
			KillRewards.roll(scuttler, 3, run, rng).orange]
		assert_eq(got, expected[level], Difficulty.name_of(level))


func test_the_essence_scale_stacks_with_an_endless_boss_tier() -> void:
	var run := StageSetup.new()
	run.difficulty = Difficulty.EXTREME
	var boss: EnemyData = load("res://data/enemies/akshan.tres")
	assert_eq(KillRewards.roll(boss, 2, run, RandomNumberGenerator.new(), false, 1.3).orange, roundi(5 * 1.3 * 1.5), "9.75")


func test_armor_lowers_the_scaled_hit() -> void:
	var stage: Stage = await _stage(Difficulty.HARD, 2, 2)
	var lucian := stage.lucian
	var before := lucian.hp
	lucian.take_damage(DamageInfo.create(100.0, DamageInfo.Type.PHYSICAL, &"test"))
	var expected := DamageCalc.mitigate(110.0, DamageInfo.Type.PHYSICAL, lucian.stats.armor, lucian.stats.mr, 0.0, 0.0)
	assert_almost_eq(before - lucian.hp, expected, 0.01)
