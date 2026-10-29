class_name DamageOverTime
extends RefCounted
## Burns and poisons on one unit. Each id deals `dps` of its damage type for
## its time, in a tick every TICK seconds of burning (a short last tick when
## the time isn't a whole number of ticks). Adding an id that is already
## burning refreshes it and keeps its tick clock, so a burn refreshed every
## frame (standing in lava) still ticks. The unit ticks it from physics and
## takes each hit through its take_damage.

const TICK := 0.5
## Every tick's source: never &"basic", so Thornmail doesn't answer it.
const SOURCE := &"burn"
## Float slack when the burned time reaches a tick.
const EPSILON := 0.0001

## Id -> {dps, type, attacker, left, duration, burned}. `burned`: seconds
## burned since the last tick.
var _running := {}


## Burns for `dps` of `type` per second for `seconds`, credited to `attacker`.
## The same id replaces the old burn.
func add(id: StringName, dps: float, seconds: float, type: DamageInfo.Type, attacker: Node = null) -> void:
	var burned: float = _running[id].burned if _running.has(id) else 0.0
	_running[id] = {"dps": dps, "type": type, "attacker": attacker, "left": seconds,
		"duration": maxf(seconds, 0.01), "burned": burned}


## The ticks due over the next `delta` seconds, as `over_time` hits.
func tick(delta: float) -> Array[DamageInfo]:
	var hits: Array[DamageInfo] = []
	for id: StringName in _running.keys():
		var entry: Dictionary = _running[id]
		var step := minf(delta, entry.left)
		entry.left -= step
		entry.burned += step
		while entry.burned >= TICK - EPSILON:
			entry.burned -= TICK
			hits.append(_hit(entry, TICK))
		if entry.left <= EPSILON:
			if entry.burned > EPSILON:
				hits.append(_hit(entry, entry.burned))
			_running.erase(id)
	return hits


## `id` is burning.
func has(id: StringName) -> bool:
	return _running.has(id)


## Seconds `id` still burns; 0 when it doesn't.
func time_left(id: StringName) -> float:
	return _running[id].left if _running.has(id) else 0.0


## Seconds `id` burns in full, for a buff timer; 0 when it doesn't burn.
func duration(id: StringName) -> float:
	return _running[id].duration if _running.has(id) else 0.0


## Damage per second of every burn together.
func total_dps() -> float:
	var total := 0.0
	for entry: Dictionary in _running.values():
		total += entry.dps
	return total


## The id that burns the longest, or &"" when nothing burns.
func longest() -> StringName:
	var best := &""
	for id: StringName in _running:
		if best == &"" or _running[id].left > _running[best].left:
			best = id
	return best


## Nothing burns.
func is_empty() -> bool:
	return _running.is_empty()


## Puts out every burn at once, with no last tick.
func clear() -> void:
	_running.clear()


func _hit(entry: Dictionary, seconds: float) -> DamageInfo:
	var attacker: Node = entry.attacker if is_instance_valid(entry.attacker) else null
	var info := DamageInfo.create(entry.dps * seconds, entry.type, SOURCE, attacker)
	info.over_time = true
	return info
