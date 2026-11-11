class_name ScreenFade
extends CanvasLayer
## The black cover over a change of screen. The new screen is already in
## place; the cover starts opaque and clears in FADE_IN seconds, so the
## change reads as a fade through black. It never takes input, runs while the
## tree is paused and ignores the time scale. Off on Low quality and when run
## headless (see Juice.on).

## Above the prompt (Game.PROMPT_LAYER) and every pop-up.
const LAYER := 100
const FADE_IN := 0.25

var cover := ColorRect.new()

var _tween: Tween


func _init() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	cover.color = Color.BLACK
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.modulate.a = 0.0
	add_child(cover)


## Covers the screen at once and clears it again. A change during a fade
## starts the fade over; the cover always ends clear.
func play() -> void:
	if _tween:
		_tween.kill()
	if not Juice.on():
		cover.modulate.a = 0.0
		return
	cover.modulate.a = 1.0
	_tween = create_tween().set_ignore_time_scale(true)
	_tween.tween_property(cover, "modulate:a", 0.0, FADE_IN)
