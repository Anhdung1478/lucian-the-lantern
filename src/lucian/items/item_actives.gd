class_name ItemActives
extends Node
## Item actives on keys 1-6: Hextech Gunblade, Galeforce and Hextech
## Rocketbelt, aimed at the cursor. Every copy of an item shares one cooldown
## (Lucian.item_cooldown), which keeps running after the item is sold.
## Not usable during a cast time or a dash. Lucian can't steer Galeforce's or
## Rocketbelt's dash, and can move again as soon as it lands.

const GUNBLADE_RANGE := 700.0
const GUNBLADE_BASE := 175.0
const GUNBLADE_AP := 0.3
const GUNBLADE_SLOW := 2.0
const GALEFORCE_DASH := 200.0
const GALEFORCE_DASH_SPEED := 1260.0
const GALEFORCE_RANGE := 750.0
const GALEFORCE_MISSILES := 3
const GALEFORCE_BASE := 60.0
const GALEFORCE_BONUS_AD := 0.15
## Missiles leave this far (radians) to each side of the target's direction.
const GALEFORCE_FAN := 1.0
## Dash trails: a pale wind for Galeforce, Rocketbelt's hextech violet.
const GALEFORCE_TRAIL := Color(0.72, 1.0, 0.9)
const ROCKETBELT_TRAIL := Color(0.9, 0.4, 1.0)
const ROCKETBELT_DASH := 275.0
## Slower than the bolts, so they fly ahead of Lucian.
const ROCKETBELT_DASH_SPEED := 800.0
const ROCKETBELT_BOLT_SPEED := 1500.0
const ROCKETBELT_BOLTS := 7
## 50 degrees, in radians.
const ROCKETBELT_ARC := 0.8727
## How far the bolts fly from where Lucian stood when he used it.
const ROCKETBELT_RANGE := 900.0
const ROCKETBELT_BASE := 100.0
const ROCKETBELT_AP := 0.1
const ACTIVES: Array[StringName] = [&"hextech_gunblade", &"galeforce", &"hextech_rocketbelt"]

var lucian: Lucian

## Galeforce fires once its dash is over.
var _galeforce_pending := false


func setup(owner_lucian: Lucian) -> void:
	lucian = owner_lucian


static func has_active(item: ItemData) -> bool:
	return item != null and ACTIVES.has(item.id)


## The range indicator's shape for `item`'s active, or null without one.
static func cast_range(item: ItemData) -> CastRange:
	if item == null:
		return null
	match item.id:
		&"hextech_gunblade":
			return CastRange.target(GUNBLADE_RANGE)
		&"galeforce":
			return CastRange.dash(GALEFORCE_DASH)
		&"hextech_rocketbelt":
			return CastRange.dash(ROCKETBELT_DASH)
	return null


## Uses `item`'s active toward `aim`. False when it is not an active, is on
## cooldown, Lucian is busy, or (Gunblade) there is no enemy in range.
func use(item: ItemData, aim: Vector2) -> bool:
	if not has_active(item) or lucian.is_cast_locked() or lucian.is_dashing():
		return false
	var cooldown := lucian.item_cooldown(item.id)
	if not cooldown.is_ready():
		return false
	match item.id:
		&"hextech_gunblade":
			if not _gunblade(aim):
				return false
		&"galeforce":
			lucian.start_dash(lucian.aim_direction(aim), _dash_length(aim, GALEFORCE_DASH), GALEFORCE_DASH_SPEED, GALEFORCE_TRAIL)
			_galeforce_pending = true
		&"hextech_rocketbelt":
			_rocketbelt(aim)
	cooldown.start(0.0 if lucian.cheat_no_cooldowns else _cooldown_of(item))
	return true


func _physics_process(_delta: float) -> void:
	if _galeforce_pending and not lucian.is_dashing():
		_galeforce_pending = false
		_galeforce_missiles()


