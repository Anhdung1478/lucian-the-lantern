class_name EnemyUnit
extends Enemy
## A fighting enemy built in code from an EnemyData: body, hurtbox, art and
## health bar. It walks at Lucian (on a path around a wall in the way,
## sliding along walls, sidestepping when stuck), attacks when in range,
## and stands still while he is dead or can't be hit. With the data's
## `escape_after` it gets away after that long alive. Subclasses say what an
## attack does (_attack), and may think differently (_think).

## It got away (see escape): no death, no kill.
signal escaped(unit: EnemyUnit)

const HIT_FLASH := Color(1.8, 1.8, 1.8)
## Moving less than this share of its speed in a frame counts as stuck.
const STUCK_SHARE := 0.25
const STUCK_TIME := 0.4
const ELITE_BAR := Vector2(110, 12)
const BOSS_BAR := Vector2(140, 14)
## A super minion's Empower on the minions around it: +15% damage.
const EMPOWER := &"empower"
const EMPOWER_BONUS := 0.15
const EMPOWER_ICON := preload("res://assets/art/ui/status_empower.svg")

var data: EnemyData
var target: Lucian
## The wave it came with (its scaling); its splits come with the same one.
var wave := 1
## It got away: out of the group and every hitbox, it can't take damage or
## die, and it is fading out.
var has_escaped := false
## This unit's numbers, after the act and wave scaling.
var damage := 0.0
var attack_range := 0.0
var move_speed := 0.0
## Where shots and ground warnings go; the parent when not set.
var projectile_parent: Node
var warning_parent: Node
var visuals := Node2D.new()
var health_bar := EnemyHealthBar.new()
## Its way around walls (see walk_toward).
var path_follower := PathFollower.new()

var _attack_left := 0.0
var _stuck_left := 0.0
var _sidestep := 1.0
var _flash_tween: Tween
## Seconds alive, for `escape_after`.
var _alive_time := 0.0


## Call before adding the unit to the tree.
func setup(enemy_data: EnemyData, act: int, of_wave: int, foe: Lucian) -> void:
	data = enemy_data
	target = foe
	wave = of_wave
	max_hp = data.max_hp * data.hp_scale(act, wave)
	armor = data.armor
	mr = data.mr
	radius = data.radius
	damage = data.damage * data.damage_scale(act, wave)
	attack_range = data.attack_range
	move_speed = data.move_speed


func _ready() -> void:
	super()
	collision_layer = Layers.ENEMY_BODY
	collision_mask = Layers.WORLD | Layers.ENEMY_BODY | Layers.PLAYER_BODY
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_child(_circle(data.radius * 0.85))
	var hurtbox := Hurtbox.new()
	hurtbox.collision_layer = Layers.ENEMY_HURTBOX
	hurtbox.collision_mask = 0
	hurtbox.monitoring = false
	hurtbox.add_child(_circle(data.radius + 6.0))
	add_child(hurtbox)
	add_child(visuals)
	var sprite := Sprite2D.new()
	sprite.texture = data.art
	visuals.add_child(sprite)
	if data.is_boss_kind():
		health_bar.size = BOSS_BAR
	elif data.kind == &"elite":
		health_bar.size = ELITE_BAR
		health_bar.badge = true
	health_bar.position = Vector2(0, -data.radius - 34.0)
	health_bar.z_index = 10
	add_child(health_bar)
	health_bar.set_health(hp, max_hp)
	if projectile_parent == null:
		projectile_parent = get_parent()
	if warning_parent == null:
		warning_parent = get_parent()
	_attack_left = randf_range(0.2, data.attack_interval)


func _physics_process(delta: float) -> void:
	super(delta)
	if not is_alive():
		return
	if data.escape_after > 0.0:
		_alive_time += delta
		if _alive_time >= data.escape_after:
			escape()
			return
	_attack_left = maxf(_attack_left - delta, 0.0)
	if can_fight():
		_think(delta)


## Alive and still here (not escaped).
func is_alive() -> bool:
	return super() and not has_escaped


## An escaped unit takes nothing: a shot already in flight can't kill it.
func take_damage(info: DamageInfo) -> float:
	return 0.0 if has_escaped else super(info)


