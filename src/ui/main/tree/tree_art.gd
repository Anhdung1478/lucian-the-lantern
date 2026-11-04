class_name TreeArt
extends RefCounted
## The Evolution Tree page's scenery and its living tree, drawn on the page
## (TreePage). draw_back: the night sky with its moon and stars, the far
## hills and the forest at both sides, the grassy mound and the back of the
## canopy. draw_tree: roots, boughs out to the nodes, a gnarled trunk with
## bark grooves, a knot and a moonlit rim, the leafy canopy around every limb
## group (and over a bare trunk tip), its clumps shaded under and lit toward
## the moon, a small lantern on each bough that lights once its node is bought,
## and grass and glowing mushrooms at the trunk's foot. draw_flow (every
## frame, on the page's mote layer): gold motes climbing from the roots to
## each bought node; none on Low effects. Everything is laid out once from
## the page's layout and seeded random numbers, so a redraw never moves it.

## The sky's stars (the sky and its palette are MainBackdrop's) and the moon.
const STARS := 120
const MOON_COLOR := Color("f3ead2")
const MOON_AT := Vector2(1010, 132)
const MOON_RADIUS := 26.0
## The grove around the tree.
const HILL_FAR := Color("0f252c")
const HILL_NEAR := Color("0a191c")
const SILHOUETTE := Color("081316")
const GROUND_COLOR := Color("0a1411")
const GRASS_COLOR := Color("1d3a2a")
const GRASS_LIGHT := Color("2f5c40")
## The bark: dark, mid and light, its outline and the moon's rim on it.
const BARK_DARK := Color("2b1d16")
const BARK_MID := Color("5a4031")
const BARK_LIGHT := Color("7a5a43")
const BARK_EDGE := Color("140d09")
const BARK_RIM := Color(0.62, 0.77, 0.85, 0.55)
## The leaves: the back, mid and front layers of the canopy, and the moon's
## rim on them.
const LEAF_DEEP := Color("123a2c")
const LEAF_MID := Color("1f5a3f")
const LEAF_LIGHT := Color("3f8a5c")
const LEAF_RIM := Color(0.56, 0.83, 0.66, 0.4)
## Under each node the canopy darkens, so icons and names stay readable.
const NODE_SHADE := Color(0.01, 0.03, 0.025, 0.7)
const LIGHT := MainBackdrop.GROVE_LIGHT
## The trunk: the root flare's extra width at the ground and how high it
## reaches, the step between its edge points, its grooves and highlights.
const FLARE := 80.0
const FLARE_HEIGHT := 40.0
const EDGE_STEP := 8.0
const GROOVES := 6
const HIGHLIGHTS := 4
## The roots: where each leaves the trunk, across its foot (-1 left, 1 right).
const ROOTS: Array[float] = [-1.0, -0.62, -0.28, 0.3, 0.66, 1.0]
## Boughs: their width where they leave the trunk, where they leave a node,
## and at the node.
const BOUGH_ROOT := 30.0
const BOUGH_KNEE := 15.0
const BOUGH_TIP := 11.0
## The canopy, per node and per layer (back, mid, front): how many clumps,
## their least and largest radius, and how far up they sit.
const CLUMP_LAYERS: Array[Vector4] = [Vector4(4, 72, 104, 20), Vector4(4, 46, 68, 10), Vector4(3, 24, 38, 34)]
## How far around a node its clumps spread.
const CLUMP_SPREAD := Vector2(78, 70)
## A clump's bumps reach this many radii from its middle.
const PUFF_REACH := 1.25
## A clump's shaded underside (how much darker), the size of its lit body (of
## the whole clump) and how far that body sits toward the moon, in radii.
const CLUMP_SHADE := 0.3
const CLUMP_LIT := 0.86
const CLUMP_LIFT := Vector2(0.056, -0.056)
## Pages with many nodes get fewer clumps per node, so their crown keeps its
## shape: the counts scale by CROWD_NODES / the page's nodes, down to CROWD_MIN.
const CROWD_NODES := 7.0
const CROWD_MIN := 0.45
## A crown at the trunk's tip where no node sits on it, hiding the fork:
## per layer, how many clumps and their least and largest radius.
const TIP_CROWN: Array[Vector3] = [Vector3(4, 56, 74), Vector3(3, 38, 52), Vector3(2, 22, 32)]
## The smallest clump kept when it shrinks to clear the ground, and how far
## above the ground clumps stay.
const CLUMP_MIN := 16.0
const CLUMP_GROUND := 40.0
## Lanterns: how far along a bough (0..1) they hang, the string, the body.
const LANTERN_ALONG := 0.6
const LANTERN_STRING := 18.0
const LANTERN_SIZE := Vector2(14, 22)
const LANTERN_METAL := Color("2a2420")
const LANTERN_GLASS := Color(0.12, 0.16, 0.17, 0.95)
const FLAME := Color("fff4c8")
## Glowing mushrooms by the roots.
const MUSHROOMS := 6
const MUSHROOM_CAP := Color("7fe3d0")
const MUSHROOM_STEM := Color("d9cfb8")
## The climbing light: motes per bought node, their speed, the path's step.
const FLOW_MOTES := 3
const FLOW_SPEED := 60.0
const FLOW_STEP := 4.0

