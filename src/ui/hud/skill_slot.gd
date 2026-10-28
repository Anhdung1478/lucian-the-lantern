class_name SkillSlot
extends Control
## One skill icon on the HUD: cooldown sweep, rank dots, mana cost, "+" button
## and lock icon. A slot without a skill is the passive, drawn smaller.
## Hovering shows the skill's card above it.

const ICON_SIZE := 64.0
## 70% of a skill icon.
const PASSIVE_SIZE := 45.0
const PLUS_HEIGHT := 26.0
const PLUS_RADIUS := 11.0
const PLUS_FILL := Color(0.07, 0.08, 0.11, 0.92)
const PLUS_HOVER := Color("fff1c2")
## A "+" that can't be pressed yet.
const PLUS_GREY := Color(0.45, 0.47, 0.52)
const DOTS_HEIGHT := 12.0
const SWEEP_COLOR := Color(0, 0, 0, 0.68)
const FRAME_COLOR := Color(0.36, 0.4, 0.48)
const DOT_ON := Color("ffcf5a")
const DOT_OFF := Color(0.2, 0.22, 0.27)
const NO_MANA_TINT := Color(0.45, 0.55, 1.0)
const UNLEARNED_TINT := Color(0.35, 0.35, 0.35)
## Greys out a skill another one holds back (Q and W during R, E during Q).
const GREY_SHADER := preload("res://src/ui/hud/grey_icon.gdshader")
const LOCK_TEXTURE := preload("res://assets/art/ui/lock.svg")

var lucian: Lucian
## Null for the passive slot.
var skill: LucianSkill

var _icon: TextureRect
var _overlay: Control
var _plus: Button
var _cooldown_label: Label
var _cost_label: Label
var _lock: TextureRect
var _key_label: Label
var _key := ""
var _icon_size := ICON_SIZE
var _grey := ShaderMaterial.new()
## The next rank isn't bought yet: the grey "+" gets a lock.
var _plus_locked := false


## `icon_size` is smaller than ICON_SIZE for the passive, which then sits
## centered in the skill icons' band.
func setup(target: Lucian, slot_skill: LucianSkill, icon: Texture2D, key: String, icon_size := ICON_SIZE) -> void:
	lucian = target
	skill = slot_skill
	_key = key
	_icon_size = icon_size
	custom_minimum_size = Vector2(icon_size, PLUS_HEIGHT + ICON_SIZE + DOTS_HEIGHT)
	var icon_rect := Rect2(0, PLUS_HEIGHT + (ICON_SIZE - icon_size) * 0.5, icon_size, icon_size)

	# A flat, text-less button: _draw_plus paints the ringed circle and the "+".
	_plus = Button.new()
	_plus.flat = true
	_plus.focus_mode = FOCUS_NONE
	for style in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
		_plus.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	_plus.position = Vector2(ICON_SIZE * 0.5 - PLUS_RADIUS - 1.0, 0)
	_plus.size = Vector2.ONE * (PLUS_RADIUS + 1.0) * 2.0
	_plus.visible = false
	_plus.draw.connect(_draw_plus)
	if skill:
		_plus.pressed.connect(func() -> void: lucian.try_rank_up(skill.slot))
	add_child(_plus)

	_grey.shader = GREY_SHADER
	_icon = TextureRect.new()
	_icon.texture = icon
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_SCALE
	_place(_icon, icon_rect)

	_overlay = Control.new()
	_overlay.draw.connect(_draw_overlay)
	_place(_overlay, icon_rect)

	_lock = TextureRect.new()
	_lock.texture = LOCK_TEXTURE
	_lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_lock.visible = false
	_place(_lock, Rect2(icon_rect.get_center() - Vector2(16, 16), Vector2(32, 32)))

	_cooldown_label = _label(icon_rect, 24, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	_cost_label = _label(icon_rect.grow(-3), 13, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP)
	_cost_label.add_theme_color_override(&"font_color", Color("8fb8ff"))
	_key_label = _label(icon_rect.grow(-3), 13, HORIZONTAL_ALIGNMENT_RIGHT, VERTICAL_ALIGNMENT_BOTTOM)
	_key_label.text = key


## Shows a new key after rebinding.
func set_key(key: String) -> void:
	_key = key
	_key_label.text = key


func _process(_delta: float) -> void:
	if lucian == null:
		return
	_overlay.queue_redraw()
	if skill == null:
		return
	var progress := lucian.progress
	var cost := skill.mana_cost()
	var remaining := skill.cooldown.remaining
	_lock.visible = progress.bought[skill.slot] == 0
	# With a point to spend, every unmaxed skill shows its "+": gold when it
	# can rank up, grey (and locked if the rank isn't bought) when not. No
	# rank-ups while paused, same as Ctrl + key.
	_plus.visible = progress.skill_points() > 0 and not progress.is_maxed(skill.slot) and not get_tree().paused
	_plus.disabled = not progress.can_rank_up(skill.slot)
	_plus_locked = not progress.next_rank_bought(skill.slot)
	_plus.queue_redraw()
	_cost_label.text = str(roundi(cost)) if cost > 0.0 else ""
	if remaining <= 0.0:
		_cooldown_label.text = ""
	elif remaining < 1.0:
		_cooldown_label.text = "%.1f" % remaining
	else:
		_cooldown_label.text = str(ceili(remaining))
	var blocked := skill.rank() > 0 and lucian.is_skill_blocked(skill.slot)
	var material: Material = _grey if blocked else null
	if _icon.material != material:
		_icon.material = material
	if skill.rank() == 0:
		_icon.modulate = UNLEARNED_TINT
	elif blocked:
		_icon.modulate = Color.WHITE
	elif lucian.mana < cost:
		_icon.modulate = NO_MANA_TINT
	else:
		_icon.modulate = Color.WHITE
	queue_redraw()


func tooltip_content() -> Control:
	return TooltipCard.skill(lucian, skill, _icon.texture, _key)


func tooltip_place() -> HoverTip.Place:
	return HoverTip.Place.ABOVE


## Rank dots under the icon.
func _draw() -> void:
	if skill == null:
		return
	var count := skill.data.max_rank
	var dot := Vector2(9, 5)
	var gap := 3.0
	var start_x := (ICON_SIZE - count * dot.x - (count - 1) * gap) * 0.5
	for i in count:
		var rect := Rect2(Vector2(start_x + i * (dot.x + gap), PLUS_HEIGHT + ICON_SIZE + 4.0), dot)
		draw_rect(rect, DOT_ON if i < skill.rank() else DOT_OFF)


func _draw_overlay() -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(_icon_size, _icon_size))
	if skill:
		var fraction := skill.cooldown.fraction_remaining()
		if fraction > 0.005:
			_overlay.draw_colored_polygon(sweep_polygon(fraction, _icon_size), SWEEP_COLOR)
	elif lucian.passive.charged:
		_overlay.draw_rect(rect.grow(-2.0), DOT_ON, false, 4.0)
		return
	_overlay.draw_rect(rect, FRAME_COLOR, false, 2.0)


