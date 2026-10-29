class_name RelentlessPursuit
extends LucianSkill
## E: a quick dash toward the cursor that resets the attack timer.
## Lightslinger hits lower its cooldown (handled in Lucian.on_damage_dealt).
## The max rank bonus (a kill lowers the cooldown by 1 s) is applied in
## Lucian.on_kill.

## Seconds a kill takes off the cooldown at max rank.
const KILL_CUT := 1.0

@export var min_distance := 0.0
@export var max_distance := 280.0
@export var dash_speed := 1350.0


func execute(aim: Vector2) -> void:
	var distance := clampf(lucian.global_position.distance_to(aim), min_distance, max_distance)
	lucian.start_dash(lucian.aim_direction(aim), distance, dash_speed)
	Sfx.play(&"cast_e")


func cast_range() -> CastRange:
	return CastRange.dash(max_distance, min_distance)


func describe() -> String:
	return TooltipText.colorize(
		"Lucian dashes toward the cursor, up to [kw]%d[/kw] units, passing through enemies, and resets his basic attack timer. "
		+ "[kw]Lightslinger[/kw] hits lower this cooldown."
	) % max_distance


func max_rank_bonus() -> String:
	return "Killing an enemy lowers this cooldown by 1 s."
