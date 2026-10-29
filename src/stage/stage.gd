class_name Stage
extends Node2D
## The on-stage screen. Owns the stage gold and the merchant, and wires its
## children together.

const DUMMY_SCENE := preload("res://src/enemies/training_dummy.tscn")
const EXTRA_DUMMY_RING := 300.0
## Up, right, left and up-right of the first dummy: never toward the merchant.
const EXTRA_DUMMY_ANGLES := [-PI / 2.0, 0.0, PI, -PI / 4.0]

## The stage is over: `result` is &"left", &"cleared" or &"failed"; `then` is
## where the player chose to go: &"main", &"retry", &"next" or &"title".
signal finished(result: StringName, then: StringName)
## Exit the game was chosen in the menu.
signal exit_requested
## Leave this stage was chosen in the menu. Whoever runs the stage asks
## first, then calls leave().
signal leave_requested
## An enemy spawned by the stage died (after its rewards).
signal enemy_died(enemy: EnemyUnit)

## Damage numbers over Lucian are smaller than over enemies.
const LUCIAN_NUMBER_SCALE := 0.8
const ENEMY_PATH := "res://data/enemies/%s.tres"
const ESSENCE_ICONS := {
	Essences.BLUE: preload("res://assets/art/ui/essence_blue.svg"),
	Essences.ORANGE: preload("res://assets/art/ui/essence_orange.svg"),
	Essences.PURPLE: preload("res://assets/art/ui/essence_purple.svg"),
}
const ESSENCE_COLORS := {Essences.BLUE: Color("5aa9ff"), Essences.ORANGE: Color("ffa040"), Essences.PURPLE: Color("b46cff")}
## How far from its camp's point (each way) a wave enemy appears (from a
## spawn point: the map's spawn_jitter).
const CAMP_JITTER := 90.0
## How far from where the parent died its splits appear.
const SPLIT_SPREAD := 40.0
## A summon's spot must be this clear of walls and the abyss, else it comes
## out on its summoner.
const SUMMON_MARGIN := 30.0
const ESCAPED_COLOR := Color("d8dde6")
## Act 1's tips: id -> [the text, the actions whose keys it names].
const TIPS := {
	&"move": ["%s to move. Hold it to keep walking.", [&"move"]],
	&"attack": ["%s on an enemy to attack it.", [&"attack"]],
	&"attack_move": ["Press %s, then %s: attack the enemy under the cursor, or the weakest one in range.", [&"attack_move", &"attack"]],
	&"siege": ["A red circle marks where a shell will land. Step out of it!", []],
	&"merchant": ["%s on the merchant to buy items with your gold.", [&"move"]],
	&"dash": ["%s to dash toward the cursor. Your next shot is ready when you land.", [&"skill_e"]],
	&"hook": ["Thresh's hook flies along the red line. Move sideways!", []],
}
## Act 1's reward lines on its first clear.
const ACT_1_REWARDS: Array[String] = [
	"Lucian takes Senna's gun: two guns from now on",
	"E – Relentless Pursuit: level 1 in the Evolution Tree",
	"Q – Piercing Light and W – Ardent Blaze can now be bought in the Evolution Tree",
]

var wallet := Wallet.new()
## The merchant on the map, or null.
var merchant: Merchant
## Items tab slots the merchant can sell from (2, up to 4 later from the
## Evolution Tree).
var shop_slots := 2
## What Lucian and the merchant start with. The default is the sandbox.
var run := StageSetup.new()
## Debug: more dummies around the first one, for Runaan's and Statikk Shiv.
var extra_dummies: Array[TrainingDummy] = []
## Essences collected in this stage, for the HUD and the result panel.
var collected := {Essences.BLUE: 0, Essences.ORANGE: 0, Essences.PURPLE: 0}
var rng := RandomNumberGenerator.new()
## The stage's waves; null in Training.
var runner: WaveRunner
## Lucian's invulnerable flag as a cutscene found it (debug God mode survives).
var _invulnerable_before_freeze := false
var result := StageResult.new()
## Kills, damage and gold, for the end screen.
var stats := StageStats.new()
## First-clear rewards, for the result panel.
var reward_lines: Array[String] = []
## Seconds played in this stage (the stage only processes while unpaused).
var elapsed := 0.0
## Act 1's ally, on the first play only.
var senna: Senna
## The boss of the boss wave, once spawned.
var boss_unit: EnemyUnit
## The scene playing, or null. The wave countdown waits while one plays.
var cutscene: Cutscene

