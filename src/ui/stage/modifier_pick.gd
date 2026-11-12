class_name ModifierPick
extends CanvasLayer
## Endless mode, after each boss wave (design: Modifiers): CHOOSE A MODIFIER
## over three cards (ModifierCard) on the blurred, paused game: two modifiers
## and Nothing (EndlessModifiers.offer). A card shows its icon, its downside
## and its reward. A click picks; the director then closes it. ESC does
## nothing: the stage's screens are locked meanwhile. The Lantern's gift
## (GiftDirector) is the same panel with its own title, over three gifts
## (LanternGifts.offer): a card shows the gift's icon, name and effect.

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
const TITLE_GAP := 76
const CARD_GAP := 30
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


func _init(offered: Array[int] = [], lantern_gifts := false) -> void:
	ids = offered
	gifts = lantern_gifts


func _ready() -> void:
	layer = LAYER
	process_mode = PROCESS_MODE_ALWAYS
	_build()


func _build() -> void:
	var backdrop := MenuBackdrop.new()
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", TITLE_GAP)
	center.add_child(column)
	var title := UiStyle.label(GIFT_TITLE if gifts else TITLE, TITLE_FONT, UiStyle.TITLE_COLOR)
	Ornament.space_out(title, TITLE_SPACING)
	column.add_child(Ornament.between_rules(title, TITLE_RULE))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", CARD_GAP)
	column.add_child(row)
	for id in ids:
		var card := ModifierCard.new(id, gifts)
		card.pressed.connect(picked.emit.bind(id))
		row.add_child(card)
		cards.append(card)
