class_name JungleMap
extends StageMap
## Act 3, stages 1 to 4: the jungle (5600 × 3600). Paths 420 wide and round
## clearings cut through dense jungle, drawn like Act 1's. The middle path
## runs from edge to edge; the side paths, the low path and the river make
## two loops, and each loop's inner jungle is a wall of its own, so no wall
## has a hole (see _floor). Camps: raptors and Gromp at the top corners,
## wolves and Krugs at the side edges, Blue and Red beside the side paths,
## the Scuttler on the river, the drakes in the pit at the top. Lucian
## starts at the bottom; the merchant stands at the center's south edge.
## A dry riverbed runs from the pit to the start. Stage 2 adds lava pools
## and Blast Cones; stage 4 fills the riverbed with shallow water and grows
## Honeyfruit.

const PATH_HALF := 210.0
## The paths: rows at these y, columns at these x.
const TOP_Y := 700.0
const MID_Y := 1850.0
const LOW_Y := 2750.0
const LEFT_X := 1500.0
const RIVER_X := 2800.0
const RIGHT_X := 4100.0
const PIT := Vector2(2800, 700)
const PIT_RADIUS := 460.0
const CENTER := Vector2(2800, 1850)
const CENTER_RADIUS := 450.0
const START := Vector2(2800, 2750)
const START_RADIUS := 380.0
const CAMP_RADIUS := 300.0
const SCUTTLE_RADIUS := 260.0
## Camp id -> where its monsters come out. The drakes' camp is the pit.
const CAMPS := {
	&"raptors": Vector2(600, 700), &"gromp": Vector2(5000, 700),
	&"wolves": Vector2(500, 1850), &"krugs": Vector2(5100, 1850),
	&"blue": Vector2(1100, 2500), &"red": Vector2(4500, 2500),
	&"scuttle": Vector2(2800, 1280),
}
## The camps wave enemies without one here come from, in turn.
const SPAWN_CAMPS: Array[StringName] = [&"raptors", &"wolves", &"krugs", &"gromp", &"blue", &"red"]
## The riverbed: half its width, how far it winds each way, and where it
## starts and ends.
const RIVERBED_HALF := 140.0
const RIVERBED_WIND := 40.0
const RIVERBED_TOP := 900.0
const RIVERBED_BOTTOM := 2530.0
const LAVA_STAGE := 2
const WATER_STAGE := 4
## Stage 2: lava pools (x, y, radius) at the back of the pit (behind the
## drake, leaving the floor in front of it open), in the center clearing, on
## the middle path and the river; Blast Cones on the middle and low paths,
## each 260 from the 480-thick jungle of a loop it throws Lucian over.
const LAVA_POOLS: Array[Vector3] = [Vector3(2580, 480, 140), Vector3(3020, 480, 140), Vector3(3000, 1680, 150), Vector3(2480, 1800, 150), Vector3(2870, 1300, 140)]
const BLAST_CONES: Array[Vector2] = [Vector2(1950, 1800), Vector2(2250, 2800), Vector2(3650, 1800), Vector2(3350, 2800)]
## Stage 4: Honeyfruit on the side and low paths.
const HONEYFRUITS: Array[Vector2] = [Vector2(1500, 1300), Vector2(4100, 1300), Vector2(2150, 2750), Vector2(3450, 2750)]
## A round clearing is cut as a polygon of this many sides.
const CIRCLE_SIDES := 40
## Spots tried for a tree, per px² of jungle (those near its edge are skipped).
const TREE_TRIES := 1.0 / 13000.0
const FLOOR_COLOR := Color("4d4b37")
const JUNGLE_COLOR := Color("1d3a24")
const JUNGLE_EDGE := Color("2f5a35")
const TREE_COLOR := Color("16301d")
const RIVERBED_COLOR := Color("6a5d43")
const PEBBLE_COLOR := Color("85775a")
const PIT_COLOR := Color("3d3832")
const PIT_RIM := Color("6b6660")
const CAMP_RING := Color(1.0, 0.95, 0.8, 0.1)

var stage := 1
var _riverbed: PackedVector2Array


func _init(stage_number := 1) -> void:
	stage = stage_number
	size = Vector2(5600, 3600)
	var walls: Array[PackedVector2Array] = [PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])]
	for open in _floor():
		walls = _carve(walls, open)
	wall_polygons = walls
	_riverbed = riverbed()
	camps = CAMPS.duplicate()
	camps[&"drake"] = PIT
	lucian_start = START + Vector2(0, 200)
	merchant_point = CENTER + Vector2(-190, 310)
	boss_point = PIT
	for camp in SPAWN_CAMPS:
		spawn_points.append(CAMPS[camp])


## The riverbed from the pit to the start, winding a little and narrowing at
## both ends: shallow water in stage 4, dry in the others.
func riverbed() -> PackedVector2Array:
	var west := PackedVector2Array()
	var east := PackedVector2Array()
	var y := RIVERBED_TOP
	while y <= RIVERBED_BOTTOM:
		var x := RIVER_X + RIVERBED_WIND * sin(y / 320.0)
		var half := RIVERBED_HALF * clampf(minf(y - RIVERBED_TOP, RIVERBED_BOTTOM - y) / 160.0 + 0.25, 0.25, 1.0)
		west.append(Vector2(x - half, y))
		east.append(Vector2(x + half, y))
		y += 70.0
	east.reverse()
	west.append_array(east)
	return west


