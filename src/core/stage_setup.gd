class_name StageSetup
extends RefCounted
## What Lucian starts a stage with: Evolution Tree purchases, the equipped
## skin and the Journey loadout. A plain StageSetup.new() is the sandbox
## that stage.tscn uses on its own (tests, screenshots, F6): every rank
## bought, 6 equip slots, Flash and Heal.

const SPELL_IDS: Array[StringName] = [&"flash", &"ghost", &"barrier", &"heal", &"clarity", &"smite"]

## Act 1's only stage: the tutorial, the first time it is played.
const TUTORIAL_STAGE := "1-1"

## The stage played (0 for Training): its act, stage and "act-stage" id. The
## sandbox pays like act 1.
var act := 0
var stage := 0
var stage_id := ""
var bought: Array[int] = [5, 5, 5, 3]
var passive := true
var equip_slots := Inventory.EQUIP_SIZE
var shop_slots := 2
var refresh_cost := MerchantStock.REFRESH_COST
## Spell ids on D and F (&"" for none), and how many of the keys are open.
var summoners: Array[StringName] = [&"flash", &"heal"]
var summoner_slots := 2
## Spell id -> upgrade value: a cooldown share off for Flash and Ghost
## (negative), an effect share added for the others.
var summoner_upgrades := {}
## Flat stats from the tree's stat nodes, keyed like ItemStats.
var stat_bonus := {}
## Tree economy bonuses, as shares (0.1 = +10%).
var gold_bonus := 0.0
var xp_bonus := 0.0
var essence_bonus := 0.0
var skin: SkinData = Skins.ALL[0]
## Shown on the HUD and the result panel.
var display_name := "Training"
## The boss wave's enemy id, or &"" for none.
var boss := &""
## Act 1's first play: one gun, no skills or summoners; Senna fights too.
var tutorial := false
## An Endless run, and its map choice (a Journey.ENDLESS_MAPS index; 0 is
## Random, rolled again on Retry). `act` and `stage` then only pick the map.
var endless := false
var map_choice := 0
## The Endless modifier's reward multipliers (EndlessModifiers.apply_rewards):
## gold, blue, the orange drop chance and repeat purple. 1 = none.
var gold_mult := 1.0
var blue_mult := 1.0
var orange_mult := 1.0
var purple_mult := 1.0


## The setup a save's tree, equipped skin and loadout give.
static func from_save(save: SaveGame) -> StageSetup:
	var tree := save.tree
	var setup := StageSetup.new()
	setup.bought = [tree.level(&"skill_q"), tree.level(&"skill_w"), tree.level(&"skill_e"), tree.level(&"skill_r")]
	setup.passive = tree.level(&"passive") > 0
	setup.equip_slots = int(tree.value(&"equip_slots"))
	setup.shop_slots = int(tree.value(&"merchant_stock"))
	setup.refresh_cost = int(tree.value(&"refresh_cost"))
	setup.summoner_slots = 1 + tree.level(&"summoner_slot_2")
	setup.summoners = []
	for i in 2:
		var id := save.loadout[i]
		setup.summoners.append(id if i < setup.summoner_slots and tree.level(id) > 0 else &"")
	for id in SPELL_IDS:
		var upgrade := StringName("%s_upgrade" % id)
		if tree.level(upgrade) > 0:
			setup.summoner_upgrades[id] = tree.value(upgrade)
	for data in tree.nodes():
		if data.stat_key != &"" and tree.level(data.id) > 0:
			setup.stat_bonus[data.stat_key] = setup.stat_bonus.get(data.stat_key, 0.0) + tree.value(data.id)
	setup.gold_bonus = tree.value(&"stage_gold")
	setup.xp_bonus = tree.value(&"bonus_xp")
	setup.essence_bonus = tree.value(&"essence_drop")
	setup.skin = Skins.find(save.skin)
	return setup


## A Journey stage: the save's setup plus the stage, its boss, and the
## tutorial's limits on Act 1's first play. Thresh only comes that first time.
static func for_stage(save: SaveGame, act_number: int, stage_number: int) -> StageSetup:
	var setup := from_save(save)
	setup.act = act_number
	setup.stage = stage_number
	setup.stage_id = Journey.stage_id(act_number, stage_number)
	setup.display_name = Journey.stage_name(act_number, stage_number)
	setup.boss = WavePlan.boss(setup.stage_id)
	if setup.stage_id == TUTORIAL_STAGE:
		if TUTORIAL_STAGE in save.cleared:
			setup.boss = &""
		else:
			setup.tutorial = true
			setup.bought.assign([0, 0, 0, 0])
			setup.passive = false
			setup.summoners.assign([&"", &""])
	return setup


## An Endless run: the save's setup on the map `choice` names (Random rolls one
## with `rng`), with no boss.
static func for_endless(save: SaveGame, choice: int, rng: RandomNumberGenerator) -> StageSetup:
	var setup := from_save(save)
	setup.endless = true
	setup.map_choice = choice
	var map := EndlessPlan.resolve_map(choice, rng)
	var place := EndlessPlan.map_for(map)
	setup.act = place.x
	setup.stage = place.y
	setup.stage_id = EndlessPlan.STAGE_ID
	setup.display_name = "Endless · %s" % EndlessPlan.map_name(map)
	setup.boss = &""
	return setup
