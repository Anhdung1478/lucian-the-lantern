class_name Lucian
extends CharacterBody2D
## The player champion. Holds one standing order (move / attack / attack-move)
## and carries it out every physics frame.

signal health_changed(current: float, maximum: float)
signal mana_changed(current: float, maximum: float)
signal stats_changed(stats: StatBlock)

enum Order { NONE, MOVE }

@export var base_stats: UnitStats

var progress := ChampionProgress.new()
var stats: StatBlock
var hp := 0.0
var mana := 0.0

var _order := Order.NONE
var _move_point := Vector2.ZERO

@onready var visuals: LucianVisuals = $Visuals


func _ready() -> void:
	stats = base_stats.at_level(progress.level)
	hp = stats.max_hp
	mana = stats.max_mana


func command_move(point: Vector2) -> void:
	_order = Order.MOVE
	_move_point = point


func current_move_speed() -> float:
	return stats.move_speed


func _physics_process(delta: float) -> void:
	match _order:
		Order.MOVE:
			if _step_toward(_move_point, delta):
				_order = Order.NONE
		_:
			velocity = Vector2.ZERO


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
