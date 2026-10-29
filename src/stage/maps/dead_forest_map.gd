class_name DeadForestMap
extends StageMap
## Act 5: a dead forest clearing (5400 × 3400), varied by stage. A ragged wall
## of black trees along the top and bottom, twisted trees for cover (round
## walls, a fixed seeded list per stage), the merchant in a stone-ringed
## clearing at the center. Saplings come out of the tree lines. From 5-3 a
## spider nest in the east; 5-2 has Maokai's huge dead tree and 5-4 Elise's
## camp; 5-5 ends in Karthus's ruined graveyard in the east. Black Mist banks
## (see BlackMist) lie over the floor.

const START := Vector2(500, 1700)
const MERCHANT := Vector2(2500, 1700)
const SPAWNS: Array[Vector2] = [Vector2(1800, 420), Vector2(3400, 420), Vector2(1800, 2980), Vector2(3400, 2980)]
const MAOKAI := Vector2(3900, 1700)
const ELISE := Vector2(3900, 1400)
const NEST_NORTH := Vector2(5000, 900)
const NEST_SOUTH := Vector2(5000, 2500)
## Karthus's place in 5-5 (also where the other stages keep their boss point clear).
const GRAVE_BOSS := Vector2(4300, 1700)
## 5-5: the graveyard is the ground east of this.
const GRAVEYARD_X := 3600.0

## The ragged tree line along the top and the bottom edge.
const TREE_LINE := 250.0
const TREE_LINE_JAG := 40.0
const TREE_LINE_PIECE := 300.0
## Twisted trees: radius range, how far they keep from the points and from
## each other (edge to edge), and the band of y they stand in.
const TREE_RADIUS_MIN := 45.0
const TREE_RADIUS_MAX := 90.0
const TREE_POINT_GAP := 220.0
const TREE_GAP := 160.0
const TREE_Y_MIN := 520.0
const TREE_Y_MAX := 2880.0
const TREE_X_MIN := 250.0
const TREE_X_MAX := 5150.0
## 5-5: its trees stand west of the graveyard, this far from it.
const GRAVE_TREE_MARGIN := 150.0
## Trees per stage, 5-1 to 5-5.
const TREE_COUNTS := [14, 16, 18, 18, 10]
## Maokai's dead tree: 6 trunks in a ring round his camp, open to the west.
const TRUNK_RADIUS := 85.0
const TRUNK_RING := 260.0
const TRUNK_ANGLES: Array[float] = [-120.0, -72.0, -24.0, 24.0, 72.0, 120.0]
## The Black Mist banks per stage (x, y, radius), clear of every point.
const MIST_BANKS := [
	[Vector3(1300, 900, 450), Vector3(3300, 2500, 480)],
	[Vector3(1300, 950, 450), Vector3(3200, 2400, 500), Vector3(3200, 1000, 420)],
	[Vector3(1300, 950, 450), Vector3(1500, 2500, 480), Vector3(3300, 2450, 500)],
	[Vector3(1300, 900, 450), Vector3(1500, 2500, 450), Vector3(3200, 950, 420), Vector3(3300, 2500, 500)],
	[Vector3(1000, 700, 450), Vector3(1000, 2700, 450)],
]
## The graveyard: tombstones (40 × 70) in rows, and two slabs of a broken
## crypt wall behind Karthus, with a gap between them.
const TOMB_SIZE := Vector2(40, 70)
const TOMB_COLUMNS: Array[float] = [3800.0, 4050.0]
const TOMB_ROWS: Array[float] = [800.0, 1100.0, 2300.0, 2600.0]
const CRYPT_SLABS: Array[Rect2] = [Rect2(4880, 1150, 70, 450), Rect2(4880, 1800, 70, 450)]

const FLOOR_COLOR := Color("2a3330")
const FLECK_COLOR := Color("3a4a3c")
const TREE_LINE_COLOR := Color("0b0e0d")
const TREE_LINE_EDGE := Color("1b2421")
const TRUNK_COLOR := Color("1c1f1e")
const BRANCH_COLOR := Color("2c322f")
const STONE_COLOR := Color("5d6560")
const WEB_COLOR := Color(0.92, 0.95, 0.93, 0.8)
const WEB_HOLE := Color("0a0c0b")
const FLAGSTONE := Color("3c4541")
const GRAVE_STONE := Color("77807a")
const CRYPT_COLOR := Color("59615c")
const NEST_RADIUS := 130.0
const MERCHANT_RING := 170.0

var stage := 1


func _init(stage_number := 1) -> void:
	stage = clampi(stage_number, 1, 5)
	size = Vector2(5400, 3400)
	lucian_start = START
	merchant_point = MERCHANT
	boss_point = GRAVE_BOSS
	spawn_points.assign(SPAWNS)
	camps = camp_points(stage)
	if camps.has(&"maokai"):
		boss_point = MAOKAI
	elif camps.has(&"elise"):
		boss_point = ELISE
	wall_polygons = tree_lines()
	if has_graveyard(stage):
		wall_polygons.append_array(graves())
	for tree in trees(stage):
		wall_circles.append(tree)
	for trunk in trunks(stage):
		wall_circles.append(trunk)
	mist.assign(MIST_BANKS[stage - 1])


