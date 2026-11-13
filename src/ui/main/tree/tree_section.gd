class_name TreeSection
extends Control
## "Go to Journey" in the info panel: the branch waits for an act.
signal journey_requested

## The Evolution Tree page of the main screen, laid out as the Journey: one
## frame of a TreePage per branch (one shown) and the NodeInfoPanel as a
## column on its right. The branch switch (BranchTabs) sits over the page's
## top band, inside the frame. The forge and Reset tree are quiet utilities at
## the top bar's right end, over the info column (shown with this section
## only). At rest the page's next step wears gold: a free level, else the cheapest one that
## can be bought now (next_step()). It opens on the first branch with a free
## upgrade, otherwise on Skills. The cost bar asks first (TreePurchasePopup).
## Buying, forging and resetting change the save in memory only; nothing here
## writes a file.

## In this section (the content area, y 72–992 on screen): the pages and the
## info column right of them, the Journey's map and panel rects.
const PAGE_RECT := Rect2(Vector2(32, 8), TreePage.SIZE)
## The switch, inside the page's top band.
const TABS_RECT := Rect2(PAGE_RECT.position + Vector2(40, 22), Vector2(1336, BranchTabs.HEIGHT))
const PANEL_RECT := Rect2(Vector2(1448, 8), JourneyPanel.SIZE)
## The utilities in the top bar (above this section), 16 under the screen's
## top, their right end over the info column's: clear of the main screen's
## toast, which is centred in the top bar and never reaches x 1300.
const UTILITIES_RIGHT := 1888.0
const UTILITIES_TOP := 16.0 - MainScreen.TOP_BAR
const UTILITY_GAP := 18
const RESET_FONT := 18
const PURPLE_ICON := preload("res://assets/art/ui/essence_purple.svg")
## How long a question's card takes to leave the page (UiMotion's close):
## a purchase or a reset plays after it.
const POPUP_GONE := UiMotion.EXIT + 0.03

## Branch -> its TreePage.
var pages := {}
## Node id -> its TreeNodeView, across every page.
var views := {}
var tabs := BranchTabs.new()
var info: NodeInfoPanel
var reset_button: Button
## Inside Reset tree: the words, the price and the purple icon, as one group.
var reset_price: HBoxContainer
var forge_bar: ForgeBar
## The forge and Reset tree, with a hairline before each.
var utilities := HBoxContainer.new()
## The main screen's Yes / No pop-up, set before the section is added.
var confirm: ConfirmPopup
## The open "buy this level?" question, or null.
var purchase: TreePurchasePopup
var tree: EvolutionTree
var essences: Essences
## The branch whose page shows.
var branch: StringName


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var save := SaveGame.instance()
	tree = save.tree
	essences = save.essences
	for branch_id: StringName in EvolutionTree.BRANCHES:
		var page := TreePage.new(branch_id, tree, essences)
		page.position = PAGE_RECT.position
		add_child(page)
		pages[branch_id] = page
		for id: StringName in page.views:
			views[id] = page.views[id]
			page.views[id].chosen.connect(select)

	tabs.position = TABS_RECT.position
	tabs.size = TABS_RECT.size
	tabs.branch_chosen.connect(show_branch)
	add_child(tabs)

	info = NodeInfoPanel.new(tree, essences)
	info.position = PANEL_RECT.position
	info.node_chosen.connect(select)
	info.cost_bar.buy_asked.connect(ask_buy)
	info.journey_asked.connect(journey_requested.emit)
	add_child(info)

	utilities.add_theme_constant_override(&"separation", UTILITY_GAP)
	utilities.alignment = BoxContainer.ALIGNMENT_END
	utilities.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	utilities.position = Vector2(UTILITIES_RIGHT, UTILITIES_TOP)
	utilities.resized.connect(func() -> void: utilities.position.x = UTILITIES_RIGHT - utilities.size.x)
	add_child(utilities)
	forge_bar = ForgeBar.new(essences)
	reset_button = Button.new()
	ForgeBar.quiet_style(reset_button, RESET_FONT)
	reset_price = UiStyle.price_row(Lang.t("Reset tree"), EvolutionTree.RESET_COST, PURPLE_ICON, RESET_FONT)
	reset_button.add_child(reset_price)
	reset_button.custom_minimum_size = Vector2(reset_price.get_combined_minimum_size().x + ForgeBar.PAD * 2.0, ForgeBar.HEIGHT)
	# Off most of the time: then only its dim words, no surface.
	reset_button.add_theme_stylebox_override(&"disabled", StyleBoxEmpty.new())
	reset_button.pressed.connect(_ask_reset)
	for part: Control in [forge_bar, _hairline(), reset_button]:
		part.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		utilities.add_child(part)
	# Their notes open left of the group, in the top bar's empty middle, so
	# they cover nothing (the kit's LEFT, measured from the whole group).
	for control: Control in [forge_bar.buttons[1], forge_bar.buttons[10], reset_button]:
		control.set_meta(&"hover_place", HoverTip.Place.LEFT)
		control.set_meta(&"hover_anchor", utilities)

	tree.changed.connect(refresh)
	essences.changed.connect(refresh)
	visibility_changed.connect(_on_visibility_changed)
	refresh()
	show_branch(_opening_branch())


## Shows `branch_id`'s page and lights its tab; the pick is cleared, so the
## info column sums up that branch. The old page crossfades to the new one
## and the tab's highlight slides.
func show_branch(branch_id: StringName) -> void:
	var old: TreePage = pages.get(branch)
	branch = branch_id
	for id: StringName in pages:
		if id != branch_id and pages[id] != old:
			pages[id].visible = false
	UiMotion.swap_body(old if old and old.visible else null, pages[branch_id])
	tabs.select(branch_id)
	_clear_pick()
	info.show_branch(branch_id)
	_mark_next()


