class_name LaserBeam
extends Node2D
## Q's beam: a bright gold-white line that fades out. Dark Lucian's Q sets
## its own colors.

const LIFETIME := 0.25

## The wide glow, the core, and the thin line in the middle.
var glow_color := Color(1.0, 0.8, 0.35, 0.35)
var core_color := Color(1.0, 0.95, 0.75, 0.85)
var center_color := Color.WHITE

## The beam's size: along its rotation, and across.
var length := 0.0
var width := 0.0


func setup(from: Vector2, direction: Vector2, beam_length: float, beam_width: float) -> void:
	position = from
	rotation = direction.angle()
	length = beam_length
	width = beam_width


func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)


func _draw() -> void:
	draw_rect(Rect2(0, -width * 0.5, length, width), glow_color)
	draw_rect(Rect2(0, -width * 0.22, length, width * 0.44), core_color)
	draw_rect(Rect2(0, -width * 0.08, length, width * 0.16), center_color)
