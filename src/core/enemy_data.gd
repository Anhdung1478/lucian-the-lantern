class_name EnemyData
extends Resource
## One enemy type, with its numbers at Act 1, wave 1. EnemyUnit scales them
## by act and wave; bosses and mini bosses never scale.

## HP, damage and reward growth per act after the first; HP and damage
## growth per wave after the first.
const ACT_HP := 0.6
const ACT_DAMAGE := 0.25
const ACT_REWARD := 0.25
const WAVE_GROWTH := 0.15
## The kinds with a boss-size health bar, a skull on the radar, the boss
## bar, no scaling and a first-time purple reward.
const BOSS_KINDS: Array[StringName] = [&"mini_boss", &"boss"]

@export var id: StringName
@export var display_name := ""
## &"normal", &"elite", &"mini_boss" or &"boss".
@export var kind := &"normal"
## How it fights: &"melee", &"ranged", &"siege", &"super" (a Minion);
## &"swarm", &"flank", &"brute", &"spit", &"flee" (a Monster); or a boss id.
@export var behavior := &"melee"
@export var art: Texture2D
@export var max_hp := 100.0
@export var armor := 0.0
@export var mr := 0.0
## One basic attack's damage, and its type.
@export var damage := 10.0
@export var damage_type := DamageInfo.Type.PHYSICAL
@export var attack_range := 110.0
## Seconds between attacks.
@export var attack_interval := 1.25
@export var move_speed := 300.0
## Body and click size.
@export var radius := 28.0
@export var gold := 0
@export var xp := 0
## Ranged and spit: the distance band it keeps from Lucian, and its bolt's
## speed.
@export var keep_min := 0.0
@export var keep_max := 0.0
@export var projectile_speed := 0.0
## Siege: the shell's circle and its warning.
@export var area_radius := 0.0
@export var warn_time := 0.0
## Super: how far Empower reaches.
@export var empower_radius := 0.0
## What a basic attack that lands (a melee hit or a bolt) leaves on Lucian:
## a slow (a fraction) for `hit_slow_time` seconds, and a burn (damage per
## second, of burn_type) for `hit_burn_time` seconds. 0 = none.
@export var hit_slow := 0.0
@export var hit_slow_time := 0.0
@export var hit_burn := 0.0
@export var hit_burn_time := 0.0
## The burn's damage type when it isn't the hit's (Red: a physical hit, a
## magic burn); -1 = damage_type.
@export_enum("Same as the hit:-1", "Physical:0", "Magic:1", "True:2") var hit_burn_type := -1
## Bosses and mini bosses: purple essence the first time, and on every
## later clear (a boss) or kill (a mini boss).
@export var purple_first := 0
@export var purple_repeat := 0
## The map's camp (StageMap.camps) it spawns from in a wave; &"" (or a map
## without that camp) = the spawn points in turn.
@export var camp := &""
## Its death brings `split_count` enemies of id `split_into` where it died.
@export var split_into := &""
@export var split_count := 0
## Seconds alive before it escapes: no rewards, done for the wave. 0 = never.
@export var escape_after := 0.0
## Essence on top of what its kind gives: blue (raised by Essence Drops like
## the rest), and orange for sure.
@export var extra_blue := 0
@export var extra_orange := 0
## The jungle buff (JungleBuffs.BLUE or RED) Lucian gets when it dies. &"" = none.
@export var buff_on_kill := &""


## A boss or a mini boss.
func is_boss_kind() -> bool:
	return kind in BOSS_KINDS


## The damage type of its on-hit burn: hit_burn_type, else its hit's.
func burn_type() -> DamageInfo.Type:
	return damage_type if hit_burn_type < 0 else hit_burn_type as DamageInfo.Type


func hp_scale(act: int, wave: int) -> float:
	if is_boss_kind():
		return 1.0
	return (1.0 + ACT_HP * (act - 1)) * (1.0 + WAVE_GROWTH * (wave - 1))


func damage_scale(act: int, wave: int) -> float:
	if is_boss_kind():
		return 1.0
	return (1.0 + ACT_DAMAGE * (act - 1)) * (1.0 + WAVE_GROWTH * (wave - 1))


func reward_scale(act: int) -> float:
	return 1.0 if is_boss_kind() else 1.0 + ACT_REWARD * (act - 1)
