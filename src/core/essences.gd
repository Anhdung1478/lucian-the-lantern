class_name Essences
extends RefCounted
## Blue, orange and purple essence: permanent currencies, spent outside stages.

signal changed

const BLUE := &"blue"
const ORANGE := &"orange"
const PURPLE := &"purple"
const KINDS: Array[StringName] = [BLUE, ORANGE, PURPLE]

var _amounts := {BLUE: 0, ORANGE: 0, PURPLE: 0}


func amount(kind: StringName) -> int:
	return _amounts[kind]


func add(kind: StringName, value: int) -> void:
	if value <= 0:
		return
	_amounts[kind] += value
	changed.emit()


## Debug: sets one kind (never below 0).
func set_amount(kind: StringName, value: int) -> void:
	_amounts[kind] = maxi(value, 0)
	changed.emit()


func can_afford(blue: int, orange := 0, purple := 0) -> bool:
	return _amounts[BLUE] >= blue and _amounts[ORANGE] >= orange and _amounts[PURPLE] >= purple


## Pays all three at once, or nothing.
func spend(blue: int, orange := 0, purple := 0) -> bool:
	if not can_afford(blue, orange, purple):
		return false
	_amounts[BLUE] -= blue
	_amounts[ORANGE] -= orange
	_amounts[PURPLE] -= purple
	changed.emit()
	return true


func to_dict() -> Dictionary:
	return {"blue": _amounts[BLUE], "orange": _amounts[ORANGE], "purple": _amounts[PURPLE]}


## JSON numbers load as floats; anything else counts as 0.
func from_dict(data: Dictionary) -> void:
	for kind in KINDS:
		var value: Variant = data.get(String(kind), 0)
		_amounts[kind] = maxi(int(value), 0) if (value is int or value is float) else 0
	changed.emit()
