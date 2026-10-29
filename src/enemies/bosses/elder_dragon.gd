class_name ElderDragon
extends Boss
## Act 3's boss, in 3-5's pit. Its shot is a violet magic bolt. Elder
## Breath: a wide cone warning, then a hit. Sky Dive (at or below 85% HP): it
## takes off, untargetable and unseen, and its shadow (the dragon itself,
## drawn as a dark ellipse) flies after Lucian over walls and rocks; then
## the shadow stops, a circle warning fills, and it lands there with a hit
## and a push. Elder's Mark: an ElderMark over Lucian that lands true damage
## after a few seconds, three times as much if he is low by then.
##
## Lucian keeps his attack order on it while it is up (see Lucian), so he
## shoots again once it lands. It takes off and lands in _physics_process
## and the warning's `fired`, never inside a damage path.

enum Dive { NONE, FOLLOW, FALL }

const BREATH_LENGTH := 700.0
const BREATH_ANGLE := PI / 2.0
const BREATH_WARN := 1.0
const BREATH_DAMAGE := 160.0
const BREATH_COOLDOWN := 8.0
const BREATH_FIRST := 2.0
## Seconds its shadow follows Lucian, at DIVE_SPEED.
const DIVE_FOLLOW := 2.4
const DIVE_SPEED := 300.0
const DIVE_RADIUS := 260.0
const DIVE_WARN := 0.8
const DIVE_DAMAGE := 240.0
## A landing on Lucian pushes him this far from the circle's middle, at PUSH_SPEED.
const DIVE_PUSH := 200.0
const PUSH_SPEED := 1200.0
const DIVE_COOLDOWN := 18.0
## Sky Dive waits until HP is at or below this share.
const DIVE_HP := 0.85
## Seconds its art takes to fade as it takes off; it grows as it rises.
const TAKE_OFF_FADE := 0.3
const TAKE_OFF_SCALE := 1.3
## A landing spot in a rock or the rim moves toward the pit's middle this
## far at a time until its body fits.
const LANDING_STEP := 20.0
const MARK_DAMAGE := 130.0
const MARK_COOLDOWN := 16.0
const MARK_FIRST := 8.0
## Seconds it stands to cast the mark.
const MARK_CAST := 0.3
## Seconds it stands after a skill's warning ends, or after it lands.
const RECOVER := 0.3
const ELDER := Color("c9a8ff")
## Its shadow while up: an ellipse this much bigger than its body, squashed
## across; it grows and darkens as it falls.
const SHADOW_COLOR := Color(0.05, 0.02, 0.1)
const SHADOW_SIZE := 1.1
const SHADOW_SQUASH := 0.6

var _dive := Dive.NONE
## Seconds of the follow left, then seconds into the fall.
var _follow_left := 0.0
var _fall_time := 0.0
var _fade: Tween


func _ready() -> void:
	super()
	add_skill(&"sky_dive", DIVE_COOLDOWN, INF, 0.0, sky_dive)
	add_skill(&"elder_mark", MARK_COOLDOWN, INF, MARK_FIRST, elder_mark)
	# Used whenever the cone reaches him (his body counts).
	add_skill(&"elder_breath", BREATH_COOLDOWN, BREATH_LENGTH + Lucian.HIT_RADIUS, BREATH_FIRST, elder_breath)


## Up in the air: from the take-off until it lands.
func is_diving() -> bool:
	return _dive != Dive.NONE


## A cone warning at Lucian, then the hit.
func elder_breath() -> float:
	var toward := global_position.direction_to(target.global_position)
	face(target.global_position)
	var warning := GroundWarning.cone(global_position, toward, BREATH_LENGTH, BREATH_ANGLE, BREATH_WARN)
	warning.strike(skill_hit(BREATH_DAMAGE, DamageInfo.Type.MAGIC, &"elder_breath"), target)
	warning_parent.add_child(warning)
	return BREATH_WARN + RECOVER


## Takes off: untargetable, its art fading out, its shadow following Lucian
## (see _physics_process). Busy until it has landed.
func sky_dive() -> float:
	set_untargetable(true)
	_dive = Dive.FOLLOW
	_follow_left = DIVE_FOLLOW
	_fall_time = 0.0
	if _flash_tween:
		_flash_tween.kill()
	visuals.modulate = Color.WHITE
	_fade = create_tween().set_parallel()
	_fade.tween_property(visuals, "modulate:a", 0.0, TAKE_OFF_FADE)
	_fade.tween_property(visuals, "scale", Vector2.ONE * TAKE_OFF_SCALE, TAKE_OFF_FADE)
	_fade.tween_property(health_bar, "modulate:a", 0.0, TAKE_OFF_FADE)
	queue_redraw()
	return DIVE_FOLLOW + DIVE_WARN + RECOVER


