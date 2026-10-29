class_name JungleBuffs
extends RefCounted
## The jungle buffs a camp's elite leaves Lucian when it dies: stat buffs he
## holds for DURATION seconds (Lucian.add_jungle_buff). Blue gives mana regen
## and ability haste. Red gives HP regen, and while he holds it his attacks
## burn their target and his attacks and skills slow it (see
## Lucian.on_damage_dealt).

const BLUE := &"blue_buff"
const RED := &"red_buff"
const DURATION := 60.0
## Stat bonuses, keyed like UnitStats.at_level's bonus (regen per second).
const BLUE_BONUS := {&"mana_regen": 10.0, &"ability_haste": 20.0}
const RED_BONUS := {&"hp_regen": 5.0}
## Red's on-hit: attacks burn for RED_BURN true damage per second, attacks and
## skills slow by RED_SLOW.
const RED_BURN := 15.0
const RED_BURN_TIME := 3.0
const RED_SLOW := 0.15
const RED_SLOW_TIME := 1.5
const BLUE_ICON := preload("res://assets/art/ui/buff_blue.svg")
const RED_ICON := preload("res://assets/art/ui/buff_red.svg")


## `id` is Blue or Red.
static func is_jungle_buff(id: StringName) -> bool:
	return id == BLUE or id == RED


## The stat bonus of buff `id`; empty for an unknown id.
static func bonus(id: StringName) -> Dictionary:
	match id:
		BLUE:
			return BLUE_BONUS
		RED:
			return RED_BONUS
	return {}


## The buff row's name: Blue's, else Red's.
static func display_name(id: StringName) -> String:
	return "Crest of Insight" if id == BLUE else "Crest of Cinders"


## The buff row's icon: Blue's, else Red's.
static func icon(id: StringName) -> Texture2D:
	return BLUE_ICON if id == BLUE else RED_ICON


## The buff row's hover text.
static func text(id: StringName) -> String:
	if id == BLUE:
		return TooltipText.colorize("+%d [mana]mana regen[/mana] per second and +%d ability haste." % [
			roundi(BLUE_BONUS[&"mana_regen"]), roundi(BLUE_BONUS[&"ability_haste"])])
	return TooltipText.colorize(("+%d [hp]health regen[/hp] per second. Basic attacks burn for [true]%d true damage[/true] "
		+ "per second for %d s, and basic attacks and skills slow by %d%% for %s s.") % [
			roundi(RED_BONUS[&"hp_regen"]), roundi(RED_BURN), roundi(RED_BURN_TIME), roundi(RED_SLOW * 100.0),
			TooltipText.number(RED_SLOW_TIME)])
