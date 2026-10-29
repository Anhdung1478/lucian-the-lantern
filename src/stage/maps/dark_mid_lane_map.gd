class_name DarkMidLaneMap
extends MidLaneMap
## Act 4: Act 1's lane in the dark. The same layout and points, a black-purple
## palette. Dark Lucian rises from the river at `boss_point`.


func _init() -> void:
	super()
	lane_color = Color("2a2633")
	jungle_color = Color("120f1a")
	jungle_edge = Color("3b2a52")
	tree_color = Color("0c0a12")
	river_color = Color("1d1630")
	river_edge = Color("7a4fb0")
	rock_color = Color("3a3742")
