class_name WaveRunner
extends RefCounted
## A stage's waves: a countdown, each wave's enemies in groups, a break
## once all are dead, and the boss wave last when there is one. The stage
## ticks it (so it pauses with the game), spawns what it asks for, and
## reports each death.

signal spawn_requested(enemy_id: StringName, wave: int)
signal wave_started(wave: int)
signal break_started(seconds: float)
signal break_ended
signal boss_wave_started(boss_id: StringName)
signal cleared

enum State { INTRO, FIGHT, BREAK, DONE }

const INTRO_TIME := 5.0
const BREAK_TIME := 20.0
const GROUP_SIZE := 3
const GROUP_GAP := 1.2

var state := State.INTRO
## The wave being fought or coming next (1-based); the boss wave is last.
var wave := 0
var boss := &""

var _waves: Array = []
var _countdown := INTRO_TIME
var _to_spawn: Array[StringName] = []
var _spawn_left := 0.0
var _alive := 0
var _done := 0


func _init(stage_waves: Array, boss_id := &"") -> void:
	_waves = stage_waves
	boss = boss_id


func wave_count() -> int:
	return _waves.size()


## The waves, the boss wave included.
func total_waves() -> int:
	return _waves.size() + (1 if boss != &"" else 0)


func waves_done() -> int:
	return _done


func is_boss_wave() -> bool:
	return boss != &"" and wave > _waves.size()


## The countdown before wave 1, or a break, is running.
func is_waiting() -> bool:
	return state == State.INTRO or state == State.BREAK


func countdown() -> float:
	return maxf(_countdown, 0.0) if is_waiting() else 0.0


## Enemies still to beat this wave, those not spawned yet included.
func alive() -> int:
	return _alive + _to_spawn.size()


func tick(delta: float) -> void:
	match state:
		State.INTRO, State.BREAK:
			_countdown -= delta
			if _countdown <= 0.0:
				_start_next()
		State.FIGHT:
			if not _to_spawn.is_empty():
				_spawn_left -= delta
				if _spawn_left <= 0.0:
					_spawn_group()


## Starts the next wave now. Returns the seconds skipped (0 mid-wave).
func skip() -> float:
	if not is_waiting():
		return 0.0
	var skipped := maxf(_countdown, 0.0)
	_start_next()
	return skipped


## The stage ends here, cleared (Act 1's cutscene, or the last wave).
func finish() -> void:
	if state == State.DONE:
		return
	state = State.DONE
	cleared.emit()


## An enemy that wasn't asked for (debug) still has to die.
func enemy_spawned() -> void:
	_alive += 1


func enemy_died() -> void:
	_alive = maxi(_alive - 1, 0)
	if state == State.FIGHT and alive() == 0:
		_wave_done()


func _start_next() -> void:
	if state == State.BREAK:
		break_ended.emit()
	wave += 1
	state = State.FIGHT
	if is_boss_wave():
		_to_spawn = [boss]
		boss_wave_started.emit(boss)
	else:
		_to_spawn.assign(_waves[wave - 1])
	_spawn_left = 0.0
	wave_started.emit(wave)


func _spawn_group() -> void:
	for i in mini(GROUP_SIZE, _to_spawn.size()):
		_alive += 1
		spawn_requested.emit(_to_spawn.pop_front(), wave)
	_spawn_left = GROUP_GAP


func _wave_done() -> void:
	_done += 1
	if wave >= total_waves():
		finish()
	else:
		state = State.BREAK
		_countdown = BREAK_TIME
		break_started.emit(BREAK_TIME)
