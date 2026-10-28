class_name SkinShop
extends Control
## The Skin Shop page of the main screen: one card per skin in a centered row.
## Buying does not equip. Nothing here saves.

const GAP := 24

## One card per skin, Classic first.
var cards: Array[SkinCard] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", GAP)
	center.add_child(row)
	for skin in Skins.ALL:
		var card := SkinCard.new(skin)
		card.buy_pressed.connect(_buy)
		card.equip_pressed.connect(_equip)
		row.add_child(card)
		cards.append(card)
	SaveGame.instance().changed.connect(refresh)
	# Essences change on their own (rewards, debug): the Purchase buttons follow.
	SaveGame.instance().essences.changed.connect(refresh)
	refresh()


## Updates every card's button and border from the save.
func refresh() -> void:
	for card in cards:
		card.refresh(SaveGame.instance())


## No pop-ups here (the main screen's ESC calls this).
func close_popup() -> bool:
	return false


func _buy(id: StringName) -> void:
	if SaveGame.instance().buy_skin(id):
		Sfx.play(&"coin")


func _equip(id: StringName) -> void:
	SaveGame.instance().equip_skin(id)
