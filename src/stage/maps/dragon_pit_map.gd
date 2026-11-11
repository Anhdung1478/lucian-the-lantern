class_name DragonPitMap
extends StageMap
## Act 3, stage 5: the Elder Dragon's pit (3600 × 3600). A round stone floor
## with rock all round it. The rock is WALL_PIECES arc pieces, so no wall has
## a hole, and ROCKS rocks in a ring give cover. There are no camps: waves
## come in at the north, east and west rim, in turn (never the south, where
## Lucian starts). The merchant stands south of the middle and the dragon
## lands in the middle.
## Drawn with MapArt: a worn stone floor with rings, joints, cracks, claw
## marks, bones and rubble, and a faint glow at its heart where the elder
## lands; a wall of boulders that darken with depth, lit at the rim where it
## faces the light; the six cover rocks; drifting dust and wisps
## (build_ambience).

const FLOOR_RADIUS := 1650.0
const WALL_PIECES := 8
## Points along each piece's arc.
const ARC_POINTS := 12
const ROCKS := 6
const ROCK_RADIUS := 80.0
const ROCK_RING := 900.0
## The spawn points' distance from the middle, inside the rim.
const SPAWN_RING := 1450.0
const LUCIAN_START := Vector2(0, 1000)
const MERCHANT := Vector2(0, 450)

## The floor: its stone, the joints between its flagstones, its rings
## (radius, width) with joints running out across them (how many), its worn
## middle, and its soft patches (how many, their radius range).
const FLOOR_COLOR := Color("4a4540")
const JOINT_COLOR := Color("2f2b28")
const RINGS: Array[Vector2] = [Vector2(350, 56), Vector2(700, 64), Vector2(1200, 70)]
const JOINTS := 36
const WORN_RADIUS := 900.0
const PATCHES := 50
const PATCH_RADIUS := Vector2(120, 300)
## Marks on the floor (tries): cracks, claw marks (of three gouges), bones
## and chips of rubble.
const CRACK_TRIES := 90
const CLAW_MARKS := 10
const BONE_TRIES := 36
const RUBBLE_TRIES := 260
const BONE := Color("cfc7b2")
## The elder's glow at the heart, and the faint runes ringed round it.
const HEART_COLOR := Color("9b7fe8")
const HEART_RADIUS := 620.0
const RUNES := 12
## The wall: the dark under its boulders, the boulders (a grid cell, their
## radius range, how much darker they get with depth, how deep that is), the
## rock's rim, and how tall the wall is (for its shadow).
const STONE_COLOR := Color("24221f")
const BOULDER_COLOR := Color("5a554d")
const BOULDER_CELL := 150.0
const BOULDER_RADIUS := Vector2(46, 110)
const BOULDER_DARK := 0.62
const BOULDER_DEPTH := 700.0
## Boulders are drawn this far past the border, and cast a shadow within this
## share of BOULDER_DEPTH of the rim.
const BOULDERS_OUTSIDE := 500.0
const SHADOW_DEPTH := 0.6
const STONE_EDGE := Color("8a8174")
const WALL_HEIGHT := 90.0
## The cover rocks: their stone and how tall they are (for their shadows).
const ROCK_COLOR := Color("6b6660")
const ROCK_HEIGHT := 46.0
## The rim's line is this wide, in this many pieces.
const RIM_WIDTH := 10.0
const RIM_PIECES := 64
## The far edges darken over this depth, this much.
const VIGNETTE_DEPTH := 600.0
const VIGNETTE_ALPHA := 0.4
## Dust in the air and wisps over the heart.
const DUST_TRIES := 60
const WISPS := 14


func _init() -> void:
	size = Vector2(3600, 3600)
	var middle := size * 0.5
	var area := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	# Each piece: its arc of the rim, then out past the area's corners.
	var reach := size.length()
	for i in WALL_PIECES:
		var from := TAU * i / WALL_PIECES
		var to := TAU * (i + 1) / WALL_PIECES
		var wedge := PackedVector2Array()
		for step in ARC_POINTS + 1:
			wedge.append(middle + Vector2.from_angle(lerpf(from, to, float(step) / ARC_POINTS)) * FLOOR_RADIUS)
		wedge.append(middle + Vector2.from_angle(to) * reach)
		wedge.append(middle + Vector2.from_angle(from) * reach)
		wall_polygons.append_array(Geometry2D.intersect_polygons(area, wedge))
	for i in ROCKS:
		var rock := middle + Vector2.from_angle(TAU * i / ROCKS) * ROCK_RING
		wall_circles.append(Vector3(rock.x, rock.y, ROCK_RADIUS))
	lucian_start = middle + LUCIAN_START
	merchant_point = middle + MERCHANT
	boss_point = middle
	# Not the south rim: a wave would come in on top of Lucian's start.
	for direction in [Vector2.UP, Vector2.RIGHT, Vector2.LEFT]:
		spawn_points.append(middle + direction * SPAWN_RING)