## Lightning Bolt: the enemy nearest the cursor within range of Lucian.
func _gunblade(aim: Vector2) -> bool:
	var target := lucian.enemy_near_cursor(aim, GUNBLADE_RANGE)
	if target == null:
		return false
	lucian.visuals.face(target.global_position - lucian.global_position)
	target.add_status(Enemy.SLOW, GUNBLADE_SLOW, 1, _icon(&"hextech_gunblade"))
	lucian.passives.on_enemy_slowed()
	target.take_damage(lucian.make_damage(GUNBLADE_BASE + GUNBLADE_AP * lucian.stats.ap, DamageInfo.Type.MAGIC, &"hextech_gunblade"))
	var bolt := ChainLightning.new()
	bolt.setup(PackedVector2Array([lucian.global_position, target.global_position]), Color("6fe8d8"))
	lucian.spawn(bolt)
	Sfx.play(&"zap")
	return true


## Cloudburst's missiles at the lowest-health enemy near Lucian: they leave
## in a fan and curve onto it.
func _galeforce_missiles() -> void:
	var target: Enemy = null
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if lucian.global_position.distance_to(enemy.global_position) <= GALEFORCE_RANGE + enemy.radius \
				and (target == null or enemy.hp < target.hp):
			target = enemy
	if target == null:
		return
	var damage := GALEFORCE_BASE + GALEFORCE_BONUS_AD * lucian.bonus_ad()
	var toward := lucian.global_position.direction_to(target.global_position)
	lucian.visuals.face(toward)
	for i in GALEFORCE_MISSILES:
		var spread := 0.0 if GALEFORCE_MISSILES == 1 else (float(i) / (GALEFORCE_MISSILES - 1) * 2.0 - 1.0)
		var direction := toward.rotated(spread * GALEFORCE_FAN)
		var missile := HomingMissile.new()
		missile.launch(lucian.global_position + direction * 30.0, direction, target,
			lucian.make_damage(damage, DamageInfo.Type.MAGIC, &"galeforce"))
		lucian.spawn(missile)
	Sfx.play(&"shot", 0.0, 1.4)


## Supersonic: a dash and an arc of bolts forward that outrun it (each enemy
## hit once).
func _rocketbelt(aim: Vector2) -> void:
	var direction := lucian.aim_direction(aim)
	lucian.start_dash(direction, _dash_length(aim, ROCKETBELT_DASH), ROCKETBELT_DASH_SPEED, ROCKETBELT_TRAIL)
	var hit: Array[Enemy] = []
	var damage := ROCKETBELT_BASE + ROCKETBELT_AP * lucian.stats.ap
	for i in ROCKETBELT_BOLTS:
		var angle := direction.angle() + ROCKETBELT_ARC * (float(i) / (ROCKETBELT_BOLTS - 1) - 0.5)
		var bolt := LinearProjectile.new()
		bolt.launch(lucian.global_position, Vector2.from_angle(angle), ROCKETBELT_BOLT_SPEED, ROCKETBELT_RANGE, 12.0)
		bolt.color = Color("ffd0f0")
		bolt.glow_color = Color(0.9, 0.4, 1.0, 0.5)
		bolt.hit_enemy.connect(func(enemy: Enemy, _prior: int) -> void:
			if not hit.has(enemy):
				hit.append(enemy)
				enemy.take_damage(lucian.make_damage(damage, DamageInfo.Type.MAGIC, &"hextech_rocketbelt")))
		lucian.spawn(bolt)
	Sfx.play(&"refresh", -2.0)


## Item dashes go as far as the cursor, up to `longest` (0 on Lucian).
func _dash_length(aim: Vector2, longest: float) -> float:
	return minf(lucian.global_position.distance_to(aim), longest)


func _cooldown_of(item: ItemData) -> float:
	for effect in item.effects:
		if effect.active:
			return effect.cooldown
	return 0.0


func _icon(id: StringName) -> Texture2D:
	var item: ItemData = lucian.item_catalog.find(id) if lucian.item_catalog else null
	return item.icon if item else null
