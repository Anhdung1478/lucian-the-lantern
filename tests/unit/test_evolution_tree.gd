extends GutTest

var tree: EvolutionTree
var essences: Essences


func before_each() -> void:
	tree = EvolutionTree.new()
	essences = Essences.new()
	essences.set_amount(Essences.BLUE, 10000)
	essences.set_amount(Essences.ORANGE, 1000)


func test_buying_spends_and_levels_up() -> void:
	tree.acts_cleared = 1
	assert_true(tree.buy(&"skill_q", essences))
	assert_eq(tree.level(&"skill_q"), 1)
	assert_eq(essences.amount(Essences.BLUE), 10000 - 100)
	assert_eq(tree.cost(&"skill_q"), Vector2i(200, 0))


func test_q_and_w_open_once_act_1_is_cleared() -> void:
	assert_false(tree.is_open(&"skill_q"))
	assert_false(tree.is_open(&"skill_w"))
	assert_false(tree.buy(&"skill_q", essences))
	tree.acts_cleared = 1
	assert_true(tree.is_open(&"skill_q"))
	assert_true(tree.is_open(&"skill_w"))


func test_passive_needs_any_one_basic_skill() -> void:
	tree.acts_cleared = 1
	assert_false(tree.is_open(&"passive"))
	tree.buy(&"skill_w", essences)
	assert_true(tree.is_open(&"passive"))


func test_r_needs_q_w_e_and_the_passive() -> void:
	tree.acts_cleared = 1
	for id in [&"skill_q", &"skill_w", &"skill_e"]:
		tree.buy(id, essences)
	assert_false(tree.is_open(&"skill_r"))
	tree.buy(&"passive", essences)
	assert_true(tree.is_open(&"skill_r"))


func test_e_rank_1_is_free_after_act_1() -> void:
	assert_false(tree.is_open(&"skill_e"))
	tree.acts_cleared = 1
	assert_eq(tree.cost(&"skill_e"), Vector2i.ZERO)
	assert_true(tree.buy(&"skill_e", Essences.new()))


func test_second_summoner_slot_needs_two_spells() -> void:
	tree.buy(&"flash", essences)
	assert_false(tree.is_open(&"summoner_slot_2"))
	tree.buy(&"heal", essences)
	assert_true(tree.is_open(&"summoner_slot_2"))


func test_maxed_node_cannot_be_bought() -> void:
	for i in 3:
		tree.buy(&"stage_gold", essences)
	assert_true(tree.is_maxed(&"stage_gold"))
	assert_eq(tree.cost(&"stage_gold"), Vector2i.ZERO)
	assert_false(tree.buy(&"stage_gold", essences))


func test_buy_refused_when_too_poor_or_closed() -> void:
	assert_false(tree.buy(&"skill_r", essences))
	assert_false(tree.buy(&"skill_q", Essences.new()))
	assert_eq(tree.level(&"skill_q"), 0)


func test_reset_costs_5_purple_and_refunds_blue_and_orange() -> void:
	essences.set_amount(Essences.PURPLE, 5)
	for i in 4:
		tree.buy(&"stat_ad", essences)  # 50 + 100 + 200 + 350 blue, 3 orange
	var blue_before := essences.amount(Essences.BLUE)
	assert_eq(tree.spent(), Vector2i(700, 3))
	assert_true(tree.reset(essences))
	assert_eq(essences.amount(Essences.BLUE), blue_before + 700)
	assert_eq(essences.amount(Essences.ORANGE), 1000)
	assert_eq(essences.amount(Essences.PURPLE), 0)
	assert_eq(tree.level(&"stat_ad"), 0)


func test_reset_refused_without_purple_or_purchases() -> void:
	essences.set_amount(Essences.PURPLE, 5)
	assert_false(tree.can_reset(essences))
	assert_false(tree.reset(essences))
	tree.buy(&"stat_ad", essences)
	essences.set_amount(Essences.PURPLE, 4)
	assert_true(tree.has_bought())
	assert_false(tree.reset(essences))
	assert_eq(tree.level(&"stat_ad"), 1)


func test_value_text() -> void:
	assert_eq(tree.node(&"stat_ad").value_text(0), "None")
	assert_eq(tree.node(&"stat_ad").value_text(2), "+8 AD")
	assert_eq(tree.node(&"stat_attack_speed").value_text(1), "+3% Attack Speed")
	assert_eq(tree.node(&"equip_slots").value_text(0), "1 equip slots")
	assert_eq(tree.node(&"refresh_cost").value_text(2), "Refresh: 50 gold")
	assert_eq(tree.node(&"flash_upgrade").value_text(1), "-10% cooldown")


func test_value_reads_the_current_level() -> void:
	tree.buy(&"stat_hp", essences)
	tree.buy(&"stat_hp", essences)
	assert_eq(tree.value(&"stat_hp"), 80.0)


func test_from_dict_drops_unknown_ids_and_clamps_levels() -> void:
	tree.from_dict({"skill_q": 9.0, "nope": 1, "skill_r": -2})
	assert_eq(tree.level(&"skill_q"), 5)
	assert_eq(tree.to_dict(), {"skill_q": 5})


func test_max_all_and_clear() -> void:
	tree.max_all()
	assert_true(tree.is_maxed(&"skill_r"))
	tree.clear()
	assert_false(tree.has_bought())


func test_changed_emits_on_buy() -> void:
	watch_signals(tree)
	tree.buy(&"flash", essences)
	assert_signal_emit_count(tree, "changed", 1)