var _next_spawn := 0
## The map's ledges taken: ledge index -> the perched unit put on it (it may
## be dead or freed since; see _free_ledge).
var _perched := {}
## Act 1's first play: Senna has taught E (at the first break).
var _taught_e := false
## Debug jumps so far (_remove_every_enemy); a deferred summon or split
## asked for before the last one is dropped.
var _jumps := 0

@onready var arena: StageMap = $Arena
@onready var lucian: Lucian = $World/Lucian
@onready var dummy: TrainingDummy = $World/TrainingDummy
@onready var damage_numbers: DamageNumberSpawner = $DamageNumbers
@onready var camera: StageCamera = $StageCamera
@onready var hud: Hud = $Hud
@onready var debug_table: DebugTable = $DebugTable
@onready var screens: ScreenSwitcher = $Screens


## Call before adding the stage to the tree.
func setup(stage_run: StageSetup) -> void:
	run = stage_run


func _ready() -> void:
	if run.act > 0:
		_use_map(StageMaps.create(run.act, run.stage))
	rng.randomize()
	var settings := GameSettings.instance()
	settings.apply()
	settings.changed.connect(_on_setting_changed)
	lucian.queue_casts = settings.get_value(&"queue_casts")
	screens.settings.setup(settings)
	screens.controller = lucian.get_node("Controller")
	if not Sfx.exists():
		add_child(Sfx.new())
	screens.menu.leave_requested.connect(leave_requested.emit)
	# Game connects `leave_requested` before adding the stage; alone, nobody would act on Leave.
	screens.menu.set_leave_enabled(not leave_requested.get_connections().is_empty())
	screens.menu.exit_requested.connect(_exit)
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	camera.setup(lucian, arena.get_bounds().grow(StageMap.WALL_THICKNESS))
	lucian.projectile_parent = $Projectiles
	if dummy:
		dummy.damage_taken.connect(damage_numbers.spawn.bind(dummy))
	lucian.apply_setup(run)
	shop_slots = run.shop_slots
	debug_table.setup(self)
	add_child(result)
	result.chosen.connect(func(then: StringName) -> void: finished.emit(&"cleared" if result.cleared else &"failed", then))
	lucian.died.connect(_on_lucian_died)
	lucian.damage_received.connect(damage_numbers.spawn.bind(lucian, LUCIAN_NUMBER_SCALE))
	lucian.damage_received.connect(func(_info: DamageInfo, amount: float) -> void: stats.damage_taken += amount)
	screens.backpack.setup(lucian.inventory)
	screens.backpack.potion_used.connect(lucian.use_item)
	screens.backpack_toggled.connect(debug_table.set_docked_right)
	lucian.merchant_reached.connect(_open_shop)
	screens.backpack.traded.connect(func(ok: bool) -> void: Sfx.play(&"coin" if ok else &"error"))
	if run.act == 0:
		add_merchant()
	else:
		_start_waves()
	hud.setup(lucian, wallet, self)
	if run.tutorial:
		_start_tutorial()


## Frees the mouse _ready confined, for the main screen and the title.
func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	if result.visible:
		return
	elapsed += delta
	if runner and not lucian.dead and cutscene == null:
		runner.tick(delta)


## Skip (the HUD's button): the next wave now, plus the regen of the time skipped.
func skip_break() -> void:
	if runner:
		lucian.restore_for(runner.skip())


