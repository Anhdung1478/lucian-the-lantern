class_name DarkLucian
extends Boss
## Act 4's boss, on 4-3's dark lane: a mirror of Lucian, with no passive and
## no W. His basic attack is two shots, one from each gun. Piercing Light
## (Q): a line warning at Lucian, then a dark laser along it. Relentless
## Pursuit (E): a quick dash, untargetable on the way, so shots in flight
## miss: sideways once he has taken a lot of damage lately, or at Lucian
## when Lucian is far. The Culling (R, at or below 80% HP): a wide line
## warning at Lucian, then a stream of bullets along that fixed line while
## he strafes across it; a faint band under him marks that line while it fires.
##
## The damage is recorded in _lose_hp; the dodge comes from _think, and the
## dash and the stream run in _physics_process, never inside a damage path.
## Lucian keeps his attack order on him through the dash (see Lucian).

## Seconds between the two shots of a basic attack.
const SHOT_GAP := 0.15
## His guns are this far each side of his middle.
const GUN_OFFSET := 13.0
const LASER_LENGTH := 1100.0
const LASER_WIDTH := 70.0
const LASER_WARN := 0.7
const LASER_DAMAGE := 170.0
const LASER_COOLDOWN := 7.0
const LASER_FIRST := 3.0
const DASH_DISTANCE := 400.0
const DASH_TIME := 0.2
const DASH_COOLDOWN := 6.0
## He dodges once the damage he took in the last DODGE_WINDOW seconds
## reaches this share of his max HP.
const DODGE_SHARE := 0.06
const DODGE_WINDOW := 1.5
## He dashes at Lucian when Lucian is farther than this.
const CHASE_RANGE := 750.0
const CULLING_LENGTH := 1200.0
const CULLING_WIDTH := 120.0
const CULLING_WARN := 0.8
const CULLING_TIME := 3.0
const CULLING_SHOTS := 24
const CULLING_GAP := CULLING_TIME / CULLING_SHOTS
## The faint band under him while The Culling fires: as long and wide as its
## line, drawn under the units.
const CULLING_BAND := Color(0.7, 0.4, 1.0, 0.12)
## A bullet flies up to this far off the line, either way (4°).
const CULLING_SPREAD := PI / 45.0
const CULLING_DAMAGE := 30.0
const CULLING_SPEED := 1400.0
const CULLING_RANGE := 1200.0
const STRAFE_SPEED := 150.0
const CULLING_COOLDOWN := 20.0
## The Culling waits until HP is at or below this share.
const CULLING_HP := 0.8
## Seconds he stands after Q's warning ends.
const RECOVER := 0.3
const SHOT_COLOR := Color("b57cff")
## The dark laser: a violet glow round a black line.
const LASER_GLOW := Color(0.6, 0.3, 1.0, 0.45)
const LASER_CORE := Color(0.78, 0.55, 1.0, 0.9)
const LASER_CENTER := Color("1a0f2e")
const TRAIL_COLOR := Color(0.62, 0.36, 1.0)
## His art while he dashes: half seen, as shots can't touch him.
const DASH_ALPHA := 0.55

## The way he strafes during The Culling: across its line, chosen as he
## casts it.
var strafe_direction := Vector2.ZERO

## Seconds he has been alive, for the damage log.
var _clock := 0.0
## (time, amount) per hit he took in the last DODGE_WINDOW seconds.
var _damage_log: Array[Vector2] = []
var _second_shot_left := 0.0
var _dash_left := 0.0
var _dash_direction := Vector2.ZERO
var _dash_echo_left := 0.0
var _trail: DashTrail
## The Culling: seconds of its warning left, then seconds of the stream.
var _culling_wait := 0.0
var _culling_left := 0.0
var _culling_shots := 0
var _culling_gap_left := 0.0
var _culling_direction := Vector2.RIGHT
## The band that shows the stream's line; a child, so it moves with him.
var _culling_band: Node2D


