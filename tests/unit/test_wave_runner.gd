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
