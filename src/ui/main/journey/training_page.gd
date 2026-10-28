class_name TrainingPage
extends VBoxContainer
## The Training tab: what it is and the working Start Training button.

signal start_pressed

var start_button: Button


func _init() -> void:
	add_theme_constant_override(&"separation", 18)
	add_child(UiStyle.label("TRAINING", 34, UiStyle.TITLE_COLOR))
	var text := UiStyle.label("Practice on training dummies with what you have bought in the Evolution Tree and your equipped skin. No essences are earned. Leave from the ESC menu to come back here.", 22, UiStyle.TEXT_COLOR)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = 900.0
	add_child(text)
	start_button = Button.new()
	start_button.text = "Start Training"
	start_button.custom_minimum_size = Vector2(320, 64)
	UiStyle.style_button(start_button, 28, true)
	start_button.add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR)
	start_button.pressed.connect(start_pressed.emit)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add_child(start_button)
