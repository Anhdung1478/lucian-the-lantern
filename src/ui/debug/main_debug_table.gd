class_name MainDebugTable
extends DebugPanel
## Testing panel for the main screen, toggled with F3 + Q: essences, acts
## cleared, the Evolution Tree and a progress reset. Everything happens in
## memory; nothing is saved until the gear menu's Save.

const ACTS := 6
## Per essence kind: its name and the amounts of its + buttons.
const ESSENCE_ROWS := [
	[Essences.BLUE, "Blue", [100, 1000, 10000]],
	[Essences.ORANGE, "Orange", [1, 10, 100]],
	[Essences.PURPLE, "Purple", [1, 10, 100]],
]


func _ready() -> void:
	super()
	_build()


func _build() -> void:
	var outer := _build_frame("DEBUG   (F3 + Q)")
	var tabs := TabContainer.new()
	tabs.focus_mode = Control.FOCUS_NONE
	tabs.get_tab_bar().focus_mode = Control.FOCUS_NONE
	outer.add_child(tabs)

	var box := _tab(tabs, "Essences")
	for entry: Array in ESSENCE_ROWS:
		var kind: StringName = entry[0]
		var row := _row(box)
		var name_label := _label(row, entry[1])
		name_label.custom_minimum_size.x = 60.0
		for amount: int in entry[2]:
			_button(row, "+%d" % amount, func() -> void: SaveGame.instance().essences.add(kind, amount))
		_button(row, "Reset", func() -> void: SaveGame.instance().essences.set_amount(kind, 0))

	box = _tab(tabs, "Progress")
	_section(box, "Journey")
	var row := _row(box)
	_label(row, "Acts cleared")
	var acts := _spin(row, 0, ACTS, 0)
	acts.value_changed.connect(func(value: float) -> void:
		SaveGame.instance().set_cleared(Journey.all_stage_ids(int(value))))
	_section(box, "Evolution Tree")
	row = _row(box)
	_button(row, "Max tree (free)", func() -> void: SaveGame.instance().tree.max_all())
	_button(row, "Clear tree (no refund)", func() -> void: SaveGame.instance().tree.clear())
	_section(box, "Save")
	_button(box, "Reset progress", func() -> void: SaveGame.instance().reset())
	_label(box, "A new game in memory; nothing is saved until you save.")
