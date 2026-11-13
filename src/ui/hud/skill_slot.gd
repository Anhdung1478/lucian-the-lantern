class_name SkillSlot
extends Control
## One skill on the HUD, in a dark cell: its icon, cooldown sweep and
## seconds, mana cost (a tab top left), its key (a tab bottom right), rank
## diamonds under it, the "+" button over it and a lock while it isn't bought
## (then no "+": the lock says it). A slot without a skill is the passive,
## drawn smaller. The cell's rim eases to gold while the mouse is on the slot;
## hovering shows the skill's card above the bar.

const ICON_SIZE := 64.0
## 70% of a skill icon.
const PASSIVE_SIZE := 45.0
## The band over the cell for the "+": its ring (PLUS_RADIUS + 1 out from
## its centre) ends 7 (6 px on screen) above the cell.
const PLUS_HEIGHT := 29.0
const PLUS_RADIUS := 10.0
const PLUS_FILL := Color(0.07, 0.08, 0.11, 0.92)
const PLUS_HOVER := Color("fff1c2")
## A "+" that can't be pressed yet.
const PLUS_GREY := Color(0.45, 0.47, 0.52)
## The soft light behind a "+" that can be pressed.
const PLUS_GLOW := 0.35
## The band under the cell for the rank diamonds: DOTS_GAP, then a diamond.
const DOTS_HEIGHT := 14.0
const DOTS_GAP := 5.0
## A rank diamond: its half-width and the step from one to the next (about
## 4 px between two on screen).
const DIAMOND := 4.5
const DIAMOND_STEP := 13.5
## The small lock beside a grey "+" whose next rank isn't bought.
const PLUS_LOCK := 16.0
const COST_COLOR := Color("8fb8ff")
const SWEEP_COLOR := Color(0, 0, 0, 0.68)
const DOT_ON := Color("ffcf5a")
const DOT_OFF := Color(0.2, 0.22, 0.27)
## The charged passive's ring.
const CHARGED_WIDTH := 3
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
var _key := ""
var _icon_size := ICON_SIZE
var _grey := ShaderMaterial.new()
## The next rank isn't bought yet: the grey "+" gets a lock.
var _plus_locked := false
## How far the rim has eased to gold (UiMotion.lit).
var lit_t := 0.0
## The mouse is on the slot: its rim eases to gold.
var _hovered := false:
	set(value):
		_hovered = value
		UiMotion.lit(self, value)


