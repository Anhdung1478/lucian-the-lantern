class_name ShopPanel
extends Plate
## The merchant's shop, beside the backpack while it is open, on an ornate
## plate headed MERCHANT: the Items, Potions and Craft tabs with the stage
## gold beside them, the open tab's page ending with its hint, and the foot: the sell
## slot on the left with the message line beside it, the Undo sale button
## (every tab; it buys back the last sale) and the Refresh button (Items
## only; its slot stays on the other tabs, so Undo sale never moves) on the
## right. The Items and Potions tabs list what is for sale as rows that name
## it (ShopSlot). Refused purchases show a red message; a full backpack and
## the one-penetration rule are told in a pop-up instead
## (BackpackScreen._report). The panel keeps one size on every tab and
## whatever its message says, and is as tall as the backpack's column beside
## it (BackpackScreen._place_column), so nothing beside it moves.
##
## Motion: a tab change keeps the frame, the heading, the tabs and the foot
## still and swaps only the page (UiMotion.swap_body); the chosen tab's fill
## slides (SlideHighlight). The gold counts (CountLabel). The message fades
## in and out in its fixed slot.
##
## The Craft tab: [input] + [input] -> [result], a note line, the fee and a
## Craft button. Two fragments make their legendary, for the legendary's cost
## minus the fragments'; the boots and a fragment make the upgraded boots,
## for their upgrade_cost. Its two inputs are filled by dragging from the
## backpack: an item in an input leaves the backpack view until it comes back
## (see CraftSlot), and changing tabs gives both back. The Craft button asks
## first (BackpackScreen.craft). The tab shows where it stands (craft_state):
## the note, the result, the arrow, the fee and the button follow it. Once the
## inputs make something the note shows only the result's name; craft_note()
## still says the whole recipe.

## Where the Craft tab stands: nothing in its inputs; one item in; two that
## make nothing (or boots that are fully upgraded); a craft the wallet can't
## pay for; a craft ready to be pressed.
enum CraftState { EMPTY, ONE, NO_RECIPE, NO_GOLD, READY }

const PAD := 22.0
const GAP := UiStyle.GAP
const GAP_L := UiStyle.GAP_L
const ROW_GAP := 6
const TAB_SIZE := Vector2(86, 38)
const BUTTON_FONT := UiStyle.FONT_BODY
## Room for the hint's two lines, text or not.
const HINT_HEIGHT := 44.0
## The open tab's page: as tall as the Items tab's rows, as wide as a row.
const PAGE_HEIGHT := MerchantStock.SLOTS * ShopSlot.HEIGHT + (MerchantStock.SLOTS - 1) * ROW_GAP
## The page and its hint, on every tab.
const BODY_HEIGHT := PAGE_HEIGHT + GAP + HINT_HEIGHT
## The foot's buttons (they keep their width in every language, so the
## message beside the sell slot keeps its room).
const UNDO_SIZE := Vector2(104, 40)
const REFRESH_SIZE := Vector2(156, 40)
const MESSAGE_TIME := 1.6
const TAB_NAMES: Array[String] = ["Items", "Potions", "Craft"]
const ITEMS_TAB := 0
const POTIONS_TAB := 1
const CRAFT_TAB := 2
## One hint line per tab; the Potions tab's names the potion keys (hint()).
const HINTS: Array[String] = [
	"Right-click or drag to buy.\nDrag an item onto Sell to sell it.",
	"Right-click or drag to buy. Potions fill\nthe %s and %s cells first, then the backpack.",
	"Drag two fragments, or your boots and a\nfragment, into the slots, then pay the fee.",
]
const MESSAGES := {
	Shop.Result.NO_GOLD: "Not enough gold",
	Shop.Result.CELL_LOCKED: "That cell is locked",
	Shop.Result.SOLD_OUT: "Already sold",
	Shop.Result.NOTHING_TO_REFRESH: "Nothing left to refresh",
	Shop.Result.NO_RECIPE: "Those don't craft into anything",
	Shop.Result.WRONG_CELL: "That item can't go there",
	Shop.Result.NOTHING_TO_UNDO: "No sale to undo",
	Shop.Result.SLOT_LOCKED: "That slot is locked",
}
## The Craft button's word and the note's colour in each state.
const CRAFT_WORDS := {
	CraftState.EMPTY: "Craft",
	CraftState.ONE: "Craft",
	CraftState.NO_RECIPE: "No recipe",
	CraftState.NO_GOLD: "Not enough gold",
	CraftState.READY: "Craft",
}
const NOTE_COLORS := {
	CraftState.EMPTY: UiStyle.DIM_COLOR,
	CraftState.ONE: UiStyle.TEXT_COLOR,
	CraftState.NO_RECIPE: UiStyle.ERROR_COLOR,
	CraftState.NO_GOLD: UiStyle.TITLE_COLOR,
	CraftState.READY: UiStyle.TITLE_COLOR,
}
const CRAFT_BUTTON_SIZE := Vector2(176, 42)
## The Craft tab's bench: the box around its three slots.
const BENCH_PAD := 24.0
const BENCH_GAP := 18
const SIGN_FONT := 30
const GOLD_FONT := 22

