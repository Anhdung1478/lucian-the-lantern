extends GutTest
## HoverTip builds a shown card again, in place, when its source's
## tooltip_version() changes (a skill card's haste), and only then.


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