func _ready() -> void:
	super()
	# The dodge first: it answers what just hit him.
	add_skill(&"relentless_pursuit", DASH_COOLDOWN, INF, 0.0, relentless_pursuit)
	add_skill(&"the_culling", CULLING_COOLDOWN, CULLING_LENGTH, 0.0, the_culling)
	add_skill(&"piercing_light", LASER_COOLDOWN, LASER_LENGTH, LASER_FIRST, piercing_light)


func is_dashing() -> bool:
	return _dash_left > 0.0


## From The Culling's warning to the end of its stream.
func is_culling() -> bool:
	return _culling_wait > 0.0 or _culling_left > 0.0


## The damage he took in the last DODGE_WINDOW seconds.
func recent_damage() -> float:
	var total := 0.0
	for hit in _damage_log:
		if _clock - hit.x <= DODGE_WINDOW:
			total += hit.y
	return total


## He has taken enough lately to dodge.
func wants_dodge() -> bool:
	return recent_damage() >= max_hp * DODGE_SHARE


## A line warning at Lucian, then the dark laser along it (see _fire_laser).
func piercing_light() -> float:
	var toward := _toward_lucian()
	face(global_position + toward)
	var warning := GroundWarning.line(global_position, toward, LASER_LENGTH, LASER_WIDTH, LASER_WARN)
	warning.fired.connect(_fire_laser.bind(global_position, toward))
	warning_parent.add_child(warning)
	return LASER_WARN + RECOVER


## Sideways when he has taken DODGE_SHARE of his max HP lately (to open
## ground, see side_step), else at Lucian.
func relentless_pursuit() -> float:
	var toward := _toward_lucian()
	if wants_dodge():
		_damage_log.clear()
		return dash(side_step(global_position, toward, DASH_DISTANCE, arena, radius))
	return dash(toward)


## DASH_DISTANCE along `direction` in DASH_TIME (see _dash_step), untargetable
## and half seen on the way, leaving a violet trail. A basic attack's second
## shot is dropped. Returns the seconds it takes.
func dash(direction: Vector2) -> float:
	_dash_direction = direction.normalized()
	_dash_left = DASH_TIME
	_dash_echo_left = 0.0
	_second_shot_left = 0.0
	set_untargetable(true)
	face(global_position + _dash_direction)
	if _flash_tween:
		_flash_tween.kill()
	visuals.modulate = Color(1.0, 1.0, 1.0, DASH_ALPHA)
	_finish_trail()
	_trail = DashTrail.new()
	_trail.setup(global_position, TRAIL_COLOR)
	warning_parent.add_child(_trail)
	_spawn_afterimage()
	_dash_echo_left = DASH_TIME / 3.0
	return DASH_TIME


## A wide line warning at Lucian; then, on its own timer, CULLING_SHOTS
## bullets along that line over CULLING_TIME while he strafes across it (see
## _cull). Busy for all of it.
func the_culling() -> float:
	_culling_direction = _toward_lucian()
	strafe_direction = side_step(global_position, _culling_direction, STRAFE_SPEED * CULLING_TIME, arena, radius)
	face(global_position + _culling_direction)
	warning_parent.add_child(GroundWarning.line(global_position, _culling_direction, CULLING_LENGTH, CULLING_WIDTH, CULLING_WARN))
	_culling_wait = CULLING_WARN
	return CULLING_WARN + CULLING_TIME


## Across the line `toward` from `from`, one way or the other at random; but
## when only the other way's end, `distance` off, fits a body of
## `body_radius` on `map`'s walkable ground (geometry only), that way.
static func side_step(from: Vector2, toward: Vector2, distance: float, map: StageMap, body_radius: float) -> Vector2:
	var side := toward.normalized().orthogonal()
	if randf() < 0.5:
		side = -side
	if map and not map.is_walkable(from + side * distance, body_radius) and map.is_walkable(from - side * distance, body_radius):
		return -side
	return side


