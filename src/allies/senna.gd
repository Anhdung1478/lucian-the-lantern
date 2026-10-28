class_name Senna
extends Node2D
## Act 1's ally: follows Lucian, behind and to his left, and shoots the
## nearest enemy in reach. Enemies never target her (she isn't one of
## "enemies" and has no body), so she can't die before the cutscene.

const ART := preload("res://assets/art/npc/senna.svg")
## Her place next to Lucian, turned with him.
const FOLLOW_OFFSET := Vector2(-150, -90)
const SPEED := 380.0
const REACH := 900.0
const DAMAGE := 45.0
const INTERVAL := 1.5
const SHOT_COLOR := Color("b8fff0")
const SHOT_GLOW := Color(0.5, 1.0, 0.9, 0.5)

var lucian: Lucian
var projectile_parent: Node
var visuals := Node2D.new()

var _attack_left := 0.0


func _ready() -> void:
	add_to_group(&"allies")
	var sprite := Sprite2D.new()
	sprite.texture = ART
	visuals.add_child(sprite)
	add_child(visuals)
	if projectile_parent == null:
		projectile_parent = get_parent()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(lucian):
		return
	var spot := lucian.global_position + FOLLOW_OFFSET.rotated(lucian.visuals.rotation)
	var offset := spot - global_position
	if offset.length() > 12.0:
		global_position += offset.normalized() * minf(SPEED * delta * (1.0 + offset.length() / 400.0), offset.length())
		visuals.rotation = offset.angle()
	_attack_left = maxf(_attack_left - delta, 0.0)
	var target := _nearest_enemy()
	if target == null:
		return
	visuals.rotation = (target.global_position - global_position).angle()
	if _attack_left <= 0.0:
		_attack_left = INTERVAL
		var shot := AttackProjectile.new()
		shot.color = SHOT_COLOR
		shot.glow_color = SHOT_GLOW
		shot.launch(global_position + Vector2.from_angle(visuals.rotation) * 50.0, target, DamageInfo.create(DAMAGE, DamageInfo.Type.PHYSICAL, &"senna", self))
		projectile_parent.add_child(shot)
		Sfx.play(&"shot", -10.0)


func _nearest_enemy() -> Enemy:
	var best: Enemy = null
	var best_distance := REACH
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		var distance := global_position.distance_to(enemy.global_position)
		if distance <= best_distance:
			best = enemy
			best_distance = distance
	return best
