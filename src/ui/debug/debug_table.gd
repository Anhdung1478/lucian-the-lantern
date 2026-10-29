class_name DebugTable
extends DebugPanel
## Testing panel, toggled with F3 + Q (hidden by default), in tabs: Lucian
## (level, cheats, summoner spells), Items, Shop (gold), Waves (skip, kill all,
## spawn, boss wave, God mode) and Dummy (settings, DPS meter, hit log). Keeps working while the game is paused, so items can be given into an
## open backpack.

const LOG_SIZE := 10
const ENEMY_DIR := "res://data/enemies"

var stage: Stage
var lucian: Lucian
var dummy: TrainingDummy

var _meter := DpsMeter.new()
## Seconds of unpaused play, so pauses never split a DPS session.
var _game_time := 0.0
## Newest first: [source, raw, final, is_crit].
var _hits: Array[Array] = []

var _level_info: Label
var _level_value: SpinBox
var _crit_toggle: CheckBox
var _crit_value: SpinBox
var _item_picker: OptionButton
var _enemy_picker: OptionButton
## The picker's items, A to Z.
var _picker_items: Array[ItemData] = []
var _equip_slots: SpinBox
var _shop_slots: SpinBox
## D and F.
var _summoner_pickers: Array[OptionButton] = []
var _item_stats: Label
var _armor: SpinBox
var _mr: SpinBox
var _max_hp: SpinBox
var _dps_label: Label
var _log_label: RichTextLabel
var _gold_label: Label
var _wave_label: Label
var _tabs: TabContainer
var _dummy_tab := 0


func _ready() -> void:
	super()
	_build()


func setup(owner_stage: Stage) -> void:
	stage = owner_stage
	lucian = stage.lucian
	dummy = stage.dummy
	if dummy:
		watch(dummy)
		_armor.set_value_no_signal(dummy.armor)
		_mr.set_value_no_signal(dummy.mr)
		_max_hp.set_value_no_signal(dummy.max_hp)
	else:
		_tabs.set_tab_hidden(_dummy_tab, true)
	_picker_items = lucian.item_catalog.by_name()
	for item in _picker_items:
		_item_picker.add_item(item.display_name)
	_equip_slots.set_value_no_signal(lucian.inventory.unlocked_equip)
	_shop_slots.set_value_no_signal(stage.shop_slots)
	_show_summoners()


## Adds a dummy's hits to the DPS meter and the hit log.
func watch(target: Enemy) -> void:
	target.damage_taken.connect(_on_damage_taken)


## Moves the table to the top-right while the backpack's recipe table needs
## the top-left. Top-left otherwise, where it never covers the dummy.
func set_docked_right(right: bool) -> void:
	var width := get_viewport().get_visible_rect().size.x
	_panel.position.x = width - _panel.size.x - 12.0 if right else 12.0


func _process(_delta: float) -> void:
	if not visible or lucian == null:
		return
	var progress := lucian.progress
	_level_info.text = "Level %d   XP %d / %d   Skill points %d" % [
		progress.level, progress.xp, progress.xp_for_next(), progress.skill_points()]
	_dps_label.text = "DPS %.1f   Total %d   %.1f s" % [_meter.dps(), roundi(_meter.total), _meter.elapsed()]
	_gold_label.text = "Gold %d" % stage.wallet.gold
	var runner := stage.runner
	if runner:
		_wave_label.text = "Wave %d / %d   state %s   alive %d   next %s" % [
			runner.wave, runner.total_waves(), WaveRunner.State.find_key(runner.state),
			runner.alive(), "%.1f s" % runner.countdown()]
	else:
		_wave_label.text = "Training: no waves"
	var stats := lucian.stats
	_item_stats.text = "AH %d   Life steal %d%%   Omnivamp %d%%   Pen %d%% / %d%%" % [
		roundi(stats.ability_haste), roundi(stats.lifesteal * 100.0), roundi(stats.omnivamp * 100.0),
		roundi(stats.armor_pen * 100.0), roundi(stats.magic_pen * 100.0)]


func _physics_process(delta: float) -> void:
	if not get_tree().paused:
		_game_time += delta


func _on_damage_taken(info: DamageInfo, final_amount: float) -> void:
	_meter.record(final_amount, _game_time)
	_hits.push_front([info.source, info.amount, final_amount, info.is_crit])
	if _hits.size() > LOG_SIZE:
		_hits.pop_back()
	var text := "[table=4][cell][color=#9aa3b2]source   [/color][/cell][cell][color=#9aa3b2]raw   [/color][/cell]" \
		+ "[cell][color=#9aa3b2]final   [/color][/cell][cell][/cell]"
	for hit in _hits:
		text += "[cell]%s   [/cell][cell]%d   [/cell][cell]%d   [/cell][cell]%s[/cell]" % [
			hit[0], roundi(hit[1]), roundi(hit[2]), "[color=#ffcf5a]CRIT[/color]" if hit[3] else ""]
	_log_label.text = text + "[/table]"


