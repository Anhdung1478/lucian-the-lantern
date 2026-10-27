class_name Lucian
extends CharacterBody2D
## The player champion. Holds one standing order (move / attack / attack-move)
## and carries it out every physics frame. Attack windups pause the order.

enum Order { NONE, MOVE, ATTACK, ATTACK_MOVE }

## Share of the attack period spent winding up before the shot leaves the gun.
const WINDUP_RATIO := 0.15
const RANGE_RING_COLOR := Color(1.0, 0.91, 0.66, 0.35)

@export var base_stats: UnitStats

var progress := ChampionProgress.new()
var stats: StatBlock
var hp := 0.0
var mana := 0.0
## Where spawned shots go. Set by the stage.
var projectile_parent: Node
## Debug: values >= 0 replace Lucian's crit chance.
var cheat_crit_chance := -1.0
var cheat_no_cooldowns := false
var cheat_infinite_mana := false

var _order := Order.NONE
var _move_point := Vector2.ZERO
var _target: Enemy
var _attack_cooldown := 0.0
var _windup_left := 0.0
var _show_range_ring := false
var _cast_lock_left := 0.0
var _dash_velocity := Vector2.ZERO
var _dash_left := 0.0

@onready var visuals: LucianVisuals = $Visuals
@onready var skills: Array[LucianSkill] = [$Skills/Q, $Skills/W, $Skills/E, $Skills/R]
@onready var passive: Lightslinger = $Skills/Passive


func _ready() -> void:
	stats = base_stats.at_level(progress.level)
	hp = stats.max_hp
	mana = stats.max_mana
	if projectile_parent == null:
		projectile_parent = get_parent()
	progress.level_changed.connect(_on_level_changed)


func command_move(point: Vector2) -> void:
	_cancel_windup()
	_order = Order.MOVE
	_move_point = point


func command_attack(target: Enemy) -> void:
	if target != _target:
		_cancel_windup()
	_order = Order.ATTACK
	_target = target


func command_attack_move(point: Vector2) -> void:
	_cancel_windup()
	_order = Order.ATTACK_MOVE
	_move_point = point
	_target = null


func try_rank_up(slot: ChampionProgress.Slot) -> bool:
	return progress.rank_up(slot)


## The cast gate: rank, cooldown, state and mana, then pay and cast.
func try_cast(slot: ChampionProgress.Slot, aim: Vector2) -> bool:
	var skill := skills[slot]
	if skill.rank() == 0 or not skill.cooldown.is_ready() or is_cast_locked() or is_dashing():
		return false
	if mana < skill.mana_cost():
		return false
	mana -= skill.mana_cost()
	skill.cooldown.start(0.0 if cheat_no_cooldowns else skill.cooldown_seconds(), stats.ability_haste)
	_cancel_windup()
	skill.execute(aim)
	passive.charge()
	return true


## Called by an enemy after it takes damage from Lucian.
func on_damage_dealt(_target: Enemy, info: DamageInfo, _final_amount: float) -> void:
	if info.source == &"lightslinger":
		skills[ChampionProgress.Slot.E].cooldown.reduce(passive.e_cooldown_reduction)


## Every enemy whose hurtbox overlaps `shape` placed at `xform`, found instantly.
func query_enemies(shape: Shape2D, xform: Transform2D) -> Array[Enemy]:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = xform
	query.collision_mask = Layers.ENEMY_HURTBOX
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var found: Array[Enemy] = []
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 64):
		var hurtbox := hit.collider as Hurtbox
		if hurtbox and hurtbox.unit is Enemy and not found.has(hurtbox.unit):
			found.append(hurtbox.unit)
	return found


## Lucian stands still for `seconds` (a cast time); the standing order resumes after.
func lock_cast(seconds: float) -> void:
	_cast_lock_left = seconds


func is_cast_locked() -> bool:
	return _cast_lock_left > 0.0


## Dashes through enemies (walls still stop him). A move order ends here, but
## attack orders carry on, and the attack timer resets.
func start_dash(direction: Vector2, distance: float, speed: float) -> void:
	_cancel_windup()
	_dash_velocity = direction * speed
	_dash_left = distance / speed
	_attack_cooldown = 0.0
	collision_mask = Layers.WORLD
	if _order == Order.MOVE:
		_order = Order.NONE
	visuals.face(direction)


func is_dashing() -> bool:
	return _dash_left > 0.0


func set_range_ring_visible(value: bool) -> void:
	_show_range_ring = value
	queue_redraw()


func current_move_speed() -> float:
	return stats.move_speed


func crit_chance() -> float:
	return cheat_crit_chance if cheat_crit_chance >= 0.0 else stats.crit_chance


