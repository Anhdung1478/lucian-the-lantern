class_name NodeInfoPanel
extends PanelContainer
## The Evolution Tree's info column, right of the pages and always shown, in
## the Journey panel's look.
## - Nothing picked: the branch's levels bought as the lead (its name and
##   blurb are on the page's art, so not here), "Pick a node" and a row per
##   node it knows (icon, name, level; a click picks it), then one dim line
##   for the hidden ones ("7 more to discover").
## - A node picked: its branch, name and icon, "LVL 2 / 5", its value now and
##   at the next level, what it does, R's "Q + W + E ranks: 7 / 9", what its
##   next level still needs, a row per level (value and cost; bought ones lit,
##   the next one framed) and the CostBar that buys it, at the bottom. A
##   hidden node reads "???": its requirement, then the branch's list.
##   Under the ladder of a known node: the branch's known nodes as small rows
##   (one column up to NEAR_ONE_COLUMN of them, else two), the open one
##   marked; a click steps to a neighbour.
## The frame stays; its body fades and rises in when the subject changes.
##   Icons not bought yet show in greyscale, as on the page.

## A row of the branch's node list was clicked.
signal node_chosen(id: StringName)

const PORTRAIT_SIZE := 96.0
const PROGRESS_HEIGHT := 10.0
const ROW_GAP := 12
## The branch's node list: a row's height, its icon and fonts.
const LIST_ROW := Vector2(400, 42)
const LIST_GAP := 4
const LIST_ICON := 32.0
const LIST_FONT := UiStyle.FONT_ROW
## The neighbour list under a picked node's ladder: two columns of small rows.
const NEAR_ROW := Vector2(196, 31)
const NEAR_GAP := 8
## Up to this many known nodes the small rows take the full width.
const NEAR_ONE_COLUMN := 5
const NEAR_ROW_GAP := 4
const NEAR_ICON := 24.0
const NEAR_FONT := UiStyle.FONT_BODY
## The picked node's level ladder: a row's height (34 px pitch on screen) and
## fonts.
const LADDER_ROW := 37.0
const LADDER_FONT := UiStyle.FONT_ROW
const LADDER_SMALL := UiStyle.FONT_BODY
## The body's rise as the subject changes (6 px on screen).
const TURN_RISE := 7.0
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
## "Levels bought 3 / 19": the branch's lead (counts as it changes).
var levels_label: CountLabel
## "Pick a node".
var hint_label: Label
## "7 more to discover", under the known nodes while some are hidden.
var more_label: Label
## The branch's node list: node id -> its row.
var rows := {}
## The same nodes as small rows under a picked node's ladder (known ones only).
var near_rows := {}
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
var _near := GridContainer.new()
var _near_caption: Label
## The branch the list was built for.
var _list_branch: StringName
## The "LEVELS" caption over the ladder; both hide for a hidden node.
var _ladder_caption: Label
## The node the ladder was built for.
var _ladder_id: StringName
var _node_box := VBoxContainer.new()
var _portrait := Control.new()
var _progress := Control.new()
## The share of the branch bought that the bar shows (eases to the new one).
var _progress_shown := -1.0
var _progress_tween: Tween
## Holds the column on a plain Control, so the body can rise as it enters.
var _body := Control.new()
var _column := VBoxContainer.new()
## The rule under the node's name, and the one over its ladder.
var _top_rule: Control
var _ladder_rule: Control
## What the body shows: the branch, or the node id.
var _subject: StringName


