class_name UnitMotion
extends Node
## Small motion that makes a unit's art feel alive: a sway and a swell with
## every step while it walks, a lunge or a recoil when it attacks, a squash
## when it is hit, a scale-in when it appears and a collapse as it dies. It
## moves only `art` (the sprite under the unit's visuals): its offset, turn
## and scale. The unit's body, hitboxes, facing and timing never change.
## Nothing moves while Juice is off; headless, it never runs at all. It runs
## with the physics frames, as the units' own steps do.

enum Profile { DEFAULT, BIPED, FLOATING, FLYING, HEAVY, SKITTER, WHEELED }

## Ground covered per full sway (left, then right); how far the art turns
## each way (radians) and how much it swells at each step.
const STRIDE := 150.0
const SWAY := 0.075
const SWELL := 0.035
## A frame's travel past this (a dash, a charge, a pull) adds no more stride.
const MAX_STEP := 10.0
## Seconds for the sway to come in, and to settle once the unit stands.
const SETTLE := 0.14
## A lunge goes this share of the unit's size toward what it faces and comes
## back; a recoil goes back and returns. Seconds for each, and the share of
## that time spent going out.
const LUNGE := 0.4
const LUNGE_TIME := 0.22
const RECOIL := 0.14
const RECOIL_TIME := 0.14
const RECOIL_TWIST := 0.085
const KICK_OUT := 0.3
## A hit: along its facing it shrinks SQUASH.x and across it swells SQUASH.y,
## then springs back over SQUASH_TIME.
const SQUASH := Vector2(0.16, 0.1)
const SQUASH_TIME := 0.16
## A dash: forward elongation along facing that eases cleanly back to 1.0.
const DASH_STRETCH := Vector2(1.16, 0.86)
## A cast windup: subtle pullback and coiled squash before firing.
const BRACE_PULL := 0.09
const BRACE_SQUASH := Vector2(0.93, 1.06)
## Calm seconds before archetype idle breathing/hover smoothly fades in.
const IDLE_DELAY := 0.45
const IDLE_FADE := 0.35
## It appears at SPAWN_SCALE of its size and grows over SPAWN_TIME.
const SPAWN_SCALE := 0.55
const SPAWN_TIME := 0.25
## Dying, it shrinks and flattens cleanly regardless of facing.
const DEATH_SCALE := Vector2(0.82, 0.42)

## The sprite it moves, and the unit's size (its radius), for lunges.
var art: Node2D
var size := 30.0
## Movement archetype; DEFAULT preserves exact raw motion without idle pulse.
var profile := Profile.DEFAULT

var _unit: Node2D
## When art is a Sprite2D moving itself (e.g. SkinPreview), write Sprite2D.offset
## instead of Node2D.position so external position tweens never conflict.
var _use_offset := false
## Where the art sits when nothing moves it.
var _home := Vector2.ZERO
var _last := Vector2.ZERO
var _phase := 0.0
## How much of the sway shows, 0 to 1.
var _walk := 0.0
## A lunge (forward) or a recoil (back): its distance, twist, seconds and time left.
var _kick := 0.0
var _kick_twist := 0.0
var _kick_time := 0.0
var _kick_left := 0.0
var _squash_left := 0.0
var _dash_time := 0.0
var _dash_left := 0.0
var _brace_time := 0.0
var _brace_left := 0.0
var _spawn_left := 0.0
var _death_time := 0.0
var _death_left := 0.0
var _ambient_phase := 0.0
var _idle_time := 0.0
## The art is back where the unit's art was drawn: nothing to write.
var _rest := true


## Moves `sprite`, the art of `unit` (it walks when `unit` moves), a unit of
## `unit_size` across.
func setup(sprite: Node2D, unit: Node2D, unit_size: float) -> void:
	art = sprite
	size = unit_size
	_unit = unit
	_use_offset = sprite is Sprite2D and sprite == unit
	_home = (sprite as Sprite2D).offset if _use_offset else sprite.position


func _ready() -> void:
	set_physics_process(Juice.renders)
	_ambient_phase = randf() * TAU
	if _unit:
		_last = _unit.global_position


## A melee hit: a short step toward what the unit faces, and back.
func lunge() -> void:
	if profile == Profile.HEAVY:
		_start_kick(size * LUNGE * 1.25, LUNGE_TIME * 1.2)
	else:
		_start_kick(size * LUNGE, LUNGE_TIME)


## A shot: a short kick back, and forward again.
func recoil(strength := 1.0) -> void:
	var duration := RECOIL_TIME * lerpf(1.0, 1.25, clampf(strength - 1.0, 0.0, 1.0))
	_start_kick(-size * RECOIL * strength, duration)


