extends GutTest
## Endless modifiers in the stage: after each boss wave a ModifierPick of
## three cards (Nothing among them) over a paused game, the break held until a
## click; each modifier's effect; a new pick replacing the last and undoing
## it; Nothing clearing it; and its row in the buff bar.

## Enough frames for a boss wave: its boss, a final Thresh's two phases and
## his souls.
const KILL_FRAMES := 120
## Journey.ENDLESS_MAPS: Jungle.
const JUNGLE := 3


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_endless_modifiers_stage_save_slot_")


func after_each() -> void:
	get_tree().paused = false


## An Endless run on the Jungle, from a fresh save; Lucian takes no damage.
func _endless() -> Stage:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_endless(SaveGame.instance(), JUNGLE, RandomNumberGenerator.new()))
	add_child_autofree(stage)
	await wait_process_frames(2)
	stage.lucian.invulnerable = true
	return stage


func _lethal() -> DamageInfo:
	return DamageInfo.create(999999.0, DamageInfo.Type.TRUE, &"test")


## Jumps to wave 10 and wins it for real: every enemy dies (a final Thresh
## rises at once, then falls) until the break; then the frame the pick opens.
func _win_boss_wave(stage: Stage) -> void:
	var runner := stage.runner
	stage.jump_to_boss_wave()
	runner.tick(0.1)
	assert_eq(runner.wave, 10)
	for frame in KILL_FRAMES:
		if runner.state == WaveRunner.State.BREAK:
			break
		runner.tick(WaveRunner.GROUP_GAP)
		for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
			if enemy is ThreshFinal:
				(enemy as ThreshFinal)._rise_left = 0.0
			enemy.take_damage(_lethal())
		await wait_physics_frames(1)
	assert_eq(runner.state, WaveRunner.State.BREAK, "the boss wave is won")
	await wait_process_frames(1)


func _data(id: StringName) -> EnemyData:
	return load(Stage.ENEMY_PATH % id)


## The modifier's row in the buff bar, or null.
func _modifier_row(stage: Stage) -> BuffIcon:
	for icon: BuffIcon in stage.hud._buff_bar.get_children():
		if icon.visible and icon.buff.get("id") == Hud.MODIFIER_ROW:
			return icon
	return null


func _texts(node: Node, into: Array[String]) -> void:
	if node is Label:
		into.append((node as Label).text)
	for child in node.get_children():
		_texts(child, into)


func _press_esc(pressed: bool) -> void:
	var esc := InputEventAction.new()
	esc.action = &"open_menu"
	esc.pressed = pressed
	Input.parse_input_event(esc)


# --- The pick -----------------------------------------------------------------


func test_after_a_boss_wave_the_pick_shows_three_cards_with_nothing_and_the_break_waits() -> void:
	var stage: Stage = await _endless()
	var runner := stage.runner as EndlessRunner
	await _win_boss_wave(stage)
	var pick := stage.endless.pick
	assert_not_null(pick)
	if pick == null:
		return
	assert_eq(pick.ids.size(), 3)
	assert_eq(pick.cards.size(), 3)
	assert_eq(pick.ids[2], EndlessModifiers.NOTHING)
	assert_ne(pick.ids[0], pick.ids[1])
	for i in 2:
		assert_between(pick.ids[i], 1, 5)
	for i in 3:
		var texts: Array[String] = []
		_texts(pick.cards[i], texts)
		assert_has(texts, EndlessModifiers.downside(pick.ids[i]))
		assert_has(texts, EndlessModifiers.reward(pick.ids[i]))
	assert_true(pick.cards[2].is_visible_in_tree())
	assert_true(get_tree().paused)
	assert_true(stage.screens.locked)
	assert_true(runner.held)
	runner.tick(5.0)
	assert_eq(runner.countdown(), WaveRunner.BREAK_TIME, "no countdown before a pick")
	stage.skip_break()
	assert_eq(runner.wave, 10, "no skip either")
	var info := stage.hud.stage_info
	info.refresh()
	assert_false(info.skip_button.visible)
	assert_false(info.timer_label.visible, "no frozen countdown")
	assert_engine_error_count(0)