var screen: BackpackScreen

var _tab := 0
var _tab_buttons: Array[Button] = []
var _tab_highlight: SlideHighlight
var _pages: Array[Control] = []
## Each tab's rows (the Craft tab: its page) and its hint line.
var _rows: Array[Control] = []
var _hints: Array[Label] = []
var _gold_label: CountLabel
## The open tab's hint line.
var _hint: Label
var _message: Label
var _message_fade: Tween
## The message is fading out (it empties at the end).
var _fading_out := false
var _refresh: Button
var _undo: Button
var _message_left := 0.0
## Whether the message line shows the sell slot's price.
var _selling := false
var _first_input: CraftSlot
var _second_input: CraftSlot
var _result_slot: CraftSlot
var _arrow: Label
var _fee_label: Label
var _craft_note: Label
var _craft_button: Button
## The state the Craft button is styled for; -1 before the first.
var _styled_state := -1


func _init() -> void:
	super(PAD)


## `sell_cell` is the backpack screen's sell slot: it sits in the foot.
func setup(owner_screen: BackpackScreen, potions: Array[ItemData], sell_cell: Control = null) -> void:
	screen = owner_screen
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", GAP)
	add_child(box)
	box.add_child(BagHeading.new(Lang.t("MERCHANT")))

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override(&"separation", 8)
	box.add_child(tabs)
	_tab_highlight = SlideHighlight.under(tabs)
	for i in TAB_NAMES.size():
		var button := Button.new()
		button.text = Lang.t(TAB_NAMES[i])
		button.custom_minimum_size = TAB_SIZE
		button.pressed.connect(show_tab.bind(i))
		UiStyle.style_button(button, BUTTON_FONT)
		SlideHighlight.clear_rest(button)
		tabs.add_child(button)
		_tab_buttons.append(button)
	# One track behind the three tabs: the unchosen ones keep a surface.
	_tab_highlight.track_tabs.assign(_tab_buttons)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(gap)
	tabs.add_child(_coin(24.0))
	_gold_label = CountLabel.new()
	_gold_label.add_theme_font_size_override(&"font_size", GOLD_FONT)
	_gold_label.add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR)
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_gold_label.flash = true
	# No reserved width: the coin hugs the number whatever its size.
	tabs.add_child(_gold_label)

	# The pages share one plain holder, so a new page can rise into place.
	# Each page ends with its own hint, right under what it explains; a short
	# page leaves its room above the foot.
	var pages := Control.new()
	pages.custom_minimum_size = Vector2(ShopSlot.WIDTH, BODY_HEIGHT)
	pages.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(pages)
	var items := _column(ROW_GAP)
	for slot in MerchantStock.SLOTS:
		items.add_child(ShopSlot.new(screen, slot))
	var potion_rows := _column(ROW_GAP)
	# Fewer rows than the page has room for: the block sits in the middle of
	# the room above the hint, so no band opens between rows and foot.
	potion_rows.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	for potion in potions:
		potion_rows.add_child(ShopSlot.new(screen, -1, potion))
	var craft := _build_craft_page()
	_rows = [items, potion_rows, craft]
	_pages = [_column(GAP), _column(GAP), _column(GAP)]
	for tab in _pages.size():
		var page := _pages[tab]
		if page != _rows[tab]:
			page.add_child(_rows[tab])
		var line := UiStyle.note(hint(tab))
		# Long key names are cut off instead of widening the shop.
		line.clip_text = true
		line.custom_minimum_size.y = HINT_HEIGHT
		page.add_child(line)
		_hints.append(line)
		# Sized by hand, not anchored: UiMotion moves its position as it rises,
		# which would rewrite an anchored page's offsets.
		page.size = pages.custom_minimum_size
		page.visible = false
		pages.add_child(page)
	pages.resized.connect(func() -> void:
		for page in _pages:
			page.size = pages.size)
	_hint = _hints[0]
	GameSettings.instance().changed.connect(_on_setting_changed)

	# The foot sits on the panel's bottom edge however tall the panel is.
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(spacer)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override(&"separation", GAP)
	box.add_child(foot)
	if sell_cell:
		sell_cell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		foot.add_child(sell_cell)
	# The message's slot never changes size, whatever it says.
	var slot := Control.new()
	slot.custom_minimum_size.y = ItemCell.SIZE
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.clip_contents = true
	foot.add_child(slot)
	_message = UiStyle.note("", UiStyle.ERROR_COLOR)
	_message.set_anchors_preset(Control.PRESET_FULL_RECT)
	_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.max_lines_visible = 2
	_message.clip_text = true
	slot.add_child(_message)
	_undo = Button.new()
	_undo.text = Lang.t("Undo sale")
	_undo.custom_minimum_size = UNDO_SIZE
	_undo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiStyle.style_button(_undo, BUTTON_FONT)
	_undo.pressed.connect(func() -> void: screen.undo_sale())
	foot.add_child(_undo)
	# Refresh keeps its slot on every tab; only the button hides.
	var refresh_slot := Control.new()
	refresh_slot.custom_minimum_size = REFRESH_SIZE
	refresh_slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	refresh_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.add_child(refresh_slot)
	_refresh = Button.new()
	_refresh.set_anchors_preset(Control.PRESET_FULL_RECT)
	UiStyle.style_button(_refresh, BUTTON_FONT)
	_refresh.add_child(UiStyle.price_row(Lang.t("Refresh"), 0, ShopSlot.COIN, BUTTON_FONT))
	_refresh.pressed.connect(func() -> void: screen.refresh_shop())
	refresh_slot.add_child(_refresh)
	screen.inventory.changed.connect(_recheck_inputs)
	show_tab(0)


