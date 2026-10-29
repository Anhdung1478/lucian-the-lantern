class_name JourneyPanel
extends Control
## The Journey's side panel, opaque beside the map: the picked place and its
## Start, with the D/F summoner spells at the bottom for every pick.
## - A stage: its act and id, the boss or mini boss with its purple, the
##   waves, the act's story, whether it is cleared, and its enemies.
## - Training: what it is.
## - Endless: the best wave, the rules, and the map choice with a thumbnail.

## Start was pressed; JourneySection knows what is picked.
signal start_pressed

const SIZE := Vector2(440, 904)
const PAD := 20.0
const CONTENT_WIDTH := 400.0
const START_HEIGHT := 64.0
const LOADOUT_HEIGHT := 114.0
const GAP := 16.0
## Between the rows of a box (Endless's is fuller).
const ROW_GAP := 12
const ENDLESS_ROW_GAP := 9
const PORTRAIT_SIZE := 112.0
const ICON_SIZE := 26.0
const CHIP_HEIGHT := 34.0
## The roster's round icons.
const ROSTER_ICON := 44.0
## How far down the picked place's color glows from the top.
const GLOW_HEIGHT := 300.0
const GLOW_ALPHA := 0.3
const CAPTION_COLOR := Color("c9a45c")
const PURPLE_COLOR := Color("b46cff")
const BACKGROUND := Color(0.05, 0.06, 0.08)
const TRAINING_ACCENT := Color("c9a45c")
const ENDLESS_ACCENT := Color("9a5cff")
const TRAINING_TEXT := "Practice on training dummies with what you have bought in the Evolution Tree and your equipped skin. No essences are earned. Leave from the ESC menu to come back here."
const SKULL := preload("res://assets/art/ui/skull.svg")
const PURPLE_ICON := preload("res://assets/art/ui/essence_purple.svg")
const BLUE_ICON := preload("res://assets/art/ui/essence_blue.svg")
const ORANGE_ICON := preload("res://assets/art/ui/essence_orange.svg")

var start_button := Button.new()
var loadout := LoadoutPanel.new()
var thumbnail := MapThumbnail.new()
## Endless's map chips, one per Journey.ENDLESS_MAPS entry.
var map_buttons: Array[Button] = []
var best_label: Label
## One box per kind of place; the picked one shows.
var stage_box := VBoxContainer.new()
var training_box := VBoxContainer.new()
var endless_box := VBoxContainer.new()
var act_label: Label
var title_label: Label
var boss_row: HBoxContainer
var boss_name_label: Label
var tag_label: Label
var purple_row: HBoxContainer
var purple_label: Label
var waves_label: Label
var story_label: Label
var status_label: Label
## The stage's enemies, each once in wave order (its mini boss is in the
## portrait), and their icons.
var enemy_ids: Array[StringName] = []
var roster := HFlowContainer.new()

var _choice := 0
var _accent := TRAINING_ACCENT
var _portrait := Control.new()
var _portrait_art: Texture2D
var _portrait_ring := Color.WHITE
var _tag_style := StyleBoxFlat.new()
var _status_mark := Control.new()
var _cleared_mark := false
## The stage the roster shows, so a refresh doesn't rebuild it.
var _roster_stage := ""
var _top_glow: GradientTexture2D


func _init() -> void:
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	_top_glow = GradientTexture2D.new()
	_top_glow.gradient = gradient
	_top_glow.fill = GradientTexture2D.FILL_RADIAL
	_top_glow.fill_from = Vector2(0.5, 0.0)
	_top_glow.fill_to = Vector2(0.5, 1.0)
	for box: VBoxContainer in [stage_box, training_box, endless_box]:
		box.position = Vector2(PAD, PAD + 4.0)
		box.size = Vector2(CONTENT_WIDTH, 0)
		box.add_theme_constant_override(&"separation", ENDLESS_ROW_GAP if box == endless_box else ROW_GAP)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(box)
	_build_stage()
	_build_training()
	_build_endless()
	start_button.position = Vector2(PAD, SIZE.y - PAD - LOADOUT_HEIGHT - GAP - START_HEIGHT)
	start_button.size = Vector2(CONTENT_WIDTH, START_HEIGHT)
	UiStyle.style_button(start_button, 28, true)
	start_button.add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR)
	start_button.pressed.connect(start_pressed.emit)
	add_child(start_button)
	loadout.position = Vector2(PAD, SIZE.y - PAD - LOADOUT_HEIGHT)
	loadout.size = Vector2(CONTENT_WIDTH, LOADOUT_HEIGHT)
	add_child(loadout)