func _can_use(id: StringName) -> bool:
	match id:
		&"relentless_pursuit":
			return wants_dodge() or distance_to_target() > CHASE_RANGE
		&"the_culling":
			return hp <= max_hp * CULLING_HP
	return true


## Nothing new while he dashes or fires The Culling.
func _think(delta: float) -> void:
	if not is_dashing() and not is_culling():
		super(delta)


## Two shots: the first gun now, the other SHOT_GAP later.
func _attack() -> void:
	_shoot(-1.0)
	_second_shot_left = SHOT_GAP


## Records the hit for the dodge, which comes from _think.
func _lose_hp(amount: float) -> void:
	_damage_log.append(Vector2(_clock, amount))
	super(amount)


## The dash and The Culling go on whether or not Lucian can be fought, so
## they always end.
func _physics_process(delta: float) -> void:
	super(delta)
	if not is_alive():
		_finish_trail()
		return
	_clock += delta
	while not _damage_log.is_empty() and _clock - _damage_log[0].x > DODGE_WINDOW:
		_damage_log.pop_front()
	if _second_shot_left > 0.0:
		_second_shot_left -= delta
		if _second_shot_left <= 0.0 and can_fight():
			_shoot(1.0)
	if is_dashing():
		_dash_step(delta)
	if _culling_wait > 0.0:
		_culling_wait -= delta
		if _culling_wait <= 0.0:
			_culling_left = CULLING_TIME
			_culling_shots = CULLING_SHOTS
			_culling_gap_left = 0.0
	if _culling_left > 0.0:
		_cull(delta)
	else:
		_hide_culling_band()


## A basic shot at Lucian from the gun on `gun`'s side (-1 or 1).
func _shoot(gun: float) -> void:
	face(target.global_position)
	var bolt := fire_bolt(make_hit(), data.projectile_speed, attack_range + BOLT_OVERREACH)
	bolt.color = SHOT_COLOR
	bolt.style = EnemyProjectile.Style.DARK_BOLT
	var muzzle_offset := Vector2.from_angle(visuals.rotation).orthogonal() * GUN_OFFSET * gun
	bolt.global_position += muzzle_offset
	_spawn_muzzle_flash(bolt.global_position, bolt.direction)


## One step of the dash; walls stop him (his body keeps its mask). At the
## end he is seen and targetable again.
func _dash_step(delta: float) -> void:
	var step := minf(delta, _dash_left)
	_dash_left -= delta
	_dash_echo_left -= delta
	velocity = _dash_direction * (DASH_DISTANCE / DASH_TIME) * (step / delta)
	move_and_slide()
	velocity = Vector2.ZERO
	if is_instance_valid(_trail):
		_trail.reach(global_position)
	if _dash_left > 0.0 and _dash_echo_left <= 0.0:
		_dash_echo_left = DASH_TIME / 3.0
		_spawn_afterimage()
	if _dash_left <= 0.0:
		_dash_left = 0.0
		set_untargetable(false)
		visuals.modulate.a = 1.0
		_finish_trail()


## One step of The Culling: he strafes across the line (walls stop him) and
## fires a bullet along it every CULLING_GAP, each up to CULLING_SPREAD off.
func _cull(delta: float) -> void:
	var step := minf(delta, _culling_left)
	_culling_left -= delta
	velocity = strafe_direction * STRAFE_SPEED * (step / delta)
	move_and_slide()
	velocity = Vector2.ZERO
	face(global_position + _culling_direction)
	_show_culling_band()
	_culling_gap_left -= delta
	while _culling_shots > 0 and _culling_gap_left <= 0.0:
		_culling_gap_left += CULLING_GAP
		_culling_shots -= 1
		if is_instance_valid(target):
			var toward := _culling_direction.rotated(randf_range(-CULLING_SPREAD, CULLING_SPREAD))
			var shot := fire_bolt(skill_hit(CULLING_DAMAGE, DamageInfo.Type.PHYSICAL, &"the_culling"), CULLING_SPEED, CULLING_RANGE, toward)
			shot.color = SHOT_COLOR
			shot.style = EnemyProjectile.Style.DARK_BOLT
			var side := 1.0 if _culling_shots % 2 == 0 else -1.0
			_spawn_muzzle_flash(global_position + _culling_direction * 24.0 + _culling_direction.orthogonal() * GUN_OFFSET * side, toward)
			Sfx.play(&"shot", -8.0)
	if _culling_left <= 0.0:
		_culling_left = 0.0
		_culling_shots = 0
		_hide_culling_band()


