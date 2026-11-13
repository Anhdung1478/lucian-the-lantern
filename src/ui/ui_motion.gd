class_name UiMotion
extends RefCounted
## The UI's motion kit: how panels, pop-ups, pages, numbers, highlights and
## tooltips arrive, leave and change. Every helper ends in the same state as
## the plain code it replaces (`visible = true`, `.text = `, a restyle); only
## the look trails. While off() is true (headless tests and bots, Low quality,
## or `UiMotion.instant` set by the screenshot tool) every helper sets that end
## state at once, synchronously, so code and tests that read values right
## after the call keep working. Nothing blinks; nothing waits for a tween.
##
## HOW TO USE (the area screens' manual)
##
## Arriving and leaving (a panel, a tip plate, a card, a banner):
##   UiMotion.enter(node)          visible = true, fades in and rises RISE into
##                                 its place over BASE. Optional (rise, time, delay).
##   UiMotion.pop_in(node)         fades in and grows from POP_SCALE about its
##                                 centre (cards, pop-ups). Optional (time, delay, rise).
##   UiMotion.exit(node)           fades out and sinks DROP over EXIT, then
##                                 visible = false, alpha and place put back.
##                                 exit(node, then) calls `then` after (queue_free).
##   UiMotion.pop_out(node, then)  the reverse of pop_in.
##   UiMotion.stagger(nodes)       enter() each in reading order, STAGGER apart.
##                                 Optional (step, start, rise, time). Story
##                                 moments: stagger(rows, 0.05, 0.35, RISE, STORY).
##   UiMotion.swap_body(old, new)  a tab page or section: old fades out over
##                                 SWAP_OUT, new enters over SWAP_IN with a
##                                 SWAP_RISE rise. Keep the frame, header and
##                                 tabs still; swap only the body.
## Each returns its Tween (await tween.finished if you must), or null when off
## (the end state is already set). Calling one while another motion runs on
## the same node retargets from where the node is now (it never restarts from
## the start, so quick toggles never jump); on a node already shown and at
## rest, enter() and pop_in() play the entrance again. A leaving node ignores
## the mouse.
## The node's resting alpha is 1 and its resting scale is 1.
##
## CONTAINERS. A Container (VBox, HBox, Grid, Margin, Center, PanelContainer...)
## puts its children's position and scale back whenever it sorts. So for a
## child of a Container the helpers animate the alpha only (they check this
## themselves). To get the rise or the scale too, animate a node whose parent
## is NOT a Container: an overlay's full-rect CenterContainer (the child of its
## MenuBackdrop), a `_face` child, a HUD plate anchored in a plain Control, or
## wrap the thing in a plain `Control` holder. swap_body() in a Container shows
## the new page only once the old one is hidden (no two pages stacked); in a
## plain Control the two cross over at once.
##
## Overlays (menus, pop-ups, result and pick screens):
##   layer.visible = true; UiMotion.open_overlay(backdrop, center)
##   UiMotion.close_overlay(backdrop, center, func() -> void: layer.visible = false)
## `backdrop` is the MenuBackdrop, `center` its full-rect CenterContainer (pass
## that, not the card inside it, to get the scale). Open: the dim and blur fade
## in over BACKDROP_IN, the card pops in CARD_DELAY later. Close: the reverse
## over EXIT, then `done` (or backdrop.visible = false); the backdrop's strength
## and the card's look are put back after, so a plain `visible = true` later
## shows it whole. Flip your logical state (is_open(), input, signals) AT ONCE,
## before or after the call: do not read `visible` for it while it closes. The
## closing overlay ignores the mouse at once. Reopening while it closes
## retargets and `done` is never called.
##
## Numbers: CountLabel (src/ui/count_label.gd), a Label that counts:
##   var gold := CountLabel.new(); gold.format = "%d"   (or gold.formatter =
##   func(v: int) -> String: return Lang.t("%d / %d") % [v, total])
##   gold.reserve("99999"); gold.flash = true; gold.set_value(n)
##   set_value(n, true) for a jump; final_text() for tests; `value` is the target.
##
## Eased looks:
##   Buttons styled with UiStyle.style_button ease their hover fill by
##   themselves. UiStyle.set_selected(button, on) eases a tab's selected fill
##   and font colour instead of restyling it (set_selected(button, on, false)
##   for a tab under a SlideHighlight: the font eases, the fill stays clear).
##   Drawn cells: UiMotion.lit(cell, hovered) tweens the cell's `lit_t` (0 to 1
##   over FAST; a `var lit_t := 0.0` on the cell or a meta) and calls
##   queue_redraw() each step; in _draw use
##   draw_style_box(UiStyle.cell_style_t(rim, UiMotion.lit_t(self)), rect).
##   lit(node, on, step) calls step.call(t) each step instead, for a node that
##   restyles a stylebox or moves a lift from the one value.
##
## Tabs: SlideHighlight (src/ui/slide_highlight.gd) paints the chosen tab's
##   fill behind a row or column of tab buttons and slides it to the new one:
##   var hl := SlideHighlight.under(tab_row); hl.follow(button)   (on select)
##   with each tab's own rest look clear: SlideHighlight.clear_rest(button).
##
## Price buttons: button.add_child(UiStyle.price_row(Lang.t("Purchase"), 25, icon))
##   (leave button.text empty): one centred group text, amount, icon; its labels
##   follow the button's font colour (hover, disabled). The amount is a
##   CountLabel: UiStyle.price_amount(row).set_value(n).
##
## Tooltips (HoverTip): a source may add tooltip_anchor() -> Rect2 (in screen
##   coordinates, e.g. `bar.get_global_rect()`): Place.ABOVE and Place.BESIDE
##   then measure from it, e.g. to hang every HUD card 8 px above the bar. A
##   `hover_text` note may set the meta `hover_place` (HoverTip.Place.BESIDE)
##   to open beside its source instead of at the cursor. Cards fade in and out
##   by themselves.
##
## Tokens: the times and distances below, and the type and space sizes in
##   UiStyle (FONT_TAG, FONT_NOTE, FONT_BODY, FONT_ROW, FONT_LEAD; GAP_S, GAP,
##   GAP_L, INSET, STACK; SURFACE_RAISED; NOTE_LINE_SPACING). Use them; do not
##   type new numbers.
##
## Under the hood every tween runs while the SceneTree is paused (most
## overlays show over a paused stage) and ignores Engine.time_scale; all ease
## TRANS_CUBIC + EASE_OUT. Tests that check the motion itself set
## `UiMotion.renders = true` (and put it back to its old value after).

