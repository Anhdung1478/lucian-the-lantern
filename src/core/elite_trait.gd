class_name EliteTrait
extends RefCounted
## The trait an elite comes with from Act 3 on (and in Endless from wave
## ENDLESS_FROM): one of four, rolled by the stage when it spawns. Swift is
## quicker, Armored takes less, Vampiric heals on its hits and Volatile
## explodes where it dies. A unit with a trait pays PAY_BONUS more gold and
## XP. This table holds every number; the stage and Endless only call it.

const SWIFT := &"swift"
const ARMORED := &"armored"
const VAMPIRIC := &"vampiric"
const VOLATILE := &"volatile"
const IDS: Array[StringName] = [SWIFT, ARMORED, VAMPIRIC, VOLATILE]

## The story acts and the Endless wave it starts at.
const FIRST_ACT := 3
const ENDLESS_FROM := 11
## Extra gold and XP (not essence) a unit with a trait pays.
const PAY_BONUS := 0.25

## Swift: extra move speed and attack speed.
const SWIFT_MOVE := 0.25
const SWIFT_ATTACK := 0.15
## Armored: flat armor and magic resist added.
const ARMORED_RESIST := 40.0
## Vampiric: the share of the damage its hits deal to Lucian that it heals.
const VAMPIRIC_DRAIN := 0.3
## Volatile: the circle left where it died, the seconds before it
## explodes, and the blast as a multiple of its basic damage (magic).
const BLAST_RADIUS := 150.0
const BLAST_TIME := 1.0
const BLAST_DAMAGE := 2.0

## id -> its name, its tip, its small icon and its ring's color.
const TRAITS := {
	SWIFT: {
		"name": "Swift",
		"tip": "Swift elites move and attack faster.",
		"icon": preload("res://assets/art/ui/trait_swift.svg"),
		"color": Color("7fd8ff"),
	},
	ARMORED: {
		"name": "Armored",
		"tip": "Armored elites take less damage: armor penetration helps.",
		"icon": preload("res://assets/art/ui/trait_armored.svg"),
		"color": Color("a9b4c4"),
	},
	VAMPIRIC: {
		"name": "Vampiric",
		"tip": "Vampiric elites heal when they hit you: Grievous Wounds cuts it.",
		"icon": preload("res://assets/art/ui/trait_vampiric.svg"),
		"color": Color("d0305a"),
	},
	VOLATILE: {
		"name": "Volatile",
		"tip": "Volatile elites explode where they die: step away.",
		"icon": preload("res://assets/art/ui/trait_volatile.svg"),
		"color": Color("ff7a2a"),
	},
}


## Whether an enemy of `data` spawning in `run`'s stage at `wave` gets a
## trait: an elite (never a summon, never one that escapes) in Acts 3 to 6,
## or in Endless from wave ENDLESS_FROM. Never in Training (act 0).
static func applies(data: EnemyData, run: StageSetup, wave: int, summoned := false) -> bool:
	if data.kind != &"elite" or summoned or data.escape_after > 0.0:
		return false
	if run.endless:
		return wave >= ENDLESS_FROM
	return run.act >= FIRST_ACT


## One of the four, from `rng`.
static func pick(rng: RandomNumberGenerator) -> StringName:
	return IDS[rng.randi_range(0, IDS.size() - 1)]


## Gives `unit` trait `id`: its numbers change now, so call it after its
## setup and any Endless scaling, before it joins the tree. &"" does nothing.
static func apply(unit: EnemyUnit, id: StringName) -> void:
	unit.elite_trait = id
	match id:
		SWIFT:
			unit.move_speed *= 1.0 + SWIFT_MOVE
			unit.attack_interval /= 1.0 + SWIFT_ATTACK
		ARMORED:
			unit.armor += ARMORED_RESIST
			unit.mr += ARMORED_RESIST
		VAMPIRIC:
			unit.drain = maxf(unit.drain, VAMPIRIC_DRAIN)


## Volatile: the warning where `unit` died. Its hit has no attacker, so the
## warning has no caster to die with: it belongs to nobody alive. The hit
## still names the elite's id, for the death recap.
static func leave_blast(unit: EnemyUnit) -> void:
	var hit := DamageInfo.create(unit.damage * BLAST_DAMAGE, DamageInfo.Type.MAGIC, &"volatile")
	hit.attacker_id = unit.data.id
	var warning := GroundWarning.circle(unit.global_position, BLAST_RADIUS, BLAST_TIME)
	warning.strike(hit, unit.target)
	warning.sound = &"shell"
	unit.warning_parent.add_child(warning)


static func icon(id: StringName) -> Texture2D:
	return TRAITS[id].icon


static func tip(id: StringName) -> String:
	return TRAITS[id].tip


static func color(id: StringName) -> Color:
	return TRAITS[id].color
