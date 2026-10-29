extends GutTest
## Endless mode's runner: waves made up by EndlessPlan without end, and the
## break that holds after a boss wave until the modifier is picked.

var spawned: Array[StringName] = []
## Each wave's enemy ids, by wave.
var waves := {}


func _runner(rng_seed := 7) -> EndlessRunner:
	spawned.clear()
	waves.clear()
	var runner := EndlessRunner.new(rng_seed)
	runner.spawn_requested.connect(_on_spawn_requested)
	return runner


func _on_spawn_requested(id: StringName, wave: int) -> void:
	spawned.append(id)
	waves[wave] = waves.get(wave, []) + [id]


## Ticks until every enemy of the wave has been asked for.
func _spawn_all(runner: WaveRunner) -> void:
	for i in 50:
		runner.tick(WaveRunner.GROUP_GAP)


func _kill_all(runner: WaveRunner) -> void:
	for i in spawned.size():
		runner.enemy_died()
	spawned.clear()


## Plays `count` more waves, picking (releasing) after each boss wave.
func _play(runner: EndlessRunner, count: int) -> void:
	for i in count:
		runner.release()
		runner.skip()
		_spawn_all(runner)
		_kill_all(runner)


func test_it_has_no_end() -> void:
	var runner := _runner()
	assert_eq(runner.total_waves(), -1)
	assert_eq(runner.wave_count(), -1)
	assert_eq(runner.state, WaveRunner.State.INTRO)
	assert_eq(runner.waves_cleared, 0)


func test_it_never_emits_cleared_and_counts_the_waves_cleared() -> void:
	var runner := _runner()
	watch_signals(runner)
	_play(runner, 25)
	assert_signal_not_emitted(runner, "cleared")
	assert_eq(runner.waves_cleared, 25)
	assert_eq(runner.waves_done(), 25)
	assert_eq(runner.wave, 25)
	assert_eq(runner.state, WaveRunner.State.BREAK)
	runner.finish()
	assert_signal_not_emitted(runner, "cleared", "finish does nothing in Endless")
	assert_eq(runner.state, WaveRunner.State.BREAK)


func test_each_wave_comes_from_the_plan_with_its_own_seeded_rng() -> void:
	var runner := _runner(11)
	_play(runner, 4)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for w in range(1, 5):
		assert_eq(waves[w], Array(EndlessPlan.wave(w, rng)), "wave %d" % w)


func test_the_same_seed_plays_the_same_run() -> void:
	_play(_runner(5), 12)
	var first := waves.duplicate(true)
	_play(_runner(5), 12)
	assert_eq(waves, first)


func test_wave_5_ends_with_a_mini_boss_and_wave_10_is_a_boss_alone() -> void:
	var runner := _runner()
	_play(runner, 4)
	runner.skip()
	assert_true(runner.is_mini_boss_wave())
	assert_false(runner.is_boss_wave())
	_spawn_all(runner)
	assert_has(EndlessPlan.MINI_BOSSES, spawned.back())
	assert_eq(runner.mini_boss, spawned.back())
	_kill_all(runner)
	_play(runner, 4)
	watch_signals(runner)
	runner.skip()
	assert_true(runner.is_boss_wave())
	assert_false(runner.is_mini_boss_wave())
	_spawn_all(runner)
	assert_eq(spawned.size(), 1)
	assert_has(EndlessPlan.BOSSES, spawned[0])
	assert_eq(runner.boss, spawned[0])
	assert_signal_emitted_with_parameters(runner, "boss_wave_started", [spawned[0]])


func test_wave_7_is_neither() -> void:
	var runner := _runner()
	_play(runner, 6)
	runner.skip()
	assert_eq(runner.wave, 7)
	assert_false(runner.is_boss_wave())
	assert_false(runner.is_mini_boss_wave())


