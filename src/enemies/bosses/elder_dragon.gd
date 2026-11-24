class_name ElderDragon
extends Boss
## Act 3's boss, in 3-5's pit. Its shot is a violet magic bolt. Elder
## Breath: a wide cone warning, then a hit. Sky Dive (at or below 85% HP): it
## takes off, untargetable and unseen, and its shadow (the dragon itself,
## drawn as a dark ellipse) flies after Lucian over walls and rocks; then
## the shadow stops, a circle warning fills, and it lands there with a hit
## and a push. Elder's Mark: an ElderMark over Lucian that lands true damage
## after a few seconds, three times as much if he is low by then.
##
## Lucian keeps his attack order on it while it is up (see Lucian), so he
## shoots again once it lands. It takes off and lands in _physics_process,
## never inside a damage path. The landing runs on its own fall timer: the
## circle warning only shows it, so the dragon lands even if the warning is
## gone.

enum Dive { NONE, FOLLOW, FALL }

const BREATH_LENGTH := 700.0
const BREATH_ANGLE := PI / 2.0
const BREATH_WARN := 1.0
const BREATH_DAMAGE := 160.0
const BREATH_COOLDOWN := 8.0
const BREATH_FIRST := 2.0
## Seconds its shadow follows Lucian, at DIVE_SPEED.
const DIVE_FOLLOW := 2.4
const DIVE_SPEED := 300.0
const DIVE_RADIUS := 260.0
## Seconds the landing's circle fills before it lands: long enough for a
## Lucian under the shadow to walk out (260 + his hit radius at base speed).
const DIVE_WARN := 1.2
const DIVE_DAMAGE := 240.0
## A landing on Lucian pushes him this far from the circle's middle, at PUSH_SPEED.
const DIVE_PUSH := 200.0
const PUSH_SPEED := 1200.0
const DIVE_COOLDOWN := 18.0
## Sky Dive waits until HP is at or below this share.
const DIVE_HP := 0.85
## Seconds its art takes to fade as it takes off; it grows as it rises.
const TAKE_OFF_FADE := 0.3
const TAKE_OFF_SCALE := 1.3
const MARK_DAMAGE := 130.0
const MARK_COOLDOWN := 16.0
const MARK_FIRST := 8.0
## Seconds it stands to cast the mark.
const MARK_CAST := 0.3
## Seconds it stands after a skill's warning ends, or after it lands.
const RECOVER := 0.3
const ELDER := Color("c9a8ff")
## Its shadow while up: an ellipse this much bigger than its body, squashed
## across; it grows and darkens as it falls.
const SHADOW_COLOR := Color(0.05, 0.02, 0.1)
const SHADOW_SIZE := 1.1
const SHADOW_SQUASH := 0.6

var _dive := Dive.NONE
## Seconds of the follow left, then seconds into the fall.
var _follow_left := 0.0
var _fall_time := 0.0
var _wing_clock := 0.0
var _fade: Tween
var _slam_tween: Tween


func _ready() -> void:
	super()
	add_skill(&"sky_dive", DIVE_COOLDOWN, INF, 0.0, sky_dive)
	add_skill(&"elder_mark", MARK_COOLDOWN, INF, MARK_FIRST, elder_mark)
	# Used whenever the cone reaches him (his body counts).
	add_skill(&"elder_breath", BREATH_COOLDOWN, BREATH_LENGTH + Lucian.HIT_RADIUS, BREATH_FIRST, elder_breath)


## Up in the air: from the take-off until it lands.
func is_diving() -> bool:
	return _dive != Dive.NONE


## A cone warning at Lucian, then the hit.
func elder_breath() -> float:
	var toward := global_position.direction_to(target.global_position)
	face(target.global_position)
	var warning := GroundWarning.cone(global_position, toward, BREATH_LENGTH, BREATH_ANGLE, BREATH_WARN)
	warning.strike(skill_hit(BREATH_DAMAGE, DamageInfo.Type.MAGIC, &"elder_breath"), target)
	warning.fired.connect(_spawn_breath_vfx.bind(global_position, toward))
	warning_parent.add_child(warning)
	return BREATH_WARN + RECOVER