func build_ambience() -> MapAmbience:
	var ambience := MapAmbience.new()
	var dice := MapArt.rng(51)
	var middle := size * 0.5
	ambience.add(MapAmbience.Kind.DUST, MapArt.scatter(dice, get_bounds().grow(-MapAmbience.DUST_REACH * 0.5), DUST_TRIES, is_walkable.bind(0.0)),
		Color(STONE_EDGE.lightened(0.3), 0.3), dice)
	var wisps := PackedVector2Array()
	for i in WISPS:
		wisps.append(middle + Vector2.from_angle(dice.randf() * TAU) * dice.randf_range(80.0, HEART_RADIUS * 0.8))
	ambience.add(MapAmbience.Kind.FIREFLY, wisps, Color(HEART_COLOR.lightened(0.3), 0.8), dice)
	return ambience


func _draw() -> void:
	MapArt.outside(self, get_bounds(), STONE_COLOR.darkened(0.3))
	_draw_floor()
	_draw_marks()
	for polygon in wall_polygons:
		MapArt.cast_shadow(self, polygon, WALL_HEIGHT)
	for rock in wall_circles:
		MapArt.round_shadow(self, Vector2(rock.x, rock.y), rock.z, ROCK_HEIGHT)
	_draw_wall()
	_draw_rim()
	_draw_rocks()
	MapArt.vignette(self, get_bounds(), VIGNETTE_DEPTH, VIGNETTE_ALPHA)


## The floor: stone worn lighter toward the middle and broken up by soft
## patches, rings of flagstones with joints across them, and the elder's
## glow at the heart with a ring of faint runes.
func _draw_floor() -> void:
	var dice := MapArt.rng(11)
	var middle := size * 0.5
	draw_circle(middle, FLOOR_RADIUS, FLOOR_COLOR)
	for at in MapArt.scatter(dice, get_bounds(), PATCHES, is_walkable.bind(0.0)):
		var radius := dice.randf_range(PATCH_RADIUS.x, PATCH_RADIUS.y)
		MapArt.soft_oval(self, at, Vector2(radius * dice.randf_range(1.0, 1.4), radius),
			Color(FLOOR_COLOR.lightened(0.14), 0.4) if dice.randf() < 0.5 else Color(FLOOR_COLOR.darkened(0.35), 0.4))
	MapArt.glow(self, middle, WORN_RADIUS, Color(FLOOR_COLOR.lightened(0.2), 0.2))
	for ring in RINGS:
		draw_arc(middle, ring.x, 0.0, TAU, 128, Color(JOINT_COLOR, 0.5), ring.y + 8.0, true)
		draw_arc(middle, ring.x, 0.0, TAU, 128, Color(FLOOR_COLOR.lightened(0.07), 0.8), ring.y, true)
	var joints := MapArt.Facets.new()
	for i in JOINTS:
		var way := Vector2.from_angle(TAU * (i + 0.5) / JOINTS)
		for ring in RINGS:
			joints.line(middle + way * (ring.x - ring.y * 0.5), middle + way * (ring.x + ring.y * 0.5), 3.0, Color(JOINT_COLOR, 0.7))
	joints.draw(self)
	MapArt.glow(self, middle, HEART_RADIUS, Color(HEART_COLOR, 0.14))
	MapArt.glow(self, middle, HEART_RADIUS * 0.4, Color(HEART_COLOR, 0.12))
	draw_arc(middle, RINGS[0].x - RINGS[0].y, 0.0, TAU, 96, Color(HEART_COLOR, 0.2), 3.0, true)
	var runes := MapArt.Facets.new()
	for i in RUNES:
		var way := Vector2.from_angle(TAU * i / RUNES)
		runes.blade(middle + way * 120.0, middle + way * 200.0, 14.0, Color(HEART_COLOR, 0.16))
	runes.draw(self)


