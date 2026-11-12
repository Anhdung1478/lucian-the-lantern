class_name EliteRing
extends Node2D
## A thin ring on the ground under an elite with a trait, in the trait's
## color. A child of the unit's body, drawn at the shadow's depth: under the
## units and every ground warning, over the floor.

const WIDTH := 3.0
const ALPHA := 0.75
## How far past the unit's radius it lies.
const GAP := 10.0

var color := Color.WHITE
var radius := 30.0


func _init() -> void:
	z_index = UnitShadow.Z


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius + GAP, 0.0, TAU, 48, Color(color, ALPHA), WIDTH, true)
