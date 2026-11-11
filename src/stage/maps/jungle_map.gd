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
## The ground: earth, its soft patches (how many, their radius range), and
## the paths worn lighter (stamps this far apart, this wide).
const FLOOR_COLOR := Color("56503a")
const PATCHES := 70
const PATCH_RADIUS := Vector2(200, 420)
const WORN_HALF := 190.0
const WORN_STEP := 110.0
## The jungle: the dark under the trees, the crowns' greens, the light the
## leaves catch, and how tall the trees are (for their shadows).
const JUNGLE_COLOR := Color("1d3a24")
const JUNGLE_EDGE := Color("2f5a35")
const TREE_COLOR := Color("16301d")
const LEAF_LIGHT := Color("9ab890")
const TREE_HEIGHT := 64.0
const TREES_OUTSIDE := 150.0
## Grass creeps in from the jungle: soft stamps this far apart along its
## edge, this wide. Then, along the edge: tufts, roots, leaves (tries).
const GRASS_STEP := 130.0
const GRASS_REACH := 170.0
const TUFT_TRIES := 1500
const ROOT_STEP := 210.0
const LEAF_TRIES := 900
const FLOWER_TRIES := 160
const PEBBLE_TRIES := 420
const FLOWER_COLOR := Color("efe6b4")
## The riverbed: its dry earth, the damp round it, its pebbles, and its
## water (stage 4): deep, at the bank, foam, how deep it is, and its streaks,
## ripples and stones (tries).
const RIVERBED_COLOR := Color("65583f")
const PEBBLE_COLOR := Color("8a7c5e")
const BED_PEBBLES := 150
const BED_CRACKS := 45
const WATER_DEEP := Color("2f7a96")
const WATER_BANK := Color("86cfd2")
const WATER_FOAM := Color("d6f1ee")
const WATER_DEPTH := 90.0
const STREAK_TRIES := 60
const RIPPLE_TRIES := 70
const SHALLOW_STONES := 40
## The pit's stone: its floor, its rim, its marks (cracks, claw marks, bones,
## rim stones) and the elder's glow at its heart.
const PIT_COLOR := Color("403a33")
const PIT_RIM := Color("7a736a")
const PIT_CRACKS := 18
const CLAW_MARKS := 5
const RIM_STONES := 46
const ELDER_GLOW := Color("9b7fe8")
## Lava: its crust, its fill, its glow and its bright rim.
const LAVA_CRUST := Color("2a1812")
const LAVA_FILL := Color("4c2010")
const LAVA_GLOW := Color("d2661f")
const LAVA_RIM := Color("ffab52")
## What marks each camp: bones, feathers, straw, stone, water, blue and red.
const BONE := Color("d8d0bc")
const FEATHER := Color("b8643a")
const STRAW := Color("9a8650")
const SCREE := Color("77726a")
const POND := Color("2f5a4a")
const BLUE_LIGHT := Color("5aaeff")
const RED_THORN := Color("8a3a2a")
## The far edges darken over this depth, this much.
const VIGNETTE_DEPTH := 600.0
const VIGNETTE_ALPHA := 0.4
## Fireflies along the paths, embers over the lava, glints on the water.
const FIREFLY_TRIES := 220
const GLINT_TRIES := 120
const FIREFLY_COLOR := Color("e6f28a")
const EMBER_COLOR := Color("ffb15a")

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


func build_ambience() -> MapAmbience:
	var ambience := MapAmbience.new()
	var dice := MapArt.rng(41)
	ambience.add(MapAmbience.Kind.FIREFLY, MapArt.scatter(dice, get_bounds(), FIREFLY_TRIES, _near_jungle), FIREFLY_COLOR, dice)
	if stage == LAVA_STAGE:
		var embers := PackedVector2Array()
		for pool in LAVA_POOLS:
			embers.append(Vector2(pool.x, pool.y))
			embers.append(Vector2(pool.x, pool.y) + Vector2(pool.z * 0.5, 0.0))
		ambience.add(MapAmbience.Kind.FIREFLY, embers, EMBER_COLOR, dice)
	elif stage == WATER_STAGE:
		ambience.add(MapAmbience.Kind.GLINT, MapArt.scatter(dice, MapArt.bounds_of(_riverbed), GLINT_TRIES, _in_riverbed.bind(30.0)),
			Color(WATER_FOAM, 0.75), dice)
	return ambience


