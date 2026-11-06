extends SceneTree
## Playtest bot: plays the story from a new save, as a player would, and
## prints what happened. Not a test; a balance probe. Between stages it
## spends essences in the Evolution Tree (BUY_ORDER); in a stage it kites,
## steps out of red warnings, casts on cooldown, drinks potions, shops at the
## merchant and picks up loot. A failed stage is retried (essences kept).
## Usage (headless, as fast as the CPU allows):
##   godot --headless --fixed-fps 60 --path . -s res://tests/tools/autoplay.gd -- <tier> <max_tries> [last_stage] [seed]
##   tier: skilled, average or novice (Bot.TIERS: reaction, kiting, dodging)
## Optional: first_stage (the stages before it count as cleared, and Act 1's
## gifts are given) with the blue and orange essence to start from:
##   ... -- average 6 3-5 3-1 1500 20
## Headless only (a window would confine the mouse). AUTOPLAY_TRACE=<seconds>
## prints a line of the fight that often, on each stage's first try.
## AUTOPLAY_DIFFICULTY=easy|normal|hard|extreme plays on that difficulty
## (default normal); each tier and difficulty has its own save files.
## Each try also prints its items: the gold at each merchant, what was bought,
## picked up and crafted (after how many waves), and what was equipped at
## the end.

const SAVE_PREFIX := "user://autoplay_save_slot_"
const SETTINGS_PATH := "user://autoplay_settings.json"
const STAGE_SCENE := "res://src/stage/stage.tscn"
## One stage may not run longer than this (game seconds).
const STAGE_LIMIT := 2400.0
## The tree, in the order a player would buy it: [node id, level wanted].
const BUY_ORDER := [
	[&"ghost", 1], [&"skill_e", 1],
	[&"skill_q", 1], [&"skill_w", 1], [&"passive", 1],
	[&"stat_hp", 1], [&"stat_ad", 1], [&"heal", 1], [&"equip_slots", 1], [&"backpack_slots", 1], [&"boots", 1],
	[&"skill_q", 2], [&"skill_w", 2], [&"stat_armor", 1], [&"stat_attack_speed", 1],
	[&"skill_r", 1], [&"stat_hp", 2], [&"stat_ad", 2], [&"skill_e", 2], [&"summoner_slot_2", 1], [&"flash", 1],
	[&"skill_q", 3], [&"skill_w", 3], [&"stat_mr", 1], [&"equip_slots", 2], [&"boots", 2], [&"stat_armor", 2], [&"backpack_slots", 2],
	[&"stat_attack_speed", 2], [&"heal_upgrade", 1], [&"skill_e", 3], [&"equip_slots", 3], [&"stat_hp", 3], [&"stat_ad", 3],
	[&"skill_r", 2], [&"skill_q", 4], [&"skill_w", 4], [&"stat_mr", 2], [&"stat_hp_regen", 1], [&"stage_gold", 1],
	[&"stat_armor", 3], [&"stat_attack_speed", 3], [&"skill_q", 5], [&"skill_e", 4], [&"skill_w", 5],
	[&"heal_upgrade", 2], [&"equip_slots", 4], [&"skill_r", 3], [&"skill_e", 5], [&"stat_hp", 4], [&"stat_ad", 4],
	[&"stat_mr", 3], [&"equip_slots", 5], [&"stat_armor", 4], [&"stat_attack_speed", 4], [&"stat_hp", 5], [&"stat_ad", 5],
	[&"stat_mr", 4], [&"stat_armor", 5], [&"stat_attack_speed", 5], [&"stat_mr", 5], [&"backpack_slots", 3],
]

