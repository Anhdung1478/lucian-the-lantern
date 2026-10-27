class_name TrainingDummy
extends StaticBody2D
## LoL-style practice dummy. Takes damage but never dies: HP floors at 1 and
## refills after `reset_delay` seconds without a hit.

signal damage_taken(info: DamageInfo, final_amount: float)

const MARK_RING_COLOR := Color(1.0, 0.55, 0.15, 0.85)

@export var max_hp := 2000.0
@export var armor := 30.0
@export var mr := 30.0
@export var reset_delay := 4.0
## Used for clicking on the dummy and for attack range.
@export var radius := 40.0

var hp := 0.0
var _since_hit := 0.0
## Mark id -> seconds left.
var _marks := {}
var _hit_tween: Tween

@onready var visuals: Node2D = $Visuals
@onready var health_bar: EnemyHealthBar = $HealthBar


func _ready() -> void:
	hp = max_hp
	health_bar.set_health(hp, max_hp)


func take_damage(info: DamageInfo) -> float:
	var final_amount := DamageCalc.mitigate(info.amount, info.type, armor, mr)
	hp = maxf(hp - final_amount, 1.0)
	_since_hit = 0.0
	health_bar.set_health(hp, max_hp)
	_play_hit()
	damage_taken.emit(info, final_amount)
	if is_instance_valid(info.attacker) and info.attacker.has_method(&"on_damage_dealt"):
		info.attacker.on_damage_dealt(self, info, final_amount)
	return final_amount


## Debug table hook. Also refills HP.
func set_defenses(new_armor: float, new_mr: float, new_max_hp: float) -> void:
	armor = new_armor
	mr = new_mr
	max_hp = maxf(new_max_hp, 1.0)
	hp = max_hp
	health_bar.set_health(hp, max_hp)


func add_mark(id: StringName, duration: float) -> void:
	_marks[id] = duration
	queue_redraw()


func has_mark(id: StringName) -> bool:
	return _marks.has(id)


func _physics_process(delta: float) -> void:
	for id in _marks.keys():
		_marks[id] -= delta
		if _marks[id] <= 0.0:
			_marks.erase(id)
			queue_redraw()
	if hp < max_hp:
		_since_hit += delta
		if _since_hit >= reset_delay:
			hp = max_hp
			health_bar.set_health(hp, max_hp)


func _draw() -> void:
	if not _marks.is_empty():
		draw_arc(Vector2.ZERO, radius + 14.0, 0.0, TAU, 48, MARK_RING_COLOR, 4.0, true)


func _play_hit() -> void:
	if _hit_tween:
		_hit_tween.kill()
	visuals.modulate = Color(1.8, 1.8, 1.8)
	visuals.rotation = 0.12 if randf() < 0.5 else -0.12
	_hit_tween = create_tween().set_parallel()
	_hit_tween.tween_property(visuals, "modulate", Color.WHITE, 0.15)
	_hit_tween.tween_property(visuals, "rotation", 0.0, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
