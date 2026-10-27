# Phase 1 — Base game: Lucian, movement, skills, levels, HUD

## Context

`E:\Project\lucian-the-latern` holds only design docs (`docs/lucian_game_design.md`, `docs/ui_design.md`) and a configured `project.godot`:
- Godot 4.7.2, GDScript
- 1920×1080 canvas_items/expand, window override 1600×900
- input map from the controls table, including Y = `toggle_camera`

Phase 1 builds the first playable slice: one stage screen on a test map. Lucian moves, auto-attacks a training dummy, casts all his skills, and levels up and spends skill points. The slice includes the on-stage HUD and a debug table. Later work (waves, enemies, items, merchant, Evolution Tree, saves) builds on these foundations.

### Decisions made with the user
| Topic | Decision |
|---|---|
| Art | Claude designs top-down SVG art based on LoL Lucian |
| Attacks | Full LoL-style: RMB move (hold to follow cursor); LMB on enemy = chase and auto-attack; A + LMB attack-move. Bullets are projectiles. |
| Cast mode | Quick cast only: a key press casts toward the cursor |
| Q aiming | Fires toward the cursor, no target needed |
| Dummy | Never dies (LoL practice dummy): HP floors at 1 and refills after 4 s without damage |
| Debug table (F3+Q, off by default) | Level controls, cheats, dummy settings + DPS meter + hit log |
| HUD | Lucian's panel, stats panel (C), dummy HP bar + floating damage numbers. **Not included:** buff icons, radar, summoners, items, wave/loot bar |
| Tests | GUT 9.7.1 (the Godot 4.7 line), headless unit tests for pure logic |
| Git | Initial commit of docs + project setup, then one commit per verified milestone, on `main`, never pushed |
| Plan doc | This file |

### Defaults chosen during planning
- **1 LoL unit = 1 pixel.**
- **Rank caps like LoL:** Q/W/E rank N needs level ≥ 2N−1; R ranks only at 6/11/16.
- **Every rank counts as bought** (no Evolution Tree yet). A per-skill `bought` cap still exists so lock icons work later.
- **Ctrl+Q/W/E/R** levels a skill, in addition to the HUD "+" buttons.
- **Free-cam:**
  - edge panning when the mouse is within 20 px of the screen edge, clamped to the map
  - mouse confined to the window during a stage
  - camera starts centered on Lucian
- **Crit-chance override** (0–100%) in the debug cheats. Without items Lucian has 0% crit, so crit damage numbers could not be checked otherwise.
- **Passive charge never expires.** The docs give no duration.
- **R:** the cooldown starts on cast; recasting cancels it.
- **E:**
  - clears a move order but keeps attack orders, so E → attack reset → double shot works
  - passes through enemies and stops at walls
