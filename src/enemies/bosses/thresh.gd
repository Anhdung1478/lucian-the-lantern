class_name Thresh
extends Boss
## Act 1's Thresh, scripted. Death Sentence: a hook along a line warning
## that pulls Lucian in. Flay: a cone that pushes him away. At half HP the
## fight stops: `phase_ended` starts the cutscene, and nothing hurts him.
## The skill numbers are vars that start at these constants; Act 6's Thresh
## (ThreshFinal) sets his own and never stops (`stop_share` 0).

signal phase_ended

const HOOK_LENGTH := 1000.0
const HOOK_WIDTH := 70.0
const HOOK_WARN := 0.9
const HOOK_SPEED := 1400.0
const HOOK_DAMAGE := 80.0
const HOOK_COOLDOWN := 9.0
## Seconds into the fight before the first hook and the first Flay.
const HOOK_FIRST := 2.0
const FLAY_FIRST := 4.0
## A hooked Lucian lands this far in front of Thresh.
const PULL_GAP := 120.0
const PULL_SPEED := 1600.0
const FLAY_LENGTH := 400.0
const FLAY_ANGLE := PI * 70.0 / 180.0
const FLAY_WARN := 0.6
const FLAY_DAMAGE := 60.0
const FLAY_PUSH := 250.0
const FLAY_COOLDOWN := 7.0
## The share of HP where Act 1's fight ends.
const PHASE_END := 0.5
const CHAIN_COLOR := Color("8fe3b0")
## Where his lantern hangs, from his center (the cutscene's soul flies there).
const LANTERN_OFFSET := Vector2(-20, 46)

## The fight stops at this share of max HP (phase_ended); 0 = it never does.
var stop_share := PHASE_END
var hook_damage := HOOK_DAMAGE
var hook_warn := HOOK_WARN
var hook_cooldown := HOOK_COOLDOWN
var flay_damage := FLAY_DAMAGE
var flay_push := FLAY_PUSH
var flay_cooldown := FLAY_COOLDOWN
## The fight is stopped: he loses no HP, thinks nothing and throws nothing.
## Act 1's stops for good at half HP; ThreshFinal's while he is down, rising
## or fallen.
var stopped := false


func _ready() -> void:
	super()
	add_skill(&"death_sentence", hook_cooldown, HOOK_LENGTH, HOOK_FIRST, death_sentence)
	add_skill(&"flay", flay_cooldown, FLAY_LENGTH, FLAY_FIRST, flay)


## The hook: a line warning, then the chain flies; a hit pulls Lucian in.
func death_sentence() -> float:
	var toward := global_position.direction_to(target.global_position)
	face(target.global_position)
	var warning := GroundWarning.line(global_position, toward, HOOK_LENGTH, HOOK_WIDTH, hook_warn)
	warning.fired.connect(_throw_hook.bind(toward))
	_place(warning)
	return hook_warn + HOOK_LENGTH / HOOK_SPEED


## Flay: a cone warning, then a hit that pushes Lucian away.
func flay() -> float:
	var toward := global_position.direction_to(target.global_position)
	face(target.global_position)
	var warning := GroundWarning.cone(global_position, toward, FLAY_LENGTH, FLAY_ANGLE, FLAY_WARN)
	warning.fired.connect(_flay_lands.bind(warning))
	_place(warning)
	return FLAY_WARN + 0.2


func _think(delta: float) -> void:
	if not stopped:
		super(delta)


## HP never goes under stop_share of it; reaching it ends the fight, once.
## With stop_share 0, HP is lost as any boss loses it.
func _lose_hp(amount: float) -> void:
	if stopped:
		return
	if stop_share <= 0.0:
		super(amount)
		return
	super(minf(amount, maxf(hp - max_hp * stop_share, 0.0)))
	if hp <= max_hp * stop_share:
		stopped = true
		phase_ended.emit()


## A warning (or another mark of his) goes on the ground, under warning_parent.
func _place(node: Node) -> void:
	warning_parent.add_child(node)


## The chain flies along `toward`; null once the fight has stopped.
func _throw_hook(toward: Vector2) -> EnemyProjectile:
	if stopped:
		return null
	var hook := fire_bolt(skill_hit(hook_damage, DamageInfo.Type.MAGIC, &"death_sentence"), HOOK_SPEED, HOOK_LENGTH, toward)
	hook.hit_radius = HOOK_WIDTH * 0.5
	hook.color = CHAIN_COLOR
	hook.tether = self
	hook.hit_lucian.connect(_pull)
	Sfx.play(&"hook")
	return hook


func _pull() -> void:
	if is_instance_valid(target):
		target.displace(global_position + global_position.direction_to(target.global_position) * PULL_GAP, PULL_SPEED)


func _flay_lands(warning: GroundWarning) -> void:
	if stopped or not warning.covers(target.global_position, Lucian.HIT_RADIUS):
		return
	if target.take_damage(skill_hit(flay_damage, DamageInfo.Type.MAGIC, &"flay")):
		target.displace(target.global_position + global_position.direction_to(target.global_position) * flay_push, PULL_SPEED)
