class_name ItemActives
extends Node
## Item actives on keys 1-6: Hextech Gunblade, Galeforce and Hextech
## Rocketbelt, aimed at the cursor. Every copy of an item shares one cooldown
## (Lucian.item_cooldown), which keeps running after the item is sold.
## Not usable during a cast time or a dash.

const GUNBLADE_RANGE := 700.0
const GUNBLADE_BASE := 175.0
const GUNBLADE_AP := 0.3
const GUNBLADE_SLOW := 2.0
const GALEFORCE_DASH := 200.0
const GALEFORCE_DASH_SPEED := 1400.0
const GALEFORCE_RANGE := 750.0
const GALEFORCE_MISSILES := 3
const GALEFORCE_BASE := 60.0
const GALEFORCE_BONUS_AD := 0.15
const ROCKETBELT_DASH := 275.0
const ROCKETBELT_DASH_SPEED := 1500.0
const ROCKETBELT_BOLTS := 7
## 50 degrees, in radians.
const ROCKETBELT_ARC := 0.8727
## How far the bolts fly from where Lucian stood when he used it.
const ROCKETBELT_RANGE := 900.0
const ROCKETBELT_BASE := 100.0
const ROCKETBELT_AP := 0.1
const ROCKETBELT_SPEED := 0.75
const ROCKETBELT_SPEED_TIME := 2.0
const ACTIVES: Array[StringName] = [&"hextech_gunblade", &"galeforce", &"hextech_rocketbelt"]

var lucian: Lucian

## Galeforce fires once its dash is over.
var _galeforce_pending := false


func setup(owner_lucian: Lucian) -> void:
	lucian = owner_lucian


static func has_active(item: ItemData) -> bool:
	return item != null and ACTIVES.has(item.id)


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
			lucian.start_dash(lucian.aim_direction(aim), GALEFORCE_DASH, GALEFORCE_DASH_SPEED)
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
	var target: Enemy = null
	var best := INF
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if lucian.global_position.distance_to(enemy.global_position) > GUNBLADE_RANGE + enemy.radius:
			continue
		var distance := aim.distance_to(enemy.global_position)
		if distance < best:
			best = distance
			target = enemy
	if target == null:
		return false
	lucian.visuals.face(target.global_position - lucian.global_position)
	target.add_status(Enemy.SLOW, GUNBLADE_SLOW, 1, _icon(&"hextech_gunblade"))
	target.take_damage(lucian.make_damage(GUNBLADE_BASE + GUNBLADE_AP * lucian.stats.ap, DamageInfo.Type.MAGIC, &"hextech_gunblade"))
	var bolt := ChainLightning.new()
	bolt.setup(PackedVector2Array([lucian.global_position, target.global_position]), Color("6fe8d8"))
	lucian.spawn(bolt)
	Sfx.play(&"zap")
	return true


## Cloudburst's missiles at the lowest-health enemy near Lucian.
func _galeforce_missiles() -> void:
	var target: Enemy = null
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if lucian.global_position.distance_to(enemy.global_position) <= GALEFORCE_RANGE + enemy.radius \
				and (target == null or enemy.hp < target.hp):
			target = enemy
	if target == null:
		return
	var damage := GALEFORCE_BASE + GALEFORCE_BONUS_AD * lucian.bonus_ad()
	for i in GALEFORCE_MISSILES:
		var missile := AttackProjectile.new()
		missile.speed = 1600.0
		missile.color = Color("dff4ff")
		missile.glow_color = Color(0.45, 0.75, 1.0, 0.55)
		var offset := Vector2.from_angle(lucian.visuals.rotation + (i - 1) * 0.6) * 30.0
		missile.launch(lucian.global_position + offset, target, lucian.make_damage(damage, DamageInfo.Type.MAGIC, &"galeforce"))
		lucian.spawn(missile)
	Sfx.play(&"shot", 0.0, 1.4)


## Supersonic: a dash, an arc of bolts forward (each enemy hit once), then a
## burst of move speed that fades.
func _rocketbelt(aim: Vector2) -> void:
	var direction := lucian.aim_direction(aim)
	lucian.start_dash(direction, ROCKETBELT_DASH, ROCKETBELT_DASH_SPEED)
	var hit: Array[Enemy] = []
	var damage := ROCKETBELT_BASE + ROCKETBELT_AP * lucian.stats.ap
	for i in ROCKETBELT_BOLTS:
		var angle := direction.angle() + ROCKETBELT_ARC * (float(i) / (ROCKETBELT_BOLTS - 1) - 0.5)
		var bolt := LinearProjectile.new()
		bolt.launch(lucian.global_position, Vector2.from_angle(angle), 1500.0, ROCKETBELT_RANGE, 12.0)
		bolt.color = Color("ffd0f0")
		bolt.glow_color = Color(0.9, 0.4, 1.0, 0.5)
		bolt.hit_enemy.connect(func(enemy: Enemy, _prior: int) -> void:
			if not hit.has(enemy):
				hit.append(enemy)
				enemy.take_damage(lucian.make_damage(damage, DamageInfo.Type.MAGIC, &"hextech_rocketbelt")))
		lucian.spawn(bolt)
	lucian.add_speed_buff(&"rocketbelt", 0.0, ROCKETBELT_SPEED, ROCKETBELT_SPEED_TIME, true)
	Sfx.play(&"refresh", -2.0)


func _cooldown_of(item: ItemData) -> float:
	for effect in item.effects:
		if effect.active:
			return effect.cooldown
	return 0.0


func _icon(id: StringName) -> Texture2D:
	var item: ItemData = lucian.item_catalog.find(id) if lucian.item_catalog else null
	return item.icon if item else null
