class_name ItemData
extends Resource
## One fragment or legendary item. Stats use ItemStats keys.

enum Kind { FRAGMENT, LEGENDARY }

@export var id: StringName
@export var display_name := ""
@export var kind := Kind.FRAGMENT
## Short label drawn when there is no icon: the fragment code (AD, AS, ...),
## or a few letters of a legendary's name.
@export var code := ""
@export var icon: Texture2D
@export var cost := 0
@export var stats: Dictionary[StringName, float] = {}
## The two fragment ids a legendary is crafted from.
@export var components: Array[StringName] = []
@export var effects: Array[ItemEffect] = []


func is_fragment() -> bool:
	return kind == Kind.FRAGMENT
