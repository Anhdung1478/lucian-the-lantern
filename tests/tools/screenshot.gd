extends SceneTree
## Visual check harness. Loads the stage (or, for the main screen scenarios,
## the whole game), drives it by calling its commands directly, and saves
## viewport screenshots. Needs a real window (not --headless).
## Usage: godot --path . -s res://tests/tools/screenshot.gd -- <scenario> <output_dir>

const SETTINGS_PATH := "user://screenshot_settings.json"
const SAVE_PREFIX := "user://screenshot_save_slot_"
## Scenarios that start from the game's root scene (the main screen).
const GAME_SCENARIOS := ["training_setup", "skins_stage", "title", "title_slots"]
## Scenarios played on a Journey stage: [act, stage], built from the new save
## (so Act 1 is its first play, the tutorial).
const ACT_SCENARIOS := {
	"act1_start": [1, 1], "act1_wave": [1, 1], "act1_shell": [1, 1], "act1_break": [1, 1],
	"act1_lesson": [1, 1], "act1_thresh": [1, 1], "act1_cutscene": [1, 1], "act1_result": [1, 1], "game_over": [1, 1],
	"act2_pillars": [2, 3], "act2_super": [2, 1], "akshan_e": [2, 3], "akshan_r": [2, 3],
	"defeat": [2, 1], "loot": [2, 2], "guardian_angel": [2, 2],
	"act3_jungle": [3, 2], "act3_water": [3, 4], "act3_pit": [3, 5],
	"infernal_meteor": [3, 2], "ocean_mist": [3, 4],
}

var stage: Node
var lucian: Lucian
## The Game root, for the main screen scenarios and the Training they start.
var game_root: Game
var out_dir := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scenario: String = args[0] if args.size() > 0 else "move"
	out_dir = args[1] if args.size() > 1 else OS.get_user_data_dir()
	# A scratch settings file, so runs never touch the player's settings.
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	GameSettings._instance = GameSettings.new(SETTINGS_PATH)
	# Scratch save slots too, so every run starts from a new game.
	var save := SaveGame.new(SAVE_PREFIX)
	for n in range(1, SaveGame.SLOTS + 1):
		for file in [save.path(n), save.backup_path(n)]:
			if FileAccess.file_exists(file):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	save.load_slot(1)
	SaveGame._instance = save
	if scenario == "art_sheet":
		# Art only: no stage, and no stretch, so a 32 px icon is 32 real pixels.
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
		_run.call_deferred(scenario)
		return
	if scenario.begins_with("main_") or scenario in GAME_SCENARIOS:
		game_root = load("res://src/main/game.tscn").instantiate()
		# "Save before leaving?" must never close the run.
		game_root.quit_game = func() -> void: print("quit_game called")
		root.add_child(game_root)
		_run.call_deferred(scenario)
		return
	stage = load("res://src/stage/stage.tscn").instantiate()
	if ACT_SCENARIOS.has(scenario):
		var where: Array = ACT_SCENARIOS[scenario]
		(stage as Stage).setup(StageSetup.for_stage(save, where[0], where[1]))
	root.add_child(stage)
	# The stage confines the mouse; give it back during automated runs.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	lucian = stage.get_node("World/Lucian")
	(stage.get_node("StageCamera") as StageCamera).mode = StageCamera.Mode.FOLLOW
	_run.call_deferred(scenario)


func _run(scenario: String) -> void:
	# The game opens on the title screen; these start on the main screen. Not
	# in _initialize: the game root isn't in the tree yet there.
	if game_root and not scenario.begins_with("title"):
		game_root.show_main_screen()
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
		"camera":
			await scenario_camera()
		"indicators":
			await scenario_indicators()
		"cast_modes":
			await scenario_cast_modes()
		"art_sheet":
			await scenario_art_sheet()
		"main_journey":
			await scenario_main_journey()
		"main_acts":
			await scenario_main_acts()
		"main_endless":
			await scenario_main_endless()
		"main_tree":
			await scenario_main_tree()
		"main_tree_max":
			await scenario_main_tree_max()
		"main_skins":
			await scenario_main_skins()
		"main_gear":
			await scenario_main_gear()
		"main_debug":
			await scenario_main_debug()
		"title":
			await scenario_title()
		"title_slots":
			await scenario_title_slots()
		"act1_start":
			await scenario_act1_start()
		"act1_wave":
			await scenario_act1_wave()
		"act1_shell":
			await scenario_act1_shell()
		"act1_break":
			await scenario_act1_break()
		"act1_lesson":
			await scenario_act1_lesson()
		"act1_thresh":
			await scenario_act1_thresh()
		"act1_cutscene":
			await scenario_act1_cutscene()
		"act1_result":
			await scenario_act1_result()
		"game_over":
			await scenario_game_over()
		"act2_pillars":
			await scenario_act2_pillars()
		"act2_super":
			await scenario_act2_super()
		"akshan_e":
			await scenario_akshan_e()
		"akshan_r":
			await scenario_akshan_r()
		"defeat":
			await scenario_defeat()
		"loot":
			await scenario_loot()
		"guardian_angel":
			await scenario_guardian_angel()
		"act3_jungle":
			await scenario_act3_jungle()
		"act3_water":
			await scenario_act3_water()
		"act3_pit":
			await scenario_act3_pit()
		"infernal_meteor":
			await scenario_infernal_meteor()
		"ocean_mist":
			await scenario_ocean_mist()
		"training_setup":
			await scenario_training_setup()
		"skins_stage":
			await scenario_skins_stage()
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
	var tip := hover_tip()
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


## The HoverTip of what is on screen: the stage's or the main screen's.
func hover_tip() -> HoverTip:
	var screen: Node = stage if game_root == null else game_root.screen
	for child in screen.get_children():
		if child is HoverTip:
			return child
	return null


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
	print("slow (expect true): ", dummy.has_status(Enemy.SLOW))
	await shot("actives_0_gunblade")
	await wait(0.5)
	print("galeforce (expect true): ", lucian.use_equip_slot(1, dummy.global_position))
	await wait(0.3)
	await shot("actives_1_galeforce")
	await wait(0.6)
	print("rocketbelt (expect true): ", lucian.use_equip_slot(2, dummy.global_position + Vector2(0, -100)))
	# Mid-dash (it lands at 0.34 s): the trail grows behind Lucian.
	await wait(0.2)
	await shot("actives_2_rocketbelt")
	lucian.progress.set_level(6)
	lucian.try_rank_up(ChampionProgress.Slot.R)
	lucian.try_cast(ChampionProgress.Slot.R, dummy.global_position)
	await wait(1.0)
	await shot("actives_3_hatefog")
	print("hatefog on the dummy (expect true): ", dummy.has_status(Enemy.HATEFOG))


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
	# Running under Ghost leaves afterimages behind him.
	lucian.command_move(lucian.global_position + Vector2(-600, 0))
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
	print("hp after heal (expect 455): ", roundi(lucian.hp))
	await wait(0.25)
	await shot("summoners_4_heal")
	await wait(0.8)
	lucian.summoners.set_spell(0, &"clarity")
	lucian.mana = 50.0
	lucian.use_summoner(0, Vector2.ZERO)
	print("mana after clarity (expect 210): ", roundi(lucian.mana))
	await wait(0.3)
	await shot("summoners_5_clarity")
	var slot: Control = hud.skill_row.get_child(hud.skill_row.get_child_count() - 1)
	await mouse_move(control_center(slot))
	await wait_for_tooltip(slot)
	await shot("summoners_6_card")