## Gets away, once: it leaves the enemies group and every hitbox first (so
## `_die` and damage do nothing from here), says so through `escaped`, then
## fades out. Nothing for a dead unit.
func escape() -> void:
	if dead or has_escaped:
		return
	has_escaped = true
	_leave_fight()
	escaped.emit(self)
	_fade_out()


func _die() -> void:
	if has_escaped:
		return
	super()


## Lucian is there to fight: alive, not in stasis, not untouchable.
func can_fight() -> bool:
	return is_instance_valid(target) and not target.dead and not target.invulnerable and not target.in_stasis()


func distance_to_target() -> float:
	return global_position.distance_to(target.global_position)


## Move speed after the strongest slow.
func current_speed() -> float:
	return move_speed * (1.0 - slow_amount())


## A hit from this unit (Empower included): its basic attack by default.
func make_hit(amount := -1.0, source := &"basic") -> DamageInfo:
	var dealt := damage if amount < 0.0 else amount
	if has_status(EMPOWER):
		dealt *= 1.0 + EMPOWER_BONUS
	return DamageInfo.create(dealt, data.damage_type, source, self)


## A straight shot from this unit, at Lucian unless `toward` is given; walls
## stop it. A basic attack's bolt carries the data's on-hit slow and burn.
func fire_bolt(hit: DamageInfo, speed: float, reach: float, toward := Vector2.ZERO) -> EnemyProjectile:
	var bolt := EnemyProjectile.new()
	bolt.launch(global_position, toward if toward != Vector2.ZERO else global_position.direction_to(target.global_position), hit, target)
	bolt.speed = speed
	bolt.max_range = reach
	if hit.source == &"basic":
		bolt.hit_lucian.connect(apply_on_hit)
	projectile_parent.add_child(bolt)
	return bolt


## A basic attack landed on Lucian: the data's slow and burn (of its
## burn_type), each under the data's id so one kind of enemy refreshes its own.
func apply_on_hit() -> void:
	if not is_instance_valid(target):
		return
	if data.hit_slow > 0.0:
		target.add_slow(data.id, data.hit_slow, data.hit_slow_time)
	if data.hit_burn > 0.0:
		target.add_burn(data.id, data.hit_burn, data.hit_burn_time, data.burn_type(), self)


## One step toward `point`: straight while no wall is in the way, else along
## a path around it (see PathFollower), as walk does.
func walk_toward(point: Vector2, delta: float) -> void:
	var world := get_world_2d()
	var toward := path_follower.next_point(global_position, point, delta, world.direct_space_state, world.navigation_map)
	walk(global_position.direction_to(toward), delta)


## One step in `direction`, with no path, sliding along walls. A unit that
## barely moved sidesteps for a moment.
func walk(direction: Vector2, delta: float) -> void:
	if _stuck_left > 0.0:
		_stuck_left -= delta
		direction = (direction + direction.orthogonal() * _sidestep).normalized()
	var before := global_position
	velocity = direction * current_speed()
	move_and_slide()
	velocity = Vector2.ZERO
	face(global_position + direction)
	if _stuck_left <= 0.0 and before.distance_to(global_position) < current_speed() * delta * STUCK_SHARE:
		_stuck_left = STUCK_TIME
		if randf() < 0.3:
			_sidestep = -_sidestep


func face(point: Vector2) -> void:
	if point != global_position:
		visuals.rotation = (point - global_position).angle()


## Walks into range, then attacks whenever the attack is ready.
func _think(delta: float) -> void:
	if distance_to_target() > attack_range + Lucian.HIT_RADIUS:
		walk_toward(target.global_position, delta)
		return
	face(target.global_position)
	if _attack_left <= 0.0:
		_attack_left = data.attack_interval
		_attack()


## One attack: by default a hit on Lucian at once (melee), with the data's
## on-hit effects when he takes it.
func _attack() -> void:
	if target.take_damage(make_hit()):
		apply_on_hit()


func _lose_hp(amount: float) -> void:
	super(amount)
	health_bar.set_health(hp, max_hp)


func _show_hit() -> void:
	visuals.modulate = HIT_FLASH
	if _flash_tween:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(visuals, "modulate", Color.WHITE, 0.15)


func _circle(circle_radius: float) -> CollisionShape2D:
	var round_shape := CircleShape2D.new()
	round_shape.radius = circle_radius
	var shape := CollisionShape2D.new()
	shape.shape = round_shape
	return shape
