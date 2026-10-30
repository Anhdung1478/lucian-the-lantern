class_name ProjectBlast
extends FxBlast
## PROJECT's W: a cross built from grid squares that light up from the
## centre outward, then flicker off one by one, with pixel sparks flying
## from the arm ends. On Low effects: a plain cyan cross that fades.

const CELL_FILL := Color(0.22, 0.91, 1.0, 0.55)
const CELL_EDGE := Color("7ff4ff")
const CORE := Color("f0ffff")
const PLAIN_OUTER := Color(0.22, 0.91, 1.0, 0.45)
const PLAIN_INNER := Color(0.5, 0.96, 1.0, 0.8)
## Seconds the light-up takes to reach the arm ends.
const SPREAD_TIME := 0.12
const SPARKS_PER_END := 3

## Each cell: [centre, side, lit at, off at] (seconds).
var _cells: Array[Array] = []


func _start() -> void:
	var side := bar.y / 3.0
	var reach := bar.x * 0.5
	for arm: Vector2 in [bar, Vector2(bar.y, bar.x)]:
		for column in roundi(arm.x / side):
			for row in roundi(arm.y / side):
				var center := -arm * 0.5 + Vector2(column + 0.5, row + 0.5) * side
				if _has_cell(center):
					continue
				var lit_at := center.length() / reach * SPREAD_TIME
				_cells.append([center, side, lit_at, randf_range(maxf(lit_at + 0.08, 0.2), lifetime)])
	for direction: Vector2 in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
		for i in SPARKS_PER_END:
			sparks.emit(direction * reach, direction.rotated(randf_range(-0.6, 0.6)) * randf_range(120.0, 260.0),
				randf_range(0.25, 0.4), 4.0, CELL_EDGE)


func details() -> int:
	return sparks.size() + _cells.filter(func(cell: Array) -> bool: return age >= cell[2] and age < cell[3]).size()


func _has_cell(center: Vector2) -> bool:
	for cell in _cells:
		if (cell[0] as Vector2).is_equal_approx(center):
			return true
	return false


func _draw() -> void:
	if low:
		var a := fade()
		if a > 0.0:
			for arm in [bar, Vector2(bar.y, bar.x)]:
				draw_rect(Rect2(-arm * 0.5, arm), Color(PLAIN_OUTER, PLAIN_OUTER.a * a))
				draw_rect(Rect2(-arm * 0.25, arm * 0.5), Color(PLAIN_INNER, PLAIN_INNER.a * a))
		return
	for cell in _cells:
		if age >= cell[2] and age < cell[3]:
			var side: float = cell[1]
			var rect := Rect2(cell[0] - Vector2.ONE * (side * 0.5 - 1.0), Vector2.ONE * (side - 2.0))
			draw_rect(rect, CELL_FILL)
			draw_rect(rect, CELL_EDGE, false, 1.0)
	if age < lifetime:
		var d := bar.y * 0.3 * fade()
		draw_colored_polygon(PackedVector2Array([Vector2(d, 0), Vector2(0, d), Vector2(-d, 0), Vector2(0, -d)]), CORE)
	sparks.draw_on(self, FxSparks.Shape.SQUARE)
