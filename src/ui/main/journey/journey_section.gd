class_name JourneySection
extends Control
## The Journey page of the main screen: tabs Act 1 to Act 6, Training and
## Endless across the top, the open tab's page on the left and the D/F
## loadout on the right. It opens on Training. Tabs unlock along the Journey
## chain. Nothing here saves.

signal start_training

const TRAINING_TAB := 6
const ENDLESS_TAB := 7
const MARGIN := 32.0

## Act 1 to 6, Training, Endless.
var tabs: Array[JourneyTab] = []
var act_pages: Array[ActPage] = []
var training_page := TrainingPage.new()
var endless_page := EndlessPage.new()
var loadout := LoadoutPanel.new()
var current := 0

var _pages: Array[Control] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override(&"separation", 8)
	tab_row.position = Vector2(MARGIN, 20)
	add_child(tab_row)
	var names: Array[String] = []
	for act in range(1, Journey.ACTS.size() + 1):
		names.append("Act %d" % act)
	names.append("Training")
	names.append("Endless")
	for i in names.size():
		var tab := JourneyTab.new(names[i])
		tab.pressed.connect(show_tab.bind(i))
		tab_row.add_child(tab)
		tabs.append(tab)
	var page_area := Control.new()
	page_area.position = Vector2(MARGIN, 100)
	page_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(page_area)
	for act in range(1, Journey.ACTS.size() + 1):
		var page := ActPage.new(act)
		page_area.add_child(page)
		act_pages.append(page)
		_pages.append(page)
	training_page.start_pressed.connect(start_training.emit)
	page_area.add_child(training_page)
	page_area.add_child(endless_page)
	_pages.append(training_page)
	_pages.append(endless_page)
	loadout.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	loadout.offset_left = -(LoadoutPanel.WIDTH + MARGIN)
	loadout.offset_right = -MARGIN
	loadout.offset_top = 100.0
	add_child(loadout)
	var save := SaveGame.instance()
	save.changed.connect(refresh)
	save.tree.changed.connect(refresh)
	refresh()
	show_tab(TRAINING_TAB)


## Shows tab `index`; a locked tab stays closed.
func show_tab(index: int) -> void:
	if index < 0 or index >= tabs.size() or tabs[index].locked:
		return
	current = index
	for i in _pages.size():
		_pages[i].visible = i == index
		tabs[i].set_selected(i == index)


## Closes the spell menu if it is open (the main screen's ESC calls this).
func close_popup() -> bool:
	return loadout.close_menu()


## Locks and opens the tabs and cards from the save.
func refresh() -> void:
	var save := SaveGame.instance()
	for i in act_pages.size():
		tabs[i].set_locked(not Journey.is_act_open(i + 1, save.cleared), "Clear Act %d first" % i)
		act_pages[i].refresh(save.cleared)
	tabs[ENDLESS_TAB].set_locked(not Journey.is_endless_open(save.cleared), "Clear Act %d first" % Journey.ENDLESS_ACT)
	endless_page.refresh(save.endless_best)
	if tabs[current].locked:
		show_tab(0)