## Picks node `id`: its page shows, it gets the white outline and the info
## column shows it.
func select(id: StringName) -> void:
	var node_branch := tree.node(id).branch
	if node_branch != branch:
		show_branch(node_branch)
	for view: TreeNodeView in views.values():
		view.selected = view.data.id == id
	info.show_node(id)
	_mark_next()


## Asks before buying node `id`'s next level (the cost bar's click), closing
## a question already open. From the panel at rest, the node is picked first,
## so the panel stays on it after the purchase.
func ask_buy(id: StringName) -> void:
	if info.id != id:
		select(id)
	if purchase:
		purchase.close()
	var opened := TreePurchasePopup.new(tree, id, essences)
	purchase = opened
	opened.confirmed.connect(_buy)
	opened.closed.connect(func() -> void:
		if purchase == opened:
			purchase = null)
	# Over the whole screen, beside the main screen's Yes / No question, so it
	# dims and blocks everything outside it (the top bar's forge and Reset
	# tree, the section bar) as that question does.
	question_host().add_child(opened)


## Where the purchase question goes: the main screen's question's parent
## (the whole screen), else this section.
func question_host() -> Node:
	return confirm.get_parent() if confirm and confirm.get_parent() else self


## Closes the buy question, else clears the pick, if there is one (the main
## screen's ESC calls this).
func close_popup() -> bool:
	if purchase:
		purchase.close()
		return true
	if info.id == &"":
		return false
	_clear_pick()
	info.show_branch(branch)
	_mark_next()
	return true


## Redraws the pages, the tabs, the info column and Reset tree from the save.
func refresh() -> void:
	for page: TreePage in pages.values():
		page.refresh()
	tabs.refresh(tree)
	info.refresh()
	reset_button.disabled = not tree.can_reset(essences)
	if tree.spent() == Vector2i.ZERO:
		reset_button.set_meta(&"hover_text", Lang.t("Nothing to refund: no blue or orange essence spent"))
	elif reset_button.disabled:
		reset_button.set_meta(&"hover_text", Lang.t("Needs %d purple essence") % EvolutionTree.RESET_COST)
	elif reset_button.has_meta(&"hover_text"):
		reset_button.remove_meta(&"hover_text")
	_mark_next()


## The next step on `branch_id`'s page: a free level first, else the cheapest
## level that can be bought now (blue plus orange at the forge's rate; the
## first in catalog order on a tie); &"" when nothing can be bought or claimed.
static func next_step(evolution_tree: EvolutionTree, owned: Essences, branch_id: StringName) -> StringName:
	var free := evolution_tree.free_ids(branch_id)
	if not free.is_empty():
		return free[0]
	var best: StringName = &""
	var best_cost := INF
	for data in evolution_tree.branch_nodes(branch_id):
		if not evolution_tree.can_buy(data.id, owned):
			continue
		var price := evolution_tree.cost(data.id)
		var weight := price.x + price.y * float(Essences.FORGE_BLUE)
		if weight < best_cost:
			best_cost = weight
			best = data.id
	return best


## Gold on the shown page's next step while nothing is picked.
func _mark_next() -> void:
	if info == null or branch == &"":
		return
	var marked: StringName = &"" if info.id != &"" else next_step(tree, essences, branch)
	for view: TreeNodeView in views.values():
		view.next = view.data.id == marked


## A short upright hairline between the top bar's groups.
func _hairline() -> Control:
	var line := Control.new()
	line.custom_minimum_size = Vector2(1, 28)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.draw.connect(func() -> void: line.draw_rect(Rect2(Vector2.ZERO, line.size), Color(UiStyle.BORDER_COLOR, 0.35)))
	return line


## The first branch with a free upgrade, else the first branch.
func _opening_branch() -> StringName:
	for branch_id: StringName in EvolutionTree.BRANCHES:
		if tree.has_free(branch_id):
			return branch_id
	return EvolutionTree.BRANCHES[0]


func _clear_pick() -> void:
	for view: TreeNodeView in views.values():
		view.selected = false


## The question's Buy: the purchase plays once its card has left the page.
func _buy(id: StringName) -> void:
	if info.cost_bar.id != id:
		return
	var page: TreePage = pages[tree.node(id).branch]
	page.lead_in = POPUP_GONE
	info.hold(POPUP_GONE)
	if not info.cost_bar.buy():
		page.lead_in = 0.0


## The question lives outside the section: it goes with it.
func _exit_tree() -> void:
	if purchase and is_instance_valid(purchase):
		purchase.queue_free()
	purchase = null


## A hidden tree closes its question, so it never shows on another page.
func _on_visibility_changed() -> void:
	if not visible and purchase:
		purchase.close()


func _ask_reset() -> void:
	if tree.can_reset(essences):
		confirm.ask(reset_question(), _reset)


## Reset tree's question, with what comes back: "Reset the Evolution Tree for
## 5 purple essence? 1200 blue and 10 orange essence come back."
func reset_question() -> String:
	var refund := tree.spent()
	var cost := EvolutionTree.RESET_COST
	if refund.x > 0 and refund.y > 0:
		return Lang.t("Reset the Evolution Tree for %d purple essence? %d blue and %d orange essence come back.") % [cost, refund.x, refund.y]
	if refund.y > 0:
		return Lang.t("Reset the Evolution Tree for %d purple essence? %d orange essence comes back.") % [cost, refund.y]
	return Lang.t("Reset the Evolution Tree for %d purple essence? %d blue essence comes back.") % [cost, refund.x]


func _reset() -> void:
	pages[branch].lead_in = POPUP_GONE
	info.hold(POPUP_GONE)
	if tree.reset(essences):
		Sfx.play(&"refresh")
