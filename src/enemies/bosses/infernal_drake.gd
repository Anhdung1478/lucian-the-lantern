class_name InfernalDrake
extends Boss
## Act 3's first mini boss, in 3-2's last wave. Its fireball burns (the
## data's on-hit burn). Fire Breath: a cone warning, then a hit, and the cone
## burns for a while. Meteor Fall: four circle warnings, one on Lucian and
## three around him, then a hit in each, and each circle burns for a while.
## The burning ground goes down as its warning ends, on the warnings' layer;
## a drake dead by then leaves none.

const BREATH_LENGTH := 550.0
const BREATH_ANGLE := PI / 3.0
const BREATH_WARN := 0.8
const BREATH_DAMAGE := 100.0
## Burning ground, magic damage per second.
const BREATH_BURN := 30.0
const BREATH_COOLDOWN := 9.0
const BREATH_FIRST := 3.0
const METEORS := 4
const METEOR_RADIUS := 120.0
## The meteors after the first (on Lucian) fall this close to him.
const METEOR_SPREAD := 280.0
const METEOR_WARN := 1.2
const METEOR_DAMAGE := 80.0
const METEOR_BURN := 25.0
const METEOR_COOLDOWN := 13.0
const METEOR_FIRST := 6.0
## Meteor Fall is used when Lucian is this close.
const METEOR_REACH := 900.0
## Tries for a meteor spot on walkable ground before it falls on Lucian.
const METEOR_TRIES := 12
## Seconds the burning ground lasts.
const BURN_TIME := 3.0
## Seconds it stands after a skill's warning ends.
const RECOVER := 0.3
## The cone's arc is a polygon of this many sides.
const CONE_SIDES := 16
const FIRE := Color("ff7a2a")


func _ready() -> void:
	super()
	# Used whenever the cone reaches him (his body counts).
	add_skill(&"fire_breath", BREATH_COOLDOWN, BREATH_LENGTH + Lucian.HIT_RADIUS, BREATH_FIRST, fire_breath)
	add_skill(&"meteor_fall", METEOR_COOLDOWN, METEOR_REACH, METEOR_FIRST, meteor_fall)


## A cone warning at Lucian; it hits, then the cone burns.
func fire_breath() -> float:
	var toward := global_position.direction_to(target.global_position)
	face(target.global_position)
	var warning := GroundWarning.cone(global_position, toward, BREATH_LENGTH, BREATH_ANGLE, BREATH_WARN)
	warning.strike(skill_hit(BREATH_DAMAGE, DamageInfo.Type.MAGIC, &"fire_breath"), target)
	warning.fired.connect(_burn_cone.bind(global_position, toward))
	warning_parent.add_child(warning)
	return BREATH_WARN + RECOVER


## METEORS circle warnings round Lucian (see meteor_spots); each hits, then
## burns.
func meteor_fall() -> float:
	face(target.global_position)
	for spot in meteor_spots(target.global_position):
		var warning := GroundWarning.circle(spot, METEOR_RADIUS, METEOR_WARN)
		warning.strike(skill_hit(METEOR_DAMAGE, DamageInfo.Type.MAGIC, &"meteor_fall"), target)
		warning.fired.connect(_burn_circle.bind(spot))
		warning_parent.add_child(warning)
		if Juice.on():
			var streak := _MeteorStreakVfx.new()
			streak.setup(spot, METEOR_WARN, self)
			warning_parent.add_child(streak)
	return METEOR_WARN + RECOVER


## Where the meteors fall: the first on `center`, the rest at random within
## METEOR_SPREAD of it, on walkable ground when the map is known (else on
## `center`, after METEOR_TRIES misses).
func meteor_spots(center: Vector2) -> Array[Vector2]:
	var spots: Array[Vector2] = [center]
	for i in METEORS - 1:
		var spot := center
		for attempt in METEOR_TRIES:
			var tried := center + Vector2.from_angle(randf() * TAU) * METEOR_SPREAD * sqrt(randf())
			if arena == null or arena.is_walkable(tried):
				spot = tried
				break
		spots.append(spot)
	return spots


## The cone from `from` along `toward` as a polygon, its arc in CONE_SIDES steps.
static func cone_outline(from: Vector2, toward: Vector2, length: float, angle: float) -> PackedVector2Array:
	var points := PackedVector2Array([from])
	for i in CONE_SIDES + 1:
		points.append(from + Vector2.from_angle(toward.angle() - angle * 0.5 + angle * i / CONE_SIDES) * length)
	return points