## Fills the panel for `node` (a place from JourneyMap); `save` gives the
## bosses already paid their first-time purple.
func show_node(node: JourneyNode, save: SaveGame) -> void:
	stage_box.visible = node.is_stage()
	training_box.visible = node.kind == JourneyNode.TRAINING
	endless_box.visible = node.kind == JourneyNode.ENDLESS
	match node.kind:
		JourneyNode.TRAINING:
			start_button.text = "Start Training"
			_accent = TRAINING_ACCENT
		JourneyNode.ENDLESS:
			start_button.text = "Start"
			_accent = ENDLESS_ACCENT
		_:
			_show_stage(node, save)
	start_button.disabled = node.locked
	queue_redraw()


## Endless's best wave.
func show_best(waves: int) -> void:
	best_label.text = "Best wave: %d" % waves


## The Journey.ENDLESS_MAPS index of the chosen map (0 is Random).
func map_choice() -> int:
	return _choice


## The art the portrait shows (null when it is hidden).
func portrait_texture() -> Texture2D:
	return _portrait_art if boss_row.visible else null


func _show_stage(node: JourneyNode, save: SaveGame) -> void:
	var info: Dictionary = Journey.ACTS[node.act - 1]
	_accent = JourneyMap.REGIONS[node.act - 1]["accent"]
	act_label.text = "ACT %d · %s" % [node.act, String(info["name"]).to_upper()]
	title_label.text = "Stage %s" % node.stage_id
	# Act 1's stage brings Thresh only on its first play.
	var no_boss := node.stage_id == StageSetup.TUTORIAL_STAGE and node.cleared
	boss_row.visible = node.enemy != null and not no_boss
	purple_row.visible = node.enemy != null
	if node.enemy:
		_portrait_art = node.enemy.art
		_portrait_ring = node.ring_color()
		_portrait.queue_redraw()
		boss_name_label.text = node.enemy.display_name
		tag_label.text = "Boss" if node.kind == JourneyNode.BOSS else "Mini boss"
		_tag_style.bg_color = Color(node.ring_color(), 0.22)
		_tag_style.border_color = node.ring_color()
		purple_row.modulate = Color(1, 1, 1, 0.5) if no_boss else Color.WHITE
		if no_boss:
			purple_label.text = "No boss on replays"
		elif String(node.enemy.id) in save.bosses:
			purple_label.text = "+%d again" % node.enemy.purple_repeat
		else:
			purple_label.text = "First kill: +%d" % node.enemy.purple_first
	waves_label.text = node.waves_text
	story_label.text = info["story"]
	status_label.text = "Cleared" if node.cleared else "Not cleared yet"
	status_label.add_theme_color_override(&"font_color", JourneyNode.CHECK_COLOR if node.cleared else UiStyle.DIM_COLOR)
	_cleared_mark = node.cleared
	_status_mark.queue_redraw()
	start_button.text = "Start" if Journey.stage_count(node.act) == 1 else "Start stage %d" % node.stage
	_show_roster(node.stage_id)


func _show_roster(stage_id: String) -> void:
	if stage_id == _roster_stage:
		return
	_roster_stage = stage_id
	enemy_ids.clear()
	var mini_boss := WavePlan.mini_boss(stage_id)
	for wave: Array in WavePlan.waves(stage_id):
		for id: StringName in wave:
			if id != mini_boss and not id in enemy_ids:
				enemy_ids.append(id)
	for child in roster.get_children():
		roster.remove_child(child)
		child.free()
	for id in enemy_ids:
		var data: EnemyData = load(Stage.ENEMY_PATH % id)
		var icon := Control.new()
		icon.custom_minimum_size = Vector2.ONE * ROSTER_ICON
		icon.set_meta(&"hover_text", data.display_name)
		icon.draw.connect(_draw_roster_icon.bind(icon, data.art))
		roster.add_child(icon)