## An alternating twin-gun shot: kick back plus a snappy shoulder twist
## (`side`: -1.0 for left gun, +1.0 for right gun).
func recoil_side(side: float) -> void:
	recoil()
	if Juice.on():
		_kick_twist = clampf(side, -1.0, 1.0) * RECOIL_TWIST


## A dash: aerodynamic forward stretch that eases cleanly back to 1.0.
func dash_stretch(seconds: float) -> void:
	if Juice.on():
		_dash_time = maxf(seconds, 0.01)
		_dash_left = _dash_time
		_idle_time = 0.0


## A cast windup: subtle pullback and coiled squash over `seconds`.
func brace(seconds: float) -> void:
	if Juice.on():
		_brace_time = maxf(seconds, 0.01)
		_brace_left = _brace_time
		_idle_time = 0.0


## A hit taken: a quick squash.
func flinch() -> void:
	if Juice.on():
		_squash_left = SQUASH_TIME
		_idle_time = 0.0


## The unit appears: its art grows in.
func appear() -> void:
	if Juice.on():
		_spawn_left = SPAWN_TIME
		_idle_time = 0.0
		_apply()


## The unit dies: its art collapses and recoils over `seconds`.
func die(seconds: float) -> void:
	if Juice.on():
		_death_time = maxf(seconds, 0.01)
		_death_left = _death_time
		_idle_time = 0.0
		_start_kick(-size * RECOIL * 0.85, minf(seconds * 0.55, 0.22))


## Clears active motion and returns the art cleanly to rest.
func reset() -> void:
	_walk = 0.0
	_kick = 0.0
	_kick_twist = 0.0
	_kick_left = 0.0
	_squash_left = 0.0
	_dash_left = 0.0
	_brace_left = 0.0
	_spawn_left = 0.0
	_death_time = 0.0
	_death_left = 0.0
	_idle_time = 0.0
	if _unit:
		_last = _unit.global_position
	if art:
		_rest = true
		_write_offset(_home)
		art.rotation = 0.0
		art.scale = Vector2.ONE


## Something still moves the art.
func is_moving() -> bool:
	return not _rest


func _start_kick(distance: float, seconds: float) -> void:
	if not Juice.on():
		return
	_kick = distance
	_kick_twist = 0.0
	_kick_time = seconds
	_kick_left = seconds
	_idle_time = 0.0


func _physics_process(delta: float) -> void:
	var here := _unit.global_position
	var moved := here.distance_to(_last)
	_last = here
	var on := Juice.on()
	var walking := moved > 0.01 and on
	if walking:
		_phase = fmod(_phase + minf(moved, MAX_STEP) / STRIDE * TAU, TAU)
	_walk = move_toward(_walk, 1.0 if walking else 0.0, delta / SETTLE)
	_kick_left = maxf(_kick_left - delta, 0.0)
	_squash_left = maxf(_squash_left - delta, 0.0)
	_dash_left = maxf(_dash_left - delta, 0.0)
	_brace_left = maxf(_brace_left - delta, 0.0)
	_spawn_left = maxf(_spawn_left - delta, 0.0)
	_death_left = maxf(_death_left - delta, 0.0)
	if on and profile != Profile.DEFAULT:
		_ambient_phase = fmod(_ambient_phase + delta * TAU, TAU * 60.0)
		var busy := walking or _walk > 0.0 or _kick_left > 0.0 or _squash_left > 0.0 \
			or _dash_left > 0.0 or _brace_left > 0.0 or _spawn_left > 0.0 or _death_time > 0.0
		_idle_time = 0.0 if busy else _idle_time + delta
	else:
		_idle_time = 0.0
	_apply()


