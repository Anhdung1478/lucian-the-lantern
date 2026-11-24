class_name ClassicFlash
extends FxPiece
## Classic's muzzle flash: a soft gold-white glow with a crisp Sentinel star.

const GLOW := Color(UiStyle.GOLD_COLOR, 0.52)
const TEAL := Color(UiStyle.LANTERN_COLOR, 0.65)
const CORE := Color(1.0, 0.98, 0.92)
const STAR_RADIUS := 22.0


func _init() -> void:
	lifetime = MuzzleFlash.LIFETIME


func details() -> int:
	return 0 if low or age >= lifetime else 1


func _draw() -> void:
	var a := fade()
	if a <= 0.0:
		return
	SoftShape.ellipse(self, Vector2.ZERO, Vector2(18.0, 14.0), Color(GLOW, GLOW.a * a), 0.3)
	draw_circle(Vector2.ZERO, 6.5, Color(CORE, a))
	if not low:
		ClassicStar.draw(self, Vector2.ZERO, STAR_RADIUS, 0.0, Color(CORE, 0.95 * a), 0.18)
		ClassicStar.draw(self, Vector2.ZERO, STAR_RADIUS * 0.65, PI / 4.0, Color(TEAL, 0.72 * a), 0.2)
