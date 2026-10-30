class_name PlainShotLook
extends ShotLook
## Classic's shots: the projectiles' own plain streak (W's fireball, R's
## bullets) or bolt (basic attacks), in these colours and sizes.

var color := Color("fffbe8")
var glow_color := Color(1.0, 0.85, 0.45, 0.5)
var streak_length := 26.0
var streak_width := 4.0
var head_radius := 0.0


func _draw() -> void:
	if kind == Kind.BOLT:
		draw_bolt(self, color, glow_color)
	else:
		draw_streak(self, color, glow_color, streak_length, streak_width, head_radius)
