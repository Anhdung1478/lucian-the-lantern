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


## LoL-style tooltip text (BBCode) at the current rank.
func describe() -> String:
	return ""


## What reaching max rank adds, shown after "Rank N:". Empty when nothing.
func max_rank_bonus() -> String:
	return ""


## "80/110/140 (+60/70/80% AD) physical damage", colored like LoL, with the
## current rank lit up.
func damage_text() -> String:
	var r := rank()
	var text := TooltipText.ranked(data.base_damage, r)
	if not data.ad_ratio.is_empty():
		text += " " + TooltipText.ratio(data.ad_ratio, r, "AD")
	if not data.ap_ratio.is_empty():
		text += " " + TooltipText.ratio(data.ap_ratio, r, "AP")
	var words: String = {
		DamageInfo.Type.PHYSICAL: "[phys]physical damage[/phys]",
		DamageInfo.Type.MAGIC: "[magic]magic damage[/magic]",
		DamageInfo.Type.TRUE: "[true]true damage[/true]",
	}[data.damage_type]
	return text + " " + TooltipText.colorize(words)


func _physics_process(delta: float) -> void:
	cooldown.reduce(delta)
