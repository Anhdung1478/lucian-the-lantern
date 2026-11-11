extends GutTest
## ScreenFade: opaque on a change, clear after, never in the way of the mouse,
## off on Low quality and headless.

var fade: ScreenFade
var _renders := false


func before_each() -> void:
	_renders = Juice.renders
	Juice.renders = true
	fade = ScreenFade.new()
	add_child_autofree(fade)


func after_each() -> void:
	Juice.renders = _renders
	GameSettings.instance().set_value(&"quality", "high", false)


func test_it_starts_clear_and_ignores_the_mouse() -> void:
	assert_eq(fade.cover.modulate.a, 0.0)
	assert_eq(fade.cover.mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_a_change_covers_the_screen_then_clears_it() -> void:
	fade.play()
	assert_eq(fade.cover.modulate.a, 1.0)
	await wait_seconds(ScreenFade.FADE_IN + 0.15)
	assert_eq(fade.cover.modulate.a, 0.0)
	assert_eq(fade.cover.mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_a_second_change_during_a_fade_still_ends_clear() -> void:
	fade.play()
	await wait_seconds(0.1)
	fade.play()
	assert_eq(fade.cover.modulate.a, 1.0)
	await wait_seconds(ScreenFade.FADE_IN + 0.15)
	assert_eq(fade.cover.modulate.a, 0.0)


func test_it_does_nothing_headless() -> void:
	Juice.renders = false
	fade.play()
	assert_eq(fade.cover.modulate.a, 0.0)


func test_it_does_nothing_on_low_quality() -> void:
	GameSettings.instance().set_value(&"quality", "low", false)
	fade.play()
	assert_eq(fade.cover.modulate.a, 0.0)


func test_it_runs_while_the_tree_is_paused() -> void:
	assert_eq(fade.process_mode, Node.PROCESS_MODE_ALWAYS)
