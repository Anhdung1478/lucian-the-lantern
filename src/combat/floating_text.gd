class_name FloatingText
extends Node2D
## A short text, with an icon in front if given, that rises and fades:
## essences gained, "Backpack full".

const RISE := 60.0
const LIFETIME := 1.2
const FONT_SIZE := 22
const ICON_SIZE := 28.0

var text := ""
var color := Color.WHITE
var icon: Texture2D


func _init(shown: String, text_color: Color, shown_icon: Texture2D = null) -> void:
	text = shown
	color = text_color
	icon = shown_icon
	z_index = 100


func _ready() -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y - RISE, LIFETIME).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME * 0.4).set_delay(LIFETIME * 0.6)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x + (ICON_SIZE + 4.0 if icon else 0.0)
	var x := -width * 0.5
	if icon:
		draw_texture_rect(icon, Rect2(x, -ICON_SIZE + 6.0, ICON_SIZE, ICON_SIZE), false)
		x += ICON_SIZE + 4.0
	draw_string_outline(font, Vector2(x, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 5, Color.BLACK)
	draw_string(font, Vector2(x, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
