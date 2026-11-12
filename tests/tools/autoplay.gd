extends SceneTree
## Playtest bot: plays the story from a new save, as a player would, and
## prints what happened. Not a test; a balance probe. Between stages it
## spends essences in the Evolution Tree (BUY_ORDER); in a stage it kites,
## steps out of red warnings, casts on cooldown, drinks potions, shops at the
## merchant and picks up loot. A failed stage is retried (essences kept, and
## a Resolve stack for each defeat there).
## Usage (headless, as fast as the CPU allows):
##   godot --headless --fixed-fps 60 --path . -s res://tests/tools/autoplay.gd -- <tier> <max_tries> [last_stage] [seed]
##   tier: skilled, average or novice (Bot.TIERS: reaction, kiting, panic, dodging)
## Optional: first_stage (the stages before it count as cleared, and Act 1's
## gifts are given) with the blue and orange essence to start from:
##   ... -- average 6 3-5 3-1 1500 20
## Headless only (a window would confine the mouse). AUTOPLAY_TRACE=<seconds>
## prints a line of the fight that often, on each stage's first try.
## AUTOPLAY_DIFFICULTY=easy|normal|hard|extreme plays on that difficulty
## (default normal); each tier and difficulty has its own save files.
## AUTOPLAY_RUN=<name> gives a run its own save and settings files too, so
## several runs of one tier and difficulty can play at the same time.
## AUTOPLAY_TIER="panic=0.2,react=0.4" plays the tier with those numbers
## changed (to find what a tier should be).
## AUTOPLAY_RESOLVE=off plays with the Resolve setting off (defeats are
## still counted, but give nothing).
## Skins: between stages it buys every skin its purple affords, in Skin Shop
## order, and wears the last one bought. AUTOPLAY_SKIN=<id> (e.g. pulsefire,
## or classic for none) saves up for that skin first and wears it once owned.
## Each try prints the skin worn.
## Each try also prints its items: the gold at each merchant, what was bought,
## picked up and crafted (after how many waves), and what was equipped at
## the end; and the Resolve stacks it was played with.
## In a break the bot walks to the merchant, shops, looks around for its
## tier's `idle` seconds and presses Skip. Halfway through a stage, at the
## Lantern's gift, it waits `idle` seconds, then picks the skilled tier's
## favorite of the three cards (the others take the first); each try prints it.
## The run ends with a summary: the stage time and an estimate of the play
## time (the slot's clock also runs on the end screen and the main screen:
## `between` seconds before each stage, `retry` before each Retry), one line
## per stage ("summary 2-1: tries 4,
## cleared in 3:10 with Resolve 3, spent 8:02"; its farm runs too) and the
## tree and essences it ended with.

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
## AUTOPLAY_SKIN's skin id; empty wears the last one bought.
var wanted_skin := &""
## The last skin bought.
var last_skin := &""
## The tier played: Bot.TIERS[skill], with AUTOPLAY_TIER's changes.
var tier := {}
## One row per stage tried, for the summary: {id, tries, clear (the winning
## try's seconds, -1 while not cleared), resolve (the winning try's stacks),
## spent (seconds over every try), farms, farm_time (the replays of an
## earlier stage made while stuck here)}.
var stage_rows: Array[Dictionary] = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	skill = args[0] if args.size() > 0 else "average"
	max_tries = int(args[1]) if args.size() > 1 else 6
	last_stage = args[2] if args.size() > 2 else "6-5"
	if args.size() > 3:
		first_stage = args[3]
	# AUTOPLAY_RUN=<name>: its own settings and save files, so several runs of
	# one tier and difficulty can play side by side.
	var run := OS.get_environment("AUTOPLAY_RUN")
	var settings_path := SETTINGS_PATH if run == "" else "user://autoplay_settings_%s.json" % run
	if FileAccess.file_exists(settings_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))
	GameSettings._instance = GameSettings.new(settings_path)
	tier = Bot.TIERS[skill].duplicate()
	# AUTOPLAY_TIER="panic=0.2,react=0.4": the tier with those numbers changed.
	for change in OS.get_environment("AUTOPLAY_TIER").split(",", false):
		var pair := change.split("=")
		if pair.size() == 2 and tier.has(pair[0].strip_edges()):
			tier[pair[0].strip_edges()] = pair[1].strip_edges().to_float()
			print("autoplay: %s = %s" % [pair[0].strip_edges(), pair[1].strip_edges()])
	if OS.get_environment("AUTOPLAY_RESOLVE").to_lower() == "off":
		GameSettings.instance().set_value(Resolve.SETTING, false)
	difficulty = Difficulty.from_key(OS.get_environment("AUTOPLAY_DIFFICULTY").to_lower())
	var save := SaveGame.new("%s%s_%s_%s" % [SAVE_PREFIX, skill, Difficulty.KEYS[difficulty], "" if run == "" else run + "_"])
	SaveGame._instance = save
	save.start_new(1, difficulty)
	print("autoplay: %s on %s (%s), Resolve %s" % [skill, Difficulty.name_of(difficulty), Difficulty.scale_text(difficulty),
		"on" if Resolve.enabled() else "off"])
	wanted_skin = StringName(OS.get_environment("AUTOPLAY_SKIN").to_lower())
	if wanted_skin != &"" and Skins.find(wanted_skin).id != wanted_skin:
		print("autoplay: no skin %s; wearing the last one bought" % wanted_skin)
		wanted_skin = &""
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
			var row := {"id": id, "tries": 0, "clear": -1.0, "resolve": 0, "spent": 0.0, "farms": 0, "farm_time": 0.0}
			stage_rows.append(row)
			while true:
				tries += 1
				var bought := _spend(save)
				var skins := _buy_skins(save)
				var r: Dictionary = await _play(act, number, tries == 1)
				total += r.time
				act_time += r.time
				row.tries = tries
				row.spent += r.time
				if r.cleared:
					row.clear = r.time
					row.resolve = r.resolve
				_say("%s try %d: %s  resolve %d  time %s  waves %s  kills %d  minHP %d%%  lvl %d  pots %d  dodges %d  dealt %d  taken %d  gold %d  blue+%d  tree %s  skin %s  gift %s%s" % [
					id, tries, "CLEARED" if r.cleared else "FAILED ", r.resolve, StageResult.clock(r.time), r.waves, r.kills, int(r.min_hp * 100), r.level,
					r.potions, r.dodges, int(r.dealt), int(r.damage_taken), r.gold, r.blue, _tree_text(save), Skins.find(save.skin).display_name,
					r.gift, ("  died to " + r.killer) if not r.cleared else ""])
				if bought != "":
					_say("    bought: " + bought)
				if skins != "":
					_say("    bought skin: " + skins)
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
					row.farms += 1
					row.farm_time += f.time
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


