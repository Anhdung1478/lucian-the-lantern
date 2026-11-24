class_name SummonerSpells
extends Node
## Summoner spells on D and F (the Journey loadout; the debug table can pick
## too). Each spell has its own cooldown, which moves with it to the
## other key and counts down with the game. Ability haste doesn't shorten it;
## summoner spell haste (Ionian Boots of Lucidity) does.

const SPELLS: Array[SummonerData] = [
	preload("res://data/summoners/flash.tres"),
	preload("res://data/summoners/ghost.tres"),
	preload("res://data/summoners/barrier.tres"),
	preload("res://data/summoners/heal.tres"),
	preload("res://data/summoners/clarity.tres"),
	preload("res://data/summoners/smite.tres"),
]
## Spells whose upgrade is a shorter cooldown.
const COOLDOWN_UPGRADES: Array[StringName] = [&"flash", &"ghost"]
const FLASH_RANGE := 400.0
## Flash steps back this far at a time until Lucian's body fits.
const FLASH_STEP := 10.0
const GHOST_SPEED := 0.4
const GHOST_TIME := 6.0
## Ghost leaves an afterimage each time Lucian has moved this far.
const GHOST_IMAGE_SPACING := 28.0
const BARRIER_BASE := 95.0
const BARRIER_PER_LEVEL := 18.0
const BARRIER_TIME := 2.5
const HEAL_BASE := 80.0
const HEAL_PER_LEVEL := 15.0
const HEAL_SPEED := 0.3
const HEAL_SPEED_TIME := 1.0
## Share of max mana.
const CLARITY_MANA := 0.5
const SMITE_RANGE := 500.0
const SMITE_DAMAGE := 450.0
## Share of max HP, healed when Smite's hit kills.
const SMITE_HEAL := 0.025

var lucian: Lucian
## Spell id on D (0) and F (1).
var slots: Array[StringName] = [&"flash", &"heal"]
## How many keys work: D always, F once the 2nd slot is bought.
var open_slots := 2
## Spell id -> Evolution Tree upgrade (see StageSetup).
var upgrades := {}

## Spell id -> Cooldown.
var _cooldowns := {}
## Where Ghost's last afterimage was left.
var _ghost_image_at := Vector2.ZERO


func setup(owner_lucian: Lucian) -> void:
	lucian = owner_lucian


static func find(id: StringName) -> SummonerData:
	for spell in SPELLS:
		if spell.id == id:
			return spell
	return null


func spell_in(slot: int) -> SummonerData:
	return find(slots[slot]) if slot < open_slots else null


## The cooldown `spell` starts with: Flash and Ghost shortened by their
## upgrade, then every spell by Lucian's summoner spell haste.
func cooldown_of(spell: SummonerData) -> float:
	var base := spell.cooldown
	if spell.id in COOLDOWN_UPGRADES:
		base *= 1.0 + upgrades.get(spell.id, 0.0)
	var haste := lucian.stats.summoner_haste if lucian and lucian.stats else 0.0
	return Cooldown.hasted(base, haste)


## "Upgraded: ..." for the spell's card, or "" when it has no upgrade.
func upgrade_text(id: StringName) -> String:
	var value: float = upgrades.get(id, 0.0)
	if value == 0.0:
		return ""
	if id in COOLDOWN_UPGRADES:
		return Lang.t("Upgraded: %d%% shorter cooldown") % roundi(-value * 100.0)
	return Lang.t("Upgraded: %d%% stronger") % roundi(value * 100.0)


## Multiplier on the effect of a spell with a strength upgrade.
func _effect(id: StringName) -> float:
	return 1.0 if id in COOLDOWN_UPGRADES else 1.0 + upgrades.get(id, 0.0)


## Puts spell `id` on `slot` (&"" for none). If it was on the other key, the two swap.
func set_spell(slot: int, id: StringName) -> void:
	var other := 1 - slot
	if id != &"" and slots[other] == id:
		slots[other] = slots[slot]
	slots[slot] = id


## The range indicator's shape for spell `id`: Flash's blink and Smite's
## reach. The others have no aim.
static func cast_range(id: StringName) -> CastRange:
	match id:
		&"flash":
			return CastRange.blink(FLASH_RANGE)
		&"smite":
			return CastRange.target(SMITE_RANGE)
	return null


func cooldown(id: StringName) -> Cooldown:
	if not _cooldowns.has(id):
		_cooldowns[id] = Cooldown.new()
	return _cooldowns[id]


func clear_cooldowns() -> void:
	for running: Cooldown in _cooldowns.values():
		running.clear()