func _draw() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = BACKGROUND
	style.border_color = UiStyle.BORDER_COLOR
	style.set_border_width_all(2)
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	draw_style_box(style, Rect2(Vector2.ZERO, size))
	draw_texture_rect(_top_glow, Rect2(2, 2, size.x - 4.0, GLOW_HEIGHT), false, Color(_accent, GLOW_ALPHA))
	var line_y := start_button.position.y - GAP * 0.5
	draw_line(Vector2(PAD, line_y), Vector2(size.x - PAD, line_y), Color(UiStyle.BORDER_COLOR, 0.25), 1.0)


func _build_stage() -> void:
	act_label = UiStyle.label("", 16, CAPTION_COLOR)
	stage_box.add_child(act_label)
	title_label = UiStyle.label("", 40, UiStyle.TITLE_COLOR)
	stage_box.add_child(title_label)
	stage_box.add_child(_divider())
	boss_row = HBoxContainer.new()
	boss_row.add_theme_constant_override(&"separation", 18)
	stage_box.add_child(boss_row)
	_portrait.custom_minimum_size = Vector2.ONE * PORTRAIT_SIZE
	_portrait.draw.connect(_draw_portrait)
	boss_row.add_child(_portrait)
	var who := VBoxContainer.new()
	who.alignment = BoxContainer.ALIGNMENT_CENTER
	who.add_theme_constant_override(&"separation", 8)
	boss_row.add_child(who)
	var tag := PanelContainer.new()
	_tag_style.set_border_width_all(1)
	_tag_style.set_corner_radius_all(10)
	_tag_style.content_margin_left = 10.0
	_tag_style.content_margin_right = 10.0
	_tag_style.content_margin_top = 1.0
	_tag_style.content_margin_bottom = 2.0
	tag.add_theme_stylebox_override(&"panel", _tag_style)
	tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tag_label = UiStyle.label("", 15, UiStyle.TEXT_COLOR)
	tag.add_child(tag_label)
	who.add_child(tag)
	boss_name_label = UiStyle.label("", 28, UiStyle.TITLE_COLOR)
	boss_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boss_name_label.custom_minimum_size.x = CONTENT_WIDTH - PORTRAIT_SIZE - 18.0
	who.add_child(boss_name_label)
	purple_label = UiStyle.label("", 20, PURPLE_COLOR)
	purple_row = _icon_row(_icon(PURPLE_ICON), purple_label)
	stage_box.add_child(purple_row)
	waves_label = UiStyle.label("", 22, UiStyle.TEXT_COLOR)
	stage_box.add_child(_icon_row(_icon(SKULL, Color(0.75, 0.77, 0.82)), waves_label))
	story_label = UiStyle.label("", 18, UiStyle.DIM_COLOR)
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_label.custom_minimum_size.x = CONTENT_WIDTH
	stage_box.add_child(story_label)
	status_label = UiStyle.label("", 20, UiStyle.DIM_COLOR)
	_status_mark.custom_minimum_size = Vector2.ONE * ICON_SIZE
	_status_mark.draw.connect(_draw_status_mark)
	stage_box.add_child(_icon_row(_status_mark, status_label))
	stage_box.add_child(_divider())
	stage_box.add_child(UiStyle.label("ENEMIES", 16, CAPTION_COLOR))
	roster.add_theme_constant_override(&"h_separation", 8)
	roster.add_theme_constant_override(&"v_separation", 8)
	roster.custom_minimum_size.x = CONTENT_WIDTH
	stage_box.add_child(roster)


func _build_training() -> void:
	training_box.add_child(UiStyle.label("PRACTICE", 16, CAPTION_COLOR))
	training_box.add_child(UiStyle.label("TRAINING", 40, UiStyle.TITLE_COLOR))
	training_box.add_child(_divider())
	var dummy := Control.new()
	dummy.custom_minimum_size = Vector2(CONTENT_WIDTH, PORTRAIT_SIZE)
	dummy.draw.connect(func() -> void:
		var middle := Vector2(PORTRAIT_SIZE * 0.5, PORTRAIT_SIZE * 0.5)
		_draw_round(dummy, JourneyNode.DUMMY_ART, middle, JourneyNode.RIM_COLOR))
	training_box.add_child(dummy)
	var text := UiStyle.label(TRAINING_TEXT, 20, UiStyle.TEXT_COLOR)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = CONTENT_WIDTH
	training_box.add_child(text)