## The rank-up button: a gold "+" in a gold ring. Brighter on hover; pressing
## fills the circle gold. Grey when the skill can't rank up now, with a small
## lock when its next rank isn't bought.
func _draw_plus() -> void:
	var center := _plus.size * 0.5
	var mode := _plus.get_draw_mode()
	var pressed := mode == BaseButton.DRAW_PRESSED or mode == BaseButton.DRAW_HOVER_PRESSED
	var accent := PLUS_HOVER if mode == BaseButton.DRAW_HOVER else DOT_ON
	if _plus.disabled:
		accent = PLUS_GREY
		pressed = false
	_plus.draw_circle(center, PLUS_RADIUS, accent if pressed else PLUS_FILL)
	_plus.draw_arc(center, PLUS_RADIUS, 0.0, TAU, 32, accent, 2.0, true)
	var mark := PLUS_FILL if pressed else accent
	var arm := PLUS_RADIUS * 0.55
	_plus.draw_line(center - Vector2(arm, 0), center + Vector2(arm, 0), mark, 3.0, true)
	_plus.draw_line(center - Vector2(0, arm), center + Vector2(0, arm), mark, 3.0, true)
	if _plus.disabled and _plus_locked:
		_plus.draw_texture_rect(LOCK_TEXTURE, Rect2(center + Vector2(PLUS_RADIUS - 2.0, -2.0), Vector2(14, 14)), false)


## Dark area of a square cooldown sweep: the last `fraction` of a clockwise
## turn that starts at 12 o'clock, like LoL.
static func sweep_polygon(fraction: float, square: float) -> PackedVector2Array:
	var center := Vector2(square, square) * 0.5
	var start := -PI / 2.0 + TAU * (1.0 - fraction)
	var angles := [start]
	for corner in [-PI / 4.0, PI / 4.0, 3.0 * PI / 4.0, 5.0 * PI / 4.0]:
		if corner > start:
			angles.append(corner)
	angles.append(3.0 * PI / 2.0)
	var points := PackedVector2Array([center])
	for angle: float in angles:
		var direction := Vector2(cos(angle), sin(angle))
		points.append(center + direction / maxf(absf(direction.x), absf(direction.y)) * square * 0.5)
	return points


func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size
	control.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(control)


func _label(rect: Rect2, font_size: int, horizontal: HorizontalAlignment, vertical: VerticalAlignment) -> Label:
	var label := Label.new()
	label.horizontal_alignment = horizontal
	label.vertical_alignment = vertical
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	label.add_theme_constant_override(&"outline_size", 5)
	_place(label, rect)
	return label