## `icon_size` is smaller than ICON_SIZE for the passive, which then sits
## centered in the skill icons' band.
func setup(target: Lucian, slot_skill: LucianSkill, icon: Texture2D, key: String, icon_size := ICON_SIZE) -> void:
	lucian = target
	skill = slot_skill
	_key = key
	_icon_size = icon_size
	custom_minimum_size = Vector2(icon_size, PLUS_HEIGHT + ICON_SIZE + DOTS_HEIGHT)
	var cell := _cell_rect()
	mouse_entered.connect(func() -> void: _hovered = true)
	mouse_exited.connect(func() -> void: _hovered = false)

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
	_place(_icon, cell.grow(-HudCell.INSET))

	_overlay = Control.new()
	_overlay.draw.connect(_draw_overlay)
	_place(_overlay, cell)

	_lock = TextureRect.new()
	_lock.texture = LOCK_TEXTURE
	_lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_lock.visible = false
	_place(_lock, Rect2(cell.get_center() - Vector2(16, 16), Vector2(32, 32)))

	_cooldown_label = _label(cell, 24, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	# Its text is drawn in the cell's top-left tab (_draw_overlay).
	_cost_label = _label(cell.grow(-4), UiStyle.FONT_TAG, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP)
	_cost_label.add_theme_color_override(&"font_color", COST_COLOR)
	_cost_label.visible = false


## Shows a new key after rebinding.
func set_key(key: String) -> void:
	_key = key
	_overlay.queue_redraw()


func _process(_delta: float) -> void:
	if lucian == null:
		return
	_overlay.queue_redraw()
	queue_redraw()
	if skill == null:
		# The passive: locked and grey until the Evolution Tree teaches it.
		var learned := lucian.passive.learned
		_lock.visible = not learned
		var passive_material: Material = null if learned else _grey
		if _icon.material != passive_material:
			_icon.material = passive_material
		return
	var progress := lucian.progress
	var cost := skill.mana_cost()
	var remaining := skill.cooldown.remaining
	_lock.visible = progress.bought[skill.slot] == 0
	# With a point to spend, every unmaxed skill shows its "+": gold when it
	# can rank up, grey (and locked if the rank isn't bought) when not. A skill
	# not bought at all has its lock on the cell and no "+". No rank-ups while
	# paused, same as Ctrl + key.
	_plus.visible = progress.skill_points() > 0 and not progress.is_maxed(skill.slot) and not get_tree().paused 		and not _lock.visible
	_plus.disabled = not progress.can_rank_up(skill.slot)
	_plus_locked = not progress.next_rank_bought(skill.slot)
	_plus.queue_redraw()
	_cost_label.text = str(roundi(cost)) if cost > 0.0 else ""
	_cooldown_label.text = HudCell.seconds_text(remaining) if remaining > 0.0 else ""
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


## Shown around Lucian while hovered, once the skill is learned.
func hover_range() -> CastRange:
	return lucian.skill_range(skill.slot) if skill else null


func tooltip_content() -> Control:
	return TooltipCard.skill(lucian, skill, _icon.texture, _key)


## What the card shows that can change while it is hovered: the haste, the
## rank and the lock. HoverTip rebuilds the card when it changes.
func tooltip_version() -> Variant:
	if skill == null:
		return null
	return [lucian.skill_haste(skill.slot), skill.rank(), lucian.skill_lock_note(skill.slot)]


func tooltip_place() -> HoverTip.Place:
	return HoverTip.Place.ABOVE


## The card hangs above the bar, over this cell.
func tooltip_anchor() -> Rect2:
	return HudCell.tip_anchor(self, _cell_rect())


## The cell behind the icon, and a skill's rank diamonds under it: gold for
## each rank learned.
func _draw() -> void:
	HudCell.draw_box(self, _cell_rect(), UiStyle.CELL_BORDER, lit_t)
	if skill == null:
		return
	var count := skill.data.max_rank
	var first := Vector2((ICON_SIZE - (count - 1) * DIAMOND_STEP) * 0.5, PLUS_HEIGHT + ICON_SIZE + DOTS_GAP + DIAMOND)
	for i in count:
		draw_colored_polygon(Plate.diamond(first + Vector2(i * DIAMOND_STEP, 0), DIAMOND), DOT_ON if i < skill.rank() else DOT_OFF)


## Over the icon: the cooldown sweep (or the charged passive's gold ring), the
## mana cost's tab and the key's tab.
func _draw_overlay() -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(_icon_size, _icon_size))
	if skill:
		var fraction := skill.cooldown.fraction_remaining()
		if fraction > 0.005:
			_overlay.draw_set_transform(Vector2.ONE * HudCell.INSET)
			_overlay.draw_colored_polygon(sweep_polygon(fraction, _icon_size - HudCell.INSET * 2.0), SWEEP_COLOR)
			_overlay.draw_set_transform(Vector2.ZERO)
	elif lucian.passive.learned and lucian.passive.charged:
		var ring := UiStyle.cell_style(DOT_ON)
		ring.draw_center = false
		ring.set_border_width_all(CHARGED_WIDTH)
		_overlay.draw_style_box(ring, rect)
	HudCell.draw_tab(_overlay, rect, _cost_label.text, CORNER_TOP_LEFT, COST_COLOR)
	HudCell.draw_key(_overlay, rect, _key)


## The rank-up button: a gold "+" in a gold ring over a soft light. Brighter
## on hover; pressing fills the circle gold. Grey, with no light, when the
## skill can't rank up now, and with a small lock when its next rank isn't
## bought.
func _draw_plus() -> void:
	var center := _plus.size * 0.5
	var mode := _plus.get_draw_mode()
	var pressed := mode == BaseButton.DRAW_PRESSED or mode == BaseButton.DRAW_HOVER_PRESSED
	var accent := PLUS_HOVER if mode == BaseButton.DRAW_HOVER else DOT_ON
	if _plus.disabled:
		accent = PLUS_GREY
		pressed = false
	else:
		_plus.draw_texture_rect(JourneyMap.glow(), Rect2(center - Vector2.ONE * PLUS_RADIUS * 2.0, Vector2.ONE * PLUS_RADIUS * 4.0), false, Color(DOT_ON, PLUS_GLOW))
	_plus.draw_circle(center, PLUS_RADIUS, accent if pressed else PLUS_FILL)
	_plus.draw_arc(center, PLUS_RADIUS, 0.0, TAU, 32, accent, 2.0, true)
	var mark := PLUS_FILL if pressed else accent
	var arm := PLUS_RADIUS * 0.55
	_plus.draw_line(center - Vector2(arm, 0), center + Vector2(arm, 0), mark, 3.0, true)
	_plus.draw_line(center - Vector2(0, arm), center + Vector2(0, arm), mark, 3.0, true)
	if _plus.disabled and _plus_locked:
		_plus.draw_texture_rect(LOCK_TEXTURE, Rect2(center + Vector2(PLUS_RADIUS - 3.0, -PLUS_LOCK * 0.5), Vector2.ONE * PLUS_LOCK), false)


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


## The cell: under the "+", centered in the skill icons' band.
func _cell_rect() -> Rect2:
	return Rect2(0, PLUS_HEIGHT + (ICON_SIZE - _icon_size) * 0.5, _icon_size, _icon_size)


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
