class_name BossBar
extends Control
## Under the stage info while a boss or a mini boss lives: its name over a
## wide red health bar. It finds the unit itself (a boss before a mini boss).
## `phase_text` is for Act 6's Thresh ("Phase 1 / 2").

const SIZE := Vector2(600, 22)
const FILL := Color("c8312b")

var boss: EnemyUnit
var phase_text := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(SIZE.x, SIZE.y + 30.0)
	visible = false


## Keeps the unit it holds while it lives, even untargetable (out of the
## enemies group), except that a boss takes the bar from a mini boss.
func _process(_delta: float) -> void:
	var held := is_instance_valid(boss) and boss.is_alive()
	if not (held and boss.data.kind == &"boss"):
		var found := _find(&"boss")
		if found == null and not held:
			found = _find(&"mini_boss")
		if found or not held:
			boss = found
	visible = boss != null
	queue_redraw()


func _find(kind: StringName) -> EnemyUnit:
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if enemy is EnemyUnit and (enemy as EnemyUnit).data.kind == kind:
			return enemy
	return null


func _draw() -> void:
	if boss == null:
		return
	var font := ThemeDB.fallback_font
	var title := boss.data.display_name + ("   " + phase_text if phase_text != "" else "")
	draw_string_outline(font, Vector2(0, 20), title, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 20, 5, Color.BLACK)
	draw_string(font, Vector2(0, 20), title, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 20, UiStyle.TITLE_COLOR)
	var bar := Rect2(0, 28, SIZE.x, SIZE.y)
	draw_rect(bar.grow(2.0), Color(0, 0, 0, 0.85))
	draw_rect(Rect2(bar.position, Vector2(SIZE.x * clampf(boss.hp / boss.max_hp, 0.0, 1.0), SIZE.y)), FILL)
	var text := "%d / %d" % [roundi(boss.hp), roundi(boss.max_hp)]
	draw_string_outline(font, bar.position + Vector2(0, 17), text, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 15, 4, Color.BLACK)
	draw_string(font, bar.position + Vector2(0, 17), text, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 15, Color.WHITE)
