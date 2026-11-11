class_name DamageNumberSpawner
extends Node2D
## Shows a floating number above a unit for every hit it takes, and a green
## one for what an enemy heals.

const HEIGHT_ABOVE := 115.0
const SPREAD := 40.0


func spawn(info: DamageInfo, final_amount: float, unit: Node2D, size_scale := 1.0) -> void:
	var number := FloatingNumber.new()
	number.setup(final_amount, info.type, info.is_crit, size_scale)
	_place(number, unit)


## A green "+N" over `unit` (EnemyUnit.healed).
func spawn_heal(amount: float, unit: Node2D) -> void:
	var number := FloatingNumber.new()
	number.setup_heal(amount)
	_place(number, unit)


func _place(number: FloatingNumber, unit: Node2D) -> void:
	number.position = unit.global_position + Vector2(randf_range(-SPREAD, SPREAD), -HEIGHT_ABOVE)
	add_child(number)
