class_name DashTrail
extends Node2D
## A dash's trail: light streaks from where the dash started, growing behind
## Lucian as he goes, that fade out once the dash is over.

## Seconds the trail takes to fade after the dash.
const LIFETIME := 0.3
const STREAK_OFFSETS := [-14.0, 0.0, 14.0]
## E's light blue. Item dashes pass their own color.
const LIGHT := Color(0.62, 0.77, 1.0)

var color := LIGHT
## From the start of the dash to Lucian.
var length := 0.0


func setup(from: Vector2, trail_color := LIGHT) -> void:
	position = from
	color = trail_color


## Stretches the trail up to `to` (Lucian) while the dash goes on.
func reach(to: Vector2) -> void:
	length = position.distance_to(to)
	if length > 0.0:
		rotation = (to - position).angle()
	queue_redraw()


## The dash is over: fade out.
func finish() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME)
	tween.tween_callback(queue_free)


func _draw() -> void:
	draw_rect(Rect2(0, -24, length, 48), Color(color, 0.18))
	var streak := Color(color.lerp(Color.WHITE, 0.6), 0.7)
	for offset: float in STREAK_OFFSETS:
		draw_line(Vector2(0, offset), Vector2(length, offset), streak, 3.0)
