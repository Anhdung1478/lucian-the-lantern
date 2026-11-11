class_name UnitShadow
extends Node2D
## A soft dark ellipse on the ground under a unit, sized to its radius and
## lying a little down and to the right of it: the light comes from the
## top-left. A child of the unit's body, never of its art, so it never turns
## with it. It is drawn at Z: under every unit and every ground warning, over
## the floor. `lift` takes the unit off the ground (a leap, a throw): its
## shadow shrinks, fades and moves further off.

## Under the units and the warnings (0), over the floor (StageMap.FLOOR_Z).
const Z := -1
const COLOR := Color(0.0, 0.01, 0.03, 0.5)
## Its half size and where its middle lies, in shares of the unit's radius.
const SIZE := Vector2(1.3, 1.1)
const OFFSET := Vector2(0.16, 0.3)
## At full lift: its size and alpha as shares of those on the ground, and how
## much further off it lies (a share of the radius).
const LIFT_SIZE := 0.6
const LIFT_ALPHA := 0.45
const LIFT_SHIFT := Vector2(0.3, 0.55)

@export var radius := 30.0:
	set(value):
		radius = value
		_place()
		queue_redraw()
## 0 on the ground, 1 at the top of a leap.
var lift := 0.0:
	set(value):
		lift = clampf(value, 0.0, 1.0)
		_place()


func _init() -> void:
	z_index = Z


func _ready() -> void:
	_place()


## Where it lies and how big and dark it is, for this lift. No redraw: the
## ellipse is drawn once, for the unit on the ground.
func _place() -> void:
	position = LIFT_SHIFT * radius * lift
	scale = Vector2.ONE * lerpf(1.0, LIFT_SIZE, lift)
	self_modulate.a = lerpf(1.0, LIFT_ALPHA, lift)


func _draw() -> void:
	SoftShape.ellipse(self, OFFSET * radius, SIZE * radius, COLOR)
