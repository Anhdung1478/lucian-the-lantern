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


## Cuts the time left by a share of itself (0.12 = 12%).
func reduce_fraction(fraction: float) -> void:
	remaining *= 1.0 - fraction


func clear() -> void:
	remaining = 0.0


func is_ready() -> bool:
	return remaining <= 0.0


func fraction_remaining() -> float:
	return remaining / duration if duration > 0.0 else 0.0
