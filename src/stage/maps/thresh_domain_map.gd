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
## Waves come from the east end of the east plateau and the far ends of the
## bridges. 6-2 has the revived Karthus's broken altar on the east plateau,
## 6-4 Hecarim's camp at its east end. 6-5 is the final platform: a carved
## stone disc with a rune ring and chains at its rim, Thresh at its center,
## four bridge stubs (the spawn points) and no walls.
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
## A stub's spawn point: this far back from its broken end.
const STUB_SPAWN_BACK := 110.0

# The art.
const ABYSS_COLOR := Color("040706")
const MIST_COLOR := Color(0.3, 0.85, 0.55)
## Haze patches lying in the abyss, and their alpha.
const HAZE_PATCHES := 40
const HAZE_ALPHA := 0.035
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
const SLATE := Color("2b3134")
const SLATE_DARK := Color("1c2124")
const SLATE_EDGE := Color("4f5a60")
## Paving slabs on the plateaus: their size, and how far their shade varies.
const SLAB := 120.0
const SLAB_SHADE := 0.06
const CRACK_GLOW := Color(0.35, 1.0, 0.6, 0.1)
const CRACK_CORE := Color(0.55, 1.0, 0.75, 0.3)
## Cracks per px² of a plateau's box.
const CRACKS_PER_AREA := 1.0 / 90000.0
const STONE := Color("47453f")
const STONE_JOINT := Color("34322e")
const STONE_EDGE := Color("29282a")
const PAVING := 46.0
const LANTERN_GAP := 150.0
## No lantern this close to a bridge's ends.
const LANTERN_INSET := 40.0
const LANTERN_POST := Color("121516")
const LANTERN_GLOW := Color(0.4, 1.0, 0.7, 0.16)
const LANTERN_FLAME := Color("b9ffd9")
const CHAIN_DARK := Color("15181a")
const CHAIN_COLOR := Color("3a3f43")
const CHAIN_SHINE := Color("666e73")
const CHAIN_LINK := 18.0
## How far a chain sags, as a share of its length.
const CHAIN_SAG := 0.12
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
const ROCK := Color("343b3f")
const ROCK_LIGHT := Color("59636a")
const ROCK_DARK := Color("161a1c")
## The platform: its stone, the carved rings (radius) and the rune ring
## between two of them, its runes, and the chains rising at its rim (how far
## out they run to their rocks).
const PLATFORM_STONE := Color("3a3f43")
const CARVE_COLOR := Color("23282b")
const CARVED_RINGS: Array[float] = [250.0, 600.0, 1050.0, 1250.0]
const RUNE_RING := 1150.0
const RUNES := 32
const RUNE_COLOR := Color(0.45, 1.0, 0.7, 0.45)
const RUNE_GLOW := Color(0.45, 1.0, 0.7, 0.1)
const RIM_CHAINS := 16
const RIM_CHAIN_REACH := 460.0
const ALTAR_COLOR := Color("5a6064")
const ALTAR_SIZE := 200.0
const HOOF_COLOR := Color(0.35, 1.0, 0.65, 0.22)

var stage := 1
## The walkable ground: the plateaus and the bridges (stages 1 to 4), or the
## platform and its stubs (6-5). The abyss is the rest.
var ground: Array[PackedVector2Array] = []

var _swirls: Array[Node2D] = []


func _init(stage_number := 1) -> void:
	stage = clampi(stage_number, 1, FINAL_STAGE)
	size = MAP_SIZE
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


## 6-5's spawn points: one on each stub, back from its broken end.
static func stub_spawns() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for i in STUB_DIRECTIONS.size():
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


func _draw() -> void:
	if stage == FINAL_STAGE:
		_draw_platform()
		return
	for rock in ABYSS_ROCKS:
		_draw_spike(Vector2(rock.x, rock.y), rock.z, true)
	for ledge in ledge_points:
		_draw_ledge(ledge)
	var width := bridge_width(stage)
	for i in BRIDGES.size():
		var bridge := BRIDGES[i]
		var west := Vector2(bridge.x, bridge.z)
		var east := Vector2(bridge.y, bridge.z)
		if is_broken(stage, i):
			_draw_causeway(west, west + Vector2(BROKEN_STUB, 0), width, true)
			_draw_causeway(east, east - Vector2(BROKEN_STUB, 0), width, true)
			_draw_rubble(west.lerp(east, 0.5), width)
		else:
			_draw_causeway(west, east, width, false)
	var plateau_list := plateaus()
	for i in plateau_list.size():
		_draw_plateau(plateau_list[i], 71 + i)
	for chain in CHAINS:
		_draw_chain(Vector2(chain.x, chain.y), Vector2(chain.z, chain.w))
	if camps.has(&"karthus_revived"):
		_draw_altar(camps[&"karthus_revived"])
	if camps.has(&"hecarim"):
		_draw_hoofmarks(camps[&"hecarim"])
	for spike in wall_circles:
		_draw_spike(Vector2(spike.x, spike.y), spike.z, false)


