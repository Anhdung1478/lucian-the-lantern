class_name Thresh
extends Boss
## Act 1's Thresh, scripted. Death Sentence: a hook along a line warning
## that pulls Lucian in. Flay: a cone that pushes him away. At half HP the
## fight stops: `phase_ended` starts the cutscene, and nothing hurts him.

signal phase_ended

const HOOK_LENGTH := 1000.0
const HOOK_WIDTH := 70.0
const HOOK_WARN := 0.9
const HOOK_SPEED := 1400.0
const HOOK_DAMAGE := 80.0
const HOOK_COOLDOWN := 9.0
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

var stopped := false


func _ready() -> void:
	super()
	add_skill(&"death_sentence", HOOK_COOLDOWN, HOOK_LENGTH, 2.0, death_sentence)
	add_skill(&"flay", FLAY_COOLDOWN, FLAY_LENGTH, 4.0, flay)


## The hook: a line warning, then the chain flies; a hit pulls Lucian in.
func death_sentence() -> float:
	var toward := global_position.direction_to(target.global_position)
	face(target.global_position)
	var warning := GroundWarning.line(global_position, toward, HOOK_LENGTH, HOOK_WIDTH, HOOK_WARN)
	warning.fired.connect(_throw_hook.bind(toward))
	warning_parent.add_child(warning)
	return HOOK_WARN + HOOK_LENGTH / HOOK_SPEED


## Flay: a cone warning, then a hit that pushes Lucian away.
func flay() -> float:
	var toward := global_position.direction_to(target.global_position)
	face(target.global_position)
	var warning := GroundWarning.cone(global_position, toward, FLAY_LENGTH, FLAY_ANGLE, FLAY_WARN)
	warning.fired.connect(_flay_lands.bind(warning))
	warning_parent.add_child(warning)
	return FLAY_WARN + 0.2


func _think(delta: float) -> void:
	if not stopped:
		super(delta)


## HP never goes under half; reaching it ends the fight, once.
func _lose_hp(amount: float) -> void:
	if stopped:
		return
	super(minf(amount, maxf(hp - max_hp * PHASE_END, 0.0)))
	if hp <= max_hp * PHASE_END:
		stopped = true
		phase_ended.emit()


func _throw_hook(toward: Vector2) -> void:
	if stopped:
		return
	var hook := fire_bolt(skill_hit(HOOK_DAMAGE, DamageInfo.Type.MAGIC, &"death_sentence"), HOOK_SPEED, HOOK_LENGTH, toward)
	hook.hit_radius = HOOK_WIDTH * 0.5
	hook.color = CHAIN_COLOR
	hook.tether = self
	hook.hit_lucian.connect(_pull)
	Sfx.play(&"hook")


func _pull() -> void:
	if is_instance_valid(target):
		target.displace(global_position + global_position.direction_to(target.global_position) * PULL_GAP, PULL_SPEED)


func _flay_lands(warning: GroundWarning) -> void:
	if stopped or not warning.covers(target.global_position, Lucian.HIT_RADIUS):
		return
	if target.take_damage(skill_hit(FLAY_DAMAGE, DamageInfo.Type.MAGIC, &"flay")):
		target.displace(target.global_position + global_position.direction_to(target.global_position) * FLAY_PUSH, PULL_SPEED)
