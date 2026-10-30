class_name PulsefireTrail
extends FxTrail
## Pulsefire's E: fading blue afterimages of Lucian along the dash, a pale
## band, and a ring at each end.

const BAND := Color(0.5, 0.85, 1.0, 0.12)
const RING := Color(0.5, 0.85, 1.0, 0.6)
const IMAGE := Color(0.5, 0.8, 1.0)
## Where the afterimages stand, as shares of the trail, oldest first.
const IMAGES := [0.2, 0.4, 0.6, 0.8]
const RING_RADIUS := 26.0


func _draw() -> void:
	draw_rect(Rect2(0, -18, length, 36), BAND)
	draw_arc(Vector2.ZERO, RING_RADIUS, 0.0, TAU, 32, RING, 2.0)
	draw_arc(Vector2(length, 0), RING_RADIUS, 0.0, TAU, 32, RING, 2.0)
	if body == null:
		return
	var half := body.get_size() * 0.5
	for i in IMAGES.size():
		draw_texture(body, Vector2(IMAGES[i] * length, 0) - half, Color(IMAGE, 0.15 + 0.15 * i))
