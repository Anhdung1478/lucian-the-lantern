extends GutTest
## Phase 9's sounds: the level-up chime and burst, rank-ups, Q/W/E, waves,
## bosses, the result, essences and button clicks.

const Slot := ChampionProgress.Slot
const NEW_SOUNDS: Array[StringName] = [
	&"level_up", &"rank_up", &"cast_q", &"cast_w", &"cast_e", &"wave", &"boss",
	&"victory", &"defeat", &"click", &"essence",
]


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_sounds_save_slot_")


func after_each() -> void:
	get_tree().paused = false


## An Sfx node of the test's own: the stage then doesn't add one.
func _sfx() -> Sfx:
	var sfx := Sfx.new()
	add_child_autofree(sfx)
	return sfx


func _lucian() -> Lucian:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	var effects := Node2D.new()
	add_child_autofree(effects)
	lucian.projectile_parent = effects
	add_child_autofree(lucian)
	lucian.cheat_infinite_mana = true
	return lucian


func _stage(act: int, stage_number: int) -> Stage:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), act, stage_number))
	add_child_autofree(stage)
	await wait_process_frames(2)
	stage.lucian.invulnerable = true
	return stage


func _bursts(lucian: Lucian) -> Array:
	return lucian.get_children().filter(func(node: Node) -> bool: return node is LevelUpBurst and not node.is_queued_for_deletion())


# --- The sounds themselves --------------------------------------------------


func test_every_new_sound_is_its_own_not_the_fallback_beep() -> void:
	var fallback := Sfx.stream(&"test_no_such_sound").data.size()
	for sound in NEW_SOUNDS:
		assert_ne(Sfx.stream(sound).data.size(), fallback, "%s is not the fallback beep" % sound)


# --- Level-up ---------------------------------------------------------------


func test_a_level_gained_plays_the_chime_and_adds_a_burst_with_the_level() -> void:
	var sfx := _sfx()
	var lucian := _lucian()
	lucian.progress.add_xp(ChampionProgress.xp_to_next(1))
	assert_eq(lucian.progress.level, 2)
	assert_true(sfx._last_played.has(&"level_up"))
	var bursts := _bursts(lucian)
	assert_eq(bursts.size(), 1)
	var texts := (bursts[0] as Node).get_children().filter(func(node: Node) -> bool: return node is FloatingText)
	assert_eq(texts.size(), 1)
	assert_eq((texts[0] as FloatingText).text, "Level 2")


func test_a_level_gained_while_dead_plays_no_chime_and_no_burst() -> void:
	var sfx := _sfx()
	var lucian := _lucian()
	lucian.dead = true
	sfx._last_played.clear()
	lucian.progress.add_xp(ChampionProgress.xp_to_next(1))
	assert_eq(lucian.progress.level, 2, "the level still counts")
	assert_false(sfx._last_played.has(&"level_up"))
	assert_eq(_bursts(lucian).size(), 0)


func test_the_burst_goes_away_on_its_own() -> void:
	_sfx()
	var lucian := _lucian()
	lucian.progress.add_xp(ChampionProgress.xp_to_next(1))
	assert_eq(_bursts(lucian).size(), 1)
	await wait_seconds(LevelUpBurst.LIFETIME + 0.2)
	assert_eq(_bursts(lucian).size(), 0)


func test_a_level_lost_plays_nothing() -> void:
	var sfx := _sfx()
	var lucian := _lucian()
	lucian.progress.set_level(5)
	sfx._last_played.clear()
	for burst: Node in _bursts(lucian):
		burst.free()
	lucian.progress.set_level(3)
	assert_false(sfx._last_played.has(&"level_up"))
	assert_eq(_bursts(lucian).size(), 0)


func test_xp_without_a_level_plays_nothing() -> void:
	var sfx := _sfx()
	var lucian := _lucian()
	lucian.progress.add_xp(10)
	assert_eq(lucian.progress.level, 1)
	assert_false(sfx._last_played.has(&"level_up"))
	assert_eq(_bursts(lucian).size(), 0)


func test_stage_start_plays_no_level_up() -> void:
	var sfx := _sfx()
	var stage: Stage = await _stage(2, 1)
	assert_false(sfx._last_played.has(&"level_up"))
	assert_eq(_bursts(stage.lucian).size(), 0)


# --- Rank-ups and casts -----------------------------------------------------


func test_learning_a_rank_plays_rank_up() -> void:
	var sfx := _sfx()
	var lucian := _lucian()
	assert_true(lucian.try_rank_up(Slot.Q))
	assert_true(sfx._last_played.has(&"rank_up"))


func test_a_refused_rank_up_is_quiet() -> void:
	var sfx := _sfx()
	var lucian := _lucian()
	assert_false(lucian.try_rank_up(Slot.R), "R needs level 6")
	assert_false(sfx._last_played.has(&"rank_up"))