## Shows what the open shop charges for a refresh.
func show_refresh_cost(cost: int) -> void:
	UiStyle.price_amount(_refresh.get_node(^"PriceRow")).set_value(cost, true)


## The Refresh button's words and price, as shown ("Refresh 100").
func refresh_text() -> String:
	var row := _refresh.get_node(^"PriceRow")
	return "%s %s" % [UiStyle.price_text(row).text, UiStyle.price_amount(row).final_text()]


## Switching tabs gives the Craft inputs' items back to the backpack. Only
## the page swaps; the chosen tab's fill slides to its button.
func show_tab(tab: int) -> void:
	if tab != _tab:
		clear_craft()
	var old: Control = null
	for page in _pages:
		if page.visible and page != _pages[tab]:
			old = page
	_tab = tab
	UiMotion.swap_body(old, _pages[tab])
	for i in _tab_buttons.size():
		UiStyle.set_selected(_tab_buttons[i], i == tab, false)
	_tab_highlight.follow(_tab_buttons[tab])
	_refresh.visible = tab == ITEMS_TAB
	_hint = _hints[tab]
	_hint.text = hint(tab)


## Tab `tab`'s hint line. The Potions tab's names the potion keys as bound
## now, in full ("Mouse 4"): it is a sentence, not a slot label.
static func hint(tab: int) -> String:
	if tab != POTIONS_TAB:
		return Lang.t(HINTS[tab])
	var settings := GameSettings.instance()
	return Lang.t(HINTS[tab]) % [
		settings.key_label(Inventory.key_action(Inventory.HP_POTION_CELL)),
		settings.key_label(Inventory.key_action(Inventory.MP_POTION_CELL)),
	]


## A rebound potion key shows in the hint at once.
func _on_setting_changed(key: StringName) -> void:
	if key == &"bindings":
		_hints[POTIONS_TAB].text = hint(POTIONS_TAB)


func undo_button() -> Button:
	return _undo


func current_tab() -> int:
	return _tab


## The open tab's page.
func page(tab: int) -> Control:
	return _pages[tab]