func _draw() -> void:
	MapArt.outside(self, get_bounds(), _under_color())
	_draw_ground()
	_draw_camps()
	_draw_riverbed()
	_draw_pit()
	if stage == LAVA_STAGE:
		_draw_lava()
	_draw_marks()
	for polygon in wall_polygons:
		MapArt.cast_shadow(self, polygon, TREE_HEIGHT)
	for rect in border_rects():
		MapArt.cast_shadow(self, MapArt.polygon_of(rect), TREE_HEIGHT)
	_draw_jungle()
	MapArt.vignette(self, get_bounds(), VIGNETTE_DEPTH, VIGNETTE_ALPHA)


## The earth, broken up by soft patches, with the paths worn lighter and
## grass creeping in from the jungle's edge.
func _draw_ground() -> void:
	draw_rect(get_bounds(), FLOOR_COLOR)
	MapArt.patches(self, MapArt.rng(21), get_bounds(), PATCHES, PATCH_RADIUS, Color(FLOOR_COLOR.lightened(0.12), 0.5), Color(FLOOR_COLOR.darkened(0.32), 0.45))
	var worn := Color(FLOOR_COLOR.lightened(0.2), 0.3)
	for path in _paths():
		var steps := ceili(path[0].distance_to(path[1]) / WORN_STEP)
		for i in steps + 1:
			MapArt.glow(self, path[0].lerp(path[1], float(i) / steps), WORN_HALF, worn)
	for at in _edge_points(GRASS_STEP, -MapArt.EDGE_BEYOND):
		MapArt.glow(self, at, GRASS_REACH, Color(_grass_color(), 0.3))


