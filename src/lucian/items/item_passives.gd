class_name ItemPassives
extends Node
## The item passives that work in combat, for Lucian's equipped items and
## boots only. Each item counts once however many copies are equipped.
##
## Lucian calls the hooks: adjust_stats (stat passives), on_cast, on_moved,
## on_basic_attack (counters and "next attack" effects, as the shot leaves
## the gun), before_damage (damage multipliers, at impact) and
## on_damage_dealt (on-hit damage and statuses on the target). Item damage
## uses the item's id as its source and never triggers on-hit effects again.
## Defensive passives react to hits on Lucian: before_damage_taken (Banshee's),
## delay_damage (Death's Dance), before_hp_loss (Shieldbow), on_damage_taken
## (Thornmail, Kaenic Rookern, the Noxian shields), on_lethal (Guardian
## Angel), on_kill (Death's Dance, Slay) and on_enemy_slowed (Fimbulwinter).
## Boots add damage_taken_multiplier (Plating), heal_scale (Now and Forever)
## and on_summoner_used (Noxian Haste). "Champion" triggers count any enemy.

const ENERGIZED: Array[StringName] = [&"statikk_shiv", &"rapid_firecannon", &"stormrazor"]
const ATTACK_SOURCES: Array[StringName] = [&"basic", &"lightslinger"]
const SKILL_SOURCES: Array[StringName] = [&"q", &"w", &"r"]
const ENERGIZED_ICON := preload("res://assets/art/ui/buff_energized.svg")

# Numbers from docs/items.md and docs/implementation/phase3.md.
const IE_CRIT_DAMAGE := 0.4
const KRAKEN_DAMAGE := 140.0
const KRAKEN_LOW_HP_BONUS := 0.5
const NASHOR_BASE := 15.0
const NASHOR_AP := 0.2
const NAVORI_CUT := 0.12
const SPELLBLADE_BASE_AD := 1.0
const SPELLBLADE_BONUS_AD := 0.4
const SPELLBLADE_MANA := 0.4
const SPELLBLADE_COOLDOWN := 1.5
const MURAMANA_SKILL := 0.03
const MURAMANA_ATTACK := 0.015
const CARVE_DURATION := 6.0
const CARVE_MAX := 6
const FERVOR_SPEED := 20.0
const FERVOR_DURATION := 2.0
const GRIEVOUS_DURATION := 3.0
const GIANT_SLAYER_MAX := 0.15
const GIANT_SLAYER_HP_GAP := 1500.0
const CINDERBLOOM_HP := 0.4
const CINDERBLOOM_BONUS := 0.2
const SHOJIN_PER_STACK := 0.03
const SHOJIN_MAX := 4
const SHOJIN_DURATION := 6.0
const MANA_CHARGE_STEP := 3.0
const MANA_CHARGE_MAX := 360.0
const AWE_AP := 0.02
const AWE_HP := 0.08
const AWE_AD := 0.025
const RABADON_AP := 1.3
const SPIRIT_VISAGE_POWER := 0.25
const RUNAAN_BOLTS := 2
const RUNAAN_RANGE := 450.0
const RUNAAN_AD := 0.55
const STATIKK_BASE := 90.0
const STATIKK_AP := 0.2
const STATIKK_TARGETS := 5
const STATIKK_JUMP := 500.0
const RFC_DAMAGE := 60.0
const RFC_RANGE := 0.35
## Seconds the RFC ring waits for the Energized shot to land before giving up
## (its target may vanish).
const RFC_RING_WAIT := 1.0
const STORMRAZOR_DAMAGE := 90.0
const STORMRAZOR_SPEED := 0.35
const STORMRAZOR_DURATION := 1.5
const JAKSHO_PER_STACK := 0.05
const JAKSHO_MAX := 6
## Seconds after dealing damage that count as "in combat".
const COMBAT_TIME := 3.0
const HATEFOG_COOLDOWN := 3.0
const SCORN_HASTE := 20.0
const ANNUL_COOLDOWN := 40.0
const THORNS_BASE := 20.0
const THORNS_BONUS_ARMOR := 0.1
const LIFELINE_HP := 0.3
const LIFELINE_MIN := 300.0
const LIFELINE_MAX := 650.0
const LIFELINE_TIME := 3.0
const LIFELINE_COOLDOWN := 90.0
const IGNORE_PAIN := 0.3
const IGNORE_PAIN_TIME := 3.0
const DEFY_HEAL := 0.15
const DEFY_TIME := 2.0
const EVERLASTING_BASE := 100.0
const EVERLASTING_MANA := 0.05
const EVERLASTING_TIME := 3.0
const EVERLASTING_COOLDOWN := 8.0
const REBIRTH_STASIS := 4.0
const REBIRTH_HP := 0.5
const REBIRTH_MANA := 0.3
const REBIRTH_COOLDOWN := 300.0
const MAGEBANE_WAIT := 15.0
const MAGEBANE_SHIELD := 0.15
# Boots (docs/items.md, Boots).
const SLAY_BOOTS: Array[StringName] = [&"gluttonous_greaves", &"immortal_path"]
const SLAY_KINDS: Array[StringName] = [&"elite", &"mini_boss", &"boss"]
const SLAY_OMNIVAMP := 0.006
const SLAY_MAX := 10
const FOREVER_HP := 0.5
const FOREVER_DAMAGE := 1.04
const FOREVER_HEAL := 1.12
## Swiftmarch: adaptive force per point of move speed, and the AD one point gives.
const NOXIAN_FERVOR := 0.05
const ADAPTIVE_AD := 0.6
const NOXIAN_HASTE_SPEED := 0.08
const NOXIAN_HASTE_TIME := 4.0
const NOXIAN_HASTE_COOLDOWN := 4.0
const NOXIAN_SHIELD_MIN := 100.0
const NOXIAN_SHIELD_MAX := 200.0
const NOXIAN_SHIELD_HP := 0.08
const NOXIAN_SHIELD_TIME := 5.0
const NOXIAN_SHIELD_COOLDOWN := 15.0
const PLATING_BOOTS: Array[StringName] = [&"plated_steelcaps", &"armored_advance"]
const PLATING := 0.9

