class_name NodeInfoPanel
extends PanelContainer
## The Evolution Tree's info column, right of the page, in the Journey
## panel's frame. It always shows one node, or what the branch waits for,
## and ends in its one action (CostBar) at the foot, in the same place for
## every node and state; the frame and the action stay put while the content
## between them crossfades and rises.
## - A node picked: its group's caption, its name, what the next level gives
##   ("+8 AD → +12 AD"; the value alone, in green, once maxed), what it does,
##   in red what its next level still needs, on Backpack the node's preview
##   (the six equip slots and their acts, the two boots, the 9 x 6 cells),
##   then LEVELS: a row per level and its price (the next level's price is on
##   the action, so its row says "Next"). A hidden node reads "Hidden node"
##   and its whole requirement.
## - Nothing picked, the page's subject, said as the fact that chose it:
##   FREE TO CLAIM, CHEAPEST UPGRADE (the page's gold node) or SAVING FOR (the
##   cheapest level, too dear: no gold on the page), shown as if picked; its
##   action picks it and asks. With nothing open: NEXT STEP, "Clear Act 1",
##   how many nodes it opens and what the others wait for (STILL HIDDEN),
##   and no action. A finished branch: WHAT IT GIVES, a row per node. At
##   rest a node's ladder is followed by THIS BRANCH GIVES: what each bought
##   node gives now (as many rows as the room allows).

## Kept for callers that pick from the panel.
signal node_chosen(id: StringName)

const ROW_GAP := 12
const NAME_FONT := 34
const LEAD_FONT := 24
const BODY_FONT := 19
const CAPTION_FONT := 16
const ROW_FONT := UiStyle.FONT_BODY
## The level ladder: a row's height and the gap (34 px pitch: 28 on screen).
const LADDER_ROW := 30.0
const LADDER_GAP := 4
const COST_ICON := 20.0
## A row of what the branch gives: its icon, and the least room for its name.
const GIVES_ICON := 24.0
const GIVES_NAME_MIN := 120.0
## The body inside the frame's margins: its height (the action sits at its foot).
const BODY_HEIGHT := JourneyPanel.SIZE.y - JourneyPanel.PAD * 2.0 - 4.0
## The body's rise as the subject changes (6 px on screen).
const TURN_RISE := 7.0
## The Backpack previews: the equip slots, the boots, the cells.
const SLOT_SIZE := 48.0
const SLOT_GAP := 10.0
const BOOT_SLOT := 64.0
const BOOT_COLUMN := 190.0
const CELL := 22.0
const CELL_GAP := 4.0
const EQUIP_ID := &"equip_slots"
const BACKPACK_ID := &"backpack_slots"
const BOOTS_ID := &"boots"
const BOOTS_ICONS: Array[Texture2D] = [
	preload("res://assets/art/items/boots_of_speed.svg"),
	preload("res://assets/art/items/slightly_magical_boots.svg"),
]
const LOCK := preload("res://assets/art/ui/lock.svg")

## The picked node, &"" with nothing picked.
var id: StringName
## The branch shown.
var branch: StringName = EvolutionTree.BRANCHES[0]
## The node the panel shows (the picked one, or the branch's subject at
## rest), &"" when it shows what the branch waits for or gives.
var subject: StringName
var tree: EvolutionTree
var essences: Essences
## FREE TO CLAIM, CHEAPEST UPGRADE, SAVING FOR, NEXT STEP, BRANCH COMPLETE,
## or a picked node's group (OFFENSE...).
var caption_label: Label
var name_label: Label
## "+8 AD → +12 AD"; only the value, in green, once maxed.
var value_label: Label
var description: RichTextLabel
## "Requires: …", shown while the next level is closed.
var requires_label: Label
## A dim line under a hidden node's requirement.
var note_label: Label
## The Backpack nodes' preview.
var preview := Control.new()
## "2 of 6 slots open", over the preview.
var preview_label: Label
## One row per level of the shown node.
var ladder := VBoxContainer.new()
## What the branch's other closed nodes wait for (rows of rule and count).
var waiting := VBoxContainer.new()
## A finished branch: a row per node; at rest, the bought nodes.
var gives := VBoxContainer.new()
## The gives rows are trimmed to the room (at rest only), once laid out:
## frames left before that.
var _gives_trim := false
var _trim_wait := 0
var cost_bar: CostBar

