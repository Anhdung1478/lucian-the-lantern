class_name DeadForestMap
extends StageMap
## Act 5: a dead forest clearing (5400 × 3400), varied by stage. A ragged wall
## of black trees along the top and bottom, twisted trees for cover (round
## walls, a fixed seeded list per stage), the merchant in a stone-ringed
## clearing at the center. Saplings come out of the tree lines. From 5-3 a
## spider nest in the east; 5-2 has Maokai's huge dead tree and 5-4 Elise's
## camp; 5-5 ends in Karthus's ruined graveyard in the east. Black Mist banks
## (see BlackMist) lie over the floor.
## Drawn with MapArt: cold grey-teal earth with dead grass, black puddles and
## old bones; the tree lines as black crowns with tangled bare branches and a
## faint teal rim light; twisted trees as gnarled trunks with bare limbs and
## long shadows; Maokai's roots, the nest's webs, Elise's cocoons, Karthus's
## flagstones, tombstones and crypt wall, with a few soul lights; teal motes
## and mist wisps drifting (build_ambience).

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

## The ground: its tint, its soft patches (how many, their radius range) and
## the land past the border.
const FLOOR_COLOR := Color("313f3b")
const BEYOND_COLOR := Color("060909")
const PATCHES := 46
const PATCH_RADIUS := Vector2(260, 560)
## Small marks on the ground (tries): dead grass, roots, bones and puddles.
const TUFT_TRIES := 1500
const TUFT_HEIGHT := Vector2(9, 20)
const GRASS_COLOR := Color("5d7266")
const ROOT_TRIES := 60
const BONE_TRIES := 40
const BONE_COLOR := Color("b4bfb3")
const PUDDLE_TRIES := 150
const PUDDLES := 24
const PUDDLE_RADIUS := Vector2(40, 100)
const PUDDLE_COLOR := Color("0b1413")
const PUDDLE_SHEEN := Color("7fc4b6")
## The merchant's clearing: its worn ground, its ring of stones (how many,
## their radius) and the path Lucian wore to it.
const MERCHANT_RING := 170.0
const MERCHANT_STONES := 14
const MERCHANT_GLOW := 300.0
const PATH_HALF := 110.0
const STONE_COLOR := Color("69746d")
## The tree lines: their crowns' tints, the light on them, the dark under
## them, how tall they are (for their shadow), how far the crowns go on past
## the border, and the bare branches along an open edge (this far apart,
## how long a piece is, and how many).
const TREE_LINE_COLOR := Color("060909")
const CROWN_TINTS: Array[Color] = [Color("141c1c"), Color("0f1717"), Color("1a2625"), Color("0d1313")]
const LEAF_LIGHT := Color("5aa89c")
const TREE_HEIGHT := 130.0
const TREES_OUTSIDE := 150.0
const BRANCH_STEP := 80.0
const BRANCH_PIECE := Vector2(34, 60)
const BRANCH_PIECES := 3
const BRANCH_COLOR := Color("2a3a37")
const RIM_GLOW := 52.0
## A twisted tree: its bark, its limbs (how many on a tree and on a trunk),
## the light on them and how tall it is (for its shadow, over its radius).
const BARK_COLOR := Color("1b2321")
const TRUNK_BARK := Color("1d2a25")
const LIMB_COLOR := Color("303d39")
const LIMBS := 7
const TRUNK_LIMBS := 10
const TREE_SHADOW := 1.2
const TRUNK_HEIGHT := 190.0
## The nest: its web, the pit at its heart, its egg sacs, and the threads
## strung to trees this close.
const NEST_RADIUS := 130.0
const NEST_PIT := 36.0
const NEST_SPOKES := 10
const NEST_SACS := 7
const NEST_THREAD_REACH := 640.0
const WEB_COLOR := Color(0.88, 0.95, 0.92, 0.42)
const SAC_COLOR := Color("c5d2c2")
## Elise's camp: the dark ground, its glow, and the cocoons round it.
const CAMP_RADIUS := 270.0
const CAMP_COLOR := Color("1a1424")
const CAMP_GLOW := Color("7a5aa0")
const COCOONS := 7
## Maokai's roots, and the sickly glow inside his ring.
const ROOT_COLOR := Color("141a18")
const MAOKAI_GLOW := Color("6ea87a")
## Karthus's rune circles (radius), his flagstones (slab, colours), and how
## far the ragged edge of the flagstones reaches west.
const RUNE_RADII: Array[float] = [170.0, 230.0]
const RUNE_COLOR := Color("6fd6c4")
const SLAB := Vector2(120, 90)
const FLAGSTONE := Color("46544f")
const FLAG_JOINT := Color("27312e")
const FLAG_EDGE := 130.0
## A tombstone: its stone, its height (for its shadow), and the crypt's.
const GRAVE_STONE := Color("77807a")
const GRAVE_HEIGHT := 34.0
const CRYPT_COLOR := Color("59615c")
const CRYPT_HEIGHT := 60.0
const MOSS_COLOR := Color("4f6a55")
## Soul lights over the graveyard, and the moon's haze over the clearing
## (how many patches, their radius range, how strong).
const SOUL_COLOR := Color("8ff0dc")
const SOULS: Array[int] = [0, 3, 5, 6]
const HAZE_PATCHES := 12
const HAZE_RADIUS := Vector2(500, 820)
const HAZE_ALPHA := 0.05
## The far edges darken over this depth, this much.
const VIGNETTE_DEPTH := 520.0
const VIGNETTE_ALPHA := 0.5
## Motes: spirits and mist wisps drifting over the clearing (tries).
const SPIRIT_TRIES := 50
const WISP_TRIES := 60

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




