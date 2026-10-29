class_name Boss
extends EnemyUnit
## A boss: its basic attack (a bolt when its data has a projectile speed),
## plus skills it uses one at a time, each behind a ground warning. A skill
## is {id, cooldown, range, use}; `use` returns how many seconds the boss is
## busy (no walking, no basic attacks). Skill hits are `from_skill`, so
## Banshee's Veil blocks them.

## A landing spot in a rock or the rim moves toward the map's middle this
## far at a time until its body fits (landing_spot).
const LANDING_STEP := 20.0
## A basic bolt flies this far past the attack range.
const BOLT_OVERREACH := 150.0

var skills: Array[Dictionary] = []
## Seconds the boss is busy with a skill.
var busy_left := 0.0
## The map it fights on, for skills that need walkable ground; null outside
## a stage.
var arena: StageMap

var _cooldowns := {}


## `first_delay`: seconds into the fight before its first use.
func add_skill(id: StringName, cooldown: float, reach: float, first_delay: float, use: Callable) -> void:
	skills.append({"id": id, "cooldown": cooldown, "range": reach, "use": use})
	_cooldowns[id] = first_delay


## Where it can land for `spot`: there, or moved toward the map's middle
## (its boss point) until a body of `body_radius` fits on walkable ground
## (geometry only). Unchanged without a map.
static func landing_spot(spot: Vector2, map: StageMap, body_radius: float) -> Vector2:
	if map == null:
		return spot
	var middle := map.boss_point
	while not map.is_walkable(spot, body_radius) and spot.distance_to(middle) > LANDING_STEP:
		spot = spot.move_toward(middle, LANDING_STEP)
	return spot if map.is_walkable(spot, body_radius) else middle


func skill_hit(amount: float, type: DamageInfo.Type, source: StringName) -> DamageInfo:
	var info := DamageInfo.create(amount, type, source, self)
	info.from_skill = true
	return info


func _physics_process(delta: float) -> void:
	for id: StringName in _cooldowns:
		_cooldowns[id] = maxf(_cooldowns[id] - delta, 0.0)
	busy_left = maxf(busy_left - delta, 0.0)
	super(delta)


func _think(delta: float) -> void:
	if busy_left > 0.0:
		return
	for skill in skills:
		if _cooldowns[skill.id] <= 0.0 and distance_to_target() <= skill.range and _can_use(skill.id):
			_cooldowns[skill.id] = skill.cooldown
			busy_left = skill.use.call()
			return
	super(delta)


## While it channels a skill that damage breaks (Soothing Mist, Requiem):
## {"done": damage so far, "need": damage that breaks it}; else {}. The boss
## bar draws the break bar from it.
func channel() -> Dictionary:
	return {}


## Shown after its name on the boss bar ("Phase 2" for Act 6's Thresh); ""
## for none.
func phase_label() -> String:
	return ""


## A skill's own condition (Comeuppance waits for 75% HP).
func _can_use(_id: StringName) -> bool:
	return true


func _attack() -> void:
	if data.projectile_speed > 0.0:
		fire_bolt(make_hit(), data.projectile_speed, attack_range + BOLT_OVERREACH)
	else:
		super()
