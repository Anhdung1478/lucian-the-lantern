extends GutTest

const PREFIX := "user://test_main_backdrop_save_slot_"

var main: MainScreen
var backdrop: MainBackdrop


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new(PREFIX)
	SaveGame.instance().reset()
	SaveGame.instance().slot = 1
	main = MainScreen.new()
	add_child_autofree(main)
	backdrop = main.backdrop


func test_the_scene_follows_the_section() -> void:
	assert_eq(backdrop.scene, MainBackdrop.Scene.GROVE, "the main screen opens on the Journey")
	main.show_section(MainScreen.SECTION_SKINS)
	assert_eq(backdrop.scene, MainBackdrop.Scene.GALLERY, "Skin Shop")
	main.show_section(MainScreen.SECTION_TREE)
	assert_eq(backdrop.scene, MainBackdrop.Scene.GROVE, "Evolution Tree")
	main.show_section(MainScreen.SECTION_SKINS)
	main.show_section(MainScreen.SECTION_JOURNEY)
	assert_eq(backdrop.scene, MainBackdrop.Scene.GROVE, "Journey")


func test_it_is_the_first_child_fills_the_screen_and_ignores_the_mouse() -> void:
	assert_eq(main.get_child(0), backdrop)
	assert_eq(backdrop.size, main.size)
	assert_eq(backdrop.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	var layers := backdrop.find_children("*", "Control", true, false)
	assert_gt(layers.size(), 0, "the motes layer")
	for layer: Control in layers:
		assert_eq(layer.mouse_filter, Control.MOUSE_FILTER_IGNORE, layer.name)


func test_the_gallery_arches_line_up_with_the_cards() -> void:
	main.show_section(MainScreen.SECTION_SKINS)
	# The shop's row is laid out by its containers.
	await wait_process_frames(2)
	var shop := main.sections[MainScreen.SECTION_SKINS] as SkinShop
	assert_eq(shop.cards.size(), Skins.ALL.size())
	for i in shop.cards.size():
		var card := shop.cards[i].get_global_rect()
		var slot := backdrop.card_rect(i)
		slot.position += backdrop.global_position
		var niche := backdrop.niche(i)
		niche.position += backdrop.global_position
		var id := shop.cards[i].skin.id
		assert_almost_eq(slot.get_center(), card.get_center(), Vector2.ONE, "%s's slot" % id)
		assert_almost_eq(niche.get_center().x, card.get_center().x, 1.0, "%s's arch is centred on it" % id)
		assert_lt(niche.position.y, card.position.y, "%s's arch rises over it" % id)
		assert_gte(niche.end.y, card.end.y, "%s's arch reaches the floor under it" % id)
		assert_eq(backdrop.arch_accent(i), MainBackdrop.accent(id), "%s's arch is lit in its accent" % id)


func test_every_skin_has_its_own_accent_and_others_fall_back() -> void:
	var seen: Array[Color] = []
	for skin in Skins.ALL:
		assert_true(MainBackdrop.ACCENTS.has(skin.id), skin.id)
		var color := MainBackdrop.accent(skin.id)
		assert_false(color in seen, "%s shares its accent" % skin.id)
		seen.append(color)
	assert_eq(MainBackdrop.accent(&"no_such_skin"), MainBackdrop.DEFAULT_ACCENT)


func test_it_draws_both_scenes_without_errors() -> void:
	# GUT fails the test on any engine or script error while drawing.
	await wait_process_frames(2)
	watch_signals(backdrop)
	watch_signals(backdrop.motes)
	for scene: MainBackdrop.Scene in [MainBackdrop.Scene.GALLERY, MainBackdrop.Scene.GROVE]:
		var drawn: int = get_signal_emit_count(backdrop, "draw")
		var moved: int = get_signal_emit_count(backdrop.motes, "draw")
		backdrop.scene = scene
		await wait_process_frames(2)
		assert_eq(get_signal_emit_count(backdrop, "draw"), drawn + 1, "scene %d drawn once" % scene)
		assert_gt(get_signal_emit_count(backdrop.motes, "draw"), moved, "motes, scene %d" % scene)


func test_only_the_motes_redraw_and_only_while_the_screen_shows() -> void:
	main.show_section(MainScreen.SECTION_SKINS)
	await wait_process_frames(2)
	watch_signals(backdrop)
	watch_signals(backdrop.motes)
	await wait_process_frames(4)
	assert_signal_emit_count(backdrop, "draw", 0, "the scene is drawn once")
	assert_gt(get_signal_emit_count(backdrop.motes, "draw"), 2, "the motes move")
	assert_true(backdrop.is_processing())
	main.visible = false
	assert_false(backdrop.is_processing(), "hidden")
	main.visible = true
	assert_true(backdrop.is_processing(), "shown again")
