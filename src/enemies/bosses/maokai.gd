class_name Maokai
extends Boss
## Act 5's first mini boss, in the dead forest. A melee treant. Twisted
## Advance: a circle warning on Lucian, then it leaps there (untargetable in
## the air) and roots him if he is still inside. Nature's Grasp: a line
## warning, then a wave of vines along it that roots on a hit; trees stop it.
## Every root comes from a warning or a wave Lucian can see.

const ADVANCE_RADIUS := 90.0
const ADVANCE_WARN := 0.8
const ADVANCE_LEAP := 0.4
const ADVANCE_DAMAGE := 130.0
const ADVANCE_ROOT := 1.0
const ADVANCE_COOLDOWN := 10.0
const ADVANCE_RANGE := 700.0
const ADVANCE_FIRST := 3.0
const GRASP_LENGTH := 900.0
const GRASP_WIDTH := 140.0
const GRASP_WARN := 0.8
const GRASP_SPEED := 700.0
const GRASP_DAMAGE := 110.0
const GRASP_ROOT := 1.25
const GRASP_COOLDOWN := 12.0
const GRASP_FIRST := 2.0
## Seconds it stands after a skill's warning ends, or after it lands.
const RECOVER := 0.3
const VINE := Color("6fbf4a")


func _ready() -> void:
	super()
	add_skill(&"twisted_advance", ADVANCE_COOLDOWN, ADVANCE_RANGE, ADVANCE_FIRST, twisted_advance)
	add_skill(&"nature_grasp", GRASP_COOLDOWN, GRASP_LENGTH, GRASP_FIRST, nature_grasp)


## A circle warning where Lucian stands (on ground its body fits), then the leap.
func twisted_advance() -> float:
	var spot := Boss.landing_spot(target.global_position, arena, radius)
	face(spot)
	var warning := GroundWarning.circle(spot, ADVANCE_RADIUS, ADVANCE_WARN)
	warning.fired.connect(_leap.bind(spot))
	warning_parent.add_child(warning)
	return ADVANCE_WARN + ADVANCE_LEAP + RECOVER


func _leap(spot: Vector2) -> void:
	if not is_alive():
		return
	landed.connect(_come_down.bind(spot), CONNECT_ONE_SHOT)
	leap_to(spot, ADVANCE_LEAP)


## It lands: Lucian inside the circle takes the hit and, if it landed, the root.
func _come_down(spot: Vector2) -> void:
	if not is_alive() or not is_instance_valid(target):
		return
	if not GroundWarning.in_circle(spot, ADVANCE_RADIUS, target.global_position, Lucian.HIT_RADIUS):
		return
	if target.take_damage(skill_hit(ADVANCE_DAMAGE, DamageInfo.Type.MAGIC, &"twisted_advance")):
		target.add_cc(CrowdControl.Kind.ROOT, ADVANCE_ROOT)


## A line warning at Lucian, then the wave of vines along it.
func nature_grasp() -> float:
	var toward := global_position.direction_to(target.global_position)
	face(target.global_position)
	var warning := GroundWarning.line(global_position, toward, GRASP_LENGTH, GRASP_WIDTH, GRASP_WARN)
	warning.fired.connect(_send_vines.bind(toward))
	warning_parent.add_child(warning)
	return GRASP_WARN + RECOVER


func _send_vines(toward: Vector2) -> void:
	if not is_alive():
		return
	var wave := fire_bolt(skill_hit(GRASP_DAMAGE, DamageInfo.Type.MAGIC, &"nature_grasp"), GRASP_SPEED, GRASP_LENGTH, toward)
	wave.hit_radius = GRASP_WIDTH * 0.5
	wave.front_width = GRASP_WIDTH
	wave.color = VINE
	wave.hit_lucian.connect(_vines_hit)


func _vines_hit() -> void:
	if is_instance_valid(target):
		target.add_cc(CrowdControl.Kind.ROOT, GRASP_ROOT)
