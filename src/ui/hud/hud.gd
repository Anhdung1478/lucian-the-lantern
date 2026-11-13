class_name Hud
extends CanvasLayer
## Lucian's bottom bar (portrait, skills, bars, equipped items), the buff
## icons above it, the stats panels and the stage gold (top right). Ctrl + the
## stats key toggles the stats panel; holding the key alone shows the extra
## stats above it. Reads Lucian every frame, also while the game is paused, so
## equipping items shows up right away.

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
## The HUD's plates let a little of the fight through.
const PLATE_OPACITY := 0.92
## The room inside the bottom bar's frame, and inside the gold box's.
const BAR_PAD := 12.0
const GOLD_PAD := 10.0
## The mana bar: its fill's top and bottom, and its ghost.
const MANA_TOP := Color("5b9cf0")
const MANA_BOTTOM := Color("2a5cb8")
const MANA_GHOST := Color("c4d9ff")
## The top stack, each plate UiStyle.STACK under the one above it: the stage
## info, then the boss bar or (in a break, when there is no boss bar) the
## next-wave preview, then the tips. BOSS_BAR_TOP is about where the boss bar
## and the preview come, TIPS_TOP about where a tip comes under them (the
## wave banner's place is measured from it; a new tip waits while the banner
## shows, so the two never stack).
const BOSS_BAR_TOP := 92.0
const TIPS_TOP := 180.0
## The stage info and the preview share one width when theirs differ by less
## than this (24 px on screen).
const SAME_WIDTH := 29.0
## How fast the tips follow a plate above them that comes or goes (of the
## distance left, per second).
const TIPS_FOLLOW := 14.0
const TIP_MARGIN := 14.0
## Space between the buff icons and the bottom panel.
const BUFF_GAP := 8.0
## Space between R and the summoner spells.
const SUMMONER_GAP := 10.0
## Between the item cells, the two potion cells and the boots (6 px on screen).
const GEAR_GAP := 7
## The level badge on a level up: it grows to LEVEL_POP and back over LEVEL_POP_TIME.
const LEVEL_POP := 1.2
const LEVEL_POP_TIME := 0.3
## Between the four groups of the gold plate (coin and gold, then each
## essence): the same distance everywhere.
const GOLD_GROUP_GAP := 28
## Endless's modifier in the buff row: its id and name. No timer; its card
## gives both lines.
const MODIFIER_ROW := &"endless_modifier"
const MODIFIER_NAME := "Endless modifier"

var lucian: Lucian
var wallet: Wallet
## Shown while the stats key is held.
var extra_stats := StatsPanel.new()
## Regeneration per second, at the right end of the HP and mana bars.
var hp_regen_label: Label
var mana_regen_label: Label

## Act 1's tips and Endless's milestones, under the boss bar.
var tips := TipBanner.new()
var stage: Stage
var stage_info := StageInfo.new()
var boss_bar := BossBar.new()
var wave_preview := WavePreview.new()
## Under the rest of the HUD: it never hides its text.
var vignette := LowHealthVignette.new()
var radar := Radar.new()

var _gold_label: CountLabel
var _essence_pairs := {}
var _fps_label: Label
var _buff_bar := BuffBar.new()
var _skill_slots: Array[SkillSlot] = []
## The modifier row of the modifier shown, built once per modifier (it loads an icon).
var _modifier_shown := EndlessModifiers.NONE
var _modifier_row := {}
## The level the badge shows, to mark a level up.
var _bars_extend := 0.0
var _bars_tween: Tween
var _level_shown := 0
var _level_pop: Tween

@onready var bottom_panel: Plate = %BottomPanel
@onready var portrait: HudPortrait = %Portrait
@onready var stats_panel: StatsPanel = %StatsPanel
@onready var skill_row: HBoxContainer = %SkillRow
@onready var item_grid: GridContainer = %ItemGrid
## Beside item_grid (not in it): the two potion cells and the boots.
@onready var gear_column: VBoxContainer = %GearColumn
## Holds item_grid and gear_column: two rows of cells, centred on the span
## from the skill cells' top to the mana bar's bottom.
@onready var gear_block: MarginContainer = %GearBlock
@onready var gear_row: HBoxContainer = %Gear
@onready var level_label: Label = %LevelLabel
@onready var xp_bar: ProgressBar = %XpBar
@onready var hp_bar: HudBar = %HpBar
@onready var hp_label: Label = %HpLabel
@onready var mana_bar: HudBar = %ManaBar
@onready var mana_label: Label = %ManaLabel