## Hover, press, tooltip, a cell lighting up.
const FAST := 0.12
## A panel coming in, a tab body.
const BASE := 0.18
## Anything leaving.
const EXIT := 0.12
## Story moments: a result, a banner, the Lantern's gift.
const STORY := 0.45
## Between neighbours of a staggered entrance.
const STAGGER := 0.06
## How far an entering node rises into place (8 px on screen).
const RISE := 10.0
## How far a leaving node sinks (6 px on screen).
const DROP := 7.0
## The scale a popped card grows from and shrinks back to.
const POP_SCALE := 0.97
## swap_body(): the old page's fade, the new page's entrance and its rise.
const SWAP_OUT := 0.08
const SWAP_IN := 0.2
const SWAP_RISE := 10.0
## open_overlay(): the backdrop's fade, and how long after it the card starts.
const BACKDROP_IN := 0.15
const CARD_DELAY := 0.04

## Something is drawn (false headless). Tests turn it on to check the motion.
static var renders := DisplayServer.get_name() != "headless"
## Every helper sets its end state at once (the screenshot tool sets it, so no
## frame is caught mid-fade).
static var instant := false

## The node's running motion (enter, exit, pop, swap, overlay).
const TWEEN_META := &"_ui_motion_tween"
## The node's resting position.y, kept while a motion runs.
const HOME_META := &"_ui_motion_home"
## A leaving Control's own mouse settings, put back once it is at rest.
const MUTE_META := &"_ui_motion_mute"
## lit(): the running tween and the value, when the node has no `lit_t`.
const LIT_TWEEN_META := &"_ui_lit_tween"
const LIT_META := &"lit_t"


## True when motion is skipped: every helper sets its end state at once.
static func off() -> bool:
	return instant or not renders or GameSettings.instance().low_effects()


## A tween on `node` with the kit's settings: runs while paused, ignores the
## time scale, cubic ease-out. `node` must be inside the tree.
static func tween(node: Node) -> Tween:
	return node.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Shows `node`: fades in and rises `rise` into place over `time`, after
## `delay`. A child of a Container only fades (see CONTAINERS above).
static func enter(node: CanvasItem, rise := RISE, time := BASE, delay := 0.0) -> Tween:
	return _arrive(node, rise, 1.0, time, delay, false)


## Shows `node` like enter(), growing from POP_SCALE about its centre (no rise
## unless given).
static func pop_in(node: CanvasItem, time := BASE, delay := 0.0, rise := 0.0) -> Tween:
	return _arrive(node, rise, POP_SCALE, time, delay, false)


## Hides `node`: fades out and sinks `drop` over `time`, then visible = false,
## its alpha and place put back, then `then` (e.g. queue_free).
static func exit(node: CanvasItem, then := Callable(), drop := DROP, time := EXIT) -> Tween:
	return _leave(node, then, drop, 1.0, time, true)


## Hides `node` the way pop_in() showed it: fades out and shrinks to POP_SCALE.
static func pop_out(node: CanvasItem, then := Callable(), time := EXIT) -> Tween:
	return _leave(node, then, 0.0, POP_SCALE, time, true)


