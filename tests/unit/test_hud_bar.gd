extends GutTest
## HudBar: the HUD's health and mana bars and the boss bar's.


func _bar() -> HudBar:
	var bar := HudBar.new()
	add_child_autofree(bar)
	return bar


func test_a_loss_leaves_a_ghost_that_drains_in_ghost_time() -> void:
	var bar := _bar()
	bar.show_amount(600.0, 600.0)
	assert_eq(bar.ghost_amount(), 600.0, "no ghost on a bar that only filled")
	bar.show_amount(400.0, 600.0)
	assert_eq(bar.amount, 400.0)
	assert_eq(bar.ghost_amount(), 600.0, "the ghost stays where the health was")
	bar._process(HudBar.GHOST_TIME * 0.5)
	assert_almost_eq(bar.ghost_amount(), 500.0, 0.01, "half drained")
	bar._process(HudBar.GHOST_TIME * 0.5)
	assert_almost_eq(bar.ghost_amount(), 400.0, 0.01, "gone after GHOST_TIME")
	bar._process(1.0)
	assert_eq(bar.ghost_amount(), 400.0, "never under the amount")


func test_a_second_hit_grows_the_ghost_and_starts_its_time_again() -> void:
	var bar := _bar()
	bar.show_amount(600.0, 600.0)
	bar.show_amount(500.0, 600.0)
	bar._process(HudBar.GHOST_TIME * 0.5)
	assert_almost_eq(bar.ghost_amount(), 550.0, 0.01)
	bar.show_amount(300.0, 600.0)
	assert_almost_eq(bar.ghost_amount(), 550.0, 0.01, "the old chunk is kept")
	bar._process(HudBar.GHOST_TIME * 0.5)
	assert_almost_eq(bar.ghost_amount(), 425.0, 0.01, "the whole chunk drains in GHOST_TIME")
	bar._process(HudBar.GHOST_TIME * 0.5)
	assert_almost_eq(bar.ghost_amount(), 300.0, 0.01)


func test_a_heal_or_a_bigger_bar_leaves_no_ghost() -> void:
	var bar := _bar()
	bar.show_amount(300.0, 600.0)
	bar.show_amount(500.0, 600.0)
	assert_eq(bar.ghost_amount(), 500.0, "a heal")
	bar.show_amount(500.0, 900.0)
	assert_eq(bar.ghost_amount(), 500.0, "more max health, the same health")


func test_reset_shows_a_new_owner_with_no_ghost() -> void:
	var bar := _bar()
	bar.show_amount(9000.0, 9000.0, 50.0)
	bar.show_amount(100.0, 9000.0, 50.0)
	bar.reset(2000.0, 20000.0)
	assert_eq(bar.amount, 2000.0)
	assert_eq(bar.max_amount, 20000.0)
	assert_eq(bar.shield, 0.0)
	assert_eq(bar.ghost_amount(), 2000.0)


func test_drained_never_passes_the_amount() -> void:
	assert_eq(HudBar.drained(600.0, 400.0, 500.0, 0.1), 550.0)
	assert_eq(HudBar.drained(600.0, 400.0, 500.0, 5.0), 400.0)


func test_tick_marks_are_100_apart_and_coarser_on_a_crowded_bar() -> void:
	assert_eq(HudBar.tick_step(600.0, 420.0), 100.0, "Lucian at level 1")
	assert_eq(HudBar.tick_step(4000.0, 480.0), 100.0, "a late Lucian: 12 px apart")
	assert_eq(HudBar.tick_step(20000.0, 600.0), 1000.0, "Karthus: 100s would be 3 px apart")
	assert_eq(HudBar.tick_step(0.0, 600.0), 100.0, "an empty bar never loops")


func test_the_bar_never_takes_the_mouse() -> void:
	assert_eq(_bar().mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_the_hud_bars_follow_lucian() -> void:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	var hud: Hud = load("res://src/ui/hud/hud.tscn").instantiate()
	add_child_autofree(hud)
	hud.setup(lucian, Wallet.new())
	await wait_process_frames(2)
	var max_hp := lucian.stats.max_hp
	assert_eq(hud.hp_bar.amount, max_hp)
	assert_eq(hud.hp_bar.max_amount, max_hp)
	assert_true(hud.hp_bar.ticks, "health has tick marks")
	assert_false(hud.mana_bar.ticks, "mana has none")
	lucian.hp = max_hp - 200.0
	lucian.mana -= 50.0
	lucian.add_barrier(80.0, 5.0)
	hud._process(0.0)
	assert_eq(hud.hp_bar.amount, max_hp - 200.0)
	assert_eq(hud.hp_bar.ghost_amount(), max_hp, "the damage just taken")
	assert_eq(hud.hp_bar.shield, lucian.total_shield())
	assert_gt(hud.hp_bar.shield, 0.0)
	assert_eq(hud.hp_label.text, "%d / %d  (+%d)" % [roundi(lucian.hp), roundi(max_hp), roundi(lucian.total_shield())])
	assert_eq(hud.mana_bar.amount, lucian.mana)
	assert_eq(hud.mana_bar.ghost_amount(), lucian.stats.max_mana)
