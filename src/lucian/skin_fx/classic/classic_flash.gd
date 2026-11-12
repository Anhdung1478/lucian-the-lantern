class_name ClassicFlash
extends FxPiece
## Classic's muzzle flash: a gold-white glow with a small four-point star.

const GLOW := Color(UiStyle.GOLD_COLOR, 0.45)
const CORE := Color(1.0, 0.98, 0.9)
const STAR_RADIUS := 20.0


func _init() -> void:
	lifetime = MuzzleFlash.LIFETIME


func details() -> int:
	return 0 if low or age >= lifetime else 1


func _draw() -> void:
	var a := fade()
	if a <= 0.0:
		return
	draw_circle(Vector2.ZERO, 12.0, Color(GLOW, GLOW.a * a))
	draw_circle(Vector2.ZERO, 6.0, Color(CORE, a))
	if not low:
		ClassicStar.draw(self, Vector2.ZERO, STAR_RADIUS, 0.0, Color(CORE, 0.9 * a))
