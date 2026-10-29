class_name EnemyProjectile
extends Area2D
## An enemy's shot: flies straight and ends on Lucian (by distance, taken or
## blocked) or on a wall or pillar. A boomerang flies `max_range` out, then
## back to its thrower, and may hit once each way.

## The shot hit Lucian and he took it (not blocked).
signal hit_lucian

## A wave front: how far its crest bows forward at the middle, its depth
## behind the crest, the trailing wake's extra depth, and the points along it.
const FRONT_BOW := 22.0
const FRONT_DEPTH := 58.0
const WAKE_DEPTH := 56.0
const FRONT_POINTS := 18
const FOAM := Color("eafcff")

var info: DamageInfo
var target: Lucian
var direction := Vector2.RIGHT
var speed := 450.0
var max_range := 600.0
var hit_radius := 12.0
var color := Color("c47cff")
## Drawn as a wave front this wide across its travel (the Ocean Drake's Tidal
## Wave), a crest of foam bowing forward, instead of a ball. 0 = a ball. The
## look only: it still hits within hit_radius of its center.
var front_width := 0.0
## Boomerang: flies back to this node after max_range.
var return_to: Node2D
## Draws a chain back to this node (Thresh's hook).
var tether: Node2D

var _travelled := 0.0
var _returning := false
var _hit_this_pass := false


func launch(from: Vector2, toward: Vector2, hit: DamageInfo, foe: Lucian) -> void:
	position = from
	direction = toward.normalized()
	rotation = direction.angle()
	info = hit
	target = foe


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.WORLD
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(func(_body: Node2D) -> void: queue_free())


func _physics_process(delta: float) -> void:
	var step := speed * delta
	if _returning:
		if not is_instance_valid(return_to):
			queue_free()
			return
		var offset := return_to.global_position - global_position
		if offset.length() <= step:
			queue_free()
			return
		direction = offset.normalized()
	global_position += direction * step
	rotation = direction.angle()
	_travelled += step
	if tether:
		queue_redraw()
	if not _hit_this_pass and is_instance_valid(target) and global_position.distance_to(target.global_position) <= hit_radius + Lucian.HIT_RADIUS:
		_hit_this_pass = true
		if target.take_damage(info):
			hit_lucian.emit()
		if not return_to:
			queue_free()
			return
	if not _returning and _travelled >= max_range:
		if return_to:
			_returning = true
			_hit_this_pass = false
		else:
			queue_free()


func _draw() -> void:
	if is_instance_valid(tether):
		draw_line(Vector2.ZERO, to_local(tether.global_position), color, 4.0)
	if front_width > 0.0:
		_draw_front()
		return
	draw_circle(Vector2.ZERO, hit_radius, Color(color, 0.35))
	draw_circle(Vector2.ZERO, hit_radius * 0.55, color)


## A crescent across its travel (+X here): a faint wake, the water fading
## back from the crest, then the foam along the crest. Its ends taper to a
## point at front_width / 2 each side.
func _draw_front() -> void:
	var half := front_width * 0.5
	var crest := PackedVector2Array()
	for i in FRONT_POINTS + 1:
		var t := lerpf(-1.0, 1.0, float(i) / FRONT_POINTS)
		crest.append(Vector2(FRONT_BOW * (1.0 - t * t), half * t))
	for layer: Array in [[FRONT_DEPTH + WAKE_DEPTH, 0.3, 0.0], [FRONT_DEPTH, 0.9, 0.2]]:
		var depth: float = layer[0]
		var crest_alpha: float = layer[1]
		var back_alpha: float = layer[2]
		var points := crest.duplicate()
		var colors := PackedColorArray()
		colors.resize(points.size())
		colors.fill(Color(color, crest_alpha))
		# Back along the inside, end to end, skipping the tips (already in).
		for i in range(FRONT_POINTS - 1, 0, -1):
			var bow := 1.0 - crest[i].y * crest[i].y / (half * half)
			points.append(crest[i] - Vector2(depth * sqrt(bow), 0.0))
			colors.append(Color(color.darkened(0.35), back_alpha))
		draw_polygon(points, colors)
	draw_polyline(crest, Color(color.lightened(0.45), 0.6), 14.0, true)
	draw_polyline(crest, FOAM, 5.0, true)
	for i in range(2, FRONT_POINTS - 1, 3):
		draw_circle(crest[i] - Vector2(10.0, 0.0), 3.5, Color(FOAM, 0.8))
