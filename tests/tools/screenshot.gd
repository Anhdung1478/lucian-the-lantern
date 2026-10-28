extends SceneTree
## Visual check harness. Loads the stage, drives Lucian by calling his commands
## directly, and saves viewport screenshots. Needs a real window (not --headless).
## Usage: godot --path . -s res://tests/tools/screenshot.gd -- <scenario> <output_dir>

const SETTINGS_PATH := "user://screenshot_settings.json"

var stage: Node
var lucian: Lucian
var out_dir := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scenario: String = args[0] if args.size() > 0 else "move"
	out_dir = args[1] if args.size() > 1 else OS.get_user_data_dir()
	# A scratch settings file, so runs never touch the player's settings.
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	GameSettings._instance = GameSettings.new(SETTINGS_PATH)
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
		"settings":
			await scenario_settings()
		"buffs":
			await scenario_buffs()
		"actives":
			await scenario_actives()
		"energized":
			await scenario_energized()
		"skillbar":
			await scenario_skillbar()
		"stats":
			await scenario_stats()
		"rfc_ring":
			await scenario_rfc_ring()
		"summoners":
			await scenario_summoners()
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
	lucian.command_move(Vector2(1000, dummy.global_position.y))
	await wait(3.0)
	hits.clear()
	lucian.command_attack(dummy)
	await wait(0.05)
	lucian.command_move(lucian.global_position + Vector2(0, -50))
	await wait(1.0)
	print("hits after attack then instant move away (expect 0): ", hits.size())

	# Attack-move toward a point past the dummy stops in range and attacks.
	lucian.command_attack_move(Vector2(3400, dummy.global_position.y))
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
	var settings: Button = menu.find_children("*", "Button", true, false)[2]
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


func click(control: Control) -> void:
	await mouse_move(control_center(control))
	await mouse_button(control_center(control), true)
	await mouse_button(control_center(control), false)


func scenario_settings() -> void:
	await press_key(KEY_ESCAPE, true)
	await press_key(KEY_ESCAPE, false)
	var menu: GameMenu = stage.get_node("Screens/Menu")
	await click(menu.find_children("*", "Button", true, false)[1])
	var screen: SettingsScreen = stage.get_node("Screens/Settings")
	print("settings open and paused (expect true true): ", screen.visible, " ", paused)
	await wait(0.2)
	await shot("settings_0_audio")
	await click(screen._tab_buttons[1])
	await click(screen._bind_buttons[&"skill_q"])
	print("listening (expect true): ", screen.is_listening())
	await shot("settings_1_listening")
	await press_key(KEY_Z, true)
	await press_key(KEY_Z, false)
	var settings := GameSettings.instance()
	print("Q bound to (expect Z): ", settings.key_label(&"skill_q"))
	await click(screen._bind_buttons[&"skill_w"])
	await press_key(KEY_Z, true)
	await press_key(KEY_Z, false)
	print("W took Z, Q got W (expect Z W): ", settings.key_label(&"skill_w"), " ", settings.key_label(&"skill_q"))
	await wait(0.1)
	await shot("settings_2_controls")
	await click(screen._tab_buttons[2])
	await wait(0.1)
	await shot("settings_3_graphics")
	await click(screen._tab_buttons[3])
	await wait(0.1)
	await shot("settings_4_gameplay")
	await press_key(KEY_ESCAPE, true)
	await press_key(KEY_ESCAPE, false)
	print("ESC back to the menu (expect false true): ", screen.visible, " ", menu.visible)
	await press_key(KEY_ESCAPE, true)
	await press_key(KEY_ESCAPE, false)
	await wait(0.2)
	await shot("settings_5_hud_keys")
	var saved := GameSettings.new(SETTINGS_PATH)
	print("saved binding reloads (expect W): ", saved.key_label(&"skill_q"))


func equip_all(ids: Array[StringName]) -> void:
	for i in ids.size():
		lucian.inventory.put(Inventory.EQUIP_START + i, lucian.item_catalog.find(ids[i]))


