extends GutTest
## Endless mode in the stage: an EndlessRunner on the chosen map, enemies
## scaled by EndlessPlan, bosses at the boss point, repeat purple on boss
## kills, the merchant in breaks, the stage info, the best recorded as each
## wave is won, and the debug jumps.

## Enough frames for any wave: its groups, then splits and escapes.
const KILL_FRAMES := 120
## Journey.ENDLESS_MAPS choices.
const TRAINING_GROUND := 2
const JUNGLE := 3


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_endless_stage_save_slot_")


func after_each() -> void:
	get_tree().paused = false


## An Endless run on map `choice`, from a fresh save whose best is `best`
## and that has cleared the first `acts` acts; Lucian takes no damage.
func _endless(choice := JUNGLE, best := 0, acts := 0) -> Stage:
	SaveGame.instance().reset()
	SaveGame.instance().record_endless(best)
	SaveGame.instance().set_cleared(Journey.all_stage_ids(acts))
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_endless(SaveGame.instance(), choice, RandomNumberGenerator.new()))
	add_child_autofree(stage)
	await wait_process_frames(2)
	stage.lucian.invulnerable = true
	return stage


func _story(act: int, stage_number: int) -> Stage:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), act, stage_number))
	add_child_autofree(stage)
	await wait_process_frames(2)
	stage.lucian.invulnerable = true
	return stage


func _lethal() -> DamageInfo:
	return DamageInfo.create(999999.0, DamageInfo.Type.TRUE, &"test")


## Kills the wave until the runner has nobody left in it (groups still to
## come, splits, a unit on its way out). Fails the test if some are still
## left after KILL_FRAMES.
func _kill_wave(stage: Stage) -> void:
	for frame in KILL_FRAMES:
		if stage.runner.alive() == 0:
			return
		stage.runner.tick(WaveRunner.GROUP_GAP)
		for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
			enemy.take_damage(_lethal())
		await wait_physics_frames(1)
	if stage.runner.alive() > 0:
		fail_test("%d still in the wave after %d frames" % [stage.runner.alive(), KILL_FRAMES])


## _kill_wave sparing `keep`: until it is the only one left in the wave.
func _kill_all_but(stage: Stage, keep: Enemy) -> void:
	for frame in KILL_FRAMES:
		if stage.runner.alive() == 1:
			return
		stage.runner.tick(WaveRunner.GROUP_GAP)
		for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
			if enemy != keep:
				enemy.take_damage(_lethal())
		await wait_physics_frames(1)


## The unit of `id` on the map (the first one found), or null.
func _unit(id: StringName) -> EnemyUnit:
	for enemy: Node in get_tree().get_nodes_in_group(&"enemies"):
		if (enemy as EnemyUnit).data.id == id:
			return enemy
	return null


func _buttons(node: Node, text: String, into: Array[Button]) -> void:
	var button := node as Button
	if button and button.text == text and not button is OptionButton:
		into.append(button)
	for child in node.get_children():
		_buttons(child, text, into)


## The debug table's button with `text`.
func _debug_button(stage: Stage, text: String) -> Button:
	var found: Array[Button] = []
	_buttons(stage.debug_table, text, found)
	assert_eq(found.size(), 1, "button %s" % text)
	return found[0] if found.size() == 1 else null


func test_the_stage_runs_an_endless_runner_on_the_chosen_map() -> void:
	var stage: Stage = await _endless(JUNGLE)
	assert_is(stage.runner, EndlessRunner)
	assert_is(stage.arena, JungleMap)
	assert_not_null(stage.endless)
	assert_eq(stage.runner.wave, 0)
	assert_null(stage.merchant, "no merchant before wave 1")
	stage.skip_break()
	assert_eq(stage.runner.wave, 1)
	# Two whole packs can leave a wave up to 2 short (EndlessPlan).
	assert_between(stage.runner.alive(), EndlessPlan.normal_count(1) - 2, EndlessPlan.normal_count(1), "wave 1 is made up by EndlessPlan")
	assert_engine_error_count(0)


func test_a_story_stage_has_no_endless_director() -> void:
	var stage: Stage = await _story(2, 1)
	assert_null(stage.endless)
	assert_false(stage.runner is EndlessRunner)


