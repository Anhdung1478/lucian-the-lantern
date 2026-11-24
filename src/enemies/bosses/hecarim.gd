class_name Hecarim
extends Boss
## Act 6's second mini boss, in 6-4. A spectral centaur who fights in melee.
## Devastating Charge: for CHARGE_TIME he runs at CHARGE_SPEED times his speed
## behind a glowing trail, chasing Lucian; the first contact hurts and knocks
## Lucian back (once per cast). Onslaught of Shadows (at or below 80% HP): a
## line warning, then he rides along it with four ghost riders beside him; a
## Lucian in the band as the pack passes takes a hit and a fear, running
## sideways out of the band. The fear comes from the warning, which is on the
## ground for a full second, or from the pack he can see.
##
## The Onslaught hit rule: the band decides, not his body. The ride is
## EnemyUnit.charge (through units, stopped by walls and the abyss), and each
## frame of it Lucian is hit if he stands in the band (GroundWarning.in_line,
## the very area the warning drew) and the pack is on him (he is no further
## ahead than Hecarim's radius, and no further behind than RIDE_TAIL, the
## last ghost's back). A step out of the band dodges it, and so does a step
## into it behind the pack; a ride a wall stops short of him does not hit.

const CHARGE_TIME := 2.5
const CHARGE_SPEED := 1.8
const CHARGE_DAMAGE := 170.0
## The contact knocks Lucian this far straight away from him, at KNOCK_SPEED.
const CHARGE_KNOCK := 300.0
const KNOCK_SPEED := 1200.0
const CHARGE_COOLDOWN := 13.0
const CHARGE_FIRST := 3.0
## He charges only from this far: it needs room to be seen coming.
const CHARGE_MIN := 300.0
const CHARGE_REACH := 1100.0
const RIDE_LENGTH := 1100.0
const RIDE_WIDTH := 300.0
const RIDE_WARN := 1.0
const RIDE_SPEED := 1600.0
const RIDE_DAMAGE := 150.0
const RIDE_FEAR := 1.0
const RIDE_COOLDOWN := 18.0
const RIDE_FIRST := 2.0
## Onslaught waits until HP is at or below this share.
const RIDE_HP := 0.8
## Seconds he stands after the ride ends.
const RECOVER := 0.3
const FLAME := Color("4de8c0")
const FLAME_EDGE := Color("36b6e8")
## The ghost riders: (distance behind him, distance to the side), in his
## facing. All within the band.
const RIDERS: Array[Vector2] = [Vector2(40, -105), Vector2(40, 105), Vector2(130, -130), Vector2(130, 130)]
const RIDER_ART := preload("res://assets/art/enemies/spectral_rider.svg")
const RIDER_ALPHA := 0.55
## The pack's tail: how far behind him the ride still hits. The last ghosts
## ride 130 behind him, and the rider art is 92 long (half of it 46).
const RIDE_TAIL := 180.0
## The charge's trail behind him: its length and half-width.
const TRAIL_LENGTH := 230.0
const TRAIL_WIDTH := 44.0

var _rush_left := 0.0
var _rush_hit := false
var _base_speed := 0.0
var _riding := false
var _ride_from := Vector2.ZERO
var _ride_dir := Vector2.RIGHT
var _ride_hit := false
var _vfx_time := 0.0


func _ready() -> void:
	super()
	landed.connect(_on_landed)
	# Tried first: at its HP, Onslaught comes before the charge.
	add_skill(&"onslaught_of_shadows", RIDE_COOLDOWN, RIDE_LENGTH, RIDE_FIRST, onslaught_of_shadows)
	add_skill(&"devastating_charge", CHARGE_COOLDOWN, CHARGE_REACH, CHARGE_FIRST, devastating_charge)


## True for CHARGE_TIME after Devastating Charge starts.
func is_charge_running() -> bool:
	return _rush_left > 0.0


## True while he rides along the Onslaught line.
func is_riding() -> bool:
	return _riding


## Speeds up for CHARGE_TIME (see _think and _physics_process). He is not
## busy: he runs at Lucian meanwhile.
func devastating_charge() -> float:
	_rush_left = CHARGE_TIME
	_rush_hit = false
	_base_speed = move_speed
	move_speed = _base_speed * CHARGE_SPEED
	queue_redraw()
	return 0.0


## A line warning at Lucian, then the ride (see _ride).
func onslaught_of_shadows() -> float:
	var toward := global_position.direction_to(target.global_position)
	face(target.global_position)
	var warning := GroundWarning.line(global_position, toward, RIDE_LENGTH, RIDE_WIDTH, RIDE_WARN)
	warning.fired.connect(_ride.bind(global_position, toward))
	warning_parent.add_child(warning)
	return RIDE_WARN + RIDE_LENGTH / RIDE_SPEED + RECOVER


func _can_use(id: StringName) -> bool:
	match id:
		&"onslaught_of_shadows":
			return hp <= max_hp * RIDE_HP and not is_charge_running()
		&"devastating_charge":
			return distance_to_target() >= CHARGE_MIN and not is_charge_running()
	return true