var page: TreePage
## The trunk's middle (x).
var middle: float
## The trunk's edges, from below the ground up to its tip, a point each per
## EDGE_STEP; the same count on both sides.
var trunk_left := PackedVector2Array()
var trunk_right := PackedVector2Array()
var grooves: Array[PackedVector2Array] = []
var highlights: Array[PackedVector2Array] = []
## A knot on the trunk: (x, y, radius); radius 0 when no spot is free.
var knot := Vector3.ZERO
var roots: Array[PackedVector2Array] = []
## Node id -> its bough's points, from inside the trunk (or its parent node)
## out to the node.
var boughs := {}
var twigs: Array[PackedVector2Array] = []
## A leaf sprig at each twig's tip: (x, y, angle).
var sprigs := PackedVector3Array()
## Leaf clumps: (x, y, radius, layer); layer 0 back, 1 mid, 2 front.
var clumps := PackedVector4Array()
## Per clump, the bumps along its top: (dx, dy, radius).
var puffs: Array[PackedVector3Array] = []
## Per clump, leaf marks on it: (x, y, angle, length); none on the back layer.
var leaf_marks: Array[PackedVector4Array] = []
## (x, y, size)
var mushrooms := PackedVector3Array()
## The lanterns: the node each one lights for, where its string hangs from
## and where its body is.
var lantern_ids: Array[StringName] = []
var lantern_hooks := PackedVector2Array()
var lantern_spots := PackedVector2Array()
## Node id -> the path the light climbs, from the ground up the trunk and
## along the boughs to the node, a point every FLOW_STEP px.
var flow_paths := {}


func _init(tree_page: TreePage) -> void:
	page = tree_page
	middle = TreePage.SIZE.x * 0.5
	_lay_trunk(page.rng(40))
	_lay_roots(page.rng(41))
	_lay_boughs(page.rng(42))
	_lay_canopy(page.rng(43))
	_lay_lanterns()
	_lay_flow()


## The trunk's width at height `y`, its root flare included.
func width_at(y: float) -> float:
	return page.trunk_width(y) + FLARE * exp(-maxf(TreePage.GROUND_Y - y, 0.0) / FLARE_HEIGHT)


## The mound's grassy rim at `x`.
func rim_y(x: float) -> float:
	var spread := (x - middle) / 420.0
	return TreePage.GROUND_Y + 34.0 - 40.0 * exp(-spread * spread)


## The ids of the nodes whose lantern is lit.
func lit_lanterns(tree: EvolutionTree) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in lantern_ids:
		if tree.level(id) > 0:
			out.append(id)
	return out