## The summary (a line per stage tried, then the tree and essences the run
## ended with), the real time, and the run is over.
func _finish(started: int) -> void:
	var save := SaveGame.instance()
	_say("== Summary: %s on %s, Resolve %s" % [skill, Difficulty.name_of(difficulty), "on" if Resolve.enabled() else "off"])
	for row in stage_rows:
		var outcome := "cleared in %s with Resolve %d" % [StageResult.clock(row.clear), row.resolve] if row.clear >= 0.0 else "not cleared"
		var farm := ", farm %d runs %s" % [row.farms, StageResult.clock(row.farm_time)] if row.farms > 0 else ""
		_say("summary %s: tries %d, %s, spent %s%s" % [row.id, row.tries, outcome, StageResult.clock(row.spent), farm])
	var in_stages := 0.0
	var visits := 0
	var retries := 0
	for row in stage_rows:
		in_stages += row.spent + row.farm_time
		visits += 1 + row.farms
		retries += row.tries - 1
	var outside: float = visits * tier.between + retries * tier.retry
	_say("summary time: %s in stages; with %d visits to the main screen at %d s and %d retries at %d s, about %s of play time" % [
		_hours(in_stages), visits, int(tier.between), retries, int(tier.retry), _hours(in_stages + outside)])
	_say("summary tree: %s; essences B%d O%d P%d" % [_tree_text(save), save.essences.amount(Essences.BLUE),
		save.essences.amount(Essences.ORANGE), save.essences.amount(Essences.PURPLE)])
	_say("real seconds: %d" % ((Time.get_ticks_msec() - started) / 1000))
	quit()