var lucian: Lucian
var energize := EnergizeCharge.new()
## Basic attacks landed toward Kraken Slayer's third (0-2).
var kraken_hits := 0
var shojin_stacks := 0
## Archangel's Staff's max mana bonus. Kept for the stage, even unequipped.
var mana_charge := 0.0
var jaksho_stacks := 0
var spellblade_ready := false
## Gluttonous Greaves and Immortal Path's Slay: elite, mini boss and boss
## kills this stage (up to SLAY_MAX). Kept through the upgrade.
var slay_stacks := 0

## Equipped item ids.
var _owned := {}
## Every item id -> ItemData, to tell item damage from Lucian's own.
var _items := {}
var _shojin_left := 0.0
var _shojin_armed := false
var _mana_charge_armed := false
var _combat_left := 0.0
var _jaksho_tick := 0.0
var _hatefog_left := 0.0
var _rfc_shot_left := 0.0
## Death's Dance's delayed damage: {rate, left}. Owed until it lands, even
## once the item is off; only Defy (on_kill) and Guardian Angel (on_lethal)
## clear it.
var _bleeds: Array[Dictionary] = []
var _magebane_wait := 0.0


func setup(owner_lucian: Lucian) -> void:
	lucian = owner_lucian
	if lucian.item_catalog:
		for item in lucian.item_catalog.items:
			_items[item.id] = item


func has(id: StringName) -> bool:
	return _owned.has(id)


func has_energized() -> bool:
	return ENERGIZED.any(has)


func is_item_source(source: StringName) -> bool:
	return _items.has(source)


func in_combat() -> bool:
	return _combat_left > 0.0


## Re-reads the equipped items. Effects of items no longer equipped end,
## but Death's Dance's delayed damage still lands: taking it off for a moment
## (or selling it and undoing the sale) never wipes what is owed.
func refresh() -> void:
	_owned.clear()
	for item in lucian.inventory.equipped():
		_owned[item.id] = true
	if not has_energized():
		energize.consume()
	if not has(&"kraken_slayer"):
		kraken_hits = 0
	if not has(&"essence_reaver"):
		spellblade_ready = false
	if not has(&"spear_of_shojin"):
		shojin_stacks = 0
		_shojin_armed = false
	if not has(&"archangels_staff"):
		_mana_charge_armed = false
	if not has(&"jaksho_the_protean"):
		jaksho_stacks = 0
	if not has(&"kaenic_rookern"):
		_magebane_wait = 0.0
	# Gluttonous Greaves becoming Immortal Path keeps the stacks.
	if not has_slay():
		slay_stacks = 0