func test_q_plays_its_sound_when_the_beam_fires() -> void:
	var sfx := _sfx()
	var lucian := _lucian()
	lucian.try_rank_up(Slot.Q)
	assert_true(lucian.try_cast(Slot.Q, Vector2(600, 0)))
	await wait_seconds(0.4)
	assert_true(sfx._last_played.has(&"cast_q"))


func test_w_plays_its_sound_when_the_missile_leaves() -> void:
	var sfx := _sfx()
	var lucian := _lucian()
	lucian.try_rank_up(Slot.W)
	assert_true(lucian.try_cast(Slot.W, Vector2(600, 0)))
	await wait_seconds(0.3)
	assert_true(sfx._last_played.has(&"cast_w"))


func test_e_plays_its_sound_on_the_dash() -> void:
	var sfx := _sfx()
	var lucian := _lucian()
	lucian.try_rank_up(Slot.E)
	assert_true(lucian.try_cast(Slot.E, Vector2(600, 0)))
	assert_true(sfx._last_played.has(&"cast_e"))


func test_a_refused_cast_is_quiet() -> void:
	var sfx := _sfx()
	var lucian := _lucian()
	assert_false(lucian.try_cast(Slot.Q, Vector2(600, 0)), "not learned")
	assert_false(lucian.try_cast(Slot.W, Vector2(600, 0)))
	assert_false(lucian.try_cast(Slot.E, Vector2(600, 0)))
	await wait_seconds(0.4)
	for sound in [&"cast_q", &"cast_w", &"cast_e"]:
		assert_false(sfx._last_played.has(sound), sound)


# --- Waves and bosses -------------------------------------------------------


func test_a_wave_start_plays_wave() -> void:
	var sfx := _sfx()
	var stage: Stage = await _stage(2, 1)
	assert_false(sfx._last_played.has(&"wave"), "not during the countdown")
	stage.skip_break()
	assert_true(sfx._last_played.has(&"wave"))
	assert_false(sfx._last_played.has(&"boss"))


func test_the_boss_wave_plays_boss_not_wave() -> void:
	var sfx := _sfx()
	var stage: Stage = await _stage(2, 3)
	stage.jump_to_boss_wave()
	stage.runner.tick(0.1)
	stage.runner.tick(0.1)
	assert_not_null(stage.boss_unit)
	assert_true(sfx._last_played.has(&"boss"))
	assert_false(sfx._last_played.has(&"wave"))


func test_a_mini_boss_wave_enemy_plays_boss() -> void:
	var sfx := _sfx()
	var stage: Stage = await _stage(3, 2)
	stage.runner.spawn_requested.emit(&"melee_minion", 1)
	assert_false(sfx._last_played.has(&"boss"), "a minion is no boss")
	stage.runner.spawn_requested.emit(&"infernal_drake", 1)
	assert_true(sfx._last_played.has(&"boss"))


# --- The result -------------------------------------------------------------


func test_a_clear_plays_victory() -> void:
	var sfx := _sfx()
	var stage: Stage = await _stage(2, 1)
	stage.show_result(true)
	assert_true(sfx._last_played.has(&"victory"))
	assert_false(sfx._last_played.has(&"defeat"))


func test_a_defeat_plays_defeat() -> void:
	var sfx := _sfx()
	var stage: Stage = await _stage(2, 1)
	stage.show_result(false)
	assert_true(sfx._last_played.has(&"defeat"))
	assert_false(sfx._last_played.has(&"victory"))


# --- Essences ---------------------------------------------------------------


func test_orange_gained_plays_essence() -> void:
	var sfx := _sfx()
	var stage: Stage = await _stage(2, 1)
	stage.add_essences(0, 3, 0, Vector2.ZERO)
	assert_true(sfx._last_played.has(&"essence"))


func test_purple_gained_plays_essence() -> void:
	var sfx := _sfx()
	var stage: Stage = await _stage(2, 1)
	stage.add_essences(0, 0, 2, Vector2.ZERO)
	assert_true(sfx._last_played.has(&"essence"))


func test_blue_alone_is_quiet() -> void:
	var sfx := _sfx()
	var stage: Stage = await _stage(2, 1)
	stage.add_essences(40, 0, 0, Vector2.ZERO)
	assert_false(sfx._last_played.has(&"essence"))


# --- Buttons ----------------------------------------------------------------


func test_a_styled_button_clicks_once_even_restyled() -> void:
	var sfx := _sfx()
	var button := Button.new()
	add_child_autofree(button)
	var before := button.pressed.get_connections().size()
	UiStyle.style_button(button)
	UiStyle.style_button(button, 22, true)
	assert_eq(button.pressed.get_connections().size(), before + 1, "connected once")
	button.pressed.emit()
	assert_true(sfx._last_played.has(&"click"))
