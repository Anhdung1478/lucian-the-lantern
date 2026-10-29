class_name HazardZone
extends Node2D
## Ground that hurts or hinders Lucian while he stands in it: lava, shallow
## water, burning ground. Its area is a circle round its position or a
## polygon. A BURN zone burns him (`dps` of `damage_type`), lingering
## BURN_LINGER after he steps out; a SLOW zone slows him by `slow`, ending
## about as he steps out. Zones with the same `id` don't stack. A thrown
## Lucian flies over it untouched. With a `lifetime` it fades in, then out,
## and goes. It draws itself (a glowing pool or translucent water) under the
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
const LAVA_COLOR := Color(0.55, 0.12, 0.04, 0.92)
const LAVA_GLOW := Color(1.0, 0.45, 0.1, 0.75)
const LAVA_EDGE := Color(1.0, 0.62, 0.2, 0.9)
const LAVA_CRUST := Color(0.2, 0.06, 0.03, 0.9)
const WATER_COLOR := Color(0.24, 0.52, 0.78, 0.42)
const WATER_EDGE := Color(0.62, 0.84, 1.0, 0.55)
const RIPPLE_COLOR := Color(0.8, 0.93, 1.0, 0.5)
## Ripples or bubbles per 10 000 px² of area, at most MAX_SPOTS.
const SPOT_DENSITY := 0.8
const MAX_SPOTS := 60

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
## The edge, relative to the position: `polygon`, or the circle's sides.
var _shape := PackedVector2Array()
## Ripples or bubbles: (x, y, phase), relative to the position.
var _spots: Array[Vector3] = []


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
	_scatter_spots()
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
	_scatter_spots()
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


func _process(_delta: float) -> void:
	queue_redraw()


## 1 in full; a zone with a lifetime fades in at the start and out at the end.
func _opacity() -> float:
	if lifetime <= 0.0:
		return 1.0
	return clampf(minf(_age, lifetime - _age) / FADE_TIME, 0.0, 1.0)


## Spots for ripples or bubbles, spread over the area by a seed of its size.
func _scatter_spots() -> void:
	_spots.clear()
	if _shape.size() < 3:
		return
	var box := Rect2(_shape[0], Vector2.ZERO)
	for point in _shape:
		box = box.expand(point)
	var count := mini(ceili(box.get_area() / 10000.0 * SPOT_DENSITY), MAX_SPOTS)
	var dice := RandomNumberGenerator.new()
	dice.seed = hash(_shape)
	# Kept off the edge, inside a smaller copy of the area.
	var inner := _scaled(0.8)
	var tries := 0
	while _spots.size() < count and tries < count * 10:
		tries += 1
		var at := Vector2(dice.randf_range(box.position.x, box.end.x), dice.randf_range(box.position.y, box.end.y))
		if Geometry2D.is_point_in_polygon(at, inner):
			_spots.append(Vector3(at.x, at.y, dice.randf() * TAU))


func _draw() -> void:
	if _shape.size() < 3:
		return
	var fade := _opacity()
	if effect == Effect.BURN:
		_draw_lava(fade)
	else:
		_draw_water(fade)


## A dark red crust, the glowing pool inside it pulsing softly, and bubbles.
func _draw_lava(fade: float) -> void:
	var pulse := 0.5 + 0.5 * sin(_age * 2.4)
	draw_colored_polygon(_shape, _faded(LAVA_CRUST, fade))
	draw_colored_polygon(_scaled(0.88), _faded(LAVA_COLOR, fade))
	draw_colored_polygon(_scaled(0.6 + 0.06 * pulse), _faded(Color(LAVA_GLOW, LAVA_GLOW.a * (0.55 + 0.35 * pulse)), fade))
	for spot in _spots:
		var life := fmod(_age * 0.7 + spot.z / TAU, 1.0)
		draw_circle(Vector2(spot.x, spot.y), 4.0 + 8.0 * life, _faded(Color(LAVA_EDGE, 0.6 * (1.0 - life)), fade))
	_draw_edge(_faded(LAVA_EDGE, fade), 4.0)


## Translucent blue with rings spreading out and fading.
func _draw_water(fade: float) -> void:
	draw_colored_polygon(_shape, _faded(WATER_COLOR, fade))
	for spot in _spots:
		var life := fmod(_age * 0.45 + spot.z / TAU, 1.0)
		draw_arc(Vector2(spot.x, spot.y), 6.0 + 26.0 * life, 0.0, TAU, 20, _faded(Color(RIPPLE_COLOR, RIPPLE_COLOR.a * (1.0 - life)), fade), 2.0, true)
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