## Under the ground: the abyss's near black, past the map's edges too, with
## faint patches of green haze.
func _draw_depths(depths: Node2D) -> void:
	depths.draw_rect(get_bounds().grow(WALL_THICKNESS * 2.0), ABYSS_COLOR)
	var haze := RandomNumberGenerator.new()
	haze.seed = 61
	for i in HAZE_PATCHES:
		var at := Vector2(haze.randf_range(0.0, size.x), haze.randf_range(0.0, size.y))
		depths.draw_circle(at, haze.randf_range(200.0, 500.0), Color(MIST_COLOR, HAZE_ALPHA))


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


## A slate plateau: paving slabs, faint green cracks, and its cliff edge.
func _draw_plateau(polygon: PackedVector2Array, seed_number: int) -> void:
	var dice := RandomNumberGenerator.new()
	dice.seed = seed_number
	var box := _bounds_of(polygon)
	draw_colored_polygon(polygon, SLATE)
	var y := box.position.y + SLAB * 0.5
	while y < box.end.y:
		var x := box.position.x + SLAB * 0.5
		while x < box.end.x:
			var at := Vector2(x, y)
			var shade := dice.randf_range(-SLAB_SHADE, SLAB_SHADE)
			if Geometry2D.is_point_in_polygon(at, polygon) and _distance_to_edge(at, polygon) > SLAB * 0.5:
				var slab := SLATE.lightened(shade) if shade > 0.0 else SLATE.darkened(-shade)
				draw_rect(Rect2(at - Vector2.ONE * SLAB * 0.46, Vector2.ONE * SLAB * 0.92), slab)
			x += SLAB
		y += SLAB
	for i in ceili(box.get_area() * CRACKS_PER_AREA):
		_draw_crack(polygon, box, dice)
	for ring in Geometry2D.offset_polygon(polygon, -16.0):
		_draw_outline(ring, SLATE_DARK, 6.0)
	_draw_outline(polygon, SLATE_EDGE, 8.0)


## A crack glowing faintly green: a crooked line from a random spot well
## inside `polygon`, stopping before its edge.
func _draw_crack(polygon: PackedVector2Array, box: Rect2, dice: RandomNumberGenerator) -> void:
	var at := Vector2(dice.randf_range(box.position.x, box.end.x), dice.randf_range(box.position.y, box.end.y))
	var heading := dice.randf() * TAU
	var points := PackedVector2Array([at])
	for step in dice.randi_range(3, 6):
		heading += dice.randf_range(-0.7, 0.7)
		at += Vector2.from_angle(heading) * dice.randf_range(25.0, 60.0)
		if not Geometry2D.is_point_in_polygon(at, polygon) or _distance_to_edge(at, polygon) < 30.0:
			break
		points.append(at)
	if points.size() < 2 or not Geometry2D.is_point_in_polygon(points[0], polygon):
		return
	draw_polyline(points, CRACK_GLOW, 8.0, true)
	draw_polyline(points, CRACK_CORE, 2.0, true)


## A stone causeway from `from` (where it leaves its ground) to `to`, `width`
## wide: paving joints, curbs and soul lanterns along both edges. Its base
## runs on under the ground at `from` (and at `to` when whole); a broken one
## ends in jagged stone at `to`.
func _draw_causeway(from: Vector2, to: Vector2, width: float, broken: bool) -> void:
	var along := from.direction_to(to)
	var side := along.orthogonal() * width * 0.5
	var start := from - along * BRIDGE_OVERLAP
	var end := to if broken else to + along * BRIDGE_OVERLAP
	draw_colored_polygon(PackedVector2Array([start + side, end + side, end - side, start - side]), STONE)
	var length := from.distance_to(to)
	var step := PAVING
	while step < length:
		var at := from + along * step
		draw_line(at + side * 0.85, at - side * 0.85, STONE_JOINT, 2.0)
		step += PAVING
	draw_line(start + side, end + side, STONE_EDGE, 10.0)
	draw_line(start - side, end - side, STONE_EDGE, 10.0)
	if broken:
		var teeth := PackedVector2Array([end + side])
		for k in 5:
			teeth.append(end + side - side * 2.0 * (k + 0.5) / 5.0 + along * (16.0 if k % 2 == 0 else 5.0))
		teeth.append(end - side)
		draw_colored_polygon(teeth, STONE)
	step = LANTERN_INSET
	while step <= length - LANTERN_INSET:
		for way: float in [-1.0, 1.0]:
			_draw_lantern(from + along * step + side * way * 0.8)
		step += LANTERN_GAP