func build_ambience() -> MapAmbience:
	var ambience := MapAmbience.new()
	var dice := MapArt.rng(53)
	var spirits := MapArt.scatter(dice, get_bounds(), SPIRIT_TRIES, is_walkable.bind(80.0))
	ambience.add(MapAmbience.Kind.FIREFLY, spirits, Color(SOUL_COLOR, 0.7), dice)
	ambience.add(MapAmbience.Kind.FIREFLY, souls(), Color(SOUL_COLOR.lightened(0.3), 0.9), dice)
	var wisps := MapArt.scatter(dice, get_bounds().grow(-MapAmbience.DUST_REACH * 0.5), WISP_TRIES)
	ambience.add(MapAmbience.Kind.DUST, wisps, Color(BlackMist.MIST_COLOR, 0.2), dice)
	var sheen := PackedVector2Array()
	for puddle in puddles():
		sheen.append(Vector2(puddle.x, puddle.y))
	ambience.add(MapAmbience.Kind.GLINT, sheen, Color(PUDDLE_SHEEN, 0.45), dice)
	return ambience


func _draw() -> void:
	MapArt.outside(self, get_bounds(), BEYOND_COLOR)
	_draw_ground()
	_draw_marks()
	_draw_camps()
	_draw_shadows()
	_draw_tree_lines()
	_draw_trees()
	if has_graveyard(stage):
		_draw_graves()
	MapArt.vignette(self, get_bounds(), VIGNETTE_DEPTH, VIGNETTE_ALPHA)
	_draw_lights()


## The earth, broken up by soft patches; the merchant's clearing with its
## ring of stones, and the path worn to it; in 5-5 the graveyard's flagstones.
func _draw_ground() -> void:
	var dice := MapArt.rng(11)
	draw_rect(get_bounds(), FLOOR_COLOR)
	MapArt.patches(self, dice, get_bounds(), PATCHES, PATCH_RADIUS, Color(FLOOR_COLOR.lightened(0.13), 0.4), Color(FLOOR_COLOR.darkened(0.35), 0.45))
	MapArt.band(self, START, MERCHANT, PATH_HALF, Color(FLOOR_COLOR.lightened(0.12), 0.5))
	MapArt.glow(self, MERCHANT, MERCHANT_GLOW, Color(FLOOR_COLOR.lightened(0.2), 0.5))
	if has_graveyard(stage):
		_draw_flagstones(dice)
	for i in MERCHANT_STONES:
		var at := MERCHANT + Vector2.from_angle(TAU * (i + dice.randf_range(-0.15, 0.15)) / MERCHANT_STONES) * MERCHANT_RING
		MapArt.pebble(self, dice, at, dice.randf_range(11.0, 16.0), STONE_COLOR)


