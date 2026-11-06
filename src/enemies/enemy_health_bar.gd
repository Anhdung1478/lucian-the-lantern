class_name EnemyHealthBar
extends Node2D
## HP bar drawn above an enemy, with its item statuses (armor shred, Grievous
## Wounds, ...) as small icons above it. Drawn by hand instead of using a
## Control so it can never swallow clicks aimed at the enemy. It redraws only
## when the health or the statuses change, and about every REFRESH_TIME while
## a status shows, so the time-spent shading keeps moving.

const STATUS_SIZE := 22.0
const STATUS_GAP := 3.0
## Seconds between redraws of the status shading.
const REFRESH_TIME := 0.1

@export var size := Vector2(90, 10)
@export var fill_color := Color("c8312b")

## Elites: a small gold diamond at the bar's left end.
var badge := false

var _ratio := 1.0
## The enemy's status_version at the last redraw, and the time since it.
var _seen_version := 0
var _since_draw := 0.0


func set_health(current: float, maximum: float) -> void:
	var ratio := clampf(current / maximum, 0.0, 1.0)
	if is_equal_approx(ratio, _ratio):
		return
	_ratio = ratio
	queue_redraw()


func _process(delta: float) -> void:
	var enemy := get_parent() as Enemy
	if enemy == null:
		return
	_since_draw += delta
	if enemy.status_version != _seen_version or (enemy.has_any_status() and _since_draw >= REFRESH_TIME):
		queue_redraw()


func _draw() -> void:
	_since_draw = 0.0
	var rect := Rect2(-size * 0.5, size)
	draw_rect(rect.grow(2.0), Color(0, 0, 0, 0.8))
	draw_rect(Rect2(rect.position, Vector2(size.x * _ratio, size.y)), fill_color)
	if badge:
		var left := Vector2(rect.position.x, 0.0)
		var diamond := PackedVector2Array([left + Vector2(0, -6), left + Vector2(6, 0), left + Vector2(0, 6), left + Vector2(-6, 0)])
		draw_colored_polygon(diamond, UiStyle.GOLD_COLOR)
		diamond.append(diamond[0])
		draw_polyline(diamond, Color.BLACK, 2.0)
	var enemy := get_parent() as Enemy
	if enemy == null:
		return
	_seen_version = enemy.status_version
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
