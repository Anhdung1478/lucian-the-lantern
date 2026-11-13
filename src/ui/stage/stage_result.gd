class_name StageResult
extends CanvasLayer
## The end of a stage, full screen over a paused game, in the Lantern look:
## the game blurred behind an ornate plate with the lantern in a medallion on
## its top edge, lit warm after a clear, dim and red after a defeat. On the
## plate: STAGE CLEARED or DEFEATED (GAME OVER when the tutorial is lost, or
## the caller's own title: Endless's RUN OVER), the stage between gold rules,
## a stats column and a rewards column, then Retry, Next stage and Main screen
## (a single Back to title after a game over). After a clear the rewards are the
## payoff: the essences as one row of large counts, then the unlock lines. After
## a defeat the right column is what hit Lucian (DeathRecap: the killed-by
## line, the shares one per line, the tips) and the essences earned are the
## stats' last rows. It arrives in beats (_play_in): backdrop and glow, plate,
## title, stage line, stat rows one by one, the rewards, the buttons last
## (which take clicks from the first frame); every number counts up. With
## UiMotion.off() (low effects, tests, screenshots) it is whole at once.

## The button pressed: &"retry", &"next", &"main" or &"title".
signal chosen(then: StringName)

const LAYER := 42
const REWARD_COLOR := UiStyle.GOOD_COLOR
## The recap's killed-by line, its tip (a calmer color) and its shares' gap.
const KILLED_COLOR := UiStyle.ERROR_COLOR
const TIP_COLOR := UiStyle.LANTERN_COLOR
const PANEL_WIDTH := 1040.0
const BUTTON_SIZE := Vector2(260, 60)
const CLEARED_GLOW := Color(1.0, 0.78, 0.3, 0.22)
const DEFEATED_GLOW := Color(0.7, 0.05, 0.05, 0.28)
## The plate's padding, and the room its column keeps under the medallion.
const PAD := 30.0
const CREST_ROOM := 28.0
## The medallion over the plate's top edge, and the lantern in it.
const MEDALLION := 44.0
const LANTERN_SIZE := 70.0
const LANTERN := preload("res://assets/art/ui/title_lantern.svg")
## The medallion after a clear: a warm light around a lit lantern.
const LIT_LIGHT := Color(1.0, 0.85, 0.54, 0.5)
## After a defeat: a red light, a dull ring and the lantern gone dim and red.
const DIM_LIGHT := Color(0.8, 0.08, 0.06, 0.34)
const DIM_RING := Color(0.5, 0.29, 0.25)
const DIM_LANTERN := Color(0.72, 0.26, 0.22)
const TITLE_FONT := 60
const TITLE_SPACING := 8
## The title's glow: how far past the title it reaches (× its size), and how
## strong it is beside the screen's glow.
const TITLE_GLOW_REACH := Vector2(1.5, 2.8)
const TITLE_GLOW_ALPHA := 1.8
const STAGE_FONT := 24
const STAGE_RULE := 170.0
const HEAD_FONT := 18
const HEAD_SPACING := 4
const ROW_FONT := 22
const LINE_FONT := 20
## The lead number (an essence's count, Endless's waves cleared): 28 px on screen.
const LEAD_FONT := 34
## A green line's least width before it wraps.
const LINE_WIDTH := 400.0
## A stats row: a faint well with its icon in the name's left margin.
const ROW_COLOR := Color(0.0, 0.0, 0.0, 0.24)
const ROW_RADIUS := 6
const ROW_PAD := 12.0
const ROW_MARGIN := 3.0
const STAT_ICON := 24.0
const STAT_ICON_ROOM := 48.0
## A stats row's icon, by its label. A row without art draws a mark of its own
## (_draw_mark): wave pips for Waves, a ring for Level reached, the modifier's
## or the gift's own icon, and a diamond for any other row.
const STAT_ICONS := {
	"Time": preload("res://assets/art/stats/ability_haste.svg"),
	"Kills": preload("res://assets/art/ui/skull.svg"),
	"Damage dealt": preload("res://assets/art/stats/ad.svg"),
	"Damage taken": preload("res://assets/art/stats/armor.svg"),
	"Gold earned": preload("res://assets/art/ui/gold.svg"),
}
## The row of Endless's run: the lead stat, large and gold.
const LEAD_ROW := "Waves cleared"
## An essence's icon and count (40 px on screen), and the room the right
## column gives the row of counts: each count is centred in its share of it.
const ESSENCE_ICON := 48.0
const ESSENCE_FONT := 48
const ESSENCE_ROW_WIDTH := 460.0
## The bullet's room before a reward line.
const BULLET_ROOM := 32.0
## The word under an essence's count, and its row's name after a defeat.
const ESSENCE_WORDS := {
	Essences.BLUE: "blue",
	Essences.ORANGE: "orange",
	Essences.PURPLE: "purple",
}
const ESSENCE_NAMES := {
	Essences.BLUE: "Blue essence",
	Essences.ORANGE: "Orange essence",
	Essences.PURPLE: "Purple essence",
}
## The longest an essence takes to count up (the last of the beats' time).
const COUNT_TIME := 0.6
## The beats of the arrival, in seconds from the call (all STORY curves).
const BACKDROP_TIME := 0.2
const PLATE_TIME := 0.3
const TITLE_AT := 0.15
const STAGE_AT := 0.25
const ROWS_AT := 0.35
const ROW_STEP := 0.05
const REWARDS_AT := 0.6
const REWARD_STEP := 0.06
const BUTTONS_AT := 1.0