## Each camp's clearing, lit a little, and what marks who lives there.
func _draw_camps() -> void:
	var dice := MapArt.rng(23)
	var marks := MapArt.Facets.new()
	for id: StringName in CAMPS:
		var at: Vector2 = CAMPS[id]
		MapArt.glow(self, at, CAMP_RADIUS * 0.9, Color(FLOOR_COLOR.lightened(0.18), 0.3))
		match id:
			&"raptors":
				for i in 3:
					var nest := at + Vector2.from_angle(TAU * i / 3.0 + 0.5) * 150.0
					MapArt.soft_oval(self, nest, Vector2(70, 56), Color(STRAW, 0.5))
					MapArt.disc(self, nest, 26.0, Color(FLOOR_COLOR.darkened(0.3), 0.6))
				_scatter_bones(marks, dice, at, 200.0, 8)
				for i in 10:
					var feather := at + Vector2.from_angle(dice.randf() * TAU) * dice.randf_range(40.0, 230.0)
					marks.blade(feather, feather + Vector2.from_angle(dice.randf() * TAU) * 24.0, 7.0, Color(FEATHER.lightened(dice.randf_range(0.0, 0.3)), 0.75))
			&"wolves":
				MapArt.glow(self, at, 210.0, Color(MapArt.SHADOW, 0.3))
				_scatter_bones(marks, dice, at, 210.0, 7)
				for i in 4:
					var claw := at + Vector2.from_angle(dice.randf() * TAU) * dice.randf_range(60.0, 220.0)
					for k in 3:
						marks.line(claw + Vector2(k * 9.0, 0.0), claw + Vector2(k * 9.0 + 6.0, 36.0), 2.5, Color(FLOOR_COLOR.darkened(0.5), 0.6))
			&"krugs":
				for i in 12:
					var slab := at + Vector2.from_angle(dice.randf() * TAU) * dice.randf_range(30.0, 240.0)
					var radii := Vector2(dice.randf_range(22.0, 44.0), dice.randf_range(14.0, 30.0))
					MapArt.oval(self, slab + MapArt.SHADOW_DIR * 4.0, radii, Color(MapArt.SHADOW, 0.3))
					MapArt.oval(self, slab, radii, SCREE.darkened(dice.randf_range(0.0, 0.2)))
					MapArt.oval(self, slab - MapArt.SHADOW_DIR * 3.0, radii * 0.6, SCREE.lightened(0.12))
			&"gromp":
				MapArt.soft_oval(self, at + Vector2(10, 20), Vector2(190, 130), Color(POND.darkened(0.3), 0.7))
				MapArt.soft_oval(self, at + Vector2(10, 20), Vector2(150, 100), Color(POND, 0.85))
				MapArt.soft_oval(self, at + Vector2(-10, 5), Vector2(80, 50), Color(POND.lightened(0.18), 0.6))
				for i in 3:
					MapArt.ripple(marks, at + Vector2(dice.randf_range(-90.0, 90.0), dice.randf_range(-40.0, 70.0)), dice.randf_range(14.0, 30.0), Color(WATER_BANK, 0.4))
				for i in 14:
					MapArt.tuft(marks, dice, at + Vector2(10, 20) + Vector2.from_angle(TAU * i / 14.0) * Vector2(200, 140) * dice.randf_range(0.92, 1.05), 16.0, Color(_grass_color().lightened(0.15), 0.9))
			&"blue":
				MapArt.glow(self, at, 230.0, Color(BLUE_LIGHT, 0.14))
				MapArt.glow(self, at, 90.0, Color(BLUE_LIGHT, 0.14))
				draw_arc(at, 150.0, 0.0, TAU, 40, Color(BLUE_LIGHT, 0.22), 3.0, true)
				for i in 6:
					var rune := at + Vector2.from_angle(TAU * i / 6.0) * 150.0
					marks.blade(rune - Vector2(0, 4), rune - Vector2(0, 30), 10.0, Color(BLUE_LIGHT, 0.4))
			&"red":
				MapArt.glow(self, at, 200.0, Color(MapArt.SHADOW, 0.25))
				MapArt.glow(self, at, 130.0, Color(LAVA_GLOW, 0.08))
				for i in 22:
					MapArt.tuft(marks, dice, at + Vector2.from_angle(dice.randf() * TAU) * dice.randf_range(60.0, 240.0), dice.randf_range(14.0, 24.0), Color(RED_THORN, 0.8))
			&"scuttle":
				MapArt.glow(self, at, SCUTTLE_RADIUS, Color(RIVERBED_COLOR.lightened(0.15), 0.5))
				for at_pebble in MapArt.scatter(dice, Rect2(at - Vector2.ONE * 200.0, Vector2.ONE * 400.0), 30, is_walkable.bind(30.0)):
					MapArt.pebble(self, dice, at_pebble, dice.randf_range(4.0, 9.0), PEBBLE_COLOR)
	marks.draw(self)


