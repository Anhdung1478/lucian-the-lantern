extends SceneTree
## Visual check harness. Loads the stage, drives Lucian by calling his commands
## directly, and saves viewport screenshots. Needs a real window (not --headless).
## Usage: godot --path . -s res://tests/tools/screenshot.gd -- <scenario> <output_dir>

var stage: Node
var lucian: Lucian
var out_dir := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scenario: String = args[0] if args.size() > 0 else "move"
	out_dir = args[1] if args.size() > 1 else OS.get_user_data_dir()
	stage = load("res://src/stage/stage.tscn").instantiate()
	root.add_child(stage)
	# The stage confines the mouse; give it back during automated runs.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	lucian = stage.get_node("World/Lucian")
	(stage.get_node("StageCamera") as StageCamera).mode = StageCamera.Mode.FOLLOW
	_run.call_deferred(scenario)


func _run(scenario: String) -> void:
	await wait(0.3)
	match scenario:
		"move":
			await scenario_move()
		"dummy":
			await scenario_dummy()
		"attack":
			await scenario_attack()
		"debug":
			await scenario_debug()
		"skills":
			await scenario_skills()
		"q":
			await scenario_q()
		"e":
			await scenario_e()
		"w":
			await scenario_w()
		"r":
			await scenario_r()
		"combo":
			await scenario_combo()
		"hud":
			await scenario_hud()
		"menu":
			await scenario_menu()
		"tooltip":
			await scenario_tooltip()
		"backpack":
			await scenario_backpack()
		"craft":
			await scenario_craft()
		"hud_items":
			await scenario_hud_items()
		"icons":
			await scenario_icons()
		"gold":
			await scenario_gold()
		"potions":
			await scenario_potions()
		"shop":
			await scenario_shop()
		_:
			push_error("Unknown scenario: " + scenario)
	quit()


func shot(file_name: String) -> void:
	# Let every node process once more so the HUD shows the latest values.
	await process_frame
	await RenderingServer.frame_post_draw
	var path := out_dir.path_join(file_name + ".png")
	root.get_texture().get_image().save_png(path)
	print("saved ", path)


func wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func scenario_move() -> void:
	await shot("move_0_start")
	lucian.command_move(lucian.global_position + Vector2(500, -250))
	await wait(1.0)
	await shot("move_1_after")
	# Walk into the left wall: Lucian must stop at it.
	lucian.command_move(Vector2(-500, lucian.global_position.y))
	await wait(6.0)
	print("x after walking into the wall: ", lucian.global_position.x)
	await shot("move_2_wall")


func scenario_dummy() -> void:
	var dummy: TrainingDummy = stage.get_node("World/TrainingDummy")
	var camera: StageCamera = stage.get_node("StageCamera")
	lucian.visuals.face(dummy.global_position - lucian.global_position)
	camera.zoom = Vector2(2.2, 2.2)
	camera.mode = StageCamera.Mode.FREE
	camera.global_position = (lucian.global_position + dummy.global_position) * 0.5
	await wait(0.2)
	var Type := DamageInfo.Type
	print("physical 100 vs 30 armor -> ", dummy.take_damage(DamageInfo.create(100, Type.PHYSICAL, &"test")))
	await wait(0.12)
	dummy.take_damage(DamageInfo.create(100, Type.MAGIC, &"test"))
	await wait(0.12)
	dummy.take_damage(DamageInfo.create(100, Type.TRUE, &"test"))
	await wait(0.12)
	dummy.take_damage(DamageInfo.create(175, Type.PHYSICAL, &"test", null, true))
	dummy.add_mark(&"ardent_blaze", 6.0)
	await wait(0.15)
	await shot("dummy_0_hits")
	print("hp after hits: ", dummy.hp)
	await wait(4.5)
	print("hp after 4.5 s idle: ", dummy.hp)