## Cracks, claw marks, bones and rubble on the floor.
func _draw_marks() -> void:
	var dice := MapArt.rng(13)
	var middle := size * 0.5
	var marks := MapArt.Facets.new()
	for at in MapArt.scatter(dice, get_bounds(), CRACK_TRIES, is_walkable.bind(60.0)):
		MapArt.crack(marks, dice, at, dice.randf_range(50.0, 130.0), 2.5, Color(JOINT_COLOR.darkened(0.3), 0.6))
	for i in CLAW_MARKS:
		var claw := middle + Vector2.from_angle(dice.randf() * TAU) * dice.randf_range(300.0, 1250.0)
		var way := Vector2.from_angle(dice.randf() * TAU) * dice.randf_range(110.0, 190.0)
		for k in 3:
			var shift := way.orthogonal().normalized() * (k - 1) * 20.0
			marks.blade(claw + shift, claw + shift + way, 7.0, Color(JOINT_COLOR.darkened(0.3), 0.6))
			marks.line(claw + shift + way.normalized() * 6.0, claw + shift + way * 0.9, 2.0, Color(FLOOR_COLOR.lightened(0.2), 0.3))
	for at in MapArt.scatter(dice, get_bounds(), BONE_TRIES, is_walkable.bind(80.0)):
		var way := Vector2.from_angle(dice.randf() * TAU) * dice.randf_range(14.0, 30.0)
		marks.line(at - way, at + way, 6.0, Color(BONE, 0.8))
		marks.line(at + way * 0.8, at + way * 1.2, 12.0, Color(BONE, 0.8))
		marks.line(at - way * 1.2, at - way * 0.8, 12.0, Color(BONE, 0.8))
	marks.draw(self)
	for at in MapArt.scatter(dice, get_bounds(), RUBBLE_TRIES, is_walkable.bind(20.0)):
		MapArt.pebble(self, dice, at, dice.randf_range(4.0, 11.0), FLOOR_COLOR.lightened(0.14))


## The wall: the dark under its boulders, then boulders in a grid, lighter at
## the rim and darker deeper in, each kept inside the rock.
func _draw_wall() -> void:
	for polygon in wall_polygons:
		draw_colored_polygon(polygon, STONE_COLOR)
	var dice := MapArt.rng(17)
	var middle := size * 0.5
	var boulders: Array[Vector3] = []
	for at in MapArt.grid(dice, get_bounds().grow(BOULDERS_OUTSIDE), BOULDER_CELL):
		var depth := at.distance_to(middle) - FLOOR_RADIUS
		var radius := minf(dice.randf_range(BOULDER_RADIUS.x, BOULDER_RADIUS.y), depth - 8.0)
		if radius >= BOULDER_RADIUS.x * 0.6:
			boulders.append(Vector3(at.x, at.y, radius))
	var stone := MapArt.Facets.new()
	for boulder in boulders:
		var at := Vector2(boulder.x, boulder.y)
		var deep := clampf((at.distance_to(middle) - FLOOR_RADIUS) / BOULDER_DEPTH, 0.0, 1.0)
		if deep < SHADOW_DEPTH:
			MapArt.round_shadow(self, at, boulder.z, boulder.z * 0.5)
		MapArt.rock(stone, dice, at, boulder.z, BOULDER_COLOR.darkened(BOULDER_DARK * deep))
	stone.draw(self)


## The rock's rim round the floor: lit where it faces the light (the
## bottom-right of the pit), dark where it faces away.
func _draw_rim() -> void:
	var middle := size * 0.5
	for i in RIM_PIECES:
		var from := TAU * i / RIM_PIECES
		var to := TAU * (i + 1) / RIM_PIECES
		var facing := -Vector2.from_angle((from + to) * 0.5).dot(MapArt.SHADOW_DIR)
		var color := Color(MapArt.SHADOW, 0.6).lerp(STONE_EDGE, smoothstep(-0.25, 0.25, facing))
		draw_arc(middle, FLOOR_RADIUS, from, to + 0.01, 4, color, RIM_WIDTH, true)


## The six cover rocks.
func _draw_rocks() -> void:
	var dice := MapArt.rng(9)
	var stone := MapArt.Facets.new()
	for rock in wall_circles:
		MapArt.rock(stone, dice, Vector2(rock.x, rock.y), rock.z, ROCK_COLOR)
	stone.draw(self)