func scenario_camera() -> void:
	var camera: StageCamera = stage.get_node("StageCamera")
	camera.mode = StageCamera.Mode.FREE
	lucian.global_position = Vector2(2000, 1500)
	camera.global_position = Vector2(3200, 900)
	await wait(0.2)
	await shot("camera_0_away")
	await press_key(KEY_SPACE, true)
	await press_key(KEY_SPACE, false)
	await wait(0.1)
	print("camera after Space (expect (2000, 1500)): ", camera.global_position.round(), "  still free (expect true): ", camera.mode == StageCamera.Mode.FREE)
	await shot("camera_1_back")


## Hovering each slot shows its range around Lucian, pointing where he faces.
func scenario_indicators() -> void:
	var hud: Hud = stage.get_node("Hud")
	lucian.progress.set_level(6)
	for slot in [ChampionProgress.Slot.Q, ChampionProgress.Slot.W, ChampionProgress.Slot.E, ChampionProgress.Slot.R]:
		lucian.try_rank_up(slot)
	lucian.summoners.slots = [&"flash", &"smite"]
	equip_all([&"hextech_gunblade", &"galeforce", &"hextech_rocketbelt"])
	lucian.visuals.face(Vector2(1.0, -0.5))
	var count := hud.skill_row.get_child_count()
	var hovers := [
		["q", hud.skill_row.get_child(1)], ["w", hud.skill_row.get_child(2)],
		["e", hud.skill_row.get_child(3)], ["r", hud.skill_row.get_child(4)],
		["flash", hud.skill_row.get_child(count - 2)], ["smite", hud.skill_row.get_child(count - 1)],
		["gunblade", hud.item_grid.get_child(0)], ["galeforce", hud.item_grid.get_child(1)],
	]
	for i in hovers.size():
		await mouse_move(control_center(hovers[i][1]))
		await wait(0.1)
		var shown := lucian.indicator.shown()
		print("%s: %s" % [hovers[i][0], "none" if shown == null else "kind %d reach %d" % [shown.kind, shown.reach]])
		await shot("indicators_%d_%s" % [i, hovers[i][0]])
	await mouse_move(Vector2(200, 200))
	await wait(0.1)
	print("off the HUD (expect none): ", "none" if lucian.indicator.shown() == null else "shown")


## Normal cast: pressing a key aims at the cursor until a left-click.
func scenario_cast_modes() -> void:
	var settings := GameSettings.instance()
	var controller: LucianController = lucian.get_node("Controller")
	lucian.progress.set_level(6)
	for slot in [ChampionProgress.Slot.Q, ChampionProgress.Slot.W, ChampionProgress.Slot.E, ChampionProgress.Slot.R]:
		lucian.try_rank_up(slot)
	for action in [&"skill_q", &"skill_e", &"summoner_d"]:
		settings.set_cast_mode(action, "normal")
	var screen := root.get_visible_rect().size
	await mouse_move(screen * Vector2(0.75, 0.3))
	await press_key(KEY_Q, true)
	await press_key(KEY_Q, false)
	await wait(0.1)
	print("aiming Q (expect skill_q): ", controller.aiming())
	await shot("cast_modes_0_q_aimed")
	await press_key(KEY_E, true)
	await press_key(KEY_E, false)
	await mouse_move(screen * Vector2(0.58, 0.42))
	await wait(0.1)
	print("aiming E (expect skill_e): ", controller.aiming())
	await shot("cast_modes_1_e_landing")
	await press_key(KEY_D, true)
	await press_key(KEY_D, false)
	await mouse_move(screen * Vector2(0.62, 0.62))
	await wait(0.1)
	await shot("cast_modes_2_flash")
	await mouse_button(screen * Vector2(0.62, 0.62), true)
	await mouse_button(screen * Vector2(0.62, 0.62), false)
	await wait(0.1)
	print("after the click (expect none, flash used): ", controller.aiming(), " ", not lucian.summoners.cooldown(&"flash").is_ready())
	settings.set_value(&"cast_modes", {})


## The Phase 5 art: essence, gear and skull icons, then every Evolution Tree
## node icon, each at 64 px and 32 px with its file name under it.
func scenario_art_sheet() -> void:
	var paths: Array[String] = []
	for file in ["essence_blue", "essence_orange", "essence_purple", "gear", "skull"]:
		paths.append("res://assets/art/ui/%s.svg" % file)
	for id in [
		"skill_q", "skill_w", "skill_e", "passive", "skill_r",
		"stat_ad", "stat_ap", "stat_hp", "stat_armor", "stat_mr", "stat_attack_speed", "stat_mana",
		"equip_slots", "stage_gold", "bonus_xp", "essence_drop", "merchant_stock", "refresh_cost",
		"flash", "ghost", "barrier", "heal", "clarity", "smite",
		"flash_upgrade", "ghost_upgrade", "barrier_upgrade", "heal_upgrade", "clarity_upgrade", "smite_upgrade",
		"summoner_slot_2",
	]:
		paths.append("res://assets/art/tree/%s.svg" % id)
	var background := ColorRect.new()
	background.color = Color("0b0d12")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var grid := GridContainer.new()
	grid.columns = 8
	grid.position = Vector2(16, 16)
	grid.add_theme_constant_override(&"h_separation", 12)
	grid.add_theme_constant_override(&"v_separation", 18)
	root.add_child(grid)
	var missing := 0
	for path in paths:
		var texture: Texture2D = load(path) if ResourceLoader.exists(path) else null
		if texture == null:
			missing += 1
		var box := VBoxContainer.new()
		box.custom_minimum_size.x = 180
		var icons := HBoxContainer.new()
		icons.alignment = BoxContainer.ALIGNMENT_CENTER
		icons.add_theme_constant_override(&"separation", 10)
		for side in [64, 32]:
			var rect := TextureRect.new()
			rect.texture = texture
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			rect.custom_minimum_size = Vector2(side, side)
			rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			icons.add_child(rect)
		box.add_child(icons)
		var label := Label.new()
		label.text = path.get_file()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override(&"font_size", 13)
		box.add_child(label)
		grid.add_child(box)
	print("art icons: ", paths.size() - missing, " / ", paths.size())
	await wait(0.3)
	await shot("art_sheet_0")


# --- Phase 5: the main screen, and Training started from it ---------------


func main_screen() -> MainScreen:
	return game_root.screen as MainScreen


func journey() -> JourneySection:
	return main_screen().sections[MainScreen.SECTION_JOURNEY] as JourneySection


func tree_section() -> TreeSection:
	return main_screen().sections[MainScreen.SECTION_TREE] as TreeSection


func main_debug() -> MainDebugTable:
	return main_screen().get_node("MainDebugTable") as MainDebugTable


## Every button under `node` reading `text`, in tree order.
func find_buttons(node: Node, text: String) -> Array[Button]:
	var found: Array[Button] = []
	for child in node.find_children("*", "Button", true, false):
		if (child as Button).text == text:
			found.append(child)
	return found


## Journey → Start Training, as the player does it: the stage is built from
## the save. `stage` and `lucian` point at it afterwards.
func start_training() -> void:
	main_screen().show_section(MainScreen.SECTION_JOURNEY)
	journey().show_tab(JourneySection.TRAINING_TAB)
	journey().training_page.start_button.pressed.emit()
	stage = game_root.screen
	lucian = (stage as Stage).lucian
	# The stage confines the mouse; give it back during automated runs.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	(stage as Stage).camera.mode = StageCamera.Mode.FOLLOW
	await wait(0.4)


## ESC menu → Leave this stage: the stage-done auto-save, then the main screen.
func leave_stage() -> void:
	(stage as Stage).screens.menu.leave_requested.emit()
	await wait(0.2)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("left the stage: main screen (expect true): ", game_root.screen is MainScreen,
		"  save file written (expect true): ", FileAccess.file_exists(SaveGame.instance().path(1)))
	stage = null
	lucian = null