func scenario_attack() -> void:
	var dummy: TrainingDummy = stage.get_node("World/TrainingDummy")
	var hits: Array[DamageInfo] = []
	dummy.damage_taken.connect(func(info: DamageInfo, _final: float) -> void: hits.append(info))
	lucian.cheat_crit_chance = 0.5
	lucian.command_attack(dummy)
	for i in 6:
		await wait(0.12)
		await shot("attack_%d" % i)
	await wait(3.5)
	print("hits after ~4.2 s of attacking: ", hits.size(), " crits: ", hits.filter(func(h: DamageInfo) -> bool: return h.is_crit).size())
	print("distance to dummy while attacking: ", lucian.global_position.distance_to(dummy.global_position))

	# A move during the windup cancels the shot.
	lucian.command_move(Vector2(1000, 1350))
	await wait(3.0)
	hits.clear()
	lucian.command_attack(dummy)
	await wait(0.05)
	lucian.command_move(lucian.global_position + Vector2(0, -50))
	await wait(1.0)
	print("hits after attack then instant move away (expect 0): ", hits.size())

	# Attack-move toward a point past the dummy stops in range and attacks.
	lucian.command_attack_move(Vector2(3400, 1350))
	lucian.set_range_ring_visible(true)
	await wait(3.0)
	print("attack-move: x=", snappedf(lucian.global_position.x, 1), " hits=", hits.size())
	await shot("attack_move")


func scenario_hud() -> void:
	lucian.progress.add_xp(280 + 380 + 200)
	lucian.hp -= 250.0
	lucian.mana -= 120.0
	await wait(0.2)
	print("level ", lucian.progress.level, " hp ", roundi(lucian.hp), "/", roundi(lucian.stats.max_hp))
	await shot("hud_0")


func press_key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame


func scenario_debug() -> void:
	var table: DebugTable = stage.get_node("DebugTable")
	var dummy: TrainingDummy = stage.get_node("World/TrainingDummy")
	print("table visible at start (expect false): ", table.visible)
	await press_key(KEY_F3, true)
	await press_key(KEY_Q, true)
	await press_key(KEY_Q, false)
	await press_key(KEY_F3, false)
	print("table visible after F3+Q (expect true): ", table.visible)
	await press_key(KEY_Q, true)
	await press_key(KEY_Q, false)
	print("table visible after Q alone (expect true): ", table.visible)
	lucian.progress.add_xp(500)
	lucian.cheat_crit_chance = 0.5
	lucian.command_attack(dummy)
	await wait(5.0)
	await shot("debug_0")


func scenario_skills() -> void:
	var Slot := ChampionProgress.Slot
	lucian.progress.set_level(7)
	lucian.try_rank_up(Slot.Q)
	lucian.try_rank_up(Slot.Q)
	lucian.try_rank_up(Slot.W)
	lucian.try_rank_up(Slot.E)
	lucian.try_rank_up(Slot.R)
	lucian.try_cast(Slot.Q, lucian.global_position + Vector2.RIGHT * 300)
	await wait(2.0)
	lucian.try_cast(Slot.W, lucian.global_position + Vector2.RIGHT * 300)
	await wait(0.4)
	lucian.mana = 60.0
	print("points left: ", lucian.progress.skill_points(), " can rank Q: ", lucian.progress.can_rank_up(Slot.Q))
	await shot("skills_0")


func scenario_q() -> void:
	var dummy: TrainingDummy = stage.get_node("World/TrainingDummy")
	lucian.progress.set_level(9)
	for i in 5:
		lucian.try_rank_up(ChampionProgress.Slot.Q)
	lucian.try_cast(ChampionProgress.Slot.Q, dummy.global_position)
	await wait(0.31)
	await shot("q_0_beam")


func scenario_e() -> void:
	(stage.get_node("StageCamera") as StageCamera).mode = StageCamera.Mode.FREE
	lucian.try_rank_up(ChampionProgress.Slot.E)
	lucian.try_cast(ChampionProgress.Slot.E, lucian.global_position + Vector2(400, -200))
	await wait(0.4)
	await shot("e_0_trail")


func scenario_w() -> void:
	var dummy: TrainingDummy = stage.get_node("World/TrainingDummy")
	lucian.try_rank_up(ChampionProgress.Slot.W)
	lucian.try_cast(ChampionProgress.Slot.W, dummy.global_position)
	await wait(0.42)
	await shot("w_0_missile")
	await wait(0.17)
	await shot("w_1_cross")
	await wait(0.06)
	await shot("w_2_cross")