## Cutscenes: the world stops (tweens still move it), the HUD hides, and
## ESC and P do nothing.
func freeze(on: bool) -> void:
	for node: Node in [$World, $Warnings, $Projectiles, camera]:
		node.process_mode = Node.PROCESS_MODE_DISABLED if on else Node.PROCESS_MODE_INHERIT
	hud.visible = not on
	screens.locked = on
	if on:
		_invulnerable_before_freeze = lucian.invulnerable
		lucian.invulnerable = true
	else:
		lucian.invulnerable = _invulnerable_before_freeze


## Debug and tests: every enemy goes (no rewards) and the boss wave comes next.
func jump_to_boss_wave() -> void:
	if runner == null or run.boss == &"":
		return
	_remove_every_enemy()
	runner.skip_to_boss()


## Debug and tests: every enemy goes (no rewards) and the stage's last wave comes next
## (a mini boss stage's mini boss wave).
func jump_to_last_wave() -> void:
	if runner == null:
		return
	_remove_every_enemy()
	runner.skip_to_last_wave()


## A jump's sweep: every enemy goes, and a summon or split still on its way
## never comes (_jumps): the jump reset the wave's count, so it would come
## uncounted, and its death would end the next wave one enemy early.
func _remove_every_enemy() -> void:
	_jumps += 1
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		enemy.remove_from_group(&"enemies")
		enemy.queue_free()


## The result panel over a paused game; ESC and P stop working.
func show_result(is_cleared: bool) -> void:
	if result.visible:
		return
	remove_merchant()
	if screens.backpack.visible:
		screens.set_backpack_open(false)
	screens.set_menu_open(false)
	screens.locked = true
	hud.visible = false
	var rows := [["Time", StageResult.clock(elapsed)]]
	if runner:
		rows.append(["Waves", "%d / %d" % [runner.waves_done(), runner.total_waves()]])
	rows.append_array([
		["Kills", StageStats.format(stats.kills)],
		["Damage dealt", StageStats.format(stats.damage_dealt)],
		["Damage taken", StageStats.format(stats.damage_taken)],
		["Gold earned", StageStats.format(stats.gold_earned)],
		["Level reached", str(lucian.progress.level)],
	])
	Sfx.play(&"victory" if is_cleared else &"defeat")
	var next := Journey.next_stage(run.act, run.stage) if run.act > 0 else Vector2i.ZERO
	var can_next := is_cleared and next != Vector2i.ZERO and WavePlan.has_stage(Journey.stage_id(next.x, next.y))
	# Losing the tutorial (Act 1 before its first clear) is a game over.
	result.show_result(is_cleared, run.display_name, rows, collected, reward_lines, not is_cleared and run.tutorial, can_next)
	get_tree().paused = true


## Ends the stage as left: the essences collected so far are kept.
func leave() -> void:
	finished.emit(&"left", &"main")


## Run alone (no Game around it) the stage closes the game itself.
func _exit() -> void:
	if exit_requested.get_connections().is_empty():
		get_tree().quit()
	else:
		exit_requested.emit()


## Puts a new merchant at the map's merchant point, replacing any old one. A new
## merchant is a new visit, with new stock.
func add_merchant() -> void:
	remove_merchant()
	merchant = Merchant.new()
	merchant.setup(lucian.item_catalog)
	merchant.stock.unlocked = shop_slots
	merchant.position = arena.merchant_point
	$World.add_child(merchant)


## Takes the merchant off the map, closing his shop if it is open.
func remove_merchant() -> void:
	if screens.is_shopping():
		screens.set_backpack_open(false)
	if is_instance_valid(merchant):
		merchant.remove_from_group(&"merchants")
		merchant.queue_free()
	merchant = null