func test_a_wave_1_melee_minion_has_its_base_hp_and_wave_20_follows_the_table() -> void:
	# Training ground is act 2's map: the story would give its minions ×1.6.
	var stage: Stage = await _endless(TRAINING_GROUND)
	var at := stage.arena.spawn_points[0]
	var first := stage.spawn_enemy(WavePlan.MELEE, at, 1)
	assert_almost_eq(first.max_hp, 240.0, 0.01)
	assert_almost_eq(first.hp, first.max_hp, 0.01)
	assert_almost_eq(first.damage, 12.0, 0.01)
	var twentieth := stage.spawn_enemy(WavePlan.MELEE, at, 20)
	assert_almost_eq(twentieth.max_hp, 240.0 * (1.0 + 0.06 * 19) * (1.0 + 0.05 * 19), 0.01)
	assert_almost_eq(twentieth.hp, twentieth.max_hp, 0.01)
	assert_almost_eq(twentieth.damage, 12.0 * (1.0 + 0.025 * 19) * (1.0 + 0.05 * 19), 0.01)
	assert_almost_eq(twentieth.skill_scale, 1.0, 0.0001)


func test_kills_pay_like_the_act_of_their_wave() -> void:
	var stage: Stage = await _endless(TRAINING_GROUND)
	var data: EnemyData = load(Stage.ENEMY_PATH % WavePlan.MELEE)
	var at := stage.arena.spawn_points[0]
	stage.spawn_enemy(WavePlan.MELEE, at, 1).take_damage(_lethal())
	assert_eq(stage.collected[Essences.BLUE], 1 + data.extra_blue, "wave 1 pays like act 1, not the map's act 2")
	var gold := roundi(data.gold * data.reward_scale(1))
	assert_eq(stage.wallet.gold, gold)
	stage.spawn_enemy(WavePlan.MELEE, at, 21).take_damage(_lethal())
	assert_eq(stage.collected[Essences.BLUE], 1 + 3 + 2 * data.extra_blue, "wave 21 pays like act 3")
	assert_eq(stage.wallet.gold, gold + roundi(data.gold * data.reward_scale(3)))


## P11: never less than the acts the save has cleared.
func test_kills_pay_at_least_like_the_acts_cleared() -> void:
	var stage: Stage = await _endless(TRAINING_GROUND, 0, 3)
	assert_eq(stage.run.acts_cleared, 3)
	var data: EnemyData = load(Stage.ENEMY_PATH % WavePlan.MELEE)
	var at := stage.arena.spawn_points[0]
	stage.spawn_enemy(WavePlan.MELEE, at, 1).take_damage(_lethal())
	assert_eq(stage.collected[Essences.BLUE], 3 + data.extra_blue, "wave 1 pays like act 3")
	var gold := roundi(data.gold * data.reward_scale(3))
	assert_eq(stage.wallet.gold, gold)
	stage.spawn_enemy(WavePlan.MELEE, at, 31).take_damage(_lethal())
	assert_eq(stage.collected[Essences.BLUE], 3 + 4 + 2 * data.extra_blue, "wave 31 pays like act 4")
	assert_eq(stage.wallet.gold, gold + roundi(data.gold * data.reward_scale(4)))


## The break after winning wave `waves` of the run (its count, as the best
## counts it).
func _win_wave(stage: Stage, waves: int) -> void:
	stage.runner._done = waves
	stage.runner.break_started.emit(WaveRunner.BREAK_TIME)


