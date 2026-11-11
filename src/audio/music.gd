class_name Music
extends Node
## The score (Score) on the Music bus: one piece at a time, its layers faded in
## and out with what the screen the Game shows is doing. The Game adds one and
## hands it each new screen (follow()).
## - The title, the main screen and The End play the theme, calm.
## - A stage plays its act's piece (Endless: the act its map comes from;
##   Training: the theme). In a wave the pulse grows with the enemies left to
##   beat (full at PULSE_FULL), and a boss or mini boss brings the boss layer
##   in for the rest of its wave. The countdown, the breaks and the scenes keep
##   only the drone, quieter, and the voices. A clear plays on calm; a defeat
##   leaves the drone alone.
## - Senna's voice sings in Act 1 and in the theme until Thresh takes her
##   (Act 1's first clear), then not again until 6-5 frees her (senna_sings).
## A new piece crossfades in over the old one. While the game is paused (the
## ESC menu, the backpack) the music plays on, quieter.
##
## Each piece is rendered once, off the main thread (each layer on a thread of
## its own), when it is first needed; the old piece plays on meanwhile. Run
## headless (the bots, the tests) nothing is rendered or played, but the
## volumes still follow the game.

## What a piece is playing for: the calm of the menus and a cleared stage, a
## wave being fought, a pause between waves (the countdown, a break, a scene,
## Training), or a lost stage.
enum Scene { CALM, FIGHT, BREAK, FAILED }

## Seconds a layer takes to fade all the way in or out.
const LAYER_FADE := 2.0
## Seconds a new piece takes to fade in, and the old one to fade out.
const CROSSFADE := 3.0
## How loud everything plays while the game is paused.
const PAUSED_LEVEL := 0.5
## The pulse is at full volume with this many enemies left to beat.
const PULSE_FULL := 12
## Between waves the drone and the voices play this loud.
const BREAK_DRONE := 0.7
const BREAK_VOICES := 0.8
## After a defeat the drone plays this loud, alone.
const FAILED_DRONE := 0.6
## Rendered pieces kept in memory (about 3 MB each): the theme always stays.
const CACHED := 3
const SILENT_DB := -80.0

## Piece -> its AudioStreamSynchronized, once rendered.
static var _streams := {}

## Pieces are rendered and played; off when run headless. Tests turn it on to
## check the players.
var renders := DisplayServer.get_name() != "headless"
## The piece wanted now (Score.THEME or an act), even while it renders.
var piece := Score.THEME
## The layer volumes wanted now, 0–1, in Score.Layer order.
var targets := layer_targets(Scene.CALM, 0, false, true)
## The game is paused, and everything plays at PAUSED_LEVEL.
var paused := false

## The screen followed.
var _screen: Node
## Two decks, so one piece can fade in while the other fades out.
var _decks: Array[Deck] = []
## How loud the pause leaves everything, fading toward 1 or PAUSED_LEVEL.
var _pause_level := 1.0
## The wave a boss or mini boss was seen in, and its runner's instance id.
var _boss_runner := 0
var _boss_wave := -1
## The render under way: its piece (-1 for none), its group task and the
## layers it fills in.
var _rendering := -1
var _task := -1
var _wavs: Array[AudioStreamWAV] = []
var _wavs_lock := Mutex.new()


## One piece playing: its player, how loud it plays (the crossfade) and its
## layers' volumes, 0–1.
class Deck:
	## Score.THEME or an act; -1 when the deck is free.
	var piece := -1
	var player := AudioStreamPlayer.new()
	var level := 0.0
	var layers := PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 0.0])


## The layer volumes, 0–1 in Score.Layer order, for `scene`; in a FIGHT,
## with `enemies` left to beat and whether a boss or a mini boss is in the
## wave. Senna's voice follows Lucian's when she sings.
static func layer_targets(scene: Scene, enemies := 0, boss := false, senna := false) -> PackedFloat32Array:
	var drone := 1.0
	var voices := 1.0
	var pulse := 0.0
	var boss_level := 0.0
	match scene:
		Scene.FIGHT:
			# The square root: the first few enemies are already heard.
			pulse = sqrt(clampf(float(enemies) / PULSE_FULL, 0.0, 1.0))
			boss_level = 1.0 if boss else 0.0
		Scene.BREAK:
			drone = BREAK_DRONE
			voices = BREAK_VOICES
		Scene.FAILED:
			drone = FAILED_DRONE
			voices = 0.0
	return PackedFloat32Array([drone, pulse, voices, voices if senna else 0.0, boss_level])


