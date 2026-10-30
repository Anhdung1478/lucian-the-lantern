class_name TreeSection
extends Control
## The Evolution Tree page of the main screen: one TreePage per branch, with
## the BranchTabs under them to switch pages, Reset tree at the top right of
## the page, and the NodeInfoPanel as a column on the right (as the Journey's
## map and panel). It opens on the first branch with a free upgrade, otherwise
## on Skills. Buying and resetting change the save in memory only; nothing
## here writes a file.

## In this section (the content area, y 72–992 on screen): the pages, the tabs
## hanging under them, and the info column right of both.
const PAGE_RECT := Rect2(Vector2(32, 8), TreePage.SIZE)
const TABS_RECT := Rect2(32, 848, 1416, BranchTabs.HEIGHT)
const PANEL_RECT := Rect2(Vector2(1448, 8), JourneyPanel.SIZE)
const MARGIN := 24.0
## How far in from the page's sides the tabs start.
const TABS_INSET := 24.0
const RESET_SIZE := Vector2(260, 52)
const PURPLE_ICON := preload("res://assets/art/ui/essence_purple.svg")

## Branch -> its TreePage.
var pages := {}
## Node id -> its TreeNodeView, across every page.
var views := {}
var tabs := BranchTabs.new()
var info: NodeInfoPanel
var reset_button: Button
## The main screen's Yes / No pop-up, set before the section is added.
var confirm: ConfirmPopup
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
	add_child(info)

	reset_button = Button.new()
	reset_button.text = "Reset tree  %d" % EvolutionTree.RESET_COST
	reset_button.icon = PURPLE_ICON
	reset_button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reset_button.expand_icon = true
	reset_button.add_theme_constant_override(&"icon_max_width", 30)
	reset_button.position = PAGE_RECT.position + Vector2(PAGE_RECT.size.x - MARGIN - RESET_SIZE.x, MARGIN)
	reset_button.size = RESET_SIZE
	UiStyle.style_button(reset_button, 22)
	reset_button.pressed.connect(_ask_reset)
	add_child(reset_button)

	tree.changed.connect(refresh)
	essences.changed.connect(refresh)
	refresh()
	show_branch(_opening_branch())


## Shows `branch_id`'s page and lights its tab; the pick is cleared, so the
## info column sums up that branch.
func show_branch(branch_id: StringName) -> void:
	branch = branch_id
	for id: StringName in pages:
		pages[id].visible = id == branch_id
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


## Clears the pick if there is one (the main screen's ESC calls this).
func close_popup() -> bool:
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


## The first branch with a free upgrade, else the first branch.
func _opening_branch() -> StringName:
	for branch_id: StringName in EvolutionTree.BRANCHES:
		if tree.has_free(branch_id):
			return branch_id
	return EvolutionTree.BRANCHES[0]


func _clear_pick() -> void:
	for view: TreeNodeView in views.values():
		view.selected = false


func _ask_reset() -> void:
	confirm.ask("Reset the Evolution Tree for %d purple essence? Every blue and orange essence spent comes back." % EvolutionTree.RESET_COST, _reset)


func _reset() -> void:
	if tree.reset(essences):
		Sfx.play(&"refresh")