## P11: the first time the save wins wave 10, its 300 blue and 5 orange rise
## over Lucian, with a banner and a result line; never again.
func test_winning_wave_10_the_first_time_pays_its_milestone_once() -> void:
	var stage: Stage = await _endless()
	var save := SaveGame.instance()
	_win_wave(stage, 9)
	assert_eq(stage.collected[Essences.BLUE], 0, "no milestone at 9")
	_win_wave(stage, 10)
	assert_eq(save.endless_milestones, [10] as Array[int])
	assert_eq(save.endless_best, 10)
	assert_eq(stage.collected[Essences.BLUE], 300)
	assert_eq(stage.collected[Essences.ORANGE], 5)
	assert_eq(save.essences.amount(Essences.BLUE), 300, "in the save at once, as a kill's essence")
	assert_eq(save.essences.amount(Essences.ORANGE), 5)
	var line := "Wave 10 won for the first time: +300 blue and +5 orange essence"
	assert_eq(stage.reward_lines, [line] as Array[String])
	assert_eq(stage.hud.tips._queue, [line] as Array[String], "a banner")
	_win_wave(stage, 10)
	assert_eq(stage.collected[Essences.BLUE], 300, "paid once")
	_win_wave(stage, 20)
	assert_eq(stage.collected[Essences.BLUE], 900)
	assert_eq(stage.collected[Essences.ORANGE], 15)
	assert_eq(save.endless_milestones, [10, 20] as Array[int])
	stage.show_result(false)
	assert_eq(stage.reward_lines[-1], "New best: 20 waves!")
	assert_eq(stage.reward_lines.size(), 3, "both milestones on the result")


## A debug jump's skipped waves don't count: wave 10 reached by a jump is 1
## wave won.
func test_a_jump_to_wave_10_pays_no_milestone() -> void:
	var stage: Stage = await _endless()
	stage.jump_to_boss_wave()
	stage.runner.tick(0.1)
	stage.runner.tick(0.1)
	assert_eq(stage.runner.wave, 10)
	# The boss goes without a kill (no rewards), and the wave is won.
	for enemy: Node in get_tree().get_nodes_in_group(&"enemies"):
		enemy.remove_from_group(&"enemies")
		enemy.queue_free()
		stage.runner.enemy_died()
	assert_eq(stage.runner.state, WaveRunner.State.BREAK)
	assert_eq(stage.runner.waves_cleared, 1)
	assert_true(SaveGame.instance().endless_milestones.is_empty())
	assert_eq(stage.collected[Essences.BLUE], 0)


func test_a_tier_2_boss_kill_pays_130_blue_and_a_tier_1_boss_100() -> void:
	var stage: Stage = await _endless()
	var blue: int = stage.collected[Essences.BLUE]
	stage.runner.spawn_requested.emit(&"akshan", 10)
	_unit(&"akshan").take_damage(_lethal())
	assert_eq(stage.collected[Essences.BLUE], blue + 100, "tier 1")
	blue = stage.collected[Essences.BLUE]
	stage.runner.spawn_requested.emit(&"akshan", 20)
	_unit(&"akshan").take_damage(_lethal())
	assert_eq(stage.collected[Essences.BLUE], blue + 130, "tier 2")


func test_a_boss_comes_at_the_boss_point_with_its_waves_hp_and_scaled_skill_hits() -> void:
	var stage: Stage = await _endless()
	stage.runner.spawn_requested.emit(&"akshan", 20)
	var boss := _unit(&"akshan") as Boss
	assert_not_null(boss)
	assert_eq(boss.global_position, stage.arena.boss_point)
	# P9: 0.6 of the HP wave 19 brings (more than tier 2's 19500), and the
	# square root of the damage scale's growth since wave 10 (more than tier
	# 2's ×1.15).
	var power := EndlessPlan.boss_power(20)
	assert_almost_eq(power, 1.2725, 0.0001)
	assert_almost_eq(boss.max_hp, 0.6 * EndlessPlan.wave_hp(19, Journey.ENDLESS_ACT), 0.01, "the waves of Acts 1–3")
	assert_gt(boss.max_hp, 15000.0 * 1.3)
	assert_almost_eq(boss.hp, boss.max_hp, 0.01)
	assert_almost_eq(boss.skill_scale, power, 0.0001)
	assert_almost_eq(boss.damage, 28.0 * power, 0.01)
	assert_almost_eq(boss.skill_hit(100.0, DamageInfo.Type.PHYSICAL, &"test").amount, 100.0 * power, 0.01)
	assert_almost_eq(boss.make_hit().amount, 28.0 * power, 0.01)
	assert_null(stage.boss_unit, "never the stage's boss")