## Where the climbing motes are at `time`: FLOW_MOTES per bought node; none
## on Low effects.
func flow_points(tree: EvolutionTree, time: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if GameSettings.instance().low_effects():
		return out
	var k := 0
	for id: StringName in flow_paths:
		if tree.level(id) == 0:
			continue
		var path: PackedVector2Array = flow_paths[id]
		var length := (path.size() - 1) * FLOW_STEP
		if length <= 0.0:
			continue
		for m in FLOW_MOTES:
			var s := fposmod(time * FLOW_SPEED + length * m / FLOW_MOTES + k * 37.0, length)
			out.append(path[int(s / FLOW_STEP)])
		k += 1
	return out


# --- Drawing --------------------------------------------------------------------------


## The night sky, the far hills and the forest at both sides, the grassy
## mound and the back of the canopy.
func draw_back(canvas: Control) -> void:
	_draw_sky(canvas)
	_draw_hills(canvas)
	_draw_ground(canvas)
	_draw_clumps(canvas, 0, LEAF_DEEP, Color(0, 0, 0, 0))


## The tree: roots, boughs and twigs, the trunk, the light along bought
## boughs, the mid and front canopy, the shade under the nodes, the lanterns
## and the grass and mushrooms at the trunk's foot.
func draw_tree(canvas: Control, tree: EvolutionTree) -> void:
	var glow := JourneyMap.glow()
	var y := TreePage.GROUND_Y
	while y > page.trunk_top:
		canvas.draw_texture_rect(glow, Rect2(Vector2(middle, y) - Vector2(90, 100), Vector2(180, 200)), false, Color(LIGHT, 0.06))
		y -= 70.0
	for root in roots:
		draw_strip(canvas, root, 24.0, 3.0, BARK_MID)
	for id: StringName in boughs:
		var from_trunk: bool = page.parents[id] == &""
		draw_strip(canvas, boughs[id], BOUGH_ROOT if from_trunk else BOUGH_KNEE, BOUGH_TIP, BARK_MID, BARK_RIM)
	for twig in twigs:
		draw_strip(canvas, twig, 7.0, 2.5, BARK_MID)
	_draw_trunk(canvas)
	for id: StringName in boughs:
		var lit := _off_trunk(boughs[id])
		if tree.level(id) > 0 and lit.size() >= 2:
			canvas.draw_polyline(lit, Color(LIGHT, 0.5), 2.0, true)
	_draw_clumps(canvas, 1, LEAF_MID, Color(LEAF_RIM, LEAF_RIM.a * 0.6))
	_draw_clumps(canvas, 2, LEAF_LIGHT, LEAF_RIM)
	for sprig in sprigs:
		for turn: float in [-0.6, 0.0, 0.6]:
			draw_leaf(canvas, Vector2(sprig.x, sprig.y), sprig.z + turn, 12.0, LEAF_LIGHT)
	for center: Vector2 in page.centers.values():
		canvas.draw_texture_rect(glow, Rect2(center - Vector2(120, 90), Vector2(240, 240)), false, NODE_SHADE)
	for i in lantern_ids.size():
		_draw_lantern(canvas, lantern_hooks[i], lantern_spots[i], tree.level(lantern_ids[i]) > 0)
	_draw_foot(canvas)


## The gold motes climbing to the bought nodes, at `time`.
func draw_flow(canvas: CanvasItem, tree: EvolutionTree, time: float) -> void:
	for point in flow_points(tree, time):
		MainBackdrop.draw_mote(canvas, point, LIGHT, 0.75)


## A tapered strip along `points`, `from_width` wide at its start and
## `to_width` at its end: lit on its upper side, shaded under, outlined, and
## with `rim` (moonlight) along its upper edge when given.
static func draw_strip(canvas: CanvasItem, points: PackedVector2Array, from_width: float, to_width: float, color: Color, rim := Color(0, 0, 0, 0)) -> void:
	var count := points.size()
	if count < 2:
		return
	# Which side faces up, for a strip going left or right.
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
		colors.append_array([color.lightened(0.14), color.darkened(0.4)])
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


## `points` from the first one off the trunk's face on: a bough's light starts
## where the bough leaves the trunk.
func _off_trunk(points: PackedVector2Array) -> PackedVector2Array:
	for i in points.size():
		if points[i].y < page.trunk_top or absf(points[i].x - middle) >= width_at(points[i].y) * 0.5:
			return points.slice(i)
	return PackedVector2Array()


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
	# A rounded-off tip.
	trunk_left.append(Vector2(middle - TreePage.TRUNK_TIP * 0.3, top - 8.0))
	trunk_right.append(Vector2(middle + TreePage.TRUNK_TIP * 0.3, top - 8.0))
	for k in GROOVES:
		var across := lerpf(-0.36, 0.3, float(k) / (GROOVES - 1)) + rng.randf_range(-0.04, 0.04)
		var from := TreePage.GROUND_Y + 6.0 - rng.randf_range(0.0, 40.0)
		grooves.append(_bark_line(across, from, lerpf(from, top + 20.0, rng.randf_range(0.55, 1.0)), rng.randf() * TAU))
	for k in HIGHLIGHTS:
		var from := rng.randf_range(top + 60.0, TreePage.GROUND_Y - 40.0)
		highlights.append(_bark_line(rng.randf_range(0.08, 0.28), from, maxf(from - rng.randf_range(40.0, 90.0), top + 10.0), rng.randf() * TAU))
	_place_knot(rng)


## A wavy line up the bark, `across` of the trunk's width from its middle
## (-0.5 left edge, 0.5 right edge), from `from` up to `to`.
func _bark_line(across: float, from: float, to: float, wave: float) -> PackedVector2Array:
	var line := PackedVector2Array()
	var y := from
	while y > to:
		line.append(Vector2(middle + across * width_at(y) + sin(y * 0.045 + wave) * 2.5, y))
		y -= 10.0
	return line


## A knot where no node stands near the trunk.
func _place_knot(rng: RandomNumberGenerator) -> void:
	for attempt in 12:
		var y := rng.randf_range(page.trunk_top + 90.0, TreePage.GROUND_Y - 110.0)
		var clear := true
		for id: StringName in page.centers:
			var center: Vector2 = page.centers[id]
			if absf(center.x - middle) < TreePage.CELL.x * 0.5 + 40.0 and absf(center.y - y) < 110.0:
				clear = false
		if clear:
			knot = Vector3(middle + width_at(y) * 0.12, y, 9.0)
			return


func _lay_roots(rng: RandomNumberGenerator) -> void:
	var ground := TreePage.GROUND_Y
	for side: float in ROOTS:
		var base := Vector2(middle + side * width_at(ground) * 0.36, ground - 4.0)
		var reach := rng.randf_range(110.0, 190.0) * absf(side) + 40.0
		var end := Vector2(middle + signf(side) * reach, ground + rng.randf_range(22.0, 40.0))
		var bend := Vector2(lerpf(base.x, end.x, 0.45), ground - rng.randf_range(2.0, 14.0))
		roots.append(TreePage.bezier(base, bend, bend.lerp(end, 0.5), end))
	for i in MUSHROOMS:
		var x := roots[i % roots.size()][-1].x + rng.randf_range(-24.0, 24.0)
		mushrooms.append(Vector3(x, rim_y(x) + rng.randf_range(4.0, 12.0), rng.randf_range(4.0, 7.0)))


func _lay_boughs(rng: RandomNumberGenerator) -> void:
	for id: StringName in page.limbs:
		var points: PackedVector2Array = (page.limbs[id] as PackedVector2Array).duplicate()
		if page.parents[id] == &"":
			# From inside the trunk: the trunk, drawn over it, hides the joint.
			points.insert(0, Vector2(middle, points[0].y + 10.0))
		boughs[id] = points
		for k in 1 + int(rng.randf() < 0.5):
			_add_twig(points, rng)


## A short twig off a bough, up and outward, with a leaf sprig at its tip;
## none where the tip would be near a node.
func _add_twig(points: PackedVector2Array, rng: RandomNumberGenerator) -> void:
	var count := points.size()
	var i := int((count - 1) * rng.randf_range(0.35, 0.7))
	var along := (points[mini(i + 1, count - 1)] - points[maxi(i - 1, 0)]).normalized()
	var turn := rng.randf_range(0.6, 1.0)
	# Up and outward: above a bough going right or going left.
	var direction := along.rotated(-turn if along.x >= 0.0 else turn)
	var tip := points[i] + direction * rng.randf_range(26.0, 40.0)
	if page.near_node(tip):
		return
	twigs.append(PackedVector2Array([points[i], points[i].lerp(tip, 0.5) + direction.orthogonal() * 2.0, tip]))
	sprigs.append(Vector3(tip.x, tip.y, direction.angle()))


func _lay_canopy(rng: RandomNumberGenerator) -> void:
	# A crowded page's clumps are fewer and smaller, so gaps stay between them.
	var crowd := clampf(CROWD_NODES / page.centers.size(), CROWD_MIN, 1.0)
	var shrink := sqrt(crowd)
	for id: StringName in page.centers:
		var center: Vector2 = page.centers[id]
		var outward := signf(center.x - middle)
		for layer in CLUMP_LAYERS.size():
			var spec := CLUMP_LAYERS[layer]
			for k in maxi(1, roundi(spec.x * crowd)):
				var at := center + Vector2(rng.randf_range(-CLUMP_SPREAD.x, CLUMP_SPREAD.x) + outward * rng.randf_range(0.0, 24.0),
					rng.randf_range(-CLUMP_SPREAD.y, CLUMP_SPREAD.y * 0.35) - spec.w)
				_add_clump(at, rng.randf_range(spec.y, spec.z) * shrink, layer, rng)
	for id: StringName in boughs:
		if page.parents[id] != &"":
			continue
		var points: PackedVector2Array = boughs[id]
		for along: float in [0.55, 0.78]:
			var radius := rng.randf_range(34.0, 52.0)
			_add_clump(points[int((points.size() - 1) * along)] - Vector2(0, radius * 0.45), radius, 1, rng)
	# Where no node sits on the trunk's tip, a crown hides the fork.
	var bare_tip := true
	for id: StringName in page.centers:
		if page.on_trunk[id] and page.centers[id].y < page.trunk_top + 1.0:
			bare_tip = false
	if bare_tip:
		var tip := Vector2(middle, page.trunk_top - 40.0)
		for layer in TIP_CROWN.size():
			var spec := TIP_CROWN[layer]
			for k in int(spec.x):
				var at := tip + Vector2(rng.randf_range(-64.0, 64.0), rng.randf_range(-36.0, 18.0) - layer * 10.0)
				_add_clump(at, rng.randf_range(spec.y, spec.z), layer, rng)


## Adds a clump unless it would cover the header or Reset tree or leave the
## page; one reaching the ground shrinks, and one left too small is dropped.
func _add_clump(at: Vector2, radius: float, layer: int, rng: RandomNumberGenerator) -> void:
	radius = minf(radius, TreePage.GROUND_Y - CLUMP_GROUND - at.y)
	if radius < CLUMP_MIN:
		return
	for rect: Rect2 in TreePage.KEEP_CLEAR:
		if circle_hits_rect(at, radius * PUFF_REACH, rect):
			return
	if at.x - radius < 12.0 or at.x + radius > TreePage.SIZE.x - 12.0:
		return
	clumps.append(Vector4(at.x, at.y, radius, layer))
	var bumps := PackedVector3Array()
	for k in rng.randi_range(5, 7):
		var angle := lerpf(-PI * 0.95, -PI * 0.05, (k + rng.randf_range(-0.3, 0.3)) / 6.0)
		bumps.append(Vector3(cos(angle) * radius * 0.78, sin(angle) * radius * 0.78, radius * rng.randf_range(0.32, 0.45)))
	puffs.append(bumps)
	var marks := PackedVector4Array()
	if layer > 0:
		for k in 3:
			var spot := at + Vector2(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.6, 0.4)) * radius
			marks.append(Vector4(spot.x, spot.y, rng.randf() * TAU, rng.randf_range(9.0, 14.0)))
	leaf_marks.append(marks)