func test_no_enemy_is_ever_the_last_one() -> void:
	var runner := _runner()
	runner.skip()
	_spawn_all(runner)
	for i in spawned.size() - 1:
		runner.enemy_died()
	assert_eq(runner.alive(), 1)
	assert_false(runner.is_last_enemy())
	runner.enemy_died()
	assert_eq(runner.state, WaveRunner.State.BREAK)


func test_a_boss_or_mini_boss_never_repeats_the_last_one() -> void:
	var runner := _runner(3)
	_play(runner, 80)
	for w in range(20, 81, 10):
		assert_ne(waves[w][0], waves[w - 10][0], "boss of wave %d" % w)
	for w in range(15, 76, 10):
		assert_ne(waves[w].back(), waves[w - 10].back(), "mini boss of wave %d" % w)


func test_a_normal_break_counts_down() -> void:
	var runner := _runner()
	_play(runner, 1)
	assert_false(runner.held)
	assert_almost_eq(runner.countdown(), WaveRunner.BREAK_TIME, 0.001)
	runner.tick(WaveRunner.BREAK_TIME + 0.1)
	assert_eq(runner.state, WaveRunner.State.FIGHT)
	assert_eq(runner.wave, 2)


func test_the_break_after_a_boss_wave_holds_until_released() -> void:
	var runner := _runner()
	_play(runner, 9)
	runner.skip()
	_spawn_all(runner)
	var order: Array[String] = []
	runner.boss_cleared.connect(func(_wave: int) -> void: order.append("boss_cleared"))
	runner.break_started.connect(func(_seconds: float) -> void: order.append("break_started"))
	watch_signals(runner)
	_kill_all(runner)
	assert_signal_emitted_with_parameters(runner, "boss_cleared", [10])
	assert_eq(order, ["boss_cleared", "break_started"] as Array[String], "the pick comes before the break")
	assert_true(runner.held)
	assert_eq(runner.state, WaveRunner.State.BREAK)
	assert_eq(runner.waves_cleared, 10)
	runner.tick(100.0)
	assert_eq(runner.state, WaveRunner.State.BREAK, "no countdown while held")
	assert_almost_eq(runner.countdown(), WaveRunner.BREAK_TIME, 0.001)
	assert_eq(runner.skip(), 0.0, "no skip while held")
	assert_eq(runner.state, WaveRunner.State.BREAK)
	runner.release()
	assert_false(runner.held)
	runner.tick(WaveRunner.BREAK_TIME - 0.1)
	assert_eq(runner.state, WaveRunner.State.BREAK, "the whole break comes after the pick")
	runner.tick(0.2)
	assert_eq(runner.state, WaveRunner.State.FIGHT)
	assert_eq(runner.wave, 11)
	assert_signal_emit_count(runner, "boss_cleared", 1)


func test_elite_mult_doubles_the_elites() -> void:
	var runner := _runner()
	runner.elite_mult = 2
	_play(runner, 15)
	runner.skip()
	_spawn_all(runner)
	assert_eq(spawned.filter(func(id: StringName) -> bool: return id in EndlessPlan.ELITES).size(), 8)


func test_jump_to_boss_wave_reaches_the_next_tenth_wave() -> void:
	var runner := _runner()
	_play(runner, 2)
	runner.skip()
	_spawn_all(runner)
	runner.skip_to_boss()
	spawned.clear()
	runner.tick(0.01)
	assert_eq(runner.wave, 10)
	assert_true(runner.is_boss_wave())
	_spawn_all(runner)
	_kill_all(runner)
	runner.release()
	runner.skip_to_boss()
	runner.tick(0.01)
	assert_eq(runner.wave, 20)
	assert_true(runner.is_boss_wave())


func test_jump_to_the_last_wave_does_nothing() -> void:
	var runner := _runner()
	runner.skip()
	runner.skip_to_last_wave()
	assert_eq(runner.wave, 1)
	assert_eq(runner.state, WaveRunner.State.FIGHT)
