class_name TreePage
extends Control
## One branch of the Evolution Tree on a page of its own: a tree at night
## (TreeArt) whose lanterns are the branch's nodes (TreeNodeView). The page
## is the Journey map's size and frame; the branch switch (BranchTabs) sits
## over its top band, so nothing of the tree comes within CLEAR_TOP of it.
## - Each node stands where LAYOUT puts it (its data `grid` is the fallback).
## - LIMBS groups the nodes: a group shares one bough into the crown, and a
##   labelled group (OFFENSE, REWARDS...) carries its caption over its top
##   node. Nodes on the page's middle line stand on the trunk.
## - A link is drawn only where a node needs another one outright (its
##   `requires` with no count): dim until the needed node has a level, then
##   gold. Counted rules are said at the node (TreeNodeView's rule tag), and
##   a level sum is the node's ring (R: one track, one arc, ticks at 5, 9, 13).
## It redraws on refresh() only; nothing on it moves at rest.

const SIZE := JourneyMap.SIZE
## Where the trunk meets the ground.
const GROUND_Y := 850.0
## The trunk: its width at the roots (before TreeArt's flare) and at its top.
const TRUNK_ROOT := 76.0
const TRUNK_TIP := 26.0
const CURVE_STEPS := 28
## The branch switch's band over the page's top, and the line nothing of the
## tree crosses (48 under the switch: 40 px on screen).
const SWITCH_RECT := Rect2(24, 20, 1368, 56)
const CLEAR_TOP := 124.0
const KEEP_CLEAR: Array[Rect2] = [Rect2(0, 0, 1416, CLEAR_TOP)]
## A name wraps past this width (two lines at most).
const NAME_MAX := 180.0
## Links: their width, and how far they stop short of the nodes they join.
const LINK_WIDTH := 3.0
const LINK_GAP := 10.0
const LINK_DIM := Color("3b4b54")
const LINK_LIT := Color(1.0, 0.81, 0.35, 0.85)
## The ring of a node with a level sum: radius, thickness, the open gap at the
## bottom (radians), its ticks and the font of its numbers.
const RING_RADIUS := 80.0
const RING_WIDTH := 6.0
const RING_GAP := PI * 0.8
const RING_TICK := 10.0
const RING_FONT := 16
const RING_TRACK := Color("1d2a30")
## A group's caption over its top node: its font and its lift over the tile.
const GROUP_FONT := 16
const GROUP_LIFT := 28.0

const LIGHT := MainBackdrop.GROVE_LIGHT