func _lay_lanterns() -> void:
	for id: StringName in page.limbs:
		var points: PackedVector2Array = page.limbs[id]
		var hook := points[int((points.size() - 1) * LANTERN_ALONG)]
		var spot := hook + Vector2(0, LANTERN_STRING + LANTERN_SIZE.y * 0.5)
		if _blocked(Rect2(spot - LANTERN_SIZE * 0.5, LANTERN_SIZE).grow(4.0)):
			continue
		lantern_ids.append(id)
		lantern_hooks.append(hook)
		lantern_spots.append(spot)


## Whether `rect` would touch a node (its frame, badge or name), a Backpack
## preview plaque or the ground.
func _blocked(rect: Rect2) -> bool:
	for id: StringName in page.centers:
		var center: Vector2 = page.centers[id]
		if rect.intersects(Rect2(center - Vector2(TreePage.CELL.x * 0.5 + 6.0, 60.0), Vector2(TreePage.CELL.x + 12.0, 160.0))):
			return true
		if id in [TreePage.EQUIP_ID, TreePage.BACKPACK_ID] and rect.intersects(TreePage.plaque_rect(center)):
			return true
	return rect.end.y > TreePage.GROUND_Y - 20.0


func _lay_flow() -> void:
	var ground := Vector2(middle, TreePage.GROUND_Y)
	for id: StringName in page.centers:
		var path := page.stem(id)
		path.reverse()
		var climb := PackedVector2Array([ground, Vector2(middle, path[0].y)])
		climb.append_array(path)
		flow_paths[id] = resample(climb, FLOW_STEP)