func _apply_crit(_value: Variant = null) -> void:
	lucian.cheat_crit_chance = _crit_value.value / 100.0 if _crit_toggle.button_pressed else -1.0


func _apply_dummy(_value: float) -> void:
	if dummy == null:
		return
	dummy.set_defenses(_armor.value, _mr.value, _max_hp.value)


func _give_picked_item() -> void:
	lucian.inventory.add(_picker_items[_item_picker.selected])


## Picking the spell the other key has swaps the two, so both pickers follow.
func _pick_summoner(index: int, slot: int) -> void:
	# Index 0 is "None".
	lucian.summoners.set_spell(slot, &"" if index == 0 else SummonerSpells.SPELLS[index - 1].id)
	if slot == 1:
		lucian.summoners.open_slots = 2
	_show_summoners()


## Debug: every skill rank and the passive, as if bought in the Evolution Tree.
func _buy_all_ranks() -> void:
	lucian.progress.bought = ChampionProgress.MAX_RANKS.duplicate()
	lucian.passive.learned = true


func _show_summoners() -> void:
	for slot in _summoner_pickers.size():
		_summoner_pickers[slot].select(SummonerSpells.SPELLS.find(SummonerSpells.find(lucian.summoners.slots[slot])) + 1)


func _kill_all() -> void:
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if not enemy is TrainingDummy:
			enemy.take_damage(lucian.make_damage(999999.0, DamageInfo.Type.TRUE, &"debug"))


## A minion near the cursor; it counts toward the wave.
func _spawn(id: StringName) -> void:
	stage.spawn_enemy(id, lucian.get_global_mouse_position())
	if stage.runner:
		stage.runner.enemy_spawned()


## Every enemy id in data/enemies, sorted. Exported builds list `.tres.remap` files.
func _enemy_ids() -> Array[String]:
	var ids: Array[String] = []
	for file in DirAccess.get_files_at(ENEMY_DIR):
		file = file.trim_suffix(".remap")
		if file.ends_with(".tres"):
			ids.append(file.get_basename())
	ids.sort()
	return ids


func _spawn_picked() -> void:
	if _enemy_picker.selected >= 0:
		_spawn(StringName(_enemy_picker.get_item_text(_enemy_picker.selected)))


## The boss (kind "boss", not a mini boss) goes to 51%. The Elder Dragon leaves the
## group mid-dive, so stage.boss_unit is checked as well.
func _boss_to_51() -> void:
	var units: Array[EnemyUnit] = []
	if stage.boss_unit:
		units.append(stage.boss_unit)
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if enemy is EnemyUnit and not units.has(enemy):
			units.append(enemy)
	for unit in units:
		if unit.data.kind == &"boss":
			unit.hp = unit.max_hp * 0.51
			unit.health_bar.set_health(unit.hp, unit.max_hp)


func _give_random_fragment() -> void:
	lucian.inventory.add(lucian.item_catalog.fragments().pick_random())