func _build_endless() -> void:
	endless_box.add_child(UiStyle.label("WAVES NEVER END", 16, CAPTION_COLOR))
	endless_box.add_child(UiStyle.label("ENDLESS", 40, UiStyle.TITLE_COLOR))
	best_label = UiStyle.label("Best wave: 0", 24, UiStyle.GOLD_COLOR)
	endless_box.add_child(best_label)
	endless_box.add_child(_divider())
	var rules := VBoxContainer.new()
	rules.add_theme_constant_override(&"separation", 6)
	endless_box.add_child(rules)
	rules.add_child(_icon_row(_icon(SKULL, JourneyNode.MINI_BOSS_COLOR), UiStyle.label("A mini boss every %d waves" % EndlessPlan.MINI_BOSS_EVERY, 18, UiStyle.TEXT_COLOR)))
	rules.add_child(_icon_row(_icon(SKULL, JourneyNode.BOSS_COLOR), UiStyle.label("A boss every %d waves" % EndlessPlan.BOSS_EVERY, 18, UiStyle.TEXT_COLOR)))
	var card := Control.new()
	card.custom_minimum_size = Vector2.ONE * ICON_SIZE
	card.draw.connect(_draw_card_icon.bind(card))
	rules.add_child(_icon_row(card, UiStyle.label("A modifier to pick after each boss", 18, UiStyle.TEXT_COLOR)))
	var essences := HBoxContainer.new()
	essences.add_theme_constant_override(&"separation", -8)
	for icon: Texture2D in [BLUE_ICON, ORANGE_ICON, PURPLE_ICON]:
		essences.add_child(_icon(icon))
	rules.add_child(_icon_row(essences, UiStyle.label("Blue, orange, and repeat purple", 18, UiStyle.TEXT_COLOR)))
	endless_box.add_child(UiStyle.label("MAP", 16, CAPTION_COLOR))
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override(&"h_separation", 8)
	chips.add_theme_constant_override(&"v_separation", 8)
	chips.custom_minimum_size.x = CONTENT_WIDTH
	endless_box.add_child(chips)
	var group := ButtonGroup.new()
	for i in Journey.ENDLESS_MAPS.size():
		var chip := Button.new()
		chip.text = Journey.ENDLESS_MAPS[i]
		chip.toggle_mode = true
		chip.button_group = group
		chip.button_pressed = i == 0
		chip.custom_minimum_size = Vector2(0, CHIP_HEIGHT)
		chip.pressed.connect(choose_map.bind(i))
		chips.add_child(chip)
		map_buttons.append(chip)
	_style_chips()
	thumbnail.show_choice(_choice)
	endless_box.add_child(thumbnail)


## Endless's map chip `index` (a Journey.ENDLESS_MAPS index) is the chosen
## one, with its thumbnail, as a click on it does.
func choose_map(index: int) -> void:
	_choice = index
	for i in map_buttons.size():
		map_buttons[i].set_pressed_no_signal(i == index)
	_style_chips()
	thumbnail.show_choice(index)


func _style_chips() -> void:
	for i in map_buttons.size():
		UiStyle.style_button(map_buttons[i], 16, i == _choice)
		for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
			var style := map_buttons[i].get_theme_stylebox(state) as StyleBoxFlat
			style.content_margin_left = 12.0
			style.content_margin_right = 12.0
			style.set_corner_radius_all(16)


