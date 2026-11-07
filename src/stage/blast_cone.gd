class_name BlastCone
extends Enemy
## A Blast Cone (3-2): a bulb plant on the jungle floor that Lucian shoots
## to be thrown over the jungle. It is in group &"plants", never &"enemies",
## so waves, the radar, item effects and A + Left-click's fallbacks ignore it;
## a click on it (Lucian.enemy_at) still gives an attack order.
##
## Any hit (a basic attack or a skill; not a burn tick) pops it. If Lucian is
## within REACH, he is thrown THROW_DISTANCE straight away from the plant
## (see landing_spot), over walls, in THROW_TIME. The throw is deferred: hits
## land inside physics callbacks. Popped, it is not alive and leaves the group
## and the hitboxes, until it regrows after REGROW_TIME. It never dies: no
## kill, no on-kill effects. Units walk through it.
##
## Ripe, it marks the ground in its own soft yellow, never red (red is enemy
## danger): a faint ring at REACH, brighter while Lucian stands inside it;
## and while a shot now would throw him, a ring his body's size where he
## would land, with a faint dashed line from him to it, redrawn every frame
## as he moves. Popped, it marks nothing.
##
## Set `lucian` and `arena` (the map, for walkable ground) before adding it,
## and `ground_parent` for its ground marks.

## Drawn 108 px wide (its leaves reach about 46 from the middle).
const ART := preload("res://assets/art/stage/blast_cone.svg")
const GROUP := &"plants"
## For clicks and attack range: a click on a leaf tip (RADIUS +
## Lucian.CLICK_SLACK) still picks it.
const RADIUS := 36.0
## Lucian is thrown only this close to the plant.
const REACH := 350.0
const THROW_DISTANCE := 800.0
const THROW_TIME := 0.6
## A shorter throw than this is no throw: he stays.
const MIN_THROW := 250.0
## The landing steps back toward Lucian this far at a time.
const LANDING_STEP := 25.0
## The landing is at least this far from every wall.
const LANDING_MARGIN := 40.0
const REGROW_TIME := 20.0
const STALK := Color("4f8a2e")
const BUD := Color("8fa628")
const OUTLINE := Color("1a1d24")
## Ripe, a soft yellow glow under it, breathing GLOW_PULSE times a second.
const GLOW := Color("f2f56a")
const GLOW_RADIUS := 66.0
const GLOW_PULSE := 0.6
## The reach ring's alpha (Lucian outside it, inside it) and width.
const REACH_ALPHA := 0.16
const REACH_LIT_ALPHA := 0.38
const REACH_WIDTH := 3.0
## The landing ring's alpha and fill, and the dashed line's alpha.
const LANDING_ALPHA := 0.75
const LANDING_FILL := 0.14
const LANDING_LINE_ALPHA := 0.32
const LANDING_WIDTH := 3.0
const LANDING_DASH := 14.0

var lucian: Lucian
var arena: StageMap
## Where its ground marks are drawn: the stage's Warnings (with the ground
## warnings: over the lava, under the units). Unset (tests, a stage without
## it), its own child, under the units.
var ground_parent: Node

var _regrow_left := 0.0
## Seconds ripe, for the glow's breathing.
var _ripe_time := 0.0
## Built in _ready (a cone freed unadded leaves nothing behind).
var _hurtbox: Hurtbox
var _bulb: Sprite2D
## Draws its reach and landing marks (_draw_guide): on `ground_parent`, or
## its own child.
var _guide: Node2D
## Lucian is within REACH of it, ripe.
var _lucian_in_reach := false
## A shot now would throw him, to _landing.
var _throws := false
var _landing := Vector2.ZERO


## Where a throw lands Lucian, standing at `from`, thrown away from a plant
## at `plant`: THROW_DISTANCE on, or nearer in LANDING_STEP steps, the
## farthest spot `map` calls walkable (LANDING_MARGIN from walls), a check of
## the map's shapes, not a physics query. `from` itself when none is at least
## MIN_THROW away, or there is no map: no throw.
static func landing_spot(plant: Vector2, from: Vector2, map: StageMap) -> Vector2:
	if map == null:
		return from
	var direction := plant.direction_to(from)
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	var distance := THROW_DISTANCE
	while distance >= MIN_THROW:
		var point := from + direction * distance
		if map.is_walkable(point, LANDING_MARGIN):
			return point
		distance -= LANDING_STEP
	return from


## Not Enemy's: that would join &"enemies".
func _ready() -> void:
	max_hp = 1.0
	hp = max_hp
	radius = RADIUS
	add_to_group(GROUP)
	collision_layer = 0
	collision_mask = 0
	var circle := CircleShape2D.new()
	circle.radius = RADIUS + 6.0
	var shape := CollisionShape2D.new()
	shape.shape = circle
	_hurtbox = Hurtbox.new()
	_hurtbox.collision_layer = Layers.ENEMY_HURTBOX
	_hurtbox.collision_mask = 0
	_hurtbox.monitoring = false
	_hurtbox.add_child(shape)
	add_child(_hurtbox)
	_bulb = Sprite2D.new()
	_bulb.texture = ART
	add_child(_bulb)
	_make_guide()