func _init(evolution_tree: EvolutionTree, owned: Essences) -> void:
	tree = evolution_tree
	essences = owned
	custom_minimum_size = JourneyPanel.SIZE
	size = JourneyPanel.SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Opaque, with the Journey panel's frame: rounded on the right only.
	var style := JourneyPanel.frame_style()
	style.set_content_margin_all(JourneyPanel.PAD)
	style.content_margin_top = JourneyPanel.PAD + 4.0
	add_theme_stylebox_override(&"panel", style)

	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.resized.connect(_fit_column)
	add_child(_body)
	# Sized by hand, not anchored: the body's entrance moves it, and moving an
	# anchored node would rewrite its offsets.
	var column := _column
	column.add_theme_constant_override(&"separation", ROW_GAP)
	column.minimum_size_changed.connect(_fit_column, CONNECT_DEFERRED)
	_body.add_child(column)
	caption_label = UiStyle.label("", 16, JourneyPanel.CAPTION_COLOR)
	column.add_child(caption_label)
	name_label = _wrapped(UiStyle.label("", 34, UiStyle.TITLE_COLOR))
	column.add_child(name_label)
	_top_rule = JourneyPanel.divider()
	column.add_child(_top_rule)

	_branch_box.add_theme_constant_override(&"separation", ROW_GAP)
	column.add_child(_branch_box)
	# The branch's name and blurb are on the page's art: kept, not shown.
	blurb_label = _wrapped(UiStyle.label("", 20, UiStyle.TEXT_COLOR))
	blurb_label.visible = false
	_branch_box.add_child(blurb_label)
	levels_label = CountLabel.new()
	levels_label.add_theme_font_size_override(&"font_size", UiStyle.FONT_LEAD)
	levels_label.add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR)
	_branch_box.add_child(levels_label)
	_progress.custom_minimum_size = Vector2(JourneyPanel.CONTENT_WIDTH, PROGRESS_HEIGHT)
	_progress.draw.connect(_draw_progress)
	_branch_box.add_child(_progress)
	_branch_box.add_child(JourneyPanel.divider())
	hint_label = UiStyle.label(Lang.t("Pick a node"), 18, UiStyle.DIM_COLOR)
	_branch_box.add_child(hint_label)
	_list.add_theme_constant_override(&"separation", LIST_GAP)
	_branch_box.add_child(_list)
	more_label = UiStyle.label("", LIST_FONT, UiStyle.DIM_COLOR)
	_branch_box.add_child(more_label)

	_node_box.add_theme_constant_override(&"separation", ROW_GAP)
	column.add_child(_node_box)
	# Before the branch's list: a hidden node shows its requirement, then it.
	column.move_child(_node_box, _branch_box.get_index())
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
	_ladder_rule = JourneyPanel.divider()
	_node_box.add_child(_ladder_rule)
	_ladder_caption = UiStyle.label(Lang.t("LEVELS"), 16, JourneyPanel.CAPTION_COLOR)
	_node_box.add_child(_ladder_caption)
	ladder.add_theme_constant_override(&"separation", 4)
	_node_box.add_child(ladder)
	_near_caption = UiStyle.label(Lang.t("NODES"), 16, JourneyPanel.CAPTION_COLOR)
	_node_box.add_child(_near_caption)
	_near.columns = 2
	_near.add_theme_constant_override(&"h_separation", NEAR_GAP)
	_near.add_theme_constant_override(&"v_separation", NEAR_ROW_GAP)
	_node_box.add_child(_near)

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
	_turn_to(branch_id)


## Shows node `node_id` (and its branch).
func show_node(node_id: StringName) -> void:
	id = node_id
	branch = tree.node(id).branch
	cost_bar.show_node(id)
	refresh()
	_turn_to(node_id)


## Rereads the branch or the node from the tree.
func refresh() -> void:
	var picked := id != &""
	var hidden := picked and TreeNodeView.is_hidden(tree, id)
	# A hidden node's requirement, then the branch's list under it.
	_branch_box.visible = not picked or hidden
	_node_box.visible = picked
	cost_bar.visible = picked
	for part: CanvasItem in [caption_label, name_label, _top_rule]:
		part.visible = picked
	for part: CanvasItem in [levels_label, _progress, hint_label]:
		part.visible = not picked
	var bought := TreePage.levels(tree, branch)
	var new_branch := _list_branch != branch
	if not picked:
		caption_label.text = Lang.t("EVOLUTION TREE")
		name_label.text = Lang.t(TreePage.NAMES[branch])
	blurb_label.text = Lang.t(TreePage.BLURBS[branch])
	levels_label.formatter = func(v: int) -> String: return Lang.t("Levels bought %d / %d") % [v, bought.y]
	levels_label.set_value(bought.x, new_branch)
	_ease_progress(float(bought.x) / maxf(bought.y, 1.0), new_branch)
	_fill_list()
	if picked:
		_show_node()
	queue_redraw()


