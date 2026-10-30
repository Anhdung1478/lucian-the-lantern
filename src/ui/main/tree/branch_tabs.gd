class_name BranchTabs
extends HBoxContainer
## The Evolution Tree's branch tabs, a strip under the pages: Skills, Stats,
## Backpack, Economy and Summoners, each with its icon, name and levels bought
## ("3 / 19"). The tabs hang from the page's bottom edge; the chosen one is
## lit gold.

signal branch_chosen(branch: StringName)

const HEIGHT := 64.0
const TAB_HEIGHT := 56.0
const ICON_SIZE := 34.0
const NAME_FONT := 21
const COUNT_FONT := 17
const GAP := 12

## One tab per EvolutionTree.BRANCHES entry, in that order.
var buttons: Array[Button] = []
## Each tab's levels bought, "3 / 19".
var counts: Array[Label] = []
## The lit tab's branch.
var selected: StringName

var _names: Array[Label] = []


func _init() -> void:
	add_theme_constant_override(&"separation", GAP)
	for branch: StringName in EvolutionTree.BRANCHES:
		var button := Button.new()
		button.custom_minimum_size.y = TAB_HEIGHT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		button.pressed.connect(branch_chosen.emit.bind(branch))
		add_child(button)
		buttons.append(button)
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
		var title := UiStyle.label(TreePage.NAMES[branch], NAME_FONT)
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(title)
		_names.append(title)
		var count := UiStyle.label("", COUNT_FONT, UiStyle.DIM_COLOR)
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(count)
		counts.append(count)
	select(EvolutionTree.BRANCHES[0])


## Lights `branch`'s tab and dims the others. Does not emit.
func select(branch: StringName) -> void:
	selected = branch
	for i in buttons.size():
		var lit := EvolutionTree.BRANCHES[i] == branch
		UiStyle.style_button(buttons[i], NAME_FONT, lit)
		for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
			var style := buttons[i].get_theme_stylebox(state) as StyleBoxFlat
			style.border_width_top = 0
			style.corner_radius_top_left = 0
			style.corner_radius_top_right = 0
			style.corner_radius_bottom_left = 12
			style.corner_radius_bottom_right = 12
		_names[i].add_theme_color_override(&"font_color", UiStyle.TITLE_COLOR if lit else UiStyle.TEXT_COLOR)
		counts[i].add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR if lit else UiStyle.DIM_COLOR)


## Rereads each tab's levels bought.
func refresh(tree: EvolutionTree) -> void:
	for i in buttons.size():
		var bought := TreePage.levels(tree, EvolutionTree.BRANCHES[i])
		counts[i].text = "%d / %d" % [bought.x, bought.y]