## Its marks' node, on `ground_parent` at the plant, or its own child under
## the units.
func _make_guide() -> void:
	_guide = Node2D.new()
	_guide.draw.connect(_draw_guide)
	if ground_parent:
		ground_parent.add_child(_guide)
		_guide.global_position = global_position
	else:
		_guide.z_index = HazardZone.Z
		add_child(_guide)


## Its marks shown or hidden. Made again first if the ground was cleared
## under them (a fallen Thresh's Stage._clear_fight frees what lies in
## Warnings: a debug one in 3-2).
func _show_guide(on: bool) -> void:
	if not is_instance_valid(_guide):
		_make_guide()
	_guide.visible = on


## Its ground marks go with it.
func _exit_tree() -> void:
	if is_instance_valid(_guide) and _guide.get_parent() != self:
		_guide.queue_free()


## Ripe and waiting to be shot.
func is_ripe() -> bool:
	return not dead


## Lucian stands within REACH of it while it is ripe: its ring is brighter.
func lucian_in_reach() -> bool:
	return _lucian_in_reach


## A shot now would throw Lucian: the landing ring is shown, at landing_mark.
func marks_landing() -> bool:
	return _throws


## Where the landing ring is (landing_spot for Lucian where he stands);
## meaningful while marks_landing.
func landing_mark() -> Vector2:
	return _landing


## A hit pops it (once) and maybe throws Lucian; it takes no damage itself.
func take_damage(info: DamageInfo) -> float:
	if dead or info.over_time:
		return 0.0
	_pop()
	return 0.0


func _physics_process(delta: float) -> void:
	super(delta)
	if dead:
		_regrow_left -= delta
		queue_redraw()
		if _regrow_left <= 0.0:
			_regrow()
	else:
		_ripe_time += delta
		queue_redraw()
		_update_guide()


## Where a throw would land Lucian now, if he is within REACH (landing_spot's
## map checks only then), and the marks redrawn to match.
func _update_guide() -> void:
	var near := is_instance_valid(lucian) and not lucian.dead and global_position.distance_to(lucian.global_position) <= REACH
	_lucian_in_reach = near
	_landing = landing_spot(global_position, lucian.global_position, arena) if near else Vector2.ZERO
	_throws = near and _landing != lucian.global_position
	_show_guide(true)
	_guide.queue_redraw()


func _pop() -> void:
	dead = true
	_regrow_left = REGROW_TIME
	remove_from_group(GROUP)
	_hurtbox.collision_layer = 0
	_bulb.visible = false
	_lucian_in_reach = false
	_throws = false
	_show_guide(false)
	Sfx.play(&"shell", -6.0)
	queue_redraw()
	# Not here: the hit may land inside a physics callback.
	_throw.call_deferred()


## Lucian within REACH flies to the landing spot, if there is one.
func _throw() -> void:
	if not is_instance_valid(lucian) or lucian.dead:
		return
	if global_position.distance_to(lucian.global_position) > REACH:
		return
	var to := landing_spot(global_position, lucian.global_position, arena)
	if to != lucian.global_position:
		lucian.launch(to, THROW_TIME)


func _regrow() -> void:
	dead = false
	hp = max_hp
	_regrow_left = 0.0
	add_to_group(GROUP)
	_hurtbox.collision_layer = Layers.ENEMY_HURTBOX
	_bulb.visible = true
	_show_guide(true)
	queue_redraw()


func _draw() -> void:
	super()
	if not dead:
		# Rings fading out from the bulb, under the art.
		var breath := 0.8 + 0.2 * sin(_ripe_time * TAU * GLOW_PULSE)
		for i in 5:
			draw_circle(Vector2.ZERO, GLOW_RADIUS * breath * (1.0 - i * 0.16), Color(GLOW, 0.09))
		return
	# Regrowing: a stem with a bud swelling back.
	var grown := 1.0 - _regrow_left / REGROW_TIME
	draw_line(Vector2(0, 14), Vector2(0, -4), STALK, 4.0, true)
	for side in [-1.0, 1.0]:
		draw_line(Vector2(0, 8), Vector2(12 * side, 2), STALK, 3.0, true)
	draw_circle(Vector2(0, -6), 4.0 + 6.0 * grown, BUD)
	draw_arc(Vector2(0, -6), 4.0 + 6.0 * grown, 0.0, TAU, 20, OUTLINE, 2.0, true)


## On _guide, in its space (it sits on the plant): the reach ring, then the
## landing ring and the dashed line to it from Lucian's body edge.
func _draw_guide() -> void:
	if dead:
		return
	_guide.draw_arc(Vector2.ZERO, REACH, 0.0, TAU, 96, Color(GLOW, REACH_LIT_ALPHA if _lucian_in_reach else REACH_ALPHA), REACH_WIDTH, true)
	if not _throws or not is_instance_valid(lucian):
		return
	var to := _guide.to_local(_landing)
	var from := _guide.to_local(lucian.global_position)
	var along := from.direction_to(to)
	_guide.draw_dashed_line(from + along * Lucian.HIT_RADIUS, to - along * Lucian.HIT_RADIUS, Color(GLOW, LANDING_LINE_ALPHA), LANDING_WIDTH, LANDING_DASH, true, true)
	_guide.draw_circle(to, Lucian.HIT_RADIUS, Color(GLOW, LANDING_FILL))
	_guide.draw_arc(to, Lucian.HIT_RADIUS, 0.0, TAU, 40, Color(GLOW, LANDING_ALPHA), LANDING_WIDTH, true)
