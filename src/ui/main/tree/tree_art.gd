class_name TreeArt
extends RefCounted
## The Evolution Tree page's scenery: a tree at night in the muted greens of
## the Journey map, lit from a moon off the page's top right. draw_back: the
## sky with the moon's glow and a few stars, far hills with mist, dark trees
## at both sides, the mound and the back of the crown. draw_tree: roots, the
## boughs (one per group of nodes, ending in the crown), the trunk with its
## grooves and the moon's rim, the crown's mid and top masses with a teal rim
## on their moonward edge, and a dark pool under every node so its tile and
## name sit on a quiet ground. The nodes are the tree's lights; the art has
## none of its own and nothing on it moves. Everything is laid out once from
## the page's layout and seeded random numbers, so a redraw never moves it.

const STARS := 60
## The moon's light, from off the page's top right: where its glow sits and
## its colour.
const MOON_GLOW_AT := Vector2(1240, -80)
const MOON_LIGHT := Color(0.55, 0.72, 0.86)
## The grove around the tree.
const HILL_FAR := Color("10262c")
const HILL_NEAR := Color("0b1a1d")
const SILHOUETTE := Color("081316")
const GROUND_COLOR := Color("0a1411")
const GRASS_COLOR := Color("1a3326")
const GRASS_LIGHT := Color("26493a")
## The bark: dark, mid and light, its outline and the moon's rim on it.
const BARK_DARK := Color("1d1611")
const BARK_MID := Color("392b20")
const BARK_LIGHT := Color("4c3b2c")
const BARK_EDGE := Color("110c08")
const BARK_RIM := Color(0.56, 0.89, 0.69, 0.3)
## The crown's three tones (back, mid, top) and the moon's teal rim on it.
const LEAF_DEEP := Color("10231d")
const LEAF_MID := Color("173326")
const LEAF_LIGHT := Color("1f412f")
const LEAF_RIM := Color(0.56, 0.89, 0.69, 0.26)
## The dark pool under each node: its colour and size, and how far below the
## node's centre it sits (so the name is in it too).
const NODE_SHADE := Color(0.012, 0.03, 0.026, 0.86)
const SHADE_SIZE := Vector2(250, 270)
const SHADE_DROP := 26.0
## The trunk: the root flare's extra width at the ground and how high it
## reaches, the step between its edge points, its grooves.
const FLARE := 80.0
const FLARE_HEIGHT := 40.0
const EDGE_STEP := 8.0
const GROOVES := 5
## The roots: where each leaves the trunk, across its foot (-1 left, 1 right).
const ROOTS: Array[float] = [-1.0, -0.62, -0.28, 0.3, 0.66, 1.0]
## Boughs: their width where they leave the trunk and at their end.
const BOUGH_ROOT := 30.0
const BOUGH_TIP := 12.0
## The crown, per node and per layer (back, mid, top): how many masses, their
## least and largest radius, how far up they sit, and how far around the node
## they spread.
const CLUMP_LAYERS: Array[Vector4] = [Vector4(3, 92, 122, 6), Vector4(3, 62, 84, 18), Vector4(2, 40, 56, 52)]
const CLUMP_SPREAD := Vector2(84, 62)
## How far out of a tile the crown reaches at least.
const COVER_OUT := 16.0
## A mass's bumps reach this many radii from its middle.
const PUFF_REACH := 1.25
## A mass's shaded underside (how much darker), the size of its lit body and
## how far that body sits toward the moon, in radii.
const CLUMP_SHADE := 0.32
const CLUMP_LIT := 0.86
const CLUMP_LIFT := Vector2(0.06, -0.06)
## Pages with many nodes get fewer masses per node: the counts scale by
## CROWD_NODES / the page's nodes, down to CROWD_MIN.
const CROWD_NODES := 6.0
const CROWD_MIN := 0.5
## A page with this many nodes or more is wide: its crown domes. How far out
## the dome reaches, and how much lower its edge sits (a share of the lift).
const WIDE_NODES := 10
const DOME_REACH := 560.0
const DOME_DROP := 0.9
## A crown over the trunk's tip where no node stands on it.
const TIP_CROWN: Array[Vector3] = [Vector3(4, 70, 96), Vector3(3, 48, 64), Vector3(2, 30, 42)]
## The smallest mass kept when it shrinks to clear the ground or the switch,
## and how far above the ground masses stay.
const CLUMP_MIN := 24.0
const CLUMP_GROUND := 40.0

