class_name SpectralWall
extends Node2D
## Pale spectral slabs on the ground for a while (Karthus's Wall of Pain,
## Thresh's The Box): one straight piece, or a ring of pieces, each a chord
## of the circle. It is no physics body and blocks nothing. Each physics
## frame it takes Lucian's path since the last frame as a segment and checks
## it against every piece with his hit radius (Geometry2D only, no physics
## query), so a walk, a dash or a Flash across a piece is caught. A piece
## touches once; with `break_on_touch` it also goes. Nothing touches while
## Lucian can't be touched (dead, invulnerable, in stasis), and no piece is
## used up meanwhile. The wall fades out over its last FADE_TIME, then frees
## itself. The caller sets `target` and says what a touch does.

## Lucian touched or crossed piece number `piece` (once per piece).
signal touched(piece: int)

enum Style { DEFAULT, KARTHUS, THRESH }

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
## Visual theme for the wall (DEFAULT cyan, KARTHUS necromantic, THRESH chained emerald).
var style := Style.DEFAULT

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
		# Untouchable (dead, God mode, a cutscene, stasis): no touch, and no piece used up.
		var touchable := not target.dead and not target.invulnerable and not target.in_stasis()
		for piece in _pieces.size():
			if touchable and not _touched[piece] and _crossed(piece, from, now):
				_touched[piece] = true
				_broken[piece] = break_on_touch
				if break_on_touch:
					_spawn_shatter(piece)
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


func _spawn_shatter(piece: int) -> void:
	if not Juice.on():
		return
	var host := get_parent()
	if host == null:
		return
	var ends := piece_ends(piece)
	var burst := _ShatterBurst.new()
	burst.setup(ends[0], ends[1], style)
	host.add_child(burst)


## Each standing piece: styled per boss (Karthus necromantic wall with twin
## tomb-pillars, Thresh emerald chained walls with iron corner posts, or
## default pale cyan slab).
func _draw() -> void:
	var rise := minf(_elapsed / RISE_TIME, 1.0)
	match style:
		Style.KARTHUS:
			_draw_karthus(rise)
		Style.THRESH:
			_draw_thresh(rise)
		_:
			_draw_default(rise)


func _draw_default(rise: float) -> void:
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


func _draw_karthus(rise: float) -> void:
	var pulse := 0.5 + 0.5 * sin(_elapsed * 6.0)
	var outer := Color(0.45, 0.18, 0.78, 0.34)
	var mid := Color(0.56, 0.38, 0.92, 0.72)
	var teal := Color(0.32, 0.88, 0.84, 0.62)
	var core := Color(0.92, 0.86, 1.0, 0.94)
	for piece in _pieces.size():
		if _broken[piece]:
			continue
		var a := _pieces[piece][0]
		var b := _pieces[piece][1]
		var seg := b - a
		var dist := seg.length()
		var dir := seg / maxf(dist, 0.001)
		var perp := dir.orthogonal()
		draw_line(a, b, outer, SLAB * 2.1 * rise, true)
		draw_line(a, b, mid, SLAB * 1.05 * rise, true)
		# Writhing necromantic violet-teal spectral filaments along the wall.
		var steps := maxi(int(dist / 28.0), 6)
		var wave_pts := PackedVector2Array()
		for i in steps + 1:
			var t := float(i) / steps
			var sway := sin(_elapsed * 7.0 + t * 14.0) * 6.5 * rise * sin(t * PI)
			wave_pts.append(a.lerp(b, t) + perp * sway)
		draw_polyline(wave_pts, teal, maxf(4.5 * rise, 1.5), true)
		draw_line(a, b, core, maxf(SLAB * 0.18 * rise, 1.0), true)
		# Twin glowing spectral tomb-pillars at the two ends.
		for end: Vector2 in [a, b]:
			var pr := (17.0 + pulse * 2.5) * rise
			draw_circle(end, pr * 1.65, Color(0.55, 0.28, 0.95, 0.28))
			draw_circle(end, pr * 1.15, Color(0.28, 0.85, 0.82, 0.35))
			var oct := PackedVector2Array()
			for k in 8:
				oct.append(end + Vector2.from_angle(k * TAU / 8.0 + PI / 8.0) * pr)
			draw_colored_polygon(oct, Color("1d152b", 0.96))
			draw_polyline(oct + PackedVector2Array([oct[0]]), Color("9c6dff", 0.9), 2.5, true)
			var rune := PackedVector2Array([
				end + Vector2(0.0, -pr * 0.58),
				end + Vector2(pr * 0.42, 0.0),
				end + Vector2(0.0, pr * 0.58),
				end + Vector2(-pr * 0.42, 0.0),
			])
			draw_colored_polygon(rune, Color("66ffe8", 0.92))