## P10: a save that has cleared Acts 1–3 meets only their enemies, and its
## bosses' HP follows their waves.
func test_a_run_draws_from_the_acts_the_save_has_cleared() -> void:
	var stage: Stage = await _endless(JUNGLE, 0, 3)
	var runner := stage.runner as EndlessRunner
	assert_eq(runner.acts, 3)
	stage.skip_break()
	assert_eq(runner.wave, 1)
	# Acts 1–3's normal enemies, a pack's members included.
	var normals := {}
	for entry in EndlessPlan.cleared_pool(EndlessPlan.NORMALS, 3):
		for member: StringName in WavePlan.PACKS.get(entry, [entry]):
			normals[member] = true
	assert_false(runner._to_spawn.is_empty())
	for id: StringName in runner._to_spawn:
		assert_true(normals.has(id), String(id))
	stage.runner.spawn_requested.emit(&"akshan", 20)
	assert_almost_eq(_unit(&"akshan").max_hp, EndlessPlan.boss_hp(20, 3), 0.01)
	stage.jump_to_boss_wave()
	runner.tick(0.1)
	assert_eq(runner.wave, 10)
	assert_has([&"akshan", &"elder_dragon"], runner._to_spawn[0])


## P10: an Act 5–6 boss hits ×0.8 at tier 1, ×0.9 at tier 2; its burns too.
func test_a_late_boss_deals_less_at_its_first_tiers() -> void:
	var stage: Stage = await _endless(JUNGLE, 0, 6)
	stage.runner.spawn_requested.emit(&"karthus", 10)
	var karthus := _unit(&"karthus") as Boss
	var power := EndlessPlan.boss_power(10) * 0.8
	assert_almost_eq(karthus.skill_scale, power, 0.0001)
	assert_almost_eq(karthus.damage, 80.0 * power, 0.01)
	assert_almost_eq(karthus.burn_scale, power, 0.0001)
	stage.runner.spawn_requested.emit(&"maokai", 15)
	assert_almost_eq(_unit(&"maokai").skill_scale, EndlessPlan.mini_boss_power(15) * 0.9, 0.0001)
	stage.runner.spawn_requested.emit(&"elise", 25)
	assert_almost_eq(_unit(&"elise").skill_scale, EndlessPlan.mini_boss_power(25), 0.0001, "all of it at tier 3")


func test_a_mini_boss_has_its_tiers_hp_and_power_and_keeps_its_spawn_point() -> void:
	var stage: Stage = await _endless()
	stage.runner.spawn_requested.emit(&"maokai", 15)
	var maokai := _unit(&"maokai") as Boss
	assert_not_null(maokai)
	assert_ne(maokai.global_position, stage.arena.boss_point)
	assert_almost_eq(maokai.max_hp, 9000.0 * 1.3, 0.01)
	# P10: an Act 5 mini boss deals ×0.9 of its power at tier 2.
	var power := EndlessPlan.mini_boss_power(15) * 0.9
	assert_almost_eq(EndlessPlan.mini_boss_power(15), 1.3186, 0.0001, "the square root of the damage scale's growth since wave 5, more than tier 2's ×1.15")
	assert_almost_eq(maokai.damage, 90.0 * power, 0.01)
	assert_almost_eq(maokai.skill_hit(100.0, DamageInfo.Type.MAGIC, &"test").amount, 100.0 * power, 0.01)


## Its burns follow its power (Fix B, B13): after P9, the square root of
## the damage scale's growth since wave 5, ×1.633 (tier 3 alone gave ×1.3).
func test_a_tier_3_endless_infernal_drake_burns_with_its_power() -> void:
	var stage: Stage = await _endless()
	stage.runner.spawn_requested.emit(&"infernal_drake", 25)
	var drake := _unit(&"infernal_drake") as InfernalDrake
	assert_not_null(drake)
	var power := EndlessPlan.mini_boss_power(25)
	assert_almost_eq(power, 1.633, 0.001)
	assert_almost_eq(drake.skill_scale, power, 0.0001)
	drake._burn_cone(Vector2.ZERO, Vector2.RIGHT)
	drake._burn_circle(Vector2(500, 0))
	var dps: Array = []
	for zone: Node in drake.warning_parent.get_children():
		if zone is HazardZone:
			dps.append(snappedf((zone as HazardZone).dps, 0.001))
	assert_eq(dps, [snappedf(30.0 * power, 0.001), snappedf(25.0 * power, 0.001)], "breath and meteor burns")
	drake.target = stage.lucian
	drake.apply_on_hit()
	assert_almost_eq(stage.lucian._burns.total_dps(), 10.0 * power, 0.001, "the fireball's burn")
	assert_almost_eq(drake.burn_scale, drake.skill_scale, 0.0001, "scaled once, by its power")