func _build() -> void:
	var outer := _build_frame("DEBUG   (F3 + Q)")
	var tabs := TabContainer.new()
	_tabs = tabs
	tabs.focus_mode = Control.FOCUS_NONE
	tabs.get_tab_bar().focus_mode = Control.FOCUS_NONE
	outer.add_child(tabs)

	var box := _tab(tabs, "Lucian")
	_section(box, "Level")
	_level_info = _label(box, "")
	var row := _row(box)
	_button(row, "+100 XP", func() -> void: lucian.progress.add_xp(100))
	_button(row, "Level +1", func() -> void: lucian.progress.set_level(lucian.progress.level + 1))
	_button(row, "Level -1", func() -> void: lucian.progress.set_level(lucian.progress.level - 1))
	row = _row(box)
	_level_value = _spin(row, 1, 18, 1)
	_button(row, "Set level", func() -> void: lucian.progress.set_level(int(_level_value.value)))
	_button(row, "Reset skill ranks", func() -> void: lucian.progress.reset_ranks())
	_button(row, "Buy all ranks", _buy_all_ranks)
	row = _row(box)
	_button(row, "Lucian HP 50%", func() -> void: lucian.hp = lucian.stats.max_hp * 0.5)

	_section(box, "Cheats")
	_check(box, "No cooldowns").toggled.connect(func(on: bool) -> void: lucian.cheat_no_cooldowns = on)
	_check(box, "Infinite mana").toggled.connect(func(on: bool) -> void: lucian.cheat_infinite_mana = on)
	row = _row(box)
	_crit_toggle = _check(row, "Crit chance override (%)")
	_crit_toggle.toggled.connect(_apply_crit)
	_crit_value = _spin(row, 0, 100, 100)
	_crit_value.value_changed.connect(_apply_crit)

	_section(box, "Summoner spells")
	row = _row(box)
	for slot in 2:
		_label(row, "D" if slot == 0 else "F")
		var picker := OptionButton.new()
		picker.focus_mode = Control.FOCUS_NONE
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		picker.add_item("None")
		for spell in SummonerSpells.SPELLS:
			picker.add_item(spell.display_name)
		picker.item_selected.connect(_pick_summoner.bind(slot))
		row.add_child(picker)
		_summoner_pickers.append(picker)

	box = _tab(tabs, "Items")
	_section(box, "Items")
	row = _row(box)
	_item_picker = OptionButton.new()
	_item_picker.focus_mode = Control.FOCUS_NONE
	_item_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_item_picker)
	_button(row, "Give", _give_picked_item)
	row = _row(box)
	_button(row, "Random fragment", _give_random_fragment)
	_button(row, "Clear items", func() -> void: lucian.inventory.clear())
	_button(row, "+HP potion", func() -> void: lucian.inventory.add(lucian.item_catalog.find(&"hp_potion")))
	_button(row, "+MP potion", func() -> void: lucian.inventory.add(lucian.item_catalog.find(&"mp_potion")))
	_button(row, "Energize now", func() -> void: lucian.passives.energize.value = EnergizeCharge.MAX)
	row = _row(box)
	_label(row, "Equip slots")
	_equip_slots = _spin(row, 1, Inventory.EQUIP_SIZE, Inventory.EQUIP_SIZE)
	_equip_slots.value_changed.connect(func(value: float) -> void: lucian.inventory.unlocked_equip = int(value))
	_item_stats = _label(box, "")

	box = _tab(tabs, "Shop")
	_section(box, "Stage gold")
	_gold_label = _label(box, "")
	row = _row(box)
	for amount in [100, 1000, 10000]:
		_button(row, "+%d" % amount, func() -> void: stage.wallet.add(amount))
	_button(row, "Reset", func() -> void: stage.wallet.reset())
	_section(box, "Merchant")
	row = _row(box)
	_button(row, "Add merchant", func() -> void: stage.add_merchant())
	_button(row, "Remove merchant", func() -> void: stage.remove_merchant())
	row = _row(box)
	_label(row, "Shop item slots")
	var slots := _spin(row, 1, MerchantStock.SLOTS, 2)
	_shop_slots = slots
	slots.value_changed.connect(func(value: float) -> void: stage.set_shop_slots(int(value)))

	box = _tab(tabs, "Waves")
	_section(box, "Waves")
	_wave_label = _label(box, "")
	row = _row(box)
	_button(row, "Skip break", func() -> void: stage.skip_break())
	_button(row, "Kill all enemies", _kill_all)
	_button(row, "Jump to boss wave", func() -> void: stage.jump_to_boss_wave())
	row = _row(box)
	_enemy_picker = OptionButton.new()
	_enemy_picker.focus_mode = Control.FOCUS_NONE
	_enemy_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for id in _enemy_ids():
		_enemy_picker.add_item(id)
	row.add_child(_enemy_picker)
	_button(row, "Spawn", _spawn_picked)
	row = _row(box)
	_button(row, "Boss HP 51%", _boss_to_51)
	_check(box, "God mode (no damage)").toggled.connect(func(on: bool) -> void: stage.lucian.invulnerable = on)

	box = _tab(tabs, "Dummy")
	_dummy_tab = tabs.get_tab_count() - 1
	_section(box, "Training dummy")
	var grid := GridContainer.new()
	grid.columns = 6
	box.add_child(grid)
	_label(grid, "Armor")
	_armor = _spin(grid, -100, 1000, 30)
	_label(grid, "MR")
	_mr = _spin(grid, -100, 1000, 30)
	_label(grid, "Max HP")
	_max_hp = _spin(grid, 1, 100000, 2000)
	for spin in [_armor, _mr, _max_hp]:
		spin.value_changed.connect(_apply_dummy)
	row = _row(box)
	_label(row, "Dummies (for Runaan's / Statikk)")
	var count := _spin(row, 1, 5, 1)
	count.value_changed.connect(func(value: float) -> void:
		if dummy:
			stage.set_dummy_count(int(value)))

	# The DPS meter and hit log stay under the tabs, always in view.
	_section(outer, "Damage")
	row = _row(outer)
	_dps_label = _label(row, "")
	_dps_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(row, "Reset DPS", func() -> void: _meter.reset())
	_log_label = RichTextLabel.new()
	_log_label.bbcode_enabled = true
	_log_label.fit_content = true
	_log_label.scroll_active = false
	_log_label.custom_minimum_size.x = PANEL_WIDTH - 24.0
	_log_label.add_theme_font_size_override(&"normal_font_size", 14)
	outer.add_child(_log_label)