## Slay: Gluttonous Greaves or Immortal Path is worn.
func has_slay() -> bool:
	return SLAY_BOOTS.any(has)


## Stat passives, applied after the level and item stats.
func adjust_stats(stats: StatBlock) -> void:
	if has(&"infinity_edge"):
		stats.crit_damage += IE_CRIT_DAMAGE
	if has(&"archangels_staff"):
		stats.max_mana += mana_charge
		stats.ap += stats.max_mana * AWE_AP
	if has(&"fimbulwinter"):
		stats.max_hp += stats.max_mana * AWE_HP
	if has(&"muramana"):
		stats.ad += stats.max_mana * AWE_AD
	if has(&"rabadons_deathcap"):
		stats.ap *= RABADON_AP
	if has(&"spirit_visage"):
		stats.heal_shield_power += SPIRIT_VISAGE_POWER
	if jaksho_stacks > 0:
		stats.armor *= 1.0 + JAKSHO_PER_STACK * jaksho_stacks
		stats.mr *= 1.0 + JAKSHO_PER_STACK * jaksho_stacks
	if slay_stacks > 0 and has_slay():
		stats.omnivamp += SLAY_OMNIVAMP * slay_stacks
	# Swiftmarch's Noxian Fervor, after the other passives: adaptive force from
	# move speed, as AD unless his bonus AP is higher than his bonus AD.
	if has(&"swiftmarch"):
		var force := stats.move_speed * NOXIAN_FERVOR
		if stats.ap > stats.ad - lucian.base_ad():
			stats.ap += force
		else:
			stats.ad += force * ADAPTIVE_AD


## Immortal Path's Now and Forever: deals more damage at half health or more.
func now_and_forever_damage() -> bool:
	return has(&"immortal_path") and lucian.hp >= lucian.stats.max_hp * FOREVER_HP


## How much stronger heals, shields and health regen are (Now and Forever
## below half health: x1.12); 1 otherwise. On top of heal and shield power.
func heal_scale() -> float:
	if has(&"immortal_path") and lucian.stats and lucian.hp < lucian.stats.max_hp * FOREVER_HP:
		return FOREVER_HEAL
	return 1.0


## Plating: enemy basic attacks deal 10% less (burn ticks are not attacks).
func damage_taken_multiplier(info: DamageInfo) -> float:
	if info.source == &"basic" and not info.over_time and PLATING_BOOTS.any(has):
		return PLATING
	return 1.0


## A summoner spell was cast (Noxian Haste).
func on_summoner_used() -> void:
	_noxian_haste()


## Extra ability haste for one skill's cooldown (Malignance: R).
func skill_haste(slot: ChampionProgress.Slot) -> float:
	return SCORN_HASTE if slot == ChampionProgress.Slot.R and has(&"malignance") else 0.0


## Rapid Firecannon: an Energized attack reaches 35% further.
func attack_range_bonus() -> float:
	return RFC_RANGE if has(&"rapid_firecannon") and energize.is_ready() else 0.0


## Rapid Firecannon's longer reach shows as a ring from full Energize until
## the Energized shot lands.
func shows_rfc_ring() -> bool:
	return has(&"rapid_firecannon") and (energize.is_ready() or _rfc_shot_left > 0.0)


func on_cast(_slot: ChampionProgress.Slot) -> void:
	_shojin_armed = has(&"spear_of_shojin")
	_mana_charge_armed = has(&"archangels_staff")
	if has(&"essence_reaver") and lucian.item_cooldown(&"essence_reaver").is_ready():
		spellblade_ready = true


func on_moved(distance: float, dashing: bool) -> void:
	if has_energized():
		energize.add_distance(distance, dashing)


## The main shot of a basic attack leaving the gun: Energize, Kraken Slayer's
## count and Spellblade ride on it as procs; Navori and Runaan's act now.
func on_basic_attack(target: Enemy, info: DamageInfo) -> void:
	if has_energized():
		if energize.is_ready():
			energize.consume()
			info.procs.append(&"energized")
			if has(&"rapid_firecannon"):
				_rfc_shot_left = RFC_RING_WAIT
		else:
			energize.add_attack()
	if has(&"kraken_slayer"):
		kraken_hits += 1
		if kraken_hits >= 3:
			kraken_hits = 0
			info.procs.append(&"kraken_slayer")
	if spellblade_ready:
		spellblade_ready = false
		info.procs.append(&"spellblade")
		lucian.item_cooldown(&"essence_reaver").start(0.0 if lucian.cheat_no_cooldowns else SPELLBLADE_COOLDOWN)
	if has(&"navori_flickerblade"):
		for slot in [ChampionProgress.Slot.Q, ChampionProgress.Slot.W, ChampionProgress.Slot.E]:
			lucian.skills[slot].cooldown.reduce_fraction(NAVORI_CUT)
	if has(&"runaans_hurricane"):
		_fire_runaans_bolts(target)