func scenario_r() -> void:
	var dummy: TrainingDummy = stage.get_node("World/TrainingDummy")
	lucian.progress.set_level(6)
	lucian.try_rank_up(ChampionProgress.Slot.R)
	lucian.try_cast(ChampionProgress.Slot.R, dummy.global_position)
	lucian.command_move(lucian.global_position + Vector2(0, -400))
	await wait(1.0)
	await shot("r_0_stream")


func scenario_combo() -> void:
	var Slot := ChampionProgress.Slot
	var dummy: TrainingDummy = stage.get_node("World/TrainingDummy")
	(stage.get_node("DebugTable") as DebugTable).visible = true
	lucian.progress.set_level(16)
	for slot in [Slot.Q, Slot.W, Slot.E]:
		for i in 4:
			lucian.try_rank_up(slot)
	for i in 3:
		lucian.try_rank_up(Slot.R)
	lucian.cheat_crit_chance = 0.3
	lucian.try_cast(Slot.Q, dummy.global_position)
	lucian.command_attack(dummy)
	await wait(1.2)
	lucian.try_cast(Slot.E, lucian.global_position + Vector2(0, 300))
	await wait(0.5)
	lucian.try_cast(Slot.W, dummy.global_position)
	await wait(1.0)
	lucian.try_cast(Slot.R, dummy.global_position)
	await wait(1.2)
	await shot("combo_0")
	await wait(2.5)
	await shot("combo_1")


func scenario_menu() -> void:
	lucian.command_move(lucian.global_position + Vector2(600, 0))
	await wait(0.3)
	await press_key(KEY_ESCAPE, true)
	await press_key(KEY_ESCAPE, false)
	var x := lucian.global_position.x
	await wait(0.5)
	print("paused after ESC (expect true): ", paused, "  Lucian frozen (expect true): ", is_equal_approx(x, lucian.global_position.x))
	await shot("menu_0")
	await press_key(KEY_ESCAPE, true)
	await press_key(KEY_ESCAPE, false)
	await wait(0.3)
	print("paused after 2nd ESC (expect false): ", paused, "  Lucian moving (expect true): ", lucian.global_position.x > x)


## Moves the mouse to `canvas_pos` (1920x1080 canvas units), as if the player
## did it. `held` keeps the left button down during the motion. The OS cursor
## is warped there too, so its own motion events agree with ours.
func mouse_move(canvas_pos: Vector2, held := false) -> void:
	var window_pos := root.get_final_transform() * canvas_pos
	Input.warp_mouse(window_pos)
	var event := InputEventMouseMotion.new()
	event.position = window_pos
	event.global_position = window_pos
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	Input.parse_input_event(event)
	await process_frame


func mouse_button(canvas_pos: Vector2, pressed: bool) -> void:
	var window_pos := root.get_final_transform() * canvas_pos
	Input.warp_mouse(window_pos)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = window_pos
	event.global_position = window_pos
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(event)
	await process_frame


func control_center(control: Control) -> Vector2:
	return control.get_global_rect().get_center()


func scenario_tooltip() -> void:
	lucian.progress.set_level(3)
	lucian.try_rank_up(ChampionProgress.Slot.Q)
	lucian.try_rank_up(ChampionProgress.Slot.Q)
	var skill_row: HBoxContainer = stage.get_node("Hud").skill_row
	await mouse_move(control_center(skill_row.get_child(1)))
	await wait(0.5)
	await mouse_move(control_center(skill_row.get_child(1)) + Vector2(5, 3))
	await wait_for_tooltip(skill_row.get_child(1))
	await shot("tooltip_0_q")
	await mouse_move(control_center(skill_row.get_child(0)))
	await wait_for_tooltip(skill_row.get_child(0))
	await shot("tooltip_1_passive")
	await mouse_move(Vector2(960, 300))
	await wait(0.2)
	print("hidden after leaving (expect false): ", stage.get_node("HoverTip").is_showing())
	await press_key(KEY_ESCAPE, true)
	await press_key(KEY_ESCAPE, false)
	var menu: GameMenu = stage.get_node("Screens/Menu")
	var settings: Button = menu.find_children("*", "Button", true, false)[1]
	await mouse_move(control_center(settings))
	await wait_for_tooltip(settings)
	await shot("tooltip_2_disabled_button")


func give(ids: Array[StringName]) -> void:
	for id in ids:
		lucian.inventory.add(lucian.item_catalog.find(id))


