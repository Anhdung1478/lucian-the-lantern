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
## Set `lucian` and `arena` (the map, for walkable ground) before adding it.

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

var lucian: Lucian
var arena: StageMap

var _regrow_left := 0.0
## Seconds ripe, for the glow's breathing.
var _ripe_time := 0.0
## Built in _ready (a cone freed unadded leaves nothing behind).
var _hurtbox: Hurtbox
var _bulb: Sprite2D


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


## Ripe and waiting to be shot.
func is_ripe() -> bool:
	return not dead


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


func _pop() -> void:
	dead = true
	_regrow_left = REGROW_TIME
	remove_from_group(GROUP)
	_hurtbox.collision_layer = 0
	_bulb.visible = false
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
