class_name ClarityBurst
extends Node2D
## Clarity's effect on Lucian: blue motes spiralling in from a ring around
## him, then a small flash as he takes them in. A child of Lucian, so it moves
## with him.

const LIFETIME := 0.9
const COLOR := Color("8fb8ff")
const CORE_COLOR := Color("eef4ff")
const MOTES := 10
## The motes start this far out and turn this much (radians) on the way in.
const START_RADIUS := 70.0
const END_RADIUS := 8.0
const TURN := 2.6
## The share of the life spent spiralling in; the flash takes the rest.
const GATHER := 0.75

var _age := 0.0


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _age / LIFETIME
	if t < GATHER:
		var g := t / GATHER
		# Eased so the motes speed up as they close in.
		var radius := lerpf(START_RADIUS, END_RADIUS, g * g)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(COLOR, 0.35 * (1.0 - g)), 2.0, true)
		for i in MOTES:
			var point := Vector2.from_angle(TAU * i / MOTES + TURN * g) * radius
			var size := lerpf(4.0, 2.5, g)
			draw_circle(point, size + 3.0, Color(COLOR, 0.35))
			draw_circle(point, size, COLOR)
			draw_circle(point, size * 0.45, CORE_COLOR)
	else:
		var f := (t - GATHER) / (1.0 - GATHER)
		draw_circle(Vector2.ZERO, lerpf(14.0, 46.0, f), Color(COLOR, 0.45 * (1.0 - f)))
		draw_arc(Vector2.ZERO, lerpf(20.0, 56.0, f), 0.0, TAU, 64, Color(CORE_COLOR, 0.7 * (1.0 - f)), 3.0, true)