# --- Drawing parts --------------------------------------------------------------------


func _draw_sky(canvas: Control) -> void:
	var rect := Rect2(Vector2.ZERO, TreePage.SIZE)
	MainBackdrop.draw_sky(canvas, rect)
	MainBackdrop.draw_stars(canvas, rect, page.rng(1), STARS)
	var glow := JourneyMap.glow()
	# The moon and its halo, and the tree's own light around its crown.
	canvas.draw_texture_rect(glow, Rect2(MOON_AT - Vector2(330, 260), Vector2(660, 520)), false, Color(0.55, 0.7, 0.85, 0.08))
	canvas.draw_texture_rect(glow, Rect2(MOON_AT - Vector2.ONE * MOON_RADIUS * 3.0, Vector2.ONE * MOON_RADIUS * 6.0), false, Color(MOON_COLOR, 0.22))
	canvas.draw_circle(MOON_AT, MOON_RADIUS, MOON_COLOR)
	for spot: Vector3 in [Vector3(-8, -6, 7), Vector3(9, 6, 5), Vector3(-2, 12, 4), Vector3(10, -10, 3)]:
		canvas.draw_circle(MOON_AT + Vector2(spot.x, spot.y), spot.z, Color(0.75, 0.72, 0.62, 0.45))
	canvas.draw_circle(MOON_AT + Vector2(9, -5), MOON_RADIUS * 0.92, Color(MainBackdrop.SKY_TOP, 0.12))
	var crown := Vector2(middle, (page.trunk_top + TreePage.MIDDLE_Y) * 0.5)
	canvas.draw_texture_rect(glow, Rect2(crown - Vector2(640, 420), Vector2(1280, 840)), false, Color(LIGHT, 0.09))
	canvas.draw_texture_rect(glow, Rect2(crown - Vector2(300, 240), Vector2(600, 480)), false, Color(LIGHT, 0.06))