func locked_tab_names(section: JourneySection) -> Array:
	return section.tabs.filter(func(tab: JourneyTab) -> bool: return tab.locked).map(
		func(tab: JourneyTab) -> String: return tab.text)


## Journey's Training tab with the loadout on a new save, then with spells
## bought: the spell menu for F, and a pick that swaps D and F.
func scenario_main_journey() -> void:
	var section := journey()
	var loadout := section.loadout
	await wait(0.2)
	print("opens on Journey, Training tab (expect true true): ",
		main_screen().sections[MainScreen.SECTION_JOURNEY].visible, " ", section.training_page.visible)
	print("new save: D reads (expect None), F chained (expect true): ", loadout.picks[0].text, " ", loadout.picks[1].disabled)
	await shot("main_journey_0_training")
	var save := SaveGame.instance()
	save.essences.add(Essences.BLUE, 2000)
	save.essences.add(Essences.ORANGE, 10)
	for id: StringName in [&"flash", &"ghost", &"heal", &"smite", &"summoner_slot_2"]:
		save.tree.buy(id, save.essences)
	save.set_loadout(0, &"flash")
	save.set_loadout(1, &"heal")
	await wait(0.1)
	print("2nd slot bought: F chained (expect false): ", loadout.picks[1].disabled)
	loadout.open_menu(1)
	await wait(0.1)
	print("menu lists (expect [flash, ghost, heal, smite]): ", loadout.menu.spell_ids())
	await shot("main_journey_1_spell_menu")
	loadout.menu.pick(&"flash")
	await wait(0.1)
	print("Flash on F swaps (expect [heal, flash]): ", save.loadout)
	await shot("main_journey_2_swapped")


## Act 1 on a new save; then the debug table's "Acts cleared" at 2: Act 3
## with its skulls and chains, and Act 2 cleared.
func scenario_main_acts() -> void:
	var section := journey()
	section.show_tab(0)
	await wait(0.2)
	print("locked tabs on a new save (expect Act 2-6 and Endless): ", locked_tab_names(section))
	await shot("main_acts_0_act1")
	var spin: SpinBox = main_debug().find_children("*", "SpinBox", true, false)[0]
	spin.value = 2
	print("acts cleared after the debug spin (expect 2): ", Journey.acts_cleared(SaveGame.instance().cleared))
	print("locked tabs (expect Act 4-6 and Endless): ", locked_tab_names(section))
	section.show_tab(2)
	await wait(0.2)
	var cards := section.act_pages[2].cards
	print("Act 3 cards locked (expect [false, true, true, true, true]): ",
		cards.map(func(card: StageCard) -> bool: return card.locked))
	print("Act 3 skulls (expect [false, true, false, true, true]): ",
		cards.map(func(card: StageCard) -> bool: return card.skull.visible))
	await shot("main_acts_1_act3")
	section.show_tab(1)
	await wait(0.2)
	print("Act 2 cards cleared (expect [true, true, true]): ",
		section.act_pages[1].cards.map(func(card: StageCard) -> bool: return card.cleared))
	await shot("main_acts_2_act2_cleared")


## The Endless tab locked (hovered: what to clear), then open after Act 3.
func scenario_main_endless() -> void:
	var section := journey()
	var tab := section.tabs[JourneySection.ENDLESS_TAB]
	await wait(0.2)
	print("Endless locked on a new save (expect true): ", tab.locked,
		"  hover (expect Clear Act 3 first): ", tab.get_meta(&"hover_text", ""))
	await mouse_move(control_center(tab))
	await wait_for_tooltip(tab)
	await shot("main_endless_0_locked")
	SaveGame.instance().set_cleared(Journey.all_stage_ids(Journey.ENDLESS_ACT))
	section.show_tab(JourneySection.ENDLESS_TAB)
	await mouse_move(Vector2(960, 1000))
	await wait(0.2)
	print("after Act 3: Endless locked, shown (expect false true): ", tab.locked, " ", section.endless_page.visible)
	print("best wave (expect Best wave: 0): ", section.endless_page.best_label.text)
	await shot("main_endless_1_open")


## The Evolution Tree on a new save; then with essence, some nodes bought and
## the info panel open; a drag that starts on a node; zoomed out to 0.6.
func scenario_main_tree() -> void:
	main_screen().show_section(MainScreen.SECTION_TREE)
	var section := tree_section()
	var map := section.map
	await wait(0.3)
	print("new save: Q, passive, E (expect poor hidden hidden): ",
		[map.views[&"skill_q"].state(), map.views[&"passive"].state(), map.views[&"skill_e"].state()])
	await shot("main_tree_0_new_save")
	var save := SaveGame.instance()
	save.essences.add(Essences.BLUE, 10000)
	save.essences.add(Essences.ORANGE, 100)
	for id: StringName in [&"skill_q", &"skill_q", &"skill_w", &"passive", &"stat_ad", &"stat_ad",
			&"stat_hp", &"equip_slots", &"flash"]:
		section.select(id)
		section.info.cost_bar.buy()
	section.select(&"stat_ad")
	await wait(0.2)
	print("Q level, state (expect 2 bought): ", save.tree.level(&"skill_q"), " ", map.views[&"skill_q"].state())
	print("stat_ad panel (expect LVL 2 / 5, +8 AD → +12 AD): ", section.info.level_label.text, ", ", section.info.value_label.text)
	print("blue left (expect 10000 - 1050 = 8950): ", save.essences.amount(Essences.BLUE))
	await shot("main_tree_1_bought_info")
	section.select(&"skill_r")
	await wait(0.2)
	print("R hidden (expect ???, LOCKED): ", section.info.name_label.text, ", ", section.info.cost_bar.status.text)
	print("R requires: ", section.info.requires_label.text)
	await shot("main_tree_2_hidden_info")
	section.close_popup()
	# A drag that starts on top of a node pans the map (real input routing).
	var start := control_center(map.views[&"skill_w"])
	var before := map.layer.position.x
	await mouse_move(start)
	await mouse_button(start, true)
	for step in 6:
		await mouse_move(start + Vector2(-40.0 * (step + 1), 0.0), true)
	await mouse_button(start + Vector2(-240.0, 0.0), false)
	print("drag from a node: moved (expect -240), panel shown (expect false): ",
		roundi(map.layer.position.x - before), " ", section.info.visible)
	await click(map.views[&"stat_hp"])
	print("click on a node selects it (expect stat_hp): ", section.info.id)
	section.close_popup()
	await mouse_move(Vector2(960, 140))
	await hover_node(map.views[&"skill_q"])
	await shot("main_tree_3_hover")
	await mouse_move(Vector2(960, 140))
	map.zoom_at(Vector2.ZERO, 0.6)
	map.pan_by(Vector2(10000, 0))
	await wait(0.2)
	print("zoom (expect 0.6): ", map.zoom)
	await shot("main_tree_4_zoom_06")
	map.pan_by(Vector2(-10000, 0))
	await wait(0.2)
	await shot("main_tree_5_zoom_06_right")


func hover_node(view: TreeNodeView) -> void:
	await mouse_move(control_center(view))
	await wait_for_tooltip(view)


