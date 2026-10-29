extends GutTest

var spawned: Array[StringName] = []


func _runner(waves: Array, boss := &"") -> WaveRunner:
	spawned.clear()
	var runner := WaveRunner.new(waves, boss)
	runner.spawn_requested.connect(func(id: StringName, _wave: int) -> void: spawned.append(id))
	return runner


## Ticks until every enemy of the wave has been asked for.
func _spawn_all(runner: WaveRunner) -> void:
	for i in 50:
		runner.tick(WaveRunner.GROUP_GAP)


func _kill_all(runner: WaveRunner) -> void:
	for i in spawned.size():
		runner.enemy_died()
	spawned.clear()


func test_a_countdown_then_wave_1_in_groups_of_3() -> void:
	var runner := _runner(WavePlan.waves("1-1"))
	runner.tick(WaveRunner.INTRO_TIME - 0.1)
	assert_true(spawned.is_empty())
	runner.tick(0.2)
	runner.tick(0.01)
	assert_eq(spawned.size(), WaveRunner.GROUP_SIZE)
	_spawn_all(runner)
	assert_eq(spawned.size(), 10)
	assert_eq(spawned.count(WavePlan.MELEE), 6)


func test_the_break_waits_for_the_last_enemy() -> void:
	var runner := _runner(WavePlan.waves("1-1"))
	runner.skip()
	_spawn_all(runner)
	for i in 9:
		runner.enemy_died()
	assert_eq(runner.state, WaveRunner.State.FIGHT)
	runner.enemy_died()
	assert_eq(runner.state, WaveRunner.State.BREAK)
	assert_almost_eq(runner.countdown(), WaveRunner.BREAK_TIME, 0.001)


func test_skip_returns_the_time_left() -> void:
	var runner := _runner(WavePlan.waves("2-1"))
	runner.tick(1.5)
	assert_almost_eq(runner.skip(), WaveRunner.INTRO_TIME - 1.5, 0.001)
	assert_eq(runner.state, WaveRunner.State.FIGHT)
	assert_eq(runner.skip(), 0.0)


func test_the_boss_wave_comes_last_only_with_a_boss() -> void:
	var runner := _runner(WavePlan.waves("2-3"), &"akshan")
	watch_signals(runner)
	for wave in 3:
		runner.skip()
		_spawn_all(runner)
		_kill_all(runner)
	assert_signal_not_emitted(runner, "cleared")
	runner.skip()
	_spawn_all(runner)
	assert_true(runner.is_boss_wave())
	assert_eq(spawned, [&"akshan"] as Array[StringName])
	_kill_all(runner)
	assert_signal_emit_count(runner, "cleared", 1)
	assert_eq(runner.waves_done(), 4)


func test_without_a_boss_the_last_wave_clears_it() -> void:
	var runner := _runner(WavePlan.waves("2-1"))
	watch_signals(runner)
	for wave in 2:
		runner.skip()
		_spawn_all(runner)
		_kill_all(runner)
	assert_signal_emit_count(runner, "cleared", 1)
	assert_eq(runner.state, WaveRunner.State.DONE)


func test_finish_ends_it_once() -> void:
	var runner := _runner(WavePlan.waves("1-1"), &"thresh_1")
	watch_signals(runner)
	runner.finish()
	runner.finish()
	assert_signal_emit_count(runner, "cleared", 1)


func test_the_last_enemy_is_the_last_of_the_last_wave() -> void:
	var runner := _runner(WavePlan.waves("2-1"))
	runner.skip()
	_spawn_all(runner)
	for i in spawned.size() - 1:
		runner.enemy_died()
	assert_false(runner.is_last_enemy(), "wave 1 of 2")
	runner.enemy_died()
	spawned.clear()
	runner.skip()
	_spawn_all(runner)
	for i in spawned.size() - 2:
		runner.enemy_died()
	assert_false(runner.is_last_enemy(), "two left")
	runner.enemy_died()
	assert_true(runner.is_last_enemy())
	runner.enemy_died()
	assert_false(runner.is_last_enemy(), "done")


## Phase 8: a summon is counted the moment it is asked for, so its
## summoner's death (even as the last of the wave) never ends the wave.
func test_a_summon_counted_at_the_request_keeps_the_wave_open() -> void:
	var runner := _runner([[WavePlan.MELEE]])
	runner.skip()
	_spawn_all(runner)
	assert_true(runner.is_last_enemy(), "the summoner, alone")
	runner.enemy_spawned()
	assert_false(runner.is_last_enemy(), "its summon on the way")
	runner.enemy_died()
	assert_eq(runner.state, WaveRunner.State.FIGHT, "the summoner's death")
	assert_eq(runner.alive(), 1)
	assert_true(runner.is_last_enemy())
	watch_signals(runner)
	runner.enemy_died()
	assert_signal_emitted(runner, "cleared", "the summon's death ends it")


func test_the_packs() -> void:
	assert_eq(WavePlan.PACKS[&"raptors"], [&"raptor_big", &"raptor", &"raptor", &"raptor", &"raptor"])
	assert_eq(WavePlan.PACKS[&"wolves"], [&"murkwolf_big", &"murkwolf", &"murkwolf"])
	assert_eq(WavePlan.PACKS[&"krugs"], [&"krug_big", &"krug", &"krug"])
	assert_eq(WavePlan.PACKS[&"gromp"], [&"gromp"])


