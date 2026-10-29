class_name Monster
extends EnemyUnit
## Act 3's jungle monsters, by behavior. Swarm (raptors): each runs to its own
## spot around Lucian, so a pack wraps him, and bites when in range. Flank
## (wolves): comes round to one side of him, then closes in. Brute (Krugs,
## Blue Sentinel, Red Brambleback): walks in and hits. Spit (Gromp): keeps
## its distance and stands still to spit a bolt. Flee (Rift Scuttler): runs
## straight away from him and never attacks; EnemyUnit's `escape_after` lets
## it get away.

## Swarm: how far from Lucian a raptor's spot is, and how close to it
## counts as there.
const SWARM_RING := 60.0
const SWARM_ARRIVE := 12.0
## Each raptor's spot is this much further round than the last one's (the
## golden angle, in radians), so any pack spreads out.
const SWARM_STEP := 2.39996
## Flank: how far to Lucian's side a wolf aims, until it is this close.
const FLANK_SIDE := 160.0
const FLANK_CLOSE := 250.0
## Spit: seconds Gromp stands still each time it spits.
const SPIT_STAND := 0.4
## Spit: how far it steps back at a time when Lucian is too close.
const BACK_OFF := 100.0

## Raptors spawned so far, for each one's spot.
static var _swarmed := 0

## Swarm: the angle of its spot around Lucian.
var swarm_angle := 0.0
## Flank: the side of its line to Lucian it comes round on: 1 (that line's
## orthogonal()) or -1. Set at spawn.
var flank_side := 1.0

var _stand_left := 0.0


func _ready() -> void:
	super()
	match data.behavior:
		&"swarm":
			var from := target.global_position.direction_to(global_position).angle() if is_instance_valid(target) else 0.0
			swarm_angle = wrapf(from + _swarmed * SWARM_STEP, -PI, PI)
			_swarmed += 1
		&"flank":
			flank_side = 1.0 if randf() < 0.5 else -1.0


func _think(delta: float) -> void:
	match data.behavior:
		&"swarm":
			_swarm(delta)
		&"flank":
			_flank(delta)
		&"spit":
			_spit(delta)
		&"flee":
			walk(target.global_position.direction_to(global_position), delta)
		_:
			super(delta)


func _attack() -> void:
	if data.behavior == &"spit":
		fire_bolt(make_hit(), data.projectile_speed, attack_range + Minion.BOLT_OVERSHOOT)
		return
	super()


## Runs to its spot around Lucian (it follows him), facing him once in
## range, and bites whenever in range and ready.
func _swarm(delta: float) -> void:
	var spot := target.global_position + Vector2.from_angle(swarm_angle) * SWARM_RING
	if global_position.distance_to(spot) > SWARM_ARRIVE:
		walk_toward(spot, delta)
	if distance_to_target() > attack_range + Lucian.HIT_RADIUS:
		return
	face(target.global_position)
	if _attack_left <= 0.0:
		_attack_left = data.attack_interval
		_attack()


## Heads for a point FLANK_SIDE to Lucian's side of its line to him, which
## curves it round to that side, then closes in and hits.
func _flank(delta: float) -> void:
	if distance_to_target() <= FLANK_CLOSE:
		super._think(delta)
		return
	var line := global_position.direction_to(target.global_position)
	walk_toward(target.global_position + line.orthogonal() * FLANK_SIDE * flank_side, delta)


## Keeps keep_min..keep_max from Lucian. In range with the attack ready, it
## stands still for SPIT_STAND and spits, even when he is too close.
func _spit(delta: float) -> void:
	if _stand_left > 0.0:
		_stand_left -= delta
		face(target.global_position)
		return
	var distance := distance_to_target()
	if distance <= attack_range + Lucian.HIT_RADIUS and _attack_left <= 0.0:
		_attack_left = data.attack_interval
		_stand_left = SPIT_STAND
		face(target.global_position)
		_attack()
	elif distance > data.keep_max:
		walk_toward(target.global_position, delta)
	elif distance < data.keep_min:
		walk_toward(global_position + target.global_position.direction_to(global_position) * BACK_OFF, delta)
	else:
		face(target.global_position)
