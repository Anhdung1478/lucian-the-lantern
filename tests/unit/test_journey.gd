extends GutTest


func test_22_stages_in_all() -> void:
	assert_eq(Journey.all_stage_ids(6).size(), 22)
	assert_eq(Journey.all_stage_ids(1), ["1-1"] as Array[String])


func test_stage_ids() -> void:
	assert_eq(Journey.stage_id(3, 2), "3-2")
	assert_eq(Journey.stage_count(3), 5)
	assert_true(Journey.is_stage_id("6-5"))
	assert_false(Journey.is_stage_id("7-1"))
	assert_false(Journey.is_stage_id("1-2"))
	assert_false(Journey.is_stage_id("junk"))


func test_waves() -> void:
	assert_eq(Journey.waves(3, 4), 5)
	assert_eq(Journey.waves(1, 1), 2)


func test_boss_kind() -> void:
	assert_eq(Journey.boss_kind(3, 2), &"mini_boss")
	assert_eq(Journey.boss_kind(3, 5), &"boss")
	assert_eq(Journey.boss_kind(1, 1), &"boss")
	assert_eq(Journey.boss_kind(2, 1), &"")


func test_acts_cleared_counts_in_a_row_from_act_1() -> void:
	assert_eq(Journey.acts_cleared(["1-1", "2-1", "2-2", "2-3"] as Array[String]), 2)
	assert_eq(Journey.acts_cleared(["2-1", "2-2", "2-3"] as Array[String]), 0)
	assert_eq(Journey.acts_cleared([] as Array[String]), 0)


func test_act_and_stage_unlocks() -> void:
	var cleared: Array[String] = ["1-1"]
	assert_true(Journey.is_act_open(1, cleared))
	assert_true(Journey.is_act_open(2, cleared))
	assert_false(Journey.is_act_open(3, cleared))
	assert_true(Journey.is_stage_open(2, 1, cleared))
	assert_false(Journey.is_stage_open(2, 2, cleared))
	cleared.append("2-1")
	assert_true(Journey.is_stage_open(2, 2, cleared))


func test_endless_needs_every_act() -> void:
	assert_true(Journey.is_endless_open(Journey.all_stage_ids(Journey.ENDLESS_ACT)))
	assert_false(Journey.is_endless_open(Journey.all_stage_ids(2)))


## Every act, Act 6 included: the wave counts, and a boss wave only where
## the Journey shows a boss.
func test_the_wave_plan_matches_the_journey() -> void:
	for act in Journey.ACTS.size():
		for stage in Journey.stage_count(act + 1):
			var id := Journey.stage_id(act + 1, stage + 1)
			assert_eq(Journey.waves(act + 1, stage + 1), WavePlan.waves(id).size(), id)
			assert_eq(Journey.boss_kind(act + 1, stage + 1) == &"boss", WavePlan.boss(id) != &"", id)
	assert_eq(WavePlan.boss("6-5"), &"thresh_final")


func test_next_stage() -> void:
	assert_eq(Journey.next_stage(1, 1), Vector2i(2, 1))
	assert_eq(Journey.next_stage(2, 3), Vector2i(3, 1))
	assert_eq(Journey.next_stage(3, 2), Vector2i(3, 3))
	assert_eq(Journey.next_stage(6, 5), Vector2i.ZERO)


## The Journey map shows each mini boss stage's mini boss: the last enemy of
## its last wave.
func test_mini_boss_is_the_last_enemy_of_a_mini_boss_stage() -> void:
	var expected := {"3-2": &"infernal_drake", "3-4": &"ocean_drake", "5-2": &"maokai", "5-4": &"elise", "6-2": &"karthus_revived", "6-4": &"hecarim"}
	for id: String in expected:
		assert_eq(WavePlan.mini_boss(id), expected[id], id)
		assert_true(String(expected[id]) in SaveGame.BOSS_IDS, id)
	for id: String in ["1-1", "2-1", "3-1", "3-5", "6-5", "junk", "7-1"]:
		assert_eq(WavePlan.mini_boss(id), &"", id)


## The HUD's and the Journey map's name for a stage.
func test_stage_name() -> void:
	assert_eq(Journey.stage_name(1, 1), "Act 1 · The Loss", "an act of one stage")
	assert_eq(Journey.stage_name(3, 4), "Stage 3-4 · The Jungle")