var skill := "average"
var max_tries := 6
var last_stage := "6-5"
var first_stage := "1-1"
var trace_every := 0.0
var difficulty := Difficulty.NORMAL
var log_lines: PackedStringArray = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	skill = args[0] if args.size() > 0 else "average"
	max_tries = int(args[1]) if args.size() > 1 else 6
	last_stage = args[2] if args.size() > 2 else "6-5"
	if args.size() > 3:
		first_stage = args[3]
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	GameSettings._instance = GameSettings.new(SETTINGS_PATH)
	difficulty = Difficulty.from_key(OS.get_environment("AUTOPLAY_DIFFICULTY").to_lower())
	var save := SaveGame.new("%s%s_%s_" % [SAVE_PREFIX, skill, Difficulty.KEYS[difficulty]])
	SaveGame._instance = save
	save.start_new(1, difficulty)
	print("autoplay: %s on %s (%s)" % [skill, Difficulty.name_of(difficulty), Difficulty.scale_text(difficulty)])
	if first_stage != "1-1":
		var before: Array[String] = []
		for id in Journey.all_stage_ids(Journey.ACTS.size()):
			if id == first_stage:
				break
			before.append(id)
		save.set_cleared(before)
		save.essences.set_amount(Essences.BLUE, int(args[4]) if args.size() > 4 else 0)
		save.essences.set_amount(Essences.ORANGE, int(args[5]) if args.size() > 5 else 0)
	if DisplayServer.get_name() != "headless":
		print("autoplay runs headless only: add --headless")
		quit()
		return
	if OS.get_environment("AUTOPLAY_TRACE") != "":
		trace_every = float(OS.get_environment("AUTOPLAY_TRACE"))
	_campaign.call_deferred()


func _say(line: String) -> void:
	print(line)
	log_lines.append(line)


func _campaign() -> void:
	var save := SaveGame.instance()
	var total := 0.0
	var started := Time.get_ticks_msec()
	## The last stage cleared: where a stuck player farms.
	var farm_from := Vector2i.ZERO
	_say("skill=%s max_tries=%d" % [skill, max_tries])
	for act in range(1, Journey.ACTS.size() + 1):
		var act_time := 0.0
		for number in range(1, Journey.stage_count(act) + 1):
			var id := Journey.stage_id(act, number)
			if id in save.cleared:
				continue
			var tries := 0
			while true:
				tries += 1
				var bought := _spend(save)
				var r: Dictionary = await _play(act, number, tries == 1)
				total += r.time
				act_time += r.time
				_say("%s try %d: %s  time %s  waves %s  kills %d  minHP %d%%  lvl %d  pots %d  dodges %d  dealt %d  taken %d  gold %d  blue+%d  tree %s%s" % [
					id, tries, "CLEARED" if r.cleared else "FAILED ", StageResult.clock(r.time), r.waves, r.kills, int(r.min_hp * 100), r.level,
					r.potions, r.dodges, int(r.dealt), int(r.damage_taken), r.gold, r.blue, _tree_text(save), ("  died to " + r.killer) if not r.cleared else ""])
				if bought != "":
					_say("    bought: " + bought)
				var parts: PackedStringArray = []
				var by: Dictionary = r.taken_by
				var ids := by.keys()
				ids.sort_custom(func(a: String, b: String) -> bool: return by[a] > by[b])
				for key: String in ids:
					parts.append("%s %d" % [key, by[key]])
				_say("    taken by: " + ", ".join(parts))
				_say("    items: %s  | end: %s" % [" · ".join(r.items) if not r.items.is_empty() else "none", r.equipped])
				if r.cleared:
					farm_from = Vector2i(act, number)
					break
				# Stuck: like a player, replay the last stage cleared once for essences.
				if tries % 3 == 0 and farm_from != Vector2i.ZERO and tries < max_tries:
					_spend(save)
					var f: Dictionary = await _play(farm_from.x, farm_from.y)
					total += f.time
					act_time += f.time
					_say("  farm %s: %s  time %s  blue+%d" % [Journey.stage_id(farm_from.x, farm_from.y),
						"cleared" if f.cleared else "failed", StageResult.clock(f.time), f.blue])
				if tries >= max_tries:
					_say("WALL at %s after %d tries; total game time %s" % [id, tries, StageResult.clock(total)])
					_finish(started)
					return
			if id == last_stage:
				_say("Act %d time %s; total %s" % [act, StageResult.clock(act_time), StageResult.clock(total)])
				_finish(started)
				return
		_say("== Act %d done in %s game time (total %s); essences B%d O%d P%d" % [act, StageResult.clock(act_time), StageResult.clock(total),
			save.essences.amount(Essences.BLUE), save.essences.amount(Essences.ORANGE), save.essences.amount(Essences.PURPLE)])
	_finish(started)


func _finish(started: int) -> void:
	_say("real seconds: %d" % ((Time.get_ticks_msec() - started) / 1000))
	quit()