## Damage multipliers, just before the hit is mitigated.
func before_damage(target: Enemy, info: DamageInfo) -> void:
	var multiplier := 1.0
	if has(&"lord_dominiks_regards"):
		multiplier += GIANT_SLAYER_MAX * clampf((target.max_hp - lucian.stats.max_hp) / GIANT_SLAYER_HP_GAP, 0.0, 1.0)
	if has(&"shadowflame") and info.type == DamageInfo.Type.MAGIC and target.hp < target.max_hp * CINDERBLOOM_HP:
		multiplier += CINDERBLOOM_BONUS
	if shojin_stacks > 0 and SKILL_SOURCES.has(info.source):
		multiplier += SHOJIN_PER_STACK * shojin_stacks
	if now_and_forever_damage():
		multiplier *= FOREVER_DAMAGE
	info.amount *= multiplier


## Banshee's Veil: a spell shield blocks the next boss skill, whole.
func before_damage_taken(info: DamageInfo) -> bool:
	if info.from_skill and has(&"banshees_veil") and lucian.item_cooldown(&"banshees_veil").is_ready():
		lucian.item_cooldown(&"banshees_veil").start(0.0 if lucian.cheat_no_cooldowns else ANNUL_COOLDOWN)
		Sfx.play(&"buff")
		return false
	return true


## Death's Dance: 30% of the hit is taken over 3 s instead. Returns what
## lands now.
func delay_damage(amount: float) -> float:
	if not has(&"deaths_dance") or amount <= 0.0:
		return amount
	var delayed := amount * IGNORE_PAIN
	_bleeds.append({"rate": delayed / IGNORE_PAIN_TIME, "left": IGNORE_PAIN_TIME})
	return amount - delayed


## Immortal Shieldbow: a hit that would leave Lucian under 30% HP first
## gives him Lifeline (300 at level 1 to 650 at 18).
func before_hp_loss(amount: float) -> void:
	if not has(&"immortal_shieldbow") or not lucian.item_cooldown(&"immortal_shieldbow").is_ready():
		return
	if lucian.hp + lucian.shields.total() - amount >= lucian.stats.max_hp * LIFELINE_HP:
		return
	var share := (lucian.progress.level - 1) / float(ChampionProgress.MAX_LEVEL - 1)
	lucian.add_shield(&"lifeline", lerpf(LIFELINE_MIN, LIFELINE_MAX, share), LIFELINE_TIME)
	lucian.item_cooldown(&"immortal_shieldbow").start(0.0 if lucian.cheat_no_cooldowns else LIFELINE_COOLDOWN)


## Thornmail answers a basic attack; any magic damage resets Kaenic
## Rookern's wait. Magic damage raises Chainlaced Crushers' shield, physical
## damage Armored Advance's. Being hit counts as being in combat.
func on_damage_taken(info: DamageInfo, _amount: float) -> void:
	_combat_left = COMBAT_TIME
	if info.type == DamageInfo.Type.MAGIC:
		_magebane_wait = 0.0
		if has(&"chainlaced_crushers"):
			_noxian_shield(&"chainlaced_crushers", &"persistence", true)
	elif info.type == DamageInfo.Type.PHYSICAL and has(&"armored_advance"):
		_noxian_shield(&"armored_advance", &"endurance", false)
	if not has(&"thornmail") or info.source != &"basic" or not is_instance_valid(info.attacker):
		return
	var attacker := info.attacker as Enemy
	if Lucian.is_target(attacker):
		attacker.take_damage(lucian.make_damage(THORNS_BASE + THORNS_BONUS_ARMOR * lucian.bonus_armor(), DamageInfo.Type.MAGIC, &"thornmail"))
		attacker.add_status(Enemy.GRIEVOUS_WOUNDS, GRIEVOUS_DURATION, 1, _icon(&"thornmail"))


