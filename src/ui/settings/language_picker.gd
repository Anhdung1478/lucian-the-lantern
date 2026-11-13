class_name LanguagePicker
extends HBoxContainer
## The languages as a row of small buttons, each named in its own language
## and never translated, so a player who can't read the one in use still
## finds theirs. The one in use is lit gold. A click sets the "language"
## setting; the Game then builds the screen again in it.

const BUTTON_SIZE := Vector2(132, 40)
const FONT := 18
const GAP := 8

var settings: GameSettings
## Language code -> its button.
var buttons := {}


func _init(game_settings: GameSettings = null) -> void:
	settings = game_settings
	add_theme_constant_override(&"separation", GAP)


func _ready() -> void:
	if settings == null:
		settings = GameSettings.instance()
	for code in Lang.CODES:
		var button := Button.new()
		button.text = Lang.NAMES[code]
		# A language's own name stays as it is in every language.
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		button.custom_minimum_size = BUTTON_SIZE
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(choose.bind(code))
		add_child(button)
		buttons[code] = button
	settings.changed.connect(_on_changed)
	_light()


## Sets the language; choosing the one in use does nothing.
func choose(code: String) -> void:
	if settings.get_value(&"language") != code:
		settings.set_value(&"language", code)


func _on_changed(key: StringName) -> void:
	if key == &"language":
		_light()


func _light() -> void:
	for code: String in buttons:
		UiStyle.style_button(buttons[code], FONT, settings.get_value(&"language") == code)
