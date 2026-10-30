class_name FxPiece
extends Node2D
## A skin effect that shows its main shape for `lifetime` seconds and frees
## itself once its details are gone, never later than FxSparks.MAX_LIFE.
## With Low effects (`low`, read when it enters the tree) it makes no
## particles or other details: only the main shape.

var lifetime := 0.25
var age := 0.0
var low := false
var sparks := FxSparks.new()


func _ready() -> void:
	low = GameSettings.instance().low_effects()
	if not low:
		_start()


## Makes the first particles and details. Never called on Low effects.
func _start() -> void:
	pass


func _process(delta: float) -> void:
	age += delta
	sparks.step(delta)
	if age >= FxSparks.MAX_LIFE or (age >= lifetime and sparks.is_empty() and not _lingers()):
		queue_free()
		return
	queue_redraw()


## True while a detail other than particles (a scorch ring, bats) still shows.
func _lingers() -> bool:
	return false


## How many particles and other details (rings, bats, scan lines) show now.
## Always 0 on Low effects.
func details() -> int:
	return sparks.size()


## 0 → 1 over `lifetime`.
func progress() -> float:
	return clampf(age / lifetime, 0.0, 1.0)


## The main shape's alpha: 1 → 0 over `lifetime`, like the linear fade of
## LaserBeam and CrossBlast.
func fade() -> float:
	return 1.0 - progress()
