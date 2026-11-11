class_name BossBar
extends Control
## Under the stage info while a boss or a mini boss lives, on an ornate
## plate: its name, and its Boss.phase_label() after it (Act 6's Thresh:
## "Phase 1", "Phase 2"), as a heading in spaced capitals over a wide red
## health bar (a HudBar with Lucian's gradient and ghost damage, no ticks). It finds
## the unit itself (a boss before a mini boss).

## The health bar.
const SIZE := Vector2(600, 22)
const FILL_TOP := Color("e0524a")
const FILL_BOTTOM := Color("9c241f")
## The room between the plate's frame and what it holds.
const PAD := 14.0
const HEADING_HEIGHT := 20.0
const HEADING_GAP := 4.0
## The break bar under the health bar while the boss channels something that
## damage breaks (Soothing Mist, Requiem).
const BREAK_HEIGHT := 8.0
const BREAK_GAP := 4.0
const BREAK_FILL := Color("ffd166")
const BREAK_WELL := Color(0.02, 0.025, 0.04, 0.88)
const TEXT_SIZE := 15

var boss: EnemyUnit
## The boss's Boss.phase_label() as of the last frame; "" for none.
var phase_text := ""
## The boss's Boss.channel() as of the last frame; {} when it has none.
var channel := {}

var _heading := HudHeading.new()
var _bar := HudBar.new()
var _text := UiStyle.label("", TEXT_SIZE, Color.WHITE)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The plate always has room for the break bar, so it never changes height.
	custom_minimum_size = Vector2(SIZE.x + PAD * 2.0, PAD * 2.0 + HEADING_HEIGHT + HEADING_GAP + SIZE.y + BREAK_GAP + BREAK_HEIGHT)
	visible = false
	_heading.position = Vector2(PAD, PAD)
	_heading.size = Vector2(SIZE.x, HEADING_HEIGHT)
	add_child(_heading)
	_bar.fill_top = FILL_TOP
	_bar.fill_bottom = FILL_BOTTOM
	_bar.ticks = false
	_bar.position = Vector2(PAD, PAD + HEADING_HEIGHT + HEADING_GAP)
	_bar.size = SIZE
	add_child(_bar)
	_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.add_theme_constant_override(&"outline_size", 4)
	_text.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_bar.add_child(_text)


## Keeps the unit it holds while it lives, even untargetable (out of the
## enemies group), except that a boss takes the bar from a mini boss.
func _process(_delta: float) -> void:
	var held := is_instance_valid(boss) and boss.is_alive()
	var before := boss
	if not (held and boss.data.kind == &"boss"):
		var found := _find(&"boss")
		if found == null and not held:
			found = _find(&"mini_boss")
		if found or not held:
			boss = found
	visible = boss != null
	channel = (boss as Boss).channel() if boss is Boss else {}
	phase_text = (boss as Boss).phase_label() if boss is Boss else ""
	if boss != null:
		_heading.label.text = boss.data.display_name + ("   " + phase_text if phase_text != "" else "")
		# A new boss starts with no ghost.
		if boss != before:
			_bar.reset(boss.hp, boss.max_hp)
		_bar.show_amount(boss.hp, boss.max_hp)
		_text.text = "%d / %d" % [roundi(boss.hp), roundi(boss.max_hp)]
	queue_redraw()


func _find(kind: StringName) -> EnemyUnit:
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if enemy is EnemyUnit and (enemy as EnemyUnit).data.kind == kind:
			return enemy
	return null


func _draw() -> void:
	if boss == null:
		return
	Plate.draw_on(self, Rect2(Vector2.ZERO, size), 10.0, true, Hud.PLATE_OPACITY)
	if channel.is_empty():
		return
	var thin := Rect2(PAD, _bar.position.y + SIZE.y + BREAK_GAP, SIZE.x, BREAK_HEIGHT)
	var well := StyleBoxFlat.new()
	well.bg_color = BREAK_WELL
	well.set_corner_radius_all(HudBar.RADIUS)
	draw_style_box(well, thin)
	draw_rect(Rect2(thin.position, Vector2(SIZE.x * clampf(channel.done / channel.need, 0.0, 1.0), BREAK_HEIGHT)), BREAK_FILL)