## A soul lantern on a post: a pale green flame and its glow.
func _draw_lantern(at: Vector2) -> void:
	draw_circle(at, 26.0, LANTERN_GLOW)
	draw_circle(at, 9.0, LANTERN_POST)
	draw_circle(at, 4.5, LANTERN_FLAME)


## Blocks of the broken bridge, fallen into the dark under its gap.
func _draw_rubble(at: Vector2, width: float) -> void:
	var dice := RandomNumberGenerator.new()
	dice.seed = 29
	for i in 7:
		var middle := at + Vector2(dice.randf_range(-120.0, 120.0), dice.randf_range(-width, width) * 0.5)
		var half := dice.randf_range(14.0, 26.0)
		var turn := dice.randf() * TAU
		var block := PackedVector2Array()
		for corner in 4:
			block.append(middle + Vector2.from_angle(turn + TAU * corner / 4.0) * half)
		draw_colored_polygon(block, STONE.darkened(0.6))


## A chain sagging from `from` to `to`, link by link, with an iron staple at
## each end.
func _draw_chain(from: Vector2, to: Vector2) -> void:
	var bend := (from + to) * 0.5 + Vector2(0, from.distance_to(to) * CHAIN_SAG)
	var links := maxi(ceili(from.distance_to(to) * 1.05 / CHAIN_LINK), 2)
	var points := PackedVector2Array()
	for i in links + 1:
		var t := float(i) / links
		points.append(from.lerp(bend, t).lerp(bend.lerp(to, t), t))
	draw_polyline(points, CHAIN_DARK, 8.0, true)
	for i in links:
		var middle := (points[i] + points[i + 1]) * 0.5
		if i % 2 == 0:
			draw_line(points[i], points[i + 1], CHAIN_COLOR, 4.0, true)
		else:
			draw_arc(middle, CHAIN_LINK * 0.45, 0.0, TAU, 10, CHAIN_SHINE, 2.5, true)
	for end: Vector2 in [from, to]:
		draw_circle(end, 10.0, CHAIN_DARK)
		draw_circle(end, 4.0, CHAIN_SHINE)


## A rock spike seen from above: a jagged star with a lit side and a tip.
## `deep` ones rise out of the abyss, darker.
func _draw_spike(at: Vector2, radius: float, deep: bool) -> void:
	var body := ROCK.darkened(0.35) if deep else ROCK
	draw_circle(at + Vector2(8, 10), radius, Color(ROCK_DARK, 0.8))
	draw_colored_polygon(_star(at, radius, 0.72), body)
	draw_colored_polygon(_star(at - Vector2.ONE * radius * 0.12, radius * 0.55, 0.7), ROCK_LIGHT.darkened(0.35) if deep else ROCK_LIGHT)
	draw_circle(at - Vector2.ONE * radius * 0.15, radius * 0.12, ROCK_LIGHT.lightened(0.3))


