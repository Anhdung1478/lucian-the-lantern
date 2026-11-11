extends GutTest
## The music: which piece plays, how its layers follow the game, Senna's
## voice, the crossfade and the pause. Headless nothing is rendered, so most
## tests read the volumes wanted; the deck tests play stand-in streams.

const Layer := Score.Layer
const Scene := Music.Scene
## The Jungle, a Journey.ENDLESS_MAPS choice.
const JUNGLE := 3

var music: Music
## The rendered pieces the tests replaced, put back in after_each.
var _old_streams := {}


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_music_save_slot_")
	SaveGame.instance().reset()
	_old_streams = Music._streams
	Music._streams = {}
	music = Music.new()
	add_child_autofree(music)
	# The tests step it themselves.
	music.set_process(false)


func after_each() -> void:
	get_tree().paused = false
	Music._streams = _old_streams
	SaveGame.instance().reset()


func _stage(act: int, stage_number: int) -> Stage:
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), act, stage_number))
	add_child_autofree(stage)
	await wait_process_frames(2)
	stage.lucian.invulnerable = true
	return stage


## A screen that is no stage, as the main screen is.
func _menu() -> Node:
	var screen := Node.new()
	add_child_autofree(screen)
	return screen


## A stand-in for a rendered piece: five short silent loops.
func _stream() -> AudioStreamSynchronized:
	var wavs: Array[AudioStreamWAV] = []
	for layer in Score.LAYER_COUNT:
		var samples := PackedFloat32Array()
		samples.resize(64)
		wavs.append(Score.to_wav(samples))
	return Score.stream_of(wavs)


func _db(linear: float) -> float:
	return Music._db(linear)


# --- The layers' volumes ----------------------------------------------------


func test_the_pulse_grows_with_the_enemies_left_and_is_full_at_twelve() -> void:
	assert_eq(Music.layer_targets(Scene.FIGHT, 0)[Layer.PULSE], 0.0)
	var last := 0.0
	for enemies in range(1, Music.PULSE_FULL + 1):
		var pulse := Music.layer_targets(Scene.FIGHT, enemies)[Layer.PULSE]
		assert_gt(pulse, last, "%d enemies" % enemies)
		last = pulse
	assert_eq(last, 1.0)
	assert_eq(Music.layer_targets(Scene.FIGHT, 30)[Layer.PULSE], 1.0)


func test_a_boss_or_mini_boss_brings_the_boss_layer_in() -> void:
	assert_eq(Music.layer_targets(Scene.FIGHT, 5, false)[Layer.BOSS], 0.0)
	assert_eq(Music.layer_targets(Scene.FIGHT, 5, true)[Layer.BOSS], 1.0)


func test_a_fight_plays_the_drone_and_the_voices_at_full() -> void:
	var targets := Music.layer_targets(Scene.FIGHT, 5, false, true)
	assert_eq(targets[Layer.DRONE], 1.0)
	assert_eq(targets[Layer.LUCIAN], 1.0)
	assert_eq(targets[Layer.SENNA], 1.0)


func test_a_break_drops_the_pulse_and_the_boss_for_a_quieter_drone_and_the_voices() -> void:
	var targets := Music.layer_targets(Scene.BREAK, 9, true, true)
	assert_eq(targets[Layer.PULSE], 0.0)
	assert_eq(targets[Layer.BOSS], 0.0)
	assert_lt(targets[Layer.DRONE], 1.0)
	assert_gt(targets[Layer.DRONE], 0.0)
	assert_lt(targets[Layer.LUCIAN], 1.0)
	assert_gt(targets[Layer.LUCIAN], 0.0)
	assert_eq(targets[Layer.SENNA], targets[Layer.LUCIAN])


func test_the_calm_is_the_drone_and_the_voices_alone() -> void:
	assert_eq(Music.layer_targets(Scene.CALM, 0, false, true), PackedFloat32Array([1.0, 0.0, 1.0, 1.0, 0.0]))


func test_a_defeat_leaves_the_drone_alone() -> void:
	var targets := Music.layer_targets(Scene.FAILED, 4, true, true)
	assert_gt(targets[Layer.DRONE], 0.0)
	for layer in [Layer.PULSE, Layer.LUCIAN, Layer.SENNA, Layer.BOSS]:
		assert_eq(targets[layer], 0.0, "layer %d" % layer)