## Senna's voice sings in `piece`: in Act 1's piece, and in the theme until
## Act 1 is cleared (Thresh has taken her); in every piece once the last
## stage is cleared (she is free).
static func senna_sings(piece_number: int, cleared: Array[String], ending_seen: bool) -> bool:
	if ending_seen or Journey.act_cleared(Journey.ACTS.size(), cleared):
		return true
	if piece_number == Score.THEME:
		return not Journey.act_cleared(1, cleared)
	return piece_number == 1


## The piece a stage plays: its act's (an Endless run's map has one too), or
## the theme in Training.
static func stage_piece(run: StageSetup) -> int:
	return run.act if run.act > 0 else Score.THEME


func _ready() -> void:
	# Plays on while the game is paused.
	process_mode = PROCESS_MODE_ALWAYS
	for i in 2:
		var deck := Deck.new()
		deck.player.bus = &"Music"
		add_child(deck.player)
		_decks.append(deck)


## Waits for a render under way: the task's layers must not outlive the node.
func _exit_tree() -> void:
	if _task != -1:
		WorkerThreadPool.wait_for_group_task_completion(_task)
		_task = -1
		_rendering = -1


## The screen the Game shows now: its piece plays from now on.
func follow(screen: Node) -> void:
	_screen = screen
	_read_screen()


func _process(delta: float) -> void:
	_read_screen()
	if renders:
		_collect_render()
		_render(piece)
		_start_deck()
	_fade(delta)


## The deck playing `piece_number`, or null.
func deck_of(piece_number: int) -> Deck:
	for deck in _decks:
		if deck.piece == piece_number:
			return deck
	return null


## The piece, the layer volumes and the pause from the screen followed.
func _read_screen() -> void:
	paused = get_tree().paused
	if not is_instance_valid(_screen):
		_screen = null
	if _screen is Stage:
		_read_stage(_screen as Stage)
		return
	piece = Score.THEME
	# The title comes before the story: Senna is still with him.
	var save := SaveGame.instance()
	var senna := _screen is TitleScreen or senna_sings(Score.THEME, save.cleared, save.ending_seen)
	targets = layer_targets(Scene.CALM, 0, false, senna)


func _read_stage(stage: Stage) -> void:
	piece = stage_piece(stage.run)
	var scene := Scene.BREAK
	var enemies := 0
	var boss := false
	var runner := stage.runner
	var cutscene: Cutscene = stage.cutscene if is_instance_valid(stage.cutscene) else null
	if stage.result.visible:
		scene = Scene.CALM if stage.result.cleared else Scene.FAILED
	elif stage.lucian.dead:
		scene = Scene.FAILED
	elif runner and runner.state == WaveRunner.State.FIGHT and cutscene == null:
		scene = Scene.FIGHT
		enemies = runner.alive()
		boss = _boss_in_wave(runner)
	targets = layer_targets(scene, enemies, boss, _senna_in(stage, cutscene))
	# The result panel pauses the game, but it is no pause to play quieter for.
	paused = paused and not stage.result.visible


## A boss or a mini boss has come in the wave being fought, or it is the
## stage's boss wave. It stays a boss wave to its end, also while the boss is
## out of reach (a dash takes it out of "enemies").
func _boss_in_wave(runner: WaveRunner) -> bool:
	if runner.is_boss_wave():
		return true
	var id := runner.get_instance_id()
	if _boss_runner != id or _boss_wave != runner.wave:
		for node in get_tree().get_nodes_in_group(&"enemies"):
			var unit := node as EnemyUnit
			if unit and unit.data and unit.data.is_boss_kind():
				_boss_runner = id
				_boss_wave = runner.wave
				break
	return _boss_runner == id and _boss_wave == runner.wave


