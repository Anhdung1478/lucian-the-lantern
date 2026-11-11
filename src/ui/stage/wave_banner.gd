class_name WaveBanner
extends PanelContainer
## A wave's start, in the upper middle of the screen: "WAVE 3" in spaced
## capitals between gold rules, on a dark band that fades out at its ends. A
## wave that brings a mini boss reads MINI BOSS over its name; the boss wave
## reads BOSS over the boss's name, larger and in red. It fades in (sliding
## down a little, not with low effects), stays TIME seconds and fades out.
## Its time only runs while the game does, and it never takes mouse input.
## The stage puts it on the HUD's layer, so it hides with the HUD; setup()
## makes it listen to the stage's waves.

const WAVE := "WAVE %d"
const MINI_BOSS := "MINI BOSS"
const BOSS := "BOSS"
## From the top of the screen: under the stage info, the boss bar and a tip.
const TOP := 210.0
const WIDTH := 860.0
const PAD := 14.0
## Seconds at full strength, and each fade.
const TIME := 1.6
const FADE := 0.2
## How far above its place it starts.
const SLIDE := 16.0
## The band: its strength in the middle, and the share of its width each
## end takes to fade out.
const BAND_ALPHA := 0.8
const BAND_FADE := 0.32
const TITLE_SPACING := 10
const RULE_WIDTH := 120.0
const NAME_FONT := 26
## The glow behind the title: how far past the band it reaches (× its size).
const GLOW_REACH := Vector2(0.62, 1.5)
## By kind (&"" is a plain wave): the title's size and color, the color of
## the rules and the band's lines, and the glow behind the title.
const LOOKS := {
	&"": {"font": 34, "color": UiStyle.TITLE_COLOR, "rule": UiStyle.BORDER_COLOR, "glow": Color(1.0, 0.78, 0.3, 0.0)},
	&"mini_boss": {"font": 36, "color": UiStyle.GOLD_COLOR, "rule": UiStyle.BORDER_COLOR, "glow": Color(1.0, 0.78, 0.3, 0.2)},
	&"boss": {"font": 50, "color": UiStyle.ERROR_COLOR, "rule": UiStyle.BAD_COLOR, "glow": Color(0.85, 0.08, 0.06, 0.5)},
}

## The lines on show, top to bottom (lines()).
var shown := PackedStringArray()
## The kind on show: &"", &"mini_boss" or &"boss".
var kind := &""
var runner: WaveRunner
var stage_id := ""

var _box := VBoxContainer.new()
## Seconds since the banner came.
var _age := 0.0


func _init() -> void:
	var margin := StyleBoxEmpty.new()
	margin.content_margin_top = PAD
	margin.content_margin_bottom = PAD
	add_theme_stylebox_override(&"panel", margin)
	custom_minimum_size.x = WIDTH
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_theme_constant_override(&"separation", 0)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	visible = false


func _ready() -> void:
	process_mode = PROCESS_MODE_PAUSABLE
	set_process(false)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	offset_top = TOP


## What the banner says for wave `number`. `lead_kind` is &"boss" or
## &"mini_boss" when the wave brings one, named `lead_name`; else &"".
static func lines(number: int, lead_kind := &"", lead_name := "") -> PackedStringArray:
	match lead_kind:
		&"boss":
			return PackedStringArray([BOSS, lead_name])
		&"mini_boss":
			return PackedStringArray([MINI_BOSS, lead_name])
	return PackedStringArray([WAVE % number])


## The boss or mini boss that the wave `wave_runner` just started brings, or
## null: the boss in a boss wave; else Endless's mini boss in its wave, or
## the first mini boss among the story wave's enemies (`id` is its stage).
static func lead(wave_runner: WaveRunner, id: String) -> EnemyData:
	if wave_runner.is_boss_wave():
		return load(Stage.ENEMY_PATH % wave_runner.boss)
	var endless := wave_runner as EndlessRunner
	if endless:
		return load(Stage.ENEMY_PATH % endless.mini_boss) if endless.is_mini_boss_wave() else null
	var waves := WavePlan.waves(id)
	if wave_runner.wave < 1 or wave_runner.wave > waves.size():
		return null
	for enemy: StringName in waves[wave_runner.wave - 1]:
		var data: EnemyData = load(Stage.ENEMY_PATH % enemy)
		if data.kind == &"mini_boss":
			return data
	return null


