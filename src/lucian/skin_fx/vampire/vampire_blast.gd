class_name VampireBlast
extends FxBlast
## Vampire's W: a crimson cross bursting into a blood splash, with four
## small bats flying out along its arms.

const OUTER := Color(0.29, 0.03, 0.07, 0.6)
const INNER := Color(0.82, 0.09, 0.19, 0.85)
const CENTER := Color("ff3a50")
const DROP := Color("d01830")
const DROPS := 14
const BATS := 4
const BAT_SPEED := 520.0
const BAT_SPAN := 36.0
## Seconds the bats fly.
const BAT_TIME := 0.5

var _bats_out := false


func _start() -> void:
	_bats_out = true
	sparks.drag = 3.0
	for i in DROPS:
		var direction := Vector2.RIGHT.rotated(randf() * TAU)
		sparks.emit(Vector2.ZERO, direction * randf_range(200.0, 420.0), randf_range(0.35, 0.5), randf_range(3.0, 5.0), DROP)


func _lingers() -> bool:
	return _bats_out and age < BAT_TIME


func details() -> int:
	return sparks.size() + (BATS if _lingers() else 0)


func _draw() -> void:
	var a := fade()
	if a > 0.0:
		for arm in [bar, Vector2(bar.y, bar.x)]:
			draw_rect(Rect2(-arm * 0.5, arm), Color(OUTER, OUTER.a * a))
			draw_rect(Rect2(-arm * 0.25, arm * 0.5), Color(INNER, INNER.a * a))
		draw_circle(Vector2.ZERO, bar.y * 0.45, Color(CENTER, a))
	sparks.draw_on(self)
	if _lingers():
		# The bats stop at the arm ends.
		var reach := minf(age * BAT_SPEED, bar.x * 0.5)
		for i in BATS:
			var heading := i * TAU / BATS
			VampireBat.draw(self, Vector2.RIGHT.rotated(heading) * reach, heading, BAT_SPAN, sin(age * 40.0 + i), 1.0 - age / BAT_TIME)