var _body := Control.new()
var _column := VBoxContainer.new()
var _top_rule: Control
var _ladder_rule: Control
var _ladder_caption: Label
var _waiting_caption: Label
var _gives_caption: Label
## The node the ladder was built for.
var _ladder_id: StringName
## What the body shows (a turn plays when it changes).
var _turn_key := ""


func _init(evolution_tree: EvolutionTree, owned: Essences) -> void:
	tree = evolution_tree
	essences = owned
	custom_minimum_size = JourneyPanel.SIZE
	size = JourneyPanel.SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	var style := JourneyPanel.frame_style()
	style.set_content_margin_all(JourneyPanel.PAD)
	style.content_margin_top = JourneyPanel.PAD + 4.0
	add_theme_stylebox_override(&"panel", style)

	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.resized.connect(_place)
	add_child(_body)
	_column.add_theme_constant_override(&"separation", ROW_GAP)
	_column.minimum_size_changed.connect(_place, CONNECT_DEFERRED)
	_body.add_child(_column)
	caption_label = UiStyle.label("", CAPTION_FONT, JourneyPanel.CAPTION_COLOR)
	_column.add_child(caption_label)
	name_label = _wrapped(UiStyle.label("", NAME_FONT, UiStyle.TITLE_COLOR))
	_column.add_child(name_label)
	_top_rule = JourneyPanel.divider()
	_column.add_child(_top_rule)
	value_label = _wrapped(UiStyle.label("", LEAD_FONT))
	_column.add_child(value_label)
	description = RichTextLabel.new()
	description.bbcode_enabled = true
	description.fit_content = true
	description.scroll_active = false
	description.custom_minimum_size.x = JourneyPanel.CONTENT_WIDTH
	description.add_theme_font_size_override(&"normal_font_size", BODY_FONT)
	description.add_theme_color_override(&"default_color", UiStyle.TEXT_COLOR)
	_column.add_child(description)
	requires_label = _wrapped(UiStyle.label("", BODY_FONT, UiStyle.ERROR_COLOR))
	_column.add_child(requires_label)
	note_label = _wrapped(UiStyle.label(Lang.t("Its name and levels show once it opens."), ROW_FONT, UiStyle.DIM_COLOR))
	_column.add_child(note_label)
	preview_label = UiStyle.label("", ROW_FONT, UiStyle.TEXT_COLOR)
	_column.add_child(preview_label)
	preview.custom_minimum_size = Vector2(JourneyPanel.CONTENT_WIDTH, 0)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.draw.connect(_draw_preview)
	_column.add_child(preview)
	_ladder_rule = JourneyPanel.divider()
	_column.add_child(_ladder_rule)
	_ladder_caption = UiStyle.label(Lang.t("LEVELS"), CAPTION_FONT, JourneyPanel.CAPTION_COLOR)
	_column.add_child(_ladder_caption)
	ladder.add_theme_constant_override(&"separation", LADDER_GAP)
	_column.add_child(ladder)
	_waiting_caption = UiStyle.label(Lang.t("STILL HIDDEN"), CAPTION_FONT, JourneyPanel.CAPTION_COLOR)
	_column.add_child(_waiting_caption)
	waiting.add_theme_constant_override(&"separation", ROW_GAP)
	_column.add_child(waiting)
	_gives_caption = UiStyle.label("", CAPTION_FONT, JourneyPanel.CAPTION_COLOR)
	_column.add_child(_gives_caption)
	gives.add_theme_constant_override(&"separation", LADDER_GAP)
	_column.add_child(gives)

	cost_bar = CostBar.new(tree, essences)
	_body.add_child(cost_bar)
	refresh()


## Shows `branch_id` with nothing picked: its subject.
func show_branch(branch_id: StringName) -> void:
	branch = branch_id
	id = &""
	refresh()


## Shows node `node_id` (and its branch).
func show_node(node_id: StringName) -> void:
	id = node_id
	branch = tree.node(id).branch
	refresh()


