class_name Minion
extends EnemyUnit
## Minions, by behavior. Melee walks at Lucian and strikes. Ranged keeps its
## distance and fires a slow bolt where he stands. Siege marks a circle on
## him and its shell lands a second later. Super strikes in melee and
## Empowers the small minions around it.

## Seconds between Empower pulses, and how long one lasts.
const EMPOWER_PULSE := 0.25
const EMPOWER_TIME := 0.5
## A bolt flies this far past the minion's range before it fades.
const BOLT_OVERSHOOT := 150.0

var _pulse_left := 0.0


func _physics_process(delta: float) -> void:
	super(delta)
	if not is_alive() or data.behavior != &"super":
		return
	_pulse_left -= delta
	if _pulse_left <= 0.0:
		_pulse_left = EMPOWER_PULSE
		_empower()


func _think(delta: float) -> void:
	if data.behavior != &"ranged":
		super(delta)
		return
	var distance := distance_to_target()
	if distance > data.keep_max:
		walk_toward(target.global_position, delta)
	elif distance < data.keep_min:
		# Straight away, no path (a path's goal would be inside the wall it
		# backs into): it slides along a wall, and stands in a corner.
		walk(target.global_position.direction_to(global_position), delta)
	else:
		face(target.global_position)
	if distance <= attack_range + Lucian.HIT_RADIUS and _attack_left <= 0.0:
		_attack_left = data.attack_interval
		_attack()


func _attack() -> void:
	match data.behavior:
		&"ranged":
			fire_bolt(make_hit(), data.projectile_speed, attack_range + BOLT_OVERSHOOT)
		&"siege":
			var warning := GroundWarning.circle(target.global_position, data.area_radius, data.warn_time)
			warning.strike(make_hit(), target)
			warning.sound = &"shell"
			warning_parent.add_child(warning)
		_:
			super()


## Melee and ranged minions within reach deal more damage for a moment.
func _empower() -> void:
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		var minion := enemy as Minion
		if minion and minion != self and minion.data.kind == &"normal" and minion.global_position.distance_to(global_position) <= data.empower_radius:
			minion.add_status(EMPOWER, EMPOWER_TIME, 1, EMPOWER_ICON)
