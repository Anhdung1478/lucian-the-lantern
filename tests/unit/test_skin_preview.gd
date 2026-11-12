extends GutTest
## V1.1: the Skin Shop's Preview pop-up. Every card opens it for its skin;
## it plays Q, W, E, R and basic attacks with the skin's SkinFx at the
## skills' rank 1 numbers, loops ▶ All from the start, and ✕ or ESC closes
## it leaving nothing behind.

const Slot := ChampionProgress.Slot
const PREFIX := "user://test_skin_preview_save_slot_"

var shop: SkinShop
var _main: MainScreen


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save or settings.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new(PREFIX)
	if GameSettings._instance == null or GameSettings._instance.path == GameSettings.DEFAULT_PATH:
		GameSettings._instance = GameSettings.new("user://test_skin_preview_settings.json")
	SaveGame.instance().reset()
	shop = SkinShop.new()
	add_child_autofree(shop)


func after_each() -> void:
	GameSettings.instance().set_value(&"quality", "high")


func _card(id: StringName) -> SkinCard:
	for card in shop.cards:
		if card.skin.id == id:
			return card
	return null


func _open(id: StringName) -> SkinPreview:
	_card(id).preview_button.pressed.emit()
	return shop.preview


func _effects(preview: SkinPreview, type: Variant) -> Array:
	return preview.effects.get_children().filter(func(node: Node) -> bool:
		return is_instance_of(node, type) and not node.is_queued_for_deletion())


func _shots(preview: SkinPreview, kind: ShotLook.Kind) -> Array:
	return _effects(preview, LinearProjectile).filter(func(node: Node) -> bool:
		return (node as LinearProjectile).look.kind == kind)


func test_every_card_opens_the_preview_of_its_skin() -> void:
	for card in shop.cards:
		assert_eq(card.preview_button.text, "Preview")
		assert_false(card.preview_button.disabled)
		card.preview_button.pressed.emit()
		assert_eq(shop.preview.skin, card.skin, str(card.skin.id))
		assert_eq(shop.preview.lucian.texture, card.skin.body, str(card.skin.id))
		assert_true(shop.close_popup())


func test_a_skin_not_owned_can_be_previewed() -> void:
	assert_false(&"vampire" in SaveGame.instance().owned_skins)
	assert_not_null(_open(&"vampire"))


func test_opening_loops_all_starting_with_q() -> void:
	var preview := _open(&"high_noon")
	assert_eq(preview._tween.get_loops_left(), -1, "loops for ever")
	await wait_seconds(0.4)
	assert_eq(_effects(preview, HighNoonBeam).size(), 1)


func test_each_button_plays_its_piece_with_the_skin_effects() -> void:
	var preview := _open(&"high_noon")
	preview.buttons[&"w"].pressed.emit()
	assert_ne(preview._tween.get_loops_left(), -1, "▶ All stopped")
	await wait_seconds(0.3)
	var missiles := _shots(preview, ShotLook.Kind.MISSILE)
	assert_eq(missiles.size(), 1)
	assert_true(missiles[0].look is HighNoonShot)
	await wait_seconds(0.5)
	assert_eq(_effects(preview, HighNoonBlast).size(), 1, "the cross on the dummy")
	preview.buttons[&"e"].pressed.emit()
	await wait_seconds(0.1)
	assert_eq(_effects(preview, HighNoonTrail).size(), 1)
	assert_gt(preview.lucian.position.x, SkinPreview.LUCIAN_AT.x, "Lucian dashes")
	preview.buttons[&"r"].pressed.emit()
	assert_eq(preview.lucian.position, SkinPreview.LUCIAN_AT, "a new piece puts Lucian back")
	await wait_seconds(0.3)
	assert_gt(_shots(preview, ShotLook.Kind.BULLET).size(), 0)
	assert_gt(_effects(preview, HighNoonFlash).size(), 0)
	preview.buttons[&"attack"].pressed.emit()
	await wait_seconds(0.05)
	assert_eq(_shots(preview, ShotLook.Kind.BOLT).size(), 1)
	preview.buttons[&"all"].pressed.emit()
	assert_eq(preview._tween.get_loops_left(), -1)


func test_the_cross_lands_on_the_dummy() -> void:
	var preview := _open(&"classic")
	preview.play(&"w")
	await wait_seconds(0.8)
	var blasts := _effects(preview, ClassicBlast)
	assert_eq(blasts.size(), 1)
	# A missile stops on the frame it runs out of range: up to one frame's
	# travel (1600 px/s) past the dummy.
	assert_almost_eq((blasts[0] as Node2D).position.x, SkinPreview.DUMMY_AT.x, 30.0)


func test_close_and_esc_close_it_and_free_everything() -> void:
	var preview := _open(&"pulsefire")
	await wait_seconds(0.4)
	preview.close_button.pressed.emit()
	assert_null(shop.preview)
	await wait_process_frames(2)
	assert_false(is_instance_valid(preview))
	assert_false(shop.close_popup(), "nothing left to close")
	preview = _open(&"pulsefire")
	assert_true(shop.close_popup(), "ESC closes it")
	await wait_process_frames(2)
	assert_false(is_instance_valid(preview))
	assert_eq(shop.get_children().filter(func(node: Node) -> bool: return node is SkinPreview).size(), 0)