## Guardian Angel: instead of dying, stasis then a revive. True when it saved him.
func on_lethal() -> bool:
	if not has(&"guardian_angel") or not lucian.item_cooldown(&"guardian_angel").is_ready():
		return false
	lucian.item_cooldown(&"guardian_angel").start(0.0 if lucian.cheat_no_cooldowns else REBIRTH_COOLDOWN)
	_bleeds.clear()
	var base_hp := lucian.base_stats.at_level(lucian.progress.level).max_hp
	lucian.enter_stasis(REBIRTH_STASIS, base_hp * REBIRTH_HP, lucian.stats.max_mana * REBIRTH_MANA)
	Sfx.play(&"buff")
	return true


## Death's Dance (Defy): a kill clears the delayed damage and heals 15%
## max HP over 2 s. Slay: an elite, mini boss or boss kill adds a stack.
func on_kill(enemy: Enemy = null) -> void:
	if has(&"deaths_dance"):
		_bleeds.clear()
		lucian.restores.start_amount(&"deaths_dance", lucian.stats.max_hp * DEFY_HEAL, 0.0, DEFY_TIME)
	var unit := enemy as EnemyUnit
	if has_slay() and slay_stacks < SLAY_MAX and unit and unit.data and unit.data.kind in SLAY_KINDS:
		slay_stacks += 1
		lucian.refresh_stats()


## Fimbulwinter (Everlasting): slowing an enemy shields Lucian.
func on_enemy_slowed() -> void:
	if not has(&"fimbulwinter") or not lucian.item_cooldown(&"fimbulwinter").is_ready():
		return
	lucian.add_shield(&"everlasting", EVERLASTING_BASE + EVERLASTING_MANA * lucian.stats.max_mana, EVERLASTING_TIME)
	lucian.item_cooldown(&"fimbulwinter").start(0.0 if lucian.cheat_no_cooldowns else EVERLASTING_COOLDOWN)


func on_damage_dealt(target: Enemy, info: DamageInfo, _final_amount: float) -> void:
	_combat_left = COMBAT_TIME
	if info.type == DamageInfo.Type.PHYSICAL:
		if has(&"black_cleaver"):
			target.add_status(Enemy.CARVE, CARVE_DURATION, CARVE_MAX, _icon(&"black_cleaver"))
		if has(&"mortal_reminder"):
			target.add_status(Enemy.GRIEVOUS_WOUNDS, GRIEVOUS_DURATION, 1, _icon(&"mortal_reminder"))
	elif info.type == DamageInfo.Type.MAGIC and has(&"morellonomicon"):
		target.add_status(Enemy.GRIEVOUS_WOUNDS, GRIEVOUS_DURATION, 1, _icon(&"morellonomicon"))
	if has(&"black_cleaver"):
		lucian.add_speed_buff(&"fervor", FERVOR_SPEED, 0.0, FERVOR_DURATION)
	if is_item_source(info.source):
		return
	if ATTACK_SOURCES.has(info.source):
		_on_attack_hit(target, info)
	elif SKILL_SOURCES.has(info.source):
		_on_skill_hit(target, info)


