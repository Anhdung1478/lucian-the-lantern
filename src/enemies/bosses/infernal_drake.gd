class_name InfernalDrake
extends Boss
## Act 3's first mini boss, in 3-2's last wave. Its fireball burns (the
## data's on-hit burn). Fire Breath: a cone warning, then a hit, and the cone
## burns for a while. Meteor Fall: four circle warnings, one on Lucian and
## three around him, then a hit in each, and each circle burns for a while.
## The burning ground goes down as its warning ends, on the warnings' layer;
## a drake dead by then leaves none.

const BREATH_LENGTH := 550.0
const BREATH_ANGLE := PI / 3.0
const BREATH_WARN := 0.8
const BREATH_DAMAGE := 100.0
## Burning ground, magic damage per second.
const BREATH_BURN := 30.0
const BREATH_COOLDOWN := 9.0
const BREATH_FIRST := 3.0
const METEORS := 4
const METEOR_RADIUS := 120.0
## The meteors after the first (on Lucian) fall this close to him.
const METEOR_SPREAD := 280.0
const METEOR_WARN := 1.2
const METEOR_DAMAGE := 80.0
const METEOR_BURN := 25.0
const METEOR_COOLDOWN := 13.0
const METEOR_FIRST := 6.0
## Meteor Fall is used when Lucian is this close.
const METEOR_REACH := 900.0
## Tries for a meteor spot on walkable ground before it falls on Lucian.
const METEOR_TRIES := 12
## Seconds the burning ground lasts.
const BURN_TIME := 3.0
## Seconds it stands after a skill's warning ends.
const RECOVER := 0.3
## The cone's arc is a polygon of this many sides.
const CONE_SIDES := 16
const FIRE := Color("ff7a2a")


func _ready() -> void:
	super()
	# Used whenever the cone reaches him (his body counts).
	add_skill(&"fire_breath", BREATH_COOLDOWN, BREATH_LENGTH + Lucian.HIT_RADIUS, BREATH_FIRST, fire_breath)
	add_skill(&"meteor_fall", METEOR_COOLDOWN, METEOR_REACH, METEOR_FIRST, meteor_fall)


## A cone warning at Lucian; it hits, then the cone burns.
func fire_breath() -> float:
	var toward := global_position.direction_to(target.global_position)
	face(target.global_position)
	var warning := GroundWarning.cone(global_position, toward, BREATH_LENGTH, BREATH_ANGLE, BREATH_WARN)
	warning.strike(skill_hit(BREATH_DAMAGE, DamageInfo.Type.MAGIC, &"fire_breath"), target)
	warning.fired.connect(_burn_cone.bind(global_position, toward))
	warning_parent.add_child(warning)
	return BREATH_WARN + RECOVER


## METEORS circle warnings round Lucian (see meteor_spots); each hits, then
## burns.
func meteor_fall() -> float:
	face(target.global_position)
	for spot in meteor_spots(target.global_position):
		var warning := GroundWarning.circle(spot, METEOR_RADIUS, METEOR_WARN)
		warning.strike(skill_hit(METEOR_DAMAGE, DamageInfo.Type.MAGIC, &"meteor_fall"), target)
		warning.fired.connect(_burn_circle.bind(spot))
		warning_parent.add_child(warning)
	return METEOR_WARN + RECOVER


## Where the meteors fall: the first on `center`, the rest at random within
## METEOR_SPREAD of it, on walkable ground when the map is known (else on
## `center`, after METEOR_TRIES misses).
func meteor_spots(center: Vector2) -> Array[Vector2]:
	var spots: Array[Vector2] = [center]
	for i in METEORS - 1:
		var spot := center
		for attempt in METEOR_TRIES:
			var tried := center + Vector2.from_angle(randf() * TAU) * METEOR_SPREAD * sqrt(randf())
			if arena == null or arena.is_walkable(tried):
				spot = tried
				break
		spots.append(spot)
	return spots


## The cone from `from` along `toward` as a polygon, its arc in CONE_SIDES steps.
static func cone_outline(from: Vector2, toward: Vector2, length: float, angle: float) -> PackedVector2Array:
	var points := PackedVector2Array([from])
	for i in CONE_SIDES + 1:
		points.append(from + Vector2.from_angle(toward.angle() - angle * 0.5 + angle * i / CONE_SIDES) * length)
	return points


## The fireball: the data's bolt (its burn comes with it), in fire colors.
func _attack() -> void:
	fire_bolt(make_hit(), data.projectile_speed, attack_range + BOLT_OVERREACH).color = FIRE


## Fire Breath's warning ended: the cone burns, unless the drake is dead.
func _burn_cone(from: Vector2, toward: Vector2) -> void:
	if not dead:
		_lay(HazardZone.burning(BREATH_BURN, DamageInfo.Type.MAGIC, BURN_TIME).set_polygon(cone_outline(from, toward, BREATH_LENGTH, BREATH_ANGLE)))


## A meteor landed: its circle burns, unless the drake is dead.
func _burn_circle(at: Vector2) -> void:
	if not dead:
		_lay(HazardZone.burning(METEOR_BURN, DamageInfo.Type.MAGIC, BURN_TIME).set_circle(at, METEOR_RADIUS))


## Burning ground on the warnings' layer, under the units.
func _lay(zone: HazardZone) -> void:
	zone.lucian = target
	warning_parent.add_child(zone)