## The column takes the body's size (its height may not shrink under its
## content; a wrapped label too wide for a moment never keeps it wide).
func _fit_column() -> void:
	_column.size = _body.size


## The body fades and rises in when it shows a new subject (a branch or a
## node); a refresh of the same one stays still.
func _turn_to(subject: StringName) -> void:
	if subject == _subject:
		return
	var first := _subject == &""
	_subject = subject
	if not first:
		UiMotion.enter(_column, TURN_RISE, UiMotion.BASE)


## The levels bar eases to `share` (snaps for a new branch).
func _ease_progress(share: float, snap: bool) -> void:
	if _progress_tween and _progress_tween.is_valid():
		_progress_tween.kill()
	if snap or _progress_shown < 0.0 or UiMotion.off() or not is_inside_tree():
		_progress_shown = share
		_progress.queue_redraw()
		return
	_progress_tween = UiMotion.tween(self)
	_progress_tween.tween_method(_set_progress, _progress_shown, share, UiMotion.BASE)


func _set_progress(share: float) -> void:
	_progress_shown = share
	_progress.queue_redraw()


func _show_node() -> void:
	var data := tree.node(id)
	var level := tree.level(id)
	var hidden := TreeNodeView.is_hidden(tree, id)
	caption_label.text = Lang.t(TreePage.NAMES[branch]).to_upper()
	name_label.text = "???" if hidden else Lang.t(data.display_name)
	level_label.text = Lang.t("LVL %d / %d") % [level, data.max_level]
	_ladder_rule.visible = not hidden
	if hidden:
		value_label.text = ""
		value_label.add_theme_color_override(&"font_color", UiStyle.TEXT_COLOR)
	elif tree.is_maxed(id):
		value_label.text = data.value_text(level)
		value_label.add_theme_color_override(&"font_color", TreeNodeView.MAXED_COLOR)
	else:
		value_label.text = "%s → %s" % [data.value_text(level), data.value_text(level + 1)]
		value_label.add_theme_color_override(&"font_color", UiStyle.TEXT_COLOR)
	description.text = "" if hidden else TooltipText.colorize(Lang.t(data.description))
	sum_label.visible = not hidden and not data.level_sum_ids.is_empty()
	if sum_label.visible:
		var names: PackedStringArray = []
		for summed in data.level_sum_ids:
			names.append(tree.node(summed).short_name())
		sum_label.text = Lang.t("%s ranks: %d") % [" + ".join(names), tree.level_sum(id)]
		if not tree.is_maxed(id):
			sum_label.text += " / %d" % data.sum_needed(level)
	var needs := tree.next_requirement_text(id)
	requires_label.visible = needs != ""
	requires_label.text = needs
	_ladder_caption.visible = not hidden
	_fill_ladder(hidden)
	cost_bar.refresh()
	_portrait.queue_redraw()
	_portrait.material = TreeNodeView.grey_material() if TreeNodeView.state_of(tree, essences, id) in [&"open", &"poor"] else null