func _spawn_breath_vfx(from: Vector2, toward: Vector2) -> void:
	if not Juice.on() or not is_alive():
		return
	var vfx := _ElderBreathVfx.new()
	vfx.setup(from, toward, BREATH_LENGTH, BREATH_ANGLE)
	warning_parent.add_child(vfx)


## Takes off: untargetable, its art and the shadow at its feet fading out,
## its shadow from above following Lucian (see _physics_process). Busy until
## it has landed.
func sky_dive() -> float:
	set_untargetable(true)
	_dive = Dive.FOLLOW
	_follow_left = DIVE_FOLLOW
	_fall_time = 0.0
	if _flash_tween:
		_flash_tween.kill()
	visuals.modulate = Color.WHITE
	_fade = create_tween().set_parallel()
	_fade.tween_property(visuals, "modulate:a", 0.0, TAKE_OFF_FADE)
	_fade.tween_property(visuals, "scale", Vector2.ONE * TAKE_OFF_SCALE, TAKE_OFF_FADE)
	_fade.tween_property(health_bar, "modulate:a", 0.0, TAKE_OFF_FADE)
	_fade.tween_property(shadow, "modulate:a", 0.0, TAKE_OFF_FADE)
	queue_redraw()
	return DIVE_FOLLOW + DIVE_WARN + RECOVER


## An ElderMark over Lucian; a quick cast.
func elder_mark() -> float:
	face(target.global_position)
	warning_parent.add_child(ElderMark.create(target, skill_hit(MARK_DAMAGE, DamageInfo.Type.TRUE, &"elder_mark"), self))
	return MARK_CAST


func _can_use(id: StringName) -> bool:
	return id != &"sky_dive" or hp <= max_hp * DIVE_HP


## Nothing while up: no walking, no shots, no skills.
func _think(delta: float) -> void:
	if not is_diving():
		super(delta)


## The shot: the data's bolt, in elder colors.
func _attack() -> void:
	fire_bolt(make_hit(), data.projectile_speed, attack_range + BOLT_OVERREACH).color = ELDER


## The dive goes on whether or not Lucian can be fought, so it always lands:
## DIVE_WARN after the fall starts, warning or none.
func _physics_process(delta: float) -> void:
	super(delta)
	if not is_alive() or not is_diving():
		return
	_wing_clock += delta
	if _dive == Dive.FOLLOW:
		_follow(delta)
	else:
		_fall_time += delta
		if _fall_time >= DIVE_WARN:
			_land()
	queue_redraw()


## The shadow flies straight at Lucian, by position: over walls and rocks.
## He stands on the pit's round floor, so it stays over the floor.
func _follow(delta: float) -> void:
	if is_instance_valid(target):
		face(target.global_position)
		global_position = global_position.move_toward(target.global_position, DIVE_SPEED * minf(delta, _follow_left))
	_follow_left -= delta
	if _follow_left <= 0.0:
		_start_fall()


## The shadow stops where its body fits (see landing_spot), and the landing's
## circle warning fills there: only a sight, as the landing has its own timer.
func _start_fall() -> void:
	_dive = Dive.FALL
	_fall_time = 0.0
	global_position = landing_spot(global_position, arena, radius)
	warning_parent.add_child(GroundWarning.circle(global_position, DIVE_RADIUS, DIVE_WARN))