## Shows the band from his position along the stream's line (redrawn each
## frame; made on the first).
func _show_culling_band() -> void:
	if _culling_band == null:
		_culling_band = Node2D.new()
		_culling_band.z_index = HazardZone.Z
		_culling_band.draw.connect(_draw_culling_band)
		add_child(_culling_band)
	_culling_band.visible = true
	_culling_band.queue_redraw()


## The band's rectangle, in the band's own space (it sits on him).
func _draw_culling_band() -> void:
	_culling_band.draw_set_transform(Vector2.ZERO, _culling_direction.angle())
	_culling_band.draw_rect(Rect2(0.0, -CULLING_WIDTH / 2.0, CULLING_LENGTH, CULLING_WIDTH), CULLING_BAND)


## Hides the band: the stream ended or he died.
func _hide_culling_band() -> void:
	if is_instance_valid(_culling_band):
		_culling_band.visible = false


func _die() -> void:
	_hide_culling_band()
	super()


## Freed mid-dash (a debug wave jump): his trail lies under warning_parent,
## not on him, so it fades out as a dash's end would have it.
func _exit_tree() -> void:
	_finish_trail()


## The dark laser along Q's line, and its hit on Lucian if he is in it. A
## dead Dark Lucian fires nothing.
func _fire_laser(from: Vector2, toward: Vector2) -> void:
	if not is_alive():
		return
	var beam := LaserBeam.new()
	beam.setup(from, toward, LASER_LENGTH, LASER_WIDTH)
	beam.glow_color = LASER_GLOW
	beam.core_color = LASER_CORE
	beam.center_color = LASER_CENTER
	warning_parent.add_child(beam)
	if Juice.on():
		var flare := _DarkLaserFlareVfx.new()
		flare.setup(from, toward, LASER_LENGTH, LASER_WIDTH)
		warning_parent.add_child(flare)
	Sfx.play(&"zap", -4.0, 0.6)
	if is_instance_valid(target) and GroundWarning.in_line(from, toward, LASER_LENGTH, LASER_WIDTH, target.global_position, Lucian.HIT_RADIUS):
		target.take_damage(skill_hit(LASER_DAMAGE, DamageInfo.Type.PHYSICAL, &"piercing_light"))


## The way to Lucian; the way he faces when Lucian is right on him.
func _toward_lucian() -> Vector2:
	var toward := global_position.direction_to(target.global_position)
	return toward if toward != Vector2.ZERO else Vector2.from_angle(visuals.rotation)


func _finish_trail() -> void:
	if is_instance_valid(_trail):
		_trail.finish()
	_trail = null


func _spawn_muzzle_flash(at: Vector2, toward: Vector2) -> void:
	if not Juice.on():
		return
	var flash := _DarkMuzzleVfx.new()
	flash.setup(at, toward)
	warning_parent.add_child(flash)


func _spawn_afterimage() -> void:
	if not Juice.on() or sprite == null or sprite.texture == null:
		return
	var echo := _AfterimageVfx.new()
	echo.setup(global_position, visuals.rotation, sprite.texture)
	warning_parent.add_child(echo)


