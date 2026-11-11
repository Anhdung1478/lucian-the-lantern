class_name ThreshDomainMap
extends StageMap
## Act 6: Thresh's domain (5600 × 3400), ground over an abyss on
## Layers.CHASM: near black, a slow green mist turning in it, chains hanging
## across it from rock spikes. Stages 1 to 4: three slate plateaus with faint
## green cracks (west: the start; center: the merchant; east: the boss spot),
## joined by stone bridges with soul lanterns, two across each gap, 280 wide;
## from 6-3 they narrow to 200 and the north-west one is broken. Rock spikes
## on the plateaus give cover. Chain Wardens stand on small rock ledges in the
## abyss off the center plateau's north and south edges (from 6-3 the east
## plateau's too): abyss for physics, so only a perched enemy is ever there.
## A perched one takes the free ledge nearest Lucian. Waves come from the
## east end of the east plateau and the far ends of the bridges, spread only
## SPAWN_SPREAD so they stay on a bridge. 6-2 has the revived Karthus's broken
## altar on the east plateau, 6-4 Hecarim's camp at its east end. 6-5 is the
## final platform: a carved stone disc with a rune ring and chains at its rim,
## Thresh at its center, four bridge stubs and no walls; waves come from the
## north, east and south stubs (not the west one, by Lucian's start).
## The abyss is the map less the ground, cut in two along MID_Y first, so no
## piece of it has a hole (see abyss). The mist turns by rotating its
## swirls, drawn once: no frame redraws anything.

const MAP_SIZE := Vector2(5600, 3400)
const FINAL_STAGE := 5
## The abyss is cut along this row: every plateau and the platform cross it.
const MID_Y := 1700.0

# Stages 1 to 4.
## The plateaus (west, center, east), their corners cut.
const PLATEAUS: Array[Rect2] = [Rect2(200, 950, 1500, 1500), Rect2(2300, 800, 1000, 1800), Rect2(3900, 900, 1550, 1600)]
const CORNER_CUT := 150.0
const START := Vector2(450, 1700)
const MERCHANT := Vector2(2800, 1700)
const BOSS := Vector2(4700, 1700)
## The east end of the east plateau.
const EAST_SPAWNS: Array[Vector2] = [Vector2(5250, 1250), Vector2(5250, 2150)]
## The bridges: (x where it leaves its west plateau, x where it reaches its
## east one, y of its middle line); north-west, south-west, north-east,
## south-east.
const BRIDGES: Array[Vector3] = [Vector3(1700, 2300, 1250), Vector3(1700, 2300, 2150), Vector3(3300, 3900, 1200), Vector3(3300, 3900, 2200)]
const BRIDGE_WIDTH := 280.0
## From this stage the bridges narrow and the north-west one is broken.
const NARROW_STAGE := 3
const NARROW_WIDTH := 200.0
const BROKEN_BRIDGE := 0
## A bridge (or a stub) runs this far onto its ground, so they join.
const BRIDGE_OVERLAP := 60.0
## What is left of the broken bridge at each end.
const BROKEN_STUB := 100.0
## A wave's spawn point at a bridge's far (east) end: this far out on it.
const BRIDGE_END_SPAWN := 60.0
## How far (each way) a wave enemy appears from a spawn point here, not the
## usual 70: on a 200 bridge its body (r 42 at most) keeps 50 from the abyss.
const SPAWN_SPREAD := 50.0
## The ledges: center north, center south, east north, east south, each 260
## off its plateau's edge; how many each stage has.
const LEDGES: Array[Vector2] = [Vector2(2800, 540), Vector2(2800, 2860), Vector2(4700, 640), Vector2(4700, 2760)]
const LEDGE_COUNTS: Array[int] = [2, 2, 4, 4, 0]
const LEDGE_RADIUS := 120.0
## Camps: the revived Karthus's broken altar (6-2), Hecarim's (6-4).
const KARTHUS_ALTAR := Vector2(4700, 1700)
const HECARIM_CAMP := Vector2(5200, 1700)
## Rock spikes for cover: (x, y, radius).
const SPIKES: Array[Vector3] = [
	Vector3(950, 1300, 60), Vector3(1100, 2100, 55), Vector3(1400, 1700, 65),
	Vector3(2550, 1150, 60), Vector3(3050, 1150, 55), Vector3(2550, 2250, 55), Vector3(3050, 2250, 60),
	Vector3(4250, 1350, 65), Vector3(4300, 2100, 60), Vector3(4950, 1150, 55), Vector3(4950, 2250, 55),
]

# Stage 5: the final platform.
const PLATFORM_CENTER := Vector2(2800, 1700)
const PLATFORM_RADIUS := 1400.0
const PLATFORM_SIDES := 128
const PLATFORM_START := Vector2(1650, 1700)
const PLATFORM_MERCHANT := Vector2(2800, 1950)
## The bridge stubs: north, east, south, west; how far each runs out past
## the rim (the map's height keeps north and south short).
const STUB_DIRECTIONS: Array[Vector2] = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
const STUB_LENGTHS: Array[float] = [260.0, 500.0, 260.0, 500.0]
const STUB_WIDTH := 280.0
## The stubs waves come from: north, east and south. Not the west one: a
## wave would come in behind Lucian's start (as the dragon pit leaves out its
## south rim).
const SPAWN_STUBS: Array[int] = [0, 1, 2]
## A stub's spawn point: this far back from its broken end.
const STUB_SPAWN_BACK := 110.0

