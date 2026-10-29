extends GutTest
## Endless mode's modifiers (EndlessModifiers): the design's table, the offer
## of three cards, and the reward multipliers a pick writes on the run.

var rng := RandomNumberGenerator.new()


func before_each() -> void:
	rng.seed = 7


func test_six_rows_with_both_lines() -> void:
	assert_eq(EndlessModifiers.ROWS.keys(), [1, 2, 3, 4, 5, 6])
	for id: int in EndlessModifiers.ROWS:
		assert_ne(EndlessModifiers.downside(id), "", "row %d" % id)
		assert_ne(EndlessModifiers.reward(id), "", "row %d" % id)
	assert_eq(EndlessModifiers.downside(1), "Enemies move 20% faster")
	assert_eq(EndlessModifiers.reward(1), "+30% gold")
	assert_eq(EndlessModifiers.downside(EndlessModifiers.NOTHING), "Nothing")
	assert_eq(EndlessModifiers.reward(EndlessModifiers.NOTHING), "Nothing")


func test_each_modifier_has_its_icon() -> void:
	var paths := {1: "stats/move_speed", 2: "ui/essence_orange", 3: "stats/max_hp", 4: "stats/ad", 5: "ui/skull"}
	for id: int in paths:
		var icon := EndlessModifiers.icon(id)
		assert_not_null(icon, "row %d" % id)
		if icon:
			assert_eq(icon.resource_path, "res://assets/art/%s.svg" % paths[id], "row %d" % id)
	assert_null(EndlessModifiers.icon(EndlessModifiers.NOTHING))


func test_the_downsides() -> void:
	assert_eq(EndlessModifiers.enemy_speed(1), 1.2)
	assert_eq(EndlessModifiers.elite_mult(2), 2)
	assert_eq(EndlessModifiers.run_scale(3), {&"max_hp": 0.9} as Dictionary[StringName, float])
	assert_eq(EndlessModifiers.run_scale(4), {&"ad": 0.95} as Dictionary[StringName, float])
	assert_eq(EndlessModifiers.boss_hp(5), 1.25)
	for id in [EndlessModifiers.NONE, EndlessModifiers.NOTHING]:
		assert_eq(EndlessModifiers.enemy_speed(id), 1.0)
		assert_eq(EndlessModifiers.elite_mult(id), 1)
		assert_true(EndlessModifiers.run_scale(id).is_empty())
		assert_eq(EndlessModifiers.boss_hp(id), 1.0)


## A run scale is applied like a skin's scale: its keys are Lucian's stats.
func test_run_scale_keys_are_lucians_stats() -> void:
	var stats := StatBlock.new()
	for id: int in EndlessModifiers.ROWS:
		for key: StringName in EndlessModifiers.run_scale(id):
			assert_true(key in stats, "row %d: %s" % [id, key])


func test_the_rewards_written_on_the_run() -> void:
	var run := StageSetup.new()
	var expected := {
		1: [1.3, 1.0, 1.0, 1.0],
		2: [1.0, 1.0, 1.5, 1.0],
		3: [1.0, 1.15, 1.0, 1.0],
		4: [1.1, 1.0, 1.0, 1.0],
		5: [1.0, 1.0, 1.0, 1.5],
		6: [1.0, 1.0, 1.0, 1.0],
	}
	for id: int in expected:
		EndlessModifiers.apply_rewards(run, id)
		assert_eq([run.gold_mult, run.blue_mult, run.orange_mult, run.purple_mult], expected[id], "row %d" % id)


func test_a_new_pick_replaces_the_old_rewards() -> void:
	var run := StageSetup.new()
	EndlessModifiers.apply_rewards(run, 1)
	EndlessModifiers.apply_rewards(run, 2)
	assert_eq(run.gold_mult, 1.0, "#1's gold is gone")
	assert_eq(run.orange_mult, 1.5)
	EndlessModifiers.apply_rewards(run, EndlessModifiers.NOTHING)
	assert_eq(run.orange_mult, 1.0, "Nothing clears it")


func test_the_offer_is_two_of_1_to_5_and_nothing() -> void:
	for current in range(0, 7):
		for s in 30:
			rng.seed = s
			var cards := EndlessModifiers.offer(rng, current)
			var label := "current %d, seed %d" % [current, s]
			assert_eq(cards.size(), 3, label)
			assert_eq(cards[2], EndlessModifiers.NOTHING, label)
			assert_ne(cards[0], cards[1], label)
			for card in cards.slice(0, 2):
				assert_between(card, 1, 5, label)
				assert_ne(card, current, "%s: the current one is never offered" % label)


func test_every_other_modifier_can_be_offered() -> void:
	var seen := {}
	for i in 100:
		for card in EndlessModifiers.offer(rng, 3):
			seen[card] = true
	assert_eq(seen.keys().size(), 5)
	assert_false(seen.has(3))
