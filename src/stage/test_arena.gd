class_name TestArena
extends StageMap
## Open test map: a floor with a faint grid and solid border walls.
## The playable area starts at (0, 0) and the walls sit just outside it.
## Drawn with MapArt: a yard of dark slate slabs whose joints make the grid,
## broken up by soft patches and lit in its middle by the lantern's teal
## light; a few cracks and chips, and moss at the wall's foot; a stone wall
## round it casting its shadow, with lanterns on it; motes drifting in the
## light (build_ambience).

const GRID_STEP := 128.0
## The floor: its slabs and their joints, and its soft patches (how many,
## their radius range).
const FLOOR := Color("1f252d")
const JOINT := Color("14181e")
const PATCHES := 34
const PATCH_RADIUS := Vector2(220, 520)
## The lantern's light over the middle of the yard: its reach and strength.
const LIGHT_REACH := 1500.0
const LIGHT_ALPHA := 0.08
## Small marks (tries): cracks, chips, and moss at the foot of the wall
## (this far out from it).
const CRACK_TRIES := 50
const CHIP_TRIES := 120
const MOSS_TRIES := 900
const MOSS_REACH := 110.0
const MOSS := Color("3f5247")
## The wall: its blocks, its stone, how tall it is (for its shadow), and
## the land past it.
const BLOCK := Vector2(64, 32)
const WALL := Color("3f454e")
const WALL_HEIGHT := 70.0
const BEYOND := Color("0f1217")
## Lanterns on the wall, this far apart: their post, their light, and the
## light they pool on the floor.
const LANTERN_STEP := 800.0
const LANTERN_RADIUS := 13.0
const POST := Color("23272e")
const LANTERN_POOL := 280.0
## The far edges darken over this depth, this much.
const VIGNETTE_DEPTH := 520.0
const VIGNETTE_ALPHA := 0.35
## Motes drifting over the yard (tries).
const MOTE_TRIES := 60


func _init() -> void:
	lucian_start = Vector2(1700, 1350)
	merchant_point = size * 0.5


func build_ambience() -> MapAmbience:
	var ambience := MapAmbience.new()
	var dice := MapArt.rng(29)
	var drift := get_bounds().grow(-MapAmbience.DUST_REACH * 0.5)
	ambience.add(MapAmbience.Kind.DUST, MapArt.scatter(dice, drift, MOTE_TRIES), Color(UiStyle.LANTERN_COLOR.lightened(0.4), 0.35), dice)
	# A mote over each lantern's front: on the wall's inner edge.
	var fronts := MapArt.along(MapArt.polygon_of(get_bounds()), LANTERN_STEP)
	ambience.add(MapAmbience.Kind.FIREFLY, fronts, Color(UiStyle.LANTERN_COLOR, 0.8), dice)
	return ambience


func _draw() -> void:
	MapArt.outside(self, get_bounds(), BEYOND)
	var dice := MapArt.rng(27)
	MapArt.tiles(self, dice, get_bounds(), Vector2.ONE * GRID_STEP, FLOOR, JOINT, 0.05, 3.0, 0.0)
	MapArt.patches(self, dice, get_bounds(), PATCHES, PATCH_RADIUS, Color(FLOOR.lightened(0.12), 0.4), Color(FLOOR.darkened(0.4), 0.4))
	MapArt.glow(self, get_bounds().get_center(), LIGHT_REACH, Color(UiStyle.LANTERN_COLOR, LIGHT_ALPHA))
	var marks := MapArt.Facets.new()
	for at in MapArt.scatter(dice, get_bounds(), CRACK_TRIES, is_walkable.bind(30.0)):
		MapArt.crack(marks, dice, at, dice.randf_range(30.0, 70.0), 2.0, Color(JOINT, 0.6))
	for at in MapArt.scatter(dice, get_bounds(), MOSS_TRIES, _grows_moss):
		MapArt.tuft(marks, dice, at, dice.randf_range(8.0, 13.0), Color(MOSS.lightened(dice.randf_range(0.0, 0.12)), 0.8))
	marks.draw(self)
	for at in MapArt.scatter(dice, get_bounds(), CHIP_TRIES, is_walkable.bind(20.0)):
		MapArt.pebble(self, dice, at, dice.randf_range(3.0, 5.5), FLOOR.lightened(0.18))
	MapArt.wall_ring(self, dice, get_bounds(), WALL_THICKNESS, BLOCK, WALL, WALL_HEIGHT)
	MapArt.vignette(self, get_bounds(), VIGNETTE_DEPTH, VIGNETTE_ALPHA)
	_draw_lanterns()


## The lanterns on the wall: the light each pools on the floor, its post
## and its teal flame.
func _draw_lanterns() -> void:
	var spots := _lanterns()
	for at in spots:
		MapArt.glow(self, at, LANTERN_POOL, Color(UiStyle.LANTERN_COLOR, 0.1))
	for at in spots:
		MapArt.disc(self, at + MapArt.SHADOW_DIR * 5.0, LANTERN_RADIUS, Color(MapArt.SHADOW, 0.45))
		MapArt.disc(self, at, LANTERN_RADIUS, POST)
		MapArt.glow(self, at, LANTERN_RADIUS * 3.0, Color(UiStyle.LANTERN_COLOR, 0.5))
		MapArt.glow(self, at, LANTERN_RADIUS, Color(UiStyle.LANTERN_COLOR.lightened(0.6), 0.95))


## Where the lanterns stand: on the middle of the wall, LANTERN_STEP apart.
func _lanterns() -> PackedVector2Array:
	return MapArt.along(MapArt.polygon_of(get_bounds()), LANTERN_STEP, -WALL_THICKNESS * 0.5)


## Moss grows on open floor at the foot of the wall.
func _grows_moss(point: Vector2) -> bool:
	return is_walkable(point, 6.0) and not get_bounds().grow(-MOSS_REACH).has_point(point)
