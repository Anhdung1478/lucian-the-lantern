class_name SettingsScreen
extends CanvasLayer
## Settings, opened from the ESC menu, the title screen or the main screen's
## gear: Audio (volumes), Controls (rebinding, and a cast mode for each skill,
## item and summoner key), Graphics (window, resolution, VSync, FPS cap,
## quality, FPS counter) and Gameplay (skill queue). Every change applies at
## once and is saved. ESC or Back returns to the menu; while waiting for a new
## key, ESC cancels instead.
##
## The look: a lantern emblem on the panel's top edge over "SETTINGS" and a
## gold rule; a rail of icon tabs on the left, the open one lit gold with an
## accent bar; each page's rows are cards that brighten on hover.
## UiStyle.theme() dresses the sliders, dropdowns, switches and scroll bar.
##
## Rebinding: click a binding, then press a key, or click the same binding
## again with the mouse button to bind. A click anywhere else cancels.

signal back_requested

const PANEL_SIZE := Vector2(1120, 720)
## The panel's inner margin; the top one clears the emblem's lower half.
const PAD := 26.0
const HEADER_TOP := 46.0
const TITLE_FONT := 34
## The lantern emblem, a medallion on the panel's top edge, and its glow.
const EMBLEM := preload("res://assets/art/ui/title_lantern.svg")
const EMBLEM_RADIUS := 40.0
const EMBLEM_ART := 68.0
const LANTERN_GLOW := Color("6ee6a0")
const GLOW_ALPHA := 0.12
const TAB_NAMES := ["Audio", "Controls", "Graphics", "Gameplay"]
## Each page's dim line under its name.
const TAB_BLURBS := [
	"Volumes change at once. Letting go of a slider plays a test sound.",
	"Click a binding, then press a key or click it again with a mouse button.",
	"The window, the frame rate and how much the effects cost.",
	"How Lucian takes your orders.",
]
const TAB_ICONS := [
	preload("res://assets/art/ui/settings_audio.svg"),
	preload("res://assets/art/ui/settings_controls.svg"),
	preload("res://assets/art/ui/settings_graphics.svg"),
	preload("res://assets/art/ui/settings_gameplay.svg"),
]
const RAIL_WIDTH := 240.0
const TAB_HEIGHT := 60.0
const TAB_FONT := 20
const TAB_ICON := 32
## The open tab's gold bar along its left edge.
const ACCENT_WIDTH := 4
const PAGE_TITLE_FONT := 28
const NOTE_FONT := SettingsRow.NOTE_FONT
## Between row cards.
const CARD_GAP := 8
const CONTROL_HEIGHT := 36.0
const SLIDER_WIDTH := 340.0
const OPTION_WIDTH := 280.0
const BIND_WIDTH := 150.0
const BIND_FONT := 17
const CAST_WIDTH := 210.0
## Room between the Controls list and its scroll bar.
const SCROLL_GAP := 14
const BACK_SIZE := Vector2(200, 50)
const VOLUMES := [
	["Master volume", &"master_volume", "Every sound in the game."],
	["Music volume", &"music_volume", "No music yet: this slider is ready for it."],
	["Sound effects volume", &"sfx_volume", "Shots, hits, coins and clicks."],
]
const CAST_MODE_LABELS := ["Quick cast", "Quick + indicator", "Normal cast"]
## The Controls list's captions, each over its group's first action.
const CONTROL_GROUPS := {
	&"move": "MOVE AND ATTACK", &"skill_q": "SKILLS", &"summoner_d": "SUMMONER SPELLS",
	&"item_1": "ITEMS", &"open_backpack": "INTERFACE",
}
const CONTROLS_HINT := "ESC or a click elsewhere cancels a binding. Ctrl + a skill key ranks it up. Quick + indicator casts on release, Normal on left-click; right-click or ESC cancels either."
## Pressed alone, these never become a binding.
const MODIFIER_KEYS := [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]
const WHEEL_BUTTONS := [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]

var settings: GameSettings

