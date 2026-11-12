class_name TitlePaint
extends RefCounted
## The title art's brush. It gathers filled shapes, strokes and soft glows
## as coloured triangles into one mesh, so a whole layer of art is a single
## draw call, painted once: the renderer only walks that call each frame.
## Shapes are paths in a small SVG-like language: "M x y" starts an outline,
## "L x y" draws a line to a point, "Q cx cy x y" and "C ax ay bx by x y"
## draw curves, and "Z" closes the outline. The numbers are absolute and
## every word is spaced.
## A colour is a Color, or a Callable(point: Vector2) -> Color that tints
## every corner by where it is: a gradient (see linear()).
## Light is painted with the shape itself: rim() fills the band of a shape
## that its copy, moved away from the light, leaves uncovered.

## How many straight pieces flatten one curve.
const CURVE_PIECES := 8
## A glow's sides, and its middle ring: how far out it is (a share of the
## radius) and how bright (a share of the middle's alpha).
const GLOW_SIDES := 28
const GLOW_RING := Vector2(0.35, 0.42)
## Far enough to stand for "the whole plane" when an outline is cut in two.
const FAR := 100000.0
## The sharpest bend a stroke's corner may take before it is cut off.
const MITER_LIMIT := 3.0

var points := PackedVector2Array()
var colors := PackedColorArray()


## The outlines `path` draws, one per "M".
static func outlines(path: String) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	var words := path.split(" ", false)
	var at := Vector2.ZERO
	var i := 0
	while i < words.size():
		var command := words[i]
		i += 1
		match command:
			"M":
				at = _vector(words, i)
				out.append(PackedVector2Array([at]))
				i += 2
			"L":
				at = _vector(words, i)
				out[-1].append(at)
				i += 2
			"Q":
				var control := _vector(words, i)
				var to := _vector(words, i + 2)
				for k in range(1, CURVE_PIECES + 1):
					var t := float(k) / CURVE_PIECES
					out[-1].append(at.lerp(control, t).lerp(control.lerp(to, t), t))
				at = to
				i += 4
			"C":
				var first := _vector(words, i)
				var second := _vector(words, i + 2)
				var to := _vector(words, i + 4)
				for k in range(1, CURVE_PIECES + 1):
					out[-1].append(at.bezier_interpolate(first, second, to, float(k) / CURVE_PIECES))
				at = to
				i += 6
			"Z":
				if out[-1].size() > 2 and out[-1][0].is_equal_approx(out[-1][-1]):
					out[-1].remove_at(out[-1].size() - 1)
	return out


## The first outline of `path`.
static func outline(path: String) -> PackedVector2Array:
	return outlines(path)[0]


## A colour that runs from `from_color` at `from` to `to_color` at `to`,
## flat beyond them. A Callable for any colour argument.
static func linear(from: Vector2, to: Vector2, from_color: Color, to_color: Color) -> Callable:
	var way := to - from
	var length := way.length_squared()
	return func(at: Vector2) -> Color:
		return from_color.lerp(to_color, clampf((at - from).dot(way) / length, 0.0, 1.0))


## A colour that fades from `color` at `center` to clear at `radius`.
static func radial(center: Vector2, radius: float, color: Color) -> Callable:
	return func(at: Vector2) -> Color:
		return Color(color, color.a * clampf(1.0 - at.distance_to(center) / radius, 0.0, 1.0))