func _tree_text(save: SaveGame) -> String:
	var t := save.tree
	return "Q%d W%d E%d R%d P%d hp%d ad%d as%d ar%d mr%d eq%d" % [t.level(&"skill_q"), t.level(&"skill_w"), t.level(&"skill_e"), t.level(&"skill_r"),
		t.level(&"passive"), t.level(&"stat_hp"), t.level(&"stat_ad"), t.level(&"stat_attack_speed"), t.level(&"stat_armor"),
		t.level(&"stat_mr"), t.level(&"equip_slots")]


## Buys what BUY_ORDER wants, in order, saving up for the next one it can't
## afford yet (one that is locked, by an act or a level sum, is passed over).
## Returns what it bought.
func _spend(save: SaveGame) -> String:
	var bought: PackedStringArray = []
	for want: Array in BUY_ORDER:
		var id: StringName = want[0]
		if save.tree.node(id) == null or save.tree.level(id) >= want[1]:
			continue
		if not save.tree.next_level_open(id):
			continue
		if not save.tree.can_buy(id, save.essences):
			break
		save.tree.buy(id, save.essences)
		bought.append("%s%d" % [id, save.tree.level(id)])
	# D: Heal once bought, else Ghost; F: Flash, else Ghost.
	var d := &"heal" if save.tree.level(&"heal") > 0 else &"ghost"
	var f := &"flash" if save.tree.level(&"flash") > 0 else &"ghost"
	if save.tree.level(d) > 0:
		save.set_loadout(0, d)
	if f != d and save.tree.level(f) > 0:
		save.set_loadout(1, f)
	return ", ".join(bought)


func _play(act: int, number: int, first_try := false) -> Dictionary:
	var save := SaveGame.instance()
	var setup := StageSetup.for_stage(save, act, number)
	var stage: Stage = load(STAGE_SCENE).instantiate()
	stage.setup(setup)
	root.add_child(stage)
	var blue_before := save.essences.amount(Essences.BLUE)
	var bot := Bot.new()
	bot.stage = stage
	bot.tier = Bot.TIERS[skill]
	stage.add_child(bot)
	var next_trace := 0.0
	var tracing := first_try and trace_every > 0.0
	while not stage.result.visible and stage.elapsed < STAGE_LIMIT:
		await process_frame
		if stage.cutscene and not stage.cutscene.skipped:
			stage.cutscene.skip()
		if tracing and stage.elapsed >= next_trace:
			next_trace += trace_every
			print(bot.trace_line())
	var cleared: bool = stage.result.visible and stage.result.cleared
	var r := {
		"cleared": cleared, "time": stage.elapsed, "min_hp": bot.min_hp, "level": stage.lucian.progress.level,
		"potions": bot.potions, "dodges": bot.dodges, "hits": bot.hits, "damage_taken": stage.stats.damage_taken,
		"waves": "%d/%d" % [stage.runner.waves_done(), stage.runner.total_waves()],
		"blue": save.essences.amount(Essences.BLUE) - blue_before, "killer": bot.last_hit_by,
		"taken_by": bot.taken_by, "kills": stage.stats.kills, "dealt": stage.stats.damage_dealt, "gold": stage.stats.gold_earned,
		"items": bot.item_log, "equipped": bot.equipped_text(),
	}
	save.finish_stage(&"cleared" if cleared else &"failed", setup.stage_id)
	paused = false
	stage.queue_free()
	await process_frame
	await process_frame
	return r


