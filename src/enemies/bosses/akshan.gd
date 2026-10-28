class_name Akshan
extends Boss
## Act 2's boss, weakened: lower damage, slower attacks, longer warnings.
## Avengerang: a boomerang out and back that hits each way. Heroic Swing: he
## swings around a grapple point, firing outward. Comeuppance: a lock line on
## Lucian, then a burst of shots that pillars stop. Comeuppance waits until
## he is down to 75% HP.

const BOOMERANG_LENGTH := 900.0
const BOOMERANG_SPEED := 1000.0
const BOOMERANG_WARN := 0.8
const BOOMERANG_DAMAGE := 70.0
const BOOMERANG_COOLDOWN := 8.0
const SWING_RADIUS := 300.0
const SWING_WARN := 1.2
const SWING_TIME := 2.5
const SWING_SHOT_GAP := 0.3
const SWING_DAMAGE := 25.0
const SWING_BOLT_SPEED := 700.0
const SWING_BOLT_RANGE := 600.0
const SWING_COOLDOWN := 14.0
## Heroic Swing is used when Lucian is this close.
const SWING_REACH := 800.0
const LOCK_TIME := 2.0
const BURST_SHOTS := 6
const BURST_GAP := 0.12
const BURST_DAMAGE := 40.0
const BURST_SPEED := 1600.0
const BURST_RANGE := 1200.0
const BURST_COOLDOWN := 20.0
const BURST_HP := 0.75
const GOLD := Color("ffe08a")

var _swing_center := Vector2.ZERO
var _swing_left := 0.0
var _swing_angle := 0.0
var _swing_shot_left := 0.0
var _burst_left := 0
var _burst_gap_left := 0.0


func _ready() -> void:
	super()
	add_skill(&"avengerang", BOOMERANG_COOLDOWN, BOOMERANG_LENGTH, 2.0, avengerang)
	add_skill(&"heroic_swing", SWING_COOLDOWN, SWING_REACH, 5.0, heroic_swing)
	add_skill(&"comeuppance", BURST_COOLDOWN, BURST_RANGE, 0.0, comeuppance)


func swinging() -> bool:
	return _swing_left > 0.0


func avengerang() -> float:
	var toward := global_position.direction_to(target.global_position)
	face(target.global_position)
	var warning := GroundWarning.line(global_position, toward, BOOMERANG_LENGTH, 60.0, BOOMERANG_WARN)
	warning.fired.connect(_throw_boomerang.bind(toward))
	warning_parent.add_child(warning)
	return BOOMERANG_WARN + 0.3


func heroic_swing() -> float:
	var center := target.global_position + target.global_position.direction_to(global_position) * 150.0
	var warning := GroundWarning.circle(center, SWING_RADIUS, SWING_WARN)
	warning.fired.connect(start_swing.bind(center))
	warning_parent.add_child(warning)
	return SWING_WARN + SWING_TIME


func comeuppance() -> float:
	var warning := GroundWarning.lock(global_position, target, LOCK_TIME)
	warning.fired.connect(start_burst)
	warning_parent.add_child(warning)
	return LOCK_TIME + BURST_SHOTS * BURST_GAP


## Swings once around `center`, a bolt outward every SWING_SHOT_GAP.
func start_swing(center: Vector2) -> void:
	if dead:
		return
	_swing_center = center
	_swing_left = SWING_TIME
	_swing_shot_left = 0.0
	_swing_angle = (global_position - center).angle()


## BURST_SHOTS shots at Lucian, BURST_GAP apart.
func start_burst() -> void:
	if not dead:
		_burst_left = BURST_SHOTS
		_burst_gap_left = 0.0


func _can_use(id: StringName) -> bool:
	return id != &"comeuppance" or hp <= max_hp * BURST_HP


func _physics_process(delta: float) -> void:
	super(delta)
	if dead:
		return
	if _swing_left > 0.0:
		_swing_left -= delta
		_swing_angle += TAU / SWING_TIME * delta
		global_position = _swing_center + Vector2.from_angle(_swing_angle) * SWING_RADIUS
		face(global_position + Vector2.from_angle(_swing_angle))
		_swing_shot_left -= delta
		if _swing_shot_left <= 0.0:
			_swing_shot_left = SWING_SHOT_GAP
			var bolt := fire_bolt(skill_hit(SWING_DAMAGE, DamageInfo.Type.PHYSICAL, &"heroic_swing"), SWING_BOLT_SPEED, SWING_BOLT_RANGE, Vector2.from_angle(_swing_angle))
			bolt.color = GOLD
	if _burst_left > 0 and can_fight():
		_burst_gap_left -= delta
		if _burst_gap_left <= 0.0:
			_burst_gap_left = BURST_GAP
			_burst_left -= 1
			face(target.global_position)
			var shot := fire_bolt(skill_hit(BURST_DAMAGE, DamageInfo.Type.PHYSICAL, &"comeuppance"), BURST_SPEED, BURST_RANGE)
			shot.color = GOLD
			Sfx.play(&"shot", -4.0)


func _throw_boomerang(toward: Vector2) -> void:
	if dead:
		return
	var boomerang := fire_bolt(skill_hit(BOOMERANG_DAMAGE, DamageInfo.Type.PHYSICAL, &"avengerang"), BOOMERANG_SPEED, BOOMERANG_LENGTH, toward)
	boomerang.return_to = self
	boomerang.hit_radius = 22.0
	boomerang.color = GOLD