## Worn slabs east of GRAVEYARD_X, their west edge ragged and a few gone to
## dirt.
func _draw_flagstones(dice: RandomNumberGenerator) -> void:
	var area := Rect2(GRAVEYARD_X, TREE_LINE - 50.0, size.x - GRAVEYARD_X, size.y - 2.0 * (TREE_LINE - 50.0))
	MapArt.tiles(self, dice, area, SLAB, FLAGSTONE, FLAG_JOINT, 0.1, 3.0)
	for at in MapArt.scatter_band(dice, area.position, Vector2(GRAVEYARD_X, area.end.y), FLAG_EDGE, 40):
		MapArt.soft_oval(self, at, Vector2.ONE * dice.randf_range(70.0, 120.0), Color(FLOOR_COLOR, 0.9))
	for at in MapArt.scatter(dice, area, 24):
		MapArt.soft_oval(self, at, Vector2(dice.randf_range(50.0, 90.0), dice.randf_range(40.0, 60.0)), Color(FLOOR_COLOR, 0.55))
	MapArt.patches(self, dice, area, 14, Vector2(160, 320), Color(FLAGSTONE.lightened(0.12), 0.3), Color(FLAG_JOINT, 0.4))


## Black puddles, then dead grass, roots, old bones and a ripple on each
## puddle.
func _draw_marks() -> void:
	var dice := MapArt.rng(13)
	var marks := MapArt.Facets.new()
	for puddle in puddles():
		var at := Vector2(puddle.x, puddle.y)
		var radii := Vector2(puddle.z, puddle.z * 0.62)
		MapArt.soft_oval(self, at, radii * 1.25, Color(PUDDLE_COLOR, 0.4))
		MapArt.oval(self, at, radii, Color(PUDDLE_COLOR, 0.85))
		MapArt.oval(self, at - MapArt.SHADOW_DIR * puddle.z * 0.18, radii * Vector2(0.55, 0.3), Color(PUDDLE_SHEEN, 0.16))
		MapArt.ripple(marks, at + Vector2(puddle.z * 0.15, puddle.z * 0.12), puddle.z * 0.3, Color(PUDDLE_SHEEN, 0.3))
	for at in MapArt.scatter(dice, get_bounds(), TUFT_TRIES, is_walkable.bind(10.0)):
		MapArt.tuft(marks, dice, at, dice.randf_range(TUFT_HEIGHT.x, TUFT_HEIGHT.y), Color(GRASS_COLOR.lightened(dice.randf_range(-0.1, 0.2)), 0.85))
	for tree in trees(stage) + trunks(stage):
		for i in 3:
			var start := Vector2(tree.x, tree.y) + Vector2.from_angle(dice.randf() * TAU) * (tree.z + 6.0)
			MapArt.crack(marks, dice, start, dice.randf_range(70.0, 130.0), 4.0, Color(ROOT_COLOR, 0.65))
	for at in MapArt.scatter(dice, get_bounds(), ROOT_TRIES, is_walkable.bind(30.0)):
		MapArt.crack(marks, dice, at, dice.randf_range(40.0, 90.0), 2.0, Color(ROOT_COLOR, 0.5))
	for at in MapArt.scatter(dice, get_bounds(), BONE_TRIES, is_walkable.bind(20.0)):
		var way := Vector2.from_angle(dice.randf() * TAU)
		var half := way * dice.randf_range(10.0, 17.0)
		marks.line(at - half, at + half, 4.0, Color(BONE_COLOR, 0.7))
		for end: Vector2 in [at - half, at + half]:
			marks.line(end - way.orthogonal() * 4.0, end + way.orthogonal() * 4.0, 3.5, Color(BONE_COLOR, 0.7))
	marks.draw(self)


