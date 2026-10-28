# Phase 6: Acts 1 and 2, waves and real enemies, the stage HUD, the title screen, the rest of the save system (implementation plan)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The story starts. A new game opens on a title screen, picks a slot and goes straight into Act 1:
- Lucian and Senna fight minion waves on the mid lane until Thresh takes her soul, in a scripted cutscene.
- Act 2's three stages on the Sentinels' training ground end with Akshan.

Underneath that:
- Enemies hurt Lucian, and he can die.
- Enemies die and drop gold, XP, essences and items.
- The 7 defensive items work.
- The stage HUD gets a wave counter, a boss bar and a radar.
- The save system gets its last pieces: slots chosen on the title screen, Leave to main menu, and first-time boss purple.

**Architecture:** Same layering as Phases 1–5:
- **Pure logic** in `src/core/`, tested with GUT first: `Shields`, `EnemyData`, `KillRewards`, `LootTable`, `WavePlan`, `WaveRunner`, and additions to `SaveGame` and `StageSetup`.
- **Data** as `.tres`: `data/enemies/*.tres`.
- **Nodes and UI** are built in code, with no new `.tscn`.
- **The enemy class tree:**
  - `Enemy` (anything Lucian can hit) gains death.
  - `EnemyUnit extends Enemy` adds movement and attacks.
  - `Minion` and `Boss` (→ `Thresh`, `Akshan`) extend `EnemyUnit`.
- **The stage** builds its map from its `StageSetup`, runs a `WaveRunner`, spawns enemies, pays out rewards and ends with a result panel.
- **`Game`** opens on the new `TitleScreen`.

**Tech Stack:** Godot 4.7.2 (GDScript), GUT 9.7.1, the `tests/tools/screenshot.gd` harness, hand-written SVG.

**Spec:**
- `docs/act1_the_loss.md`, `docs/act2_the_sentinels.md`: enemies, bosses, waves.
- `docs/ui_design.md`: "Top center – Stage info", "Bottom right – Radar", "Screens to design".
- `docs/lucian_game_design.md`: §3 stage rules, §9 drops, §12 acts, §13 maps, §15 save system.
- `docs/items.md`: the defensive items.
- `docs/main_screen.md`: the gear menu's Leave to main menu, Journey.
- The user's Phase 6 request (quoted under Context).

## Context

The user's Phase 6 list:
1. Add the wave count UI (top center of the stage screen, as in `ui_design.md`).
2. Add the radar (bottom right of the stage screen, as in `ui_design.md`).
3. Add the start game screen: **Start new game**, **Load game**, **Settings**, **Exit game**.
4. Build the parts of the save system not done yet.
5. Design the maps and enemies of Acts 1 and 2, and build them.

Where Phase 5 left things:
- **Only Training starts.** Nothing can hurt Lucian: `Lucian` has no `take_damage` and cannot die.
- **No enemy can die.** `Enemy` only has `damage_taken`, and `TrainingDummy` floors at 1 HP. So there are no kill hooks, rewards or drops.
- **There are no waves**: no spawner and no second map. `stage.tscn` always holds `TestArena` and one dummy.
- **The save is stuck on slot 1.** There is no title screen, "Leave to main menu" is disabled, and first-time boss purple isn't tracked.

### Decisions made with the user
| Topic | Decision |
|---|---|
| Defensive items | **All 7 work now:** Guardian Angel, Immortal Shieldbow, Thornmail, Death's Dance, Banshee's Veil, Kaenic Rookern, Fimbulwinter's Everlasting. |
| Item drops | **Ground loot.** Enemies can drop a fragment, or very rarely a legendary. It lies where the enemy died, and Lucian walks over it to pick it up. |
| Thresh cutscene | **In-engine and scripted:** letterbox bars, camera pans, Thresh hooks Senna, her soul flies into his lantern, he sinks into the river. Captions; Space or a click moves on; a Skip button. |
| New game | After a slot is picked, the game goes **straight into Act 1** (the tutorial, with tips), then to the main screen. |
| Game length | A skilled player needs **at least 5–7 hours** to beat the story. Numbers are set to that pace (see **Pacing**), and play time is measured: each stage's time on its result panel, and each slot's total play time in the slot lists. |

### Defaults chosen during planning (placeholders, tune later; each goes into the docs in Task 15)
- **Who enemies attack:** only Lucian. Senna can't be targeted, so she "cannot die before the cutscene" with no special case.
- **Act 1, first play** (stage 1-1 not cleared; `StageSetup.tutorial`):
  - Lucian has **one gun**: every shot leaves the left muzzle.
  - **No skill ranks, no passive, no summoner spells.** Items, tree stats, equip slots and the skin still apply.
  - **Senna** follows him.
  - The **boss wave is Thresh**, and the cutscene plays at 50% of his HP.
- **Act 1, replay:** full kit, **no Senna, no Thresh**. The stage ends after wave 2 and gives no purple.
- **Stage flow:**
  1. **"Wave 1 in 0:05"** (Skip works).
  2. The waves, with **20 s breaks** between them. The merchant comes when a break starts and leaves when it ends.
  3. One more break, then the boss wave.
  4. A result panel.
- **Spawns:** groups of 3 every 1.2 s, taking turns over the stage's spawn points.
- **Skip** credits the HP and mana regen of the time skipped (`Lucian.restore_for`). Cooldowns and buffs don't move.
- **Result panel** (pauses the game; ESC and P do nothing):
  - It shows **STAGE CLEARED** or **DEFEATED**, the stage name, waves cleared, the essences collected and the reward lines.
  - **Continue** emits `finished`. Game auto-saves and opens the main screen on that act.