static func _star(at: Vector2, radius: float, inner: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 12:
		points.append(at + Vector2.from_angle(TAU * i / 12.0 + 0.2) * radius * (1.0 if i % 2 == 0 else inner))
	return points


## A small rock island: its cliff side below it, a rough top and a crack.
func _draw_ledge(at: Vector2) -> void:
	var dice := RandomNumberGenerator.new()
	dice.seed = hash(at)
	var top := PackedVector2Array()
	for i in 16:
		top.append(at + Vector2.from_angle(TAU * i / 16.0) * LEDGE_RADIUS * dice.randf_range(0.88, 1.0))
	var side := top.duplicate()
	for i in side.size():
		side[i] = side[i] + Vector2(0, 16)
	draw_colored_polygon(side, ROCK_DARK)
	draw_colored_polygon(top, ROCK)
	_draw_outline(top, ROCK_LIGHT, 4.0)
	_draw_crack(top, _bounds_of(top), dice)


## 6-2: the revived Karthus's broken altar, a cracked slab with a corner
## knocked off, in a faint green glow.
func _draw_altar(at: Vector2) -> void:
	draw_circle(at, ALTAR_SIZE * 0.9, Color(MIST_COLOR, 0.08))
	var half := ALTAR_SIZE * 0.5
	var turn := 0.2
	var corners: Array[Vector2] = []
	for i in 4:
		corners.append(at + Vector2(half if i in [1, 2] else -half, half if i >= 2 else -half).rotated(turn))
	var broken := corners[1]
	var cut_a := broken.lerp(corners[0], 0.35)
	var cut_b := broken.lerp(corners[2], 0.35)
	var slab := PackedVector2Array([corners[0], cut_a, cut_b, corners[2], corners[3]])
	draw_colored_polygon(slab, ALTAR_COLOR)
	_draw_outline(slab, ALTAR_COLOR.darkened(0.45), 4.0)
	var away := at.direction_to(broken) * 26.0
	draw_colored_polygon(PackedVector2Array([cut_a + away, broken + away, cut_b + away]), ALTAR_COLOR.darkened(0.2))
	draw_polyline(PackedVector2Array([corners[3].lerp(at, 0.2), at + Vector2(-10, 12), at.lerp(cut_a, 0.5)]), ALTAR_COLOR.darkened(0.5), 3.0, true)
	draw_polyline(PackedVector2Array([at + Vector2(-10, 12), at.lerp(corners[2], 0.7)]), ALTAR_COLOR.darkened(0.5), 3.0, true)


## 6-4: Hecarim rides in from the east end: green-scorched hoofprints from
## the plateau's edge to his camp.
func _draw_hoofmarks(at: Vector2) -> void:
	draw_circle(at, 150.0, Color(MIST_COLOR, 0.07))
	var x := PLATEAUS[2].end.x - 40.0
	var row := 0
	while x > at.x - 120.0:
		var mark := Vector2(x, at.y + (22.0 if row % 2 == 0 else -22.0))
		draw_arc(mark, 10.0, PI * 0.15 - PI * 0.5, PI * 1.85 - PI * 0.5, 10, HOOF_COLOR, 4.0, true)
		x -= 45.0
		row += 1


## 6-5: the stubs, then the carved disc over their ends: carved rings, the
## rune ring, a dark heart where Thresh stands, and chains rising at the rim.
func _draw_platform() -> void:
	var middle := PLATFORM_CENTER
	for i in RIM_CHAINS:
		var direction := Vector2.from_angle(TAU * (i + 0.5) / RIM_CHAINS)
		_draw_spike(middle + direction * (PLATFORM_RADIUS + RIM_CHAIN_REACH), 50.0, true)
	for i in STUB_DIRECTIONS.size():
		_draw_causeway(middle + STUB_DIRECTIONS[i] * PLATFORM_RADIUS, stub_end(i), STUB_WIDTH, true)
	draw_colored_polygon(ground[0], PLATFORM_STONE)
	draw_arc(middle, PLATFORM_RADIUS - 18.0, 0.0, TAU, PLATFORM_SIDES, SLATE_EDGE, 36.0, true)
	for ring in CARVED_RINGS:
		draw_arc(middle, ring, 0.0, TAU, 96, CARVE_COLOR, 6.0, true)
	for i in 24:
		var direction := Vector2.from_angle(TAU * (i + 0.5) / 24)
		draw_line(middle + direction * CARVED_RINGS[1], middle + direction * CARVED_RINGS[2], CARVE_COLOR, 4.0, true)
	_draw_runes(middle)
	draw_circle(middle, CARVED_RINGS[0] - 30.0, SLATE_DARK)
	draw_arc(middle, CARVED_RINGS[0] - 30.0, 0.0, TAU, 64, RUNE_COLOR, 3.0, true)
	for i in RIM_CHAINS:
		var direction := Vector2.from_angle(TAU * (i + 0.5) / RIM_CHAINS)
		_draw_chain(middle + direction * (PLATFORM_RADIUS - 30.0), middle + direction * (PLATFORM_RADIUS + RIM_CHAIN_REACH))


## Runes round the ring between the outer carved rings, each a few glowing
## strokes, standing along the ring.
func _draw_runes(middle: Vector2) -> void:
	var dice := RandomNumberGenerator.new()
	dice.seed = 53
	for i in RUNES:
		var angle := TAU * i / RUNES
		var at := middle + Vector2.from_angle(angle) * RUNE_RING
		var out := Vector2.from_angle(angle)
		var along := out.orthogonal()
		var top := at + out * 34.0
		var bottom := at - out * 34.0
		draw_line(top, bottom, RUNE_GLOW, 12.0, true)
		draw_line(top, bottom, RUNE_COLOR, 4.0, true)
		for stroke in 2:
			var from := at + out * dice.randf_range(-30.0, 30.0)
			var to := from + along * dice.randf_range(-24.0, 24.0) + out * dice.randf_range(-16.0, 16.0)
			draw_line(from, to, RUNE_COLOR, 4.0, true)


## A closed outline of `polygon`.
func _draw_outline(polygon: PackedVector2Array, color: Color, width: float) -> void:
	var loop := polygon.duplicate()
	loop.append(polygon[0])
	draw_polyline(loop, color, width, true)
