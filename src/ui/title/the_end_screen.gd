class_name TheEndScreen
extends Control
## The story's end: shown by Game on the first clear of the last stage, after
## the stage-end screen's button. The title's scene (Lucian and the freed
## Senna; Thresh is gone) under a dawn tint, and on a card "THE END", "Senna is free.", the
## story time (the slot's play time) and the credits. Continue goes where that button said.
## ESC does nothing here.

signal continue_pressed

## The warm light laid over the title's night scene: dawn, not the night's teal.
const DAWN_TINT := Color(1.0, 0.72, 0.38, 0.22)
## The card is centred in the screen's part right of this share of its width.
const CARD_FROM := 0.36
const FREE_COLOR := Color("8fe3b0")
const TITLE_FONT := 72
const SUBTITLE_FONT := 32
const BUTTON_SIZE := Vector2(420, 64)
const CREDITS: Array[String] = [
	"Lucian: The Lantern",
	"Made with Godot 4",
	"A fan game. League of Legends characters belong to Riot Games.",
]

var backdrop := TitleBackdrop.new()
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
	backdrop.thresh.visible = false
	add_child(backdrop)
	var dawn := ColorRect.new()
	dawn.color = DAWN_TINT
	dawn.set_anchors_preset(Control.PRESET_FULL_RECT)
	dawn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dawn)
	# The card stands in the right part of the scene, where Thresh stood, so
	# Lucian and Senna on the left are not covered.
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.anchor_left = CARD_FROM
	add_child(center)
	var card := MenuCard.new("THE END", "Senna is free.")
	card.title_label.add_theme_font_size_override(&"font_size", TITLE_FONT)
	card.subtitle_label.add_theme_font_size_override(&"font_size", SUBTITLE_FONT)
	card.subtitle_label.add_theme_color_override(&"font_color", FREE_COLOR)
	center.add_child(card)
	var column := card.content
	column.alignment = BoxContainer.ALIGNMENT_CENTER
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
