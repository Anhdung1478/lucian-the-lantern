class_name TreeSection
extends Control
## The Evolution Tree page of the main screen: the forest map, the info panel
## of the chosen node (bottom-right) and Reset tree (top-right). Buying and
## resetting change the save in memory only; nothing here writes a file.

const MARGIN := 24.0
const RESET_SIZE := Vector2(260, 52)
const PURPLE_ICON := preload("res://assets/art/ui/essence_purple.svg")

var map: TreeMap
var info: NodeInfoPanel
var reset_button: Button
## The main screen's Yes / No pop-up, set before the section is added.
var confirm: ConfirmPopup
var tree: EvolutionTree
var essences: Essences


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var save := SaveGame.instance()
	tree = save.tree
	essences = save.essences
	map = TreeMap.new(tree, essences)
	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map.right_room = NodeInfoPanel.WIDTH + MARGIN
	add_child(map)
	for view: TreeNodeView in map.views.values():
		view.chosen.connect(select)

	info = NodeInfoPanel.new(tree, essences)
	info.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	info.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	info.grow_vertical = Control.GROW_DIRECTION_BEGIN
	info.offset_left = -MARGIN
	info.offset_right = -MARGIN
	info.offset_top = -MARGIN
	info.offset_bottom = -MARGIN
	add_child(info)

	reset_button = Button.new()
	reset_button.text = "Reset tree  %d" % EvolutionTree.RESET_COST
	reset_button.icon = PURPLE_ICON
	reset_button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reset_button.expand_icon = true
	reset_button.add_theme_constant_override(&"icon_max_width", 30)
	reset_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	reset_button.offset_left = -(RESET_SIZE.x + MARGIN)
	reset_button.offset_right = -MARGIN
	reset_button.offset_top = MARGIN
	reset_button.offset_bottom = MARGIN + RESET_SIZE.y
	UiStyle.style_button(reset_button, 22)
	reset_button.pressed.connect(_ask_reset)
	add_child(reset_button)

	tree.changed.connect(refresh)
	essences.changed.connect(refresh)
	refresh()


## Chooses node `id`: it gets the white outline and the info panel opens on it.
func select(id: StringName) -> void:
	for view: TreeNodeView in map.views.values():
		view.selected = view.data.id == id
	info.show_node(id)


## Closes the info panel if it is open (the main screen's ESC calls this).
func close_popup() -> bool:
	if not info.visible:
		return false
	info.visible = false
	info.id = &""
	for view: TreeNodeView in map.views.values():
		view.selected = false
	return true


## Redraws the map, the info panel and Reset tree from the save.
func refresh() -> void:
	map.refresh()
	info.refresh()
	reset_button.disabled = not tree.can_reset(essences)


func _ask_reset() -> void:
	confirm.ask("Reset the Evolution Tree for %d purple essence? Every blue and orange essence spent comes back." % EvolutionTree.RESET_COST, _reset)


func _reset() -> void:
	if tree.reset(essences):
		Sfx.play(&"refresh")
