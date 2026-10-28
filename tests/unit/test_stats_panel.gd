extends GutTest
## The HUD stats panels: values, cells, hover cards and the stats key.

var lucian: Lucian


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)


func test_value_texts() -> void:
	lucian.cheat_crit_chance = 0.5
	assert_eq(StatsPanel.value_text(lucian, &"crit_chance"), "50%")
	assert_eq(StatsPanel.value_text(lucian, &"attack_speed"), "%.2f" % lucian.stats.attack_speed)
	assert_eq(StatsPanel.value_text(lucian, &"attack_range"), "500")
	assert_eq(StatsPanel.value_text(lucian, &"regen"), "%s / %s" % [
		TooltipText.number(snappedf(lucian.stats.hp_regen, 0.1)), TooltipText.number(snappedf(lucian.stats.mana_regen, 0.1))])
	for key in StatsPanel.MAIN + StatsPanel.EXTRA:
		assert_ne(StatsPanel.value_text(lucian, key), "", str(key))


func test_panels_have_one_cell_per_stat() -> void:
	var extra := StatsPanel.new()
	extra.keys = StatsPanel.EXTRA
	add_child_autofree(extra)
	var grid := extra.get_child(0)
	assert_eq(grid.get_child_count(), 8)
	assert_true(grid.get_child(0) is StatCell)


func test_stat_cards_build() -> void:
	for key in StatsPanel.MAIN + StatsPanel.EXTRA:
		var card := TooltipCard.stat(key, "1", StatsPanel.breakdown(lucian, key))
		assert_not_null(card, str(key))
		card.free()


func test_ctrl_key_toggles_and_holding_shows_extra() -> void:
	var hud: Hud = load("res://src/ui/hud/hud.tscn").instantiate()
	add_child_autofree(hud)
	hud.setup(lucian, Wallet.new())
	var press := InputEventKey.new()
	press.physical_keycode = KEY_C
	press.pressed = true
	press.ctrl_pressed = true
	hud._unhandled_input(press)
	assert_false(hud.stats_panel.visible)
	Input.action_press(&"toggle_stats")
	await wait_process_frames(2)
	assert_true(hud.extra_stats.visible)
	Input.action_release(&"toggle_stats")
	await wait_process_frames(2)
	assert_false(hud.extra_stats.visible)


func test_bars_show_regen_per_second() -> void:
	var hud: Hud = load("res://src/ui/hud/hud.tscn").instantiate()
	add_child_autofree(hud)
	hud.setup(lucian, Wallet.new())
	await wait_process_frames(2)
	assert_eq(hud.hp_regen_label.text, "+%s/s" % TooltipText.number(snappedf(lucian.stats.hp_regen, 0.1)))
	assert_eq(hud.mana_regen_label.text, "+%s/s" % TooltipText.number(snappedf(lucian.stats.mana_regen, 0.1)))


func equip(id: StringName) -> void:
	lucian.inventory.put(Inventory.EQUIP_START, lucian.item_catalog.find(id))


func test_bonus_is_what_differs_from_the_level_alone() -> void:
	assert_false(StatsPanel.has_bonus(lucian, &"ad"))
	assert_false(StatsPanel.has_bonus(lucian, &"regen"))
	assert_eq(TooltipText.plain(StatsPanel.breakdown(lucian, &"ad")), "60 base")
	equip(&"bf_sword")
	assert_true(StatsPanel.has_bonus(lucian, &"ad"))
	var bonus := roundi(lucian.stats.ad - 60.0)
	assert_eq(TooltipText.plain(StatsPanel.breakdown(lucian, &"ad")), "60 base + %d bonus" % bonus)
	assert_false(StatsPanel.has_bonus(lucian, &"ap"))


func test_buffs_and_cheats_count_as_bonus() -> void:
	lucian.add_speed_buff(&"ghost", 0.0, 0.4, 5.0)
	assert_true(StatsPanel.has_bonus(lucian, &"move_speed"))
	lucian.cheat_crit_chance = 0.5
	assert_eq(TooltipText.plain(StatsPanel.breakdown(lucian, &"crit_chance")), "0% base + 50% bonus")


func test_regen_breaks_down_health_and_mana() -> void:
	var text := TooltipText.plain(StatsPanel.breakdown(lucian, &"regen"))
	assert_string_contains(text, "Health %s base" % TooltipText.number(snappedf(lucian.stats.hp_regen, 0.1)))
	assert_string_contains(text, "Mana %s base" % TooltipText.number(snappedf(lucian.stats.mana_regen, 0.1)))


func test_a_stat_with_a_bonus_shows_in_yellow() -> void:
	var panel := StatsPanel.new()
	panel.lucian = lucian
	add_child_autofree(panel)
	equip(&"bf_sword")
	await wait_process_frames(2)
	var cells := panel.get_child(0).get_children()
	assert_eq((cells[0] as StatCell).key, &"ad")
	assert_eq((cells[0] as StatCell).value_color(), StatCell.BONUS_COLOR)
	assert_eq((cells[1] as StatCell).value_color(), StatCell.BASE_COLOR, "AP has no bonus")
