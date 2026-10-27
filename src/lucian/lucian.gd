class_name Lucian
extends CharacterBody2D
## The player champion. Holds one standing order (move / attack / attack-move)
## and carries it out every physics frame. Attack windups pause the order.

signal health_changed(current: float, maximum: float)
signal mana_changed(current: float, maximum: float)
signal stats_changed(stats: StatBlock)

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

var _order := Order.NONE
var _move_point := Vector2.ZERO
var _target: Enemy
var _attack_cooldown := 0.0
var _windup_left := 0.0
var _show_range_ring := false

@onready var visuals: LucianVisuals = $Visuals


func _ready() -> void:
	stats = base_stats.at_level(progress.level)
	hp = stats.max_hp
	mana = stats.max_mana
	if projectile_parent == null:
		projectile_parent = get_parent()


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
	projectile_parent.add_child(shot)


func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	velocity = Vector2.ZERO
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


func _draw() -> void:
	if _show_range_ring:
		draw_arc(Vector2.ZERO, stats.attack_range, 0.0, TAU, 96, RANGE_RING_COLOR, 3.0, true)


func _process_windup(delta: float) -> void:
	if not is_instance_valid(_target):
		_cancel_windup()
		return
	visuals.face(_target.global_position - global_position)
	_windup_left -= delta
	if _windup_left <= 0.0:
		_windup_left = 0.0
		fire_attack_projectile(LucianVisuals.Gun.RIGHT, _target, roll_attack(1.0, &"basic"))


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
