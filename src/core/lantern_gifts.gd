class_name LanternGifts
extends RefCounted
## The Lantern's gift (design doc §14): halfway through a story stage that
## has 4 or more waves, the player picks one of three boons, drawn from
## these eight, until the stage ends. Data and pure helpers: the stage offers
## and applies a gift, Lucian wears its stats, KillRewards reads its gold.

## No gift: before the pick, and in a stage without one.
const NONE := 0
const COUNT := 8
## Cards drawn for a pick.
const OFFERED := 3
## Stages with fewer waves have no gift (Act 1's tutorial).
const MIN_WAVES := 4
## The buff row's id and name, and its hover text: the gift's name, then its
## effect.
const BUFF := &"lantern_gift"
const BUFF_NAME := "The Lantern's gift"
const TEXT := "The Lantern's gift: %s. %s until the stage ends."
## Id -> its card's name, text and icon, and what it changes (missing = none):
## - scale: Lucian's stat multipliers, keyed like StatBlock (as a skin's scale);
## - flat: stats it adds, keyed like ItemStats (as the tree's);
## - gold_mult: the kills' gold.
const ROWS := {
	1: {
		"name": "Keen Edge", "text": "+10% attack damage",
		"icon": "res://assets/art/stats/ad.svg", "scale": {&"ad": 1.1},
	},
	2: {
		"name": "Quick Hands", "text": "+12% attack speed",
		"icon": "res://assets/art/stats/attack_speed.svg", "scale": {&"attack_speed": 1.12},
	},
	3: {
		"name": "Focus", "text": "+15 ability haste",
		"icon": "res://assets/art/stats/ability_haste.svg", "flat": {&"ability_haste": 15.0},
	},
	4: {
		"name": "Second Wind", "text": "+150 max health",
		"icon": "res://assets/art/stats/max_hp.svg", "flat": {&"max_hp": 150.0},
	},
	5: {
		"name": "Light Step", "text": "+6% move speed",
		"icon": "res://assets/art/stats/move_speed.svg", "scale": {&"move_speed": 1.06},
	},
	6: {
		"name": "Thirst", "text": "+6% omnivamp",
		"icon": "res://assets/art/stats/omnivamp.svg", "flat": {&"omnivamp": 0.06},
	},
	7: {
		"name": "Ward", "text": "+20 armor and +20 magic resist",
		"icon": "res://assets/art/stats/armor.svg", "flat": {&"armor": 20.0, &"mr": 20.0},
	},
	8: {
		"name": "Fortune", "text": "+20% gold from kills",
		"icon": "res://assets/art/ui/gold.svg", "gold_mult": 1.2,
	},
}


## The wave after which stage runs of `waves` waves offer a gift; 0 for none.
static func offer_wave(waves: int) -> int:
	return waves / 2 if waves >= MIN_WAVES else 0


## OFFERED different gifts at random.
static func offer(rng: RandomNumberGenerator) -> Array[int]:
	var pool: Array[int] = []
	for id in range(1, COUNT + 1):
		pool.append(id)
	var cards: Array[int] = []
	for i in OFFERED:
		cards.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	return cards


static func display_name(id: int) -> String:
	return Lang.t(_row(id).get("name", ""))


static func text(id: int) -> String:
	return Lang.t(_row(id).get("text", ""))


static func icon(id: int) -> Texture2D:
	var path: String = _row(id).get("icon", "")
	return load(path) if path != "" else null


## Lucian's stat multipliers, keyed like StatBlock.
static func scale(id: int) -> Dictionary[StringName, float]:
	var found: Dictionary[StringName, float] = {}
	found.assign(_row(id).get("scale", {}))
	return found


## The stats it adds, keyed like ItemStats.
static func flat(id: int) -> Dictionary[StringName, float]:
	var found: Dictionary[StringName, float] = {}
	found.assign(_row(id).get("flat", {}))
	return found


## Gift `id`'s buff row for the HUD: its icon, no timer, its card's text.
static func buff(id: int) -> Dictionary:
	return {"id": BUFF, "name": Lang.t(BUFF_NAME), "icon": icon(id),
		"text": Lang.t(TEXT) % [display_name(id), text(id)], "count": "", "left": 0.0, "duration": 0.0, "ready": false}


static func gold_mult(id: int) -> float:
	return _row(id).get("gold_mult", 1.0)


static func _row(id: int) -> Dictionary:
	return ROWS.get(id, {})