## The branches' names (the switch shows them).
const NAMES := {
	&"skills": "Skills", &"stats": "Stats", &"backpack": "Backpack",
	&"economy": "Economy", &"summoners": "Summoners",
}
## Kept for the info column's summary until it is rebuilt.
const BLURBS := {
	&"skills": "Q, W and E open the passive; their ranks open R.",
	&"stats": "Offense, defense and sustain for Lucian himself.",
	&"backpack": "Equip slots for gear, boots to wear, and cells to carry more.",
	&"economy": "More gold, XP and essence, and a better merchant.",
	&"summoners": "Summoner spells, their upgrades, a second slot.",
}
const ICONS := {
	&"skills": preload("res://assets/art/ui/icon_r.svg"),
	&"stats": preload("res://assets/art/tree/stat_ad.svg"),
	&"backpack": preload("res://assets/art/tree/backpack_slots.svg"),
	&"economy": preload("res://assets/art/tree/stage_gold.svg"),
	&"summoners": preload("res://assets/art/summoners/flash.svg"),
}
## Each node's centre on its page. Groups stand as clusters on their own
## bough; a column on the middle line stands on the trunk.
const LAYOUT := {
	&"skills": {
		&"skill_q": Vector2(300, 660), &"skill_w": Vector2(708, 720), &"skill_e": Vector2(1116, 660),
		&"passive": Vector2(708, 510), &"skill_r": Vector2(708, 300),
	},
	&"stats": {
		&"stat_hp": Vector2(708, 700), &"stat_armor": Vector2(708, 510), &"stat_mr": Vector2(708, 320),
		&"stat_ad": Vector2(330, 640), &"stat_ap": Vector2(220, 440), &"stat_attack_speed": Vector2(440, 440),
		&"stat_mana": Vector2(1086, 640), &"stat_hp_regen": Vector2(976, 440), &"stat_mana_regen": Vector2(1196, 440),
	},
	&"backpack": {
		&"equip_slots": Vector2(440, 560), &"boots": Vector2(708, 420), &"backpack_slots": Vector2(976, 560),
	},
	&"economy": {
		&"stage_gold": Vector2(330, 640), &"bonus_xp": Vector2(220, 440), &"essence_drop": Vector2(440, 440),
		&"merchant_stock": Vector2(1010, 600), &"refresh_cost": Vector2(1170, 420),
	},
	&"summoners": {
		&"flash": Vector2(178, 700), &"ghost": Vector2(378, 700), &"barrier": Vector2(578, 700),
		&"heal": Vector2(838, 700), &"clarity": Vector2(1038, 700), &"smite": Vector2(1238, 700),
		&"flash_upgrade": Vector2(178, 490), &"ghost_upgrade": Vector2(378, 490), &"barrier_upgrade": Vector2(578, 490),
		&"heal_upgrade": Vector2(838, 490), &"clarity_upgrade": Vector2(1038, 490), &"smite_upgrade": Vector2(1238, 490),
		&"summoner_slot_2": Vector2(708, 290),
	},
}
## Per branch, its groups of nodes, each sharing a bough, with an optional
## caption. A node in no group stands alone (on the trunk, or on a bough of
## its own).
const LIMBS := {
	&"stats": [
		{"label": "OFFENSE", "ids": [&"stat_ad", &"stat_ap", &"stat_attack_speed"]},
		{"label": "DEFENSE", "ids": [&"stat_hp", &"stat_armor", &"stat_mr"]},
		{"label": "SUSTAIN", "ids": [&"stat_mana", &"stat_hp_regen", &"stat_mana_regen"]},
	],
	&"economy": [
		{"label": "REWARDS", "ids": [&"stage_gold", &"bonus_xp", &"essence_drop"]},
		{"label": "MERCHANT", "ids": [&"merchant_stock", &"refresh_cost"]},
	],
	&"summoners": [
		{"ids": [&"flash", &"flash_upgrade"]},
		{"ids": [&"ghost", &"ghost_upgrade"]},
		{"ids": [&"barrier", &"barrier_upgrade"]},
		{"ids": [&"heal", &"heal_upgrade"]},
		{"ids": [&"clarity", &"clarity_upgrade"]},
		{"ids": [&"smite", &"smite_upgrade"]},
	],
}

var branch: StringName
var tree: EvolutionTree
## Node id -> its TreeNodeView on this page.
var views := {}
## Node id -> the node's centre on the page.
var centers := {}
## Node id -> true when it stands on the trunk.
var on_trunk := {}
## The groups that grow off the trunk: {"ids", "label" (maybe ""), "anchor"
## (where its bough ends in the crown)}.
var groups: Array[Dictionary] = []
## Each group's bough, from inside the trunk out to its anchor.
var boughs: Array[PackedVector2Array] = []
## The links: {"from" (the node needed), "to" (the node that needs it),
## "points" (the line, from `from` to `to`)}.
var links: Array[Dictionary] = []
## Where the trunk ends at the top.
var trunk_top := 0.0
## The page's scenery and its tree.
var art: TreeArt


func _init(branch_id: StringName, evolution_tree: EvolutionTree, essences: Essences) -> void:
	branch = branch_id
	tree = evolution_tree
	size = SIZE
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout()
	art = TreeArt.new(self)
	for data in tree.branch_nodes(branch):
		var view := TreeNodeView.new(data, tree, essences)
		view.position = centers[data.id] - Vector2.ONE * TreeNodeView.SIZE * 0.5
		add_child(view)
		views[data.id] = view



## Levels bought in `branch` and its levels in all, as (bought, all).
static func levels(evolution_tree: EvolutionTree, branch_id: StringName) -> Vector2i:
	var count := Vector2i.ZERO
	for data in evolution_tree.branch_nodes(branch_id):
		count += Vector2i(evolution_tree.level(data.id), data.max_level)
	return count


## Redraws the views, the links and the ring from the tree (a link's ends
## follow the names, which change as nodes open).
func refresh() -> void:
	for view: TreeNodeView in views.values():
		view.refresh()
	queue_redraw()