## Shows why a purchase, refresh or craft failed, and flashes the slot's
## price red.
func refuse(result: Shop.Result, slot: ShopSlot = null) -> void:
	show_message(Lang.t(MESSAGES.get(result, "")))
	if slot:
		slot.flash_left = MESSAGE_TIME


## A red message for MESSAGE_TIME seconds.
func show_message(text: String) -> void:
	_selling = false
	_say(text, UiStyle.ERROR_COLOR)
	_message_left = MESSAGE_TIME


## The shop slots on `tab` (none on the Craft tab).
func slots(tab: int) -> Array[ShopSlot]:
	var found: Array[ShopSlot] = []
	for child in _rows[tab].get_children():
		if child is ShopSlot:
			found.append(child)
	return found


func first_input() -> CraftSlot:
	return _first_input


func second_input() -> CraftSlot:
	return _second_input


func result_slot() -> CraftSlot:
	return _result_slot


func craft_button() -> Button:
	return _craft_button


## The Craft tab input under `point` while that tab shows, or null.
func craft_input_at(point: Vector2) -> CraftSlot:
	if not visible or _tab != CRAFT_TAB:
		return null
	for input in [_first_input, _second_input]:
		if input.get_global_rect().has_point(point):
			return input
	return null


## The input `target` names: BackpackScreen.CRAFT_FIRST or CRAFT_SECOND.
func input_for(target: int) -> CraftSlot:
	return _first_input if target == BackpackScreen.CRAFT_FIRST else _second_input


## Whether a Craft input holds the item in inventory cell `cell`.
func holds(cell: int) -> bool:
	return cell >= 0 and (_first_input.index == cell or _second_input.index == cell)


## Puts the item in inventory cell `cell` into the input `target` names; what
## that input held comes back to the backpack. One cell is never in both
## inputs: the other input lets go of it. False, with a message, when the item
## is never crafted (a legendary or a potion).
func load_input(target: int, cell: int) -> bool:
	var input := input_for(target)
	if not input.load_cell(cell):
		show_message(Lang.t("Only fragments and boots are crafted"))
		return false
	var other := _second_input if input == _first_input else _first_input
	if other.index == cell:
		other.clear()
	return true


## Moves what input `from` holds into the input `target` names; what that
## one held goes the other way.
func move_input(from: CraftSlot, target: int) -> void:
	var to := input_for(target)
	if to == from:
		return
	var held := to.index
	to.index = from.index
	from.index = held


## Empties both inputs: their items come back to the backpack (the tab
## changed or the shop closed), or a craft used them up.
func clear_craft() -> void:
	_first_input.clear()
	_second_input.clear()


## What the two inputs would make, or null.
func craft_preview() -> ItemData:
	if screen.shop == null:
		return null
	return screen.shop.craft_result(_first_input.index, _second_input.index)


## The fee for what is in the two inputs (0 when they make nothing).
func craft_fee() -> int:
	if screen.shop == null:
		return 0
	return screen.shop.craft_fee(_first_input.index, _second_input.index)


## Where the Craft tab stands for what is in its inputs (see CraftState).
func craft_state() -> CraftState:
	var first := _first_input.item()
	var second := _second_input.item()
	if screen.shop == null or (first == null and second == null):
		return CraftState.EMPTY
	if first == null or second == null:
		var one := first if first else second
		return CraftState.NO_RECIPE if one.is_boots() and one.boots_tier >= 3 else CraftState.ONE
	if craft_preview() == null:
		return CraftState.NO_RECIPE
	return CraftState.READY if screen.shop.wallet.can_afford(craft_fee()) else CraftState.NO_GOLD


func _process(delta: float) -> void:
	if screen == null or screen.shop == null:
		return
	if _gold_label.value != screen.shop.wallet.gold:
		_gold_label.set_value(screen.shop.wallet.gold)
	# Greyed once every open slot is sold: a refresh would change nothing.
	_refresh.disabled = not screen.shop.can_refresh()
	_show_undo()
	if _tab == CRAFT_TAB:
		_show_craft()
	# The dragged icon covers the sell slot, so its price shows here too.
	if screen.sell_refused():
		_selling = false
		_say(Lang.t("Boots can't be sold"), UiStyle.ERROR_COLOR)
		_message_left = MESSAGE_TIME
		return
	var preview := screen.sell_preview()
	if preview > 0:
		_selling = true
		_say(Lang.t("Sells for %d gold") % preview, UiStyle.GOLD_COLOR)
		_message_left = 0.0
		return
	if _message_left > 0.0:
		_message_left -= delta
		if _message_left <= 0.0:
			_say("", UiStyle.ERROR_COLOR)
	elif _selling:
		_selling = false
		_say("", UiStyle.ERROR_COLOR)


