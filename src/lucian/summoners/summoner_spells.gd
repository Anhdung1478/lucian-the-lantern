class_name SummonerSpells
extends Node
## Summoner spells on D and F (picked in the debug table until the Evolution
## Tree exists). Each spell has its own cooldown, which moves with it to the
## other key and counts down with the game. Ability haste doesn't shorten it.

const SPELLS: Array[SummonerData] = [
	preload("res://data/summoners/flash.tres"),
	preload("res://data/summoners/ghost.tres"),
	preload("res://data/summoners/barrier.tres"),
	preload("res://data/summoners/heal.tres"),
	preload("res://data/summoners/clarity.tres"),
	preload("res://data/summoners/smite.tres"),
]
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
## Share of max HP.
const SMITE_HEAL := 0.1

var lucian: Lucian
## Spell id on D (0) and F (1).
var slots: Array[StringName] = [&"flash", &"heal"]

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
	return find(slots[slot])


## Puts spell `id` on `slot`. If it was on the other key, the two swap.
func set_spell(slot: int, id: StringName) -> void:
	var other := 1 - slot
	if slots[other] == id:
		slots[other] = slots[slot]
	slots[slot] = id


## The range indicator's shape for spell `id`: Flash's blink and Smite's
## reach. The others have no aim.
static func cast_range(id: StringName) -> CastRange:
	match id:
		&"flash":
			return CastRange.dash(FLASH_RANGE, 0.0)
		&"smite":
			return CastRange.circle(SMITE_RANGE)
	return null


func cooldown(id: StringName) -> Cooldown:
	if not _cooldowns.has(id):
		_cooldowns[id] = Cooldown.new()
	return _cooldowns[id]


func clear_cooldowns() -> void:
	for running: Cooldown in _cooldowns.values():
		running.clear()


## Casts the spell on `slot` (0 = D, 1 = F) toward `aim`. False on cooldown,
## while dashing, or for Smite with no enemy in reach.
func use(slot: int, aim: Vector2) -> bool:
	var spell := spell_in(slot)
	if spell == null or lucian.is_dashing() or not cooldown(spell.id).is_ready():
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
			lucian.add_barrier(BARRIER_BASE + BARRIER_PER_LEVEL * lucian.progress.level, BARRIER_TIME)
			# A new shield pops a new bubble.
			for node in lucian.get_children():
				if node is BarrierBubble:
					node.queue_free()
			_show_on_lucian(BarrierBubble.new())
			Sfx.play(&"potion")
		&"heal":
			lucian.heal(HEAL_BASE + HEAL_PER_LEVEL * lucian.progress.level)
			lucian.add_speed_buff(&"heal", 0.0, HEAL_SPEED, HEAL_SPEED_TIME, true)
			_show_on_lucian(HealBurst.new())
			Sfx.play(&"potion")
		&"clarity":
			lucian.restore_mana(lucian.stats.max_mana * CLARITY_MANA)
			_show_on_lucian(ClarityBurst.new())
			Sfx.play(&"potion")
		&"smite":
			if not _smite(aim):
				return false
	cooldown(spell.id).start(0.0 if lucian.cheat_no_cooldowns else spell.cooldown)
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
	# A blink leaves no trail, only sparks where Lucian stood.
	if not GameSettings.instance().low_effects():
		var sparks := BlinkSparks.new()
		sparks.position = from
		lucian.spawn(sparks)
	Sfx.play(&"zap")


## True damage to the enemy nearest the cursor, and a heal.
func _smite(aim: Vector2) -> bool:
	var target := lucian.enemy_near_cursor(aim, SMITE_RANGE)
	if target == null:
		return false
	target.take_damage(lucian.make_damage(SMITE_DAMAGE, DamageInfo.Type.TRUE, &"smite"))
	lucian.heal(lucian.stats.max_hp * SMITE_HEAL)
	var bolt := ChainLightning.new()
	bolt.setup(PackedVector2Array([lucian.global_position, target.global_position]), Color("ffb347"))
	lucian.spawn(bolt)
	Sfx.play(&"zap")
	return true