## Debug Max tree: every node maxed and every line lit, at zoom 0.6 from
## both ends, then the Summoners grove at zoom 1 with a node chosen.
func scenario_main_tree_max() -> void:
	main_screen().show_section(MainScreen.SECTION_TREE)
	var section := tree_section()
	var map := section.map
	find_buttons(main_debug(), "Max tree (free)")[0].pressed.emit()
	await wait(0.2)
	var maxed := map.views.values().filter(func(view: TreeNodeView) -> bool: return view.state() == &"maxed").size()
	print("maxed nodes (expect 31): ", maxed)
	map.zoom_at(Vector2.ZERO, 0.6)
	await wait(0.2)
	await shot("main_tree_max_0_left")
	map.pan_by(Vector2(-10000, 0))
	await wait(0.2)
	await shot("main_tree_max_1_right")
	map.zoom_at(map.size, 1.0)
	map.pan_by(Vector2(-10000, 0))
	section.select(&"heal_upgrade")
	await wait(0.2)
	print("heal_upgrade (expect +45% healing, MAXED): ", section.info.value_label.text, ", ", section.info.cost_bar.status.text)
	await shot("main_tree_max_2_summoners")


## The Skin Shop with 0 purple, then with 100 purple: Vampire bought and
## equipped.
func scenario_main_skins() -> void:
	main_screen().show_section(MainScreen.SECTION_SKINS)
	var shop := main_screen().sections[MainScreen.SECTION_SKINS] as SkinShop
	var buttons := func() -> Array:
		return shop.cards.map(func(card: SkinCard) -> String:
			return "%s%s" % [card.button.text, " (off)" if card.button.disabled else ""])
	await wait(0.3)
	print("0 purple (expect Equipped (off), then Purchase N (off) x4): ", buttons.call())
	await shot("main_skins_0_zero")
	var save := SaveGame.instance()
	save.essences.add(Essences.PURPLE, 100)
	var vampire := shop.cards[4]
	vampire.button.pressed.emit()
	print("bought Vampire: purple (expect 75), skin (expect classic): ", save.essences.amount(Essences.PURPLE), " ", save.skin)
	vampire.button.pressed.emit()
	await wait(0.2)
	print("equipped (expect vampire): ", save.skin, "  buttons: ", buttons.call())
	print("no file written (expect false): ", FileAccess.file_exists(save.path(1)))
	await shot("main_skins_1_vampire")


## The gear menu (Leave to main menu), Save and its
## toast, the slot list, the overwrite question and "Save before leaving?".
func scenario_main_gear() -> void:
	var main := main_screen()
	var save := SaveGame.instance()
	main.gear.open()
	await wait(0.2)
	var leave := main.gear.find_button("Leave to main menu")
	print("Leave to main menu enabled (expect true): ", not leave.disabled)
	await shot("main_gear_0_menu")
	main.gear.find_button("Save").pressed.emit()
	await wait(0.1)
	print("Save: slot 1 written (expect true), toast (expect Saved to slot 1): ",
		FileAccess.file_exists(save.path(1)), " ", main.toast_text())
	await shot("main_gear_1_toast")
	main.gear.open()
	main.gear.show_slots()
	main.gear.find_button("Slot 2 · empty").pressed.emit()
	print("copied to an empty slot 2 without asking (expect false true): ", main.confirm.is_open(), " ",
		save.slot_exists(2), "  toast: ", main.toast_text())
	main.gear.open()
	main.gear.show_slots()
	await wait(0.2)
	print("slot list: ", main.gear._slot_list.buttons.map(func(button: Button) -> String: return button.text))
	await shot("main_gear_2_slots")
	main.gear._slot_list.buttons[1].pressed.emit()
	await wait(0.1)
	print("slot 2 exists, so it asks (expect true): ", main.confirm.is_open())
	await shot("main_gear_3_overwrite")
	main.confirm.answer(false)
	main.gear.open()
	main.gear.find_button("Exit the game").pressed.emit()
	await wait(0.2)
	print("Exit asks to save (expect true): ", game_root.prompt.is_open())
	await shot("main_gear_4_save_prompt")
	game_root.prompt.answer(false)
	paused = false


## The main screen's debug table: F3 + Q, the Essences tab after +1000 blue
## and +10 purple, then the Progress tab.
func scenario_main_debug() -> void:
	var table := main_debug()
	var save := SaveGame.instance()
	print("hidden at start (expect false): ", table.visible)
	await press_key(KEY_F3, true)
	await press_key(KEY_Q, true)
	await press_key(KEY_Q, false)
	await press_key(KEY_F3, false)
	print("shown after F3 + Q (expect true): ", table.visible)
	find_buttons(table, "+1000")[0].pressed.emit()
	find_buttons(table, "+10")[1].pressed.emit()
	await wait(0.2)
	print("blue, purple (expect 1000 10): ", save.essences.amount(Essences.BLUE), " ", save.essences.amount(Essences.PURPLE),
		"  bar reads (expect 1000): ", main_screen().essence_bar.amount_label(Essences.BLUE).text)
	await shot("main_debug_0_essences")
	var tabs: TabContainer = table.find_children("*", "TabContainer", true, false)[0]
	tabs.current_tab = 1
	await wait(0.2)
	await shot("main_debug_1_progress")
	await press_key(KEY_F3, true)
	await press_key(KEY_Q, true)
	await press_key(KEY_Q, false)
	await press_key(KEY_F3, false)
	print("hidden after F3 + Q again (expect false): ", table.visible)


## Start Training from a new save: locked ranks, the locked passive, one
## equip slot, an empty D and a chained F (with their cards), and the stage
## debug table. Then back, Max tree with Flash and Heal: everything open, the
## upgrade line on a spell card and the cheaper refresh in the shop.
func scenario_training_setup() -> void:
	await start_training()
	var hud: Hud = stage.get_node("Hud")
	var row := hud.skill_row
	var count := row.get_child_count()
	print("new save: bought (expect [0, 0, 0, 0]): ", lucian.progress.bought)
	print("passive learned, charged (expect false false): ", lucian.passive.learned, " ", lucian.passive.charged)
	print("equip slots (expect 1): ", lucian.inventory.unlocked_equip, "  shop slots (expect 2): ", (stage as Stage).shop_slots)
	print("D/F (expect empty, empty), open (expect 1): ", lucian.summoners.slots, " ", lucian.summoners.open_slots)
	await shot("training_setup_0_new_save")
	await mouse_move(control_center(row.get_child(count - 2)))
	await wait_for_tooltip(row.get_child(count - 2))
	await shot("training_setup_1_d_empty")
	await mouse_move(control_center(row.get_child(count - 1)))
	await wait_for_tooltip(row.get_child(count - 1))
	await shot("training_setup_2_f_chained")
	await mouse_move(Vector2(960, 300))
	var table: DebugTable = stage.get_node("DebugTable")
	table.visible = true
	await wait(0.2)
	var pickers := table._summoner_pickers.map(func(picker: OptionButton) -> String: return picker.get_item_text(picker.selected))
	print("debug D/F pickers (expect [None, None]): ", pickers, "  Buy all ranks buttons (expect 1): ", find_buttons(table, "Buy all ranks").size())
	await shot("training_setup_3_debug_table")
	table.visible = false
	await leave_stage()
	var save := SaveGame.instance()
	save.tree.max_all()
	save.set_loadout(0, &"flash")
	save.set_loadout(1, &"heal")
	await start_training()
	row = (stage.get_node("Hud") as Hud).skill_row
	var stats := lucian.stats
	print("max tree: bought (expect [5, 5, 5, 3]), passive (expect true): ", lucian.progress.bought, " ", lucian.passive.learned)
	print("equip slots (expect 6), shop slots (expect 4): ", lucian.inventory.unlocked_equip, " ", (stage as Stage).shop_slots)
	print("D/F (expect flash heal, 2 open): ", lucian.summoners.slots, " ", lucian.summoners.open_slots)
	print("AD (expect 80), max HP (expect 800): ", stats.ad, " ", stats.max_hp, "  tree bonus: ", lucian.tree_bonus)
	await shot("training_setup_4_max_tree")
	await mouse_move(control_center(row.get_child(count - 1)))
	await wait_for_tooltip(row.get_child(count - 1))
	print("Heal upgrade (expect Upgraded: 45% stronger): ", lucian.summoners.upgrade_text(&"heal"))
	await shot("training_setup_5_upgrade_card")
	await mouse_move(Vector2(960, 300))
	(stage as Stage)._open_shop((stage as Stage).merchant)
	await wait(0.3)
	var panel := (stage as Stage).screens.backpack.shop_panel()
	print("shop open (expect true), refresh button (expect Refresh  50): ", (stage as Stage).screens.is_shopping(), " ", panel._refresh.text)
	await shot("training_setup_6_shop_refresh")


