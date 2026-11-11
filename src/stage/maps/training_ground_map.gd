class_name TrainingGroundMap
extends StageMap
## Act 2: the Sentinels' training ground. An open stone arena with round
## pillars to hide behind (Akshan's Comeuppance) and training dummies along
## the walls. Gates on the left, top and right let the waves in. Each stage
## moves the pillars a little and opens more gates.
## Drawn with MapArt: flagstones worn lighter toward the middle, a ring
## inlaid where Stage 3's pillars stand and the Sentinels' star at its
## heart; an outer wall of stone blocks with braziers on it, their light
## pooled on the floor; gates in the wall, lit where the waves come in and
## barred where they don't; stone pillars; practice dummies on round bases;
## dust drifting and sparks over the braziers (build_ambience).

const PILLAR_RADIUS := 70.0
const DUMMY_RADIUS := 34.0
const DUMMY_ART := preload("res://assets/art/enemies/training_dummy.svg")
const GATES := {&"left": Vector2(150, 1400), &"top": Vector2(2300, 150), &"right": Vector2(4450, 1400)}
const DUMMIES: Array[Vector2] = [Vector2(700, 110), Vector2(1500, 110), Vector2(3100, 110), Vector2(3900, 110), Vector2(700, 2690), Vector2(3900, 2690)]

## The floor: its slabs and their joints, its soft patches (how many, their
## radius range), sand trodden in where the trainees fight (how many
## patches), and the light worn into its middle.
const TILE := Vector2(200, 200)
const FLOOR := Color("3b4049")
const JOINT := Color("2a2e35")
const PATCHES := 40
const PATCH_RADIUS := Vector2(220, 480)
const SAND_PATCHES := 14
const SAND := Color("72684f")
const WORN_RADIUS := 1150.0
## The ring inlaid round the middle, where Stage 3's pillars stand (its
## radius and width), and the Sentinels' star at its heart (its points'
## reach).
const RING_RADIUS := 650.0
const RING_WIDTH := 44.0
const STAR_REACH := 230.0
const INLAY := Color("484e58")
const BRASS := Color("c9a45c")
## Small marks on the floor (tries): cracks, chips, and moss at the foot of
## the wall (this far out from it) and round the pillars.
const CRACK_TRIES := 70
const CHIP_TRIES := 160
const MOSS_TRIES := 1600
const MOSS_REACH := 130.0
const MOSS := Color("56664b")
## The outer wall: its blocks, how tall it is (for its shadow), and the
## land past it.
const BLOCK := Vector2(64, 32)
const WALL := Color("555a63")
const WALL_HEIGHT := 70.0
const BEYOND := Color("14171c")
## A gate: half its opening, its towers' length along the wall, how far its
## passage is drawn out, and its bars when it is shut.
const GATE_HALF := 150.0
const TOWER := 88.0
const PASSAGE := 260.0
const BARS := 9
const GATE_DARK := Color("101217")
const IRON := Color("2b2e33")
## How tall the pillars and the dummies are, for their shadows; the
## pillars' stone; the dummies' bases and their art's size.
const PILLAR := Color("8a8478")
const PILLAR_HEIGHT := 70.0
const DUMMY_HEIGHT := 34.0
const DUMMY_SIZE := 84.0
const DUMMY_BASE := Color("4e3a28")
## Braziers on the wall, about this far apart, kept this far from the gates
## and the dummies; their bowl, their fire, and the light they pool on the
## floor.
const BRAZIER_STEP := 640.0
const GATE_CLEAR := 260.0
const DUMMY_CLEAR := 160.0
const BRAZIER_RADIUS := 17.0
const COALS := Color("6b3a1e")
const FIRE := Color("ffd27a")
const LIGHT_POOL := 330.0
## The far edges darken over this depth, this much.
const VIGNETTE_DEPTH := 500.0
const VIGNETTE_ALPHA := 0.3
## Dust in the air (tries), and the sparks over each brazier.
const DUST_TRIES := 70
const SPARKS := 2

var stage := 1


