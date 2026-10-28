class_name SlotList
extends VBoxContainer
## The 3 save slots as buttons: "Slot 2 · 1h 23m · saved 2026-10-28 14:03",
## "Slot 3 · empty" or "Slot 1 (current)". The owner decides what a pick does. Used
## by Save as copy, Start new game and Load game.

signal picked(slot: int, used: bool)

const BUTTON_SIZE := Vector2(420, 56)

var buttons: Array[Button] = []


func _init() -> void:
	add_theme_constant_override(&"separation", 14)
	for n in range(1, SaveGame.SLOTS + 1):
		var button := Button.new()
		button.custom_minimum_size = BUTTON_SIZE
		UiStyle.style_button(button)
		button.pressed.connect(func() -> void: picked.emit(n, SaveGame.instance().slot_exists(n)))
		add_child(button)
		buttons.append(button)
	refresh()


## Re-reads the slots. `current` is shown as such and disabled; with
## `empty_enabled` off (Load game), empty slots are disabled too.
func refresh(current := 0, empty_enabled := true) -> void:
	var save := SaveGame.instance()
	for i in buttons.size():
		var n := i + 1
		var button := buttons[i]
		var used := save.slot_exists(n)
		if n == current:
			button.text = "Slot %d (current)" % n
		elif used:
			button.text = "Slot %d · %s · saved %s" % [n, SaveGame.play_time_text(save.play_time_of(n)), save.saved_at(n).substr(0, 16)]
		else:
			button.text = "Slot %d · empty" % n
		button.disabled = n == current or (not used and not empty_enabled)