func setup(target: Lucian, stage_wallet: Wallet, stage_node: Stage = null) -> void:
	lucian = target
	stage = stage_node
	stage_info.setup(Lang.t(stage.run.display_name) if stage else Lang.t("Training"), stage.runner if stage else null)
	if stage:
		stage_info.skip_pressed.connect(stage.skip_break)
		wave_preview.setup(stage.runner)
	radar.setup(stage.arena.get_bounds() if stage else Rect2(0, 0, 4800, 2700), target)
	_place_radar()
	wallet = stage_wallet
	wallet.changed.connect(_show_gold)
	_show_gold(wallet.gold)
	portrait.texture = target.skin.portrait
	stats_panel.lucian = target
	extra_stats.lucian = target
	_add_skill_slot(null, PASSIVE_ICON, "", SkillSlot.PASSIVE_SIZE)
	var settings := GameSettings.instance()
	for i in SKILL_ICONS.size():
		_add_skill_slot(target.skills[i], SKILL_ICONS[i], settings.short_key_label(SKILL_ACTIONS[i]))
	var gap := Control.new()
	gap.custom_minimum_size.x = SUMMONER_GAP
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skill_row.add_child(gap)
	for i in LucianController.SUMMONER_ACTIONS.size():
		skill_row.add_child(SummonerSlot.new(target, i))
	for i in Inventory.EQUIP_SIZE:
		var item_slot := HudItemSlot.new(target.inventory, Inventory.EQUIP_START + i)
		item_slot.lucian = target
		item_grid.add_child(item_slot)
	# Beside the equip slots: the potion cells (7 and 8) over the boots.
	var potions := HBoxContainer.new()
	potions.add_theme_constant_override(&"separation", GEAR_GAP)
	gear_column.add_child(potions)
	for cell in [Inventory.HP_POTION_CELL, Inventory.MP_POTION_CELL]:
		var potion_slot := HudItemSlot.new(target.inventory, cell)
		potion_slot.lucian = target
		potions.add_child(potion_slot)
	# Under the left potion, on its edge.
	var boots_slot := HudItemSlot.new(target.inventory, Inventory.BOOTS_CELL)
	boots_slot.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	gear_column.add_child(boots_slot)
	settings.changed.connect(_on_setting_changed)


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	bottom_panel.pad = BAR_PAD
	bottom_panel.opacity = PLATE_OPACITY
	bottom_panel.resized.connect(_place_stats_panel)
	# Cards from the bar hang above it, and above the buff row when it shows.
	bottom_panel.set_meta(HudCell.TIP_PLATE, _buff_bar)
	# The stats cards hang above their panel, left of the bar.
	for panel: StatsPanel in [stats_panel, extra_stats]:
		panel.set_meta(HudCell.TIP_CLEAR, bottom_panel)
	# Two rows of cells whatever the number of open slots, rows filled from
	# the top: the first item row and the potions share one top edge.
	gear_block.add_theme_constant_override(&"margin_top", int(SkillSlot.PLUS_HEIGHT))
	gear_row.custom_minimum_size.y = HudItemSlot.SIZE * 2.0 + GEAR_GAP
	item_grid.add_theme_constant_override(&"h_separation", GEAR_GAP)
	item_grid.add_theme_constant_override(&"v_separation", GEAR_GAP)
	gear_column.add_theme_constant_override(&"separation", GEAR_GAP)
	extra_stats.keys = StatsPanel.EXTRA
	extra_stats.visible = false
	extra_stats.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	extra_stats.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	extra_stats.grow_vertical = Control.GROW_DIRECTION_BEGIN
	$Root.add_child(extra_stats)
	$Root.add_child(_buff_bar)
	_buff_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_buff_bar.grow_horizontal = Control.GROW_DIRECTION_END
	_buff_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_place_stats_panel()
	mana_bar.fill_top = MANA_TOP
	mana_bar.fill_bottom = MANA_BOTTOM
	mana_bar.ghost_color = MANA_GHOST
	mana_bar.ticks = false
	hp_regen_label = _regen_label(hp_bar, UiStyle.FONT_NOTE)
	mana_regen_label = _regen_label(mana_bar, UiStyle.FONT_NOTE)
	_build_gold()
	_fps_label = UiStyle.label("", 16, UiStyle.DIM_COLOR)
	_fps_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_fps_label.offset_left = MARGIN
	_fps_label.offset_top = 8.0
	_fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root.add_child(_fps_label)
	_build_stage_info()