## The burn `unit`'s basic attack leaves on Lucian, per second.
func _hit_burn(stage: Stage, unit: EnemyUnit) -> float:
	stage.lucian._burns.clear()
	unit.target = stage.lucian
	unit.apply_on_hit()
	return stage.lucian._burns.total_dps()


func test_an_endless_gromp_s_burn_grows_with_its_hit() -> void:
	var stage: Stage = await _endless()
	var at := stage.arena.spawn_points[0]
	var first := stage.spawn_enemy(&"gromp", at, 1)
	assert_almost_eq(_hit_burn(stage, first), 6.0, 0.001, "wave 1: as listed")
	var fortieth := stage.spawn_enemy(&"gromp", at, 40)
	var growth := EndlessPlan.damage_scale(40)
	assert_almost_eq(fortieth.damage, 17.0 * growth, 0.01)
	assert_almost_eq(_hit_burn(stage, fortieth), 6.0 * growth, 0.001, "wave 40: as much more as its hit")


func test_an_endless_red_brambleback_s_burn_grows_with_its_wave() -> void:
	var stage: Stage = await _endless()
	var at := stage.arena.spawn_points[0]
	var red := stage.spawn_enemy(WavePlan.RED_BRAMBLEBACK, at, 20)
	assert_almost_eq(_hit_burn(stage, red), 8.0 * EndlessPlan.damage_scale(20), 0.001)


func test_a_story_gromp_keeps_its_listed_burn() -> void:
	var stage: Stage = await _story(3, 1)
	var gromp := stage.spawn_enemy(&"gromp", stage.arena.spawn_points[0], 3)
	assert_gt(gromp.damage, 17.0, "its hit grows with the act and wave")
	assert_almost_eq(_hit_burn(stage, gromp), 6.0, 0.001, "its burn doesn't")


func test_a_story_boss_keeps_its_hp_and_skill_hits() -> void:
	var stage: Stage = await _story(2, 1)
	var akshan := stage.spawn_enemy(&"akshan", stage.arena.boss_point) as Boss
	assert_almost_eq(akshan.max_hp, 5000.0, 0.01)
	assert_almost_eq(akshan.skill_hit(100.0, DamageInfo.Type.PHYSICAL, &"test").amount, 100.0, 0.01)


func test_a_boss_kill_pays_repeat_purple_and_leaves_the_saves_bosses_alone() -> void:
	var stage: Stage = await _endless()
	var save := SaveGame.instance()
	stage.runner.spawn_requested.emit(&"akshan", 10)
	_unit(&"akshan").take_damage(_lethal())
	assert_eq(stage.collected[Essences.PURPLE], 2, "Akshan's repeat purple, on the kill")
	assert_eq(save.essences.amount(Essences.PURPLE), 2)
	assert_true(save.bosses.is_empty())
	stage.runner.spawn_requested.emit(&"maokai", 5)
	_unit(&"maokai").take_damage(_lethal())
	assert_eq(stage.collected[Essences.PURPLE], 3, "Maokai's repeat purple, never the first-time 5")
	assert_true(save.bosses.is_empty())
	stage.run.purple_mult = 1.5
	stage.runner.spawn_requested.emit(&"akshan", 20)
	_unit(&"akshan").take_damage(_lethal())
	assert_eq(stage.collected[Essences.PURPLE], 6, "× the modifier's purple")
	assert_true(stage.reward_lines.is_empty())