class Bot extends Node:
	## react: seconds between decisions; kite: steps back while reloading when
	## a melee enemy's swing is less than this far away (-INF = never); warn: share of red
	## warnings stepped out of; bolt: share of enemy bolts sidestepped;
	## e_dps: E used for damage, not only to escape.
	const TIERS := {
		"skilled": {"react": 0.15, "kite": 90.0, "warn": 1.0, "bolt": 0.5, "e_dps": true},
		"average": {"react": 0.25, "kite": 40.0, "warn": 0.8, "bolt": 0.2, "e_dps": false},
		"novice": {"react": 0.35, "kite": -INF, "warn": 0.5, "bolt": 0.0, "e_dps": false},
	}
	const POTION_AT := 0.55
	var stage: Stage
	var lucian: Lucian
	var tier: Dictionary = TIERS["average"]
	var min_hp := 1.0
	var potions := 0
	var dodges := 0
	var hits := 0
	var last_hit_by := ""
	## Damage taken per enemy id.
	var taken_by := {}
	## Items in order, with the waves cleared so far: "1: buy B.F. Sword".
	var item_log: PackedStringArray = []
	var _think := 0.0
	var _ignored := {}
	var _rng := RandomNumberGenerator.new()
	var _shopped := false
	var _was_break := false

	func _ready() -> void:
		lucian = stage.lucian
		_rng.randomize()
		lucian.damage_received.connect(_on_hit)
		stage.get_node("World").child_entered_tree.connect(_on_world_child)

	## A drop that leaves the map beside a living Lucian was picked up (the
	## rest leave with the stage).
	func _on_world_child(node: Node) -> void:
		var drop := node as LootDrop
		if drop == null:
			return
		drop.tree_exiting.connect(func() -> void:
			if is_instance_valid(lucian) and not stage.result.visible and not lucian.dead and drop.global_position.distance_to(lucian.global_position) <= LootDrop.PICKUP_RANGE + 1.0:
				_note("loot " + drop.item.display_name))

	func _note(text: String) -> void:
		item_log.append("%d: %s" % [stage.runner.waves_done() if stage.runner else 0, text])

	## "Muramana, Chain Vest (2/2 slots)": what the equip slots hold.
	func equipped_text() -> String:
		var inv := lucian.inventory
		var names: PackedStringArray = []
		for i in Inventory.EQUIP_SIZE:
			var item := inv.item_at(Inventory.EQUIP_START + i)
			if item and not item.is_potion():
				names.append(item.display_name)
		return "%s (%d/%d slots)" % [", ".join(names) if not names.is_empty() else "nothing", names.size(), inv.unlocked_equip]

	func _on_hit(info: DamageInfo, amount: float) -> void:
		if amount <= 0.0:
			return
		hits += 1
		var who: Variant = info.attacker
		var id := "other"
		if is_instance_valid(who) and who is EnemyUnit:
			id = String((who as EnemyUnit).data.id)
			last_hit_by = "%s (%s)" % [id, info.source]
		else:
			last_hit_by = str(info.source)
		taken_by[id] = taken_by.get(id, 0.0) + amount

	func _physics_process(delta: float) -> void:
		if lucian.dead or stage.result.visible or stage.cutscene:
			return
		min_hp = minf(min_hp, lucian.hp / lucian.stats.max_hp)
		for slot in [ChampionProgress.Slot.R, ChampionProgress.Slot.Q, ChampionProgress.Slot.W, ChampionProgress.Slot.E]:
			while lucian.try_rank_up(slot):
				pass
		_think -= delta
		if _think > 0.0:
			return
		_think = tier.react
		_decide()

	func _enemies() -> Array[EnemyUnit]:
		var found: Array[EnemyUnit] = []
		for node in get_tree().get_nodes_in_group(&"enemies"):
			var unit := node as EnemyUnit
			if unit and unit.is_alive() and not unit.untargetable:
				found.append(unit)
		return found

	func _decide() -> void:
		var enemies := _enemies()
		var in_break := stage.runner and stage.runner.state == WaveRunner.State.BREAK
		if in_break and not _was_break:
			_shopped = false
		_was_break = in_break
		_survive(enemies)
		if _dodge() or _dodge_bolts():
			return
		if enemies.is_empty():
			_between_waves(in_break)
			return
		var target := _pick_target(enemies)
		_cast(target, enemies)
		_fight(target, enemies)

	## Potions and summoner spells when low.
	func _survive(enemies: Array[EnemyUnit]) -> void:
		var share := lucian.hp / lucian.stats.max_hp
		if share < POTION_AT and lucian.restores.count(&"hp_potion") == 0:
			var index := _find(&"hp_potion")
			if index >= 0 and lucian.use_item(index):
				potions += 1
		if share < 0.35 and not enemies.is_empty():
			for slot in 2:
				var spell := lucian.summoners.spell_in(slot)
				if spell == null:
					continue
				if spell.id in [&"heal", &"barrier"]:
					lucian.use_summoner(slot, lucian.global_position)
				elif spell.id == &"ghost" and share < 0.25:
					lucian.use_summoner(slot, lucian.global_position)
				elif spell.id == &"flash" and share < 0.15:
					var away := _away_point(enemies, 400.0)
					lucian.use_summoner(slot, away)

	func _find(id: StringName) -> int:
		for i in Inventory.SIZE:
			if not lucian.inventory.is_locked(i) and lucian.inventory.item_at(i) and lucian.inventory.item_at(i).id == id:
				return i
		return -1

	## Red warnings: step to the nearest spot none covers.
	func _dodge() -> bool:
		var pos := lucian.global_position
		var warnings: Array[GroundWarning] = []
		var hit := false
		var urgency := 0.0
		for node in stage.get_node("Warnings").get_children():
			var w := node as GroundWarning
			if w == null or w.is_queued_for_deletion():
				continue
			if _skips(w, tier.warn):
				continue
			warnings.append(w)
			if w.shape != GroundWarning.Shape.LOCK and w.covers(pos, Lucian.HIT_RADIUS + 12.0):
				hit = true
				urgency = maxf(urgency, (1.0 - w.progress()) * w.warn_time)
		if not hit:
			return false
		var best := Vector2.INF
		var best_cost := INF
		for ring in [90.0, 160.0, 240.0, 340.0]:
			for i in 16:
				var spot: Vector2 = pos + Vector2.from_angle(TAU * i / 16.0) * ring
				if not stage.arena.is_walkable(spot, 34.0):
					continue
				var safe := true
				for w in warnings:
					if w.shape != GroundWarning.Shape.LOCK and w.covers(spot, Lucian.HIT_RADIUS + 16.0):
						safe = false
						break
				if not safe:
					continue
				var cost: float = ring - _nearest_melee_distance(spot) * 0.1
				if cost < best_cost:
					best_cost = cost
					best = spot
			if best != Vector2.INF:
				break
		if best == Vector2.INF:
			return false
		dodges += 1
		var speed := lucian.current_move_speed()
		if pos.distance_to(best) / maxf(speed, 1.0) > urgency and lucian.can_cast(ChampionProgress.Slot.E):
			lucian.try_cast(ChampionProgress.Slot.E, best)
		lucian.command_move(best)
		return true

	## Rolled once per warning or bolt: whether this player misses it.
	func _skips(thing: Object, share: float) -> bool:
		var key := thing.get_instance_id()
		if not _ignored.has(key):
			_ignored[key] = _rng.randf() >= share
		return _ignored[key]

	## An enemy bolt about to hit: a step to the side.
	func _dodge_bolts() -> bool:
		if tier.bolt <= 0.0:
			return false
		var pos := lucian.global_position
		for node in stage.get_node("Projectiles").get_children():
			var bolt := node as EnemyProjectile
			if bolt == null or bolt.is_queued_for_deletion():
				continue
			var to_me := pos - bolt.global_position
			var along := to_me.dot(bolt.direction)
			if along < 0.0 or along > bolt.speed * 0.6:
				continue
			var side := to_me - bolt.direction * along
			var reach := Lucian.HIT_RADIUS + bolt.hit_radius + bolt.front_width * 0.5
			if side.length() > reach or _skips(bolt, tier.bolt):
				continue
			var away := side.normalized() if side.length() > 1.0 else bolt.direction.orthogonal()
			var spot := pos + away * (reach + 50.0)
			if not stage.arena.is_walkable(spot, 34.0):
				spot = pos - away * (reach + 50.0)
			dodges += 1
			lucian.command_move(spot)
			return true
		return false

	## One line of the fight: time, HP, mana, wave, enemies near, kills, what he does.
	func trace_line() -> String:
		var near := {}
		var pos := lucian.global_position
		for unit in _enemies():
			if pos.distance_to(unit.global_position) < 700.0:
				near[unit.data.id] = near.get(unit.data.id, 0) + 1
		var ranks := lucian.progress.ranks
		return "  t=%5.1f hp=%4d/%4d mp=%3d lvl=%d QWER=%d%d%d%d wave=%d alive=%d kills=%d order=%d at=(%d,%d) melee@%d near=%s" % [
			stage.elapsed, lucian.hp, lucian.stats.max_hp, lucian.mana, lucian.progress.level, ranks[0], ranks[1], ranks[2], ranks[3],
			stage.runner.wave, stage.runner.alive(), stage.stats.kills, lucian._order, pos.x, pos.y, _nearest_melee_distance(pos), near]

	## How far `at` is outside the swing of the nearest melee enemy (negative: inside it).
	func _nearest_melee_distance(at: Vector2) -> float:
		var best := 2000.0
		for unit in _enemies():
			if unit.data.attack_range <= 200.0:
				best = minf(best, at.distance_to(unit.global_position) - unit.data.attack_range - Lucian.HIT_RADIUS)
		return best

	## Between waves: loot, then the merchant, then Skip.
	func _between_waves(in_break: bool) -> void:
		for node in stage.get_node("World").get_children():
			var drop := node as LootDrop
			if drop and lucian.inventory.space_for(drop.item) > 0:
				lucian.command_move(drop.global_position)
				return
		if not in_break:
			return
		if not _shopped and is_instance_valid(stage.merchant):
			_shopped = true
			_shop()
		stage.skip_break()

	## The merchant, as a player would use him (the shop pauses the game).
	func _shop() -> void:
		var shop := Shop.new(stage.merchant.stock, lucian.inventory, stage.wallet)
		shop.refresh_cost = stage.run.refresh_cost
		var catalog := lucian.item_catalog
		var potion := catalog.find(&"hp_potion")
		_note("gold %d" % stage.wallet.gold)
		# Items first: the best fragment or legendary affordable, keeping 100 for potions.
		for pass_count in 3:
			var best := -1
			for slot in MerchantStock.SLOTS:
				var item := shop.stock.item_at(slot)
				if item and stage.wallet.gold >= item.cost + 100:
					if best < 0 or item.cost > shop.stock.item_at(best).cost:
						best = slot
			if best < 0:
				break
			var bought := shop.stock.item_at(best)
			if shop.buy_slot(best) == Shop.Result.OK:
				_note("buy %s (%d)" % [bought.display_name, bought.cost])
		_craft()
		# Potions: up to 4.
		var have := 0
		var index := _find(&"hp_potion")
		if index >= 0:
			have = lucian.inventory.count_at(index)
		while have < 4 and shop.buy_potion(potion) == Shop.Result.OK:
			have += 1
		_equip()

	## Crafts any two fragments into their legendary.
	func _craft() -> void:
		var inv := lucian.inventory
		var again := true
		while again:
			again = false
			for a in Inventory.SIZE:
				if inv.is_locked(a) or inv.item_at(a) == null or not inv.item_at(a).is_fragment():
					continue
				for b in Inventory.SIZE:
					if b == a or inv.is_locked(b) or inv.item_at(b) == null or not inv.item_at(b).is_fragment():
						continue
					var made := inv.craft_result(a, b)
					if made:
						inv.apply_drop(a, b, true)
						_note("craft " + made.display_name)
						again = true
						break
				if again:
					break

	## The priciest items go into the open equip slots; potions stay in their
	## cells and the backpack, and the boots in theirs.
	func _equip() -> void:
		var inv := lucian.inventory
		var gear: Array[int] = []
		for i in Inventory.SIZE:
			var item := inv.item_at(i)
			if not inv.is_locked(i) and item and not item.is_potion() and not item.is_boots():
				gear.append(i)
		gear.sort_custom(func(x: int, y: int) -> bool: return inv.item_at(x).cost > inv.item_at(y).cost)
		var slot := 0
		for i in gear:
			while slot < Inventory.EQUIP_SIZE and inv.is_locked(Inventory.EQUIP_START + slot):
				slot += 1
			if slot >= Inventory.EQUIP_SIZE:
				break
			var cell := Inventory.EQUIP_START + slot
			if i != cell:
				inv.apply_drop(i, cell, false)
			slot += 1
		lucian.refresh_stats()

	func _pick_target(enemies: Array[EnemyUnit]) -> EnemyUnit:
		var pos := lucian.global_position
		var reach := lucian.attack_range()
		var best: EnemyUnit
		var best_score := INF
		for unit in enemies:
			var d := pos.distance_to(unit.global_position) - unit.radius
			var score := d
			if d <= reach:
				# In range: the weakest first, bosses after the adds near him.
				score = -1000.0 + unit.hp / maxf(unit.max_hp, 1.0) * 300.0
				if unit.data.attack_range <= 200.0 and d < 230.0:
					score -= 200.0
			if score < best_score:
				best_score = score
				best = unit
		return best

	func _cast(target: EnemyUnit, enemies: Array[EnemyUnit]) -> void:
		var pos := lucian.global_position
		var at := target.global_position
		var d := pos.distance_to(at)
		# Q through the line that holds the most enemies; W on the thickest clump.
		var q := lucian.skill_range(ChampionProgress.Slot.Q)
		if q and lucian.can_cast(ChampionProgress.Slot.Q):
			var aim := _best_line(enemies, q.reach)
			if aim != Vector2.INF:
				lucian.try_cast(ChampionProgress.Slot.Q, aim)
				return
		var w := lucian.skill_range(ChampionProgress.Slot.W)
		if w and lucian.can_cast(ChampionProgress.Slot.W):
			var aim := _best_clump(enemies, w.reach)
			if aim != Vector2.INF:
				lucian.try_cast(ChampionProgress.Slot.W, aim)
				return
		var r := lucian.skill_range(ChampionProgress.Slot.R)
		if r and lucian.can_cast(ChampionProgress.Slot.R) and d <= r.reach * 0.8:
			var near := 0
			for unit in enemies:
				if pos.distance_to(unit.global_position) < 700.0:
					near += 1
			if target.data.is_boss_kind() or near >= 5:
				lucian.try_cast(ChampionProgress.Slot.R, at)
				return
		# E: away from a melee on him, else sideways for the passive when healthy.
		if lucian.can_cast(ChampionProgress.Slot.E):
			var close := _nearest_melee_distance(pos)
			if close < 0.0:
				lucian.try_cast(ChampionProgress.Slot.E, _away_point(enemies, 260.0))
			elif tier.e_dps and lucian.hp / lucian.stats.max_hp > 0.6 and d < lucian.attack_range():
				var side := (at - pos).normalized().orthogonal() * 200.0 * (1 if _rng.randf() < 0.5 else -1)
				if stage.arena.is_walkable(pos + side, 34.0):
					lucian.try_cast(ChampionProgress.Slot.E, pos + side)

	func _fight(target: EnemyUnit, enemies: Array[EnemyUnit]) -> void:
		var pos := lucian.global_position
		var close := _nearest_melee_distance(pos)
		var reloading := lucian._attack_cooldown > 0.12 and lucian._windup_left <= 0.0
		if close < tier.kite and reloading:
			lucian.command_move(_away_point(enemies, 160.0))
			return
		lucian.command_attack(target)

	## The enemy in reach whose line from Lucian crosses the most enemies.
	func _best_line(enemies: Array[EnemyUnit], reach: float) -> Vector2:
		var pos := lucian.global_position
		var best := Vector2.INF
		var best_count := 0
		for aim in enemies:
			var dir := pos.direction_to(aim.global_position)
			if pos.distance_to(aim.global_position) > reach + aim.radius:
				continue
			var count := 0
			for unit in enemies:
				var off := unit.global_position - pos
				var along := off.dot(dir)
				if along >= 0.0 and along <= reach + unit.radius and absf(off.cross(dir)) <= 40.0 + unit.radius:
					count += 1
			if count > best_count:
				best_count = count
				best = aim.global_position
		return best

	## The enemy in reach with the most enemies within 220 of it.
	func _best_clump(enemies: Array[EnemyUnit], reach: float) -> Vector2:
		var pos := lucian.global_position
		var best := Vector2.INF
		var best_count := 0
		for aim in enemies:
			if pos.distance_to(aim.global_position) > reach:
				continue
			var count := 0
			for unit in enemies:
				if unit.global_position.distance_to(aim.global_position) <= 220.0:
					count += 1
			if count > best_count:
				best_count = count
				best = aim.global_position
		return best

	## A walkable point `distance` away: the direction that leaves him farthest
	## from every enemy, with room to keep going (no corners).
	func _away_point(enemies: Array[EnemyUnit], distance: float) -> Vector2:
		var pos := lucian.global_position
		var best := Vector2.INF
		var best_score := -INF
		for i in 16:
			var dir := Vector2.from_angle(TAU * i / 16.0)
			var spot := pos + dir * distance
			if not stage.arena.is_walkable(spot, 40.0) or not stage.arena.is_walkable(pos + dir * distance * 0.5, 40.0):
				continue
			var nearest := 2000.0
			for unit in enemies:
				nearest = minf(nearest, spot.distance_to(unit.global_position))
			var score := nearest
			if stage.arena.is_walkable(pos + dir * distance * 2.5, 40.0):
				score += 150.0
			if score > best_score:
				best_score = score
				best = spot
		return best if best != Vector2.INF else pos
