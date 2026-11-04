class_name SkinShop
extends Control
## The Skin Shop page of the main screen: one card per skin in a centered row.
## A card's Purchase opens a SkinPurchasePopup that asks first; buying does
## not equip. Each card's Preview opens a SkinPreview. One pop-up shows at a
## time. Nothing here saves.

const GAP := 24

## One card per skin, Classic first.
var cards: Array[SkinCard] = []
## The open preview, or null.
var preview: SkinPreview
## The open purchase question, or null.
var purchase: SkinPurchasePopup


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
		card.buy_pressed.connect(ask_purchase)
		card.equip_pressed.connect(_equip)
		card.preview_pressed.connect(open_preview)
		row.add_child(card)
		cards.append(card)
	visibility_changed.connect(_on_visibility_changed)
	SaveGame.instance().changed.connect(refresh)
	# Essences change on their own (rewards, debug): the Purchase buttons follow.
	SaveGame.instance().essences.changed.connect(refresh)
	refresh()


## Updates every card's button and border from the save.
func refresh() -> void:
	for card in cards:
		card.refresh(SaveGame.instance())


## Closes the open pop-up, if any (the main screen's ESC calls this).
func close_popup() -> bool:
	if preview:
		preview.close()
		return true
	if purchase:
		purchase.close()
		return true
	return false


## Opens the preview of skin `id` over the shop, closing any other pop-up.
func open_preview(id: StringName) -> void:
	close_popup()
	var opened := SkinPreview.new(Skins.find(id))
	preview = opened
	opened.closed.connect(func() -> void:
		if preview == opened:
			preview = null)
	add_child(opened)


## Asks before buying skin `id`, closing any other pop-up.
func ask_purchase(id: StringName) -> void:
	close_popup()
	var opened := SkinPurchasePopup.new(Skins.find(id), SaveGame.instance().essences)
	purchase = opened
	opened.confirmed.connect(_buy)
	opened.closed.connect(func() -> void:
		if purchase == opened:
			purchase = null)
	add_child(opened)


## A hidden shop closes its pop-up, so it never shows on another page.
func _on_visibility_changed() -> void:
	if not visible:
		close_popup()


func _buy(id: StringName) -> void:
	if SaveGame.instance().buy_skin(id):
		Sfx.play(&"coin")


func _equip(id: StringName) -> void:
	SaveGame.instance().equip_skin(id)
