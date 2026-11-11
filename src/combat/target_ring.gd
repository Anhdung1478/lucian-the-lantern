class_name TargetRing
extends Node2D
## A thin red ring on the ground under the enemy Lucian is ordered to attack.
## A child of Lucian that does not move with him (top level): it follows the
## target, fades in on a new one and goes when the order goes. An extra
## (Juice.on()). It redraws only when the target changes.

const COLOR := Color(1.0, 0.25, 0.2, 0.75)
const WIDTH := 2.0
## The ring lies this far outside the target's radius.
const MARGIN := 6.0
const POINTS := 48
## Seconds to fade in on a new target, and to fade out when it goes.
const FADE_IN := 0.12
const FADE_OUT := 0.15

var _lucian: Lucian
var _target: Enemy
var _radius := 0.0


func _init() -> void:
	top_level = true
	z_index = UnitShadow.Z
	modulate.a = 0.0


func _ready() -> void:
	_lucian = get_parent() as Lucian


## The enemy the ring sits under, or null while it is hidden.
func target() -> Enemy:
	return _target


func _process(delta: float) -> void:
	var now := _lucian.attack_target() if Juice.on() else null
	if now != _target and now != null:
		_target = now
		_radius = now.radius + MARGIN
		modulate.a = 0.0
		queue_redraw()
	if now == null:
		modulate.a = maxf(modulate.a - delta / FADE_OUT, 0.0)
		if modulate.a == 0.0:
			_target = null
		return
	global_position = now.global_position
	modulate.a = minf(modulate.a + delta / FADE_IN, 1.0)


func _draw() -> void:
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, POINTS, COLOR, WIDTH, true)