func test_a_pack_expands_into_its_members_in_order() -> void:
	var waves := WavePlan.expand([[[&"krugs", 2], [WavePlan.MELEE, 1]], [[&"gromp", 1], [&"wolves", 1]]])
	assert_eq(waves.size(), 2)
	assert_eq(Array(waves[0]), [&"krug_big", &"krug", &"krug", &"krug_big", &"krug", &"krug", WavePlan.MELEE])
	assert_eq(Array(waves[1]), [&"gromp", &"murkwolf_big", &"murkwolf", &"murkwolf"])


func test_a_packs_members_spawn_in_groups_of_3_in_order() -> void:
	var runner := _runner(WavePlan.expand([[[&"raptors", 1]]]))
	runner.skip()
	runner.tick(0.01)
	assert_eq(spawned, [&"raptor_big", &"raptor", &"raptor"] as Array[StringName])
	_spawn_all(runner)
	assert_eq(spawned.size(), 5)
	assert_eq(runner.alive(), 5)


func test_waves_without_packs_are_unchanged() -> void:
	assert_eq(WavePlan.waves("1-1"), WavePlan.expand(WavePlan.STAGES["1-1"]))
	assert_eq(WavePlan.waves("1-1")[0].size(), 10)


## Act 3's waves as the design's table writes them: R raptors, W wolves,
## K krugs, G gromp; B Blue, D Red (Brambleback), S the Scuttler. The table
## names a stage's mini boss apart: one, last in the last wave.
func test_act_3_waves_follow_the_table() -> void:
	var letters := {&"raptors": "R", &"wolves": "W", &"krugs": "K", &"gromp": "G",
		WavePlan.BLUE_SENTINEL: "B", WavePlan.RED_BRAMBLEBACK: "D", WavePlan.SCUTTLER: "S"}
	var table := {
		"3-1": "R W · R R G B · W K G D S",
		"3-2": "R W G · R K W B · W K G D S · R W K G",
		"3-3": "R R W G · K W G B · R W K D S · R R W K G B",
		"3-4": "R W G K · R W K B · W K G D S · R R K G B · R W K G D",
		"3-5": "R W K G · R R W B · W K G D S · R W K G B · R R W K D S",
	}
	var mini_bosses := {"3-2": WavePlan.INFERNAL_DRAKE, "3-4": WavePlan.OCEAN_DRAKE}
	for id: String in table:
		assert_true(WavePlan.has_stage(id), id)
		var plan: Array = WavePlan.STAGES.get(id, [])
		var mini_boss: StringName = mini_bosses.get(id, &"")
		var waves: Array[String] = []
		for wave: Array in plan:
			var written: Array[String] = []
			for group: Array in wave:
				if group[0] == mini_boss:
					continue
				for i in group[1]:
					written.append(letters.get(group[0], "?"))
			waves.append(" ".join(written))
		assert_eq(" · ".join(waves), table[id], id)
		if mini_boss != &"" and not plan.is_empty():
			assert_eq(plan.back().back(), [mini_boss, 1], "%s: its mini boss, last in the last wave" % id)
		assert_eq(WavePlan.waves(id).size(), Journey.waves(3, id.right(1).to_int()), "%s: the Journey's wave count" % id)


func test_every_act_3_enemy_has_its_data() -> void:
	for stage in range(1, 6):
		for wave: Array in WavePlan.waves(Journey.stage_id(3, stage)):
			for id: StringName in wave:
				assert_true(ResourceLoader.exists(Stage.ENEMY_PATH % id), String(id))


## Act 4's waves as the design's table writes them: m shadow melee, r shadow
## ranged, S shadow siege, U shadow super. Dark Lucian follows 4-3's last wave.
func test_act_4_waves_follow_the_table() -> void:
	var letters := {WavePlan.SHADOW_MELEE: "m", WavePlan.SHADOW_RANGED: "r", WavePlan.SHADOW_SIEGE: "S", WavePlan.SHADOW_SUPER: "U"}
	var table := {
		"4-1": "8m 6r 1S · 8m 6r 2S · 8m 8r 1S 1U · 10m 8r 2S 1U",
		"4-2": "8m 6r 2S · 8m 8r 1S 1U · 10m 8r 2S 1U · 10m 10r 2S 1U · 10m 10r 3S 1U",
		"4-3": "8m 8r 1S 1U · 10m 8r 2S 1U · 10m 10r 2S 1U · 10m 10r 3S 1U · 12m 10r 2S 2U",
	}
	for id: String in table:
		assert_true(WavePlan.has_stage(id), id)
		var waves: Array[String] = []
		for wave: Array in WavePlan.waves(id):
			var counts := {}
			for enemy: StringName in wave:
				counts[letters.get(enemy, "?")] = counts.get(letters.get(enemy, "?"), 0) + 1
			var written: Array[String] = []
			for letter: String in ["m", "r", "S", "U"]:
				if counts.has(letter):
					written.append("%d%s" % [counts[letter], letter])
			waves.append(" ".join(written))
		assert_eq(" · ".join(waves), table[id], id)
		assert_eq(WavePlan.waves(id).size(), Journey.waves(4, id.right(1).to_int()), "%s: the Journey's wave count" % id)
		for wave: Array in WavePlan.waves(id):
			for enemy: StringName in wave:
				assert_true(ResourceLoader.exists(Stage.ENEMY_PATH % enemy), String(enemy))
