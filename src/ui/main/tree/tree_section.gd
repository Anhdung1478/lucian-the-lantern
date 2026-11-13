class_name TreeSection
extends Control
## The Evolution Tree page of the main screen: one TreePage per branch, with
## the BranchTabs under them to switch pages, Reset tree at the top right of
## the page with the ForgeBar beside it, and the NodeInfoPanel as a column on
## the right (as the Journey's map and panel). It opens on the first branch with a free upgrade, otherwise
## on Skills. The cost bar asks first (TreePurchasePopup). Buying, forging and
## resetting change the save in memory only; nothing here writes a file.

## In this section (the content area, y 72–992 on screen): the pages, the tabs
## hanging under them, and the info column right of both.
const PAGE_RECT := Rect2(Vector2(32, 8), TreePage.SIZE)
const TABS_RECT := Rect2(PAGE_RECT.position.x, 848, PAGE_RECT.size.x, BranchTabs.HEIGHT)
const PANEL_RECT := Rect2(Vector2(1448, 8), JourneyPanel.SIZE)
const MARGIN := 24.0
## How far in from the page's sides the tabs start.
const TABS_INSET := 24.0
const RESET_SIZE := Vector2(260, 52)
## The forge sits left of Reset tree, clear of the tree's top and the header.
const FORGE_GAP := 20.0
const PURPLE_ICON := preload("res://assets/art/ui/essence_purple.svg")

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

	tabs.position = TABS_RECT.position + Vector2(TABS_INSET, 0)
	tabs.size = TABS_RECT.size - Vector2(TABS_INSET * 2.0, 0)
	tabs.branch_chosen.connect(show_branch)
	add_child(tabs)

	info = NodeInfoPanel.new(tree, essences)
	info.position = PANEL_RECT.position
	info.node_chosen.connect(select)
	info.cost_bar.buy_asked.connect(ask_buy)
	add_child(info)

	reset_button = Button.new()
	reset_button.position = PAGE_RECT.position + Vector2(PAGE_RECT.size.x - MARGIN - RESET_SIZE.x, MARGIN)
	reset_button.size = RESET_SIZE
	UiStyle.style_button(reset_button, 22)
	reset_price = UiStyle.price_row(Lang.t("Reset tree"), EvolutionTree.RESET_COST, PURPLE_ICON, 22)
	reset_button.add_child(reset_price)
	reset_button.pressed.connect(_ask_reset)
	add_child(reset_button)

	forge_bar = ForgeBar.new(essences)
	forge_bar.position = reset_button.position - Vector2(FORGE_GAP + ForgeBar.SIZE.x, 0)
	add_child(forge_bar)

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


## Picks node `id`: its page shows, it gets the white outline and the info
## column shows it.
func select(id: StringName) -> void:
	var node_branch := tree.node(id).branch
	if node_branch != branch:
		show_branch(node_branch)
	for view: TreeNodeView in views.values():
		view.selected = view.data.id == id
	info.show_node(id)


## Asks before buying node `id`'s next level (the cost bar's click), closing
## a question already open.
func ask_buy(id: StringName) -> void:
	if purchase:
		purchase.close()
	var opened := TreePurchasePopup.new(tree, id, essences)
	purchase = opened
	opened.confirmed.connect(_buy)
	opened.closed.connect(func() -> void:
		if purchase == opened:
			purchase = null)
	add_child(opened)


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


## The first branch with a free upgrade, else the first branch.
func _opening_branch() -> StringName:
	for branch_id: StringName in EvolutionTree.BRANCHES:
		if tree.has_free(branch_id):
			return branch_id
	return EvolutionTree.BRANCHES[0]


func _clear_pick() -> void:
	for view: TreeNodeView in views.values():
		view.selected = false


func _buy(id: StringName) -> void:
	if info.cost_bar.id == id and info.cost_bar.buy():
		views[id].bump()


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
	if tree.reset(essences):
		Sfx.play(&"refresh")
