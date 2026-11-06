class_name ItemData
extends Resource
## One fragment, legendary item, potion or pair of boots. Stats use ItemStats
## keys.

enum Kind { FRAGMENT, LEGENDARY, POTION, BOOTS }

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
## Boots: 1 (bought in the Evolution Tree), 2 or 3 (upgraded at the merchant).
@export var boots_tier := 0
## Boots of tier 3: the tier-2 boots id they are upgraded from. Tier 2 is
## upgraded from either tier-1 boots, so it leaves this empty.
@export var upgrade_from: StringName
## Boots of tier 2 and 3: the fragment id the merchant's upgrade takes.
@export var upgrade_fragment: StringName
## Boots of tier 2 and 3: the gold fee the upgrade costs.
@export var upgrade_cost := 0


func is_fragment() -> bool:
	return kind == Kind.FRAGMENT


func is_potion() -> bool:
	return kind == Kind.POTION


func is_boots() -> bool:
	return kind == Kind.BOOTS


## Rounded down; the epsilon keeps 1300 x 0.7 at 910 despite float error.
## Boots can't be sold: 0.
func sell_price() -> int:
	if is_boots():
		return 0
	return floori(cost * sell_ratio + 0.0001)