## "4 h 12" for seconds.
func _hours(seconds: float) -> String:
	var minutes := int(seconds / 60.0)
	return "%d h %02d" % [minutes / 60, minutes % 60]


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
	# A free claim (E's and R's rank 1) is taken as soon as it opens, as a
	# player would, not when the order reaches it.
	for id in save.tree.free_ids():
		if save.tree.buy(id, save.essences):
			bought.append("%s%d" % [id, save.tree.level(id)])
	for want: Array in BUY_ORDER:
		var id: StringName = want[0]
		if save.tree.node(id) == null or save.tree.level(id) >= want[1]:
			continue
		if not save.tree.next_level_open(id):
			continue
		if not save.tree.can_buy(id, save.essences):
			# Short of orange only: forge it from blue, if the blue still
			# pays this level's blue cost after that.
			var price := save.tree.cost(id)
			var missing := price.y - save.essences.amount(Essences.ORANGE)
			if missing <= 0 or not save.essences.can_afford(price.x + missing * Essences.FORGE_BLUE):
				break
			save.essences.forge(missing)
			bought.append("forged %d orange" % missing)
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


## Buys skins with purple through the Skin Shop's SaveGame.buy_skin: every
## one it can afford, in Skin Shop order, but AUTOPLAY_SKIN's first (saving
## up for it). Wears AUTOPLAY_SKIN once owned, else the last one bought.
## Returns the names bought.
func _buy_skins(save: SaveGame) -> String:
	var order: Array[StringName] = []
	if wanted_skin != &"":
		order.append(wanted_skin)
	for skin in Skins.ALL:
		if skin.id != wanted_skin:
			order.append(skin.id)
	var bought: PackedStringArray = []
	for id in order:
		if id in save.owned_skins:
			continue
		if save.buy_skin(id):
			bought.append(Skins.find(id).display_name)
			last_skin = id
		elif id == wanted_skin:
			break
	var wear := wanted_skin if wanted_skin in save.owned_skins else last_skin
	if wear != &"":
		save.equip_skin(wear)
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
	bot.tier = tier
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
		"items": bot.item_log, "equipped": bot.equipped_text(), "resolve": stage.lucian.resolve,
		"gift": LanternGifts.display_name(stage.lucian.gift) if stage.lucian.gift != LanternGifts.NONE else "none",
	}
	save.finish_stage(&"cleared" if cleared else &"failed", setup.stage_id)
	paused = false
	stage.queue_free()
	await process_frame
	await process_frame
	return r