## Where the puddles lie: (x, y, radius), on open ground. A fixed list.
func puddles() -> Array[Vector3]:
	var found: Array[Vector3] = []
	var dice := MapArt.rng(29)
	for at in MapArt.scatter(dice, get_bounds(), PUDDLE_TRIES, is_walkable.bind(PUDDLE_RADIUS.y + 20.0)):
		if found.size() < PUDDLES:
			found.append(Vector3(at.x, at.y, dice.randf_range(PUDDLE_RADIUS.x, PUDDLE_RADIUS.y)))
	return found


## What marks each camp on the ground: the nest's web and egg sacs, Elise's
## cocoons, Maokai's roots, Karthus's rune circles.
func _draw_camps() -> void:
	var dice := MapArt.rng(31)
	var webs := MapArt.Facets.new()
	if camps.has(&"nest"):
		_draw_nest(dice, webs, camps[&"nest"])
	if camps.has(&"elise"):
		_draw_elise_camp(dice, webs, camps[&"elise"])
	if camps.has(&"maokai"):
		_draw_maokai_roots(webs)
	if has_graveyard(stage):
		MapArt.glow(self, GRAVE_BOSS, RUNE_RADII[1] * 1.4, Color(RUNE_COLOR, 0.07))
		for radius in RUNE_RADII:
			webs.arc(GRAVE_BOSS, radius, 0.0, TAU, 4.0, Color(RUNE_COLOR, 0.22), 40)
		for i in 6:
			var way := Vector2.from_angle(TAU * i / 6.0)
			webs.line(GRAVE_BOSS + way * RUNE_RADII[0], GRAVE_BOSS + way * RUNE_RADII[1], 3.0, Color(RUNE_COLOR, 0.2))
	webs.draw(self)


## A web round a dark pit, egg sacs round it, and threads strung to the
## trees near it.
func _draw_nest(dice: RandomNumberGenerator, webs: MapArt.Facets, at: Vector2) -> void:
	MapArt.soft_oval(self, at, Vector2(1.5, 1.25) * NEST_RADIUS, Color(MapArt.SHADOW, 0.35))
	MapArt.disc(self, at, NEST_PIT * 1.5, Color(MapArt.SHADOW, 0.5))
	MapArt.disc(self, at, NEST_PIT, Color(TREE_LINE_COLOR, 0.95))
	for i in NEST_SACS:
		var sac := at + Vector2.from_angle(TAU * (i + dice.randf()) / NEST_SACS) * dice.randf_range(70.0, 120.0)
		MapArt.oval(self, sac + MapArt.SHADOW_DIR * 3.0, Vector2(10, 14), Color(MapArt.SHADOW, 0.35))
		MapArt.oval(self, sac, Vector2(10, 14), SAC_COLOR)
		MapArt.oval(self, sac - MapArt.SHADOW_DIR * 3.0, Vector2(5, 7), SAC_COLOR.lightened(0.3))
	for i in NEST_SPOKES:
		var spoke := Vector2.from_angle(TAU * i / NEST_SPOKES)
		webs.line(at + spoke * NEST_PIT, at + spoke * NEST_RADIUS, 2.5, WEB_COLOR)
	for ring: float in [0.45, 0.7, 1.0]:
		webs.arc(at, NEST_RADIUS * ring, 0.0, TAU, 2.5, WEB_COLOR, 28)
	_draw_threads(dice, webs, at, NEST_RADIUS)


## Threads from a web round `at` to every twisted tree within
## NEST_THREAD_REACH of it, each a few strands that sag.
func _draw_threads(dice: RandomNumberGenerator, webs: MapArt.Facets, at: Vector2, start: float) -> void:
	for tree in trees(stage):
		var tree_at := Vector2(tree.x, tree.y)
		if at.distance_to(tree_at) - tree.z > NEST_THREAD_REACH:
			continue
		var way := (tree_at - at).normalized()
		for k in 3:
			var from := at + way.rotated((k - 1) * 0.2) * start
			var to := tree_at - way * tree.z * 0.7 + way.orthogonal() * (k - 1) * tree.z * 0.5
			var sag := from.lerp(to, 0.5) + way.orthogonal() * dice.randf_range(-24.0, 24.0)
			webs.line(from, sag, 2.0, WEB_COLOR)
			webs.line(sag, to, 2.0, WEB_COLOR)