var cleared := false
## The tutorial was lost: the only way out is back to the title screen.
var game_over := false
var title: Label
var retry_button: Button
var next_button: Button
var main_button: Button

var _stage_label: Label
var _stage_row: Control
var _stats: VBoxContainer
var _rewards: VBoxContainer
## The right column's head: REWARDS, or WHAT HIT YOU after a defeat.
var _right_head: Label
var _buttons: Control
var _backdrop: MenuBackdrop
var _glow: TextureRect
var _center: CenterContainer
var _gradient: Gradient
## Draws the medallion; the top of the plate's column.
var _crest := Control.new()
var _title_glow := Control.new()
## The essence counts of a clear, by kind.
var _essence_counts := {}
## The arrival's tweens (the next result stops them).
var _beats: Array[Tween] = []
## The rows of the two columns, in reading order, for their staggers.
var _left_rows: Array[Control] = []
var _right_rows: Array[Control] = []


func _ready() -> void:
	layer = LAYER
	process_mode = PROCESS_MODE_ALWAYS
	visible = false
	_build()


## "4:32": minutes and seconds, rounded up.
static func clock(seconds: float) -> String:
	var whole := ceili(seconds)
	return "%d:%02d" % [whole / 60, whole % 60]


## `stats` is a list of [label, value] pairs, in order. `can_next`: there is a
## next stage to play (it only shows after a clear). `title_text`, when set,
## replaces the outcome's title (its color, glow and lantern stay the outcome's).
## `recap` is DeathRecap.build's parts; a clear never shows it.
func show_result(is_cleared: bool, stage_name: String, stats: Array, collected: Dictionary, rewards: Array[String], is_game_over := false, can_next := false, title_text := "", recap := {}) -> void:
	_stop_beats()
	cleared = is_cleared
	game_over = is_game_over and not is_cleared
	if title_text != "":
		title.text = Lang.t(title_text)
	elif cleared:
		title.text = Lang.t("STAGE CLEARED")
	else:
		title.text = Lang.t("GAME OVER" if game_over else "DEFEATED")
	title.add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR if cleared else UiStyle.ERROR_COLOR)
	_gradient.colors = PackedColorArray([_glow_color(), Color(0, 0, 0, 0)])
	_crest.queue_redraw()
	_title_glow.queue_redraw()
	_stage_label.text = stage_name
	retry_button.visible = not game_over
	next_button.visible = cleared and can_next
	main_button.text = Lang.t("Back to title" if game_over else "Main screen")
	# After a defeat with a recap the right column is the recap, and the
	# essences earned are the stats' last rows.
	# Endless's run over keeps its essences on the right instead, under a
	# REWARDS head of their own after the recap.
	var with_recap := not cleared and not recap.is_empty()
	var essences_apart := with_recap and title_text != ""
	_right_head.text = Lang.t("WHAT HIT YOU" if with_recap else "REWARDS")
	_fill_stats(stats, collected if with_recap and not essences_apart else {})
	if with_recap:
		_fill_recap(recap, rewards, collected if essences_apart else {})
	else:
		_fill_rewards(collected, rewards)
	visible = true
	_play_in()


