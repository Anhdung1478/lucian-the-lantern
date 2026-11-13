class_name Cutscene
extends CanvasLayer
## A scripted scene over a frozen stage: letterbox bars, the HUD hidden,
## captions (Space or a click moves on, and each goes on by itself), and a
## Skip button that jumps to the end. Subclasses write _play() with the
## helpers; `done` fires once, skipped or not.
##
## Every wait is a tween of this node, so nothing resumes on a freed scene
## and a paused game pauses the scene.
## A skip stops the scene's tweens, frees its props and ends the wait at
## once: _play() returns after any await when `skipped`.

signal done
## The step being waited on ended: its tween finished, a caption was
## clicked on, or a skip.
signal _step_ended

const LAYER := 38
const BAR_HEIGHT := 120.0
const CAPTION_TIME := 3.5
## The speaker and the caption are centred in the bottom bar as a pair (a
## caption that wraps to a second line, a longer language, starts higher), and
## never nearer than this to its top edge.
const LINES_LEAST := 4.0
## A new caption fades in over CAPTION_IN rising CAPTION_RISE; the old one
## fades out first, over CAPTION_OUT.
const CAPTION_IN := 0.15
const CAPTION_OUT := 0.08
const CAPTION_RISE := 4.0
## Props are drawn over the units.
const PROPS_Z := 20

var stage: Stage
var skipped := false
var skip_button := Button.new()

var _speaker := UiStyle.label("", 22, UiStyle.GOLD_COLOR)
var _caption := UiStyle.label("", 26, UiStyle.TEXT_COLOR)
## The speaker over the caption, on the bottom bar.
var _lines := VBoxContainer.new()
## The scene's own things in the world (a chain, a glow); they go with it.
var _props := Node2D.new()
var _tweens: Array[Tween] = []
var _step: Tween
var _in_caption := false
var _finished := false


func _ready() -> void:
	layer = LAYER
	# It pauses with the game (under "Save before leaving?"); the stage freezes
	# its nodes rather than pausing the tree.
	process_mode = PROCESS_MODE_INHERIT
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.set_anchors_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		bar.offset_top = 0.0 if top else -BAR_HEIGHT
		bar.offset_bottom = BAR_HEIGHT if top else 0.0
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bar)
	var text := _lines
	text.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	text.offset_top = -BAR_HEIGHT + LINES_LEAST
	text.grow_horizontal = Control.GROW_DIRECTION_BOTH
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speaker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_child(_speaker)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.custom_minimum_size.x = 1100.0
	text.add_child(_caption)
	add_child(text)
	skip_button.text = Lang.t("Skip")
	skip_button.custom_minimum_size = Vector2(120, 44)
	UiStyle.style_button(skip_button, 20)
	skip_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip_button.offset_left = -140.0
	skip_button.offset_right = -20.0
	skip_button.offset_top = 20.0
	skip_button.pressed.connect(skip)
	add_child(skip_button)


## Freezes the stage and plays the scene.
func start(owner_stage: Stage) -> void:
	stage = owner_stage
	stage.add_child(self)
	_props.z_index = PROPS_Z
	stage.add_child(_props)
	stage.freeze(true)
	_run()


## Ends the scene now: its tweens stop where they are and its props go.
func skip() -> void:
	skipped = true
	for tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_finish()
	_end_step()


## Shows a line until Space, a click, or CAPTION_TIME. It fades in and rises a
## little; the one before faded out first (at once with low effects).
func caption(who: String, text: String) -> void:
	if skipped:
		return
	_speaker.text = who
	_caption.text = text
	_centre_lines()
	UiMotion.enter(_lines, CAPTION_RISE, CAPTION_IN)
	var timer := animate()
	timer.tween_interval(CAPTION_TIME)
	_in_caption = true
	await step(timer)
	_in_caption = false
	if not skipped and not UiMotion.off():
		var fade := UiMotion.exit(_lines, Callable(), 0.0, CAPTION_OUT)
		if fade:
			await fade.finished
	_caption.text = ""
	_speaker.text = ""


## The speaker and the caption as one block, centred on the bottom bar.
func _centre_lines() -> void:
	var lines := maxi(_caption.get_line_count(), 1)
	var height := _speaker.get_line_height() + _lines.get_theme_constant(&"separation") + _caption.get_line_height() * lines
	_lines.offset_top = -BAR_HEIGHT + maxf((BAR_HEIGHT - height) * 0.5, LINES_LEAST)


func wait(seconds: float) -> void:
	if skipped:
		return
	var timer := animate()
	timer.tween_interval(seconds)
	await step(timer)


func pan_to(point: Vector2, seconds := 0.8) -> void:
	if skipped:
		return
	var tween := animate()
	tween.tween_property(stage.camera, "global_position", point, seconds).set_trans(Tween.TRANS_SINE)
	await step(tween)


func move(node: Node2D, to: Vector2, seconds: float) -> void:
	if skipped:
		return
	var tween := animate()
	tween.tween_property(node, "global_position", to, seconds)
	await step(tween)


## A tween of the scene; a skip stops it where it is.
func animate() -> Tween:
	var tween := create_tween()
	_tweens.append(tween)
	return tween


## Waits for `tween` (from animate()) to end; a skip ends the wait at once.
func step(tween: Tween) -> void:
	if skipped:
		tween.kill()
		return
	_step = tween
	tween.finished.connect(_end_step)
	await _step_ended


## Puts `node` in the world, over the units, until the scene ends.
func add_prop(node: Node2D) -> void:
	_props.add_child(node)


## Subclasses: the scene, with the helpers above.
func _play() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	var key := event is InputEventKey and event.is_pressed() and (event as InputEventKey).keycode == KEY_SPACE
	var click := event is InputEventMouseButton and event.is_pressed() and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	if key or click:
		get_viewport().set_input_as_handled()
		if _in_caption:
			_end_step()


func _run() -> void:
	await _play()
	_finish()
	queue_free()


func _end_step() -> void:
	if _step and _step.is_valid():
		_step.kill()
	_step = null
	_step_ended.emit()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	visible = false
	_props.queue_free()
	stage.freeze(false)
	done.emit()