## Elise's camp: dark ground with a violet glow, silk cocoons round it and
## threads to the trees.
func _draw_elise_camp(dice: RandomNumberGenerator, webs: MapArt.Facets, at: Vector2) -> void:
	MapArt.soft_oval(self, at, Vector2(1.2, 1.0) * CAMP_RADIUS, Color(CAMP_COLOR, 0.5))
	MapArt.glow(self, at, CAMP_RADIUS, Color(CAMP_GLOW, 0.14))
	for i in COCOONS:
		var cocoon := at + Vector2.from_angle(TAU * (i + dice.randf_range(0.0, 0.6)) / COCOONS) * dice.randf_range(190.0, 260.0)
		MapArt.oval(self, cocoon + MapArt.SHADOW_DIR * 4.0, Vector2(14, 26), Color(MapArt.SHADOW, 0.35))
		MapArt.oval(self, cocoon, Vector2(14, 26), SAC_COLOR.darkened(0.12))
		MapArt.oval(self, cocoon - MapArt.SHADOW_DIR * 4.0, Vector2(6, 12), SAC_COLOR.lightened(0.25))
		webs.line(cocoon + Vector2(-13, -8), cocoon + Vector2(13, -3), 2.0, Color(CAMP_COLOR, 0.6))
		webs.line(cocoon + Vector2(-13, 6), cocoon + Vector2(13, 11), 2.0, Color(CAMP_COLOR, 0.6))
	_draw_threads(dice, webs, at, CAMP_RADIUS * 0.8)


## Maokai's roots: a sickly glow in his ring, and a thick root creeping in
## from each trunk, with two small ones off it.
func _draw_maokai_roots(webs: MapArt.Facets) -> void:
	MapArt.glow(self, MAOKAI, TRUNK_RING * 1.5, Color(MAOKAI_GLOW, 0.14))
	for trunk in trunks(stage):
		var at := Vector2(trunk.x, trunk.y)
		var way := (MAOKAI - at).normalized()
		webs.blade(at + way * trunk.z * 0.8, at + way * (trunk.z + 150.0), 24.0, Color(ROOT_COLOR, 0.7))
		for turn: float in [-0.7, 0.7]:
			webs.blade(at + way * (trunk.z + 40.0), at + way.rotated(turn) * (trunk.z + 120.0), 12.0, Color(ROOT_COLOR, 0.6))


## The tree lines' shadows and the borders', the twisted trees', Maokai's
## trunks', the tombstones' and the crypt's.
func _draw_shadows() -> void:
	for polygon in tree_lines():
		MapArt.cast_shadow(self, polygon, TREE_HEIGHT)
	for rect in border_rects():
		MapArt.cast_shadow(self, MapArt.polygon_of(rect), TREE_HEIGHT)
	for tree in trees(stage):
		MapArt.round_shadow(self, Vector2(tree.x, tree.y), tree.z, tree.z * TREE_SHADOW)
	for trunk in trunks(stage):
		MapArt.round_shadow(self, Vector2(trunk.x, trunk.y), trunk.z, TRUNK_HEIGHT)
	if has_graveyard(stage):
		for rect in tombstones():
			MapArt.cast_shadow(self, MapArt.polygon_of(rect), GRAVE_HEIGHT)
		for slab in CRYPT_SLABS:
			MapArt.cast_shadow(self, MapArt.polygon_of(slab), CRYPT_HEIGHT)