## An act's map in place of the sandbox arena, its terrain (lava, water,
## plants) added to the world; the training dummy goes.
func _use_map(map: StageMap) -> void:
	remove_child(arena)
	arena.queue_free()
	map.name = "Arena"
	add_child(map)
	move_child(map, 0)
	arena = map
	for node in map.build_terrain(lucian):
		$World.add_child(node)
	if not map.mist.is_empty():
		var black_mist := BlackMist.new()
		black_mist.banks = map.mist
		black_mist.lucian = lucian
		$World.add_child(black_mist)
	$World.remove_child(dummy)
	dummy.queue_free()
	dummy = null
	lucian.blink_to(map.lucian_start)


## Debug: `count` dummies in all, the extras in a ring around the first.
func set_dummy_count(count: int) -> void:
	for extra in extra_dummies:
		extra.queue_free()
	extra_dummies.clear()
	for i in maxi(count - 1, 0):
		var extra: TrainingDummy = DUMMY_SCENE.instantiate()
		extra.position = dummy.position + Vector2.from_angle(EXTRA_DUMMY_ANGLES[i]) * EXTRA_DUMMY_RING
		$World.add_child(extra)
		extra.damage_taken.connect(damage_numbers.spawn.bind(extra))
		debug_table.watch(extra)
		extra_dummies.append(extra)


## Puts an enemy of type `id` on the map at `at`, wired for damage numbers,
## the debug meter, rewards, escapes and summons.
func spawn_enemy(id: StringName, at: Vector2, wave := 1) -> EnemyUnit:
	return spawn_unit(load(ENEMY_PATH % id), at, wave)


## spawn_enemy for data in hand (tests build it in code).
func spawn_unit(data: EnemyData, at: Vector2, wave := 1) -> EnemyUnit:
	var unit := _new_unit(data)
	unit.setup(data, maxi(run.act, 1), wave, lucian)
	unit.max_hp *= WavePlan.hp_share(run.stage_id, data.id)
	unit.projectile_parent = $Projectiles
	unit.warning_parent = $Warnings
	if unit is Boss:
		(unit as Boss).arena = arena
	unit.position = at
	$World.add_child(unit)
	unit.damage_taken.connect(damage_numbers.spawn.bind(unit))
	unit.damage_taken.connect(_count_damage_dealt.bind(unit))
	unit.died.connect(_on_enemy_died)
	unit.escaped.connect(_on_enemy_escaped)
	unit.summon_requested.connect(_on_summon_requested)
	if unit is ThreshFinal:
		## Deferred: a shot's physics callback can bring his fall. Any final Thresh, the debug list's too.
		(unit as ThreshFinal).fell.connect(_on_thresh_fell, CONNECT_DEFERRED)
	debug_table.watch(unit)
	return unit


## Essences go into the save at once, so leaving or losing keeps them. Orange
## and purple sparkle (blue comes with every kill, so it is quiet).
func add_essences(blue: int, orange: int, purple: int, at: Vector2) -> void:
	if orange > 0 or purple > 0:
		Sfx.play(&"essence")
	var amounts := {Essences.BLUE: blue, Essences.ORANGE: orange, Essences.PURPLE: purple}
	var row := 0
	for kind: StringName in Essences.KINDS:
		if amounts[kind] <= 0:
			continue
		SaveGame.instance().essences.add(kind, amounts[kind])
		collected[kind] += amounts[kind]
		var popup := FloatingText.new("+%d" % amounts[kind], ESSENCE_COLORS[kind], ESSENCE_ICONS[kind])
		popup.position = at + Vector2(0, -70 - 30 * row)
		damage_numbers.add_child(popup)
		row += 1


func drop_loot(item: ItemData, at: Vector2) -> void:
	var drop := LootDrop.new()
	drop.item = item
	drop.lucian = lucian
	drop.position = at + Vector2(rng.randf_range(-30, 30), rng.randf_range(-30, 30))
	$World.add_child(drop)


func set_shop_slots(count: int) -> void:
	shop_slots = clampi(count, 1, MerchantStock.SLOTS)
	if merchant:
		merchant.stock.unlocked = shop_slots