## Each skin in Training: its body, HUD portrait and stats. Bought and
## equipped on the main screen, then Start Training, then Leave this stage.
func scenario_skins_stage() -> void:
	var save := SaveGame.instance()
	var expected := {
		&"classic": "AD 60, AS 0.65, MS 335, HP 600",
		&"high_noon": "AD 69, AS 0.5525",
		&"project": "AD 54, AS 0.78, MS 385.25",
		&"pulsefire": "AS 0.585, AH 15",
		&"vampire": "HP 480, LS 0.15",
	}
	for i in Skins.ALL.size():
		var skin := Skins.ALL[i]
		save.essences.add(Essences.PURPLE, skin.cost)
		save.buy_skin(skin.id)
		save.equip_skin(skin.id)
		await start_training()
		(stage as Stage).camera.zoom = Vector2(1.6, 1.6)
		# Holding C shows the extra stats too (life steal for Vampire).
		Input.action_press(&"toggle_stats")
		await wait(0.3)
		var stats := lucian.stats
		var body := (lucian.get_node("Visuals/Body") as Sprite2D).texture == skin.body
		var portrait := (stage.get_node("Hud") as Hud).portrait.texture == skin.portrait
		print("%s (expect %s): AD %s, AS %s, MS %s, HP %s, AH %s, LS %s; body %s, portrait %s" % [
			skin.id, expected[skin.id], stats.ad, stats.attack_speed, stats.move_speed, stats.max_hp,
			stats.ability_haste, stats.lifesteal, body, portrait])
		await shot("skins_stage_%d_%s" % [i, skin.id])
		Input.action_release(&"toggle_stats")
		await leave_stage()


# --- Phase 6: the title screen, Acts 1 and 2 -------------------------------


## The title screen as it opens on a new game: Load game disabled (hovered:
## why).
func scenario_title() -> void:
	var title := game_root.screen as TitleScreen
	await wait(0.2)
	print("Load game disabled on a new game (expect true): ", title.load_button.disabled,
		"  hover (expect No saved games yet): ", title.load_button.get_meta(&"hover_text", ""))
	await shot("title_0_menu")
	await mouse_move(control_center(title.load_button))
	await wait_for_tooltip(title.load_button)
	await shot("title_1_load_disabled")


## Slot 2 saved (with some play time): Start new game lists it, picking it
## asks first; Load game lists only slot 2.
func scenario_title_slots() -> void:
	var title := game_root.screen as TitleScreen
	var save := SaveGame.instance()
	save.add_play_time(3720.0)
	save.essences.add(Essences.BLUE, 300)
	save.copy_to(2)
	title.show_menu()
	await wait(0.2)
	print("Load game enabled once a slot exists (expect true): ", not title.load_button.disabled)
	title.show_slots(false)
	await wait(0.2)
	print("new game slots (expect slot 2 with 1h 02m): ", title.slot_list.buttons.map(func(button: Button) -> String: return button.text))
	await shot("title_slots_0_new_game")
	title.slot_list.buttons[1].pressed.emit()
	await wait(0.2)
	print("slot 2 is used, so it asks (expect true): ", title.confirm.is_open())
	await shot("title_slots_1_overwrite")
	title.confirm.answer(false)
	title.show_slots(true)
	await wait(0.2)
	print("load slots disabled (expect [true, false, true]): ", title.slot_list.buttons.map(func(button: Button) -> bool: return button.disabled))
	await shot("title_slots_2_load")


func game_stage() -> Stage:
	return stage as Stage


func map_lane() -> MidLaneMap:
	return game_stage().arena as MidLaneMap


## The tip on screen ends and any queued ones go, as if their time had run
## (in real play a wave takes a minute or more, so the next tip is the one
## that matters).
func flush_tips() -> void:
	var tips := game_stage().hud.tips
	tips._queue.clear()
	tips._left = 0.0
	tips.visible = false


## The debug table's Kill all: each enemy dies as a kill (gold, XP, essences,
## loot) and counts toward the wave.
func kill_all() -> void:
	(stage.get_node("DebugTable") as DebugTable)._kill_all()


## Skip (the HUD button) starts the next wave; once all of it has spawned,
## Kill all ends it, again every 0.1 s until the runner has nobody left:
## splits waiting for their spawn, a Scuttler on its way out, and an
## untargetable boss (through boss_unit). Gives up after 30 s. The tips so
## far go first, so the break's tip shows. Senna's lesson (the tutorial's
## first break) is skipped unless `keep_lesson`.
func clear_wave(keep_lesson := false) -> void:
	var game := game_stage()
	game.skip_break()
	while not game.runner._to_spawn.is_empty():
		await wait(0.1)
	flush_tips()
	for step in 300:
		if game.runner.alive() == 0:
			break
		kill_all()
		var boss := game.boss_unit
		if is_instance_valid(boss) and boss.is_alive():
			boss.set_untargetable(false)
			boss.take_damage(lucian.make_damage(999999.0, DamageInfo.Type.TRUE, &"debug"))
		await wait(0.1)
	await wait(0.1)
	if game.cutscene is SennaTeachesE and not keep_lesson:
		game.cutscene.skip()
		await wait(0.1)


func info_text() -> String:
	var info := game_stage().hud.stage_info
	var parts := []
	for label: Label in [info.name_label, info.wave_label, info.enemies_label, info.timer_label]:
		if label.visible:
			parts.append(label.text)
	if info.skip_button.visible:
		parts.append("[Skip]")
	return "  ".join(parts)


## The first ground warning of `shape` in the stage, waiting up to `timeout`.
func wait_for_warning(shape: GroundWarning.Shape, timeout := 8.0) -> GroundWarning:
	var left := timeout
	while left > 0.0:
		for node in stage.get_node("Warnings").get_children():
			if node is GroundWarning and (node as GroundWarning).shape == shape:
				return node
		await wait(0.05)
		left -= 0.05
	push_error("no warning of shape %d" % shape)
	return null


## The boss of the boss wave, waiting for it to spawn.
func wait_for_boss() -> EnemyUnit:
	while not Lucian.is_target(game_stage().boss_unit):
		await wait(0.05)
	return game_stage().boss_unit


## Lucian jumps to `to` (a shortcut for walking there); Senna, if she is
## with him, lands at her place beside him as she would have walked.
func blink(to: Vector2) -> void:
	lucian.blink_to(to)
	var senna := game_stage().senna
	if senna:
		senna.global_position = to + Senna.FOLLOW_OFFSET.rotated(lucian.visuals.rotation)


## Act 1's first second: the move tip, Senna beside Lucian, "Wave 1 in 0:05"
## and the radar.
func scenario_act1_start() -> void:
	var game := game_stage()
	print("stage info (expect Act 1 · The Loss  Wave 1 in 0:05  [Skip]): ", info_text())
	print("tip (expect Right-click to move…): ", game.hud.tips.label.text, "  shown: ", game.hud.tips.visible)
	print("tutorial: one gun (expect true), ranks (expect [0, 0, 0, 0]), D/F (expect empty): ",
		lucian.one_gun, " ", lucian.progress.bought, " ", lucian.summoners.slots)
	print("Senna near Lucian (expect < 260): ", roundi(game.senna.global_position.distance_to(lucian.global_position)),
		"  radar shown (expect true): ", game.hud.radar.is_visible_in_tree())
	await shot("act1_start_0")