## The black tree lines, and on past the border where the camera still
## sees: crowns, a faint teal rim light along every edge that has open
## ground beside it, and bare branches reaching in from it.
func _draw_tree_lines() -> void:
	var dice := MapArt.rng(7)
	var tints := PackedColorArray(CROWN_TINTS)
	var polygons := tree_lines()
	for rect in MapArt.border(get_bounds(), TREES_OUTSIDE):
		polygons.append(MapArt.polygon_of(rect))
	var open := is_walkable.bind(0.0)
	for polygon in polygons:
		MapArt.canopy(self, dice, polygon, tints, LEAF_LIGHT, TREE_LINE_COLOR, open)
	var branches := MapArt.Facets.new()
	for polygon in polygons:
		for i in polygon.size():
			var into := MapArt.inward(polygon, i)
			var lit := into.dot(MapArt.SHADOW_DIR) > 0.1
			for spot in MapArt.along_edge(polygon, i, BRANCH_STEP, -MapArt.EDGE_BEYOND, open):
				var from := spot + into * (MapArt.EDGE_BEYOND + 12.0)
				MapArt.glow(self, from + into * 8.0, RIM_GLOW, Color(LEAF_LIGHT, 0.12 if lit else 0.06))
				var heading := into.angle() + dice.randf_range(-0.7, 0.7)
				for piece in BRANCH_PIECES:
					var to := from + Vector2.from_angle(heading) * dice.randf_range(BRANCH_PIECE.x, BRANCH_PIECE.y)
					if not Geometry2D.is_point_in_polygon(to, polygon):
						break
					var width := 6.0 - 1.5 * piece
					branches.line(from, to, width, BRANCH_COLOR)
					if lit:
						branches.line(from - MapArt.SHADOW_DIR * width * 0.4, to - MapArt.SHADOW_DIR * width * 0.4, 1.5, Color(LEAF_LIGHT, 0.4))
					heading += dice.randf_range(-0.8, 0.8)
					from = to
	branches.draw(self)


## The twisted trees and Maokai's trunks seen from above: a dark gnarled
## top, a knot, and bare limbs.
func _draw_trees() -> void:
	var dice := MapArt.rng(17)
	var limbs := MapArt.Facets.new()
	var round_walls: Array[Vector3] = trunks(stage) + trees(stage)
	for wall in round_walls:
		var at := Vector2(wall.x, wall.y)
		var big := wall.z == TRUNK_RADIUS
		var bark := TRUNK_BARK if big else BARK_COLOR
		MapArt.disc(self, at, wall.z, bark.darkened(0.4))
		MapArt.disc(self, at - MapArt.SHADOW_DIR * wall.z * 0.06, wall.z * 0.92, bark)
		MapArt.disc(self, at - MapArt.SHADOW_DIR * wall.z * 0.18, wall.z * 0.62, bark.lightened(0.07))
		MapArt.disc(self, at + MapArt.SHADOW_DIR * wall.z * 0.12, wall.z * 0.28, Color(MapArt.SHADOW, 0.5))
		if big:
			MapArt.glow(self, at, wall.z * 0.9, Color(MAOKAI_GLOW, 0.14))
	for wall in round_walls:
		MapArt.limbs(limbs, dice, Vector2(wall.x, wall.y), wall.z, TRUNK_LIMBS if wall.z == TRUNK_RADIUS else LIMBS, LIMB_COLOR, LEAF_LIGHT)
	limbs.draw(self)