func _on_setting_changed(key: StringName) -> void:
	if key == &"queue_casts":
		lucian.queue_casts = GameSettings.instance().get_value(&"queue_casts")


func _open_shop(visited: Merchant) -> void:
	var shop := Shop.new(visited.stock, lucian.inventory, wallet)
	shop.refresh_cost = run.refresh_cost
	screens.open_shop(shop)


func _start_waves() -> void:
	remove_merchant()
	runner = WaveRunner.new(WavePlan.waves(run.stage_id), run.boss)
	runner.spawn_requested.connect(_spawn_wave_enemy)
	runner.wave_started.connect(_on_wave_started)
	## Deferred, both to keep their order: a shot's physics callback can end a wave, and the merchant's body can't be added mid-flush.
	runner.break_started.connect(func(_seconds: float) -> void: add_merchant(), CONNECT_DEFERRED)
	runner.break_ended.connect(remove_merchant, CONNECT_DEFERRED)
	runner.cleared.connect(_on_cleared)
	enemy_died.connect(func(_enemy: EnemyUnit) -> void: runner.enemy_died())


## A horn for each wave. The boss wave has none: the boss's own sound plays
## as it comes (_spawn_wave_enemy).
func _on_wave_started(_wave: int) -> void:
	if not runner.is_boss_wave():
		Sfx.play(&"wave")


## The boss comes at the boss point. A perched enemy (data.perch) stands on
## the map's free ledge nearest Lucian and is marked perched; with none free,
## it comes like any other, from its camp or the spawn points (_spawn_point).
## A boss or a mini boss (any, not only the stage's boss) sounds as it comes.
func _spawn_wave_enemy(id: StringName, wave: int) -> void:
	var data: EnemyData = load(ENEMY_PATH % id)
	if data.is_boss_kind():
		Sfx.play(&"boss")
	if id == run.boss:
		boss_unit = spawn_enemy(id, arena.boss_point)
		# Act 1's cutscene, for a plain Thresh only (spawn_unit wires a final one's fall).
		if boss_unit is Thresh and not (boss_unit is ThreshFinal):
			## Deferred: a shot's physics callback can bring him to half HP, and the freeze can't disable bodies mid-flush.
			(boss_unit as Thresh).phase_ended.connect(_on_thresh_phase_ended, CONNECT_DEFERRED)
		return
	var ledge := _free_ledge() if data.perch else -1
	if ledge < 0:
		spawn_unit(data, _spawn_point(data), wave)
		return
	# Exactly on the ledge, with no jitter: it stands there for good.
	var unit := spawn_unit(data, arena.ledge_points[ledge], wave)
	unit.perched = true
	_perched[ledge] = unit


## The map's ledge nearest Lucian with no perched unit alive on it, or -1:
## a warden stands where the fight is (on a tie, the first ledge).
func _free_ledge() -> int:
	var best := -1
	var best_distance := INF
	for i in arena.ledge_points.size():
		# Untyped: the unit may have been freed.
		var on: Variant = _perched.get(i)
		if is_instance_valid(on) and (on as EnemyUnit).is_alive():
			continue
		var distance := lucian.global_position.distance_to(arena.ledge_points[i])
		if distance < best_distance:
			best = i
			best_distance = distance
	return best


## A wave enemy comes out of its camp when this map has it, else from the
## spawn points in turn.
func _spawn_point(data: EnemyData) -> Vector2:
	if arena.camps.has(data.camp):
		return arena.camps[data.camp] + _jitter(CAMP_JITTER)
	var at := arena.spawn_points[_next_spawn % arena.spawn_points.size()]
	_next_spawn += 1
	return at + _jitter(arena.spawn_jitter)


func _jitter(reach: float) -> Vector2:
	return Vector2(rng.randf_range(-reach, reach), rng.randf_range(-reach, reach))


