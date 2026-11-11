class_name HazardZone
extends Node2D
## Ground that hurts or hinders Lucian while he stands in it: lava, shallow
## water, burning ground. Its area is a circle round its position or a
## polygon. A BURN zone burns him (`dps` of `damage_type`), lingering
## BURN_LINGER after he steps out; a SLOW zone slows him by `slow`, ending
## about as he steps out. Zones with the same `id` don't stack. A thrown
## Lucian flies over it untouched. With a `lifetime` it fades in, then out,
## and goes. It draws itself (cracked lava with a glowing core, or clear water) under the
## units and over the floor. Enemies don't mind it.
##
## Build one with burning() or slowing(), give it its area with set_circle()
## or set_polygon(), set `lucian`, then add it to the world (the stage's
## World, at the origin: positions are in the parent's space).

enum Effect { BURN, SLOW }

## Act 3's lava (3-2) and shallow water (3-4).
const LAVA_DPS := 40.0
const WATER_SLOW := 0.25
## Lucian's burn and slow ids: every burning zone shares one, every slowing one the other.
const BURN_ID := &"burning_ground"
const SLOW_ID := &"shallow_water"
## Seconds a burn lasts after its last refresh, and a slow.
const BURN_LINGER := 0.5
const SLOW_LINGER := 0.1
## Seconds a zone with a lifetime takes to fade in, and to fade out.
const FADE_TIME := 0.4
## Under the units (0) and over the floor (StageMap.FLOOR_Z).
const Z := -1
## A circle is drawn and tested as a polygon of this many sides.
const CIRCLE_SIDES := 48
## Lava: dark crust, glowing cracks and a hot core, in orange (never red: red is
## the ground warnings'), the rim lit softly.
const LAVA_CRUST := Color(0.12, 0.065, 0.05, 0.95)
const LAVA_ROCK := Color(0.2, 0.1, 0.06, 0.95)
const LAVA_CRACK := Color(1.0, 0.52, 0.12)
const LAVA_HOT := Color(1.0, 0.76, 0.3)
const LAVA_EDGE := Color(1.0, 0.5, 0.14)
## The rock inside the crust, as a share of the zone's size.
const LAVA_ROCK_SHARE := 0.9
## The rim's light: its width and alpha, and the line on the edge.
const LAVA_HALO_WIDTH := 18.0
const LAVA_HALO_ALPHA := 0.13
const LAVA_EDGE_ALPHA := 0.75
## Seconds a pulse takes, the core's size as a share of the nearest edge, and its alpha.
const LAVA_PULSE_TIME := 2.6
const LAVA_CORE_SHARE := 1.0
const LAVA_CORE_ALPHA := 0.5
## Cracks per 10 000 px² of area (at least 3, at most MAX_CRACKS), their pieces
## and how long and how bent each piece is.
const CRACK_DENSITY := 1.4
const MAX_CRACKS := 24
const CRACK_PIECES := 4
const CRACK_LENGTH := Vector2(24.0, 46.0)
const CRACK_TURN := 0.8
const CRACK_WIDTH := 2.5
const CRACK_ALPHA := 0.85
## Water: a faint tint over the riverbed, deeper towards the middle in WATER_BANDS steps
## over WATER_DEPTH px, a soft bank and a bright line on the edge, ripples and glints.
const WATER_COLOR := Color(0.24, 0.52, 0.78, 0.22)
const WATER_DEEP := Color(0.14, 0.38, 0.66, 0.13)
const WATER_EDGE := Color(0.7, 0.88, 1.0, 0.6)
const WATER_BANK := Color(0.62, 0.84, 1.0, 0.16)
const WATER_BANK_WIDTH := 10.0
const WATER_BANDS := 3
const WATER_DEPTH := 70.0
const RIPPLE_COLOR := Color(0.8, 0.93, 1.0, 0.5)
const GLINT_COLOR := Color(0.95, 1.0, 1.0)
const GLINT_LENGTH := 7.0
## Ripples or bubbles per 10 000 px² of area, at most MAX_SPOTS; every GLINT_EVERY-th one is a glint.
const SPOT_DENSITY := 0.8
const MAX_SPOTS := 60
const GLINT_EVERY := 3
## A zone redraws this often (seconds) while it animates.
const REDRAW_EVERY := 0.1

var lucian: Lucian
var effect := Effect.BURN
## Lucian's status id (see BURN_ID and SLOW_ID).
var id := BURN_ID
## BURN: damage per second, of `damage_type`.
var dps := 0.0
var damage_type := DamageInfo.Type.MAGIC
## SLOW: 0.25 = 25% slower.
var slow := 0.0
## Seconds before it goes; 0 keeps it for good.
var lifetime := 0.0
## A circle round the position, while `polygon` is empty.
var radius := 0.0
## The area round the position (its points relative to it), or empty for a circle.
var polygon := PackedVector2Array()