## Two rows of far hills with mist between them, and dark trees standing at
## both sides of the grove.
func _draw_hills(canvas: Control) -> void:
	var size := TreePage.SIZE
	for layer in 2:
		if layer == 1:
			_draw_side_trees(canvas)
		var base := 600.0 + layer * 80.0
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


## Tall dark trees in the grove's corners, framing the page.
func _draw_side_trees(canvas: Control) -> void:
	var rng := page.rng(7)
	var blob := JourneyMap.blob()
	for side: float in [-1.0, 1.0]:
		for k in 3:
			var x := middle + side * (middle - 70.0 - k * 120.0 - rng.randf_range(-20.0, 20.0))
			var top := rng.randf_range(250.0, 380.0) + k * 70.0
			var foot := Vector2(x, 760.0)
			var height := foot.y - top
			canvas.draw_line(foot, Vector2(x + side * rng.randf_range(-12.0, 12.0), top), SILHOUETTE, 14.0 - k * 3.0, true)
			for leaf in 6:
				var at := Vector2(x + rng.randf_range(-70.0, 70.0), top + rng.randf_range(-20.0, height * 0.45))
				var radius := rng.randf_range(50.0, 90.0) * (1.0 - k * 0.15)
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
	canvas.draw_polyline(rim, Color(0.45, 0.62, 0.55, 0.22), 2.0, true)
	var rng := page.rng(4)
	for point in rim:
		for k in 2:
			var foot := point + Vector2(rng.randf_range(-6.0, 6.0), 2.0)
			var tip := foot + Vector2(rng.randf_range(-5.0, 5.0), -rng.randf_range(4.0, 12.0))
			canvas.draw_line(foot, tip, GRASS_COLOR, 2.0, true)


