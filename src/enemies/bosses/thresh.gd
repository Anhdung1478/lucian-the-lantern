class_name Thresh
extends Boss
## Act 1's Thresh, scripted. Death Sentence: a hook along a line warning
## that pulls Lucian in. Flay: a cone that pushes him away. At half HP the
## fight stops: `phase_ended` starts the cutscene (a debug one just leaves),
## and nothing hurts him.
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
	hook.style = EnemyProjectile.Style.HOOK
	hook.tether = self
	hook.hit_lucian.connect(_pull)
	Sfx.play(&"hook")
	return hook


func _pull() -> void:
	if is_instance_valid(target):
		target.displace(global_position + global_position.direction_to(target.global_position) * PULL_GAP, PULL_SPEED)


func _flay_lands(warning: GroundWarning) -> void:
	if stopped:
		return
	if Juice.on():
		var slash := _FlaySlashVfx.new()
		slash.setup(warning.global_position, warning.direction, FLAY_LENGTH, FLAY_ANGLE, CHAIN_COLOR)
		_place(slash)
	if not warning.covers(target.global_position, Lucian.HIT_RADIUS):
		return
	if target.take_damage(skill_hit(flay_damage, DamageInfo.Type.MAGIC, &"flay")):
		target.displace(target.global_position + global_position.direction_to(target.global_position) * flay_push, PULL_SPEED)


class _FlaySlashVfx extends Node2D:
	const LIFETIME := 0.34
	var _elapsed := 0.0
	var _length := 400.0
	var _angle := PI * 70.0 / 180.0
	var _color := Color("8fe3b0")
	var _sparks: Array[Dictionary] = []

	func setup(from: Vector2, toward: Vector2, length: float, angle: float, chain_color: Color) -> void:
		position = from
		rotation = toward.angle()
		_length = length
		_angle = angle
		_color = chain_color
		z_index = 7
		for i in 12:
			_sparks.append({
				"ang": randf_range(-angle * 0.52, angle * 0.52),
				"dist": randf_range(length * 0.35, length * 1.05),
				"size": randf_range(2.5, 5.5),
			})

	func _process(delta: float) -> void:
		_elapsed += delta
		if _elapsed >= LIFETIME:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := clampf(_elapsed / LIFETIME, 0.0, 1.0)
		var sweep := 1.0 - pow(1.0 - minf(t / 0.45, 1.0), 2.5)
		var alpha := 1.0 - pow(t, 1.5)
		var half_a := _angle * 0.5
		var start_a := -half_a
		var end_a := lerpf(-half_a, half_a, sweep)
		var cur_r := _length * (0.48 + 0.52 * sweep)
		# Translucent emerald cone-sweep wash.
		var wash := PackedVector2Array([Vector2.ZERO])
		for i in 13:
			var a := lerpf(start_a, end_a, float(i) / 12.0)
			wash.append(Vector2.from_angle(a) * cur_r)
		if wash.size() >= 3:
			draw_colored_polygon(wash, Color(_color, alpha * 0.22))
		# Curved glowing emerald chain-slash arc ripping across the cone.
		var arc_steps := 14
		var arc_pts := PackedVector2Array()
		for i in arc_steps + 1:
			var frac := float(i) / arc_steps
			var a := lerpf(start_a, end_a, frac)
			var r_curve := cur_r * (0.86 + 0.14 * sin(frac * PI))
			arc_pts.append(Vector2.from_angle(a) * r_curve)
		if arc_pts.size() >= 2:
			draw_polyline(arc_pts, Color(_color, alpha * 0.4), 18.0, true)
			draw_polyline(arc_pts, Color("1a332b", alpha * 0.92), 8.5, true)
			draw_polyline(arc_pts, Color(_color.lightened(0.25), alpha * 0.95), 4.2, true)
			draw_polyline(arc_pts, Color("e8fff4", alpha * 0.95), 1.8, true)
			# Iron chain-link notches along the sweeping blade.
			for i in range(1, arc_pts.size() - 1, 2):
				var p0 := arc_pts[i]
				var tangent := (arc_pts[i + 1] - arc_pts[i - 1]).normalized()
				var normal := tangent.orthogonal()
				draw_line(p0 - normal * 6.5, p0 + normal * 6.5, Color("142420", alpha * 0.95), 3.0, true)
				draw_circle(p0, 3.2, Color("b8ffdc", alpha * 0.9))
		# Trailing soul sparks thrown outward by the chain lash.
		for s: Dictionary in _sparks:
			var ang: float = s.ang
			var dist: float = s.dist
			var sz: float = s.size
			if ang <= end_a + 0.08:
				var pos := Vector2.from_angle(ang) * (dist * (0.4 + 0.6 * t))
				draw_circle(pos, sz * (1.0 - t * 0.5), Color("b8ffdc", alpha))
