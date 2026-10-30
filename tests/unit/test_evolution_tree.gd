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


func test_r_needs_the_passive_and_5_levels_in_q_w_e() -> void:
	tree.acts_cleared = 1
	tree.from_dict({"skill_q": 4, "skill_e": 1})
	assert_false(tree.is_open(&"skill_r"), "no passive yet")
	tree.from_dict({"skill_q": 4, "skill_e": 1, "passive": 1})
	assert_true(tree.is_open(&"skill_r"), "Q4 W0 E1 is 5")
	tree.from_dict({"skill_q": 3, "skill_e": 1, "passive": 1})
	assert_false(tree.is_open(&"skill_r"), "4 is too few")
	tree.from_dict({"skill_q": 5, "passive": 1})
	assert_true(tree.is_open(&"skill_r"), "W and E need not be bought")


func test_r_rank_2_needs_9_and_rank_3_needs_13() -> void:
	tree.acts_cleared = 1
	tree.from_dict({"skill_q": 4, "skill_e": 1, "passive": 1, "skill_r": 1})
	assert_false(tree.next_level_open(&"skill_r"))
	tree.from_dict({"skill_q": 4, "skill_w": 3, "skill_e": 2, "passive": 1, "skill_r": 1})
	assert_true(tree.next_level_open(&"skill_r"), "9")
	tree.from_dict({"skill_q": 4, "skill_w": 3, "skill_e": 2, "passive": 1, "skill_r": 2})
	assert_false(tree.next_level_open(&"skill_r"), "9 is not 13")
	tree.from_dict({"skill_q": 5, "skill_w": 4, "skill_e": 4, "passive": 1, "skill_r": 2})
	assert_true(tree.next_level_open(&"skill_r"), "13")


func test_old_save_keeps_r_at_3_with_the_next_level_closed() -> void:
	tree.from_dict({"skill_r": 3, "skill_q": 1})
	assert_eq(tree.level(&"skill_r"), 3)
	assert_true(tree.is_maxed(&"skill_r"))
	tree.from_dict({"skill_r": 2, "skill_q": 1})
	assert_eq(tree.level(&"skill_r"), 2)
	assert_false(tree.next_level_open(&"skill_r"))
	assert_false(tree.can_buy(&"skill_r", essences))


func test_r_panel_texts() -> void:
	assert_eq(tree.next_requirement_text(&"skill_r"),
		"Requires: Passive – Lightslinger and 5 levels in Q + W + E (now 0)")
	tree.acts_cleared = 1
	tree.from_dict({"skill_q": 4, "skill_w": 2, "skill_e": 1, "passive": 1, "skill_r": 1})
	assert_eq(tree.next_requirement_text(&"skill_r"), "Requires: 9 levels in Q + W + E (now 7)")


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


func _data() -> TreeNodeData:
	var data := TreeNodeData.new()
	data.display_name = "Q – Piercing Light"
	data.max_level = 3
	data.level_values = [0.0, 5.0, 12.0, 20.0]
	data.level_acts = [0, 2]
	data.level_sums = [5, 9]
	return data


func test_level_values_replace_base_and_per_level() -> void:
	var data := _data()
	data.base = 99.0
	assert_eq(data.value(2), 12.0)
	assert_eq(data.value(0), 0.0)
	assert_eq(data.value_text(0), "None", "None is decided by the value at level 0")
	data.format = "{v} cells"
	assert_eq(data.value_text(3), "20 cells")


func test_value_text_is_none_only_when_level_0_is_zero() -> void:
	var data := TreeNodeData.new()
	data.per_level = 1.0
	data.format = "Rank {v}"
	assert_eq(data.value_text(0), "None")
	data.base = 1.0
	data.format = "{v} slots"
	assert_eq(data.value_text(0), "1 slots")


func test_act_needed_and_sum_needed_are_0_past_the_end() -> void:
	var data := _data()
	assert_eq(data.act_needed(1), 2)
	assert_eq(data.act_needed(2), 0)
	assert_eq(data.sum_needed(1), 9)
	assert_eq(data.sum_needed(5), 0)
	assert_eq(TreeNodeData.new().act_needed(0), 0)


func test_short_name_is_the_part_before_the_dash() -> void:
	assert_eq(_data().short_name(), "Q")
	var plain := TreeNodeData.new()
	plain.display_name = "Flash"
	assert_eq(plain.short_name(), "Flash")


func test_level_rules_are_checked_per_level() -> void:
	tree.acts_cleared = 1
	assert_true(tree.is_level_open(&"skill_q", 0))
	assert_true(tree.next_level_open(&"skill_q"))
	tree.max_all()
	assert_false(tree.next_level_open(&"skill_q"), "maxed")
	assert_eq(tree.next_requirement_text(&"skill_q"), "")


func test_requirement_text_names_only_what_is_missing() -> void:
	assert_eq(tree.requirement_text(&"skill_e", 0), "Requires: Clear Act 1")
	assert_eq(tree.next_requirement_text(&"skill_e"), "Requires: Clear Act 1")
	tree.acts_cleared = 1
	assert_eq(tree.next_requirement_text(&"skill_e"), "")
	assert_eq(tree.requirement_text(&"skill_e", 0), "")


func test_free_upgrades_are_open_and_cost_nothing() -> void:
	assert_false(tree.is_free(&"skill_e"), "closed before Act 1")
	assert_eq(tree.free_ids(), [])
	assert_false(tree.has_free())
	tree.acts_cleared = 1
	assert_true(tree.is_free(&"skill_e"))
	assert_eq(tree.free_ids(), [&"skill_e"] as Array[StringName])
	assert_true(tree.has_free(&"skills"))
	assert_false(tree.has_free(&"stats"))
	assert_false(tree.is_free(&"skill_q"), "open but not free")
	tree.buy(&"skill_e", essences)
	assert_false(tree.is_free(&"skill_e"), "the next rank costs")


func test_equip_slot_2_has_no_act_slot_3_needs_act_2_and_slot_5_act_4() -> void:
	tree.acts_cleared = 1
	assert_true(tree.buy(&"equip_slots", essences), "slot 2")
	assert_false(tree.buy(&"equip_slots", essences), "slot 3 needs Act 2")
	assert_eq(tree.next_requirement_text(&"equip_slots"), "Requires: Clear Act 2")
	tree.acts_cleared = 2
	assert_true(tree.buy(&"equip_slots", essences), "slot 3")
	assert_true(tree.buy(&"equip_slots", essences), "slot 4")
	assert_false(tree.buy(&"equip_slots", essences), "slot 5 needs Act 4")
	assert_eq(tree.next_requirement_text(&"equip_slots"), "Requires: Clear Act 4")
	tree.acts_cleared = 3
	assert_false(tree.next_level_open(&"equip_slots"))
	tree.acts_cleared = 4
	assert_true(tree.buy(&"equip_slots", essences), "slot 5")
	assert_true(tree.buy(&"equip_slots", essences), "slot 6")
	assert_true(tree.is_maxed(&"equip_slots"))


func test_every_node_is_in_a_listed_branch() -> void:
	var total := 0
	for branch in EvolutionTree.BRANCHES:
		assert_false(tree.branch_nodes(branch).is_empty(), str(branch))
		total += tree.branch_nodes(branch).size()
	assert_eq(total, tree.nodes().size())
	assert_has(tree.branch_nodes(&"backpack").map(func(d: TreeNodeData) -> StringName: return d.id), &"equip_slots")