## A random number generator seeded for this page and `salt`: the same
## numbers every time.
func rng(salt: int) -> RandomNumberGenerator:
	var made := RandomNumberGenerator.new()
	made.seed = salt * 31 + EvolutionTree.BRANCHES.find(branch)
	return made


## Node `id`'s footprint (tile, level mark and name) on the page.
func footprint(id: StringName) -> Rect2:
	var view: TreeNodeView = views[id]
	var own := view.footprint()
	return Rect2(view.position + own.position, own.size)


## The trunk's width at height `y` (TreeArt adds the root flare).
func trunk_width(y: float) -> float:
	return lerpf(TRUNK_ROOT, TRUNK_TIP, clampf(inverse_lerp(GROUND_Y, trunk_top, y), 0.0, 1.0))


static func bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in CURVE_STEPS + 1:
		var t := float(i) / CURVE_STEPS
		var u := 1.0 - t
		points.append(p0 * u * u * u + p1 * 3.0 * u * u * t + p2 * 3.0 * u * t * t + p3 * t * t * t)
	return points


# --- Layout ---------------------------------------------------------------------------


func _layout() -> void:
	var nodes := tree.branch_nodes(branch)
	var placed: Dictionary = LAYOUT.get(branch, {})
	var middle := SIZE.x * 0.5
	for data in nodes:
		centers[data.id] = placed.get(data.id, Vector2(middle + (data.grid.x - 2.5) * 180.0, 700.0 - data.grid.y * 170.0))
		on_trunk[data.id] = absf(centers[data.id].x - middle) < 1.0
	# The groups off the trunk: the listed ones, then each lone node.
	var grouped := {}
	for limb: Dictionary in LIMBS.get(branch, []):
		var ids: Array[StringName] = []
		for id: StringName in limb["ids"]:
			grouped[id] = true
			if not on_trunk.get(id, false):
				ids.append(id)
		if not ids.is_empty():
			groups.append({"ids": ids, "label": limb.get("label", "")})
	for data in nodes:
		if not grouped.has(data.id) and not on_trunk[data.id]:
			groups.append({"ids": [data.id], "label": ""})
	trunk_top = GROUND_Y - 60.0
	for id: StringName in on_trunk:
		if on_trunk[id]:
			trunk_top = minf(trunk_top, centers[id].y)
	for group in groups:
		var anchor := Vector2.ZERO
		var lowest := Vector2(0, -INF)
		var column := true
		for id: StringName in group["ids"]:
			anchor += centers[id]
			column = column and absf(centers[id].x - centers[group["ids"][0]].x) < 1.0
			if centers[id].y > lowest.y:
				lowest = centers[id]
		anchor /= group["ids"].size()
		# A lone node's (or a column's) bough ends behind its lowest tile; a
		# cluster's in the crown among its nodes.
		if group["ids"].size() == 1 or column:
			anchor = lowest + Vector2(0, 30)
		else:
			anchor.y += 40.0
		group["anchor"] = anchor
		group["attach"] = minf(anchor.y + 130.0, GROUND_Y - 70.0)
	var no_trunk_node := trunk_top >= GROUND_Y - 60.0
	if no_trunk_node:
		for group in groups:
			trunk_top = minf(trunk_top, group["attach"] - 70.0)
	for group in groups:
		var anchor: Vector2 = group["anchor"]
		var y: float = group["attach"]
		var side := signf(anchor.x - middle)
		var from := Vector2(middle + side * trunk_width(y) * 0.25, y)
		var d := anchor - from
		boughs.append(bezier(from, from + Vector2(d.x * 0.25, d.y * 0.7 - absf(d.x) * 0.2), anchor - Vector2(d.x * 0.4, absf(d.x) * 0.1), anchor))


