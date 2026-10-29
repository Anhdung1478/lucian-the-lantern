class_name PathFollower
extends RefCounted
## Walking around walls, for enemies and Lucian alike. A walker heads
## straight for its goal while a ray on Layers.WORLD to it hits nothing.
## When a wall is in the way it follows a path on the world's navigation map
## (baked by StageMap), asked again every REPATH_TIME or as soon as the goal
## has moved REPATH_MOVE. Until the map has synced once, and whenever a path
## comes back empty, it heads straight for the goal.

## Seconds between path queries while a wall is in the way.
const REPATH_TIME := 0.4
## A goal this far from the one the path was asked for asks again at once.
const REPATH_MOVE := 120.0
## Path corners this close count as passed.
const CORNER_REACH := 24.0

## Path queries asked so far (none while the line is clear).
var queries := 0

var _ray := PhysicsRayQueryParameters2D.new()
var _path := PackedVector2Array()
## The corner walked to now.
var _index := 0
## The goal the path was asked for.
var _asked_for := Vector2.ZERO
var _repath_left := 0.0
var _at_end := false


func _init() -> void:
	_ray.collision_mask = Layers.WORLD


## Where a walker at `from` heads this frame on its way to `goal`: the goal
## itself when the line to it is clear in `space`, before `nav_map` has
## synced once and when no path is found; else the next corner of the path.
## Call it every frame the walker walks (`delta` paces the path queries).
func next_point(from: Vector2, goal: Vector2, delta: float, space: PhysicsDirectSpaceState2D, nav_map: RID) -> Vector2:
	_repath_left -= delta
	_at_end = false
	_ray.from = from
	_ray.to = goal
	if space.intersect_ray(_ray).is_empty():
		# A wall in the way again asks for a path at once.
		_path.clear()
		_repath_left = 0.0
		return goal
	# Asking an unsynced map is an engine error.
	if NavigationServer2D.map_get_iteration_id(nav_map) == 0:
		return goal
	if _repath_left <= 0.0 or goal.distance_to(_asked_for) > REPATH_MOVE:
		_path = NavigationServer2D.map_get_path(nav_map, from, goal, true)
		_index = 0
		_asked_for = goal
		_repath_left = REPATH_TIME
		queries += 1
	if _path.is_empty():
		return goal
	while _index < _path.size() - 1 and from.distance_to(_path[_index]) <= CORNER_REACH:
		_index += 1
	_at_end = _index == _path.size() - 1 and goal == _asked_for
	return _path[_index]


## The last next_point gave the final point of a path asked for that very
## goal, while the line to the goal was still blocked: the goal lies inside
## a wall, and this point is as close as the walker gets.
func at_path_end() -> bool:
	return _at_end