## enter() each node in reading order, `step` apart, the first after `start`.
## They are all made visible at once (alpha 0 until their turn), so the layout
## is settled from the first frame.
static func stagger(nodes: Array, step := STAGGER, start := 0.0, rise := RISE, time := BASE) -> void:
	var i := 0
	for node: CanvasItem in nodes:
		if node:
			enter(node, rise, time, start + i * step)
			i += 1


## Swaps a tab page or section body: `old` fades out over SWAP_OUT and hides,
## `new` enters over SWAP_IN with a SWAP_RISE rise. In a Container `new` shows
## once `old` is hidden; elsewhere the two cross over. Either may be null.
static func swap_body(old: CanvasItem, new: CanvasItem) -> void:
	if old == new:
		if new and not new.visible:
			enter(new, SWAP_RISE, SWAP_IN)
		return
	var wait := 0.0
	if old and old.visible:
		_leave(old, Callable(), 0.0, 1.0, SWAP_OUT, true)
		if _in_container(new) and not off():
			wait = SWAP_OUT
	if new:
		_arrive(new, SWAP_RISE, 1.0, SWAP_IN, wait, wait > 0.0)


## Opens an overlay: the backdrop's dim and blur fade in over BACKDROP_IN, then
## `card` (the backdrop's full-rect CenterContainer) pops in.
static func open_overlay(backdrop: MenuBackdrop, card: CanvasItem) -> void:
	var reopening := is_moving(backdrop) or is_moving(card)
	_kill(backdrop)
	_unmute(backdrop)
	backdrop.visible = true
	if not _can_move(backdrop):
		backdrop.strength = 1.0
		_kill(card)
		_rest(card)
		card.visible = true
		return
	if not reopening:
		backdrop.strength = 0.0
	var fade := _start(backdrop)
	fade.tween_property(backdrop, ^"strength", 1.0, BACKDROP_IN)
	_arrive(card, 0.0, POP_SCALE, BASE, CARD_DELAY if not reopening else 0.0, false, reopening)


## Closes an overlay: the reverse of open_overlay() over EXIT, then `done` (or
## backdrop.visible = false); the backdrop and card are put back to their full
## look after. The overlay ignores the mouse from the call on.
static func close_overlay(backdrop: MenuBackdrop, card: CanvasItem, done := Callable()) -> void:
	_kill(backdrop)
	_kill(card)
	_mute(backdrop)
	var wrap_up := func() -> void:
		if done.is_valid():
			done.call()
		else:
			backdrop.visible = false
		backdrop.strength = 1.0
		_rest(card)
		card.visible = true
		_unmute(backdrop)
	if not _can_move(backdrop) or not backdrop.is_visible_in_tree():
		wrap_up.call()
		return
	var fade := _start(backdrop)
	card.set_meta(TWEEN_META, fade)
	fade.tween_property(backdrop, ^"strength", 0.0, EXIT)
	fade.tween_property(card, ^"modulate:a", 0.0, EXIT)
	if not _in_container(card):
		_pivot(card)
		fade.tween_property(card, ^"scale", Vector2.ONE * POP_SCALE, EXIT)
	fade.chain().tween_callback(func() -> void:
		if is_instance_valid(card):
			card.remove_meta(TWEEN_META)
		wrap_up.call())


## Eases `node`'s lit_t to 1 (`on`) or 0 over FAST, calling queue_redraw()
## each step (or `step.call(t)` when given).
static func lit(node: CanvasItem, on: bool, step := Callable()) -> void:
	var target := 1.0 if on else 0.0
	var running: Tween = node.get_meta(LIT_TWEEN_META) if node.has_meta(LIT_TWEEN_META) else null
	if running and running.is_valid():
		running.kill()
	node.remove_meta(LIT_TWEEN_META)
	var from := lit_t(node)
	if not _can_move(node) or is_equal_approx(from, target):
		_set_lit(node, target, step)
		return
	var fill := tween(node)
	node.set_meta(LIT_TWEEN_META, fill)
	fill.tween_method(func(t: float) -> void: _set_lit(node, t, step), from, target, FAST)


## `node`'s lit value, 0 (at rest) to 1 (lit).
static func lit_t(node: Object) -> float:
	if LIT_META in node:
		return node.get(LIT_META)
	return node.get_meta(LIT_META, 0.0)


## True while one of the helpers moves `node` (enter, exit, pop, swap, overlay).
static func is_moving(node: Object) -> bool:
	if node == null or not node.has_meta(TWEEN_META):
		return false
	var running: Tween = node.get_meta(TWEEN_META)
	return running != null and running.is_valid() and running.is_running()


