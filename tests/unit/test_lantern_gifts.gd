extends GutTest
## The Lantern's gift: which stages offer it and after which wave, the pick
## (three different cards over a paused game, the break held, ESC and P
## locked), each boon's numbers on Lucian and on gold, Second Wind's heal, the
## gift ending with the stage, its buff icon and its row on the result.

## Enough frames for any wave: its groups, then splits and escapes.
const KILL_FRAMES := 120
## Seeds tried for the draw.
const SEEDS := 60


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_lantern_gifts_save_slot_")


func after_each() -> void:
	get_tree().paused = false


func _stage(act: int, stage_number: int) -> Stage:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), act, stage_number))
	add_child_autofree(stage)
	await wait_process_frames(2)
	stage.lucian.invulnerable = true
	return stage


func _lethal() -> DamageInfo:
	return DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test")


## Starts the next wave and kills it, until the runner has nobody left.
func _win_wave(stage: Stage) -> void:
	stage.runner.skip()
	for frame in KILL_FRAMES:
		if stage.runner.alive() == 0:
			break
		stage.runner.tick(WaveRunner.GROUP_GAP)
		for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
			enemy.take_damage(_lethal())
		await wait_physics_frames(1)
	await wait_process_frames(2)


## Wins waves until the gift's pick opens (the wave after which it comes).
func _to_pick(stage: Stage) -> void:
	for wave in stage.gifts.offer_wave:
		await _win_wave(stage)


## Picks card `index` the way a click does, and lets the frame end.
func _pick(stage: Stage, index := 0) -> void:
	stage.gifts.pick.cards[index].pressed.emit()
	await wait_process_frames(2)


func _press(action: StringName) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
	await wait_process_frames(2)


func _texts(node: Node, into: Array[String]) -> void:
	if node is Label:
		into.append((node as Label).text)
	for child in node.get_children():
		_texts(child, into)


## The gift's icon in the buff bar, or null.
func _gift_icon(stage: Stage) -> BuffIcon:
	for icon: BuffIcon in stage.hud._buff_bar.get_children():
		if icon.visible and icon.buff.get("id") == LanternGifts.BUFF:
			return icon
	return null


# --- Which stages, after which wave --------------------------------------------


func test_a_stage_of_4_or_more_waves_offers_after_half_of_them() -> void:
	var after := {2: 0, 3: 0, 4: 2, 5: 2, 6: 3, 7: 3, 8: 4, 9: 4}
	for waves: int in after:
		assert_eq(LanternGifts.offer_wave(waves), after[waves], "%d waves" % waves)


func test_the_offer_never_falls_on_the_last_wave_or_a_boss_wave() -> void:
	for act in Journey.ACTS.size():
		for stage in Journey.stage_count(act + 1):
			var waves := Journey.waves(act + 1, stage + 1)
			assert_lt(LanternGifts.offer_wave(waves), waves, "%d-%d" % [act + 1, stage + 1])


func test_the_tutorial_has_no_gift() -> void:
	var stage: Stage = await _stage(1, 1)
	assert_null(stage.gifts)


func test_endless_has_no_gift() -> void:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_endless(SaveGame.instance(), 3, RandomNumberGenerator.new()))
	add_child_autofree(stage)
	await wait_process_frames(2)
	assert_null(stage.gifts)


func test_training_has_no_gift() -> void:
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	add_child_autofree(stage)
	await wait_process_frames(2)
	assert_null(stage.gifts)


func test_every_other_story_stage_has_one() -> void:
	var stage: Stage = await _stage(2, 1)
	assert_not_null(stage.gifts)
	assert_eq(stage.gifts.offer_wave, 2)
	var long: Stage = await _stage(6, 3)
	assert_eq(long.gifts.offer_wave, 4)


# --- The cards ----------------------------------------------------------------


func test_the_draw_is_three_different_gifts_and_every_gift_can_come() -> void:
	var seen := {}
	var rng := RandomNumberGenerator.new()
	for seed_value in SEEDS:
		rng.seed = seed_value
		var cards := LanternGifts.offer(rng)
		assert_eq(cards.size(), 3)
		for id in cards:
			assert_between(id, 1, LanternGifts.COUNT)
			seen[id] = true
		assert_ne(cards[0], cards[1])
		assert_ne(cards[0], cards[2])
		assert_ne(cards[1], cards[2])
	assert_eq(seen.size(), LanternGifts.COUNT)


func test_every_gift_has_a_name_a_text_and_an_icon() -> void:
	for id in range(1, LanternGifts.COUNT + 1):
		assert_ne(LanternGifts.display_name(id), "")
		assert_ne(LanternGifts.text(id), "")
		assert_not_null(LanternGifts.icon(id))


# --- The pick -----------------------------------------------------------------


