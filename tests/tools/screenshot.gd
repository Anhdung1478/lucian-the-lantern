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


## Moves the real mouse to `canvas_pos` (1920x1080 canvas units), as if the
## player did it. `held` keeps the left button down during the motion.
func mouse_move(canvas_pos: Vector2, held := false) -> void:
	var window_pos := root.get_final_transform() * canvas_pos
	var event := InputEventMouseMotion.new()
	event.position = window_pos
	event.global_position = window_pos
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	Input.parse_input_event(event)
	await process_frame


func mouse_button(canvas_pos: Vector2, pressed: bool) -> void:
	var window_pos := root.get_final_transform() * canvas_pos
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
	await wait(0.6)
	await mouse_move(control_center(skill_row.get_child(1)) + Vector2(5, 3))
	await wait(0.6)
	print("Q tooltip after 1.2 s with a small move (expect true): ", stage.get_node("HoverTip").is_showing())
	await shot("tooltip_0_q")
	await mouse_move(control_center(skill_row.get_child(0)))
	await wait(1.2)
	await shot("tooltip_1_passive")
	await mouse_move(Vector2(960, 300))
	await wait(0.2)
	print("hidden after leaving (expect false): ", stage.get_node("HoverTip").is_showing())
	await press_key(KEY_ESCAPE, true)
	await press_key(KEY_ESCAPE, false)
	var menu: GameMenu = stage.get_node("Screens/Menu")
	var settings: Button = menu.find_children("*", "Button", true, false)[1]
	await mouse_move(control_center(settings))
	await wait(1.2)
	await shot("tooltip_2_disabled_button")