## Stops `node`'s motion and puts it in the state the motion was heading for.
static func finish(node: CanvasItem) -> void:
	if not is_moving(node):
		return
	var running: Tween = node.get_meta(TWEEN_META)
	running.custom_step(3600.0)


static func _set_lit(node: CanvasItem, t: float, step: Callable) -> void:
	if LIT_META in node:
		node.set(LIT_META, t)
	else:
		node.set_meta(LIT_META, t)
	if step.is_valid():
		step.call(t)
	else:
		node.queue_redraw()


## `keep`: carry on from the node's current look even if no motion of its own
## runs (an overlay reopened while its close tween, kept on the backdrop, ran).
static func _arrive(node: CanvasItem, rise: float, from_scale: float, time: float, delay: float, show_late: bool,
		keep := false) -> Tween:
	if node == null:
		return null
	var moving := is_moving(node) or keep
	var home := _home(node, moving)
	var place := not _in_container(node)
	_kill(node)
	_unmute(node)
	if not _can_move(node):
		_rest(node, home)
		node.visible = true
		return null
	if not moving:
		node.modulate.a = 0.0
		if place:
			node.position.y = home + rise
			node.scale = Vector2.ONE * from_scale
	if place and from_scale != 1.0:
		_pivot(node)
	node.set_meta(HOME_META, home)
	var motion := _start(node)
	if show_late and not node.visible:
		motion.tween_callback(func() -> void: node.visible = true).set_delay(delay)
	else:
		node.visible = true
	motion.tween_property(node, ^"modulate:a", 1.0, time).set_delay(delay)
	if place:
		motion.tween_property(node, ^"position:y", home, time).set_delay(delay)
		motion.tween_property(node, ^"scale", Vector2.ONE, time).set_delay(delay)
	motion.chain().tween_callback(func() -> void: node.remove_meta(HOME_META))
	return motion


static func _leave(node: CanvasItem, then: Callable, drop: float, to_scale: float, time: float, hide: bool) -> Tween:
	if node == null:
		return null
	var moving := is_moving(node)
	var home := _home(node, moving)
	var place := not _in_container(node)
	_kill(node)
	var done := func() -> void:
		if hide:
			node.visible = false
		_rest(node, home)
		node.remove_meta(HOME_META)
		_unmute(node)
		if then.is_valid():
			then.call()
	if not _can_move(node) or not node.is_visible_in_tree():
		done.call()
		return null
	_mute(node)
	node.set_meta(HOME_META, home)
	var motion := _start(node)
	motion.tween_property(node, ^"modulate:a", 0.0, time)
	if place:
		motion.tween_property(node, ^"position:y", home + drop, time)
		if to_scale != 1.0:
			_pivot(node)
			motion.tween_property(node, ^"scale", Vector2.ONE * to_scale, time)
	motion.chain().tween_callback(done)
	return motion


## A new parallel tween for `node`, kept in its meta (the old one killed).
static func _start(node: CanvasItem) -> Tween:
	_kill(node)
	var motion := tween(node).set_parallel(true)
	node.set_meta(TWEEN_META, motion)
	return motion


static func _kill(node: Object) -> void:
	if node and node.has_meta(TWEEN_META):
		var running: Tween = node.get_meta(TWEEN_META)
		if running and running.is_valid():
			running.kill()
		node.remove_meta(TWEEN_META)


static func _can_move(node: Node) -> bool:
	return not off() and node.is_inside_tree()


static func _in_container(node: Node) -> bool:
	return node != null and node.get_parent() is Container


## The node's resting position.y: kept while it moves, else read now.
static func _home(node: CanvasItem, moving: bool) -> float:
	if moving and node.has_meta(HOME_META):
		return node.get_meta(HOME_META)
	return node.get(&"position").y if &"position" in node else 0.0


## Alpha 1, scale 1 and (outside a Container) back at `home`.
static func _rest(node: CanvasItem, home := NAN) -> void:
	node.modulate.a = 1.0
	if _in_container(node):
		return
	if &"scale" in node:
		node.set(&"scale", Vector2.ONE)
	if not is_nan(home):
		node.set_indexed(^"position:y", home)


static func _pivot(node: CanvasItem) -> void:
	if node is Control:
		node.pivot_offset = node.size * 0.5


## A leaving Control and everything in it ignore the mouse.
static func _mute(node: CanvasItem) -> void:
	var control := node as Control
	if control == null or control.has_meta(MUTE_META):
		return
	control.set_meta(MUTE_META, [control.mouse_filter, control.mouse_behavior_recursive])
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED


static func _unmute(node: CanvasItem) -> void:
	var control := node as Control
	if control == null or not control.has_meta(MUTE_META):
		return
	var saved: Array = control.get_meta(MUTE_META)
	control.remove_meta(MUTE_META)
	control.mouse_filter = saved[0]
	control.mouse_behavior_recursive = saved[1]