func roll_attack(ad_ratio: float, source: StringName) -> DamageInfo:
	var crit := DamageCalc.is_crit(crit_chance(), randf())
	var amount := stats.ad * ad_ratio * (stats.crit_damage if crit else 1.0)
	return DamageInfo.create(amount, DamageInfo.Type.PHYSICAL, source, self, crit)


func fire_attack_projectile(gun: LucianVisuals.Gun, target: Enemy, info: DamageInfo) -> void:
	var shot := AttackProjectile.new()
	shot.launch(visuals.muzzle_position(gun), target, info)
	spawn(shot)


## Adds a projectile or effect to the stage.
func spawn(node: Node) -> void:
	projectile_parent.add_child(node)


## Direction from Lucian to `aim`; his facing if the aim is right on top of him.
func aim_direction(aim: Vector2) -> Vector2:
	var offset := aim - global_position
	return offset.normalized() if offset.length() > 1.0 else Vector2.from_angle(visuals.rotation)


func _physics_process(delta: float) -> void:
	hp = minf(hp + stats.hp_regen * delta, stats.max_hp)
	mana = stats.max_mana if cheat_infinite_mana else minf(mana + stats.mana_regen * delta, stats.max_mana)
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	velocity = Vector2.ZERO
	if _dash_left > 0.0:
		_dash_step(delta)
		return
	if _cast_lock_left > 0.0:
		_cast_lock_left -= delta
		return
	if _windup_left > 0.0:
		_process_windup(delta)
		return
	match _order:
		Order.MOVE:
			if _step_toward(_move_point, delta):
				_order = Order.NONE
		Order.ATTACK:
			if is_instance_valid(_target):
				_pursue(_target, delta)
			else:
				_order = Order.NONE
		Order.ATTACK_MOVE:
			if not is_instance_valid(_target) or not _in_range(_target):
				_target = _nearest_enemy_in_range()
			if _target:
				_pursue(_target, delta)
			elif _step_toward(_move_point, delta):
				_order = Order.NONE


## Leveling up grants the max HP / mana gained, like LoL.
func _on_level_changed(_level: int) -> void:
	var old := stats
	stats = base_stats.at_level(progress.level)
	hp = clampf(hp + stats.max_hp - old.max_hp, 1.0, stats.max_hp)
	mana = clampf(mana + stats.max_mana - old.max_mana, 0.0, stats.max_mana)
	queue_redraw()


func _draw() -> void:
	if _show_range_ring:
		draw_arc(Vector2.ZERO, stats.attack_range, 0.0, TAU, 96, RANGE_RING_COLOR, 3.0, true)


func _dash_step(delta: float) -> void:
	# The last frame only covers the distance that is left.
	velocity = _dash_velocity * minf(delta, _dash_left) / delta
	move_and_slide()
	velocity = Vector2.ZERO
	_dash_left -= delta
	if _dash_left <= 0.0 or get_slide_collision_count() > 0:
		_dash_left = 0.0
		collision_mask = Layers.WORLD | Layers.ENEMY_BODY


func _process_windup(delta: float) -> void:
	if not is_instance_valid(_target):
		_cancel_windup()
		return
	visuals.face(_target.global_position - global_position)
	_windup_left -= delta
	if _windup_left <= 0.0:
		_windup_left = 0.0
		passive.fire_basic_attack(_target)


## Walks into range of `target`, then attacks whenever the attack is ready.
func _pursue(target: Enemy, delta: float) -> void:
	if not _in_range(target):
		_step_toward(target.global_position, delta)
		return
	visuals.face(target.global_position - global_position)
	if _attack_cooldown <= 0.0:
		var period := stats.attack_period()
		_attack_cooldown = period
		_windup_left = period * WINDUP_RATIO


## A cancelled windup refunds the attack, like LoL.
func _cancel_windup() -> void:
	if _windup_left > 0.0:
		_windup_left = 0.0
		_attack_cooldown = 0.0


func _in_range(target: Enemy) -> bool:
	return global_position.distance_to(target.global_position) <= stats.attack_range + target.radius


func _nearest_enemy_in_range() -> Enemy:
	var best: Enemy = null
	var best_distance := INF
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		var distance := global_position.distance_to(enemy.global_position)
		if distance < best_distance and _in_range(enemy):
			best = enemy
			best_distance = distance
	return best


## Moves toward `point` this frame. Returns true once Lucian has arrived.
func _step_toward(point: Vector2, delta: float) -> bool:
	var offset := point - global_position
	var step := current_move_speed() * delta
	if offset.length() <= step:
		velocity = offset / delta
		move_and_slide()
		velocity = Vector2.ZERO
		return true
	velocity = offset.normalized() * current_move_speed()
	visuals.face(offset)
	move_and_slide()
	return false
