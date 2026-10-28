class_name Shields
extends RefCounted
## Lucian's shields: each has an id, an amount and a time left (0 = until it
## is used up). A hit is taken out of them in ORDER; a magic-only shield
## takes only magic damage. Every id used must be in ORDER.

## First to absorb first: Kaenic Rookern (magic only), Shieldbow, Barrier,
## Fimbulwinter, then Bloodthirster's Ichorshield, which lasts.
const ORDER: Array[StringName] = [&"magebane", &"lifeline", &"barrier", &"everlasting", &"ichorshield"]

## Id -> {amount, left, duration, magic_only}.
var _shields := {}


## A new shield replaces an older one with the same id.
func add(id: StringName, amount: float, seconds := 0.0, magic_only := false) -> void:
	if amount <= 0.0:
		return
	_shields[id] = {"amount": amount, "left": seconds, "duration": seconds, "magic_only": magic_only}


## Changes a shield's amount (it is added, lasting, if missing); 0 removes it.
func set_amount(id: StringName, amount: float) -> void:
	if amount <= 0.0:
		_shields.erase(id)
	elif _shields.has(id):
		_shields[id].amount = amount
	else:
		add(id, amount)


func remove(id: StringName) -> void:
	_shields.erase(id)


func clear() -> void:
	_shields.clear()


func has(id: StringName) -> bool:
	return _shields.has(id)


func amount(id: StringName) -> float:
	return _shields[id].amount if _shields.has(id) else 0.0


func time_left(id: StringName) -> float:
	return _shields[id].left if _shields.has(id) else 0.0


func duration(id: StringName) -> float:
	return _shields[id].duration if _shields.has(id) else 0.0


func total() -> float:
	var sum := 0.0
	for shield: Dictionary in _shields.values():
		sum += shield.amount
	return sum


## Takes `damage` of `type` out of the shields; returns what gets through.
func absorb(damage: float, type: DamageInfo.Type) -> float:
	for id in ORDER:
		if damage <= 0.0:
			break
		if not _shields.has(id):
			continue
		var shield: Dictionary = _shields[id]
		if shield.magic_only and type != DamageInfo.Type.MAGIC:
			continue
		var taken := minf(shield.amount, damage)
		shield.amount -= taken
		damage -= taken
		if shield.amount <= 0.0:
			_shields.erase(id)
	return damage


func tick(delta: float) -> void:
	for id: StringName in _shields.keys():
		var shield: Dictionary = _shields[id]
		if shield.duration > 0.0:
			shield.left -= delta
			if shield.left <= 0.0:
				_shields.erase(id)
