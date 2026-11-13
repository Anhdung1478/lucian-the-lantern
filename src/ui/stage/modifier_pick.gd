class_name ModifierPick
extends CanvasLayer
## Endless mode, after each boss wave (design: Modifiers): CHOOSE A MODIFIER
## over three cards (ModifierCard) on the blurred, paused game: two modifiers
## and Nothing (EndlessModifiers.offer). A card shows its icon, its downside
## and its reward. A click picks; the director then closes it. ESC does
## nothing: the stage's screens are locked meanwhile. The Lantern's gift
## (GiftDirector) is the same panel with its own title, over three gifts
## (LanternGifts.offer): a card shows the gift's icon, name and effect.
## It opens as an overlay (the backdrop fades in, the title rises, the cards
## rise one after another). On a click the chosen card holds its lifted, gold
## state while the other two fade, then everything fades and goes: the
## director frees the pick at once, so the picked card's look is handed to a
## layer of its own that finishes the exit (leave()).

## A card was clicked: its EndlessModifiers id.
signal picked(id: int)

## Over the HUD and the backpack, under the menus and the result.
const LAYER := 36
const TITLE := "CHOOSE A MODIFIER"
const GIFT_TITLE := "THE LANTERN'S GIFT"
const TITLE_FONT := 34
const TITLE_SPACING := 8
const TITLE_RULE := 150.0
## Between the title and the cards: room for their medallions and their lift.
const TITLE_GAP := 56
const CARD_GAP := 30
## The arrival: the cards start this long after the backdrop, this far apart.
const CARDS_AT := 0.14
const CARD_STEP := 0.07
## The exit: the others fade, the chosen one holds, then all of it fades.
const OTHERS_FADE := 0.15
const HOLD := 0.25
const LEAVE_FADE := 0.15
## The downside's color, and the reward's (the HUD's modifier row uses them too).
const DOWNSIDE_COLOR := UiStyle.BAD_COLOR
const REWARD_COLOR := UiStyle.GOOD_COLOR

## The cards' ids, in order: Nothing last (Endless's modifiers), or the
## LanternGifts ids when `gifts`.
var ids: Array[int] = []
## The cards are the Lantern's gifts, not Endless's modifiers.
var gifts := false
## The cards' buttons, in the same order.
var cards: Array[Button] = []

var _backdrop: MenuBackdrop
var _center: CenterContainer
var _left := false


func _init(offered: Array[int] = [], lantern_gifts := false) -> void:
	ids = offered
	gifts = lantern_gifts


func _ready() -> void:
	layer = LAYER
	process_mode = PROCESS_MODE_ALWAYS
	_build()


func _build() -> void:
	var backdrop := MenuBackdrop.new()
	_backdrop = backdrop
	add_child(backdrop)
	var center := CenterContainer.new()
	_center = center
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", TITLE_GAP)
	center.add_child(column)
	var title := UiStyle.label(Lang.t(GIFT_TITLE if gifts else TITLE), TITLE_FONT, UiStyle.TITLE_COLOR)
	Ornament.space_out(title, TITLE_SPACING)
	Ornament.reserve_rise(title)
	var title_row := Ornament.between_rules(title, TITLE_RULE)
	column.add_child(title_row)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", CARD_GAP)
	column.add_child(row)
	for id in ids:
		var card := ModifierCard.new(id, gifts)
		card.pressed.connect(_on_card_pressed.bind(card))
		row.add_child(card)
		cards.append(card)
	# The arrival: the backdrop, then the title and the cards one by one.
	if UiMotion.off():
		backdrop.strength = 1.0
	else:
		backdrop.strength = 0.0
		UiMotion.tween(backdrop).tween_property(backdrop, ^"strength", 1.0, UiMotion.BACKDROP_IN)
	Ornament.pop_in(center, UiMotion.BASE, UiMotion.CARD_DELAY)
	UiMotion.enter(title_row, 0.0, UiMotion.BASE, CARDS_AT * 0.5)
	Ornament.rise_in(title, UiMotion.BASE, CARDS_AT * 0.5)
	for i in cards.size():
		(cards[i] as ModifierCard).arrive(CARDS_AT + i * CARD_STEP)


## A click: the pick leaves (if motion is on), then `picked` fires at once.
func _on_card_pressed(card: ModifierCard) -> void:
	leave(card)
	picked.emit(card.id)


## The exit, kept apart from this node: the director frees the pick the moment
## it hears `picked`, so the backdrop moves to a layer of its own, which fades
## the other cards, holds the chosen one, fades it all and frees itself. Nothing
## to do while UiMotion.off() (the pick goes at once) or after the first call.
func leave(chosen: ModifierCard) -> void:
	if _left or UiMotion.off() or not is_inside_tree():
		return
	_left = true
	chosen.set_lit(true)
	_center.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	var ghost := CanvasLayer.new()
	ghost.layer = LAYER
	ghost.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(ghost)
	_backdrop.reparent(ghost, false)
	var exit := UiMotion.tween(ghost).set_parallel(true)
	for card in cards:
		if card != chosen:
			exit.tween_property(card, ^"modulate:a", 0.0, OTHERS_FADE)
	exit.tween_property(_backdrop, ^"strength", 0.0, LEAVE_FADE).set_delay(HOLD)
	exit.tween_property(_center, ^"modulate:a", 0.0, LEAVE_FADE).set_delay(HOLD)
	exit.chain().tween_callback(ghost.queue_free)
