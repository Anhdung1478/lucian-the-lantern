class_name HighNoonBlast
extends FxBlast
## High Noon's W: a burning cross over a charred ring, embers flying out
## along its four arms.

const OUTER := Color(0.78, 0.19, 0.04, 0.5)
const INNER := Color(1.0, 0.6, 0.23, 0.85)
const CENTER := Color("fff6e0")
const CHAR := Color(0.15, 0.08, 0.05, 0.5)
const EMBER := Color("ffc870")
const EMBERS_PER_ARM := 8
## Seconds the charred ring stays.
const CHAR_TIME := 0.6


func _start() -> void:
	sparks.drag = 2.5
	for arm in 4:
		var direction := Vector2.RIGHT.rotated(arm * PI / 2.0)
		for i in EMBERS_PER_ARM:
			var velocity := direction * randf_range(300.0, 520.0) + direction.orthogonal() * randf_range(-40.0, 40.0)
			sparks.emit(Vector2.ZERO, velocity, randf_range(0.4, 0.55), randf_range(2.0, 3.0), EMBER)


func _lingers() -> bool:
	return not low and age < CHAR_TIME


func details() -> int:
	return sparks.size() + (1 if _lingers() else 0)


func _draw() -> void:
	if _lingers():
		draw_arc(Vector2.ZERO, bar.y * 0.9, 0.0, TAU, 32, Color(CHAR, CHAR.a * (1.0 - age / CHAR_TIME)), 6.0)
	var a := fade()
	if a > 0.0:
		for arm in [bar, Vector2(bar.y, bar.x)]:
			draw_rect(Rect2(-arm * 0.5, arm), Color(OUTER, OUTER.a * a))
			draw_rect(Rect2(-arm * 0.25, arm * 0.5), Color(INNER, INNER.a * a))
		draw_circle(Vector2.ZERO, bar.y * 0.45, Color(CENTER, a))
	sparks.draw_on(self)
