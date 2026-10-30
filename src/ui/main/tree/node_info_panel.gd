class_name NodeInfoPanel
extends PanelContainer
## The Evolution Tree's info column, right of the pages and always shown, in
## the Journey panel's look.
## - Nothing picked: the branch shown, its name, blurb, levels bought, "Pick a
##   node" and a row per node (icon, name, level; a click picks it).
## - A node picked: its branch, name and icon, "LVL 2 / 5", its value now and
##   at the next level, what it does, R's "Q + W + E ranks: 7 / 9", what its
##   next level still needs, a row per level (value and cost; bought ones lit,
##   the next one framed) and the CostBar that buys it, at the bottom. A
##   hidden node reads "???".

## A row of the branch's node list was clicked.
signal node_chosen(id: StringName)

const PORTRAIT_SIZE := 96.0
const PROGRESS_HEIGHT := 10.0
const ROW_GAP := 12
## The branch's node list: a row's height, its icon and fonts.
const LIST_ROW := Vector2(400, 34)
const LIST_GAP := 4
const LIST_ICON := 28.0
const LIST_FONT := 18
## The picked node's level ladder: a row's height and fonts.
const LADDER_ROW := 30.0
const LADDER_FONT := 18
const COST_ICON := 20.0

## The node shown, &"" with nothing picked.
var id: StringName
## The branch summed up with nothing picked (the picked node's otherwise).
var branch: StringName = EvolutionTree.BRANCHES[0]
var tree: EvolutionTree
var essences: Essences
## The branch ("SKILLS") over a picked node; "EVOLUTION TREE" over a branch.
var caption_label: Label
## The branch's or the node's name.
var name_label: Label
var blurb_label: Label
## "Levels bought 3 / 19".
var levels_label: Label
## "Pick a node".
var hint_label: Label
## The branch's node list: node id -> its row.
var rows := {}
var level_label: Label
## "+8 AD → +12 AD"; only the value, in green, once maxed.
var value_label: Label
var description: RichTextLabel
## R's "Q + W + E ranks: 7 / 9"; shown for a node with a level sum.
var sum_label: Label
## "Requires: …", shown while the next level is closed.
var requires_label: Label
## One row per level of the picked node: "Lv 2", its value, its blue and
## orange cost.
var ladder := VBoxContainer.new()
var cost_bar: CostBar

var _branch_box := VBoxContainer.new()
var _list := VBoxContainer.new()
## The branch the list was built for.
var _list_branch: StringName
## The node the ladder was built for.
var _ladder_id: StringName
var _node_box := VBoxContainer.new()
var _portrait := Control.new()
var _progress := Control.new()
var _top_glow: GradientTexture2D


