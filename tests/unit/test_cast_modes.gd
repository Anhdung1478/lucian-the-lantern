extends GutTest
## Cast modes per key: quick cast (on press), quick cast with indicator (hold
## to aim, release to cast) and normal cast (press to aim, left-click to cast).

const Slot := ChampionProgress.Slot
const EQUIP := Inventory.EQUIP_START

var lucian: Lucian
var controller: LucianController


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	# Trails, sparks and shots go here, so they are freed with the test.
	var effects := Node2D.new()
	add_child_autofree(effects)
	lucian.projectile_parent = effects
	add_child_autofree(lucian)
	controller = lucian.get_node("Controller")
	lucian.progress.set_level(3)
	lucian.try_rank_up(Slot.Q)
	lucian.try_rank_up(Slot.W)
	lucian.cheat_infinite_mana = true


func after_each() -> void:
	GameSettings.instance().set_value(&"cast_modes", {})
	for action in GameSettings.CASTABLE:
		Input.action_release(action)


func mode(action: StringName, cast_mode: String) -> void:
	GameSettings.instance().set_cast_mode(action, cast_mode)


func press(action: StringName, code: Key) -> void:
	Input.action_press(action)
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	controller._unhandled_input(event)


func click(button: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	controller._unhandled_input(event)


func q_cast() -> bool:
	return not lucian.skills[Slot.Q].cooldown.is_ready()


func test_quick_cast_is_the_default() -> void:
	press(&"skill_q", KEY_Q)
	assert_true(q_cast())
	assert_null(lucian.indicator.aimed)


func test_normal_cast_aims_on_press_and_casts_on_left_click() -> void:
	mode(&"skill_q", "normal")
	press(&"skill_q", KEY_Q)
	Input.action_release(&"skill_q")
	assert_false(q_cast(), "only aiming")
	assert_eq(controller.aiming(), &"skill_q")
	assert_not_null(lucian.indicator.aimed)
	await wait_process_frames(3)
	assert_eq(controller.aiming(), &"skill_q", "releasing the key doesn't cast")
	click(MOUSE_BUTTON_LEFT)
	assert_true(q_cast())
	assert_eq(controller.aiming(), &"")
	assert_null(lucian.indicator.aimed)


func test_normal_cast_right_click_cancels_without_moving() -> void:
	mode(&"skill_q", "normal")
	press(&"skill_q", KEY_Q)
	Input.action_press(&"move")
	click(MOUSE_BUTTON_RIGHT)
	Input.action_release(&"move")
	assert_eq(controller.aiming(), &"")
	await wait_seconds(0.2)
	assert_false(q_cast())
	assert_eq(lucian.global_position, Vector2.ZERO, "no move either")


func test_normal_cast_the_same_key_or_esc_cancels() -> void:
	mode(&"skill_q", "normal")
	press(&"skill_q", KEY_Q)
	Input.action_release(&"skill_q")
	press(&"skill_q", KEY_Q)
	assert_eq(controller.aiming(), &"")
	assert_false(q_cast())
	press(&"skill_q", KEY_Q)
	assert_true(controller.cancel_aim(), "ESC asks this first")
	assert_false(controller.cancel_aim(), "nothing left to cancel")
	assert_false(q_cast())


func test_another_key_takes_over_the_aim() -> void:
	mode(&"skill_q", "normal")
	mode(&"skill_w", "normal")
	press(&"skill_q", KEY_Q)
	press(&"skill_w", KEY_W)
	assert_eq(controller.aiming(), &"skill_w")
	click(MOUSE_BUTTON_LEFT)
	assert_false(q_cast())
	assert_false(lucian.skills[Slot.W].cooldown.is_ready())


func test_quick_cast_with_indicator_casts_on_release() -> void:
	mode(&"skill_q", "indicator")
	press(&"skill_q", KEY_Q)
	await wait_process_frames(3)
	assert_eq(controller.aiming(), &"skill_q", "held")
	assert_false(q_cast())
	Input.action_release(&"skill_q")
	await wait_process_frames(2)
	assert_true(q_cast())
	assert_null(lucian.indicator.aimed)


func test_a_skill_that_is_not_ready_is_not_aimed() -> void:
	mode(&"skill_q", "normal")
	lucian.skills[Slot.Q].cooldown.start(5.0)
	press(&"skill_q", KEY_Q)
	assert_eq(controller.aiming(), &"")
	mode(&"skill_e", "normal")
	press(&"skill_e", KEY_E)
	assert_eq(controller.aiming(), &"", "E isn't learned")


func test_items_and_summoners_aim_too() -> void:
	lucian.inventory.put(EQUIP, lucian.item_catalog.find(&"galeforce"))
	mode(&"item_1", "normal")
	press(&"item_1", KEY_1)
	assert_eq(lucian.indicator.aimed.reach, ItemActives.GALEFORCE_DASH)
	click(MOUSE_BUTTON_LEFT)
	assert_true(lucian.is_dashing())
	mode(&"summoner_d", "normal")
	press(&"summoner_d", KEY_D)
	assert_eq(lucian.indicator.aimed.reach, SummonerSpells.FLASH_RANGE)


func test_casts_without_aim_ignore_the_mode() -> void:
	mode(&"summoner_f", "normal")
	press(&"summoner_f", KEY_F)
	assert_eq(controller.aiming(), &"")
	assert_false(lucian.summoners.cooldown(&"heal").is_ready(), "Heal cast at once")


func test_pausing_drops_the_aim() -> void:
	mode(&"skill_q", "normal")
	press(&"skill_q", KEY_Q)
	controller._notification(Node.NOTIFICATION_PAUSED)
	assert_eq(controller.aiming(), &"")
	assert_null(lucian.indicator.aimed)


func test_r_pressed_while_firing_stops_it_in_any_mode() -> void:
	lucian.progress.set_level(6)
	lucian.try_rank_up(Slot.R)
	mode(&"skill_r", "normal")
	assert_true(lucian.try_cast(Slot.R, Vector2(1000, 0)))
	press(&"skill_r", KEY_R)
	assert_eq(controller.aiming(), &"")
	assert_false((lucian.skills[Slot.R] as TheCulling).is_channeling())


func test_esc_drops_the_aim_before_opening_the_menu() -> void:
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	add_child_autofree(stage)
	var stage_controller: LucianController = stage.lucian.get_node("Controller")
	stage.lucian.progress.set_level(1)
	stage.lucian.try_rank_up(Slot.Q)
	mode(&"skill_q", "normal")
	stage_controller._press_cast(&"skill_q")
	assert_eq(stage_controller.aiming(), &"skill_q")
	var esc := InputEventAction.new()
	esc.action = &"open_menu"
	esc.pressed = true
	stage.screens._input(esc)
	assert_eq(stage_controller.aiming(), &"")
	assert_false(stage.screens.menu.visible, "the menu stays closed")
	stage.screens._input(esc)
	assert_true(stage.screens.menu.visible, "a second ESC opens it")
	stage.screens.set_menu_open(false)
