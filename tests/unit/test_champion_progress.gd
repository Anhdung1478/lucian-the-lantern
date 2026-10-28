extends GutTest

const Slot := ChampionProgress.Slot

var progress: ChampionProgress


func before_each() -> void:
	progress = ChampionProgress.new()


func test_starts_at_level_1_with_one_point() -> void:
	assert_eq(progress.level, 1)
	assert_eq(progress.xp, 0)
	assert_eq(progress.skill_points(), 1)
	assert_eq(progress.xp_for_next(), 280)


func test_xp_to_next_follows_formula() -> void:
	assert_eq(ChampionProgress.xp_to_next(1), 280)
	assert_eq(ChampionProgress.xp_to_next(17), 1880)


func test_total_xp_to_level_18() -> void:
	var total := 0
	for level in range(1, 18):
		total += ChampionProgress.xp_to_next(level)
	assert_eq(total, 18360)
	progress.add_xp(total)
	assert_eq(progress.level, 18)


func test_add_xp_below_threshold_keeps_level() -> void:
	progress.add_xp(279)
	assert_eq(progress.level, 1)
	assert_eq(progress.xp, 279)


func test_add_xp_crosses_several_levels() -> void:
	watch_signals(progress)
	progress.add_xp(280 + 380 + 10)
	assert_eq(progress.level, 3)
	assert_eq(progress.xp, 10)
	assert_eq(progress.skill_points(), 3)
	assert_signal_emitted_with_parameters(progress, "level_changed", [3])
	assert_signal_emitted_with_parameters(progress, "xp_changed", [10, 480])


func test_level_caps_at_18_and_xp_stops() -> void:
	progress.add_xp(1_000_000)
	assert_eq(progress.level, 18)
	assert_eq(progress.xp, 0)
	assert_eq(progress.xp_for_next(), 0)
	progress.add_xp(500)
	assert_eq(progress.xp, 0)


func test_basic_skill_rank_needs_level_2n_minus_1() -> void:
	assert_eq(ChampionProgress.required_level(Slot.Q, 1), 1)
	assert_eq(ChampionProgress.required_level(Slot.W, 3), 5)
	assert_eq(ChampionProgress.required_level(Slot.E, 5), 9)


func test_ult_ranks_need_6_11_16() -> void:
	assert_eq(ChampionProgress.required_level(Slot.R, 1), 6)
	assert_eq(ChampionProgress.required_level(Slot.R, 2), 11)
	assert_eq(ChampionProgress.required_level(Slot.R, 3), 16)


func test_rank_up_spends_a_point() -> void:
	watch_signals(progress)
	assert_true(progress.rank_up(Slot.Q))
	assert_eq(progress.ranks[Slot.Q], 1)
	assert_eq(progress.skill_points(), 0)
	assert_signal_emitted_with_parameters(progress, "rank_changed", [Slot.Q, 1])
	assert_signal_emitted_with_parameters(progress, "skill_points_changed", [0])


func test_cannot_rank_up_without_points() -> void:
	progress.rank_up(Slot.Q)
	assert_false(progress.can_rank_up(Slot.W))
	assert_false(progress.rank_up(Slot.W))


func test_level_2_cannot_take_q_rank_2() -> void:
	progress.set_level(2)
	progress.rank_up(Slot.Q)
	assert_false(progress.can_rank_up(Slot.Q), "rank 2 needs level 3")
	assert_true(progress.can_rank_up(Slot.W))


func test_r_locked_before_level_6() -> void:
	progress.set_level(5)
	assert_false(progress.can_rank_up(Slot.R))
	progress.set_level(6)
	assert_true(progress.can_rank_up(Slot.R))


func test_r_rank_2_needs_level_11() -> void:
	progress.set_level(10)
	progress.rank_up(Slot.R)
	assert_false(progress.can_rank_up(Slot.R))
	progress.set_level(11)
	assert_true(progress.can_rank_up(Slot.R))


func test_ranks_cap_at_max() -> void:
	progress.set_level(18)
	for i in 5:
		assert_true(progress.rank_up(Slot.Q))
	assert_false(progress.can_rank_up(Slot.Q))
	for i in 3:
		assert_true(progress.rank_up(Slot.R))
	assert_false(progress.can_rank_up(Slot.R))


func test_all_18_points_fit_into_ranks() -> void:
	progress.set_level(18)
	for slot in [Slot.Q, Slot.W, Slot.E]:
		for i in 5:
			progress.rank_up(slot)
	for i in 3:
		progress.rank_up(Slot.R)
	assert_eq(progress.skill_points(), 0)


func test_bought_rank_caps_rank_up() -> void:
	progress.set_level(5)
	progress.bought[Slot.Q] = 1
	assert_true(progress.rank_up(Slot.Q))
	assert_false(progress.can_rank_up(Slot.Q))


func test_unbought_skill_cannot_rank() -> void:
	progress.bought[Slot.W] = 0
	assert_false(progress.can_rank_up(Slot.W))


func test_reset_ranks_refunds_points() -> void:
	progress.set_level(4)
	progress.rank_up(Slot.Q)
	progress.rank_up(Slot.W)
	watch_signals(progress)
	progress.reset_ranks()
	assert_eq(progress.ranks, [0, 0, 0, 0])
	assert_eq(progress.skill_points(), 4)
	assert_signal_emitted_with_parameters(progress, "skill_points_changed", [4])


func test_set_level_keeps_valid_ranks() -> void:
	progress.set_level(5)
	progress.rank_up(Slot.Q)
	progress.rank_up(Slot.W)
	progress.set_level(3)
	assert_eq(progress.ranks, [1, 1, 0, 0])
	assert_eq(progress.skill_points(), 1)


func test_set_level_down_resets_ranks_when_too_many_spent() -> void:
	progress.set_level(5)
	for slot in [Slot.Q, Slot.W, Slot.E]:
		progress.rank_up(slot)
	progress.set_level(2)
	assert_eq(progress.ranks, [0, 0, 0, 0])
	assert_eq(progress.skill_points(), 2)


func test_set_level_down_resets_ranks_when_rank_needs_higher_level() -> void:
	progress.set_level(6)
	progress.rank_up(Slot.R)
	progress.set_level(5)
	assert_eq(progress.ranks[Slot.R], 0)


func test_set_level_clamps_and_clears_xp() -> void:
	progress.add_xp(100)
	watch_signals(progress)
	progress.set_level(40)
	assert_eq(progress.level, 18)
	assert_eq(progress.xp, 0)
	assert_signal_emitted_with_parameters(progress, "level_changed", [18])
	progress.set_level(0)
	assert_eq(progress.level, 1)


func test_basic_ranks_2_to_5_wait_for_levels_3_5_7_9() -> void:
	for rank in [2, 3, 4, 5]:
		progress.set_level(2 * rank - 2)
		progress.ranks[Slot.Q] = rank - 1
		assert_false(progress.can_rank_up(Slot.Q), "rank %d at level %d" % [rank, 2 * rank - 2])
		progress.set_level(2 * rank - 1)
		progress.ranks[Slot.Q] = rank - 1
		assert_true(progress.can_rank_up(Slot.Q), "rank %d at level %d" % [rank, 2 * rank - 1])


func test_next_rank_bought_and_maxed() -> void:
	progress.bought[Slot.W] = 1
	assert_true(progress.next_rank_bought(Slot.W))
	progress.ranks[Slot.W] = 1
	assert_false(progress.next_rank_bought(Slot.W))
	progress.ranks[Slot.R] = 3
	assert_true(progress.is_maxed(Slot.R))
	assert_false(progress.is_maxed(Slot.Q))
