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
	assert_eq(StatsPanel.value_text(lucian, &"hp_regen"), TooltipText.number(snappedf(lucian.stats.hp_regen * 5.0, 0.1)))
	for key in StatsPanel.MAIN + StatsPanel.EXTRA:
		assert_ne(StatsPanel.value_text(lucian, key), "", str(key))


func test_panels_have_one_cell_per_stat() -> void:
	var extra := StatsPanel.new()
	extra.keys = StatsPanel.EXTRA
	add_child_autofree(extra)
	var grid := extra.get_child(0)
	assert_eq(grid.get_child_count(), 9)
	assert_true(grid.get_child(0) is StatCell)


func test_stat_cards_build() -> void:
	for key in StatsPanel.MAIN + StatsPanel.EXTRA:
		var card := TooltipCard.stat(key, "1")
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
