class_name JourneySection
extends Control
## The Journey page of the main screen: a painted world map (JourneyMap) of
## the six acts on one road, with Training and the Endless portal, and beside
## it a panel (JourneyPanel) with the picked place, Start and the D/F spells.
## Places open along the Journey chain; a locked one can't be picked.
## Nothing here saves.

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
## The act just played, which the map opens on (0: none).
var focus_act := 0
## The map opens on Endless instead (after an Endless run), when it is open.
var focus_endless := false
## Endless's chosen map when the section opens (the last run's choice).
var endless_map := EndlessPlan.RANDOM


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	map.position = MAP_RECT.position
	map.node_chosen.connect(pick)
	add_child(map)
	panel.position = PANEL_RECT.position
	panel.start_pressed.connect(_on_start)
	add_child(panel)
	panel.choose_map(endless_map)
	SaveGame.instance().changed.connect(refresh)
	refresh()
	if focus_endless and not map.endless.locked:
		pick(map.endless)
	else:
		open_on(focus_act)


## Picks `act`'s first open stage not cleared yet (its last when all are)
## when `act` (just played) is open; else the next stage; else Training.
func open_on(act := 0) -> void:
	var cleared := SaveGame.instance().cleared
	if act > 0 and act <= Journey.ACTS.size() and Journey.is_act_open(act, cleared):
		var stage := 1
		while stage < Journey.stage_count(act) and Journey.stage_id(act, stage) in cleared \
				and Journey.is_stage_open(act, stage + 1, cleared):
			stage += 1
		pick(map.node_for(Journey.stage_id(act, stage)))
		return
	pick(map.token_node if map.token_node else map.training)


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


## Locks, opens and marks the map from the save, and refills the panel; a
## pick that has locked falls back as open_on() does.
func refresh() -> void:
	var save := SaveGame.instance()
	map.refresh(save.cleared, save.endless_best, Skins.find(save.skin).portrait)
	panel.show_best(save.endless_best)
	if picked == null or picked.locked:
		open_on()
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