## The node shown with nothing picked: a free level, else the cheapest one
## that can be bought now (the page's gold), else the cheapest one open but
## too dear; &"" when nothing is open.
func rest_subject() -> StringName:
	var gold := TreeSection.next_step(tree, essences, branch)
	if gold != &"":
		return gold
	var best: StringName = &""
	var best_cost := INF
	for data in tree.branch_nodes(branch):
		if not tree.next_level_open(data.id):
			continue
		var price := tree.cost(data.id)
		var weight := price.x + price.y * float(Essences.FORGE_BLUE)
		if weight < best_cost:
			best_cost = weight
			best = data.id
	return best


## Rereads the branch or the node from the tree.
func refresh() -> void:
	subject = id if id != &"" else rest_subject()
	var complete := subject == &"" and _all_maxed()
	for part: CanvasItem in [value_label, description, requires_label, note_label, preview_label, preview, _ladder_rule,
			_ladder_caption, ladder, _waiting_caption, waiting, _gives_caption, gives]:
		part.visible = false
	cost_bar.visible = subject != &""
	if subject != &"":
		_show_subject()
	elif complete:
		_show_complete()
	else:
		_show_waiting()
	_turn_to("%s|%s|%s" % [branch, id, subject])
	_place()
	queue_redraw()


func _show_subject() -> void:
	var data := tree.node(subject)
	var level := tree.level(subject)
	var hidden := TreeNodeView.is_hidden(tree, subject)
	caption_label.text = _caption()
	_set_text(name_label, Lang.t("Hidden node") if hidden else Lang.t(data.display_name))
	cost_bar.show_node(subject)
	if hidden:
		requires_label.visible = true
		requires_label.text = tree.requirement_text(subject, 0)
		note_label.visible = true
		_fill_waiting(subject)
		return
	value_label.visible = true
	if tree.is_maxed(subject):
		_set_text(value_label, data.value_text(level))
		value_label.add_theme_color_override(&"font_color", UiStyle.GOOD_COLOR)
	else:
		_set_text(value_label, "%s → %s" % [data.value_text(level), data.value_text(level + 1)])
		value_label.add_theme_color_override(&"font_color", UiStyle.TEXT_COLOR)
	description.visible = true
	description.text = TooltipText.colorize(Lang.t(data.description))
	var needs := tree.next_requirement_text(subject)
	requires_label.visible = needs != ""
	requires_label.text = needs
	if subject in [EQUIP_ID, BOOTS_ID, BACKPACK_ID]:
		preview_label.visible = true
		preview_label.text = _preview_line()
		preview.visible = true
		preview.custom_minimum_size.y = _preview_height()
		preview.queue_redraw()
	for part: CanvasItem in [_ladder_rule, _ladder_caption, ladder]:
		part.visible = true
	_fill_ladder()
	if id == &"":
		_fill_gives(true)


## What chose the shown node, as a caption.
func _caption() -> String:
	if id != &"":
		for limb: Dictionary in TreePage.LIMBS.get(branch, []):
			if limb.has("label") and id in limb["ids"]:
				return Lang.t(limb["label"])
		return ""
	if tree.is_free(subject):
		return Lang.t("FREE TO CLAIM")
	if tree.can_buy(subject, essences):
		return Lang.t("CHEAPEST UPGRADE")
	return Lang.t("SAVING FOR")


## Nothing open: the act (or rule) the branch waits for, and the rest.
func _show_waiting() -> void:
	caption_label.text = Lang.t("NEXT STEP")
	var groups := _waiting_groups(&"")
	var title := Lang.t("Nothing to buy yet")
	var skip := ""
	var largest := 0
	for rule: String in groups:
		if groups[rule].size() > largest:
			largest = groups[rule].size()
			skip = rule
	var act := _act_only(skip)
	if act > 0:
		title = Lang.t("Clear Act %d") % act
		value_label.visible = true
		_set_text(value_label, Lang.t("Opens %d nodes on this branch.") % largest if largest != 1 else Lang.t("Opens 1 node on this branch."))
		value_label.add_theme_color_override(&"font_color", UiStyle.TEXT_COLOR)
	else:
		skip = ""
	_set_text(name_label, title)
	_fill_waiting(&"", skip)


## A finished branch: what each of its nodes gives.
func _show_complete() -> void:
	caption_label.text = Lang.t("BRANCH COMPLETE")
	_set_text(name_label, Lang.t("Every level bought"))
	_fill_gives(false)