func test_senna_s_voice_is_silent_when_she_does_not_sing() -> void:
	assert_eq(Music.layer_targets(Scene.FIGHT, 5, false, false)[Layer.SENNA], 0.0)
	assert_eq(Music.layer_targets(Scene.CALM, 0, false, false)[Layer.SENNA], 0.0)


# --- Senna's voice ----------------------------------------------------------


func test_senna_sings_in_act_1_then_not_again_until_she_is_freed() -> void:
	var none: Array[String] = []
	assert_true(Music.senna_sings(1, none, false))
	for act in range(2, 7):
		assert_false(Music.senna_sings(act, none, false), "act %d" % act)
	var to_the_end: Array[String] = Journey.all_stage_ids(Journey.ACTS.size())
	for piece in range(1, 7):
		assert_true(Music.senna_sings(piece, to_the_end, false), "6-5 cleared: piece %d" % piece)
		assert_true(Music.senna_sings(piece, none, true), "the ending seen: piece %d" % piece)


func test_the_theme_has_senna_until_thresh_takes_her_and_again_once_she_is_free() -> void:
	var none: Array[String] = []
	var act_1: Array[String] = ["1-1"]
	assert_true(Music.senna_sings(Score.THEME, none, false))
	assert_false(Music.senna_sings(Score.THEME, act_1, false))
	assert_true(Music.senna_sings(Score.THEME, Journey.all_stage_ids(Journey.ACTS.size()), false))


func test_the_main_screen_follows_the_rule_and_the_title_always_has_her() -> void:
	SaveGame.instance().set_cleared(["1-1"])
	music.follow(_menu())
	assert_eq(music.piece, Score.THEME)
	assert_eq(music.targets[Layer.SENNA], 0.0, "the main screen after Act 1")
	var title := TitleScreen.new()
	add_child_autofree(title)
	music.follow(title)
	assert_gt(music.targets[Layer.SENNA], 0.0, "the title")


func test_the_tutorial_s_senna_sings_until_thresh_takes_her() -> void:
	var stage: Stage = await _stage(1, 1)
	assert_true(stage.run.tutorial)
	music.follow(stage)
	assert_gt(music.targets[Layer.SENNA], 0.0)
	stage.senna.queue_free()
	stage.senna = null
	music._process(0.0)
	assert_eq(music.targets[Layer.SENNA], 0.0)


func test_a_scene_is_a_pause_and_thresh_taking_senna_silences_her() -> void:
	var stage: Stage = await _stage(1, 1)
	music.follow(stage)
	stage.skip_break()
	var scene := ThreshTakesSenna.new()
	add_child_autofree(scene)
	# Never started, so its props never joined the world.
	autofree(scene._props)
	stage.cutscene = scene
	music._process(0.0)
	assert_eq(music.targets, Music.layer_targets(Scene.BREAK, 0, false, false))
	stage.cutscene = null


func test_the_ending_scene_frees_senna_s_voice() -> void:
	var stage: Stage = await _stage(6, 5)
	music.follow(stage)
	assert_eq(music.targets[Layer.SENNA], 0.0)
	var scene := SennaFreed.new()
	add_child_autofree(scene)
	# Never started, so its props never joined the world.
	autofree(scene._props)
	stage.cutscene = scene
	music._process(0.0)
	assert_gt(music.targets[Layer.SENNA], 0.0)
	stage.cutscene = null


func test_act_2_has_no_senna_and_the_last_stage_s_clear_brings_her_back() -> void:
	var act_2: Stage = await _stage(2, 1)
	music.follow(act_2)
	assert_eq(music.targets[Layer.SENNA], 0.0)
	var last: Stage = await _stage(6, 5)
	music.follow(last)
	assert_eq(music.targets[Layer.SENNA], 0.0, "until she is freed")
	last.show_result(true)
	music._process(0.0)
	assert_gt(music.targets[Layer.SENNA], 0.0, "freed")


# --- The pieces -------------------------------------------------------------


func test_each_act_plays_its_own_piece() -> void:
	for act in range(1, Journey.ACTS.size() + 1):
		assert_eq(Music.stage_piece(StageSetup.for_stage(SaveGame.instance(), act, 1)), act)