## Senna's voice in a stage: the piece's rule (senna_sings), but in the
## tutorial only while she is there (Thresh takes her at half his HP), and the
## last stage's ending and its cleared result free her. `cutscene` is the
## scene playing, or null.
func _senna_in(stage: Stage, cutscene: Cutscene) -> bool:
	var run := stage.run
	var last := not run.endless and run.act == Journey.ACTS.size() and run.stage == Journey.stage_count(run.act)
	if cutscene is SennaFreed or (last and stage.result.visible and stage.result.cleared):
		return true
	if run.tutorial:
		return is_instance_valid(stage.senna) and not cutscene is ThreshTakesSenna
	var save := SaveGame.instance()
	return senna_sings(piece, save.cleared, save.ending_seen)


## Starts rendering `piece_number` unless it is rendered or a render is under
## way (the next frame asks again).
func _render(piece_number: int) -> void:
	if _streams.has(piece_number) or _task != -1:
		return
	_rendering = piece_number
	_wavs.clear()
	_wavs.resize(Score.LAYER_COUNT)
	_task = WorkerThreadPool.add_group_task(_render_layer.bind(piece_number, _wavs, _wavs_lock), Score.LAYER_COUNT,
			-1, false, "Music")


## On a worker thread: one layer of `piece_number`, into `wavs`.
static func _render_layer(layer: int, piece_number: int, wavs: Array[AudioStreamWAV], lock: Mutex) -> void:
	var wav := Score.to_wav(Score.render_layer(piece_number, layer))
	lock.lock()
	wavs[layer] = wav
	lock.unlock()


## A finished render joins the cache.
func _collect_render() -> void:
	if _task == -1 or not WorkerThreadPool.is_group_task_completed(_task):
		return
	WorkerThreadPool.wait_for_group_task_completion(_task)
	_streams[_rendering] = Score.stream_of(_wavs)
	_task = -1
	_rendering = -1
	_forget_old_pieces()


## Keeps CACHED pieces at most: the oldest go first, but never the theme, the
## piece wanted or one still playing.
func _forget_old_pieces() -> void:
	for old: int in _streams.keys():
		if _streams.size() <= CACHED:
			return
		if old != Score.THEME and old != piece and deck_of(old) == null:
			_streams.erase(old)


## The piece wanted, once rendered, starts on the quieter deck (stopping what
## was left on it) at its layers' volumes, and fades in from silence.
func _start_deck() -> void:
	if deck_of(piece) or not _streams.has(piece):
		return
	var deck := _decks[0] if _decks[0].level <= _decks[1].level else _decks[1]
	deck.player.stop()
	deck.piece = piece
	deck.player.stream = _streams[piece]
	deck.level = 0.0
	deck.layers = targets.duplicate()
	_apply(deck)
	deck.player.play()


## Each deck toward full (the piece wanted) or silence (any other, which then
## stops), and the wanted piece's layers toward their targets.
func _fade(delta: float) -> void:
	_pause_level = move_toward(_pause_level, PAUSED_LEVEL if paused else 1.0, delta / LAYER_FADE)
	for deck in _decks:
		if deck.piece == -1:
			continue
		var wanted := deck.piece == piece
		deck.level = move_toward(deck.level, 1.0 if wanted else 0.0, delta / CROSSFADE)
		if wanted:
			for layer in Score.LAYER_COUNT:
				deck.layers[layer] = move_toward(deck.layers[layer], targets[layer], delta / LAYER_FADE)
		elif deck.level <= 0.0:
			deck.player.stop()
			deck.player.stream = null
			deck.piece = -1
			continue
		_apply(deck)


## The deck's volumes on its player and its stream's layers.
func _apply(deck: Deck) -> void:
	deck.player.volume_db = _db(deck.level * _pause_level)
	var stream := deck.player.stream as AudioStreamSynchronized
	if stream == null:
		return
	for layer in Score.LAYER_COUNT:
		stream.set_sync_stream_volume(layer, _db(deck.layers[layer] * Score.LAYER_PEAKS[layer]))


static func _db(linear: float) -> float:
	return maxf(linear_to_db(linear), SILENT_DB) if linear > 0.0 else SILENT_DB
