class_name ItemData
extends Resource
## One fragment, legendary item or potion. Stats use ItemStats keys.

enum Kind { FRAGMENT, LEGENDARY, POTION }

@export var id: StringName
@export var display_name := ""
@export var kind := Kind.FRAGMENT
## Short label drawn when there is no icon: the fragment code (AD, AS, ...),
## or a few letters of a legendary's name.
@export var code := ""
@export var icon: Texture2D
@export var cost := 0
## Share of the cost the merchant pays back (Guardian Angel: 0.4).
@export var sell_ratio := 0.7
@export var stats: Dictionary[StringName, float] = {}
## The two fragment ids a legendary is crafted from.
@export var components: Array[StringName] = []
@export var effects: Array[ItemEffect] = []
## How many fit in one cell. Only potions stack.
@export var max_stack := 1
## Potions: HP and mana restored over `restore_time` seconds.
@export var restore_hp := 0.0
@export var restore_mana := 0.0
@export var restore_time := 0.0


func is_fragment() -> bool:
	return kind == Kind.FRAGMENT


func is_potion() -> bool:
	return kind == Kind.POTION


## Rounded down; the epsilon keeps 1300 x 0.7 at 910 despite float error.
func sell_price() -> int:
	return floori(cost * sell_ratio + 0.0001)