var page: TreePage
## The trunk's middle (x).
var middle: float
## The trunk's edges, from below the ground up to its tip.
var trunk_left := PackedVector2Array()
var trunk_right := PackedVector2Array()
var grooves: Array[PackedVector2Array] = []
var roots: Array[PackedVector2Array] = []
## Crown masses: (x, y, radius, layer); layer 0 back, 1 mid, 2 top.
var clumps := PackedVector4Array()
## Per mass, the bumps along its top: (dx, dy, radius).
var puffs: Array[PackedVector3Array] = []
## Per mass, faint leaf marks on it: (x, y, angle, length); none on the back.
var leaf_marks: Array[PackedVector4Array] = []


func _init(tree_page: TreePage) -> void:
	page = tree_page
	middle = TreePage.SIZE.x * 0.5
	_lay_trunk(page.rng(40))
	_lay_roots(page.rng(41))
	_lay_canopy(page.rng(43))


## The trunk's width at height `y`, its root flare included.
func width_at(y: float) -> float:
	return page.trunk_width(y) + FLARE * exp(-maxf(TreePage.GROUND_Y - y, 0.0) / FLARE_HEIGHT)


## The mound's grassy rim at `x`.
func rim_y(x: float) -> float:
	var spread := (x - middle) / 420.0
	return TreePage.GROUND_Y + 34.0 - 40.0 * exp(-spread * spread)


## Whether point `at` lies in the crown (inside some mass).
func in_crown(at: Vector2) -> bool:
	for clump in clumps:
		if Vector2(clump.x, clump.y).distance_to(at) <= clump.z:
			return true
	return false


# --- Drawing --------------------------------------------------------------------------


## The sky with the moon's glow, the far hills, the dark trees at both sides,
## the mound and the back of the crown.
func draw_back(canvas: Control) -> void:
	_draw_sky(canvas)
	_draw_hills(canvas)
	_draw_ground(canvas)
	_draw_clumps(canvas, 0, LEAF_DEEP, Color(0, 0, 0, 0))


## The tree: roots, boughs, the trunk, the crown's mid and top masses, the
## pools under the nodes and the grass at the trunk's foot.
func draw_tree(canvas: Control) -> void:
	for root in roots:
		draw_strip(canvas, root, 24.0, 3.0, BARK_MID)
	for bough in page.boughs:
		draw_strip(canvas, bough, BOUGH_ROOT, BOUGH_TIP, BARK_MID, BARK_RIM)
	_draw_trunk(canvas)
	_draw_clumps(canvas, 1, LEAF_MID, Color(LEAF_RIM, LEAF_RIM.a * 0.6))
	_draw_clumps(canvas, 2, LEAF_LIGHT, LEAF_RIM)
	var glow := JourneyMap.glow()
	for center: Vector2 in page.centers.values():
		var at := center + Vector2(0, SHADE_DROP)
		canvas.draw_texture_rect(glow, Rect2(at - SHADE_SIZE * 0.5, SHADE_SIZE), false, NODE_SHADE)
	_draw_foot(canvas)


## A tapered strip along `points`, `from_width` wide at its start and
## `to_width` at its end: lit on its upper side, shaded under, outlined, and
## with `rim` (moonlight) along its upper edge when given.
static func draw_strip(canvas: CanvasItem, points: PackedVector2Array, from_width: float, to_width: float, color: Color, rim := Color(0, 0, 0, 0)) -> void:
	var count := points.size()
	if count < 2:
		return
	var flip := -1.0 if points[-1].x < points[0].x else 1.0
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	var vertices := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for i in count:
		var along := (points[mini(i + 1, count - 1)] - points[maxi(i - 1, 0)]).normalized()
		var across := along.orthogonal() * flip * lerpf(from_width, to_width, float(i) / (count - 1)) * 0.5
		upper.append(points[i] + across)
		lower.append(points[i] - across)
		vertices.append_array([points[i] + across, points[i] - across])
		colors.append_array([color.lightened(0.1), color.darkened(0.4)])
		if i > 0:
			var a := i * 2 - 2
			indices.append_array([a, a + 1, a + 2, a + 1, a + 3, a + 2])
	RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(), indices, vertices, colors)
	canvas.draw_polyline(upper, BARK_EDGE, 1.5, true)
	canvas.draw_polyline(lower, BARK_EDGE, 1.5, true)
	if rim.a > 0.0:
		canvas.draw_polyline(upper, rim, 1.5, true)