## Damage dealt is the HP Lucian's hits took; debug damage doesn't count.
func _count_damage_dealt(info: DamageInfo, _final_amount: float, enemy: Enemy) -> void:
	if info.attacker == lucian and info.source != &"debug":
		stats.damage_dealt += enemy.hp_lost


## The boss's purple (first-time or repeat) and the first-clear lines, then the result.
func _on_cleared() -> void:
	if lucian.dead or result.visible:
		return
	var save := SaveGame.instance()
	if run.boss != &"":
		var data: EnemyData = load(ENEMY_PATH % run.boss)
		var first_time := not String(run.boss) in save.bosses
		var purple := save.award_boss(String(run.boss), data.purple_first, data.purple_repeat)
		if purple > 0:
			add_essences(0, 0, purple, lucian.global_position)
			reward_lines.append("+%d purple essence (%s)" % [purple, "first clear" if first_time else "repeat"])
	if not run.stage_id in save.cleared:
		if run.stage < Journey.stage_count(run.act):
			reward_lines.append("Stage %s is open" % Journey.stage_id(run.act, run.stage + 1))
		elif run.act < Journey.ACTS.size():
			reward_lines.append("Act %d is open" % (run.act + 1))
		else:
			reward_lines.append("The story is complete")
	show_result(true)


func _on_lucian_died() -> void:
	await create_tween().tween_interval(Lucian.DEATH_FADE).finished
	show_result(false)


## A boss or mini boss has its own script; a jungle monster is a Monster;
## every other enemy is a minion.
func _new_unit(data: EnemyData) -> EnemyUnit:
	match data.behavior:
		&"thresh":
			return Thresh.new()
		&"thresh_final":
			return ThreshFinal.new()
		&"akshan":
			return Akshan.new()
		&"infernal_drake":
			return InfernalDrake.new()
		&"ocean_drake":
			return OceanDrake.new()
		&"maokai":
			return Maokai.new()
		&"elise":
			return Elise.new()
		&"elder_dragon":
			return ElderDragon.new()
		&"dark_lucian":
			return DarkLucian.new()
		&"karthus":
			return Karthus.new()
		&"karthus_revived":
			var revived := Karthus.new()
			revived.revived = true
			return revived
		&"hecarim":
			return Hecarim.new()
		&"swarm", &"flank", &"brute", &"spit", &"flee":
			return Monster.new()
		&"bomber", &"charger", &"warden":
			return Specter.new()
	return Minion.new()


## Act 1's first play: Senna fights too, teaches E at the first break, and a
## tip comes with each new thing.
func _start_tutorial() -> void:
	_add_senna()
	_tip(&"move")
	runner.spawn_requested.connect(_on_tutorial_spawn)
	enemy_died.connect(func(_enemy: EnemyUnit) -> void: _tip(&"attack_move"))
	## Deferred: a shot's physics callback can end the wave, and the lesson's freeze can't disable bodies mid-flush.
	runner.break_started.connect(_on_tutorial_break, CONNECT_DEFERRED)
	runner.boss_wave_started.connect(func(_boss: StringName) -> void: _tip(&"hook"))


## The first break: Senna teaches E in a short scene (the countdown waits),
## then the dash and merchant tips. Later breaks only bring the merchant tip.
func _on_tutorial_break(_seconds: float) -> void:
	if _taught_e or lucian.dead or result.visible:
		_tip(&"merchant")
		return
	_taught_e = true
	cutscene = SennaTeachesE.new()
	cutscene.done.connect(_on_lesson_done)
	cutscene.start(self)


func _on_lesson_done() -> void:
	cutscene = null
	lucian.teach_skill(ChampionProgress.Slot.E)
	_tip(&"dash")
	_tip(&"merchant")


func _on_tutorial_spawn(id: StringName, _wave: int) -> void:
	_tip(&"attack")
	if id == WavePlan.SIEGE:
		_tip(&"siege")


