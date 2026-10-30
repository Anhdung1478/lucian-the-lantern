class_name ShotLook
extends Node2D
## How one of Lucian's shots looks, drawn facing +x in its own frame: W's
## missile, an R bullet or a basic attack bolt. A projectile given a look
## (set_look) adds it as a child and stops drawing itself. The static
## helpers are the projectiles' own plain drawing, shared with PlainShotLook.

enum Kind { MISSILE, BULLET, BOLT }

var kind := Kind.BULLET
## Seconds since it was added, for looks that animate.
var age := 0.0
## Low effects, read when it enters the tree: no flicker or spin.
var low := false


func _init(shot_kind := Kind.BULLET) -> void:
	kind = shot_kind


func _ready() -> void:
	low = GameSettings.instance().low_effects()


## A streak with a glow, and a round head when `head_radius` > 0 (W's
## fireball): LinearProjectile's own look.
static func draw_streak(canvas: CanvasItem, color: Color, glow_color: Color, streak_length: float, streak_width: float,
		head_radius: float) -> void:
	canvas.draw_line(Vector2(-streak_length * 1.4, 0), Vector2.ZERO, glow_color, streak_width * 2.6)
	canvas.draw_line(Vector2(-streak_length, 0), Vector2(streak_width * 0.5, 0), color, streak_width)
	if head_radius > 0.0:
		canvas.draw_circle(Vector2.ZERO, head_radius * 1.6, glow_color)
		canvas.draw_circle(Vector2.ZERO, head_radius, color)
		canvas.draw_circle(Vector2.ZERO, head_radius * 0.5, Color.WHITE)


## A short bolt with a glow: AttackProjectile's own look.
static func draw_bolt(canvas: CanvasItem, color: Color, glow_color: Color) -> void:
	canvas.draw_line(Vector2(-30, 0), Vector2.ZERO, glow_color, 8.0)
	canvas.draw_line(Vector2(-20, 0), Vector2(2, 0), color, 3.0)