var _panel: PanelContainer
var _tab_buttons: Array[Button] = []
var _pages: Array[Control] = []
var _bind_buttons := {}
## Castable action -> its cast mode picker.
var _cast_modes := {}
## Greyed out unless the window mode is windowed.
var _resolution: OptionButton
## The action waiting for a new key, or &"".
var _listening: StringName = &""
var _listen_frame := -1


func _ready() -> void:
	layer = 45
	visible = false


func setup(game_settings: GameSettings) -> void:
	settings = game_settings
	settings.changed.connect(_on_changed)
	_build()


func open() -> void:
	visible = true
	_stop_listening()
	show_tab(0)


func close() -> void:
	_stop_listening()
	visible = false


func show_tab(tab: int) -> void:
	for i in _pages.size():
		_pages[i].visible = i == tab
		_style_tab(_tab_buttons[i], i == tab)


func is_listening() -> bool:
	return _listening != &""


## Starts waiting for the next key or mouse button for `action`.
func listen(action: StringName) -> void:
	_stop_listening()
	_listening = action
	var button: Button = _bind_buttons[action]
	button.text = "Press a key..."
	UiStyle.style_button(button, BIND_FONT, true)
	# The click that started listening must not bind itself.
	_listen_frame = Engine.get_process_frames()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if is_listening():
		var key := event as InputEventKey
		var mouse := event as InputEventMouseButton
		if key and key.pressed and not key.echo:
			if key.physical_keycode == KEY_ESCAPE:
				_stop_listening()
			elif not MODIFIER_KEYS.has(key.physical_keycode):
				_bind(key)
			get_viewport().set_input_as_handled()
		elif mouse and mouse.pressed and not WHEEL_BUTTONS.has(mouse.button_index) \
				and Engine.get_process_frames() != _listen_frame:
			var button: Button = _bind_buttons[_listening]
			if button.get_global_rect().has_point(button.get_global_mouse_position()):
				_bind(mouse)
				get_viewport().set_input_as_handled()
			else:
				_stop_listening()
	elif event.is_action_pressed(&"open_menu"):
		back_requested.emit()
		get_viewport().set_input_as_handled()


func _bind(event: InputEvent) -> void:
	var action := _listening
	_listening = &""
	settings.rebind(action, event)


func _stop_listening() -> void:
	_listening = &""
	_refresh_bindings()


func _on_changed(key: StringName) -> void:
	match key:
		&"bindings":
			_refresh_bindings()
			settings.apply_input()
		&"cast_modes":
			for action: StringName in _cast_modes:
				_cast_modes[action].select(GameSettings.CAST_MODES.find(settings.cast_mode(action)))
		&"master_volume", &"music_volume", &"sfx_volume":
			settings.apply_audio()
		&"window_mode":
			settings.apply_display()
			settings.apply_resolution()
			_resolution.disabled = settings.get_value(&"window_mode") != "windowed"
		&"resolution":
			settings.apply_resolution()
		&"vsync", &"max_fps", &"quality":
			settings.apply_display()


func _refresh_bindings() -> void:
	for action: StringName in _bind_buttons:
		_bind_buttons[action].text = settings.key_label(action)
		UiStyle.style_button(_bind_buttons[action], BIND_FONT)


