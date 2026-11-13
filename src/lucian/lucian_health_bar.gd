class_name LucianHealthBar
extends Node2D
## Lucian's HP bar above his head, of the enemies' bars' family (UnitBar) but
## green like the HUD's: a dark frame, a fill, a pale red ghost of the health
## just lost that drains away, a tick every 100 HP (a taller one every
## 1000), and his shields as a white segment after the HP. A child of
## Lucian's body, not of his Visuals, so it never turns with him. Drawn by
## hand, so it never swallows clicks. Under it, a red word while crowd
## control holds him ("Stunned"). It redraws only when what it shows has
## changed, and about every REFRESH_TIME while the ghost drains.

const SIZE := Vector2(90, 10)
const FILL := Color(0.25, 0.68, 0.29)
const SHIELD := Color(0.92, 0.94, 0.97, 0.9)
const GHOST_COLOR := Color(1.0, 0.62, 0.5)
const CC_COLOR := Color("ff4040")
## Big enough to read at game zoom (at 14 it was a dark smudge under the
## outline); "Stunned", the longest word, still fits the bar's width.
const CC_FONT_SIZE := 18
## A tick every TICK HP, down TICK_HEIGHT of the bar; every BIG_TICK HP one
## down the whole bar. Small ticks closer than TICK_GAP are left out.
const TICK := 100.0
const BIG_TICK := 1000.0
const TICK_HEIGHT := 0.45
const TICK_GAP := 4.0
const TICK_COLOR := Color(0.02, 0.03, 0.05, 0.6)
## Seconds between redraws while the ghost drains.
const REFRESH_TIME := 0.1
## The bar is compared at this many steps per pixel: regen alone redraws it
## only once it has moved that far.
const STEPS := 2.0

var _ghost := BarGhost.new()
var _hp_share := 1.0
## What the last redraw showed: the HP and shield ends (in steps), the max
## HP and the word under the bar.
var _shown := Vector3i(-1, -1, -1)
var _shown_word := ""
var _since_draw := 0.0

@onready var lucian: Lucian = get_parent()


func _process(delta: float) -> void:
	_since_draw += delta
	var share := clampf(lucian.hp / lucian.stats.max_hp, 0.0, 1.0)
	if share != _hp_share:
		_ghost.follow(_hp_share, share)
		_hp_share = share
	_ghost.step(delta, share)
	var word := _cc_word()
	if _showing() != _shown or word != _shown_word:
		queue_redraw()
	elif _ghost.moved and _since_draw >= REFRESH_TIME:
		queue_redraw()


## The share of the bar where the ghost of lost health ends: the health's own
## share when none shows.
func ghost_share() -> float:
	return maxf(_ghost.share, _hp_share)


## What the bar shows now: the HP and shield ends (in steps) and the max HP.
func _showing() -> Vector3i:
	var steps := SIZE.x * STEPS
	var max_hp := lucian.stats.max_hp
	return Vector3i(roundi(_hp_share * steps), roundi(minf(lucian.total_shield() / max_hp, 1.0) * steps), roundi(max_hp))


func _draw() -> void:
	_since_draw = 0.0
	_ghost.moved = false
	_shown = _showing()
	var rect := Rect2(-SIZE * 0.5, SIZE)
	UnitBar.frame(self, rect)
	var max_hp := lucian.stats.max_hp
	var shield_share := minf(lucian.total_shield() / max_hp, 1.0)
	# Like the HUD bar: the shield follows the HP, pushed back from the end when both don't fit.
	var shield_start := minf(_hp_share, 1.0 - shield_share)
	UnitBar.fill(self, rect, _hp_share, ghost_share(), GHOST_COLOR)
	UnitBar.fill(self, rect, 0.0, _hp_share, FILL)
	_draw_ticks(rect, max_hp)
	if shield_share > 0.0:
		UnitBar.fill(self, rect, shield_start, shield_start + shield_share, SHIELD)
	_shown_word = _cc_word()
	if _shown_word != "":
		var font := ThemeDB.fallback_font
		var at := Vector2(rect.position.x, rect.end.y + 2.0 + CC_FONT_SIZE)
		draw_string_outline(font, at, _shown_word, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, CC_FONT_SIZE, 4, Color.BLACK)
		draw_string(font, at, _shown_word, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, CC_FONT_SIZE, CC_COLOR)


## A thin dark line at every TICK HP of `max_hp` across `rect`, from its top.
func _draw_ticks(rect: Rect2, max_hp: float) -> void:
	for x in tick_marks(max_hp):
		var at := rect.position.x + rect.size.x * x.x
		draw_line(Vector2(at, rect.position.y), Vector2(at, rect.position.y + rect.size.y * x.y), TICK_COLOR, 1.0)


## The ticks of a bar of `max_hp`: each as (its share of the bar's width, its
## share of the bar's height). One every TICK HP (left out when they would
## lie closer than TICK_GAP), a full-height one every BIG_TICK HP.
static func tick_marks(max_hp: float) -> PackedVector2Array:
	var marks := PackedVector2Array()
	var small := SIZE.x * TICK / maxf(max_hp, 1.0) >= TICK_GAP
	var hp := TICK
	while hp < max_hp:
		var big := is_zero_approx(fmod(hp, BIG_TICK))
		if big or small:
			marks.append(Vector2(hp / max_hp, 1.0 if big else TICK_HEIGHT))
		hp += TICK
	return marks


## The strongest crowd control on Lucian as a word (stun, then fear, then
## root), or "" when none holds him.
func _cc_word() -> String:
	for kind: CrowdControl.Kind in Lucian.CC_DEBUFFS:
		if lucian.has_cc(kind):
			return Lang.t(Lucian.CC_DEBUFFS[kind].name)
	return ""
