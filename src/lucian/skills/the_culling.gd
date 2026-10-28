class_name TheCulling
extends LucianSkill
## R: for a few seconds, fires a stream of bullets in one direction from
## alternating guns while Lucian keeps moving. Pressing R again stops it.
## At max rank the bullets pierce, losing damage with each enemy hit.

@export var duration := 3.0
@export var shots := 22
@export var bullet_speed := 2800.0
@export var bullet_range := 1200.0
@export var pierce_falloff := 0.15
@export var pierce_minimum := 0.3

## The guns are this far each side of Lucian's aim line.
const MUZZLE_SPREAD := 15.0

var _channel_left := 0.0
var _direction := Vector2.RIGHT
var _next_shot_in := 0.0
var _shots_left := 0
var _gun := LucianVisuals.Gun.LEFT


func is_channeling() -> bool:
	return _channel_left > 0.0


func stop() -> void:
	_channel_left = 0.0
	_shots_left = 0


func execute(aim: Vector2) -> void:
	_direction = lucian.aim_direction(aim)
	_channel_left = duration
	_shots_left = shots
	_next_shot_in = 0.0


## Two streams of bullets, one from each gun.
func cast_range() -> CastRange:
	return CastRange.twin(Lucian.GUN_REACH + bullet_range, MUZZLE_SPREAD)


func describe() -> String:
	return TooltipText.colorize(
		"Lucian fires [kw]%d[/kw] shots in one direction over [kw]%s s[/kw], each dealing %s to the first enemy hit. "
		+ "He can move and use Relentless Pursuit while firing, but cannot attack or use Q or W. Press R again to stop early."
	) % [shots, TooltipText.number(duration), damage_text()]


func max_rank_bonus() -> String:
	return "Shots pierce, dealing %d%% less damage for each enemy already hit (down to %d%%)." % [
		roundi(pierce_falloff * 100.0), roundi(pierce_minimum * 100.0)]


func _physics_process(delta: float) -> void:
	super(delta)
	if _channel_left <= 0.0:
		return
	# Runs after Lucian's own movement, so he keeps facing the stream.
	lucian.visuals.face(_direction)
	_channel_left -= delta
	_next_shot_in -= delta
	while _shots_left > 0 and _next_shot_in <= 0.0:
		_fire()
		_next_shot_in += duration / shots
	if _channel_left <= 0.0:
		stop()


func _fire() -> void:
	_shots_left -= 1
	_gun = LucianVisuals.Gun.RIGHT if _gun == LucianVisuals.Gun.LEFT else LucianVisuals.Gun.LEFT
	var bullet := LinearProjectile.new()
	bullet.launch(lucian.visuals.muzzle_position(_gun), _direction, bullet_speed, bullet_range, 10.0, is_max_rank())
	bullet.streak_length = 36.0
	bullet.streak_width = 5.0
	bullet.hit_enemy.connect(_on_bullet_hit)
	lucian.spawn(bullet)
	lucian.flash_muzzle(_gun)


func _on_bullet_hit(enemy: Enemy, prior_hits: int) -> void:
	var damage := data.damage_at(rank(), lucian.stats)
	if is_max_rank():
		damage *= DamageCalc.falloff_multiplier(prior_hits, pierce_falloff, pierce_minimum)
	enemy.take_damage(lucian.make_damage(damage, data.damage_type, data.id))
