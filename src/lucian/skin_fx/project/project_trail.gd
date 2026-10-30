class_name ProjectTrail
extends FxTrail
## PROJECT's E: a glitch. Three copies of Lucian along the dash, each split
## into a cyan and a magenta image that jitter, over broken scan-line pieces.

const BAND := Color(0.22, 0.91, 1.0, 0.12)
const CYAN := Color(0.2, 0.9, 1.0, 0.45)
const MAGENTA := Color(1.0, 0.25, 0.95, 0.35)
const LINE := Color(0.5, 0.96, 1.0, 0.6)
## Where the copies stand, as shares of the trail.
const COPIES := [0.3, 0.6, 0.85]
const PIECES := 8
## Seconds between glitches (new scan-line pieces and jitter).
const GLITCH_EVERY := 0.05
## The cyan and magenta images sit this far apart, each side.
const SPLIT := 3.0
const JITTER := 4.0

## Each scan-line piece: (y, from share, to share).
var _pieces: Array[Vector3] = []
var _jitter := PackedFloat32Array([0.0, 0.0, 0.0])
var _next_glitch := 0.0


func _process(delta: float) -> void:
	super(delta)
	if age >= _next_glitch:
		_next_glitch = age + GLITCH_EVERY
		_glitch()


func _glitch() -> void:
	_pieces.clear()
	for i in PIECES:
		var start := randf()
		_pieces.append(Vector3(randf_range(-20.0, 20.0), start, minf(start + randf_range(0.08, 0.25), 1.0)))
	for i in _jitter.size():
		_jitter[i] = randf_range(-JITTER, JITTER)


func _draw() -> void:
	draw_rect(Rect2(0, -20, length, 40), BAND)
	for piece in _pieces:
		draw_line(Vector2(piece.y * length, piece.x), Vector2(piece.z * length, piece.x), LINE, 2.0)
	if body == null:
		return
	var half := body.get_size() * 0.5
	for i in COPIES.size():
		var at := Vector2(COPIES[i] * length + _jitter[i], 0)
		draw_texture(body, at - half + Vector2(0, -SPLIT), CYAN)
		draw_texture(body, at - half + Vector2(0, SPLIT), MAGENTA)