func _glow_color() -> Color:
	return CLEARED_GLOW if cleared else DEFEATED_GLOW


## The beats of the arrival; each is a plain call that ends in its end state at
## once while UiMotion.off(). Nothing moves after the last beat has landed, and
## the buttons take clicks all along (only their alpha waits).
func _play_in() -> void:
	var animate := not UiMotion.off()
	_backdrop.strength = 0.0 if animate else 1.0
	_glow.modulate.a = 0.0 if animate else 1.0
	if animate:
		var fade := _beat().set_parallel(true)
		fade.tween_property(_backdrop, ^"strength", 1.0, BACKDROP_TIME)
		fade.tween_property(_glow, ^"modulate:a", 1.0, BACKDROP_TIME)
	Ornament.pop_in(_center, PLATE_TIME)
	Ornament.rise_in(title, UiMotion.STORY, TITLE_AT)
	UiMotion.enter(_stage_row, 0.0, UiMotion.STORY, STAGE_AT)
	UiMotion.stagger(_left_rows, ROW_STEP, ROWS_AT, UiMotion.RISE, UiMotion.STORY)
	UiMotion.stagger(_right_rows, REWARD_STEP, REWARDS_AT, UiMotion.RISE, UiMotion.STORY)
	UiMotion.enter(_buttons, UiMotion.RISE, UiMotion.STORY, BUTTONS_AT)


func _beat() -> Tween:
	var beat := UiMotion.tween(self)
	_beats.append(beat)
	return beat


func _stop_beats() -> void:
	for beat in _beats:
		if beat.is_valid():
			beat.kill()
	_beats.clear()


## `label` counts up from 0 to `amount` once `delay` has passed (at once, final,
## while UiMotion.off()).
func _count_in(label: CountLabel, amount: int, delay: float) -> void:
	label.reserve(label.text_for(amount))
	if UiMotion.off():
		label.set_value(amount, true)
		return
	label.set_value(0, true)
	var wait := _beat()
	wait.tween_interval(delay)
	wait.tween_callback(func() -> void:
		if is_instance_valid(label):
			label.set_value(amount))


func _count_label(font_size: int, color: Color, format := "%d") -> CountLabel:
	var label := CountLabel.new()
	label.format = format
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label


## The stats column: `pairs` as rows, then (after a defeat with a recap) one
## row per essence earned.
func _fill_stats(pairs: Array, essences: Dictionary) -> void:
	_clear(_stats)
	_left_rows.clear()
	for pair: Array in pairs:
		# A gift's or modifier's name is a name, not a score: the text color.
		var named: bool = pair[0] in ["Gift", "Modifier"]
		_add_stat(_stat_row(pair[0], pair[1], null, true, -1, "%d", UiStyle.TEXT_COLOR if named else UiStyle.TITLE_COLOR))
	for kind: StringName in Essences.KINDS:
		if essences.get(kind, 0) > 0:
			_add_stat(_stat_row(Lang.t(ESSENCE_NAMES[kind]), "", Stage.ESSENCE_ICONS[kind], false, essences[kind], "+%d", Stage.ESSENCE_COLORS[kind]))


func _add_stat(row: Control) -> void:
	var delay := ROWS_AT + _left_rows.size() * ROW_STEP
	_stats.add_child(row)
	_left_rows.append(row)
	var amount := row.get_child(1) as CountLabel
	if amount:
		_count_in(amount, amount.value, delay)


## Removes a column's rows now (not at the frame's end), so a count of its
## children is the new rows only.
func _clear(box: Control) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()