## The tombstones and the crypt's two slabs: worn stone with a lit edge,
## engraved, cracked and mossy; the slabs broken at their ends.
func _draw_graves() -> void:
	var dice := MapArt.rng(43)
	var marks := MapArt.Facets.new()
	var index := 0
	for rect in tombstones():
		draw_colored_polygon(_tomb_outline(rect), GRAVE_STONE.darkened(0.4))
		draw_colored_polygon(_tomb_outline(rect.grow(-3.0)), GRAVE_STONE)
		draw_colored_polygon(_tomb_outline(Rect2(rect.position + Vector2(5, 5), rect.size - Vector2(12, 14))), GRAVE_STONE.lightened(0.1))
		var middle := rect.get_center()
		var etch := Color(GRAVE_STONE.darkened(0.5), 0.9)
		if index % 2 == 0:
			marks.line(middle + Vector2(0, -16), middle + Vector2(0, 12), 3.0, etch)
			marks.line(middle + Vector2(-8, -7), middle + Vector2(8, -7), 3.0, etch)
		else:
			for scratch in 3:
				marks.line(middle + Vector2(-9, -14 + scratch * 9), middle + Vector2(9, -14 + scratch * 9), 2.0, etch)
		MapArt.crack(marks, dice, rect.position + rect.size * Vector2(dice.randf_range(0.3, 0.7), 0.4), 30.0, 2.0, Color(GRAVE_STONE.darkened(0.5), 0.8))
		MapArt.tuft(marks, dice, Vector2(middle.x + dice.randf_range(-8.0, 8.0), rect.end.y - 2.0), 12.0, MOSS_COLOR)
		index += 1
	for slab in CRYPT_SLABS:
		MapArt.tiles(self, dice, slab, Vector2(slab.size.x, 56.0), CRYPT_COLOR, CRYPT_COLOR.darkened(0.5), 0.08, 3.0, 0.0)
		MapArt.rim(self, MapArt.polygon_of(slab), CRYPT_COLOR.lightened(0.4), Color(MapArt.SHADOW, 0.6), 3.0)
		for end: float in [slab.position.y, slab.end.y]:
			var side := 1.0 if end == slab.position.y else -1.0
			for tooth in 3:
				var x := slab.position.x + slab.size.x * tooth / 3.0
				marks.triangle(Vector2(x, end), Vector2(x + slab.size.x * 0.3, end),
					Vector2(x + slab.size.x * dice.randf_range(0.05, 0.25), end + side * dice.randf_range(14.0, 32.0)), Color(MapArt.SHADOW, 0.55))
		MapArt.crack(marks, dice, slab.get_center() + Vector2(0, dice.randf_range(-100.0, 100.0)), 70.0, 3.0, Color(CRYPT_COLOR.darkened(0.6), 0.8))
		MapArt.tuft(marks, dice, Vector2(slab.get_center().x, slab.end.y - 2.0), 14.0, MOSS_COLOR)
		for k in 3:
			var rubble := slab.get_center() + Vector2(dice.randf_range(-70.0, 70.0), (slab.size.y * 0.5 + 25.0) * (1.0 if k % 2 == 0 else -1.0))
			MapArt.pebble(self, dice, rubble, dice.randf_range(6.0, 10.0), CRYPT_COLOR)
	marks.draw(self)


## A tombstone's outline: straight sides, an arched top.
func _tomb_outline(rect: Rect2) -> PackedVector2Array:
	var arch := rect.size.x * 0.5
	var outline := PackedVector2Array([Vector2(rect.position.x, rect.end.y), Vector2(rect.position.x, rect.position.y + arch)])
	for k in range(1, 6):
		var turn := PI * k / 6.0
		outline.append(Vector2(rect.position.x + arch - cos(turn) * arch, rect.position.y + arch - sin(turn) * arch))
	outline.append(Vector2(rect.end.x, rect.position.y + arch))
	outline.append(rect.end)
	return outline


## Where the graveyard's soul lights hang: over some of the tombstones.
func souls() -> PackedVector2Array:
	var spots := PackedVector2Array()
	if has_graveyard(stage):
		var stones := tombstones()
		for index in SOULS:
			spots.append(stones[index].get_center() + Vector2(0, -TOMB_SIZE.y))
	return spots


## Over the finished map: the moon's haze, a teal glow at each tombstone's
## foot and the soul lights.
func _draw_lights() -> void:
	var dice := MapArt.rng(47)
	for at in MapArt.scatter(dice, get_bounds(), HAZE_PATCHES, is_walkable.bind(0.0)):
		MapArt.glow(self, at, dice.randf_range(HAZE_RADIUS.x, HAZE_RADIUS.y), Color(SOUL_COLOR.lightened(0.3), HAZE_ALPHA))
	if has_graveyard(stage):
		for rect in tombstones():
			MapArt.glow(self, rect.get_center() + Vector2(0, TOMB_SIZE.y * 0.5), 80.0, Color(SOUL_COLOR, 0.08))
	for at in souls():
		MapArt.glow(self, at, 60.0, Color(SOUL_COLOR, 0.3))
		MapArt.glow(self, at, 16.0, Color(SOUL_COLOR.lightened(0.5), 0.7))
