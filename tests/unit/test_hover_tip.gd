extends GutTest
## HoverTip builds a shown card again, in place, when its source's
## tooltip_version() changes (a skill card's haste, a buff's time left, a
## stat's value), and only then.


class Source extends Control:
	var version := 0

	func tooltip_content() -> Control:
		return TooltipCard.note("version %d" % version)

	func tooltip_version() -> Variant:
		return version


var tip: HoverTip
var source: Source


func before_each() -> void:
	tip = HoverTip.new()
	add_child_autofree(tip)
	source = Source.new()
	add_child_autofree(source)


func test_a_shown_card_is_kept_while_its_version_holds() -> void:
	tip.show_for(source)
	var first := tip.card()
	assert_not_null(first)
	tip.refresh_card()
	tip.refresh_card()
	assert_same(tip.card(), first)


func test_a_new_version_builds_the_card_again_without_a_blink() -> void:
	tip.show_for(source)
	var first := tip.card()
	source.version = 1
	tip.refresh_card()
	var second := tip.card()
	assert_not_null(second)
	assert_ne(second, first, "a new card")
	assert_true(is_instance_valid(first) and not first.is_queued_for_deletion(), "the old card stays until the new one is placed")
	tip._position_card()
	assert_true(first.is_queued_for_deletion(), "then it goes")
	assert_eq(second.modulate.a, 1.0)
	tip.refresh_card()
	assert_same(tip.card(), second, "the same version again: no rebuild")


func test_a_source_without_a_version_is_never_rebuilt() -> void:
	var plain := Control.new()
	plain.set_meta(&"hover_text", "A note")
	add_child_autofree(plain)
	tip.show_for(plain)
	var first := tip.card()
	tip.refresh_card()
	assert_same(tip.card(), first)


## A buff row as Lucian.buffs() gives it.
func buff_row(id: StringName, name: String, left: float, text := "Raised stats.") -> Dictionary:
	return {"id": id, "name": name, "icon": null, "text": text, "count": "", "left": left,
		"duration": 10.0, "ready": false}


## Every line of text on a card, tags removed.
func card_text(card: Control) -> String:
	var parts: PackedStringArray = []
	for label: Label in card.find_children("*", "Label", true, false):
		parts.append(label.text)
	for rich: RichTextLabel in card.find_children("*", "RichTextLabel", true, false):
		parts.append(rich.get_parsed_text())
	return "\n".join(parts)


func test_a_buff_card_follows_the_buff_that_moves_into_its_icon() -> void:
	var bar := BuffBar.new()
	add_child_autofree(bar)
	bar.show_buffs([buff_row(&"red", "Crest of Cinders", 5.0), buff_row(&"hp_potion", "Health Potion", 8.0)])
	var icon := bar.get_child(0) as BuffIcon
	tip.show_for(icon)
	assert_string_contains(card_text(tip.card()), "Crest of Cinders")
	bar.show_buffs([buff_row(&"hp_potion", "Health Potion", 8.0)])
	tip.refresh_card()
	var text := card_text(tip.card())
	assert_string_contains(text, "Health Potion", "the potion's icon moved into the hovered spot")
	assert_false(text.contains("Crest of Cinders"), "not the buff that ran out")


func test_a_buff_card_counts_down_while_hovered() -> void:
	var icon := BuffIcon.new()
	add_child_autofree(icon)
	icon.buff = buff_row(&"red", "Crest of Cinders", 5.0)
	tip.show_for(icon)
	assert_string_contains(card_text(tip.card()), "5 s left")
	var first := tip.card()
	icon.buff = buff_row(&"red", "Crest of Cinders", 5.0)
	tip.refresh_card()
	assert_same(tip.card(), first, "the same row again: no rebuild")
	icon.buff = buff_row(&"red", "Crest of Cinders", 4.5)
	tip.refresh_card()
	assert_string_contains(card_text(tip.card()), "4.5 s left")
	icon.buff = buff_row(&"red", "Crest of Cinders", 4.5, "A shield that absorbs 80 damage.")
	tip.refresh_card()
	assert_string_contains(card_text(tip.card()), "80 damage", "its text, e.g. a shield's amount")


func test_a_stat_card_follows_the_shown_value() -> void:
	var cell := StatCell.new(&"ad")
	add_child_autofree(cell)
	cell.show_value("60", false, "60 base")
	tip.show_for(cell)
	var first := tip.card()
	assert_string_contains(card_text(first), "60")
	cell.show_value("60", false, "60 base")
	tip.refresh_card()
	assert_same(tip.card(), first, "the same value: no rebuild")
	cell.show_value("70", true, "60 base + 10 bonus")
	tip.refresh_card()
	var text := card_text(tip.card())
	assert_string_contains(text, "70")
	assert_string_contains(text, "10 bonus")