## The message line says `text` in `color`: a line that was empty fades in
## over FAST, an emptied line fades out over EXIT and then empties; one text
## replacing another swaps in place. The new text is there at once (what a
## test reads); an emptied one stays until its fade ends.
func _say(text: String, color: Color) -> void:
	if text == "":
		if _message.text != "" and not _fading_out:
			_fade_message(0.0, func() -> void: _message.text = "")
		return
	_message.add_theme_color_override(&"font_color", color)
	if text == _message.text and not _fading_out:
		return
	var appearing := _message.text == "" or _fading_out
	_message.text = text
	if appearing:
		_fade_message(1.0)


## Fades the message to alpha `to`, then calls `then` (at once while
## UiMotion.off()). It always ends at alpha 1, empty or not.
func _fade_message(to: float, then := Callable()) -> void:
	if _message_fade and _message_fade.is_valid():
		_message_fade.kill()
	_message_fade = null
	_fading_out = to == 0.0
	var done := func() -> void:
		_fading_out = false
		if then.is_valid():
			then.call()
		_message.modulate.a = 1.0
	if UiMotion.off() or not _message.is_inside_tree():
		done.call()
		return
	if to > 0.0 and _message.modulate.a >= 1.0:
		_message.modulate.a = 0.0
	_message_fade = UiMotion.tween(_message)
	_message_fade.tween_property(_message, ^"modulate:a", to, UiMotion.FAST if to > 0.0 else UiMotion.EXIT)
	_message_fade.tween_callback(done)


## Undo sale is greyed with nothing sold; its hover text names the item and
## what buying it back costs.
func _show_undo() -> void:
	var sale := screen.shop.last_sale()
	_undo.disabled = sale.is_empty()
	if sale.is_empty():
		_undo.remove_meta(&"hover_text")
	else:
		_undo.set_meta(&"hover_text", Lang.t("Buy back %s for %d gold") % [Lang.t(sale.item.display_name), sale.price])


## The Craft tab's note, arrow, fee and Craft button for what is in the
## inputs. The button is off until the inputs make something, says why, and
## is lit gold once the craft can be paid for; the fee is red when it can't.
func _show_craft() -> void:
	var state := craft_state()
	var result := craft_preview()
	_fee_label.text = str(craft_fee()) if result else "–"
	_fee_label.add_theme_color_override(&"font_color", UiStyle.ERROR_COLOR if state == CraftState.NO_GOLD else UiStyle.GOLD_COLOR)
	# With a result, its name alone: the parts are named on their cells' cards.
	_craft_note.text = Lang.t(result.display_name) if result else craft_note()
	_craft_note.add_theme_color_override(&"font_color", NOTE_COLORS[state])
	_craft_note.add_theme_font_size_override(&"font_size", UiStyle.FONT_BODY if result else UiStyle.FONT_NOTE)
	_arrow.add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR if state == CraftState.READY else UiStyle.DIM_COLOR)
	_craft_button.disabled = result == null
	_craft_button.text = Lang.t(CRAFT_WORDS[state])
	if state == _styled_state:
		return
	_styled_state = state
	UiStyle.style_button(_craft_button, BUTTON_FONT, state == CraftState.READY)
	if state == CraftState.NO_GOLD:
		_craft_button.add_theme_color_override(&"font_color", UiStyle.ERROR_COLOR)
		_craft_button.add_theme_color_override(&"font_hover_color", UiStyle.ERROR_COLOR)


## The Craft button's question: "Craft Muramana from Tear of the Goddess and
## Tear of the Goddess for 1600 gold?" Only asked when the inputs make
## something.
func craft_question() -> String:
	return Lang.t("Craft %s from %s and %s for %d gold?") % [Lang.t(craft_preview().display_name),
		Lang.t(_first_input.item().display_name), Lang.t(_second_input.item().display_name), craft_fee()]


