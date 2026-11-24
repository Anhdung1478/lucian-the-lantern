class_name ProjectTrail
extends FxTrail
## PROJECT's E: a crisp tapered cyan/magenta digital glitch-ribbon with broken
## data streaks and angular holographic wireframe afterimage echoes.

const CYAN_HEAD := Color(0.18, 0.9, 1.0, 0.34)
const MAGENTA_HEAD := Color(1.0, 0.24, 0.88, 0.24)
const CYAN := Color(0.2, 0.92, 1.0, 0.52)
const MAGENTA := Color(1.0, 0.25, 0.92, 0.42)
const LINE := Color(0.6, 0.98, 1.0, 0.78)
## Where the copies stand, as shares of the trail.
const COPIES := [0.3, 0.6, 0.85]
const PIECES := 9
## Seconds between glitches (new scan-line pieces and jitter).
const GLITCH_EVERY := 0.05
## The cyan and magenta images sit this far apart, each side.
const SPLIT := 3.2
const JITTER := 3.5

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
		var start := randf_range(0.08, 0.85)
		_pieces.append(Vector3(randf_range(-20.0, 20.0), start, minf(start + randf_range(0.08, 0.24), 1.0)))
	for i in _jitter.size():
		_jitter[i] = randf_range(-JITTER, JITTER)


func _draw() -> void:
	if length <= 1.0:
		return
	# Crisp tapered cyan/magenta digital glitch-ribbon (0 width/alpha at origin).
	DashTrail.draw_tapered_ribbon(self, length, 24.0, Color(CYAN_HEAD, 0.0), CYAN_HEAD, true)
	DashTrail.draw_tapered_ribbon(self, length, 13.0, Color(MAGENTA_HEAD, 0.0), MAGENTA_HEAD, true)
	DashTrail.draw_speed_needle(self, length * 0.05, length, 0.0, 0.0, 2.6, LINE)
	DashTrail.draw_speed_needle(self, length * 0.14, length * 0.96, -3.0, -12.0, 1.8, CYAN)
	DashTrail.draw_speed_needle(self, length * 0.18, length * 0.94, 3.0, 12.0, 1.8, MAGENTA)
	for i in _pieces.size():
		var piece := _pieces[i]
		var col := LINE if i % 3 != 0 else MAGENTA
		var y_scaled := piece.x * clampf(piece.y * 1.4, 0.15, 1.0)
		draw_line(Vector2(piece.y * length, y_scaled), Vector2(piece.z * length, y_scaled), Color(col, col.a * piece.z), 2.0)
	if body == null:
		return
	var half := body.get_size() * 0.5
	for i in COPIES.size():
		var share: float = COPIES[i]
		var at := Vector2(share * length + _jitter[i], 0)
		var alpha_scale := 0.5 + 0.5 * share
		draw_texture(body, at - half + Vector2(0, -SPLIT), Color(CYAN, CYAN.a * alpha_scale))
		draw_texture(body, at - half + Vector2(0, SPLIT), Color(MAGENTA, MAGENTA.a * alpha_scale))
		# Angular cyber wireframe diamond framing each holographic echo.
		var r := 18.0 + 4.0 * i
		var wire := PackedVector2Array([at + Vector2(r, 0), at + Vector2(0, r * 0.8), at + Vector2(-r, 0), at + Vector2(0, -r * 0.8), at + Vector2(r, 0)])
		draw_polyline(wire, Color(LINE, 0.35 * alpha_scale), 1.4, true)