# The art.
const ABYSS_COLOR := Color("040706")
const MIST_COLOR := Color(0.3, 0.85, 0.55)
## The abyss's layers, far to near: patches of green haze and of dark mist
## (how many, their radius range, the haze's alpha, the dark's), then a
## nearer layer of the same, then chains hanging far below (how many, how far
## apart their ends, how faint).
const HAZE_PATCHES := 40
const HAZE_RADIUS := Vector2(260, 560)
const HAZE_ALPHA := 0.05
const MURK_ALPHA := 0.5
const NEAR_PATCHES := 26
const NEAR_RADIUS := Vector2(140, 300)
const FAR_CHAINS := 10
const FAR_CHAIN_SPAN := Vector2(500, 1100)
const FAR_CHAIN_FADE := 0.24
## Souls drifting far below and motes over the ground: how many tries each
## gets to find its place, and their colours.
const SOUL_TRIES := 80
const SOUL_COLOR := Color(0.55, 1.0, 0.8, 0.5)
const MOTE_TRIES := 70
const MOTE_COLOR := Color(0.55, 1.0, 0.8, 0.3)
## The mist swirls (x, y, radius), stages 1 to 4 and the platform: arms, the
## points along an arm, how far round an arm winds, its width (share of the
## radius), its alpha at the brightest.
const SWIRLS: Array[Vector3] = [
	Vector3(700, 450, 450), Vector3(2000, 400, 420), Vector3(3550, 450, 480), Vector3(4900, 420, 450),
	Vector3(800, 2950, 450), Vector3(2050, 3000, 430), Vector3(3550, 2950, 480), Vector3(4950, 2980, 450),
	Vector3(2000, 1700, 330), Vector3(3600, 1700, 330), Vector3(80, 1700, 350), Vector3(5560, 1700, 300),
]
const PLATFORM_SWIRLS: Array[Vector3] = [
	Vector3(600, 500, 500), Vector3(5000, 500, 500), Vector3(600, 2900, 500), Vector3(5000, 2900, 500),
	Vector3(500, 1700, 450), Vector3(5100, 1700, 450), Vector3(1400, 200, 350), Vector3(4200, 200, 350),
	Vector3(1400, 3200, 350), Vector3(4200, 3200, 350),
]
const SWIRL_ARMS := 3
const SWIRL_POINTS := 32
const SWIRL_TURN := PI * 1.4
const SWIRL_WIDTH := 0.22
const SWIRL_ALPHA := 0.07
## Radians a second the mist turns (each swirl a little faster or slower,
## every other one the other way).
const SWIRL_SPEED := 0.05
## The plateaus' slate: slabs (a straight grid of this size, how far their
## shade varies, the joint between them), the cliff below an edge (how deep,
## its two shades), the lit lip, and what each edge casts into the abyss.
const SLATE := Color("3a4247")
const SLATE_JOINT := Color("20272a")
const SLATE_EDGE := Color("6a7a82")
const SLAB := Vector2(150, 150)
const SLAB_SHADE := 0.05
const SLAB_JOINT := 4.0
const CLIFF_DEPTH := 40.0
const CLIFF_LOW := Color("0d1113")
const CLIFF_MID := Color("182024")
const CLIFF_CRACK_STEP := 70.0
const EDGE_SHADOW := 80.0
## Wear on a plateau: soft patches (how many per px², their radius range),
## cracks per px² (dark ones, and glowing green ones), pebbles per px², and
## how far from an edge each stays.
const PATCHES_PER_AREA := 1.0 / 90000.0
const PATCH_RADIUS := Vector2(90, 160)
const CRACKS_PER_AREA := 1.0 / 40000.0
const GLOW_CRACKS_PER_AREA := 1.0 / 130000.0
const PEBBLES_PER_AREA := 1.0 / 30000.0
const CRACK_KEEP := 90.0
const CRACK_GLOW := Color(0.35, 1.0, 0.6, 0.1)
const CRACK_CORE := Color(0.55, 1.0, 0.75, 0.3)
const CRACK_DARK := Color(0.05, 0.07, 0.08, 0.5)
## Mist curling over a cliff's lip onto the stone: a wisp this far apart.
const LIP_MIST_STEP := 110.0
const LIP_MIST_RADIUS := 80.0
const LIP_MIST_ALPHA := 0.04
## The bridges' stone and their curbs, the paving's slab size, and how
## far they cast into the abyss.
const STONE := Color("4b5253")
const STONE_JOINT := Color("2c3334")
const STONE_EDGE := Color("6f7c80")
const PAVING := Vector2(92, 46)
const CURB := 12.0
const BRIDGE_SHADOW := 60.0
const LANTERN_GAP := 150.0
## No lantern this close to a bridge's ends.
const LANTERN_INSET := 40.0
const LANTERN_POST := Color("121516")
const LANTERN_POOL := 120.0
const LANTERN_GLOW := Color(0.4, 1.0, 0.7, 0.16)
const LANTERN_FLAME := Color("b9ffd9")
const CHAIN_DARK := Color("15181a")
const CHAIN_COLOR := Color("4a5156")
const CHAIN_SHINE := Color("7b858b")
const CHAIN_LINK := 18.0
## How far a chain sags, as a share of its length.
const CHAIN_SAG := 0.12
## A chain bolted to a plateau runs on over its stone this far, in a plate.
const BOLTED_LENGTH := 170.0
const BOLTED_SCALE := 0.75
const PLATE_SIZE := 44.0
## A chain's end counts as on a plateau this close to its edge.
const ANCHOR_REACH := 60.0
## Stages 1 to 4: rocks rising from the abyss (x, y, radius), and the chains
## hung from them (from x, from y, to x, to y), to the plateaus' edges, off
## the map, and across the gaps between the bridges.
const ABYSS_ROCKS: Array[Vector3] = [
	Vector3(1250, 430, 70), Vector3(3600, 380, 75), Vector3(5250, 420, 60),
	Vector3(1250, 2970, 70), Vector3(3600, 3020, 75), Vector3(5250, 2980, 60),
]
const CHAINS: Array[Vector4] = [
	Vector4(1250, 430, 1000, 975), Vector4(1250, 430, 2550, 825), Vector4(1250, 430, 350, -60),
	Vector4(3600, 380, 3150, 825), Vector4(3600, 380, 4150, 925), Vector4(3600, 380, 3700, -60),
	Vector4(5250, 420, 5000, 925),
	Vector4(1250, 2970, 1000, 2425), Vector4(1250, 2970, 2550, 2575), Vector4(1250, 2970, 400, 3460),
	Vector4(3600, 3020, 3150, 2575), Vector4(3600, 3020, 4150, 2475), Vector4(3600, 3020, 3500, 3460),
	Vector4(5250, 2980, 5000, 2475),
	Vector4(1675, 1520, 2325, 1880), Vector4(3275, 1880, 3925, 1520),
]
## The rock spikes: their colour, how tall they stand (the shadow they cast),
## and a spike rising from the abyss, darker.
const ROCK := Color("3a4247")
const ROCK_LIGHT := Color("59636a")
const SPIKE_HEIGHT := 80.0
const DEEP_ROCK_DARK := 0.4
## A ledge: its cliff side below it, the worn middle of its top, and the
## joints cut across it.
const LEDGE_SIDES := 16
const LEDGE_FACE := 36.0
const LEDGE_WORN := 22.0
const LEDGE_JOINTS := 3
## The broken bridge's rubble, fallen into the dark under its gap.
const RUBBLE_BLOCKS := 7
## The platform: its stone, the carved rings (radius) and the rune ring
## between two of them, its runes, and the chains rising at its rim (how far
## out they run to their rocks).
const PLATFORM_STONE := Color("454d52")
const PLATFORM_JOINT := Color("1f2528")
const CARVE_COLOR := Color("1b2124")
const CARVED_RINGS: Array[float] = [250.0, 600.0, 1050.0, 1250.0]
## The masonry: the courses between the rings (how many in each band, from
## the dais out) and how long a slab is along its course.
const COURSES: Array[int] = [3, 4, 1, 1]
const COURSE_SLAB := 140.0
const COURSE_SHADE := 0.05
const COURSE_JOINT := 4.0
## The rune band is a little darker, the rim's coping a little lighter.
const RUNE_BAND_SHADE := 0.1
const COPING_SHADE := 0.16
const RUNE_RING := 1150.0
const RUNES := 32
const RUNE_COLOR := Color(0.45, 1.0, 0.7, 0.45)
const RUNE_GLOW := Color(0.45, 1.0, 0.7, 0.1)
const RUNE_POOL := 55.0
const RIM_CHAINS := 16
const RIM_CHAIN_REACH := 460.0
const PLATFORM_CLIFF := 44.0
const PLATFORM_SHADOW := 70.0
## The pale stone dais where Thresh starts: his green-black art (darker
## still in Phase 2) vanished on a dark one.
const HEART_COLOR := Color("5f686d")
const DAIS_STAR_REACH := 190.0
const DAIS_POOL := 380.0
const ALTAR_COLOR := Color("5a6064")
const ALTAR_SIZE := 200.0
## The altar's plinth (a share of the slab) and how tall the slab stands.
const ALTAR_PLINTH := 1.32
const ALTAR_HEIGHT := 26.0
const ALTAR_CRACKS := 3
const HOOF_COLOR := Color(0.35, 1.0, 0.65, 0.22)
## Hecarim's camp: the scorched ground round it (how many patches, how far
## out), and the iron stakes ringing it (how many, how far out).
const SCORCH := Color(0.0, 0.03, 0.02, 0.25)
const SCORCH_PATCHES := 9
const SCORCH_REACH := 190.0
const STAKES := 6
const STAKE_RING := 175.0