## Casts the spell on `slot` (0 = D, 1 = F) toward `aim`. False on cooldown,
## during a cast time or a dash (Lucian.use_summoner queues it then), or for
## Smite with no enemy in reach.
func use(slot: int, aim: Vector2) -> bool:
	var spell := spell_in(slot)
	if spell == null or lucian.is_cast_locked() or lucian.is_dashing() or not cooldown(spell.id).is_ready():
		return false
	match spell.id:
		&"flash":
			_flash(aim)
		&"ghost":
			lucian.add_speed_buff(&"ghost", 0.0, GHOST_SPEED, GHOST_TIME)
			lucian.set_ghosted(GHOST_TIME)
			_ghost_image_at = lucian.global_position
			Sfx.play(&"potion")
		&"barrier":
			lucian.add_barrier((BARRIER_BASE + BARRIER_PER_LEVEL * lucian.progress.level) * _effect(spell.id), BARRIER_TIME)
			# A new shield pops a new bubble.
			for node in lucian.get_children():
				if node is BarrierBubble:
					node.queue_free()
			_show_on_lucian(BarrierBubble.new())
			Sfx.play(&"potion")
		&"heal":
			lucian.heal((HEAL_BASE + HEAL_PER_LEVEL * lucian.progress.level) * _effect(spell.id))
			lucian.add_speed_buff(&"heal", 0.0, HEAL_SPEED, HEAL_SPEED_TIME, true)
			_show_on_lucian(HealBurst.new())
			Sfx.play(&"potion")
		&"clarity":
			lucian.restore_mana(lucian.stats.max_mana * CLARITY_MANA * _effect(spell.id))
			_show_on_lucian(ClarityBurst.new())
			Sfx.play(&"potion")
		&"smite":
			if not _smite(aim, _effect(spell.id)):
				return false
	cooldown(spell.id).start(0.0 if lucian.cheat_no_cooldowns else cooldown_of(spell))
	lucian.passives.on_summoner_used()
	return true


func _physics_process(delta: float) -> void:
	for running: Cooldown in _cooldowns.values():
		running.reduce(delta)
	if lucian.is_ghosted() and lucian.global_position.distance_to(_ghost_image_at) >= GHOST_IMAGE_SPACING:
		_ghost_image_at = lucian.global_position
		if not GameSettings.instance().low_effects():
			var image := GhostImage.new()
			image.setup(lucian.visuals.body_texture(), lucian.global_position, lucian.visuals.rotation)
			lucian.spawn_under(image)


## Barrier's, Heal's and Clarity's effects follow Lucian, drawn over his
## body but under his HP bar. None on low effects.
func _show_on_lucian(effect: Node2D) -> void:
	if GameSettings.instance().low_effects():
		effect.free()
		return
	lucian.add_child(effect)
	lucian.move_child(effect, lucian.visuals.get_index() + 1)


## Blinks toward the cursor, at most FLASH_RANGE, stepping back until
## Lucian's body fits clear of walls and enemies (enemies don't count under
## Ghost). Only the landing spot is checked, so Flash can cross them.
func _flash(aim: Vector2) -> void:
	var from := lucian.global_position
	var direction := lucian.aim_direction(aim)
	var distance := minf(from.distance_to(aim), FLASH_RANGE)
	while distance > 0.0 and not lucian.fits_at(from + direction * distance):
		distance -= FLASH_STEP
	lucian.blink_to(from + direction * maxf(distance, 0.0))
	lucian.visuals.face(direction)
	var landed := lucian.global_position
	# A blink leaves no trail, only departure & arrival sparks via one BlinkSparks node.
	if not GameSettings.instance().low_effects():
		var sparks := BlinkSparks.new()
		sparks.position = from
		sparks.arrival_offset = landed - from
		lucian.spawn(sparks)
	Sfx.play(&"zap")


## True damage to the enemy under the cursor, else the one nearest it, within
## reach (Lucian.enemy_near_cursor). A kill heals SMITE_HEAL of max HP (and
## raises an elite's orange chance: KillRewards).
func _smite(aim: Vector2, effect: float) -> bool:
	var target := lucian.enemy_near_cursor(aim, SMITE_RANGE)
	if target == null:
		return false
	target.take_damage(lucian.make_damage(SMITE_DAMAGE * effect, DamageInfo.Type.TRUE, &"smite"))
	if target.dead:
		lucian.heal(lucian.stats.max_hp * SMITE_HEAL)
	var bolt := SmiteBolt.new()
	bolt.setup(target.global_position)
	lucian.spawn(bolt)
	Sfx.play(&"zap")
	return true