func _unhandled_input(event: InputEvent) -> void:
	# Holding the key without Ctrl shows the extra stats (see _process).
	if event.is_action_pressed(&"toggle_stats") and (event as InputEventWithModifiers).ctrl_pressed:
		stats_panel.visible = not stats_panel.visible
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if lucian == null:
		return
	# Hovering a skill, item or summoner slot shows its range around Lucian.
	lucian.indicator.hovered = hover_range_of(get_viewport().gui_get_hovered_control())
	wave_preview.suppressed = stage != null and stage.result.visible
	var progress := lucian.progress
	level_label.text = str(progress.level)
	if progress.level != _level_shown:
		if _level_shown > 0 and progress.level > _level_shown:
			_pop_level_badge()
		_level_shown = progress.level
	var xp_needed := progress.xp_for_next()
	xp_bar.value = float(progress.xp) / xp_needed if xp_needed > 0 else 1.0
	var stats := lucian.stats
	hp_bar.show_amount(lucian.hp, stats.max_hp, lucian.total_shield())
	hp_label.text = "%d / %d" % [roundi(lucian.hp), roundi(stats.max_hp)]
	if lucian.total_shield() > 0.0:
		hp_label.text += "  (+%d)" % roundi(lucian.total_shield())
	vignette.show_health(lucian)
	_buff_bar.show_buffs(_buffs())
	mana_bar.show_amount(lucian.mana, stats.max_mana)
	mana_label.text = "%d / %d" % [roundi(lucian.mana), roundi(stats.max_mana)]
	hp_regen_label.text = "+%s/s" % TooltipText.number(snappedf(stats.hp_regen, 0.1))
	mana_regen_label.text = "+%s/s" % TooltipText.number(snappedf(stats.mana_regen, 0.1))
	extra_stats.visible = Input.is_action_pressed(&"toggle_stats") and not Input.is_key_pressed(KEY_CTRL)
	if extra_stats.visible:
		# On top of the stats panel, or in its place when it is hidden.
		extra_stats.offset_bottom = -12.0 - (stats_panel.size.y + STATS_GAP if stats_panel.visible else 0.0)
		extra_stats.offset_top = extra_stats.offset_bottom
	_fps_label.visible = GameSettings.instance().get_value(&"show_fps")
	if _fps_label.visible:
		_fps_label.text = "FPS %d" % Engine.get_frames_per_second()
	for kind: StringName in _essence_pairs:
		var count: int = stage.collected[kind] if stage else 0
		for node: Control in _essence_pairs[kind]:
			node.visible = count > 0
		if count > 0:
			(_essence_pairs[kind][1] as CountLabel).set_value(count)
	_place_top_stack(_delta)
	_fit_bars()


## While the item block is one row with no boots, the bars run on to the
## bar's right inset, under the items; otherwise they keep their width.
func _fit_bars() -> void:
	var open := 0
	for slot in item_grid.get_children():
		if (slot as Control).visible:
			open += 1
	var lone := open <= item_grid.columns and lucian.inventory.item_at(Inventory.BOOTS_CELL) == null
	var want := 0.0
	if lone:
		want = maxf(gear_block.global_position.x + gear_block.size.x - (hp_bar.global_position.x + hp_bar.size.x), 0.0)
	if is_equal_approx(want, _bars_extend):
		return
	_bars_extend = want
	if _bars_tween and _bars_tween.is_valid():
		_bars_tween.kill()
	if UiMotion.off():
		hp_bar.extend = want
		mana_bar.extend = want
		return
	_bars_tween = UiMotion.tween(self)
	_bars_tween.set_parallel(true)
	for bar: HudBar in [hp_bar, mana_bar]:
		_bars_tween.tween_property(bar, ^"extend", want, UiMotion.BASE).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


## The range of the HUD slot `control` is in (a control opts in with
## hover_range()), or null.
static func hover_range_of(control: Control) -> CastRange:
	while control:
		if control.has_method(&"hover_range"):
			return control.hover_range()
		control = control.get_parent() as Control
	return null