func _init(evolution_tree: EvolutionTree, owned: Essences) -> void:
	tree = evolution_tree
	essences = owned
	custom_minimum_size = JourneyPanel.SIZE
	size = JourneyPanel.SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Opaque, with the Journey panel's frame: rounded on the right only.
	var style := UiStyle.panel(JourneyPanel.BACKGROUND, UiStyle.BORDER_COLOR, 2, JourneyPanel.PAD, 0)
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_top = JourneyPanel.PAD + 4.0
	add_theme_stylebox_override(&"panel", style)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	_top_glow = GradientTexture2D.new()
	_top_glow.gradient = gradient
	_top_glow.fill = GradientTexture2D.FILL_RADIAL
	_top_glow.fill_from = Vector2(0.5, 0.0)
	_top_glow.fill_to = Vector2(0.5, 1.0)

	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", ROW_GAP)
	add_child(column)
	caption_label = UiStyle.label("", 16, JourneyPanel.CAPTION_COLOR)
	column.add_child(caption_label)
	name_label = _wrapped(UiStyle.label("", 34, UiStyle.TITLE_COLOR))
	column.add_child(name_label)
	column.add_child(JourneyPanel.divider())

	_branch_box.add_theme_constant_override(&"separation", ROW_GAP)
	column.add_child(_branch_box)
	blurb_label = _wrapped(UiStyle.label("", 20, UiStyle.TEXT_COLOR))
	_branch_box.add_child(blurb_label)
	levels_label = UiStyle.label("", 22, UiStyle.GOLD_COLOR)
	_branch_box.add_child(levels_label)
	_progress.custom_minimum_size = Vector2(JourneyPanel.CONTENT_WIDTH, PROGRESS_HEIGHT)
	_progress.draw.connect(_draw_progress)
	_branch_box.add_child(_progress)
	_branch_box.add_child(JourneyPanel.divider())
	hint_label = UiStyle.label("Pick a node", 18, UiStyle.DIM_COLOR)
	_branch_box.add_child(hint_label)
	_list.add_theme_constant_override(&"separation", LIST_GAP)
	_branch_box.add_child(_list)

	_node_box.add_theme_constant_override(&"separation", ROW_GAP)
	column.add_child(_node_box)
	var top := HBoxContainer.new()
	top.add_theme_constant_override(&"separation", 18)
	_node_box.add_child(top)
	_portrait.custom_minimum_size = Vector2.ONE * PORTRAIT_SIZE
	_portrait.draw.connect(_draw_portrait)
	top.add_child(_portrait)
	var levels := VBoxContainer.new()
	levels.alignment = BoxContainer.ALIGNMENT_CENTER
	levels.add_theme_constant_override(&"separation", 6)
	levels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(levels)
	level_label = UiStyle.label("", 20, UiStyle.GOLD_COLOR)
	levels.add_child(level_label)
	value_label = UiStyle.label("", 22)
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	levels.add_child(value_label)
	description = RichTextLabel.new()
	description.bbcode_enabled = true
	description.fit_content = true
	description.scroll_active = false
	description.custom_minimum_size.x = JourneyPanel.CONTENT_WIDTH
	description.add_theme_font_size_override(&"normal_font_size", 19)
	description.add_theme_color_override(&"default_color", UiStyle.TEXT_COLOR)
	_node_box.add_child(description)
	sum_label = UiStyle.label("", 20, UiStyle.TITLE_COLOR)
	_node_box.add_child(sum_label)
	requires_label = _wrapped(UiStyle.label("", 19, UiStyle.ERROR_COLOR))
	_node_box.add_child(requires_label)
	_node_box.add_child(JourneyPanel.divider())
	_node_box.add_child(UiStyle.label("LEVELS", 16, JourneyPanel.CAPTION_COLOR))
	ladder.add_theme_constant_override(&"separation", 4)
	_node_box.add_child(ladder)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(spacer)
	cost_bar = CostBar.new(tree, essences)
	cost_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(cost_bar)
	refresh()


## Sums up `branch_id` with nothing picked.
func show_branch(branch_id: StringName) -> void:
	branch = branch_id
	id = &""
	refresh()


## Shows node `node_id` (and its branch).
func show_node(node_id: StringName) -> void:
	id = node_id
	branch = tree.node(id).branch
	cost_bar.show_node(id)
	refresh()


## Rereads the branch or the node from the tree.
func refresh() -> void:
	var picked := id != &""
	_branch_box.visible = not picked
	_node_box.visible = picked
	cost_bar.visible = picked
	if picked:
		_show_node()
	else:
		var bought := TreePage.levels(tree, branch)
		caption_label.text = "EVOLUTION TREE"
		name_label.text = TreePage.NAMES[branch]
		blurb_label.text = TreePage.BLURBS[branch]
		levels_label.text = "Levels bought %d / %d" % [bought.x, bought.y]
		_progress.queue_redraw()
		_fill_list()
	queue_redraw()


func _show_node() -> void:
	var data := tree.node(id)
	var level := tree.level(id)
	var hidden := TreeNodeView.is_hidden(tree, id)
	caption_label.text = String(TreePage.NAMES[branch]).to_upper()
	name_label.text = "???" if hidden else data.display_name
	level_label.text = "LVL %d / %d" % [level, data.max_level]
	if tree.is_maxed(id):
		value_label.text = data.value_text(level)
		value_label.add_theme_color_override(&"font_color", TreeNodeView.MAXED_COLOR)
	else:
		value_label.text = "%s → %s" % [data.value_text(level), data.value_text(level + 1)]
		value_label.add_theme_color_override(&"font_color", UiStyle.TEXT_COLOR)
	description.text = TooltipText.colorize(data.description)
	sum_label.visible = not data.level_sum_ids.is_empty()
	if sum_label.visible:
		var names: PackedStringArray = []
		for summed in data.level_sum_ids:
			names.append(tree.node(summed).short_name())
		sum_label.text = "%s ranks: %d" % [" + ".join(names), tree.level_sum(id)]
		if not tree.is_maxed(id):
			sum_label.text += " / %d" % data.sum_needed(level)
	var needs := tree.next_requirement_text(id)
	requires_label.visible = needs != ""
	requires_label.text = needs
	_fill_ladder()
	cost_bar.refresh()
	_portrait.queue_redraw()


