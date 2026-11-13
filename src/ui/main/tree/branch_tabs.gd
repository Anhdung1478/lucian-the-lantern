class_name BranchTabs
extends HBoxContainer
## The Evolution Tree's branch tabs, a strip under the pages: Skills, Stats,
## Backpack, Economy and Summoners, each with its icon, name and levels bought
## ("3 / 19"). The tabs hang from the page's bottom edge; the chosen one is
## lit gold by a highlight that slides from tab to tab (SlideHighlight), its
## name and count easing to gold. The counts count as levels are bought.

signal branch_chosen(branch: StringName)

const HEIGHT := 64.0
const TAB_HEIGHT := 56.0
const ICON_SIZE := 34.0
const NAME_FONT := 21
const COUNT_FONT := 17
const GAP := 12
## The FREE badge's distance from a tab's top-right corner; it straddles the tab's top edge.
const BADGE_MARGIN := Vector2(8, -10)

## One tab per EvolutionTree.BRANCHES entry, in that order.
var buttons: Array[Button] = []
## Each tab's levels bought, "3 / 19".
var counts: Array[CountLabel] = []
## The chosen tab's fill, sliding between tabs.
var highlight: SlideHighlight
## The lit tab's branch.
var selected: StringName

## Each tab's FREE badge, shown while its branch has a free upgrade.
var free_badges: Array[FreeBadge] = []

var _names: Array[Label] = []
var _tints := {}


func _init() -> void:
	add_theme_constant_override(&"separation", GAP)
	var lit_box := UiStyle.button_style(&"normal", true)
	_shape(lit_box)
	highlight = SlideHighlight.under(self, lit_box)
	for branch: StringName in EvolutionTree.BRANCHES:
		var button := Button.new()
		button.custom_minimum_size.y = TAB_HEIGHT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		button.pressed.connect(branch_chosen.emit.bind(branch))
		add_child(button)
		buttons.append(button)
		UiStyle.style_button(button, NAME_FONT)
		for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
			_shape(button.get_theme_stylebox(state) as StyleBoxFlat)
		# An unchosen tab keeps its own rest box; the chosen one's turns clear
		# so the highlight under it shows (select()).
		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override(&"separation", 10)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(row)
		var icon := TextureRect.new()
		icon.texture = TreePage.ICONS[branch]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2.ONE * ICON_SIZE
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var title := UiStyle.label(Lang.t(TreePage.NAMES[branch]), NAME_FONT)
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(title)
		_names.append(title)
		var count := CountLabel.new()
		count.add_theme_font_size_override(&"font_size", COUNT_FONT)
		count.add_theme_color_override(&"font_color", UiStyle.DIM_COLOR)
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(count)
		counts.append(count)
		var free := FreeBadge.new()
		free.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		free.offset_left = -FreeBadge.SIZE.x - BADGE_MARGIN.x
		free.offset_right = -BADGE_MARGIN.x
		free.offset_top = BADGE_MARGIN.y
		free.offset_bottom = BADGE_MARGIN.y + FreeBadge.SIZE.y
		free.visible = false
		button.add_child(free)
		free_badges.append(free)
	select(EvolutionTree.BRANCHES[0])


## Lights `branch`'s tab and dims the others: the highlight slides to it
## and the names and counts ease. Does not emit.
func select(branch: StringName) -> void:
	selected = branch
	for i in buttons.size():
		var lit := EvolutionTree.BRANCHES[i] == branch
		UiStyle.set_selected(buttons[i], lit, not lit)
		_tint(_names[i], UiStyle.TITLE_COLOR if lit else UiStyle.TEXT_COLOR)
		_tint(counts[i], UiStyle.GOLD_COLOR if lit else UiStyle.DIM_COLOR)
	highlight.follow(buttons[EvolutionTree.BRANCHES.find(branch)])


## Rereads each tab's levels bought.
func refresh(tree: EvolutionTree) -> void:
	for i in buttons.size():
		var bought := TreePage.levels(tree, EvolutionTree.BRANCHES[i])
		counts[i].formatter = func(v: int) -> String: return "%d / %d" % [v, bought.y]
		counts[i].set_value(bought.x)
		free_badges[i].visible = tree.has_free(EvolutionTree.BRANCHES[i])


## A tab's box: hanging from the page, so no top rim and round at the foot.
static func _shape(style: StyleBoxFlat) -> void:
	style.border_width_top = 0
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12


## Eases `label`'s font colour to `color` over UiMotion.FAST.
func _tint(label: Label, color: Color) -> void:
	var running: Tween = _tints.get(label)
	if running and running.is_valid():
		running.kill()
	var from := label.get_theme_color(&"font_color")
	if UiMotion.off() or not is_inside_tree() or from == color:
		label.add_theme_color_override(&"font_color", color)
		return
	var tint := UiMotion.tween(label)
	tint.tween_method(func(c: Color) -> void: label.add_theme_color_override(&"font_color", c), from, color, UiMotion.FAST)
	_tints[label] = tint