- **Death:** Lucian greys and fades for 1.5 s, then DEFEATED shows. Enemies idle once he is dead. Guardian Angel's stasis comes first.
- **Essences** go into `SaveGame.essences` when they drop. Leaving, dying or answering Yes to "Save before leaving?" keeps them; No loses them, as the design doc says. The stage also counts them for its HUD.
- **Gold, XP and essences** are credited on every kill (Senna's kills too). Item loot is the only pickup.
- **Tree economy nodes work now:**
  - Stage Gold × gold.
  - Bonus XP × XP.
  - Essence Drops × blue (rounded) and × the orange chance.
- **Ground loot:**
  - It stays until the stage ends.
  - Lucian picks it up within 60 px, into the backpack.
  - With a full backpack it stays and says "Backpack full", at most once every 3 s.
  - Shown as the item icon over a bobbing glow, gold for a legendary.
- **Enemy movement:** direct steering plus `move_and_slide`, with no navigation mesh.
  - A stuck enemy sidesteps.
  - Enemies collide with each other and with Lucian.
  - Map obstacles are simple shapes kept apart.
- **Enemy hits on Lucian** use geometry: distance to his position, plus `Lucian.HIT_RADIUS` (30).
- **Enemy projectiles** are `Area2D`s on mask `WORLD`: walls and pillars stop them. Lucian's homing shots still pass walls, as today.
- **Banshee's Veil** blocks a boss skill hit (`DamageInfo.from_skill`) whole, including the hook's pull. The siege shell is a normal attack.
- **Shield order** (first absorbs first):
  1. Kaenic Rookern's Magebane (magic only)
  2. Shieldbow's Lifeline
  3. Barrier
  4. Fimbulwinter's Everlasting
  5. Bloodthirster's Ichorshield
- **HUD:**
  - The stage info sits top center, with the boss bar under it.
  - "FPS N" moves to the top-left corner.
  - Collected essences sit next to the stage gold.
- **Radar:** 260 px wide, with the height from the map's aspect.
  - Lucian is a blue dot, an enemy a red dot, an elite a bigger red dot, and a boss a red skull.
  - Also shown: Senna as a small pale-blue dot, and the merchant as a gold dot during breaks.
  - It ignores the mouse.
- **Title screen:**
  - **Start new game:**
    1. Shows the 3 slots.
    2. A used slot asks "Overwrite slot N? Its progress will be lost.".
    3. The new save is **written at once**, so the overwrite is real.
    4. Then Act 1 starts.
  - **Load game:**
    - The same list, with empty slots disabled.
    - The button itself is disabled ("No saved games yet") with no slot at all.
  - **Settings:** the shared screen.
  - **Exit game:** quits at once. The window's X on the title screen also quits without a prompt.
- **Leave to main menu** (gear menu) works:
  - "Save before leaving?" → title screen.
  - A failed save asks "Could not save. Leave anyway?".
- **Journey:**
  - Stage cards can be picked. The default is the first open, uncleared stage, else the last.
  - **Start** works on any open stage.
  - Journey opens on the **act just played** after a stage. Otherwise it opens on the **first act with an open, uncleared stage**, else on Training.
- **Save file:** `"version"` stays 1; the change only adds a key. `"bosses"` lists the bosses that already gave their first-time purple (`"thresh_1"`, `"akshan"`).

### Enemy numbers (Act 1 base; `data/enemies/*.tres`)
Lucian at level 1: 600 HP, 60 AD, 0.65 AS, 28 armor, 30 MR, range 500.

| id | Kind | HP | Armor / MR | Hit | Range | Every | Speed | Radius | Gold | XP |
|---|---|---|---|---|---|---|---|---|---|---|
| `melee_minion` | normal | 240 | 10 / 0 | 12 physical, melee | 110 | 1.25 s | 300 | 28 | 60 | 30 |
| `ranged_minion` | normal | 160 | 0 / 10 | 18 magic bolt at 450 px/s aimed where Lucian is; keeps 420–550 away | 550 | 1.6 s | 300 | 26 | 45 | 25 |
| `siege_minion` | elite | 700 | 20 / 10 | Cannon Shell: circle r 110 on Lucian, lands after 1.0 s, 40 physical | 700 | 3.0 s | 220 | 36 | 120 | 60 |
| `super_minion` | elite | 1400 | 40 / 20 | 45 physical, melee; **Empower**: melee and ranged minions within 500 deal +15% | 130 | 1.4 s | 260 | 40 | 150 | 90 |

**Scaling** (bosses don't scale):
- Per act: HP × (1 + 0.6·(act − 1)), damage × (1 + 0.25·(act − 1)), gold and XP × (1 + 0.25·(act − 1)).
- Per wave: HP and damage +15% for each wave after the first.
- These are set for the pace in **Pacing** below.

| Boss | HP | Armor / MR | Basic | Skills |
|---|---|---|---|---|
| **Thresh** (`thresh_1`) | 3000; the fight stops at 50% | 30 / 30 | 30 physical, range 450, every 1.8 s, speed 300 | **Death Sentence (Q):** a line warning (1000 × 70) for 0.9 s, then the hook at 1400 px/s. On a hit: 80 magic, and Lucian is pulled to 120 in front of Thresh. Cooldown 9 s. **Flay (E):** a cone warning (70°, 400) for 0.6 s, then 60 magic and a 250 push away. Cooldown 7 s. |
| **Akshan** (`akshan`) | 5000 | 35 / 30 | 28 physical, range 550, every 1.4 s, speed 320 | **Avengerang (Q):** a line warning (900) for 0.8 s; out 900 at 1000 px/s, then back to Akshan; 70 physical, once per pass. Cooldown 8 s. **Heroic Swing (E):** a circle warning (r 300) on a point near Lucian for 1.2 s; then 2.5 s swinging around it, a bolt outward every 0.3 s (25 physical). Cooldown 14 s. **Comeuppance (R):** a lock line follows Lucian for a 2.0 s charge; then 6 bullets 0.12 s apart, aimed at him (40 physical, range 1200, stopped by pillars). Cooldown 20 s; first used at 75% HP. |

**Senna** (Act 1 first play): stays 150 behind and to the left of Lucian. Every 1.5 s she shoots the nearest enemy within 900 for 45 physical.

**Essences** (design doc §9):
- Normal: blue = the act number; 1% chance of 1 orange.
- Elite: 5 × that blue; 10% chance of 1 orange.
- Boss: 100 blue, 5 orange, and purple 10 the first time / 2 on repeats (Thresh: 10 / 0).

**Loot:**
- Normal: 4% fragment, else 0.3% legendary.
- Elite: 25% fragment, else 3% legendary.
- Boss: a fragment for sure, plus a 15% legendary.

### Waves (`WavePlan`)
| Stage | Waves (m melee, r ranged, S siege, U super) | Boss wave |
|---|---|---|
| 1-1 | 6m 4r · 6m 6r 1S | Thresh (first play only) |
| 2-1 | 6m 4r 1S · 6m 6r 1S 1U | — |
| 2-2 | 6m 6r 1S · 6m 6r 2S · 6m 6r 1S 1U | — |
| 2-3 | 6m 6r 2S · 6m 6r 1S 1U · 8m 6r 2S 1U | Akshan, alone |

### Pacing (at least 5–7 hours for a skilled player)

**The whole story, per act.** These are minutes for a skilled player's first clear, including a few deaths, shopping, and the replays needed to afford Evolution Tree nodes.

| Act | Stages | Waves (+ boss / mini boss waves) | Minutes |
|---|---|---|---|
| 1 | 1 | 2 + 1 | 8–10 (tutorial and cutscene) |
| 2 | 3 | 8 + 1 | 30–40 |
| 3 | 5 | 21 + 3 | 70–90 |
| 4 | 3 | 14 + 1 | 45–60 |
| 5 | 5 | 28 + 3 | 80–100 |
| 6 | 5 | 33 + 3 | 90–120 |
| **All** | 22 | 106 + 12 | **323–420 (5.4–7 h)** |

**Rules of thumb for this and later phases:**
- A wave should take a skilled player **about 2 minutes** of fighting.
- A boss should take **2–3 minutes**.
- A break is used, on average, for about 30 s of shopping.
- About a third of each act's time is deaths and replays: farming essence for the tree, as the design doc's balance goal expects.

**How Acts 1–2 hit their share.** Lucian restarts every stage at level 1; Act 2 stages have Q/W rank 1–2, E 1 and the passive by 2-3, and a fragment or two per stage, so his pack damage is about 60–90 at levels 1–3 and 120–160 at levels 4–7 with a legendary.
- **Act 1:**
  - The waves hold 2.1k and 3.4k HP of minions. Against Lucian (~35 damage per second) plus Senna (~27), each takes about 1–1.5 minutes with walking and dodging.
  - Thresh's 1,500 HP to the cutscene takes about 1.5 minutes, dodging hooks.
  - Add the countdown, a break, tips and the cutscene: about **8 minutes**.
- **Act 2:**
  - With the scaling above (×1.6 HP, +15% per wave), waves hold 4.4k to 11.8k HP: about 1.5–2.5 minutes each.
  - Akshan's 5,000 HP with dodge windows takes about 3 minutes.
  - A clean pass is about **27 minutes**. One or two defeats, or a replay of 2-1 or 2-2 for essence, bring it to the **30–40** budget.
- **Economy check (unchanged §9 rates):**
  - Act 1 gives about 127 blue (Thresh's 100 included): Q rank 1.
  - Act 2 gives about 450 blue on a first pass: W, the passive, and Q or E rank 2.
  - Across the story a first pass earns about 11k blue. Buying "all skills, R, 4–5 equip slots and some stats" (about 14k blue and 130 orange) needs some replays, which the minutes above include.

Tune against this in playtests. The result panel's stage time and the slot's total play time (below) are the measurements. If Act 2 clears in under 25 minutes, raise `EnemyData.ACT_HP` and the bosses' HP before changing rewards.

### Maps (drawn in code; walls on `Layers.WORLD`)
- **Act 1 – Mid lane** (`MidLaneMap`, 5200 × 3200):
  - A diagonal lane 900 wide, from bottom-left (500, 2700) to top-right (4700, 500).
  - The jungle on both sides is wall, dark green.
  - The **river** crosses the lane's middle at a right angle. It is walkable shallow water, 520 wide, reaching 1100 from the lane's center into the jungle.
  - Three rocks (r 70) give cover.
  - Lucian and Senna start at the bottom-left end, and minions come from the top-right end. Thresh rises from the river center. The merchant waits on the lane before the river.
- **Act 2 – Training ground** (`TrainingGroundMap`, 4600 × 2800):
  - Stone tiles, with gates drawn on the left, top and right walls.
  - Training dummies stand along the walls as decoration: `WORLD` circles, faded art, not enemies.
  - Lucian starts at (2300, 2550). The merchant stands at (1700, 2350).
  - Pillars (r 70) by stage:
    - Stage 1: 6 pillars; spawns at the top and right gates.
    - Stage 2: 8 pillars; all 3 gates.
    - Stage 3: 10 pillars in a ring (r 650) around the center; all 3 gates; Akshan enters from the top gate.
- **Training** keeps `TestArena` and its dummy, with no waves.

### Art (hand-written SVG, top-down, facing +X, a `<!-- Name: description -->` header, `#1a1d24` outline)
| File | Size | Look |
|---|---|---|
| `assets/art/enemies/melee_minion.svg` | 72 | Red-team minion: round crimson helmet, short blade forward |
| `assets/art/enemies/ranged_minion.svg` | 68 | Red-team caster: hooded, a glowing purple orb held forward |
| `assets/art/enemies/siege_minion.svg` | 96 | A wheeled cannon cart, barrel forward, red crest |
| `assets/art/enemies/super_minion.svg` | 112 | A big armored brute with glowing red runes and two fists |
| `assets/art/enemies/thresh.svg` | 120 | Green-black warden, a chain sickle forward, a green lantern at his left |
| `assets/art/enemies/akshan.svg` | 100 | Sentinel coat (white and teal), a rope grapple, a gold-white gun forward |
| `assets/art/npc/senna.svg` | 100 | Hooded, a big relic cannon forward, teal-white light |
| `assets/art/ui/status_empower.svg` | 64 | A red up-chevron over a fist (Empower status) |
| `assets/art/ui/title_lantern.svg` | 256 | Thresh's lantern with chains and a green soul glow |

## Global Constraints
- Godot **4.7.2**. Match the GDScript style around it: tabs, typed vars, `##` doc comments on classes and public funcs, `&"name"` StringNames, one `class_name` per file.
- **No autoloads.** Pure logic stays in `src/core/` with no scene dependencies. UI is built in code; there is no new `.tscn`.
- `stage.tscn` run on its own stays the sandbox: Training, everything unlocked. `StageSetup.new()` is that sandbox (`act = 0`).
- **Everything that holds an enemy** (Lucian's orders, attack shots, homing missiles, Lightslinger's second shot) checks `is_alive()`. A dead enemy leaves `&"enemies"` and its hitboxes at once, then fades for 0.4 s and is freed.
- New player-facing numbers are constants at the top of their script or exports on `.tres` data, set for the **Pacing** budget (a skilled player: at least 5–7 hours for the story).
- Work on `main`, **one verified commit per task**, never pushed. Each commit: GUT suite green. Every commit message ends with `Co-Authored-By: Claude <noreply@anthropic.com>`.
- Docs follow the existing voice: short plain sentences, tables for numbers.

## File map

| File | Change |
|---|---|
| `src/enemies/enemy.gd` | `died`, `dead`, `is_alive()`, `last_attacker`, death fade, kill credit |
| `src/core/shields.gd` | **new** `Shields` |
| `src/lucian/lucian.gd` | `take_damage`, `died`, `dead`, `invulnerable`, stasis, `displace`, `restore_for`, `on_kill`, `one_gun`, `add_shield`, `bonus_armor` |
| `src/lucian/items/item_passives.gd` | defensive hooks and the 7 items |
| `src/lucian/items/item_actives.gd` | Gunblade tells passives it slowed |
| `src/core/restore_over_time.gd` | `start_amount()` (Death's Dance's Defy heal) |
| `src/lucian/lucian_controller.gd` | no input while dead, in stasis or displaced |
| `src/core/damage_info.gd` | `from_skill` |
| `src/combat/attack_projectile.gd`, `homing_missile.gd`, `src/lucian/skills/lightslinger.gd` | `is_alive()` guards |
| `src/combat/damage_number_spawner.gd`, `floating_number.gd` | `size_scale` |
| `src/combat/floating_text.gd` | **new** rising text with an optional icon |
| `src/combat/ground_warning.gd`, `src/combat/enemy_projectile.gd` | **new** |
| `src/core/enemy_data.gd`, `data/enemies/*.tres` (6) | **new** |
| `src/enemies/enemy_unit.gd`, `minion.gd`, `boss.gd`, `bosses/thresh.gd`, `bosses/akshan.gd` | **new** |
| `src/allies/senna.gd` | **new** |
| `src/core/kill_rewards.gd`, `src/core/loot_table.gd`, `src/stage/loot_drop.gd` | **new** |
| `src/core/save_game.gd` | `bosses`, `award_boss`, `start_new`, `any_slot_exists` |
| `src/stage/stage_map.gd`, `src/stage/stage_maps.gd`, `src/stage/maps/mid_lane_map.gd`, `src/stage/maps/training_ground_map.gd` | **new** |
| `src/stage/test_arena.gd` | extends `StageMap` |
| `src/core/wave_plan.gd`, `src/core/wave_runner.gd` | **new** |
| `src/core/stage_setup.gd` | act, stage, id, name, boss, tutorial, bonuses, `for_stage()` |
| `src/stage/stage.gd`, `stage.tscn` | map swap, `Warnings` node, spawning, rewards, waves, result, cutscene, Senna |
| `src/stage/cutscene.gd`, `src/stage/cutscenes/thresh_takes_senna.gd` | **new** |
| `src/ui/stage/stage_result.gd` | **new** |
| `src/ui/screen_switcher.gd` | `locked` |
| `src/ui/hud/hud.gd`, `stage_info.gd`, `boss_bar.gd`, `radar.gd`, `tip_banner.gd` | stage panel, boss bar, radar, tips, essences, FPS top-left |
| `src/ui/main/journey/stage_card.gd`, `act_page.gd`, `journey_section.gd`, `src/ui/main/main_screen.gd` | acts start |
| `src/ui/menu/slot_list.gd`, `src/ui/title/title_screen.gd` | **new** |
| `src/ui/main/gear_menu.gd` | `SlotList`, Leave to main menu |
| `src/main/game.gd` | title first, `show_title`, stage id, back to the act |
| `src/ui/debug/debug_table.gd`, `main_debug_table.gd` | Waves tab, God mode, no dummy, Forget boss purple |
| `src/audio/sfx.gd` | `hurt`, `hook`, `shell` sounds |
| `tests/unit/…` | new: `test_enemy_death`, `test_shields`, `test_lucian_damage`, `test_item_defense`, `test_ground_warning`, `test_enemy_data_files`, `test_minions`, `test_kill_rewards`, `test_loot`, `test_maps`, `test_wave_runner`, `test_stage_waves`, `test_stage_hud`, `test_act1`, `test_akshan`, `test_title_screen`, `test_stage_debug_waves`. Extended: `test_skins`, `test_save_game`, `test_game`, `test_journey_section`, `test_main_screen`, `test_main_debug`, `test_stage_setup` |
| `tests/tools/screenshot.gd` | Phase 6 scenarios |
| `docs/…` | `implementation/phase6.md`, `report/phase6.md` (+ `report/phase6/*.png`), `ui_design.md`, `main_screen.md`, `lucian_game_design.md`, `act1_the_loss.md`, `act2_the_sentinels.md`, `items.md` |

## Running things

```powershell
$godot = "$env:LOCALAPPDATA\Programs\Godot"
& "$godot\godot_console.exe" --headless --path . --import                       # after adding SVG/.tres files
& "$godot\godot_console.exe" --headless --path . -s res://addons/gut/gut_cmdln.gd  # full suite
& "$godot\godot_console.exe" --headless --path . -s res://addons/gut/gut_cmdln.gd -gconfig= -gtest=res://tests/unit/<file>.gd -gexit  # one file
& "$godot\godot.exe" --path . -s res://tests/tools/screenshot.gd -- <scenario> <out_dir>  # needs a window
```

---

### Task 0: Save the plan

- [ ] This file is the plan. Add "Phase 6: `implementation/phase6.md`" to `lucian_game_design.md` §16.
- [ ] In `act2_the_sentinels.md`, replace the Overview's "*(placeholder)*" with a **Waves** table (the 2-1, 2-2 and 2-3 rows of the Waves table above).
- [ ] Commit: `git add docs/implementation/phase6.md docs/lucian_game_design.md docs/act2_the_sentinels.md` → `git commit -m "Add the Phase 6 plan"`.

---

### Task 1: Enemies die; kill hooks

**Files:**
- Modify: `src/enemies/enemy.gd`, `src/lucian/lucian.gd`, `src/lucian/skills/lightslinger.gd`, `src/lucian/skills/relentless_pursuit.gd`, `src/combat/attack_projectile.gd`, `src/combat/homing_missile.gd`.
- Test: `tests/unit/test_enemy_death.gd`; modify `tests/unit/test_skins.gd`.

**Interfaces — Produces:**
- `Enemy`:
  - `signal died(enemy: Enemy)`, `var dead := false`, `var last_attacker: Node`, `func is_alive() -> bool`, `const DEATH_FADE := 0.4`.
  - `take_damage` on a dead enemy returns `0.0` and does nothing.
- `Lucian`: `signal enemy_killed(enemy: Enemy)`, `func on_kill(enemy: Enemy) -> void`.
- `RelentlessPursuit.KILL_CUT := 1.0`.

- [ ] **Step 1: Failing tests.**
  - `tests/unit/test_enemy_death.gd`:
    ```gdscript
    extends GutTest
    ## Enemies that die: the died signal, the kill credit and what lets go of them.

    const Slot := ChampionProgress.Slot

    var lucian: Lucian


    func before_each() -> void:
    	lucian = load("res://src/lucian/lucian.tscn").instantiate()
    	add_child_autofree(lucian)


    func _enemy(hp: float, at := Vector2(300, 0)) -> Enemy:
    	var enemy := Enemy.new()
    	enemy.max_hp = hp
    	enemy.position = at
    	add_child_autofree(enemy)
    	return enemy


    func _true_hit(amount: float, source := &"test") -> DamageInfo:
    	return lucian.make_damage(amount, DamageInfo.Type.TRUE, source)


    func test_died_fires_once_and_the_enemy_leaves_the_group() -> void:
    	var enemy := _enemy(100.0)
    	watch_signals(enemy)
    	enemy.take_damage(_true_hit(150.0))
    	enemy.take_damage(_true_hit(10.0))
    	assert_signal_emit_count(enemy, "died", 1)
    	assert_false(enemy.is_alive())
    	assert_false(enemy.is_in_group(&"enemies"))


    func test_a_dead_enemy_takes_no_damage() -> void:
    	var enemy := _enemy(100.0)
    	enemy.take_damage(_true_hit(150.0))
    	watch_signals(enemy)
    	assert_eq(enemy.take_damage(_true_hit(50.0)), 0.0)
    	assert_signal_not_emitted(enemy, "damage_taken")


    func test_the_kill_goes_to_the_last_attacker() -> void:
    	var enemy := _enemy(100.0)
    	watch_signals(lucian)
    	enemy.take_damage(_true_hit(150.0))
    	assert_signal_emit_count(lucian, "enemy_killed", 1)


    func test_on_hit_procs_after_the_killing_blow_never_kill_twice() -> void:
    	lucian.inventory.put(Inventory.EQUIP_START, lucian.item_catalog.find(&"nashors_tooth"))
    	var enemy := _enemy(10.0)
    	watch_signals(lucian)
    	enemy.take_damage(_true_hit(50.0, &"basic"))
    	assert_signal_emit_count(lucian, "enemy_killed", 1)


    func test_a_shot_flying_to_a_dead_enemy_is_dropped() -> void:
    	var enemy := _enemy(100.0, Vector2(2000, 0))
    	var shot := AttackProjectile.new()
    	add_child(shot)
    	shot.launch(Vector2.ZERO, enemy, _true_hit(40.0))
    	enemy.take_damage(_true_hit(500.0))
    	watch_signals(enemy)
    	await wait_physics_frames(2)
    	assert_signal_not_emitted(enemy, "damage_taken")
    	assert_false(is_instance_valid(shot))


    func test_an_attack_order_on_a_dead_enemy_stops() -> void:
    	var enemy := _enemy(100.0, Vector2(2000, 0))
    	enemy.take_damage(_true_hit(500.0))
    	lucian.command_attack(enemy)
    	await wait_physics_frames(3)
    	assert_eq(lucian.global_position, Vector2.ZERO)


    func test_a_dead_enemy_fades_then_is_freed() -> void:
    	var enemy := _enemy(100.0)
    	enemy.take_damage(_true_hit(500.0))
    	assert_true(is_instance_valid(enemy))
    	await wait_seconds(Enemy.DEATH_FADE + 0.2)
    	assert_false(is_instance_valid(enemy))


    func test_e_rank_5_kill_cuts_its_cooldown_by_1_second() -> void:
    	lucian.progress.set_level(9)
    	for i in 5:
    		assert_true(lucian.try_rank_up(Slot.E))
    	var e := lucian.skills[Slot.E]
    	e.cooldown.start(10.0)
    	_enemy(10.0).take_damage(_true_hit(50.0))
    	assert_almost_eq(e.cooldown.remaining, 10.0 - RelentlessPursuit.KILL_CUT, 0.001)


    func test_e_rank_4_kill_does_not() -> void:
    	lucian.progress.set_level(7)
    	for i in 4:
    		lucian.try_rank_up(Slot.E)
    	var e := lucian.skills[Slot.E]
    	e.cooldown.start(10.0)
    	_enemy(10.0).take_damage(_true_hit(50.0))
    	assert_almost_eq(e.cooldown.remaining, 10.0, 0.001)
    ```
  - `test_skins.gd`: replace `_hit()` so the kill goes through `take_damage`:
    ```gdscript
    func _hit(enemy_hp: float) -> float:
    	var enemy := Enemy.new()
    	enemy.max_hp = 1000.0
    	add_child_autofree(enemy)
    	enemy.hp = maxf(enemy_hp, 1.0)
    	lucian.hp = lucian.stats.max_hp * 0.5
    	var before := lucian.hp
    	# A Q (no life steal) that kills an enemy at 1 HP, or scratches one at 50.
    	enemy.take_damage(lucian.make_damage(1.0 if enemy_hp > 1.0 else 5.0, DamageInfo.Type.TRUE, &"q"))
    	return lucian.hp - before
    ```
- [ ] **Step 2:** Run both files and expect FAIL (`died`, `on_kill`, `KILL_CUT` missing).
- [ ] **Step 3: Implement.**
  - `Enemy` (the death part; the rest of the class stays):
    ```gdscript
    ## The enemy died (once). Lucian's kill hooks run from it too.
    signal died(enemy: Enemy)

    ## Seconds a dead enemy fades before it is freed.
    const DEATH_FADE := 0.4

    var dead := false
    ## Whoever hit this enemy last: the kill is theirs.
    var last_attacker: Node


    func is_alive() -> bool:
    	return not dead


    ## The attacker may scale the hit first (before_damage), then armor or magic
    ## resist, after any shred, lowers it. A dead enemy takes nothing. It dies
    ## after the attacker's on-hit effects, so they still see the target.
    func take_damage(info: DamageInfo) -> float:
    	if dead:
    		return 0.0
    	var attacker: Node = info.attacker if is_instance_valid(info.attacker) else null
    	if attacker and attacker.has_method(&"before_damage"):
    		attacker.before_damage(self, info)
    	var final_amount := DamageCalc.mitigate(info.amount, info.type, effective_armor(), effective_mr(), info.armor_pen, info.magic_pen)
    	if attacker:
    		last_attacker = attacker
    	_lose_hp(final_amount)
    	Sfx.play(&"hit", -12.0)
    	damage_taken.emit(info, final_amount)
    	if attacker and attacker.has_method(&"on_damage_dealt"):
    		attacker.on_damage_dealt(self, info, final_amount)
    	if hp <= 0.0:
    		_die()
    	return final_amount


    ## Once: out of the enemies group and every hitbox, the kill credit, then a
    ## short fade before the node goes.
    func _die() -> void:
    	if dead:
    		return
    	dead = true
    	remove_from_group(&"enemies")
    	collision_layer = 0
    	for child in get_children():
    		if child is Hurtbox:
    			(child as Hurtbox).collision_layer = 0
    	died.emit(self)
    	if is_instance_valid(last_attacker) and last_attacker.has_method(&"on_kill"):
    		last_attacker.on_kill(self)
    	var fade := create_tween()
    	fade.tween_property(self, "modulate:a", 0.0, DEATH_FADE)
    	fade.tween_callback(queue_free)
    ```
  - `Lucian`:
    - Add `signal enemy_killed(enemy: Enemy)`.
    - Delete the two kill-heal lines from `on_damage_dealt` (`if skin.kill_heal > 0.0 and target.hp <= 0.0: …`) and its doc sentence "A skin's kill heal works on the hit that kills."
    - Add:
    ```gdscript
    ## Called once by an enemy Lucian killed: the skin's kill heal, E's max
    ## rank bonus and item kill effects.
    func on_kill(enemy: Enemy) -> void:
    	if skin.kill_heal > 0.0:
    		heal(stats.max_hp * skin.kill_heal)
    	var e := skills[ChampionProgress.Slot.E]
    	if e.rank() >= ChampionProgress.MAX_RANKS[ChampionProgress.Slot.E]:
    		e.cooldown.reduce(RelentlessPursuit.KILL_CUT)
    	passives.on_kill()
    	enemy_killed.emit(enemy)


    ## An enemy still worth aiming at: there, and not dead.
    static func is_target(enemy: Enemy) -> bool:
    	return is_instance_valid(enemy) and enemy.is_alive()
    ```
    - In `_physics_process`, use `is_target()` in place of `is_instance_valid()` for `_target` (`Order.ATTACK`, `Order.ATTACK_MOVE`) and `_cast_target` (`Order.CAST`). Do the same in `_process_windup`.
  - `ItemPassives`: add an empty `func on_kill() -> void: pass` with `## Death's Dance (Defy) reacts here.`. Task 3 fills it.
  - `RelentlessPursuit`:
    - Add `## Seconds a kill takes off the cooldown at max rank.` with `const KILL_CUT := 1.0`.
    - Its doc comment becomes "The max rank bonus (a kill lowers the cooldown by 1 s) is applied in Lucian.on_kill."
  - Guards:
    - `AttackProjectile` and `HomingMissile`: `if not Lucian.is_target(_target): queue_free(); return`.
    - `Lightslinger`: `if _second_shot_in <= 0.0 and Lucian.is_target(_second_shot_target):`.
- [ ] **Step 4:** Run both files, then the full suite → PASS.
- [ ] **Step 5:** Commit `"Enemies can die: died signal, kill credit (Vampire once per kill, E max rank), dead targets dropped"`.

---

### Task 2: Lucian takes damage, gets displaced and dies

**Files:**
- Create: `src/core/shields.gd`.
- Modify: `src/lucian/lucian.gd`, `src/lucian/lucian_controller.gd`, `src/core/damage_info.gd`, `src/combat/damage_number_spawner.gd`, `src/combat/floating_number.gd`, `src/audio/sfx.gd`.
- Test: `tests/unit/test_shields.gd`, `tests/unit/test_lucian_damage.gd`.

**Interfaces — Produces:**
- `Shields`:
  - `ORDER`, `add(id, amount, seconds := 0.0, magic_only := false)`, `set_amount(id, amount)`, `remove(id)`, `clear()`.
  - Reads: `amount(id) -> float`, `has(id) -> bool`, `time_left(id)`, `duration(id)`, `total() -> float`.
  - `absorb(amount, type) -> float` (what gets through), `tick(delta)`.
- `DamageInfo.from_skill := false`.
- `Lucian`:
  - `signal died`, `signal damage_received(info: DamageInfo, amount: float)`.
  - `const HIT_RADIUS := 30.0`, `const DEATH_FADE := 1.5`.
  - `var shields := Shields.new()`, `var dead := false`, `var invulnerable := false`, `var one_gun := false`.
  - `take_damage(info) -> bool`, `lose_hp(amount, type)`, `add_shield(id, amount, seconds, magic_only := false)`.
  - `restore_for(seconds)`, `displace(to: Vector2, speed: float)`, `is_displaced() -> bool`.
  - `enter_stasis(seconds, revive_hp, revive_mana)`, `in_stasis() -> bool`, `can_act() -> bool`, `bonus_armor() -> float`.
  - `shield` stays as a property for the Ichorshield, and `barrier` as a read-only one.
- `DamageNumberSpawner.spawn(info, final_amount, unit, size_scale := 1.0)`.

- [ ] **Step 1: Failing tests.**
  - `test_shields.gd`:
    ```gdscript
    extends GutTest

    var shields: Shields


    func before_each() -> void:
    	shields = Shields.new()


    func test_a_hit_goes_through_the_shields_in_order() -> void:
    	shields.add(&"ichorshield", 100.0)
    	shields.add(&"barrier", 50.0, 2.0)
    	assert_almost_eq(shields.absorb(80.0, DamageInfo.Type.PHYSICAL), 0.0, 0.001)
    	assert_false(shields.has(&"barrier"))
    	assert_almost_eq(shields.amount(&"ichorshield"), 70.0, 0.001)


    func test_what_is_left_gets_through() -> void:
    	shields.add(&"barrier", 50.0, 2.0)
    	assert_almost_eq(shields.absorb(80.0, DamageInfo.Type.PHYSICAL), 30.0, 0.001)
    	assert_eq(shields.total(), 0.0)


    func test_a_magic_only_shield_ignores_physical_damage() -> void:
    	shields.add(&"magebane", 100.0, 0.0, true)
    	assert_almost_eq(shields.absorb(40.0, DamageInfo.Type.PHYSICAL), 40.0, 0.001)
    	assert_almost_eq(shields.absorb(40.0, DamageInfo.Type.MAGIC), 0.0, 0.001)
    	assert_almost_eq(shields.amount(&"magebane"), 60.0, 0.001)


    func test_a_timed_shield_runs_out_and_a_lasting_one_stays() -> void:
    	shields.add(&"barrier", 50.0, 1.0)
    	shields.add(&"ichorshield", 20.0)
    	shields.tick(1.1)
    	assert_false(shields.has(&"barrier"))
    	assert_true(shields.has(&"ichorshield"))


    func test_set_amount_to_zero_removes_it() -> void:
    	shields.add(&"ichorshield", 20.0)
    	shields.set_amount(&"ichorshield", 0.0)
    	assert_false(shields.has(&"ichorshield"))
    ```
  - `test_lucian_damage.gd`:
    ```gdscript
    extends GutTest

    var lucian: Lucian


    func before_each() -> void:
    	lucian = load("res://src/lucian/lucian.tscn").instantiate()
    	add_child_autofree(lucian)


    func _hit(amount: float, type := DamageInfo.Type.PHYSICAL) -> DamageInfo:
    	return DamageInfo.create(amount, type, &"basic")


    func test_armor_lowers_physical_damage() -> void:
    	var before := lucian.hp
    	assert_true(lucian.take_damage(_hit(100.0)))
    	var expected := DamageCalc.mitigate(100.0, DamageInfo.Type.PHYSICAL, lucian.stats.armor, lucian.stats.mr, 0.0, 0.0)
    	assert_almost_eq(before - lucian.hp, expected, 0.01)


    func test_barrier_takes_the_hit_first() -> void:
    	lucian.add_barrier(1000.0, 2.0)
    	var before := lucian.hp
    	lucian.take_damage(_hit(100.0))
    	assert_eq(lucian.hp, before)
    	assert_lt(lucian.total_shield(), 1000.0)


    func test_death_fires_once_and_regen_stops() -> void:
    	watch_signals(lucian)
    	lucian.take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))
    	lucian.take_damage(DamageInfo.create(10.0, DamageInfo.Type.TRUE, &"test"))
    	assert_signal_emit_count(lucian, "died", 1)
    	assert_true(lucian.dead)
    	await wait_physics_frames(5)
    	assert_eq(lucian.hp, 0.0)


    func test_stats_refresh_never_revives_him() -> void:
    	lucian.take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))
    	lucian.refresh_stats()
    	assert_eq(lucian.hp, 0.0)


    func test_invulnerable_refuses_hits() -> void:
    	lucian.invulnerable = true
    	var before := lucian.hp
    	assert_false(lucian.take_damage(_hit(100.0)))
    	assert_eq(lucian.hp, before)


    func test_restore_for_gives_that_much_regen_at_once() -> void:
    	lucian.hp = 100.0
    	lucian.mana = 0.0
    	lucian.restore_for(10.0)
    	assert_almost_eq(lucian.hp, minf(100.0 + lucian.stats.hp_regen * 10.0, lucian.stats.max_hp), 0.01)
    	assert_almost_eq(lucian.mana, minf(lucian.stats.mana_regen * 10.0, lucian.stats.max_mana), 0.01)


    func test_displace_moves_him_and_drops_his_move() -> void:
    	lucian.command_move(Vector2(0, 2000))
    	lucian.displace(Vector2(300, 0), 3000.0)
    	assert_true(lucian.is_displaced())
    	assert_false(lucian.can_act())
    	await wait_physics_frames(12)
    	assert_almost_eq(lucian.global_position.x, 300.0, 2.0)
    	assert_almost_eq(lucian.global_position.y, 0.0, 2.0)
    	assert_false(lucian.is_displaced())


    func test_displace_stops_at_a_wall() -> void:
    	var wall := StaticBody2D.new()
    	wall.collision_layer = Layers.WORLD
    	var shape := CollisionShape2D.new()
    	var box := RectangleShape2D.new()
    	box.size = Vector2(40, 400)
    	shape.shape = box
    	shape.position = Vector2(200, 0)
    	wall.add_child(shape)
    	add_child_autofree(wall)
    	await wait_physics_frames(1)
    	lucian.displace(Vector2(400, 0), 3000.0)
    	await wait_physics_frames(12)
    	assert_lt(lucian.global_position.x, 200.0)
    	assert_false(lucian.is_displaced())


    func test_damage_received_reports_the_amount() -> void:
    	watch_signals(lucian)
    	lucian.take_damage(DamageInfo.create(50.0, DamageInfo.Type.TRUE, &"test"))
    	assert_almost_eq(get_signal_parameters(lucian, "damage_received")[1], 50.0, 0.01)
    ```
- [ ] **Step 2:** Run both files and expect FAIL.
- [ ] **Step 3: Implement.**
  - `Shields`:
    ```gdscript
    class_name Shields
    extends RefCounted
    ## Lucian's shields: each has an id, an amount and a time left (0 = until it
    ## is used up). A hit is taken out of them in ORDER; a magic-only shield
    ## takes only magic damage. Every id used must be in ORDER.

    ## First to absorb first: Kaenic Rookern (magic only), Shieldbow, Barrier,
    ## Fimbulwinter, then Bloodthirster's Ichorshield, which lasts.
    const ORDER: Array[StringName] = [&"magebane", &"lifeline", &"barrier", &"everlasting", &"ichorshield"]

    ## Id -> {amount, left, duration, magic_only}.
    var _shields := {}


    ## A new shield replaces an older one with the same id.
    func add(id: StringName, amount: float, seconds := 0.0, magic_only := false) -> void:
    	if amount <= 0.0:
    		return
    	_shields[id] = {"amount": amount, "left": seconds, "duration": seconds, "magic_only": magic_only}


    ## Changes a shield's amount (it is added, lasting, if missing); 0 removes it.
    func set_amount(id: StringName, amount: float) -> void:
    	if amount <= 0.0:
    		_shields.erase(id)
    	elif _shields.has(id):
    		_shields[id].amount = amount
    	else:
    		add(id, amount)


    func remove(id: StringName) -> void:
    	_shields.erase(id)


    func clear() -> void:
    	_shields.clear()


    func has(id: StringName) -> bool:
    	return _shields.has(id)


    func amount(id: StringName) -> float:
    	return _shields[id].amount if _shields.has(id) else 0.0


    func time_left(id: StringName) -> float:
    	return _shields[id].left if _shields.has(id) else 0.0


    func duration(id: StringName) -> float:
    	return _shields[id].duration if _shields.has(id) else 0.0


    func total() -> float:
    	var sum := 0.0
    	for shield: Dictionary in _shields.values():
    		sum += shield.amount
    	return sum


    ## Takes `damage` of `type` out of the shields; returns what gets through.
    func absorb(damage: float, type: DamageInfo.Type) -> float:
    	for id in ORDER:
    		if damage <= 0.0:
    			break
    		if not _shields.has(id):
    			continue
    		var shield: Dictionary = _shields[id]
    		if shield.magic_only and type != DamageInfo.Type.MAGIC:
    			continue
    		var taken := minf(shield.amount, damage)
    		shield.amount -= taken
    		damage -= taken
    		if shield.amount <= 0.0:
    			_shields.erase(id)
    	return damage


    func tick(delta: float) -> void:
    	for id: StringName in _shields.keys():
    		var shield: Dictionary = _shields[id]
    		if shield.duration > 0.0:
    			shield.left -= delta
    			if shield.left <= 0.0:
    				_shields.erase(id)
    ```
  - `DamageInfo`: `## A boss or mini boss skill (Banshee's Veil blocks it).` with `var from_skill := false`.
  - `Lucian`. The shields move into `Shields`; `shield` and `barrier` stay as properties, so `BarrierBubble` and the older tests still read them:
    ```gdscript
    ## Lucian died: the stage shows DEFEATED.
    signal died
    ## A hit landed, after armor and before shields (the number shown).
    signal damage_received(info: DamageInfo, amount: float)

    ## Enemy hits reach Lucian within this distance of his center (+ theirs).
    const HIT_RADIUS := 30.0
    ## Seconds Lucian greys out and fades after dying.
    const DEATH_FADE := 1.5
    const HURT_FLASH := Color(1.0, 0.45, 0.45)
    const STASIS_TINT := Color(1.6, 1.35, 0.5)

    var shields := Shields.new()
    ## Bloodthirster's Ichorshield (kept as a property for older callers).
    var shield: float:
    	get:
    		return shields.amount(&"ichorshield")
    	set(value):
    		shields.set_amount(&"ichorshield", minf(value, ICHORSHIELD_MAX))
    ## Barrier's shield.
    var barrier: float:
    	get:
    		return shields.amount(&"barrier")
    var dead := false
    ## Cutscenes and the debug God mode: every hit is refused.
    var invulnerable := false
    ## Act 1's first play: every shot leaves the left gun.
    var one_gun := false

    var _displace_velocity := Vector2.ZERO
    var _displace_left := 0.0
    var _stasis_left := 0.0
    var _revive := Vector2.ZERO
    ```
    - Delete `_barrier_left` and `_barrier_duration`.
    - `add_barrier(amount, seconds)` becomes `add_shield(&"barrier", amount, seconds)`.
    - `total_shield()` returns `shields.total()`.
    - `buffs()` reads the Ichorshield as `shields.amount(&"ichorshield")`, and the Barrier with `shields.time_left(&"barrier")` / `shields.duration(&"barrier")`.
    - In `on_damage_dealt`, the Bloodthirster line becomes `shield = shield + overheal` (the setter caps it).
    - In `_tick_buffs`:
      - The Ichorshield decay becomes `if shield > 0.0 and not passives.in_combat(): shield = maxf(shield - ICHORSHIELD_DECAY * delta, 0.0)`.
      - The barrier timer block is replaced by `shields.tick(delta)`.
    ```gdscript
    ## A shield made stronger by heal and shield power (Barrier, Lifeline,
    ## Everlasting, Magebane).
    func add_shield(id: StringName, amount: float, seconds: float, magic_only := false) -> void:
    	shields.add(id, amount * (1.0 + stats.heal_shield_power), seconds, magic_only)


    ## A hit from an enemy. False when it is refused: Lucian is dead, in stasis
    ## or untouchable, or a spell shield blocks it. Armor or magic resist lower
    ## it, item passives react, then the shields and HP take it.
    func take_damage(info: DamageInfo) -> bool:
    	if dead or invulnerable or in_stasis():
    		return false
    	var amount := DamageCalc.mitigate(info.amount, info.type, stats.armor, stats.mr, info.armor_pen, info.magic_pen)
    	damage_received.emit(info, amount)
    	lose_hp(amount, info.type)
    	_flash_hurt()
    	return true


    ## HP lost through the shields; Lucian dies at 0.
    func lose_hp(amount: float, type: DamageInfo.Type) -> void:
    	if dead or in_stasis():
    		return
    	hp -= shields.absorb(amount, type)
    	if hp <= 0.0:
    		hp = 0.0
    		_die()


    ## Skip between waves: the HP and mana regen of `seconds`, at once.
    func restore_for(seconds: float) -> void:
    	if dead:
    		return
    	hp = minf(hp + stats.hp_regen * seconds, stats.max_hp)
    	mana = minf(mana + stats.mana_regen * seconds, stats.max_mana)


    ## Forced movement (Thresh's hook, Flay): Lucian slides to `to` and can't
    ## move, attack or cast until he lands. Walls stop him. Drops his orders,
    ## windup and queued cast, and stops R. No trail, no Energize.
    func displace(to: Vector2, speed: float) -> void:
    	if dead or in_stasis():
    		return
    	var offset := to - global_position
    	_cancel_windup()
    	_order = Order.NONE
    	_queued_slot = -1
    	_cast_lock_left = 0.0
    	(skills[ChampionProgress.Slot.R] as TheCulling).stop()
    	_displace_velocity = offset.normalized() * speed if offset.length() > 1.0 else Vector2.ZERO
    	_displace_left = offset.length() / speed
    	collision_mask = Layers.WORLD
    	move_dropped.emit()


    func is_displaced() -> bool:
    	return _displace_left > 0.0


    ## Guardian Angel: `seconds` of stasis, then back with these HP and mana.
    func enter_stasis(seconds: float, revive_hp: float, revive_mana: float) -> void:
    	_stasis_left = seconds
    	_revive = Vector2(revive_hp, revive_mana)
    	hp = 0.0
    	_order = Order.NONE
    	_cancel_windup()
    	visuals.modulate = STASIS_TINT


    func in_stasis() -> bool:
    	return _stasis_left > 0.0


    ## Lucian can take orders and cast.
    func can_act() -> bool:
    	return not dead and not in_stasis() and not is_displaced()


    ## Armor above what his level alone gives (Thornmail).
    func bonus_armor() -> float:
    	return maxf(stats.armor - base_stats.at_level(progress.level).armor, 0.0)


    func _die() -> void:
    	dead = true
    	_order = Order.NONE
    	_cancel_windup()
    	_displace_left = 0.0
    	collision_layer = 0
    	(skills[ChampionProgress.Slot.R] as TheCulling).stop()
    	visuals.modulate = Color(0.55, 0.55, 0.55)
    	create_tween().tween_property(visuals, "modulate:a", 0.0, DEATH_FADE)
    	died.emit()


    func _flash_hurt() -> void:
    	if dead or in_stasis():
    		return
    	visuals.modulate = HURT_FLASH
    	create_tween().tween_property(visuals, "modulate", Color.WHITE, 0.2)


    func _displace_step(delta: float) -> void:
    	velocity = _displace_velocity * minf(delta, _displace_left) / delta
    	move_and_slide()
    	velocity = Vector2.ZERO
    	_displace_left -= delta
    	if _displace_left <= 0.0 or get_slide_collision_count() > 0:
    		_displace_left = 0.0
    		collision_mask = _body_mask()
    ```
    - `_physics_process` begins:
    ```gdscript
    func _physics_process(delta: float) -> void:
    	if dead:
    		return
    	if _stasis_left > 0.0:
    		_stasis_left -= delta
    		if _stasis_left <= 0.0:
    			hp = _revive.x
    			mana = _revive.y
    			visuals.modulate = Color.WHITE
    		return
    	hp = minf(hp + stats.hp_regen * delta, stats.max_hp)
    	…  # as before, up to `velocity = Vector2.ZERO`
    	if _displace_left > 0.0:
    		_displace_step(delta)
    		_last_position = global_position
    		return
    	…  # queued cast, dash, cast lock, windup, orders: as before
    ```
    - Item and shield timers (`_tick_buffs`) run before the displacement check, as today.
    - In `_refresh_stats`, the HP floor `1.0` becomes `0.0 if dead or in_stasis() else 1.0`, in both branches.
    - `try_cast`, `use_equip_slot` and `use_summoner` return `false` at once `if not can_act()`.
    - `next_gun()` returns `LucianVisuals.Gun.LEFT` when `one_gun` is set, and doesn't alternate.
  - `LucianController._unhandled_input`: first line `if not lucian.can_act(): return`. In `_physics_process`, `_move_held = false` while it can't act.
  - `FloatingNumber.setup(amount, type, is_crit, size_scale := 1.0)` multiplies the font size by `size_scale`. `DamageNumberSpawner.spawn(info, final_amount, unit, size_scale := 1.0)` passes it on.
  - `Sfx._generate`: add `&"hurt"`, `&"hook"` and `&"shell"`:
    ```gdscript
    		&"hurt":
    			samples = _tone(0.12, 220.0, 120.0, 0.4, 0.6, 18.0)
    		&"hook":
    			samples = _tone(0.25, 700.0, 250.0, 0.7, 0.3, 6.0, 40.0)
    		&"shell":
    			samples = _tone(0.3, 140.0, 50.0, 0.9, 0.2, 7.0)
    ```
    `Lucian._flash_hurt` plays `Sfx.play(&"hurt", -8.0)`.
- [ ] **Step 4:** Run both files and the full suite → PASS. `test_summoner_spells`, `test_item_passives` and `test_tooltips` must still pass through the `shield` / `barrier` properties.
- [ ] **Step 5:** Commit `"Lucian takes damage: shields in order, displacement, stasis and death"`.

---

### Task 3: The 7 defensive items

**Files:**
- Modify: `src/lucian/items/item_passives.gd`, `src/lucian/items/item_actives.gd`, `src/lucian/lucian.gd` (`take_damage`, `lose_hp`), `src/core/restore_over_time.gd`.
- Test: `tests/unit/test_item_defense.gd`.

**Interfaces — Consumes:** Task 2's `take_damage`, `lose_hp`, `add_shield`, `enter_stasis`, `bonus_armor`, `shields`, `item_cooldown(id)`. **Produces:**
- `ItemPassives` hooks:
  - `before_damage_taken(info) -> bool` (false = blocked).
  - `delay_damage(amount) -> float` (what lands now).
  - `before_hp_loss(amount)`, `on_damage_taken(info, amount)`, `on_lethal() -> bool`, `on_kill()`, `on_enemy_slowed()`.
- `RestoreOverTime.start_amount(id, hp, mana, seconds)`.

**Numbers** (constants at the top of `ItemPassives`, from `docs/items.md`):

| Constant | Value |
|---|---|
| `ANNUL_COOLDOWN` | 40.0 |
| `THORNS_BASE`, `THORNS_BONUS_ARMOR` | 20.0, 0.1 |
| `LIFELINE_HP`, `LIFELINE_MIN`, `LIFELINE_MAX`, `LIFELINE_TIME`, `LIFELINE_COOLDOWN` | 0.3, 300.0, 650.0, 3.0, 90.0 |
| `IGNORE_PAIN`, `IGNORE_PAIN_TIME`, `DEFY_HEAL`, `DEFY_TIME` | 0.3, 3.0, 0.15, 2.0 |
| `EVERLASTING_BASE`, `EVERLASTING_MANA`, `EVERLASTING_TIME`, `EVERLASTING_COOLDOWN` | 100.0, 0.05, 3.0, 8.0 |
| `REBIRTH_STASIS`, `REBIRTH_HP` (of base HP), `REBIRTH_MANA`, `REBIRTH_COOLDOWN` | 4.0, 0.5, 0.3, 300.0 |
| `MAGEBANE_WAIT`, `MAGEBANE_SHIELD` | 15.0, 0.15 |

- [ ] **Step 1: Failing tests** (`test_item_defense.gd`). An attacker is a plain `Enemy` with `max_hp = 5000`. Hits are `DamageInfo.create(amount, type, &"basic", attacker)`.
  ```gdscript
  extends GutTest

  var lucian: Lucian
  var attacker: Enemy


  func before_each() -> void:
  	lucian = load("res://src/lucian/lucian.tscn").instantiate()
  	add_child_autofree(lucian)
  	attacker = Enemy.new()
  	attacker.max_hp = 5000.0
  	attacker.position = Vector2(100, 0)
  	add_child_autofree(attacker)


  func _equip(id: StringName) -> void:
  	lucian.inventory.put(Inventory.EQUIP_START, lucian.item_catalog.find(id))


  func _hit(amount: float, type := DamageInfo.Type.TRUE, from_skill := false) -> DamageInfo:
  	var info := DamageInfo.create(amount, type, &"basic", attacker)
  	info.from_skill = from_skill
  	return info


  func test_banshees_blocks_one_skill_then_waits_40_s() -> void:
  	_equip(&"banshees_veil")
  	var before := lucian.hp
  	assert_false(lucian.take_damage(_hit(100.0, DamageInfo.Type.TRUE, true)))
  	assert_eq(lucian.hp, before)
  	assert_true(lucian.take_damage(_hit(100.0, DamageInfo.Type.TRUE, true)))
  	assert_almost_eq(lucian.item_cooldown(&"banshees_veil").remaining, ItemPassives.ANNUL_COOLDOWN, 0.01)


  func test_banshees_lets_basic_attacks_through() -> void:
  	_equip(&"banshees_veil")
  	assert_true(lucian.take_damage(_hit(10.0)))


  func test_thornmail_hurts_and_wounds_a_basic_attacker() -> void:
  	_equip(&"thornmail")
  	lucian.take_damage(_hit(10.0))
  	assert_lt(attacker.hp, attacker.max_hp)
  	assert_true(attacker.has_status(Enemy.GRIEVOUS_WOUNDS))


  func test_shieldbow_shields_before_dropping_under_30_percent() -> void:
  	_equip(&"immortal_shieldbow")
  	lucian.hp = lucian.stats.max_hp * 0.35
  	var before := lucian.hp
  	# Would leave 25%: Lifeline (300+) comes first and takes the whole hit.
  	lucian.take_damage(_hit(lucian.stats.max_hp * 0.1))
  	assert_almost_eq(lucian.hp, before, 0.01)
  	assert_true(lucian.shields.has(&"lifeline"))
  	assert_false(lucian.item_cooldown(&"immortal_shieldbow").is_ready())


  func test_deaths_dance_delays_30_percent() -> void:
  	_equip(&"deaths_dance")
  	var before := lucian.hp
  	lucian.take_damage(_hit(100.0))
  	assert_almost_eq(before - lucian.hp, 70.0, 0.5)
  	await wait_seconds(ItemPassives.IGNORE_PAIN_TIME + 0.2)
  	assert_almost_eq(before - lucian.hp, 100.0 - lucian.stats.hp_regen * (ItemPassives.IGNORE_PAIN_TIME + 0.2), 3.0)


  func test_deaths_dance_kill_clears_the_bleed() -> void:
  	_equip(&"deaths_dance")
  	lucian.take_damage(_hit(100.0))
  	lucian.passives.on_kill()
  	var after_kill := lucian.hp
  	await wait_seconds(0.5)
  	assert_gte(lucian.hp, after_kill)


  func test_fimbulwinter_shields_on_a_slow() -> void:
  	_equip(&"fimbulwinter")
  	lucian.passives.on_enemy_slowed()
  	assert_true(lucian.shields.has(&"everlasting"))
  	lucian.shields.clear()
  	lucian.passives.on_enemy_slowed()
  	assert_false(lucian.shields.has(&"everlasting"), "8 s cooldown")


  func test_guardian_angel_holds_him_then_revives() -> void:
  	_equip(&"guardian_angel")
  	watch_signals(lucian)
  	lucian.take_damage(_hit(99999.0))
  	assert_signal_not_emitted(lucian, "died")
  	assert_true(lucian.in_stasis())
  	assert_false(lucian.take_damage(_hit(10.0)))
  	await wait_seconds(ItemPassives.REBIRTH_STASIS + 0.2)
  	assert_false(lucian.in_stasis())
  	assert_almost_eq(lucian.hp, lucian.base_stats.at_level(1).max_hp * ItemPassives.REBIRTH_HP, 5.0)
  	lucian.take_damage(_hit(99999.0))
  	assert_signal_emitted(lucian, "died")


  func test_kaenic_rookern_shields_after_15_quiet_seconds() -> void:
  	_equip(&"kaenic_rookern")
  	lucian.passives._magebane_wait = ItemPassives.MAGEBANE_WAIT - 0.05
  	await wait_physics_frames(6)
  	assert_true(lucian.shields.has(&"magebane"))
  	var before := lucian.hp
  	lucian.take_damage(_hit(30.0, DamageInfo.Type.PHYSICAL))
  	assert_lt(lucian.hp, before, "magic only")
  ```
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3: Implement.**
  - `Lucian.take_damage` and `lose_hp` call the hooks:
    ```gdscript
    func take_damage(info: DamageInfo) -> bool:
    	if dead or invulnerable or in_stasis():
    		return false
    	if not passives.before_damage_taken(info):
    		return false
    	var amount := DamageCalc.mitigate(info.amount, info.type, stats.armor, stats.mr, info.armor_pen, info.magic_pen)
    	damage_received.emit(info, amount)
    	lose_hp(passives.delay_damage(amount), info.type)
    	passives.on_damage_taken(info, amount)
    	_flash_hurt()
    	return true


    func lose_hp(amount: float, type: DamageInfo.Type) -> void:
    	if dead or in_stasis():
    		return
    	passives.before_hp_loss(amount)
    	hp -= shields.absorb(amount, type)
    	if hp <= 0.0:
    		hp = 0.0
    		if not passives.on_lethal():
    			_die()
    ```
  - `ItemPassives`:
    - Its doc comment drops the "still tooltip text" sentence. It adds: "Defensive passives react to hits on Lucian: before_damage_taken (Banshee's), delay_damage (Death's Dance), before_hp_loss (Shieldbow), on_damage_taken (Thornmail, Kaenic Rookern), on_lethal (Guardian Angel), on_kill (Death's Dance) and on_enemy_slowed (Fimbulwinter)."
    - New state: `var _bleeds: Array[Dictionary] = []` and `var _magebane_wait := 0.0`.
    ```gdscript
    ## Banshee's Veil: a spell shield blocks the next boss skill, whole.
    func before_damage_taken(info: DamageInfo) -> bool:
    	if info.from_skill and has(&"banshees_veil") and lucian.item_cooldown(&"banshees_veil").is_ready():
    		lucian.item_cooldown(&"banshees_veil").start(0.0 if lucian.cheat_no_cooldowns else ANNUL_COOLDOWN)
    		Sfx.play(&"buff")
    		return false
    	return true


    ## Death's Dance: 30% of the hit is taken over 3 s instead. Returns what
    ## lands now.
    func delay_damage(amount: float) -> float:
    	if not has(&"deaths_dance") or amount <= 0.0:
    		return amount
    	var delayed := amount * IGNORE_PAIN
    	_bleeds.append({"rate": delayed / IGNORE_PAIN_TIME, "left": IGNORE_PAIN_TIME})
    	return amount - delayed


    ## Immortal Shieldbow: a hit that would leave Lucian under 30% HP first
    ## gives him Lifeline (300 at level 1 to 650 at 18).
    func before_hp_loss(amount: float) -> void:
    	if not has(&"immortal_shieldbow") or not lucian.item_cooldown(&"immortal_shieldbow").is_ready():
    		return
    	if lucian.hp + lucian.shields.total() - amount >= lucian.stats.max_hp * LIFELINE_HP:
    		return
    	var share := (lucian.progress.level - 1) / float(ChampionProgress.MAX_LEVEL - 1)
    	lucian.add_shield(&"lifeline", lerpf(LIFELINE_MIN, LIFELINE_MAX, share), LIFELINE_TIME)
    	lucian.item_cooldown(&"immortal_shieldbow").start(0.0 if lucian.cheat_no_cooldowns else LIFELINE_COOLDOWN)


    ## Thornmail answers a basic attack; any magic damage resets Kaenic
    ## Rookern's wait. Being hit counts as being in combat.
    func on_damage_taken(info: DamageInfo, _amount: float) -> void:
    	_combat_left = COMBAT_TIME
    	if info.type == DamageInfo.Type.MAGIC:
    		_magebane_wait = 0.0
    	var attacker := info.attacker as Enemy
    	if has(&"thornmail") and info.source == &"basic" and Lucian.is_target(attacker):
    		attacker.take_damage(lucian.make_damage(THORNS_BASE + THORNS_BONUS_ARMOR * lucian.bonus_armor(), DamageInfo.Type.MAGIC, &"thornmail"))
    		attacker.add_status(Enemy.GRIEVOUS_WOUNDS, GRIEVOUS_DURATION, 1, _icon(&"thornmail"))


    ## Guardian Angel: instead of dying, stasis then a revive. True when it saved him.
    func on_lethal() -> bool:
    	if not has(&"guardian_angel") or not lucian.item_cooldown(&"guardian_angel").is_ready():
    		return false
    	lucian.item_cooldown(&"guardian_angel").start(0.0 if lucian.cheat_no_cooldowns else REBIRTH_COOLDOWN)
    	_bleeds.clear()
    	var base_hp := lucian.base_stats.at_level(lucian.progress.level).max_hp
    	lucian.enter_stasis(REBIRTH_STASIS, base_hp * REBIRTH_HP, lucian.stats.max_mana * REBIRTH_MANA)
    	Sfx.play(&"buff")
    	return true


    ## Death's Dance (Defy): a kill clears the delayed damage and heals 15%
    ## max HP over 2 s.
    func on_kill() -> void:
    	if has(&"deaths_dance"):
    		_bleeds.clear()
    		lucian.restores.start_amount(&"deaths_dance", lucian.stats.max_hp * DEFY_HEAL, 0.0, DEFY_TIME)


    ## Fimbulwinter (Everlasting): slowing an enemy shields Lucian.
    func on_enemy_slowed() -> void:
    	if not has(&"fimbulwinter") or not lucian.item_cooldown(&"fimbulwinter").is_ready():
    		return
    	lucian.add_shield(&"everlasting", EVERLASTING_BASE + EVERLASTING_MANA * lucian.stats.max_mana, EVERLASTING_TIME)
    	lucian.item_cooldown(&"fimbulwinter").start(0.0 if lucian.cheat_no_cooldowns else EVERLASTING_COOLDOWN)
    ```
    - At the start of `_physics_process`:
    ```gdscript
    	if not _bleeds.is_empty():
    		var bleed := 0.0
    		for entry in _bleeds:
    			var step := minf(delta, entry.left)
    			bleed += entry.rate * step
    			entry.left -= step
    		_bleeds.assign(_bleeds.filter(func(entry: Dictionary) -> bool: return entry.left > 0.0))
    		lucian.lose_hp(bleed, DamageInfo.Type.TRUE)
    	if has(&"kaenic_rookern"):
    		if not lucian.shields.has(&"magebane"):
    			_magebane_wait += delta
    			if _magebane_wait >= MAGEBANE_WAIT:
    				lucian.add_shield(&"magebane", lucian.stats.max_hp * MAGEBANE_SHIELD, 0.0, true)
    	elif lucian.shields.has(&"magebane"):
    		lucian.shields.remove(&"magebane")
    		_magebane_wait = 0.0
    ```
    - `refresh()`: without Death's Dance, `_bleeds.clear()`. Without Kaenic Rookern, `_magebane_wait = 0.0`.
    - `buffs()` adds:
      - "Annul" (`banshees_veil` icon), ready, while the spell shield is up.
      - "Magebane" (`kaenic_rookern` icon) with its amount while the shield is up. While waiting, `left`/`duration` show the time left (`MAGEBANE_WAIT - _magebane_wait`).
      - "Lifeline" and "Everlasting" with their amounts and timers from `lucian.shields`.
  - `ItemActives._gunblade`: after `add_status(Enemy.SLOW, …)`, call `lucian.passives.on_enemy_slowed()`.
  - `RestoreOverTime`: `start(potion)` calls a new `start_amount(id, hp, mana, seconds)`, which holds today's body. A Defy heal shows in no buff icon, since `buffs()` lists potions only.
- [ ] **Step 4:** Run the file and the full suite → PASS.
- [ ] **Step 5:** Commit `"Defensive items work: Banshee's, Thornmail, Shieldbow, Death's Dance, Fimbulwinter, Guardian Angel, Kaenic Rookern"`.

---

### Task 4: Ground warnings, enemy projectiles, minions (+ art)

**Files:**
- Create: `src/combat/ground_warning.gd`, `src/combat/enemy_projectile.gd`, `src/core/enemy_data.gd`, `src/enemies/enemy_unit.gd`, `src/enemies/minion.gd`.
- Data: `data/enemies/{melee,ranged,siege,super}_minion.tres`.
- Art: `assets/art/enemies/{melee,ranged,siege,super}_minion.svg`, `assets/art/ui/status_empower.svg`.
- Modify: `src/enemies/enemy_health_bar.gd` (`badge`), `src/stage/stage.tscn` (a `Warnings` Node2D right after `Arena`, before `World`, so warnings are drawn under the units).
- Test: `tests/unit/test_ground_warning.gd`, `tests/unit/test_enemy_data_files.gd`, `tests/unit/test_minions.gd`.

**Interfaces — Produces:**
- `EnemyData`:
  - The table's fields, as exports: `id`, `display_name`, `kind`, `behavior`, `art`, `max_hp`, `armor`, `mr`, `damage`, `damage_type`, `attack_range`, `attack_interval`, `move_speed`, `radius`, `gold`, `xp`, `keep_min`, `keep_max`, `projectile_speed`, `area_radius`, `warn_time`, `empower_radius`, `purple_first`, `purple_repeat`.
  - `hp_scale(act, wave)`, `damage_scale(act, wave)`, `reward_scale(act)`.
- `GroundWarning`:
  - Builders: `circle(at, radius, seconds)`, `line(from, toward, length, width, seconds)`, `cone(from, toward, length, angle, seconds)`, `lock(from, onto, seconds)`.
  - `strike(hit, victim)`, `covers(point, radius) -> bool`, `progress()`, `sound`, `signal fired`.
  - Static hit tests: `in_circle`, `in_line`, `in_cone`.
- `EnemyProjectile`: `launch(from, toward, hit, foe)`, `speed`, `max_range`, `hit_radius`, `color`, `return_to`, `tether`, `signal hit_lucian`.
- `EnemyUnit`:
  - `setup(data, act, wave, foe)`, `data`, `target`, `damage`, `attack_range`, `move_speed`, `projectile_parent`, `warning_parent`, `visuals`, `health_bar`.
  - `can_fight()`, `distance_to_target()`, `walk_toward(point, delta)`, `face(point)`, `current_speed()`, `make_hit(amount := -1.0, source := &"basic")`.
  - `fire_bolt(hit, speed, reach, toward := Vector2.ZERO) -> EnemyProjectile`.
  - Constants: `EMPOWER`, `EMPOWER_BONUS`, `SLOW_AMOUNT`.
  - Overridables: `_think(delta)`, `_attack()`.
- `Minion extends EnemyUnit`.
- `EnemyHealthBar.badge`.

- [ ] **Step 1: Failing tests.**
  - `test_ground_warning.gd`:
    ```gdscript
    extends GutTest


    func test_a_line_covers_points_along_it_only() -> void:
    	assert_true(GroundWarning.in_line(Vector2.ZERO, Vector2.RIGHT, 1000.0, 70.0, Vector2(600, 30)))
    	assert_false(GroundWarning.in_line(Vector2.ZERO, Vector2.RIGHT, 1000.0, 70.0, Vector2(600, 80)))
    	assert_true(GroundWarning.in_line(Vector2.ZERO, Vector2.RIGHT, 1000.0, 70.0, Vector2(600, 60), 30.0))
    	assert_false(GroundWarning.in_line(Vector2.ZERO, Vector2.RIGHT, 1000.0, 70.0, Vector2(-100, 0)))


    func test_a_cone_covers_its_angle_and_length() -> void:
    	var wide := deg_to_rad(70.0)
    	assert_true(GroundWarning.in_cone(Vector2.ZERO, Vector2.RIGHT, 400.0, wide, Vector2(300, 100)))
    	assert_false(GroundWarning.in_cone(Vector2.ZERO, Vector2.RIGHT, 400.0, wide, Vector2(100, 300)))
    	assert_false(GroundWarning.in_cone(Vector2.ZERO, Vector2.RIGHT, 400.0, wide, Vector2(500, 0)))


    func test_it_fires_once_after_its_time_and_goes() -> void:
    	var warning := GroundWarning.circle(Vector2.ZERO, 100.0, 0.3)
    	add_child(warning)
    	watch_signals(warning)
    	await wait_seconds(0.2)
    	assert_signal_not_emitted(warning, "fired")
    	await wait_seconds(0.2)
    	assert_signal_emit_count(warning, "fired", 1)
    	assert_false(is_instance_valid(warning))
    ```
  - `test_enemy_data_files.gd`:
    - Each of `melee_minion`, `ranged_minion`, `siege_minion` and `super_minion` loads, has an `id` equal to its file name, has `art`, and has a `kind` in `[&"normal", &"elite", &"boss"]`.
    - Then:
      - `ranged_minion`: `damage_type == DamageInfo.Type.MAGIC`, and `keep_min < keep_max <= attack_range`.
      - `siege_minion`: `area_radius == 110` and `warn_time == 1.0`.
      - `super_minion`: `empower_radius == 500`.
    - Tasks 10 and 11 add `thresh_1` and `akshan` to the list.
  - `test_minions.gd`:
    ```gdscript
    extends GutTest

    var lucian: Lucian


    func before_each() -> void:
    	lucian = load("res://src/lucian/lucian.tscn").instantiate()
    	add_child_autofree(lucian)


    func _minion(id: String, at: Vector2, act := 1, wave := 1) -> Minion:
    	var minion := Minion.new()
    	minion.setup(load("res://data/enemies/%s.tres" % id), act, wave, lucian)
    	minion.position = at
    	add_child_autofree(minion)
    	return minion


    func _wall(at: Vector2) -> void:
    	var wall := StaticBody2D.new()
    	wall.collision_layer = Layers.WORLD
    	var shape := CollisionShape2D.new()
    	var box := RectangleShape2D.new()
    	box.size = Vector2(40, 400)
    	shape.shape = box
    	wall.position = at
    	wall.add_child(shape)
    	add_child_autofree(wall)


    func test_a_melee_minion_walks_up_and_hits() -> void:
    	var minion := _minion("melee_minion", Vector2(500, 0))
    	var before := lucian.hp
    	await wait_seconds(2.5)
    	assert_lt(minion.global_position.x, 200.0)
    	assert_lt(lucian.hp, before)


    func test_a_ranged_minion_keeps_its_distance() -> void:
    	var minion := _minion("ranged_minion", Vector2(200, 0))
    	await wait_seconds(1.5)
    	assert_between(minion.global_position.distance_to(lucian.global_position), 400.0, 560.0)


    func test_a_bolt_is_stopped_by_a_wall() -> void:
    	_wall(Vector2(200, 0))
    	await wait_physics_frames(1)
    	var bolt := EnemyProjectile.new()
    	bolt.launch(Vector2(500, 0), Vector2.LEFT, DamageInfo.create(50.0, DamageInfo.Type.MAGIC, &"basic"), lucian)
    	add_child(bolt)
    	var before := lucian.hp
    	await wait_seconds(1.3)
    	assert_gte(lucian.hp, before)
    	assert_false(is_instance_valid(bolt))


    func test_the_shell_lands_after_its_warning_inside_the_circle() -> void:
    	var warning := GroundWarning.circle(Vector2.ZERO, 110.0, 1.0)
    	warning.strike(DamageInfo.create(40.0, DamageInfo.Type.TRUE, &"basic"), lucian)
    	add_child(warning)
    	var before := lucian.hp
    	await wait_seconds(0.5)
    	assert_gte(lucian.hp, before)
    	await wait_seconds(0.7)
    	assert_lt(lucian.hp, before)


    func test_stepping_out_of_the_circle_dodges_the_shell() -> void:
    	var warning := GroundWarning.circle(Vector2.ZERO, 110.0, 1.0)
    	warning.strike(DamageInfo.create(40.0, DamageInfo.Type.TRUE, &"basic"), lucian)
    	add_child(warning)
    	lucian.global_position = Vector2(300, 0)
    	var before := lucian.hp
    	await wait_seconds(1.2)
    	assert_gte(lucian.hp, before)


    func test_empower_reaches_small_minions_not_elites() -> void:
    	_minion("super_minion", Vector2(1500, 0))
    	var melee := _minion("melee_minion", Vector2(1700, 0))
    	var siege := _minion("siege_minion", Vector2(1500, 300))
    	await wait_physics_frames(3)
    	assert_true(melee.has_status(EnemyUnit.EMPOWER))
    	assert_false(siege.has_status(EnemyUnit.EMPOWER))
    	assert_almost_eq(melee.make_hit().amount, melee.damage * (1.0 + EnemyUnit.EMPOWER_BONUS), 0.01)


    func test_a_slow_cuts_move_speed() -> void:
    	var minion := _minion("melee_minion", Vector2(2000, 0))
    	minion.add_status(Enemy.SLOW, 2.0)
    	assert_almost_eq(minion.current_speed(), minion.move_speed * (1.0 - EnemyUnit.SLOW_AMOUNT), 0.01)


    func test_numbers_scale_with_act_and_wave() -> void:
    	var minion := _minion("melee_minion", Vector2(2000, 0), 2, 3)
    	assert_almost_eq(minion.max_hp, 240.0 * 1.6 * 1.3, 0.01)
    	assert_almost_eq(minion.damage, 12.0 * 1.25 * 1.3, 0.01)


    func test_minions_stand_still_while_lucian_is_untouchable() -> void:
    	lucian.invulnerable = true
    	var minion := _minion("melee_minion", Vector2(500, 0))
    	await wait_seconds(0.5)
    	assert_almost_eq(minion.global_position.x, 500.0, 1.0)


    func test_a_killed_minion_is_hit_no_more() -> void:
    	var minion := _minion("melee_minion", Vector2(500, 0))
    	minion.take_damage(lucian.make_damage(9999.0, DamageInfo.Type.TRUE, &"q"))
    	await wait_physics_frames(2)
    	var shape := CircleShape2D.new()
    	shape.radius = 50.0
    	assert_false(lucian.query_enemies(shape, Transform2D(0.0, minion.global_position)).has(minion))
    ```
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3: Implement.**
  - `EnemyData`:
    ```gdscript
    class_name EnemyData
    extends Resource
    ## One enemy type, with its numbers at Act 1, wave 1. EnemyUnit scales them
    ## by act and wave; bosses never scale.

    ## HP, damage and reward growth per act after the first; HP and damage
    ## growth per wave after the first.
    const ACT_HP := 0.6
    const ACT_DAMAGE := 0.25
    const ACT_REWARD := 0.25
    const WAVE_GROWTH := 0.15

    @export var id: StringName
    @export var display_name := ""
    ## &"normal", &"elite" or &"boss".
    @export var kind := &"normal"
    ## How it fights: &"melee", &"ranged", &"siege", &"super", or a boss id.
    @export var behavior := &"melee"
    @export var art: Texture2D
    @export var max_hp := 100.0
    @export var armor := 0.0
    @export var mr := 0.0
    ## One basic attack's damage, and its type.
    @export var damage := 10.0
    @export var damage_type := DamageInfo.Type.PHYSICAL
    @export var attack_range := 110.0
    ## Seconds between attacks.
    @export var attack_interval := 1.25
    @export var move_speed := 300.0
    ## Body and click size.
    @export var radius := 28.0
    @export var gold := 0
    @export var xp := 0
    ## Ranged: the distance band it keeps from Lucian, and its bolt's speed.
    @export var keep_min := 0.0
    @export var keep_max := 0.0
    @export var projectile_speed := 0.0
    ## Siege: the shell's circle and its warning.
    @export var area_radius := 0.0
    @export var warn_time := 0.0
    ## Super: how far Empower reaches.
    @export var empower_radius := 0.0
    ## Bosses: purple essence the first time, and on every later clear.
    @export var purple_first := 0
    @export var purple_repeat := 0


    func hp_scale(act: int, wave: int) -> float:
    	if kind == &"boss":
    		return 1.0
    	return (1.0 + ACT_HP * (act - 1)) * (1.0 + WAVE_GROWTH * (wave - 1))


    func damage_scale(act: int, wave: int) -> float:
    	if kind == &"boss":
    		return 1.0
    	return (1.0 + ACT_DAMAGE * (act - 1)) * (1.0 + WAVE_GROWTH * (wave - 1))


    func reward_scale(act: int) -> float:
    	return 1.0 if kind == &"boss" else 1.0 + ACT_REWARD * (act - 1)
    ```
  - `data/enemies/melee_minion.tres` is below. The other three follow the enemy table:
    - `ranged_minion` adds `damage_type = 1`, `keep_min = 420.0`, `keep_max = 550.0` and `projectile_speed = 450.0`.
    - `siege_minion` adds `area_radius = 110.0` and `warn_time = 1.0`.
    - `super_minion` adds `empower_radius = 500.0`.
    ```
    [gd_resource type="Resource" script_class="EnemyData" format=3]

    [ext_resource type="Script" path="res://src/core/enemy_data.gd" id="1_data"]
    [ext_resource type="Texture2D" path="res://assets/art/enemies/melee_minion.svg" id="2_art"]

    [resource]
    script = ExtResource("1_data")
    id = &"melee_minion"
    display_name = "Melee Minion"
    kind = &"normal"
    behavior = &"melee"
    art = ExtResource("2_art")
    max_hp = 240.0
    armor = 10.0
    damage = 12.0
    attack_range = 110.0
    attack_interval = 1.25
    move_speed = 300.0
    radius = 28.0
    gold = 60
    xp = 30
    ```
  - `GroundWarning`:
    ```gdscript
    class_name GroundWarning
    extends Node2D
    ## A red mark on the ground before an enemy attack lands: a circle, a line
    ## (from the origin along `direction`), a cone, or a lock line that follows
    ## a node. Its fill grows over `warn_time`; then `fired` and it goes. With
    ## a strike set, Lucian takes the hit if he is inside when it fires.

    signal fired

    enum Shape { CIRCLE, LINE, CONE, LOCK }

    const EDGE := Color(1.0, 0.25, 0.2, 0.9)
    const FILL := Color(1.0, 0.2, 0.15, 0.3)

    var shape := Shape.CIRCLE
    ## The circle's radius, or the line's or cone's length.
    var reach := 100.0
    var width := 60.0
    ## The cone's angle, in radians.
    var spread := deg_to_rad(70.0)
    var direction := Vector2.RIGHT
    var warn_time := 1.0
    ## LOCK: the node the line points at.
    var follow: Node2D
    ## Played when it fires (&"" for none).
    var sound := &""

    var _elapsed := 0.0
    var _hit: DamageInfo
    var _victim: Lucian


    static func circle(at: Vector2, radius: float, seconds: float) -> GroundWarning:
    	var warning := GroundWarning.new()
    	warning.position = at
    	warning.reach = radius
    	warning.warn_time = seconds
    	return warning


    static func line(from: Vector2, toward: Vector2, length: float, line_width: float, seconds: float) -> GroundWarning:
    	var warning := GroundWarning.new()
    	warning.shape = Shape.LINE
    	warning.position = from
    	warning.direction = toward.normalized()
    	warning.reach = length
    	warning.width = line_width
    	warning.warn_time = seconds
    	return warning


    static func cone(from: Vector2, toward: Vector2, length: float, angle: float, seconds: float) -> GroundWarning:
    	var warning := GroundWarning.new()
    	warning.shape = Shape.CONE
    	warning.position = from
    	warning.direction = toward.normalized()
    	warning.reach = length
    	warning.spread = angle
    	warning.warn_time = seconds
    	return warning


    ## A thin line from `from` that keeps pointing at `onto` (Comeuppance).
    static func lock(from: Vector2, onto: Node2D, seconds: float) -> GroundWarning:
    	var warning := GroundWarning.new()
    	warning.shape = Shape.LOCK
    	warning.position = from
    	warning.follow = onto
    	warning.width = 8.0
    	warning.warn_time = seconds
    	return warning


    ## Lucian takes `hit` if he is inside when the warning fires.
    func strike(hit: DamageInfo, victim: Lucian) -> void:
    	_hit = hit
    	_victim = victim


    ## How far the warning has filled, 0 to 1.
    func progress() -> float:
    	return clampf(_elapsed / warn_time, 0.0, 1.0) if warn_time > 0.0 else 1.0


    ## A body of `radius` at `point` is inside.
    func covers(point: Vector2, radius := 0.0) -> bool:
    	match shape:
    		Shape.CIRCLE:
    			return in_circle(global_position, reach, point, radius)
    		Shape.LINE:
    			return in_line(global_position, direction, reach, width, point, radius)
    		Shape.CONE:
    			return in_cone(global_position, direction, reach, spread, point, radius)
    	return false


    func _physics_process(delta: float) -> void:
    	_elapsed += delta
    	if shape == Shape.LOCK and is_instance_valid(follow):
    		direction = global_position.direction_to(follow.global_position)
    		reach = global_position.distance_to(follow.global_position)
    	queue_redraw()
    	if _elapsed < warn_time:
    		return
    	if _hit and is_instance_valid(_victim) and covers(_victim.global_position, Lucian.HIT_RADIUS):
    		_victim.take_damage(_hit)
    	if sound != &"":
    		Sfx.play(sound)
    	fired.emit()
    	queue_free()


    static func in_circle(center: Vector2, radius: float, point: Vector2, point_radius := 0.0) -> bool:
    	return center.distance_to(point) <= radius + point_radius


    static func in_line(from: Vector2, toward: Vector2, length: float, line_width: float, point: Vector2, point_radius := 0.0) -> bool:
    	var local := (point - from).rotated(-toward.angle())
    	return local.x >= -point_radius and local.x <= length + point_radius and absf(local.y) <= line_width * 0.5 + point_radius


    static func in_cone(from: Vector2, toward: Vector2, length: float, angle: float, point: Vector2, point_radius := 0.0) -> bool:
    	var offset := point - from
    	if offset.length() > length + point_radius:
    		return false
    	return offset.length() <= point_radius or absf(toward.angle_to(offset)) <= angle * 0.5


    func _draw() -> void:
    	var fill := Color(FILL, FILL.a * (0.4 + 0.6 * progress()))
    	match shape:
    		Shape.CIRCLE:
    			draw_circle(Vector2.ZERO, reach * progress(), fill)
    			draw_arc(Vector2.ZERO, reach, 0.0, TAU, 64, EDGE, 3.0, true)
    		Shape.LINE, Shape.LOCK:
    			draw_set_transform(Vector2.ZERO, direction.angle())
    			draw_rect(Rect2(0.0, -width * 0.5, reach * progress(), width), fill)
    			draw_rect(Rect2(0.0, -width * 0.5, reach, width), EDGE, false, 3.0 if shape == Shape.LINE else 2.0)
    			draw_set_transform(Vector2.ZERO, 0.0)
    		Shape.CONE:
    			var points := PackedVector2Array([Vector2.ZERO])
    			for i in 17:
    				points.append(Vector2.from_angle(direction.angle() - spread * 0.5 + spread * i / 16.0) * reach)
    			draw_colored_polygon(points, fill)
    			points.append(Vector2.ZERO)
    			draw_polyline(points, EDGE, 3.0, true)
    ```
  - `EnemyProjectile`:
    ```gdscript
    class_name EnemyProjectile
    extends Area2D
    ## An enemy's shot: flies straight, hits Lucian once (by distance) and stops
    ## on a wall or pillar. A boomerang flies `max_range` out, then back to its
    ## thrower, and may hit once each way.

    ## The shot hit Lucian and he took it (not blocked).
    signal hit_lucian

    var info: DamageInfo
    var target: Lucian
    var direction := Vector2.RIGHT
    var speed := 450.0
    var max_range := 600.0
    var hit_radius := 12.0
    var color := Color("c47cff")
    ## Boomerang: flies back to this node after max_range.
    var return_to: Node2D
    ## Draws a chain back to this node (Thresh's hook).
    var tether: Node2D

    var _travelled := 0.0
    var _returning := false
    var _hit_this_pass := false


    func launch(from: Vector2, toward: Vector2, hit: DamageInfo, foe: Lucian) -> void:
    	position = from
    	direction = toward.normalized()
    	rotation = direction.angle()
    	info = hit
    	target = foe


    func _ready() -> void:
    	collision_layer = 0
    	collision_mask = Layers.WORLD
    	var shape := CollisionShape2D.new()
    	var circle := CircleShape2D.new()
    	circle.radius = 6.0
    	shape.shape = circle
    	add_child(shape)
    	body_entered.connect(func(_body: Node2D) -> void: queue_free())


    func _physics_process(delta: float) -> void:
    	var step := speed * delta
    	if _returning:
    		if not is_instance_valid(return_to):
    			queue_free()
    			return
    		var offset := return_to.global_position - global_position
    		if offset.length() <= step:
    			queue_free()
    			return
    		direction = offset.normalized()
    	global_position += direction * step
    	rotation = direction.angle()
    	_travelled += step
    	if tether:
    		queue_redraw()
    	if not _hit_this_pass and is_instance_valid(target) and global_position.distance_to(target.global_position) <= hit_radius + Lucian.HIT_RADIUS:
    		_hit_this_pass = true
    		if target.take_damage(info):
    			hit_lucian.emit()
    	if not _returning and _travelled >= max_range:
    		if return_to:
    			_returning = true
    			_hit_this_pass = false
    		else:
    			queue_free()


    func _draw() -> void:
    	if is_instance_valid(tether):
    		draw_line(Vector2.ZERO, to_local(tether.global_position), color, 4.0)
    	draw_circle(Vector2.ZERO, hit_radius, Color(color, 0.35))
    	draw_circle(Vector2.ZERO, hit_radius * 0.55, color)
    ```
  - `EnemyUnit`:
    ```gdscript
    class_name EnemyUnit
    extends Enemy
    ## A fighting enemy built in code from an EnemyData: body, hurtbox, art and
    ## health bar. It walks at Lucian (sliding along walls, sidestepping when
    ## stuck), attacks when in range, and stands still while he is dead or
    ## can't be hit. Subclasses say what an attack does (_attack), and may
    ## think differently (_think).

    const HIT_FLASH := Color(1.8, 1.8, 1.8)
    ## Moving less than this share of its speed in a frame counts as stuck.
    const STUCK_SHARE := 0.25
    const STUCK_TIME := 0.4
    ## Gunblade's slow.
    const SLOW_AMOUNT := 0.4
    const ELITE_BAR := Vector2(110, 12)
    const BOSS_BAR := Vector2(140, 14)
    ## A super minion's Empower on the minions around it: +15% damage.
    const EMPOWER := &"empower"
    const EMPOWER_BONUS := 0.15
    const EMPOWER_ICON := preload("res://assets/art/ui/status_empower.svg")

    var data: EnemyData
    var target: Lucian
    ## This unit's numbers, after the act and wave scaling.
    var damage := 0.0
    var attack_range := 0.0
    var move_speed := 0.0
    ## Where shots and ground warnings go; the parent when not set.
    var projectile_parent: Node
    var warning_parent: Node
    var visuals := Node2D.new()
    var health_bar := EnemyHealthBar.new()

    var _attack_left := 0.0
    var _stuck_left := 0.0
    var _sidestep := 1.0
    var _flash_tween: Tween


    ## Call before adding the unit to the tree.
    func setup(enemy_data: EnemyData, act: int, wave: int, foe: Lucian) -> void:
    	data = enemy_data
    	target = foe
    	max_hp = data.max_hp * data.hp_scale(act, wave)
    	armor = data.armor
    	mr = data.mr
    	radius = data.radius
    	damage = data.damage * data.damage_scale(act, wave)
    	attack_range = data.attack_range
    	move_speed = data.move_speed


    func _ready() -> void:
    	super()
    	collision_layer = Layers.ENEMY_BODY
    	collision_mask = Layers.WORLD | Layers.ENEMY_BODY | Layers.PLAYER_BODY
    	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
    	add_child(_circle(data.radius * 0.85))
    	var hurtbox := Hurtbox.new()
    	hurtbox.collision_layer = Layers.ENEMY_HURTBOX
    	hurtbox.collision_mask = 0
    	hurtbox.monitoring = false
    	hurtbox.add_child(_circle(data.radius + 6.0))
    	add_child(hurtbox)
    	add_child(visuals)
    	var sprite := Sprite2D.new()
    	sprite.texture = data.art
    	visuals.add_child(sprite)
    	if data.kind == &"boss":
    		health_bar.size = BOSS_BAR
    	elif data.kind == &"elite":
    		health_bar.size = ELITE_BAR
    		health_bar.badge = true
    	health_bar.position = Vector2(0, -data.radius - 34.0)
    	health_bar.z_index = 10
    	add_child(health_bar)
    	health_bar.set_health(hp, max_hp)
    	if projectile_parent == null:
    		projectile_parent = get_parent()
    	if warning_parent == null:
    		warning_parent = get_parent()
    	_attack_left = randf_range(0.2, data.attack_interval)


    func _physics_process(delta: float) -> void:
    	super(delta)
    	if dead:
    		return
    	_attack_left = maxf(_attack_left - delta, 0.0)
    	if can_fight():
    		_think(delta)


    ## Lucian is there to fight: alive, not in stasis, not untouchable.
    func can_fight() -> bool:
    	return is_instance_valid(target) and not target.dead and not target.invulnerable and not target.in_stasis()


    func distance_to_target() -> float:
    	return global_position.distance_to(target.global_position)


    func current_speed() -> float:
    	return move_speed * (1.0 - SLOW_AMOUNT if has_status(Enemy.SLOW) else 1.0)


    ## A hit from this unit (Empower included): its basic attack by default.
    func make_hit(amount := -1.0, source := &"basic") -> DamageInfo:
    	var dealt := damage if amount < 0.0 else amount
    	if has_status(EMPOWER):
    		dealt *= 1.0 + EMPOWER_BONUS
    	return DamageInfo.create(dealt, data.damage_type, source, self)


    ## A straight shot from this unit, at Lucian unless `toward` is given; walls
    ## stop it.
    func fire_bolt(hit: DamageInfo, speed: float, reach: float, toward := Vector2.ZERO) -> EnemyProjectile:
    	var bolt := EnemyProjectile.new()
    	bolt.launch(global_position, toward if toward != Vector2.ZERO else global_position.direction_to(target.global_position), hit, target)
    	bolt.speed = speed
    	bolt.max_range = reach
    	projectile_parent.add_child(bolt)
    	return bolt


    ## One step toward `point`, sliding along walls. A unit that barely moved
    ## sidesteps for a moment.
    func walk_toward(point: Vector2, delta: float) -> void:
    	var direction := global_position.direction_to(point)
    	if _stuck_left > 0.0:
    		_stuck_left -= delta
    		direction = (direction + direction.orthogonal() * _sidestep).normalized()
    	var before := global_position
    	velocity = direction * current_speed()
    	move_and_slide()
    	velocity = Vector2.ZERO
    	face(global_position + direction)
    	if _stuck_left <= 0.0 and before.distance_to(global_position) < current_speed() * delta * STUCK_SHARE:
    		_stuck_left = STUCK_TIME
    		if randf() < 0.3:
    			_sidestep = -_sidestep


    func face(point: Vector2) -> void:
    	if point != global_position:
    		visuals.rotation = (point - global_position).angle()


    ## Walks into range, then attacks whenever the attack is ready.
    func _think(delta: float) -> void:
    	if distance_to_target() > attack_range + Lucian.HIT_RADIUS:
    		walk_toward(target.global_position, delta)
    		return
    	face(target.global_position)
    	if _attack_left <= 0.0:
    		_attack_left = data.attack_interval
    		_attack()


    ## One attack: by default a hit on Lucian at once (melee).
    func _attack() -> void:
    	target.take_damage(make_hit())


    func _lose_hp(amount: float) -> void:
    	super(amount)
    	health_bar.set_health(hp, max_hp)
    	visuals.modulate = HIT_FLASH
    	if _flash_tween:
    		_flash_tween.kill()
    	_flash_tween = create_tween()
    	_flash_tween.tween_property(visuals, "modulate", Color.WHITE, 0.15)


    func _circle(circle_radius: float) -> CollisionShape2D:
    	var round_shape := CircleShape2D.new()
    	round_shape.radius = circle_radius
    	var shape := CollisionShape2D.new()
    	shape.shape = round_shape
    	return shape
    ```
  - `Minion`:
    ```gdscript
    class_name Minion
    extends EnemyUnit
    ## Minions, by behavior. Melee walks at Lucian and strikes. Ranged keeps its
    ## distance and fires a slow bolt where he stands. Siege marks a circle on
    ## him and its shell lands a second later. Super strikes in melee and
    ## Empowers the small minions around it.

    ## Seconds between Empower pulses, and how long one lasts.
    const EMPOWER_PULSE := 0.25
    const EMPOWER_TIME := 0.5
    ## A bolt flies this far past the minion's range before it fades.
    const BOLT_OVERSHOOT := 150.0

    var _pulse_left := 0.0


    func _physics_process(delta: float) -> void:
    	super(delta)
    	if dead or data.behavior != &"super":
    		return
    	_pulse_left -= delta
    	if _pulse_left <= 0.0:
    		_pulse_left = EMPOWER_PULSE
    		_empower()


    func _think(delta: float) -> void:
    	if data.behavior != &"ranged":
    		super(delta)
    		return
    	var distance := distance_to_target()
    	if distance > data.keep_max:
    		walk_toward(target.global_position, delta)
    	elif distance < data.keep_min:
    		walk_toward(global_position + target.global_position.direction_to(global_position) * 100.0, delta)
    	else:
    		face(target.global_position)
    	if distance <= attack_range + Lucian.HIT_RADIUS and _attack_left <= 0.0:
    		_attack_left = data.attack_interval
    		_attack()


    func _attack() -> void:
    	match data.behavior:
    		&"ranged":
    			fire_bolt(make_hit(), data.projectile_speed, attack_range + BOLT_OVERSHOOT)
    		&"siege":
    			var warning := GroundWarning.circle(target.global_position, data.area_radius, data.warn_time)
    			warning.strike(make_hit(), target)
    			warning.sound = &"shell"
    			warning_parent.add_child(warning)
    		_:
    			super()


    ## Melee and ranged minions within reach deal more damage for a moment.
    func _empower() -> void:
    	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
    		var minion := enemy as Minion
    		if minion and minion != self and minion.data.kind == &"normal" and minion.global_position.distance_to(global_position) <= data.empower_radius:
    			minion.add_status(EMPOWER, EMPOWER_TIME, 1, EMPOWER_ICON)
    ```
  - `EnemyHealthBar`: add `var badge := false` with `## Elites: a small gold diamond at the bar's left end.`. In `_draw`, when `badge` is set, draw a 12 px gold (`UiStyle.GOLD_COLOR`) diamond with a black outline, centered on the bar's left edge.
  - **Art.** The 5 SVGs from the Art table: the house header, facing +X, a transparent background, the `#1a1d24` outline, readable at the size listed. Then run `--import`.
- [ ] **Step 4:** Run the three files, then the full suite → PASS.
- [ ] **Step 5:** Commit `"Minions: melee, ranged, siege (Cannon Shell warning) and super (Empower); enemy projectiles and ground warnings"`.

---

### Task 5: Kill rewards and ground loot

**Files:**
- Create: `src/core/kill_rewards.gd`, `src/core/loot_table.gd`, `src/stage/loot_drop.gd`, `src/combat/floating_text.gd`.
- Modify: `src/core/stage_setup.gd` (bonuses), `src/stage/stage.gd` (`spawn_enemy`, rewards, `collected`), `data/tree/{stage_gold,bonus_xp,essence_drop}.tres` (descriptions).
- Test: `tests/unit/test_kill_rewards.gd`, `tests/unit/test_loot.gd`; extend `tests/unit/test_stage_setup.gd`.

**Interfaces — Produces:**
- `KillRewards.roll(data, act, run, rng) -> Dictionary` with keys `gold`, `xp`, `blue`, `orange`.
- `LootTable.roll(kind, catalog, rng) -> Array[ItemData]`.
- `LootDrop`: `item`, `lucian`, `PICKUP_RANGE`.
- `FloatingText.new(text, color, icon := null)`.
- `StageSetup`: `gold_bonus`, `xp_bonus`, `essence_bonus`.
- `Stage`:
  - Constants: `ENEMY_PATH`, `ESSENCE_ICONS`, `ESSENCE_COLORS`.
  - `collected`, `rng`, `spawn_enemy(id, at, wave := 1) -> EnemyUnit`, `add_essences(blue, orange, purple, at)`, `drop_loot(item, at)`.
  - `signal enemy_died(enemy: EnemyUnit)`.

- [ ] **Step 1: Failing tests.**
  - `test_kill_rewards.gd`:
    ```gdscript
    extends GutTest

    const MELEE := preload("res://data/enemies/melee_minion.tres")
    const SIEGE := preload("res://data/enemies/siege_minion.tres")

    var rng := RandomNumberGenerator.new()


    func before_each() -> void:
    	rng.seed = 7


    func test_a_normal_kill_in_act_1() -> void:
    	var reward := KillRewards.roll(MELEE, 1, StageSetup.new(), rng)
    	assert_eq(reward.gold, 60)
    	assert_eq(reward.xp, 30)
    	assert_eq(reward.blue, 1)


    func test_act_2_pays_more() -> void:
    	var reward := KillRewards.roll(MELEE, 2, StageSetup.new(), rng)
    	assert_eq(reward.gold, 75)
    	assert_eq(reward.blue, 2)


    func test_an_elite_gives_five_times_the_blue() -> void:
    	assert_eq(KillRewards.roll(SIEGE, 2, StageSetup.new(), rng).blue, 10)


    func test_tree_bonuses_multiply() -> void:
    	var run := StageSetup.new()
    	run.gold_bonus = 0.3
    	run.xp_bonus = 0.2
    	run.essence_bonus = 0.5
    	var reward := KillRewards.roll(SIEGE, 1, run, rng)
    	assert_eq(reward.gold, 156)
    	assert_eq(reward.xp, 72)
    	assert_eq(reward.blue, 8)


    func test_orange_is_rare_from_normal_enemies() -> void:
    	var orange := 0
    	for i in 10000:
    		orange += KillRewards.roll(MELEE, 1, StageSetup.new(), rng).orange
    	assert_between(orange, 60, 140)
    ```
  - `test_loot.gd`:
    - Over 20000 normal `LootTable` rolls: fragments between 650 and 950, legendaries between 20 and 110.
    - A boss roll always holds a fragment.
    - **Stage tests** (`stage.tscn` with `StageSetup.new()`; `SaveGame.instance().reset()` first):
      - A `melee_minion` spawned at (1700, 600) and killed by Lucian (`lucian.make_damage(9999, TRUE, &"q")`) gives: the wallet 60, Lucian 30 XP, `collected[Essences.BLUE] == 1`, and the save's blue +1.
      - A `LootDrop` placed on Lucian puts its item in the backpack within 2 physics frames.
      - With the backpack full (49 × `bf_sword`, `max_stack` 1), the drop stays.
  - `test_stage_setup.gd`: buying `stage_gold` twice gives `from_save(...).gold_bonus == 0.2`.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3: Implement.**
  - `KillRewards`:
    ```gdscript
    class_name KillRewards
    extends RefCounted
    ## What a kill gives (design doc §9): stage gold and XP for the run, blue
    ## and orange essence for good. Boss purple comes from SaveGame.award_boss.
    ## The tree's Stage Gold, Bonus XP and Essence Drops raise them. Pure: the
    ## randomness comes from `rng`.

    const ORANGE_CHANCE := {&"normal": 0.01, &"elite": 0.1}
    const ELITE_BLUE := 5
    const BOSS_BLUE := 100
    const BOSS_ORANGE := 5


    static func roll(data: EnemyData, act: int, run: StageSetup, rng: RandomNumberGenerator) -> Dictionary:
    	var scale := data.reward_scale(act)
    	var reward := {
    		"gold": roundi(data.gold * scale * (1.0 + run.gold_bonus)),
    		"xp": roundi(data.xp * scale * (1.0 + run.xp_bonus)),
    		"blue": 0,
    		"orange": 0,
    	}
    	var blue := act
    	if data.kind == &"boss":
    		blue = BOSS_BLUE
    		reward.orange = BOSS_ORANGE
    	else:
    		if data.kind == &"elite":
    			blue = act * ELITE_BLUE
    		if rng.randf() < ORANGE_CHANCE[data.kind] * (1.0 + run.essence_bonus):
    			reward.orange = 1
    	reward.blue = roundi(blue * (1.0 + run.essence_bonus))
    	return reward
    ```
  - `LootTable`:
    ```gdscript
    class_name LootTable
    extends RefCounted
    ## Items a kill drops on the ground. A normal or elite enemy drops at most
    ## one: a legendary (rare), or else maybe a fragment. A boss always drops a
    ## fragment, and sometimes a legendary too.

    ## Kind -> [fragment chance, legendary chance].
    const CHANCES := {&"normal": [0.04, 0.003], &"elite": [0.25, 0.03], &"boss": [1.0, 0.15]}


    static func roll(kind: StringName, catalog: ItemCatalog, rng: RandomNumberGenerator) -> Array[ItemData]:
    	var drops: Array[ItemData] = []
    	var chance: Array = CHANCES[kind]
    	var legendary := rng.randf() < chance[1]
    	if legendary:
    		drops.append(_pick(catalog.legendaries(), rng))
    	if kind == &"boss" or (not legendary and rng.randf() < chance[0]):
    		drops.append(_pick(catalog.fragments(), rng))
    	return drops


    static func _pick(items: Array[ItemData], rng: RandomNumberGenerator) -> ItemData:
    	return items[rng.randi_range(0, items.size() - 1)]
    ```
  - `FloatingText`:
    ```gdscript
    class_name FloatingText
    extends Node2D
    ## A short text, with an icon in front if given, that rises and fades:
    ## essences gained, "Backpack full".

    const RISE := 60.0
    const LIFETIME := 1.2
    const FONT_SIZE := 22
    const ICON_SIZE := 28.0

    var text := ""
    var color := Color.WHITE
    var icon: Texture2D


    func _init(shown: String, text_color: Color, shown_icon: Texture2D = null) -> void:
    	text = shown
    	color = text_color
    	icon = shown_icon
    	z_index = 100


    func _ready() -> void:
    	var tween := create_tween().set_parallel()
    	tween.tween_property(self, "position:y", position.y - RISE, LIFETIME).set_ease(Tween.EASE_OUT)
    	tween.tween_property(self, "modulate:a", 0.0, LIFETIME * 0.4).set_delay(LIFETIME * 0.6)
    	tween.chain().tween_callback(queue_free)


    func _draw() -> void:
    	var font := ThemeDB.fallback_font
    	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x + (ICON_SIZE + 4.0 if icon else 0.0)
    	var x := -width * 0.5
    	if icon:
    		draw_texture_rect(icon, Rect2(x, -ICON_SIZE + 6.0, ICON_SIZE, ICON_SIZE), false)
    		x += ICON_SIZE + 4.0
    	draw_string_outline(font, Vector2(x, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 5, Color.BLACK)
    	draw_string(font, Vector2(x, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
    ```
  - `LootDrop`:
    ```gdscript
    class_name LootDrop
    extends Node2D
    ## An item on the ground where an enemy died. Lucian picks it up by walking
    ## within PICKUP_RANGE, into the backpack. With no room it stays and says
    ## so, at most every FULL_NOTE_GAP seconds. It stays until the stage ends.

    const PICKUP_RANGE := 60.0
    const FULL_NOTE_GAP := 3.0
    const ICON_SIZE := 44.0
    const GLOW := Color(0.6, 0.85, 1.0, 0.35)
    const LEGENDARY_GLOW := Color(1.0, 0.8, 0.3, 0.5)

    var item: ItemData
    var lucian: Lucian

    var _note_left := 0.0
    var _time := 0.0


    func _physics_process(delta: float) -> void:
    	_time += delta
    	_note_left -= delta
    	queue_redraw()
    	if not is_instance_valid(lucian) or not lucian.can_act():
    		return
    	if global_position.distance_to(lucian.global_position) > PICKUP_RANGE:
    		return
    	if lucian.inventory.add(item):
    		Sfx.play(&"coin")
    		queue_free()
    	elif _note_left <= 0.0:
    		_note_left = FULL_NOTE_GAP
    		var note := FloatingText.new("Backpack full", UiStyle.ERROR_COLOR)
    		note.position = global_position + Vector2(0, -50)
    		get_parent().add_child(note)


    func _draw() -> void:
    	var bob := sin(_time * 3.0) * 5.0
    	var glow := LEGENDARY_GLOW if item.kind == ItemData.Kind.LEGENDARY else GLOW
    	draw_circle(Vector2(0, 8), 30.0, Color(glow, glow.a * (0.7 + 0.3 * sin(_time * 4.0))))
    	draw_texture_rect(item.icon, Rect2(-ICON_SIZE * 0.5, -ICON_SIZE * 0.5 + bob - 6.0, ICON_SIZE, ICON_SIZE), false)
    ```
  - `StageSetup`:
    - Add `## Tree economy bonuses, as shares (0.1 = +10%).` with `var gold_bonus := 0.0`, `var xp_bonus := 0.0`, `var essence_bonus := 0.0`.
    - `from_save` sets them from `tree.value(&"stage_gold")`, `tree.value(&"bonus_xp")` and `tree.value(&"essence_drop")`.
    - Those three nodes' `.tres` descriptions drop "…starts working once enemies give…" and say what they do: "Enemies give more stage gold.", "Enemies give more XP.", "Enemies drop more essence.".
  - `Stage`:
    ```gdscript
    ## An enemy spawned by the stage died (after its rewards).
    signal enemy_died(enemy: EnemyUnit)

    const ENEMY_PATH := "res://data/enemies/%s.tres"
    const ESSENCE_ICONS := {
    	Essences.BLUE: preload("res://assets/art/ui/essence_blue.svg"),
    	Essences.ORANGE: preload("res://assets/art/ui/essence_orange.svg"),
    	Essences.PURPLE: preload("res://assets/art/ui/essence_purple.svg"),
    }
    const ESSENCE_COLORS := {Essences.BLUE: Color("5aa9ff"), Essences.ORANGE: Color("ffa040"), Essences.PURPLE: Color("b46cff")}

    ## Essences collected in this stage, for the HUD and the result panel.
    var collected := {Essences.BLUE: 0, Essences.ORANGE: 0, Essences.PURPLE: 0}
    var rng := RandomNumberGenerator.new()


    ## Puts an enemy of type `id` on the map at `at`, wired for damage numbers,
    ## the debug meter and rewards.
    func spawn_enemy(id: StringName, at: Vector2, wave := 1) -> EnemyUnit:
    	var data: EnemyData = load(ENEMY_PATH % id)
    	var unit := _new_unit(data)
    	unit.setup(data, maxi(run.act, 1), wave, lucian)
    	unit.projectile_parent = $Projectiles
    	unit.warning_parent = $Warnings
    	unit.position = at
    	$World.add_child(unit)
    	unit.damage_taken.connect(damage_numbers.spawn.bind(unit))
    	unit.died.connect(_on_enemy_died)
    	debug_table.watch(unit)
    	return unit


    ## Essences go into the save at once, so leaving or losing keeps them.
    func add_essences(blue: int, orange: int, purple: int, at: Vector2) -> void:
    	var amounts := {Essences.BLUE: blue, Essences.ORANGE: orange, Essences.PURPLE: purple}
    	var row := 0
    	for kind: StringName in Essences.KINDS:
    		if amounts[kind] <= 0:
    			continue
    		SaveGame.instance().essences.add(kind, amounts[kind])
    		collected[kind] += amounts[kind]
    		var popup := FloatingText.new("+%d" % amounts[kind], ESSENCE_COLORS[kind], ESSENCE_ICONS[kind])
    		popup.position = at + Vector2(0, -70 - 30 * row)
    		damage_numbers.add_child(popup)
    		row += 1


    func drop_loot(item: ItemData, at: Vector2) -> void:
    	var drop := LootDrop.new()
    	drop.item = item
    	drop.lucian = lucian
    	drop.position = at + Vector2(rng.randf_range(-30, 30), rng.randf_range(-30, 30))
    	$World.add_child(drop)


    ## Minions for now; Tasks 10 and 11 add the bosses.
    func _new_unit(_data: EnemyData) -> EnemyUnit:
    	return Minion.new()


    func _on_enemy_died(enemy: Enemy) -> void:
    	var unit := enemy as EnemyUnit
    	var reward := KillRewards.roll(unit.data, maxi(run.act, 1), run, rng)
    	wallet.add(reward.gold)
    	lucian.progress.add_xp(reward.xp)
    	add_essences(reward.blue, reward.orange, 0, unit.global_position)
    	for item in LootTable.roll(unit.data.kind, lucian.item_catalog, rng):
    		drop_loot(item, unit.global_position)
    	enemy_died.emit(unit)
    ```
    `_ready` calls `rng.randomize()`.
- [ ] **Step 4:** Run the files, then the full suite → PASS.
- [ ] **Step 5:** Commit `"Kills give gold, XP and essences (the tree's economy nodes work); enemies drop fragments and legendaries on the ground"`.

---

### Task 6: Save system: first-time boss purple, a new game in any slot, play time

**Files:** Modify `src/core/save_game.gd` and `src/ui/debug/main_debug_table.gd`. Tests: extend `tests/unit/test_save_game.gd` and `tests/unit/test_main_debug.gd`.

**Interfaces — Produces:**
- `SaveGame`: `BOSS_IDS`, `bosses: Array[String]`, `award_boss(id, first, repeat) -> int`, `forget_bosses()`, `start_new(of_slot) -> bool`, `any_slot_exists() -> bool`, `play_time: float` (seconds), `add_play_time(seconds)`, `play_time_of(of_slot) -> int`, `static play_time_text(seconds) -> String`.
- The save gains `"play_time": 5025` (whole seconds).
- The save gains a `"bosses"` key, e.g. `["thresh_1"]`.

- [ ] **Step 1: Failing tests** (`test_save_game.gd`; `save_game` and `PREFIX` are the file's own, and its `after_each` already deletes slots 1–3):
  ```gdscript
  func test_award_boss_gives_the_first_amount_once_then_the_repeat() -> void:
  	assert_eq(save_game.award_boss("akshan", 10, 2), 10)
  	assert_eq(save_game.award_boss("akshan", 10, 2), 2)
  	assert_eq(save_game.bosses, ["akshan"] as Array[String])


  func test_bosses_round_trip_and_unknown_ids_are_dropped() -> void:
  	save_game.award_boss("thresh_1", 10, 0)
  	save_game.save()
  	var data := JSON.parse_string(FileAccess.get_file_as_string(save_game.path(1))) as Dictionary
  	data["bosses"] = ["thresh_1", "teemo"]
  	var file := FileAccess.open(save_game.path(1), FileAccess.WRITE)
  	file.store_string(JSON.stringify(data))
  	file.close()
  	var loaded := SaveGame.new(PREFIX)
  	loaded.load_slot(1)
  	assert_eq(loaded.bosses, ["thresh_1"] as Array[String])


  func test_a_file_without_bosses_loads() -> void:
  	save_game.save()
  	var loaded := SaveGame.new(PREFIX)
  	loaded.load_slot(1)
  	assert_true(loaded.bosses.is_empty())


  func test_start_new_writes_that_slot_and_makes_it_current() -> void:
  	save_game.essences.add(Essences.BLUE, 500)
  	assert_true(save_game.start_new(2))
  	assert_eq(save_game.slot, 2)
  	assert_true(save_game.slot_exists(2))
  	assert_eq(save_game.essences.amount(Essences.BLUE), 0)


  func test_any_slot_exists() -> void:
  	assert_false(save_game.any_slot_exists())
  	save_game.copy_to(3)
  	assert_true(save_game.any_slot_exists())


  func test_play_time_round_trips_and_reads_per_slot() -> void:
  	save_game.add_play_time(5025.4)
  	save_game.save()
  	assert_eq(save_game.play_time_of(1), 5025)
  	assert_eq(save_game.play_time_of(2), 0)
  	var loaded := SaveGame.new(PREFIX)
  	loaded.load_slot(1)
  	assert_almost_eq(loaded.play_time, 5025.0, 0.001)


  func test_play_time_text() -> void:
  	assert_eq(SaveGame.play_time_text(5025), "1h 23m")
  	assert_eq(SaveGame.play_time_text(59), "0m")
  	assert_eq(SaveGame.play_time_text(600), "10m")
  ```
  - `test_main_debug.gd`: "Forget boss purple" empties `bosses`.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3: Implement** in `SaveGame`:
  ```gdscript
  ## Bosses with a first-time purple reward, by id.
  const BOSS_IDS: Array[String] = ["thresh_1", "akshan"]

  ## Boss ids that already gave their first-time purple.
  var bosses: Array[String] = []


  ## A boss was beaten: the purple due (`first` the first time, `repeat`
  ## after), and the boss is marked as paid. The caller adds the essence.
  func award_boss(id: String, first: int, repeat: int) -> int:
  	if id in bosses:
  		return repeat
  	bosses.append(id)
  	changed.emit()
  	return first


  ## Debug: every boss gives its first-time purple again.
  func forget_bosses() -> void:
  	bosses = []
  	changed.emit()


  ## A new game in slot `of_slot`, which becomes current and is written at
  ## once (it replaces what was there).
  func start_new(of_slot: int) -> bool:
  	slot = of_slot
  	reset()
  	return save()


  func any_slot_exists() -> bool:
  	for n in range(1, SLOTS + 1):
  		if slot_exists(n):
  			return true
  	return false
  ```
  - `reset()` sets `bosses = []` and `play_time = 0.0`. `to_dict()` adds `"bosses": bosses.duplicate()` and `"play_time": int(play_time)`.
  - Play time (Game adds to it in Task 13; nothing saves by itself):
    ```gdscript
    ## Seconds played in this slot (title screen and pauses not counted).
    var play_time := 0.0


    func add_play_time(seconds: float) -> void:
    	play_time += maxf(seconds, 0.0)


    ## The play time written in `of_slot` (main file, else backup), in whole seconds.
    func play_time_of(of_slot: int) -> int:
    	for file in [path(of_slot), backup_path(of_slot)]:
    		var data := _read(file)
    		if not data.is_empty():
    			var seconds: Variant = data.get("play_time", 0)
    			return maxi(int(seconds), 0) if (seconds is int or seconds is float) else 0
    	return 0


    ## "1h 23m", or "23m" under an hour.
    static func play_time_text(seconds: int) -> String:
    	var minutes := seconds / 60
    	return "%dh %02dm" % [minutes / 60, minutes % 60] if minutes >= 60 else "%dm" % minutes
    ```
    `_apply` reads `"play_time"` like `"endless_best"` (a number, never below 0).
  - `_apply` reads `"bosses"` like `"cleared"`: Strings in `BOSS_IDS` only, no repeats.
  - The doc comments change:
    - `slot`: "The current slot: every save writes to it. The title screen picks it."
    - `instance()`: "The running game's progress: slot 1 until the title screen loads another."
  - `MainDebugTable` gets a "Forget boss purple" button on its Progress tab that calls `SaveGame.instance().forget_bosses()`.
- [ ] **Step 4:** Run → PASS. Full suite → PASS.
- [ ] **Step 5:** Commit `"Save: first-time boss purple, a new game in any slot, play time"`.

---

### Task 7: Maps

**Files:**
- Create: `src/stage/stage_map.gd`, `src/stage/stage_maps.gd`, `src/stage/maps/mid_lane_map.gd`, `src/stage/maps/training_ground_map.gd`.
- Modify: `src/stage/test_arena.gd`, `src/stage/stage.gd`, `src/core/stage_setup.gd` (`act`, `stage`, `stage_id`), `src/ui/debug/debug_table.gd` (works with no dummy).
- Test: `tests/unit/test_maps.gd`.

**Interfaces — Produces:**
- `StageMap` (Node2D):
  - `WALL_THICKNESS`, `size`, `get_bounds()`, `border_rects()`.
  - Points: `lucian_start`, `ally_start`, `merchant_point`, `boss_point`, `spawn_points: Array[Vector2]`.
  - Walls: `wall_polygons: Array[PackedVector2Array]`, `wall_circles: Array[Vector3]` (x, y, radius).
  - `is_walkable(point, margin := 40.0) -> bool`.
- `StageMaps.create(act, stage) -> StageMap`.
- `MidLaneMap`: `along()`, `across()`, `center()`.
- `TrainingGroundMap.new(stage_number)`, `TrainingGroundMap.pillars(stage_number) -> Array[Vector2]`.
- `StageSetup`: `act := 0`, `stage := 0`, `stage_id := ""`.
- `Stage.arena: StageMap`. `Stage.dummy` is null on an act's map.

- [ ] **Step 1: Failing tests** (`test_maps.gd`):
  ```gdscript
  extends GutTest

  const STAGES := [[1, 1], [2, 1], [2, 2], [2, 3]]


  func test_every_point_is_walkable_and_inside() -> void:
  	for act_stage in STAGES:
  		var map := StageMaps.create(act_stage[0], act_stage[1])
  		var points: Array[Vector2] = [map.lucian_start, map.merchant_point, map.boss_point]
  		if act_stage[0] == 1:
  			points.append(map.ally_start)
  		points.append_array(map.spawn_points)
  		assert_false(map.spawn_points.is_empty(), str(act_stage))
  		for point in points:
  			assert_true(map.is_walkable(point), "%s: %s" % [act_stage, point])
  		map.free()


  func test_act_2_stages_differ() -> void:
  	assert_eq(TrainingGroundMap.pillars(1).size(), 6)
  	assert_eq(TrainingGroundMap.pillars(2).size(), 8)
  	assert_eq(TrainingGroundMap.pillars(3).size(), 10)
  	var first := TrainingGroundMap.new(1)
  	var second := TrainingGroundMap.new(2)
  	assert_lt(first.spawn_points.size(), second.spawn_points.size())
  	first.free()
  	second.free()


  func test_lucian_cannot_walk_into_the_jungle() -> void:
  	var map := MidLaneMap.new()
  	add_child_autofree(map)
  	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
  	lucian.position = map.lucian_start
  	add_child_autofree(lucian)
  	await wait_physics_frames(1)
  	lucian.command_move(map.lucian_start + map.across() * 900.0)
  	await wait_seconds(1.8)
  	assert_true(map.is_walkable(lucian.global_position, 0.0))


  func test_training_keeps_its_arena_and_dummy() -> void:
  	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
  	add_child_autofree(stage)
  	await wait_frames(2)
  	assert_is(stage.arena, TestArena)
  	assert_not_null(stage.dummy)


  func test_an_act_stage_swaps_the_map_and_drops_the_dummy() -> void:
  	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
  	var run := StageSetup.new()
  	run.act = 2
  	run.stage = 1
  	run.stage_id = "2-1"
  	stage.setup(run)
  	add_child_autofree(stage)
  	await wait_frames(2)
  	assert_is(stage.arena, TrainingGroundMap)
  	assert_null(stage.dummy)
  	assert_eq(stage.lucian.global_position, stage.arena.lucian_start)
  	assert_eq(get_tree().get_nodes_in_group(&"enemies").size(), 0)
  ```
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3: Implement.**
  - `StageMap`:
    ```gdscript
    class_name StageMap
    extends Node2D
    ## A stage's ground: its size, its walls on Layers.WORLD (the border, plus
    ## polygons and circles inside) and the points the stage uses. Subclasses
    ## fill the lists in _init and draw the ground in _draw. The playable area
    ## starts at (0, 0); the border walls sit just outside it.

    const WALL_THICKNESS := 64.0

    @export var size := Vector2(4800, 2700)

    var lucian_start := Vector2.ZERO
    ## Senna's place in Act 1.
    var ally_start := Vector2.ZERO
    var merchant_point := Vector2.ZERO
    var boss_point := Vector2.ZERO
    ## Where wave enemies come from, taken in turn.
    var spawn_points: Array[Vector2] = []
    var wall_polygons: Array[PackedVector2Array] = []
    ## Round walls: (x, y, radius).
    var wall_circles: Array[Vector3] = []


    func _ready() -> void:
    	var walls := StaticBody2D.new()
    	walls.name = "Walls"
    	walls.collision_layer = Layers.WORLD
    	walls.collision_mask = 0
    	for rect in border_rects():
    		var box := RectangleShape2D.new()
    		box.size = rect.size
    		var shape := CollisionShape2D.new()
    		shape.shape = box
    		shape.position = rect.get_center()
    		walls.add_child(shape)
    	for polygon in wall_polygons:
    		var solid := CollisionPolygon2D.new()
    		solid.polygon = polygon
    		walls.add_child(solid)
    	for circle in wall_circles:
    		var round_shape := CircleShape2D.new()
    		round_shape.radius = circle.z
    		var shape := CollisionShape2D.new()
    		shape.shape = round_shape
    		shape.position = Vector2(circle.x, circle.y)
    		walls.add_child(shape)
    	add_child(walls)


    func get_bounds() -> Rect2:
    	return Rect2(Vector2.ZERO, size)


    ## Inside the area and at least `margin` away from every wall.
    func is_walkable(point: Vector2, margin := 40.0) -> bool:
    	if not get_bounds().grow(-margin).has_point(point):
    		return false
    	for polygon in wall_polygons:
    		if Geometry2D.is_point_in_polygon(point, polygon) or _distance_to_edge(point, polygon) < margin:
    			return false
    	for circle in wall_circles:
    		if point.distance_to(Vector2(circle.x, circle.y)) < circle.z + margin:
    			return false
    	return true


    func border_rects() -> Array[Rect2]:
    	var t := WALL_THICKNESS
    	return [
    		Rect2(-t, -t, size.x + 2 * t, t),
    		Rect2(-t, size.y, size.x + 2 * t, t),
    		Rect2(-t, 0, t, size.y),
    		Rect2(size.x, 0, t, size.y),
    	]


    static func _distance_to_edge(point: Vector2, polygon: PackedVector2Array) -> float:
    	var best := INF
    	for i in polygon.size():
    		var closest := Geometry2D.get_closest_point_to_segment(point, polygon[i], polygon[(i + 1) % polygon.size()])
    		best = minf(best, point.distance_to(closest))
    	return best
    ```
  - `TestArena extends StageMap`:
    - It keeps its colors, grid and `_draw`, with `_wall_rects()` becoming `border_rects()`.
    - It deletes its own `size`, `WALL_THICKNESS` and walls code.
    - `_init` sets `lucian_start = Vector2(1700, 1350)` and `merchant_point = size * 0.5`.
  - `MidLaneMap`:
    ```gdscript
    class_name MidLaneMap
    extends StageMap
    ## Act 1: a long diagonal lane from the bottom-left to the top-right, jungle
    ## walls on both sides, and the river crossing its middle as walkable
    ## shallow water. Three rocks give cover. Lucian and Senna start at the
    ## bottom-left end; minions come from the top-right end; Thresh rises from
    ## the river.

    const LANE_START := Vector2(500, 2700)
    const LANE_END := Vector2(4700, 500)
    const LANE_HALF := 450.0
    ## Half the river's width, and how far it runs each way from the lane's center.
    const RIVER_HALF := 260.0
    const RIVER_REACH := 1100.0
    const ROCK_RADIUS := 70.0
    const LANE_COLOR := Color("5b5244")
    const JUNGLE_COLOR := Color("1d3a24")
    const JUNGLE_EDGE := Color("2f5a35")
    const TREE_COLOR := Color("16301d")
    const RIVER_COLOR := Color("2e5f86")
    const RIVER_EDGE := Color("6fb4d8")
    const ROCK_COLOR := Color("6b6660")

    var _river: PackedVector2Array


    func _init() -> void:
    	size = Vector2(5200, 3200)
    	var area := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
    	var lane := _band(LANE_START - along() * 2000.0, LANE_END + along() * 2000.0, LANE_HALF)
    	var river := _band(center() - across() * RIVER_REACH, center() + across() * RIVER_REACH, RIVER_HALF)
    	_river = Geometry2D.intersect_polygons(area, river)[0]
    	var open: PackedVector2Array = Geometry2D.merge_polygons(lane, river)[0]
    	for piece in Geometry2D.clip_polygons(area, open):
    		# A clockwise piece would be a hole; there are none, but never build one as a wall.
    		if not Geometry2D.is_polygon_clockwise(piece):
    			wall_polygons.append(piece)
    	lucian_start = LANE_START + along() * 300.0
    	ally_start = LANE_START + along() * 120.0 + across() * 160.0
    	merchant_point = center() - along() * 700.0 - across() * 160.0
    	boss_point = center() + across() * 300.0
    	spawn_points = [LANE_END - along() * 200.0 + across() * 160.0, LANE_END - along() * 200.0 - across() * 160.0]
    	for rock: Vector2 in [center() - along() * 480.0 + across() * 230.0, center() + along() * 480.0 - across() * 230.0, center() - across() * 720.0]:
    		wall_circles.append(Vector3(rock.x, rock.y, ROCK_RADIUS))


    ## Down the lane, toward the minions' end.
    func along() -> Vector2:
    	return (LANE_END - LANE_START).normalized()


    ## Across the lane, toward the top-left jungle.
    func across() -> Vector2:
    	return along().orthogonal()


    func center() -> Vector2:
    	return (LANE_START + LANE_END) * 0.5


    func _band(from: Vector2, to: Vector2, half: float) -> PackedVector2Array:
    	var side := (to - from).normalized().orthogonal() * half
    	return PackedVector2Array([from + side, to + side, to - side, from - side])


    func _draw() -> void:
    	draw_rect(get_bounds(), LANE_COLOR)
    	draw_colored_polygon(_river, RIVER_COLOR)
    	var ripples := RandomNumberGenerator.new()
    	ripples.seed = 3
    	for i in 40:
    		var at := center() + across() * ripples.randf_range(-RIVER_REACH, RIVER_REACH) + along() * ripples.randf_range(-RIVER_HALF + 30.0, RIVER_HALF - 30.0)
    		draw_arc(at, ripples.randf_range(18.0, 40.0), PI * 1.1, PI * 1.9, 12, Color(RIVER_EDGE, 0.35), 2.0, true)
    	var trees := RandomNumberGenerator.new()
    	trees.seed = 7
    	for polygon in wall_polygons:
    		draw_colored_polygon(polygon, JUNGLE_COLOR)
    		var box := _bounds_of(polygon)
    		for i in 70:
    			var at := Vector2(trees.randf_range(box.position.x, box.end.x), trees.randf_range(box.position.y, box.end.y))
    			if Geometry2D.is_point_in_polygon(at, polygon) and _distance_to_edge(at, polygon) > 80.0:
    				draw_circle(at, trees.randf_range(40.0, 80.0), TREE_COLOR)
    		var outline := polygon.duplicate()
    		outline.append(polygon[0])
    		draw_polyline(outline, JUNGLE_EDGE, 8.0, true)
    	for rock in wall_circles:
    		draw_circle(Vector2(rock.x, rock.y), rock.z, ROCK_COLOR)
    		draw_arc(Vector2(rock.x, rock.y), rock.z, 0.0, TAU, 32, ROCK_COLOR.lightened(0.3), 4.0, true)
    	draw_rect(get_bounds(), JUNGLE_EDGE, false, 4.0)


    static func _bounds_of(polygon: PackedVector2Array) -> Rect2:
    	var box := Rect2(polygon[0], Vector2.ZERO)
    	for point in polygon:
    		box = box.expand(point)
    	return box
    ```
  - `TrainingGroundMap`:
    ```gdscript
    class_name TrainingGroundMap
    extends StageMap
    ## Act 2: the Sentinels' training ground. An open stone arena with round
    ## pillars to hide behind (Akshan's Comeuppance) and training dummies along
    ## the walls. Gates on the left, top and right let the waves in. Each stage
    ## moves the pillars a little and opens more gates.

    const PILLAR_RADIUS := 70.0
    const DUMMY_RADIUS := 34.0
    const DUMMY_ART := preload("res://assets/art/enemies/training_dummy.svg")
    const GATES := {&"left": Vector2(150, 1400), &"top": Vector2(2300, 150), &"right": Vector2(4450, 1400)}
    const DUMMIES: Array[Vector2] = [Vector2(700, 110), Vector2(1500, 110), Vector2(3100, 110), Vector2(3900, 110), Vector2(700, 2690), Vector2(3900, 2690)]
    const TILE := 200.0
    const FLOOR := Color("3a3f47")
    const FLOOR_ALT := Color("343941")
    const PILLAR := Color("8a8478")
    const GATE := Color("c9a45c")

    var stage := 1


    func _init(stage_number := 1) -> void:
    	stage = stage_number
    	size = Vector2(4600, 2800)
    	lucian_start = Vector2(2300, 2550)
    	merchant_point = Vector2(1700, 2350)
    	boss_point = GATES[&"top"] + Vector2(0, 150)
    	for gate: StringName in ([&"top", &"right"] if stage == 1 else [&"left", &"top", &"right"]):
    		spawn_points.append(GATES[gate])
    	for pillar in pillars(stage):
    		wall_circles.append(Vector3(pillar.x, pillar.y, PILLAR_RADIUS))
    	for dummy in DUMMIES:
    		wall_circles.append(Vector3(dummy.x, dummy.y, DUMMY_RADIUS))


    ## Stage 1: 6 pillars; stage 2: 8; stage 3: a ring of 10 around the center.
    static func pillars(stage_number: int) -> Array[Vector2]:
    	var found: Array[Vector2] = []
    	if stage_number >= 3:
    		for i in 10:
    			found.append(Vector2(2300, 1400) + Vector2.from_angle(deg_to_rad(18.0 + 36.0 * i)) * 650.0)
    		return found
    	found.assign([Vector2(1300, 900), Vector2(3300, 900), Vector2(1300, 1900), Vector2(3300, 1900), Vector2(2300, 950), Vector2(2300, 1850)])
    	if stage_number == 2:
    		found.append_array([Vector2(800, 1400), Vector2(3800, 1400)])
    	return found


    func _draw() -> void:
    	var x := 0.0
    	while x < size.x:
    		var y := 0.0
    		while y < size.y:
    			var odd := (roundi(x / TILE) + roundi(y / TILE)) % 2 == 1
    			draw_rect(Rect2(x, y, TILE, TILE), FLOOR_ALT if odd else FLOOR)
    			y += TILE
    		x += TILE
    	for gate: Vector2 in GATES.values():
    		var along_wall := Vector2(0, 1) if gate.x < 300.0 or gate.x > size.x - 300.0 else Vector2(1, 0)
    		draw_line(gate - along_wall * 160.0, gate + along_wall * 160.0, GATE, 10.0)
    	for circle in wall_circles:
    		var at := Vector2(circle.x, circle.y)
    		if circle.z == PILLAR_RADIUS:
    			draw_circle(at, circle.z, PILLAR)
    			draw_circle(at + Vector2(-14, -14), circle.z * 0.55, PILLAR.lightened(0.15))
    			draw_arc(at, circle.z, 0.0, TAU, 40, PILLAR.darkened(0.4), 5.0, true)
    		else:
    			draw_texture(DUMMY_ART, at - DUMMY_ART.get_size() * 0.5, Color(1, 1, 1, 0.75))
    	draw_rect(get_bounds(), Color("6b717b"), false, 4.0)
    ```
  - `StageMaps`:
    ```gdscript
    class_name StageMaps
    extends RefCounted
    ## The map each act's stages are played on (design doc §13).


    static func create(act: int, stage: int) -> StageMap:
    	match act:
    		1:
    			return MidLaneMap.new()
    		2:
    			return TrainingGroundMap.new(stage)
    	return TestArena.new()
    ```
  - `StageSetup`: add `## The stage played (0 for Training): its act, stage and "act-stage" id.` with `var act := 0`, `var stage := 0` and `var stage_id := ""`.
  - `Stage`:
    - `@onready var arena: StageMap = $Arena`.
    - `_ready` begins with `if run.act > 0: _use_map(StageMaps.create(run.act, run.stage))`.
    - The camera uses `StageMap.WALL_THICKNESS`. `dummy.damage_taken.connect(...)` runs only `if dummy`. `add_merchant()` places him at `arena.merchant_point`.
    ```gdscript
    ## An act's map in place of the sandbox arena; the training dummy goes too.
    func _use_map(map: StageMap) -> void:
    	remove_child(arena)
    	arena.queue_free()
    	map.name = "Arena"
    	add_child(map)
    	move_child(map, 0)
    	arena = map
    	$World.remove_child(dummy)
    	dummy.queue_free()
    	dummy = null
    	lucian.position = map.lucian_start
    ```
  - `DebugTable`:
    - `_build` keeps the `TabContainer` as `_tabs` and the Dummy tab's index.
    - `setup` with no dummy skips `watch(dummy)` and the spins, and hides the tab (`_tabs.set_tab_hidden(index, true)`).
    - `_apply_dummy` and the dummy-count spin do nothing without a dummy.
- [ ] **Step 4:** Run → PASS. Full suite → PASS (the Training tests still see `TestArena` and its dummy).
- [ ] **Step 5:** Commit `"Maps: Act 1's mid lane with the river and jungle walls, Act 2's training ground with pillars"`.

---

### Task 8: Waves, the stage loop and the result panel

**Files:**
- Create: `src/core/wave_plan.gd`, `src/core/wave_runner.gd`, `src/ui/stage/stage_result.gd`.
- Modify: `src/core/stage_setup.gd` (`for_stage`), `src/stage/stage.gd`, `src/lucian/lucian.gd` (`apply_setup` sets `one_gun`), `src/ui/screen_switcher.gd` (`locked`), `src/main/game.gd` (the stage id).
- Test: `tests/unit/test_wave_runner.gd`, `tests/unit/test_stage_waves.gd`; extend `tests/unit/test_stage_setup.gd`, `tests/unit/test_journey.gd` and `tests/unit/test_game.gd`.

**Interfaces — Produces:**
- `WavePlan`: `MELEE`, `RANGED`, `SIEGE`, `SUPER`, `STAGES`, `BOSSES`, `waves(stage_id) -> Array`, `boss(stage_id) -> StringName`.
- `WaveRunner`:
  - Setup and state: `_init(stage_waves, boss_id := &"")`, `State`, `state`, `wave`, `boss`, `INTRO_TIME`, `BREAK_TIME`, `GROUP_SIZE`, `GROUP_GAP`.
  - Driving it: `tick(delta)`, `skip() -> float`, `finish()`, `enemy_spawned()`, `enemy_died()`.
  - Reads: `wave_count()`, `total_waves()`, `waves_done()`, `is_boss_wave()`, `is_waiting()`, `countdown()`, `alive()`.
  - Signals: `spawn_requested(enemy_id, wave)`, `wave_started(wave)`, `break_started(seconds)`, `break_ended`, `boss_wave_started(boss_id)`, `cleared`.
- `StageSetup`: `TUTORIAL_STAGE`, `display_name`, `boss`, `tutorial`, `static for_stage(save, act, stage)`.
- `StageResult` (CanvasLayer): `cleared`, `title`, `continue_button`, `show_result(cleared, stage_name, waves_text, collected, rewards)`, `static clock(seconds) -> String`, `signal continue_pressed`.
- `Stage`: `runner`, `result`, `reward_lines`, `elapsed` (seconds played in this stage, pauses not counted), `LUCIAN_NUMBER_SCALE`, `skip_break()`, `show_result(cleared)`.
- `ScreenSwitcher.locked`.

- [ ] **Step 1: Failing tests.**
  - `test_wave_runner.gd`:
    ```gdscript
    extends GutTest

    var spawned: Array[StringName] = []


    func _runner(waves: Array, boss := &"") -> WaveRunner:
    	spawned.clear()
    	var runner := WaveRunner.new(waves, boss)
    	runner.spawn_requested.connect(func(id: StringName, _wave: int) -> void: spawned.append(id))
    	return runner


    ## Ticks until every enemy of the wave has been asked for.
    func _spawn_all(runner: WaveRunner) -> void:
    	for i in 50:
    		runner.tick(WaveRunner.GROUP_GAP)


    func _kill_all(runner: WaveRunner) -> void:
    	for i in spawned.size():
    		runner.enemy_died()
    	spawned.clear()


    func test_a_countdown_then_wave_1_in_groups_of_3() -> void:
    	var runner := _runner(WavePlan.waves("1-1"))
    	runner.tick(WaveRunner.INTRO_TIME - 0.1)
    	assert_true(spawned.is_empty())
    	runner.tick(0.2)
    	runner.tick(0.01)
    	assert_eq(spawned.size(), WaveRunner.GROUP_SIZE)
    	_spawn_all(runner)
    	assert_eq(spawned.size(), 10)
    	assert_eq(spawned.count(WavePlan.MELEE), 6)


    func test_the_break_waits_for_the_last_enemy() -> void:
    	var runner := _runner(WavePlan.waves("1-1"))
    	runner.skip()
    	_spawn_all(runner)
    	for i in 9:
    		runner.enemy_died()
    	assert_eq(runner.state, WaveRunner.State.FIGHT)
    	runner.enemy_died()
    	assert_eq(runner.state, WaveRunner.State.BREAK)
    	assert_almost_eq(runner.countdown(), WaveRunner.BREAK_TIME, 0.001)


    func test_skip_returns_the_time_left() -> void:
    	var runner := _runner(WavePlan.waves("2-1"))
    	runner.tick(1.5)
    	assert_almost_eq(runner.skip(), WaveRunner.INTRO_TIME - 1.5, 0.001)
    	assert_eq(runner.state, WaveRunner.State.FIGHT)
    	assert_eq(runner.skip(), 0.0)


    func test_the_boss_wave_comes_last_only_with_a_boss() -> void:
    	var runner := _runner(WavePlan.waves("2-3"), &"akshan")
    	watch_signals(runner)
    	for wave in 3:
    		runner.skip()
    		_spawn_all(runner)
    		_kill_all(runner)
    	assert_signal_not_emitted(runner, "cleared")
    	runner.skip()
    	_spawn_all(runner)
    	assert_true(runner.is_boss_wave())
    	assert_eq(spawned, [&"akshan"] as Array[StringName])
    	_kill_all(runner)
    	assert_signal_emit_count(runner, "cleared", 1)
    	assert_eq(runner.waves_done(), 4)


    func test_without_a_boss_the_last_wave_clears_it() -> void:
    	var runner := _runner(WavePlan.waves("2-1"))
    	watch_signals(runner)
    	for wave in 2:
    		runner.skip()
    		_spawn_all(runner)
    		_kill_all(runner)
    	assert_signal_emit_count(runner, "cleared", 1)
    	assert_eq(runner.state, WaveRunner.State.DONE)


    func test_finish_ends_it_once() -> void:
    	var runner := _runner(WavePlan.waves("1-1"), &"thresh_1")
    	watch_signals(runner)
    	runner.finish()
    	runner.finish()
    	assert_signal_emit_count(runner, "cleared", 1)
    ```
  - `test_journey.gd`: for every stage of Acts 1–2, `Journey.waves(act, stage) == WavePlan.waves(id).size()`, and `Journey.boss_kind(act, stage) == &"boss"` exactly where `WavePlan.boss(id) != &""`.
  - `test_stage_setup.gd`:
    - `for_stage(save, 1, 1)` on a new game gives `tutorial`, `bought == [0, 0, 0, 0]`, no passive, `summoners == [&"", &""]`, `boss == &"thresh_1"` and `display_name == "Act 1 · The Loss"`.
    - With `"1-1"` cleared it is not `tutorial`, and `boss == &""`.
    - `for_stage(save, 2, 3)` gives `boss == &"akshan"` and `display_name == "Stage 2-3 · The Sentinels"`.
  - `test_stage_waves.gd` (`SaveGame.instance().reset()` in `before_each`; `get_tree().paused = false` in `after_each`):
    ```gdscript
    extends GutTest


    func after_each() -> void:
    	get_tree().paused = false


    func _stage(act: int, stage_number: int) -> Stage:
    	SaveGame.instance().reset()
    	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
    	stage.setup(StageSetup.for_stage(SaveGame.instance(), act, stage_number))
    	add_child_autofree(stage)
    	await wait_frames(2)
    	stage.lucian.invulnerable = true
    	return stage


    func _kill_wave(stage: Stage) -> void:
    	for i in 20:
    		stage.runner.tick(WaveRunner.GROUP_GAP)
    	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
    		enemy.take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))


    func test_the_merchant_comes_only_for_the_break() -> void:
    	var stage: Stage = await _stage(2, 1)
    	assert_null(stage.merchant)
    	stage.skip_break()
    	_kill_wave(stage)
    	await wait_frames(1)
    	assert_eq(stage.runner.state, WaveRunner.State.BREAK)
    	assert_not_null(stage.merchant)
    	stage.skip_break()
    	await wait_frames(1)
    	assert_null(stage.merchant)


    func test_skip_gives_the_regen_of_the_time_skipped() -> void:
    	var stage: Stage = await _stage(2, 1)
    	stage.lucian.hp = 100.0
    	stage.skip_break()
    	assert_gt(stage.lucian.hp, 100.0 + stage.lucian.stats.hp_regen * 4.0)


    func test_clearing_every_wave_shows_stage_cleared() -> void:
    	var stage: Stage = await _stage(2, 1)
    	for wave in 2:
    		stage.skip_break()
    		_kill_wave(stage)
    		await wait_frames(1)
    	assert_true(stage.result.visible)
    	assert_eq(stage.result.title.text, "STAGE CLEARED")
    	assert_true(get_tree().paused)
    	watch_signals(stage)
    	stage.result.continue_button.pressed.emit()
    	assert_signal_emitted_with_parameters(stage, "finished", [&"cleared"])


    func test_dying_shows_defeated() -> void:
    	var stage: Stage = await _stage(2, 1)
    	stage.lucian.invulnerable = false
    	stage.lucian.take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))
    	await wait_seconds(Lucian.DEATH_FADE + 0.2)
    	assert_eq(stage.result.title.text, "DEFEATED")
    	watch_signals(stage)
    	stage.result.continue_button.pressed.emit()
    	assert_signal_emitted_with_parameters(stage, "finished", [&"failed"])


    func test_esc_does_nothing_on_the_result() -> void:
    	var stage: Stage = await _stage(2, 1)
    	stage.show_result(true)
    	var esc := InputEventAction.new()
    	esc.action = &"open_menu"
    	esc.pressed = true
    	stage.screens._input(esc)
    	assert_false(stage.screens.menu.visible)


    func test_the_result_shows_the_stage_time() -> void:
    	var stage: Stage = await _stage(2, 1)
    	await wait_seconds(0.5)
    	stage.show_result(true)
    	assert_gt(stage.elapsed, 0.4)
    	var texts := stage.result.find_children("*", "Label", true, false).map(func(label: Label) -> String: return label.text)
    	assert_true(texts.any(func(text: String) -> bool: return text.contains("Time 0:01")), str(texts))


    func test_the_clock() -> void:
    	assert_eq(StageResult.clock(17.2), "0:18")
    	assert_eq(StageResult.clock(65.0), "1:05")
    ```
  - `test_game.gd` gains:
    ```gdscript
    func test_a_cleared_act_stage_is_saved_as_cleared() -> void:
    	game.start_stage(StageSetup.for_stage(SaveGame.instance(), 2, 1))
    	await wait_frames(2)
    	var stage := game.screen as Stage
    	stage.show_result(true)
    	stage.result.continue_button.pressed.emit()
    	await wait_frames(2)
    	assert_true("2-1" in SaveGame.instance().cleared)
    	assert_is(game.screen, MainScreen)
    ```
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3: Implement.**
  - `WavePlan`:
    ```gdscript
    class_name WavePlan
    extends RefCounted
    ## Which enemies each wave of a stage brings (docs/act1_the_loss.md,
    ## docs/act2_the_sentinels.md), and each stage's boss.

    const MELEE := &"melee_minion"
    const RANGED := &"ranged_minion"
    const SIEGE := &"siege_minion"
    const SUPER := &"super_minion"
    ## Stage id -> waves; each wave lists [enemy id, count] in spawn order.
    const STAGES := {
    	"1-1": [[[MELEE, 6], [RANGED, 4]], [[MELEE, 6], [RANGED, 6], [SIEGE, 1]]],
    	"2-1": [[[MELEE, 6], [RANGED, 4], [SIEGE, 1]], [[MELEE, 6], [RANGED, 6], [SIEGE, 1], [SUPER, 1]]],
    	"2-2": [[[MELEE, 6], [RANGED, 6], [SIEGE, 1]], [[MELEE, 6], [RANGED, 6], [SIEGE, 2]], [[MELEE, 6], [RANGED, 6], [SIEGE, 1], [SUPER, 1]]],
    	"2-3": [[[MELEE, 6], [RANGED, 6], [SIEGE, 2]], [[MELEE, 6], [RANGED, 6], [SIEGE, 1], [SUPER, 1]], [[MELEE, 8], [RANGED, 6], [SIEGE, 2], [SUPER, 1]]],
    }
    ## Stage id -> the boss wave's enemy id.
    const BOSSES := {"1-1": &"thresh_1", "2-3": &"akshan"}


    ## Each wave as the enemy ids to spawn, in order.
    static func waves(stage_id: String) -> Array:
    	var found := []
    	for wave: Array in STAGES.get(stage_id, []):
    		var ids: Array[StringName] = []
    		for group: Array in wave:
    			for i in group[1]:
    				ids.append(group[0])
    		found.append(ids)
    	return found


    static func boss(stage_id: String) -> StringName:
    	return BOSSES.get(stage_id, &"")
    ```
  - `WaveRunner`:
    ```gdscript
    class_name WaveRunner
    extends RefCounted
    ## A stage's waves: a countdown, each wave's enemies in groups, a break
    ## once all are dead, and the boss wave last when there is one. The stage
    ## ticks it (so it pauses with the game), spawns what it asks for, and
    ## reports each death.

    signal spawn_requested(enemy_id: StringName, wave: int)
    signal wave_started(wave: int)
    signal break_started(seconds: float)
    signal break_ended
    signal boss_wave_started(boss_id: StringName)
    signal cleared

    enum State { INTRO, FIGHT, BREAK, DONE }

    const INTRO_TIME := 5.0
    const BREAK_TIME := 20.0
    const GROUP_SIZE := 3
    const GROUP_GAP := 1.2

    var state := State.INTRO
    ## The wave being fought or coming next (1-based); the boss wave is last.
    var wave := 0
    var boss := &""

    var _waves: Array = []
    var _countdown := INTRO_TIME
    var _to_spawn: Array[StringName] = []
    var _spawn_left := 0.0
    var _alive := 0
    var _done := 0


    func _init(stage_waves: Array, boss_id := &"") -> void:
    	_waves = stage_waves
    	boss = boss_id


    func wave_count() -> int:
    	return _waves.size()


    ## The waves, the boss wave included.
    func total_waves() -> int:
    	return _waves.size() + (1 if boss != &"" else 0)


    func waves_done() -> int:
    	return _done


    func is_boss_wave() -> bool:
    	return boss != &"" and wave > _waves.size()


    ## The countdown before wave 1, or a break, is running.
    func is_waiting() -> bool:
    	return state == State.INTRO or state == State.BREAK


    func countdown() -> float:
    	return maxf(_countdown, 0.0) if is_waiting() else 0.0


    ## Enemies still to beat this wave, those not spawned yet included.
    func alive() -> int:
    	return _alive + _to_spawn.size()


    func tick(delta: float) -> void:
    	match state:
    		State.INTRO, State.BREAK:
    			_countdown -= delta
    			if _countdown <= 0.0:
    				_start_next()
    		State.FIGHT:
    			if not _to_spawn.is_empty():
    				_spawn_left -= delta
    				if _spawn_left <= 0.0:
    					_spawn_group()


    ## Starts the next wave now. Returns the seconds skipped (0 mid-wave).
    func skip() -> float:
    	if not is_waiting():
    		return 0.0
    	var skipped := maxf(_countdown, 0.0)
    	_start_next()
    	return skipped


    ## The stage ends here, cleared (Act 1's cutscene, or the last wave).
    func finish() -> void:
    	if state == State.DONE:
    		return
    	state = State.DONE
    	cleared.emit()


    ## An enemy that wasn't asked for (debug) still has to die.
    func enemy_spawned() -> void:
    	_alive += 1


    func enemy_died() -> void:
    	_alive = maxi(_alive - 1, 0)
    	if state == State.FIGHT and alive() == 0:
    		_wave_done()


    func _start_next() -> void:
    	if state == State.BREAK:
    		break_ended.emit()
    	wave += 1
    	state = State.FIGHT
    	if is_boss_wave():
    		_to_spawn = [boss]
    		boss_wave_started.emit(boss)
    	else:
    		_to_spawn.assign(_waves[wave - 1])
    	_spawn_left = 0.0
    	wave_started.emit(wave)


    func _spawn_group() -> void:
    	for i in mini(GROUP_SIZE, _to_spawn.size()):
    		_alive += 1
    		spawn_requested.emit(_to_spawn.pop_front(), wave)
    	_spawn_left = GROUP_GAP


    func _wave_done() -> void:
    	_done += 1
    	if wave >= total_waves():
    		finish()
    	else:
    		state = State.BREAK
    		_countdown = BREAK_TIME
    		break_started.emit(BREAK_TIME)
    ```
  - `StageSetup`:
    ```gdscript
    ## Act 1's only stage: the tutorial, the first time it is played.
    const TUTORIAL_STAGE := "1-1"

    ## Shown on the HUD and the result panel.
    var display_name := "Training"
    ## The boss wave's enemy id, or &"" for none.
    var boss := &""
    ## Act 1's first play: one gun, no skills or summoners; Senna fights too.
    var tutorial := false


    ## A Journey stage: the save's setup plus the stage, its boss, and the
    ## tutorial's limits on Act 1's first play. Thresh only comes that first time.
    static func for_stage(save: SaveGame, act_number: int, stage_number: int) -> StageSetup:
    	var setup := from_save(save)
    	setup.act = act_number
    	setup.stage = stage_number
    	setup.stage_id = Journey.stage_id(act_number, stage_number)
    	var act_name: String = Journey.ACTS[act_number - 1]["name"]
    	if Journey.stage_count(act_number) == 1:
    		setup.display_name = "Act %d · %s" % [act_number, act_name]
    	else:
    		setup.display_name = "Stage %s · %s" % [setup.stage_id, act_name]
    	setup.boss = WavePlan.boss(setup.stage_id)
    	if setup.stage_id == TUTORIAL_STAGE:
    		if TUTORIAL_STAGE in save.cleared:
    			setup.boss = &""
    		else:
    			setup.tutorial = true
    			setup.bought.assign([0, 0, 0, 0])
    			setup.passive = false
    			setup.summoners.assign([&"", &""])
    	return setup
    ```
    `Lucian.apply_setup` adds `one_gun = setup.tutorial`.
  - `StageResult`:
    ```gdscript
    class_name StageResult
    extends CanvasLayer
    ## The end of a stage, over a paused game: STAGE CLEARED or DEFEATED, the
    ## stage, the waves cleared, the essences collected and any first-clear
    ## reward, then Continue.

    signal continue_pressed

    const LAYER := 42
    const REWARD_COLOR := Color("5ad07a")

    var cleared := false
    var title: Label
    var continue_button: Button

    var _lines: VBoxContainer


    func _ready() -> void:
    	layer = LAYER
    	process_mode = PROCESS_MODE_ALWAYS
    	visible = false
    	_build()


    ## "4:32": minutes and seconds, rounded up.
    static func clock(seconds: float) -> String:
    	var whole := ceili(seconds)
    	return "%d:%02d" % [whole / 60, whole % 60]


    func show_result(is_cleared: bool, stage_name: String, waves_text: String, collected: Dictionary, rewards: Array[String]) -> void:
    	cleared = is_cleared
    	title.text = "STAGE CLEARED" if cleared else "DEFEATED"
    	title.add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR if cleared else UiStyle.ERROR_COLOR)
    	for child in _lines.get_children():
    		child.queue_free()
    	_lines.add_child(UiStyle.label(stage_name, 24, UiStyle.TITLE_COLOR))
    	if waves_text != "":
    		_lines.add_child(UiStyle.label(waves_text, 20, UiStyle.TEXT_COLOR))
    	var essences := HBoxContainer.new()
    	essences.add_theme_constant_override(&"separation", 10)
    	_lines.add_child(essences)
    	for kind: StringName in Essences.KINDS:
    		if collected[kind] > 0:
    			var icon := TextureRect.new()
    			icon.texture = Stage.ESSENCE_ICONS[kind]
    			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    			icon.custom_minimum_size = Vector2(32, 32)
    			essences.add_child(icon)
    			essences.add_child(UiStyle.label("+%d" % collected[kind], 22, Stage.ESSENCE_COLORS[kind]))
    	if essences.get_child_count() == 0:
    		essences.add_child(UiStyle.label("No essences", 20, UiStyle.DIM_COLOR))
    	for line in rewards:
    		_lines.add_child(UiStyle.label(line, 20, REWARD_COLOR))
    	visible = true


    func _build() -> void:
    	var backdrop := ColorRect.new()
    	backdrop.color = Color(0, 0, 0, 0.6)
    	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
    	add_child(backdrop)
    	var center := CenterContainer.new()
    	center.set_anchors_preset(Control.PRESET_FULL_RECT)
    	backdrop.add_child(center)
    	var panel := PanelContainer.new()
    	panel.add_theme_stylebox_override(&"panel", UiStyle.panel())
    	panel.custom_minimum_size = Vector2(560, 0)
    	center.add_child(panel)
    	var column := VBoxContainer.new()
    	column.add_theme_constant_override(&"separation", 16)
    	panel.add_child(column)
    	title = UiStyle.label("", 40, UiStyle.GOLD_COLOR)
    	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    	column.add_child(title)
    	column.add_child(HSeparator.new())
    	_lines = VBoxContainer.new()
    	_lines.add_theme_constant_override(&"separation", 10)
    	column.add_child(_lines)
    	continue_button = Button.new()
    	continue_button.text = "Continue"
    	continue_button.custom_minimum_size = Vector2(320, 60)
    	UiStyle.style_button(continue_button, 26, true)
    	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    	continue_button.pressed.connect(continue_pressed.emit)
    	column.add_child(continue_button)
    ```
  - `ScreenSwitcher`: add `## The stage result is up: ESC and P do nothing.` with `var locked := false`. `_input` returns at once while `locked`.
  - `Stage`:
    ```gdscript
    ## Damage numbers over Lucian are smaller than over enemies.
    const LUCIAN_NUMBER_SCALE := 0.8

    ## The stage's waves; null in Training.
    var runner: WaveRunner
    var result := StageResult.new()
    ## First-clear rewards, for the result panel.
    var reward_lines: Array[String] = []
    ## Seconds played in this stage (the stage only processes while unpaused).
    var elapsed := 0.0

    var _next_spawn := 0
    ```
    In `_ready`, after the HUD and debug table:
    ```gdscript
    	add_child(result)
    	result.continue_pressed.connect(func() -> void: finished.emit(&"cleared" if result.cleared else &"failed"))
    	lucian.died.connect(_on_lucian_died)
    	lucian.damage_received.connect(damage_numbers.spawn.bind(lucian, LUCIAN_NUMBER_SCALE))
    	if run.act > 0:
    		_start_waves()
    ```
    Then:
    ```gdscript
    func _process(delta: float) -> void:
    	if result.visible:
    		return
    	elapsed += delta
    	if runner and not lucian.dead:
    		runner.tick(delta)


    ## Skip (the HUD's button): the next wave now, plus the regen of the time skipped.
    func skip_break() -> void:
    	if runner:
    		lucian.restore_for(runner.skip())


    ## The result panel over a paused game; ESC and P stop working.
    func show_result(is_cleared: bool) -> void:
    	if result.visible:
    		return
    	remove_merchant()
    	if screens.backpack.visible:
    		screens.set_backpack_open(false)
    	screens.set_menu_open(false)
    	screens.locked = true
    	var waves_text := "Waves cleared: %d / %d   ·   " % [runner.waves_done(), runner.total_waves()] if runner else ""
    	result.show_result(is_cleared, run.display_name, waves_text + "Time %s" % StageResult.clock(elapsed), collected, reward_lines)
    	get_tree().paused = true


    func _start_waves() -> void:
    	remove_merchant()
    	runner = WaveRunner.new(WavePlan.waves(run.stage_id), run.boss)
    	runner.spawn_requested.connect(_spawn_wave_enemy)
    	runner.break_started.connect(func(_seconds: float) -> void: add_merchant())
    	runner.break_ended.connect(remove_merchant)
    	runner.cleared.connect(_on_cleared)
    	enemy_died.connect(func(_enemy: EnemyUnit) -> void: runner.enemy_died())


    func _spawn_wave_enemy(id: StringName, wave: int) -> void:
    	if id == run.boss:
    		spawn_enemy(id, arena.boss_point)
    		return
    	var at := arena.spawn_points[_next_spawn % arena.spawn_points.size()]
    	_next_spawn += 1
    	spawn_enemy(id, at + Vector2(rng.randf_range(-70, 70), rng.randf_range(-70, 70)), wave)


    ## The boss's purple (first-time or repeat) and the first-clear lines, then the result.
    func _on_cleared() -> void:
    	var save := SaveGame.instance()
    	if run.boss != &"":
    		var data: EnemyData = load(ENEMY_PATH % run.boss)
    		var first_time := not String(run.boss) in save.bosses
    		var purple := save.award_boss(String(run.boss), data.purple_first, data.purple_repeat)
    		if purple > 0:
    			add_essences(0, 0, purple, lucian.global_position)
    			reward_lines.append("+%d purple essence (%s)" % [purple, "first clear" if first_time else "repeat"])
    	if not run.stage_id in save.cleared and run.stage == Journey.stage_count(run.act) and run.act < Journey.ACTS.size():
    		reward_lines.append("Act %d is open" % (run.act + 1))
    	show_result(true)


    func _on_lucian_died() -> void:
    	await get_tree().create_timer(Lucian.DEATH_FADE).timeout
    	show_result(false)
    ```
    `screens.set_menu_open(false)` unpauses through `_update_pause`, so `show_result` pauses last.
  - `Game`:
    - `var _run := StageSetup.new()`. `start_stage` stores `_run = run`.
    - `_on_stage_finished` calls `SaveGame.instance().finish_stage(result, _run.stage_id)`. It only records a clear for `&"cleared"` with an id.
- [ ] **Step 4:** Run the files, then the full suite → PASS.
- [ ] **Step 5:** Commit `"Waves: the countdown, breaks with the merchant, Skip with regen, the boss wave, and a cleared or defeated result"`.

---

### Task 9: Stage HUD: wave counter, boss bar, collected essences, radar

**Files:**
- Create: `src/ui/hud/stage_info.gd`, `src/ui/hud/boss_bar.gd`, `src/ui/hud/radar.gd`.
- Modify: `src/ui/hud/hud.gd`, `src/stage/stage.gd` (passes itself to the HUD).
- Test: `tests/unit/test_stage_hud.gd`.

**Interfaces — Produces:**
- `StageInfo` (PanelContainer):
  - `setup(stage_name, runner)`, `refresh()`, `signal skip_pressed` (times use `StageResult.clock`).
  - Labels and button: `name_label`, `wave_label`, `enemies_label`, `timer_label`, `skip_button`.
- `BossBar` (Control): `boss`, `phase_text`, `SIZE`.
- `Radar` (Control):
  - `setup(bounds, lucian)`, `to_radar(point) -> Vector2`, `static dot_size(kind) -> float`.
  - Constants: `WIDTH`, `DOT`, `ELITE_DOT`, `SKULL_SIZE`.
- `Hud`:
  - `setup(target, wallet, stage: Stage = null)`.
  - `stage_info`, `boss_bar`, `radar`, `tips` (Task 10 fills the tips).

- [ ] **Step 1: Failing tests** (`test_stage_hud.gd`):
  ```gdscript
  extends GutTest


  func test_the_wave_text_follows_the_runner() -> void:
  	var runner := WaveRunner.new(WavePlan.waves("2-2"))
  	var info := StageInfo.new()
  	add_child_autofree(info)
  	info.setup("Stage 2-2 · The Sentinels", runner)
  	info.refresh()
  	assert_true(info.skip_button.visible)
  	assert_eq(info.timer_label.text, "Wave 1 in 0:05")
  	runner.skip()
  	for i in 10:
  		runner.tick(WaveRunner.GROUP_GAP)
  	info.refresh()
  	assert_eq(info.wave_label.text, "Wave 1/3")
  	assert_eq(info.enemies_label.text, "Enemies: 13")
  	assert_false(info.skip_button.visible)


  func test_training_shows_only_its_name() -> void:
  	var info := StageInfo.new()
  	add_child_autofree(info)
  	info.setup("Training", null)
  	info.refresh()
  	assert_eq(info.name_label.text, "Training")
  	assert_false(info.wave_label.visible)
  	assert_false(info.skip_button.visible)


  func test_skip_on_the_hud_starts_the_wave() -> void:
  	SaveGame.instance().reset()
  	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
  	stage.setup(StageSetup.for_stage(SaveGame.instance(), 2, 1))
  	add_child_autofree(stage)
  	await wait_frames(2)
  	stage.hud.stage_info.skip_button.pressed.emit()
  	assert_eq(stage.runner.state, WaveRunner.State.FIGHT)


  func test_the_radar_maps_the_world_onto_itself() -> void:
  	var radar := Radar.new()
  	add_child_autofree(radar)
  	radar.setup(Rect2(0, 0, 5200, 3200), null)
  	assert_eq(radar.size, Vector2(Radar.WIDTH, 160))
  	assert_eq(radar.to_radar(Vector2(2600, 1600)), Vector2(130, 80))
  	assert_eq(radar.mouse_filter, Control.MOUSE_FILTER_IGNORE)


  func test_elites_are_bigger_dots_and_bosses_skulls() -> void:
  	assert_gt(Radar.dot_size(&"elite"), Radar.dot_size(&"normal"))
  	assert_eq(Radar.dot_size(&"boss"), Radar.SKULL_SIZE)


  func test_the_boss_bar_shows_only_while_a_boss_lives() -> void:
  	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
  	add_child_autofree(lucian)
  	var bar := BossBar.new()
  	add_child_autofree(bar)
  	await wait_frames(1)
  	assert_false(bar.visible)
  	var data := EnemyData.new()
  	data.kind = &"boss"
  	data.display_name = "Test Boss"
  	data.max_hp = 1000.0
  	var boss := Minion.new()
  	boss.setup(data, 1, 1, lucian)
  	boss.position = Vector2(3000, 0)
  	add_child_autofree(boss)
  	await wait_frames(2)
  	assert_true(bar.visible)
  	boss.take_damage(DamageInfo.create(5000.0, DamageInfo.Type.TRUE, &"test"))
  	await wait_frames(2)
  	assert_false(bar.visible)


  func test_fps_sits_top_left() -> void:
  	var hud: Hud = load("res://src/ui/hud/hud.tscn").instantiate()
  	add_child_autofree(hud)
  	assert_eq(hud._fps_label.anchor_left, 0.0)
  	assert_eq(hud._fps_label.anchor_right, 0.0)
  ```
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3: Implement.**
  - `StageInfo`:
    ```gdscript
    class_name StageInfo
    extends PanelContainer
    ## Top center of the stage: the stage's name, "Wave 2/3" (or "Boss wave")
    ## and the enemies left; before a wave, "Wave 2 in 0:17" and Skip. Training
    ## shows only its name. Only the Skip button takes clicks.

    signal skip_pressed

    var runner: WaveRunner
    var name_label := UiStyle.label("", 20, UiStyle.TITLE_COLOR)
    var wave_label := UiStyle.label("", 20, UiStyle.TEXT_COLOR)
    var enemies_label := UiStyle.label("", 20, UiStyle.TEXT_COLOR)
    var timer_label := UiStyle.label("", 20, UiStyle.GOLD_COLOR)
    var skip_button := Button.new()


    func _ready() -> void:
    	mouse_filter = Control.MOUSE_FILTER_IGNORE
    	var row := HBoxContainer.new()
    	row.add_theme_constant_override(&"separation", 22)
    	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    	add_child(row)
    	for label in [name_label, wave_label, enemies_label, timer_label]:
    		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    		row.add_child(label)
    	skip_button.text = "Skip"
    	skip_button.custom_minimum_size = Vector2(90, 34)
    	UiStyle.style_button(skip_button, 18)
    	skip_button.set_meta(&"hover_text", "Start the next wave now. Lucian still gets the health and mana regen of the time skipped.")
    	skip_button.pressed.connect(skip_pressed.emit)
    	row.add_child(skip_button)


    func setup(stage_name: String, stage_runner: WaveRunner) -> void:
    	name_label.text = stage_name
    	runner = stage_runner
    	refresh()


    func _process(_delta: float) -> void:
    	refresh()


    func refresh() -> void:
    	var waiting := runner != null and runner.is_waiting()
    	wave_label.visible = runner != null and not waiting
    	enemies_label.visible = runner != null and not waiting
    	timer_label.visible = waiting
    	skip_button.visible = waiting
    	if runner == null:
    		return
    	if waiting:
    		var next := runner.wave + 1
    		var what := "Boss wave" if next > runner.wave_count() else "Wave %d" % next
    		timer_label.text = "%s in %s" % [what, StageResult.clock(runner.countdown())]
    	else:
    		wave_label.text = "Boss wave" if runner.is_boss_wave() else "Wave %d/%d" % [runner.wave, runner.wave_count()]
    		enemies_label.text = "Enemies: %d" % runner.alive()
    ```
  - `BossBar`:
    ```gdscript
    class_name BossBar
    extends Control
    ## Under the stage info while a boss lives: its name over a wide red health
    ## bar. It finds the boss itself (the enemy whose kind is &"boss").
    ## `phase_text` is for Act 6's Thresh ("Phase 1 / 2").

    const SIZE := Vector2(600, 22)
    const FILL := Color("c8312b")

    var boss: EnemyUnit
    var phase_text := ""


    func _ready() -> void:
    	mouse_filter = Control.MOUSE_FILTER_IGNORE
    	custom_minimum_size = Vector2(SIZE.x, SIZE.y + 30.0)
    	visible = false


    func _process(_delta: float) -> void:
    	if not Lucian.is_target(boss):
    		boss = null
    		for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
    			if enemy is EnemyUnit and (enemy as EnemyUnit).data.kind == &"boss":
    				boss = enemy
    	visible = boss != null
    	queue_redraw()


    func _draw() -> void:
    	if boss == null:
    		return
    	var font := ThemeDB.fallback_font
    	var title := boss.data.display_name + ("   " + phase_text if phase_text != "" else "")
    	draw_string_outline(font, Vector2(0, 20), title, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 20, 5, Color.BLACK)
    	draw_string(font, Vector2(0, 20), title, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 20, UiStyle.TITLE_COLOR)
    	var bar := Rect2(0, 28, SIZE.x, SIZE.y)
    	draw_rect(bar.grow(2.0), Color(0, 0, 0, 0.85))
    	draw_rect(Rect2(bar.position, Vector2(SIZE.x * clampf(boss.hp / boss.max_hp, 0.0, 1.0), SIZE.y)), FILL)
    	var text := "%d / %d" % [roundi(boss.hp), roundi(boss.max_hp)]
    	draw_string_outline(font, bar.position + Vector2(0, 17), text, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 15, 4, Color.BLACK)
    	draw_string(font, bar.position + Vector2(0, 17), text, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 15, Color.WHITE)
    ```
  - `Radar`:
    ```gdscript
    class_name Radar
    extends Control
    ## Bottom right: the map as a dark panel with dots, no terrain. Lucian is a
    ## blue dot, an enemy red (an elite bigger), a boss a red skull; Senna a
    ## small pale-blue dot and the merchant gold. Never takes clicks, so
    ## right-clicks under it still move Lucian.

    const WIDTH := 260.0
    const SKULL := preload("res://assets/art/ui/skull.svg")
    const DOT := 4.0
    const ELITE_DOT := 7.0
    const SKULL_SIZE := 16.0
    const LUCIAN_DOT := 6.0
    const LUCIAN_COLOR := Color("4fa8ff")
    const ENEMY_COLOR := Color("e0475a")
    const ALLY_COLOR := Color("a8d8ff")
    const MERCHANT_COLOR := Color("ffcf5a")

    var bounds := Rect2(0, 0, 4800, 2700)
    var lucian: Lucian


    func _ready() -> void:
    	mouse_filter = Control.MOUSE_FILTER_IGNORE


    func setup(map_bounds: Rect2, target: Lucian) -> void:
    	bounds = map_bounds
    	lucian = target
    	custom_minimum_size = Vector2(WIDTH, roundf(WIDTH * bounds.size.y / bounds.size.x))
    	size = custom_minimum_size


    ## Where a world point sits on the radar.
    func to_radar(point: Vector2) -> Vector2:
    	return (point - bounds.position) / bounds.size * size


    static func dot_size(kind: StringName) -> float:
    	match kind:
    		&"boss":
    			return SKULL_SIZE
    		&"elite":
    			return ELITE_DOT
    	return DOT


    func _process(_delta: float) -> void:
    	queue_redraw()


    func _draw() -> void:
    	draw_style_box(UiStyle.panel(Color(0.04, 0.05, 0.07, 0.88), Color(0.36, 0.4, 0.48), 2, 0.0, 6), Rect2(Vector2.ZERO, size))
    	for merchant: Node2D in get_tree().get_nodes_in_group(&"merchants"):
    		draw_circle(to_radar(merchant.global_position), DOT, MERCHANT_COLOR)
    	for ally: Node2D in get_tree().get_nodes_in_group(&"allies"):
    		draw_circle(to_radar(ally.global_position), DOT, ALLY_COLOR)
    	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
    		var kind := (enemy as EnemyUnit).data.kind if enemy is EnemyUnit else &"normal"
    		var at := to_radar(enemy.global_position)
    		if kind == &"boss":
    			draw_texture_rect(SKULL, Rect2(at - Vector2.ONE * SKULL_SIZE * 0.5, Vector2.ONE * SKULL_SIZE), false, ENEMY_COLOR)
    		else:
    			draw_circle(at, dot_size(kind), ENEMY_COLOR)
    	if is_instance_valid(lucian):
    		var at := to_radar(lucian.global_position)
    		draw_circle(at, LUCIAN_DOT + 1.5, Color.WHITE)
    		draw_circle(at, LUCIAN_DOT, LUCIAN_COLOR)
    ```
  - `Hud`:
    - `setup(target, stage_wallet, stage: Stage = null)` keeps its body.
    - It sets `stage_info.setup(stage.run.display_name if stage else "Training", stage.runner if stage else null)`, `stage_info.skip_pressed.connect(stage.skip_break)` when there is a stage, and `radar.setup(stage.arena.get_bounds() if stage else Rect2(0, 0, 4800, 2700), target)`.
    - Build in `_ready`:
      - `stage_info` in the HUD panel style (the bottom panel's stylebox), `PRESET_CENTER_TOP`, offset top 12, growing both ways.
      - `boss_bar` centered under it (offset top 72).
      - `radar` at `PRESET_BOTTOM_RIGHT`, 12 px from both edges, growing up and left.
    - `_fps_label` moves to `PRESET_TOP_LEFT`, offset (12, 8).
    - The gold panel gains three essence pairs (16 px gap, 26 px icon and label) after the coin. `_process` shows a pair only while `stage.collected[kind] > 0`.
    - `Stage._ready` calls `hud.setup(lucian, wallet, self)` after `_start_waves()`, so the runner exists.
- [ ] **Step 4:** Run the file, then the full suite → PASS.
- [ ] **Step 5:** Commit `"Stage HUD: wave counter with the break timer and Skip, boss bar, essences collected, radar"`.

---

### Task 10: Act 1: Senna, Thresh, the tutorial tips and the cutscene (+ art)

**Files:**
- Create: `src/allies/senna.gd`, `src/enemies/boss.gd`, `src/enemies/bosses/thresh.gd`, `src/stage/cutscene.gd`, `src/stage/cutscenes/thresh_takes_senna.gd`, `src/ui/hud/tip_banner.gd`, `data/enemies/thresh_1.tres`, `assets/art/enemies/thresh.svg`, `assets/art/npc/senna.svg`.
- Modify: `src/stage/stage.gd`, `src/core/wave_runner.gd` (`skip_to_boss`), `src/ui/hud/hud.gd` (`tips`).
- Test: `tests/unit/test_act1.gd`; add `thresh_1` to `test_enemy_data_files.gd`.

**Interfaces — Produces:**
- `Boss extends EnemyUnit`: `add_skill(id, cooldown, reach, first_delay, use: Callable)`, `skill_hit(amount, type, source) -> DamageInfo`, `_can_use(id) -> bool`, `busy_left`.
- `Thresh`:
  - `signal phase_ended`, `stopped`, `PHASE_END`, `CHAIN_COLOR`, `LANTERN_OFFSET`.
  - Skills: `death_sentence() -> float`, `flay() -> float`.
- `Senna` (Node2D): `lucian`, `projectile_parent`, `visuals`, `REACH`, `DAMAGE`, `INTERVAL`.
- `Cutscene` (CanvasLayer):
  - `start(stage)`, `skip()`, `skipped`, `skip_button`, `signal done`.
  - Helpers: `caption(who, text)`, `pan_to(point, seconds := 0.8)`, `wait(seconds)`, `move(node, to, seconds)`.
- `ThreshTakesSenna extends Cutscene`.
- `TipBanner` (PanelContainer): `show_tip(id, text)`, `TIME`, `label`.
- `WaveRunner.skip_to_boss()`.
- `Stage`: `senna`, `boss_unit`, `cutscene`, `freeze(on)`, `jump_to_boss_wave()`.

**Rewards when the cutscene ends:**
- Thresh's 100 blue and 5 orange (`KillRewards` for his data).
- `award_boss(&"thresh_1", 10, 0)` through `_on_cleared`.
- The lines "Lucian takes Senna's gun: two guns from now on" and "E – Relentless Pursuit is free in the Evolution Tree".

- [ ] **Step 1: Failing tests** (`test_act1.gd`; `SaveGame.instance().reset()` in `before_each`, unpause in `after_each`):
  ```gdscript
  extends GutTest

  var lucian: Lucian


  func before_each() -> void:
  	SaveGame.instance().reset()
  	lucian = load("res://src/lucian/lucian.tscn").instantiate()
  	add_child_autofree(lucian)


  func after_each() -> void:
  	get_tree().paused = false


  func _thresh(at: Vector2) -> Thresh:
  	var thresh := Thresh.new()
  	thresh.setup(load("res://data/enemies/thresh_1.tres"), 1, 1, lucian)
  	thresh.position = at
  	add_child_autofree(thresh)
  	return thresh


  func test_the_hook_pulls_lucian_in() -> void:
  	lucian.global_position = Vector2(700, 0)
  	var thresh := _thresh(Vector2.ZERO)
  	await wait_physics_frames(1)
  	thresh.death_sentence()
  	await wait_seconds(Thresh.HOOK_WARN + 0.9)
  	assert_lt(lucian.global_position.distance_to(thresh.global_position), 260.0)


  func test_banshees_veil_blocks_the_hook_and_its_pull() -> void:
  	lucian.inventory.put(Inventory.EQUIP_START, lucian.item_catalog.find(&"banshees_veil"))
  	lucian.global_position = Vector2(700, 0)
  	var thresh := _thresh(Vector2.ZERO)
  	await wait_physics_frames(1)
  	thresh.death_sentence()
  	await wait_seconds(Thresh.HOOK_WARN + 0.9)
  	assert_gt(lucian.global_position.x, 650.0)


  func test_flay_pushes_lucian_away() -> void:
  	lucian.global_position = Vector2(200, 0)
  	var thresh := _thresh(Vector2.ZERO)
  	await wait_physics_frames(1)
  	thresh.flay()
  	await wait_seconds(Thresh.FLAY_WARN + 0.4)
  	assert_gt(lucian.global_position.distance_to(thresh.global_position), 380.0)


  func test_the_fight_stops_at_half_health() -> void:
  	var thresh := _thresh(Vector2(2000, 0))
  	watch_signals(thresh)
  	thresh.take_damage(DamageInfo.create(2000.0, DamageInfo.Type.TRUE, &"test"))
  	thresh.take_damage(DamageInfo.create(500.0, DamageInfo.Type.TRUE, &"test"))
  	assert_signal_emit_count(thresh, "phase_ended", 1)
  	assert_almost_eq(thresh.hp, thresh.max_hp * Thresh.PHASE_END, 0.01)
  	assert_true(thresh.is_alive())


  func test_senna_shoots_the_nearest_enemy() -> void:
  	var senna := Senna.new()
  	senna.lucian = lucian
  	add_child_autofree(senna)
  	var dummy: TrainingDummy = load("res://src/enemies/training_dummy.tscn").instantiate()
  	dummy.position = Vector2(600, 0)
  	add_child_autofree(dummy)
  	await wait_seconds(Senna.INTERVAL + 0.6)
  	assert_lt(dummy.hp, dummy.max_hp)
  	assert_true(senna.is_in_group(&"allies"))
  	assert_false(senna.is_in_group(&"enemies"))


  func _act1_stage() -> Stage:
  	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
  	stage.setup(StageSetup.for_stage(SaveGame.instance(), 1, 1))
  	add_child_autofree(stage)
  	await wait_frames(2)
  	stage.lucian.invulnerable = true
  	return stage


  func test_the_first_play_is_the_tutorial() -> void:
  	var stage: Stage = await _act1_stage()
  	assert_not_null(stage.senna)
  	assert_true(stage.lucian.one_gun)
  	assert_eq(stage.lucian.next_gun(), LucianVisuals.Gun.LEFT)
  	assert_eq(stage.lucian.next_gun(), LucianVisuals.Gun.LEFT)
  	assert_eq(stage.runner.total_waves(), 3)


  func test_a_replay_has_no_senna_and_no_thresh() -> void:
  	SaveGame.instance().set_cleared(["1-1"] as Array[String])
  	var stage: Stage = await _act1_stage()
  	assert_null(stage.senna)
  	assert_eq(stage.runner.total_waves(), 2)


  func test_half_health_plays_the_cutscene_and_skip_clears_the_stage() -> void:
  	var stage: Stage = await _act1_stage()
  	stage.jump_to_boss_wave()
  	stage.runner.tick(0.1)
  	stage.runner.tick(0.1)
  	await wait_frames(1)
  	assert_is(stage.boss_unit, Thresh)
  	stage.boss_unit.take_damage(DamageInfo.create(5000.0, DamageInfo.Type.TRUE, &"test"))
  	await wait_frames(2)
  	assert_not_null(stage.cutscene)
  	stage.cutscene.skip_button.pressed.emit()
  	await wait_frames(2)
  	assert_eq(stage.result.title.text, "STAGE CLEARED")
  	assert_eq(stage.collected[Essences.PURPLE], 10)
  	assert_true("thresh_1" in SaveGame.instance().bosses)
  ```
  - `TipBanner`: one test that a tip shows once (a second `show_tip` with the same id adds nothing) and that queued tips wait their turn.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3: Implement.**
  - `WaveRunner`:
    ```gdscript
    ## Debug: the boss wave comes next, straight away (the enemies left don't count).
    func skip_to_boss() -> void:
    	if boss == &"":
    		return
    	_to_spawn.clear()
    	_alive = 0
    	wave = _waves.size()
    	state = State.BREAK
    	_countdown = 0.0
    ```
  - `Boss`:
    ```gdscript
    class_name Boss
    extends EnemyUnit
    ## A boss: its basic attack (a bolt when its data has a projectile speed),
    ## plus skills it uses one at a time, each behind a ground warning. A skill
    ## is {id, cooldown, range, use}; `use` returns how many seconds the boss is
    ## busy (no walking, no basic attacks). Skill hits are `from_skill`, so
    ## Banshee's Veil blocks them.

    var skills: Array[Dictionary] = []
    ## Seconds the boss is busy with a skill.
    var busy_left := 0.0

    var _cooldowns := {}


    ## `first_delay`: seconds into the fight before its first use.
    func add_skill(id: StringName, cooldown: float, reach: float, first_delay: float, use: Callable) -> void:
    	skills.append({"id": id, "cooldown": cooldown, "range": reach, "use": use})
    	_cooldowns[id] = first_delay


    func skill_hit(amount: float, type: DamageInfo.Type, source: StringName) -> DamageInfo:
    	var info := DamageInfo.create(amount, type, source, self)
    	info.from_skill = true
    	return info


    func _physics_process(delta: float) -> void:
    	for id: StringName in _cooldowns:
    		_cooldowns[id] = maxf(_cooldowns[id] - delta, 0.0)
    	busy_left = maxf(busy_left - delta, 0.0)
    	super(delta)


    func _think(delta: float) -> void:
    	if busy_left > 0.0:
    		return
    	for skill in skills:
    		if _cooldowns[skill.id] <= 0.0 and distance_to_target() <= skill.range and _can_use(skill.id):
    			_cooldowns[skill.id] = skill.cooldown
    			busy_left = skill.use.call()
    			return
    	super(delta)


    ## A skill's own condition (Comeuppance waits for 75% HP).
    func _can_use(_id: StringName) -> bool:
    	return true


    func _attack() -> void:
    	if data.projectile_speed > 0.0:
    		fire_bolt(make_hit(), data.projectile_speed, attack_range + 150.0)
    	else:
    		super()
    ```
  - `Thresh`:
    ```gdscript
    class_name Thresh
    extends Boss
    ## Act 1's Thresh, scripted. Death Sentence: a hook along a line warning
    ## that pulls Lucian in. Flay: a cone that pushes him away. At half HP the
    ## fight stops: `phase_ended` starts the cutscene, and nothing hurts him.

    signal phase_ended

    const HOOK_LENGTH := 1000.0
    const HOOK_WIDTH := 70.0
    const HOOK_WARN := 0.9
    const HOOK_SPEED := 1400.0
    const HOOK_DAMAGE := 80.0
    const HOOK_COOLDOWN := 9.0
    ## A hooked Lucian lands this far in front of Thresh.
    const PULL_GAP := 120.0
    const PULL_SPEED := 1600.0
    const FLAY_LENGTH := 400.0
    const FLAY_ANGLE := PI * 70.0 / 180.0
    const FLAY_WARN := 0.6
    const FLAY_DAMAGE := 60.0
    const FLAY_PUSH := 250.0
    const FLAY_COOLDOWN := 7.0
    ## The share of HP where Act 1's fight ends.
    const PHASE_END := 0.5
    const CHAIN_COLOR := Color("8fe3b0")
    ## Where his lantern hangs, from his center (the cutscene's soul flies there).
    const LANTERN_OFFSET := Vector2(-20, 46)

    var stopped := false


    func _ready() -> void:
    	super()
    	add_skill(&"death_sentence", HOOK_COOLDOWN, HOOK_LENGTH, 2.0, death_sentence)
    	add_skill(&"flay", FLAY_COOLDOWN, FLAY_LENGTH, 4.0, flay)


    ## The hook: a line warning, then the chain flies; a hit pulls Lucian in.
    func death_sentence() -> float:
    	var toward := global_position.direction_to(target.global_position)
    	face(target.global_position)
    	var warning := GroundWarning.line(global_position, toward, HOOK_LENGTH, HOOK_WIDTH, HOOK_WARN)
    	warning.fired.connect(_throw_hook.bind(toward))
    	warning_parent.add_child(warning)
    	return HOOK_WARN + HOOK_LENGTH / HOOK_SPEED


    ## Flay: a cone warning, then a hit that pushes Lucian away.
    func flay() -> float:
    	var toward := global_position.direction_to(target.global_position)
    	face(target.global_position)
    	var warning := GroundWarning.cone(global_position, toward, FLAY_LENGTH, FLAY_ANGLE, FLAY_WARN)
    	warning.fired.connect(_flay_lands.bind(warning))
    	warning_parent.add_child(warning)
    	return FLAY_WARN + 0.2


    func _think(delta: float) -> void:
    	if not stopped:
    		super(delta)


    ## HP never goes under half; reaching it ends the fight, once.
    func _lose_hp(amount: float) -> void:
    	if stopped:
    		return
    	super(minf(amount, maxf(hp - max_hp * PHASE_END, 0.0)))
    	if hp <= max_hp * PHASE_END:
    		stopped = true
    		phase_ended.emit()


    func _throw_hook(toward: Vector2) -> void:
    	if stopped:
    		return
    	var hook := fire_bolt(skill_hit(HOOK_DAMAGE, DamageInfo.Type.MAGIC, &"death_sentence"), HOOK_SPEED, HOOK_LENGTH, toward)
    	hook.hit_radius = HOOK_WIDTH * 0.5
    	hook.color = CHAIN_COLOR
    	hook.tether = self
    	hook.hit_lucian.connect(_pull)
    	Sfx.play(&"hook")


    func _pull() -> void:
    	if is_instance_valid(target):
    		target.displace(global_position + global_position.direction_to(target.global_position) * PULL_GAP, PULL_SPEED)


    func _flay_lands(warning: GroundWarning) -> void:
    	if stopped or not warning.covers(target.global_position, Lucian.HIT_RADIUS):
    		return
    	if target.take_damage(skill_hit(FLAY_DAMAGE, DamageInfo.Type.MAGIC, &"flay")):
    		target.displace(target.global_position + global_position.direction_to(target.global_position) * FLAY_PUSH, PULL_SPEED)
    ```
  - `data/enemies/thresh_1.tres`:
    - Stats: `kind = &"boss"`, `behavior = &"thresh"`, `max_hp = 3000.0`, `armor = 30.0`, `mr = 30.0`, `damage = 30.0`, `attack_range = 450.0`, `attack_interval = 1.8`, `move_speed = 300.0`, `radius = 44.0`, `projectile_speed = 900.0`.
    - Rewards: `gold = 300`, `purple_first = 10`, `purple_repeat = 0`.
  - `Senna`:
    ```gdscript
    class_name Senna
    extends Node2D
    ## Act 1's ally: follows Lucian, behind and to his left, and shoots the
    ## nearest enemy in reach. Enemies never target her (she isn't one of
    ## "enemies" and has no body), so she can't die before the cutscene.

    const ART := preload("res://assets/art/npc/senna.svg")
    ## Her place next to Lucian, turned with him.
    const FOLLOW_OFFSET := Vector2(-150, -90)
    const SPEED := 380.0
    const REACH := 900.0
    const DAMAGE := 45.0
    const INTERVAL := 1.5
    const SHOT_COLOR := Color("b8fff0")
    const SHOT_GLOW := Color(0.5, 1.0, 0.9, 0.5)

    var lucian: Lucian
    var projectile_parent: Node
    var visuals := Node2D.new()

    var _attack_left := 0.0


    func _ready() -> void:
    	add_to_group(&"allies")
    	var sprite := Sprite2D.new()
    	sprite.texture = ART
    	visuals.add_child(sprite)
    	add_child(visuals)
    	if projectile_parent == null:
    		projectile_parent = get_parent()


    func _physics_process(delta: float) -> void:
    	if not is_instance_valid(lucian):
    		return
    	var spot := lucian.global_position + FOLLOW_OFFSET.rotated(lucian.visuals.rotation)
    	var offset := spot - global_position
    	if offset.length() > 12.0:
    		global_position += offset.normalized() * minf(SPEED * delta * (1.0 + offset.length() / 400.0), offset.length())
    		visuals.rotation = offset.angle()
    	_attack_left = maxf(_attack_left - delta, 0.0)
    	var target := _nearest_enemy()
    	if target == null:
    		return
    	visuals.rotation = (target.global_position - global_position).angle()
    	if _attack_left <= 0.0:
    		_attack_left = INTERVAL
    		var shot := AttackProjectile.new()
    		shot.color = SHOT_COLOR
    		shot.glow_color = SHOT_GLOW
    		shot.launch(global_position + Vector2.from_angle(visuals.rotation) * 50.0, target, DamageInfo.create(DAMAGE, DamageInfo.Type.PHYSICAL, &"senna", self))
    		projectile_parent.add_child(shot)
    		Sfx.play(&"shot", -10.0)


    func _nearest_enemy() -> Enemy:
    	var best: Enemy = null
    	var best_distance := REACH
    	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
    		var distance := global_position.distance_to(enemy.global_position)
    		if distance <= best_distance:
    			best = enemy
    			best_distance = distance
    	return best
    ```
  - `Cutscene`:
    ```gdscript
    class_name Cutscene
    extends CanvasLayer
    ## A scripted scene over a frozen stage: letterbox bars, the HUD hidden,
    ## captions (Space or a click moves on, and each goes on by itself), and a
    ## Skip button that jumps to the end. Subclasses write _play() with the
    ## helpers; `done` fires once, skipped or not.

    signal done

    const LAYER := 38
    const BAR_HEIGHT := 120.0
    const CAPTION_TIME := 3.5

    var stage: Stage
    var skipped := false
    var skip_button := Button.new()

    var _bars: Array[ColorRect] = []
    var _speaker := UiStyle.label("", 22, UiStyle.GOLD_COLOR)
    var _caption := UiStyle.label("", 26, UiStyle.TEXT_COLOR)
    var _advance := false
    var _finished := false


    func _ready() -> void:
    	layer = LAYER
    	process_mode = PROCESS_MODE_ALWAYS
    	for top in [true, false]:
    		var bar := ColorRect.new()
    		bar.color = Color.BLACK
    		bar.set_anchors_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
    		bar.offset_top = -BAR_HEIGHT if top else 0.0
    		bar.offset_bottom = 0.0 if top else BAR_HEIGHT
    		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    		add_child(bar)
    		_bars.append(bar)
    	var text := VBoxContainer.new()
    	text.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    	text.offset_top = -BAR_HEIGHT + 16.0
    	text.grow_horizontal = Control.GROW_DIRECTION_BOTH
    	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
    	text.add_child(_speaker)
    	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    	_caption.custom_minimum_size.x = 1100.0
    	text.add_child(_caption)
    	add_child(text)
    	skip_button.text = "Skip"
    	skip_button.custom_minimum_size = Vector2(120, 44)
    	UiStyle.style_button(skip_button, 20)
    	skip_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    	skip_button.offset_left = -140.0
    	skip_button.offset_top = 20.0
    	skip_button.pressed.connect(skip)
    	add_child(skip_button)


    ## Freezes the stage and plays the scene.
    func start(owner_stage: Stage) -> void:
    	stage = owner_stage
    	stage.add_child(self)
    	stage.freeze(true)
    	_run()


    func skip() -> void:
    	skipped = true
    	_finish()


    ## Shows a line until Space, a click, or CAPTION_TIME.
    func caption(who: String, text: String) -> void:
    	if skipped:
    		return
    	_speaker.text = who
    	_caption.text = text
    	_advance = false
    	var left := CAPTION_TIME
    	while left > 0.0 and not _advance and not skipped:
    		await get_tree().process_frame
    		left -= get_process_delta_time()
    	_caption.text = ""
    	_speaker.text = ""


    func wait(seconds: float) -> void:
    	if not skipped:
    		await get_tree().create_timer(seconds, true).timeout


    func pan_to(point: Vector2, seconds := 0.8) -> void:
    	if skipped:
    		return
    	var tween := create_tween()
    	tween.tween_property(stage.camera, "global_position", point, seconds).set_trans(Tween.TRANS_SINE)
    	await tween.finished


    func move(node: Node2D, to: Vector2, seconds: float) -> void:
    	if skipped:
    		return
    	var tween := create_tween()
    	tween.tween_property(node, "global_position", to, seconds)
    	await tween.finished


    ## Subclasses: the scene, with the helpers above.
    func _play() -> void:
    	pass


    func _unhandled_input(event: InputEvent) -> void:
    	var key := event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_SPACE
    	var click := event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
    	if key or click:
    		_advance = true
    		get_viewport().set_input_as_handled()


    func _run() -> void:
    	await _play()
    	_finish()
    	queue_free()


    func _finish() -> void:
    	if _finished:
    		return
    	_finished = true
    	visible = false
    	stage.freeze(false)
    	done.emit()
    ```
    The Skip click reaches the button first (GUI input comes before `_unhandled_input`), so it never also counts as "advance". The scene's own coroutine runs on to its end after a skip (each helper returns at once), then frees the node.
  - `ThreshTakesSenna._play()` (the steps, each a helper call):
    1. `pan_to` Thresh. `caption("Thresh", "Such a bright soul... it will make a fine light.")`.
    2. A `Line2D` chain (width 6, `Thresh.CHAIN_COLOR`) grows from Thresh to Senna over 0.35 s (`tween_method` on its second point), with `Sfx.play(&"hook")`. `caption("Lucian", "SENNA!")`.
    3. `move` Senna to 100 in front of Thresh over 0.5 s, with the chain following. Her visuals turn grey (`modulate`) and tip over (`rotation` + 1.4).
    4. A **soul orb**: a small Node2D that draws a white-teal glowing circle. It rises from Senna and flies to `thresh.global_position + Thresh.LANTERN_OFFSET` over 1.2 s, then frees. The lantern glows: a green circle tween on Thresh's visuals. `caption("Thresh", "Your light is mine now.")`.
    5. Thresh sinks into the river: his `scale` → 0.3 and `modulate:a` → 0 over 1.2 s, with a ring drawn on the water. The chain frees.
    6. `pan_to` Lucian. `move` him to where Senna fell over 1.0 s. Senna's body fades.
    7. `caption("", "Lucian takes up Senna's gun. Relentless Pursuit (E) is now free in the Evolution Tree.")`.
    8. When skipped, `_finish` still leaves the stage right: the stage's `done` handler frees Senna and Thresh.
  - `TipBanner`:
    ```gdscript
    class_name TipBanner
    extends PanelContainer
    ## Act 1's tips under the stage info: one at a time, each shown once for
    ## TIME seconds; later ones wait their turn.

    const TIME := 7.0

    var label := UiStyle.label("", 20, UiStyle.TEXT_COLOR)

    var _queue: Array[String] = []
    var _shown := {}
    var _left := 0.0


    func _ready() -> void:
    	mouse_filter = Control.MOUSE_FILTER_IGNORE
    	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    	add_child(label)
    	visible = false


    func show_tip(id: StringName, text: String) -> void:
    	if _shown.has(id):
    		return
    	_shown[id] = true
    	_queue.append(text)


    func _process(delta: float) -> void:
    	if _left > 0.0:
    		_left -= delta
    		if _left <= 0.0:
    			visible = false
    	elif not _queue.is_empty():
    		label.text = _queue.pop_front()
    		visible = true
    		_left = TIME
    ```
    `Hud` adds `tips`: the gold-bordered `UiStyle.panel()`, `PRESET_CENTER_TOP`, offset top 130, growing both ways.
  - `Stage`:
    ```gdscript
    var senna: Senna
    ## The boss of the boss wave, once spawned.
    var boss_unit: EnemyUnit
    var cutscene: Cutscene


    ## Cutscenes: the world stops (tweens still move it), the HUD hides, and
    ## ESC and P do nothing.
    func freeze(on: bool) -> void:
    	for node: Node in [$World, $Warnings, $Projectiles, camera]:
    		node.process_mode = Node.PROCESS_MODE_DISABLED if on else Node.PROCESS_MODE_INHERIT
    	hud.visible = not on
    	screens.locked = on
    	lucian.invulnerable = on


    ## Debug and tests: every enemy goes (no rewards) and the boss wave comes next.
    func jump_to_boss_wave() -> void:
    	if runner == null or run.boss == &"":
    		return
    	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
    		enemy.remove_from_group(&"enemies")
    		enemy.queue_free()
    	runner.skip_to_boss()
    ```
    - `_new_unit` matches `data.behavior`: `&"thresh"` → `Thresh.new()`, else `Minion.new()`.
    - `_spawn_wave_enemy` keeps the boss in `boss_unit`. For a `Thresh` it connects `phase_ended` to `_on_thresh_phase_ended`.
    - `_ready`, when `run.tutorial`:
      - `_add_senna()`: a `Senna` at `arena.ally_start`, with `lucian`, `projectile_parent = $Projectiles`, in `$World`.
      - Tips:
        - At once: "Right-click to move. Hold it to keep walking."
        - On the first spawn: "Left-click an enemy to attack it."
        - On the first kill: "Hold A and left-click to attack the nearest enemy."
        - On the first siege spawn: "A red circle marks where a shell will land. Step out of it!"
        - On the first `break_started`: "Right-click the merchant to buy items with your gold."
        - On `boss_wave_started`: "Thresh's hook flies along the red line. Move sideways!"
      - Key names come from `GameSettings.instance().key_label(&"move")`, `(&"attack")` and `(&"attack_move")`. Write the texts as `"%s to move…" % key` where a key is named.
    ```gdscript
    func _on_thresh_phase_ended() -> void:
    	for node: Node in $Warnings.get_children() + $Projectiles.get_children():
    		node.queue_free()
    	cutscene = ThreshTakesSenna.new()
    	cutscene.done.connect(_on_cutscene_done)
    	cutscene.start(self)


    ## Thresh is beaten for this act: his blue and orange now, his purple in _on_cleared.
    func _on_cutscene_done() -> void:
    	var reward := KillRewards.roll(boss_unit.data, run.act, run, rng)
    	add_essences(reward.blue, reward.orange, 0, lucian.global_position)
    	reward_lines.append("Lucian takes Senna's gun: two guns from now on")
    	reward_lines.append("E – Relentless Pursuit is free in the Evolution Tree")
    	for node: Node2D in [boss_unit, senna]:
    		if is_instance_valid(node):
    			node.queue_free()
    	runner.finish()
    ```
    Freeing Thresh leaves `&"enemies"` (and stops the boss bar), since `queue_free` removes him from the tree at the end of the frame. Call `boss_unit.remove_from_group(&"enemies")` first, so the radar and the bar drop him at once.
  - **Art:** `thresh.svg` and `senna.svg` from the Art table. Then `--import`.
- [ ] **Step 4:** Run the files, then the full suite → PASS.
- [ ] **Step 5:** Commit `"Act 1: Senna fights beside Lucian, Thresh's hook and Flay, tutorial tips, and the cutscene where Thresh takes Senna"`.

---

### Task 11: Act 2: Akshan (+ art)

**Files:**
- Create: `src/enemies/bosses/akshan.gd`, `data/enemies/akshan.tres`, `assets/art/enemies/akshan.svg`.
- Modify: `src/stage/stage.gd` (`_new_unit`: `&"akshan"` → `Akshan.new()`).
- Test: `tests/unit/test_akshan.gd`; add `akshan` to `test_enemy_data_files.gd`.

**Interfaces — Produces:** `Akshan`:
- Skills: `avengerang() -> float`, `heroic_swing() -> float`, `comeuppance() -> float`, plus `start_swing(center)` and `start_burst()`.
- Constants as below. `swinging() -> bool`.

**`data/enemies/akshan.tres`:**
- Stats: `kind = &"boss"`, `behavior = &"akshan"`, `max_hp = 5000.0`, `armor = 35.0`, `mr = 30.0`, `damage = 28.0`, `attack_range = 550.0`, `attack_interval = 1.4`, `move_speed = 320.0`, `radius = 40.0`, `projectile_speed = 1200.0`.
- Rewards: `gold = 300`, `purple_first = 10`, `purple_repeat = 2`.

- [ ] **Step 1: Failing tests** (`test_akshan.gd`):
  ```gdscript
  extends GutTest

  var lucian: Lucian


  func before_each() -> void:
  	lucian = load("res://src/lucian/lucian.tscn").instantiate()
  	add_child_autofree(lucian)


  func _akshan(at: Vector2) -> Akshan:
  	var akshan := Akshan.new()
  	akshan.setup(load("res://data/enemies/akshan.tres"), 2, 1, lucian)
  	akshan.position = at
  	add_child_autofree(akshan)
  	return akshan


  func _wall(at: Vector2) -> void:
  	var wall := StaticBody2D.new()
  	wall.collision_layer = Layers.WORLD
  	var shape := CollisionShape2D.new()
  	var circle := CircleShape2D.new()
  	circle.radius = 70.0
  	shape.shape = circle
  	wall.position = at
  	wall.add_child(shape)
  	add_child_autofree(wall)


  func test_the_boomerang_hits_once_out_and_once_back() -> void:
  	lucian.global_position = Vector2(450, 0)
  	var thrower := Node2D.new()
  	add_child_autofree(thrower)
  	var boomerang := EnemyProjectile.new()
  	boomerang.launch(Vector2.ZERO, Vector2.RIGHT, DamageInfo.create(10.0, DamageInfo.Type.TRUE, &"avengerang"), lucian)
  	boomerang.speed = Akshan.BOOMERANG_SPEED
  	boomerang.max_range = Akshan.BOOMERANG_LENGTH
  	boomerang.hit_radius = 22.0
  	boomerang.return_to = thrower
  	add_child(boomerang)
  	watch_signals(lucian)
  	await wait_seconds(2.2)
  	assert_signal_emit_count(lucian, "damage_received", 2)


  func test_swing_bolts_fly_outward() -> void:
  	var akshan := _akshan(Vector2(3000, 0))
  	await wait_physics_frames(1)
  	akshan.start_swing(Vector2(3000, 300))
  	await wait_seconds(0.7)
  	var bolts := get_children().filter(func(child: Node) -> bool: return child is EnemyProjectile)
  	assert_gt(bolts.size(), 0)
  	for bolt: EnemyProjectile in bolts:
  		var outward := (bolt.global_position - Vector2(3000, 300)).normalized()
  		assert_gt(bolt.direction.dot(outward), 0.9)


  func test_a_pillar_stops_comeuppance() -> void:
  	var akshan := _akshan(Vector2.ZERO)
  	lucian.global_position = Vector2(600, 0)
  	_wall(Vector2(300, 0))
  	await wait_physics_frames(2)
  	var before := lucian.hp
  	akshan.start_burst()
  	await wait_seconds(1.2)
  	assert_gte(lucian.hp, before)


  func test_comeuppance_hits_in_the_open_and_misses_out_of_range() -> void:
  	var akshan := _akshan(Vector2.ZERO)
  	lucian.global_position = Vector2(600, 0)
  	await wait_physics_frames(1)
  	var before := lucian.hp
  	akshan.start_burst()
  	await wait_seconds(1.0)
  	assert_lt(lucian.hp, before)
  	lucian.global_position = Vector2(1600, 0)
  	before = lucian.hp
  	akshan.start_burst()
  	await wait_seconds(1.6)
  	assert_gte(lucian.hp, before)


  func test_comeuppance_waits_for_75_percent() -> void:
  	var akshan := _akshan(Vector2(3000, 0))
  	assert_false(akshan._can_use(&"comeuppance"))
  	akshan.hp = akshan.max_hp * 0.7
  	assert_true(akshan._can_use(&"comeuppance"))


  func test_purple_is_10_then_2() -> void:
  	var data: EnemyData = load("res://data/enemies/akshan.tres")
  	var save := SaveGame.instance()
  	save.reset()
  	assert_eq(save.award_boss("akshan", data.purple_first, data.purple_repeat), 10)
  	assert_eq(save.award_boss("akshan", data.purple_first, data.purple_repeat), 2)
  ```
  In the first test, Lucian's regen can hide a small hit. The test counts `damage_received`, not HP.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3: Implement.**
  ```gdscript
  class_name Akshan
  extends Boss
  ## Act 2's boss, weakened: lower damage, slower attacks, longer warnings.
  ## Avengerang: a boomerang out and back that hits each way. Heroic Swing: he
  ## swings around a grapple point, firing outward. Comeuppance: a lock line on
  ## Lucian, then a burst of shots that pillars stop. Comeuppance waits until
  ## he is down to 75% HP.

  const BOOMERANG_LENGTH := 900.0
  const BOOMERANG_SPEED := 1000.0
  const BOOMERANG_WARN := 0.8
  const BOOMERANG_DAMAGE := 70.0
  const BOOMERANG_COOLDOWN := 8.0
  const SWING_RADIUS := 300.0
  const SWING_WARN := 1.2
  const SWING_TIME := 2.5
  const SWING_SHOT_GAP := 0.3
  const SWING_DAMAGE := 25.0
  const SWING_BOLT_SPEED := 700.0
  const SWING_BOLT_RANGE := 600.0
  const SWING_COOLDOWN := 14.0
  ## Heroic Swing is used when Lucian is this close.
  const SWING_REACH := 800.0
  const LOCK_TIME := 2.0
  const BURST_SHOTS := 6
  const BURST_GAP := 0.12
  const BURST_DAMAGE := 40.0
  const BURST_SPEED := 1600.0
  const BURST_RANGE := 1200.0
  const BURST_COOLDOWN := 20.0
  const BURST_HP := 0.75
  const GOLD := Color("ffe08a")

  var _swing_center := Vector2.ZERO
  var _swing_left := 0.0
  var _swing_angle := 0.0
  var _swing_shot_left := 0.0
  var _burst_left := 0
  var _burst_gap_left := 0.0


  func _ready() -> void:
  	super()
  	add_skill(&"avengerang", BOOMERANG_COOLDOWN, BOOMERANG_LENGTH, 2.0, avengerang)
  	add_skill(&"heroic_swing", SWING_COOLDOWN, SWING_REACH, 5.0, heroic_swing)
  	add_skill(&"comeuppance", BURST_COOLDOWN, BURST_RANGE, 0.0, comeuppance)


  func swinging() -> bool:
  	return _swing_left > 0.0


  func avengerang() -> float:
  	var toward := global_position.direction_to(target.global_position)
  	face(target.global_position)
  	var warning := GroundWarning.line(global_position, toward, BOOMERANG_LENGTH, 60.0, BOOMERANG_WARN)
  	warning.fired.connect(_throw_boomerang.bind(toward))
  	warning_parent.add_child(warning)
  	return BOOMERANG_WARN + 0.3


  func heroic_swing() -> float:
  	var center := target.global_position + target.global_position.direction_to(global_position) * 150.0
  	var warning := GroundWarning.circle(center, SWING_RADIUS, SWING_WARN)
  	warning.fired.connect(start_swing.bind(center))
  	warning_parent.add_child(warning)
  	return SWING_WARN + SWING_TIME


  func comeuppance() -> float:
  	var warning := GroundWarning.lock(global_position, target, LOCK_TIME)
  	warning.fired.connect(start_burst)
  	warning_parent.add_child(warning)
  	return LOCK_TIME + BURST_SHOTS * BURST_GAP


  ## Swings once around `center`, a bolt outward every SWING_SHOT_GAP.
  func start_swing(center: Vector2) -> void:
  	if dead:
  		return
  	_swing_center = center
  	_swing_left = SWING_TIME
  	_swing_shot_left = 0.0
  	_swing_angle = (global_position - center).angle()


  ## BURST_SHOTS shots at Lucian, BURST_GAP apart.
  func start_burst() -> void:
  	if not dead:
  		_burst_left = BURST_SHOTS
  		_burst_gap_left = 0.0


  func _can_use(id: StringName) -> bool:
  	return id != &"comeuppance" or hp <= max_hp * BURST_HP


  func _physics_process(delta: float) -> void:
  	super(delta)
  	if dead:
  		return
  	if _swing_left > 0.0:
  		_swing_left -= delta
  		_swing_angle += TAU / SWING_TIME * delta
  		global_position = _swing_center + Vector2.from_angle(_swing_angle) * SWING_RADIUS
  		face(global_position + Vector2.from_angle(_swing_angle))
  		_swing_shot_left -= delta
  		if _swing_shot_left <= 0.0:
  			_swing_shot_left = SWING_SHOT_GAP
  			var bolt := fire_bolt(skill_hit(SWING_DAMAGE, DamageInfo.Type.PHYSICAL, &"heroic_swing"), SWING_BOLT_SPEED, SWING_BOLT_RANGE, Vector2.from_angle(_swing_angle))
  			bolt.color = GOLD
  	if _burst_left > 0 and can_fight():
  		_burst_gap_left -= delta
  		if _burst_gap_left <= 0.0:
  			_burst_gap_left = BURST_GAP
  			_burst_left -= 1
  			face(target.global_position)
  			var shot := fire_bolt(skill_hit(BURST_DAMAGE, DamageInfo.Type.PHYSICAL, &"comeuppance"), BURST_SPEED, BURST_RANGE)
  			shot.color = GOLD
  			Sfx.play(&"shot", -4.0)


  func _throw_boomerang(toward: Vector2) -> void:
  	if dead:
  		return
  	var boomerang := fire_bolt(skill_hit(BOOMERANG_DAMAGE, DamageInfo.Type.PHYSICAL, &"avengerang"), BOOMERANG_SPEED, BOOMERANG_LENGTH, toward)
  	boomerang.return_to = self
  	boomerang.hit_radius = 22.0
  	boomerang.color = GOLD
  ```
  - At the start of a swing he is set onto the circle at once. A small jump is fine, because the warning showed where he would go.
  - **Art:** `akshan.svg`. Then `--import`.
- [ ] **Step 4:** Run the files, then the full suite → PASS.
- [ ] **Step 5:** Commit `"Act 2: Akshan with Avengerang, Heroic Swing and Comeuppance"`.

---

### Task 12: Journey starts the acts

**Files:**
- Modify: `src/ui/main/journey/stage_card.gd`, `act_page.gd`, `journey_section.gd`; `src/ui/main/main_screen.gd`; `src/main/game.gd`; `src/core/wave_plan.gd` (`has_stage`).
- Test: extend `tests/unit/test_journey_section.gd` and `tests/unit/test_game.gd`.

**Interfaces — Produces:**
- `StageCard`: `selected`, `set_selected(on)`, `signal chosen`.
- `ActPage`: `selected`, `select(stage)`, `default_stage(cleared) -> int`, `playable`, `signal start_pressed(stage: int)`.
- `JourneySection`: `signal start_stage(act: int, stage: int)`, `focus_act`, `open_on(act := 0)`.
- `MainScreen.focus_act`. `Game.show_main_screen(focus_act := 0)`.
- `WavePlan.has_stage(stage_id) -> bool`.

**Rules:**
- An act page can start stages only when `WavePlan.has_stage()` knows its first stage (Acts 1 and 2 now). Acts 3–6 keep Start disabled, with the hover text "Act N comes in a later phase".
- `open_on(act)`:
  - The act just played, if given and open.
  - Else the first *playable* act with an open, uncleared stage.
  - Else Training.

- [ ] **Step 1: Failing tests** (`test_journey_section.gd`):
  - Replace `test_start_buttons_of_acts_and_endless_are_disabled` with:
    - **Act 1:** Start is enabled on a new game.
    - **Acts 2 and 3:**
      - Act 2's Start is disabled while its tab is locked.
      - After debug Acts cleared 2, Act 3's Start is disabled ("comes in a later phase").
    - **Endless:** Start stays disabled.
  - `test_a_locked_card_cannot_be_chosen`: on Act 2 with only `"1-1"` cleared, `cards[1].chosen` does nothing and `selected == 1`.
  - `test_the_default_stage_is_the_first_open_uncleared_one`: with `["1-1", "2-1"]` cleared, Act 2's `selected == 2`.
  - `test_start_emits_the_act_and_stage`: `watch_signals(section)`, select stage 2 of Act 2 (with `"2-1"` cleared), press Start → `start_stage` with `[2, 2]`.
  - `test_it_opens_on_the_first_act_with_work_to_do`: a new game opens on Act 1. With `"1-1"` cleared it opens on Act 2. With Acts 1–2 cleared it opens on Training.
  - `test_game.gd`: after a cleared `2-1` (as in Task 8's test), Journey is on Act 2 (`journey.current == 1`).
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3: Implement.**
  - `StageCard`:
    ```gdscript
    ## The card was clicked (open cards only).
    signal chosen

    var selected := false


    func _gui_input(event: InputEvent) -> void:
    	var click := event as InputEventMouseButton
    	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT and not locked:
    		chosen.emit()
    		accept_event()


    func set_selected(on: bool) -> void:
    	selected = on
    	queue_redraw()
    ```
    - `set_state` sets `mouse_default_cursor_shape` to `CURSOR_POINTING_HAND` when open and `CURSOR_ARROW` when locked.
    - `_draw` adds, when `selected`, a second outline 5 px outside the card in `UiStyle.TITLE_COLOR`, 3 px wide.
  - `ActPage`:
    ```gdscript
    signal start_pressed(stage: int)

    ## The stage Start plays (0: none open).
    var selected := 0
    ## Acts with waves and a map; the others wait for a later phase.
    var playable := false
    ```
    - In `_init`:
      - `playable = WavePlan.has_stage(Journey.stage_id(act, 1))`.
      - Each card's `chosen` → `select(stage)`.
      - Start is styled like Start Training (gold, `selected = true` in `style_button`) and pressed → `start_pressed.emit(selected)`.
      - When not playable, Start is disabled with the meta "Act %d comes in a later phase".
    ```gdscript
    func select(stage: int) -> void:
    	if stage < 1 or stage > cards.size() or cards[stage - 1].locked:
    		return
    	selected = stage
    	for i in cards.size():
    		cards[i].set_selected(i + 1 == stage)
    	start_button.text = "Start" if cards.size() == 1 else "Start stage %d" % stage


    ## The first open stage not cleared yet, else the last open one; 0 if none.
    func default_stage(cleared: Array[String]) -> int:
    	var last_open := 0
    	for stage in range(1, cards.size() + 1):
    		if not Journey.is_stage_open(act, stage, cleared):
    			continue
    		if not Journey.stage_id(act, stage) in cleared:
    			return stage
    		last_open = stage
    	return last_open


    func refresh(cleared: Array[String]) -> void:
    	for i in cards.size():
    		cards[i].set_state(not Journey.is_stage_open(act, i + 1, cleared), Journey.stage_id(act, i + 1) in cleared)
    	if selected == 0 or cards[selected - 1].locked:
    		selected = 0
    		select(default_stage(cleared))
    	start_button.disabled = not playable or selected == 0
    ```
  - `JourneySection`:
    - Add `signal start_stage(act: int, stage: int)` and `var focus_act := 0`.
    - Connect each page: `page.start_pressed.connect(func(stage: int) -> void: start_stage.emit(page.act, stage))`.
    - `_ready` ends with `open_on(focus_act)` instead of `show_tab(TRAINING_TAB)`.
    - Its doc comment drops "It opens on Training".
    ```gdscript
    ## The tab to open on: `act` (just played) if it is open, else the first
    ## playable act with an open stage not cleared yet, else Training.
    func open_on(act := 0) -> void:
    	var cleared := SaveGame.instance().cleared
    	if act > 0 and Journey.is_act_open(act, cleared):
    		show_tab(act - 1)
    		return
    	for page in act_pages:
    		if page.playable and Journey.is_act_open(page.act, cleared) and page.default_stage(cleared) > 0 \
    				and not Journey.stage_id(page.act, page.default_stage(cleared)) in cleared:
    			show_tab(page.act - 1)
    			return
    	show_tab(TRAINING_TAB)
    ```
  - `MainScreen`:
    - `## The act Journey opens on (the one just played), or 0.` with `var focus_act := 0`. Set it before the screen is added.
    - `_build` sets `journey.focus_act = focus_act` and connects `journey.start_stage` → `_start_stage`.
    ```gdscript
    func _start_stage(act: int, stage: int) -> void:
    	start_requested.emit(StageSetup.for_stage(SaveGame.instance(), act, stage))
    ```
  - `Game`:
    - `show_main_screen(focus_act := 0)` sets `main.focus_act`.
    - `_on_stage_finished` calls `show_main_screen.call_deferred(_run.act)`.
  - `WavePlan`: `static func has_stage(stage_id: String) -> bool: return STAGES.has(stage_id)`.
- [ ] **Step 4:** Run → PASS. Full suite → PASS (update `test_journey_section`'s Training-first expectations to `open_on`).
- [ ] **Step 5:** Commit `"Journey: pick a stage of Act 1 or 2 and Start it; back on its act afterwards"`.

---

### Task 13: Title screen and Leave to main menu

**Files:**
- Create: `src/ui/menu/slot_list.gd`, `src/ui/title/title_screen.gd`, `assets/art/ui/title_lantern.svg`.
- Modify: `src/ui/main/gear_menu.gd`, `src/ui/main/main_screen.gd`, `src/main/game.gd`, `tests/tools/screenshot.gd` (`main_*` scenarios open the main screen first).
- Test: `tests/unit/test_title_screen.gd`; update `tests/unit/test_game.gd` and `tests/unit/test_main_screen.gd`.

**Interfaces — Produces:**
- `SlotList` (VBoxContainer): `buttons`, `refresh(current := 0, empty_enabled := true)`, `signal picked(slot: int, used: bool)`.
- `TitleScreen` (Control):
  - Parts: `settings`, `confirm`, `slot_list`, `load_button`, `error_label`.
  - `show_menu()`, `show_slots(loading: bool)`, `is_showing_slots() -> bool`, `find_button(text) -> Button`.
  - Signals: `new_game_started`, `game_loaded`, `exit_requested`.
- `GearMenu.leave_requested`. `MainScreen.leave_requested`.
- `Game`: `show_title()`, `ask_to_leave()`. Play time: `Game._process` adds to `SaveGame.play_time` everywhere but the title screen; pauses don't count (Game pauses with the tree).

- [ ] **Step 1: Failing tests.**
  - `test_title_screen.gd` (slot files deleted in `before_each`/`after_each`, as in `test_main_screen.gd`):
    ```gdscript
    extends GutTest

    var game: Game
    var quit_called := false


    func before_each() -> void:
    	quit_called = false
    	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
    		SaveGame._instance = SaveGame.new("user://test_title_save_slot_")
    	_delete_slots()
    	SaveGame.instance().load_slot(1)
    	game = load("res://src/main/game.tscn").instantiate()
    	game.quit_game = func() -> void: quit_called = true
    	add_child_autofree(game)


    func after_each() -> void:
    	get_tree().paused = false
    	_delete_slots()


    func _delete_slots() -> void:
    	var save := SaveGame.instance()
    	for n in range(1, SaveGame.SLOTS + 1):
    		for file in [save.path(n), save.backup_path(n)]:
    			if FileAccess.file_exists(file):
    				DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


    func _title() -> TitleScreen:
    	return game.screen as TitleScreen


    func test_the_game_opens_on_the_title_screen() -> void:
    	assert_is(game.screen, TitleScreen)


    func test_load_game_is_disabled_with_no_saves() -> void:
    	assert_true(_title().load_button.disabled)


    func test_a_new_game_in_an_empty_slot_starts_act_1() -> void:
    	_title().show_slots(false)
    	_title().slot_list.buttons[1].pressed.emit()
    	await wait_frames(2)
    	assert_is(game.screen, Stage)
    	assert_eq((game.screen as Stage).run.stage_id, "1-1")
    	assert_true((game.screen as Stage).run.tutorial)
    	assert_eq(SaveGame.instance().slot, 2)
    	assert_true(SaveGame.instance().slot_exists(2))


    func test_a_new_game_on_a_used_slot_asks_first() -> void:
    	SaveGame.instance().copy_to(3)
    	_title().show_slots(false)
    	_title().slot_list.buttons[2].pressed.emit()
    	assert_true(_title().confirm.is_open())
    	_title().confirm.answer(false)
    	assert_is(game.screen, TitleScreen)


    func test_load_game_opens_the_main_screen_on_that_slot() -> void:
    	SaveGame.instance().essences.add(Essences.BLUE, 77)
    	SaveGame.instance().copy_to(3)
    	SaveGame.instance().reset()
    	game.show_title()
    	await wait_frames(1)
    	assert_false(_title().load_button.disabled)
    	_title().show_slots(true)
    	assert_true(_title().slot_list.buttons[0].disabled, "empty slot 1")
    	_title().slot_list.buttons[2].pressed.emit()
    	await wait_frames(2)
    	assert_is(game.screen, MainScreen)
    	assert_eq(SaveGame.instance().slot, 3)
    	assert_eq(SaveGame.instance().essences.amount(Essences.BLUE), 77)


    func test_esc_goes_back_from_the_slot_list() -> void:
    	_title().show_slots(true)
    	var esc := InputEventAction.new()
    	esc.action = &"open_menu"
    	esc.pressed = true
    	_title()._input(esc)
    	assert_false(_title().is_showing_slots())


    func test_exit_and_the_window_close_quit_at_once() -> void:
    	game._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
    	assert_true(quit_called)
    	assert_false(game.prompt.is_open())


    func test_leave_to_main_menu_asks_then_shows_the_title() -> void:
    	game.show_main_screen()
    	await wait_frames(1)
    	(game.screen as MainScreen).gear.find_button("Leave to main menu").pressed.emit()
    	assert_true(game.prompt.is_open())
    	game.prompt.answer(true)
    	await wait_frames(2)
    	assert_is(game.screen, TitleScreen)
    	assert_true(SaveGame.instance().slot_exists(SaveGame.instance().slot))


    func test_play_time_counts_off_the_title_screen_only() -> void:
    	await wait_seconds(0.3)
    	assert_eq(SaveGame.instance().play_time, 0.0)
    	game.show_main_screen()
    	await wait_seconds(0.3)
    	assert_gt(SaveGame.instance().play_time, 0.2)


    func test_the_slot_list_shows_play_time() -> void:
    	SaveGame.instance().add_play_time(5025.0)
    	SaveGame.instance().copy_to(2)
    	_title().show_slots(true)
    	assert_string_contains(_title().slot_list.buttons[1].text, "1h 23m")
    ```
  - `test_game.gd`:
    - `test_starts_on_the_main_screen` becomes `test_starts_on_the_title_screen`.
    - Tests that start from the main screen call `game.show_main_screen()` and `await wait_frames(1)` first.
  - `test_main_screen.gd`: `test_leave_to_main_menu_is_disabled` becomes `test_leave_to_main_menu_asks_the_game` (pressing it emits `leave_requested`).
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3: Implement.**
  - `SlotList`:
    ```gdscript
    class_name SlotList
    extends VBoxContainer
    ## The 3 save slots as buttons: "Slot 2 · 1h 23m · saved 2026-10-28 14:03",
    ## "Slot 3 · empty" or "Slot 1 (current)". The owner decides what a pick does. Used
    ## by Save as copy, Start new game and Load game.

    signal picked(slot: int, used: bool)

    const BUTTON_SIZE := Vector2(420, 56)

    var buttons: Array[Button] = []


    func _init() -> void:
    	add_theme_constant_override(&"separation", 14)
    	for n in range(1, SaveGame.SLOTS + 1):
    		var button := Button.new()
    		button.custom_minimum_size = BUTTON_SIZE
    		UiStyle.style_button(button)
    		button.pressed.connect(func() -> void: picked.emit(n, SaveGame.instance().slot_exists(n)))
    		add_child(button)
    		buttons.append(button)
    	refresh()


    ## Re-reads the slots. `current` is shown as such and disabled; with
    ## `empty_enabled` off (Load game), empty slots are disabled too.
    func refresh(current := 0, empty_enabled := true) -> void:
    	var save := SaveGame.instance()
    	for i in buttons.size():
    		var n := i + 1
    		var button := buttons[i]
    		var used := save.slot_exists(n)
    		if n == current:
    			button.text = "Slot %d (current)" % n
    		elif used:
    			button.text = "Slot %d · %s · saved %s" % [n, SaveGame.play_time_text(save.play_time_of(n)), save.saved_at(n).substr(0, 16)]
    		else:
    			button.text = "Slot %d · empty" % n
    		button.disabled = n == current or (not used and not empty_enabled)
    ```
  - `GearMenu`:
    - `signal leave_requested`.
    - The slot page holds a `SlotList`; `picked` → `_copy(slot, used)`. `show_slots()` calls `refresh(SaveGame.instance().slot)`.
    - Drop `_slot_buttons`. `find_button` searches the page shown recursively (`find_children("*", "Button", true, false)`).
    - "Leave to main menu" → `leave_requested.emit`, with no hover note.
    - The doc comment drops "(not there yet)".
  - `MainScreen`: `signal leave_requested`; `gear.leave_requested.connect(leave_requested.emit)`.
  - `TitleScreen`:
    ```gdscript
    class_name TitleScreen
    extends Control
    ## The screen the game opens on: Thresh's lantern, the title, and Start new
    ## game, Load game, Settings and Exit the game. The two game buttons turn
    ## the panel into the slot list. A new game in a used slot asks first and
    ## writes the slot at once. Nothing is unsaved here, so Exit and the
    ## window's X quit at once.

    signal new_game_started
    signal game_loaded
    signal exit_requested

    const LANTERN := preload("res://assets/art/ui/title_lantern.svg")
    const BUTTON_SIZE := Vector2(420, 64)

    var settings := SettingsScreen.new()
    var confirm := ConfirmPopup.new()
    var slot_list := SlotList.new()
    var load_button: Button
    var error_label := UiStyle.label("", 20, UiStyle.ERROR_COLOR)

    var _menu: VBoxContainer
    var _slots_page: VBoxContainer
    var _slots_title: Label
    var _loading := false


    func _ready() -> void:
    	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    	_build()
    	show_menu()


    func show_menu() -> void:
    	_slots_page.visible = false
    	_menu.visible = true
    	error_label.text = ""
    	load_button.disabled = not SaveGame.instance().any_slot_exists()
    	if load_button.disabled:
    		load_button.set_meta(&"hover_text", "No saved games yet")
    	elif load_button.has_meta(&"hover_text"):
    		load_button.remove_meta(&"hover_text")


    ## The slot list: for a new game (every slot), or to load (used slots only).
    func show_slots(loading: bool) -> void:
    	_loading = loading
    	_slots_title.text = "LOAD GAME" if loading else "START NEW GAME"
    	slot_list.refresh(0, not loading)
    	_menu.visible = false
    	_slots_page.visible = true


    func is_showing_slots() -> bool:
    	return _slots_page.visible


    func find_button(text: String) -> Button:
    	for button: Button in find_children("*", "Button", true, false):
    		if button.text == text and button.is_visible_in_tree():
    			return button
    	return null


    func _input(event: InputEvent) -> void:
    	if not event.is_action_pressed(&"open_menu") or settings.visible or confirm.is_open():
    		return
    	if is_showing_slots():
    		show_menu()
    		get_viewport().set_input_as_handled()


    func _on_picked(slot: int, used: bool) -> void:
    	if _loading:
    		SaveGame.instance().load_slot(slot)
    		game_loaded.emit()
    	elif used:
    		confirm.ask("Overwrite slot %d? Its progress will be lost." % slot, _start_new.bind(slot))
    	else:
    		_start_new(slot)


    func _start_new(slot: int) -> void:
    	if SaveGame.instance().start_new(slot):
    		new_game_started.emit()
    	else:
    		error_label.text = "Could not write slot %d" % slot


    func _build() -> void:
    	var background := TextureRect.new()
    	var gradient := Gradient.new()
    	gradient.colors = PackedColorArray([Color(0.1, 0.18, 0.16), Color(0.02, 0.03, 0.04)])
    	var texture := GradientTexture2D.new()
    	texture.gradient = gradient
    	texture.fill = GradientTexture2D.FILL_RADIAL
    	texture.fill_from = Vector2(0.5, 0.35)
    	texture.fill_to = Vector2(1.0, 0.9)
    	background.texture = texture
    	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    	background.stretch_mode = TextureRect.STRETCH_SCALE
    	background.set_anchors_preset(Control.PRESET_FULL_RECT)
    	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    	add_child(background)
    	var center := CenterContainer.new()
    	center.set_anchors_preset(Control.PRESET_FULL_RECT)
    	add_child(center)
    	var column := VBoxContainer.new()
    	column.alignment = BoxContainer.ALIGNMENT_CENTER
    	column.add_theme_constant_override(&"separation", 18)
    	center.add_child(column)
    	var lantern := TextureRect.new()
    	lantern.texture = LANTERN
    	lantern.custom_minimum_size = Vector2(200, 200)
    	lantern.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    	lantern.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    	column.add_child(lantern)
    	var title := UiStyle.label("LUCIAN", 84, UiStyle.GOLD_COLOR)
    	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    	column.add_child(title)
    	var subtitle := UiStyle.label("THE LANTERN", 34, Color("8fe3b0"))
    	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    	column.add_child(subtitle)
    	_menu = VBoxContainer.new()
    	_menu.add_theme_constant_override(&"separation", 14)
    	column.add_child(_menu)
    	_button(_menu, "Start new game", show_slots.bind(false))
    	load_button = _button(_menu, "Load game", show_slots.bind(true))
    	_button(_menu, "Settings", _open_settings)
    	_button(_menu, "Exit game", exit_requested.emit)
    	_slots_page = VBoxContainer.new()
    	_slots_page.add_theme_constant_override(&"separation", 14)
    	column.add_child(_slots_page)
    	_slots_title = UiStyle.label("", 28, UiStyle.TITLE_COLOR)
    	_slots_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    	_slots_page.add_child(_slots_title)
    	slot_list.picked.connect(_on_picked)
    	_slots_page.add_child(slot_list)
    	_slots_page.add_child(error_label)
    	_button(_slots_page, "Back", show_menu)
    	settings.setup(GameSettings.instance())
    	settings.back_requested.connect(func() -> void: settings.close())
    	add_child(settings)
    	add_child(confirm)
    	add_child(HoverTip.new())


    func _open_settings() -> void:
    	settings.open()


    func _button(parent: Control, text: String, action: Callable) -> Button:
    	var button := Button.new()
    	button.text = text
    	button.custom_minimum_size = BUTTON_SIZE
    	UiStyle.style_button(button, 26)
    	button.pressed.connect(action)
    	parent.add_child(button)
    	return button
    ```
  - `Game`:
    ```gdscript
    func _ready() -> void:
    	GameSettings.instance().apply()
    	get_tree().auto_accept_quit = false
    	add_child(Sfx.new())
    	add_child(prompt)
    	show_title()


    ## Play time, for the slot lists: everywhere but the title screen. Game pauses
    ## with the tree, so pauses don't count.
    func _process(delta: float) -> void:
    	if screen and not screen is TitleScreen:
    		SaveGame.instance().add_play_time(delta)


    ## The title screen has nothing unsaved: its Exit and the window's X quit at once.
    func _notification(what: int) -> void:
    	if what == NOTIFICATION_WM_CLOSE_REQUEST:
    		if screen is TitleScreen:
    			quit_game.call()
    		else:
    			ask_to_quit()


    func show_title() -> void:
    	var title := TitleScreen.new()
    	title.new_game_started.connect(func() -> void: start_stage(StageSetup.for_stage(SaveGame.instance(), 1, 1)))
    	title.game_loaded.connect(show_main_screen)
    	title.exit_requested.connect(func() -> void: quit_game.call())
    	_swap(title)


    ## Leave to main menu: "Save before leaving?", then the title screen.
    func ask_to_leave() -> void:
    	if prompt.is_open():
    		return
    	prompt.ask("Save before leaving?", _leave.bind(true), _leave.bind(false), false)


    func _leave(save: bool) -> void:
    	if save and not SaveGame.instance().save():
    		prompt.ask("Could not save. Leave anyway?", show_title, Callable(), false)
    		return
    	show_title()
    ```
    - `show_main_screen` connects `main.leave_requested` → `ask_to_leave`.
    - The doc comment: "The root scene. Opens on the title screen; a slot leads to the main screen, which swaps in a stage and comes back when it ends…".
  - `screenshot.gd`: for `main_*` and `GAME_SCENARIOS`, call `game_root.show_main_screen()` right after adding the root. A new `title` scenario keeps the title.
  - **Art:** `title_lantern.svg` (256 viewBox): a dark iron lantern with a ring handle, chains hanging off both sides, a green soul glow inside, and soft light rays. Then `--import`.
- [ ] **Step 4:** Run the files, then the full suite → PASS.
- [ ] **Step 5:** Commit `"Title screen: a new game in any slot, load a slot, settings, exit; Leave to main menu works"`.

---

### Task 14: Debug tables

**Files:** Modify `src/ui/debug/debug_table.gd`. Test: `tests/unit/test_stage_debug_waves.gd`.

- [ ] **Step 1: Failing tests** (`test_stage_debug_waves.gd`, on a 2-1 stage as in `test_stage_waves.gd`):
  - "Kill all enemies" leaves the group empty and pays the rewards (wallet > 0).
  - "Spawn melee" adds one enemy and `runner.alive()` grows by one.
  - "God mode" makes `lucian.invulnerable` true.
  - On 2-3, "Jump to boss wave" then two `runner.tick(0.1)` spawns Akshan.
  - "Boss HP 51%" sets the boss to 51%.
  - "Skip break" starts the wave.
  - Buttons are found by text, as in `test_main_debug.gd` (`_collect`).
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3: Implement.** A **Waves** tab after Shop, built with the `DebugPanel` helpers:
  ```gdscript
  	box = _tab(tabs, "Waves")
  	_section(box, "Waves")
  	_wave_label = _label(box, "")
  	row = _row(box)
  	_button(row, "Skip break", func() -> void: stage.skip_break())
  	_button(row, "Kill all enemies", _kill_all)
  	_button(row, "Jump to boss wave", func() -> void: stage.jump_to_boss_wave())
  	row = _row(box)
  	for id: StringName in [WavePlan.MELEE, WavePlan.RANGED, WavePlan.SIEGE, WavePlan.SUPER]:
  		_button(row, "Spawn %s" % String(id).trim_suffix("_minion"), _spawn.bind(id))
  	row = _row(box)
  	_button(row, "Boss HP 51%", _boss_to_51)
  	_check(box, "God mode (no damage)").toggled.connect(func(on: bool) -> void: stage.lucian.invulnerable = on)
  ```
  ```gdscript
  func _kill_all() -> void:
  	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
  		if not enemy is TrainingDummy:
  			enemy.take_damage(lucian.make_damage(999999.0, DamageInfo.Type.TRUE, &"debug"))


  ## A minion near the cursor; it counts toward the wave.
  func _spawn(id: StringName) -> void:
  	stage.spawn_enemy(id, lucian.get_global_mouse_position())
  	if stage.runner:
  		stage.runner.enemy_spawned()


  func _boss_to_51() -> void:
  	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
  		var unit := enemy as EnemyUnit
  		if unit and unit.data.kind == &"boss":
  			unit.hp = unit.max_hp * 0.51
  			unit.health_bar.set_health(unit.hp, unit.max_hp)
  ```
  - `_process` shows `"Wave %d / %d   state %s   alive %d   next %s"` in `_wave_label` while there is a runner, else "Training: no waves".
  - The header comment lists the Waves tab.
  - Spawns in Training work too (no runner).
- [ ] **Step 4:** Run the file, then the full suite → PASS.
- [ ] **Step 5:** Commit `"Debug table: a Waves tab (skip, kill all, spawn, boss wave, boss HP 51%) and God mode"`.

---

### Task 15: Screenshots, docs, report

- [ ] **Step 1: Screenshot scenarios** in `tests/tools/screenshot.gd`. Each prints "expect" lines like the Phase 5 ones.

  **Title screen** (start `game.tscn`; add them to the list of game scenarios):
  - `title`: the title screen as it opens.
  - `title_slots`: Start new game → the slot list, with slot 2 saved.

  **Act 1** (start `stage.tscn` with `StageSetup.for_stage(save, …)`, via `stage.setup(...)` before `root.add_child`):
  - `act1_start`: the tutorial's first tip, Senna beside Lucian, the stage info "Wave 1 in 0:05", and the radar.
  - `act1_wave`: wave 1 on the lane, with "Wave 1/2" and "Enemies: N", red dots on the radar, and minions hitting Lucian (damage numbers on him).
  - `act1_shell`: a siege minion's red circle on Lucian.
  - `act1_break`: the merchant during a break, and "Wave 2 in 0:17" with Skip.
  - `act1_thresh`: the boss bar, and the hook's line warning toward Lucian.
  - `act1_cutscene`: the letterbox, a caption, and the soul flying to the lantern.
  - `act1_result`: STAGE CLEARED with +10 purple and the E line.

  **Act 2:**
  - `act2_pillars`: stage 2-3's ring of pillars, with a wave on the radar.
  - `act2_super`: a super minion, with Empower icons on the minions near it.
  - `akshan_e`: Heroic Swing's circle warning, then the swing with its outward bolts.
  - `akshan_r`: Comeuppance's lock line, with Lucian behind a pillar.

  **Anywhere:**
  - `defeat`: DEFEATED.
  - `loot`: a fragment and a legendary on the ground, plus "Backpack full".
  - `guardian_angel`: Lucian in gold stasis.
- [ ] **Step 2:** Run every scenario and look at every PNG. Fix what doesn't read (sizes, overlaps, colors), with a test for each fix where one fits.
- [ ] **Step 3: Docs** (same voice: short sentences, tables for numbers):
  - **`act1_the_loss.md`:** a "Built in Phase 6" section:
    - The enemy table with real numbers.
    - The tutorial rules (one gun, no skills, the tips).
    - Senna, Thresh's numbers, the cutscene steps, the replay rules.
    - The mid lane map.
  - **`act2_the_sentinels.md`:**
    - The wave table (done in Task 0).
    - The super minion's numbers and Akshan's numbers.
    - The training ground and the pillars per stage.
  - **`lucian_game_design.md`:**
    - §1: "Target length" becomes "A skilled player needs at least 5–7 hours to beat the story", plus the **Pacing** table and rules of thumb from this plan.
    - §3: the stage flow as built (countdown, spawns in groups, Skip and regen, death, result with the stage time).
    - §9: the drops as built, the tree's economy bonuses, item loot.
    - §11: Stage Gold / Bonus XP / Essence Drops now work. The balance goal reads "in 5–7 hours".
    - §13: maps built.
    - §15: slots on the title screen, `"bosses"`, `"play_time"`, `start_new`, Leave to main menu; delete "Not saved yet: which bosses…".
    - §16: tick the title screen.
  - **`ui_design.md`:**
    - "Top center – Stage info" as built, the FPS move, the radar as built, the boss bar.
    - The Act 1 tips, the result panel, the title screen.
    - Tick "Main menu and save slot selection".
  - **`main_screen.md`:** Journey acts start (card selection, Start, opening on the act); "Leave to main menu" works; the title screen.
  - **`items.md`:** move the 7 defensive items into "What works in combat" with their numbers, and delete the "Still tooltip text" paragraph.
- [ ] **Step 4: Report** `docs/report/phase6.md` (+ `docs/report/phase6/*.png`), laid out like Phase 5's:
  - Summary.
  - What was asked → what was built (a table).
  - Choices made where the request was open.
  - Verification (suite count, scenarios).
  - Pacing: the budget table, and the stage times measured in the screenshot runs (the cleared stages' result panels).
  - Screenshots.
  - Known limits:
    - Acts 3–6 and Endless still wait.
    - No navigation mesh: enemies can snag on corners.
    - Senna floats over walls.
    - Thresh's later fight is Act 6's.
  - Manual playtest checklist (below).
  - Feedback and suggestions.
- [ ] **Step 5:** Full suite → PASS. Add an "Implementation notes (Phase 6 done)" section at the end of this file, like Phase 5's. Commit `"Phase 6 screenshots, docs and report"`.

---

## Verification

1. **GUT:** the full suite is green after every task (`gut_cmdln.gd`). New files: `test_enemy_death`, `test_shields`, `test_lucian_damage`, `test_item_defense`, `test_ground_warning`, `test_enemy_data_files`, `test_minions`, `test_kill_rewards`, `test_loot`, `test_maps`, `test_wave_runner`, `test_stage_waves`, `test_stage_hud`, `test_act1`, `test_akshan`, `test_title_screen`, `test_stage_debug_waves`.
2. **Screenshots** (Task 15): every scenario run in a window and every PNG looked at.
3. **Manual playtest checklist** (also in the report). Delete `%APPDATA%\lucian_the_lantern\save_slot_*.json` first:
   1. Launch: the title screen. Load game is disabled.
   2. **Start new game:**
      - Pick slot 1: Act 1 starts, with "Right-click to move…".
      - Senna follows and shoots. Lucian fires one gun only, and has no skills or summoners.
   3. **Wave 1:**
      - "Wave 1/2" and "Enemies: 10" at the top center. Red dots on the radar, bottom right.
      - Melee minions walk up and hit (numbers over Lucian). Ranged minions keep away and their bolts can be dodged.
      - Kills give gold, XP (level ups) and "+1" blue. Sometimes a fragment lies on the ground; walk over it.
   4. **The break:**
      - "Wave 2 in 0:20" with Skip. The merchant is on the lane.
      - Shopping pauses the timer. Skip starts wave 2, and HP jumps up by the regen skipped.
   5. **Wave 2:** a siege minion's red circle. Step out of it.
   6. **Thresh** rises from the river:
      - The boss bar shows.
      - His hook's line warning, then the pull. Flay's cone pushes.
      - At half HP, the cutscene. Try Skip on a second run.
   7. **STAGE CLEARED:** "+10 purple essence (first clear)", the E line and "Act 2 is open". Continue → the main screen on Act 2. E is free in the tree.
   8. **Act 2** stages 1–3 in order:
      - Super minions Empower the small ones.
      - Akshan's boomerang hits twice. Heroic Swing shows a circle.
      - Comeuppance's lock line: hide behind a pillar and the shots stop. First clear gives +10 purple; replay 2-3 for +2.
   9. **Die** (Debug Boss HP 51% isn't needed; just stand in the minions): DEFEATED, and the essences are kept after Continue.
   10. **Buy Guardian Angel** (debug gold and Give) and die: gold stasis, then a revive at half base HP.
   11. **Gear → Leave to main menu → Yes** → the title. Load game → slot 1 is there, with the same progress.
   12. **Close the window** on the title: no prompt. During a stage: "Save before leaving?".
4. **Save file:** after Act 1, `save_slot_1.json` has `"cleared": ["1-1"]`, `"bosses": ["thresh_1"]` and a `"play_time"`.
5. **Pacing:** note each result panel's time. Act 1 should take about 8–10 minutes and Act 2's three stages 30–40 in all (the slot list's play time shows the total). Much faster means `EnemyData.ACT_HP` and the bosses' HP go up.

## Implementation notes (Phase 6 done)

Everything in the plan is in place, one commit per task (Tasks 0–14, plus a fix commit after the Task 2, 3 and 4 reviews), then the visual pass, the screenshot scenarios, the docs and the report (`docs/report/phase6.md`). Changes and details settled while building:

### Deviations and rulings
- **Enemies die** (Task 1): `Lucian.is_target(enemy: Variant)` is untyped. With an `Enemy` parameter, passing a freed object errors before `is_instance_valid` can run.
- **Lucian takes damage** (Task 2):
  - `_drop_in_flight()` ends a windup, a queued cast, the cast lock, R, a dash (its trail finishes) and a displacement. `displace()`, `enter_stasis()` and `_die()` call it, so a pull, stasis or death ends a dash, as in LoL.
  - `FloatingNumber` keeps its crit flag in a field: comparing font sizes broke once `size_scale` came in.
- **Defensive items** (Task 3):
  - Thornmail checks that its attacker is still valid before casting it to `Enemy`.
  - The plan's `test_deaths_dance_kill_clears_the_bleed` couldn't fail (Defy's heal outpaced the bleed). It now checks that the bleed list empties on a kill.
  - The tooltip texts for Annul, Lifeline and Everlasting were written then.
- **Minions** (Task 4): the ground warning's "fires once" test counts with a connected lambda; GUT's signal watcher fails on a node that frees itself. A follow-up commit fixed the `World` line of `stage.tscn`.
- **Rewards** (Task 5): `StageSetup.act` was added here, ahead of Task 7. `var legendary: bool` is typed (inference failed on the `Array` element).
- **Maps** (Task 7):
  - `_use_map` moves Lucian with `blink_to`: a raw position jump counted as movement (Energize).
  - `MidLaneMap` keeps every piece `clip_polygons` returns; Godot's polygon orientation is y-up, so a clockwise filter could drop the real jungle. A test checks there are exactly 2 jungle pieces.
- **Waves** (Task 8):
  - `Stage._ready` adds the merchant only in Training; act stages start their waves last in `_ready`.
  - `_on_lucian_died` waits on a stage-owned tween, never a SceneTreeTimer (which could resume on a freed stage).
  - `test_dying_shows_defeated` waits with a SceneTreeTimer: GUT's own wait freezes once the result pauses the tree.
  - `test_game.gd`'s `after_each` deletes the slot-1 files.
- **Stage HUD** (Task 9): the boss bar test waits 6 frames (2 were too few headless).
- **Act 1** (Task 10):
  - Every cutscene wait is a tween of the cutscene node. `_play()` checks `skipped` after each await, and Skip kills the scene's tweens and props, so nothing moves Thresh, Senna or the chain afterwards.
  - The letterbox bars sit on screen (the plan's offsets put them off it). Props (chain, soul, ring) live in a cutscene-owned node. Thresh sinks by scaling his visuals, never his body.
  - The lantern hangs at `LANTERN_OFFSET` (-20, 46): his right side when facing +X, as drawn. The plan's Art table said his left.
  - Thresh's last hit flash is reset to white when the scene starts.
  - `_on_cutscene_done` calls `runner.enemy_died()` before `finish()`, so Act 1 reads "Waves cleared: 3 / 3".
  - `TipBanner` is pausable (a tip's 7 s only run with the game) and shrinks around its center for a shorter tip.
- **Act 2** (Task 11):
  - Two Comeuppance tests set `akshan.move_speed = 0`, so he can't walk into range during their waits.
  - `Stage._on_thresh_phase_ended` and `_on_cleared` do nothing once Lucian is dead or the result shows: a death just before Thresh's half HP gives DEFEATED, with no cutscene and no purple (his repeat purple is 0, so it would be lost for good).
- **Debug tables** (Task 14): `Stage.freeze(false)` restores the invulnerable value Lucian had before the freeze, so God mode survives a cutscene.
- **Tests:** from Task 11 on, new waits use `wait_physics_frames` / `wait_process_frames` (`wait_frames` is deprecated). Task 15 converted `test_act1.gd` and `test_stage_hud.gd`, which brought GUT's Deprecated count from 39 to 15; the final review's fixes converted the rest (0).
- **Journey after Act 1:** it opens on Act 1, the act just played (the rule in *Defaults*). The Verification checklist's "the main screen on Act 2" was wrong; the report's checklist is corrected.

### Visual pass (Task 15)
Every scenario was run in a window and every PNG looked at. Eight fixes:
- **Radar:** `Radar.setup()` sets its size after the HUD anchored it, which moved its right and bottom edges past the corner: only a sliver showed. `Hud._place_radar()`, called after `radar.setup()`, re-anchors it with `PRESET_MODE_MINSIZE` and the 12 px margin. Test: `test_the_radar_sits_inside_the_bottom_right_corner`.
- **Death grey and stasis gold:** a hit's red flash tween, still running, painted `modulate` back to white over `DEATH_TINT` (new const) and `STASIS_TINT`. `Lucian._hurt_tween` is now kept and killed in `_die()` and `enter_stasis()`. Tests: `test_a_hit_just_before_death_keeps_the_grey`, `test_a_hit_just_before_stasis_keeps_the_gold`.
- **Cutscene framing:** the first pan goes to the midpoint of Thresh and Senna, and the camera tweens to Thresh during the pull. Before, the hook flew off screen and Lucian sat under the bottom bar. Test: `test_the_cutscene_frames_the_hook_then_thresh`.
- **Slot list:** `SlotList.BUTTON_SIZE` 420 → 520; "Slot 2 · 99h 59m · saved …" needs 441. Test: `test_a_used_slot_leaves_room_around_its_text`.
- **Thresh's essences** rise at `boss_unit.global_position`. They overlapped the first-clear purple over Lucian ("+110"), visible after a skipped cutscene. Test: `test_thresh_essences_rise_where_he_sank_and_the_purple_over_lucian`.
- **Stage info width:** the HUD anchored the panel while the Skip button was still in its layout, so its offsets kept that width (206 px for "Training", which needs 104). Its left and right offsets are now 0 around the center, so it is always as wide as what it shows. Test: `test_the_stage_info_fits_training`.
- **Map edges:** the camera's limits are the map grown by `WALL_THICKNESS`, and that band was empty (the clear color). `MidLaneMap` draws the border rects in jungle green, `TrainingGroundMap` in `WALL` (`#4a4f57`). Drawing only, no test.
- **Title lantern:** its light rays ended in flat cuts at the SVG's edge. They now use a radial gradient (`gradientUnits="userSpaceOnUse"`, set on each polygon, not on a `<g>`) that fades out before the edge.

### Screenshot harness (Task 15)
- `ACT_SCENARIOS` maps each act scenario to [act, stage]. The stage gets `StageSetup.for_stage(save, act, stage)` through `stage.setup()` before it enters the tree, from the scratch new save.
- `show_main_screen()` moved from `_initialize` to `_run`. In `_initialize` the Game root isn't in the tree yet, so every `main_*` scenario, `training_setup` and `skins_stage` had crashed since the title screen came first.
- Helpers: `clear_wave()` (Skip, then the debug Kill all once the wave has spawned; earlier tips are flushed so the break's tip shows), `flush_tips()`, `blink()` (moves Lucian, and Senna to her place beside him), `wait_for_warning()`, `wait_for_boss()`, `surround()`.
- `main_gear` no longer waits for a tooltip on Leave to main menu (it has none now). The doc comment of `scenario_training_setup` is back above it.

### Fixes from the final review
- **Saving on quit keeps a stage clear:** `Game._save()` (used by "Save before leaving?" on quit and on Leave) calls `finish_stage` while a stage's result panel shows, so closing the window on STAGE CLEARED, then Yes, keeps the clear. Test: `test_closing_the_window_on_stage_cleared_keeps_the_clear`.
- **Flush-safe wave ends:** `break_started` and `break_ended` (both, to keep their order) and Thresh's `phase_ended` are connected deferred. A kill or hit inside a shot's `area_entered` added the merchant's body, or froze the world's bodies, mid physics flush (engine errors). `cleared` and `spawn_requested` stay direct: the result adds no bodies, and spawns come from `tick()`. Tests: `test_a_shot_that_ends_a_wave_brings_the_merchant_safely`, `..._ends_the_stage_shows_the_result_safely`, `..._halves_thresh_plays_the_cutscene_safely`.
- **No loot from the kill that ends the stage:** `WaveRunner.is_last_enemy()`; `Stage._on_enemy_died` rolls no loot for it. Akshan's reward line lost its fragment; the boss row of `LootTable` stays for Endless.
- **Enemy bolts** end on a hit, taken or blocked, unless they return (the boomerang).
- **Dead Lucian:** `heal()` gives nothing, and a level up leaves HP at 0.
- **Cutscene:** `PROCESS_MODE_INHERIT`, so it pauses under "Save before leaving?". Its tweens are bound to it.
- **Mouse:** `Stage._exit_tree()` sets it back to visible (no headless test: the headless display ignores mouse modes).
- **Bosses:** `award_boss` warns about an id missing from `BOSS_IDS`; a test checks every boss `.tres` with first-time purple is listed.
- **Tests:** every Phase 6 test that uses the save swaps in a scratch `SaveGame` when run alone; no `wait_frames` left; the defeat and cutscene camera tests wait for the result or the step instead of a fixed time; `test_lucian_damage` gives Lucian an autofreed `projectile_parent`, so no dash trail outlives a test.
- **Docs:** a table split in `items.md`; boss walk and bolt speeds; the clocks skip shopping; Act 1 may run short of its budget.

### Left as is (small, from the reviews)
- **Untested:** HomingMissile and Lightslinger second-shot `is_alive` guards; stasis, `one_gun`, `can_act` gating of casts, `bonus_armor`, `size_scale`; Magebane absorbing magic, its reset and unequip; Thornmail on a dead attacker, buffs, Gunblade → Fimbulwinter; the "Backpack full" throttle, elite and boss stage kills, `enemy_died`, orange and purple `add_essences`; skips after the first pan, the siege and attack tips at stage level; Akshan's boomerang wiring and his skills after he dies mid-skill; `MainScreen._start_stage`; "Could not save. Leave anyway?", Leave → No, the Exit button and ESC with Settings open on the title; a Training spawn from the debug table.
- **Logic:** `Enemy.last_attacker` is set by any attacker (check kill credit when other damage sources arrive). `Shields.add` accepts ids outside `ORDER`. `LucianController` keeps an aim up while Lucian can't act. Death's Dance bleeds run out during stasis and aren't cleared on death; `before_hp_loss` counts magic-only Magebane in the total.
- **Stage:** `spawn_enemy` has no guard for a bad id; `_on_enemy_died` assumes a live Lucian; drops scatter ±30 px with no wall check. A stage id without waves would index out of range (only Acts 1–2 are reachable). `skip_break` isn't guarded while the result or a death shows. `EnemyUnit.warning_parent` defaults to the parent.
- **Act 2:** Heroic Swing sets `global_position`, so Akshan can swing through pillars and the edge; the swing keeps firing if Lucian dies mid-swing (the burst is gated).
- **HUD:** radar dots aren't clipped to the panel. `BossBar` rescans the enemies every frame while there is no boss. `TipBanner` counts down while the HUD is hidden. A damage number may show the unclamped amount while Thresh is stopped.
- **Save:** `start_new` sets the slot before saving (a failed write leaves the new slot current); `play_time_text` uses int division; `BOSS_IDS` sits among the vars. Loading a broken slot gives a new game silently. `ask_to_leave` doesn't pause, so play time runs while its prompt is up.
- **Journey:** a picked card that becomes locked keeps its outline and "Start stage N" when nothing is open (debug or reset only); `open_on` computes `default_stage` twice. Act 1's card reads "+ boss wave" on replays too.
- **Debug:** a nested `freeze(true)` overwrites the remembered invulnerable value; God mode toggled during a cutscene is overwritten when it ends; Kill all and Boss HP 51% aren't guarded during a cutscene or after Thresh stopped.
- **Tests:** the older `test_lucian_skills` leaves 4 shot nodes (GUT's one warning). One early Task 4 run had a failure in `test_cast_modes` / `test_game` that never came back. Several tests use wall-clock waits.

### Running the checks

```
godot_console --headless --path . --import
godot_console --headless --path . -s res://addons/gut/gut_cmdln.gd
godot --path . -s res://tests/tools/screenshot.gd -- <scenario> <output_dir>
```

New scenarios: `title`, `title_slots`, `act1_start`, `act1_wave`, `act1_shell`, `act1_break`, `act1_thresh`, `act1_cutscene`, `act1_result`, `act2_pillars`, `act2_super`, `akshan_e`, `akshan_r`, `defeat`, `loot`, `guardian_angel`. The `title*` scenarios start `src/main/game.tscn` on its title screen; the others start `stage.tscn` set up for a Journey stage (Act 1 as its first play). Every run uses scratch save slots and settings.