## While the charge runs he chases Lucian until contact, then fights as usual.
func _think(delta: float) -> void:
	if is_charge_running() and busy_left <= 0.0 and distance_to_target() > radius + Lucian.HIT_RADIUS:
		walk_toward(target.global_position, delta)
		return
	super(delta)


func _physics_process(delta: float) -> void:
	super(delta)
	if not is_alive():
		return
	if is_charge_running() or _riding:
		_vfx_time += delta
	if is_charge_running():
		_rush_step(delta)
	if _riding:
		_ride_check()
		queue_redraw()


## One frame of the charge: the contact hit, then the clock.
func _rush_step(delta: float) -> void:
	if not _rush_hit and can_fight() and distance_to_target() <= radius + Lucian.HIT_RADIUS:
		_rush_hit = true
		var away := target.global_position - global_position
		var knock_to := target.global_position + (away.normalized() if away != Vector2.ZERO else Vector2.RIGHT) * CHARGE_KNOCK
		if target.take_damage(skill_hit(CHARGE_DAMAGE, DamageInfo.Type.PHYSICAL, &"devastating_charge")):
			target.displace(knock_to, KNOCK_SPEED)
	_rush_left = maxf(_rush_left - delta, 0.0)
	if _rush_left <= 0.0:
		move_speed = _base_speed
	queue_redraw()


## The warning is over: he rides the line, ghosts beside him.
func _ride(from: Vector2, toward: Vector2) -> void:
	if not is_alive():
		return
	_riding = true
	_ride_hit = false
	_ride_from = from
	_ride_dir = toward
	charge(toward, RIDE_LENGTH, RIDE_SPEED)
	queue_redraw()


## Lucian is hit once if he is in the band and the pack is on him: no
## further ahead than Hecarim's radius, no further behind than RIDE_TAIL.
func _ride_check() -> void:
	if _ride_hit or not can_fight():
		return
	var ahead := (target.global_position - global_position).dot(_ride_dir)
	if ahead > radius or ahead < -RIDE_TAIL:
		return
	if not GroundWarning.in_line(_ride_from, _ride_dir, RIDE_LENGTH, RIDE_WIDTH, target.global_position, Lucian.HIT_RADIUS):
		return
	_ride_hit = true
	if target.take_damage(skill_hit(RIDE_DAMAGE, DamageInfo.Type.MAGIC, &"onslaught_of_shadows")):
		target.add_cc(CrowdControl.Kind.FEAR, RIDE_FEAR, _fear_source(target.global_position))


## The fear runs from the nearest point on the ride's centre line, so Lucian
## runs sideways out of the band. Right on the line, he runs to the ride's
## orthogonal side.
func _fear_source(at: Vector2) -> Vector2:
	var on_line := _ride_from + _ride_dir * (at - _ride_from).dot(_ride_dir)
	if at.distance_to(on_line) > 1.0:
		return on_line
	return at - _ride_dir.orthogonal() * radius


## The ride is over (it ran its length or a wall stopped it): its last frame counts.
func _on_landed() -> void:
	if not _riding:
		return
	_ride_check()
	_riding = false
	busy_left = maxf(busy_left, RECOVER)
	queue_redraw()


