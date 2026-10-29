class_name TheEndScreen
extends Control
## The story's end: shown by Game on the first clear of the last stage, after
## the stage-end screen's button. "THE END", the lantern, the story time (the
## slot's play time) and the credits. Continue goes where that button said.
## ESC does nothing here.

signal continue_pressed

const LANTERN := preload("res://assets/art/ui/title_lantern.svg")
const BUTTON_SIZE := Vector2(420, 64)
const CREDITS: Array[String] = [
	"Lucian: The Lantern",
	"Made with Godot 4",
	"A fan game. League of Legends characters belong to Riot Games.",
]

var time_label := UiStyle.label("", 28, UiStyle.TEXT_COLOR)
var credit_labels: Array[Label] = []
var continue_button := Button.new()


## "1:02:05": hours, minutes and seconds.
static func story_time(seconds: float) -> String:
	var whole := maxi(int(seconds), 0)
	return "%d:%02d:%02d" % [whole / 3600, whole / 60 % 60, whole % 60]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


## ESC is taken so nothing under this screen reads it.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"open_menu"):
		get_viewport().set_input_as_handled()


func _build() -> void:
	var background := ColorRect.new()
	background.color = Color(0.02, 0.03, 0.04)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override(&"separation", 16)
	center.add_child(column)
	var lantern := TextureRect.new()
	lantern.texture = LANTERN
	lantern.custom_minimum_size = Vector2(200, 200)
	lantern.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lantern.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(lantern)
	column.add_child(_centered(UiStyle.label("THE END", 84, UiStyle.GOLD_COLOR)))
	column.add_child(_centered(UiStyle.label("Senna is free.", 34, Color("8fe3b0"))))
	time_label.text = "Story time: %s" % story_time(SaveGame.instance().play_time)
	column.add_child(_centered(time_label))
	for line in CREDITS:
		var credit := _centered(UiStyle.label(line, 20, UiStyle.DIM_COLOR))
		credit_labels.append(credit)
		column.add_child(credit)
	continue_button.text = "Continue"
	continue_button.custom_minimum_size = BUTTON_SIZE
	UiStyle.style_button(continue_button, 26)
	continue_button.pressed.connect(continue_pressed.emit)
	column.add_child(continue_button)


func _centered(label: Label) -> Label:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
