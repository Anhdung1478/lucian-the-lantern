class_name TrainingDummy
extends Enemy
## LoL-style practice dummy. Never dies: HP floors at 1 and refills after
## `reset_delay` seconds without a hit.

@export var reset_delay := 4.0

var _since_hit := 0.0
var _hit_tween: Tween

@onready var visuals: Node2D = $Visuals
@onready var health_bar: EnemyHealthBar = $HealthBar


func _ready() -> void:
	super()
	health_bar.set_health(hp, max_hp)


## Debug table hook. Also refills HP.
func set_defenses(new_armor: float, new_mr: float, new_max_hp: float) -> void:
	armor = new_armor
	mr = new_mr
	max_hp = maxf(new_max_hp, 1.0)
	hp = max_hp
	health_bar.set_health(hp, max_hp)


func _lose_hp(amount: float) -> void:
	hp = maxf(hp - amount, 1.0)
	_since_hit = 0.0
	health_bar.set_health(hp, max_hp)
	_play_hit()


func _physics_process(delta: float) -> void:
	super(delta)
	if hp < max_hp:
		_since_hit += delta
		if _since_hit >= reset_delay:
			hp = max_hp
			health_bar.set_health(hp, max_hp)


func _play_hit() -> void:
	if _hit_tween:
		_hit_tween.kill()
	visuals.modulate = Color(1.8, 1.8, 1.8)
	visuals.rotation = 0.12 if randf() < 0.5 else -0.12
	_hit_tween = create_tween().set_parallel()
	_hit_tween.tween_property(visuals, "modulate", Color.WHITE, 0.15)
	_hit_tween.tween_property(visuals, "rotation", 0.0, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
