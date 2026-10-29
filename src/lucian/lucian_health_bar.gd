class_name LucianHealthBar
extends Node2D
## Lucian's HP bar above his head, green like the HUD's, with his shields as a
## white segment after the HP. A child of Lucian's body, not of his Visuals,
## so it never turns with him. Drawn by hand, so it never swallows clicks.
## Under it, a red word while crowd control holds him ("Stunned").

const SIZE := Vector2(90, 10)
const FILL := Color(0.25, 0.68, 0.29)
const SHIELD := Color(0.92, 0.94, 0.97, 0.9)
const CC_COLOR := Color("ff4040")
const CC_FONT_SIZE := 14

@onready var lucian: Lucian = get_parent()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(-SIZE * 0.5, SIZE)
	draw_rect(rect.grow(2.0), Color(0, 0, 0, 0.8))
	var max_hp := lucian.stats.max_hp
	var hp_share := clampf(lucian.hp / max_hp, 0.0, 1.0)
	var shield_share := minf(lucian.total_shield() / max_hp, 1.0)
	# Like the HUD bar: the shield follows the HP, pushed back from the end when both don't fit.
	var shield_start := minf(hp_share, 1.0 - shield_share)
	draw_rect(Rect2(rect.position, Vector2(SIZE.x * hp_share, SIZE.y)), FILL)
	if shield_share > 0.0:
		draw_rect(Rect2(rect.position + Vector2(SIZE.x * shield_start, 0), Vector2(SIZE.x * shield_share, SIZE.y)), SHIELD)
	var word := _cc_word()
	if word != "":
		var font := ThemeDB.fallback_font
		var at := Vector2(rect.position.x, rect.end.y + 2.0 + CC_FONT_SIZE)
		draw_string_outline(font, at, word, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, CC_FONT_SIZE, 4, Color.BLACK)
		draw_string(font, at, word, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, CC_FONT_SIZE, CC_COLOR)


## The strongest crowd control on Lucian as a word (stun, then fear, then
## root), or "" when none holds him.
func _cc_word() -> String:
	for kind: CrowdControl.Kind in Lucian.CC_DEBUFFS:
		if lucian.has_cc(kind):
			return Lucian.CC_DEBUFFS[kind].name
	return ""