## The fireball: the data's bolt (its burn comes with it), in fire colors.
func _attack() -> void:
	var bolt := fire_bolt(make_hit(), data.projectile_speed, attack_range + BOLT_OVERREACH)
	bolt.color = FIRE
	bolt.style = EnemyProjectile.Style.FIREBALL


## Fire Breath's warning ended: the cone burns, unless the drake is dead.
func _burn_cone(from: Vector2, toward: Vector2) -> void:
	if not dead:
		_lay(HazardZone.burning(BREATH_BURN * skill_scale, DamageInfo.Type.MAGIC, BURN_TIME).set_polygon(cone_outline(from, toward, BREATH_LENGTH, BREATH_ANGLE)))
		if Juice.on():
			var vfx := _FlameBreathVfx.new()
			vfx.setup(from, toward, BREATH_LENGTH, BREATH_ANGLE)
			warning_parent.add_child(vfx)


## A meteor landed: its circle burns, unless the drake is dead.
func _burn_circle(at: Vector2) -> void:
	if not dead:
		_lay(HazardZone.burning(METEOR_BURN * skill_scale, DamageInfo.Type.MAGIC, BURN_TIME).set_circle(at, METEOR_RADIUS))
		if Juice.on():
			var impact := _MeteorImpactVfx.new()
			impact.setup(at, METEOR_RADIUS)
			warning_parent.add_child(impact)


## Burning ground on the warnings' layer, under the units.
func _lay(zone: HazardZone) -> void:
	zone.lucian = target
	warning_parent.add_child(zone)


