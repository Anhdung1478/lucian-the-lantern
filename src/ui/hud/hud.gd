class_name Hud
extends CanvasLayer
## Lucian's bottom panel (portrait, skills, bars, equipped items), the buff
## icons above it, the stats panel and the stage gold (top right). Reads Lucian every frame, also while
## the game is paused, so equipping items shows up right away.

## Space between the stats panel and the bottom panel.
const STATS_GAP := 10.0
const PASSIVE_ICON := preload("res://assets/art/ui/icon_passive.svg")
const SKILL_ICONS := [
	preload("res://assets/art/ui/icon_q.svg"),
	preload("res://assets/art/ui/icon_w.svg"),
	preload("res://assets/art/ui/icon_e.svg"),
	preload("res://assets/art/ui/icon_r.svg"),
]
const SKILL_ACTIONS: Array[StringName] = [&"skill_q", &"skill_w", &"skill_e", &"skill_r"]
const GOLD_ICON := preload("res://assets/art/ui/gold.svg")
const GOLD_COLOR := Color("ffcf5a")
const MARGIN := 12.0
## Space between the buff icons and the bottom panel.
const BUFF_GAP := 8.0

var lucian: Lucian
var wallet: Wallet

var _gold_label: Label
var _fps_label: Label
var _buff_bar := BuffBar.new()
var _shield_overlay := Control.new()
var _skill_slots: Array[SkillSlot] = []

@onready var bottom_panel: PanelContainer = %BottomPanel
@onready var stats_panel: StatsPanel = %StatsPanel
@onready var skill_row: HBoxContainer = %SkillRow
@onready var item_grid: GridContainer = %ItemGrid
@onready var level_label: Label = %LevelLabel
@onready var xp_bar: ProgressBar = %XpBar
@onready var hp_bar: ProgressBar = %HpBar
@onready var hp_label: Label = %HpLabel
@onready var mana_bar: ProgressBar = %ManaBar
@onready var mana_label: Label = %ManaLabel


func setup(target: Lucian, stage_wallet: Wallet) -> void:
	lucian = target
	wallet = stage_wallet
	wallet.changed.connect(_show_gold)
	_show_gold(wallet.gold)
	stats_panel.lucian = target
	_add_skill_slot(null, PASSIVE_ICON, "", SkillSlot.PASSIVE_SIZE)
	var settings := GameSettings.instance()
	for i in SKILL_ICONS.size():
		_add_skill_slot(target.skills[i], SKILL_ICONS[i], settings.key_label(SKILL_ACTIONS[i]))
	for i in Inventory.EQUIP_SIZE:
		var item_slot := HudItemSlot.new(target.inventory, i)
		item_slot.lucian = target
		item_grid.add_child(item_slot)
	settings.changed.connect(_on_setting_changed)


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	bottom_panel.resized.connect(_place_stats_panel)
	$Root.add_child(_buff_bar)
	_buff_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_buff_bar.grow_horizontal = Control.GROW_DIRECTION_END
	_buff_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_place_stats_panel()
	_shield_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shield_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shield_overlay.draw.connect(_draw_shield)
	hp_bar.add_child(_shield_overlay)
	hp_bar.move_child(_shield_overlay, 0)
	_build_gold()
	_fps_label = UiStyle.label("", 16, UiStyle.DIM_COLOR)
	_fps_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_fps_label.offset_top = 6.0
	_fps_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root.add_child(_fps_label)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_stats"):
		stats_panel.visible = not stats_panel.visible
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if lucian == null:
		return
	var progress := lucian.progress
	level_label.text = str(progress.level)
	var xp_needed := progress.xp_for_next()
	xp_bar.value = float(progress.xp) / xp_needed if xp_needed > 0 else 1.0
	var stats := lucian.stats
	hp_bar.value = lucian.hp / stats.max_hp
	hp_label.text = "%d / %d" % [roundi(lucian.hp), roundi(stats.max_hp)]
	if lucian.shield > 0.0:
		hp_label.text += "  (+%d)" % roundi(lucian.shield)
	_shield_overlay.queue_redraw()
	_buff_bar.show_buffs(lucian.buffs())
	mana_bar.value = lucian.mana / stats.max_mana
	mana_label.text = "%d / %d" % [roundi(lucian.mana), roundi(stats.max_mana)]
	_fps_label.visible = GameSettings.instance().get_value(&"show_fps")
	if _fps_label.visible:
		_fps_label.text = "FPS %d" % Engine.get_frames_per_second()


func _add_skill_slot(skill: LucianSkill, icon: Texture2D, key: String, icon_size := SkillSlot.ICON_SIZE) -> void:
	var slot := SkillSlot.new()
	slot.setup(lucian, skill, icon, key, icon_size)
	skill_row.add_child(slot)
	if skill:
		_skill_slots.append(slot)


## Key labels follow the bindings.
func _on_setting_changed(key: StringName) -> void:
	if key != &"bindings":
		return
	for i in _skill_slots.size():
		_skill_slots[i].set_key(GameSettings.instance().key_label(SKILL_ACTIONS[i]))
	for slot in item_grid.get_children():
		slot.queue_redraw()


func _place_stats_panel() -> void:
	# Zero-width rect at the panel's left edge; the minimum size grows it leftward.
	stats_panel.offset_right = -bottom_panel.size.x * 0.5 - STATS_GAP
	stats_panel.offset_left = stats_panel.offset_right
	# Buffs sit just above the panel, starting over the portrait.
	_buff_bar.offset_left = -bottom_panel.size.x * 0.5 + 12.0
	_buff_bar.offset_right = _buff_bar.offset_left
	_buff_bar.offset_bottom = -12.0 - bottom_panel.size.y - BUFF_GAP
	_buff_bar.offset_top = _buff_bar.offset_bottom


## The shield, white, right after the HP on the HP bar (pushed back from the
## end when HP and shield are more than max HP).
func _draw_shield() -> void:
	if lucian == null or lucian.shield <= 0.0:
		return
	var width := _shield_overlay.size.x
	var share := minf(lucian.shield / lucian.stats.max_hp, 1.0)
	var start := minf(lucian.hp / lucian.stats.max_hp, 1.0 - share)
	_shield_overlay.draw_rect(Rect2(width * start, 0, width * share, _shield_overlay.size.y), Color(0.92, 0.94, 0.97, 0.85))


func _show_gold(gold: int) -> void:
	_gold_label.text = str(gold)


## Top right: a coin and the stage gold, in the HUD panel style.
func _build_gold() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", bottom_panel.get_theme_stylebox(&"panel"))
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.offset_right = -MARGIN
	panel.offset_top = MARGIN
	panel.set_meta(&"hover_text", "Stage gold: spend it at the merchant. Resets every stage.")
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	$Root.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	var coin := TextureRect.new()
	coin.texture = GOLD_ICON
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.custom_minimum_size = Vector2(32, 32)
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(coin)
	_gold_label = Label.new()
	_gold_label.text = "0"
	_gold_label.custom_minimum_size.x = 72
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_gold_label.add_theme_font_size_override(&"font_size", 24)
	_gold_label.add_theme_color_override(&"font_color", GOLD_COLOR)
	_gold_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_gold_label)