func test_opening_another_preview_closes_the_first() -> void:
	var first := _open(&"vampire")
	var second := _open(&"project")
	await wait_process_frames(2)
	assert_false(is_instance_valid(first))
	assert_eq(shop.preview, second)


func test_on_low_effects_e_makes_no_trail_but_still_dashes() -> void:
	GameSettings.instance().set_value(&"quality", "low")
	var preview := _open(&"vampire")
	preview.play(&"e")
	await wait_seconds(0.1)
	assert_eq(_effects(preview, DashTrail).size(), 0)
	assert_gt(preview.lucian.position.x, SkinPreview.LUCIAN_AT.x)


func test_preview_numbers_are_the_skills_rank_1_numbers() -> void:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	var q := lucian.skills[Slot.Q] as PiercingLight
	assert_eq([SkinPreview.Q_CAST, SkinPreview.Q_WIDTH], [q.cast_time, q.width])
	var w := lucian.skills[Slot.W] as ArdentBlaze
	assert_eq([SkinPreview.W_CAST, SkinPreview.W_SPEED, SkinPreview.W_BAR], [w.cast_time, w.missile_speed, w.bar_size])
	var e := lucian.skills[Slot.E] as RelentlessPursuit
	assert_eq([SkinPreview.E_DISTANCE, SkinPreview.E_SPEED], [e.max_distance, e.dash_speed])
	var r := lucian.skills[Slot.R] as TheCulling
	assert_eq([SkinPreview.R_SHOTS, SkinPreview.R_DURATION, SkinPreview.R_SPEED], [r.shots, r.duration, r.bullet_speed])
	assert_eq(SkinPreview.MUZZLES[0], (lucian.get_node("Visuals/MuzzleLeft") as Marker2D).position)
	assert_eq(SkinPreview.MUZZLES[1], (lucian.get_node("Visuals/MuzzleRight") as Marker2D).position)


func test_hiding_the_shop_closes_the_preview() -> void:
	var preview := _open(&"project")
	shop.visible = false
	assert_null(shop.preview)
	await wait_process_frames(2)
	assert_false(is_instance_valid(preview))


func test_closing_twice_emits_closed_once_and_keeps_the_next_preview() -> void:
	var first := _open(&"vampire")
	var closes: Array[int] = [0]
	first.closed.connect(func() -> void: closes[0] += 1)
	first.close()
	var second := _open(&"project")
	first.close()
	assert_eq(closes[0], 1, "closed emitted once")
	assert_eq(shop.preview, second, "the new preview is still the shop's")


## A main screen on the Skin Shop with `id`'s preview open.
func _open_in_main(id: StringName) -> SkinPreview:
	var main := MainScreen.new()
	add_child_autofree(main)
	main.show_section(MainScreen.SECTION_SKINS)
	var skin_shop: SkinShop = main.sections[MainScreen.SECTION_SKINS]
	skin_shop.open_preview(id)
	_main = main
	return skin_shop.preview


func test_the_gear_menu_over_the_preview_freezes_it_and_closing_resumes_it() -> void:
	var preview := _open_in_main(&"pulsefire")
	var spawned: Array[int] = [0]
	preview.effects.child_entered_tree.connect(func(_node: Node) -> void: spawned[0] += 1)
	await wait_seconds(0.2)
	_main.gear.open()
	assert_eq(preview.process_mode, Node.PROCESS_MODE_DISABLED)
	var before := spawned[0]
	await wait_seconds(1.5)
	assert_eq(spawned[0], before, "no new effects while covered")
	_main.gear.close()
	assert_eq(preview.process_mode, Node.PROCESS_MODE_INHERIT)
	await wait_seconds(1.5)
	assert_gt(spawned[0], before, "it plays on again")


func test_settings_and_a_pop_up_freeze_the_preview_too() -> void:
	var preview := _open_in_main(&"project")
	_main.settings.open()
	assert_eq(preview.process_mode, Node.PROCESS_MODE_DISABLED, "Settings")
	_main.settings.close()
	assert_eq(preview.process_mode, Node.PROCESS_MODE_INHERIT)
	_main.confirm.ask("Sure?", func() -> void: pass)
	assert_eq(preview.process_mode, Node.PROCESS_MODE_DISABLED, "a pop-up")
	_main.confirm.answer(false)
	assert_eq(preview.process_mode, Node.PROCESS_MODE_INHERIT)


func test_a_preview_opened_under_the_gear_menu_starts_frozen() -> void:
	var preview := _open_in_main(&"vampire")
	_main.gear.open()
	_main.sections[MainScreen.SECTION_SKINS].open_preview(&"project")
	assert_eq(_main.sections[MainScreen.SECTION_SKINS].preview.process_mode, Node.PROCESS_MODE_DISABLED)
