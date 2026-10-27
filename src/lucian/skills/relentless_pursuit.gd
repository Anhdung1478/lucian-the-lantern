class_name RelentlessPursuit
extends LucianSkill
## E: a quick dash toward the cursor that resets the attack timer.
## Lightslinger hits lower its cooldown (handled in Lucian.on_damage_dealt).
## The max rank bonus (a kill lowers the cooldown by 1 s) needs enemies that
## can die, so it arrives with them.

@export var min_distance := 160.0
@export var max_distance := 280.0
@export var dash_speed := 1350.0

var _dash_start := Vector2.ZERO
var _was_dashing := false


func execute(aim: Vector2) -> void:
	var distance := clampf(lucian.global_position.distance_to(aim), min_distance, max_distance)
	_dash_start = lucian.global_position
	lucian.start_dash(lucian.aim_direction(aim), distance, dash_speed)
	_was_dashing = true


func _physics_process(delta: float) -> void:
	super(delta)
	# Draw the trail once the dash is over, so it matches where Lucian stopped.
	if _was_dashing and not lucian.is_dashing():
		_was_dashing = false
		var trail := DashTrail.new()
		trail.setup(_dash_start, lucian.global_position)
		lucian.spawn(trail)
