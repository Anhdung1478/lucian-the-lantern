extends GutTest
## R3: the defeat screen's recap: what killed Lucian, what hurt him most, a tip.

var tree: EvolutionTree
var essences: Essences


const STAGE_SCENE := "res://src/stage/stage.tscn"
const HEAD := "WHAT HIT YOU"
## The card may be this tall (a 1080 screen less the medallion over its edge).
const CARD_LIMIT := 1000.0

func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_death_recap_save_slot_")
	tree = EvolutionTree.new()
	essences = Essences.new()


## Stats where Lucian took `taken` (source id -> damage) and the last hit
## came from `last`.
func _stats(taken: Dictionary, last: StringName, with := &"basic") -> StageStats:
	var stats := StageStats.new()
	stats.damage_by_source = taken
	stats.damage_taken = 0.0
	for amount: float in taken.values():
		stats.damage_taken += amount
	stats.last_hit_by = last
	stats.last_hit_with = with
	return stats


func _build(stats: StageStats) -> Dictionary:
	return DeathRecap.build(stats, tree, essences)


func test_the_killer_is_named_by_its_display_name() -> void:
	var recap := _build(_stats({&"ranged_minion": 10.0}, &"ranged_minion"))
	assert_eq(recap.killed, "Killed by Ranged Minion")


func test_a_burn_or_hazard_with_no_enemy_has_a_plain_name() -> void:
	assert_eq(_build(_stats({&"burn": 10.0}, &"burn", &"burn")).killed, "Killed by burning ground")
	assert_eq(_build(_stats({&"mystery_pit": 10.0}, &"mystery_pit")).killed, "Killed by Mystery Pit")


func test_a_burn_an_enemy_left_names_the_enemy() -> void:
	var recap := _build(_stats({&"gromp": 10.0}, &"gromp", &"burn"))
	assert_eq(recap.killed, "Killed by Gromp's burn")


func test_the_top_three_sources_share_all_the_damage() -> void:
	var recap := _build(_stats({&"raptor": 10.0, &"gromp": 50.0, &"melee_minion": 25.0, &"burn": 15.0}, &"gromp"))
	assert_eq(recap.shares, ["Gromp 50%", "Melee Minion 25%", "Burning ground 15%"] as Array[String])


func test_fewer_sources_make_fewer_shares() -> void:
	assert_eq(_build(_stats({&"gromp": 7.0}, &"gromp")).shares, ["Gromp 100%"] as Array[String])
	assert_eq(_build(_stats({&"gromp": 1.0, &"raptor": 2.0}, &"gromp")).shares, ["Raptor 67%", "Gromp 33%"] as Array[String])


func test_no_damage_taken_gives_no_recap() -> void:
	assert_true(_build(StageStats.new()).is_empty())


func test_the_tip_follows_the_top_source() -> void:
	var expected := {
		&"ranged_minion": DeathRecap.TIP_RANGED, &"gromp": DeathRecap.TIP_RANGED,
		&"melee_minion": DeathRecap.TIP_MELEE, &"raptor": DeathRecap.TIP_MELEE, &"murkwolf": DeathRecap.TIP_MELEE,
		&"ghoul": DeathRecap.TIP_MELEE, &"sapling": DeathRecap.TIP_MELEE,
		&"siege_minion": DeathRecap.TIP_MARKS, &"shadow_siege_minion": DeathRecap.TIP_MARKS,
		&"super_minion": DeathRecap.TIP_ELITE, &"blue_sentinel": DeathRecap.TIP_ELITE, &"spectral_rider": DeathRecap.TIP_ELITE,
		&"elise": DeathRecap.TIP_BOSS, &"karthus": DeathRecap.TIP_BOSS, &"thresh_1": DeathRecap.TIP_BOSS,
		&"burn": DeathRecap.TIP_BURN,
	}
	for id: StringName in expected:
		assert_eq(_build(_stats({id: 10.0, &"melee_minion": 1.0}, id)).tip, expected[id], String(id))


func test_every_enemy_has_a_short_tip() -> void:
	for tip: String in [DeathRecap.TIP_RANGED, DeathRecap.TIP_MELEE, DeathRecap.TIP_MARKS, DeathRecap.TIP_ELITE, DeathRecap.TIP_BOSS, DeathRecap.TIP_BURN]:
		assert_lt(tip.length(), 91, tip)
	for file in DirAccess.get_files_at("res://data/enemies"):
		var id := file.get_basename()
		assert_ne(_build(_stats({StringName(id): 1.0}, StringName(id))).tip, "", id)