## Wave 1 reaches Lucian: "Wave 1/2", the enemies left, red dots on the radar,
## and the minions' hits as numbers over him.
func scenario_act1_wave() -> void:
	var game := game_stage()
	game.skip_break()
	flush_tips()
	# Halfway up the lane, so the wave meets him sooner.
	blink(map_lane().center() - map_lane().along() * 300.0)
	var hits := [0]
	lucian.damage_received.connect(func(_info: DamageInfo, _amount: float) -> void: hits[0] += 1)
	while hits[0] < 4:
		await wait(0.1)
	lucian.command_attack_move(lucian.global_position)
	await wait(1.2)
	print("stage info (expect Act 1 · The Loss  Wave 1/2  Enemies: N): ", info_text())
	print("enemies on the map: ", get_nodes_in_group(&"enemies").size(), "  hits on Lucian so far: ", hits[0],
		"  HP: ", roundi(lucian.hp))
	await shot("act1_wave_0")


## A siege minion's Cannon Shell: the red circle on Lucian before it lands.
func scenario_act1_shell() -> void:
	var game := game_stage()
	flush_tips()
	var siege := game.spawn_enemy(WavePlan.SIEGE, lucian.global_position + map_lane().along() * 600.0)
	game._tip(&"siege")
	var warning := await wait_for_warning(GroundWarning.Shape.CIRCLE)
	await wait(0.55)
	print("shell circle: radius (expect 110), on Lucian (expect < 40): ", warning.reach, " ",
		roundi(warning.global_position.distance_to(lucian.global_position)), "  siege alive: ", siege.is_alive())
	print("tip (expect A red circle marks…): ", game.hud.tips.label.text)
	await shot("act1_shell_0")


## Wave 1 cleared: the break, "Wave 2 in 0:17" with Skip, the merchant on
## the lane and his tip.
func scenario_act1_break() -> void:
	var game := game_stage()
	await clear_wave()
	# The first kill's tip; in real play it is long gone by the break.
	game.hud.tips._left = 0.0
	blink(game.arena.merchant_point - map_lane().along() * 380.0)
	await wait(3.2)
	print("stage info (expect Wave 2 in 0:17  [Skip]): ", info_text())
	print("merchant on the map (expect true): ", is_instance_valid(game.merchant),
		"  gold: ", game.wallet.gold, "  blue collected: ", game.collected[Essences.BLUE])
	await shot("act1_break_0")


## Wave 1 cleared: Senna's lesson. Her first line, her dash with its trail,
## the last caption, then E learned with its tip.
func scenario_act1_lesson() -> void:
	var game := game_stage()
	var e := ChampionProgress.Slot.E
	# Up the lane from the map's corner, so the scene has room around them.
	blink(map_lane().center() - map_lane().along() * 900.0)
	await clear_wave(true)
	var lesson := game.cutscene
	print("lesson playing (expect true): ", lesson is SennaTeachesE, "  E rank (expect 0): ", lucian.progress.ranks[e],
		"  one gun (expect true): ", lucian.one_gun)
	var countdown := game.runner.countdown()
	await wait(1.4)
	await shot("act1_lesson_0_caption")
	# Each caption ends early, as a click or Space does in play.
	lesson._end_step()
	await wait(0.12)
	await shot("act1_lesson_1_dash")
	# Out and back (0.18 + 0.35 + 0.18 s), then her second line.
	await wait(0.8)
	lesson._end_step()
	await wait(0.4)
	await shot("act1_lesson_2_learned")
	print("break countdown waited (expect true): ", is_equal_approx(game.runner.countdown(), countdown))
	# The first kill's tip; in real play it is long gone by the break.
	flush_tips()
	lesson._end_step()
	await wait(0.6)
	print("E rank (expect 1): ", lucian.progress.ranks[e], "  tip (expect E to dash…): ", game.hud.tips.label.text)
	await shot("act1_lesson_3_after")


## Both waves cleared, then the boss wave: Thresh rises from the river.
func to_thresh() -> Thresh:
	var game := game_stage()
	await clear_wave()
	await clear_wave()
	flush_tips()
	# Across the river from where he rises, so he isn't under the top of the HUD.
	blink(game.arena.boss_point + map_lane().along() * 520.0)
	game.skip_break()
	return await wait_for_boss() as Thresh


## The boss bar, and Death Sentence's line warning toward Lucian.
func scenario_act1_thresh() -> void:
	var game := game_stage()
	var thresh := await to_thresh()
	var warning := await wait_for_warning(GroundWarning.Shape.LINE)
	await wait(0.45)
	var toward := warning.global_position.direction_to(lucian.global_position)
	print("stage info (expect Boss wave  Enemies: 1): ", info_text(), "  boss bar shown (expect true): ", game.hud.boss_bar.visible)
	print("hook line: length (expect 1000), width (expect 70), aimed at Lucian (expect ~0°): ", warning.reach, " ",
		warning.width, " ", roundi(rad_to_deg(absf(warning.direction.angle_to(toward)))))
	print("tip (expect Thresh's hook…): ", game.hud.tips.label.text, "  Thresh HP: ", roundi(thresh.hp))
	await shot("act1_thresh_0")


## Thresh down to half: the cutscene's letterbox and captions, the hook on
## Senna, her soul flying to his lantern, the lantern lit.
func scenario_act1_cutscene() -> void:
	var game := game_stage()
	var thresh := await to_thresh()
	await wait(0.5)
	thresh.take_damage(lucian.make_damage(thresh.max_hp, DamageInfo.Type.TRUE, &"debug"))
	# The stage reacts to his half HP at the end of the frame.
	await process_frame
	print("Thresh stops at half (expect 1500): ", roundi(thresh.hp), "  cutscene (expect true): ", game.cutscene != null)
	var scene := game.cutscene
	await wait(1.6)
	print("caption: ", scene._speaker.text, ": ", scene._caption.text, "  HUD hidden (expect true): ", not game.hud.visible)
	await shot("act1_cutscene_0_caption")
	await press_key(KEY_SPACE, true)
	await press_key(KEY_SPACE, false)
	await wait(0.9)
	print("caption: ", scene._speaker.text, ": ", scene._caption.text)
	await shot("act1_cutscene_1_hook")
	await press_key(KEY_SPACE, true)
	await press_key(KEY_SPACE, false)
	# The pull (0.5 s), then the soul rises (0.4 s) and flies (1.2 s).
	await wait(1.4)
	await shot("act1_cutscene_2_soul")
	await wait(1.2)
	print("caption: ", scene._speaker.text, ": ", scene._caption.text)
	await shot("act1_cutscene_3_lantern")


## The cutscene skipped: STAGE CLEARED, first-clear purple, the E line and
## "Act 2 is open".
func scenario_act1_result() -> void:
	var game := game_stage()
	var thresh := await to_thresh()
	await wait(0.5)
	thresh.take_damage(lucian.make_damage(thresh.max_hp, DamageInfo.Type.TRUE, &"debug"))
	await wait(1.0)
	game.cutscene.skip_button.pressed.emit()
	await wait(0.4)
	print("result (expect STAGE CLEARED): ", game.result.title.text, "  paused (expect true): ", paused)
	print("reward lines: ", game.reward_lines)
	print("purple (expect 10), bosses (expect [thresh_1]): ", SaveGame.instance().essences.amount(Essences.PURPLE),
		" ", SaveGame.instance().bosses, "  waves (expect 3 / 3): ", game.runner.waves_done(), " / ", game.runner.total_waves())
	print("buttons (expect retry, next hidden and main lit): ", game.result.retry_button.visible, " ", game.result.next_button.visible, " ", game.result.main_button.text,
		"  HUD hidden (expect true): ", not game.hud.visible)
	await shot("act1_result_0")
	paused = false


