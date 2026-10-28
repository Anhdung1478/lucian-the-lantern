class_name EnemyData
extends Resource
## One enemy type, with its numbers at Act 1, wave 1. EnemyUnit scales them
## by act and wave; bosses never scale.

## HP, damage and reward growth per act after the first; HP and damage
## growth per wave after the first.
const ACT_HP := 0.6
const ACT_DAMAGE := 0.25
const ACT_REWARD := 0.25
const WAVE_GROWTH := 0.15

@export var id: StringName
@export var display_name := ""
## &"normal", &"elite" or &"boss".
@export var kind := &"normal"
## How it fights: &"melee", &"ranged", &"siege", &"super", or a boss id.
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
## Ranged: the distance band it keeps from Lucian, and its bolt's speed.
@export var keep_min := 0.0
@export var keep_max := 0.0
@export var projectile_speed := 0.0
## Siege: the shell's circle and its warning.
@export var area_radius := 0.0
@export var warn_time := 0.0
## Super: how far Empower reaches.
@export var empower_radius := 0.0
## Bosses: purple essence the first time, and on every later clear.
@export var purple_first := 0
@export var purple_repeat := 0


func hp_scale(act: int, wave: int) -> float:
	if kind == &"boss":
		return 1.0
	return (1.0 + ACT_HP * (act - 1)) * (1.0 + WAVE_GROWTH * (wave - 1))


func damage_scale(act: int, wave: int) -> float:
	if kind == &"boss":
		return 1.0
	return (1.0 + ACT_DAMAGE * (act - 1)) * (1.0 + WAVE_GROWTH * (wave - 1))


func reward_scale(act: int) -> float:
	return 1.0 if kind == &"boss" else 1.0 + ACT_REWARD * (act - 1)