func test_a_click_picks_with_the_buff_sound_and_the_break_counts_down() -> void:
	var stage: Stage = await _endless()
	var runner := stage.runner as EndlessRunner
	await _win_boss_wave(stage)
	var pick := stage.endless.pick
	var id := pick.ids[0]
	Sfx._node._last_played.clear()
	pick.cards[0].pressed.emit()
	# A second card in the same frame, before the pick is freed, is too late.
	pick.cards[1].pressed.emit()
	assert_eq(stage.endless.modifier, id)
	assert_true(Sfx._node._last_played.has(&"buff"))
	assert_null(stage.endless.pick)
	assert_false(get_tree().paused)
	assert_false(stage.screens.locked)
	assert_false(runner.held)
	assert_eq(runner.countdown(), WaveRunner.BREAK_TIME, "the whole break")
	runner.tick(1.0)
	assert_lt(runner.countdown(), WaveRunner.BREAK_TIME)
	stage.hud.stage_info.refresh()
	assert_true(stage.hud.stage_info.skip_button.visible)
	assert_true(stage.hud.stage_info.timer_label.visible)
	await wait_process_frames(1)
	assert_false(is_instance_valid(pick), "the pick is gone")
	stage.skip_break()
	assert_eq(runner.wave, 11)


func test_esc_does_nothing_while_the_pick_is_open() -> void:
	var stage: Stage = await _endless()
	await _win_boss_wave(stage)
	_press_esc(true)
	_press_esc(false)
	await wait_process_frames(2)
	assert_false(stage.screens.menu.visible)
	assert_not_null(stage.endless.pick)
	assert_true(get_tree().paused)


func test_the_current_modifier_is_never_offered() -> void:
	var stage: Stage = await _endless()
	stage.endless.choose(3)
	await _win_boss_wave(stage)
	assert_does_not_have(stage.endless.pick.ids, 3)


func test_jump_to_boss_wave_closes_an_open_pick() -> void:
	var stage: Stage = await _endless()
	var runner := stage.runner as EndlessRunner
	await _win_boss_wave(stage)
	var pick := stage.endless.pick
	stage.jump_to_boss_wave()
	assert_null(stage.endless.pick)
	assert_false(get_tree().paused)
	assert_false(stage.screens.locked)
	assert_false(runner.held)
	assert_eq(stage.endless.modifier, EndlessModifiers.NONE, "nothing was picked")
	runner.tick(0.1)
	assert_eq(runner.wave, 20)
	await wait_process_frames(1)
	assert_false(is_instance_valid(pick))


func test_no_pick_comes_over_a_dead_lucian() -> void:
	var stage: Stage = await _endless()
	# He dies with the boss's last blow. (Dead from the start, a final Thresh
	# would never fall: the stage stops counting his fall.)
	stage.runner.boss_cleared.connect(func(_wave: int) -> void: stage.lucian.dead = true)
	await _win_boss_wave(stage)
	assert_null(stage.endless.pick)
	assert_false(get_tree().paused)


# --- The effects --------------------------------------------------------------


func test_modifier_1_makes_enemies_faster_and_pays_more_gold() -> void:
	var stage: Stage = await _endless()
	var at := stage.arena.spawn_points[0]
	stage.endless.choose(1)
	var minion := stage.spawn_enemy(WavePlan.MELEE, at, 1)
	assert_almost_eq(minion.move_speed, _data(WavePlan.MELEE).move_speed * 1.2, 0.001)
	var akshan := stage.spawn_enemy(&"akshan", stage.arena.boss_point, 10)
	assert_almost_eq(akshan.move_speed, _data(&"akshan").move_speed * 1.2, 0.001, "every enemy")
	assert_almost_eq(stage.run.gold_mult, 1.3, 0.0001)
	minion.take_damage(_lethal())
	var data := _data(WavePlan.MELEE)
	assert_eq(stage.wallet.gold, roundi(data.gold * data.reward_scale(1) * 1.3))


