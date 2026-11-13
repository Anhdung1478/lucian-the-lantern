class_name SlideHighlight
extends Node
## The chosen tab's fill, painted behind a row or column of tab buttons, that
## slides to the next chosen one instead of jumping (section bar, the tree's
## branch tabs, the merchant's tabs, the settings' side list, the language
## picker). It paints on its bar (under the bar's children, over the bar's own
## panel) and lives in it as an internal plain Node, so Containers never lay
## it out and get_children() never lists it.
##   var hl := SlideHighlight.under(tab_row)
##   hl.follow(_buttons[index])            # on every select; snaps the first time
##   SlideHighlight.clear_rest(button)      # each tab: its rest look turns clear
## A row of tabs that has no surface of its own (the merchant's tabs, the
## language picker) can have a shared track behind it, hugging the tabs, inside
## which the fill slides: SlideHighlight.under(row, null, [button, button, ...]).
##   UiStyle.set_selected(button, on, false) # each tab: only the font eases
## It slides over UiMotion.BASE (cubic out), retargeting from where it is when
## the choice changes mid-slide; it snaps on the first follow(), whenever the
## bar or the chosen button is resized or moved by its layout, and while
## UiMotion.off().

## The fill painted under the chosen tab (default: a styled button's selected look).
var style: StyleBox:
	set(box):
		style = box
		_redraw()
## The shared track behind the tabs (a well with a faint rim), painted under the fill.
const TRACK_RADIUS := 6
const TRACK_RIM_ALPHA := 0.3
## How far the track reaches past the tabs on every side.
const TRACK_PAD := 3.0

## The chosen button, or null.
var target: Control
## The painted rect, in the bar's coordinates (moves while it slides).
var rect := Rect2()

## The tabs the track hugs (empty: no track).
var track_tabs: Array[Control] = []

var _bar: Control
var _slide: Tween
var _placed := false


## A highlight painting under `bar`'s children; `box` is its fill. With
## `track_for` (the tab buttons), a track hugs them behind the fill.
static func under(bar: Control, box: StyleBox = null, track_for: Array[Control] = []) -> SlideHighlight:
	var highlight := SlideHighlight.new()
	highlight.style = box if box else UiStyle.button_style(&"normal", true)
	highlight.track_tabs = track_for
	# Internal: the bar's get_children() and MenuKeys never see it.
	bar.add_child(highlight, false, Node.INTERNAL_MODE_BACK)
	return highlight


## A tab's rest look made clear (no fill, no rim) so the highlight shows
## through it; its hover, pressed and disabled looks stay.
static func clear_rest(button: Button) -> void:
	var box := button.get_theme_stylebox(&"normal") as StyleBoxFlat
	if box:
		box.bg_color = Color(box.bg_color, 0.0)
		box.border_color = Color(box.border_color, 0.0)


func _enter_tree() -> void:
	_bar = get_parent() as Control
	if _bar == null:
		return
	_bar.draw.connect(_paint)
	_bar.resized.connect(_snap)
	if _bar is Container:
		_bar.sort_children.connect(_redraw)


func _exit_tree() -> void:
	if _bar and _bar.draw.is_connected(_paint):
		_bar.draw.disconnect(_paint)
		_bar.resized.disconnect(_snap)
		if _bar is Container and _bar.sort_children.is_connected(_redraw):
			_bar.sort_children.disconnect(_redraw)
	_bar = null


## Moves the highlight to `button` (slides, or snaps the first time).
func follow(button: Control, instant := false) -> void:
	if target != button:
		if target and is_instance_valid(target) and target.item_rect_changed.is_connected(_snap):
			target.item_rect_changed.disconnect(_snap)
		target = button
		if target and not target.item_rect_changed.is_connected(_snap):
			target.item_rect_changed.connect(_snap)
	if target == null:
		_stop()
		rect = Rect2()
		_redraw()
		return
	if instant or not _placed or _bar == null or not _bar.is_visible_in_tree() or UiMotion.off():
		_snap()
		return
	_stop()
	_slide = UiMotion.tween(self)
	_slide.tween_method(_set_rect.bind(rect), 0.0, 1.0, UiMotion.BASE).set_trans(Tween.TRANS_CUBIC)
	_slide.tween_callback(_snap)


## True while it slides.
func is_sliding() -> bool:
	return _slide != null and _slide.is_valid() and _slide.is_running()


func _set_rect(t: float, from: Rect2) -> void:
	var to := _target_rect()
	rect = Rect2(from.position.lerp(to.position, t), from.size.lerp(to.size, t))
	_redraw()


## Straight onto the chosen button.
func _snap() -> void:
	_stop()
	if target == null or not is_instance_valid(target) or _bar == null:
		return
	rect = _target_rect()
	_placed = rect.size != Vector2.ZERO
	_redraw()


func _stop() -> void:
	if _slide and _slide.is_valid():
		_slide.kill()
	_slide = null


## The chosen button's rect in the bar's coordinates.
func _target_rect() -> Rect2:
	if target == null or not is_instance_valid(target) or _bar == null:
		return rect
	var to_bar := _bar.get_global_transform().affine_inverse() * target.get_global_transform()
	return to_bar * Rect2(Vector2.ZERO, target.size)


## The track's rect in the bar's coordinates: the tabs' union and TRACK_PAD
## around it. An empty rect without a track.
func track_rect() -> Rect2:
	if track_tabs.is_empty() or _bar == null:
		return Rect2()
	var to_bar := _bar.get_global_transform().affine_inverse()
	var union := Rect2()
	var first := true
	for tab in track_tabs:
		if not is_instance_valid(tab):
			continue
		var tab_rect := (to_bar * tab.get_global_transform()) * Rect2(Vector2.ZERO, tab.size)
		union = tab_rect if first else union.merge(tab_rect)
		first = false
	return union.grow(TRACK_PAD) if not first else Rect2()


func _paint() -> void:
	var track := track_rect()
	if track.size.x > 0.0 and track.size.y > 0.0:
		var well := StyleBoxFlat.new()
		well.bg_color = UiStyle.CELL_COLOR
		well.border_color = Color(UiStyle.BORDER_COLOR, TRACK_RIM_ALPHA)
		well.set_border_width_all(1)
		well.set_corner_radius_all(TRACK_RADIUS)
		_bar.draw_style_box(well, track)
	if style and target and rect.size.x > 0.0 and rect.size.y > 0.0:
		_bar.draw_style_box(style, rect)


func _redraw() -> void:
	if _bar:
		_bar.queue_redraw()