## The buff row: Endless's modifier first (it stays, so it never moves),
## then Lucian's buffs.
func _buffs() -> Array[Dictionary]:
	var shown := lucian.buffs()
	var modifier := stage.endless.modifier if stage and stage.endless else EndlessModifiers.NONE
	if modifier != EndlessModifiers.NONE:
		if modifier != _modifier_shown:
			_modifier_shown = modifier
			_modifier_row = modifier_buff(modifier)
		shown.push_front(_modifier_row)
	return shown


## Modifier `id`'s buff row: its icon, no timer, its downside and reward.
static func modifier_buff(id: int) -> Dictionary:
	var downside := TooltipText.color(EndlessModifiers.downside(id), ModifierPick.DOWNSIDE_COLOR.to_html(false))
	var reward := TooltipText.color(EndlessModifiers.reward(id), ModifierPick.REWARD_COLOR.to_html(false))
	return {"id": MODIFIER_ROW, "name": Lang.t(MODIFIER_NAME), "icon": EndlessModifiers.icon(id), "text": "%s\n%s" % [downside, reward],
		"count": "", "left": 0.0, "duration": 0.0, "ready": false}


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
		_skill_slots[i].set_key(GameSettings.instance().short_key_label(SKILL_ACTIONS[i]))
	for slot in item_grid.get_children():
		slot.queue_redraw()
	for slot in gear_slots():
		slot.queue_redraw()


## The HUD's potion cells and boots, in that order.
func gear_slots() -> Array[HudItemSlot]:
	var found: Array[HudItemSlot] = []
	for node in gear_column.find_children("*", "HudItemSlot", true, false):
		found.append(node as HudItemSlot)
	return found


func _place_stats_panel() -> void:
	# Zero-width rect at the panel's left edge; the minimum size grows it leftward.
	stats_panel.offset_right = -bottom_panel.size.x * 0.5 - STATS_GAP
	stats_panel.offset_left = stats_panel.offset_right
	extra_stats.offset_right = stats_panel.offset_right
	extra_stats.offset_left = stats_panel.offset_right
	# Buffs sit just above the panel, starting over the portrait.
	_buff_bar.offset_left = -bottom_panel.size.x * 0.5 + 12.0
	_buff_bar.offset_right = _buff_bar.offset_left
	_buff_bar.offset_bottom = -12.0 - bottom_panel.size.y - BUFF_GAP
	_buff_bar.offset_top = _buff_bar.offset_bottom


func _regen_label(bar: HudBar, font_size: int) -> Label:
	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_right = -8.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	label.add_theme_constant_override(&"outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(label)
	return label


func _show_gold(gold: int) -> void:
	_gold_label.set_value(gold)
	_reserve_gold(gold)


## Room for the digits shown plus one, so the plate hugs the number (it is
## anchored right and grows leftward) and moves only when a digit is gained.
func _reserve_gold(gold: int) -> void:
	_gold_label.custom_minimum_size.x = 0.0
	_gold_label.reserve("9".repeat(str(maxi(gold, 0)).length() + 1))


## The level badge grows a little and settles back (not with low effects).
func _pop_level_badge() -> void:
	var badge := level_label.get_parent() as Control
	if _level_pop and _level_pop.is_valid():
		_level_pop.kill()
	badge.pivot_offset = badge.size * 0.5
	badge.scale = Vector2.ONE
	if UiMotion.off():
		return
	_level_pop = UiMotion.tween(badge)
	_level_pop.tween_property(badge, ^"scale", Vector2.ONE * LEVEL_POP, LEVEL_POP_TIME * 0.4)
	_level_pop.tween_property(badge, ^"scale", Vector2.ONE, LEVEL_POP_TIME * 0.6).set_ease(Tween.EASE_IN_OUT)


## Top right: a coin and the stage gold, on a plain plate.
func _build_gold() -> void:
	var panel := Plate.new(GOLD_PAD, false)
	panel.opacity = PLATE_OPACITY
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.offset_right = -MARGIN
	panel.offset_top = MARGIN
	panel.set_meta(&"hover_text", Lang.t("Stage gold: spend it at the merchant. Resets every stage."))
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	$Root.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", UiStyle.GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	var coin := TextureRect.new()
	coin.texture = GOLD_ICON
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.custom_minimum_size = Vector2(32, 32)
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(coin)
	# Counts to a new amount, green on a gain and red on a spend, in a slot
	# as wide as its digits plus one.
	_gold_label = CountLabel.new()
	_gold_label.flash = true
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_gold_label.add_theme_font_size_override(&"font_size", 24)
	_gold_label.add_theme_color_override(&"font_color", GOLD_COLOR)
	_gold_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_gold_label)
	_reserve_gold(wallet.gold if wallet else 0)
	for kind: StringName in Stage.ESSENCE_ICONS:
		var gap := Control.new()
		gap.custom_minimum_size.x = GOLD_GROUP_GAP - 2 * UiStyle.GAP
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := TextureRect.new()
		icon.texture = Stage.ESSENCE_ICONS[kind]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(26, 26)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var amount := CountLabel.new()
		amount.flash = true
		amount.add_theme_font_size_override(&"font_size", 22)
		amount.add_theme_color_override(&"font_color", Stage.ESSENCE_COLORS[kind])
		amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for node: Control in [gap, icon, amount]:
			node.visible = false
			row.add_child(node)
		_essence_pairs[kind] = [icon, amount, gap]