## Losing the tutorial: GAME OVER with a single Back to title.
func scenario_game_over() -> void:
	var game := game_stage()
	await wait(0.5)
	game.show_result(false)
	await wait(0.2)
	print("result (expect GAME OVER): ", game.result.title.text, "  retry shown (expect false): ", game.result.retry_button.visible,
		"  main button (expect Back to title): ", game.result.main_button.text)
	await shot("game_over_0")
	paused = false


## Stage 2-3: the ring of pillars, wave 1 coming in from three gates.
func scenario_act2_pillars() -> void:
	var game := game_stage()
	game.skip_break()
	await wait(3.5)
	print("stage info (expect Stage 2-3 · The Sentinels  Wave 1/3  Enemies: 14): ", info_text())
	print("pillars (expect 10): ", TrainingGroundMap.pillars(3).size(), "  spawn gates (expect 3): ", game.arena.spawn_points.size())
	await shot("act2_pillars_0_wave")
	game.camera.zoom = Vector2(0.42, 0.42)
	await wait(0.2)
	await shot("act2_pillars_1_ring")


## The whole of an Act 3 map, the camera zoomed out over it.
func whole_map(file_name: String) -> void:
	var game := game_stage()
	game.camera.mode = StageCamera.Mode.FREE
	var view := game.camera.get_viewport_rect().size
	var fit := minf(view.x / game.arena.size.x, view.y / game.arena.size.y)
	game.camera.zoom = Vector2.ONE * fit
	game.camera.global_position = game.arena.size * 0.5
	await wait(0.3)
	await shot(file_name)


## 3-2's jungle: the whole map with its lava and Blast Cones; then Lucian
## shoots a cone beside a loop and flies over its jungle.
func scenario_act3_jungle() -> void:
	var game := game_stage()
	print("stage info (expect Stage 3-2 · The Jungle  Wave 1 in …): ", info_text())
	print("walls (expect 4): ", game.arena.wall_polygons.size(), "  plants (expect 4): ", get_nodes_in_group(&"plants").size())
	await whole_map("act3_jungle_0_map")
	var cone: BlastCone = get_nodes_in_group(&"plants")[0]
	blink(cone.global_position + Vector2(0, 160))
	game.camera.zoom = Vector2(0.6, 0.6)
	game.camera.mode = StageCamera.Mode.FOLLOW
	await wait(0.3)
	await shot("act3_jungle_1_cone")
	lucian.command_attack(cone)
	while not lucian.is_launched():
		await wait(0.02)
	await wait(0.25)
	await shot("act3_jungle_2_thrown")
	await wait(0.6)
	print("landed walkable (expect true): ", game.arena.is_walkable(lucian.global_position), " at ", lucian.global_position)
	await shot("act3_jungle_3_landed")


## 3-4's jungle: the riverbed of shallow water and the Honeyfruit; Lucian
## wading in the river, slowed.
func scenario_act3_water() -> void:
	var game := game_stage()
	await whole_map("act3_water_0_map")
	blink(Vector2(JungleMap.RIVER_X, 1600))
	game.camera.zoom = Vector2(0.8, 0.8)
	game.camera.mode = StageCamera.Mode.FOLLOW
	await wait(0.3)
	print("slowed in the water (expect 0.25): ", lucian.slow_amount())
	await shot("act3_water_1_wading")


## 3-5's pit: the round floor, its rock ring in 8 pieces and 6 rocks; then
## Lucian at the start with the radar.
func scenario_act3_pit() -> void:
	var game := game_stage()
	print("walls (expect 8): ", game.arena.wall_polygons.size(), "  rocks (expect 6): ", game.arena.wall_circles.size())
	await whole_map("act3_pit_0_map")
	game.camera.zoom = Vector2.ONE
	game.camera.mode = StageCamera.Mode.FOLLOW
	await wait(0.3)
	await shot("act3_pit_1_start")


## A drake in the jungle's pit, Lucian below it, the camera between them.
func to_drake(id: StringName) -> Boss:
	var game := game_stage()
	flush_tips()
	blink(JungleMap.PIT + Vector2(0, 250))
	game.camera.mode = StageCamera.Mode.FREE
	game.camera.global_position = JungleMap.PIT + Vector2(0, 60)
	game.camera.zoom = Vector2(0.8, 0.8)
	var drake := game.spawn_enemy(id, JungleMap.PIT + Vector2(0, -180)) as Boss
	drake.move_speed = 0.0
	for skill: StringName in drake._cooldowns:
		drake._cooldowns[skill] = 60.0
	return drake


## The Infernal Drake: Meteor Fall's four circles round Lucian, then the
## burning ground they leave; then Fire Breath's cone and its fire.
func scenario_infernal_meteor() -> void:
	var drake := to_drake(&"infernal_drake") as InfernalDrake
	drake._cooldowns[&"meteor_fall"] = 0.0
	await wait_for_warning(GroundWarning.Shape.CIRCLE)
	await wait(0.8)
	var circles := stage.get_node("Warnings").get_children().filter(func(node: Node) -> bool: return node is GroundWarning)
	print("meteor circles (expect 4): ", circles.size())
	await shot("infernal_meteor_0_warnings")
	await wait(0.6)
	var zones := stage.get_node("Warnings").get_children().filter(func(node: Node) -> bool: return node is HazardZone)
	print("burning circles (expect 4): ", zones.size(), "  Lucian burning (expect true): ", lucian._burns.has(HazardZone.BURN_ID))
	await shot("infernal_meteor_1_burning")
	drake._cooldowns[&"fire_breath"] = 0.0
	await wait_for_warning(GroundWarning.Shape.CONE)
	await wait(0.6)
	await shot("infernal_meteor_2_breath")
	await wait(0.5)
	await shot("infernal_meteor_3_fire")


## The Ocean Drake: Tidal Wave's line and the wave pushing Lucian back;
## then Soothing Mist's ring, and an interrupt with the drake dazed.
func scenario_ocean_mist() -> void:
	var drake := to_drake(&"ocean_drake") as OceanDrake
	drake._cooldowns[&"tidal_wave"] = 0.0
	await wait_for_warning(GroundWarning.Shape.LINE)
	await wait(0.6)
	var before := lucian.global_position
	await shot("ocean_mist_0_wave_warning")
	await wait(0.4)
	await shot("ocean_mist_1_wave")
	await wait(0.5)
	print("pushed (expect about 300): ", before.distance_to(lucian.global_position), "  slowed (expect 0.3): ", lucian.slow_amount())
	# Back where he stood, before the mist.
	blink(before)
	drake.hp = drake.max_hp * 0.6
	drake.health_bar.set_health(drake.hp, drake.max_hp)
	drake._cooldowns[&"soothing_mist"] = 0.0
	while not drake.is_channeling():
		await wait(0.05)
	await wait(1.5)
	print("healed from 60%% to %d%%" % roundi(100.0 * drake.hp / drake.max_hp))
	await shot("ocean_mist_2_channel")
	drake.take_damage(DamageInfo.create(drake.max_hp * 0.09, DamageInfo.Type.TRUE, &"test"))
	await wait(0.3)
	print("interrupted (expect false, true): ", drake.is_channeling(), " ", drake.is_dazed())
	await shot("ocean_mist_3_interrupted")


