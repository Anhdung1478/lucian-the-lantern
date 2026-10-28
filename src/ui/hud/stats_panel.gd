class_name StatsPanel
extends PanelContainer
## Lucian's stats as icon + value cells, two per row, like LoL's stats panel.
## A value with a bonus over Lucian's level alone shows in yellow, and its
## hover card breaks it down. The HUD has two: MAIN (Ctrl + the stats key
## toggles it) and EXTRA (shown while the stats key is held). Set `keys`
## before adding it to the tree.

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
		cell.show_value(value_text(lucian, cell.key), has_bonus(lucian, cell.key), breakdown(lucian, cell.key))


## The number shown for `key`. Regen is "health / mana" per second, like the
## HUD bars.
static func value_text(target: Lucian, key: StringName) -> String:
	if key == &"regen":
		return "%s / %s" % [_format(&"hp_regen", _amounts(target, &"hp_regen").y), _format(&"mana_regen", _amounts(target, &"mana_regen").y)]
	return _format(key, _amounts(target, key).y)


## True when `key` differs from what Lucian's level alone gives (items,
## passives, buffs, cheats), as shown.
static func has_bonus(target: Lucian, key: StringName) -> bool:
	if key == &"regen":
		return has_bonus(target, &"hp_regen") or has_bonus(target, &"mana_regen")
	var amounts := _amounts(target, key)
	return _format(key, amounts.x) != _format(key, amounts.y)


## "60 base + 22 bonus" (the bonus in yellow) for the hover card. Regen has a
## line for health and one for mana.
static func breakdown(target: Lucian, key: StringName) -> String:
	if key == &"regen":
		return "Health %s\nMana %s" % [breakdown(target, &"hp_regen"), breakdown(target, &"mana_regen")]
	var amounts := _amounts(target, key)
	var text := "%s base" % _format(key, amounts.x)
	if has_bonus(target, key):
		var sign := "+" if amounts.y >= amounts.x else "−"
		text += " %s %s" % [sign, TooltipText.color("%s bonus" % _format(key, absf(amounts.y - amounts.x)), StatCell.BONUS_COLOR.to_html(false))]
	return text


## (base, total): the base is Lucian's level alone; the total uses his live
## values where they differ from his stats (the crit cheat, move speed buffs,
## Rapid Firecannon's range).
static func _amounts(target: Lucian, key: StringName) -> Vector2:
	var base := target.base_stats.at_level(target.progress.level)
	match key:
		&"crit_chance":
			return Vector2(base.crit_chance, target.crit_chance())
		&"move_speed":
			return Vector2(base.move_speed, target.current_move_speed())
		&"attack_range":
			return Vector2(base.attack_range, target.attack_range())
	return Vector2(base.get(key), target.stats.get(key))


static func _format(key: StringName, value: float) -> String:
	match key:
		&"attack_speed":
			return "%.2f" % value
		&"hp_regen", &"mana_regen":
			return TooltipText.number(snappedf(value, 0.1))
	if ItemStats.is_percent(key):
		return "%d%%" % roundi(value * 100.0)
	return str(roundi(value))