## A thin gold rule with a diamond in its middle.
func _divider() -> Control:
	var line := Control.new()
	line.custom_minimum_size = Vector2(CONTENT_WIDTH, 12)
	line.draw.connect(func() -> void:
		var y := 6.0
		var middle := CONTENT_WIDTH * 0.5
		var faded := Color(UiStyle.BORDER_COLOR, 0.0)
		line.draw_polyline_colors(PackedVector2Array([Vector2(0, y), Vector2(middle - 10.0, y)]), PackedColorArray([faded, UiStyle.BORDER_COLOR]), 1.5)
		line.draw_polyline_colors(PackedVector2Array([Vector2(middle + 10.0, y), Vector2(CONTENT_WIDTH, y)]), PackedColorArray([UiStyle.BORDER_COLOR, faded]), 1.5)
		line.draw_colored_polygon(PackedVector2Array([Vector2(middle, y - 5), Vector2(middle + 5, y), Vector2(middle, y + 5), Vector2(middle - 5, y)]), UiStyle.BORDER_COLOR))
	return line


func _icon(texture: Texture2D, tint := Color.WHITE) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.modulate = tint
	icon.custom_minimum_size = Vector2.ONE * ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return icon


## An icon column (fixed width, so the texts line up) and a label.
func _icon_row(icon: Control, label: Label) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	var holder := CenterContainer.new()
	holder.custom_minimum_size = Vector2(ICON_SIZE * 2.2, ICON_SIZE)
	holder.add_child(icon)
	row.add_child(holder)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	return row


func _draw_portrait() -> void:
	if _portrait_art:
		var middle := Vector2.ONE * PORTRAIT_SIZE * 0.5
		_draw_round(_portrait, _portrait_art, middle, _portrait_ring)


## Round art in a ringed frame, like the map's medallions.
func _draw_round(canvas: CanvasItem, texture: Texture2D, middle: Vector2, ring: Color) -> void:
	var radius := PORTRAIT_SIZE * 0.5
	canvas.draw_texture_rect(JourneyMap.glow(), Rect2(middle - Vector2.ONE * radius * 1.4, Vector2.ONE * radius * 2.8), false, Color(ring, 0.2))
	canvas.draw_circle(middle, radius, ring.darkened(0.3))
	canvas.draw_arc(middle, radius - 3.0, PI * 1.08, PI * 1.92, 32, ring.lightened(0.3), 3.5, true)
	canvas.draw_circle(middle, radius - 6.0, JourneyNode.FACE_COLOR)
	JourneyMap.draw_round_art(canvas, texture, middle, radius - 7.0, JourneyNode.ART_ZOOM)
	canvas.draw_arc(middle, radius - 6.0, 0.0, TAU, 64, Color(0, 0, 0, 0.6), 1.5, true)


func _draw_roster_icon(icon: Control, art: Texture2D) -> void:
	var middle := Vector2.ONE * ROSTER_ICON * 0.5
	var radius := ROSTER_ICON * 0.5
	icon.draw_circle(middle, radius, JourneyNode.RIM_COLOR.darkened(0.45))
	icon.draw_circle(middle, radius - 2.5, JourneyNode.FACE_COLOR)
	if art:
		JourneyMap.draw_round_art(icon, art, middle, radius - 3.5, 1.0)


func _draw_status_mark() -> void:
	var middle := Vector2.ONE * ICON_SIZE * 0.5
	if _cleared_mark:
		_status_mark.draw_circle(middle, 11.0, Color("0e2414"))
		_status_mark.draw_arc(middle, 11.0, 0.0, TAU, 24, JourneyNode.CHECK_COLOR, 2.0, true)
		_status_mark.draw_polyline(PackedVector2Array([middle + Vector2(-5, 0), middle + Vector2(-1.5, 4), middle + Vector2(5, -4)]), JourneyNode.CHECK_COLOR, 3.0, true)
	else:
		_status_mark.draw_arc(middle, 10.0, 0.0, TAU, 24, UiStyle.DIM_COLOR, 2.0, true)


## Two cards, fanned: a modifier pick.
func _draw_card_icon(card: Control) -> void:
	for i in 2:
		card.draw_set_transform(Vector2(ICON_SIZE * 0.5, ICON_SIZE * 0.55), -0.25 + i * 0.4)
		var rect := Rect2(-7, -11, 14, 20)
		card.draw_rect(rect, Color("1d1a15"))
		card.draw_rect(rect, UiStyle.GOLD_COLOR, false, 1.5)
	card.draw_set_transform(Vector2.ZERO)
