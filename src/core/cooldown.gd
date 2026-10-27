class_name Cooldown
extends RefCounted

var duration := 0.0
var remaining := 0.0


static func hasted(base: float, haste: float) -> float:
	return base * 100.0 / (100.0 + haste)


func start(base: float, haste := 0.0) -> void:
	duration = hasted(base, haste)
	remaining = duration


## Counts down. Used every frame and for cooldown reduction effects.
func reduce(seconds: float) -> void:
	remaining = maxf(remaining - seconds, 0.0)


func clear() -> void:
	remaining = 0.0


func is_ready() -> bool:
	return remaining <= 0.0


func fraction_remaining() -> float:
	return remaining / duration if duration > 0.0 else 0.0