var _age := 0.0
var _redraw_in := 0.0
## The edge, relative to the position: `polygon`, or the circle's sides.
var _shape := PackedVector2Array()
## Ripples or bubbles: (x, y, phase), relative to the position.
var _spots: Array[Vector3] = []
## Lava's cracks, relative to the position.
var _cracks: Array[PackedVector2Array] = []
## The edge shrunk: lava's rock, or water's deeper steps.
var _inner: Array[PackedVector2Array] = []
## The distance from the middle to the nearest edge.
var _core := 0.0


## A zone burning Lucian for `burn_dps` of `type` per second, for
## `seconds` (0: for good).
static func burning(burn_dps: float, type: DamageInfo.Type, seconds := 0.0) -> HazardZone:
	var zone := HazardZone.new()
	zone.effect = Effect.BURN
	zone.id = BURN_ID
	zone.dps = burn_dps
	zone.damage_type = type
	zone.lifetime = seconds
	return zone


## A zone slowing Lucian by `pct` (0.25 = 25%), for `seconds` (0: for good).
static func slowing(pct: float, seconds := 0.0) -> HazardZone:
	var zone := HazardZone.new()
	zone.effect = Effect.SLOW
	zone.id = SLOW_ID
	zone.slow = pct
	zone.lifetime = seconds
	return zone


## Makes the zone a circle of `zone_radius` at `center`. Returns the zone.
func set_circle(center: Vector2, zone_radius: float) -> HazardZone:
	position = center
	radius = zone_radius
	polygon = PackedVector2Array()
	_shape = PackedVector2Array()
	for i in CIRCLE_SIDES:
		_shape.append(Vector2.from_angle(TAU * i / CIRCLE_SIDES) * radius)
	_prepare()
	return self


## Makes the zone the polygon `points` (in the parent's space); the zone
## stands at their middle. Returns the zone.
func set_polygon(points: PackedVector2Array) -> HazardZone:
	var middle := Vector2.ZERO
	for point in points:
		middle += point
	position = middle / maxi(points.size(), 1)
	radius = 0.0
	polygon = PackedVector2Array()
	for point in points:
		polygon.append(point - position)
	_shape = polygon
	_prepare()
	return self


## `point` (in the parent's space) lies in the zone.
func contains(point: Vector2) -> bool:
	var local := point - position
	if polygon.is_empty():
		return local.length() <= radius
	return Geometry2D.is_point_in_polygon(local, polygon)


## The zone's edge in the parent's space (a circle as CIRCLE_SIDES points).
func outline() -> PackedVector2Array:
	var points := PackedVector2Array()
	for point in _shape:
		points.append(position + point)
	return points


func _init() -> void:
	z_index = Z


func _physics_process(delta: float) -> void:
	_age += delta
	if lifetime > 0.0 and _age >= lifetime:
		queue_free()
		return
	if not is_instance_valid(lucian) or lucian.dead or lucian.is_launched() or not contains(lucian.global_position):
		return
	match effect:
		Effect.BURN:
			lucian.add_burn(id, dps, BURN_LINGER, damage_type)
		Effect.SLOW:
			lucian.add_slow(id, slow, SLOW_LINGER)


## The pulse, the ripples and the fade redraw a few times a second; with
## Juice off only a zone with a lifetime does (its fade).
func _process(delta: float) -> void:
	if not is_visible_in_tree() or not (Juice.on() or lifetime > 0.0):
		return
	_redraw_in -= delta
	if _redraw_in <= 0.0:
		_redraw_in = REDRAW_EVERY
		queue_redraw()


## 1 in full; a zone with a lifetime fades in at the start and out at the end.
func _opacity() -> float:
	if lifetime <= 0.0:
		return 1.0
	return clampf(minf(_age, lifetime - _age) / FADE_TIME, 0.0, 1.0)


## The seconds its animation has run (0 with Juice off: it stands still).
func _clock() -> float:
	return _age if Juice.on() else 0.0


## What is drawn once from the shape: its ripples or bubbles, cracks, inner
## edges and the distance to the nearest edge. Seeded by the shape.
func _prepare() -> void:
	_spots.clear()
	_cracks.clear()
	_inner.clear()
	if _shape.size() < 3:
		return
	_core = MapArt.edge_distance(Vector2.ZERO, _shape)
	var box := MapArt.bounds_of(_shape)
	var area := box.get_area() / 10000.0
	var dice := MapArt.rng(hash(_shape))
	# Kept off the edge, inside a smaller copy of the area.
	var inner := _scaled(0.8)
	var count := mini(ceili(area * SPOT_DENSITY), MAX_SPOTS)
	var tries := 0
	while _spots.size() < count and tries < count * 10:
		tries += 1
		var at := Vector2(dice.randf_range(box.position.x, box.end.x), dice.randf_range(box.position.y, box.end.y))
		if Geometry2D.is_point_in_polygon(at, inner):
			_spots.append(Vector3(at.x, at.y, dice.randf() * TAU))
	if effect == Effect.BURN:
		_inner.append(_scaled(LAVA_ROCK_SHARE))
		_make_cracks(dice, clampi(ceili(area * CRACK_DENSITY), 3, MAX_CRACKS))
	else:
		for step in range(1, WATER_BANDS + 1):
			for deeper in Geometry2D.offset_polygon(_shape, -WATER_DEPTH * step / WATER_BANDS, Geometry2D.JOIN_ROUND):
				_inner.append(deeper)