## It lands where it fell, once, seen and targetable again: a hit on Lucian
## inside the circle, which pushes him away from its middle.
func _land() -> void:
	if not is_alive() or _dive != Dive.FALL:
		return
	_dive = Dive.NONE
	set_untargetable(false)
	if _fade:
		_fade.kill()
	if _slam_tween:
		_slam_tween.kill()
	visuals.modulate.a = 1.0
	visuals.scale = Vector2.ONE * 1.55
	_slam_tween = create_tween()
	_slam_tween.tween_property(visuals, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	health_bar.modulate.a = 1.0
	shadow.modulate.a = 1.0
	if Juice.on():
		var slam_vfx := _ElderSlamVfx.new()
		slam_vfx.setup(global_position, DIVE_RADIUS)
		warning_parent.add_child(slam_vfx)
	queue_redraw()
	if not (is_instance_valid(target) and GroundWarning.in_circle(global_position, DIVE_RADIUS, target.global_position, Lucian.HIT_RADIUS)):
		return
	if target.take_damage(skill_hit(DIVE_DAMAGE, DamageInfo.Type.MAGIC, &"sky_dive")):
		var away := global_position.direction_to(target.global_position)
		if away == Vector2.ZERO:
			away = Vector2.from_angle(visuals.rotation)
		target.displace(target.global_position + away * DIVE_PUSH, PUSH_SPEED)


func _draw() -> void:
	super()
	if not is_diving():
		return
	# Recognizable winged dragon shadow silhouette gliding over the pit floor,
	# growing sharper and darker as it dives during FALL.
	var fall := clampf(_fall_time / DIVE_WARN, 0.0, 1.0)
	var scale_f := radius * SHADOW_SIZE * lerpf(0.86, 1.24, fall) / 84.0
	var alpha := lerpf(0.38, 0.76, fall)
	var flap := sin(_wing_clock * 5.8) * (1.0 - fall * 0.65)
	var wing_y := 1.0 + flap * 0.14 - fall * 0.12
	var wing_sweep := fall * 18.0
	var dragon := PackedVector2Array([
		# Snout & horned head (+X)
		Vector2(86.0, 0.0),
		Vector2(68.0, -11.0),
		Vector2(56.0, -21.0),
		Vector2(52.0, -11.0),
		# Neck & upper swept dragon wing
		Vector2(34.0, -13.0),
		Vector2(28.0 - wing_sweep * 0.4, -58.0 * wing_y),
		Vector2(-12.0 - wing_sweep, -124.0 * wing_y),
		Vector2(-38.0 - wing_sweep * 0.8, -88.0 * wing_y),
		Vector2(-24.0, -64.0 * wing_y),
		Vector2(-52.0 - wing_sweep * 0.5, -52.0 * wing_y),
		Vector2(-26.0, -22.0),
		# Haunch & long sinuous tapering tail (-X)
		Vector2(-48.0, -16.0),
		Vector2(-96.0, -8.0),
		Vector2(-132.0, -14.0),
		Vector2(-150.0, 0.0),
		Vector2(-132.0, 14.0),
		Vector2(-96.0, 8.0),
		Vector2(-48.0, 16.0),
		# Lower swept dragon wing
		Vector2(-26.0, 22.0),
		Vector2(-52.0 - wing_sweep * 0.5, 52.0 * wing_y),
		Vector2(-24.0, 64.0 * wing_y),
		Vector2(-38.0 - wing_sweep * 0.8, 88.0 * wing_y),
		Vector2(-12.0 - wing_sweep, 124.0 * wing_y),
		Vector2(28.0 - wing_sweep * 0.4, 58.0 * wing_y),
		Vector2(34.0, 13.0),
		Vector2(52.0, 11.0),
		Vector2(56.0, 21.0),
		Vector2(68.0, 11.0),
	])
	# Soft outer penumbra shadow beneath the crisp inner dragon silhouette.
	draw_set_transform(Vector2.ZERO, visuals.rotation, Vector2.ONE * scale_f * 1.12)
	draw_colored_polygon(dragon, Color(SHADOW_COLOR, alpha * 0.34))
	draw_set_transform(Vector2.ZERO, visuals.rotation, Vector2.ONE * scale_f)
	draw_colored_polygon(dragon, Color(SHADOW_COLOR, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class _ElderSlamVfx extends Node2D:
	const LIFETIME := 0.48
	var _elapsed := 0.0
	var _radius := 260.0
	var _rays: Array[Dictionary] = []

	func setup(at: Vector2, slam_radius: float) -> void:
		position = at
		_radius = slam_radius
		z_index = 7
		for i in 16:
			var ang := TAU * float(i) / 16.0 + randf_range(-0.12, 0.12)
			_rays.append({
				"dir": Vector2.from_angle(ang),
				"len": randf_range(slam_radius * 0.65, slam_radius * 1.15),
				"w": randf_range(3.0, 6.5),
			})

	func _process(delta: float) -> void:
		_elapsed += delta
		if _elapsed >= LIFETIME:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := clampf(_elapsed / LIFETIME, 0.0, 1.0)
		var ease_out := 1.0 - pow(1.0 - t, 2.8)
		var alpha := 1.0 - t
		var ring_r := _radius * (0.2 + 0.9 * ease_out)
		draw_circle(Vector2.ZERO, _radius * 0.65 * (1.0 - t * 0.5), Color("8b4dff", alpha * 0.34))
		draw_circle(Vector2.ZERO, _radius * 0.3 * (1.0 - t * 0.65), Color("f5ecff", alpha * 0.85))
		draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 64, Color("b47aff", alpha * 0.95), lerpf(16.0, 2.5, t), true)
		draw_arc(Vector2.ZERO, ring_r * 0.86, 0.0, TAU, 56, Color("f7f0ff", alpha * 0.9), lerpf(6.5, 1.2, t), true)
		for r: Dictionary in _rays:
			var d: Vector2 = r.dir
			var rlen: float = r.len
			var rw: float = r.w
			var start_p := d * (_radius * 0.15 + ring_r * 0.28)
			var end_p := d * (rlen * ease_out)
			draw_line(start_p, end_p, Color("d4b5ff", alpha * 0.85), rw * (1.0 - t * 0.6), true)


class _ElderBreathVfx extends Node2D:
	const LIFETIME := 0.45
	var _elapsed := 0.0
	var _length := 700.0
	var _angle := PI / 2.0
	var _sparks: Array[Dictionary] = []

	func setup(from: Vector2, toward: Vector2, length: float, angle: float) -> void:
		position = from
		rotation = toward.angle()
		_length = length
		_angle = angle
		z_index = 6
		for i in 22:
			_sparks.append({
				"ang": randf_range(-angle * 0.48, angle * 0.48),
				"dist": randf_range(0.18, 1.06),
				"size": randf_range(3.0, 6.0),
			})

	func _process(delta: float) -> void:
		_elapsed += delta
		if _elapsed >= LIFETIME:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := clampf(_elapsed / LIFETIME, 0.0, 1.0)
		var reach_frac := minf(t / 0.2, 1.0)
		var alpha := 1.0 - pow(t, 1.4)
		var cur_len := _length * (0.28 + 0.72 * reach_frac)
		var outer := PackedVector2Array([Vector2.ZERO])
		var mid := PackedVector2Array([Vector2.ZERO])
		var core := PackedVector2Array([Vector2.ZERO])
		var steps := 18
		for i in steps + 1:
			var frac := float(i) / steps
			var ang := lerpf(-_angle * 0.5, _angle * 0.5, frac)
			var surge := 0.88 + 0.14 * sin(_elapsed * 38.0 + i * 2.1)
			outer.append(Vector2.from_angle(ang) * cur_len * surge)
			mid.append(Vector2.from_angle(ang * 0.84) * cur_len * 0.82 * (0.9 + 0.12 * cos(_elapsed * 42.0 + i * 1.7)))
			core.append(Vector2.from_angle(ang * 0.52) * cur_len * 0.52 * surge)
		draw_colored_polygon(outer, Color("6c2bd9", alpha * 0.5))
		draw_colored_polygon(mid, Color("c492ff", alpha * 0.75))
		draw_colored_polygon(core, Color("faf5ff", alpha * 0.92))
		# Roaring arcane energy streams shooting out from the dragon's jaws.
		for k in 5:
			var ang := lerpf(-_angle * 0.38, _angle * 0.38, float(k) / 4.0)
			var pts := PackedVector2Array()
			for s in 8:
				var sf := float(s) / 7.0
				var jitter := sin(_elapsed * 48.0 + s * 2.5 + k) * 12.0 * sf
				pts.append(Vector2.from_angle(ang) * (cur_len * sf) + Vector2.from_angle(ang + PI * 0.5) * jitter)
			draw_polyline(pts, Color("efe3ff", alpha * 0.8), 3.0, true)
		draw_circle(Vector2(20.0, 0.0), 38.0 * (1.0 - t * 0.4), Color("b47aff", alpha * 0.55))
		draw_circle(Vector2(16.0, 0.0), 18.0 * (1.0 - t * 0.5), Color.WHITE * Color(1, 1, 1, alpha * 0.96))
		for s: Dictionary in _sparks:
			var ang: float = s.ang
			var dist: float = s.dist
			var sz: float = s.size
			var pos := Vector2.from_angle(ang) * (_length * dist * (0.25 + 0.75 * t))
			draw_circle(pos, sz * (1.0 - t * 0.5), Color("f2e6ff", alpha))