## Smite's heavenly sky-strike: a blazing vertical golden-white lightning bolt
## plunging from high overhead onto the target, with a scorching impact ring
## and bursting sparks. Frees itself within LIFETIME and tones down on Low.
class SmiteBolt extends Node2D:
	const LIFETIME := 0.35
	const SKY_HEIGHT := 520.0
	const GOLD := Color("ffb838")
	const CYAN_AURA := Color(0.55, 0.9, 1.0, 0.42)
	const CORE := Color("fffdf2")

	var _age := 0.0
	var _low := false
	## Pre-rolled impact sparks: [angle, speed, len, width].
	var _sparks: Array[Array] = []

	func setup(at: Vector2) -> void:
		position = at
		z_index = 5

	func _ready() -> void:
		_low = GameSettings.instance().low_effects() or not Juice.renders
		if not _low:
			for i in 12:
				var ang := TAU * i / 12.0 + randf_range(-0.2, 0.2)
				_sparks.append([ang, randf_range(120.0, 260.0), randf_range(9.0, 17.0), randf_range(2.2, 3.8)])

	func _process(delta: float) -> void:
		_age += delta
		if _age >= LIFETIME:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := clampf(_age / LIFETIME, 0.0, 1.0)
		var fade := 1.0 - t
		var bolt_fade := pow(fade, 1.25)
		var top := Vector2(0.0, -SKY_HEIGHT)
		var main := _jagged(top, Vector2.ZERO, 16, 18.0)
		# Sky-strike aura & scorching pillar.
		if not _low:
			draw_line(top, Vector2.ZERO, Color(CYAN_AURA, CYAN_AURA.a * bolt_fade), lerpf(34.0, 10.0, t))
			draw_line(top, Vector2.ZERO, Color(GOLD, 0.28 * bolt_fade), lerpf(44.0, 14.0, t))
		draw_polyline(main, Color(CYAN_AURA, 0.45 * bolt_fade), lerpf(20.0, 6.0, t), true)
		draw_polyline(main, Color(GOLD, 0.9 * bolt_fade), lerpf(11.0, 3.5, t), true)
		draw_polyline(main, Color(CORE, bolt_fade), lerpf(4.5, 1.5, t), true)
		# Side lightning forks on high effects.
		if not _low and t < 0.72:
			var fork_a := (1.0 - t / 0.72)
			for idx in [4, 9, 12]:
				var origin := main[idx]
				var side := -1.0 if idx % 2 == 0 else 1.0
				var tip := origin + Vector2(side * randf_range(42.0, 78.0), randf_range(55.0, 110.0))
				var fork := _jagged(origin, tip, 4, 10.0)
				draw_polyline(fork, Color(GOLD, 0.55 * fork_a), 4.0, true)
				draw_polyline(fork, Color(CORE, 0.85 * fork_a), 1.6, true)
		# Scorching ground impact bloom & expanding shockwave rings.
		var out := 1.0 - pow(1.0 - t, 2.6)
		SoftShape.ellipse(self, Vector2.ZERO, Vector2(56.0, 38.0) * (0.7 + 0.5 * out), Color(GOLD, 0.48 * fade), 0.25)
		SoftShape.ellipse(self, Vector2.ZERO, Vector2(28.0, 20.0) * (1.0 - 0.3 * t), Color(CORE, 0.95 * bolt_fade), 0.4)
		var ring_r := lerpf(16.0, 76.0, out)
		draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 44, Color(GOLD, 0.85 * fade * fade), lerpf(5.0, 1.0, t), true)
		if not _low:
			draw_arc(Vector2.ZERO, ring_r * 0.72, 0.0, TAU, 36, Color(CYAN_AURA, 0.7 * fade * fade), lerpf(3.0, 0.8, t), true)
			# Impact starburst flare.
			if t < 0.55:
				var st := 1.0 - t / 0.55
				ClassicStar.draw(self, Vector2.ZERO, lerpf(44.0, 20.0, 1.0 - st), PI * 0.25, Color(GOLD, 0.75 * st), 0.18)
				ClassicStar.draw(self, Vector2.ZERO, lerpf(32.0, 14.0, 1.0 - st), 0.0, Color(CORE, 0.95 * st), 0.16)
			# Bursting golden impact sparks.
			for s in _sparks:
				var dir := Vector2.from_angle(s[0])
				var side := dir.orthogonal()
				var dist: float = (s[1] as float) * out * 0.36 + 10.0
				var seg: float = (s[2] as float) * (0.35 + 0.65 * fade)
				var hw: float = (s[3] as float) * 0.5 * fade
				var p0 := dir * dist
				var pm := dir * (dist + seg * 0.35)
				var p1 := dir * (dist + seg)
				draw_colored_polygon(PackedVector2Array([p0, pm + side * hw, p1, pm - side * hw]), Color(GOLD, 0.92 * fade))
				draw_colored_polygon(PackedVector2Array([p0.lerp(pm, 0.4), pm + side * (hw * 0.45), p1.lerp(pm, 0.2), pm - side * (hw * 0.45)]), Color(CORE, 0.95 * fade))

	func _jagged(a: Vector2, b: Vector2, steps: int, jag: float) -> PackedVector2Array:
		var line := PackedVector2Array([a])
		var side := (b - a).normalized().orthogonal()
		for i in range(1, steps):
			var share := float(i) / steps
			var taper := sin(share * PI)
			line.append(a.lerp(b, share) + side * randf_range(-jag, jag) * (0.35 + 0.65 * taper))
		line.append(b)
		return line