## `count` cracks, each a bent line of up to CRACK_PIECES pieces from a spot in
## the rock, ending where it would leave it.
func _make_cracks(dice: RandomNumberGenerator, count: int) -> void:
	var rock := _inner[0]
	var box := MapArt.bounds_of(rock)
	var tries := 0
	while _cracks.size() < count and tries < count * 10:
		tries += 1
		var at := Vector2(dice.randf_range(box.position.x, box.end.x), dice.randf_range(box.position.y, box.end.y))
		if not Geometry2D.is_point_in_polygon(at, rock):
			continue
		var crack := PackedVector2Array([at])
		var heading := dice.randf() * TAU
		for piece in CRACK_PIECES:
			heading += dice.randf_range(-CRACK_TURN, CRACK_TURN)
			at += Vector2.from_angle(heading) * dice.randf_range(CRACK_LENGTH.x, CRACK_LENGTH.y)
			if not Geometry2D.is_point_in_polygon(at, rock):
				break
			crack.append(at)
		if crack.size() >= 2:
			_cracks.append(crack)


func _draw() -> void:
	if _shape.size() < 3:
		return
	var fade := _opacity()
	if effect == Effect.BURN:
		_draw_lava(fade)
	else:
		_draw_water(fade)


## A dark crust with glowing cracks and a hot core that pulse together, a soft
## orange light on the rim, and bubbles.
func _draw_lava(fade: float) -> void:
	var clock := _clock()
	var pulse := 0.5 + 0.5 * sin(clock * TAU / LAVA_PULSE_TIME)
	_draw_edge(_faded(Color(LAVA_EDGE, LAVA_HALO_ALPHA * (0.7 + 0.3 * pulse)), fade), LAVA_HALO_WIDTH)
	draw_colored_polygon(_shape, _faded(LAVA_CRUST, fade))
	draw_colored_polygon(_inner[0], _faded(LAVA_ROCK, fade))
	var glow := 0.55 + 0.45 * pulse
	for crack in _cracks:
		draw_polyline(crack, _faded(Color(LAVA_CRACK, CRACK_ALPHA * 0.35 * glow), fade), CRACK_WIDTH * 3.0, true)
		draw_polyline(crack, _faded(Color(LAVA_CRACK, CRACK_ALPHA * glow), fade), CRACK_WIDTH, true)
	MapArt.glow(self, Vector2.ZERO, _core * LAVA_CORE_SHARE, _faded(Color(LAVA_CRACK, LAVA_CORE_ALPHA * glow), fade))
	MapArt.glow(self, Vector2.ZERO, _core * LAVA_CORE_SHARE * 0.5, _faded(Color(LAVA_HOT, LAVA_CORE_ALPHA * glow), fade))
	for spot in _spots:
		var life := fmod(clock * 0.7 + spot.z / TAU, 1.0)
		draw_circle(Vector2(spot.x, spot.y), 3.0 + 6.0 * life, _faded(Color(LAVA_HOT, 0.5 * (1.0 - life)), fade))
	_draw_edge(_faded(Color(LAVA_EDGE, LAVA_EDGE_ALPHA), fade), 3.0)


## Clear water over the riverbed: a tint deepening inward, a soft bank,
## ripples spreading out and fading, and glints.
func _draw_water(fade: float) -> void:
	var clock := _clock()
	draw_colored_polygon(_shape, _faded(WATER_COLOR, fade))
	for deeper in _inner:
		draw_colored_polygon(deeper, _faded(WATER_DEEP, fade))
	_draw_edge(_faded(WATER_BANK, fade), WATER_BANK_WIDTH)
	for i in _spots.size():
		var spot := _spots[i]
		var at := Vector2(spot.x, spot.y)
		if i % GLINT_EVERY == 0:
			var twinkle := maxf(sin(clock * 1.6 + spot.z), 0.0)
			draw_line(at - Vector2(GLINT_LENGTH, 0.0), at + Vector2(GLINT_LENGTH, 0.0), _faded(Color(GLINT_COLOR, 0.7 * twinkle), fade), 2.0, true)
			continue
		var life := fmod(clock * 0.45 + spot.z / TAU, 1.0)
		draw_arc(at, 6.0 + 26.0 * life, 0.0, TAU, 20, _faded(Color(RIPPLE_COLOR, RIPPLE_COLOR.a * (1.0 - life)), fade), 2.0, true)
	_draw_edge(_faded(WATER_EDGE, fade), 3.0)


func _draw_edge(color: Color, width: float) -> void:
	var edge := _shape.duplicate()
	edge.append(_shape[0])
	draw_polyline(edge, color, width, true)


## The edge drawn `factor` as big round the middle.
func _scaled(factor: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point in _shape:
		points.append(point * factor)
	return points


static func _faded(color: Color, fade: float) -> Color:
	return Color(color, color.a * fade)