## A stats row: its name and its value (the row's two children) on a faint
## well. The row draws the well and, in the name's left margin, its mark. A
## value that is a whole number is a CountLabel (it counts up); `amount` and
## `format` make one of any value. `mark` is a Texture2D, or null for the row's
## own (_draw_mark), or &"none" for a row without one (the recap's shares).
func _stat_row(text: String, value: String, mark: Variant = null, translate := true, amount := -1, format := "%d", color := UiStyle.TITLE_COLOR, font := ROW_FONT) -> HBoxContainer:
	var lead := text == LEAD_ROW
	var row := HBoxContainer.new()
	var room := 0.0 if str(mark) == "none" else STAT_ICON_ROOM
	var name_label := UiStyle.label(Lang.t(text) if translate else text, font, UiStyle.TEXT_COLOR)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_stylebox_override(&"normal", _row_margin(room if room > 0.0 else ROW_PAD, 0.0))
	var value_label: Label
	if amount < 0 and value.is_valid_int():
		amount = value.to_int()
	if amount >= 0:
		var count := _count_label(LEAD_FONT if lead else font, UiStyle.GOLD_COLOR if lead else color, format)
		count.set_value(amount, true)
		value_label = count
	else:
		value_label = UiStyle.label(value, font, color)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_stylebox_override(&"normal", _row_margin(0.0, ROW_PAD))
	row.add_child(name_label)
	row.add_child(value_label)
	var icon: Texture2D = mark if mark is Texture2D else STAT_ICONS.get(text)
	var well := StyleBoxFlat.new()
	well.bg_color = ROW_COLOR
	well.set_corner_radius_all(ROW_RADIUS)
	row.draw.connect(func() -> void:
		row.draw_style_box(well, Rect2(Vector2.ZERO, row.size))
		if room > 0.0:
			_draw_mark(row, Vector2(room * 0.5, row.size.y * 0.5), text, value, icon))
	return row


## A row's mark at `middle`: its icon; else the row's own, by name: three wave
## pips (Waves, Waves cleared), a ring (Level reached), the icon of the
## modifier or gift the value names, or a diamond.
func _draw_mark(row: Control, middle: Vector2, text: String, value: String, icon: Texture2D) -> void:
	if icon == null:
		icon = _named_icon(text, value)
	if icon:
		row.draw_texture_rect(icon, Rect2(middle - Vector2.ONE * STAT_ICON * 0.5, Vector2.ONE * STAT_ICON), false)
		return
	match text:
		"Waves", LEAD_ROW:
			for step in [-1, 0, 1]:
				row.draw_colored_polygon(Plate.diamond(middle + Vector2(step * 9.0, 0.0), 3.5), UiStyle.GOLD_COLOR)
		"Level reached", "Modifier", "Gift":
			row.draw_arc(middle, STAT_ICON * 0.33, 0.0, TAU, 32, UiStyle.GOLD_COLOR, 2.0, true)
		_:
			row.draw_colored_polygon(Plate.diamond(middle, Ornament.DIAMOND), UiStyle.BORDER_COLOR)


## The icon of the modifier ("Modifier") or the gift ("Gift") that `value` names.
func _named_icon(text: String, value: String) -> Texture2D:
	if text == "Modifier":
		for id in range(1, EndlessModifiers.NOTHING):
			if EndlessModifiers.downside(id) == value:
				return EndlessModifiers.icon(id)
	elif text == "Gift":
		for id in range(1, LanternGifts.COUNT + 1):
			if LanternGifts.display_name(id) == value:
				return LanternGifts.icon(id)
	return null


## A label's margins inside a stats row.
func _row_margin(left: float, right: float) -> StyleBoxEmpty:
	var margin := StyleBoxEmpty.new()
	margin.content_margin_left = left
	margin.content_margin_right = right
	margin.content_margin_top = ROW_MARGIN
	margin.content_margin_bottom = ROW_MARGIN
	return margin


## After a clear (or a defeat with no recap): the essences as one row of large
## counts (an icon, the number in the essence's color, its word under it),
## then each unlock line with a green diamond.
func _fill_rewards(collected: Dictionary, rewards: Array[String]) -> void:
	_clear(_rewards)
	_right_rows.clear()
	_essence_counts.clear()
	if not _add_essences(collected):
		_add_right(UiStyle.label(Lang.t("No essences"), ROW_FONT, UiStyle.DIM_COLOR))
	for line in rewards:
		_add_right(_reward_line(line))