func _init(stage_number := 1) -> void:
	stage = stage_number
	size = Vector2(4600, 2800)
	lucian_start = Vector2(2300, 2550)
	merchant_point = Vector2(1700, 2350)
	boss_point = GATES[&"top"] + Vector2(0, 150)
	for gate: StringName in ([&"top", &"right"] if stage == 1 else [&"left", &"top", &"right"]):
		spawn_points.append(GATES[gate])
	for pillar in pillars(stage):
		wall_circles.append(Vector3(pillar.x, pillar.y, PILLAR_RADIUS))
	for dummy in DUMMIES:
		wall_circles.append(Vector3(dummy.x, dummy.y, DUMMY_RADIUS))


## Stage 1: 6 pillars; stage 2: 8; stage 3: a ring of 10 around the center.
static func pillars(stage_number: int) -> Array[Vector2]:
	var found: Array[Vector2] = []
	if stage_number >= 3:
		for i in 10:
			found.append(Vector2(2300, 1400) + Vector2.from_angle(deg_to_rad(18.0 + 36.0 * i)) * 650.0)
		return found
	found.assign([Vector2(1300, 900), Vector2(3300, 900), Vector2(1300, 1900), Vector2(3300, 1900), Vector2(2300, 950), Vector2(2300, 1850)])
	if stage_number == 2:
		found.append_array([Vector2(800, 1400), Vector2(3800, 1400)])
	return found


func build_ambience() -> MapAmbience:
	var ambience := MapAmbience.new()
	var dice := MapArt.rng(19)
	var drift := get_bounds().grow(-MapAmbience.DUST_REACH * 0.5)
	ambience.add(MapAmbience.Kind.DUST, MapArt.scatter(dice, drift, DUST_TRIES), Color(FIRE.lightened(0.5), 0.35), dice)
	var sparks := PackedVector2Array()
	for at in _braziers():
		# Over the fire's front, toward the floor.
		var front := at - _outward(at) * WALL_THICKNESS * 0.5
		for i in SPARKS:
			sparks.append(front)
	ambience.add(MapAmbience.Kind.FIREFLY, sparks, Color(FIRE, 0.9), dice)
	return ambience


func _draw() -> void:
	MapArt.outside(self, get_bounds(), BEYOND)
	_draw_floor()
	_draw_marks()
	_draw_shadows()
	_draw_wall()
	_draw_gates()
	_draw_pillars()
	MapArt.vignette(self, get_bounds(), VIGNETTE_DEPTH, VIGNETTE_ALPHA)
	_draw_braziers()


## The flagstones, broken up by soft patches and sand and worn lighter
## toward the middle; the ring inlaid round it and the star at its heart.
func _draw_floor() -> void:
	var dice := MapArt.rng(11)
	var middle := get_bounds().get_center()
	MapArt.tiles(self, dice, get_bounds(), TILE, FLOOR, JOINT, 0.08, 4.0, 0.0)
	MapArt.patches(self, dice, get_bounds(), PATCHES, PATCH_RADIUS, Color(FLOOR.lightened(0.14), 0.4), Color(FLOOR.darkened(0.35), 0.4))
	for at in MapArt.scatter(dice, get_bounds().grow(-400.0), SAND_PATCHES):
		MapArt.glow(self, at, dice.randf_range(PATCH_RADIUS.x, PATCH_RADIUS.y), Color(SAND, 0.2))
	MapArt.glow(self, middle, WORN_RADIUS, Color(FLOOR.lightened(0.2), 0.2))
	draw_arc(middle, RING_RADIUS, 0.0, TAU, 160, INLAY, RING_WIDTH, true)
	for edge: float in [-0.5, 0.5]:
		draw_arc(middle, RING_RADIUS + RING_WIDTH * edge, 0.0, TAU, 160, Color(BRASS, 0.35), 3.0, true)
	var star := MapArt.Facets.new()
	for i in 8:
		var way := Vector2.from_angle(TAU * i / 8.0 - PI * 0.5)
		var long := i % 2 == 0
		star.blade(middle, middle + way * STAR_REACH * (1.0 if long else 0.55), 60.0 if long else 36.0, Color(BRASS, 0.12))
	star.draw(self)
	MapArt.disc(self, middle, 34.0, Color(BRASS, 0.22))
	MapArt.disc(self, middle, 22.0, Color(FLOOR, 0.9))