## A leaf from `at`, pointing at `angle`.
static func draw_leaf(canvas: CanvasItem, at: Vector2, angle: float, length: float, color: Color) -> void:
	var along := Vector2.from_angle(angle)
	var across := along.orthogonal()
	var points := PackedVector2Array()
	for k in 5:
		var t := k / 4.0
		points.append(at + along * length * t + across * sin(PI * t) * length * 0.32)
	for k in range(3, 0, -1):
		var t := k / 4.0
		points.append(at + along * length * t - across * sin(PI * t) * length * 0.32)
	canvas.draw_colored_polygon(points, color)


## `points` resampled every `step` px along the line.
static func resample(points: PackedVector2Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if points.is_empty():
		return out
	out.append(points[0])
	var carry := 0.0
	for i in range(1, points.size()):
		var from := points[i - 1]
		var length := from.distance_to(points[i])
		var at := step - carry
		while at <= length:
			out.append(from.lerp(points[i], at / length))
			at += step
		carry = length - (at - step)
	if out[-1] != points[-1]:
		out.append(points[-1])
	return out


## Whether a circle at `center` with `radius` overlaps `rect`.
static func circle_hits_rect(center: Vector2, radius: float, rect: Rect2) -> bool:
	var nearest := Vector2(clampf(center.x, rect.position.x, rect.end.x), clampf(center.y, rect.position.y, rect.end.y))
	return nearest.distance_to(center) < radius


# --- Layout ---------------------------------------------------------------------------


func _lay_trunk(rng: RandomNumberGenerator) -> void:
	var phase := Vector2(rng.randf() * TAU, rng.randf() * TAU)
	var top := page.trunk_top
	var y := TreePage.GROUND_Y + 14.0
	while y > top:
		var half := width_at(y) * 0.5
		trunk_left.append(Vector2(middle - half + sin(y * 0.05 + phase.x) * 2.5 + sin(y * 0.13 + phase.y) * 1.2, y))
		trunk_right.append(Vector2(middle + half + sin(y * 0.047 + phase.y) * 2.5 + sin(y * 0.11 + phase.x) * 1.2, y))
		y -= EDGE_STEP
	trunk_left.append(Vector2(middle - TreePage.TRUNK_TIP * 0.3, top - 8.0))
	trunk_right.append(Vector2(middle + TreePage.TRUNK_TIP * 0.3, top - 8.0))
	for k in GROOVES:
		var across := lerpf(-0.34, 0.28, float(k) / (GROOVES - 1)) + rng.randf_range(-0.04, 0.04)
		var from := TreePage.GROUND_Y + 6.0 - rng.randf_range(0.0, 40.0)
		grooves.append(_bark_line(across, from, lerpf(from, top + 20.0, rng.randf_range(0.5, 0.95)), rng.randf() * TAU))


## A wavy line up the bark, `across` of the trunk's width from its middle
## (-0.5 left edge, 0.5 right edge), from `from` up to `to`.
func _bark_line(across: float, from: float, to: float, wave: float) -> PackedVector2Array:
	var line := PackedVector2Array()
	var y := from
	while y > to:
		line.append(Vector2(middle + across * width_at(y) + sin(y * 0.045 + wave) * 2.5, y))
		y -= 10.0
	return line


func _lay_roots(rng: RandomNumberGenerator) -> void:
	var ground := TreePage.GROUND_Y
	for side: float in ROOTS:
		var base := Vector2(middle + side * width_at(ground) * 0.36, ground - 4.0)
		var reach := rng.randf_range(110.0, 190.0) * absf(side) + 40.0
		var end := Vector2(middle + signf(side) * reach, ground + rng.randf_range(22.0, 40.0))
		var bend := Vector2(lerpf(base.x, end.x, 0.45), ground - rng.randf_range(2.0, 14.0))
		roots.append(TreePage.bezier(base, bend, bend.lerp(end, 0.5), end))


func _lay_canopy(rng: RandomNumberGenerator) -> void:
	var crowd := clampf(CROWD_NODES / page.centers.size(), CROWD_MIN, 1.0)
	var shrink := lerpf(0.8, 1.0, crowd)
	# A wide page's crown domes: its outer masses sit lower and smaller, and
	# its outer top masses go, so sky shows along its top line.
	var wide := page.centers.size() >= WIDE_NODES
	for id: StringName in page.centers:
		var center: Vector2 = page.centers[id]
		var outward := signf(center.x - middle)
		var out := clampf(absf(center.x - middle) / DOME_REACH, 0.0, 1.0)
		var dome := 1.0 - out * out * DOME_DROP if wide else 1.0
		for layer in CLUMP_LAYERS.size():
			var spec := CLUMP_LAYERS[layer]
			if wide and layer == 2 and out > 0.6:
				continue
			for k in maxi(1, roundi(spec.x * crowd)):
				var at := center + Vector2(rng.randf_range(-CLUMP_SPREAD.x, CLUMP_SPREAD.x) + outward * rng.randf_range(0.0, 20.0),
					rng.randf_range(-CLUMP_SPREAD.y * dome, CLUMP_SPREAD.y * 0.5) - spec.w * dome)
				_add_clump(at, rng.randf_range(spec.y, spec.z) * shrink * lerpf(1.0, 0.85, 1.0 - dome), layer, rng)
	# Each group's bough ends in the crown.
	for group in page.groups:
		var anchor: Vector2 = group["anchor"]
		for k in 2:
			_add_clump(anchor + Vector2(rng.randf_range(-50.0, 50.0), rng.randf_range(-30.0, 10.0)), rng.randf_range(56.0, 76.0), 1, rng)
	# Every tile stands in the crown: a mass fills any gap around it.
	for id: StringName in page.centers:
		var center: Vector2 = page.centers[id]
		var around := Rect2(center - Vector2.ONE * TreeNodeView.SIZE * 0.5, Vector2.ONE * TreeNodeView.SIZE).grow(COVER_OUT)
		for spot: Vector2 in [around.position, Vector2(around.end.x, around.position.y), around.end, Vector2(around.position.x, around.end.y),
				Vector2(center.x, around.position.y), Vector2(center.x, around.end.y), Vector2(around.position.x, center.y), Vector2(around.end.x, center.y)]:
			if not in_crown(spot) and spot.y < rim_y(spot.x) - 60.0:
				_add_clump(spot.lerp(center, 0.35), rng.randf_range(58.0, 72.0), 1, rng)
	# Where no node stands on the trunk's tip, a crown hides the fork.
	var bare_tip := true
	for id: StringName in page.centers:
		if page.on_trunk[id] and page.centers[id].y <= page.trunk_top + 1.0:
			bare_tip = false
	if bare_tip:
		var tip := Vector2(middle, page.trunk_top - 50.0)
		for layer in TIP_CROWN.size():
			var spec := TIP_CROWN[layer]
			for k in int(spec.x):
				var at := tip + Vector2(rng.randf_range(-90.0, 90.0), rng.randf_range(-40.0, 24.0) - layer * 14.0)
				_add_clump(at, rng.randf_range(spec.y, spec.z), layer, rng)


## Adds a mass, shrunk to stay clear of the switch's band, the ground and the
## page's sides; one left too small is dropped.
func _add_clump(at: Vector2, radius: float, layer: int, rng: RandomNumberGenerator) -> void:
	radius = minf(radius, TreePage.GROUND_Y - CLUMP_GROUND - at.y)
	radius = minf(radius, (at.y - TreePage.CLEAR_TOP) / PUFF_REACH - 1.0)
	radius = minf(radius, minf(at.x - 16.0, TreePage.SIZE.x - 16.0 - at.x) / PUFF_REACH)
	if radius < CLUMP_MIN:
		return
	clumps.append(Vector4(at.x, at.y, radius, layer))
	var bumps := PackedVector3Array()
	for k in rng.randi_range(5, 7):
		var angle := lerpf(-PI * 0.95, -PI * 0.05, (k + rng.randf_range(-0.3, 0.3)) / 6.0)
		bumps.append(Vector3(cos(angle) * radius * 0.78, sin(angle) * radius * 0.78, radius * rng.randf_range(0.3, 0.42)))
	puffs.append(bumps)
	var marks := PackedVector4Array()
	if layer > 0:
		for k in 3:
			var spot := at + Vector2(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.7, 0.2)) * radius
			marks.append(Vector4(spot.x, spot.y, rng.randf() * TAU, rng.randf_range(10.0, 15.0)))
	leaf_marks.append(marks)