func test_no_pick_before_the_offer_wave_and_none_on_a_later_break() -> void:
	var stage: Stage = await _stage(2, 1)
	await _win_wave(stage)
	assert_null(stage.gifts.pick, "wave 1 of 4")
	assert_false(stage.runner.held)
	await _win_wave(stage)
	assert_not_null(stage.gifts.pick, "wave 2 of 4")
	await _pick(stage)
	await _win_wave(stage)
	assert_null(stage.gifts.pick, "wave 3: once only")


func test_the_pick_shows_three_cards_titled_the_lanterns_gift_over_a_paused_game() -> void:
	var stage: Stage = await _stage(2, 1)
	await _to_pick(stage)
	var pick := stage.gifts.pick
	assert_not_null(pick)
	if pick == null:
		return
	assert_eq(pick.cards.size(), 3)
	var titles: Array[String] = []
	_texts(pick, titles)
	assert_has(titles, "THE LANTERN'S GIFT")
	for i in 3:
		var texts: Array[String] = []
		_texts(pick.cards[i], texts)
		assert_has(texts, LanternGifts.display_name(pick.ids[i]))
		assert_has(texts, LanternGifts.text(pick.ids[i]))
	assert_true(get_tree().paused)
	assert_true(stage.screens.locked)
	assert_true(stage.runner.held)


func test_the_break_waits_while_the_pick_is_open() -> void:
	var stage: Stage = await _stage(2, 1)
	await _to_pick(stage)
	var left := stage.runner.countdown()
	stage.runner.tick(5.0)
	assert_eq(stage.runner.countdown(), left)
	assert_eq(stage.runner.skip(), 0.0)
	assert_eq(stage.runner.state, WaveRunner.State.BREAK)


func test_esc_and_the_backpack_key_do_nothing_while_the_pick_is_open() -> void:
	var stage: Stage = await _stage(2, 1)
	await _to_pick(stage)
	await _press(&"open_menu")
	await _press(&"open_backpack")
	assert_false(stage.screens.menu.visible)
	assert_false(stage.screens.backpack.visible)
	assert_not_null(stage.gifts.pick)
	assert_true(get_tree().paused)


func test_a_click_picks_and_the_break_counts_down_with_the_merchant() -> void:
	var stage: Stage = await _stage(2, 1)
	await _to_pick(stage)
	var id := stage.gifts.pick.ids[1]
	await _pick(stage, 1)
	assert_eq(stage.gifts.gift, id)
	assert_eq(stage.lucian.gift, id)
	assert_null(stage.gifts.pick)
	assert_false(get_tree().paused)
	assert_false(stage.screens.locked)
	assert_false(stage.runner.held)
	assert_almost_eq(stage.runner.countdown(), WaveRunner.BREAK_TIME, 0.5, "the full break")
	assert_not_null(stage.merchant)
	var left := stage.runner.countdown()
	stage.runner.tick(1.0)
	assert_almost_eq(stage.runner.countdown(), left - 1.0, 0.001)


func test_the_pick_never_comes_on_a_boss_waves_break() -> void:
	var stage: Stage = await _stage(2, 3)
	var runner := stage.runner
	stage.gifts.offer_wave = runner.wave_count() + 1
	runner.wave = runner.wave_count() + 1
	assert_true(runner.is_boss_wave())
	stage.gifts._on_break_started(WaveRunner.BREAK_TIME)
	assert_false(runner.held)
	assert_null(stage.gifts.pick)


func test_no_pick_comes_over_a_dead_lucian() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.lucian.dead = true
	stage.runner.wave = stage.gifts.offer_wave
	stage.gifts._on_break_started(WaveRunner.BREAK_TIME)
	await wait_process_frames(2)
	assert_null(stage.gifts.pick)
	assert_false(get_tree().paused)


# --- The boons ----------------------------------------------------------------


func test_each_boon_changes_the_stats_it_names() -> void:
	var stage: Stage = await _stage(2, 1)
	var lucian := stage.lucian
	var before := lucian.stats
	lucian.set_gift(1)
	assert_almost_eq(lucian.stats.ad, before.ad * 1.1, 0.01, "Keen Edge")
	lucian.set_gift(2)
	assert_almost_eq(lucian.stats.attack_speed, before.attack_speed * 1.12, 0.001, "Quick Hands")
	assert_almost_eq(lucian.stats.ad, before.ad, 0.01, "the last gift is gone")
	lucian.set_gift(3)
	assert_almost_eq(lucian.stats.ability_haste, before.ability_haste + 15.0, 0.001, "Focus")
	lucian.set_gift(4)
	assert_almost_eq(lucian.stats.max_hp, before.max_hp + 150.0, 0.001, "Second Wind")
	lucian.set_gift(5)
	assert_almost_eq(lucian.stats.move_speed, before.move_speed * 1.06, 0.01, "Light Step")
	lucian.set_gift(6)
	assert_almost_eq(lucian.stats.omnivamp, before.omnivamp + 0.06, 0.0001, "Thirst")
	lucian.set_gift(7)
	assert_almost_eq(lucian.stats.armor, before.armor + 20.0, 0.001, "Ward armor")
	assert_almost_eq(lucian.stats.mr, before.mr + 20.0, 0.001, "Ward magic resist")
	lucian.set_gift(8)
	assert_almost_eq(lucian.stats.ad, before.ad, 0.01, "Fortune changes no stat")
	lucian.set_gift(LanternGifts.NONE)
	assert_eq(lucian.stats.max_hp, before.max_hp)
	assert_eq(lucian.stats.armor, before.armor)