func scenario_backpack() -> void:
	give([&"bf_sword", &"bf_sword", &"recurve_bow", &"needlessly_large_rod", &"cloak_of_agility",
		&"giants_belt", &"tear_of_the_goddess", &"negatron_cloak", &"chain_vest", &"infinity_edge",
		&"kraken_slayer", &"guardian_angel"])
	var inventory := lucian.inventory
	inventory.apply_drop(9, Inventory.EQUIP_START, false)
	inventory.apply_drop(10, Inventory.EQUIP_START + 1, false)
	inventory.unlocked_equip = 4
	(stage.get_node("DebugTable") as DebugTable).visible = true
	await press_key(KEY_P, true)
	await press_key(KEY_P, false)
	print("paused with backpack (expect true): ", paused)
	await wait(0.3)
	await shot("backpack_0")
	var backpack: BackpackScreen = stage.get_node("Screens/Backpack")
	await mouse_move(backpack._cells[0].get_global_rect().get_center())
	await wait_for_tooltip(backpack._cells[0])
	await shot("backpack_1_item_tooltip")
	await press_key(KEY_ESCAPE, true)
	await press_key(KEY_ESCAPE, false)
	print("ESC closes backpack, not menu (expect false false): ", backpack.visible, " ", (stage.get_node("Screens/Menu") as GameMenu).visible)


## Waits for the hover card of `source`, printing how long that took. A
## stray OS motion event can move the hover off `source`; then it is hovered
## again, and the retry is counted.
func wait_for_tooltip(source: Control, timeout := 4.0) -> void:
	var tip: HoverTip = stage.get_node("HoverTip")
	var start := Time.get_ticks_msec()
	var since := start
	var retries := 0
	while not (tip.is_showing() and tip._source == source) and Time.get_ticks_msec() - start < timeout * 1000.0:
		if HoverTip._find_source(root.gui_get_hovered_control()) != source:
			retries += 1
			since = Time.get_ticks_msec()
			await mouse_move(control_center(source))
		await process_frame
	print("tooltip for %s shown: " % source.get_class(), tip.is_showing() and tip._source == source,
		" after %.2f s of resting, %d re-hovers" % [(Time.get_ticks_msec() - since) / 1000.0, retries])
	await wait(0.1)


func scenario_craft() -> void:
	give([&"bf_sword", &"needlessly_large_rod", &"bf_sword", &"giants_belt"])
	await press_key(KEY_P, true)
	await press_key(KEY_P, false)
	await wait(0.3)
	var backpack: BackpackScreen = stage.get_node("Screens/Backpack")
	var inventory := lucian.inventory
	var cell := func(index: int) -> Vector2: return backpack._cells[index].get_global_rect().get_center()
	# Pick up the sword at 0, carry it over the rod at 1 and hold.
	await mouse_move(cell.call(0))
	await mouse_button(cell.call(0), true)
	for step in 6:
		await mouse_move(lerp(cell.call(0), cell.call(1), (step + 1) / 6.0), true)
	await wait(0.5)
	print("popup visible (expect true): ", backpack._craft_popup.visible, "  progress ~0.5: %.2f" % backpack._craft_popup.progress)
	await shot("craft_0_half")
	await wait(0.6)
	await shot("craft_1_full")
	await mouse_button(cell.call(1), false)
	await wait(0.1)
	print("crafted (expect hextech_gunblade, empty): ", inventory.item_at(1).id, ", ", inventory.item_at(0))
	await shot("craft_2_done")
	# Early release swaps: sword at 2 onto the belt at 3 is no recipe, so try
	# the gunblade's partner-free swap with a quick drop instead.
	await mouse_move(cell.call(2))
	await mouse_button(cell.call(2), true)
	await mouse_move(cell.call(3), true)
	await wait(0.3)
	await mouse_button(cell.call(3), false)
	print("swapped (expect giants_belt, bf_sword): ", inventory.item_at(2).id, ", ", inventory.item_at(3).id)
	# Equip the gunblade into slot 1, then drop the belt outside the backpack.
	var ad := lucian.stats.ad
	await mouse_move(cell.call(1))
	await mouse_button(cell.call(1), true)
	await mouse_move(cell.call(Inventory.EQUIP_START), true)
	await mouse_button(cell.call(Inventory.EQUIP_START), false)
	print("equipped (expect hextech_gunblade, AD +40): ", inventory.item_at(Inventory.EQUIP_START).id, ", +", lucian.stats.ad - ad)
	await mouse_move(cell.call(2))
	await mouse_button(cell.call(2), true)
	await mouse_move(Vector2(1700, 1000), true)
	await mouse_button(Vector2(1700, 1000), false)
	print("dropped outside, still there (expect giants_belt): ", inventory.item_at(2).id)
	await wait(0.2)
	await shot("craft_3_equipped")


