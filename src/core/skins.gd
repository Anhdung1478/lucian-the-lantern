class_name Skins
extends RefCounted
## Every Lucian skin, in Skin Shop order with Classic first. Listed by hand
## like ItemCatalog, so exports never need to scan folders.

const CLASSIC := &"classic"
const ALL: Array[SkinData] = [
	preload("res://data/skins/classic.tres"),
	preload("res://data/skins/high_noon.tres"),
	preload("res://data/skins/project.tres"),
	preload("res://data/skins/pulsefire.tres"),
	preload("res://data/skins/vampire.tres"),
]


## The skin with `id`, or Classic when there is none.
static func find(id: StringName) -> SkinData:
	for skin in ALL:
		if skin.id == id:
			return skin
	return ALL[0]