# --- Drawing parts --------------------------------------------------------------------


func _draw_sky(canvas: Control) -> void:
	var rect := Rect2(Vector2.ZERO, TreePage.SIZE)
	MainBackdrop.draw_sky(canvas, rect)
	var glow := JourneyMap.glow()
	# The moon's light from off the page, and a faint haze behind the crown
	# so the tree's outline reads against the sky.
	canvas.draw_texture_rect(glow, Rect2(MOON_GLOW_AT - Vector2(900, 640), Vector2(1800, 1280)), false, Color(MOON_LIGHT, 0.16))
	canvas.draw_texture_rect(glow, Rect2(MOON_GLOW_AT - Vector2(420, 320), Vector2(840, 640)), false, Color(MOON_LIGHT, 0.12))
	canvas.draw_texture_rect(glow, Rect2(Vector2(middle, 420) - Vector2(720, 420), Vector2(1440, 840)), false, Color(MOON_LIGHT, 0.06))
	MainBackdrop.draw_stars(canvas, rect, page.rng(1), STARS)


## Two rows of far hills with mist between them, and dark trees standing at
## both sides of the grove.
func _draw_hills(canvas: Control) -> void:
	var size := TreePage.SIZE
	for layer in 2:
		if layer == 1:
			_draw_side_trees(canvas)
		var base := 640.0 + layer * 80.0
		var points := PackedVector2Array([Vector2(0, size.y)])
		var x := 0.0
		while x <= size.x:
			var rise := sin(x * 0.0042 + layer * 2.1) * 34.0 + sin(x * 0.011 + layer) * 14.0
			points.append(Vector2(x, base - rise))
			x += 24.0
		points.append(Vector2(size.x, size.y))
		canvas.draw_colored_polygon(points, HILL_FAR if layer == 0 else HILL_NEAR)
		var rng := page.rng(20 + layer)
		for i in 5:
			var at := Vector2(rng.randf_range(0.0, size.x), base - 10.0 + rng.randf_range(-20.0, 30.0))
			canvas.draw_texture_rect(JourneyMap.glow(), Rect2(at - Vector2(340, 50), Vector2(680, 100)), false, MainBackdrop.MIST_COLOR)


