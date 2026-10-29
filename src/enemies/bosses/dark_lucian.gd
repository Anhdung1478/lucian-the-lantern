class_name DarkLucian
extends Boss
## Act 4's boss, on 4-3's dark lane: a mirror of Lucian, with no passive and
## no W. His basic attack is two shots, one from each gun. Piercing Light
## (Q): a line warning at Lucian, then a dark laser along it. Relentless
## Pursuit (E): a quick dash, untargetable on the way, so shots in flight
## miss: sideways once he has taken a lot of damage lately, or at Lucian
## when Lucian is far. The Culling (R, at or below 80% HP): a wide line
## warning at Lucian, then a stream of bullets along that fixed line while
## he strafes across it.
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
var _trail: DashTrail
## The Culling: seconds of its warning left, then seconds of the stream.
var _culling_wait := 0.0
var _culling_left := 0.0
var _culling_shots := 0
var _culling_gap_left := 0.0
var _culling_direction := Vector2.RIGHT


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


## A basic shot at Lucian from the gun on `gun`'s side (-1 or 1).
func _shoot(gun: float) -> void:
	face(target.global_position)
	var bolt := fire_bolt(make_hit(), data.projectile_speed, attack_range + BOLT_OVERREACH)
	bolt.color = SHOT_COLOR
	bolt.global_position += Vector2.from_angle(visuals.rotation).orthogonal() * GUN_OFFSET * gun


## One step of the dash; walls stop him (his body keeps its mask). At the
## end he is seen and targetable again.
func _dash_step(delta: float) -> void:
	var step := minf(delta, _dash_left)
	_dash_left -= delta
	velocity = _dash_direction * (DASH_DISTANCE / DASH_TIME) * (step / delta)
	move_and_slide()
	velocity = Vector2.ZERO
	if is_instance_valid(_trail):
		_trail.reach(global_position)
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
	_culling_gap_left -= delta
	while _culling_shots > 0 and _culling_gap_left <= 0.0:
		_culling_gap_left += CULLING_GAP
		_culling_shots -= 1
		if is_instance_valid(target):
			var toward := _culling_direction.rotated(randf_range(-CULLING_SPREAD, CULLING_SPREAD))
			fire_bolt(skill_hit(CULLING_DAMAGE, DamageInfo.Type.PHYSICAL, &"the_culling"), CULLING_SPEED, CULLING_RANGE, toward).color = SHOT_COLOR
			Sfx.play(&"shot", -8.0)
	if _culling_left <= 0.0:
		_culling_left = 0.0
		_culling_shots = 0


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