func test_training_plays_the_theme() -> void:
	assert_eq(Music.stage_piece(StageSetup.new()), Score.THEME)


func test_endless_plays_the_piece_of_its_map_s_act() -> void:
	var run := StageSetup.for_endless(SaveGame.instance(), JUNGLE, RandomNumberGenerator.new())
	assert_eq(Music.stage_piece(run), 3)


func test_a_screen_that_is_no_stage_plays_the_theme_calm() -> void:
	music.follow(_menu())
	assert_eq(music.piece, Score.THEME)
	assert_eq(music.targets[Layer.PULSE], 0.0)
	assert_eq(music.targets[Layer.DRONE], 1.0)


# --- Following a stage ------------------------------------------------------


func test_a_stage_plays_its_act_and_its_countdown_is_a_break() -> void:
	var stage: Stage = await _stage(3, 1)
	music.follow(stage)
	assert_eq(music.piece, 3)
	assert_eq(music.targets, Music.layer_targets(Scene.BREAK, 0, false, false))


func test_a_wave_s_pulse_follows_the_enemies_left() -> void:
	var stage: Stage = await _stage(3, 1)
	music.follow(stage)
	stage.skip_break()
	music._process(0.0)
	var left := stage.runner.alive()
	assert_gt(left, 0)
	assert_eq(music.targets, Music.layer_targets(Scene.FIGHT, left, false, false))


func test_the_boss_wave_brings_the_boss_layer_in() -> void:
	var stage: Stage = await _stage(2, 3)
	music.follow(stage)
	stage.jump_to_boss_wave()
	stage.runner.tick(0.1)
	music._process(0.0)
	assert_true(stage.runner.is_boss_wave())
	assert_eq(music.targets[Layer.BOSS], 1.0)


func test_a_mini_boss_brings_the_boss_layer_in_for_the_rest_of_its_wave() -> void:
	var stage: Stage = await _stage(3, 2)
	music.follow(stage)
	stage.skip_break()
	music._process(0.0)
	assert_eq(music.targets[Layer.BOSS], 0.0, "a wave of minions")
	var drake := stage.spawn_enemy(&"infernal_drake", stage.arena.boss_point, stage.runner.wave)
	music._process(0.0)
	assert_eq(music.targets[Layer.BOSS], 1.0)
	# Out of reach (a dash takes a boss out of "enemies"): still its wave.
	drake.remove_from_group(&"enemies")
	music._process(0.0)
	assert_eq(music.targets[Layer.BOSS], 1.0)
	stage.runner.state = WaveRunner.State.BREAK
	music._process(0.0)
	assert_eq(music.targets[Layer.BOSS], 0.0, "the break")


func test_a_break_keeps_the_quieter_drone_and_the_voices() -> void:
	var stage: Stage = await _stage(3, 1)
	music.follow(stage)
	stage.skip_break()
	stage.runner.state = WaveRunner.State.BREAK
	music._process(0.0)
	assert_eq(music.targets, Music.layer_targets(Scene.BREAK, 0, false, false))


func test_a_clear_plays_on_calm_and_a_defeat_leaves_the_drone() -> void:
	var cleared: Stage = await _stage(2, 1)
	music.follow(cleared)
	cleared.show_result(true)
	music._process(0.0)
	assert_eq(music.targets, Music.layer_targets(Scene.CALM, 0, false, false))
	assert_false(music.paused, "the result panel's pause is no pause to play quieter for")
	get_tree().paused = false
	var lost: Stage = await _stage(2, 1)
	music.follow(lost)
	lost.show_result(false)
	music._process(0.0)
	assert_eq(music.targets, Music.layer_targets(Scene.FAILED))


# --- Playing ----------------------------------------------------------------


func test_a_piece_plays_its_layers_at_their_volumes() -> void:
	Music._streams[Score.THEME] = _stream()
	music.renders = true
	music.follow(_menu())
	music._process(0.0)
	var deck := music.deck_of(Score.THEME)
	assert_not_null(deck)
	assert_true(deck.player.playing)
	assert_eq(deck.player.bus, &"Music")
	var stream := deck.player.stream as AudioStreamSynchronized
	assert_almost_eq(stream.get_sync_stream_volume(Layer.DRONE), _db(Score.LAYER_PEAKS[Layer.DRONE]), 0.01)
	assert_eq(stream.get_sync_stream_volume(Layer.PULSE), Music.SILENT_DB)
	assert_eq(stream.get_sync_stream_volume(Layer.BOSS), Music.SILENT_DB)