## The riverbed: damp earth round it, its dry floor lighter in the middle with
## pebbles and cracks; in stage 4 shallow water over it, with its current,
## ripples and stones.
func _draw_riverbed() -> void:
	for damp in Geometry2D.offset_polygon(_riverbed, 34.0, Geometry2D.JOIN_ROUND):
		draw_colored_polygon(damp, Color(FLOOR_COLOR.darkened(0.2), 0.7))
	draw_colored_polygon(_riverbed, RIVERBED_COLOR.darkened(0.12))
	for middle in Geometry2D.offset_polygon(_riverbed, -34.0, Geometry2D.JOIN_ROUND):
		draw_colored_polygon(middle, RIVERBED_COLOR)
	var dice := MapArt.rng(5)
	var box := MapArt.bounds_of(_riverbed)
	var marks := MapArt.Facets.new()
	if stage == WATER_STAGE:
		MapArt.water(self, _riverbed, WATER_DEEP, WATER_BANK.lerp(WATER_DEEP, 0.35), WATER_FOAM, WATER_DEPTH)
		var current := Color(WATER_BANK.lightened(0.3), 0.14)
		for at in MapArt.scatter(dice, box, STREAK_TRIES, _in_riverbed.bind(30.0)):
			var half := Vector2(0.0, dice.randf_range(60.0, 160.0)) * 0.5
			marks.blade(at - half, at + half, 3.0, current)
		for at in MapArt.scatter(dice, box, RIPPLE_TRIES, _in_riverbed.bind(36.0)):
			MapArt.ripple(marks, at, dice.randf_range(12.0, 28.0), Color(WATER_BANK.lightened(0.3), 0.45))
		marks.draw(self)
		var stones := MapArt.scatter(dice, box, SHALLOW_STONES, _in_riverbed.bind(24.0))
		for at in stones:
			MapArt.disc(self, at, 17.0, Color(WATER_FOAM, 0.25))
		for at in stones:
			MapArt.pebble(self, dice, at, dice.randf_range(6.0, 14.0), PEBBLE_COLOR.darkened(0.2))
		return
	for at in MapArt.scatter(dice, box, BED_CRACKS, _in_riverbed.bind(24.0)):
		MapArt.crack(marks, dice, at, dice.randf_range(30.0, 70.0), 2.0, Color(RIVERBED_COLOR.darkened(0.45), 0.5))
	marks.draw(self)
	for at in MapArt.scatter(dice, box, BED_PEBBLES, _in_riverbed.bind(16.0)):
		MapArt.pebble(self, dice, at, dice.randf_range(4.0, 10.0), PEBBLE_COLOR)


## The pit: a worn stone floor with a rim of stones, rings, cracks, the
## drakes' claw marks and bones, and the elder's glow at its heart.
func _draw_pit() -> void:
	var dice := MapArt.rng(7)
	var floor_radius := PIT_RADIUS - 40.0
	MapArt.disc(self, PIT, floor_radius + 14.0, Color(MapArt.SHADOW, 0.5))
	MapArt.disc(self, PIT, floor_radius, PIT_COLOR)
	MapArt.patches(self, dice, Rect2(PIT - Vector2.ONE * floor_radius * 0.7, Vector2.ONE * floor_radius * 1.4), 8, Vector2(60, 140),
		Color(PIT_COLOR.lightened(0.14), 0.4), Color(PIT_COLOR.darkened(0.3), 0.4))
	MapArt.glow(self, PIT, floor_radius * 0.7, Color(ELDER_GLOW, 0.14))
	draw_arc(PIT, floor_radius, 0.0, TAU, 64, Color(PIT_RIM, 0.7), 6.0, true)
	for ring in [floor_radius - 110.0, floor_radius - 220.0]:
		draw_arc(PIT, ring, 0.0, TAU, 64, Color(PIT_RIM, 0.3), 3.0, true)
	var marks := MapArt.Facets.new()
	for at in MapArt.scatter(dice, Rect2(PIT - Vector2.ONE * floor_radius, Vector2.ONE * floor_radius * 2.0), PIT_CRACKS, _in_pit.bind(30.0)):
		MapArt.crack(marks, dice, at, dice.randf_range(40.0, 90.0), 2.0, Color(PIT_COLOR.darkened(0.55), 0.6))
	for i in CLAW_MARKS:
		var claw := PIT + Vector2.from_angle(dice.randf() * TAU) * dice.randf_range(100.0, 300.0)
		var way := Vector2.from_angle(dice.randf() * TAU) * 70.0
		for k in 3:
			var shift := way.orthogonal().normalized() * (k - 1) * 12.0
			marks.line(claw + shift, claw + shift + way, 3.0, Color(PIT_COLOR.darkened(0.55), 0.6))
	_scatter_bones(marks, dice, PIT, floor_radius - 60.0, 10)
	marks.draw(self)
	for i in RIM_STONES:
		var stone := PIT + Vector2.from_angle(TAU * (i + dice.randf_range(-0.3, 0.3)) / RIM_STONES) * (floor_radius + 6.0)
		if is_walkable(stone, 0.0):
			MapArt.pebble(self, dice, stone, dice.randf_range(7.0, 13.0), PIT_RIM.darkened(0.15))