class Bot extends Node:
	## react: seconds between decisions; kite: steps back while reloading when
	## a melee enemy's swing is less than this far away (-INF = never); panic:
	## below this share of health it also steps back from a melee enemy whose
	## swing is within PANIC_REACH (0 = never: the tiers that kite already do);
	## warn: share of red warnings stepped out of; bolt: share of enemy bolts
	## sidestepped; e_dps: E used for damage, not only to escape; focus: share
	## of summoners (a Maiden, a Broodmother) it goes for first, as a player
	## who knows them does; fumble: share of its decisions in a fight that are
	## wasted on an aimless step (a new player's hands: no shot, no cast);
	## idle: seconds it looks around after shopping before it presses Skip (and
	## before it picks the Lantern's gift); gift: it picks by GIFT_ORDER;
	## between: seconds on the end screen and the main screen (the tree, the
	## Journey) before each new stage or farm run; retry: seconds on the
	## DEFEATED screen before a Retry. The summary's play time counts the last
	## two; the stage clock doesn't.
	const TIERS := {
		"skilled": {"react": 0.15, "kite": 90.0, "panic": 0.0, "warn": 1.0, "bolt": 0.5, "e_dps": true, "focus": 1.0, "fumble": 0.0, "idle": 1.0, "gift": true, "between": 45.0, "retry": 10.0},
		"average": {"react": 0.25, "kite": 40.0, "panic": 0.0, "warn": 0.8, "bolt": 0.2, "e_dps": false, "focus": 0.5, "fumble": 0.08, "idle": 3.0, "gift": false, "between": 75.0, "retry": 15.0},
		"novice": {"react": 0.35, "kite": -INF, "panic": 0.25, "warn": 0.5, "bolt": 0.0, "e_dps": false, "focus": 0.0, "fumble": 0.25, "idle": 6.0, "gift": false, "between": 120.0, "retry": 20.0},
	}
	## A summoner this far past his reach is still worth walking to.
	## The skilled tier's gifts, best first (LanternGifts ids): Keen Edge, Quick
	## Hands, Thirst, Second Wind, Focus, Ward, Light Step, Fortune.
	const GIFT_ORDER := [1, 2, 6, 4, 3, 7, 5, 8]
	const FOCUS_WALK := 200.0
	## A wasted decision is a step this long in any direction.
	const FUMBLE_STEP := 90.0
	## A walk to the merchant that takes longer than this (a blocked path)
	## shops anyway, so a stuck bot doesn't skew the numbers.
	const WALK_LIMIT := 10.0
	const POTION_AT := 0.55
	## A hurt player (below the tier's panic share) backs away from a melee
	## enemy whose swing is less than this far away.
	const PANIC_REACH := 150.0
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
	## This break's seconds spent walking to the merchant, and looking around
	## after shopping.
	var _walked := 0.0
	var _idled := 0.0
	## Seconds the Lantern's gift pick has been open.
	var _gift_open := 0.0

	func _ready() -> void:
		# The gift's pick pauses the game: the bot still has to click it.
		process_mode = Node.PROCESS_MODE_ALWAYS
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
		if get_tree().paused:
			_pick_gift(delta)
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

	## The Lantern's gift: after `idle` seconds the skilled tier clicks the
	## card first in GIFT_ORDER; the others click the first card.
	func _pick_gift(delta: float) -> void:
		if stage.gifts == null or stage.gifts.pick == null:
			return
		_gift_open += delta
		if _gift_open < tier.idle:
			return
		_gift_open = 0.0
		var pick := stage.gifts.pick
		var card := 0
		if tier.gift:
			for id in GIFT_ORDER:
				if id in pick.ids:
					card = pick.ids.find(id)
					break
		pick.cards[card].pressed.emit()

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
			_walked = 0.0
			_idled = 0.0
		_was_break = in_break
		_survive(enemies)
		if _dodge() or _dodge_bolts():
			return
		if enemies.is_empty():
			_between_waves(in_break)
			return
		if _rng.randf() < tier.fumble:
			lucian.command_move(lucian.global_position + Vector2.from_angle(_rng.randf() * TAU) * FUMBLE_STEP)
			return
		var target := _pick_target(enemies)
		_cast(target, enemies)
		_fight(target, enemies)

	## Potions and summoner spells when low.
	func _survive(enemies: Array[EnemyUnit]) -> void:
		var share := lucian.hp / lucian.stats.max_hp
		if share < POTION_AT and lucian.restores.count(&"hp_potion") == 0:
			# Key 7, as a player would: the backpack has no Use button.
			if lucian.use_potion_cell(Inventory.HP_POTION_CELL):
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

	## Between waves: loot, then a walk to the merchant, a moment to look
	## around, then Skip. A full backpack
	## leaves loot on the ground; with an equip slot free, the bot equips first
	## to make room, as a player would.
	func _between_waves(in_break: bool) -> void:
		for node in stage.get_node("World").get_children():
			var drop := node as LootDrop
			if drop and lucian.inventory.space_for(drop.item) == 0 and _free_equip_slot(drop.item) >= 0:
				_equip()
			if drop and lucian.inventory.space_for(drop.item) > 0:
				lucian.command_move(drop.global_position)
				return
		if not in_break:
			return
		if not _shopped and is_instance_valid(stage.merchant):
			# He walks to the merchant first, as a player must.
			if lucian.global_position.distance_to(stage.merchant.global_position) > Merchant.INTERACT_RANGE and _walked < WALK_LIMIT:
				_walked += tier.react
				lucian.command_move(stage.merchant.global_position)
				return
			_shopped = true
			_shop()
		if _idled < tier.idle:
			_idled += tier.react
			return
		stage.skip_break()

	## The merchant, as a player would use him (the shop pauses the game).
	func _shop() -> void:
		var shop := Shop.new(stage.merchant.stock, lucian.inventory, stage.wallet)
		shop.refresh_cost = stage.run.refresh_cost
		var catalog := lucian.item_catalog
		var potion := catalog.find(&"hp_potion")
		_note("gold %d" % stage.wallet.gold)
		# Crafts first, at the merchant's fee, then items.
		_craft(shop)
		# Items: the best fragment or legendary affordable that has somewhere to
		# go, keeping 100 for potions.
		for pass_count in 3:
			var best := -1
			for slot in MerchantStock.SLOTS:
				var item := shop.stock.item_at(slot)
				if item == null or stage.wallet.gold < item.cost + 100:
					continue
				if lucian.inventory.space_for(item) == 0 and _free_equip_slot(item) < 0:
					continue
				# A second penetration item could never be worn.
				if item.is_penetration() and _holds_penetration():
					continue
				if best < 0 or item.cost > shop.stock.item_at(best).cost:
					best = slot
			if best < 0:
				break
			var bought := shop.stock.item_at(best)
			# A full backpack takes nothing: it is dragged onto a free equip slot.
			var cell := -1 if lucian.inventory.space_for(bought) > 0 else _free_equip_slot(bought)
			if shop.buy_slot(best, cell) == Shop.Result.OK:
				_note("buy %s (%d)" % [bought.display_name, bought.cost])
		_craft(shop)
		# Potions: up to 4.
		var have := 0
		var index := _find(&"hp_potion")
		if index >= 0:
			have = lucian.inventory.count_at(index)
		while have < 4 and shop.buy_potion(potion) == Shop.Result.OK:
			have += 1
		_equip()

	## The first empty open equip slot that takes `item` (the one-penetration
	## rule allowing), or -1.
	func _free_equip_slot(item: ItemData) -> int:
		var inv := lucian.inventory
		for i in range(Inventory.EQUIP_START, Inventory.EQUIP_END):
			if inv.item_at(i) == null and inv.can_put(i, item):
				return i
		return -1

	## A penetration item is held anywhere: equipped or in the backpack.
	func _holds_penetration() -> bool:
		var inv := lucian.inventory
		for i in Inventory.SIZE:
			var item := inv.item_at(i)
			if item and not inv.is_locked(i) and item.is_penetration():
				return true
		return false

	## Crafts any two fragments into their legendary at the merchant's Craft
	## tab, while the fee leaves 100 gold for potions; never a second
	## penetration item, which could not be worn.
	func _craft(shop: Shop) -> void:
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
					var made := shop.craft_result(a, b)
					var fee := shop.craft_fee(a, b)
					if made and made.is_penetration() and _holds_penetration():
						continue
					if made and stage.wallet.gold >= fee + 100 and shop.craft(a, b) == Shop.Result.OK:
						_note("craft %s (fee %d)" % [made.display_name, fee])
						again = true
						break
				if again:
					break

	## The priciest items go into the open equip slots, with at most one
	## penetration item (the priciest); Health potions in the backpack top up
	## their cell (key 7), and the boots stay in theirs. Each open slot is
	## filled in turn with the priciest item not yet placed; a penetration item
	## takes the slot of the one equipped, if any, so the rule never refuses it.
	func _equip() -> void:
		var inv := lucian.inventory
		for i in Inventory.BACKPACK_SIZE:
			var held := inv.item_at(i)
			if held and held.id == &"hp_potion" and not inv.is_locked(i):
				inv.apply_drop(i, Inventory.HP_POTION_CELL)
		var placed: Array[int] = []
		var has_pen := false
		while placed.size() < inv.unlocked_equip:
			var best := -1
			for i in Inventory.SIZE:
				var item := inv.item_at(i)
				if inv.is_locked(i) or item == null or item.is_potion() or item.is_boots() or placed.has(i):
					continue
				if item.is_penetration() and has_pen:
					continue
				# On a tie the item already equipped wins, so two items of one
				# price never swap back and forth.
				if best >= 0 and (item.cost < inv.item_at(best).cost or (item.cost == inv.item_at(best).cost and i < Inventory.EQUIP_START)):
					continue
				best = i
			if best < 0:
				break
			var cell := _equip_cell(best, placed)
			if best != cell:
				inv.apply_drop(best, cell)
			placed.append(cell)
			var worn := inv.item_at(cell)
			has_pen = has_pen or (worn != null and worn.is_penetration())
		lucian.refresh_stats()

	## The open equip slot not in `placed` that the item in cell `index` goes
	## to: its own when it is equipped, the slot of the penetration item
	## equipped when it is one too, else the first.
	func _equip_cell(index: int, placed: Array[int]) -> int:
		var inv := lucian.inventory
		var free: Array[int] = []
		for i in range(Inventory.EQUIP_START, Inventory.EQUIP_START + inv.unlocked_equip):
			if not placed.has(i):
				free.append(i)
		if free.has(index):
			return index
		if inv.item_at(index).is_penetration():
			for i in free:
				if inv.item_at(i) and inv.item_at(i).is_penetration():
					return i
		return free[0]

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
			# A summoner within a short walk comes first for a player who knows
			# it: its summons keep coming while it lives.
			if unit.data.summon_id != &"" and d <= reach + FOCUS_WALK and not _skips(unit, tier.focus):
				score = -2000.0 + d
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
		var panicking: bool = lucian.hp / lucian.stats.max_hp < tier.panic and close < PANIC_REACH
		if (close < tier.kite or panicking) and reloading:
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