## The picked node's levels: built when the node changes, recoloured every
## time (bought, next, later).
func _fill_ladder(hidden: bool) -> void:
	var data := tree.node(id)
	var wanted: StringName = &"" if hidden else id
	if _ladder_id != wanted:
		_ladder_id = wanted
		for child in ladder.get_children():
			ladder.remove_child(child)
			child.free()
		for i in (0 if hidden else data.max_level):
			ladder.add_child(_ladder_row(data, i))
	var level := tree.level(id)
	for i in ladder.get_child_count():
		var row := ladder.get_child(i) as PanelContainer
		var style := row.get_theme_stylebox(&"panel") as StyleBoxFlat
		style.bg_color = Color(UiStyle.GOLD_COLOR, 0.1) if i == level else Color(1, 1, 1, 0.025)
		style.border_color = Color(UiStyle.GOLD_COLOR, 0.55 if i == level else 0.0)
		var color := UiStyle.TITLE_COLOR if i < level else (UiStyle.TEXT_COLOR if i == level else UiStyle.DIM_COLOR)
		for part: StringName in [&"Level", &"Value"]:
			(row.get_node("Line/" + part) as Label).add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR if part == &"Level" and i < level else color)


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
	var level := UiStyle.label(Lang.t("Lv %d") % (i + 1), LADDER_SMALL)
	level.name = &"Level"
	level.custom_minimum_size.x = 52.0
	line.add_child(level)
	var value := UiStyle.label(data.value_text(i + 1), LADDER_FONT)
	value.name = &"Value"
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# A long value ("Slightly Magical Boots") wraps inside the row, so the
	# column never grows past the panel.
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(value)
	var free := data.blue[i] == 0 and data.orange[i] == 0
	for kind: StringName in [Essences.BLUE, Essences.ORANGE]:
		var amount: int = data.blue[i] if kind == Essences.BLUE else data.orange[i]
		var text := ""
		if free:
			text = Lang.t("Free") if kind == Essences.BLUE else ""
		elif amount > 0 or kind == Essences.BLUE:
			text = str(amount)
		var label := UiStyle.label(text, LADDER_SMALL, UiStyle.TEXT_COLOR)
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
## Hidden nodes have no row on show: one dim line counts them instead, and a
## caption over only hidden nodes hides too.
func _fill_list() -> void:
	if _list_branch != branch:
		_list_branch = branch
		for child in _list.get_children():
			_list.remove_child(child)
			child.free()
		rows.clear()
		for child in _near.get_children():
			_near.remove_child(child)
			child.free()
		near_rows.clear()
		# Grouped under the page's limb captions (OFFENSE ...), then the rest in
		# catalog order.
		for limb: Dictionary in TreePage.LIMBS.get(branch, []):
			if limb.has("label"):
				_list.add_child(UiStyle.label(Lang.t(limb["label"]), UiStyle.FONT_NOTE, JourneyPanel.CAPTION_COLOR))
				for node_id: StringName in limb["ids"]:
					_add_row(node_id)
		for data in tree.branch_nodes(branch):
			if not rows.has(data.id):
				_add_row(data.id)
		for node_id: StringName in rows:
			near_rows[node_id] = _list_row(node_id, true)
			_near.add_child(near_rows[node_id])
	_fill_rows(rows)
	_fill_rows(near_rows)
	_mark_open_row()
	var known := 0
	for node_id: StringName in near_rows:
		known += int((near_rows[node_id] as Button).visible)
	_near.columns = 1 if known <= NEAR_ONE_COLUMN else 2
	for node_id: StringName in near_rows:
		(near_rows[node_id] as Button).custom_minimum_size.x = 0.0 if _near.columns == 1 else NEAR_ROW.x
	var show_near := id != &"" and not TreeNodeView.is_hidden(tree, id)
	_near_caption.visible = show_near
	_near.visible = show_near
	var unknown := 0
	var caption: Control = null
	var caption_rows := 0
	for child: Control in _list.get_children():
		if child is Button:
			if child.visible:
				caption_rows += 1
			else:
				unknown += 1
			continue
		if caption:
			caption.visible = caption_rows > 0
		caption = child
		caption_rows = 0
	if caption:
		caption.visible = caption_rows > 0
	more_label.visible = unknown > 0
	more_label.text = Lang.t("%d more to discover") % unknown


