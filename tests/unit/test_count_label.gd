extends GutTest
## CountLabel counts to a new value instead of jumping, lands at once while
## motion is off, keeps room for its widest text and can flash a gain or loss.

var _renders: bool


func before_each() -> void:
	_renders = UiMotion.renders


func after_each() -> void:
	UiMotion.renders = _renders


func _label() -> CountLabel:
	var label := CountLabel.new()
	add_child_autofree(label)
	return label


func test_off_every_value_lands_at_once() -> void:
	UiMotion.renders = false
	var label := _label()
	label.set_value(10)
	label.set_value(250)
	assert_eq(label.text, "250")
	assert_eq(label.value, 250)
	assert_eq(label.final_text(), "250")
	assert_false(label.is_counting())


func test_the_first_value_lands_at_once_then_it_counts() -> void:
	UiMotion.renders = true
	var label := _label()
	label.set_value(100)
	assert_eq(label.text, "100", "the first value")
	label.set_value(500)
	assert_eq(label.text, "100", "counts from the shown value")
	assert_eq(label.final_text(), "500")
	assert_true(label.is_counting())
	label._count.custom_step(0.1)
	var mid := label.shown
	assert_between(mid, 101, 499)
	label.set_value(200)
	assert_eq(label.shown, mid, "a new value carries on from the shown one")
	await wait_seconds(CountLabel.COUNT_MAX + 0.1)
	assert_eq(label.text, "200")


func test_instant_jumps() -> void:
	UiMotion.renders = true
	var label := _label()
	label.set_value(1)
	label.set_value(900, true)
	assert_eq(label.text, "900")


func test_format_and_formatter() -> void:
	UiMotion.renders = false
	var label := _label()
	label.format = "+%d blue essence"
	label.set_value(3)
	assert_eq(label.text, "+3 blue essence")
	label.formatter = func(v: int) -> String: return "%d / %d" % [v, 40]
	assert_eq(label.text, "3 / 40", "a new formatter shows at once")
	label.set_value(12)
	assert_eq(label.final_text(), "12 / 40")


func test_reserve_keeps_room_for_the_widest_text() -> void:
	var label := _label()
	label.reserve("99999")
	var wide := label.custom_minimum_size.x
	assert_gt(wide, 0.0)
	label.reserve("1")
	assert_eq(label.custom_minimum_size.x, wide, "never shrinks")


func test_flash_tints_a_gain_then_eases_back() -> void:
	UiMotion.renders = true
	var label := _label()
	label.add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR)
	label.flash = true
	label.set_value(10)
	label.set_value(20)
	assert_eq(label.get_theme_color(&"font_color"), UiStyle.GOOD_COLOR)
	await wait_seconds(CountLabel.FLASH_TIME + 0.1)
	assert_eq(label.get_theme_color(&"font_color"), UiStyle.GOLD_COLOR)
	label.set_value(5)
	assert_eq(label.get_theme_color(&"font_color"), UiStyle.BAD_COLOR, "a loss")


func test_flash_off_while_motion_is_off() -> void:
	UiMotion.renders = false
	var label := _label()
	label.flash = true
	label.set_value(10)
	label.set_value(20)
	assert_false(label.has_theme_color_override(&"font_color"))
