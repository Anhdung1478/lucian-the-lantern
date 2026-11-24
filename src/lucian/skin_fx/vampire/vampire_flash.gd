class_name VampireFlash
extends FxPiece
## Vampire's muzzle flash: a crimson-black bloom with a sharp ruby starburst
## throwing blood drops forward.

const DARK := Color(0.24, 0.02, 0.06, 0.65)
const GLOW := Color(0.84, 0.09, 0.2, 0.6)
const CORE := Color("ff4860")
const HOT := Color("ffd6dc")
const DROP := Color("d01830")
const DROPS := 5
## Half the spread of the drops: 40°.
const SPREAD := 0.7


func _init() -> void:
	lifetime = MuzzleFlash.LIFETIME


func _start() -> void:
	for i in DROPS:
		var direction := Vector2.RIGHT.rotated(randf_range(-SPREAD, SPREAD))
		sparks.emit(Vector2(4, 0), direction * randf_range(130.0, 240.0), 0.18, 2.2, DROP if i % 2 == 0 else CORE)


func _draw() -> void:
	var a := fade()
	if a > 0.0:
		SoftShape.ellipse(self, Vector2.ZERO, Vector2(20.0, 15.0), Color(DARK, DARK.a * a), 0.28)
		SoftShape.ellipse(self, Vector2.ZERO, Vector2(15.0, 11.0), Color(GLOW, GLOW.a * a), 0.3)
		ClassicStar.draw(self, Vector2.ZERO, 18.0, 0.0, Color(CORE, 0.9 * a), 0.2)
		draw_circle(Vector2.ZERO, 5.5, Color(HOT, a))
	sparks.draw_on(self)
