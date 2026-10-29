class_name CrowdControl
extends RefCounted
## Roots, stuns and fears on one unit (Lucian), one timer per kind. Tenacity
## shortens the time when it is added; a new one of the same kind keeps the
## longer time. The unit ticks it from physics and decides what each kind
## stops.

enum Kind { ROOT, STUN, FEAR }

## Kind -> {left, duration}.
var _running := {}
## Where the fear that holds the time came from.
var _fear_from := Vector2.ZERO


## `kind` for `seconds`, shortened by `tenacity` (0.3 = 30% shorter). The same
## kind keeps the longer time; a fear that takes the time also takes its
## `from`.
func add(kind: Kind, seconds: float, tenacity: float, from := Vector2.ZERO) -> void:
	var time := seconds * (1.0 - clampf(tenacity, 0.0, 1.0))
	if time <= 0.0 or time <= time_left(kind):
		return
	_running[kind] = {"left": time, "duration": time}
	if kind == Kind.FEAR:
		_fear_from = from


## Counts every kind down by `delta` seconds; the ones run out end.
func tick(delta: float) -> void:
	for kind: Kind in _running.keys():
		_running[kind].left -= delta
		if _running[kind].left <= 0.0:
			_running.erase(kind)


func has(kind: Kind) -> bool:
	return _running.has(kind)


## Seconds `kind` still lasts; 0 when it isn't on.
func time_left(kind: Kind) -> float:
	return _running[kind].left if _running.has(kind) else 0.0


## The full seconds `kind` was given, for a buff timer; 0 when it isn't on.
func duration(kind: Kind) -> float:
	return _running[kind].duration if _running.has(kind) else 0.0


## Where the fear came from: the feared unit runs away from it.
func fear_from() -> Vector2:
	return _fear_from


## Ends every kind at once.
func clear() -> void:
	_running.clear()
