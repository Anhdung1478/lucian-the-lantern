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
## Act 1's first play: Senna has taught E (at the first break).
var _taught_e := false

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
	screens.menu.leave_requested.connect(func() -> void: finished.emit(&"left", &"main"))
	# Game connects `finished` before adding the stage; alone, nobody would act on Leave.
	screens.menu.set_leave_enabled(not finished.get_connections().is_empty())
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
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		enemy.remove_from_group(&"enemies")
		enemy.queue_free()
	runner.skip_to_boss()


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
	var next := Journey.next_stage(run.act, run.stage) if run.act > 0 else Vector2i.ZERO
	var can_next := is_cleared and next != Vector2i.ZERO and WavePlan.has_stage(Journey.stage_id(next.x, next.y))
	# Losing the tutorial (Act 1 before its first clear) is a game over.
	result.show_result(is_cleared, run.display_name, rows, collected, reward_lines, not is_cleared and run.tutorial, can_next)
	get_tree().paused = true


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


## An act's map in place of the sandbox arena; the training dummy goes too.
func _use_map(map: StageMap) -> void:
	remove_child(arena)
	arena.queue_free()
	map.name = "Arena"
	add_child(map)
	move_child(map, 0)
	arena = map
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
## the debug meter and rewards.
func spawn_enemy(id: StringName, at: Vector2, wave := 1) -> EnemyUnit:
	var data: EnemyData = load(ENEMY_PATH % id)
	var unit := _new_unit(data)
	unit.setup(data, maxi(run.act, 1), wave, lucian)
	unit.max_hp *= WavePlan.hp_share(run.stage_id, id)
	unit.projectile_parent = $Projectiles
	unit.warning_parent = $Warnings
	unit.position = at
	$World.add_child(unit)
	unit.damage_taken.connect(damage_numbers.spawn.bind(unit))
	unit.damage_taken.connect(_count_damage_dealt.bind(unit))
	unit.died.connect(_on_enemy_died)
	debug_table.watch(unit)
	return unit


## Essences go into the save at once, so leaving or losing keeps them.
func add_essences(blue: int, orange: int, purple: int, at: Vector2) -> void:
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
	## Deferred, both to keep their order: a shot's physics callback can end a wave, and the merchant's body can't be added mid-flush.
	runner.break_started.connect(func(_seconds: float) -> void: add_merchant(), CONNECT_DEFERRED)
	runner.break_ended.connect(remove_merchant, CONNECT_DEFERRED)
	runner.cleared.connect(_on_cleared)
	enemy_died.connect(func(_enemy: EnemyUnit) -> void: runner.enemy_died())


func _spawn_wave_enemy(id: StringName, wave: int) -> void:
	if id == run.boss:
		boss_unit = spawn_enemy(id, arena.boss_point)
		if boss_unit is Thresh:
			## Deferred: a shot's physics callback can bring him to half HP, and the freeze can't disable bodies mid-flush.
			(boss_unit as Thresh).phase_ended.connect(_on_thresh_phase_ended, CONNECT_DEFERRED)
		return
	var at := arena.spawn_points[_next_spawn % arena.spawn_points.size()]
	_next_spawn += 1
	spawn_enemy(id, at + Vector2(rng.randf_range(-70, 70), rng.randf_range(-70, 70)), wave)


## The boss's purple (first-time or repeat) and the first-clear lines, then the result.
## Damage dealt is the HP Lucian's hits took; debug damage doesn't count.
func _count_damage_dealt(info: DamageInfo, _final_amount: float, enemy: Enemy) -> void:
	if info.attacker == lucian and info.source != &"debug":
		stats.damage_dealt += enemy.hp_lost


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
	show_result(true)


func _on_lucian_died() -> void:
	await create_tween().tween_interval(Lucian.DEATH_FADE).finished
	show_result(false)


## A boss has its own script; every other enemy is a minion.
func _new_unit(data: EnemyData) -> EnemyUnit:
	match data.behavior:
		&"thresh":
			return Thresh.new()
		&"akshan":
			return Akshan.new()
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
	for node: Node in $Warnings.get_children() + $Projectiles.get_children():
		node.queue_free()
	cutscene = ThreshTakesSenna.new()
	cutscene.done.connect(_on_cutscene_done)
	cutscene.start(self)


## Thresh is beaten for this act: his blue and orange now, rising where he
## sank (as a kill's do), his purple over Lucian in _on_cleared. He and
## Senna leave the map.
func _on_cutscene_done() -> void:
	var reward := KillRewards.roll(boss_unit.data, run.act, run, rng)
	add_essences(reward.blue, reward.orange, 0, boss_unit.global_position)
	reward_lines.append_array(ACT_1_REWARDS)
	# He has her gun now (the scene gives it to him; a skip still does).
	lucian.one_gun = false
	# Out of "enemies" now, so the radar and the boss bar drop him at once.
	boss_unit.remove_from_group(&"enemies")
	for node: Node2D in [boss_unit, senna]:
		if is_instance_valid(node):
			node.queue_free()
	boss_unit = null
	senna = null
	cutscene = null
	# His leaving ends the boss wave like a death would (all 3 waves cleared);
	# finish() ends the stage even if other enemies are still about.
	runner.enemy_died()
	runner.finish()


func _on_enemy_died(enemy: Enemy) -> void:
	var unit := enemy as EnemyUnit
	var reward := KillRewards.roll(unit.data, maxi(run.act, 1), run, rng)
	wallet.add(reward.gold)
	stats.gold_earned += reward.gold
	stats.kills += 1
	lucian.progress.add_xp(reward.xp)
	add_essences(reward.blue, reward.orange, 0, unit.global_position)
	# The kill that ends the stage drops nothing: the result comes up at once,
	# and items don't carry over.
	if not (runner and runner.is_last_enemy()):
		for item in LootTable.roll(unit.data.kind, lucian.item_catalog, rng):
			drop_loot(item, unit.global_position)
	enemy_died.emit(unit)
