extends GutTest


func test_every_stat_has_icon_color_name_and_description() -> void:
	for key in StatStyle.KEYS:
		assert_not_null(StatStyle.icon(key), str(key))
		assert_ne(StatStyle.stat_name(key), "", str(key))
		assert_ne(StatStyle.description(key), "", str(key))
	for key: StringName in ItemStats.NAMES:
		assert_has(StatStyle.KEYS, key)


func test_item_line_is_icon_then_amount_then_name() -> void:
	var line := StatStyle.item_line(&"ad", 65.0)
	var icon_at := line.find("res://assets/art/stats/ad.svg")
	var amount_at := line.find("+65")
	var name_at := line.find("Attack Damage")
	assert_true(icon_at >= 0 and icon_at < amount_at and amount_at < name_at, line)
	assert_string_contains(line, StatStyle.color(&"ad").to_html(false))


func test_ap_is_dark_blue_everywhere() -> void:
	assert_eq(StatStyle.color(&"ap").to_html(false), TooltipText.COLORS["ap"])
