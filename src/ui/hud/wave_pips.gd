class_name WavePips
extends Control
## A stage's waves as a row of small diamonds, in the stage info: gold for a
## wave cleared, bright with a soft glow for the one being fought, dim for
## those to come. The boss wave's pip is larger. Endless has none (its waves
## never end).

enum State { CLEARED, CURRENT, AHEAD }

## A pip's half-width, the boss wave's, and the room between two pips.
const PIP := 6.0
const BOSS_PIP := 9.0
const GAP := 6.0
const CLEARED_COLOR := UiStyle.GOLD_COLOR
const CLEARED_RIM := UiStyle.BORDER_COLOR
const CURRENT_COLOR := Color("fff8e0")
const AHEAD_COLOR := Color(0.13, 0.15, 0.2)
const AHEAD_RIM := UiStyle.CELL_BORDER
## The glow under the current pip: how far it reaches (in pips) and how strong.
const GLOW_REACH := 3.4
const GLOW_COLOR := Color(UiStyle.GOLD_COLOR, 0.75)

## The stage's waves, the boss wave included.
var total := 0
## The last wave is a boss wave.
var boss := false
## The wave being fought, or the last one fought (WaveRunner.wave).
var wave := 0
var fighting := false


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


## Shows `total_waves` pips with the runner at `current`.
func show_waves(total_waves: int, has_boss: bool, current: int, is_fighting: bool) -> void:
	if total_waves == total and has_boss == boss and current == wave and is_fighting == fighting:
		return
	total = total_waves
	boss = has_boss
	wave = current
	fighting = is_fighting
	var width := 0.0
	for i in range(1, total + 1):
		width += pip_size(i) * 2.0 + (GAP if i > 1 else 0.0)
	custom_minimum_size = Vector2(width, BOSS_PIP * 2.0)
	queue_redraw()


## Wave `index` (1-based) for a runner on `current`: cleared once it is
## behind, or once its fight is over.
static func state_of(index: int, current: int, is_fighting: bool) -> State:
	if index < current or (index == current and not is_fighting):
		return State.CLEARED
	return State.CURRENT if index == current else State.AHEAD


## Wave `index`'s half-width: larger for the boss wave.
func pip_size(index: int) -> float:
	return BOSS_PIP if boss and index == total else PIP


func _draw() -> void:
	var x := 0.0
	var y := size.y * 0.5
	for i in range(1, total + 1):
		var half := pip_size(i)
		var at := Vector2(x + half, y)
		var points := Plate.diamond(at, half)
		var outline := Plate.diamond(at, half)
		outline.append(outline[0])
		match state_of(i, wave, fighting):
			State.CLEARED:
				draw_colored_polygon(points, CLEARED_COLOR)
				draw_polyline(outline, CLEARED_RIM, 1.0, true)
			State.CURRENT:
				var reach := half * GLOW_REACH
				draw_texture_rect(JourneyMap.glow(), Rect2(at - Vector2.ONE * reach, Vector2.ONE * reach * 2.0), false, GLOW_COLOR)
				draw_colored_polygon(points, CURRENT_COLOR)
				draw_polyline(outline, CLEARED_COLOR, 1.0, true)
			State.AHEAD:
				draw_colored_polygon(points, AHEAD_COLOR)
				draw_polyline(outline, AHEAD_RIM, 1.0, true)
		x += half * 2.0 + GAP