func scenario_buffs() -> void:
	var game := stage as Stage
	var dummy: TrainingDummy = stage.get_node("World/TrainingDummy")
	game.set_dummy_count(3)
	equip_all([&"kraken_slayer", &"statikk_shiv", &"essence_reaver", &"black_cleaver", &"spear_of_shojin", &"hp_potion"])
	lucian.inventory.put(Inventory.EQUIP_START + 5, lucian.item_catalog.find(&"hp_potion"))
	lucian.progress.set_level(5)
	lucian.try_rank_up(ChampionProgress.Slot.Q)
	lucian.try_rank_up(ChampionProgress.Slot.W)
	lucian.hp = 500.0
	(stage.get_node("DebugTable") as DebugTable).visible = true
	var hits := {}
	for target in [dummy] + game.extra_dummies:
		target.damage_taken.connect(func(info: DamageInfo, _final: float) -> void:
			hits[info.source] = hits.get(info.source, 0) + 1)
	lucian.command_attack(dummy)
	await wait(1.0)
	lucian.try_cast(ChampionProgress.Slot.Q, dummy.global_position)
	await wait(1.5)
	lucian.use_equip_slot(5, Vector2.ZERO)
	lucian.passives.energize.value = 100.0
	await wait(1.2)
	print("hit sources: ", hits)
	print("carve stacks on the dummy: ", dummy.status_stacks(Enemy.CARVE), "  shojin stacks: ", lucian.passives.shojin_stacks)
	await shot("buffs_0_combat")
	var bar: BuffBar = stage.get_node("Hud")._buff_bar
	print("buff icons: ", bar.get_children().filter(func(c: Control) -> bool: return c.visible).map(func(c: BuffIcon) -> StringName: return c.buff.id))
	lucian.command_move(lucian.global_position)
	await wait(0.2)
	var first := bar.get_child(0) as Control
	await mouse_move(control_center(first))
	await wait_for_tooltip(first)
	await shot("buffs_1_tooltip")


func scenario_actives() -> void:
	var dummy: TrainingDummy = stage.get_node("World/TrainingDummy")
	equip_all([&"hextech_gunblade", &"galeforce", &"hextech_rocketbelt", &"malignance"])
	lucian.global_position = dummy.global_position + Vector2(-450, 150)
	await wait(0.2)
	print("gunblade (expect true): ", lucian.use_equip_slot(0, dummy.global_position))
	await wait(0.05)
	await shot("actives_0_gunblade")
	await wait(0.5)
	print("galeforce (expect true): ", lucian.use_equip_slot(1, dummy.global_position))
	await wait(0.3)
	await shot("actives_1_galeforce")
	await wait(0.6)
	print("rocketbelt (expect true): ", lucian.use_equip_slot(2, dummy.global_position + Vector2(0, -100)))
	await wait(0.15)
	await shot("actives_2_rocketbelt")
	lucian.progress.set_level(6)
	lucian.try_rank_up(ChampionProgress.Slot.R)
	lucian.try_cast(ChampionProgress.Slot.R, dummy.global_position)
	await wait(1.0)
	await shot("actives_3_hatefog")
	print("hatefog on the dummy (expect true): ", dummy.has_status(Enemy.HATEFOG), "  slow (expect true): ", dummy.has_status(Enemy.SLOW))


func scenario_energized() -> void:
	equip_all([&"rapid_firecannon", &"stormrazor"])
	lucian.command_move(lucian.global_position + Vector2(0, 400))
	await wait(1.0)
	var walked := lucian.passives.energize.value
	print("charge after 1 s walking (expect ~14): %.1f" % walked)
	lucian.try_rank_up(ChampionProgress.Slot.E)
	lucian.try_cast(ChampionProgress.Slot.E, lucian.global_position + Vector2(280, 0))
	await wait(0.4)
	print("charge gained from a 280 dash (expect ~23): %.1f" % (lucian.passives.energize.value - walked))
	await shot("energized_0_building")
	lucian.passives.energize.value = 100.0
	lucian.set_range_ring_visible(true)
	await wait(0.3)
	print("range with RFC ready (expect 675): ", roundi(lucian.attack_range()))
	await shot("energized_1_ready")


