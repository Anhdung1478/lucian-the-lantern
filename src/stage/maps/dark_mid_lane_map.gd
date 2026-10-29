class_name DarkMidLaneMap
extends MidLaneMap
## Act 4: Act 1's lane in the dark. The same layout and points, a black-purple
## palette. Dark Lucian rises from the river at `boss_point`. The lane, the
## river and the jungle's edge are a step lighter than the jungle, so the
## shadow minions and Dark Lucian stand out on them.


func _init() -> void:
	super()
	lane_color = Color("37313f")
	jungle_color = Color("120f1a")
	jungle_edge = Color("5e4285")
	tree_color = Color("0c0a12")
	river_color = Color("2a1f45")
	river_edge = Color("9467d0")
	rock_color = Color("4a4554")
