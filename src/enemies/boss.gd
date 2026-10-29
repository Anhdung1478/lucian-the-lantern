class_name Boss
extends EnemyUnit
## A boss: its basic attack (a bolt when its data has a projectile speed),
## plus skills it uses one at a time, each behind a ground warning. A skill
## is {id, cooldown, range, use}; `use` returns how many seconds the boss is
## busy (no walking, no basic attacks). Skill hits are `from_skill`, so
## Banshee's Veil blocks them.

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


## A skill's own condition (Comeuppance waits for 75% HP).
func _can_use(_id: StringName) -> bool:
	return true


func _attack() -> void:
	if data.projectile_speed > 0.0:
		fire_bolt(make_hit(), data.projectile_speed, attack_range + BOLT_OVERREACH)
	else:
		super()
