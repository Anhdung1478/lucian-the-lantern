class_name StageMap
extends Node2D
## A stage's ground: its size, its walls on Layers.WORLD (the border, plus
## polygons and circles inside), the navigation baked around them for
## PathFollower, and the points the stage uses. Subclasses fill the lists in
## _init and draw the ground in _draw. The playable area starts at (0, 0);
## the border walls sit just outside it. A map may also have terrain (lava,
## water, plants): build_terrain makes it, and the stage adds it to its
## world. The map is drawn at FLOOR_Z, under everything else on the stage.

const WALL_THICKNESS := 64.0
## Under ground zones (HazardZone.Z) and the units.
const FLOOR_Z := -10
## Paths keep this far from every wall.
const NAV_AGENT_RADIUS := 36.0
## A round wall is baked as a polygon with this many sides, just around it.
const NAV_CIRCLE_SIDES := 16

@export var size := Vector2(4800, 2700)

var lucian_start := Vector2.ZERO
## Senna's place in Act 1.
var ally_start := Vector2.ZERO
var merchant_point := Vector2.ZERO
var boss_point := Vector2.ZERO
## Where wave enemies come from, taken in turn.
var spawn_points: Array[Vector2] = []
## Camp id -> point: wave enemies whose data names a camp here come out of it.
var camps := {}
var wall_polygons: Array[PackedVector2Array] = []
## Round walls: (x, y, radius).
var wall_circles: Array[Vector3] = []
## The walkable ground for paths around the walls, baked in _ready.
var navigation: NavigationRegion2D


func _ready() -> void:
	z_index = FLOOR_Z
	var walls := StaticBody2D.new()
	walls.name = "Walls"
	walls.collision_layer = Layers.WORLD
	walls.collision_mask = 0
	for rect in border_rects():
		var box := RectangleShape2D.new()
		box.size = rect.size
		var shape := CollisionShape2D.new()
		shape.shape = box
		shape.position = rect.get_center()
		walls.add_child(shape)
	for polygon in wall_polygons:
		var solid := CollisionPolygon2D.new()
		solid.polygon = polygon
		walls.add_child(solid)
	for circle in wall_circles:
		var round_shape := CircleShape2D.new()
		round_shape.radius = circle.z
		var shape := CollisionShape2D.new()
		shape.shape = round_shape
		shape.position = Vector2(circle.x, circle.y)
		walls.add_child(shape)
	add_child(walls)
	_bake_navigation()


func get_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, size)


## The map's terrain (HazardZone, Honeyfruit, BlastCone), made new and wired
## to `lucian` and this map, positioned in the map's space, for the stage to
## add to its world. None by default.
func build_terrain(_lucian: Lucian) -> Array[Node2D]:
	return []


## Inside the area and at least `margin` away from every wall.
func is_walkable(point: Vector2, margin := 40.0) -> bool:
	if not get_bounds().grow(-margin).has_point(point):
		return false
	for polygon in wall_polygons:
		if Geometry2D.is_point_in_polygon(point, polygon) or _distance_to_edge(point, polygon) < margin:
			return false
	for circle in wall_circles:
		if point.distance_to(Vector2(circle.x, circle.y)) < circle.z + margin:
			return false
	return true


func border_rects() -> Array[Rect2]:
	var t := WALL_THICKNESS
	return [
		Rect2(-t, -t, size.x + 2 * t, t),
		Rect2(-t, size.y, size.x + 2 * t, t),
		Rect2(-t, 0, t, size.y),
		Rect2(size.x, 0, t, size.y),
	]


## The bounds less every wall polygon and circle, kept NAV_AGENT_RADIUS
## away from them, into the `navigation` region on the world's map.
func _bake_navigation() -> void:
	var source := NavigationMeshSourceGeometryData2D.new()
	var bounds := get_bounds()
	source.add_traversable_outline(PackedVector2Array([bounds.position, Vector2(bounds.end.x, bounds.position.y),
		bounds.end, Vector2(bounds.position.x, bounds.end.y)]))
	for polygon in wall_polygons:
		source.add_obstruction_outline(polygon)
	for circle in wall_circles:
		source.add_obstruction_outline(_circle_outline(circle))
	var ground := NavigationPolygon.new()
	ground.agent_radius = NAV_AGENT_RADIUS
	NavigationServer2D.bake_from_source_geometry_data(ground, source)
	navigation = NavigationRegion2D.new()
	navigation.name = "Navigation"
	navigation.navigation_polygon = ground
	add_child(navigation)


## A round wall (x, y, radius) as a polygon whose sides touch the circle, so
## it covers the whole wall.
static func _circle_outline(circle: Vector3) -> PackedVector2Array:
	var center := Vector2(circle.x, circle.y)
	var corner := circle.z / cos(PI / NAV_CIRCLE_SIDES)
	var outline := PackedVector2Array()
	for i in NAV_CIRCLE_SIDES:
		outline.append(center + Vector2.from_angle(TAU * i / NAV_CIRCLE_SIDES) * corner)
	return outline


## The smallest box holding `polygon`, for scattering trees over a wall.
static func _bounds_of(polygon: PackedVector2Array) -> Rect2:
	var box := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		box = box.expand(point)
	return box


static func _distance_to_edge(point: Vector2, polygon: PackedVector2Array) -> float:
	var best := INF
	for i in polygon.size():
		var closest := Geometry2D.get_closest_point_to_segment(point, polygon[i], polygon[(i + 1) % polygon.size()])
		best = minf(best, point.distance_to(closest))
	return best