## Dark trees in the grove's corners, framing the page.
func _draw_side_trees(canvas: Control) -> void:
	var rng := page.rng(7)
	var blob := JourneyMap.blob()
	for side: float in [-1.0, 1.0]:
		for k in 2:
			var x := middle + side * (middle - 50.0 - k * 110.0 - rng.randf_range(-20.0, 20.0))
			var top := rng.randf_range(330.0, 420.0) + k * 70.0
			var foot := Vector2(x, 800.0)
			var height := foot.y - top
			canvas.draw_line(foot, Vector2(x + side * rng.randf_range(-12.0, 12.0), top), SILHOUETTE, 12.0 - k * 3.0, true)
			for leaf in 5:
				var at := Vector2(x + rng.randf_range(-60.0, 60.0), top + rng.randf_range(-20.0, height * 0.4))
				var radius := rng.randf_range(44.0, 76.0) * (1.0 - k * 0.15)
				canvas.draw_texture_rect(blob, Rect2(at - Vector2(radius, radius * 0.8), Vector2(radius * 2.0, radius * 1.6)), false, Color(SILHOUETTE, 0.9))


## The grove's ground: a low mound under the trunk, with grass on its rim.
func _draw_ground(canvas: Control) -> void:
	var size := TreePage.SIZE
	var rim := PackedVector2Array()
	var x := 0.0
	while x <= size.x:
		rim.append(Vector2(x, rim_y(x)))
		x += 12.0
	var fill := rim.duplicate()
	fill.append(size)
	fill.append(Vector2(0, size.y))
	canvas.draw_colored_polygon(fill, GROUND_COLOR)
	canvas.draw_polyline(rim, Color(0.45, 0.62, 0.55, 0.16), 2.0, true)
	var rng := page.rng(4)
	for point in rim:
		for k in 2:
			var foot := point + Vector2(rng.randf_range(-6.0, 6.0), 2.0)
			var tip := foot + Vector2(rng.randf_range(-5.0, 5.0), -rng.randf_range(4.0, 12.0))
			canvas.draw_line(foot, tip, GRASS_COLOR, 2.0, true)