func scenario_hud_items() -> void:
	give([&"infinity_edge", &"kraken_slayer", &"bf_sword", &"guardian_angel"])
	var inventory := lucian.inventory
	inventory.apply_drop(0, Inventory.EQUIP_START, false)
	inventory.apply_drop(1, Inventory.EQUIP_START + 1, false)
	inventory.apply_drop(2, Inventory.EQUIP_START + 3, false)
	await wait(0.2)
	await shot("hud_items_0")
	var grid: GridContainer = stage.get_node("Hud").item_grid
	await mouse_move(control_center(grid.get_child(1)))
	await wait_for_tooltip(grid.get_child(1))
	await shot("hud_items_1_tooltip")
	inventory.unlocked_equip = 4
	await mouse_move(Vector2(960, 300))
	await wait(0.2)
	print("visible HUD slots with 4 unlocked (expect 4): ", grid.get_children().filter(func(c: Control) -> bool: return c.visible).size())
	await shot("hud_items_2_four_slots")


## Every item icon at 64 px with its name, plus a row at HUD (40 px) and
## recipe table (36 px) sizes, on a sheet that covers the stage.
func scenario_icons() -> void:
	var sheet := CanvasLayer.new()
	sheet.layer = 200
	root.add_child(sheet)
	var background := ColorRect.new()
	background.color = Color("0b0d12")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	sheet.add_child(background)
	var grid := GridContainer.new()
	grid.columns = 9
	grid.position = Vector2(24, 20)
	grid.add_theme_constant_override(&"h_separation", 18)
	grid.add_theme_constant_override(&"v_separation", 10)
	sheet.add_child(grid)
	var items := lucian.item_catalog.items
	for item in items:
		var box := VBoxContainer.new()
		box.custom_minimum_size.x = 190
		var icon := ItemIcon.new(item)
		icon.custom_minimum_size = Vector2(64, 64)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(icon)
		var label := Label.new()
		label.text = item.display_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override(&"font_size", 14)
		box.add_child(label)
		grid.add_child(box)
	var small := HBoxContainer.new()
	small.position = Vector2(24, 1000)
	small.add_theme_constant_override(&"separation", 4)
	sheet.add_child(small)
	for item in items:
		var icon := ItemIcon.new(item)
		icon.custom_minimum_size = Vector2(40, 40) if item.is_fragment() else Vector2(36, 36)
		small.add_child(icon)
	print("items with icons: ", items.filter(func(item: ItemData) -> bool: return item.icon != null).size(), " / ", items.size())
	await wait(0.3)
	await shot("icons_0_sheet")


func scenario_gold() -> void:
	var table: DebugTable = stage.get_node("DebugTable")
	table.visible = true
	(stage as Stage).wallet.add(1250)
	var tabs: TabContainer = table.find_children("*", "TabContainer", true, false)[0]
	tabs.current_tab = 2
	await wait(0.2)
	print("gold (expect 1250): ", (stage as Stage).wallet.gold)
	await shot("gold_0")


func mouse_right_click(canvas_pos: Vector2) -> void:
	var window_pos := root.get_final_transform() * canvas_pos
	Input.warp_mouse(window_pos)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_RIGHT
		event.pressed = pressed
		event.position = window_pos
		event.global_position = window_pos
		event.button_mask = MOUSE_BUTTON_MASK_RIGHT if pressed else 0
		Input.parse_input_event(event)
		await process_frame