## Top center: the stage info with the boss bar and the tips under it; bottom
## right: the radar.
func _build_stage_info() -> void:
	$Root.add_child(vignette)
	$Root.move_child(vignette, 0)
	$Root.add_child(stage_info)
	stage_info.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	stage_info.grow_horizontal = Control.GROW_DIRECTION_BOTH
	# No width of its own: it is always as wide as what it shows (Training
	# hides Skip after this, and the panel must shrink with it).
	stage_info.offset_left = 0.0
	stage_info.offset_right = 0.0
	stage_info.offset_top = MARGIN
	$Root.add_child(wave_preview)
	wave_preview.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	wave_preview.grow_horizontal = Control.GROW_DIRECTION_BOTH
	wave_preview.offset_top = BOSS_BAR_TOP
	$Root.add_child(boss_bar)
	boss_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	boss_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	boss_bar.offset_top = BOSS_BAR_TOP
	tips.add_theme_stylebox_override(&"panel", UiStyle.panel(UiStyle.PANEL_COLOR, UiStyle.BORDER_COLOR, 2, TIP_MARGIN))
	$Root.add_child(tips)
	tips.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	tips.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tips.offset_top = TIPS_TOP
	# A new tip waits while a wave's banner is up.
	tips.held = func() -> bool: return stage != null and is_instance_valid(stage.wave_banner) and stage.wave_banner.visible
	$Root.add_child(radar)


## The top stack: the boss bar or the preview UiStyle.STACK under the stage
## info, the tips STACK under the lowest plate on show (easing there when one
## above comes or goes). The stage info and the preview share one width when
## theirs are close, so their edges line up.
func _place_top_stack(delta: float) -> void:
	var preview_on := wave_preview.shown
	var width := 0.0
	if preview_on:
		var info_width := stage_info.get_minimum_size().x
		var preview_width := wave_preview.get_minimum_size().x
		if absf(info_width - preview_width) < SAME_WIDTH:
			width = maxf(info_width, preview_width)
	if stage_info.custom_minimum_size.x != width:
		stage_info.custom_minimum_size.x = width
	if wave_preview.custom_minimum_size.x != width:
		wave_preview.custom_minimum_size.x = width
	var below := stage_info.offset_top + stage_info.get_combined_minimum_size().y + UiStyle.STACK
	for plate: Control in [boss_bar, wave_preview]:
		if not UiMotion.is_moving(plate):
			plate.offset_top = below
	var tips_top := below
	if boss_bar.shown:
		tips_top += boss_bar.get_combined_minimum_size().y + UiStyle.STACK
	elif preview_on:
		tips_top += wave_preview.get_combined_minimum_size().y + UiStyle.STACK
	if UiMotion.is_moving(tips):
		return
	if not tips.visible or UiMotion.off() or absf(tips.offset_top - tips_top) < 0.5:
		tips.offset_top = tips_top
	else:
		tips.offset_top = lerpf(tips.offset_top, tips_top, minf(1.0, TIPS_FOLLOW * delta))


## Bottom right, MARGIN in from the corner, at the size its map gives it
## (known only in setup).
func _place_radar() -> void:
	radar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, int(MARGIN))
	radar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	radar.grow_vertical = Control.GROW_DIRECTION_BEGIN
