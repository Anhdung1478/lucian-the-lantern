class_name StageSetup
extends RefCounted
## What Lucian starts a stage with: Evolution Tree purchases, the equipped
## skin and the Journey loadout. A plain StageSetup.new() is the sandbox
## that stage.tscn uses on its own (tests, screenshots, F6): every rank
## bought, 6 equip slots, Flash and Heal.

const SPELL_IDS: Array[StringName] = [&"flash", &"ghost", &"barrier", &"heal", &"clarity", &"smite"]

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
var skin: SkinData = Skins.ALL[0]


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
	setup.skin = Skins.find(save.skin)
	return setup