## HUD buff icons: {id, name, icon, text, count, left, duration, ready}.
func buffs() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	if has_energized():
		var names := ENERGIZED.filter(has).map(func(id: StringName) -> String: return _items[id].display_name)
		found.append(_buff(&"energized", "Energized", ENERGIZED_ICON,
			"Moving and attacking build charge; dashing builds it twice as fast. At 100 the next basic attack is Energized (%s)." % ", ".join(names),
			str(int(energize.value)), energize.is_ready()))
	if has(&"kraken_slayer"):
		found.append(_buff(&"kraken_slayer", "Bring It Down", _icon(&"kraken_slayer"),
			"Every third basic attack deals [phys]%d bonus physical damage[/phys]. Next attack: %d of 3." % [KRAKEN_DAMAGE, kraken_hits + 1],
			str(kraken_hits) if kraken_hits > 0 else "", kraken_hits == 2))
	if spellblade_ready:
		found.append(_buff(&"spellblade", "Spellblade", _icon(&"essence_reaver"),
			"The next basic attack deals bonus [phys]physical damage[/phys] and restores [mana]mana[/mana].", "", true))
	if shojin_stacks > 0:
		var shojin := _buff(&"spear_of_shojin", "Focused Will", _icon(&"spear_of_shojin"),
			"Skills deal %d%% more damage." % roundi(SHOJIN_PER_STACK * shojin_stacks * 100.0), str(shojin_stacks), false)
		shojin.left = _shojin_left
		shojin.duration = SHOJIN_DURATION
		found.append(shojin)
	if jaksho_stacks > 0:
		found.append(_buff(&"jaksho_the_protean", "Voidborn Resilience", _icon(&"jaksho_the_protean"),
			"+%d%% armor and magic resist while in combat." % roundi(JAKSHO_PER_STACK * jaksho_stacks * 100.0),
			str(jaksho_stacks), jaksho_stacks == JAKSHO_MAX))
	if has(&"archangels_staff") and mana_charge > 0.0:
		found.append(_buff(&"archangels_staff", "Mana Charge", _icon(&"archangels_staff"),
			"+%d max [mana]mana[/mana] from skill hits (up to %d)." % [roundi(mana_charge), MANA_CHARGE_MAX],
			str(roundi(mana_charge)), mana_charge >= MANA_CHARGE_MAX))
	if has(&"banshees_veil") and lucian.item_cooldown(&"banshees_veil").is_ready():
		found.append(_buff(&"banshees_veil", "Annul", _icon(&"banshees_veil"),
			"A spell shield blocks the next enemy skill.", "", true))
	if has(&"kaenic_rookern"):
		var magebane := _buff(&"kaenic_rookern", "Magebane", _icon(&"kaenic_rookern"),
			"A shield against [magic]magic damage[/magic] after %d s without magic damage." % roundi(MAGEBANE_WAIT), "", false)
		if lucian.shields.has(&"magebane"):
			magebane.count = str(roundi(lucian.shields.amount(&"magebane")))
			magebane.ready = true
		else:
			magebane.left = MAGEBANE_WAIT - _magebane_wait
			magebane.duration = MAGEBANE_WAIT
		found.append(magebane)
	for shield in [[&"lifeline", "Lifeline", &"immortal_shieldbow"], [&"everlasting", "Everlasting", &"fimbulwinter"]]:
		if lucian.shields.has(shield[0]):
			var buff := _buff(shield[0], shield[1], _icon(shield[2]),
				"A shield absorbs damage.", str(roundi(lucian.shields.amount(shield[0]))), true)
			buff.left = lucian.shields.time_left(shield[0])
			buff.duration = lucian.shields.duration(shield[0])
			found.append(buff)
	if has_slay():
		found.append(_buff(&"slay", "Slay", _icon(&"immortal_path" if has(&"immortal_path") else &"gluttonous_greaves"),
			"[hp]+%s%% omnivamp[/hp] from elite, mini boss and boss kills (up to %d)." % [TooltipText.number(SLAY_OMNIVAMP * slay_stacks * 100.0), SLAY_MAX],
			str(slay_stacks) if slay_stacks > 0 else "", slay_stacks == SLAY_MAX))
	if not _bleeds.is_empty():
		var coming := 0.0
		var longest := 0.0
		for entry in _bleeds:
			coming += entry.rate * entry.left
			longest = maxf(longest, entry.left)
		var ignore_pain := _buff(&"deaths_dance", "Ignore Pain", _icon(&"deaths_dance"),
			"%d%% of damage taken is dealt over %d s instead. This is the damage still to come." % [roundi(IGNORE_PAIN * 100.0), roundi(IGNORE_PAIN_TIME)],
			str(roundi(coming)), false)
		ignore_pain.left = longest
		ignore_pain.duration = IGNORE_PAIN_TIME
		found.append(ignore_pain)
	for noxian in [
		[&"chainlaced_crushers", &"persistence", "Noxian Persistence", "[magic]magic damage[/magic]"],
		[&"armored_advance", &"endurance", "Noxian Endurance", "[phys]physical damage[/phys]"],
	]:
		if not has(noxian[0]):
			continue
		var buff := _buff(noxian[1], noxian[2], _icon(noxian[0]),
			"Taking %s grants a shield against it for %d s." % [noxian[3], roundi(NOXIAN_SHIELD_TIME)], "", false)
		var cooldown := lucian.item_cooldown(noxian[0])
		if lucian.shields.has(noxian[1]):
			buff.count = str(roundi(lucian.shields.amount(noxian[1])))
			buff.left = lucian.shields.time_left(noxian[1])
			buff.duration = lucian.shields.duration(noxian[1])
			buff.ready = true
		elif not cooldown.is_ready():
			buff.left = cooldown.remaining
			buff.duration = cooldown.duration
		else:
			buff.ready = true
		found.append(buff)
	return found


