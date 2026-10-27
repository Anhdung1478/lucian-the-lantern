class_name DebugTable
extends CanvasLayer
## Testing panel, toggled with F3 + Q (hidden by default): level controls,
## cheats, training dummy settings, DPS meter and a hit log.

const LOG_SIZE := 10
const PANEL_WIDTH := 400.0

var lucian: Lucian
var dummy: TrainingDummy

var _meter := DpsMeter.new()
## Newest first: [source, raw, final, is_crit].
var _hits: Array[Array] = []

var _level_info: Label
var _level_value: SpinBox
var _crit_toggle: CheckBox
var _crit_value: SpinBox
var _armor: SpinBox
var _mr: SpinBox
var _max_hp: SpinBox
var _dps_label: Label
var _log_label: RichTextLabel


func _ready() -> void:
	layer = 20
	visible = false
	_build()


func setup(target: Lucian, training_dummy: TrainingDummy) -> void:
	lucian = target
	dummy = training_dummy
	dummy.damage_taken.connect(_on_damage_taken)
	_armor.set_value_no_signal(dummy.armor)
	_mr.set_value_no_signal(dummy.mr)
	_max_hp.set_value_no_signal(dummy.max_hp)


## _input runs before the controller's _unhandled_input, so Q never casts here.
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_Q \
			and Input.is_physical_key_pressed(KEY_F3):
		visible = not visible
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not visible or lucian == null:
		return
	var progress := lucian.progress
	_level_info.text = "Level %d   XP %d / %d   Skill points %d" % [
		progress.level, progress.xp, progress.xp_for_next(), progress.skill_points()]
	_dps_label.text = "DPS %.1f   Total %d   %.1f s" % [_meter.dps(), roundi(_meter.total), _meter.elapsed()]


func _on_damage_taken(info: DamageInfo, final_amount: float) -> void:
	_meter.record(final_amount, Time.get_ticks_msec() / 1000.0)
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
	dummy.set_defenses(_armor.value, _mr.value, _max_hp.value)


func _build() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = PANEL_WIDTH
	panel.position = Vector2(12, 12)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.08, 0.94)
	style.border_color = Color(0.85, 0.35, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override(&"panel", style)
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 6)
	panel.add_child(box)
	var title := _label(box, "DEBUG   (F3 + Q)")
	title.add_theme_color_override(&"font_color", Color(0.95, 0.45, 0.4))

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

	_section(box, "Cheats")
	_check(box, "No cooldowns").toggled.connect(func(on: bool) -> void: lucian.cheat_no_cooldowns = on)
	_check(box, "Infinite mana").toggled.connect(func(on: bool) -> void: lucian.cheat_infinite_mana = on)
	row = _row(box)
	_crit_toggle = _check(row, "Crit chance override (%)")
	_crit_toggle.toggled.connect(_apply_crit)
	_crit_value = _spin(row, 0, 100, 100)
	_crit_value.value_changed.connect(_apply_crit)

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
	_dps_label = _label(row, "")
	_dps_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(row, "Reset DPS", func() -> void: _meter.reset())
	_log_label = RichTextLabel.new()
	_log_label.bbcode_enabled = true
	_log_label.fit_content = true
	_log_label.scroll_active = false
	_log_label.custom_minimum_size.x = PANEL_WIDTH - 24.0
	_log_label.add_theme_font_size_override(&"normal_font_size", 14)
	box.add_child(_log_label)


func _section(parent: Control, text: String) -> void:
	parent.add_child(HSeparator.new())
	var label := _label(parent, text.to_upper())
	label.add_theme_color_override(&"font_color", Color("c9a45c"))
	label.add_theme_font_size_override(&"font_size", 13)


func _label(parent: Control, text: String) -> Label:
	var label := Label.new()
	label.text = text
	parent.add_child(label)
	return label


func _row(parent: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	parent.add_child(row)
	return row


func _button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _check(parent: Control, text: String) -> CheckBox:
	var check := CheckBox.new()
	check.text = text
	check.focus_mode = Control.FOCUS_NONE
	parent.add_child(check)
	return check


func _spin(parent: Control, low: float, high: float, value: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = low
	spin.max_value = high
	spin.set_value_no_signal(value)
	spin.select_all_on_focus = true
	parent.add_child(spin)
	return spin