## The trunk: shaded dark on the left and lit to the right, its knot, its
## grooves and highlights, its outline and the moon's rim on its right.
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
	if knot.z > 0.0:
		var at := Vector2(knot.x, knot.y)
		canvas.draw_colored_polygon(_ellipse(at, Vector2(knot.z, knot.z * 1.5)), BARK_DARK.darkened(0.4))
		var ring := _ellipse(at + Vector2(1, 0), Vector2(knot.z + 3.0, knot.z * 1.5 + 3.0))
		ring.append(ring[0])
		canvas.draw_polyline(ring, BARK_LIGHT, 2.0, true)
	for line in grooves:
		if line.size() >= 2:
			canvas.draw_polyline(line, Color(BARK_DARK.darkened(0.3), 0.75), 2.0, true)
	for line in highlights:
		if line.size() >= 2:
			canvas.draw_polyline(line, Color(BARK_LIGHT.lightened(0.15), 0.45), 1.5, true)
	canvas.draw_polyline(trunk_left, BARK_EDGE, 2.0, true)
	canvas.draw_polyline(trunk_right, BARK_EDGE, 2.0, true)
	var rim := PackedVector2Array()
	for point in trunk_right:
		rim.append(point - Vector2(2.5, 0))
	canvas.draw_polyline(rim, BARK_RIM, 2.5, true)


## The clumps of one canopy layer in `color`: each a disc with bumps along
## its top, shaded on its lower left and lit toward the moon, the moon's
## `rim` on its upper right, and leaf marks.
func _draw_clumps(canvas: Control, layer: int, color: Color, rim: Color) -> void:
	var shade := color.darkened(CLUMP_SHADE)
	for i in clumps.size():
		var clump := clumps[i]
		if int(clump.w) != layer:
			continue
		var at := Vector2(clump.x, clump.y)
		# The whole clump in shade, then its lit body over it, leaving a shaded
		# crescent on its lower left.
		_draw_puff(canvas, i, at, 1.0, shade)
		_draw_puff(canvas, i, at + CLUMP_LIFT * clump.z, CLUMP_LIT, color)
		if rim.a > 0.0:
			canvas.draw_arc(at, clump.z * 0.97, -PI * 0.62, -PI * 0.08, 16, rim, 2.0, true)
		var marks: PackedVector4Array = leaf_marks[i]
		for k in marks.size():
			var mark := marks[k]
			draw_leaf(canvas, Vector2(mark.x, mark.y), mark.z, mark.w, color.lightened(0.18) if k % 2 == 0 else color.darkened(0.25))


