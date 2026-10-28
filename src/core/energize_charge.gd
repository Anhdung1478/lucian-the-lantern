class_name EnergizeCharge
extends RefCounted
## LoL's Energize: 0-100 charge built by basic attacks and by moving (dashes
## count double). At 100 the next basic attack is Energized and uses it up.

const MAX := 100.0
const PER_ATTACK := 9.0
## Units walked for one point of charge.
const UNITS_PER_POINT := 24.0
const DASH_FACTOR := 2.0

var value := 0.0


func add_attack() -> void:
	value = minf(value + PER_ATTACK, MAX)


func add_distance(units: float, dashing: bool) -> void:
	value = minf(value + units / UNITS_PER_POINT * (DASH_FACTOR if dashing else 1.0), MAX)


func is_ready() -> bool:
	return value >= MAX


func consume() -> void:
	value = 0.0
