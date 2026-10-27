class_name PiercingLight
extends LucianSkill
## Q: after a short cast, fires a laser toward the aim point that hits every
## enemy in a line. Max rank makes the laser wider.

## The beam is drawn from the guns, not from Lucian's center.
const GUN_REACH := 44.0

@export var cast_time := 0.3
@export var length := 1000.0
@export var width := 60.0
@export var max_rank_width := 90.0

var _fire_in := 0.0
var _direction := Vector2.RIGHT


func execute(aim: Vector2) -> void:
	_direction = lucian.aim_direction(aim)
	lucian.visuals.face(_direction)
	lucian.lock_cast(cast_time)
	_fire_in = cast_time


func _physics_process(delta: float) -> void:
	super(delta)
	if _fire_in > 0.0:
		_fire_in -= delta
		if _fire_in <= 0.0:
			_fire()


func _fire() -> void:
	var beam_width := max_rank_width if is_max_rank() else width
	var origin := lucian.global_position
	var box := RectangleShape2D.new()
	box.size = Vector2(length, beam_width)
	var xform := Transform2D(_direction.angle(), origin + _direction * length * 0.5)
	var damage := data.damage_at(rank(), lucian.stats)
	for enemy in lucian.query_enemies(box, xform):
		enemy.take_damage(DamageInfo.create(damage, data.damage_type, data.id, lucian))
	var beam := LaserBeam.new()
	beam.setup(origin + _direction * GUN_REACH, _direction, length - GUN_REACH, beam_width)
	lucian.spawn(beam)