func test_modifier_2_doubles_the_elites_and_raises_the_orange_chance() -> void:
	var stage: Stage = await _endless()
	var runner := stage.runner as EndlessRunner
	stage.endless.choose(2)
	assert_eq(runner.elite_mult, 2)
	# Wave 12 comes next: 3 elites, doubled.
	runner._skip_to(11)
	runner.tick(0.1)
	assert_eq(runner.wave, 12)
	var elites := runner._to_spawn.filter(func(id: StringName) -> bool: return id in EndlessPlan.ELITES)
	assert_eq(elites.size(), 6)
	assert_almost_eq(stage.run.orange_mult, 1.5, 0.0001)


func test_modifier_3_lowers_max_hp_keeping_the_hp_share_and_pays_more_blue() -> void:
	var stage: Stage = await _endless()
	var lucian := stage.lucian
	var max_hp := lucian.stats.max_hp
	lucian.hp = max_hp * 0.5
	stage.endless.choose(3)
	assert_almost_eq(lucian.stats.max_hp, max_hp * 0.9, 0.01)
	assert_almost_eq(lucian.hp, lucian.stats.max_hp * 0.5, 0.01, "the HP share is kept")
	assert_almost_eq(stage.run.blue_mult, 1.15, 0.0001)
	var akshan := stage.spawn_enemy(&"akshan", stage.arena.boss_point, 10)
	akshan.take_damage(_lethal())
	assert_eq(stage.collected[Essences.BLUE], roundi((KillRewards.BOSS_BLUE + _data(&"akshan").extra_blue) * 1.15))
	lucian.progress.set_level(5)
	assert_almost_eq(lucian.stats.max_hp, lucian.base_stats.at_level(5).max_hp * 0.9, 0.01, "it lasts through level-ups")


func test_modifier_4_lowers_ad_and_pays_more_gold() -> void:
	var stage: Stage = await _endless()
	var lucian := stage.lucian
	var ad := lucian.stats.ad
	var max_hp := lucian.stats.max_hp
	stage.endless.choose(4)
	assert_almost_eq(lucian.stats.ad, ad * 0.95, 0.001)
	assert_almost_eq(lucian.stats.max_hp, max_hp, 0.001)
	assert_almost_eq(stage.run.gold_mult, 1.1, 0.0001)


func test_modifier_5_raises_boss_and_mini_boss_hp_and_purple() -> void:
	var stage: Stage = await _endless()
	stage.endless.choose(5)
	var akshan := stage.spawn_enemy(&"akshan", stage.arena.boss_point, 20)
	assert_almost_eq(akshan.max_hp, 15000.0 * 1.3 * 1.25, 0.01)
	assert_almost_eq(akshan.hp, akshan.max_hp, 0.01)
	var maokai := stage.spawn_enemy(&"maokai", stage.arena.spawn_points[0], 15)
	assert_almost_eq(maokai.max_hp, 9000.0 * 1.3 * 1.25, 0.01)
	var minion := stage.spawn_enemy(WavePlan.MELEE, stage.arena.spawn_points[0], 1)
	assert_almost_eq(minion.max_hp, 240.0, 0.01, "not a normal enemy")
	assert_almost_eq(minion.move_speed, _data(WavePlan.MELEE).move_speed, 0.001)
	akshan.take_damage(_lethal())
	assert_eq(stage.collected[Essences.PURPLE], 3, "Akshan's repeat 2 × 1.5")