## Lava pools: scorched earth, a dark crust, the glowing fill with a bright
## rim and a few cracks of light. Dark enough not to read as a warning.
func _draw_lava() -> void:
	var dice := MapArt.rng(9)
	var cracks := MapArt.Facets.new()
	for pool in LAVA_POOLS:
		var at := Vector2(pool.x, pool.y)
		MapArt.glow(self, at, pool.z * 1.9, Color(MapArt.SHADOW, 0.45))
		MapArt.disc(self, at, pool.z * 1.12, LAVA_CRUST)
		MapArt.disc(self, at, pool.z, LAVA_FILL)
		MapArt.glow(self, at, pool.z * 0.8, Color(LAVA_GLOW, 0.2))
		MapArt.glow(self, at - MapArt.SHADOW_DIR * pool.z * 0.2, pool.z * 0.4, Color(LAVA_RIM, 0.2))
		draw_arc(at, pool.z * 0.97, 0.0, TAU, 48, Color(LAVA_RIM, 0.75), 4.0, true)
		for i in 3:
			MapArt.crack(cracks, dice, at + Vector2.from_angle(dice.randf() * TAU) * pool.z * 0.4, pool.z * 0.5, 2.5, Color(LAVA_RIM, 0.45))
	cracks.draw(self)


## Small things on the paths: leaves, pebbles, roots and tufts along the
## jungle's foot, a few flowers.
func _draw_marks() -> void:
	var dice := MapArt.rng(13)
	var leaves: Array[Color] = [Color("6a7d3a"), Color("8a6a34"), Color("3f6a38"), Color("a07a3c")]
	for at in MapArt.scatter(dice, get_bounds(), LEAF_TRIES, _on_path):
		var radii := Vector2(dice.randf_range(5.0, 9.0), dice.randf_range(2.5, 4.5))
		MapArt.oval(self, at, radii, Color(leaves[dice.randi() % leaves.size()], 0.55))
	var marks := MapArt.Facets.new()
	var root := Color(FLOOR_COLOR.darkened(0.55), 0.55)
	for at in _edge_points(ROOT_STEP, -6.0):
		MapArt.crack(marks, dice, at, dice.randf_range(40.0, 80.0), 4.0, root)
	var blades: Array[Color] = [_grass_color(), _grass_color().lightened(0.18), FLOOR_COLOR.lightened(0.2)]
	for at in MapArt.scatter(dice, get_bounds(), TUFT_TRIES, _grows_grass.bind(dice)):
		MapArt.tuft(marks, dice, at, dice.randf_range(11.0, 19.0), Color(blades[dice.randi() % blades.size()], 0.85))
	marks.draw(self)
	for at in MapArt.scatter(dice, get_bounds(), PEBBLE_TRIES, _on_path):
		MapArt.pebble(self, dice, at, dice.randf_range(4.0, 9.0), PEBBLE_COLOR.darkened(0.2))
	for at in MapArt.scatter(dice, get_bounds(), FLOWER_TRIES, _grows_grass.bind(dice)):
		MapArt.disc(self, at, dice.randf_range(2.5, 4.0), Color(FLOWER_COLOR, 0.8))


## Tree crowns over the jungle, and on past the border where the camera
## still sees.
func _draw_jungle() -> void:
	var tints := PackedColorArray([TREE_COLOR.lerp(JUNGLE_COLOR, 0.5), JUNGLE_COLOR, JUNGLE_COLOR.lerp(JUNGLE_EDGE, 0.35),
		JUNGLE_COLOR.lerp(JUNGLE_EDGE, 0.7), Color("2b5238"), Color("335a2c")])
	var dice := MapArt.rng(11)
	var open := is_walkable.bind(0.0)
	for rect in MapArt.border(get_bounds(), TREES_OUTSIDE):
		MapArt.canopy(self, dice, MapArt.polygon_of(rect), tints, LEAF_LIGHT, _under_color(), open)
	for polygon in wall_polygons:
		MapArt.canopy(self, dice, polygon, tints, LEAF_LIGHT, _under_color(), open)


