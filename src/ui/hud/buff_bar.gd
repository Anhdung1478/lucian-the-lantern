class_name BuffBar
extends HBoxContainer
## The row of buff icons just above the HUD panel, over the portrait and the
## skills. Shows Lucian.buffs() every frame, reusing its icons.

const GAP := 4


func _init() -> void:
	add_theme_constant_override(&"separation", GAP)
	mouse_filter = MOUSE_FILTER_IGNORE


func show_buffs(buffs: Array[Dictionary]) -> void:
	while get_child_count() < buffs.size():
		add_child(BuffIcon.new())
	for i in get_child_count():
		var icon := get_child(i) as BuffIcon
		icon.visible = i < buffs.size()
		if icon.visible:
			icon.buff = buffs[i]
