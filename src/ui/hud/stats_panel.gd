class_name StatsPanel
extends PanelContainer
## Lucian's stats as icon + value cells, two per row, like LoL's stats panel.
## The HUD has two: MAIN (Ctrl + the stats key toggles it) and EXTRA (shown
## while the stats key is held). Set `keys` before adding it to the tree.

const MAIN: Array[StringName] = [
	&"ad", &"ap", &"armor", &"mr", &"attack_speed", &"ability_haste", &"crit_chance", &"move_speed",
]
const EXTRA: Array[StringName] = [
	&"regen", &"heal_shield_power", &"armor_pen", &"magic_pen",
	&"lifesteal", &"omnivamp", &"attack_range", &"tenacity",
]

var lucian: Lucian
var keys: Array[StringName] = MAIN

var _cells: Array[StatCell] = []


func _ready() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 18)
	grid.add_theme_constant_override(&"v_separation", 4)
	add_child(grid)
	for key in keys:
		var cell := StatCell.new(key)
		grid.add_child(cell)
		_cells.append(cell)


func _process(_delta: float) -> void:
	if lucian == null or not visible:
		return
	for cell in _cells:
		cell.set_value(value_text(lucian, cell.key))


## The number shown for `key`. Uses Lucian's live values where they differ
## from his stats: the crit cheat, move speed buffs, Rapid Firecannon's range.
## Regen is "health / mana" per second, like the HUD bars.
static func value_text(target: Lucian, key: StringName) -> String:
	var stats := target.stats
	match key:
		&"attack_speed":
			return "%.2f" % stats.attack_speed
		&"crit_chance":
			return "%d%%" % roundi(target.crit_chance() * 100.0)
		&"move_speed":
			return str(roundi(target.current_move_speed()))
		&"attack_range":
			return str(roundi(target.attack_range()))
		&"regen":
			return "%s / %s" % [TooltipText.number(snappedf(stats.hp_regen, 0.1)), TooltipText.number(snappedf(stats.mana_regen, 0.1))]
	if ItemStats.is_percent(key):
		return "%d%%" % roundi(stats.get(key) * 100.0)
	return str(roundi(stats.get(key)))
