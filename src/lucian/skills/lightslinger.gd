class_name Lightslinger
extends Node
## Passive: after any skill cast, the next basic attack shoots twice. Shots
## take turns between the guns, so the second comes from the other one. Each
## one that hits lowers E's cooldown.

@export var second_shot_ratio := 0.6
@export var second_shot_delay := 0.15
@export var e_cooldown_reduction := 1.0

## Bought in the Evolution Tree. Unlearned, skills never charge the second shot.
var learned := true
var charged := false

var _second_shot_target: Enemy
var _second_shot_in := 0.0

@onready var lucian: Lucian = owner


func describe() -> String:
	return TooltipText.colorize(
		"After using a skill, Lucian's next basic attack fires a second shot from his other gun for [ad]%d%% AD[/ad] [phys]physical damage[/phys]. "
		+ "The second shot can critically strike. Each Lightslinger shot that hits lowers [kw]Relentless Pursuit[/kw]'s cooldown by [kw]%s s[/kw]."
	) % [roundi(second_shot_ratio * 100.0), TooltipText.number(e_cooldown_reduction)]


func charge() -> void:
	if not learned:
		return
	charged = true


## Lucian's basic attack: one shot, or two when charged.
func fire_basic_attack(target: Enemy) -> void:
	lucian.fire_attack_projectile(lucian.next_gun(), target, lucian.basic_attack(target))
	if charged:
		charged = false
		_second_shot_target = target
		_second_shot_in = second_shot_delay


func _physics_process(delta: float) -> void:
	if _second_shot_in <= 0.0:
		return
	_second_shot_in -= delta
	if _second_shot_in <= 0.0 and is_instance_valid(_second_shot_target):
		var info := lucian.roll_attack(second_shot_ratio, &"lightslinger")
		lucian.fire_attack_projectile(lucian.next_gun(), _second_shot_target, info)