## The rows' icon, name and level, from the tree (hidden nodes show nothing,
## and have no row in the small list).
func _fill_rows(group: Dictionary) -> void:
	for node_id: StringName in group:
		var row: Button = group[node_id]
		var current := TreeNodeView.state_of(tree, essences, node_id)
		var hidden := current == &"hidden"
		var icon: TextureRect = row.get_node(^"Line/Icon")
		icon.texture = null if hidden else tree.node(node_id).icon
		icon.material = TreeNodeView.grey_material() if current in [&"open", &"poor"] else null
		var title: Label = row.get_node(^"Line/Name")
		title.text = "???" if hidden else Lang.t(tree.node(node_id).display_name)
		# A small row may clip a long name: the hover card has all of it.
		if group == near_rows:
			row.set_meta(&"hover_text", title.text)
		title.add_theme_color_override(&"font_color", UiStyle.DIM_COLOR if hidden else UiStyle.TEXT_COLOR)
		var level: Label = row.get_node(^"Line/Level")
		level.text = "" if hidden else "%d/%d" % [tree.level(node_id), tree.node(node_id).max_level]
		# The small rows keep their room for the name: a level only once bought,
		# and not on the open node (its level is above).
		if group == near_rows and (node_id == id or tree.level(node_id) == 0):
			level.text = ""
		level.add_theme_color_override(&"font_color", TreeNodeView.state_color(current) if current in [&"bought", &"maxed"] else UiStyle.DIM_COLOR)
		row.visible = not hidden


## The picked node's small row is framed like the ladder's current level.
func _mark_open_row() -> void:
	for node_id: StringName in near_rows:
		var style := (near_rows[node_id] as Button).get_theme_stylebox(&"normal") as StyleBoxFlat
		var open: bool = node_id == id
		style.bg_color = Color(UiStyle.GOLD_COLOR, 0.1) if open else Color(1, 1, 1, 0.03)
		style.border_color = Color(UiStyle.GOLD_COLOR, 0.55) if open else Color(UiStyle.BORDER_COLOR, 0.0)


func _add_row(node_id: StringName) -> void:
	rows[node_id] = _list_row(node_id)
	_list.add_child(rows[node_id])


func _list_row(node_id: StringName, compact := false) -> Button:
	var row := Button.new()
	row.custom_minimum_size = NEAR_ROW if compact else LIST_ROW
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	line.add_theme_constant_override(&"separation", 8 if compact else 10)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(line)
	var icon := TextureRect.new()
	icon.name = &"Icon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2.ONE * (NEAR_ICON if compact else LIST_ICON)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(icon)
	for part: StringName in [&"Name", &"Level"]:
		var label := UiStyle.label("", NEAR_FONT if compact else LIST_FONT)
		label.name = part
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if part == &"Name":
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.clip_text = true
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		line.add_child(label)
	return row


func _wrapped(label: Label) -> Label:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = JourneyPanel.CONTENT_WIDTH
	return label


func _draw() -> void:
	JourneyPanel.draw_top_glow(self, size.x, UiStyle.GOLD_COLOR, JourneyPanel.GLOW_ALPHA * 0.7)
	if cost_bar.visible:
		# The cost bar is last, at the bottom: the Journey's rule over it, as over Start.
		JourneyPanel.draw_rule(self, size.y - JourneyPanel.PAD - CostBar.SIZE.y - JourneyPanel.GAP * 0.5, size.x)


## The levels bought as a gold bar.
func _draw_progress() -> void:
	var rect := Rect2(Vector2.ZERO, _progress.size)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(1, 1, 1, 0.06)
	back.set_corner_radius_all(5)
	_progress.draw_style_box(back, rect)
	if _progress_shown > 0.0:
		var fill := back.duplicate() as StyleBoxFlat
		fill.bg_color = UiStyle.GOLD_COLOR
		rect.size.x = maxf(rect.size.x * _progress_shown, PROGRESS_HEIGHT)
		_progress.draw_style_box(fill, rect)


## The picked node's frame and icon, as on the page ("?" while hidden).
func _draw_portrait() -> void:
	if id == &"":
		return
	var current := TreeNodeView.state_of(tree, essences, id)
	var frame := StyleBoxFlat.new()
	frame.bg_color = TreeNodeView.HIDDEN_FILL if current == &"hidden" else TreeNodeView.FILL_COLOR
	frame.border_color = TreeNodeView.state_color(current)
	frame.set_border_width_all(TreeNodeView.border_width(current))
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