## The links, from the needed node's tile to the footprint of the node that
## needs it (its name's size as it reads now).
func _lay_links() -> void:
	links.clear()
	for id: StringName in centers:
		var data := tree.node(id)
		if data.requires_count != 0:
			continue
		for required in data.requires:
			if not centers.has(required):
				continue
			var from := _tile(required)
			var to := footprint(id)
			var points := PackedVector2Array()
			if to.end.y < from.position.y:
				# The usual case: the node that needs it stands above.
				var x: float = centers[required].x
				points.append(Vector2(x, from.position.y - LINK_GAP))
				points.append(Vector2(x, to.end.y + LINK_GAP))
			else:
				var a: Vector2 = centers[required]
				var b: Vector2 = centers[id]
				var along := (b - a).normalized()
				points.append(a + along * (TreeNodeView.SIZE * 0.5 + LINK_GAP))
				points.append(b - along * (TreeNodeView.SIZE * 0.5 + LINK_GAP))
			links.append({"from": required, "to": id, "points": points})


func _tile(id: StringName) -> Rect2:
	return Rect2(centers[id] - Vector2.ONE * TreeNodeView.SIZE * 0.5, Vector2.ONE * TreeNodeView.SIZE)


# --- Drawing -----------------------------------------------------------------------


func _draw() -> void:
	_lay_links()
	art.draw_back(self)
	art.draw_tree(self)
	for link in links:
		var lit := tree.level(link["from"]) > 0
		draw_polyline(link["points"], LINK_LIT if lit else LINK_DIM, LINK_WIDTH, true)
	for id: StringName in centers:
		if not tree.node(id).level_sum_ids.is_empty():
			_draw_ring(id)
	_draw_group_captions()
	# The Journey map's frame, open on the right where the info column stands.
	JourneyMap.draw_frame(self, SIZE)


## Node `id`'s level sum as a ring: one dark track and one gold arc up to the
## sum, a tick and its number where each level opens.
func _draw_ring(id: StringName) -> void:
	var data := tree.node(id)
	var center: Vector2 = centers[id]
	var marks := data.level_sums
	var top: int = marks[-1]
	var total := tree.level_sum(id)
	var start := PI * 0.5 + RING_GAP * 0.5
	var sweep := TAU - RING_GAP
	draw_arc(center, RING_RADIUS, start, start + sweep, 64, RING_TRACK, RING_WIDTH, true)
	var share := clampf(float(total) / top, 0.0, 1.0)
	if share > 0.0:
		draw_arc(center, RING_RADIUS, start, start + sweep * share, maxi(4, int(64 * share)), UiStyle.GOLD_COLOR, RING_WIDTH, true)
		for end: float in [start, start + sweep * share]:
			draw_circle(center + Vector2.from_angle(end) * RING_RADIUS, RING_WIDTH * 0.5, UiStyle.GOLD_COLOR)
	var font := get_theme_default_font()
	for mark: int in marks:
		var direction := Vector2.from_angle(start + sweep * mark / top)
		var reached := total >= mark
		var inner := center + direction * (RING_RADIUS - RING_WIDTH * 0.5 - 2.0)
		draw_line(inner, inner + direction * RING_TICK, UiStyle.TITLE_COLOR if reached else UiStyle.DIM_COLOR, 2.0, true)
		var label_at := center + direction * (RING_RADIUS + 22.0)
		JourneyMap.draw_text(self, str(mark), label_at + Vector2(0, font.get_ascent(RING_FONT) * 0.4), RING_FONT,
			UiStyle.TITLE_COLOR if reached else UiStyle.DIM_COLOR, true)


## Each labelled group's caption over its top node, between two small diamonds.
func _draw_group_captions() -> void:
	var font := JourneyMap.text_font(self, 3)
	for limb: Dictionary in LIMBS.get(branch, []):
		if not limb.has("label"):
			continue
		var top := Vector2(0, INF)
		for id: StringName in limb["ids"]:
			if centers[id].y < top.y:
				top = centers[id]
		var text := Lang.t(limb["label"])
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, GROUP_FONT).x
		var baseline := Vector2(top.x - width * 0.5, top.y - TreeNodeView.SIZE * 0.5 - GROUP_LIFT)
		JourneyMap.draw_text(self, text, baseline, GROUP_FONT, JourneyPanel.CAPTION_COLOR, false, 3)
		for side: float in [-1.0, 1.0]:
			var at := Vector2(top.x + side * (width * 0.5 + 14.0), baseline.y - GROUP_FONT * 0.35)
			draw_colored_polygon(PackedVector2Array([at + Vector2(0, -4), at + Vector2(4, 0), at + Vector2(0, 4), at + Vector2(-4, 0)]), JourneyPanel.CAPTION_COLOR)