func _add_senna() -> void:
	senna = Senna.new()
	senna.lucian = lucian
	senna.projectile_parent = $Projectiles
	senna.position = arena.ally_start
	$World.add_child(senna)


## A tip from TIPS, with the keys as bound now.
func _tip(id: StringName) -> void:
	var keys := []
	for action: StringName in TIPS[id][1]:
		keys.append(GameSettings.instance().key_label(action))
	hud.tips.show_tip(id, TIPS[id][0] % keys)


## Thresh at half HP: the fight stops and the cutscene plays.
func _on_thresh_phase_ended() -> void:
	if lucian.dead or result.visible:
		return
	_clear_fight()
	cutscene = ThreshTakesSenna.new()
	cutscene.done.connect(_on_cutscene_done)
	cutscene.start(self)


## Act 1's Thresh is beaten for this act: Senna's lessons, and he and
## Senna leave the map (his rewards: _thresh_leaves).
func _on_cutscene_done() -> void:
	reward_lines.append_array(ACT_1_REWARDS)
	# He has her gun now (the scene gives it to him; a skip still does).
	lucian.one_gun = false
	if is_instance_valid(senna):
		senna.queue_free()
	senna = null
	cutscene = null
	_thresh_leaves(boss_unit)


## Every warning on the ground and every shot in the air goes: a Thresh's
## fight has stopped.
func _clear_fight() -> void:
	for node: Node in $Warnings.get_children() + $Projectiles.get_children():
		node.queue_free()


## A final Thresh falls in Phase 2 (the boss wave's, or one from the debug
## list): the fight stops, every soul he summoned goes free (vanish), and he
## leaves with his rewards.
func _on_thresh_fell(thresh: ThreshFinal) -> void:
	if lucian.dead or result.visible or not is_instance_valid(thresh):
		return
	_clear_fight()
	for enemy: Node in get_tree().get_nodes_in_group(&"enemies"):
		var unit := enemy as EnemyUnit
		if unit and unit.summoned and unit.summoner == thresh:
			unit.vanish()
	if thresh != boss_unit:
		_thresh_leaves(thresh)
		return
	cutscene = SennaFreed.new()
	cutscene.done.connect(_on_ending_done)
	cutscene.start(self)


## The ending is over (played or skipped): Senna is free, and he leaves.
## With him gone already, the stage still ends (its purple comes in _on_cleared).
func _on_ending_done() -> void:
	cutscene = null
	reward_lines.append("Senna is free")
	if is_instance_valid(boss_unit):
		_thresh_leaves(boss_unit)
	elif runner:
		runner.finish()


## A Thresh is beaten: his blue and orange now, rising where he stands (as a
## kill's do). He leaves the map and the wave counts him out, as a death
## would (that may end the wave). The boss wave's Thresh also ends the stage:
## finish(), even with other enemies about; his purple comes in _on_cleared.
func _thresh_leaves(thresh: EnemyUnit) -> void:
	var reward := KillRewards.roll(thresh.data, maxi(run.act, 1), run, rng)
	add_essences(reward.blue, reward.orange, 0, thresh.global_position)
	# Out of "enemies" now, so the radar and the boss bar drop him at once.
	thresh.remove_from_group(&"enemies")
	thresh.queue_free()
	var was_boss := thresh == boss_unit
	if was_boss:
		boss_unit = null
	if runner:
		runner.enemy_died()
		if was_boss:
			runner.finish()


