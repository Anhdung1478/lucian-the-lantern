class_name ClarityBurst
extends Node2D
## Clarity's effect on Lucian: a radiant sapphire-cyan vertical shimmer, blue
## motes spiralling inward from an arcane ring around him, and a crisp double
## ripple burst as he absorbs the mana. A child of Lucian, so it moves with him.

const LIFETIME := 0.9
const COLOR := Color("6fa8ff")
const CYAN := Color("8be6ff")
const CORE_COLOR := Color("eef7ff")
const MOTES := 10
## The motes start this far out and turn this much (radians) on the way in.
const START_RADIUS := 72.0
const END_RADIUS := 8.0
const TURN := 2.8
## The share of the life spent spiralling in; the flash takes the rest.
const GATHER := 0.72

var _age := 0.0


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := clampf(_age / LIFETIME, 0.0, 1.0)
	var fade := 1.0 - t
	# Radiant vertical mana shimmer rising around Lucian.
	var shimmer_a := sin(t * PI) * 0.85
	SoftShape.ellipse(self, Vector2(0.0, -14.0 * t), Vector2(32.0, 58.0), Color(COLOR, 0.26 * shimmer_a), 0.25)
	SoftShape.ellipse(self, Vector2(0.0, -18.0 * t), Vector2(14.0, 44.0), Color(CYAN, 0.34 * shimmer_a), 0.3)
	if t < GATHER:
		var g := t / GATHER
		# Eased so the motes speed up as they close in.
		var radius := lerpf(START_RADIUS, END_RADIUS, g * g)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(COLOR, 0.38 * (1.0 - g * 0.7)), 2.2, true)
		draw_arc(Vector2.ZERO, radius * 1.14, 0.0, TAU, 56, Color(CYAN, 0.22 * (1.0 - g)), 1.5, true)
		for i in MOTES:
			var ang := TAU * i / MOTES + TURN * g
			var point := Vector2.from_angle(ang) * radius
			# Trailing mana tail behind each spiralling mote.
			var tail_ang := ang - 0.32 * (0.4 + g)
			var tail_pt := Vector2.from_angle(tail_ang) * minf(radius * 1.12, START_RADIUS)
			draw_line(tail_pt, point, Color(CYAN, 0.45 * (1.0 - g * 0.3)), 2.4, true)
			var size := lerpf(4.2, 2.8, g)
			draw_circle(point, size + 3.2, Color(COLOR, 0.34))
			draw_circle(point, size, CYAN)
			draw_circle(point, size * 0.48, CORE_COLOR)
	else:
		var f := (t - GATHER) / (1.0 - GATHER)
		var out := 1.0 - (1.0 - f) * (1.0 - f)
		var burst_a := 1.0 - f
		SoftShape.ellipse(self, Vector2.ZERO, Vector2.ONE * lerpf(18.0, 54.0, out), Color(COLOR, 0.5 * burst_a), 0.25)
		ClassicStar.draw(self, Vector2.ZERO, lerpf(36.0, 14.0, f), PI * 0.25, Color(CORE_COLOR, 0.9 * burst_a), 0.16)
		# Double expanding mana absorption rings.
		draw_arc(Vector2.ZERO, lerpf(18.0, 66.0, out), 0.0, TAU, 64, Color(CORE_COLOR, 0.78 * burst_a), lerpf(3.4, 0.9, f), true)
		draw_arc(Vector2.ZERO, lerpf(10.0, 48.0, f), 0.0, TAU, 56, Color(CYAN, 0.62 * burst_a), lerpf(2.6, 0.7, f), true)
	# Subtle outer glow fading smoothly across entire lifetime.
	draw_arc(Vector2.ZERO, lerpf(28.0, 74.0, t), 0.0, TAU, 48, Color(COLOR, 0.22 * fade * fade), 1.6, true)