func _draw_thresh(rise: float) -> void:
	var pulse := 0.5 + 0.5 * sin(_elapsed * 7.5)
	var outer := Color(0.1, 0.72, 0.46, 0.28)
	var wall_col := Color(0.24, 0.9, 0.62, 0.68)
	var chain_dark := Color(0.09, 0.2, 0.18, 0.9)
	var core := Color(0.82, 1.0, 0.92, 0.92)
	var posts: Array[Vector2] = []
	for piece in _pieces.size():
		if _broken[piece]:
			continue
		var a := _pieces[piece][0]
		var b := _pieces[piece][1]
		for end: Vector2 in [a, b]:
			var seen := false
			for p: Vector2 in posts:
				if p.distance_squared_to(end) < 4.0:
					seen = true
					break
			if not seen:
				posts.append(end)
		var seg := b - a
		var dist := seg.length()
		var dir := seg / maxf(dist, 0.001)
		var perp := dir.orthogonal()
		draw_line(a, b, outer, SLAB * 1.9 * rise, true)
		draw_line(a, b, wall_col, SLAB * 0.9 * rise, true)
		# Linked spectral iron chains suspended along the emerald barrier.
		var link_step := 18.0
		var count := maxi(int(dist / link_step), 2)
		for i in count:
			var t0 := float(i) / count
			var t1 := float(i + 1) / count
			var p0 := a.lerp(b, t0)
			var p1 := a.lerp(b, t1)
			var mid_p := (p0 + p1) * 0.5
			var half_w := (4.8 if i % 2 == 0 else 2.2) * rise
			var quad := PackedVector2Array([
				p0 + perp * half_w,
				p1 + perp * half_w,
				p1 - perp * half_w,
				p0 - perp * half_w,
			])
			draw_colored_polygon(quad, chain_dark)
			draw_line(mid_p - dir * (link_step * 0.35), mid_p + dir * (link_step * 0.35), core, maxf(2.0 * rise, 1.0), true)
		draw_line(a, b, core, maxf(SLAB * 0.16 * rise, 1.0), true)
	# Dark-iron corner posts with glowing emerald lantern cores.
	for post: Vector2 in posts:
		var pr := 13.5 * rise
		draw_circle(post, pr * (1.7 + 0.15 * pulse), Color(0.24, 0.98, 0.62, 0.25))
		var hex := PackedVector2Array()
		for k in 6:
			hex.append(post + Vector2.from_angle(k * TAU / 6.0) * pr)
		draw_colored_polygon(hex, Color("14211e", 0.98))
		draw_polyline(hex + PackedVector2Array([hex[0]]), Color("467568", 0.95), 2.2, true)
		draw_circle(post, pr * 0.48, Color("3cff9e", 0.95))
		draw_circle(post, pr * 0.24, Color("e6fff3", 0.98))


class _ShatterBurst extends Node2D:
	const LIFETIME := 0.38
	var _elapsed := 0.0
	var _shards: Array[Dictionary] = []
	var _color := Color("4dff9a")
	var _core := Color("dcfff0")

	func setup(a: Vector2, b: Vector2, wall_style: int) -> void:
		position = (a + b) * 0.5
		z_index = 6
		match wall_style:
			Style.THRESH:
				_color = Color("3eff98")
				_core = Color("dcfff0")
			Style.KARTHUS:
				_color = Color("9d6bff")
				_core = Color("e8dcff")
			_:
				_color = Color("9beeff")
				_core = Color.WHITE
		var seg := b - a
		var dist := seg.length()
		var dir := seg / maxf(dist, 0.001)
		var perp := dir.orthogonal()
		for i in 12:
			var frac := (float(i) / 11.0 - 0.5) * 0.9
			var origin := dir * (dist * frac)
			var side := 1.0 if i % 2 == 0 else -1.0
			var vel := (perp * side * randf_range(120.0, 260.0)) + (dir * randf_range(-90.0, 90.0))
			_shards.append({
				"pos": origin,
				"vel": vel,
				"rot": randf() * TAU,
				"spin": randf_range(-10.0, 10.0),
				"size": randf_range(7.0, 15.0),
			})

	func _process(delta: float) -> void:
		_elapsed += delta
		if _elapsed >= LIFETIME:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := clampf(_elapsed / LIFETIME, 0.0, 1.0)
		var alpha := (1.0 - t) * (1.0 - t * 0.4)
		for s: Dictionary in _shards:
			var pos: Vector2 = s.pos + s.vel * _elapsed * (1.0 - t * 0.35)
			var ang: float = s.rot + s.spin * _elapsed
			var sz: float = s.size * (1.0 - t * 0.45)
			var f := Vector2.from_angle(ang)
			var p := f.orthogonal()
			var poly := PackedVector2Array([
				pos + f * sz,
				pos + p * (sz * 0.42),
				pos - f * (sz * 0.8),
				pos - p * (sz * 0.36),
			])
			draw_colored_polygon(poly, Color(_color, alpha * 0.85))
			draw_polyline(poly + PackedVector2Array([poly[0]]), Color(_core, alpha), 1.4, true)
