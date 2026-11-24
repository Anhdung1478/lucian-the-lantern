class_name Maokai
extends Boss
## Act 5's first mini boss, in the dead forest. A melee treant. Twisted
## Advance: a circle warning on Lucian, then it leaps there (untargetable in
## the air) and roots him if he is still inside. Nature's Grasp: a line
## warning, then a wave of vines along it that roots on a hit; trees stop it.
## Every root comes from a warning or a wave Lucian can see.

const ADVANCE_RADIUS := 90.0
const ADVANCE_WARN := 0.8
const ADVANCE_LEAP := 0.4
const ADVANCE_DAMAGE := 130.0
const ADVANCE_ROOT := 1.0
const ADVANCE_COOLDOWN := 10.0
const ADVANCE_RANGE := 700.0
const ADVANCE_FIRST := 3.0
const GRASP_LENGTH := 900.0
const GRASP_WIDTH := 140.0
const GRASP_WARN := 0.8
const GRASP_SPEED := 700.0
const GRASP_DAMAGE := 110.0
const GRASP_ROOT := 1.25
const GRASP_COOLDOWN := 12.0
const GRASP_FIRST := 2.0
## Seconds it stands after a skill's warning ends, or after it lands.
const RECOVER := 0.3
const VINE := Color("6fbf4a")


func _ready() -> void:
	super()
	add_skill(&"twisted_advance", ADVANCE_COOLDOWN, ADVANCE_RANGE, ADVANCE_FIRST, twisted_advance)
	add_skill(&"nature_grasp", GRASP_COOLDOWN, GRASP_LENGTH, GRASP_FIRST, nature_grasp)


## A circle warning where Lucian stands (on ground its body fits), then the leap.
func twisted_advance() -> float:
	var spot := Boss.landing_spot(target.global_position, arena, radius)
	face(spot)
	var warning := GroundWarning.circle(spot, ADVANCE_RADIUS, ADVANCE_WARN)
	warning.fired.connect(_leap.bind(spot))
	warning_parent.add_child(warning)
	return ADVANCE_WARN + ADVANCE_LEAP + RECOVER


func _leap(spot: Vector2) -> void:
	if not is_alive():
		return
	landed.connect(_come_down.bind(spot), CONNECT_ONE_SHOT)
	leap_to(spot, ADVANCE_LEAP)


## It lands: Lucian inside the circle takes the hit and, if it landed, the root.
func _come_down(spot: Vector2) -> void:
	if not is_alive():
		return
	if Juice.on():
		var snare := _RootSnareVfx.new()
		snare.setup(spot, ADVANCE_RADIUS)
		warning_parent.add_child(snare)
	if not is_instance_valid(target):
		return
	if not GroundWarning.in_circle(spot, ADVANCE_RADIUS, target.global_position, Lucian.HIT_RADIUS):
		return
	if target.take_damage(skill_hit(ADVANCE_DAMAGE, DamageInfo.Type.MAGIC, &"twisted_advance")):
		target.add_cc(CrowdControl.Kind.ROOT, ADVANCE_ROOT)


## A line warning at Lucian, then the wave of vines along it.
func nature_grasp() -> float:
	var toward := global_position.direction_to(target.global_position)
	face(target.global_position)
	var warning := GroundWarning.line(global_position, toward, GRASP_LENGTH, GRASP_WIDTH, GRASP_WARN)
	warning.fired.connect(_send_vines.bind(toward))
	warning_parent.add_child(warning)
	return GRASP_WARN + RECOVER


func _send_vines(toward: Vector2) -> void:
	if not is_alive():
		return
	var wave := fire_bolt(skill_hit(GRASP_DAMAGE, DamageInfo.Type.MAGIC, &"nature_grasp"), GRASP_SPEED, GRASP_LENGTH, toward)
	wave.hit_radius = GRASP_WIDTH * 0.5
	wave.front_width = GRASP_WIDTH
	wave.color = VINE
	wave.style = EnemyProjectile.Style.VINE_WAVE
	wave.hit_lucian.connect(_vines_hit)


func _vines_hit() -> void:
	if is_instance_valid(target):
		target.add_cc(CrowdControl.Kind.ROOT, GRASP_ROOT)


class _RootSnareVfx extends Node2D:
	const LIFETIME := 0.48
	var _elapsed := 0.0
	var _radius := 90.0
	var _roots: Array[Dictionary] = []
	var _shards: Array[Dictionary] = []

	func setup(at: Vector2, snare_radius: float) -> void:
		position = at
		_radius = snare_radius
		z_index = 6
		for i in 8:
			var ang := TAU * float(i) / 8.0 + randf_range(-0.18, 0.18)
			_roots.append({
				"ang": ang,
				"curve": randf_range(-0.35, 0.35),
				"len": snare_radius * randf_range(0.85, 1.15),
			})
		for i in 14:
			var ang := randf() * TAU
			_shards.append({
				"dir": Vector2.from_angle(ang),
				"speed": randf_range(110.0, 240.0),
				"rot": randf() * TAU,
				"spin": randf_range(-9.0, 9.0),
				"leaf": i % 2 == 0,
				"size": randf_range(5.0, 9.5),
			})

	func _process(delta: float) -> void:
		_elapsed += delta
		if _elapsed >= LIFETIME:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := clampf(_elapsed / LIFETIME, 0.0, 1.0)
		var ease_out := 1.0 - pow(1.0 - t, 2.6)
		var alpha := 1.0 - t
		var ring_r := _radius * (0.25 + 0.85 * ease_out)
		# Ground burst shadow & emerald root-snare shockwave ring.
		draw_circle(Vector2.ZERO, _radius * 0.7 * (1.0 - t * 0.4), Color("1f3818", alpha * 0.35))
		draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 48, Color("6fbf4a", alpha * 0.9), lerpf(10.0, 2.0, t), true)
		draw_arc(Vector2.ZERO, ring_r * 0.84, 0.0, TAU, 40, Color("b4ff7a", alpha * 0.65), lerpf(3.5, 1.0, t), true)
		# Jagged dark-bark roots erupting outward across the snare ring.
		for r: Dictionary in _roots:
			var ang: float = r.ang
			var curve: float = r.curve
			var max_len: float = r.len * ease_out
			var pts := PackedVector2Array()
			for k in 5:
				var kf := float(k) / 4.0
				pts.append(Vector2.from_angle(ang + curve * kf) * (max_len * kf))
			draw_polyline(pts, Color("382416", alpha * 0.95), lerpf(7.5, 3.0, t), true)
			draw_polyline(pts, Color("68c945", alpha * 0.8), lerpf(3.0, 1.2, t), true)
		# Flying dark-bark splinters & emerald leaf shards.
		for s: Dictionary in _shards:
			var pos: Vector2 = s.dir * (s.speed * _elapsed * (1.0 - t * 0.35))
			var f := Vector2.from_angle(s.rot + s.spin * _elapsed)
			var p := f.orthogonal()
			var sz: float = s.size * (1.0 - t * 0.35)
			if s.leaf:
				var leaf := PackedVector2Array([
					pos + f * sz,
					pos + p * (sz * 0.5),
					pos - f * sz,
					pos - p * (sz * 0.5),
				])
				draw_colored_polygon(leaf, Color("7ee650", alpha * 0.92))
			else:
				var bark := PackedVector2Array([
					pos + f * sz,
					pos + p * (sz * 0.28),
					pos - f * (sz * 0.85),
					pos - p * (sz * 0.28),
				])
				draw_colored_polygon(bark, Color("4a311e", alpha * 0.95))