func _physics_process(delta: float) -> void:
	if not _bleeds.is_empty():
		var bleed := 0.0
		for entry in _bleeds:
			var step := minf(delta, entry.left)
			bleed += entry.rate * step
			entry.left -= step
		_bleeds.assign(_bleeds.filter(func(entry: Dictionary) -> bool: return entry.left > 0.0))
		lucian.lose_hp(bleed, DamageInfo.Type.TRUE)
	if has(&"kaenic_rookern"):
		if not lucian.shields.has(&"magebane"):
			_magebane_wait += delta
			if _magebane_wait >= MAGEBANE_WAIT:
				lucian.add_shield(&"magebane", lucian.stats.max_hp * MAGEBANE_SHIELD, 0.0, true)
	elif lucian.shields.has(&"magebane"):
		lucian.shields.remove(&"magebane")
		_magebane_wait = 0.0
	if _shojin_left > 0.0:
		_shojin_left -= delta
		if _shojin_left <= 0.0:
			shojin_stacks = 0
	_hatefog_left = maxf(_hatefog_left - delta, 0.0)
	_rfc_shot_left = maxf(_rfc_shot_left - delta, 0.0)
	if _combat_left > 0.0:
		_combat_left = maxf(_combat_left - delta, 0.0)
		if has(&"jaksho_the_protean"):
			_jaksho_tick += delta
			if _jaksho_tick >= 1.0:
				_jaksho_tick -= 1.0
				if jaksho_stacks < JAKSHO_MAX:
					jaksho_stacks += 1
					lucian.refresh_stats()
	elif jaksho_stacks > 0 or _jaksho_tick > 0.0:
		jaksho_stacks = 0
		_jaksho_tick = 0.0
		lucian.refresh_stats()


func _on_attack_hit(target: Enemy, info: DamageInfo) -> void:
	var stats := lucian.stats
	if has(&"nashors_tooth"):
		_deal(target, NASHOR_BASE + NASHOR_AP * stats.ap, DamageInfo.Type.MAGIC, &"nashors_tooth")
	if has(&"muramana"):
		_deal(target, MURAMANA_ATTACK * stats.max_mana, DamageInfo.Type.PHYSICAL, &"muramana")
	for proc in info.procs:
		match proc:
			&"kraken_slayer":
				var missing := 1.0 - target.hp / target.max_hp
				_deal(target, KRAKEN_DAMAGE * (1.0 + KRAKEN_LOW_HP_BONUS * missing), DamageInfo.Type.PHYSICAL, &"kraken_slayer")
			&"spellblade":
				var damage := SPELLBLADE_BASE_AD * lucian.base_ad() + SPELLBLADE_BONUS_AD * lucian.bonus_ad()
				var dealt := _deal(target, damage, DamageInfo.Type.PHYSICAL, &"essence_reaver")
				lucian.restore_mana(dealt * SPELLBLADE_MANA)
			&"energized":
				_energized_hit(target)


func _on_skill_hit(target: Enemy, info: DamageInfo) -> void:
	_noxian_haste()
	if has(&"muramana"):
		_deal(target, MURAMANA_SKILL * lucian.stats.max_mana, DamageInfo.Type.PHYSICAL, &"muramana")
	if _shojin_armed:
		_shojin_armed = false
		shojin_stacks = mini(shojin_stacks + 1, SHOJIN_MAX)
		_shojin_left = SHOJIN_DURATION
	if _mana_charge_armed:
		_mana_charge_armed = false
		if mana_charge < MANA_CHARGE_MAX:
			mana_charge = minf(mana_charge + MANA_CHARGE_STEP, MANA_CHARGE_MAX)
			lucian.refresh_stats()
	if info.source == &"r" and has(&"malignance") and _hatefog_left <= 0.0:
		_hatefog_left = HATEFOG_COOLDOWN
		var zone := HatefogZone.new()
		zone.setup(lucian, target.global_position, _icon(&"malignance"))
		lucian.spawn(zone)


