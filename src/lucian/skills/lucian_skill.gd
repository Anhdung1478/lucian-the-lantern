class_name LucianSkill
extends Node
## Base for Q / W / E / R. Owns the cooldown; Lucian.try_cast decides whether
## a cast is allowed and pays for it, then calls execute().

@export var slot: ChampionProgress.Slot
@export var data: SkillData

var cooldown := Cooldown.new()

@onready var lucian: Lucian = owner


func rank() -> int:
	return lucian.progress.ranks[slot]


func is_max_rank() -> bool:
	return rank() >= data.max_rank


## Cost of the next cast; shows the rank 1 cost before the skill is learned.
func mana_cost() -> float:
	return data.value_at(data.mana_cost, maxi(rank(), 1))


func cooldown_seconds() -> float:
	return data.value_at(data.cooldown, rank())


func execute(_aim: Vector2) -> void:
	pass


func _physics_process(delta: float) -> void:
	cooldown.reduce(delta)
