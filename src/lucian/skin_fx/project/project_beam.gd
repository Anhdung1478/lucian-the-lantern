class_name ProjectBeam
extends FxBeam
## PROJECT's Q: a hologram beam. Bright cyan edge lines over a see-through
## fill and scan lines sweeping along it. In its second half it breaks into
## pixels that wink out one by one, instead of fading. On Low effects it
## fades whole.

const FILL := Color(0.22, 0.91, 1.0, 0.2)
const EDGE := Color("7ff4ff")
const CENTER := Color("f0ffff")
const SCAN := Color(0.5, 0.96, 1.0, 0.5)
const PIXEL := Color(0.22, 0.91, 1.0, 0.55)
const SCAN_LINES := 5
## Scan lines sweep this many px a second.
const SCAN_SPEED := 2400.0
## Pixel rows across the beam.
const ROWS := 3
const SPARKS := 16

## Each pixel's share of the lifetime when it winks out (0.5–1).
var _pixel_ends := PackedFloat32Array()
var _columns := 0


func _start() -> void:
	_columns = maxi(ceili(length / (width / ROWS)), 1)
	for i in _columns * ROWS:
		_pixel_ends.append(randf_range(0.5, 1.0))
	for i in SPARKS:
		var side := 1.0 if randf() < 0.5 else -1.0
		sparks.emit(Vector2(randf_range(0.0, length), side * width * 0.45), Vector2(0.0, side * randf_range(20.0, 80.0)),
			randf_range(0.3, 0.45), randf_range(3.0, 5.0), EDGE)


func details() -> int:
	return sparks.size() + (SCAN_LINES if not low and age < lifetime else 0)


func _draw() -> void:
	if age < lifetime:
		if low:
			_draw_whole(fade())
		elif progress() < 0.5:
			_draw_whole(1.0)
		else:
			_draw_pixels()
		if not low:
			_draw_scan_lines()
	sparks.draw_on(self, FxSparks.Shape.SQUARE)


func _draw_whole(a: float) -> void:
	draw_rect(Rect2(0, -width * 0.5, length, width), Color(FILL, FILL.a * a))
	draw_line(Vector2(0, -width * 0.5), Vector2(length, -width * 0.5), Color(EDGE, a), 3.0)
	draw_line(Vector2(0, width * 0.5), Vector2(length, width * 0.5), Color(EDGE, a), 3.0)
	draw_rect(Rect2(0, -width * 0.06, length, width * 0.12), Color(CENTER, a))


func _draw_pixels() -> void:
	var cell := width / ROWS
	var p := progress()
	for column in _columns:
		var x := column * cell
		var side := minf(cell, length - x) - 1.0
		for row in ROWS:
			if p < _pixel_ends[column * ROWS + row]:
				draw_rect(Rect2(x, -width * 0.5 + row * cell, side, cell - 1.0), PIXEL)


func _draw_scan_lines() -> void:
	for i in SCAN_LINES:
		var x := fmod(age * SCAN_SPEED + i * length / SCAN_LINES, length)
		draw_line(Vector2(x, -width * 0.5), Vector2(x, width * 0.5), SCAN, 2.0)