## Camp id -> point for the stage: Maokai in 5-2, Elise in 5-4, the spider
## nest from 5-3 (north in 5-3 and 5-5, south in 5-4).
static func camp_points(stage_number: int) -> Dictionary:
	var found := {}
	if stage_number == 2:
		found[&"maokai"] = MAOKAI
	if stage_number == 4:
		found[&"elise"] = ELISE
	if stage_number >= 3:
		found[&"nest"] = NEST_SOUTH if stage_number == 4 else NEST_NORTH
	return found


static func has_graveyard(stage_number: int) -> bool:
	return stage_number == 5


## Maokai's trunks (5-2 only): (x, y, radius), a ring with a gap facing west.
static func trunks(stage_number: int) -> Array[Vector3]:
	var ring: Array[Vector3] = []
	if stage_number != 2:
		return ring
	for angle in TRUNK_ANGLES:
		var at := MAOKAI + Vector2.from_angle(deg_to_rad(angle)) * TRUNK_RING
		ring.append(Vector3(at.x, at.y, TRUNK_RADIUS))
	return ring


## The points the twisted trees keep clear of: start, merchant, boss spot,
## spawn points and camps (the same in every stage, so the stages' trees
## never block one another's points).
static func keep_clear(stage_number: int) -> Array[Vector2]:
	var points: Array[Vector2] = [START, MERCHANT, GRAVE_BOSS]
	points.append_array(SPAWNS)
	for point: Vector2 in camp_points(stage_number).values():
		points.append(point)
	return points


## The stage's twisted trees (x, y, radius), a fixed list: 220 px from every
## point and 160 px from each other and from Maokai's trunks, edge to edge.
static func trees(stage_number: int) -> Array[Vector3]:
	var found: Array[Vector3] = []
	var count: int = TREE_COUNTS[clampi(stage_number, 1, 5) - 1]
	var clear := keep_clear(stage_number)
	var ring := trunks(stage_number)
	var dice := RandomNumberGenerator.new()
	dice.seed = 6000 + stage_number
	var x_max := TREE_X_MAX
	var tries := 0
	while found.size() < count and tries < 20000:
		tries += 1
		var radius := dice.randf_range(TREE_RADIUS_MIN, TREE_RADIUS_MAX)
		if has_graveyard(stage_number):
			x_max = GRAVEYARD_X - GRAVE_TREE_MARGIN - radius
		var at := Vector2(dice.randf_range(TREE_X_MIN, x_max), dice.randf_range(TREE_Y_MIN, TREE_Y_MAX))
		var fits := true
		for point in clear:
			if at.distance_to(point) - radius < TREE_POINT_GAP:
				fits = false
		for other in found + ring:
			if at.distance_to(Vector2(other.x, other.y)) - radius - other.z < TREE_GAP:
				fits = false
		if fits:
			found.append(Vector3(at.x, at.y, radius))
	return found


## The black tree line along the top and the bottom edge: convex pieces of
## uneven depth, each sharing its sides with the next.
static func tree_lines() -> Array[PackedVector2Array]:
	var pieces: Array[PackedVector2Array] = []
	var dice := RandomNumberGenerator.new()
	dice.seed = 77
	var width := 5400.0
	var count := ceili(width / TREE_LINE_PIECE)
	var depths: Array[float] = []
	var depths_bottom: Array[float] = []
	for i in count + 1:
		depths.append(TREE_LINE + dice.randf_range(-TREE_LINE_JAG, TREE_LINE_JAG))
		depths_bottom.append(TREE_LINE + dice.randf_range(-TREE_LINE_JAG, TREE_LINE_JAG))
	for i in count:
		var left := i * TREE_LINE_PIECE
		var right := minf(left + TREE_LINE_PIECE, width)
		pieces.append(_piece(PackedVector2Array([Vector2(left, 0), Vector2(right, 0), Vector2(right, depths[i + 1]), Vector2(left, depths[i])])))
		pieces.append(_piece(PackedVector2Array([Vector2(left, 3400), Vector2(right, 3400), Vector2(right, 3400 - depths_bottom[i + 1]), Vector2(left, 3400 - depths_bottom[i])])))
	return pieces


## The graveyard's tombstones and crypt slabs as wall polygons.
static func graves() -> Array[PackedVector2Array]:
	var pieces: Array[PackedVector2Array] = []
	for rect in tombstones():
		pieces.append(_rect_polygon(rect))
	for slab in CRYPT_SLABS:
		pieces.append(_rect_polygon(slab))
	return pieces


## The tombstones (40 × 70), in rows.
static func tombstones() -> Array[Rect2]:
	var found: Array[Rect2] = []
	for x in TOMB_COLUMNS:
		for y in TOMB_ROWS:
			found.append(Rect2(Vector2(x, y) - TOMB_SIZE * 0.5, TOMB_SIZE))
	return found


static func _rect_polygon(rect: Rect2) -> PackedVector2Array:
	return _piece(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]))