## Bones lying on the ground round `at`, within `reach` of it.
func _scatter_bones(into: MapArt.Facets, dice: RandomNumberGenerator, at: Vector2, reach: float, count: int) -> void:
	for i in count:
		var bone := at + Vector2.from_angle(dice.randf() * TAU) * reach * sqrt(dice.randf())
		var way := Vector2.from_angle(dice.randf() * TAU) * dice.randf_range(7.0, 13.0)
		into.line(bone - way, bone + way, 4.0, Color(BONE, 0.8))
		into.line(bone + way * 0.8, bone + way * 1.2, 8.0, Color(BONE, 0.8))
		into.line(bone - way * 1.2, bone - way * 0.8, 8.0, Color(BONE, 0.8))


## The centre lines of the paths, for the wear along them.
func _paths() -> Array[PackedVector2Array]:
	var found: Array[PackedVector2Array] = []
	found.assign([
		PackedVector2Array([Vector2(0, MID_Y), Vector2(size.x, MID_Y)]),
		PackedVector2Array([Vector2(LEFT_X, TOP_Y), Vector2(LEFT_X, LOW_Y)]),
		PackedVector2Array([Vector2(RIGHT_X, TOP_Y), Vector2(RIGHT_X, LOW_Y)]),
		PackedVector2Array([CAMPS[&"raptors"], Vector2(LEFT_X, TOP_Y)]),
		PackedVector2Array([Vector2(RIGHT_X, TOP_Y), CAMPS[&"gromp"]]),
		PackedVector2Array([PIT, CENTER]),
		PackedVector2Array([CENTER, START]),
		PackedVector2Array([Vector2(LEFT_X, LOW_Y), Vector2(RIGHT_X, LOW_Y)]),
	])
	return found


## Points every `step` px along the jungle's edge, `inset` px into the
## jungle (out of it, below 0), on open ground.
func _edge_points(step: float, inset: float) -> PackedVector2Array:
	var found := PackedVector2Array()
	for polygon in wall_polygons:
		found.append_array(MapArt.along(polygon, step, inset, is_walkable.bind(0.0)))
	return found


## The dark under the trees.
func _under_color() -> Color:
	return TREE_COLOR.darkened(0.35)


func _grass_color() -> Color:
	return JUNGLE_COLOR.lerp(JUNGLE_EDGE, 0.75)


## In the riverbed, at least `margin` from its banks.
func _in_riverbed(point: Vector2, margin: float) -> bool:
	return Geometry2D.is_point_in_polygon(point, _riverbed) and MapArt.edge_distance(point, _riverbed) >= margin


## In the riverbed or within 40 px of it.
func _by_riverbed(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, _riverbed) or MapArt.edge_distance(point, _riverbed) < 40.0


## Inside the pit's floor, at least `margin` from its rim.
func _in_pit(point: Vector2, margin: float) -> bool:
	return point.distance_to(PIT) < PIT_RADIUS - 40.0 - margin


## On open ground, off the riverbed and the pit and clear of the jungle.
func _on_path(point: Vector2) -> bool:
	return is_walkable(point, 30.0) and not _by_riverbed(point) and not _in_pit(point, -30.0)


## On open ground within reach of the jungle's edge, for a firefly.
func _near_jungle(point: Vector2) -> bool:
	return is_walkable(point, 24.0) and not is_walkable(point, GRASS_REACH)


## Where a tuft or flower grows: on open ground, mostly near the jungle.
func _grows_grass(point: Vector2, dice: RandomNumberGenerator) -> bool:
	return _on_path(point) and dice.randf() < (0.9 if not is_walkable(point, GRASS_REACH * 0.7) else 0.12)