class _DarkMuzzleVfx extends Node2D:
	const LIFETIME := 0.12
	var _elapsed := 0.0

	func setup(at: Vector2, toward: Vector2) -> void:
		position = at
		rotation = toward.angle()
		z_index = 6

	func _process(delta: float) -> void:
		_elapsed += delta
		if _elapsed >= LIFETIME:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := clampf(_elapsed / LIFETIME, 0.0, 1.0)
		var alpha := 1.0 - t
		var s := lerpf(1.0, 0.45, t)
		var star := PackedVector2Array([
			Vector2(24.0 * s, 0.0),
			Vector2(4.0 * s, -5.0 * s),
			Vector2(0.0, -14.0 * s),
			Vector2(-4.0 * s, -4.0 * s),
			Vector2(-10.0 * s, 0.0),
			Vector2(-4.0 * s, 4.0 * s),
			Vector2(0.0, 14.0 * s),
			Vector2(4.0 * s, 5.0 * s),
		])
		draw_circle(Vector2(4.0 * s, 0.0), 14.0 * s, Color("8b4dff", alpha * 0.42))
		draw_colored_polygon(star, Color("d4b5ff", alpha * 0.94))
		draw_circle(Vector2(2.0 * s, 0.0), 4.5 * s, Color("1a0b2e", alpha * 0.95))


class _AfterimageVfx extends Node2D:
	const LIFETIME := 0.24
	var _elapsed := 0.0
	var _tex: Texture2D

	func setup(at: Vector2, angle: float, tex: Texture2D) -> void:
		position = at
		rotation = angle
		_tex = tex
		z_index = -1

	func _process(delta: float) -> void:
		_elapsed += delta
		if _elapsed >= LIFETIME:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		if _tex == null:
			return
		var t := clampf(_elapsed / LIFETIME, 0.0, 1.0)
		var alpha := (1.0 - t) * 0.54
		var sz := _tex.get_size()
		draw_texture(_tex, -sz * 0.5, Color(0.58, 0.28, 1.0, alpha))


class _DarkLaserFlareVfx extends Node2D:
	const LIFETIME := 0.28
	var _elapsed := 0.0
	var _length := 1100.0
	var _width := 70.0

	func setup(from: Vector2, toward: Vector2, length: float, width: float) -> void:
		position = from
		rotation = toward.angle()
		_length = length
		_width = width
		z_index = 6

	func _process(delta: float) -> void:
		_elapsed += delta
		if _elapsed >= LIFETIME:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := clampf(_elapsed / LIFETIME, 0.0, 1.0)
		var alpha := 1.0 - pow(t, 1.4)
		# Violet origin starburst & shockwave ring at Dark Lucian's guns.
		var ring_r := lerpf(18.0, 56.0, t)
		draw_circle(Vector2.ZERO, lerpf(42.0, 16.0, t), Color("8c4dff", alpha * 0.45))
		draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 32, Color("d4b5ff", alpha * 0.85), lerpf(4.0, 1.0, t), true)
		var star := PackedVector2Array()
		for i in 8:
			var ang := i * PI * 0.25
			var rad := (46.0 if i % 2 == 0 else 13.0) * (1.0 - t * 0.55)
			star.append(Vector2.from_angle(ang) * rad)
		draw_colored_polygon(star, Color("ead9ff", alpha * 0.9))
		draw_circle(Vector2.ZERO, 12.0 * (1.0 - t * 0.5), Color("160926", alpha * 0.96))
		# Crisp dark-void spine & crackling violet energy arcs along the beam.
		draw_line(Vector2.ZERO, Vector2(_length, 0.0), Color("110620", alpha * 0.96), maxf(_width * 0.14 * (1.0 - t * 0.4), 2.0), true)
		var segs := 18
		for side: float in [-1.0, 1.0]:
			var pts := PackedVector2Array()
			for i in segs + 1:
				var frac := float(i) / segs
				var x := _length * frac
				var y := side * (_width * 0.26) * sin(frac * PI * 6.0 + _elapsed * 32.0 + side)
				pts.append(Vector2(x, y))
			draw_polyline(pts, Color("c492ff", alpha * 0.72), 2.2, true)
