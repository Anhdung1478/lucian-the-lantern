class_name ArdentBlaze
extends LucianSkill
## W: a missile that bursts in a cross on the first enemy or at max range,
## dealing magic damage and marking every enemy hit. Lucian's other hits on a
## marked enemy give him a burst of move speed. Max rank makes the cross bigger.

const MARK := &"ardent_blaze"

@export var cast_time := 0.2
@export var missile_speed := 1600.0
@export var missile_range := 900.0
## Size of one bar of the cross.
@export var bar_size := Vector2(400, 60)
@export var max_rank_scale := 1.4
@export var mark_duration := 6.0
@export var move_speed_bonus: Array[float] = [60.0, 65.0, 70.0, 75.0, 80.0]
@export var move_speed_duration := 1.0

var _fire_in := 0.0
var _direction := Vector2.RIGHT


func execute(aim: Vector2) -> void:
	_direction = lucian.aim_direction(aim)
	lucian.visuals.face(_direction)
	lucian.lock_cast(cast_time)
	_fire_in = cast_time


## The missile's flight, ending in the cross it bursts into.
func cast_range() -> CastRange:
	var shape := CastRange.line(Lucian.GUN_REACH + missile_range, 32.0)
	shape.cross = bar_size * (max_rank_scale if is_max_rank() else 1.0)
	return shape


func describe() -> String:
	return TooltipText.colorize(
		"Lucian fires a missile that bursts in a cross on the first enemy hit or at max range, dealing %s and marking enemies for [kw]%s s[/kw]. "
		+ "Lucian's other hits on a marked enemy grant him %s [ms]move speed[/ms] for [kw]%s s[/kw]."
	) % [damage_text(), TooltipText.number(mark_duration), TooltipText.ranked(move_speed_bonus, rank()),
		TooltipText.number(move_speed_duration)]


func max_rank_bonus() -> String:
	return "The cross is %d%% bigger." % roundi((max_rank_scale - 1.0) * 100.0)


func current_move_speed_bonus() -> float:
	return move_speed_bonus[clampi(rank() - 1, 0, move_speed_bonus.size() - 1)]


func _physics_process(delta: float) -> void:
	super(delta)
	if _fire_in > 0.0:
		_fire_in -= delta
		if _fire_in <= 0.0:
			_launch()


func _launch() -> void:
	var missile := LinearProjectile.new()
	missile.launch(lucian.global_position + _direction * Lucian.GUN_REACH, _direction, missile_speed, missile_range, 16.0)
	missile.color = Color("ffd27a")
	missile.glow_color = Color(1.0, 0.45, 0.1, 0.6)
	missile.streak_length = 40.0
	missile.streak_width = 8.0
	missile.head_radius = 11.0
	# Deferred: physics queries are locked while area overlaps are reported.
	missile.finished.connect(_explode, CONNECT_DEFERRED)
	lucian.spawn(missile)
	Sfx.play(&"cast_w")


func _explode(at: Vector2) -> void:
	var bar := RectangleShape2D.new()
	bar.size = bar_size * (max_rank_scale if is_max_rank() else 1.0)
	var angle := _direction.angle()
	var enemies := lucian.query_enemies(bar, Transform2D(angle, at))
	for enemy in lucian.query_enemies(bar, Transform2D(angle + PI / 2.0, at)):
		if not enemies.has(enemy):
			enemies.append(enemy)
	var damage := data.damage_at(rank(), lucian.stats)
	for enemy in enemies:
		enemy.take_damage(lucian.make_damage(damage, data.damage_type, data.id))
		enemy.add_mark(MARK, mark_duration)
	var blast := CrossBlast.new()
	blast.setup(at, _direction, bar.size)
	lucian.spawn(blast)