## The trunk: shaded on the left and lit to the right, its grooves, its
## outline and the moon's rim on its right.
func _draw_trunk(canvas: Control) -> void:
	var vertices := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for i in trunk_left.size():
		vertices.append_array([trunk_left[i], trunk_left[i].lerp(trunk_right[i], 0.62), trunk_right[i]])
		colors.append_array([BARK_DARK, BARK_LIGHT, BARK_MID])
		if i > 0:
			var a := (i - 1) * 3
			var b := i * 3
			indices.append_array([a, a + 1, b, a + 1, b + 1, b, a + 1, a + 2, b + 1, a + 2, b + 2, b + 1])
	RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(), indices, vertices, colors)
	for line in grooves:
		if line.size() >= 2:
			canvas.draw_polyline(line, Color(BARK_DARK.darkened(0.3), 0.75), 2.0, true)
	canvas.draw_polyline(trunk_left, BARK_EDGE, 2.0, true)
	canvas.draw_polyline(trunk_right, BARK_EDGE, 2.0, true)
	var rim := PackedVector2Array()
	for point in trunk_right:
		rim.append(point - Vector2(2.5, 0))
	canvas.draw_polyline(rim, BARK_RIM, 2.0, true)


## The masses of one crown layer in `color`: each a disc with bumps along its
## top, shaded on its lower left and lit toward the moon, the moon's `rim` on
## its upper right, and faint leaf marks.
func _draw_clumps(canvas: Control, layer: int, color: Color, rim: Color) -> void:
	var shade := color.darkened(CLUMP_SHADE)
	for i in clumps.size():
		var clump := clumps[i]
		if int(clump.w) != layer:
			continue
		var at := Vector2(clump.x, clump.y)
		_draw_puff(canvas, i, at, 1.0, shade)
		_draw_puff(canvas, i, at + CLUMP_LIFT * clump.z, CLUMP_LIT, color)
		if rim.a > 0.0:
			canvas.draw_arc(at, clump.z * 0.97, -PI * 0.6, -PI * 0.1, 16, rim, 2.0, true)
		var marks: PackedVector4Array = leaf_marks[i]
		for k in marks.size():
			var mark := marks[k]
			draw_leaf(canvas, Vector2(mark.x, mark.y), mark.z, mark.w, color.lightened(0.07) if k % 2 == 0 else color.darkened(0.2))


func _draw_puff(canvas: Control, i: int, at: Vector2, scale: float, color: Color) -> void:
	canvas.draw_circle(at, clumps[i].z * scale, color)
	for bump in puffs[i]:
		canvas.draw_circle(at + Vector2(bump.x, bump.y), bump.z * scale, color)


## Grass in front of the trunk's foot.
func _draw_foot(canvas: Control) -> void:
	var rng := page.rng(44)
	var x := middle - 260.0
	while x <= middle + 260.0:
		var foot := Vector2(x + rng.randf_range(-3.0, 3.0), rim_y(x) + 4.0)
		var tip := foot + Vector2(rng.randf_range(-5.0, 5.0), -rng.randf_range(6.0, 16.0))
		canvas.draw_line(foot, tip, GRASS_LIGHT if rng.randf() < 0.4 else GRASS_COLOR, 2.0, true)
		x += 6.0