## A kill: its rewards (a summon's are small); its splits (counted at once,
## spawned deferred); its loot (none from a summon); its buff for Lucian; a
## mini boss's purple; its summoner told. Then `enemy_died`.
func _on_enemy_died(enemy: Enemy) -> void:
	var unit := enemy as EnemyUnit
	var data := unit.data
	var reward := KillRewards.roll(data, maxi(run.act, 1), run, rng, unit.summoned)
	wallet.add(reward.gold)
	stats.gold_earned += reward.gold
	stats.kills += 1
	lucian.progress.add_xp(reward.xp)
	add_essences(reward.blue, reward.orange, 0, unit.global_position)
	# Its splits join the wave now, so this death never ends it.
	var splits := data.split_count if data.split_into != &"" else 0
	if runner:
		for i in splits:
			runner.enemy_spawned()
	# The kill that ends the stage drops nothing: the result comes up at once,
	# and items don't carry over. A summon drops nothing either (no farming).
	if not unit.summoned and not (runner and runner.is_last_enemy()):
		for item in LootTable.roll(data.kind, lucian.item_catalog, rng):
			drop_loot(item, unit.global_position)
	if splits > 0:
		# Deferred: the killing shot can land inside a physics callback, where no body can be added.
		_spawn_splits.call_deferred(data.split_into, splits, unit.global_position, unit.wave, _jumps)
	if data.buff_on_kill != &"":
		lucian.add_jungle_buff(data.buff_on_kill)
	if data.kind == &"mini_boss":
		_award_mini_boss(data)
	_summon_gone(unit)
	enemy_died.emit(unit)


## `count` enemies of `id` around where their parent died, in its wave
## (already counted in it), unless a debug jump came since (`jumps`).
func _spawn_splits(id: StringName, count: int, at: Vector2, wave: int, jumps: int) -> void:
	if jumps != _jumps:
		return
	for i in count:
		spawn_enemy(id, at + Vector2.from_angle(TAU * i / count) * SPLIT_SPREAD, wave)


## A mini boss's purple, paid on the kill: first-time or repeat, rising over
## Lucian (as a boss's does), with a line for the result.
func _award_mini_boss(data: EnemyData) -> void:
	var save := SaveGame.instance()
	var first_time := not String(data.id) in save.bosses
	var purple := save.award_boss(String(data.id), data.purple_first, data.purple_repeat)
	if purple > 0:
		add_essences(0, 0, purple, lucian.global_position)
		reward_lines.append("+%d purple essence (%s, %s)" % [purple, data.display_name, "first kill" if first_time else "repeat"])


## An enemy got away: its note ("Escaped!", none after a vanish) and it is
## done for the wave; its summoner is told. No rewards, no kill and no
## `enemy_died` (the kill count and the tutorial).
func _on_enemy_escaped(unit: EnemyUnit) -> void:
	if unit.escape_note != "":
		var note := FloatingText.new(unit.escape_note, ESCAPED_COLOR)
		note.position = unit.global_position + Vector2(0, -unit.radius - 40.0)
		damage_numbers.add_child(note)
	_summon_gone(unit)
	if runner:
		runner.enemy_died()


## A summoner calls a summon: counted in the wave at once, as a split is, so
## its summoner's death (even on this frame) never ends the wave before it
## comes; spawned deferred beside it, or on the summoner when that spot is in
## a wall, in the abyss or off the map.
func _on_summon_requested(unit: EnemyUnit, id: StringName, at: Vector2) -> void:
	if runner:
		runner.enemy_spawned()
	var spot := at if arena.is_walkable(at, SUMMON_MARGIN) else unit.global_position
	# Deferred, like splits: a summon called from a physics callback can't add
	# its body there. A weak ref: the deferred call never holds a freed node.
	_spawn_summon.call_deferred(weakref(unit), id, spot, unit.wave, _jumps)


## A summon comes, in its summoner's wave (already counted in it), unless a
## debug jump came since (`jumps`).
func _spawn_summon(from: WeakRef, id: StringName, at: Vector2, wave: int, jumps: int) -> void:
	if jumps != _jumps:
		return
	var summon := spawn_enemy(id, at, wave)
	summon.summoned = true
	summon.summoner = from.get_ref() as EnemyUnit


## A summon died or vanished: its summoner, while it is still there, may
## call another.
func _summon_gone(unit: EnemyUnit) -> void:
	if unit.summoned and is_instance_valid(unit.summoner):
		unit.summoner.summon_gone()
