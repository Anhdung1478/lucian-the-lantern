class_name FloatingNumber
extends Label
## A damage number (or an enemy's heal, "+N" in green) that rises, fades and
## frees itself.

const COLORS := {
	DamageInfo.Type.PHYSICAL: Color("ff9a3c"),
	DamageInfo.Type.MAGIC: Color("4fa8ff"),
	DamageInfo.Type.TRUE: Color("ffffff"),
}
## Heal's green (HealBurst).
const HEAL_COLOR := HealBurst.COLOR
const NORMAL_SIZE := 28
const CRIT_SIZE := 42
const RISE := 70.0
const DRIFT := 35.0
const LIFETIME := 0.9

var _is_crit := false


func setup(amount: float, type: DamageInfo.Type, is_crit: bool, size_scale := 1.0) -> void:
	_is_crit = is_crit
	text = str(roundi(amount)) + ("!" if is_crit else "")
	_style(COLORS[type], roundi((CRIT_SIZE if is_crit else NORMAL_SIZE) * size_scale))


## A heal: "+N" in green, at the normal size.
func setup_heal(amount: float) -> void:
	text = "+%d" % roundi(amount)
	_style(HEAL_COLOR, NORMAL_SIZE)


func _style(color: Color, font_size: int) -> void:
	var settings := LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = color
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
	if _is_crit:
		scale = Vector2(1.4, 1.4)
		tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	tween.chain().tween_callback(queue_free)
