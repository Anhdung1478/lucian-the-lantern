class_name EnemyHealthBar
extends Node2D
## HP bar drawn above an enemy, with its item statuses (armor shred, Grievous
## Wounds, ...) as small icons above it. Drawn by hand instead of using a
## Control so it can never swallow clicks aimed at the enemy.

const STATUS_SIZE := 22.0
const STATUS_GAP := 3.0

@export var size := Vector2(90, 10)
@export var fill_color := Color("c8312b")

var _ratio := 1.0


func set_health(current: float, maximum: float) -> void:
	_ratio = clampf(current / maximum, 0.0, 1.0)
	queue_redraw()


func _process(_delta: float) -> void:
	if get_parent() is Enemy:
		queue_redraw()


func _draw() -> void:
	var rect := Rect2(-size * 0.5, size)
	draw_rect(rect.grow(2.0), Color(0, 0, 0, 0.8))
	draw_rect(Rect2(rect.position, Vector2(size.x * _ratio, size.y)), fill_color)
	var enemy := get_parent() as Enemy
	if enemy == null:
		return
	var statuses := enemy.statuses()
	var x := -(statuses.size() * (STATUS_SIZE + STATUS_GAP) - STATUS_GAP) * 0.5
	var font := ThemeDB.fallback_font
	for status in statuses:
		var box := Rect2(x, rect.position.y - STATUS_SIZE - 6.0, STATUS_SIZE, STATUS_SIZE)
		draw_rect(box.grow(1.5), Color(0, 0, 0, 0.85))
		if status.icon:
			draw_texture_rect(status.icon, box, false)
		else:
			draw_rect(box, Color(0.5, 0.2, 0.6))
		# The part of the timer that has run out darkens from the top.
		var spent: float = 1.0 - status.left / maxf(status.duration, 0.01)
		draw_rect(Rect2(box.position, Vector2(box.size.x, box.size.y * spent)), Color(0, 0, 0, 0.45))
		if status.stacks > 1:
			var at := Vector2(box.position.x, box.end.y - 1.0)
			draw_string_outline(font, at, str(status.stacks), HORIZONTAL_ALIGNMENT_RIGHT, box.size.x, 13, 4, Color.BLACK)
			draw_string(font, at, str(status.stacks), HORIZONTAL_ALIGNMENT_RIGHT, box.size.x, 13, Color.WHITE)
		x += STATUS_SIZE + STATUS_GAP