func test_a_new_pick_replaces_the_old_one_and_undoes_it() -> void:
	var stage: Stage = await _endless()
	var runner := stage.runner as EndlessRunner
	var lucian := stage.lucian
	var at := stage.arena.spawn_points[0]
	var speed := _data(WavePlan.MELEE).move_speed
	var max_hp := lucian.stats.max_hp
	var ad := lucian.stats.ad
	stage.endless.choose(3)
	stage.endless.choose(4)
	assert_eq(stage.endless.modifier, 4)
	assert_almost_eq(lucian.stats.max_hp, max_hp, 0.01, "#3's max HP is back")
	assert_almost_eq(lucian.stats.ad, ad * 0.95, 0.001)
	assert_almost_eq(stage.run.blue_mult, 1.0, 0.0001)
	assert_almost_eq(stage.run.gold_mult, 1.1, 0.0001)
	stage.endless.choose(1)
	assert_almost_eq(lucian.stats.ad, ad, 0.001, "#4's AD is back")
	assert_almost_eq(stage.run.gold_mult, 1.3, 0.0001)
	stage.endless.choose(2)
	assert_almost_eq(stage.spawn_enemy(WavePlan.MELEE, at, 1).move_speed, speed, 0.001, "#1's speed is gone")
	assert_almost_eq(stage.run.gold_mult, 1.0, 0.0001)
	stage.endless.choose(5)
	assert_eq(runner.elite_mult, 1, "#2's elites are gone")
	assert_almost_eq(stage.run.orange_mult, 1.0, 0.0001)
	stage.endless.choose(3)
	assert_almost_eq(stage.spawn_enemy(&"akshan", stage.arena.boss_point, 10).max_hp, 15000.0, 0.01, "#5's boss HP is gone")
	assert_almost_eq(stage.run.purple_mult, 1.0, 0.0001)


func test_nothing_clears_the_modifier() -> void:
	var stage: Stage = await _endless()
	var runner := stage.runner as EndlessRunner
	var lucian := stage.lucian
	var at := stage.arena.spawn_points[0]
	var max_hp := lucian.stats.max_hp
	var ad := lucian.stats.ad
	for id in range(1, EndlessModifiers.NOTHING):
		stage.endless.choose(id)
		stage.endless.choose(EndlessModifiers.NOTHING)
		assert_eq(stage.endless.modifier, EndlessModifiers.NONE, "after #%d" % id)
		assert_almost_eq(lucian.stats.max_hp, max_hp, 0.01)
		assert_almost_eq(lucian.stats.ad, ad, 0.001)
		assert_eq(runner.elite_mult, 1)
		for key in EndlessModifiers.REWARDS:
			assert_almost_eq(float(stage.run.get(key)), 1.0, 0.0001, "%s after #%d" % [key, id])
		var minion := stage.spawn_enemy(WavePlan.MELEE, at, 1)
		assert_almost_eq(minion.move_speed, _data(WavePlan.MELEE).move_speed, 0.001)
		var akshan := stage.spawn_enemy(&"akshan", stage.arena.boss_point, 10)
		assert_almost_eq(akshan.max_hp, 15000.0, 0.01)
		for unit: EnemyUnit in [minion, akshan]:
			unit.remove_from_group(&"enemies")
			unit.queue_free()


# --- The buff bar -------------------------------------------------------------


func test_the_buff_bar_shows_the_modifier_row_with_no_timer() -> void:
	var stage: Stage = await _endless()
	await wait_process_frames(1)
	assert_null(_modifier_row(stage), "no row before a pick")
	stage.endless.choose(1)
	await wait_process_frames(1)
	var row := _modifier_row(stage)
	assert_not_null(row)
	if row == null:
		return
	assert_eq(row.buff.icon, EndlessModifiers.icon(1))
	assert_eq(row.buff.left, 0.0)
	assert_eq(row.buff.duration, 0.0, "no timer")
	assert_string_contains(row.buff.text, EndlessModifiers.downside(1))
	assert_string_contains(row.buff.text, EndlessModifiers.reward(1))
	var card := row.tooltip_content()
	assert_not_null(card)
	if card:
		card.free()
	stage.endless.choose(EndlessModifiers.NOTHING)
	await wait_process_frames(1)
	assert_null(_modifier_row(stage), "no row for Nothing")


func test_the_hud_builds_the_modifier_row_once_per_modifier() -> void:
	var stage: Stage = await _endless()
	var first := Hud.modifier_buff(1)
	stage.endless.modifier = 1
	var hud := stage.hud
	var row: Dictionary = hud._buffs()[0]
	assert_same(hud._buffs()[0], row, "the same row on the next frame")
	assert_eq(row, first, "its content is unchanged")
	stage.endless.modifier = 2
	assert_ne(hud._buffs()[0]["text"], row["text"], "a new modifier, a new row")