func _cast_mode_picker(action: StringName) -> OptionButton:
	var option := _dropdown(CAST_MODE_LABELS, CAST_WIDTH)
	option.select(GameSettings.CAST_MODES.find(settings.cast_mode(action)))
	option.item_selected.connect(func(index: int) -> void: settings.set_cast_mode(action, GameSettings.CAST_MODES[index]))
	_cast_modes[action] = option
	return option


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.55)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = PANEL_SIZE
	_panel.add_theme_stylebox_override(&"panel", UiStyle.panel(Color(UiStyle.PANEL_COLOR, 1.0), UiStyle.BORDER_COLOR, 2, 0.0))
	_panel.theme = UiStyle.theme()
	center.add_child(_panel)
	var decor := Control.new()
	decor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decor.draw.connect(_draw_emblem.bind(decor))
	_panel.add_child(decor)

	var margin := MarginContainer.new()
	for side: String in ["left", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, int(PAD))
	margin.add_theme_constant_override(&"margin_top", int(HEADER_TOP))
	_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 14)
	margin.add_child(box)
	box.add_child(_header())
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override(&"separation", 28)
	box.add_child(body)
	body.add_child(_rail())

	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override(&"separation", 10)
	body.add_child(side)
	var pages := Control.new()
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(pages)
	for build in [_build_audio, _build_controls, _build_graphics, _build_gameplay]:
		var page: Control = build.call()
		page.set_anchors_preset(Control.PRESET_FULL_RECT)
		pages.add_child(page)
		_pages.append(page)
	side.add_child(HSeparator.new())
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	side.add_child(bottom)
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = BACK_SIZE
	UiStyle.style_button(back, 22, true)
	back.add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR)
	back.pressed.connect(func() -> void: back_requested.emit())
	bottom.add_child(back)


