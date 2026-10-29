class_name ElderMark
extends Node2D
## Elder's Mark over Lucian: a ring round him that empties as the TIME
## counts down, and the mark's sigil over his head. Then he takes its hit
## through take_damage (a boss skill's true damage: shields absorb it and
## Banshee's Veil blocks it), LOW_HP_SCALE times as much when his HP is
## under LOW_HP of his max as it lands. It goes away harmless when Lucian is
## dead or in stasis, or its caster is dead.
##
## The caster puts it on its warnings' layer, drawn over the units
## (z_index); it puts itself on Lucian every frame.

const TIME := 4.0
## Under this share of max HP as it lands, the hit is LOW_HP_SCALE times as much.
const LOW_HP := 0.25
const LOW_HP_SCALE := 3.0
const ICON := preload("res://assets/art/ui/elder_mark.svg")
const ICON_SIZE := 48.0
## The sigil sits over Lucian's HP bar.
const ICON_AT := Vector2(0, -Lucian.HEALTH_BAR_HEIGHT - 38.0)
const RING_RADIUS := 58.0
const COLOR := Color("b48cff")
const GLOW := Color("efe6ff")
## The ring's color while Lucian is low enough for the bigger hit.
const DANGER := Color("ff4a6a")
const Z := 5

var lucian: Lucian
var hit: DamageInfo
## Its death ends the mark (null: none).
var caster: Enemy
var time_left := TIME

var _has_caster := false


## A mark on `victim` that lands `mark_hit` after TIME.
static func create(victim: Lucian, mark_hit: DamageInfo, by: Enemy = null) -> ElderMark:
	var mark := ElderMark.new()
	mark.lucian = victim
	mark.hit = mark_hit
	mark.caster = by
	mark._has_caster = by != null
	mark.z_index = Z
	mark.position = victim.global_position
	return mark


## How much of the countdown has gone, 0 to 1.
func progress() -> float:
	return clampf(1.0 - time_left / TIME, 0.0, 1.0)


## Lucian is under LOW_HP: the mark would land LOW_HP_SCALE times over.
func is_boosted() -> bool:
	return is_instance_valid(lucian) and lucian.hp < lucian.stats.max_hp * LOW_HP


func _physics_process(delta: float) -> void:
	if not _holds():
		queue_free()
		return
	global_position = lucian.global_position
	time_left -= delta
	queue_redraw()
	if time_left > 0.0:
		return
	if is_boosted():
		hit.amount *= LOW_HP_SCALE
	lucian.take_damage(hit)
	queue_free()


func _process(_delta: float) -> void:
	if _holds():
		global_position = lucian.global_position


## Lucian can still take it, and its caster lives.
func _holds() -> bool:
	if not is_instance_valid(lucian) or lucian.dead or lucian.in_stasis():
		return false
	return not _has_caster or (is_instance_valid(caster) and caster.is_alive())


func _draw() -> void:
	var color := DANGER if is_boosted() else COLOR
	var left := 1.0 - progress()
	# The faint full ring, then what is left of the countdown, from the top.
	draw_circle(Vector2.ZERO, RING_RADIUS, Color(color, 0.08))
	draw_arc(Vector2.ZERO, RING_RADIUS, 0.0, TAU, 64, Color(color, 0.3), 3.0, true)
	draw_arc(Vector2.ZERO, RING_RADIUS, -PI * 0.5, -PI * 0.5 + TAU * left, 64, color, 6.0, true)
	draw_arc(Vector2.ZERO, RING_RADIUS, -PI * 0.5, -PI * 0.5 + TAU * left, 64, Color(GLOW, 0.7), 2.0, true)
	# The sigil swells a little as it nears.
	var side := ICON_SIZE * (1.0 + 0.2 * progress())
	draw_texture_rect(ICON, Rect2(ICON_AT - Vector2(side, side) * 0.5, Vector2(side, side)), false)
