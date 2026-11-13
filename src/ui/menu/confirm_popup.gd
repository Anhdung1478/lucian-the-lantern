class_name ConfirmPopup
extends CanvasLayer
## A question over everything else, on a MenuCard over the blurred screen: Yes / No (ask), Yes / No / Cancel
## (ask_or_cancel) or an action / Cancel (confirm); or a notice with OK alone
## (tell). Swallows all keys while open. ESC is Cancel when the question has
## one; on a Yes / No question it answers No when the question allows it; on a
## notice it is OK. The arrow keys pick a button and Enter presses it; Yes
## (or the action, or OK) starts lit, so Enter confirms at once. It opens and
## closes with the overlay motion (UiMotion.open_overlay): is_open() flips at
## once, only the look trails.

const BUTTON_SIZE := Vector2(200, 56)
## Above the menus. A pop-up that must stay on top of another one (Game's
## "Save before leaving?") gets a higher layer: it is drawn over the other and
## gets clicks first.
const LAYER := 80
## A question wraps at this width (560 px on screen); the card is never wider
## than CARD_MAX (640 px): WRAP_WIDTH plus the card's side padding fits.
const WRAP_WIDTH := 672.0
const CARD_MAX := 768.0
const MESSAGE_FONT := 26

var _on_yes := Callable()
var _on_no := Callable()
var _on_cancel := Callable()
var _escape_means_no := true
var _message: Label
var _backdrop: MenuBackdrop
var _center: CenterContainer
## True from open to answer, whatever the look is doing.
var _is_open := false
## Built once; each question shows and labels the ones it needs.
var _yes: Button
var _no: Button
var _cancel: Button
## Arrow keys and Enter on the buttons shown.
var _keys := MenuKeys.new()


func _init(on_layer := LAYER) -> void:
	layer = on_layer


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	visible = false
	_build()


func _build() -> void:
	_backdrop = MenuBackdrop.new()
	add_child(_backdrop)
	_center = CenterContainer.new()
	_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.add_child(_center)
	var card := MenuCard.new()
	_center.add_child(card)
	var box := card.content
	box.add_theme_constant_override(&"separation", 18)
	_message = Label.new()
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.add_theme_color_override(&"font_color", UiStyle.TITLE_COLOR)
	_message.add_theme_font_size_override(&"font_size", MESSAGE_FONT)
	box.add_child(_message)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 16)
	box.add_child(row)
	_yes = _button(row, Lang.t("Yes"), answer.bind(true))
	_no = _button(row, Lang.t("No"), answer.bind(false))
	_cancel = _button(row, Lang.t("Cancel"), cancel)
	_keys.set_buttons(MenuKeys.buttons_in(row))


func _button(row: HBoxContainer, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = BUTTON_SIZE
	UiStyle.style_button(button)
	button.pressed.connect(action)
	row.add_child(button)
	return button


## Yes / No: Overwrite, Reset tree, "Could not save…". ESC answers No when
## `escape_means_no`, else does nothing.
func ask(text: String, on_yes: Callable, on_no := Callable(), escape_means_no := true) -> void:
	_open(text, Lang.t("Yes"), true, false)
	_on_yes = on_yes
	_on_no = on_no
	_escape_means_no = escape_means_no


## Yes / No / Cancel: "Save before leaving?". The Cancel button and ESC call
## `on_cancel`.
func ask_or_cancel(text: String, on_yes: Callable, on_no: Callable, on_cancel := Callable()) -> void:
	_open(text, Lang.t("Yes"), true, true)
	_on_yes = on_yes
	_on_no = on_no
	_on_cancel = on_cancel


## [action_label] / Cancel: "Exit the game?" Exit / Cancel. The action
## answers like Yes; the Cancel button and ESC call `on_cancel`.
func confirm(text: String, action_label: String, on_action: Callable, on_cancel := Callable()) -> void:
	_open(text, action_label, false, true)
	_on_yes = on_action
	_on_cancel = on_cancel


## OK alone: "Your backpack is full." OK, Enter and ESC close it, then call
## `on_ok`.
func tell(text: String, on_ok := Callable()) -> void:
	_open(text, Lang.t("OK"), false, false)
	_on_yes = on_ok


## Shows the question with these buttons; the last question's answers are dropped.
func _open(text: String, yes_label: String, with_no: bool, with_cancel: bool) -> void:
	_message.text = text
	_message.custom_minimum_size.x = _wrap_width(text)
	_yes.text = yes_label
	_no.visible = with_no
	_cancel.visible = with_cancel
	_on_yes = Callable()
	_on_no = Callable()
	_on_cancel = Callable()
	_escape_means_no = false
	_is_open = true
	visible = true
	UiMotion.open_overlay(_backdrop, _center)
	_keys.light(0)


## The question's width: its longest line on one row, or WRAP_WIDTH when longer.
func _wrap_width(text: String) -> float:
	var font := _message.get_theme_font(&"font")
	var widest := 0.0
	for line in text.split("\n"):
		widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, MESSAGE_FONT).x)
	return minf(widest + 4.0, WRAP_WIDTH)


func is_open() -> bool:
	return _is_open


## The look of closing: the card and the dim fade out, then the layer is hidden.
func _close() -> void:
	_is_open = false
	UiMotion.close_overlay(_backdrop, _center, func() -> void: visible = false)


## Hides the pop-up, then calls the matching callable (which may ask again).
## Does nothing while the pop-up is closed, so an old question never answers,
## nor No on a question without a No.
func answer(yes: bool) -> void:
	if not _is_open or (not yes and not _no.visible):
		return
	_close()
	var action := _on_yes if yes else _on_no
	if action.is_valid():
		action.call()


## The Cancel button and ESC: hides the pop-up, then calls `on_cancel`. Does
## nothing while the pop-up is closed or on a question without Cancel.
func cancel() -> void:
	if not _is_open or not _cancel.visible:
		return
	_close()
	if _on_cancel.is_valid():
		_on_cancel.call()


## Hides the pop-up without answering: what it asked about went away (the
## backpack closed under it).
func dismiss() -> void:
	if _is_open:
		_close()


func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			if _cancel.visible:
				cancel()
			elif _escape_means_no:
				answer(false)
			elif not _no.visible:
				answer(true)
		else:
			_keys.handle(event)
		get_viewport().set_input_as_handled()
