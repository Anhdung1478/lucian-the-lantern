class_name SpectralWall
extends Node2D
## Pale spectral slabs on the ground for a while (Karthus's Wall of Pain,
## Thresh's The Box): one straight piece, or a ring of pieces, each a chord
## of the circle. It is no physics body and blocks nothing. Each physics
## frame it takes Lucian's path since the last frame as a segment and checks
## it against every piece with his hit radius (Geometry2D only, no physics
## query), so a walk, a dash or a Flash across a piece is caught. A piece
## touches once; with `break_on_touch` it also goes. The wall fades out over
## its last FADE_TIME, then frees itself. The caller sets `target` and says
## what a touch does.

## Lucian touched or crossed piece number `piece` (once per piece).
signal touched(piece: int)

## Seconds it fades out at the end of its time.
const FADE_TIME := 0.35
## Seconds a slab takes to rise to its full width.
const RISE_TIME := 0.12
## How wide a slab is drawn (the look only: a touch is his hit radius).
const SLAB := 22.0
const GLOW := Color(0.7, 0.95, 1.0, 0.25)
const SLAB_COLOR := Color(0.8, 0.95, 1.0, 0.7)
const CORE := Color(1.0, 1.0, 1.0, 0.9)

## Whose path is checked: the caller sets it.
var target: Lucian
## A touched piece breaks and goes (The Box).
var break_on_touch := false
## Seconds it stands, the fade included.
var lifetime := 1.0

## Each piece's two ends, relative to the wall.
var _pieces: Array[PackedVector2Array] = []
var _touched: Array[bool] = []
var _broken: Array[bool] = []
var _elapsed := 0.0
## Where Lucian was last frame; not finite before the first.
var _last_at := Vector2.INF


## One straight piece `length` long, centered on `center`, along `along`.
static func line(center: Vector2, along: Vector2, length: float, seconds: float) -> SpectralWall:
	var half := along.normalized() * length * 0.5
	var ends: Array[PackedVector2Array] = [PackedVector2Array([-half, half])]
	return _made(center, ends, seconds)


## `pieces` pieces round the circle of `radius` about `center`, each a chord
## between neighboring points on it: a closed ring.
static func ring(center: Vector2, radius: float, pieces: int, seconds: float) -> SpectralWall:
	var ends: Array[PackedVector2Array] = []
	for i in pieces:
		ends.append(PackedVector2Array([Vector2.from_angle(TAU * i / pieces) * radius,
			Vector2.from_angle(TAU * (i + 1) / pieces) * radius]))
	return _made(center, ends, seconds)


static func _made(center: Vector2, ends: Array[PackedVector2Array], seconds: float) -> SpectralWall:
	var wall := SpectralWall.new()
	wall.position = center
	wall.lifetime = seconds
	wall._pieces = ends
	wall._touched.resize(ends.size())
	wall._broken.resize(ends.size())
	return wall


func piece_count() -> int:
	return _pieces.size()


## Piece `piece`'s two ends, on the map (the wall in the tree).
func piece_ends(piece: int) -> PackedVector2Array:
	return PackedVector2Array([to_global(_pieces[piece][0]), to_global(_pieces[piece][1])])


## The piece was touched with break_on_touch, and is gone.
func is_broken(piece: int) -> bool:
	return _broken[piece]


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if is_instance_valid(target):
		var now := target.global_position
		var from := _last_at if _last_at.is_finite() else now
		_last_at = now
		for piece in _pieces.size():
			if not _touched[piece] and _crossed(piece, from, now):
				_touched[piece] = true
				_broken[piece] = break_on_touch
				touched.emit(piece)
	modulate.a = clampf((lifetime - _elapsed) / FADE_TIME, 0.0, 1.0)
	queue_redraw()
	if _elapsed >= lifetime:
		queue_free()


## Lucian's path from `from` to `to` comes within his hit radius of the piece.
func _crossed(piece: int, from: Vector2, to: Vector2) -> bool:
	var ends := piece_ends(piece)
	var closest := Geometry2D.get_closest_points_between_segments(from, to, ends[0], ends[1])
	return closest[0].distance_to(closest[1]) <= Lucian.HIT_RADIUS


## Each standing piece: a faint glow, the pale slab with round ends, and a
## bright core, rising to full width as the wall comes up.
func _draw() -> void:
	var rise := minf(_elapsed / RISE_TIME, 1.0)
	for piece in _pieces.size():
		if _broken[piece]:
			continue
		var a := _pieces[piece][0]
		var b := _pieces[piece][1]
		draw_line(a, b, GLOW, SLAB * 1.8 * rise)
		draw_line(a, b, SLAB_COLOR, SLAB * rise)
		for end: Vector2 in [a, b]:
			draw_circle(end, SLAB * 0.5 * rise, SLAB_COLOR)
		draw_line(a, b, CORE, maxf(SLAB * 0.2 * rise, 1.0))
