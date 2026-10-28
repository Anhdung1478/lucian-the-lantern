class_name RestoreOverTime
extends RefCounted
## Potions being drunk. Each one restores its HP and mana evenly over its
## restore time; several run at the same time. Ticked from physics, so
## nothing is restored while the game is paused.

## One per drink: {id, hp_rate, mana_rate, left, duration}.
var _running: Array[Dictionary] = []


func start(potion: ItemData) -> void:
	start_amount(potion.id, potion.restore_hp, potion.restore_mana, potion.restore_time)


## Restores `hp` and `mana` evenly over `seconds`, listed under `id`.
func start_amount(id: StringName, hp: float, mana: float, seconds: float) -> void:
	var duration := maxf(seconds, 0.01)
	_running.append({
		"id": id,
		"hp_rate": hp / duration,
		"mana_rate": mana / duration,
		"left": duration,
		"duration": duration,
	})


## HP (x) and mana (y) restored over the next `delta` seconds.
func tick(delta: float) -> Vector2:
	var restored := Vector2.ZERO
	for entry in _running:
		var step := minf(delta, entry.left)
		restored += Vector2(entry.hp_rate, entry.mana_rate) * step
		entry.left -= step
	_running.assign(_running.filter(func(entry: Dictionary) -> bool: return entry.left > 0.0))
	return restored


func is_empty() -> bool:
	return _running.is_empty()


## How many drinks of potion `id` are running.
func count(id: StringName) -> int:
	return _running.filter(func(entry: Dictionary) -> bool: return entry.id == id).size()


## Seconds until the last running drink of `id` ends.
func time_left(id: StringName) -> float:
	var longest := 0.0
	for entry in _running:
		if entry.id == id:
			longest = maxf(longest, entry.left)
	return longest


## Seconds a full drink of `id` lasts, for the buff timer; 0 when none runs.
func duration(id: StringName) -> float:
	for entry in _running:
		if entry.id == id:
			return entry.duration
	return 0.0
