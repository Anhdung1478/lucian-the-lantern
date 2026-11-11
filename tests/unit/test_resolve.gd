extends GutTest
## R1: Resolve. Each defeat on a story stage not yet cleared gives a stack
## there, up to 5: more damage dealt and less taken, 10% a stack on Easy and
## Normal, 5% on Hard, none on Extreme, until the stage is cleared.


# --- The rule ------------------------------------------------------------------


func test_a_stack_is_worth_10_percent_5_on_hard_and_nothing_on_extreme() -> void:
	assert_eq(Difficulty.LEVELS.map(func(level: int) -> float: return Difficulty.resolve_step(level)), [0.1, 0.1, 0.05, 0.0])
	assert_eq(Difficulty.resolve_step(7), 0.1, "an unknown level is Normal")


func test_each_defeat_is_a_stack_up_to_5() -> void:
	assert_eq(Resolve.MAX_STACKS, 5)
	for level in [Difficulty.EASY, Difficulty.NORMAL, Difficulty.HARD]:
		assert_eq(range(8).map(func(defeats: int) -> int: return Resolve.stacks(defeats, level)), [0, 1, 2, 3, 4, 5, 5, 5],
			Difficulty.name_of(level))
	assert_eq(Resolve.stacks(3, Difficulty.EXTREME), 0, "Extreme has no Resolve")
	assert_eq(Resolve.stacks(-2, Difficulty.NORMAL), 0)


func test_a_stack_raises_the_damage_dealt_and_lowers_the_damage_taken() -> void:
	for level in [Difficulty.EASY, Difficulty.NORMAL]:
		assert_almost_eq(Resolve.damage_dealt_scale(0, level), 1.0, 0.0001)
		assert_almost_eq(Resolve.damage_taken_scale(0, level), 1.0, 0.0001)
		assert_almost_eq(Resolve.damage_dealt_scale(3, level), 1.3, 0.0001, Difficulty.name_of(level))
		assert_almost_eq(Resolve.damage_taken_scale(3, level), 0.7, 0.0001, Difficulty.name_of(level))
		assert_almost_eq(Resolve.damage_dealt_scale(5, level), 1.5, 0.0001)
		assert_almost_eq(Resolve.damage_taken_scale(5, level), 0.5, 0.0001, "5 stacks halve it")
	assert_almost_eq(Resolve.damage_dealt_scale(5, Difficulty.HARD), 1.25, 0.0001)
	assert_almost_eq(Resolve.damage_taken_scale(5, Difficulty.HARD), 0.75, 0.0001)
	assert_almost_eq(Resolve.damage_dealt_scale(2, Difficulty.HARD), 1.1, 0.0001)
	assert_almost_eq(Resolve.damage_dealt_scale(5, Difficulty.EXTREME), 1.0, 0.0001)
	assert_almost_eq(Resolve.damage_taken_scale(5, Difficulty.EXTREME), 1.0, 0.0001)
	assert_eq([Resolve.percent(3, Difficulty.NORMAL), Resolve.percent(3, Difficulty.HARD), Resolve.percent(5, Difficulty.EASY)], [30, 15, 50])
