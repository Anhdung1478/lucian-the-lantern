class_name UnitMotion
extends Node
## Small motion that makes a unit's art feel alive: a sway and a swell with
## every step while it walks, a lunge or a recoil when it attacks, a squash
## when it is hit, a scale-in when it appears and a squash as it dies. It
## moves only `art` (the sprite under the unit's visuals): its offset, turn
## and scale. The unit's body, hitboxes, facing and timing never change.
## Nothing moves while Juice is off; headless, it never runs at all. It runs
## with the physics frames, as the units' own steps do.

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
const KICK_OUT := 0.3
## A hit: along its facing it shrinks SQUASH.x and across it swells SQUASH.y,
## then springs back over SQUASH_TIME.
const SQUASH := Vector2(0.16, 0.1)
const SQUASH_TIME := 0.16
## It appears at SPAWN_SCALE of its size and grows over SPAWN_TIME.
const SPAWN_SCALE := 0.55
const SPAWN_TIME := 0.25
## Dying, it flattens to this scale.
const DEATH_SCALE := Vector2(1.15, 0.5)

## The sprite it moves, and the unit's size (its radius), for lunges.
var art: Node2D
var size := 30.0

var _unit: Node2D
## Where the art sits when nothing moves it.
var _home := Vector2.ZERO
var _last := Vector2.ZERO
var _phase := 0.0
## How much of the sway shows, 0 to 1.
var _walk := 0.0
## A lunge (forward) or a recoil (back): its distance, seconds and time left.
var _kick := 0.0
var _kick_time := 0.0
var _kick_left := 0.0
var _squash_left := 0.0
var _spawn_left := 0.0
var _death_time := 0.0
var _death_left := 0.0
## The art is back where the unit's art was drawn: nothing to write.
var _rest := true


## Moves `sprite`, the art of `unit` (it walks when `unit` moves), a unit of
## `unit_size` across.
func setup(sprite: Node2D, unit: Node2D, unit_size: float) -> void:
	art = sprite
	size = unit_size
	_unit = unit
	_home = sprite.position


func _ready() -> void:
	set_physics_process(Juice.renders)
	if _unit:
		_last = _unit.global_position


## A melee hit: a short step toward what the unit faces, and back.
func lunge() -> void:
	_start_kick(size * LUNGE, LUNGE_TIME)


## A shot: a short kick back, and forward again.
func recoil() -> void:
	_start_kick(-size * RECOIL, RECOIL_TIME)


## A hit taken: a quick squash.
func flinch() -> void:
	if Juice.on():
		_squash_left = SQUASH_TIME


## The unit appears: its art grows in.
func appear() -> void:
	if Juice.on():
		_spawn_left = SPAWN_TIME
		_apply()


## The unit dies: its art flattens over `seconds`.
func die(seconds: float) -> void:
	if Juice.on():
		_death_time = maxf(seconds, 0.01)
		_death_left = _death_time


## Something still moves the art.
func is_moving() -> bool:
	return not _rest


func _start_kick(distance: float, seconds: float) -> void:
	if not Juice.on():
		return
	_kick = distance
	_kick_time = seconds
	_kick_left = seconds


func _physics_process(delta: float) -> void:
	var here := _unit.global_position
	var moved := here.distance_to(_last)
	_last = here
	var walking := moved > 0.01 and Juice.on()
	if walking:
		_phase = fmod(_phase + minf(moved, MAX_STEP) / STRIDE * TAU, TAU)
	_walk = move_toward(_walk, 1.0 if walking else 0.0, delta / SETTLE)
	_kick_left = maxf(_kick_left - delta, 0.0)
	_squash_left = maxf(_squash_left - delta, 0.0)
	_spawn_left = maxf(_spawn_left - delta, 0.0)
	_death_left = maxf(_death_left - delta, 0.0)
	_apply()


## Writes the art's offset, turn and scale for this moment; once, back to
## rest, when nothing moves it any more.
func _apply() -> void:
	if _walk <= 0.0 and _kick_left <= 0.0 and _squash_left <= 0.0 and _spawn_left <= 0.0 and _death_time <= 0.0:
		if not _rest:
			_rest = true
			art.position = _home
			art.rotation = 0.0
			art.scale = Vector2.ONE
		return
	_rest = false
	var step := sin(_phase)
	var grow := Vector2.ONE * (1.0 + SWELL * absf(step) * _walk)
	if _squash_left > 0.0:
		var pressed := _squash_left / SQUASH_TIME
		grow *= Vector2(1.0 - SQUASH.x * pressed * pressed, 1.0 + SQUASH.y * pressed * pressed)
	if _spawn_left > 0.0:
		var hidden := _spawn_left / SPAWN_TIME
		grow *= lerpf(1.0, SPAWN_SCALE, hidden * hidden)
	if _death_time > 0.0:
		var gone := 1.0 - _death_left / _death_time
		grow *= Vector2.ONE.lerp(DEATH_SCALE, 1.0 - (1.0 - gone) * (1.0 - gone))
	art.position = _home + Vector2(_kick * _kick_curve(), 0.0)
	art.rotation = step * SWAY * _walk
	art.scale = grow


## How far out the kick is, 0 to 1: quickly out, then smoothly back.
func _kick_curve() -> float:
	if _kick_left <= 0.0:
		return 0.0
	var t := 1.0 - _kick_left / _kick_time
	if t < KICK_OUT:
		return sin(t / KICK_OUT * PI * 0.5)
	return 0.5 + 0.5 * cos((t - KICK_OUT) / (1.0 - KICK_OUT) * PI)