## Cracks and moss (at the foot of the wall and round the pillars), then
## chips of stone.
func _draw_marks() -> void:
	var dice := MapArt.rng(13)
	var marks := MapArt.Facets.new()
	for at in MapArt.scatter(dice, get_bounds(), CRACK_TRIES, is_walkable.bind(30.0)):
		MapArt.crack(marks, dice, at, dice.randf_range(30.0, 80.0), 2.0, Color(JOINT.darkened(0.3), 0.5))
	for at in MapArt.scatter(dice, get_bounds(), MOSS_TRIES, _grows_moss):
		MapArt.tuft(marks, dice, at, dice.randf_range(8.0, 14.0), Color(MOSS.lightened(dice.randf_range(0.0, 0.15)), 0.8))
	marks.draw(self)
	for at in MapArt.scatter(dice, get_bounds(), CHIP_TRIES, is_walkable.bind(20.0)):
		MapArt.pebble(self, dice, at, dice.randf_range(3.0, 6.0), FLOOR.lightened(0.15))


## The wall's shadow on the floor, and the pillars' and the dummies'.
func _draw_shadows() -> void:
	for rect in border_rects():
		MapArt.cast_shadow(self, MapArt.polygon_of(rect), WALL_HEIGHT)
	for circle in wall_circles:
		var tall := PILLAR_HEIGHT if circle.z == PILLAR_RADIUS else DUMMY_HEIGHT
		MapArt.round_shadow(self, Vector2(circle.x, circle.y), circle.z, tall)


## The outer wall's blocks, with a lit edge where it faces the light.
func _draw_wall() -> void:
	var dice := MapArt.rng(17)
	for rect in border_rects():
		var block := BLOCK if rect.size.x > rect.size.y else Vector2(BLOCK.y, BLOCK.x)
		MapArt.tiles(self, dice, rect, block, WALL, WALL.darkened(0.45), 0.07, 3.0)
	# The floor is a hole in the wall: where the floor's edge faces the light,
	# the wall's faces away from it.
	MapArt.rim(self, MapArt.polygon_of(get_bounds()), Color(MapArt.SHADOW, 0.5), WALL.lightened(0.3), 4.0)


## Each gate: a passage out through the wall, lit where the waves come in
## and barred where they don't, a brass threshold, a worn path in from an
## open one, and a tower on each side.
func _draw_gates() -> void:
	var bars := MapArt.Facets.new()
	for at: Vector2 in GATES.values():
		var out := _outward(at)
		var side := out.orthogonal()
		var line := _wall_point(at)
		var near := line - side * GATE_HALF
		var far := line + side * GATE_HALF
		var passage := MapArt.bounds_of(PackedVector2Array([near, far, far + out * PASSAGE, near + out * PASSAGE]))
		MapArt.tiles(self, MapArt.rng(23), passage, TILE * 0.5, FLOOR.darkened(0.3), JOINT.darkened(0.3), 0.05, 3.0)
		var clear := Color(GATE_DARK, 0.3)
		draw_polygon(PackedVector2Array([near, far, far + out * PASSAGE, near + out * PASSAGE]),
			PackedColorArray([clear, clear, GATE_DARK, GATE_DARK]))
		draw_colored_polygon(PackedVector2Array([near, far, far - out * 14.0, near - out * 14.0]), Color(BRASS, 0.4))
		if spawn_points.has(at):
			MapArt.glow(self, line + out * WALL_THICKNESS, GATE_HALF * 1.2, Color(FIRE, 0.2))
			MapArt.band(self, line, at - out * 160.0, GATE_HALF * 0.9, Color(FLOOR.lightened(0.14), 0.4))
		else:
			for i in BARS:
				var along := side * lerpf(-GATE_HALF, GATE_HALF, (i + 0.5) / BARS)
				bars.line(line + along, line + along + out * WALL_THICKNESS, 7.0, IRON)
				bars.line(line + along - side * 2.0, line + along - side * 2.0 + out * WALL_THICKNESS, 2.0, IRON.lightened(0.3))
			for share: float in [0.3, 0.75]:
				bars.line(near + out * WALL_THICKNESS * share, far + out * WALL_THICKNESS * share, 8.0, IRON.lightened(0.08))
		for way: float in [-1.0, 1.0]:
			var middle := line + out * WALL_THICKNESS * 0.5 + side * way * (GATE_HALF + TOWER * 0.5)
			var half := (side * TOWER * 0.5 + out * WALL_THICKNESS * 0.5).abs()
			var tower := Rect2(middle - half, half * 2.0)
			draw_rect(tower, WALL.lightened(0.12))
			draw_rect(tower.grow(-8.0), WALL.darkened(0.1))
			MapArt.rim(self, MapArt.polygon_of(tower), WALL.lightened(0.4), Color(MapArt.SHADOW, 0.6), 3.0)
			draw_colored_polygon(PackedVector2Array([middle + Vector2(0, -12), middle + Vector2(12, 0), middle + Vector2(0, 12), middle + Vector2(-12, 0)]), BRASS)
	bars.draw(self)