## The essences earned as one row of large counts across the column, each
## centred in its share of the width (a kind with none is left out), with room
## above and below. False when there is nothing to show.
func _add_essences(collected: Dictionary) -> bool:
	var essences := HBoxContainer.new()
	essences.add_theme_constant_override(&"separation", 0)
	var kinds: Array[StringName] = []
	for kind: StringName in Essences.KINDS:
		if collected.get(kind, 0) > 0:
			kinds.append(kind)
	if kinds.is_empty():
		essences.free()
		return false
	for kind in kinds:
		essences.add_child(_essence_cell(kind, collected[kind], ESSENCE_ROW_WIDTH / kinds.size()))
	var block := VBoxContainer.new()
	block.add_theme_constant_override(&"separation", 0)
	block.add_child(_spacer(UiStyle.GAP_L * 1.4))
	block.add_child(essences)
	block.add_child(_spacer(UiStyle.GAP_L * 1.4))
	_add_right(block)
	for kind: StringName in _essence_counts:
		_count_in(_essence_counts[kind], collected[kind], REWARDS_AT)
	return true


func _spacer(height: float) -> Control:
	var room := Control.new()
	room.custom_minimum_size.y = height
	return room


## One essence: its icon and large count over its word, centred in `share`.
## The number steps down when its digits would not fit the share.
func _essence_cell(kind: StringName, amount: int, share: float) -> VBoxContainer:
	var cell := VBoxContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_theme_constant_override(&"separation", 0)
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override(&"separation", 8)
	var size := ESSENCE_FONT
	var font := ThemeDB.fallback_font
	while size > LEAD_FONT and font.get_string_size(str(amount), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + ESSENCE_ICON + 8.0 > share - 8.0:
		size -= 4
	var icon := TextureRect.new()
	icon.texture = Stage.ESSENCE_ICONS[kind]
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(ESSENCE_ICON, ESSENCE_ICON)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(icon)
	var count := _count_label(size, Stage.ESSENCE_COLORS[kind])
	top.add_child(count)
	cell.add_child(top)
	var word := UiStyle.note(Lang.t(ESSENCE_WORDS[kind]))
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.add_child(word)
	_essence_counts[kind] = count
	return cell


func _add_right(row: Control) -> void:
	_rewards.add_child(row)
	_right_rows.append(row)


## What hit Lucian, in the right column: who struck the last blow, the shares
## of the damage one per line (the name left, the share right), the tip, the
## Evolution Tree line when something can be bought, then the stage's own lines
## (Resolve).
func _fill_recap(recap: Dictionary, lines: Array[String], essences := {}) -> void:
	_clear(_rewards)
	_right_rows.clear()
	_essence_counts.clear()
	var killed := UiStyle.label(recap.killed, ROW_FONT, KILLED_COLOR)
	killed.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	killed.custom_minimum_size = Vector2(LINE_WIDTH, 0)
	_add_right(killed)
	for share: String in recap.shares:
		var parts := share.rsplit(" ", true, 1)
		_add_right(_stat_row(parts[0], parts[1] if parts.size() > 1 else "", &"none", false, -1, "%d", UiStyle.TEXT_COLOR, LINE_FONT))
	_add_right(_reward_line(recap.tip, TIP_COLOR, TIP_COLOR))
	if recap.tree != "":
		_add_right(_reward_line(recap.tree))
	if not essences.is_empty():
		_add_right(_spacer(UiStyle.GAP_L))
		_add_right(_head(Lang.t("REWARDS")))
		_add_essences(essences)
	for line in lines:
		_add_right(_reward_line(line))


## A line with a diamond before it (green unless told otherwise); a long one wraps.
func _reward_line(text: String, color := UiStyle.TEXT_COLOR, bullet_color := REWARD_COLOR) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	var bullet := Control.new()
	bullet.custom_minimum_size = Vector2(BULLET_ROOM, LINE_FONT)
	bullet.draw.connect(func() -> void:
		bullet.draw_colored_polygon(Plate.diamond(Vector2(bullet.size.x * 0.5, LINE_FONT * 0.7), Ornament.DIAMOND), bullet_color))
	row.add_child(bullet)
	var reward := UiStyle.label(text, LINE_FONT, color)
	reward.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward.custom_minimum_size = Vector2(LINE_WIDTH, 0)
	reward.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(reward)
	return row


func _build() -> void:
	var backdrop := MenuBackdrop.new()
	_backdrop = backdrop
	add_child(backdrop)
	# A soft glow behind the plate: a radial gradient, tinted per outcome.
	_gradient = Gradient.new()
	_gradient.colors = PackedColorArray([CLEARED_GLOW, Color(0, 0, 0, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = _gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var glow := TextureRect.new()
	_glow = glow
	glow.texture = texture
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(glow)
	var center := CenterContainer.new()
	_center = center
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)
	var plate := Plate.new(PAD)
	plate.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	center.add_child(plate)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 14)
	plate.add_child(column)
	_crest.custom_minimum_size.y = CREST_ROOM
	_crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crest.draw.connect(_draw_medallion)
	column.add_child(_crest)
	title = UiStyle.label("", TITLE_FONT, UiStyle.GOLD_COLOR)
	# As wide as its text, so its glow is too.
	title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	Ornament.space_out(title, TITLE_SPACING)
	# Room for its rise under it (the glow below is centred on the text).
	Ornament.reserve_rise(title, UiMotion.RISE, false)
	column.add_child(title)
	_title_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title_glow.show_behind_parent = true
	_title_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_glow.draw.connect(_draw_title_glow)
	title.add_child(_title_glow)
	_stage_label = UiStyle.label("", STAGE_FONT, UiStyle.TITLE_COLOR)
	_stage_row = Ornament.between_rules(_stage_label, STAGE_RULE)
	column.add_child(_stage_row)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override(&"separation", 22)
	column.add_child(columns)
	_stats = _section(columns, Lang.t("STATS"))
	columns.add_child(Ornament.divider(true))
	_rewards = _section(columns, Lang.t("REWARDS"))
	_right_head = _rewards.get_parent().get_child(0).get_child(0) as Label
	column.add_child(Ornament.divider())
	var buttons := HBoxContainer.new()
	_buttons = buttons
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override(&"separation", 30)
	column.add_child(buttons)
	retry_button = _button(buttons, Lang.t("Retry"), false, &"retry")
	next_button = _button(buttons, Lang.t("Next stage"), false, &"next")
	main_button = _button(buttons, Lang.t("Main screen"), true, &"main")


## The lantern in its medallion on the middle of the plate's top edge (PAD
## above the column), lit after a clear, dim and red after a defeat.
func _draw_medallion() -> void:
	var at := Vector2(_crest.size.x * 0.5, -PAD)
	if cleared:
		Ornament.draw_medallion(_crest, at, MEDALLION, LANTERN, LANTERN_SIZE, LIT_LIGHT)
	else:
		Ornament.draw_medallion(_crest, at, MEDALLION, LANTERN, LANTERN_SIZE, DIM_LIGHT, DIM_RING, DIM_LANTERN)


## The outcome's soft glow behind the title, wider than it.
func _draw_title_glow() -> void:
	var reach := _title_glow.size * TITLE_GLOW_REACH
	var light := _glow_color()
	light.a = minf(light.a * TITLE_GLOW_ALPHA, 1.0)
	# The title's box has its rise's room under the text: the glow sits on the text.
	var centre := _title_glow.size * 0.5 - Vector2(0.0, UiMotion.RISE * 0.5)
	_title_glow.draw_texture_rect(JourneyMap.glow(), Rect2(centre - reach * 0.5, reach), false, light)


## A column with its head (spaced capitals and a rule), returning the box
## the rows go into.
func _section(parent: Control, head: String) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.size_flags_stretch_ratio = 1.0
	section.add_theme_constant_override(&"separation", 10)
	section.add_child(_head(head))
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override(&"separation", 6)
	section.add_child(rows)
	parent.add_child(section)
	return rows


## A column's head: spaced capitals and a rule.
func _head(head: String) -> HBoxContainer:
	var head_row := HBoxContainer.new()
	head_row.add_theme_constant_override(&"separation", 12)
	var head_label := UiStyle.label(head, HEAD_FONT, UiStyle.TITLE_COLOR)
	Ornament.space_out(head_label, HEAD_SPACING)
	head_row.add_child(head_label)
	head_row.add_child(Ornament.rule(false, Ornament.RULE_WIDTH, true))
	return head_row


func _button(parent: Control, text: String, lit: bool, then: StringName) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = BUTTON_SIZE
	UiStyle.style_button(button, 24, lit)
	button.pressed.connect(func() -> void: chosen.emit(&"title" if game_over and then == &"main" else then))
	parent.add_child(button)
	return button