## The Craft tab's note line for what is in the inputs.
func craft_note() -> String:
	var first := _first_input.item()
	var second := _second_input.item()
	if first == null and second == null:
		return Lang.t("Drag in two fragments, or your boots and a fragment.")
	if first == null or second == null:
		var one := first if first else second
		if one.is_boots() and one.boots_tier >= 3:
			return Lang.t("%s are fully upgraded.") % Lang.t(one.display_name)
		return Lang.t("Now drag in a fragment.")
	var result := craft_preview()
	if result:
		return "%s + %s → %s" % [Lang.t(first.display_name), Lang.t(second.display_name), Lang.t(result.display_name)]
	if first.is_boots() or second.is_boots():
		var boots := first if first.is_boots() else second
		if boots.boots_tier >= 3:
			return Lang.t("%s are fully upgraded.") % Lang.t(boots.display_name)
		var other := second if boots == first else first
		return Lang.t("%s doesn't upgrade %s.") % [Lang.t(other.display_name), Lang.t(boots.display_name)]
	return Lang.t("No legendary is made from %s and %s.") % [Lang.t(first.display_name), Lang.t(second.display_name)]


func _column(gap: int) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", gap)
	return column


## The bench, the note and the fee row as one block (the page's hint goes
## under it, at the page's foot).
func _build_craft_page() -> VBoxContainer:
	var page := _column(GAP_L)
	# The block (bench, note, fee row) is centred in the room above the hint.
	page.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	var bench := PanelContainer.new()
	var inset := StyleBoxFlat.new()
	inset.bg_color = ShopSlot.ROW_FILL
	inset.border_color = ShopSlot.ROW_RIM
	inset.set_border_width_all(1)
	inset.set_corner_radius_all(ShopSlot.RADIUS)
	inset.set_content_margin_all(BENCH_PAD)
	bench.add_theme_stylebox_override(&"panel", inset)
	page.add_child(bench)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", BENCH_GAP)
	bench.add_child(row)
	_first_input = CraftSlot.new(screen, CraftSlot.Kind.INPUT, BackpackScreen.CRAFT_FIRST)
	_second_input = CraftSlot.new(screen, CraftSlot.Kind.INPUT, BackpackScreen.CRAFT_SECOND)
	_result_slot = CraftSlot.new(screen, CraftSlot.Kind.RESULT)
	_arrow = _sign("→")
	row.add_child(_first_input)
	row.add_child(_sign("+"))
	row.add_child(_second_input)
	row.add_child(_arrow)
	row.add_child(_result_slot)

	_craft_note = UiStyle.note("", UiStyle.TEXT_COLOR)
	_craft_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_craft_note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Long item names wrap instead of widening the shop.
	_craft_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_craft_note.custom_minimum_size = Vector2(0, HINT_HEIGHT)
	page.add_child(_craft_note)

	var fee_row := HBoxContainer.new()
	fee_row.add_theme_constant_override(&"separation", UiStyle.GAP_S)
	page.add_child(fee_row)
	var fee_word := UiStyle.label(Lang.t("Fee"), UiStyle.FONT_BODY, UiStyle.DIM_COLOR)
	fee_word.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fee_row.add_child(fee_word)
	fee_row.add_child(_coin(20.0))
	_fee_label = UiStyle.label("–", UiStyle.FONT_ROW, UiStyle.GOLD_COLOR)
	_fee_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fee_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fee_row.add_child(_fee_label)
	_craft_button = Button.new()
	_craft_button.text = Lang.t(CRAFT_WORDS[CraftState.EMPTY])
	_craft_button.custom_minimum_size = CRAFT_BUTTON_SIZE
	UiStyle.style_button(_craft_button, BUTTON_FONT)
	_craft_button.pressed.connect(func() -> void: screen.craft())
	fee_row.add_child(_craft_button)
	return page


## The gold coin, `side` wide.
func _coin(side: float) -> TextureRect:
	var coin := TextureRect.new()
	coin.texture = ShopSlot.COIN
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.custom_minimum_size = Vector2(side, side)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return coin


func _sign(text: String) -> Label:
	var sign := UiStyle.label(text, SIGN_FONT, UiStyle.DIM_COLOR)
	sign.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return sign


func _recheck_inputs() -> void:
	_first_input.recheck()
	_second_input.recheck()