## The stone pillars, and the practice dummies on their round bases.
func _draw_pillars() -> void:
	for circle in wall_circles:
		var at := Vector2(circle.x, circle.y)
		if circle.z == PILLAR_RADIUS:
			MapArt.pillar(self, at, circle.z, PILLAR, BRASS)
		else:
			MapArt.disc(self, at, circle.z, DUMMY_BASE.darkened(0.3))
			MapArt.disc(self, at - MapArt.SHADOW_DIR * 2.0, circle.z - 4.0, DUMMY_BASE)
			var half := Vector2.ONE * DUMMY_SIZE * 0.5
			draw_texture_rect(DUMMY_ART, Rect2(at - half, half * 2.0), false, Color(0.86, 0.86, 0.86))


## The braziers on the wall: the light each pools on the floor, its iron
## bowl and its fire.
func _draw_braziers() -> void:
	var spots := _braziers()
	for at in spots:
		MapArt.glow(self, at, LIGHT_POOL, Color(FIRE, 0.1))
	for at in spots:
		MapArt.disc(self, at + MapArt.SHADOW_DIR * 5.0, BRAZIER_RADIUS, Color(MapArt.SHADOW, 0.45))
		MapArt.disc(self, at, BRAZIER_RADIUS, IRON)
		MapArt.disc(self, at, BRAZIER_RADIUS - 4.0, COALS)
		MapArt.glow(self, at, BRAZIER_RADIUS * 2.8, Color(FIRE, 0.55))
		MapArt.glow(self, at, BRAZIER_RADIUS * 0.9, Color(FIRE.lightened(0.6), 0.95))


## Where the braziers stand: along the middle of each side of the wall,
## about BRAZIER_STEP apart, clear of the gates and the dummies.
func _braziers() -> PackedVector2Array:
	var spots := PackedVector2Array()
	var corners := MapArt.polygon_of(get_bounds())
	for i in corners.size():
		var from := corners[i]
		var to := corners[(i + 1) % corners.size()]
		var count := roundi(from.distance_to(to) / BRAZIER_STEP)
		for k in count:
			var on_line := from.lerp(to, (k + 0.5) / count)
			if _clear_for_brazier(on_line):
				spots.append(on_line - MapArt.inward(corners, i) * WALL_THICKNESS * 0.5)
	return spots


## Far enough from every gate and dummy for a brazier at `on_line`, on the
## wall's inner edge.
func _clear_for_brazier(on_line: Vector2) -> bool:
	for gate: Vector2 in GATES.values():
		if on_line.distance_to(_wall_point(gate)) < GATE_CLEAR:
			return false
	for dummy in DUMMIES:
		if on_line.distance_to(dummy) < DUMMY_CLEAR:
			return false
	return true


## Moss grows on open floor at the foot of the wall and round the pillars
## and the dummies.
func _grows_moss(point: Vector2) -> bool:
	if not is_walkable(point, 6.0):
		return false
	if not get_bounds().grow(-MOSS_REACH).has_point(point):
		return true
	for circle in wall_circles:
		if point.distance_to(Vector2(circle.x, circle.y)) < circle.z + 50.0:
			return true
	return false


## The way out through the nearest side of the wall from `at`.
func _outward(at: Vector2) -> Vector2:
	var gaps: Array[float] = [at.x, at.y, size.x - at.x, size.y - at.y]
	var ways: Array[Vector2] = [Vector2.LEFT, Vector2.UP, Vector2.RIGHT, Vector2.DOWN]
	return ways[gaps.find(gaps.min())]


## Where the wall's inner edge is, straight out from `at`.
func _wall_point(at: Vector2) -> Vector2:
	var out := _outward(at)
	return Vector2(clampf(at.x + out.x * size.x, 0.0, size.x), clampf(at.y + out.y * size.y, 0.0, size.y))
