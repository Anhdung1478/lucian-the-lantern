class_name LevelUpBurst
extends Node2D
## A level gained: a gold ring rising around Lucian from his feet to over his
## head, and "Level 7" floating up above him. A child of Lucian, so it moves
## with him. Low effects keep the text and drop the ring.

## As long as its text lasts.
const LIFETIME := FloatingText.LIFETIME
const COLOR := Color("ffcf5a")
const GLOW_COLOR := Color("fff0b8")
## The ring, seen at a slant: its half width and half height. It shrinks to
## RING_END of that as it rises.
const RING_SIZE := Vector2(48.0, 16.0)
const RING_END := 0.7
const RING_POINTS := 48
## The ring starts at his feet (below his center) and rises this far.
const RING_START := 26.0
const RISE := 96.0
## Sparks on the ring, turning this much (radians) as it rises.
const SPARKS := 8
const SPARK_TURN := 2.0
## The text starts this far above his center (over his HP bar).
const TEXT_HEIGHT := 84.0

var level := 1
var _ring := true
var _age := 0.0


func _init(new_level: int) -> void:
	level = new_level


func _ready() -> void:
	_ring = not GameSettings.instance().low_effects()
	var text := FloatingText.new("Level %d" % level, COLOR)
	text.position = Vector2(0, -TEXT_HEIGHT)
	add_child(text)


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	if _ring:
		queue_redraw()


func _draw() -> void:
	if not _ring:
		return
	var t := _age / LIFETIME
	var fade := 1.0 - t
	# Eased: quick off the ground, slowing as it reaches his head.
	var up := 1.0 - fade * fade
	var center := Vector2(0, RING_START - RISE * up)
	var radius := RING_SIZE * lerpf(1.0, RING_END, up)
	var points := PackedVector2Array()
	for i in RING_POINTS + 1:
		points.append(center + Vector2.from_angle(TAU * i / RING_POINTS) * radius)
	draw_polyline(points, Color(GLOW_COLOR, 0.35 * fade), 9.0, true)
	draw_polyline(points, Color(COLOR, 0.9 * fade), 3.5, true)
	for i in SPARKS:
		var at := center + Vector2.from_angle(TAU * i / SPARKS + SPARK_TURN * up) * radius
		draw_circle(at, 3.0, Color(GLOW_COLOR, fade))