## The pools of light round the camps, and the platform's wear: patches,
## cracks and glowing cracks over the disc.
const CAMP_POOL := 200.0
const PLATFORM_PATCHES := 70
const PLATFORM_CRACKS := 160
const PLATFORM_GLOW_CRACKS := 45
## The map's edges darken, a little less than the other maps'.
const VIGNETTE_DEPTH := 380.0
const VIGNETTE_ALPHA := 0.4

var stage := 1
## The walkable ground: the plateaus and the bridges (stages 1 to 4), or the
## platform and its stubs (6-5). The abyss is the rest.
var ground: Array[PackedVector2Array] = []

var _swirls: Array[Node2D] = []


func _init(stage_number := 1) -> void:
	stage = clampi(stage_number, 1, FINAL_STAGE)
	size = MAP_SIZE
	spawn_jitter = SPAWN_SPREAD
	if stage == FINAL_STAGE:
		ground = platform()
		lucian_start = PLATFORM_START
		merchant_point = PLATFORM_MERCHANT
		boss_point = PLATFORM_CENTER
		spawn_points = stub_spawns()
	else:
		ground = plateaus()
		ground.append_array(bridges(stage))
		lucian_start = START
		merchant_point = MERCHANT
		boss_point = BOSS
		spawn_points = spawns(stage)
		camps = camp_points(stage)
		ledge_points.assign(LEDGES.slice(0, LEDGE_COUNTS[stage - 1]))
		wall_circles.assign(SPIKES)
	chasm_polygons = abyss(ground)


## The abyss's floor and its mist, behind the ground this map draws.
func _ready() -> void:
	super()
	var depths := Node2D.new()
	depths.name = "Depths"
	depths.show_behind_parent = true
	depths.draw.connect(_draw_depths.bind(depths))
	add_child(depths)
	var mist_layer := Node2D.new()
	mist_layer.name = "Mist"
	mist_layer.show_behind_parent = true
	add_child(mist_layer)
	var swirls := PLATFORM_SWIRLS if stage == FINAL_STAGE else SWIRLS
	for i in swirls.size():
		var swirl := Node2D.new()
		swirl.position = Vector2(swirls[i].x, swirls[i].y)
		swirl.rotation = i * 1.3
		swirl.draw.connect(_draw_swirl.bind(swirl, swirls[i].z))
		mist_layer.add_child(swirl)
		_swirls.append(swirl)


## The mist turns. Only the swirls' rotations change: nothing is redrawn.
func _process(delta: float) -> void:
	for i in _swirls.size():
		var way := 1.0 if i % 2 == 0 else -1.0
		_swirls[i].rotation += SWIRL_SPEED * (1.0 + 0.25 * (i % 3)) * way * delta


## The west, center and east plateaus, their corners cut.
static func plateaus() -> Array[PackedVector2Array]:
	var found: Array[PackedVector2Array] = []
	for rect in PLATEAUS:
		found.append(_cut_corners(rect, CORNER_CUT))
	return found


static func bridge_width(stage_number: int) -> float:
	return NARROW_WIDTH if stage_number >= NARROW_STAGE else BRIDGE_WIDTH


static func is_broken(stage_number: int, bridge: int) -> bool:
	return bridge == BROKEN_BRIDGE and stage_number >= NARROW_STAGE


## Each bridge as a polygon running onto both its plateaus; the broken one as
## the two stubs left of it.
static func bridges(stage_number: int) -> Array[PackedVector2Array]:
	var width := bridge_width(stage_number)
	var found: Array[PackedVector2Array] = []
	for i in BRIDGES.size():
		var bridge := BRIDGES[i]
		if is_broken(stage_number, i):
			found.append(_rect_polygon(_span(bridge.x - BRIDGE_OVERLAP, bridge.x + BROKEN_STUB, bridge.z, width)))
			found.append(_rect_polygon(_span(bridge.y - BROKEN_STUB, bridge.y + BRIDGE_OVERLAP, bridge.z, width)))
		else:
			found.append(_rect_polygon(_span(bridge.x - BRIDGE_OVERLAP, bridge.y + BRIDGE_OVERLAP, bridge.z, width)))
	return found