## What the branch's nodes give: every node (a finished branch), or at rest
## the bought ones, as many as fit above the action ("+2 more" past that).
func _fill_gives(bought_only: bool) -> void:
	for child in gives.get_children():
		gives.remove_child(child)
		child.free()
	var shown: Array[TreeNodeData] = []
	for data in tree.branch_nodes(branch):
		if not bought_only or tree.level(data.id) > 0:
			shown.append(data)
	if shown.is_empty():
		return
	_gives_caption.text = Lang.t("THIS BRANCH GIVES") if bought_only else Lang.t("WHAT IT GIVES")
	_gives_caption.visible = true
	gives.visible = true
	_gives_trim = bought_only
	if bought_only:
		# Measured once laid out (two frames on); until then it waits unseen.
		gives.modulate.a = 0.0
		_trim_wait = 2
		set_process(true)
	for data in shown:
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = LADDER_ROW
		row.add_theme_constant_override(&"separation", 10)
		var icon := TextureRect.new()
		icon.texture = data.icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2.ONE * GIVES_ICON
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
		var title := UiStyle.label(TreeNodeView.glued(data.short_name()), ROW_FONT, UiStyle.DIM_COLOR)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		# A long name wraps beside a long value; the row never grows past the column.
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.custom_minimum_size.x = GIVES_NAME_MIN
		row.add_child(title)
		var value := UiStyle.label(data.value_text(tree.level(data.id)), ROW_FONT, UiStyle.TEXT_COLOR)
		value.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(value)
		gives.add_child(row)
	if bought_only:
		var more := UiStyle.label("", UiStyle.FONT_NOTE, UiStyle.DIM_COLOR)
		more.name = &"More"
		more.visible = false
		gives.add_child(more)


func _ready() -> void:
	set_process(_trim_wait > 0)


func _process(_delta: float) -> void:
	_trim_wait -= 1
	if _trim_wait > 0:
		return
	set_process(false)
	_trim_gives()
	if UiMotion.off() or not is_inside_tree():
		gives.modulate.a = 1.0
		return
	var tween := UiMotion.tween(gives)
	tween.tween_property(gives, ^"modulate:a", 1.0, UiMotion.BASE)


## At rest, once laid out: the rows that would reach the action's rule go,
## and "+2 more" says how many.
func _trim_gives() -> void:
	if not _gives_trim or not gives.visible:
		return
	var more := gives.get_node_or_null(^"More") as Label
	if more == null:
		return
	var hidden := 0
	for row in gives.get_children():
		hidden += int(row != more and not row.visible)
	var guard := gives.get_child_count()
	while content_bottom() > action_top() - 16.0 and guard > 0:
		guard -= 1
		var last: Control = null
		for row in gives.get_children():
			if row != more and row.visible:
				last = row
		if last == null:
			_gives_caption.visible = false
			gives.visible = false
			return
		last.visible = false
		hidden += 1
		more.visible = true
		more.text = Lang.t("+%d more") % hidden


## The closed nodes of the branch (other than `except`) by what they wait
## for: requirement text (without "Requires: ") -> their ids.
func _waiting_groups(except: StringName) -> Dictionary:
	var groups := {}
	for data in tree.branch_nodes(branch):
		if data.id == except or tree.is_maxed(data.id) or tree.next_level_open(data.id):
			continue
		var rule := tree.requirement_text(data.id, tree.level(data.id))
		if not groups.has(rule):
			groups[rule] = []
		groups[rule].append(data.id)
	return groups


## The act in a rule that is only "Requires: Clear Act N"; 0 otherwise.
func _act_only(rule: String) -> int:
	for act in range(1, 7):
		if rule == Lang.t("Requires: %s") % (Lang.t("Clear Act %d") % act):
			return act
	return 0


