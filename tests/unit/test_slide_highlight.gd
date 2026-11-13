extends GutTest
## SlideHighlight paints the chosen tab's fill under a row of tabs, snaps the
## first time and while motion is off, and slides to a new choice otherwise.

var _renders: bool
var row: HBoxContainer
var tabs: Array[Button] = []


func before_each() -> void:
	_renders = UiMotion.renders
	row = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	add_child_autofree(row)
	tabs.clear()
	for i in 3:
		var tab := Button.new()
		tab.text = "Tab %d" % i
		tab.custom_minimum_size = Vector2(120, 40)
		row.add_child(tab)
		tabs.append(tab)
	await wait_process_frames(2)


func after_each() -> void:
	UiMotion.renders = _renders


func test_it_lives_in_the_bar_unseen_by_layout() -> void:
	var highlight := SlideHighlight.under(row)
	assert_eq(row.get_child_count(), 3, "internal: get_children() never lists it")
	assert_eq(highlight.get_parent(), row)


func test_the_first_follow_snaps() -> void:
	UiMotion.renders = true
	var highlight := SlideHighlight.under(row)
	highlight.follow(tabs[1])
	assert_eq(highlight.rect, tabs[1].get_rect())
	assert_false(highlight.is_sliding())


func test_it_slides_to_a_new_choice_and_retargets() -> void:
	UiMotion.renders = true
	var highlight := SlideHighlight.under(row)
	highlight.follow(tabs[0])
	highlight.follow(tabs[2])
	assert_true(highlight.is_sliding())
	highlight._slide.custom_step(UiMotion.BASE * 0.4)
	var x := highlight.rect.position.x
	assert_between(x, tabs[0].position.x + 1.0, tabs[2].position.x - 1.0)
	highlight.follow(tabs[1])
	assert_eq(highlight.rect.position.x, x, "from where it is")
	await wait_seconds(UiMotion.BASE + 0.1)
	assert_eq(highlight.rect, tabs[1].get_rect())


func test_off_it_snaps() -> void:
	UiMotion.renders = false
	var highlight := SlideHighlight.under(row)
	highlight.follow(tabs[0])
	highlight.follow(tabs[2])
	assert_eq(highlight.rect, tabs[2].get_rect())


func test_a_layout_change_snaps_it_onto_its_tab() -> void:
	UiMotion.renders = true
	var highlight := SlideHighlight.under(row)
	highlight.follow(tabs[1])
	tabs[0].custom_minimum_size.x = 200
	await wait_process_frames(2)
	assert_eq(highlight.rect, tabs[1].get_rect())


func test_clear_rest_makes_the_rest_box_clear() -> void:
	UiStyle.style_button(tabs[0])
	SlideHighlight.clear_rest(tabs[0])
	var rest := tabs[0].get_theme_stylebox(&"normal") as StyleBoxFlat
	assert_eq(rest.bg_color.a, 0.0)
	assert_eq(rest.border_color.a, 0.0)
	assert_eq((tabs[0].get_theme_stylebox(&"hover") as StyleBoxFlat).bg_color, UiStyle.button_style(&"hover").bg_color)


func test_no_track_unless_asked() -> void:
	var highlight := SlideHighlight.under(row)
	assert_eq(highlight.track_rect(), Rect2())


func test_the_track_hugs_the_tabs() -> void:
	var members: Array[Control] = []
	members.assign(tabs)
	var highlight := SlideHighlight.under(row, null, members)
	var want := tabs[0].get_rect().merge(tabs[2].get_rect()).grow(SlideHighlight.TRACK_PAD)
	assert_eq(highlight.track_rect(), want)
	highlight.follow(tabs[1])
	assert_eq(highlight.rect, tabs[1].get_rect(), "the fill still sits on its tab")