## The picked node's levels: built when the node changes, recoloured every
## time (bought, next, later).
func _fill_ladder() -> void:
	var data := tree.node(id)
	if _ladder_id != id:
		_ladder_id = id
		for child in ladder.get_children():
			ladder.remove_child(child)
			child.free()
		for i in data.max_level:
			ladder.add_child(_ladder_row(data, i))
	var level := tree.level(id)
	for i in ladder.get_child_count():
		var row := ladder.get_child(i) as PanelContainer
		var style := row.get_theme_stylebox(&"panel") as StyleBoxFlat
		style.bg_color = Color(UiStyle.GOLD_COLOR, 0.1) if i == level else Color(1, 1, 1, 0.025)
		style.border_color = Color(UiStyle.GOLD_COLOR, 0.55 if i == level else 0.0)
		var color := UiStyle.TITLE_COLOR if i < level else (UiStyle.TEXT_COLOR if i == level else UiStyle.DIM_COLOR)
		for part: String in ["Level", "Value"]:
			(row.get_node("Line/" + part) as Label).add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR if part == "Level" and i < level else color)


func _ladder_row(data: TreeNodeData, i: int) -> PanelContainer:
	var row := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	row.add_theme_stylebox_override(&"panel", style)
	row.custom_minimum_size.y = LADDER_ROW
	var line := HBoxContainer.new()
	line.name = &"Line"
	line.add_theme_constant_override(&"separation", 8)
	row.add_child(line)
	var level := UiStyle.label("Lv %d" % (i + 1), LADDER_FONT - 2)
	level.name = &"Level"
	level.custom_minimum_size.x = 44.0
	line.add_child(level)
	var value := UiStyle.label(data.value_text(i + 1), LADDER_FONT)
	value.name = &"Value"
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(value)
	var free := data.blue[i] == 0 and data.orange[i] == 0
	for kind: StringName in [Essences.BLUE, Essences.ORANGE]:
		var amount: int = data.blue[i] if kind == Essences.BLUE else data.orange[i]
		var text := ""
		if free:
			text = "Free" if kind == Essences.BLUE else ""
		elif amount > 0 or kind == Essences.BLUE:
			text = str(amount)
		var label := UiStyle.label(text, LADDER_FONT - 1, UiStyle.TEXT_COLOR)
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(label)
		var icon := TextureRect.new()
		icon.texture = CostBar.ICONS[kind]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2.ONE * COST_ICON
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.visible = text != "" and not free
		line.add_child(icon)
	return row


## The branch's rows, built when the branch changes and reread every time.
func _fill_list() -> void:
	if _list_branch != branch:
		_list_branch = branch
		for child in _list.get_children():
			_list.remove_child(child)
			child.free()
		rows.clear()
		# Grouped under the page's limb captions (OFFENSE ...), then the rest in
		# catalog order.
		for limb: Dictionary in TreePage.LIMBS.get(branch, []):
			if limb.has("label"):
				_list.add_child(UiStyle.label(limb["label"], 14, JourneyPanel.CAPTION_COLOR))
				for node_id: StringName in limb["ids"]:
					_add_row(node_id)
		for data in tree.branch_nodes(branch):
			if not rows.has(data.id):
				_add_row(data.id)
	for node_id: StringName in rows:
		var row: Button = rows[node_id]
		var current := TreeNodeView.state_of(tree, essences, node_id)
		var hidden := current == &"hidden"
		var icon: TextureRect = row.get_node(^"Line/Icon")
		icon.texture = null if hidden else tree.node(node_id).icon
		var title: Label = row.get_node(^"Line/Name")
		title.text = "???" if hidden else tree.node(node_id).display_name
		title.add_theme_color_override(&"font_color", UiStyle.DIM_COLOR if hidden else UiStyle.TEXT_COLOR)
		var level: Label = row.get_node(^"Line/Level")
		level.text = "" if hidden else "%d/%d" % [tree.level(node_id), tree.node(node_id).max_level]
		level.add_theme_color_override(&"font_color", TreeNodeView.state_color(current) if current in [&"bought", &"maxed"] else UiStyle.DIM_COLOR)


