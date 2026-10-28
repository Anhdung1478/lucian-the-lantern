class_name ActPage
extends VBoxContainer
## One act: its name and story, a card for every stage and a Start button
## for the picked stage. Acts without waves and a map yet keep Start disabled.

signal start_pressed(stage: int)

var act := 1
## The stage Start plays (0: none open).
var selected := 0
## Acts with waves and a map; the others wait for a later phase.
var playable := false
var cards: Array[StageCard] = []
var start_button: Button
var _row: HBoxContainer


func _init(act_number: int) -> void:
	act = act_number
	add_theme_constant_override(&"separation", 18)
	var info: Dictionary = Journey.ACTS[act - 1]
	add_child(UiStyle.label("ACT %d · %s" % [act, String(info["name"]).to_upper()], 34, UiStyle.TITLE_COLOR))
	add_child(UiStyle.label(info["story"], 20, UiStyle.DIM_COLOR))
	_row = HBoxContainer.new()
	_row.add_theme_constant_override(&"separation", 16)
	add_child(_row)
	for stage in range(1, Journey.stage_count(act) + 1):
		var card := StageCard.new(stage, Journey.waves(act, stage), Journey.boss_kind(act, stage))
		_row.add_child(card)
		card.chosen.connect(select.bind(stage))
		cards.append(card)
	playable = WavePlan.has_stage(Journey.stage_id(act, 1))
	start_button = Button.new()
	start_button.text = "Start"
	start_button.custom_minimum_size = Vector2(320, 64)
	start_button.disabled = true
	if not playable:
		start_button.set_meta(&"hover_text", "Act %d comes in a later phase" % act)
	UiStyle.style_button(start_button, 28, true)
	start_button.add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR)
	start_button.pressed.connect(func() -> void: start_pressed.emit(selected))
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add_child(start_button)


func select(stage: int) -> void:
	if stage < 1 or stage > cards.size() or cards[stage - 1].locked:
		return
	selected = stage
	for i in cards.size():
		cards[i].set_selected(i + 1 == stage)
	start_button.text = "Start" if cards.size() == 1 else "Start stage %d" % stage


## The first open stage not cleared yet, else the last open one; 0 if none.
func default_stage(cleared: Array[String]) -> int:
	var last_open := 0
	for stage in range(1, cards.size() + 1):
		if not Journey.is_stage_open(act, stage, cleared):
			continue
		if not Journey.stage_id(act, stage) in cleared:
			return stage
		last_open = stage
	return last_open


## Locks, opens and marks the cards for these cleared stages.
func refresh(cleared: Array[String]) -> void:
	for i in cards.size():
		cards[i].set_state(not Journey.is_stage_open(act, i + 1, cleared), Journey.stage_id(act, i + 1) in cleared)
	if selected == 0 or cards[selected - 1].locked:
		selected = 0
		select(default_stage(cleared))
	start_button.disabled = not playable or selected == 0