func scenario_skillbar() -> void:
	var Slot := ChampionProgress.Slot
	var dummy: TrainingDummy = stage.get_node("World/TrainingDummy")
	lucian.progress.set_level(2)
	lucian.try_rank_up(Slot.Q)
	lucian.progress.bought[Slot.W] = 0
	print("points (expect 1): ", lucian.progress.skill_points(), "  Q can rank (expect false): ", lucian.progress.can_rank_up(Slot.Q))
	await wait(0.1)
	await shot("skillbar_0_plus")
	lucian.progress.bought[Slot.W] = 5
	lucian.progress.set_level(6)
	for slot in [Slot.W, Slot.E, Slot.R]:
		lucian.try_rank_up(slot)
	lucian.try_cast(Slot.R, dummy.global_position)
	await wait(0.3)
	print("Q/W blocked during R (expect true true): ", lucian.is_skill_blocked(Slot.Q), " ", lucian.is_skill_blocked(Slot.W))
	await shot("skillbar_1_r_greys_qw")
	(lucian.skills[Slot.R] as TheCulling).stop()
	lucian.try_cast(Slot.Q, dummy.global_position)
	await wait(0.05)
	print("E blocked during Q (expect true): ", lucian.is_skill_blocked(Slot.E))
	await shot("skillbar_2_q_greys_e")


func scenario_stats() -> void:
	equip_all([&"infinity_edge", &"rabadons_deathcap", &"lord_dominiks_regards"])
	await wait(0.2)
	var hud: Hud = stage.get_node("Hud")
	print("main panel visible (expect true): ", hud.stats_panel.visible)
	await shot("stats_0_main")
	Input.action_press(&"toggle_stats")
	await wait(0.1)
	print("extra panel while held (expect true): ", hud.extra_stats.visible)
	await shot("stats_1_extra")
	Input.action_release(&"toggle_stats")
	var cell: Control = hud.stats_panel.get_child(0).get_child(0)
	await mouse_move(control_center(cell))
	await wait_for_tooltip(cell)
	await shot("stats_2_hover")
	var grid: GridContainer = hud.item_grid
	await mouse_move(control_center(grid.get_child(0)))
	await wait_for_tooltip(grid.get_child(0))
	await shot("stats_3_item_card")


func scenario_rfc_ring() -> void:
	var dummy: TrainingDummy = stage.get_node("World/TrainingDummy")
	equip_all([&"rapid_firecannon"])
	lucian.passives.energize.value = 100.0
	await wait(0.2)
	print("ring while Energized (expect true): ", lucian.passives.shows_rfc_ring())
	await shot("rfc_ring_0_ready")
	lucian.command_attack(dummy)
	await wait(1.5)
	print("ring after the shot lands (expect false): ", lucian.passives.shows_rfc_ring())
	await shot("rfc_ring_1_gone")


func scenario_summoners() -> void:
	var dummy: TrainingDummy = stage.get_node("World/TrainingDummy")
	var hud: Hud = stage.get_node("Hud")
	var table: DebugTable = stage.get_node("DebugTable")
	table.visible = true
	await wait(0.2)
	await shot("summoners_0_hud_and_picker")
	table.visible = false
	var start := lucian.global_position
	lucian.use_summoner(0, start + Vector2(600, -300))
	await wait(0.05)
	print("flash distance (expect 400): ", roundi(lucian.global_position.distance_to(start)))
	await shot("summoners_1_flash")
	lucian.summoners.set_spell(0, &"barrier")
	lucian.summoners.set_spell(1, &"ghost")
	lucian.use_summoner(0, Vector2.ZERO)
	lucian.use_summoner(1, Vector2.ZERO)
	await wait(0.3)
	print("shield (expect 113): ", roundi(lucian.total_shield()), "  ghosted (expect true): ", lucian.is_ghosted())
	await shot("summoners_2_barrier_ghost")
	lucian.summoners.set_spell(0, &"smite")
	lucian.summoners.set_spell(1, &"heal")
	lucian.blink_to(dummy.global_position + Vector2(-450, 0))
	lucian.hp = 300.0
	var before := dummy.hp
	lucian.use_summoner(0, dummy.global_position)
	print("smite damage (expect 450): ", roundi(before - dummy.hp), "  hp after smite (expect 360): ", roundi(lucian.hp))
	await wait(0.1)
	await shot("summoners_3_smite")
	lucian.use_summoner(1, Vector2.ZERO)
	lucian.summoners.set_spell(0, &"clarity")
	lucian.mana = 50.0
	lucian.use_summoner(0, Vector2.ZERO)
	print("hp after heal (expect 455): ", roundi(lucian.hp), "  mana after clarity (expect 210): ", roundi(lucian.mana))
	await wait(0.2)
	await shot("summoners_4_heal_clarity")
	var slot: Control = hud.skill_row.get_child(hud.skill_row.get_child_count() - 1)
	await mouse_move(control_center(slot))
	await wait_for_tooltip(slot)
	await shot("summoners_5_card")