## `points` wound the way wall polygons are (not clockwise).
static func _piece(points: PackedVector2Array) -> PackedVector2Array:
	if Geometry2D.is_polygon_clockwise(points):
		points.reverse()
	return points


func _draw() -> void:
	for rect in border_rects():
		draw_rect(rect, TREE_LINE_COLOR)
	draw_rect(get_bounds(), FLOOR_COLOR)
	_draw_flecks()
	if has_graveyard(stage):
		_draw_flagstones()
	draw_arc(MERCHANT, MERCHANT_RING, 0.0, TAU, 48, STONE_COLOR, 10.0, true)
	for i in 14:
		var at := MERCHANT + Vector2.from_angle(TAU * i / 14.0) * MERCHANT_RING
		draw_circle(at, 14.0, STONE_COLOR)
	if camps.has(&"nest"):
		_draw_nest(camps[&"nest"])
	for polygon in wall_polygons:
		draw_colored_polygon(polygon, TREE_LINE_COLOR)
	_draw_tree_line_trees()
	if has_graveyard(stage):
		_draw_graves()
	for trunk in trunks(stage):
		_draw_tree(trunk, 3)
	for tree in trees(stage):
		_draw_tree(tree, 4)
	draw_rect(get_bounds(), TREE_LINE_EDGE, false, 4.0)


## Dead-grass flecks over the floor.
func _draw_flecks() -> void:
	var dice := RandomNumberGenerator.new()
	dice.seed = 31
	for i in 700:
		var at := Vector2(dice.randf_range(0.0, size.x), dice.randf_range(TREE_LINE, size.y - TREE_LINE))
		var lean := dice.randf_range(-0.6, 0.6)
		var length := dice.randf_range(8.0, 18.0)
		draw_line(at, at + Vector2(lean * length, -length), FLECK_COLOR, 2.0)


## Round black crowns piled along the tree line's edge.
func _draw_tree_line_trees() -> void:
	var dice := RandomNumberGenerator.new()
	dice.seed = 19
	for i in 70:
		var x := dice.randf_range(0.0, size.x)
		var y := TREE_LINE + dice.randf_range(-60.0, 10.0)
		var radius := dice.randf_range(40.0, 75.0)
		draw_circle(Vector2(x, y), radius, TREE_LINE_COLOR)
		draw_circle(Vector2(x, size.y - y), radius, TREE_LINE_COLOR)
		draw_arc(Vector2(x, y), radius, 0.0, PI, 16, TREE_LINE_EDGE, 3.0, true)
		draw_arc(Vector2(x, size.y - y), radius, PI, TAU, 16, TREE_LINE_EDGE, 3.0, true)


## A black-grey trunk with crooked branches reaching out of it.
func _draw_tree(tree: Vector3, branches: int) -> void:
	var at := Vector2(tree.x, tree.y)
	var dice := RandomNumberGenerator.new()
	dice.seed = hash(at)
	for i in branches:
		var angle := dice.randf() * TAU
		var tip := at + Vector2.from_angle(angle) * tree.z * 1.5
		var elbow := at + Vector2.from_angle(angle + dice.randf_range(-0.5, 0.5)) * tree.z * 1.0
		draw_polyline(PackedVector2Array([at, elbow, tip]), BRANCH_COLOR, 6.0, true)
		draw_line(elbow, elbow + Vector2.from_angle(angle + 0.9) * tree.z * 0.5, BRANCH_COLOR, 3.0, true)
	draw_circle(at, tree.z, TRUNK_COLOR)
	draw_arc(at, tree.z, 0.0, TAU, 32, BRANCH_COLOR, 4.0, true)
	draw_circle(at + Vector2(-tree.z * 0.2, -tree.z * 0.2), tree.z * 0.45, BRANCH_COLOR.darkened(0.3))


## A white web disc with a dark hole in the middle.
func _draw_nest(at: Vector2) -> void:
	draw_circle(at, NEST_RADIUS, Color(WEB_COLOR, 0.25))
	for i in 8:
		var spoke := Vector2.from_angle(TAU * i / 8.0)
		draw_line(at + spoke * 30.0, at + spoke * NEST_RADIUS, WEB_COLOR, 2.0, true)
	for ring in [0.45, 0.7, 1.0]:
		draw_arc(at, NEST_RADIUS * ring, 0.0, TAU, 32, WEB_COLOR, 2.0, true)
	draw_circle(at, 34.0, WEB_HOLE)


func _draw_flagstones() -> void:
	var dice := RandomNumberGenerator.new()
	dice.seed = 41
	var x := GRAVEYARD_X
	while x < size.x:
		var y := TREE_LINE
		while y < size.y - TREE_LINE:
			if dice.randf() < 0.8:
				draw_rect(Rect2(x + 4, y + 4, 112, 112), FLAGSTONE)
			y += 120.0
		x += 120.0


func _draw_graves() -> void:
	for rect in tombstones():
		draw_rect(rect, GRAVE_STONE)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 12)), GRAVE_STONE.lightened(0.15))
	for slab in CRYPT_SLABS:
		draw_rect(slab, CRYPT_COLOR)
		draw_rect(slab, CRYPT_COLOR.darkened(0.4), false, 4.0)
