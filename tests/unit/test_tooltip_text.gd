extends GutTest


func test_colorize_turns_markup_into_bbcode() -> void:
	assert_eq(
		TooltipText.colorize("[ad]50 AD[/ad] and [magic]magic damage[/magic]"),
		"[color=#ff9a3c]50 AD[/color] and [color=#4fa8ff]magic damage[/color]")


func test_colorize_leaves_other_text_alone() -> void:
	assert_eq(TooltipText.colorize("plain text"), "plain text")


func test_ranked_highlights_current_rank() -> void:
	var text := TooltipText.ranked([80.0, 110.0, 140.0, 170.0, 200.0], 2)
	assert_eq(TooltipText.plain(text), "80/110/140/170/200")
	assert_string_contains(text, "[color=#%s]110[/color]" % TooltipText.BRIGHT)
	assert_string_contains(text, "[color=#%s]80[/color]" % TooltipText.DIM)


func test_ranked_without_rank_is_plain() -> void:
	assert_eq(TooltipText.ranked([80.0, 110.0, 140.0], 0), "80/110/140")


func test_ranked_single_value() -> void:
	assert_eq(TooltipText.plain(TooltipText.ranked([70.0], 3)), "70")


func test_ranked_keeps_decimals() -> void:
	assert_eq(TooltipText.plain(TooltipText.ranked([19.0, 17.75, 16.5], 1)), "19/17.75/16.5")


func test_ratio_shows_percent_and_stat_in_its_color() -> void:
	var text := TooltipText.ratio([0.6, 0.7, 0.8, 0.9, 1.0], 1, "AD")
	assert_eq(TooltipText.plain(text), "(+60/70/80/90/100% AD)")
	assert_true(text.begins_with("[color=#ff9a3c]"))
	assert_true(TooltipText.ratio([0.9], 1, "AP").begins_with("[color=#%s]" % TooltipText.COLORS["ap"]))


func test_plain_strips_tags() -> void:
	assert_eq(TooltipText.plain("[color=#fff]a[/color] [b]b[/b]"), "a b")