## A super minion with melee and ranged minions around it: Empower's icon
## over the near ones, none over the far one.
func scenario_act2_super() -> void:
	var game := game_stage()
	var at := lucian.global_position + Vector2(0, -520)
	var super_minion := game.spawn_enemy(WavePlan.SUPER, at)
	var near: Array[EnemyUnit] = []
	for offset: Vector2 in [Vector2(-150, 60), Vector2(150, 60), Vector2(-110, -120), Vector2(120, -110)]:
		near.append(game.spawn_enemy(WavePlan.MELEE if offset.y > 0 else WavePlan.RANGED, at + offset))
	var far := game.spawn_enemy(WavePlan.MELEE, at + Vector2(820, 0))
	await wait(0.7)
	print("empowered near (expect [true, true, true, true]): ", near.map(func(unit: EnemyUnit) -> bool: return unit.has_status(EnemyUnit.EMPOWER)),
		"  far (expect false): ", far.has_status(EnemyUnit.EMPOWER), "  super: ", super_minion.data.display_name)
	await shot("act2_super_0")
	await mouse_move(Vector2(960, 540))
	game.camera.mode = StageCamera.Mode.FREE
	var middle := super_minion.global_position
	for unit in near:
		middle += unit.global_position
	game.camera.global_position = middle / (near.size() + 1)
	game.camera.zoom = Vector2(1.6, 1.6)
	await wait(0.1)
	await shot("act2_super_1_close")


## Akshan in stage 2-3's boss wave.
func to_akshan(lucian_at: Vector2) -> Akshan:
	var game := game_stage()
	flush_tips()
	lucian.blink_to(lucian_at)
	game.jump_to_boss_wave()
	return await wait_for_boss() as Akshan


## Heroic Swing: the circle warning near Lucian, then Akshan swinging round
## it, firing gold bolts outward.
func scenario_akshan_e() -> void:
	var akshan := await to_akshan(Vector2(1500, 1000))
	akshan._cooldowns[&"avengerang"] = 60.0
	akshan._cooldowns[&"heroic_swing"] = 0.0
	akshan.global_position = Vector2(950, 1000)
	var warning := await wait_for_warning(GroundWarning.Shape.CIRCLE)
	await wait(0.7)
	print("swing circle: radius (expect 300), Lucian inside (expect true): ", warning.reach, " ",
		warning.covers(lucian.global_position))
	await shot("akshan_e_0_warning")
	while not akshan.swinging():
		await wait(0.05)
	await wait(1.1)
	var bolts := stage.get_node("Projectiles").get_children().filter(func(node: Node) -> bool: return node is EnemyProjectile)
	print("swinging (expect true): ", akshan.swinging(), "  bolts in the air: ", bolts.size())
	await shot("akshan_e_1_swing")


## Comeuppance: Lucian behind a pillar of the ring. The lock line follows
## him, then the burst hits the pillar, not him.
func scenario_akshan_r() -> void:
	# The ring's pillar at 18°, between Akshan (inside the ring) and Lucian.
	var pillar := TrainingGroundMap.pillars(3)[0]
	var akshan := await to_akshan(pillar + Vector2(130, 0))
	akshan.global_position = pillar - Vector2(470, 0)
	akshan.move_speed = 0.0
	akshan.hp = akshan.max_hp * 0.7
	akshan.health_bar.set_health(akshan.hp, akshan.max_hp)
	akshan._cooldowns[&"avengerang"] = 60.0
	akshan._cooldowns[&"heroic_swing"] = 60.0
	var hp_before := lucian.hp
	var warning := await wait_for_warning(GroundWarning.Shape.LOCK)
	await wait(1.0)
	print("lock line on Lucian (expect true): ", warning.follow == lucian, "  pillar at ", pillar)
	await shot("akshan_r_0_lock")
	await wait(1.15)
	await shot("akshan_r_1_burst")
	await wait(1.0)
	print("Lucian's HP after the burst (expect unchanged %d): %d" % [roundi(hp_before), roundi(lucian.hp)])


## Three melee minions around Lucian, low on HP.
func surround(hp: float) -> void:
	var game := game_stage()
	for offset: Vector2 in [Vector2(-150, -110), Vector2(160, -100), Vector2(10, 170)]:
		game.spawn_enemy(WavePlan.MELEE, lucian.global_position + offset)
		if game.runner:
			game.runner.enemy_spawned()
	lucian.hp = hp


## Lucian dies to minions in stage 2-1's second wave: grey and fading, then
## DEFEATED.
func scenario_defeat() -> void:
	var game := game_stage()
	await clear_wave()
	game.skip_break()
	surround(30.0)
	while not lucian.dead:
		await wait(0.05)
	await wait(0.6)
	print("dead (expect true), body tint (expect grey 0.55, fading): ", lucian.dead, " ", lucian.visuals.modulate)
	await shot("defeat_0_fading")
	await wait(1.2)
	var blue: int = game.collected[Essences.BLUE]
	print("result (expect DEFEATED): ", game.result.title.text, "  waves (expect 1 / 2): ", game.runner.waves_done(), " / ", game.runner.total_waves())
	print("blue kept in the save (expect %d): %d" % [blue, SaveGame.instance().essences.amount(Essences.BLUE)])
	print("buttons (expect Retry shown, Next hidden): ", game.result.retry_button.visible, " ", game.result.next_button.visible)
	await shot("defeat_1_result")
	paused = false


## A fragment and a legendary on the ground; with a full backpack, walking
## onto one says "Backpack full".
func scenario_loot() -> void:
	var game := game_stage()
	var catalog := lucian.item_catalog
	var legendaries := catalog.legendaries()
	for i in Inventory.BACKPACK_SIZE:
		lucian.inventory.add(legendaries[i % legendaries.size()])
	var fragment := catalog.find(&"bf_sword")
	game.drop_loot(fragment, lucian.global_position + Vector2(300, -60))
	game.drop_loot(catalog.find(&"infinity_edge"), lucian.global_position + Vector2(460, 80))
	await wait(0.3)
	await shot("loot_0_ground")
	var drops := stage.get_node("World").get_children().filter(func(node: Node) -> bool: return node is LootDrop)
	lucian.command_move(drops[0].global_position)
	await wait(1.2)
	var notes := stage.get_node("World").get_children().filter(func(node: Node) -> bool: return node is FloatingText)
	print("backpack space for a fragment (expect 0): ", lucian.inventory.space_for(fragment),
		"  drops left (expect 2): ", stage.get_node("World").get_children().filter(func(node: Node) -> bool: return node is LootDrop).size(),
		"  notes: ", notes.map(func(note: FloatingText) -> String: return note.text))
	await shot("loot_1_backpack_full")


## Guardian Angel: minions bring Lucian down; he is in gold stasis, then
## comes back with half his base HP.
func scenario_guardian_angel() -> void:
	lucian.inventory.put(Inventory.EQUIP_START, lucian.item_catalog.find(&"guardian_angel"))
	surround(25.0)
	while not lucian.in_stasis():
		await wait(0.05)
	await wait(0.6)
	print("in stasis (expect true), dead (expect false): ", lucian.in_stasis(), " ", lucian.dead,
		"  tint (expect gold %s): %s" % [Lucian.STASIS_TINT, lucian.visuals.modulate])
	await shot("guardian_angel_0_stasis")
	while lucian.in_stasis():
		await wait(0.02)
	print("revived: HP (expect 300, half his base HP, less any hits since), dead (expect false): ", roundi(lucian.hp), " ", lucian.dead)
	await wait(0.3)
	await shot("guardian_angel_1_revived")
