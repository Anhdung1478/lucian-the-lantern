extends GutTest
## The tip banner's look: a plain plate with the flow screens' type, which
## keeps its own frame under the HUD, takes no mouse input and fits each tip.
## Its queue is tested with Act 1 (test_act1.gd).


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_tip_banner_save_slot_")


func _tips() -> TipBanner:
	var tips := TipBanner.new()
	add_child_autofree(tips)
	tips.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	tips.grow_horizontal = Control.GROW_DIRECTION_BOTH
	return tips


func test_it_is_a_plain_plate() -> void:
	var tips := _tips()
	assert_is(tips, Plate)
	assert_false(tips.ornate, "no inner line, no corner diamonds")
	assert_eq(tips.pad, TipBanner.PAD)


func test_its_text_is_in_the_flow_screens_type() -> void:
	var tips := _tips()
	assert_eq(tips.label.get_theme_font_size(&"font_size"), TipBanner.FONT)
	assert_eq(tips.label.get_theme_color(&"font_color"), UiStyle.TEXT_COLOR)
	assert_eq(tips.label.get_theme_stylebox(&"normal").content_margin_left, TipBanner.MARK_ROOM, "room for the diamond")


## A caller's panel (the HUD's, set before adding it) would be drawn under
## the plate: the plate's empty one comes back as it enters the tree.
func test_it_keeps_the_plates_frame_over_a_panel_given_before_it_is_added() -> void:
	var tips := TipBanner.new()
	tips.add_theme_stylebox_override(&"panel", UiStyle.panel())
	add_child_autofree(tips)
	var panel := tips.get_theme_stylebox(&"panel")
	assert_is(panel, StyleBoxEmpty)
	assert_eq(panel.content_margin_left, TipBanner.PAD)
	assert_eq(panel.content_margin_top, TipBanner.PAD)


func test_the_stages_tips_are_on_the_plate() -> void:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), 1, 1))
	add_child_autofree(stage)
	await wait_process_frames(2)
	var tips := stage.hud.tips
	assert_true(tips.visible, "the tutorial's first tip")
	assert_is(tips.get_theme_stylebox(&"panel"), StyleBoxEmpty)
	assert_gt(tips.size.x, tips.label.get_minimum_size().x, "the plate's padding around the text")


func test_it_takes_no_mouse_input() -> void:
	var tips := _tips()
	assert_eq(tips.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(tips.label.mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_it_shrinks_to_a_shorter_tip_around_the_same_center() -> void:
	var tips := _tips()
	tips.show_tip(&"long", "A long tip that takes a lot of room on the screen.")
	tips.show_tip(&"short", "A short tip.")
	tips._process(0.0)
	await wait_process_frames(1)
	var wide := tips.size.x
	var center := tips.get_global_rect().get_center().x
	tips._process(TipBanner.TIME)
	tips._process(0.0)
	await wait_process_frames(1)
	assert_eq(tips.label.text, "A short tip.")
	assert_lt(tips.size.x, wide)
	assert_almost_eq(tips.get_global_rect().get_center().x, center, 1.0)