## `outline` moved by `by`.
static func moved(outline: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	return Transform2D(0.0, by) * outline


## `outline` turned by `angle` round `pivot`, then moved by `by`.
static func turned(outline: PackedVector2Array, pivot: Vector2, angle: float, by := Vector2.ZERO) -> PackedVector2Array:
	return Transform2D(angle, pivot + by) * (Transform2D(0.0, -pivot) * outline)


## What is left of `outline` once `cutters` are taken away, in pieces
## without holes.
static func cut(outline: PackedVector2Array, cutters: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var pieces: Array[PackedVector2Array] = [outline]
	for cutter in cutters:
		var next: Array[PackedVector2Array] = []
		for piece in pieces:
			next.append_array(_solid(Geometry2D.clip_polygons(piece, cutter)))
		pieces = next
	return pieces


## Where `outline` and `other` overlap, in pieces without holes.
static func overlap(outline: PackedVector2Array, other: PackedVector2Array) -> Array[PackedVector2Array]:
	return _solid(Geometry2D.intersect_polygons(outline, other))


## The rect round `outline`.
static func bounds(outline: PackedVector2Array) -> Rect2:
	var out := Rect2(outline[0], Vector2.ZERO)
	for point in outline:
		out = out.expand(point)
	return out


## Fills every outline of `path`.
func fill(path: String, color: Variant) -> void:
	for piece in outlines(path):
		shape(piece, color)


## Fills `outline`, a polygon whose sides do not cross.
func shape(outline: PackedVector2Array, color: Variant) -> void:
	var tints := _tints(outline, color)
	for index in Geometry2D.triangulate_polygon(outline):
		points.append(outline[index])
		colors.append(tints[index])


## Fills each of `pieces`.
func shapes(pieces: Array[PackedVector2Array], color: Variant) -> void:
	for piece in pieces:
		shape(piece, color)


## Fills the band along the side of `outline` that `toward` points to, as
## wide as `toward` is long: what the outline's copy, moved back by
## `toward`, leaves uncovered. Light on the side facing a light, or shade
## on the side away from it.
func rim(outline: PackedVector2Array, toward: Vector2, color: Variant) -> void:
	shapes(_solid(Geometry2D.clip_polygons(outline, moved(outline, -toward))), color)


## The same band, kept inside `inside` (the part it lies on).
func rim_inside(outline: PackedVector2Array, toward: Vector2, inside: PackedVector2Array, color: Variant) -> void:
	for band in _solid(Geometry2D.clip_polygons(outline, moved(outline, -toward))):
		shapes(overlap(band, inside), color)


## A line along the open `path`, `width` wide.
func stroke(path: String, width: float, color: Variant) -> void:
	for track in outlines(path):
		taper(track, width, width, color)


## A line along the points of `track`, from `from_width` wide at its start
## to `to_width` at its end, `swell` wider in its middle: a fold, a strand,
## a branch or a blade.
func taper(track: PackedVector2Array, from_width: float, to_width: float, color: Variant, swell := 0.0) -> void:
	var count := track.size()
	if count < 2:
		return
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for k in count:
		var before := track[maxi(k - 1, 0)]
		var after := track[mini(k + 1, count - 1)]
		var side := (after - before).normalized().orthogonal()
		if k > 0 and k < count - 1:
			var into := (track[k] - before).normalized().orthogonal()
			side /= maxf(side.dot(into), 1.0 / MITER_LIMIT)
		var t := float(k) / (count - 1)
		var half := (lerpf(from_width, to_width, t) + swell * sin(PI * t)) * 0.5
		left.append(track[k] + side * half)
		right.append(track[k] - side * half)
	var tints_left := _tints(left, color)
	var tints_right := _tints(right, color)
	for k in count - 1:
		_triangle(left[k], left[k + 1], right[k + 1], tints_left[k], tints_left[k + 1], tints_right[k + 1])
		_triangle(left[k], right[k + 1], right[k], tints_left[k], tints_right[k + 1], tints_right[k])


## A straight line from `from` to `to`, `width` wide.
func line(from: Vector2, to: Vector2, width: float, color: Variant) -> void:
	taper(PackedVector2Array([from, to]), width, width, color)


## A filled oval round `center`, `radii` wide each way, turned by `angle`.
func oval(center: Vector2, radii: Vector2, color: Variant, angle := 0.0, sides := 20) -> void:
	shape(oval_outline(center, radii, angle, sides), color)


## An oval's outline.
static func oval_outline(center: Vector2, radii: Vector2, angle := 0.0, sides := 20) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in sides:
		var around := Vector2.from_angle(TAU * k / sides)
		out.append(center + (around * radii).rotated(angle))
	return out


## An oval band round `center`, `radii` to its middle line, `width` wide,
## turned by `angle`: a chain's link, a ring.
func ring(center: Vector2, radii: Vector2, width: float, color: Variant, angle := 0.0, sides := 14) -> void:
	var outer := oval_outline(center, radii + Vector2.ONE * width * 0.5, angle, sides)
	var inner := oval_outline(center, radii - Vector2.ONE * width * 0.5, angle, sides)
	var outer_tints := _tints(outer, color)
	var inner_tints := _tints(inner, color)
	for k in sides:
		var next := (k + 1) % sides
		_triangle(outer[k], outer[next], inner[next], outer_tints[k], outer_tints[next], inner_tints[next])
		_triangle(outer[k], inner[next], inner[k], outer_tints[k], inner_tints[next], inner_tints[k])


## A chain along `track`: links `link` long, an open one lying flat, then
## one on its side, each with a dark edge under it.
func chain(track: PackedVector2Array, link: float, width: float, color: Color, edge: Color) -> void:
	var step := link * 0.74
	var distance := link * 0.5
	var k := 0
	var walked := 0.0
	var flat := true
	while k < track.size() - 1:
		var piece := track[k + 1] - track[k]
		var length := piece.length()
		if walked + length < distance:
			walked += length
			k += 1
			continue
		var along := piece / length
		var middle := track[k] + along * (distance - walked)
		if flat:
			ring(middle, Vector2(link * 0.5, link * 0.27), width + 1.2, edge, along.angle())
			ring(middle, Vector2(link * 0.5, link * 0.27), width, color, along.angle())
		else:
			line(middle - along * link * 0.46, middle + along * link * 0.46, width + 1.6, edge)
			line(middle - along * link * 0.46, middle + along * link * 0.46, width * 1.2, color.lightened(0.12))
		flat = not flat
		distance += step


## A soft glow: `color` in its middle, fading out to nothing at `radii`.
func glow(center: Vector2, radii: Vector2, color: Color) -> void:
	var ring := Color(color, color.a * GLOW_RING.y)
	var clear := Color(color, 0.0)
	for k in GLOW_SIDES:
		var a := Vector2.from_angle(TAU * k / GLOW_SIDES) * radii
		var b := Vector2.from_angle(TAU * (k + 1) / GLOW_SIDES) * radii
		_triangle(center, center + a * GLOW_RING.x, center + b * GLOW_RING.x, color, ring, ring)
		_triangle(center + a * GLOW_RING.x, center + a, center + b, ring, clear, clear)
		_triangle(center + a * GLOW_RING.x, center + b, center + b * GLOW_RING.x, ring, clear, ring)


## A soft glow kept inside `outline`: light from `center` on the part it
## falls on, fading out to nothing at `radius`.
func glow_in(outline: PackedVector2Array, center: Vector2, radius: float, color: Color) -> void:
	var tint := radial(center, radius, color)
	for k in GLOW_SIDES:
		var wedge := PackedVector2Array([center, center + Vector2.from_angle(TAU * k / GLOW_SIDES) * radius,
			center + Vector2.from_angle(TAU * (k + 1) / GLOW_SIDES) * radius])
		shapes(overlap(wedge, outline), tint)


## Draws everything gathered so far on `canvas`, inside its _draw, and
## starts afresh: what is painted next lies over it.
func draw(canvas: CanvasItem) -> void:
	if points.is_empty():
		return
	var indices := PackedInt32Array()
	indices.resize(points.size())
	for i in points.size():
		indices[i] = i
	RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(), indices, points, colors)
	points = PackedVector2Array()
	colors = PackedColorArray()


func _triangle(a: Vector2, b: Vector2, c: Vector2, color_a: Color, color_b: Color, color_c: Color) -> void:
	points.append_array(PackedVector2Array([a, b, c]))
	colors.append_array(PackedColorArray([color_a, color_b, color_c]))


static func _tints(outline: PackedVector2Array, color: Variant) -> PackedColorArray:
	var out := PackedColorArray()
	out.resize(outline.size())
	if color is Color:
		out.fill(color)
	else:
		for k in outline.size():
			out[k] = (color as Callable).call(outline[k])
	return out


## A Geometry2D result as outlines without holes: an outline round a hole
## is cut in two through the hole, and the hole taken from each half.
static func _solid(polygons: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var outers: Array[PackedVector2Array] = []
	var holes: Array[PackedVector2Array] = []
	for polygon in polygons:
		if Geometry2D.is_polygon_clockwise(polygon):
			holes.append(polygon)
		else:
			outers.append(polygon)
	if holes.is_empty():
		return outers
	var hole: PackedVector2Array = holes.pop_back()
	var middle := 0.0
	for point in hole:
		middle += point.x / hole.size()
	var halves: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(-FAR, -FAR), Vector2(middle, -FAR), Vector2(middle, FAR), Vector2(-FAR, FAR)]),
		PackedVector2Array([Vector2(middle, -FAR), Vector2(FAR, -FAR), Vector2(FAR, FAR), Vector2(middle, FAR)])]
	var pieces: Array[PackedVector2Array] = holes.duplicate()
	for outer in outers:
		for half in halves:
			for piece in Geometry2D.intersect_polygons(outer, half):
				pieces.append_array(Geometry2D.clip_polygons(piece, hole))
	return _solid(pieces)


static func _vector(words: PackedStringArray, at: int) -> Vector2:
	return Vector2(words[at].to_float(), words[at + 1].to_float())
