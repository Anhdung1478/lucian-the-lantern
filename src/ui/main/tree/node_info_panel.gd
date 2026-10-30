class_name NodeInfoPanel
extends PanelContainer
## The chosen node, bottom-right of the Evolution Tree: its name, "LVL 2 / 5",
## its value now and at the next level, what it does and the CostBar that
## buys it. A hidden node reads "???"; a closed next level says what it needs.

const WIDTH := 440.0

## The node shown, &"" before one is chosen.
var id: StringName
var tree: EvolutionTree
var name_label: Label
var level_label: Label
## "+8 AD → +12 AD"; only the value, in green, once maxed.
var value_label: Label
var description: RichTextLabel
## "Requires: …", shown while the next level is closed.
var requires_label: Label
var cost_bar: CostBar


func _init(evolution_tree: EvolutionTree, essences: Essences) -> void:
	tree = evolution_tree
	custom_minimum_size.x = WIDTH
	# Opaque: the nodes and lines under it must not show through.
	add_theme_stylebox_override(&"panel", UiStyle.panel(Color(UiStyle.PANEL_COLOR, 1.0), UiStyle.BORDER_COLOR, 2, 20.0))
	visible = false
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	add_child(column)
	name_label = UiStyle.label("", 26, UiStyle.TITLE_COLOR)
	column.add_child(name_label)
	level_label = UiStyle.label("", 18, UiStyle.GOLD_COLOR)
	column.add_child(level_label)
	value_label = UiStyle.label("", 22)
	column.add_child(value_label)
	description = RichTextLabel.new()
	description.bbcode_enabled = true
	description.fit_content = true
	description.scroll_active = false
	description.add_theme_font_size_override(&"normal_font_size", 18)
	description.add_theme_color_override(&"default_color", UiStyle.TEXT_COLOR)
	column.add_child(description)
	requires_label = UiStyle.label("", 18, UiStyle.ERROR_COLOR)
	requires_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(requires_label)
	cost_bar = CostBar.new(tree, essences)
	cost_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(cost_bar)


## Shows node `node_id` and opens the panel.
func show_node(node_id: StringName) -> void:
	id = node_id
	cost_bar.show_node(id)
	refresh()
	visible = true


## Rereads the shown node from the tree.
func refresh() -> void:
	if id == &"":
		return
	var data := tree.node(id)
	var level := tree.level(id)
	var hidden := TreeNodeView.is_hidden(tree, id)
	name_label.text = "???" if hidden else data.display_name
	level_label.text = "LVL %d / %d" % [level, data.max_level]
	if tree.is_maxed(id):
		value_label.text = data.value_text(level)
		value_label.add_theme_color_override(&"font_color", TreeNodeView.MAXED_COLOR)
	else:
		value_label.text = "%s → %s" % [data.value_text(level), data.value_text(level + 1)]
		value_label.add_theme_color_override(&"font_color", UiStyle.TEXT_COLOR)
	description.text = TooltipText.colorize(data.description)
	var needs := tree.next_requirement_text(id)
	requires_label.visible = needs != ""
	requires_label.text = needs
	cost_bar.refresh()