func _draw() -> void:
	super()
	var heading := visuals.rotation
	if is_charge_running():
		# Layered blazing spectral teal-cyan flame wake & flying hoof-spark embers behind him.
		draw_set_transform(Vector2.ZERO, heading)
		var segs := 10
		var outer := PackedVector2Array()
		var inner := PackedVector2Array()
		var core := PackedVector2Array()
		for i in segs + 1:
			var f := float(i) / segs
			var x := lerpf(-radius * 0.35, -TRAIL_LENGTH * 1.08, f)
			var w := TRAIL_WIDTH * 1.2 * pow(1.0 - f, 0.75) + sin(_vfx_time * 24.0 + i * 1.4) * 9.0 * (1.0 - f * 0.4)
			outer.append(Vector2(x, -maxf(w, 2.0)))
		for i in range(segs, -1, -1):
			var f := float(i) / segs
			var x := lerpf(-radius * 0.35, -TRAIL_LENGTH * 1.08, f)
			var w := TRAIL_WIDTH * 1.2 * pow(1.0 - f, 0.75) + cos(_vfx_time * 22.0 + i * 1.6) * 9.0 * (1.0 - f * 0.4)
			outer.append(Vector2(x, maxf(w, 2.0)))
		for i in segs + 1:
			var f := float(i) / segs
			var x := lerpf(-radius * 0.42, -TRAIL_LENGTH * 0.82, f)
			var w := TRAIL_WIDTH * 0.72 * pow(1.0 - f, 0.85) + sin(_vfx_time * 28.0 + i * 1.9) * 5.0 * (1.0 - f * 0.5)
			inner.append(Vector2(x, -maxf(w, 1.5)))
		for i in range(segs, -1, -1):
			var f := float(i) / segs
			var x := lerpf(-radius * 0.42, -TRAIL_LENGTH * 0.82, f)
			var w := TRAIL_WIDTH * 0.72 * pow(1.0 - f, 0.85) + cos(_vfx_time * 26.0 + i * 1.7) * 5.0 * (1.0 - f * 0.5)
			inner.append(Vector2(x, maxf(w, 1.5)))
		core.append(Vector2(-radius * 0.45, -TRAIL_WIDTH * 0.34))
		core.append(Vector2(-TRAIL_LENGTH * 0.48, sin(_vfx_time * 32.0) * 6.0))
		core.append(Vector2(-radius * 0.45, TRAIL_WIDTH * 0.34))
		draw_colored_polygon(outer, Color(FLAME_EDGE, 0.36))
		draw_colored_polygon(inner, Color(FLAME, 0.64))
		draw_colored_polygon(core, Color("d4fff5", 0.82))
		# Flying spectral hoof-spark embers streaming behind him.
		for i in 10:
			var phase := fposmod(_vfx_time * 3.4 + i * 0.29, 1.0)
			var sx := lerpf(-radius * 0.5, -TRAIL_LENGTH * 1.15, phase)
			var sy := sin(i * 2.4 + _vfx_time * 9.0) * TRAIL_WIDTH * (0.85 - phase * 0.35)
			var spark_a := (1.0 - phase) * 0.92
			draw_line(Vector2(sx, sy), Vector2(sx - 18.0, sy), Color(FLAME, spark_a * 0.65), 2.5, true)
			draw_circle(Vector2(sx, sy), lerpf(4.2, 1.5, phase), Color("e6fff9", spark_a))
		draw_set_transform(Vector2.ZERO, 0.0)
	if _riding:
		# Surging translucent spectral shadow-mist wave across the Onslaught band.
		draw_set_transform(Vector2.ZERO, heading)
		var half_band := RIDE_WIDTH * 0.5
		var mist_pts := PackedVector2Array()
		var mist_cols := PackedColorArray()
		var wave_segs := 14
		for i in wave_segs + 1:
			var f := lerpf(-1.0, 1.0, float(i) / wave_segs)
			var bow := (1.0 - f * f) * 56.0 + sin(_vfx_time * 16.0 + i * 1.2) * 8.0
			mist_pts.append(Vector2(radius * 0.6 + bow, half_band * f))
			mist_cols.append(Color(FLAME_EDGE, 0.26 * (1.0 - 0.35 * absf(f))))
		for i in range(wave_segs, -1, -1):
			var f := lerpf(-1.0, 1.0, float(i) / wave_segs)
			var tail_x := -RIDE_TAIL - 70.0 * (1.0 - 0.4 * f * f)
			mist_pts.append(Vector2(tail_x, half_band * f))
			mist_cols.append(Color("0b2628", 0.0))
		draw_polygon(mist_pts, mist_cols)
		# Crisp glowing spectral leading crest arc across the pack's front.
		var crest := PackedVector2Array()
		for i in wave_segs + 1:
			var f := lerpf(-1.0, 1.0, float(i) / wave_segs)
			crest.append(Vector2(radius * 0.55 + (1.0 - f * f) * 52.0, half_band * f))
		draw_polyline(crest, Color(FLAME, 0.45), 6.0, true)
		draw_polyline(crest, Color("ccfff4", 0.72), 2.0, true)
		draw_set_transform(Vector2.ZERO, 0.0)
		# Staggered, gently galloping/bobbing ghostly rider silhouettes & trailing hoof-sparks.
		var size := RIDER_ART.get_size()
		for i in RIDERS.size():
			var place := RIDERS[i]
			var gallop := sin(_vfx_time * 18.0 + i * 1.5)
			var bob_local := Vector2(-place.x + gallop * 8.0, place.y + cos(_vfx_time * 18.0 + i * 1.5) * 4.5)
			var at := bob_local.rotated(heading)
			draw_set_transform(at, heading)
			# Spectral mist aura & hoof-spark trail behind each ghost rider.
			draw_circle(Vector2(-10.0, 0.0), 34.0, Color(FLAME, 0.16))
			for k in 3:
				var sp := fposmod(_vfx_time * 4.2 + i * 0.31 + k * 0.33, 1.0)
				var hx := lerpf(-24.0, -105.0, sp)
				var hy := (k - 1) * 10.0 + sin(_vfx_time * 12.0 + k + i) * 3.0
				draw_line(Vector2(hx, hy), Vector2(hx - 16.0, hy), Color(FLAME, (1.0 - sp) * 0.65), 2.2, true)
				draw_circle(Vector2(hx, hy), lerpf(3.2, 1.2, sp), Color("dcfff6", (1.0 - sp) * 0.85))
			draw_texture(RIDER_ART, -size * 0.5, Color(FLAME.lerp(Color.WHITE, 0.2), RIDER_ALPHA + 0.1 * gallop))
		draw_set_transform(Vector2.ZERO, 0.0)
