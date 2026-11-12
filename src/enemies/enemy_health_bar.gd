class_name EnemyHealthBar
extends Node2D
## HP bar drawn above an enemy (see UnitBar): a dark frame, a red fill and a
## pale ghost of the health just lost that drains away, with its item
## statuses (armor shred, Grievous Wounds, ...) as small icons above it. An
## elite's has a gold rim and a gold diamond at its left end. Drawn by hand
## instead of using a Control so it can never swallow clicks aimed at the
## enemy. It redraws only when the health or the statuses change, and about
## every REFRESH_TIME while a status shows or the ghost drains, so the
## time-spent shading and the ghost keep moving.

const STATUS_SIZE := 22.0
const STATUS_GAP := 3.0
## Seconds between redraws of the status shading and the ghost.
const REFRESH_TIME := 0.1
const GHOST_COLOR := Color(1.0, 0.9, 0.74)
## The elite's diamond: its half size, and the dark line round it.
const BADGE_SIZE := 7.0
const BADGE_LINE := Color(0.02, 0.03, 0.05)

@export var size := Vector2(90, 10)
@export var fill_color := Color("c8312b")

## Elites: a gold rim, and a small gold diamond at the bar's left end.
var badge := false
## An elite's trait icon (EliteTrait), the first one over the bar. Null = none.
var trait_icon: Texture2D

var _ratio := 1.0
var _ghost := BarGhost.new()
## The enemy's status_version at the last redraw, and the time since it.
var _seen_version := 0
var _since_draw := 0.0


func set_health(current: float, maximum: float) -> void:
	var ratio := clampf(current / maximum, 0.0, 1.0)
	if is_equal_approx(ratio, _ratio):
		return
	_ghost.follow(_ratio, ratio)
	_ratio = ratio
	queue_redraw()


## The share of the bar where the ghost of lost health ends: the health's own
## share when none shows.
func ghost_share() -> float:
	return maxf(_ghost.share, _ratio)


func _process(delta: float) -> void:
	_since_draw += delta
	_ghost.step(delta, _ratio)
	var moving := _ghost.moved
	var enemy := get_parent() as Enemy
	if enemy:
		if enemy.status_version != _seen_version:
			queue_redraw()
			return
		moving = moving or enemy.has_any_status()
	if moving and _since_draw >= REFRESH_TIME:
		queue_redraw()


## What shows over the bar, in order: the trait icon (it never runs out), then
## the enemy's statuses as {id, stacks, left, duration, icon}.
func shown() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	if trait_icon:
		found.append({"id": &"trait", "stacks": 1, "left": 1.0, "duration": 1.0, "icon": trait_icon})
	var enemy := get_parent() as Enemy
	if enemy:
		found.append_array(enemy.statuses())
	return found


func _draw() -> void:
	_since_draw = 0.0
	_ghost.moved = false
	var rect := Rect2(-size * 0.5, size)
	UnitBar.frame(self, rect, UiStyle.GOLD_COLOR if badge else Color.TRANSPARENT)
	UnitBar.fill(self, rect, _ratio, ghost_share(), GHOST_COLOR)
	UnitBar.fill(self, rect, 0.0, _ratio, fill_color)
	if badge:
		var left := Vector2(rect.position.x - UnitBar.FRAME_WIDTH, 0.0)
		var diamond := PackedVector2Array([left + Vector2(0, -BADGE_SIZE), left + Vector2(BADGE_SIZE, 0),
			left + Vector2(0, BADGE_SIZE), left + Vector2(-BADGE_SIZE, 0)])
		draw_colored_polygon(diamond, UiStyle.GOLD_COLOR)
		diamond.append(diamond[0])
		draw_polyline(diamond, BADGE_LINE, 2.0, true)
	var enemy := get_parent() as Enemy
	if enemy == null:
		return
	_seen_version = enemy.status_version
	var statuses := shown()
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
