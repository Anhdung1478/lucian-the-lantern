class_name BranchTabs
extends HBoxContainer
## The Evolution Tree's branch switch, over the top of the page inside its
## frame: Skills, Stats, Backpack, Economy and Summoners as a row of Lantern
## headings, each its name in spaced capitals and its levels bought ("3/19"),
## with a FREE pill while the branch has a free upgrade. The lit one is the
## page's title (pale gold); a gold rule under it slides to the next one
## (SlideHighlight). No boxes and no fills: lighter than the section bar.
## The names ease between dim, hovered and lit; the counts count.

signal branch_chosen(branch: StringName)

const HEIGHT := 50.0
const NAME_FONT := 20
const COUNT_FONT := 16
## Between two items, and inside one (name, count, pill).
const GAP := 44
const INNER_GAP := 10
const SPACING := 3
## The rule under the lit item.
const RULE_WIDTH := 2

## One item per EvolutionTree.BRANCHES entry, in that order.
var buttons: Array[Button] = []
## Each item's levels bought, "3/19".
var counts: Array[CountLabel] = []
## The gold rule under the lit item, sliding between them.
var highlight: SlideHighlight
## The lit item's branch.
var selected: StringName
## Each item's FREE pill, shown while its branch has a free upgrade.
var free_badges: Array[FreeBadge] = []

var _names: Array[Label] = []
var _rows: Array[HBoxContainer] = []
var _hovered := {}
var _tints := {}


func _init() -> void:
	add_theme_constant_override(&"separation", GAP)
	var rule := StyleBoxFlat.new()
	rule.bg_color = Color(0, 0, 0, 0)
	rule.border_color = UiStyle.GOLD_COLOR
	rule.border_width_bottom = RULE_WIDTH
	highlight = SlideHighlight.under(self, rule)
	for branch: StringName in EvolutionTree.BRANCHES:
		var button := Button.new()
		button.custom_minimum_size.y = HEIGHT
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		for state: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		UiStyle.add_click(button)
		button.pressed.connect(branch_chosen.emit.bind(branch))
		button.mouse_entered.connect(_hover.bind(button, true))
		button.mouse_exited.connect(_hover.bind(button, false))
		add_child(button)
		buttons.append(button)
		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.add_theme_constant_override(&"separation", INNER_GAP)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.minimum_size_changed.connect(_fit.bind(button, row))
		button.add_child(row)
		_rows.append(row)
		var title := UiStyle.label(Lang.t(TreePage.NAMES[branch]), NAME_FONT, UiStyle.DIM_COLOR)
		title.uppercase = true
		title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(title)
		_names.append(title)
		var count := CountLabel.new()
		count.add_theme_font_size_override(&"font_size", COUNT_FONT)
		count.add_theme_color_override(&"font_color", UiStyle.DIM_COLOR)
		count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(count)
		counts.append(count)
		var free := FreeBadge.new()
		free.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		free.visible = false
		row.add_child(free)
		free_badges.append(free)
	select(EvolutionTree.BRANCHES[0])


func _ready() -> void:
	# The capitals spread out; the label's font is only known in the tree.
	for title in _names:
		var spaced := FontVariation.new()
		spaced.base_font = title.get_theme_font(&"font")
		spaced.spacing_glyph = SPACING
		title.add_theme_font_override(&"font", spaced)
	for i in buttons.size():
		_fit(buttons[i], _rows[i])


## Lights `branch`'s item and dims the others: the rule slides to it and the
## names and counts ease. Does not emit.
func select(branch: StringName) -> void:
	selected = branch
	for i in buttons.size():
		_retint(i)
	highlight.follow(buttons[EvolutionTree.BRANCHES.find(branch)])


## Rereads each item's levels bought and FREE pill.
func refresh(tree: EvolutionTree) -> void:
	for i in buttons.size():
		var bought := TreePage.levels(tree, EvolutionTree.BRANCHES[i])
		counts[i].formatter = func(v: int) -> String: return "%d/%d" % [v, bought.y]
		counts[i].set_value(bought.x)
		free_badges[i].visible = tree.has_free(EvolutionTree.BRANCHES[i])


## The row's width (the button takes it).
func _fit(button: Button, row: HBoxContainer) -> void:
	button.custom_minimum_size.x = row.get_combined_minimum_size().x


func _hover(button: Button, on: bool) -> void:
	_hovered[button] = on
	_retint(buttons.find(button))


func _retint(i: int) -> void:
	var lit := EvolutionTree.BRANCHES[i] == selected
	var hovered: bool = _hovered.get(buttons[i], false)
	_tint(_names[i], UiStyle.TITLE_COLOR if lit else (UiStyle.TEXT_COLOR if hovered else UiStyle.DIM_COLOR))
	_tint(counts[i], UiStyle.GOLD_COLOR if lit else UiStyle.DIM_COLOR)


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