func _add_row(node_id: StringName) -> void:
	rows[node_id] = _list_row(node_id)
	_list.add_child(rows[node_id])


func _list_row(node_id: StringName) -> Button:
	var row := Button.new()
	row.custom_minimum_size = LIST_ROW
	row.focus_mode = Control.FOCUS_NONE
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state: StringName in [&"normal", &"hover", &"pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0.03 if state == &"normal" else 0.08)
		style.border_color = Color(UiStyle.BORDER_COLOR, 0.0 if state == &"normal" else 0.6)
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		row.add_theme_stylebox_override(state, style)
	row.pressed.connect(node_chosen.emit.bind(node_id))
	var line := HBoxContainer.new()
	line.name = &"Line"
	line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line.offset_left = 6.0
	line.offset_right = -12.0
	line.add_theme_constant_override(&"separation", 10)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(line)
	var icon := TextureRect.new()
	icon.name = &"Icon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2.ONE * LIST_ICON
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(icon)
	for part: StringName in [&"Name", &"Level"]:
		var label := UiStyle.label("", LIST_FONT)
		label.name = part
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if part == &"Name":
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(label)
	return row


func _wrapped(label: Label) -> Label:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = JourneyPanel.CONTENT_WIDTH
	return label


func _draw() -> void:
	draw_texture_rect(_top_glow, Rect2(2, 2, size.x - 4.0, JourneyPanel.GLOW_HEIGHT), false, Color(UiStyle.GOLD_COLOR, JourneyPanel.GLOW_ALPHA * 0.7))
	if cost_bar.visible:
		# The cost bar is last, at the bottom: a faint rule over it, as over Start.
		var line_y := size.y - JourneyPanel.PAD - CostBar.SIZE.y - JourneyPanel.GAP * 0.5
		draw_line(Vector2(JourneyPanel.PAD, line_y), Vector2(size.x - JourneyPanel.PAD, line_y), Color(UiStyle.BORDER_COLOR, 0.25), 1.0)


## The levels bought as a gold bar.
func _draw_progress() -> void:
	var bought := TreePage.levels(tree, branch)
	var rect := Rect2(Vector2.ZERO, _progress.size)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(1, 1, 1, 0.06)
	back.set_corner_radius_all(5)
	_progress.draw_style_box(back, rect)
	if bought.x > 0:
		var fill := back.duplicate() as StyleBoxFlat
		fill.bg_color = UiStyle.GOLD_COLOR
		rect.size.x = maxf(rect.size.x * bought.x / bought.y, PROGRESS_HEIGHT)
		_progress.draw_style_box(fill, rect)


## The picked node's frame and icon, as on the page ("?" while hidden).
func _draw_portrait() -> void:
	if id == &"":
		return
	var current := TreeNodeView.state_of(tree, essences, id)
	var frame := StyleBoxFlat.new()
	frame.bg_color = TreeNodeView.HIDDEN_FILL if current == &"hidden" else TreeNodeView.FILL_COLOR
	frame.border_color = TreeNodeView.state_color(current)
	frame.set_border_width_all(TreeNodeView.BORDER)
	frame.set_corner_radius_all(TreeNodeView.CORNER)
	var rect := Rect2(Vector2.ZERO, Vector2.ONE * PORTRAIT_SIZE)
	if current in [&"bought", &"maxed"]:
		_portrait.draw_texture_rect(JourneyMap.glow(), rect.grow(30.0), false, Color(frame.border_color, 0.3))
	_portrait.draw_style_box(frame, rect)
	if current == &"hidden":
		var font := get_theme_default_font()
		var width := font.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, 44).x
		_portrait.draw_string(font, Vector2((PORTRAIT_SIZE - width) * 0.5, PORTRAIT_SIZE * 0.5 + 16.0), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, TreeNodeView.QUESTION_COLOR)
	else:
		var inset := TreeNodeView.ICON_INSET
		_portrait.draw_texture_rect(tree.node(id).icon, rect.grow(-inset), false)