## An ElderMark over Lucian; a quick cast.
func elder_mark() -> float:
	face(target.global_position)
	warning_parent.add_child(ElderMark.create(target, skill_hit(MARK_DAMAGE, DamageInfo.Type.TRUE, &"elder_mark"), self))
	return MARK_CAST


## Where it can land for `spot`: there, or moved toward the map's middle
## (its boss point) until a body of `body_radius` fits on walkable ground
## (geometry only). Unchanged without a map.
static func landing_spot(spot: Vector2, map: StageMap, body_radius: float) -> Vector2:
	if map == null:
		return spot
	var middle := map.boss_point
	while not map.is_walkable(spot, body_radius) and spot.distance_to(middle) > LANDING_STEP:
		spot = spot.move_toward(middle, LANDING_STEP)
	return spot if map.is_walkable(spot, body_radius) else middle


func _can_use(id: StringName) -> bool:
	return id != &"sky_dive" or hp <= max_hp * DIVE_HP


## Nothing while up: no walking, no shots, no skills.
func _think(delta: float) -> void:
	if not is_diving():
		super(delta)


## The shot: the data's bolt, in elder colors.
func _attack() -> void:
	fire_bolt(make_hit(), data.projectile_speed, attack_range + BOLT_OVERREACH).color = ELDER


## The dive goes on whether or not Lucian can be fought, so it always lands.
func _physics_process(delta: float) -> void:
	super(delta)
	if not is_alive() or not is_diving():
		return
	if _dive == Dive.FOLLOW:
		_follow(delta)
	else:
		_fall_time += delta
	queue_redraw()


## The shadow flies straight at Lucian, by position: over walls and rocks.
## He stands on the pit's round floor, so it stays over the floor.
func _follow(delta: float) -> void:
	if is_instance_valid(target):
		face(target.global_position)
		global_position = global_position.move_toward(target.global_position, DIVE_SPEED * minf(delta, _follow_left))
	_follow_left -= delta
	if _follow_left <= 0.0:
		_start_fall()


## The shadow stops where its body fits (see landing_spot), and the landing's
## circle warning fills there.
func _start_fall() -> void:
	_dive = Dive.FALL
	global_position = landing_spot(global_position, arena, radius)
	var warning := GroundWarning.circle(global_position, DIVE_RADIUS, DIVE_WARN)
	warning.fired.connect(_land.bind(warning))
	warning_parent.add_child(warning)


## It lands, seen and targetable again: a hit on Lucian inside the circle,
## which pushes him away from its middle. Nothing for a dead dragon.
func _land(warning: GroundWarning) -> void:
	if not is_alive():
		return
	_dive = Dive.NONE
	set_untargetable(false)
	if _fade:
		_fade.kill()
	visuals.modulate.a = 1.0
	visuals.scale = Vector2.ONE
	health_bar.modulate.a = 1.0
	queue_redraw()
	if not (is_instance_valid(target) and warning.covers(target.global_position, Lucian.HIT_RADIUS)):
		return
	if target.take_damage(skill_hit(DIVE_DAMAGE, DamageInfo.Type.MAGIC, &"sky_dive")):
		var away := warning.global_position.direction_to(target.global_position)
		if away == Vector2.ZERO:
			away = Vector2.from_angle(visuals.rotation)
		target.displace(target.global_position + away * DIVE_PUSH, PUSH_SPEED)


func _draw() -> void:
	super()
	if not is_diving():
		return
	# Small and faint while it is high; bigger and darker as it falls.
	var fall := clampf(_fall_time / DIVE_WARN, 0.0, 1.0)
	var shadow := radius * SHADOW_SIZE * lerpf(0.8, 1.2, fall)
	var alpha := lerpf(0.35, 0.6, fall)
	draw_set_transform(Vector2.ZERO, visuals.rotation, Vector2(1.0, SHADOW_SQUASH))
	draw_circle(Vector2.ZERO, shadow * 1.15, Color(SHADOW_COLOR, alpha * 0.4))
	draw_circle(Vector2.ZERO, shadow, Color(SHADOW_COLOR, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
