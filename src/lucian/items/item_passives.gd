class_name ItemPassives
extends Node
## The item passives that work in combat, for Lucian's equipped items only.
## Each item counts once however many copies are equipped. Defensive passives
## need enemies that hit back, so they are still tooltip text: Banshee's Veil,
## Thornmail, Immortal Shieldbow, Death's Dance, Fimbulwinter's Everlasting,
## Guardian Angel and Kaenic Rookern.
##
## Lucian calls the hooks: adjust_stats (stat passives), on_cast, on_moved,
## on_basic_attack (counters and "next attack" effects, as the shot leaves
## the gun), before_damage (damage multipliers, at impact) and
## on_damage_dealt (on-hit damage and statuses on the target). Item damage
## uses the item's id as its source and never triggers on-hit effects again.

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
const STORMRAZOR_DAMAGE := 90.0
const STORMRAZOR_SPEED := 0.35
const STORMRAZOR_DURATION := 1.5
const JAKSHO_PER_STACK := 0.05
const JAKSHO_MAX := 6
## Seconds after dealing damage that count as "in combat".
const COMBAT_TIME := 3.0
const HATEFOG_COOLDOWN := 3.0
const SCORN_HASTE := 20.0

var lucian: Lucian
var energize := EnergizeCharge.new()
## Basic attacks landed toward Kraken Slayer's third (0-2).
var kraken_hits := 0
var shojin_stacks := 0
## Archangel's Staff's max mana bonus. Kept for the stage, even unequipped.
var mana_charge := 0.0
var jaksho_stacks := 0
var spellblade_ready := false

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


## Re-reads the equipped items. Effects of items no longer equipped end.
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


## Extra ability haste for one skill's cooldown (Malignance: R).
func skill_haste(slot: ChampionProgress.Slot) -> float:
	return SCORN_HASTE if slot == ChampionProgress.Slot.R and has(&"malignance") else 0.0


## Rapid Firecannon: an Energized attack reaches 35% further.
func attack_range_bonus() -> float:
	return RFC_RANGE if has(&"rapid_firecannon") and energize.is_ready() else 0.0


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
		lucian.item_cooldown(&"essence_reaver").start(SPELLBLADE_COOLDOWN)
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
	info.amount *= multiplier


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
	return found


func _physics_process(delta: float) -> void:
	if _shojin_left > 0.0:
		_shojin_left -= delta
		if _shojin_left <= 0.0:
			shojin_stacks = 0
	_hatefog_left = maxf(_hatefog_left - delta, 0.0)
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


func _energized_hit(target: Enemy) -> void:
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