## The east end of the east plateau, then the far (east) end of each whole
## bridge, where souls climb out of the abyss.
static func spawns(stage_number: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	points.append_array(EAST_SPAWNS)
	for i in BRIDGES.size():
		if not is_broken(stage_number, i):
			points.append(Vector2(BRIDGES[i].y - BRIDGE_END_SPAWN, BRIDGES[i].z))
	return points


## Camp id -> point: the revived Karthus at his altar in 6-2, Hecarim at the
## east end in 6-4.
static func camp_points(stage_number: int) -> Dictionary:
	match stage_number:
		2:
			return {&"karthus_revived": KARTHUS_ALTAR}
		4:
			return {&"hecarim": HECARIM_CAMP}
	return {}


## 6-5: the disc, then its four stubs, each running onto it.
static func platform() -> Array[PackedVector2Array]:
	var disc := PackedVector2Array()
	for i in PLATFORM_SIDES:
		disc.append(PLATFORM_CENTER + Vector2.from_angle(TAU * i / PLATFORM_SIDES) * PLATFORM_RADIUS)
	var found: Array[PackedVector2Array] = [_piece(disc)]
	for i in STUB_DIRECTIONS.size():
		var along := STUB_DIRECTIONS[i]
		var side := along.orthogonal() * STUB_WIDTH * 0.5
		var from := PLATFORM_CENTER + along * (PLATFORM_RADIUS - BRIDGE_OVERLAP)
		var to := stub_end(i)
		found.append(_piece(PackedVector2Array([from + side, to + side, to - side, from - side])))
	return found


## Where stub `i` breaks off over the abyss.
static func stub_end(i: int) -> Vector2:
	return PLATFORM_CENTER + STUB_DIRECTIONS[i] * (PLATFORM_RADIUS + STUB_LENGTHS[i])


## 6-5's spawn points: one on each of SPAWN_STUBS, back from its broken end.
static func stub_spawns() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for i in SPAWN_STUBS:
		points.append(stub_end(i) - STUB_DIRECTIONS[i] * STUB_SPAWN_BACK)
	return points


## The map less `ground_pieces`: the area cut in two along MID_Y, then each
## piece of ground cut out in turn. A plateau or the platform crosses MID_Y,
## and a bridge or a stub runs onto ground cut before it, so every cut bites
## a piece's edge or splits it, and no piece is left with a hole.
static func abyss(ground_pieces: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var pieces: Array[PackedVector2Array] = [
		_rect_polygon(Rect2(0, 0, MAP_SIZE.x, MID_Y)),
		_rect_polygon(Rect2(0, MID_Y, MAP_SIZE.x, MAP_SIZE.y - MID_Y)),
	]
	for open in ground_pieces:
		pieces = _carve(pieces, open)
	return pieces


static func _cut_corners(rect: Rect2, cut: float) -> PackedVector2Array:
	var low := rect.position
	var high := rect.end
	return _piece(PackedVector2Array([
		Vector2(low.x + cut, low.y), Vector2(high.x - cut, low.y), Vector2(high.x, low.y + cut), Vector2(high.x, high.y - cut),
		Vector2(high.x - cut, high.y), Vector2(low.x + cut, high.y), Vector2(low.x, high.y - cut), Vector2(low.x, low.y + cut),
	]))


## A band from x `from_x` to `to_x` along `y`, `width` wide.
static func _span(from_x: float, to_x: float, y: float, width: float) -> Rect2:
	return Rect2(from_x, y - width * 0.5, to_x - from_x, width)




## One bridge, or what is left of one (or a platform's stub): where it
## leaves its ground, where it ends, how wide it is, and whether it breaks off
## at `to`.
class Span:
	extends RefCounted

	var from: Vector2
	var to: Vector2
	var width: float
	var broken: bool


	func _init(from_point: Vector2, to_point: Vector2, wide: float, breaks: bool) -> void:
		from = from_point
		to = to_point
		width = wide
		broken = breaks


## The souls far below and a few motes over the ground, in teal.
func build_ambience() -> MapAmbience:
	var ambience := MapAmbience.new()
	var dice := MapArt.rng(67)
	ambience.add(MapAmbience.Kind.FIREFLY, MapArt.scatter(dice, get_bounds(), SOUL_TRIES, _over_abyss), SOUL_COLOR, dice)
	ambience.add(MapAmbience.Kind.DUST, MapArt.scatter(dice, get_bounds().grow(-MapAmbience.DUST_REACH * 0.5), MOTE_TRIES), MOTE_COLOR, dice)
	return ambience


## The bridges as spans: whole ones, the stubs left of the broken one, or the
## platform's four stubs.
func _spans() -> Array[Span]:
	var found: Array[Span] = []
	if stage == FINAL_STAGE:
		for i in STUB_DIRECTIONS.size():
			found.append(Span.new(PLATFORM_CENTER + STUB_DIRECTIONS[i] * PLATFORM_RADIUS, stub_end(i), STUB_WIDTH, true))
		return found
	var width := bridge_width(stage)
	for i in BRIDGES.size():
		var west := Vector2(BRIDGES[i].x, BRIDGES[i].z)
		var east := Vector2(BRIDGES[i].y, BRIDGES[i].z)
		if is_broken(stage, i):
			found.append(Span.new(west, west + Vector2(BROKEN_STUB, 0), width, true))
			found.append(Span.new(east, east - Vector2(BROKEN_STUB, 0), width, true))
		else:
			found.append(Span.new(west, east, width, false))
	return found


## Whether `point` is over the abyss, not on any ground.
func _over_abyss(point: Vector2) -> bool:
	for piece in ground:
		if Geometry2D.is_point_in_polygon(point, piece):
			return false
	return true


func _draw() -> void:
	if stage == FINAL_STAGE:
		_draw_platform()
	else:
		_draw_plateaus()
	MapArt.vignette(self, get_bounds(), VIGNETTE_DEPTH, VIGNETTE_ALPHA)
	_draw_lights()


## Stages 1 to 4, far to near: the rocks and ledges in the abyss, the
## bridges, the plateaus, the chains, the camps and the spikes.
func _draw_plateaus() -> void:
	var deep := MapArt.Facets.new()
	var dice := MapArt.rng(71)
	for rock in ABYSS_ROCKS:
		MapArt.rock(deep, dice, Vector2(rock.x, rock.y), rock.z, ROCK.darkened(DEEP_ROCK_DARK))
	deep.draw(self)
	for ledge in ledge_points:
		_draw_ledge(ledge)
	for span in _spans():
		_draw_causeway(span)
	if is_broken(stage, BROKEN_BRIDGE):
		var gap := BRIDGES[BROKEN_BRIDGE]
		_draw_rubble(Vector2((gap.x + gap.y) * 0.5, gap.z), bridge_width(stage))
	var plateau_list := plateaus()
	for i in plateau_list.size():
		_draw_plateau(plateau_list[i], 71 + i)
	var chains := MapArt.Facets.new()
	for chain in CHAINS:
		var from := Vector2(chain.x, chain.y)
		var to := Vector2(chain.z, chain.w)
		_chain(chains, from, to)
		_bolt_down(chains, from, to)
		_bolt_down(chains, to, from)
	chains.draw(self)
	if camps.has(&"karthus_revived"):
		_draw_altar(camps[&"karthus_revived"])
	if camps.has(&"hecarim"):
		_draw_camp(camps[&"hecarim"])
	_draw_spikes()


## Under the ground: the abyss's near black, past the map's edges too, then
## its layers of mist, and chains hanging far below.
func _draw_depths(depths: Node2D) -> void:
	depths.draw_rect(get_bounds().grow(MapArt.OUTSIDE_REACH), ABYSS_COLOR)
	var area := get_bounds().grow(WALL_THICKNESS * 2.0)
	MapArt.patches(depths, MapArt.rng(61), area, HAZE_PATCHES, HAZE_RADIUS, Color(MIST_COLOR, HAZE_ALPHA), Color(MapArt.SHADOW, MURK_ALPHA))
	var far := MapArt.Facets.new()
	var dice := MapArt.rng(62)
	for i in FAR_CHAINS:
		var from := area.position + Vector2(dice.randf(), dice.randf()) * area.size
		_chain(far, from, from + Vector2.from_angle(dice.randf() * TAU) * dice.randf_range(FAR_CHAIN_SPAN.x, FAR_CHAIN_SPAN.y), 0.6, FAR_CHAIN_FADE)
	far.draw(depths)
	MapArt.patches(depths, MapArt.rng(63), area, NEAR_PATCHES, NEAR_RADIUS, Color(MIST_COLOR, HAZE_ALPHA * 0.8), Color(MapArt.SHADOW, MURK_ALPHA))


## A swirl of mist: a soft heart and arms winding out from it, fading at
## both ends. Drawn once; it turns as a whole.
func _draw_swirl(swirl: Node2D, radius: float) -> void:
	swirl.draw_circle(Vector2.ZERO, radius * 0.4, Color(MIST_COLOR, SWIRL_ALPHA * 0.4))
	for arm in SWIRL_ARMS:
		var points := PackedVector2Array()
		var colors := PackedColorArray()
		for i in SWIRL_POINTS:
			var t := float(i) / (SWIRL_POINTS - 1)
			points.append(Vector2.from_angle(TAU * arm / SWIRL_ARMS + t * SWIRL_TURN) * radius * (0.15 + 0.85 * t))
			colors.append(Color(MIST_COLOR, SWIRL_ALPHA * sin(PI * t)))
		swirl.draw_polyline_colors(points, colors, radius * SWIRL_WIDTH, true)


## A slate plateau: the shadow its edge casts into the abyss, its cliff, its
## flagstones, patches, cracks and pebbles, and the lit lip.
func _draw_plateau(polygon: PackedVector2Array, seed_number: int) -> void:
	var dice := MapArt.rng(seed_number)
	var box := MapArt.bounds_of(polygon)
	var low := _shifted(polygon, Vector2(0, CLIFF_DEPTH))
	MapArt.cast_shadow(self, low, EDGE_SHADOW, 0.35)
	draw_colored_polygon(low, CLIFF_LOW)
	draw_colored_polygon(_shifted(polygon, Vector2(0, CLIFF_DEPTH * 0.55)), CLIFF_MID)
	var strata := MapArt.Facets.new()
	for i in polygon.size():
		if MapArt.inward(polygon, i).y < -0.3:
			for at in MapArt.along_edge(polygon, i, CLIFF_CRACK_STEP, 0.0):
				strata.line(at, at + Vector2(dice.randf_range(-4.0, 4.0), CLIFF_DEPTH * dice.randf_range(0.5, 0.95)), 3.0, Color(CLIFF_LOW, 0.7))
	strata.draw(self)
	_draw_flagstones(box, dice)
	var wear := MapArt.Facets.new()
	var area := box.get_area()
	var keep := is_walkable.bind(CRACK_KEEP)
	for at in MapArt.scatter(dice, box, ceili(area * CRACKS_PER_AREA), keep):
		MapArt.crack(wear, dice, at, dice.randf_range(30.0, 80.0), 2.0, CRACK_DARK)
	for at in MapArt.scatter(dice, box, ceili(area * GLOW_CRACKS_PER_AREA), keep):
		var shape := dice.randi()
		var length := dice.randf_range(40.0, 90.0)
		MapArt.crack(wear, MapArt.rng(shape), at, length, 8.0, CRACK_GLOW)
		MapArt.crack(wear, MapArt.rng(shape), at, length, 2.0, CRACK_CORE)
	for at in MapArt.scatter(dice, box, ceili(area * PATCHES_PER_AREA), is_walkable.bind(PATCH_RADIUS.y)):
		var radius := dice.randf_range(PATCH_RADIUS.x, PATCH_RADIUS.y)
		var tint := Color(SLATE.lightened(0.18), 0.3) if dice.randf() < 0.5 else Color(SLATE.darkened(0.4), 0.35)
		MapArt.soft_oval(self, at, Vector2(radius * dice.randf_range(1.0, 1.4), radius), tint)
	wear.draw(self)
	for at in MapArt.scatter(dice, box, ceili(area * PEBBLES_PER_AREA), is_walkable.bind(40.0)):
		MapArt.pebble(self, dice, at, dice.randf_range(3.0, 7.0), SLATE.lightened(0.12))
	for ring in Geometry2D.offset_polygon(polygon, -14.0):
		_draw_outline(ring, SLATE_JOINT, 4.0)
	MapArt.rim(self, polygon, SLATE_EDGE, CLIFF_LOW, 6.0)


## A plateau's slabs: its box less the corners is two boxes crossed, each
## paved on the same square grid so the joints run on across.
func _draw_flagstones(box: Rect2, dice: RandomNumberGenerator) -> void:
	var parts: Array[Rect2] = [
		Rect2(box.position.x + CORNER_CUT, box.position.y, box.size.x - CORNER_CUT * 2.0, box.size.y),
		Rect2(box.position.x, box.position.y + CORNER_CUT, CORNER_CUT, box.size.y - CORNER_CUT * 2.0),
		Rect2(box.end.x - CORNER_CUT, box.position.y + CORNER_CUT, CORNER_CUT, box.size.y - CORNER_CUT * 2.0),
	]
	for part in parts:
		MapArt.tiles(self, dice, part, SLAB, SLATE, SLATE_JOINT, SLAB_SHADE, SLAB_JOINT, 0.0)


## `polygon` moved by `by`.
static func _shifted(polygon: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var moved := PackedVector2Array()
	for point in polygon:
		moved.append(point + by)
	return moved


## A stone causeway: its shadow in the abyss, fitted paving, curbs along
## both edges, its soul lanterns, and a jagged end where it is broken. Its
## base runs on under the ground at `from` (and at its far end when whole).
func _draw_causeway(span: Span) -> void:
	var along := span.from.direction_to(span.to)
	var side := along.orthogonal() * span.width * 0.5
	var curb := side.normalized() * CURB
	var start := span.from - along * BRIDGE_OVERLAP
	var end := span.to if span.broken else span.to + along * BRIDGE_OVERLAP
	var deck := PackedVector2Array([start + side, end + side, end - side, start - side])
	var dice := MapArt.rng(hash(span.from))
	MapArt.cast_shadow(self, deck, BRIDGE_SHADOW)
	var tile := PAVING if absf(along.x) > 0.5 else Vector2(PAVING.y, PAVING.x)
	MapArt.tiles(self, dice, MapArt.bounds_of(deck), tile, STONE, STONE_JOINT, 0.05, 3.0)
	var marks := MapArt.Facets.new()
	for way: float in [-1.0, 1.0]:
		var edge := side * way
		var inner := curb * way
		marks.quad(start + edge, end + edge, end + edge - inner, start + edge - inner, STONE.lightened(0.1))
		marks.line(start + edge - inner, end + edge - inner, 2.5, Color(MapArt.SHADOW, 0.45))
	var length := span.from.distance_to(span.to)
	for at in MapArt.scatter_band(dice, span.from, span.to, span.width * 0.5 - CURB - 6.0, ceili(length / 60.0)):
		MapArt.crack(marks, dice, at, dice.randf_range(14.0, 30.0), 2.0, CRACK_DARK)
	marks.draw(self)
	MapArt.rim(self, deck, STONE_EDGE, CLIFF_LOW, 4.0)
	if span.broken:
		var teeth := PackedVector2Array([end + side])
		for k in 5:
			teeth.append(end + side - side * 2.0 * (k + 0.5) / 5.0 + along * (16.0 if k % 2 == 0 else 5.0))
		teeth.append(end - side)
		draw_colored_polygon(teeth, STONE.darkened(0.1))
		_draw_outline(teeth, CLIFF_LOW, 3.0)
	for at in _lantern_spots(span):
		_draw_lantern(at)


## Where a causeway's soul lanterns stand: LANTERN_GAP apart along both
## curbs, none near its ends.
static func _lantern_spots(span: Span) -> PackedVector2Array:
	var along := span.from.direction_to(span.to)
	var side := along.orthogonal() * span.width * 0.5
	var length := span.from.distance_to(span.to)
	var spots := PackedVector2Array()
	var step := LANTERN_INSET
	while step <= length - LANTERN_INSET:
		for way: float in [-1.0, 1.0]:
			spots.append(span.from + along * step + side * way * 0.8)
		step += LANTERN_GAP
	return spots


## A soul lantern's post: its shadow, an iron base and the flame's cage. Its
## light is drawn last (_draw_lights).
func _draw_lantern(at: Vector2) -> void:
	MapArt.disc(self, at + MapArt.SHADOW_DIR * 5.0, 9.0, Color(MapArt.SHADOW, 0.5))
	MapArt.disc(self, at, 10.0, LANTERN_POST.lightened(0.25))
	MapArt.disc(self, at + MapArt.SHADOW_DIR * 1.5, 8.0, LANTERN_POST)
	MapArt.disc(self, at, 4.5, LANTERN_FLAME)


## Blocks of the broken bridge, fallen into the dark under its gap.
func _draw_rubble(at: Vector2, width: float) -> void:
	var dice := MapArt.rng(29)
	var blocks := MapArt.Facets.new()
	for i in RUBBLE_BLOCKS:
		var middle := at + Vector2(dice.randf_range(-120.0, 120.0), dice.randf_range(-width, width) * 0.5)
		var half := dice.randf_range(14.0, 26.0)
		var turn := dice.randf() * TAU
		var block := PackedVector2Array()
		for corner in 4:
			block.append(middle + Vector2.from_angle(turn + TAU * corner / 4.0) * half)
		blocks.fan(block, STONE.darkened(0.6))
		blocks.line(block[0], block[1], 2.5, STONE.darkened(0.3))
	blocks.draw(self)


## A chain sagging from `from` to `to`, gathered into `into`: a dark line
## under it, then its links (one lying along it, the next turned across it)
## and an iron staple at each end. `scale` sizes the links, `fade` dims them
## all and `sag` is how far it hangs, as a share of its length.
static func _chain(into: MapArt.Facets, from: Vector2, to: Vector2, scale := 1.0, fade := 1.0, sag := CHAIN_SAG) -> void:
	var dark := Color(CHAIN_DARK, fade)
	var iron := Color(CHAIN_COLOR, fade)
	var shine := Color(CHAIN_SHINE, fade)
	var bend := (from + to) * 0.5 + Vector2(0, from.distance_to(to) * sag)
	var links := maxi(ceili(from.distance_to(to) * 1.05 / (CHAIN_LINK * scale)), 2)
	var points := PackedVector2Array()
	for i in links + 1:
		var t := float(i) / links
		points.append(from.lerp(bend, t).lerp(bend.lerp(to, t), t))
	for i in links:
		into.line(points[i], points[i + 1], 8.0 * scale, dark)
	for i in links:
		if i % 2 == 0:
			into.line(points[i], points[i + 1], 4.0 * scale, iron)
			continue
		var middle := (points[i] + points[i + 1]) * 0.5
		var along := points[i].direction_to(points[i + 1])
		for share: float in [1.0, 0.5]:
			var ring := PackedVector2Array()
			for corner in 6:
				var turn := TAU * corner / 6.0
				ring.append(middle + along * cos(turn) * CHAIN_LINK * 0.6 * scale * share + along.orthogonal() * sin(turn) * CHAIN_LINK * 0.4 * scale * share)
			into.fan(ring, shine if share == 1.0 else dark)
	for end: Vector2 in [from, to]:
		into.fan(_hexagon(end, 10.0 * scale), dark)
		into.fan(_hexagon(end, 4.0 * scale), shine)


static func _hexagon(at: Vector2, radius: float) -> PackedVector2Array:
	var outline := PackedVector2Array()
	for corner in 6:
		outline.append(at + Vector2.from_angle(TAU * corner / 6.0) * radius)
	return outline


## Where a chain meets a plateau (`end` is on its stone, at its edge, the
## chain coming from `other`) it is bolted down: an iron plate, and the
## chain runs on over the stone, as far as there is room.
func _bolt_down(into: MapArt.Facets, end: Vector2, other: Vector2) -> void:
	var anchored := false
	for piece in ground.slice(0, PLATEAUS.size()):
		anchored = anchored or (Geometry2D.is_point_in_polygon(end, piece) and MapArt.edge_distance(end, piece) < ANCHOR_REACH)
	if not anchored:
		return
	var way := other.direction_to(end)
	var length := BOLTED_LENGTH
	while length > 0.0 and not is_walkable(end + way * length, 30.0):
		length -= 30.0
	if length > 0.0:
		_chain(into, end, end + way * length, BOLTED_SCALE, 0.85, 0.0)
	var half := way * PLATE_SIZE * 0.5
	var side := way.orthogonal() * PLATE_SIZE * 0.5
	into.quad(end - half - side, end + half - side, end + half + side, end - half + side, CHAIN_DARK)
	into.quad(end - half * 0.8 - side * 0.8, end + half * 0.8 - side * 0.8, end + half * 0.8 + side * 0.8, end - half * 0.8 + side * 0.8, CHAIN_COLOR)
	for corner: Vector2 in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
		into.fan(_hexagon(end + half * corner.x * 0.55 + side * corner.y * 0.55, 3.0), CHAIN_SHINE)


## The rock spikes on the plateaus, for cover: each one's shadow, then its
## faces.
func _draw_spikes() -> void:
	var dice := MapArt.rng(73)
	var rocks := MapArt.Facets.new()
	for spike in wall_circles:
		MapArt.round_shadow(self, Vector2(spike.x, spike.y), spike.z, SPIKE_HEIGHT)
	for spike in wall_circles:
		MapArt.rock(rocks, dice, Vector2(spike.x, spike.y), spike.z, ROCK)
	rocks.draw(self)


## A small rock island: its cliff side below it, a flat top of slate worn
## lighter in the middle with joints and a crack, and a lit lip, so a Warden
## plainly stands on stone.
func _draw_ledge(at: Vector2) -> void:
	var dice := MapArt.rng(hash(at))
	var top := PackedVector2Array()
	for i in LEDGE_SIDES:
		top.append(at + Vector2.from_angle(TAU * i / LEDGE_SIDES) * LEDGE_RADIUS * dice.randf_range(0.88, 1.0))
	draw_colored_polygon(_shifted(top, Vector2(0, LEDGE_FACE)), CLIFF_LOW)
	draw_colored_polygon(_shifted(top, Vector2(0, LEDGE_FACE * 0.55)), CLIFF_MID)
	draw_colored_polygon(top, SLATE)
	for ring in Geometry2D.offset_polygon(top, -LEDGE_WORN):
		draw_colored_polygon(ring, SLATE.lightened(0.06))
	var marks := MapArt.Facets.new()
	for i in LEDGE_JOINTS:
		var turn := Vector2.from_angle(dice.randf() * PI)
		marks.line(at + turn * LEDGE_RADIUS * 0.8, at - turn * LEDGE_RADIUS * 0.8, 3.0, SLATE_JOINT)
	MapArt.crack(marks, dice, at + Vector2(dice.randf_range(-30.0, 30.0), dice.randf_range(-30.0, 30.0)), 60.0, 2.0, CRACK_DARK)
	marks.draw(self)
	MapArt.rim(self, top, SLATE_EDGE, CLIFF_LOW, 5.0)


## 6-2: the revived Karthus's broken altar: a plinth, a cracked slab with a
## corner knocked off (the chunk lying beside it), glowing green in its cracks.
func _draw_altar(at: Vector2) -> void:
	var dice := MapArt.rng(83)
	var turn := 0.2
	var corners: Array[Vector2] = []
	var plinth := PackedVector2Array()
	for i in 4:
		var corner := Vector2(1 if i in [1, 2] else -1, 1 if i >= 2 else -1) * ALTAR_SIZE * 0.5
		corners.append(at + corner.rotated(turn))
		plinth.append(at + corner.rotated(turn) * ALTAR_PLINTH)
	var broken := corners[1]
	var cut_a := broken.lerp(corners[0], 0.35)
	var cut_b := broken.lerp(corners[2], 0.35)
	var slab := PackedVector2Array([corners[0], cut_a, cut_b, corners[2], corners[3]])
	MapArt.cast_shadow(self, plinth, ALTAR_HEIGHT * 0.5)
	draw_colored_polygon(plinth, ALTAR_COLOR.darkened(0.45))
	MapArt.rim(self, plinth, ALTAR_COLOR.lightened(0.1), CLIFF_LOW, 3.0)
	MapArt.cast_shadow(self, slab, ALTAR_HEIGHT)
	draw_colored_polygon(slab, ALTAR_COLOR)
	for ring in Geometry2D.offset_polygon(slab, -10.0):
		draw_colored_polygon(ring, ALTAR_COLOR.lightened(0.07))
	MapArt.rim(self, slab, ALTAR_COLOR.lightened(0.4), ALTAR_COLOR.darkened(0.5), 4.0)
	var away := at.direction_to(broken) * 30.0
	var chunk := PackedVector2Array([cut_a + away, broken + away, cut_b + away])
	MapArt.cast_shadow(self, chunk, ALTAR_HEIGHT * 0.4)
	draw_colored_polygon(chunk, ALTAR_COLOR.darkened(0.2))
	MapArt.rim(self, chunk, ALTAR_COLOR.lightened(0.3), ALTAR_COLOR.darkened(0.5), 3.0)
	var cracks := MapArt.Facets.new()
	for i in ALTAR_CRACKS:
		var shape := dice.randi()
		var start := at + Vector2(dice.randf_range(-40.0, 40.0), dice.randf_range(-40.0, 40.0))
		MapArt.crack(cracks, MapArt.rng(shape), start, 70.0, 7.0, CRACK_GLOW)
		MapArt.crack(cracks, MapArt.rng(shape), start, 70.0, 2.0, CRACK_CORE)
	cracks.draw(self)


## 6-4: Hecarim rides in from the east end: scorched ground, green-burnt
## hoofprints from the plateau's edge to his camp, and iron stakes ringing it,
## chained.
func _draw_camp(at: Vector2) -> void:
	var dice := MapArt.rng(79)
	var from := Vector2(PLATEAUS[2].end.x - 40.0, at.y)
	for spot in MapArt.scatter_band(dice, from, at, 40.0, SCORCH_PATCHES, is_walkable.bind(20.0)):
		MapArt.soft_oval(self, spot, Vector2(dice.randf_range(60.0, 110.0), dice.randf_range(36.0, 70.0)), SCORCH)
	for i in SCORCH_PATCHES:
		var spot := at + Vector2.from_angle(dice.randf() * TAU) * dice.randf() * SCORCH_REACH
		MapArt.soft_oval(self, spot, Vector2(dice.randf_range(60.0, 110.0), dice.randf_range(36.0, 70.0)), SCORCH)
	var marks := MapArt.Facets.new()
	var x := from.x
	var row := 0
	while x > at.x - 120.0:
		var mark := Vector2(x, at.y + (22.0 if row % 2 == 0 else -22.0))
		marks.arc(mark, 10.0, PI * 0.15 - PI * 0.5, PI * 1.85 - PI * 0.5, 4.0, HOOF_COLOR, 8)
		x -= 45.0
		row += 1
	var stakes: Array[Vector2] = []
	for i in STAKES:
		var stake := at + Vector2.from_angle(TAU * i / STAKES + 0.3) * STAKE_RING
		if is_walkable(stake, 20.0):
			stakes.append(stake)
	for i in stakes.size() - 1:
		_chain(marks, stakes[i], stakes[i + 1], 0.45, 0.9, 0.04)
	marks.draw(self)
	for stake in stakes:
		MapArt.disc(self, stake + MapArt.SHADOW_DIR * 4.0, 7.0, Color(MapArt.SHADOW, 0.5))
		MapArt.disc(self, stake, 7.0, LANTERN_POST.lightened(0.3))
		MapArt.disc(self, stake, 3.0, CHAIN_SHINE)


## 6-5: the stubs, then the carved disc over their ends: its cliff, masonry
## in rings, carved grooves, the rune ring, chains rising at the rim and the
## pale dais where Thresh stands.
func _draw_platform() -> void:
	var middle := PLATFORM_CENTER
	var disc := ground[0]
	var dice := MapArt.rng(87)
	var deep := MapArt.Facets.new()
	for i in RIM_CHAINS:
		var direction := Vector2.from_angle(TAU * (i + 0.5) / RIM_CHAINS)
		MapArt.rock(deep, dice, middle + direction * (PLATFORM_RADIUS + RIM_CHAIN_REACH), 50.0, ROCK.darkened(DEEP_ROCK_DARK))
	deep.draw(self)
	for span in _spans():
		_draw_causeway(span)
	MapArt.disc(self, middle + MapArt.SHADOW_DIR * PLATFORM_SHADOW, PLATFORM_RADIUS, Color(MapArt.SHADOW, 0.3))
	draw_colored_polygon(_shifted(disc, Vector2(0, PLATFORM_CLIFF)), CLIFF_LOW)
	draw_colored_polygon(_shifted(disc, Vector2(0, PLATFORM_CLIFF * 0.55)), CLIFF_MID)
	draw_colored_polygon(disc, PLATFORM_JOINT)
	MapArt.disc(self, middle, CARVED_RINGS[0], PLATFORM_STONE.darkened(0.15))
	_draw_masonry(middle)
	var wear := MapArt.Facets.new()
	var near := func(point: Vector2) -> bool: return point.distance_to(middle) < PLATFORM_RADIUS - CRACK_KEEP
	var box := Rect2(middle - Vector2.ONE * PLATFORM_RADIUS, Vector2.ONE * PLATFORM_RADIUS * 2.0)
	for at in MapArt.scatter(dice, box, PLATFORM_PATCHES, near):
		var radius := dice.randf_range(PATCH_RADIUS.x, PATCH_RADIUS.y)
		var tint := Color(PLATFORM_STONE.lightened(0.18), 0.25) if dice.randf() < 0.5 else Color(PLATFORM_STONE.darkened(0.4), 0.3)
		MapArt.soft_oval(self, at, Vector2(radius * dice.randf_range(1.0, 1.4), radius), tint)
	for at in MapArt.scatter(dice, box, PLATFORM_CRACKS, near):
		MapArt.crack(wear, dice, at, dice.randf_range(30.0, 80.0), 2.0, CRACK_DARK)
	for at in MapArt.scatter(dice, box, PLATFORM_GLOW_CRACKS, near):
		var shape := dice.randi()
		var length := dice.randf_range(40.0, 90.0)
		MapArt.crack(wear, MapArt.rng(shape), at, length, 8.0, CRACK_GLOW)
		MapArt.crack(wear, MapArt.rng(shape), at, length, 2.0, CRACK_CORE)
	for ring in CARVED_RINGS:
		wear.arc(middle, ring, 0.0, TAU, 7.0, CARVE_COLOR, PLATFORM_SIDES)
		wear.arc(middle, ring + 6.0, 0.0, TAU, 2.0, Color(1, 1, 1, 0.06), PLATFORM_SIDES)
	_draw_runes(wear, dice)
	wear.draw(self)
	var lit_from := MapArt.SHADOW_DIR.angle() + PI
	draw_arc(middle, PLATFORM_RADIUS - 3.0, lit_from - PI * 0.5, lit_from + PI * 0.5, PLATFORM_SIDES, SLATE_EDGE, 6.0, true)
	draw_arc(middle, PLATFORM_RADIUS - 3.0, lit_from + PI * 0.5, lit_from + PI * 1.5, PLATFORM_SIDES, CLIFF_LOW, 6.0, true)
	var chains := MapArt.Facets.new()
	for i in RIM_CHAINS:
		var direction := Vector2.from_angle(TAU * (i + 0.5) / RIM_CHAINS)
		_chain(chains, middle + direction * (PLATFORM_RADIUS - 30.0), middle + direction * (PLATFORM_RADIUS + RIM_CHAIN_REACH))
	chains.draw(self)
	_draw_dais(middle)


## The stone of the disc in courses of slabs between the carved rings, each
## course's joints set half a slab off the one before; the rune band darker,
## the rim's coping lighter, all a little lighter toward the middle. One mesh.
func _draw_masonry(middle: Vector2) -> void:
	var dice := MapArt.rng(89)
	var slabs := MapArt.Facets.new()
	var edges: Array[float] = []
	edges.assign(CARVED_RINGS)
	edges.append(PLATFORM_RADIUS)
	for band in COURSES.size():
		var tint := 0.0
		if band == COURSES.size() - 2:
			tint = -RUNE_BAND_SHADE
		elif band == COURSES.size() - 1:
			tint = COPING_SHADE
		for course in COURSES[band]:
			var inner := lerpf(edges[band], edges[band + 1], float(course) / COURSES[band]) + COURSE_JOINT * 0.5
			var outer := lerpf(edges[band], edges[band + 1], float(course + 1) / COURSES[band]) - COURSE_JOINT * 0.5
			var count := maxi(roundi(TAU * (inner + outer) * 0.5 / COURSE_SLAB), 6)
			var turn := dice.randf() * TAU
			for k in count:
				var from := turn + TAU * k / count + COURSE_JOINT * 0.5 / inner
				var to := turn + TAU * (k + 1) / count - COURSE_JOINT * 0.5 / inner
				var shade := tint + dice.randf_range(-COURSE_SHADE, COURSE_SHADE) + 0.08 * (1.0 - inner / PLATFORM_RADIUS)
				slabs.quad(middle + Vector2.from_angle(from) * inner, middle + Vector2.from_angle(to) * inner,
					middle + Vector2.from_angle(to) * outer, middle + Vector2.from_angle(from) * outer,
					PLATFORM_STONE.lightened(shade) if shade > 0.0 else PLATFORM_STONE.darkened(-shade))
	slabs.draw(self)


## Runes round the ring between the outer carved rings, each a few glowing
## strokes, standing along the ring (their light is drawn last).
func _draw_runes(into: MapArt.Facets, dice: RandomNumberGenerator) -> void:
	for i in RUNES:
		var out := Vector2.from_angle(TAU * i / RUNES)
		var along := out.orthogonal()
		var at := PLATFORM_CENTER + out * RUNE_RING
		into.line(at + out * 34.0, at - out * 34.0, 12.0, RUNE_GLOW)
		into.line(at + out * 34.0, at - out * 34.0, 4.0, RUNE_COLOR)
		for stroke in 2:
			var from := at + out * dice.randf_range(-30.0, 30.0)
			into.line(from, from + along * dice.randf_range(-24.0, 24.0) + out * dice.randf_range(-16.0, 16.0), 4.0, RUNE_COLOR)


## The pale dais where Thresh stands: a lit step, the stone, an inlaid ring
## of runes and a star.
func _draw_dais(middle: Vector2) -> void:
	var radius := CARVED_RINGS[0] - 30.0
	MapArt.disc(self, middle + MapArt.SHADOW_DIR * 10.0, radius + 6.0, Color(MapArt.SHADOW, 0.4))
	MapArt.disc(self, middle, radius + 6.0, HEART_COLOR.lightened(0.28))
	MapArt.disc(self, middle + MapArt.SHADOW_DIR * 3.0, radius + 3.0, HEART_COLOR.darkened(0.35))
	MapArt.disc(self, middle, radius - 2.0, HEART_COLOR)
	MapArt.disc(self, middle - MapArt.SHADOW_DIR * radius * 0.08, radius * 0.8, HEART_COLOR.lightened(0.06))
	var inlay := MapArt.Facets.new()
	inlay.arc(middle, radius * 0.72, 0.0, TAU, 3.0, RUNE_COLOR, PLATFORM_SIDES)
	for i in 8:
		var way := Vector2.from_angle(TAU * i / 8.0)
		inlay.blade(middle + way * radius * 0.1, middle + way * DAIS_STAR_REACH * (1.0 if i % 2 == 0 else 0.6), 22.0 if i % 2 == 0 else 14.0, Color(RUNE_COLOR, 0.16))
	inlay.draw(self)


## A closed outline of `polygon`.
func _draw_outline(polygon: PackedVector2Array, color: Color, width: float) -> void:
	var loop := polygon.duplicate()
	loop.append(polygon[0])
	draw_polyline(loop, color, width, true)


## Over everything else: the lanterns' pools of cold green light and their
## flames; mist curling over the cliffs' lips; the camps' glow; on the
## platform, the runes' faint teal and the dais's light.
func _draw_lights() -> void:
	if stage == FINAL_STAGE:
		MapArt.glow(self, PLATFORM_CENTER, DAIS_POOL, Color(RUNE_COLOR, 0.07))
		for i in RUNES:
			MapArt.glow(self, PLATFORM_CENTER + Vector2.from_angle(TAU * i / RUNES) * RUNE_RING, RUNE_POOL, RUNE_GLOW)
	else:
		for piece in ground.slice(0, PLATEAUS.size()):
			for at in MapArt.along(piece, LIP_MIST_STEP):
				MapArt.soft_oval(self, at, Vector2(LIP_MIST_RADIUS, LIP_MIST_RADIUS * 0.6), Color(MIST_COLOR, LIP_MIST_ALPHA))
		for camp: Vector2 in camps.values():
			MapArt.glow(self, camp, CAMP_POOL, Color(MIST_COLOR, 0.08))
	var lanterns := PackedVector2Array()
	for span in _spans():
		lanterns.append_array(_lantern_spots(span))
	for at in lanterns:
		MapArt.glow(self, at, LANTERN_POOL, LANTERN_GLOW)
	for at in lanterns:
		MapArt.glow(self, at, 26.0, Color(LANTERN_GLOW, 0.35))
		MapArt.glow(self, at, 8.0, Color(LANTERN_FLAME, 0.9))
