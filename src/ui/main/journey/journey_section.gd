class_name JourneySection
extends Control
## The Journey page of the main screen: a painted world map (JourneyMap) of
## the six acts on one road, with Training and the Endless portal, and beside
## it a panel (JourneyPanel) with the picked place, Start and the D/F spells.
## Lucian's token floats over the picked place. It always opens on the next
## stage, whatever was played before. Places open along the Journey chain; a
## locked one can't be picked. Nothing here saves.

signal start_training
signal start_stage(act: int, stage: int)
## Endless's Start: `map_choice` is a Journey.ENDLESS_MAPS index (0 is Random).
signal start_endless(map_choice: int)

## In this section (the content area, y 72–992 on screen): the map, and the
## opaque panel right of it.
const MAP_RECT := Rect2(32, 8, 1416, 904)
const PANEL_RECT := Rect2(1448, 8, 440, 904)

var map := JourneyMap.new()
var panel := JourneyPanel.new()
## The D/F spells, at the bottom of the panel.
var loadout: LoadoutPanel = panel.loadout
## The place the panel shows and Start plays.
var picked: JourneyNode

## What the map was last refreshed from: [cleared, endless_best, skin id].
## Empty until the first refresh.
var _map_inputs := []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	map.position = MAP_RECT.position
	map.node_chosen.connect(pick)
	add_child(map)
	panel.position = PANEL_RECT.position
	panel.start_pressed.connect(_on_start)
	add_child(panel)
	SaveGame.instance().changed.connect(refresh)
	# Nothing is picked yet, so the first refresh opens on the next stage.
	refresh()


## Picks the next stage (the first open one not cleared yet), or Training
## once every stage is cleared.
func open_on_next() -> void:
	pick(map.next_node if map.next_node else map.training)


## Shows `node` in the panel and outlines it; a locked place stays unpicked.
func pick(node: JourneyNode) -> void:
	if node == null or node.locked:
		return
	picked = node
	map.select(node)
	panel.show_node(node, SaveGame.instance())


## Closes the spell menu if it is open (the main screen's ESC calls this).
func close_popup() -> bool:
	return loadout.close_menu()


## Locks, opens and marks the map from the save, only when the stages cleared,
## Endless's best or the equipped skin changed since the last time (a spell
## pick leaves the map alone), and refills the panel with Endless's best and
## its map choice from the save; with no pick yet, or one that has locked,
## it opens on the next stage.
func refresh() -> void:
	var save := SaveGame.instance()
	var inputs := [save.cleared, save.endless_best, save.skin]
	if inputs != _map_inputs:
		map.refresh(save.cleared, save.endless_best, Skins.find(save.skin).portrait)
		_map_inputs = [save.cleared.duplicate(), save.endless_best, save.skin]
	panel.show_best(save.endless_best)
	if panel.map_choice() != save.endless_map:
		panel.choose_map(save.endless_map)
	if picked == null or picked.locked:
		open_on_next()
	else:
		pick(picked)


func _on_start() -> void:
	if picked == null or picked.locked:
		return
	match picked.kind:
		JourneyNode.TRAINING:
			start_training.emit()
		JourneyNode.ENDLESS:
			start_endless.emit(panel.map_choice())
		_:
			start_stage.emit(picked.act, picked.stage)
