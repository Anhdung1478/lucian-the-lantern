class_name DamageNumberSpawner
extends Node2D
## Shows a floating number above a unit for every hit it takes.

const HEIGHT_ABOVE := 115.0
const SPREAD := 40.0


func spawn(info: DamageInfo, final_amount: float, unit: Node2D, size_scale := 1.0) -> void:
	var number := FloatingNumber.new()
	number.setup(final_amount, info.type, info.is_crit, size_scale)
	number.position = unit.global_position + Vector2(randf_range(-SPREAD, SPREAD), -HEIGHT_ABOVE)
	add_child(number)