func test_final_thresh_falls_with_repeat_purple_and_no_cutscene_and_the_run_goes_on() -> void:
	var stage: Stage = await _endless()
	stage.skip_break()
	for i in 20:
		stage.runner.tick(WaveRunner.GROUP_GAP)
	stage.runner.spawn_requested.emit(&"thresh_final", 1)
	stage.runner.enemy_spawned()
	var thresh := _unit(&"thresh_final") as ThreshFinal
	assert_eq(thresh.global_position, stage.arena.boss_point)
	assert_almost_eq(thresh.max_hp, 15000.0, 0.01)
	thresh._attack_left = 1000.0
	thresh.move_speed = 0.0
	await _kill_all_but(stage, thresh)
	assert_eq(stage.runner.alive(), 1)
	await wait_physics_frames(1)
	thresh.take_damage(_lethal())
	await wait_physics_frames(2)
	assert_eq(thresh.phase, 2)
	assert_almost_eq(thresh.hp, 15000.0, 0.01, "Phase 2 has the wave's boss HP too")
	thresh._rise_left = 0.0
	await wait_physics_frames(1)
	var blue: int = stage.collected[Essences.BLUE]
	thresh.take_damage(_lethal())
	await wait_physics_frames(3)
	assert_null(stage.cutscene)
	assert_false(is_instance_valid(thresh))
	assert_eq(stage.collected[Essences.PURPLE], 4, "his repeat purple")
	assert_eq(stage.collected[Essences.BLUE], blue + KillRewards.BOSS_BLUE)
	assert_true(SaveGame.instance().bosses.is_empty())
	assert_false(stage.result.visible)
	assert_eq(stage.runner.state, WaveRunner.State.BREAK, "the run goes on")
	assert_eq(stage.runner.waves_done(), 1)
	assert_engine_error_count(0)


## Ruling (Task 6 review): an Endless final Thresh's fall counts as a kill
## and pays like the other bosses' kills: gold, XP and a loot roll.
func test_final_thresh_s_fall_counts_as_a_kill_with_gold_xp_and_loot() -> void:
	var stage: Stage = await _endless()
	stage.skip_break()
	stage.runner.spawn_requested.emit(&"thresh_final", 1)
	stage.runner.enemy_spawned()
	var thresh := _unit(&"thresh_final") as ThreshFinal
	# A copy with some XP (no boss has any), so the XP shows.
	thresh.data = thresh.data.duplicate() as EnemyData
	thresh.data.xp = 50
	var kills := stage.stats.kills
	var loot := _loot(stage).size()
	thresh.fell.emit(thresh)
	await wait_physics_frames(2)
	assert_false(is_instance_valid(thresh))
	assert_eq(stage.stats.kills, kills + 1)
	assert_eq(stage.wallet.gold, 300, "a boss's gold")
	assert_eq(stage.stats.gold_earned, 300)
	assert_eq(stage.lucian.progress.xp, 50)
	assert_gt(_loot(stage).size(), loot, "a boss always drops a fragment")
	assert_eq(stage.collected[Essences.PURPLE], 4, "and his repeat purple")


func _loot(stage: Stage) -> Array[Node]:
	return stage.get_node("World").get_children().filter(func(node: Node) -> bool: return node is LootDrop)


## The result's stats rows as [label, value] texts, in order.
func _result_rows(stage: Stage) -> Array:
	var rows := []
	for row: Node in stage.result._stats.get_children():
		if not row.is_queued_for_deletion():
			rows.append([(row.get_child(0) as Label).text, (row.get_child(1) as Label).text])
	return rows


func _row_names(stage: Stage) -> Array:
	return _result_rows(stage).map(func(row: Array) -> String: return row[0])


func test_dying_shows_run_over_with_the_waves_cleared_and_a_new_best() -> void:
	var stage: Stage = await _endless()
	stage.skip_break()
	await _kill_wave(stage)
	stage.lucian.invulnerable = false
	stage.lucian.take_damage(_lethal())
	# Frames, not seconds: the result pauses the tree, and GUT's timer with it.
	var give_up := Time.get_ticks_msec() + int((Lucian.DEATH_FADE + 3.0) * 1000.0)
	while not stage.result.visible and Time.get_ticks_msec() < give_up:
		await wait_process_frames(1)
	assert_true(stage.result.visible)
	assert_eq(stage.result.title.text, "RUN OVER")
	assert_eq(stage.result._stage_label.text, "Endless · Jungle")
	assert_eq(_row_names(stage), ["Waves cleared", "Time", "Kills", "Damage dealt", "Damage taken", "Gold earned", "Level reached", "Modifier"])
	assert_eq(_result_rows(stage)[0], ["Waves cleared", "1"])
	assert_eq(_result_rows(stage)[-1], ["Modifier", "None"], "nothing picked yet")
	assert_eq(stage.reward_lines, ["New best: 1 wave!"] as Array[String])
	assert_true(stage.result.retry_button.visible)
	assert_false(stage.result.next_button.visible)
	assert_eq(stage.result.main_button.text, "Main screen")
	watch_signals(stage)
	stage.result.retry_button.pressed.emit()
	assert_signal_emitted_with_parameters(stage, "finished", [&"failed", &"retry"])