func test_a_new_piece_crossfades_in_over_the_old() -> void:
	Music._streams[Score.THEME] = _stream()
	Music._streams[3] = _stream()
	music.renders = true
	music.follow(_menu())
	music._process(Music.CROSSFADE)
	assert_eq(music.deck_of(Score.THEME).level, 1.0)
	var stage: Stage = await _stage(3, 1)
	music.follow(stage)
	music._process(0.0)
	var theme := music.deck_of(Score.THEME)
	var act := music.deck_of(3)
	assert_eq(act.level, 0.0, "it fades in from silence")
	music._process(Music.CROSSFADE / 2.0)
	assert_almost_eq(act.level, 0.5, 0.01)
	assert_almost_eq(theme.level, 0.5, 0.01)
	assert_true(theme.player.playing)
	music._process(Music.CROSSFADE / 2.0)
	assert_eq(act.level, 1.0)
	assert_null(music.deck_of(Score.THEME), "the old piece stops once silent")
	assert_false(theme.player.playing)


func test_a_layer_fades_toward_its_volume() -> void:
	Music._streams[3] = _stream()
	music.renders = true
	var stage: Stage = await _stage(3, 1)
	music.follow(stage)
	music._process(0.0)
	var deck := music.deck_of(3)
	assert_eq(deck.layers[Layer.PULSE], 0.0)
	stage.skip_break()
	var wanted := Music.layer_targets(Scene.FIGHT, stage.runner.alive())[Layer.PULSE]
	music._process(Music.LAYER_FADE / 4.0)
	assert_almost_eq(deck.layers[Layer.PULSE], minf(wanted, 0.25), 0.01)
	music._process(Music.LAYER_FADE)
	assert_eq(deck.layers[Layer.PULSE], wanted)


func test_the_music_plays_on_quieter_while_the_game_is_paused() -> void:
	Music._streams[Score.THEME] = _stream()
	music.renders = true
	music.follow(_menu())
	music._process(Music.CROSSFADE)
	var deck := music.deck_of(Score.THEME)
	assert_almost_eq(deck.player.volume_db, 0.0, 0.01)
	get_tree().paused = true
	music._process(Music.LAYER_FADE)
	assert_true(music.paused)
	assert_true(music.can_process(), "it isn't paused with the game")
	assert_true(deck.player.can_process())
	assert_true(deck.player.playing)
	assert_almost_eq(deck.player.volume_db, _db(Music.PAUSED_LEVEL), 0.01)
	get_tree().paused = false
	music._process(Music.LAYER_FADE)
	assert_almost_eq(deck.player.volume_db, 0.0, 0.01)


func test_headless_nothing_is_rendered_or_played() -> void:
	assert_false(music.renders, "the tests run headless")
	music.follow(_menu())
	music._process(1.0)
	assert_null(music.deck_of(Score.THEME))
	assert_false(Music._streams.has(Score.THEME))


func test_a_piece_renders_off_the_main_thread_then_plays() -> void:
	music.renders = true
	music.follow(_menu())
	music._process(0.0)
	assert_null(music.deck_of(Score.THEME), "still rendering")
	var start := Time.get_ticks_msec()
	while music.deck_of(Score.THEME) == null and Time.get_ticks_msec() - start < 20000:
		await wait_process_frames(1)
		music._process(0.0)
	gut.p("The theme rendered on worker threads in %d ms" % (Time.get_ticks_msec() - start))
	var deck := music.deck_of(Score.THEME)
	assert_not_null(deck)
	assert_true(deck.player.playing)
	assert_true(Music._streams.has(Score.THEME))


func test_old_pieces_are_forgotten_but_never_the_theme_or_one_playing() -> void:
	for piece in range(0, 5):
		Music._streams[piece] = _stream()
	music.piece = 4
	music._forget_old_pieces()
	assert_eq(Music._streams.size(), Music.CACHED)
	assert_true(Music._streams.has(Score.THEME))
	assert_true(Music._streams.has(4), "the piece wanted")