func test_second_wind_heals_what_it_adds() -> void:
	var stage: Stage = await _stage(2, 1)
	var lucian := stage.lucian
	lucian.hp = 100.0
	stage.gifts.choose(4)
	assert_almost_eq(lucian.hp, 250.0, 0.001)


func test_a_stat_gift_keeps_the_hp_share() -> void:
	var stage: Stage = await _stage(2, 1)
	var lucian := stage.lucian
	lucian.hp = lucian.stats.max_hp * 0.5
	stage.gifts.choose(1)
	assert_almost_eq(lucian.hp, lucian.stats.max_hp * 0.5, 0.01)


func test_fortune_pays_a_fifth_more_gold_and_the_others_do_not() -> void:
	var stage: Stage = await _stage(2, 1)
	var data: EnemyData = load(Stage.ENEMY_PATH % WavePlan.SIEGE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var plain: int = KillRewards.roll(data, 2, stage.run, rng).gold
	stage.gifts.choose(1)
	assert_eq(stage.run.gold_mult, 1.0)
	stage.gifts.choose(8)
	assert_eq(stage.run.gold_mult, 1.2)
	rng.seed = 7
	var rich: int = KillRewards.roll(data, 2, stage.run, rng).gold
	assert_eq(rich, roundi(plain * 1.2))
	assert_gt(rich, plain)


# --- Shown --------------------------------------------------------------------


func test_a_new_stage_starts_with_no_gift() -> void:
	var first: Stage = await _stage(2, 1)
	first.gifts.choose(8)
	var next: Stage = await _stage(2, 2)
	assert_eq(next.gifts.gift, LanternGifts.NONE)
	assert_eq(next.lucian.gift, LanternGifts.NONE)
	assert_eq(next.run.gold_mult, 1.0)


func test_the_gift_is_a_buff_icon_with_no_timer_and_its_hover_text() -> void:
	var stage: Stage = await _stage(2, 1)
	assert_null(_gift_icon(stage))
	stage.gifts.choose(1)
	await wait_process_frames(2)
	var icon := _gift_icon(stage)
	assert_not_null(icon)
	if icon == null:
		return
	assert_eq(icon.buff["duration"], 0.0)
	assert_eq(icon.buff["text"], "The Lantern's gift: Keen Edge. +10% attack damage until the stage ends.")


func test_the_result_names_the_gift_and_has_no_row_without_one() -> void:
	var stage: Stage = await _stage(2, 1)
	stage.show_result(true)
	var texts: Array[String] = []
	_texts(stage.result, texts)
	assert_does_not_have(texts, "Gift")
	var picked: Stage = await _stage(2, 1)
	picked.gifts.choose(7)
	picked.show_result(true)
	var picked_texts: Array[String] = []
	_texts(picked.result, picked_texts)
	assert_has(picked_texts, "Gift")
	assert_has(picked_texts, "Ward")


## Quick Hands multiplies the final attack speed: it must not pass the cap
## every other source stops at.
func test_quick_hands_stays_under_the_attack_speed_cap() -> void:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	lucian.tree_bonus = {&"attack_speed": 10.0}
	lucian._refresh_stats(true)
	assert_eq(lucian.stats.attack_speed, UnitStats.MAX_ATTACK_SPEED, "capped without the gift")
	lucian.set_gift(2)
	assert_almost_eq(lucian.stats.attack_speed, UnitStats.MAX_ATTACK_SPEED, 0.0001, "Quick Hands stays at the cap")


## The settings page (over the ESC menu) closes for the pick like the menu
## does: its Back would bring the menu up, and Resume would unpause the game
## under the pick.
func test_the_pick_closes_the_settings_page() -> void:
	var stage := await _stage(2, 2)
	for wave in stage.gifts.offer_wave - 1:
		await _win_wave(stage)
	stage.screens.set_menu_open(true)
	stage.screens.set_settings_open(true)
	await _win_wave(stage)
	assert_not_null(stage.gifts.pick, "the pick is up")
	assert_false(stage.screens.settings.visible, "the settings page closed")
	assert_false(stage.screens.menu.visible, "the menu stays closed")
	assert_true(get_tree().paused, "the game waits for the pick")
