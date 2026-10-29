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
		# A glowing trail behind him, brightest at his back.
		draw_set_transform(Vector2.ZERO, heading)
		var trail := PackedVector2Array([Vector2(-radius * 0.5, -TRAIL_WIDTH), Vector2(-TRAIL_LENGTH, 0.0), Vector2(-radius * 0.5, TRAIL_WIDTH)])
		var glow := PackedColorArray([Color(FLAME, 0.5), Color(FLAME_EDGE, 0.0), Color(FLAME, 0.5)])
		draw_polygon(trail, glow)
		for offset: float in [-26.0, 0.0, 26.0]:
			draw_line(Vector2(-radius * 0.6, offset), Vector2(-TRAIL_LENGTH * (0.8 if offset == 0.0 else 0.55), offset * 0.4), Color(FLAME.lerp(Color.WHITE, 0.5), 0.7), 3.0)
		draw_set_transform(Vector2.ZERO, 0.0)
	if _riding:
		# Ghost riders beside him, facing the same way.
		var size := RIDER_ART.get_size()
		for place in RIDERS:
			var at := Vector2(-place.x, place.y).rotated(heading)
			draw_set_transform(at, heading)
			draw_texture(RIDER_ART, -size * 0.5, Color(FLAME, RIDER_ALPHA))
		draw_set_transform(Vector2.ZERO, 0.0)
