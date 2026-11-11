class_name ShotGlow
extends Node2D
## A soft additive glow round a shot's head and a short trail behind it. A
## child of the shot, in the shot's `color`. It adds nothing to the shot but a
## look, and only a shot with no skin look of its own gets one (the skins'
## looks bring their own). Made only while Juice is on. It draws every frame
## (the shot moves) without making anything.

## The glow's rings, outermost first: each as (its share of the radius, its
## alpha). Added up they make a soft round falloff.
const RINGS := [Vector2(1.0, 0.07), Vector2(0.68, 0.11), Vector2(0.38, 0.2)]
## Positions kept for the trail, and its width at the shot.
const TRAIL_POINTS := 7
const TRAIL_WIDTH := 5.0
const TRAIL_ALPHA := 0.4

static var _additive: CanvasItemMaterial

var radius := 18.0

## Recent global positions as a ring: oldest at _next once full.
var _trail := PackedVector2Array()
var _next := 0
var _count := 0


## Gives `shot` a glow of `radius` and, when `trail`, a trail, if Juice is on.
## The glow takes the shot's `color`.
static func attach(shot: Node2D, glow_radius: float, trail := true) -> void:
	if not Juice.on():
		return
	var glow := ShotGlow.new()
	glow.radius = glow_radius
	if trail:
		glow._trail.resize(TRAIL_POINTS)
	shot.add_child(glow)


func _init() -> void:
	if _additive == null:
		_additive = CanvasItemMaterial.new()
		_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = _additive


func _process(_delta: float) -> void:
	if not _trail.is_empty():
		_trail[_next] = global_position
		_next = (_next + 1) % TRAIL_POINTS
		_count = mini(_count + 1, TRAIL_POINTS)
	queue_redraw()


func _draw() -> void:
	var color: Color = get_parent().color
	for ring: Vector2 in RINGS:
		draw_circle(Vector2.ZERO, radius * ring.x, Color(color, ring.y))
	var from := to_local(global_position)
	for i in _count:
		# Oldest first: each segment ends at the next, the last at the head.
		var at := (_next - _count + i + TRAIL_POINTS) % TRAIL_POINTS
		var share := float(i + 1) / (_count + 1)
		var to := to_local(_trail[(at + 1) % TRAIL_POINTS]) if i < _count - 1 else from
		draw_line(to_local(_trail[at]), to, Color(color, TRAIL_ALPHA * share), TRAIL_WIDTH * share)
