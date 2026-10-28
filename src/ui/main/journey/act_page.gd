class_name ActPage
extends VBoxContainer
## One act: its name and story, a card for every stage and a Start button
## that waits for the acts to be built in a later phase.

var act := 1
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
		cards.append(card)
	start_button = Button.new()
	start_button.text = "Start"
	start_button.custom_minimum_size = Vector2(320, 64)
	start_button.disabled = true
	start_button.set_meta(&"hover_text", "Acts come in a later phase")
	UiStyle.style_button(start_button, 28)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add_child(start_button)


## Locks, opens and marks the cards for these cleared stages.
func refresh(cleared: Array[String]) -> void:
	for i in cards.size():
		cards[i].set_state(not Journey.is_stage_open(act, i + 1, cleared), Journey.stage_id(act, i + 1) in cleared)
