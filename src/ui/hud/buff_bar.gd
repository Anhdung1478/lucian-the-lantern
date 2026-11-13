class_name BuffBar
extends HBoxContainer
## The row of buff icons just above the HUD panel, over the portrait and the
## skills. Shows Lucian.buffs() every frame, reusing its icons in order: the
## i-th icon shows the i-th buff; an icon past the end fades out before its
## place closes, and a new one fades and grows in.

const GAP := 4


func _init() -> void:
	add_theme_constant_override(&"separation", GAP)
	mouse_filter = MOUSE_FILTER_IGNORE


func show_buffs(buffs: Array[Dictionary]) -> void:
	while get_child_count() < buffs.size():
		var fresh := BuffIcon.new()
		# Hidden until arrive() brings it in.
		fresh.visible = false
		add_child(fresh)
	for i in get_child_count():
		var icon := get_child(i) as BuffIcon
		if i < buffs.size():
			icon.arrive()
			icon.buff = buffs[i]
		else:
			# It keeps its last buff while it fades out.
			icon.leave()