## The save's best rises as each wave is won; "New best" compares with the
## best the run started with.
func test_new_best_beats_the_best_the_run_started_with() -> void:
	var stage: Stage = await _endless(JUNGLE, 1)
	for i in 2:
		stage.skip_break()
		await _kill_wave(stage)
	assert_eq(SaveGame.instance().endless_best, 2)
	stage.show_result(false)
	assert_eq(stage.reward_lines, ["New best: 2 waves!"] as Array[String])


func test_no_new_best_when_the_run_is_not_better() -> void:
	var stage: Stage = await _endless(JUNGLE, 1)
	stage.skip_break()
	await _kill_wave(stage)
	stage.show_result(false)
	assert_eq(_result_rows(stage)[0], ["Waves cleared", "1"])
	assert_true(stage.reward_lines.is_empty(), "equal is no new best")


func test_the_modifier_row_reads_its_downside_and_none_after_nothing() -> void:
	var stage: Stage = await _endless()
	stage.endless.choose(3)
	stage.show_result(false)
	assert_eq(_result_rows(stage)[-1], ["Modifier", "−10% max HP"])
	get_tree().paused = false
	var again: Stage = await _endless()
	again.endless.choose(3)
	again.endless.choose(EndlessModifiers.NOTHING)
	again.show_result(false)
	assert_eq(_result_rows(again)[-1], ["Modifier", "None"])
	assert_false("Waves" in _row_names(again), "no story waves row")


func test_the_story_result_keeps_its_waves_row() -> void:
	var stage: Stage = await _story(2, 1)
	stage.show_result(false)
	assert_eq(_result_rows(stage)[1], ["Waves", "0 / 2"])
	assert_false("Modifier" in _row_names(stage))
	assert_eq(stage.result.title.text, "DEFEATED")


func test_the_merchant_comes_in_breaks() -> void:
	var stage: Stage = await _endless()
	stage.skip_break()
	await _kill_wave(stage)
	await wait_process_frames(1)
	assert_eq(stage.runner.state, WaveRunner.State.BREAK)
	assert_not_null(stage.merchant)
	stage.skip_break()
	await wait_process_frames(1)
	assert_null(stage.merchant)
	assert_eq(stage.runner.wave, 2)
	assert_engine_error_count(0)


func test_clearing_a_wave_records_the_best_in_memory() -> void:
	var stage: Stage = await _endless()
	var save := SaveGame.instance()
	assert_eq(save.endless_best, 0)
	stage.skip_break()
	await _kill_wave(stage)
	assert_eq(save.endless_best, 1)
	stage.skip_break()
	await _kill_wave(stage)
	assert_eq(save.endless_best, 2)
	assert_eq(stage.runner.waves_cleared, 2)


func test_clearing_a_wave_never_lowers_the_best() -> void:
	var stage: Stage = await _endless()
	SaveGame.instance().record_endless(5)
	stage.skip_break()
	await _kill_wave(stage)
	assert_eq(SaveGame.instance().endless_best, 5)


