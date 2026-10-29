class_name EndlessRunner
extends WaveRunner
## Endless mode's waves: each made up by EndlessPlan as it starts, with the
## run's own RNG, without end. It never emits `cleared` and has no last enemy:
## a run ends when Lucian dies or the player leaves. After a boss wave it
## emits boss_cleared and holds the break (no countdown, no skip) until
## release(): the modifier pick.

## A boss wave was won; the break waits for release().
signal boss_cleared(wave: int)

## total_waves() and wave_count(): there is no last wave.
const NO_END := -1

## Elites per wave × this (modifier #2 sets 2).
var elite_mult := 1
## The break after a boss wave waits while this is true.
var held := false
## The run's last mini boss (and the inherited `boss`, its last boss): neither
## comes twice in a row.
var mini_boss := &""
## Waves won this run (a debug jump's skipped waves don't count).
var waves_cleared: int:
	get:
		return _done

var _rng := RandomNumberGenerator.new()


## A negative seed picks a random one.
func _init(rng_seed := -1) -> void:
	super([])
	if rng_seed >= 0:
		_rng.seed = rng_seed
	else:
		_rng.randomize()


func wave_count() -> int:
	return NO_END


func total_waves() -> int:
	return NO_END


func is_boss_wave() -> bool:
	return EndlessPlan.is_boss_wave(wave)


func is_mini_boss_wave() -> bool:
	return EndlessPlan.is_mini_boss_wave(wave)


## The held break ends: its countdown runs from the start.
func release() -> void:
	held = false


func tick(delta: float) -> void:
	if not held:
		super(delta)


func skip() -> float:
	return 0.0 if held else super()


## Never: there is no stage to clear.
func finish() -> void:
	pass


## Debug: the next boss wave (the next tenth) comes next, straight away.
func skip_to_boss() -> void:
	_skip_to((wave / EndlessPlan.BOSS_EVERY + 1) * EndlessPlan.BOSS_EVERY - 1)


## Debug: there is no last wave.
func skip_to_last_wave() -> void:
	pass


func _wave_ids() -> Array:
	var ids := EndlessPlan.wave(wave, _rng, elite_mult, boss, mini_boss)
	if is_boss_wave():
		boss = ids[0]
	elif is_mini_boss_wave():
		mini_boss = ids.back()
	return ids


func _is_last_wave() -> bool:
	return false


func _start_break() -> void:
	held = is_boss_wave()
	if held:
		boss_cleared.emit(wave)
	super()