## Shows each wave of `wave_runner` as it starts (`id` is its stage).
func setup(wave_runner: WaveRunner, id: String) -> void:
	runner = wave_runner
	stage_id = id
	runner.wave_started.connect(_on_wave_started)


## Shows the banner for wave `number` from its start: lines(), in the look
## of `lead_kind`.
func announce(number: int, lead_kind := &"", lead_name := "") -> void:
	shown = lines(number, lead_kind, lead_name)
	kind = lead_kind
	for child in _box.get_children():
		_box.remove_child(child)
		child.queue_free()
	var look: Dictionary = LOOKS[kind]
	var title := _line(shown[0], look.font, look.color)
	Ornament.space_out(title, TITLE_SPACING)
	_box.add_child(Ornament.between_rules(title, RULE_WIDTH, look.rule))
	if shown.size() > 1:
		_box.add_child(_line(shown[1], NAME_FONT, UiStyle.TITLE_COLOR))
	# Down to the new lines' height, from the same top.
	offset_bottom = offset_top
	_age = 0.0
	visible = true
	set_process(true)
	_place()
	queue_redraw()


func _on_wave_started(number: int) -> void:
	var data := lead(runner, stage_id)
	if data:
		announce(number, data.kind, data.display_name)
	else:
		announce(number)


func _process(delta: float) -> void:
	_age += delta
	if _age >= FADE + TIME + FADE:
		visible = false
		set_process(false)
		return
	_place()


## Its strength and place at its age: in over FADE, out over the last FADE.
func _place() -> void:
	var coming := clampf(_age / FADE, 0.0, 1.0)
	var going := clampf((FADE + TIME + FADE - _age) / FADE, 0.0, 1.0)
	modulate.a = minf(coming, going)
	var slide := 0.0 if GameSettings.instance().low_effects() else SLIDE * (1.0 - ease(coming, 0.4))
	position.y = TOP - slide


func _line(text: String, font_size: int, color: Color) -> Label:
	var label := UiStyle.label(text, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override(&"shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## The band: dark in the middle, clear at both ends, a line with a diamond
## along its top and its bottom, and the kind's glow behind the title.
func _draw() -> void:
	var look: Dictionary = LOOKS[kind]
	var left := size.x * BAND_FADE
	var right := size.x - left
	var solid := Color(UiStyle.PLATE_TOP, BAND_ALPHA)
	var clear := Color(UiStyle.PLATE_TOP, 0.0)
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(left, 0.0), Vector2(left, size.y), Vector2(0.0, size.y)]), PackedColorArray([clear, solid, solid, clear]))
	draw_rect(Rect2(left, 0.0, right - left, size.y), solid)
	draw_polygon(PackedVector2Array([Vector2(right, 0.0), Vector2(size.x, 0.0), size, Vector2(right, size.y)]), PackedColorArray([solid, clear, clear, solid]))
	var reach := size * GLOW_REACH
	draw_texture_rect(JourneyMap.glow(), Rect2((size - reach) * 0.5, reach), false, look.glow)
	var line: Color = look.rule
	var faded := Color(line, 0.0)
	for y: float in [0.0, size.y]:
		draw_polyline_colors(PackedVector2Array([Vector2(0.0, y), Vector2(left, y), Vector2(right, y), Vector2(size.x, y)]), PackedColorArray([faded, line, line, faded]), Ornament.RULE_THICKNESS, true)
		draw_colored_polygon(Plate.diamond(Vector2(size.x * 0.5, y), Ornament.DIAMOND), line)