- **RMB on the dummy moves** and does not attack, per the controls table. Lucian's shots pass through walls, as in LoL.
- **Deferred:** the E rank-5 bonus (a kill lowers E's cooldown by 1 s). The dummy never dies, so there is no kill event yet. A `notify_kill()` hook is left for the phase that adds killable enemies.
- **No pathfinding yet.** The test map is an open arena with border walls.

## Placeholder numbers (LoL Lucian, ~70–80% similar; kept in `.tres` files for tuning)

**Base stats (level 1 / growth):**

| Stat | Level 1 | Growth |
|---|---|---|
| HP | 600 | +95 |
| HP regen | 4.0 per 5 s | +0.6 |
| Mana | 320 | +40 |
| Mana regen | 8.0 per 5 s | +0.7 |
| AD | 60 | +3 |
| Attack speed | 0.65 | +3% (cap 2.5) |
| Armor | 28 | +4 |
| MR | 30 | +1.3 |
| Move speed | 335 | — |
| Range | 500 | — |
| Crit | 0% (crit damage 175%) | — |

**Formulas:**
- **Growth:** LoL's curve, `base + growth × g(L)` where `g(L) = (L−1) × (0.7025 + 0.0175 × (L−1))` (g(1)=0, g(18)=17).
- **XP to next level:** `180 + 100 × L`, so 18,360 total to reach level 18, which is the cap.
- **Damage:**
  - physical or magic × `100 / (100 + resist)`, or `2 − 100 / (100 − resist)` when the resist is negative
  - crit × 1.75
- **Cooldown:** × `100 / (100 + ability haste)`.

| Skill | Numbers per rank |
|---|---|
| Passive | After any successful cast, the next basic attack fires a 2nd shot (0.15 s later, other gun) for 60% AD; the shot can crit. Each passive shot that hits lowers E's cooldown by 1 s. |
| Q | Physical 80/110/140/170/200 + 60/70/80/90/100% AD. Mana 50/55/60/65/70. CD 9/8/7/6/5 s. Lucian stands still for a 0.3 s cast. The laser is 1000 long and 60 wide, **90 wide at rank 5**. |
| W | Magic 75/110/145/180/215 + 90% AP. Mana 70. CD 14/13/12/11/10 s. 0.2 s cast. The missile (range 900, speed 1600) explodes on the first enemy or at max range in a cross of two 400×60 bars, **×1.4 at rank 5**. The mark lasts 6 s; Lucian's next hit (not W) on a marked enemy gives him +60/65/70/75/80 MS for 1 s. |
| E | Dash toward the cursor: 425 max, 200 min, speed 1350. Mana 40/30/20/10/0. CD 19/17.75/16.5/15.25/14 s. Resets the attack timer. Usable during R. |
| R | 3 s channel, 22 shots in the cast direction, alternating guns. Physical 15/30/45 + 25% AD + 15% AP per shot. Mana 100. CD 100/90/80 s. Lucian can move and E, but cannot attack, Q or W. **Rank 3: bullets pierce, −15% per enemy hit, minimum 30%.** |
| Basic attack | Homing projectile, speed 2800. Windup 15% of attack time. Range 500 + target radius. |

**Dummy:** 2000 HP, 30 armor, 30 MR, all editable from the debug table (instance values only).

## Architecture

### Layout (`res://`)
```
addons/gut/                      vendored GUT 9.7.1 (+ .gutconfig.json at root)
assets/art/{lucian,enemies,ui}/  hand-written SVGs
data/lucian_stats.tres           UnitStats
data/skills/{q,w,e,r}_*.tres     SkillData
src/core/       PURE logic, tested by GUT: layers.gd, damage_info.gd, damage_calc.gd, cooldown.gd,
                unit_stats.gd, stat_block.gd, champion_progress.gd, skill_data.gd, dps_meter.gd
src/stage/      stage.tscn/.gd (main scene, wiring only), test_arena.tscn/.gd, stage_camera.gd
src/lucian/     lucian.tscn/.gd, lucian_controller.gd, lucian_visuals.tscn/.gd,
                skills/{lucian_skill, lightslinger, piercing_light, ardent_blaze, relentless_pursuit, the_culling}.gd
src/combat/     hurtbox.gd, attack_projectile, linear_projectile (W missile + R bullet scenes),
                laser_beam, cross_blast, floating_number, damage_number_spawner
src/enemies/    training_dummy.tscn/.gd, enemy_health_bar.gd (Node2D _draw, not a Control)
src/ui/hud/     hud.tscn/.gd, skill_slot.tscn/.gd (used ×5), stats_panel.tscn/.gd
src/ui/debug/   debug_table.tscn/.gd
tests/unit/     test_*.gd;  tests/tools/screenshot.gd (visual check harness)
```
- No autoloads. `Stage._ready()` wires everything through `setup()` calls.

### Key classes (pure, in `src/core/`)
- **`ChampionProgress`** (RefCounted). Holds `level`, `xp`, `ranks` and `bought` per `Slot {Q,W,E,R}`.
  - Signals: `level_changed`, `xp_changed`, `skill_points_changed`, `rank_changed`.
  - `skill_points()` is **derived** (`level − sum(ranks)`), so it can never drift.
  - Methods: `can_rank_up` / `rank_up`, `add_xp` (can cross several levels; caps at 18), `set_level` (debug; resets ranks if they become invalid), `reset_ranks`, `static required_level(slot, rank)`.
- **`UnitStats`** (Resource, base + growth). `at_level(L) → StatBlock` (RefCounted, the computed values).
- **`SkillData`** (Resource). Per-rank `PackedFloat32Array`s: mana, cooldown, base damage, AD/AP ratios. Plus `damage_at(rank, stats)`.
- **`DamageInfo`** (amount, `Type {PHYSICAL, MAGIC, TRUE}`, is_crit, source StringName, attacker).
- **`DamageCalc`** static functions: `resist_multiplier`, `mitigate`, `is_crit(chance, roll)` (the roll is passed in, so tests are deterministic), `falloff_multiplier`.
- **`Cooldown`**: `start(base, haste)`, `tick`, `reduce` (clamps at 0), `fraction_remaining`.
- **`DpsMeter`**: a session resets after 5 s idle.

### Scene side
- **`Lucian`** (CharacterBody2D, `MOTION_MODE_FLOATING`)
  - Owns `ChampionProgress`, the current `StatBlock`, hp and mana.
  - Signals for the HUD.
  - Exposes `command_move` / `command_attack` / `command_attack_move`, `try_cast(slot, aim)`, `try_rank_up(slot)`, and services for skills (`lock_cast`, `start_dash`, `reset_attack_timer`, `add_move_speed_bonus`, `spawn`, `muzzle_position`).
  - **One standing order** (NONE / MOVE / ATTACK / ATTACK_MOVE) plus **action locks** (attack windup, Q/W cast lock, dash). A lock pauses the order; when it ends, the latest order resumes, as in LoL.
- **`try_cast` gate**, in this order:
  1. rank > 0
  2. cooldown ready
  3. the state rules: Q/W are rejected during a lock, dash or R; E is allowed during R; R is rejected during a lock or dash
  4. mana, skipped with infinite mana
  5. spend mana and start the cooldown (0 with no-cooldowns)
  6. cancel the windup, then `execute(aim)`
  7. `passive.charge()`
- **`LucianSkill`** (Node) base class with Q/W/E/R subclasses. Countdowns run in `_physics_process`; there are no `await`s or `create_timer` (those keep running while paused).
  - **Q and the W explosion** use `direct_space_state.intersect_shape` against `enemy_hurtbox` with `collide_with_areas = true`, which gives instant results.
  - **W missile and R bullets** share the `LinearProjectile` (Area2D) script.
- **Damage pipeline**: skill or attack → `DamageInfo` → `Hurtbox.unit.take_damage(info)`. The dummy then:
  - mitigates the damage, floors its HP at 1, and restarts its refill timer
  - emits `damage_taken(info, final)`, which feeds the damage numbers, the DPS meter and the hit log
  - calls `attacker.on_damage_dealt(...)`, which handles the passive's E reduction and the W mark move-speed bonus
- **`LucianController`** (`_unhandled_input`, so the HUD and debug table get clicks first):
  - Ctrl + skill key → rank up. Checked first, because Ctrl+Q also matches `skill_q`.
  - Skill key → quick cast at `lucian.get_global_mouse_position()`.
  - RMB → move. Holding RMB re-issues the move when the cursor moves more than 8 px.
  - LMB → pick an enemy by distance from the `enemies` group.
  - A → arm attack-move; the next LMB issues it.
  - Any world click releases GUI focus.
- **`DebugTable`** (CanvasLayer 20):
  - Catches **F3+Q in `_input`** and marks it handled, so Q never casts.
  - All buttons use `focus_mode = NONE`; SpinBoxes are filled with `set_value_no_signal`.
- **`StageCamera`** (Camera2D, physics process callback):
  - Free-cam edge pan, with the position clamped by hand to map bounds minus half the visible rect (Camera2D limits alone let the position drift).
  - Edge pan runs only while the window is focused.
  - Y toggles follow mode.
- **Collision layers** (named in `project.godot`): 1 world, 2 player_body, 3 enemy_body, 4 player_hurtbox (reserved), 5 enemy_hurtbox.
  - Lucian's mask is world + enemy_body, and only world while dashing.
  - Projectiles mask only enemy_hurtbox.

## Art (hand-written SVG, top-down, facing +X so `rotation` = aim angle)

| File | Design |
|---|---|
| `lucian/lucian_body.svg` (~96 px) | Long charcoal-navy coat (#1d2230) flaring behind him, silver-white trim, dark-brown head (#5a3a2a) with short black hair, two gunmetal pistols forward with gold-white muzzles (#ffe9a8). Muzzle `Marker2D`s let each gun flash on its own. |
| `lucian/lucian_portrait.svg` | Head-and-shoulders portrait in the same palette, for the HUD |
| `enemies/training_dummy.svg` (~80 px) | LoL practice dummy seen from above: straw body (#c9a45c), wooden cross-beam arms (#7a5230), burlap head (#d8c9a3), red/white target on the chest. Flashes white and wobbles when hit; a ring shows while the W mark is active. |
| `ui/icon_{passive,q,w,e,r}.svg`, `lock.svg` (64 px) | Passive: two crossed light bolts. Q: a white-gold beam. W: an orange cross burst. E: a motion-streak dash. R: a fan of bullets. |
| Effects (drawn in code) | Bullets: short glowing streaks. Q: a gold-white beam that fades over 0.15 s. W: an orange missile and a cross-shaped flash. E: a fading trail. Muzzle flash. |
| Arena (drawn in code) | 4800×2700 dark slate floor with a faint 128 px grid, stone-grey border walls. Dummy at the center; Lucian starts 700 px to the left. |

## Build order (one commit per verified step)

0. **Setup.**
   - Initial commit of the current state.
   - Save the plan to `docs/implementation/phase1.md` and tick the open topic.
   - Vendor GUT 9.7.1, enable the plugin, add `.gutconfig.json` and a smoke test.
   - Add layer names and the main scene to `project.godot` through Godot (the same generator-script method as before).
1. **Core logic, tests first** (TDD): `ChampionProgress`, `UnitStats`/`StatBlock`, `DamageCalc`, `Cooldown`, `DpsMeter`, `SkillData`.
2. **Data `.tres` files**, plus an integrity test: every per-rank array length equals `max_rank`.
3. **Arena, stage and camera; Lucian movement** (placeholder circle).
4. **Lucian and dummy SVG art**, the dummy (hurtbox, HP bar, refill, marks) and floating damage numbers.
5. **Basic attack** (click-to-attack, windup, homing shot, crit, A-move with a range ring).
6. **HUD:** portrait, level, XP, HP and mana bars; stats panel on C.
7. **Debug table:** F3+Q, level controls, cheats, dummy editor, DPS meter, hit log.
8. **Skill framework:** the cast gate, mana and cooldowns, rank-up via "+" and Ctrl+key, five SkillSlots (cooldown sweep, rank dots, cost, "+", lock).
9. **Q** → 10. **Passive** → 11. **E** → 12. **W** → 13. **R**, each with its max-rank bonus.
14. **Polish:** icons, final GUT run, full manual checklist, final commit.

## Verification

**Unit tests** (headless; run `--import` first so the class cache exists):
```
godot_console --headless --path E:/Project/lucian-the-latern --import
godot_console --headless --path E:/Project/lucian-the-latern -s res://addons/gut/gut_cmdln.gd -gexit
```
They cover:
- growth g(1)=0 and g(18)=17; the attack-speed cap
- XP totals 280 and 18,360; one XP gain crossing several levels; the level 18 cap
- the 2N−1 rank rule; R only at 6/11/16; the `bought` cap; refunds; resets when leveling down; signals
- resist 0 / 100 / −50; true damage unchanged; crit roll edges
- ability haste; `reduce` clamping at 0
- R falloff 1.0 → 0.85 → … floored at 0.3
- DPS sessions
- `.tres` data integrity

**Screenshots** (`tests/tools/screenshot.gd`). The game runs windowed, sends input with `Input.parse_input_event` (move, attack, cast Q/W/R, open the debug table), saves PNGs of the viewport, and Claude inspects them. This checks the art, HUD layout, damage numbers and skill effects.

**Manual playtest checklist** (for you, at the end):
- edge pan and its clamp; Y toggles follow mode
- RMB click and hold-follow; clicking the HUD doesn't move Lucian
- LMB attacks; A-move; orange numbers that change as expected when the dummy's armor is edited
- F3+Q toggles the table and never casts Q
- "+" appears at the correct levels; R is locked before level 6
- Ctrl+Q ranks Q up
- each skill's effect and max-rank bonus
- passive double shot after a cast; E's cooldown drops on passive hits
- the W mark gives move speed (visible in the stats panel)
- R works while moving and E is allowed during R
- the no-cooldowns, infinite-mana and crit cheats
- the dummy refills after 4 s