func scenario_potions() -> void:
	var inventory := lucian.inventory
	inventory.add(lucian.item_catalog.find(&"hp_potion"), 12)
	inventory.add(lucian.item_catalog.find(&"mp_potion"), 4)
	inventory.put(Inventory.EQUIP_START, lucian.item_catalog.find(&"hp_potion"))
	inventory.put(Inventory.EQUIP_START, lucian.item_catalog.find(&"hp_potion"))
	lucian.hp = 150.0
	lucian.mana = 40.0
	await press_key(KEY_P, true)
	await press_key(KEY_P, false)
	await wait(0.3)
	var backpack: BackpackScreen = stage.get_node("Screens/Backpack")
	await mouse_right_click(control_center(backpack._cells[2]))
	await wait(0.1)
	print("use offered for cell (expect 2): ", backpack.use_index())
	await shot("potions_0_use")
	await mouse_move(control_center(backpack._use_button))
	await mouse_button(control_center(backpack._use_button), true)
	await mouse_button(control_center(backpack._use_button), false)
	print("mana potions left (expect 3): ", inventory.count_at(2))
	var mana := lucian.mana
	await wait(0.5)
	print("no mana while paused (expect true): ", is_equal_approx(mana, lucian.mana))
	await press_key(KEY_P, true)
	await press_key(KEY_P, false)
	await press_key(KEY_1, true)
	await press_key(KEY_1, false)
	print("slot 1 potions left (expect 1): ", inventory.count_at(Inventory.EQUIP_START))
	await wait(2.0)
	print("hp after 2 s (expect ~230+): ", roundi(lucian.hp), "  mana (expect ~100+): ", roundi(lucian.mana))
	await shot("potions_1_drinking")


func world_to_canvas(world_pos: Vector2) -> Vector2:
	return root.get_canvas_transform() * world_pos


func scenario_shop() -> void:
	var game := stage as Stage
	var inventory := lucian.inventory
	game.wallet.add(4000)
	game.set_shop_slots(3)
	inventory.add(lucian.item_catalog.find(&"bf_sword"))
	inventory.add(lucian.item_catalog.find(&"guardian_angel"))
	inventory.add(lucian.item_catalog.find(&"hp_potion"), 3)
	await wait(0.2)
	await mouse_move(world_to_canvas(game.merchant.global_position))
	await wait(0.2)
	await shot("shop_0_hover_merchant")
	await mouse_right_click(world_to_canvas(game.merchant.global_position))
	await wait(3.0)
	print("shop open after walking (expect true true): ", game.screens.is_shopping(), " ", paused)
	print("distance to merchant <= 250: ", roundi(lucian.global_position.distance_to(game.merchant.global_position)))
	var backpack := game.screens.backpack
	var panel := backpack.shop_panel()
	await wait(0.2)
	await shot("shop_1_items")
	await mouse_move(control_center(panel.slots(0)[0]))
	await wait_for_tooltip(panel.slots(0)[0])
	await shot("shop_2_tooltip")
	var bought := panel.slots(0)[0].item()
	await mouse_right_click(control_center(panel.slots(0)[0]))
	print("bought %s (gold now %d)" % [bought.display_name, game.wallet.gold])
	var gold := game.wallet.gold
	await mouse_move(control_center(panel._refresh))
	await mouse_button(control_center(panel._refresh), true)
	await mouse_button(control_center(panel._refresh), false)
	print("refresh cost (expect 100): ", gold - game.wallet.gold, "  slot 0 sold (expect true): ", game.merchant.stock.is_sold(0))
	# Drag the Guardian Angel onto the sell slot, shot while over it.
	var sell_cell: ItemCell = backpack._cells[backpack._cells.size() - 1]
	await mouse_move(control_center(backpack._cells[1]))
	await mouse_button(control_center(backpack._cells[1]), true)
	for step in 5:
		await mouse_move(lerp(control_center(backpack._cells[1]), control_center(sell_cell), (step + 1) / 5.0), true)
	await wait(0.1)
	print("sell preview (expect 1280): ", backpack.sell_preview())
	await shot("shop_3_sell_preview")
	await mouse_button(control_center(sell_cell), false)
	panel.show_tab(1)
	await wait(0.2)
	await mouse_move(Vector2(960, 1000))
	await shot("shop_4_potions")
	await press_key(KEY_ESCAPE, true)
	await press_key(KEY_ESCAPE, false)
	print("ESC closes the shop (expect false false): ", game.screens.is_shopping(), " ", paused)