## STILL HIDDEN: a row per rule the branch's other closed nodes wait for.
func _fill_waiting(except: StringName, skip := "") -> void:
	for child in waiting.get_children():
		waiting.remove_child(child)
		child.free()
	var groups := _waiting_groups(except)
	for rule: String in groups:
		if rule == skip:
			continue
		var row := VBoxContainer.new()
		row.add_theme_constant_override(&"separation", 2)
		row.add_child(_wrapped(UiStyle.label(rule, ROW_FONT, UiStyle.TEXT_COLOR)))
		var count: int = groups[rule].size()
		row.add_child(UiStyle.label(Lang.t("1 node") if count == 1 else Lang.t("%d nodes") % count, UiStyle.FONT_NOTE, UiStyle.DIM_COLOR))
		waiting.add_child(row)
	_waiting_caption.visible = waiting.get_child_count() > 0
	waiting.visible = _waiting_caption.visible


func _all_maxed() -> bool:
	for data in tree.branch_nodes(branch):
		if not tree.is_maxed(data.id):
			return false
	return true


## The shown node's levels: built when the node changes, recoloured every time
## (bought, next, later). The next level's price is on the action while it
## can be paid for there, so its row says "Next" instead.
func _fill_ladder() -> void:
	var data := tree.node(subject)
	var fresh := _ladder_id != subject
	if fresh:
		_ladder_id = subject
		for child in ladder.get_children():
			ladder.remove_child(child)
			child.free()
		for i in data.max_level:
			ladder.add_child(_ladder_row(data, i))
	var level := tree.level(subject)
	var priced_on_action := tree.next_level_open(subject) and tree.cost(subject) != Vector2i.ZERO
	for i in ladder.get_child_count():
		var row := ladder.get_child(i) as PanelContainer
		var style := row.get_theme_stylebox(&"panel") as StyleBoxFlat
		var next := i == level
		var was := style.border_color.a > 0.0
		style.bg_color = Color(UiStyle.GOLD_COLOR, 0.1) if next else Color(1, 1, 1, 0.025)
		style.border_color = Color(UiStyle.GOLD_COLOR, 0.55 if next else 0.0)
		var color := UiStyle.TITLE_COLOR if i < level else (UiStyle.TEXT_COLOR if next else UiStyle.DIM_COLOR)
		(row.get_node(^"Line/Level") as Label).add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR if i < level else color)
		(row.get_node(^"Line/Value") as Label).add_theme_color_override(&"font_color", color)
		var tag := row.get_node(^"Line/Next") as Label
		var price := row.get_node(^"Line/Price") as HBoxContainer
		tag.visible = next and priced_on_action
		price.visible = not tag.visible
		for part in price.get_children():
			if part is Label:
				part.add_theme_color_override(&"font_color", UiStyle.DIM_COLOR if i != level else UiStyle.TEXT_COLOR)
		if next != was and not fresh:
			_pulse(row)


func _ladder_row(data: TreeNodeData, i: int) -> PanelContainer:
	var row := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.set_border_width_all(1)
	style.border_color = Color(0, 0, 0, 0)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	row.add_theme_stylebox_override(&"panel", style)
	row.custom_minimum_size.y = LADDER_ROW
	var line := HBoxContainer.new()
	line.name = &"Line"
	line.add_theme_constant_override(&"separation", 8)
	row.add_child(line)
	var level := UiStyle.label(Lang.t("Lv %d") % (i + 1), ROW_FONT)
	level.name = &"Level"
	level.custom_minimum_size.x = 52.0
	level.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(level)
	var value := UiStyle.label(data.value_text(i + 1), ROW_FONT)
	value.name = &"Value"
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(value)
	var tag := UiStyle.label(Lang.t("Next"), ROW_FONT, UiStyle.GOLD_COLOR)
	tag.name = &"Next"
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(tag)
	var price := HBoxContainer.new()
	price.name = &"Price"
	price.add_theme_constant_override(&"separation", 6)
	price.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(price)
	var free := data.blue[i] == 0 and data.orange[i] == 0
	if free:
		price.add_child(UiStyle.label(Lang.t("Free"), ROW_FONT))
		return row
	for kind: StringName in [Essences.BLUE, Essences.ORANGE]:
		var amount: int = data.blue[i] if kind == Essences.BLUE else data.orange[i]
		if amount <= 0:
			continue
		price.add_child(UiStyle.label(str(amount), ROW_FONT))
		var icon := TextureRect.new()
		icon.texture = CostBar.ICONS[kind]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2.ONE * COST_ICON
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		price.add_child(icon)
	return row


# --- The Backpack previews ---------------------------------------------------------