## Crimson Lucidity: +8% move speed for 4 s, once every 4 s.
func _noxian_haste() -> void:
	if not has(&"crimson_lucidity") or not lucian.item_cooldown(&"crimson_lucidity").is_ready():
		return
	lucian.add_speed_buff(&"noxian_haste", 0.0, NOXIAN_HASTE_SPEED, NOXIAN_HASTE_TIME)
	lucian.item_cooldown(&"crimson_lucidity").start(0.0 if lucian.cheat_no_cooldowns else NOXIAN_HASTE_COOLDOWN)


## Chainlaced Crushers / Armored Advance: a shield against the damage type
## just taken, 100 at level 1 to 200 at 18 plus 8% bonus health, for 5 s.
func _noxian_shield(item: StringName, id: StringName, magic: bool) -> void:
	if not lucian.item_cooldown(item).is_ready():
		return
	var share := (lucian.progress.level - 1) / float(ChampionProgress.MAX_LEVEL - 1)
	var amount := lerpf(NOXIAN_SHIELD_MIN, NOXIAN_SHIELD_MAX, share) + NOXIAN_SHIELD_HP * lucian.bonus_hp()
	lucian.add_shield(id, amount, NOXIAN_SHIELD_TIME, magic, not magic)
	lucian.item_cooldown(item).start(0.0 if lucian.cheat_no_cooldowns else NOXIAN_SHIELD_COOLDOWN)


func _energized_hit(target: Enemy) -> void:
	_rfc_shot_left = 0.0
	Sfx.play(&"zap")
	if has(&"statikk_shiv"):
		_chain_lightning(target)
	if has(&"rapid_firecannon"):
		_deal(target, RFC_DAMAGE, DamageInfo.Type.MAGIC, &"rapid_firecannon")
	if has(&"stormrazor"):
		_deal(target, STORMRAZOR_DAMAGE, DamageInfo.Type.MAGIC, &"stormrazor")
		lucian.add_speed_buff(&"stormrazor", 0.0, STORMRAZOR_SPEED, STORMRAZOR_DURATION)


## Statikk Shiv: the target first, then each nearest enemy not hit yet within
## STATIKK_JUMP of the last one, up to STATIKK_TARGETS.
func _chain_lightning(first: Enemy) -> void:
	var chain: Array[Enemy] = [first]
	while chain.size() < STATIKK_TARGETS:
		var next := _nearest_enemy(chain.back().global_position, STATIKK_JUMP, chain)
		if next == null:
			break
		chain.append(next)
	var points := PackedVector2Array([lucian.global_position])
	var damage := STATIKK_BASE + STATIKK_AP * lucian.stats.ap
	for enemy in chain:
		points.append(enemy.global_position)
	for enemy in chain:
		if is_instance_valid(enemy):
			_deal(enemy, damage, DamageInfo.Type.MAGIC, &"statikk_shiv")
	var bolt := ChainLightning.new()
	bolt.setup(points, Color("9fd8ff"))
	lucian.spawn(bolt)


## Runaan's Hurricane: bolts at up to RUNAAN_BOLTS other enemies near the target.
func _fire_runaans_bolts(target: Enemy) -> void:
	var skip: Array[Enemy] = [target]
	for i in RUNAAN_BOLTS:
		var enemy := _nearest_enemy(target.global_position, RUNAAN_RANGE, skip)
		if enemy == null:
			return
		skip.append(enemy)
		var bolt := AttackProjectile.new()
		bolt.color = Color("b8ffcf")
		bolt.glow_color = Color(0.4, 1.0, 0.6, 0.45)
		bolt.launch(lucian.visuals.muzzle_position(LucianVisuals.Gun.LEFT), enemy, lucian.roll_attack(RUNAAN_AD, &"runaans_hurricane"))
		lucian.spawn(bolt)


func _nearest_enemy(from: Vector2, max_distance: float, skip: Array[Enemy]) -> Enemy:
	var best: Enemy = null
	var best_distance := max_distance
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		var distance := from.distance_to(enemy.global_position)
		if distance <= best_distance and not skip.has(enemy):
			best = enemy
			best_distance = distance
	return best


func _deal(target: Enemy, amount: float, type: DamageInfo.Type, source: StringName) -> float:
	return target.take_damage(lucian.make_damage(amount, type, source))


func _icon(id: StringName) -> Texture2D:
	return _items[id].icon if _items.has(id) else null


static func _buff(id: StringName, title: String, icon: Texture2D, text: String, count: String, ready: bool) -> Dictionary:
	return {"id": id, "name": title, "icon": icon, "text": text, "count": count, "left": 0.0, "duration": 0.0, "ready": ready}
