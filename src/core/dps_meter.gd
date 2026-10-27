class_name DpsMeter
extends RefCounted
## Damage per second over the current session. A session ends after
## `idle_reset` seconds without a hit.

var idle_reset := 5.0
var total := 0.0
var _start := 0.0
var _last := -INF


func record(amount: float, now: float) -> void:
	if now - _last > idle_reset:
		total = 0.0
		_start = now
	total += amount
	_last = now


func elapsed() -> float:
	return 0.0 if total == 0.0 else _last - _start


func dps() -> float:
	return total / maxf(elapsed(), 1.0)


func reset() -> void:
	total = 0.0
	_last = -INF