class _FlameBreathVfx extends Node2D:
	const LIFETIME := 0.45
	var _elapsed := 0.0
	var _length := 550.0
	var _angle := PI / 3.0
	var _embers: Array[Dictionary] = []

	func setup(from: Vector2, toward: Vector2, length: float, angle: float) -> void:
		position = from
		rotation = toward.angle()
		_length = length
		_angle = angle
		z_index = 6
		for i in 18:
			_embers.append({
				"ang": randf_range(-angle * 0.48, angle * 0.48),
				"dist": randf_range(0.18, 1.05),
				"drift": randf_range(-24.0, 24.0),
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
		var reach_frac := minf(t / 0.22, 1.0)
		var alpha := 1.0 - pow(t, 1.45)
		var cur_len := _length * (0.3 + 0.7 * reach_frac)
		# Layered blazing flame tongues fanning out from the drake's jaws.
		var outer := PackedVector2Array([Vector2.ZERO])
		var mid := PackedVector2Array([Vector2.ZERO])
		var inner := PackedVector2Array([Vector2.ZERO])
		var steps := 14
		for i in steps + 1:
			var frac := float(i) / steps
			var ang := lerpf(-_angle * 0.5, _angle * 0.5, frac)
			var flicker := 0.86 + 0.16 * sin(_elapsed * 36.0 + i * 1.9)
			var edge_taper := 0.85 + 0.15 * sin(frac * PI)
			outer.append(Vector2.from_angle(ang) * cur_len * flicker * edge_taper)
			mid.append(Vector2.from_angle(ang * 0.82) * cur_len * 0.78 * (0.9 + 0.12 * cos(_elapsed * 42.0 + i * 2.3)))
			inner.append(Vector2.from_angle(ang * 0.54) * cur_len * 0.45 * flicker)
		draw_colored_polygon(outer, Color("e63b10", alpha * 0.55))
		draw_colored_polygon(mid, Color("ff881e", alpha * 0.76))
		draw_colored_polygon(inner, Color("fff0a6", alpha * 0.9))
		# Hot incandescent throat flare.
		draw_circle(Vector2(18.0, 0.0), 34.0 * (1.0 - t * 0.4), Color("ffaa33", alpha * 0.5))
		draw_circle(Vector2(14.0, 0.0), 17.0 * (1.0 - t * 0.5), Color("fffbe0", alpha * 0.95))
		# Drifting hot embers streaming through the cone.
		for e: Dictionary in _embers:
			var dist: float = _length * e.dist * (0.28 + 0.72 * t)
			var pos := Vector2.from_angle(e.ang) * dist + Vector2(0.0, e.drift * t)
			draw_circle(pos, e.size * (1.0 - t * 0.5), Color("ffd86b", alpha * 0.95))


class _MeteorStreakVfx extends Node2D:
	const FALL_TIME := 0.42
	const START_OFFSET := Vector2(210.0, -560.0)
	var _elapsed := 0.0
	var _warn_time := 1.2
	var _target_pos := Vector2.ZERO
	var _caster: EnemyUnit

	func setup(spot: Vector2, warn_time: float, caster: EnemyUnit) -> void:
		_target_pos = spot
		position = spot
		_warn_time = warn_time
		_caster = caster
		z_index = 8

	func _process(delta: float) -> void:
		if not is_instance_valid(_caster) or not _caster.is_alive():
			queue_free()
			return
		_elapsed += delta
		if _elapsed >= _warn_time:
			queue_free()
			return
		if _warn_time - _elapsed <= FALL_TIME:
			queue_redraw()

	func _draw() -> void:
		var remain := _warn_time - _elapsed
		if remain > FALL_TIME or remain < 0.0:
			return
		var t := clampf(1.0 - remain / FALL_TIME, 0.0, 1.0)
		var eased := t * t
		var head := START_OFFSET.lerp(Vector2.ZERO, eased)
		var back := START_OFFSET.normalized()
		var perp := back.orthogonal()
		var tail_len := lerpf(150.0, 230.0, t)
		var outer_tail := PackedVector2Array([
			head - back * 14.0,
			head + perp * 22.0 + back * 24.0,
			head + back * tail_len,
			head - perp * 22.0 + back * 24.0,
		])
		var inner_tail := PackedVector2Array([
			head - back * 8.0,
			head + perp * 11.0 + back * 16.0,
			head + back * (tail_len * 0.65),
			head - perp * 11.0 + back * 16.0,
		])
		draw_colored_polygon(outer_tail, Color("e63912", 0.72))
		draw_colored_polygon(inner_tail, Color("ff9e2c", 0.9))
		draw_circle(head, 24.0, Color("ff661a", 0.35))
		draw_circle(head, 15.0, Color("4a1e14", 0.95))
		draw_circle(head - back * 3.0, 10.0, Color("ffb838", 0.95))
		draw_circle(head - back * 5.0, 5.5, Color("fffbe0", 0.98))
		for i in 5:
			var frac := 0.25 + 0.16 * i
			var sway := sin(_elapsed * 32.0 + i * 2.1) * 14.0
			draw_circle(head + back * (tail_len * frac) + perp * sway, 3.2, Color("ffda6b", 0.85))


class _MeteorImpactVfx extends Node2D:
	const LIFETIME := 0.42
	var _elapsed := 0.0
	var _radius := 120.0
	var _sparks: Array[Dictionary] = []

	func setup(at: Vector2, impact_radius: float) -> void:
		position = at
		_radius = impact_radius
		z_index = 7
		for i in 14:
			var ang := TAU * float(i) / 14.0 + randf_range(-0.18, 0.18)
			_sparks.append({
				"dir": Vector2.from_angle(ang),
				"speed": randf_range(impact_radius * 1.4, impact_radius * 2.6),
				"size": randf_range(3.5, 7.0),
			})

	func _process(delta: float) -> void:
		_elapsed += delta
		if _elapsed >= LIFETIME:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := clampf(_elapsed / LIFETIME, 0.0, 1.0)
		var ease_out := 1.0 - pow(1.0 - t, 2.5)
		var alpha := 1.0 - t
		var ring_r := _radius * (0.28 + 0.86 * ease_out)
		draw_circle(Vector2.ZERO, _radius * 0.72 * (1.0 - t * 0.45), Color("ff5c14", alpha * 0.42))
		draw_circle(Vector2.ZERO, _radius * 0.34 * (1.0 - t * 0.65), Color("fff2b8", alpha * 0.88))
		draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 48, Color("ff7a24", alpha * 0.92), lerpf(11.0, 2.0, t), true)
		draw_arc(Vector2.ZERO, ring_r * 0.88, 0.0, TAU, 40, Color("ffe38a", alpha * 0.75), lerpf(4.5, 1.0, t), true)
		for s: Dictionary in _sparks:
			var pos: Vector2 = s.dir * (s.speed * _elapsed * (1.0 - t * 0.4))
			draw_line(pos - s.dir * 12.0, pos, Color("ff9e2c", alpha * 0.85), 2.5, true)
			draw_circle(pos, s.size * (1.0 - t * 0.5), Color("fff0a8", alpha))