## Clump `i`'s disc and the bumps along its top, from `at`, `scale` times its
## size, in `color`.
func _draw_puff(canvas: Control, i: int, at: Vector2, scale: float, color: Color) -> void:
	canvas.draw_circle(at, clumps[i].z * scale, color)
	for bump in puffs[i]:
		canvas.draw_circle(at + Vector2(bump.x, bump.y), bump.z * scale, color)


## A small lantern on its string from `hook`: lit (a warm glow and a flame)
## or dark glass.
func _draw_lantern(canvas: Control, hook: Vector2, spot: Vector2, lit: bool) -> void:
	var half := LANTERN_SIZE * 0.5
	canvas.draw_line(hook, spot - Vector2(0, half.y), LANTERN_METAL.lightened(0.2), 1.5, true)
	if lit:
		canvas.draw_texture_rect(JourneyMap.glow(), Rect2(spot - Vector2.ONE * 42.0, Vector2.ONE * 84.0), false, Color(LIGHT, 0.4))
	canvas.draw_colored_polygon(PackedVector2Array([spot + Vector2(-4, -half.y), spot + Vector2(4, -half.y),
		spot + Vector2(half.x, -half.y + 4.0), spot + Vector2(-half.x, -half.y + 4.0)]), LANTERN_METAL)
	canvas.draw_rect(Rect2(spot + Vector2(-half.x + 1.0, -half.y + 4.0), Vector2(LANTERN_SIZE.x - 2.0, LANTERN_SIZE.y - 8.0)),
		Color(LIGHT, 0.92) if lit else LANTERN_GLASS)
	for x: float in [-half.x + 1.0, 0.0, half.x - 1.0]:
		canvas.draw_line(spot + Vector2(x, -half.y + 4.0), spot + Vector2(x, half.y - 4.0), LANTERN_METAL, 1.2)
	canvas.draw_rect(Rect2(spot + Vector2(-half.x, half.y - 4.0), Vector2(LANTERN_SIZE.x, 4.0)), LANTERN_METAL)
	if lit:
		canvas.draw_circle(spot + Vector2(0, 1), 2.5, FLAME)


## Grass in front of the trunk's foot, and glowing mushrooms by the roots.
func _draw_foot(canvas: Control) -> void:
	var rng := page.rng(44)
	var x := middle - 260.0
	while x <= middle + 260.0:
		var foot := Vector2(x + rng.randf_range(-3.0, 3.0), rim_y(x) + 4.0)
		var tip := foot + Vector2(rng.randf_range(-5.0, 5.0), -rng.randf_range(6.0, 16.0))
		canvas.draw_line(foot, tip, GRASS_LIGHT if rng.randf() < 0.4 else GRASS_COLOR, 2.0, true)
		x += 6.0
	for mushroom in mushrooms:
		var foot := Vector2(mushroom.x, mushroom.y)
		var cap := foot - Vector2(0, mushroom.z * 1.6)
		canvas.draw_texture_rect(JourneyMap.glow(), Rect2(cap - Vector2.ONE * mushroom.z * 4.0, Vector2.ONE * mushroom.z * 8.0), false, Color(MUSHROOM_CAP, 0.3))
		canvas.draw_line(foot, cap, MUSHROOM_STEM, 2.0, true)
		var dome := PackedVector2Array()
		for k in 9:
			dome.append(cap + Vector2.from_angle(PI + PI * k / 8.0) * mushroom.z)
		canvas.draw_colored_polygon(dome, MUSHROOM_CAP)


## An ellipse's outline at `at` with `radii`, not closed.
static func _ellipse(at: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for k in 20:
		var angle := TAU * k / 20.0
		points.append(at + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points
