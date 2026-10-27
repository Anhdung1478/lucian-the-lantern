class_name FloatingNumber
extends Label
## A damage number that rises, fades and frees itself.

const COLORS := {
	DamageInfo.Type.PHYSICAL: Color("ff9a3c"),
	DamageInfo.Type.MAGIC: Color("4fa8ff"),
	DamageInfo.Type.TRUE: Color("ffffff"),
}
const NORMAL_SIZE := 28
const CRIT_SIZE := 42
const RISE := 70.0
const DRIFT := 35.0
const LIFETIME := 0.9


func setup(amount: float, type: DamageInfo.Type, is_crit: bool) -> void:
	text = str(roundi(amount)) + ("!" if is_crit else "")
	var settings := LabelSettings.new()
	settings.font_size = CRIT_SIZE if is_crit else NORMAL_SIZE
	settings.font_color = COLORS[type]
	settings.outline_size = 6
	settings.outline_color = Color(0, 0, 0, 0.85)
	label_settings = settings
	mouse_filter = MOUSE_FILTER_IGNORE


func _ready() -> void:
	# Center the label on its spawn point.
	reset_size()
	position -= size * 0.5
	pivot_offset = size * 0.5
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y - RISE, LIFETIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position:x", position.x + randf_range(-DRIFT, DRIFT), LIFETIME).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME * 0.4).set_delay(LIFETIME * 0.6)
	if label_settings.font_size == CRIT_SIZE:
		scale = Vector2(1.4, 1.4)
		tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	tween.chain().tween_callback(queue_free)