## Writes the art's offset, turn and scale for this moment; once, back to
## rest, when nothing moves it any more.
func _apply() -> void:
	var idle_blend := 0.0
	if Juice.on() and profile != Profile.DEFAULT and _death_time <= 0.0 and _idle_time > IDLE_DELAY:
		idle_blend = clampf((_idle_time - IDLE_DELAY) / IDLE_FADE, 0.0, 1.0)
	if _walk <= 0.0 and _kick_left <= 0.0 and _squash_left <= 0.0 and _dash_left <= 0.0 \
			and _brace_left <= 0.0 and _spawn_left <= 0.0 and _death_time <= 0.0 and idle_blend <= 0.0:
		if not _rest:
			_rest = true
			_write_offset(_home)
			art.rotation = 0.0
			art.scale = Vector2.ONE
		return
	_rest = false
	var step := sin(_phase)
	var sway_rot := step * SWAY * _walk
	var grow := Vector2.ONE * (1.0 + SWELL * absf(step) * _walk)
	var extra_offset := Vector2.ZERO
	var extra_rot := 0.0
	match profile:
		Profile.BIPED:
			sway_rot = step * (SWAY * 1.05) * _walk
			if idle_blend > 0.0:
				var breath := sin(_ambient_phase * 0.42) * 0.015 * idle_blend
				grow *= Vector2(1.0 - breath * 0.4, 1.0 + breath)
		Profile.FLOATING:
			sway_rot = step * (SWAY * 0.35) * _walk
			grow = Vector2.ONE * (1.0 + SWELL * 0.45 * absf(step) * _walk)
			var amt := maxf(idle_blend, _walk)
			if amt > 0.0:
				var bob := sin(_ambient_phase * 0.4) * 3.5 * amt
				extra_offset += Vector2(0.0, bob).rotated(-_parent_rotation())
				extra_rot += sin(_ambient_phase * 0.28) * 0.045 * amt
				grow *= 1.0 + sin(_ambient_phase * 0.4) * 0.022 * amt
		Profile.FLYING:
			sway_rot = step * (SWAY * 0.55) * _walk
			grow = Vector2.ONE * (1.0 + SWELL * 0.5 * absf(step) * _walk)
			var amt := maxf(idle_blend, _walk)
			if amt > 0.0:
				var wing := sin(_ambient_phase * 0.85) * amt
				extra_offset += Vector2(0.0, -wing * 3.0).rotated(-_parent_rotation())
				grow *= Vector2(1.0 - wing * 0.025, 1.0 + wing * 0.055)
		Profile.HEAVY:
			sway_rot = step * (SWAY * 0.75) * _walk
			grow = Vector2.ONE * (1.0 + SWELL * 1.75 * absf(step) * _walk)
			if idle_blend > 0.0:
				var breath := sin(_ambient_phase * 0.28) * 0.02 * idle_blend
				grow *= Vector2(1.0 + breath * 0.35, 1.0 + breath)
		Profile.SKITTER:
			var quick := sin(_phase * 2.0)
			sway_rot = quick * (SWAY * 1.2) * _walk
			grow = Vector2.ONE * (1.0 + SWELL * 1.15 * absf(quick) * _walk)
			if idle_blend > 0.0:
				var breath := sin(_ambient_phase * 0.6) * 0.018 * idle_blend
				grow *= Vector2(1.0 + breath, 1.0 - breath * 0.5)
		Profile.WHEELED:
			var rattle := sin(_phase * 4.0)
			sway_rot = step * (SWAY * 0.18) * _walk
			grow = Vector2(1.0 + 0.01 * absf(rattle) * _walk, 1.0 + 0.024 * rattle * _walk)
			extra_offset.x += rattle * 0.9 * _walk
			if idle_blend > 0.0:
				var hum := sin(_ambient_phase * 1.1) * 0.008 * idle_blend
				grow *= Vector2(1.0, 1.0 + hum)
	if _brace_left > 0.0:
		var t := clampf(1.0 - _brace_left / _brace_time, 0.0, 1.0)
		var pull := sin(t * PI * 0.5)
		extra_offset.x -= size * BRACE_PULL * pull
		grow *= Vector2.ONE.lerp(BRACE_SQUASH, pull)
	if _dash_left > 0.0:
		var t := clampf(1.0 - _dash_left / _dash_time, 0.0, 1.0)
		var stretch := sin(pow(t, 0.6) * PI)
		grow *= Vector2.ONE.lerp(DASH_STRETCH, stretch)
	if _squash_left > 0.0:
		var pressed := _squash_left / SQUASH_TIME
		grow *= Vector2(1.0 - SQUASH.x * pressed * pressed, 1.0 + SQUASH.y * pressed * pressed)
	if _spawn_left > 0.0:
		var hidden := _spawn_left / SPAWN_TIME
		grow *= lerpf(1.0, SPAWN_SCALE, hidden * hidden)
	if _death_time > 0.0:
		var gone := 1.0 - _death_left / _death_time
		grow *= Vector2.ONE.lerp(DEATH_SCALE, 1.0 - (1.0 - gone) * (1.0 - gone))
	var kick_amount := _kick_curve()
	_write_offset(_home + Vector2(_kick * kick_amount, 0.0) + extra_offset)
	art.rotation = sway_rot + extra_rot + _kick_twist * kick_amount
	art.scale = grow


func _write_offset(value: Vector2) -> void:
	if _use_offset:
		(art as Sprite2D).offset = value
	else:
		art.position = value


func _parent_rotation() -> float:
	if _use_offset:
		return art.rotation
	var parent := art.get_parent()
	return (parent as Node2D).rotation if parent is Node2D else 0.0


## How far out the kick is, 0 to 1: quickly out, then smoothly back.
func _kick_curve() -> float:
	if _kick_left <= 0.0:
		return 0.0
	var t := 1.0 - _kick_left / _kick_time
	if t < KICK_OUT:
		return sin(t / KICK_OUT * PI * 0.5)
	return 0.5 + 0.5 * cos((t - KICK_OUT) / (1.0 - KICK_OUT) * PI)