## "2 of 6 slots open", "Wearing Boots of Speed", "5 of 54 cells open".
func _preview_line() -> String:
	var data := tree.node(subject)
	var level := tree.level(subject)
	match subject:
		EQUIP_ID:
			return Lang.t("%d of %d slots open") % [roundi(data.value(level)), roundi(data.value(data.max_level))]
		BOOTS_ID:
			return Lang.t("No boots yet") if level == 0 else Lang.t("Wearing %s") % data.value_text(level)
	return Lang.t("%d of %d cells open") % [roundi(data.value(level)), Inventory.BACKPACK_SIZE]


func _preview_height() -> float:
	match subject:
		EQUIP_ID:
			return SLOT_SIZE + 44.0
		BOOTS_ID:
			return BOOT_SLOT + 60.0
	var rows := ceili(float(Inventory.BACKPACK_SIZE) / BackpackScreen.COLUMNS)
	return rows * (CELL + CELL_GAP) - CELL_GAP


func _draw_preview() -> void:
	match subject:
		EQUIP_ID:
			_draw_equip()
		BOOTS_ID:
			_draw_boots()
		BACKPACK_ID:
			_draw_cells()


## The six equip slots: open ones lit, the next level's outlined while it can
## be bought, the rest locked; the act each needs under a bracket (green once
## that act is cleared).
func _draw_equip() -> void:
	var data := tree.node(EQUIP_ID)
	var level := tree.level(EQUIP_ID)
	var open := roundi(data.value(level))
	var next := roundi(data.value(level + 1)) if tree.next_level_open(EQUIP_ID) else open
	var all := roundi(data.value(data.max_level))
	var width := all * SLOT_SIZE + (all - 1) * SLOT_GAP
	var left := Vector2((JourneyPanel.CONTENT_WIDTH - width) * 0.5, 0)
	for i in all:
		var rect := Rect2(left + Vector2(i * (SLOT_SIZE + SLOT_GAP), 0), Vector2.ONE * SLOT_SIZE)
		_draw_slot(rect, i < open, i >= open and i < next)
		if i >= next:
			preview.draw_texture_rect(LOCK, Rect2(rect.get_center() - Vector2.ONE * 10.0, Vector2.ONE * 20.0), false, Color(1, 1, 1, 0.6))
	var i := 1
	var font := get_theme_default_font()
	while i < all:
		var act := data.act_needed(i - 1)
		var last := i
		while last + 1 < all and data.act_needed(last) == act:
			last += 1
		if act > 0:
			var from_x := left.x + i * (SLOT_SIZE + SLOT_GAP)
			var to_x := left.x + last * (SLOT_SIZE + SLOT_GAP) + SLOT_SIZE
			var y := SLOT_SIZE + 10.0
			var color := UiStyle.GOOD_COLOR if tree.acts_cleared >= act else JourneyPanel.CAPTION_COLOR
			preview.draw_polyline(PackedVector2Array([Vector2(from_x + 2, y - 4), Vector2(from_x + 2, y), Vector2(to_x - 2, y), Vector2(to_x - 2, y - 4)]), Color(color, 0.7), 1.5, true)
			var text := Lang.t("Act %d") % act
			var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiStyle.FONT_NOTE).x
			preview.draw_string(font, Vector2((from_x + to_x - text_width) * 0.5, y + 24.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiStyle.FONT_NOTE, color)
		i = last + 1


## The two boots, each lit once bought and outlined while it is the next
## level open to buy, its name under it in its own column.
func _draw_boots() -> void:
	var data := tree.node(BOOTS_ID)
	var level := tree.level(BOOTS_ID)
	var next := level + 1 if tree.next_level_open(BOOTS_ID) else level
	var font := get_theme_default_font()
	var left := (JourneyPanel.CONTENT_WIDTH - BOOT_COLUMN * 2.0) * 0.5
	for i in data.max_level:
		var column := left + i * BOOT_COLUMN
		var rect := Rect2(Vector2(column + (BOOT_COLUMN - BOOT_SLOT) * 0.5, 0), Vector2.ONE * BOOT_SLOT)
		_draw_slot(rect, i < level, i >= level and i < next)
		preview.draw_texture_rect(BOOTS_ICONS[i], rect.grow(-6.0), false, Color.WHITE if i < level else Color(1, 1, 1, 0.45))
		var color := UiStyle.TITLE_COLOR if i < level else UiStyle.DIM_COLOR
		preview.draw_multiline_string(font, Vector2(column + 12.0, rect.end.y + 8.0 + font.get_ascent(UiStyle.FONT_NOTE)), data.value_text(i + 1),
			HORIZONTAL_ALIGNMENT_CENTER, BOOT_COLUMN - 24.0, UiStyle.FONT_NOTE, 2, color)


## The 9 x 6 backpack: open cells lit, the next level's outlined.
func _draw_cells() -> void:
	var data := tree.node(BACKPACK_ID)
	var level := tree.level(BACKPACK_ID)
	var open := roundi(data.value(level))
	var next := roundi(data.value(level + 1)) if tree.next_level_open(BACKPACK_ID) else open
	var columns := BackpackScreen.COLUMNS
	var width := columns * (CELL + CELL_GAP) - CELL_GAP
	var left := (JourneyPanel.CONTENT_WIDTH - width) * 0.5
	for i in Inventory.BACKPACK_SIZE:
		var at := Vector2(left + (i % columns) * (CELL + CELL_GAP), (i / columns) * (CELL + CELL_GAP))
		_draw_slot(Rect2(at, Vector2.ONE * CELL), i < open, i >= open and i < next, 4)


func _draw_slot(rect: Rect2, open: bool, next: bool, radius := 6) -> void:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(radius)
	style.set_border_width_all(2)
	if open:
		style.bg_color = Color(UiStyle.GOLD_COLOR, 0.32)
		style.border_color = UiStyle.GOLD_COLOR
	elif next:
		style.bg_color = Color(UiStyle.GOLD_COLOR, 0.07)
		style.border_color = Color(UiStyle.GOLD_COLOR, 0.5)
	else:
		style.bg_color = Color(1, 1, 1, 0.03)
		style.border_color = Color(1, 1, 1, 0.12)
	preview.draw_style_box(style, rect)


# --- Layout and motion -------------------------------------------------------------


## The column fills the body down to the rule over the action; the action
## sits at the body's foot.
func _place() -> void:
	cost_bar.position = Vector2((JourneyPanel.CONTENT_WIDTH - CostBar.SIZE.x) * 0.5, BODY_HEIGHT - CostBar.SIZE.y)
	cost_bar.size = CostBar.SIZE
	_column.size = Vector2(JourneyPanel.CONTENT_WIDTH, _column.get_combined_minimum_size().y)


## The bottom of the column's content, in the body's coordinates.
func content_bottom() -> float:
	return _column.position.y + _column.get_combined_minimum_size().y


## The top of the action's rule, in the body's coordinates.
func action_top() -> float:
	return BODY_HEIGHT - CostBar.SIZE.y - JourneyPanel.GAP * 0.5


## The column fades and rises in when it shows something new; a refresh of
## the same thing stays still.
func _turn_to(key: String) -> void:
	if key == _turn_key:
		return
	var first := _turn_key == ""
	_turn_key = key
	if not first:
		UiMotion.enter(_column, TURN_RISE, UiMotion.BASE)


## `label` takes `text`; a change on the same subject crossfades in place.
func _set_text(label: Label, text: String) -> void:
	if label.text == text:
		return
	var same := _turn_key == "%s|%s|%s" % [branch, id, subject]
	label.text = text
	if same:
		_pulse(label)


func _pulse(item: CanvasItem) -> void:
	if UiMotion.off() or not is_inside_tree():
		return
	item.modulate.a = 0.3
	var tween := UiMotion.tween(item)
	tween.tween_property(item, ^"modulate:a", 1.0, UiMotion.FAST)


func _wrapped(label: Label) -> Label:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = JourneyPanel.CONTENT_WIDTH
	return label


func _draw() -> void:
	JourneyPanel.draw_top_glow(self, size.x, UiStyle.GOLD_COLOR, JourneyPanel.GLOW_ALPHA * 0.7)
	if cost_bar.visible:
		JourneyPanel.draw_rule(self, size.y - JourneyPanel.PAD - CostBar.SIZE.y - JourneyPanel.GAP * 0.5, size.x)