## Stage 2: the lava pools and Blast Cones; stage 4: the shallow water and
## the Honeyfruit; none in the others.
func build_terrain(lucian: Lucian) -> Array[Node2D]:
	var terrain: Array[Node2D] = []
	if stage == LAVA_STAGE:
		for pool in LAVA_POOLS:
			var lava := HazardZone.burning(HazardZone.LAVA_DPS, DamageInfo.Type.MAGIC).set_circle(Vector2(pool.x, pool.y), pool.z)
			lava.lucian = lucian
			terrain.append(lava)
		for at in BLAST_CONES:
			var cone := BlastCone.new()
			cone.lucian = lucian
			cone.arena = self
			cone.position = at
			terrain.append(cone)
	elif stage == WATER_STAGE:
		var water := HazardZone.slowing(HazardZone.WATER_SLOW).set_polygon(_riverbed)
		water.lucian = lucian
		terrain.append(water)
		for at in HONEYFRUITS:
			var fruit := Honeyfruit.new()
			fruit.lucian = lucian
			fruit.position = at
			terrain.append(fruit)
	return terrain


## The open floor, path by path and clearing by clearing. Each piece
## overlaps the floor cut before it, and the first crosses the whole map,
## so cutting them out in this order never leaves a wall with a hole: a
## loop closing splits a wall in two instead.
func _floor() -> Array[PackedVector2Array]:
	return [
		_band(Vector2(0, MID_Y), Vector2(size.x, MID_Y)),
		_circle(CAMPS[&"wolves"], CAMP_RADIUS),
		_circle(CAMPS[&"krugs"], CAMP_RADIUS),
		_circle(CENTER, CENTER_RADIUS),
		_band(Vector2(LEFT_X, TOP_Y), Vector2(LEFT_X, LOW_Y)),
		_band(Vector2(RIGHT_X, TOP_Y), Vector2(RIGHT_X, LOW_Y)),
		_band(CAMPS[&"raptors"], Vector2(LEFT_X, TOP_Y)),
		_circle(CAMPS[&"raptors"], CAMP_RADIUS),
		_band(Vector2(RIGHT_X, TOP_Y), CAMPS[&"gromp"]),
		_circle(CAMPS[&"gromp"], CAMP_RADIUS),
		_band(PIT, CENTER),
		_circle(CAMPS[&"scuttle"], SCUTTLE_RADIUS),
		_circle(PIT, PIT_RADIUS),
		_band(CENTER, START),
		_band(Vector2(LEFT_X, LOW_Y), Vector2(RIGHT_X, LOW_Y)),
		_circle(START, START_RADIUS),
		_circle(CAMPS[&"blue"], CAMP_RADIUS),
		_circle(CAMPS[&"red"], CAMP_RADIUS),
	]


## A path from `from` to `to`, running on PATH_HALF past each end so that
## corners are square.
static func _band(from: Vector2, to: Vector2) -> PackedVector2Array:
	var along := (to - from).normalized() * PATH_HALF
	var side := along.orthogonal()
	return PackedVector2Array([from - along + side, to + along + side, to + along - side, from - along - side])


static func _circle(center: Vector2, circle_radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in CIRCLE_SIDES:
		points.append(center + Vector2.from_angle(TAU * i / CIRCLE_SIDES) * circle_radius)
	return points


func _draw() -> void:
	# The jungle runs on past the edges, where the camera still sees.
	for rect in border_rects():
		draw_rect(rect, JUNGLE_COLOR)
	draw_rect(get_bounds(), FLOOR_COLOR)
	_draw_riverbed()
	draw_circle(PIT, PIT_RADIUS - 40.0, PIT_COLOR)
	draw_arc(PIT, PIT_RADIUS - 40.0, 0.0, TAU, 64, PIT_RIM, 6.0, true)
	draw_arc(PIT, PIT_RADIUS - 150.0, 0.0, TAU, 64, Color(PIT_RIM, 0.35), 3.0, true)
	for camp: Vector2 in CAMPS.values():
		draw_arc(camp, 120.0, 0.0, TAU, 40, CAMP_RING, 4.0, true)
	var trees := RandomNumberGenerator.new()
	trees.seed = 11
	for polygon in wall_polygons:
		draw_colored_polygon(polygon, JUNGLE_COLOR)
		var box := _bounds_of(polygon)
		for i in ceili(_area_of(polygon) * TREE_TRIES):
			var at := Vector2(trees.randf_range(box.position.x, box.end.x), trees.randf_range(box.position.y, box.end.y))
			if Geometry2D.is_point_in_polygon(at, polygon) and _distance_to_edge(at, polygon) > 80.0:
				draw_circle(at, trees.randf_range(40.0, 80.0), TREE_COLOR)
		var outline := polygon.duplicate()
		outline.append(polygon[0])
		draw_polyline(outline, JUNGLE_EDGE, 8.0, true)
	draw_rect(get_bounds(), JUNGLE_EDGE, false, 4.0)


## Sand and pebbles; in stage 4 the water is drawn over it.
func _draw_riverbed() -> void:
	draw_colored_polygon(_riverbed, RIVERBED_COLOR)
	var pebbles := RandomNumberGenerator.new()
	pebbles.seed = 5
	for i in 90:
		var at := Vector2(RIVER_X + pebbles.randf_range(-170.0, 170.0), pebbles.randf_range(RIVERBED_TOP, RIVERBED_BOTTOM))
		if Geometry2D.is_point_in_polygon(at, _riverbed):
			draw_circle(at, pebbles.randf_range(4.0, 10.0), PEBBLE_COLOR)


static func _area_of(polygon: PackedVector2Array) -> float:
	var twice := 0.0
	for i in polygon.size():
		twice += polygon[i].cross(polygon[(i + 1) % polygon.size()])
	return absf(twice) * 0.5
