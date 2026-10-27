class_name Enemy
extends CharacterBody2D
## Anything Lucian can attack: resists, damage intake and skill marks.

signal damage_taken(info: DamageInfo, final_amount: float)

const MARK_RING_COLOR := Color(1.0, 0.55, 0.15, 0.85)

@export var max_hp := 100.0
@export var armor := 0.0
@export var mr := 0.0
## Used for clicking on the enemy and for attack range.
@export var radius := 40.0

var hp := 0.0
## Mark id -> seconds left.
var _marks := {}


func _ready() -> void:
	hp = max_hp
	add_to_group(&"enemies")


func take_damage(info: DamageInfo) -> float:
	var final_amount := DamageCalc.mitigate(info.amount, info.type, armor, mr, info.armor_pen, info.magic_pen)
	_lose_hp(final_amount)
	damage_taken.emit(info, final_amount)
	if is_instance_valid(info.attacker) and info.attacker.has_method(&"on_damage_dealt"):
		info.attacker.on_damage_dealt(self, info, final_amount)
	return final_amount


func add_mark(id: StringName, duration: float) -> void:
	_marks[id] = duration
	queue_redraw()


func has_mark(id: StringName) -> bool:
	return _marks.has(id)


func _lose_hp(amount: float) -> void:
	hp = maxf(hp - amount, 0.0)


func _physics_process(delta: float) -> void:
	for id in _marks.keys():
		_marks[id] -= delta
		if _marks[id] <= 0.0:
			_marks.erase(id)
			queue_redraw()


func _draw() -> void:
	if not _marks.is_empty():
		draw_arc(Vector2.ZERO, radius + 14.0, 0.0, TAU, 48, MARK_RING_COLOR, 4.0, true)