func test_the_tree_line_shows_only_when_something_can_be_bought() -> void:
	var stats := _stats({&"gromp": 10.0}, &"gromp")
	assert_eq(_build(stats).tree, "", "no essences: nothing to buy")
	essences.add(Essences.BLUE, 100000)
	essences.add(Essences.ORANGE, 100000)
	assert_eq(_build(stats).tree, DeathRecap.TREE_LINE)


# --- On the end screen ---------------------------------------------------------


func _texts(stage: Stage) -> Array[String]:
	var texts: Array[String] = []
	for label: Label in stage.result.find_children("*", "Label", true, false):
		if label.is_visible_in_tree():
			texts.append(label.text)
	return texts


func _run(setup: StageSetup) -> Stage:
	var stage: Stage = load(STAGE_SCENE).instantiate()
	stage.setup(setup)
	add_child_autofree(stage)
	await wait_process_frames(2)
	return stage


## A stage whose Lucian was hit once by a ranged minion, then ended as `cleared`.
func _end(setup: StageSetup, cleared: bool) -> Stage:
	var stage := await _run(setup)
	var enemy := stage.spawn_enemy(&"ranged_minion", stage.lucian.global_position + Vector2(300, 0))
	stage.lucian.take_damage(enemy.make_hit(50.0))
	stage.show_result(cleared)
	return stage


func after_each() -> void:
	get_tree().paused = false


func test_a_story_defeat_shows_the_recap() -> void:
	var stage := await _end(StageSetup.for_stage(SaveGame.instance(), 2, 1), false)
	assert_eq(stage.result.title.text, "DEFEATED")
	var texts := _texts(stage)
	for line in [HEAD, "Killed by Ranged Minion", "Ranged Minion", "100%", DeathRecap.TIP_RANGED]:
		assert_true(line in texts, line)


func test_a_clear_shows_no_recap() -> void:
	var stage := await _end(StageSetup.for_stage(SaveGame.instance(), 2, 1), true)
	assert_eq(stage.result.title.text, "STAGE CLEARED")
	for text in _texts(stage):
		assert_false(text.begins_with("Killed by") or text == HEAD, text)


func test_the_lost_tutorial_shows_the_recap() -> void:
	SaveGame.instance().reset()
	var stage := await _end(StageSetup.for_stage(SaveGame.instance(), 1, 1), false)
	assert_eq(stage.result.title.text, "GAME OVER")
	assert_true(HEAD in _texts(stage))


func test_a_lost_endless_run_shows_the_recap() -> void:
	var stage := await _end(StageSetup.for_endless(SaveGame.instance(), 3, RandomNumberGenerator.new()), false)
	assert_eq(stage.result.title.text, EndlessDirector.RUN_OVER)
	assert_true(HEAD in _texts(stage))


func test_a_defeat_with_no_damage_shows_no_recap() -> void:
	var stage := await _run(StageSetup.for_stage(SaveGame.instance(), 2, 1))
	stage.show_result(false)
	assert_false(HEAD in _texts(stage))


func test_the_longest_recap_fits_the_card_and_keeps_the_buttons_on_screen() -> void:
	var stage := await _run(StageSetup.for_stage(SaveGame.instance(), 2, 1))
	SaveGame.instance().essences.add(Essences.BLUE, 100000)
	SaveGame.instance().essences.add(Essences.ORANGE, 100000)
	for id: StringName in [&"super_minion", &"ranged_minion", &"raptor", &"burn"]:
		var unit := stage.spawn_enemy(id, stage.lucian.global_position + Vector2(300, 0)) if id != &"burn" else null
		stage.lucian.take_damage(DamageInfo.create(10.0, DamageInfo.Type.TRUE, id, unit))
	SaveGame.instance().record_defeat("2-1")
	stage.show_result(false)
	await wait_process_frames(2)
	assert_true(DeathRecap.TREE_LINE in _texts(stage))
	var plate := stage.result.title.get_parent().get_parent() as Control
	assert_lt(plate.size.y, CARD_LIMIT, "the card, medallion included, fits a 1080 screen")