## "SETTINGS" in spaced capitals over the Journey's gold rule.
func _header() -> Control:
	var header := VBoxContainer.new()
	header.add_theme_constant_override(&"separation", 4)
	var title := UiStyle.label("SETTINGS", TITLE_FONT, UiStyle.TITLE_COLOR)
	title.add_theme_font_override(&"font", JourneyMap.text_font(title, 5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title)
	var rule := JourneyPanel.divider()
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	header.add_child(rule)
	return header


## The tabs, an icon and a name each, and a note that changes save at once.
func _rail() -> Control:
	var rail := PanelContainer.new()
	rail.custom_minimum_size.x = RAIL_WIDTH
	var style := UiStyle.panel(Color(0, 0, 0, 0.22), Color(UiStyle.BORDER_COLOR, 0.18), 1, 14.0, 8)
	# The tabs' accent bars sit on the rail's left edge.
	style.content_margin_left = 1.0
	style.content_margin_right = 10.0
	rail.add_theme_stylebox_override(&"panel", style)
	var tabs := VBoxContainer.new()
	tabs.add_theme_constant_override(&"separation", 6)
	rail.add_child(tabs)
	for i in TAB_NAMES.size():
		var button := Button.new()
		button.text = TAB_NAMES[i]
		button.icon = TAB_ICONS[i]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = TAB_HEIGHT
		button.add_theme_constant_override(&"icon_max_width", TAB_ICON)
		button.add_theme_constant_override(&"h_separation", 14)
		button.pressed.connect(show_tab.bind(i))
		tabs.add_child(button)
		_tab_buttons.append(button)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(spacer)
	var note := UiStyle.label("Every change applies at once and is saved.", NOTE_FONT, UiStyle.DIM_COLOR)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.custom_minimum_size.x = RAIL_WIDTH - 24.0
	tabs.add_child(note)
	return rail


## The button look with the rail's shape: the open tab is lit gold with a gold
## bar on its left edge, the others are bare until hovered.
func _style_tab(button: Button, lit: bool) -> void:
	UiStyle.style_button(button, TAB_FONT, lit)
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		var style := button.get_theme_stylebox(state) as StyleBoxFlat
		var hover := state == &"hover" or state == &"pressed"
		style.set_border_width_all(0)
		style.border_width_left = ACCENT_WIDTH
		style.set_corner_radius_all(0)
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_right = 6
		style.content_margin_left = 18.0
		if lit:
			style.bg_color = Color(UiStyle.GOLD_COLOR, 0.14)
			style.border_color = UiStyle.GOLD_COLOR
		else:
			style.bg_color = Color(1, 1, 1, 0.05 if hover else 0.0)
			style.border_color = Color(UiStyle.BORDER_COLOR, 0.45 if hover else 0.0)
	var icon_tint := Color.WHITE if lit else Color(1, 1, 1, 0.65)
	button.add_theme_color_override(&"icon_normal_color", icon_tint)
	button.add_theme_color_override(&"icon_hover_color", Color.WHITE)
	button.add_theme_color_override(&"icon_pressed_color", Color.WHITE)


## The lantern medallion on the panel's top edge, its glow spilling down.
func _draw_emblem(decor: Control) -> void:
	JourneyPanel.draw_top_glow(decor, decor.size.x, LANTERN_GLOW, GLOW_ALPHA)
	var middle := Vector2(decor.size.x * 0.5, 0.0)
	var halo := Vector2.ONE * EMBLEM_RADIUS * 2.0
	decor.draw_texture_rect(JourneyMap.glow(), Rect2(middle - halo, halo * 2.0), false, Color(LANTERN_GLOW, 0.3))
	decor.draw_circle(middle, EMBLEM_RADIUS, JourneyPanel.BACKGROUND)
	decor.draw_arc(middle, EMBLEM_RADIUS - 1.0, 0.0, TAU, 64, UiStyle.BORDER_COLOR, 2.0, true)
	decor.draw_arc(middle, EMBLEM_RADIUS - 6.0, 0.0, TAU, 64, Color(UiStyle.BORDER_COLOR, 0.35), 1.0, true)
	decor.draw_texture_rect(EMBLEM, Rect2(middle - Vector2.ONE * EMBLEM_ART * 0.5, Vector2.ONE * EMBLEM_ART), false)


func _build_audio() -> Control:
	var page := _page(0)
	for volume: Array in VOLUMES:
		var key: StringName = volume[1]
		var row := _row(page, volume[0], volume[2])
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.custom_minimum_size = Vector2(SLIDER_WIDTH, CONTROL_HEIGHT)
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slider.focus_mode = Control.FOCUS_NONE
		slider.value = settings.get_value(key)
		row.add(slider)
		var value := UiStyle.label(str(int(slider.value)), SettingsRow.FONT, UiStyle.GOLD_COLOR)
		value.custom_minimum_size.x = 44
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add(value)
		slider.value_changed.connect(func(volume_value: float) -> void:
			value.text = str(int(volume_value))
			settings.set_value(key, int(volume_value)))
		slider.drag_ended.connect(func(_changed: bool) -> void: Sfx.play(&"coin"))
	return page


func _build_controls() -> Control:
	var reset := Button.new()
	reset.text = "Reset to defaults"
	reset.custom_minimum_size = Vector2(200, 40)
	UiStyle.style_button(reset, 16)
	reset.pressed.connect(func() -> void:
		settings.reset_bindings()
		settings.set_value(&"cast_modes", {}))
	var page := _page(1, reset)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	var inset := MarginContainer.new()
	inset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inset.add_theme_constant_override(&"margin_right", SCROLL_GAP)
	scroll.add_child(inset)
	var list := VBoxContainer.new()
	list.add_theme_constant_override(&"separation", CARD_GAP)
	inset.add_child(list)
	for action in GameSettings.REBINDABLE:
		if CONTROL_GROUPS.has(action):
			var caption := UiStyle.label(CONTROL_GROUPS[action], NOTE_FONT, JourneyPanel.CAPTION_COLOR)
			caption.add_theme_font_override(&"font", JourneyMap.text_font(caption, 3))
			list.add_child(caption)
		var row := _row(list, GameSettings.ACTION_NAMES[action])
		var button := Button.new()
		button.custom_minimum_size = Vector2(BIND_WIDTH, CONTROL_HEIGHT)
		button.pressed.connect(listen.bind(action))
		row.add(button)
		_bind_buttons[action] = button
		if GameSettings.CASTABLE.has(action):
			row.add(_cast_mode_picker(action))
		else:
			# Keeps the bindings in one column.
			var gap := Control.new()
			gap.custom_minimum_size.x = CAST_WIDTH
			row.add(gap)
	_refresh_bindings()
	var hint := UiStyle.label(CONTROLS_HINT, NOTE_FONT, UiStyle.DIM_COLOR)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(hint)
	return page


func _build_graphics() -> Control:
	var page := _page(2)
	_option(page, "Window mode", &"window_mode", ["Windowed", "Borderless fullscreen", "Fullscreen"], GameSettings.WINDOW_MODES)
	_resolution = _build_resolution(page)
	_toggle(page, "VSync", &"vsync")
	_option(page, "FPS cap", &"max_fps", ["30", "60", "120", "144", "Unlimited"], GameSettings.FPS_CAPS)
	_option(page, "Quality", &"quality", ["Low", "Medium", "High"], GameSettings.QUALITIES,
		"Low turns off anti-aliasing, dash trails and muzzle flashes; Medium uses 2x anti-aliasing.")
	_toggle(page, "Show FPS", &"show_fps")
	return page


## Every resolution is listed, so the saved one always shows; sizes too big
## for a window on this screen are greyed out (a saved one shrinks to fit).
func _build_resolution(page: Control) -> OptionButton:
	var headless := DisplayServer.get_name() == "headless"
	var biggest := Vector2i.ZERO if headless else GameSettings.max_window_size()
	var labels: Array = []
	var too_big: Array[bool] = []
	for size: String in GameSettings.RESOLUTIONS:
		var parsed := GameSettings.parse_resolution(size)
		too_big.append(not headless and (parsed.x > biggest.x or parsed.y > biggest.y))
		labels.append(size.replace("x", " × ") + (" (too big)" if too_big.back() else ""))
	var option := _option(page, "Resolution", &"resolution", labels, GameSettings.RESOLUTIONS,
		"Borderless and fullscreen use the screen's resolution.")
	for i in too_big.size():
		option.set_item_disabled(i, too_big[i])
	option.disabled = settings.get_value(&"window_mode") != "windowed"
	return option


func _build_gameplay() -> Control:
	var page := _page(3)
	_toggle(page, "Skill queue", &"queue_casts",
		"A skill pressed during another skill's cast time or the E dash is cast as soon as it ends, aimed where the key was pressed. Only the latest press is kept.")
	return page


## A page: its name in spaced capitals and a dim line under it, then a rule;
## the caller adds the rows. `extra` (Controls' reset button) sits right of
## the name.
func _page(tab: int, extra: Control = null) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override(&"separation", CARD_GAP)
	var heading := HBoxContainer.new()
	page.add_child(heading)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override(&"separation", 2)
	heading.add_child(texts)
	var title := UiStyle.label(String(TAB_NAMES[tab]).to_upper(), PAGE_TITLE_FONT, UiStyle.TITLE_COLOR)
	title.add_theme_font_override(&"font", JourneyMap.text_font(title, 4))
	texts.add_child(title)
	texts.add_child(UiStyle.label(TAB_BLURBS[tab], 16, UiStyle.DIM_COLOR))
	if extra:
		extra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		heading.add_child(extra)
	page.add_child(HSeparator.new())
	return page


## A row card on `page`; the caller adds its controls.
func _row(page: Control, text: String, description := "") -> SettingsRow:
	var row := SettingsRow.new(text, description)
	page.add_child(row)
	return row


func _dropdown(labels: Array, width: float) -> OptionButton:
	var option := OptionButton.new()
	option.focus_mode = Control.FOCUS_NONE
	option.custom_minimum_size = Vector2(width, CONTROL_HEIGHT)
	option.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for label: String in labels:
		option.add_item(label)
	return option


func _option(page: Control, text: String, key: StringName, labels: Array, values: Array, description := "") -> OptionButton:
	var row := _row(page, text, description)
	var option := _dropdown(labels, OPTION_WIDTH)
	option.selected = maxi(values.find(settings.get_value(key)), 0)
	option.item_selected.connect(func(index: int) -> void: settings.set_value(key, values[index]))
	row.add(option)
	return option


func _toggle(page: Control, text: String, key: StringName, description := "") -> CheckButton:
	var row := _row(page, text, description)
	var toggle := CheckButton.new()
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.custom_minimum_size.y = CONTROL_HEIGHT
	toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	toggle.button_pressed = settings.get_value(key)
	toggle.toggled.connect(func(on: bool) -> void: settings.set_value(key, on))
	row.add(toggle)
	return toggle
