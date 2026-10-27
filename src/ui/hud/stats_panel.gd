class_name StatsPanel
extends PanelContainer
## Lucian's combat stats, like LoL's stats panel.

const ROWS := ["AD", "AP", "AS", "Armor", "MR", "Crit", "MS"]

var lucian: Lucian
var _values: Array[Label] = []


func _ready() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 14)
	grid.add_theme_constant_override(&"v_separation", 2)
	add_child(grid)
	for row in ROWS:
		var name_label := Label.new()
		name_label.text = row
		name_label.add_theme_color_override(&"font_color", Color("9aa3b2"))
		grid.add_child(name_label)
		var value_label := Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.custom_minimum_size.x = 56
		grid.add_child(value_label)
		_values.append(value_label)


func _process(_delta: float) -> void:
	if lucian == null:
		return
	var stats := lucian.stats
	var texts := [
		str(roundi(stats.ad)),
		str(roundi(stats.ap)),
		"%.2f" % stats.attack_speed,
		str(roundi(stats.armor)),
		str(roundi(stats.mr)),
		"%d%%" % roundi(lucian.crit_chance() * 100.0),
		str(roundi(lucian.current_move_speed())),
	]
	for i in texts.size():
		_values[i].text = texts[i]