func test_the_stage_info_reads_endless_waves_and_the_best() -> void:
	SaveGame.instance().reset()
	SaveGame.instance().record_endless(3)
	var runner := EndlessRunner.new(1)
	var info := StageInfo.new()
	add_child_autofree(info)
	info.setup("Endless · Jungle", runner)
	assert_true(info.best_label.visible)
	assert_eq(info.best_label.text, "Best 3")
	assert_false(info.pips.visible, "no pips: its waves never end")
	assert_eq(info.timer_label.text, "Wave 1 in 0:05")
	runner.state = WaveRunner.State.FIGHT
	runner.wave = 7
	info.refresh()
	assert_eq(info.wave_label.text, "Wave 7")
	runner.wave = 5
	info.refresh()
	assert_eq(info.wave_label.text, "Mini boss wave")
	runner.wave = 10
	info.refresh()
	assert_eq(info.wave_label.text, "Boss wave")
	runner.state = WaveRunner.State.BREAK
	runner.wave = 23
	info.refresh()
	assert_eq(info.timer_label.text, "Wave 24 in 0:05")
	runner.wave = 19
	info.refresh()
	assert_eq(info.timer_label.text, "Boss wave in 0:05")
	SaveGame.instance().record_endless(4)
	info.refresh()
	assert_eq(info.best_label.text, "Best 4")


func test_the_story_stage_info_has_no_best_line() -> void:
	var info := StageInfo.new()
	add_child_autofree(info)
	info.setup("Stage 2-2 · The Sentinels", WaveRunner.new(WavePlan.waves("2-2")))
	assert_false(info.best_label.visible)


## The boss bar shows while a boss lives: in a wave, under the stage info
## and its "Best" line.
func test_the_boss_bar_sits_under_the_endless_stage_info() -> void:
	var stage: Stage = await _endless()
	stage.skip_break()
	await wait_process_frames(2)
	var info := stage.hud.stage_info
	assert_true(info.best_label.visible)
	assert_gte(stage.hud.boss_bar.get_global_rect().position.y, info.get_global_rect().end.y)


func test_jump_to_boss_wave_reaches_the_next_tenth_wave() -> void:
	var stage: Stage = await _endless()
	stage.skip_break()
	_debug_button(stage, "Jump to boss wave").pressed.emit()
	stage.runner.tick(0.1)
	assert_eq(stage.runner.wave, 10)
	assert_true(stage.runner.is_boss_wave())
	stage.runner.tick(0.1)
	var bosses := get_tree().get_nodes_in_group(&"enemies").filter(func(enemy: EnemyUnit) -> bool: return enemy.data.kind == &"boss")
	assert_eq(bosses.size(), 1)
	assert_eq((bosses[0] as EnemyUnit).global_position, stage.arena.boss_point)
	_debug_button(stage, "Jump to boss wave").pressed.emit()
	stage.runner.tick(0.1)
	assert_eq(stage.runner.wave, 20)
	assert_engine_error_count(0)


func test_jump_to_boss_wave_lets_a_held_break_go() -> void:
	var stage: Stage = await _endless()
	var runner := stage.runner as EndlessRunner
	stage.jump_to_boss_wave()
	runner.tick(0.1)
	runner.held = true
	stage.jump_to_boss_wave()
	runner.tick(0.1)
	assert_false(runner.held)
	assert_eq(runner.wave, 20)


func test_the_last_wave_jump_is_hidden_and_does_nothing_in_endless() -> void:
	var stage: Stage = await _endless()
	assert_false(_debug_button(stage, "Jump to the last wave").visible)
	stage.skip_break()
	stage.runner.tick(WaveRunner.GROUP_GAP)
	var enemies := get_tree().get_nodes_in_group(&"enemies").size()
	assert_gt(enemies, 0)
	stage.jump_to_last_wave()
	assert_eq(get_tree().get_nodes_in_group(&"enemies").size(), enemies, "nothing removed")
	assert_eq(stage.runner.wave, 1)


func test_the_last_wave_jump_shows_in_the_story() -> void:
	var stage: Stage = await _story(2, 1)
	assert_true(_debug_button(stage, "Jump to the last wave").visible)


func test_the_debug_wave_line_has_no_last_wave_in_endless() -> void:
	var stage: Stage = await _endless()
	stage.skip_break()
	stage.debug_table.visible = true
	await wait_process_frames(1)
	var texts: Array[String] = []
	_label_texts(stage.debug_table, texts)
	assert_true(texts.any(func(text: String) -> bool: return text.begins_with("Wave 1 (Endless)")), str(texts))


func _label_texts(node: Node, into: Array[String]) -> void:
	if node is Label:
		into.append((node as Label).text)
	for child in node.get_children():
		_label_texts(child, into)
