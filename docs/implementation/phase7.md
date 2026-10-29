# Phase 7: Acts 3 and 4, the stage-end screen, and A + Left-click (implementation plan)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Task 0 copies this plan to `docs/implementation/phase7.md`.

**Goal:**
- Acts 3 and 4 can be played.
  - **Act 3, The Jungle:** monster packs come from their camps. There are jungle buffs, lava, Blast Cones, shallow water and Honeyfruit, two drakes, and the Elder Dragon in his pit.
  - **Act 4, The Darkness:** shadow minions fight on a dark mid lane, ending with Dark Lucian.
- A full-screen **stage-end screen** shows stats and rewards. Its buttons are **Retry**, **Next stage** and **Main screen**.
- **A + Left-click** attacks what the player means.

**Architecture:** The same layering as Phases 1–6.
- **Pure logic** lives in `src/core/` and is tested with GUT first. New: `DamageOverTime`, `StageStats`. Changed: `WavePlan` packs, `Journey.next_stage`, `KillRewards`, `LootTable`.
- **Data** is `.tres` in `data/enemies/`.
- **Nodes and UI** are built in code. No new `.tscn`.
- **New enemy classes:**
  - `Monster extends EnemyUnit`, for the jungle packs and elites.
  - `InfernalDrake`, `OceanDrake`, `ElderDragon` and `DarkLucian` extend `Boss`.
- **New map classes:**
  - `JungleMap` (stages 3-1 to 3-4) and `DragonPitMap` (3-5).
  - `DarkMidLaneMap extends MidLaneMap`.
- **New terrain nodes:**
  - `HazardZone` (lava, shallow water, burning ground).
  - `BlastCone`, `Honeyfruit`.

**Tech stack:** Godot 4.7.2 (GDScript), GUT 9.7.1, the `tests/tools/screenshot.gd` harness, hand-written SVG.

**Spec:**
- `docs/act3_the_jungle.md`, `docs/act4_the_darkness.md`.
- `docs/lucian_game_design.md` §2 (controls), §3 (stage rules, the result), §9 (drops), §12–13 (acts, maps).
- `docs/ui_design.md` "Stage result".
- The user's Phase 7 request.

## Context

**The user's Phase 7 list:**
1. Design the maps and enemies of Acts 3 and 4, and build them.
2. Design the screen shown when a stage is cleared or lost, which leads back to the main screen.
3. Fix A + Left-click. It must attack:
   - the enemy under the cursor;
   - else the enemy with the lowest HP %, if at least one is in range;
   - else the nearest enemy, chased until Lucian can attack it.

**Where Phase 6 left things:**
- **Only Acts 1–2 have stages.** Act 3 already opens after 2-3, but its cards read "Act 3 comes in a later phase", because `act_page.gd` asks `WavePlan.has_stage("3-1")`.
- **Attack-move behaves like LoL's.** `Order.ATTACK_MOVE` walks to the clicked point and shoots the nearest enemy in range on the way. So A + Left-click on an enemy does not focus that enemy.
- **The result panel is small.** It is a 560 px centered panel with the title, the stage name, waves and time, essences, green reward lines and one **Continue** button (`src/ui/stage/stage_result.gd`). The HUD stays visible around it. There are no counters for kills, damage or gold.
- **Several pieces don't exist yet:**
  - status effects: no damage over time, a single fixed 40% enemy slow, no Lucian slow, no timed stat buffs;
  - untargetable enemies;
  - throwing Lucian over walls;
  - terrain zones;
  - a mini-boss enemy kind;
  - pathing (enemies walk straight and sidestep when stuck).

### Decisions made with the user
| Topic | Decision |
|---|---|
| A + Left-click pick | The **hovered** enemy. Else the **lowest HP %** among enemies in Lucian's **attack range** (ties go to the nearer one). Else the **nearest enemy on the map**, chased. |
| After that kill | **Stop.** One target per A + Left-click; Lucian idles after the kill. |
| End screen | **Full-screen summary:** a big banner, a stats column and a rewards column. **No stars.** |
| End-screen buttons | **Retry**, **Next stage** (only after a clear, when the next stage can be played) and **Main screen**. The tutorial's GAME OVER keeps a single **Back to title**. |
| Blast Cones | **Shoot it.** A hit pops the plant and throws Lucian (if he is within reach) away from it, over walls. |

### Defaults chosen during planning (placeholders, tune later; each goes into the docs in Task 13)
- **A + Left-click with no enemy on the map:** Lucian walks to the clicked point. The attack-move ring and the cross cursor work as today.
- **Packs:** a `WavePlan` entry can name a pack, which expands into its members. Members come out of their **camp**: `EnemyData.camp` → `StageMap.camps[camp]`, jittered ±90. Maps without camps keep the per-enemy round robin. Spawning stays in groups of 3 every 1.2 s.
- **Enemies and Lucian path around walls.**
  - A unit walks straight while its line to its goal is clear. When a wall blocks it, it follows a navigation path, re-asked every 0.4 s and baked from the map's walls.
  - Lucian's walking uses the same shared `PathFollower`. This covers moves, attack chases (A + Left-click's "nearest on the map" is often behind a jungle wall), merchant visits and cast walks. A click inside a wall paths to the closest reachable point.
  - The sidestep stays as the enemies' fallback.
  - Until the navigation map has synced once (`map_get_iteration_id == 0`) and whenever a path comes back empty, everyone walks straight.
  - Acts 1–2 benefit too.
- **The mini boss is a new kind, `&"mini_boss"`:**
  - It doesn't scale, like a boss.
  - Rewards: 50 blue, 3 orange, and purple 5 the first time / 1 on repeats, **paid on the kill** with a reward line.
  - Its loot: a fragment for sure, plus an 8% legendary.
  - It gets a boss-size health bar, a 12 px skull on the radar, and the boss bar when no boss is out.
  - It joins `SaveGame.BOSS_IDS`.
- **Jungle buffs** go to Lucian when the elite dies.
  - **Blue:** 60 s of +10 mana regen per second and +20 ability haste.
  - **Red:** 60 s of +5 HP regen per second. His attacks burn for 15 true damage per second for 3 s. His attacks and skills slow enemies by 15% for 1.5 s.
  - Each buff shows in the HUD buff row.
- **Status rules:**
  - The strongest slow wins, for Lucian and for enemies alike. Tenacity doesn't shorten slows, as in LoL.
  - `add_slow` and `add_burn` also write a `_statuses` entry with an icon, so the enemy health bar shows them and `has_status(Enemy.SLOW)` still works.
  - Burns tick every 0.5 s through `take_damage` with `DamageInfo.over_time = true`, source `&"burn"` (never `&"basic"`, so Thornmail doesn't proc) and `from_skill = false` (so Banshee's Veil doesn't eat a tick). Magic resist lowers magic burns.
  - An `over_time` hit plays no hit or hurt sound and no flash, on Lucian or on an enemy. Lucian's `on_damage_dealt` skips it, so Ardent Blaze's speed refresh and other on-hit effects don't fire on ticks.
  - Death clears everything.
  - Gunblade becomes `add_slow(&"slow", 0.4, …)`.
- **Untargetable** (Sky Dive, Dark Lucian's E):
  - The enemy leaves `&"enemies"` and its body and hurtbox layers, so attacks, homing shots, A-click, Senna and the radar drop it.
  - `Lucian.is_target` is false for it.
  - `take_damage` returns 0, so burns can't kill it while it is hidden.
  - `set_untargetable(false)` does nothing on a dead enemy.
  - **Lucian's ATTACK order survives it.** He holds the target while it is alive, follows it and waits to shoot, so Dark Lucian's E doesn't cancel the player's attack every 6 s. Only shots in flight miss.
  - The boss bar keeps the boss it holds while `is_alive()`, through `is_instance_valid(boss) and boss.is_alive()` in place of `is_target`.
- **Rift Scuttler:**
  - It runs from Lucian and **escapes after 15 s**: "Escaped!", no rewards, counted as done for the wave.
  - On escaping it first sets `escaped`, leaves the group and zeroes its layers. `_die` then does nothing, so a shot already in flight can't kill it and count it twice.
  - The stage calls `runner.enemy_died()` directly. It does not emit `Stage.enemy_died`, which feeds the kill count and the tutorial.
  - Caught, it gives its elite rewards plus 45 blue and 4 orange.
- **Krugs:**
  - A big Krug's death spawns 2 small Krugs where it died.
  - `runner.enemy_spawned()` runs for each at once, before the death is counted and before the "stage-ending kill drops no loot" check. So a splitting Krug never ends a stage.
  - The bodies are added with `call_deferred`, because the killing shot can land inside a physics callback.
- **Physics flush rule:** nothing inside a damage path adds a body or runs a physics query (bullets deal damage inside `area_entered`). That covers splits, the Blast Cone throw, Dark Lucian's dodge and the Ocean Drake's interrupt. They record what happened in `take_damage` or `_lose_hp`, then act in `_think` or a deferred call.
- **Terrain** affects Lucian only:
  - **Lava:** a 40 magic per second burn, lingering 0.5 s.
  - **Shallow water:** a 25% slow while inside.
  - **Honeyfruit:** walking over it heals 100 + 6% max HP; it regrows after 30 s.
  - **Blast Cone:**
    - A hit (basic attack or skill) pops it.
    - If Lucian is within 350 px, he is thrown 800 px straight away from the plant, over walls, in 0.6 s. He lands on the farthest spot `StageMap.is_walkable` accepts, a geometry check rather than a physics query, and the throw is deferred. He can't act in flight.
    - The plant regrows after 20 s.
    - **How it plugs in:**
      - It extends `Enemy`, but doesn't call `super._ready()` (which joins `&"enemies"`). It sits in group `&"plants"`, which `enemy_at` (click and hover) also searches. Plants are never in `&"enemies"`.
      - It overrides `take_damage` and never calls `_die()`, so no `on_kill`: no skin heal, E cut or Death's Dance.
      - While popped it reports not alive and leaves `&"plants"`.
- **`Lucian.launch`:**
  - `_body_mask()` returns 0 while launched, so neither Ghost running out nor a dash end resets the mask mid-flight.
  - `displace()` is ignored in flight, and `_drop_in_flight` ends a launch.
  - `_last_position` is reset on landing, so the throw doesn't build Energize.
- **The end screen:**
  - **Stats:**
    - Time and waves.
    - Kills: every enemy death in the stage; escapes don't count.
    - Damage dealt: the HP Lucian's hits really took. `Enemy.take_damage` stores `hp_lost` (the final amount capped at the HP left); the stage adds it from each unit's `damage_taken` when the attacker is Lucian and the source isn't `&"debug"`.
    - Damage taken: after armor, before shields, as the numbers show.
    - Gold earned and level reached.
  - **Rewards:** each essence with its icon, then the green lines. A new line, **"Stage 3-3 is open"**, shows on the first clear of a non-last stage.
  - The HUD hides while the screen shows.
  - Retry, Next stage and Main screen each auto-save first, as Continue did.
- **Act 4's shadow minions** are their own data files (`shadow_*`), with Act 1–2 numbers and dark art. Empower works on them unchanged.
- **Endless** opens after Act 3 (the existing rule). Its Start stays disabled, "comes in a later phase".

### New combat pieces
| Piece | API |
|---|---|
| `DamageOverTime` (core) | `add(id, dps, seconds, type, attacker)` refreshes the same id. `tick(delta) -> Array[DamageInfo]` makes a tick every 0.5 s. Also `has(id)`, `time_left(id)`, `clear()`. |
| `DamageInfo` | `over_time := false` |
| `Lucian` | `add_slow(id, pct, s)`, `add_burn(id, dps, s, type, attacker)`, `add_stat_buff(id, bonus, s)`, `has_stat_buff(id)`, `launch(to, seconds)`, `is_launched()` |
| `UnitStats.at_level` | Bonus keys `hp_regen` and `mana_regen`, per second. |
| `Enemy` | `add_slow(id, pct, s)`, `slow_amount()`, `add_burn(…)`, `set_untargetable(on)`, `untargetable`, `hp_lost` |
| `PathFollower` (`src/stage/path_follower.gd`, RefCounted) | `next_point(from, goal, delta, space, nav_map) -> Vector2` returns the goal itself when the ray on `WORLD` is clear, the map isn't synced, or the path is empty; else the next path corner (re-asked every 0.4 s or when the goal moves 120). Used by `EnemyUnit.walk_toward` and `Lucian._step_toward`. |
| `EnemyData` | `camp`, `split_into`, `split_count`, `escape_after`, `extra_blue`, `extra_orange`, `buff_on_kill`, `hit_slow`, `hit_slow_time`, `hit_burn`, `hit_burn_time` |
| `HazardZone` | A polygon or circle; effect `burn(dps, type)` or `slow(pct)` on Lucian while he is inside; `lifetime` (0 = for good); it draws itself. |

### Act 3 enemy numbers (base, before scaling; `data/enemies/*.tres`)
Act 3 scaling: HP × 2.2, damage × 1.5, gold and XP × 1.5, and +15% HP and damage per wave after the first. Normal blue = 3 per kill; an elite gives 15.

| id | Kind | Behavior | HP | Armor / MR | Hit | Range | Every | Speed | Radius | Gold | XP |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `raptor` | normal | swarm | 110 | 10 / 0 | 8 physical | 90 | 0.9 s | 330 | 22 | 20 | 10 |
| `raptor_big` | normal | swarm | 360 | 20 / 10 | 18 physical | 100 | 1.0 s | 320 | 32 | 55 | 28 |
| `murkwolf` | normal | flank | 190 | 10 / 10 | 12 physical | 100 | 1.1 s | 340 | 26 | 30 | 16 |
| `murkwolf_big` | normal | flank | 480 | 20 / 15 | 24 physical | 110 | 1.2 s | 320 | 36 | 70 | 36 |
| `krug` | normal | brute | 200 | 30 / 10 | 16 physical | 100 | 1.5 s | 200 | 28 | 30 | 16 |
| `krug_big` | normal | brute; splits into 2 `krug` | 720 | 40 / 15 | 34 physical | 120 | 1.8 s | 170 | 46 | 80 | 42 |
| `gromp` | normal | spit | 650 | 15 / 25 | 22 magic bolt (500 px/s) + poison 6 magic/s for 3 s | 500 | 1.7 s | 160 | 44 | 80 | 40 |
| `blue_sentinel` | elite | brute; **Blue buff** | 1700 | 35 / 35 | 42 physical slam + 30% slow for 1.5 s | 150 | 1.6 s | 240 | 50 | 160 | 90 |
| `red_brambleback` | elite | brute; **Red buff** | 1700 | 35 / 35 | 40 physical + burn 8 magic/s for 3 s | 150 | 1.5 s | 240 | 50 | 160 | 90 |
| `rift_scuttler` | elite | flee; escapes after 15 s | 600 | 20 / 20 | none | — | — | 250 | 34 | 120 | 60 |

**Behaviors (`Monster`).** Each behavior id is unique, so `Stage._new_unit` sends `swarm`, `flank`, `brute`, `spit` and `flee` to `Monster` and leaves Minion's `melee` and `ranged` alone.
- **swarm:** each raptor aims at a point 60 px around Lucian at its own angle, so a pack wraps him.
- **flank:** a wolf aims 160 px to Lucian's side (left or right, set at spawn) until it is within 250, then closes.
- **brute:** walks in and hits (the `EnemyUnit` melee default).
- **spit:** keeps 380–480 px away, stands still while it attacks, and fires a bolt.
- **flee:** runs straight away from Lucian, sliding along walls, and escapes at `escape_after`.
- On-hit slow and burn come from the data's `hit_*` fields. They apply when a basic hit lands: for melee when `take_damage` returned true, for bolts on `hit_lucian`.

**Packs (`WavePlan.PACKS`):**

| Pack | Members |
|---|---|
| `raptors` | `raptor_big` + 4 `raptor` |
| `wolves` | `murkwolf_big` + 2 `murkwolf` |
| `krugs` | `krug_big` + 2 `krug` |
| `gromp` | `gromp` |

### Mini bosses and bosses (no scaling)
All skill hits are `from_skill`.

| id | HP | Armor / MR | Basic | Skills | Purple |
|---|---|---|---|---|---|
| `infernal_drake` (mini boss, 3-2) | 9000 | 40 / 40 | Fireball, 50 magic (700 px/s) + burn 10/s for 2 s; range 600, every 1.6 s, speed 260, radius 70 | **Fire Breath:** a cone warning (60°, 550) for 0.8 s, then 100 magic, and the cone burns for 3 s (30 magic/s). Cooldown 9 s, first after 3 s. **Meteor Fall:** 4 circle warnings (r 120: one on Lucian, 3 within 280 of him) for 1.2 s, then 80 magic each, and each burns for 3 s (25/s). Cooldown 13 s, first after 6 s. | 5 / 1 |
| `ocean_drake` (mini boss, 3-4) | 10000 | 40 / 50 | Water shot, 55 magic (800 px/s); range 600, every 1.5 s, speed 260, radius 70 | **Tidal Wave:** a line warning (1100 × 180) for 0.8 s, then a wave at 900 px/s. On a hit: 90 magic, a push of 300 along the line, and a 30% slow for 2 s. Cooldown 10 s, first after 3 s. **Soothing Mist:** stops and heals 30% of max HP over 4 s. If it takes 8% of max HP in damage during the channel, it is **interrupted** and stands dazed for 1.5 s ("Interrupted!"). Cooldown 18 s; first used at or below 70% HP. | 5 / 1 |
| `elder_dragon` (boss, 3-5) | 16000 | 50 / 50 | A shot, 70 magic (900 px/s); range 650, every 1.5 s, speed 280, radius 84 | **Elder Breath:** a cone warning (90°, 700) for 1.0 s, then 160 magic. Cooldown 8 s, first after 2 s. **Sky Dive:** untargetable and unseen for 3.2 s. Its shadow follows Lucian at 300 px/s for 2.4 s, then a circle warning (r 260) fills for 0.8 s; it lands for 240 magic and a 200 push from the center. Cooldown 18 s; first used at or below 85% HP. **Elder's Mark:** a mark over Lucian with a 4 s countdown ring, then 130 true damage, or **× 3** if he is below 25% HP when it lands. Shields absorb it. Cooldown 16 s, first after 8 s. | 10 / 2 |
| `dark_lucian` (boss, 4-3) | 18000 | 45 / 45 | Two shots 0.15 s apart, 40 physical each (1400 px/s); range 550, every 1.3 s, speed 330, radius 40 | **Piercing Light (Q):** a line warning (1100 × 70) for 0.7 s, then a dark laser for 170 physical. Cooldown 7 s, first after 3 s. **Relentless Pursuit (E):** a 400 px dash in 0.2 s, untargetable during it, so shots in flight miss. It dodges sideways after taking 6% of max HP within 1.5 s, or chases when Lucian is more than 750 away. Cooldown 6 s. **The Culling (R):** a line warning (1200 × 120) toward Lucian for 0.8 s; then for 3 s he fires 24 bullets along that fixed line (±4° spread, 30 physical each) while strafing sideways at 150 px/s. Cooldown 20 s; first used at or below 80% HP. | 10 / 2 |

`SaveGame.BOSS_IDS` adds all four ids.

### Act 4 enemy numbers
`shadow_melee_minion`, `shadow_ranged_minion`, `shadow_siege_minion` and `shadow_super_minion` copy the Act 1–2 minion numbers, behaviors and kinds (Phase 6 table). Only the id, the name and the art change.

Act 4 scaling: HP × 2.8, damage × 1.75, rewards × 1.75. Normal blue = 4 per kill.

### Waves (`WavePlan`)
Act 3 packs: **R** raptors, **W** wolves, **K** krugs, **G** gromp. Elites: **B** blue, **D** red (Brambleback), **S** scuttler. HP is the total after scaling, with the split Krugs counted.

| Stage | Waves | HP per wave | Mini boss / boss |
|---|---|---|---|
| 3-1 | R W · R R G B · W K G D S | 3.7k · 10.0k · 15.2k | — |
| 3-2 | R W G · R K W B · W K G D S · R W K G | 5.1k · 12.3k · 15.2k · 12.2k | Infernal Drake, last in wave 4 |
| 3-3 | R R W G · K W G B · R W K D S · R R W K G B | 6.8k · 12.0k · 15.7k · 20.2k | — |
| 3-4 | R W G K · R W K B · W K G D S · R R K G B · R W K G D | 8.4k · 12.3k · 15.2k · 17.4k · 19.5k | Ocean Drake, last in wave 5 |
| 3-5 | R W K G · R R W B · W K G D S · R W K G B · R R W K D S | 8.4k · 10.5k · 15.2k · 17.6k · 22.1k | Elder Dragon (boss wave) |

Act 4 uses Phase 6 letters with the shadow minions: **m** melee, **r** ranged, **S** siege, **U** super.

| Stage | Waves | HP per wave | Boss |
|---|---|---|---|
| 4-1 | 8m 6r 1S · 8m 6r 2S · 8m 8r 1S 1U · 10m 8r 2S 1U | 10.0k · 13.8k · 19.3k · 26.3k | — |
| 4-2 | 8m 6r 2S · 8m 8r 1S 1U · 10m 8r 2S 1U · 10m 10r 2S 1U · 10m 10r 3S 1U | 12.0k · 17.1k · 23.6k · 27.6k · 33.6k | — |
| 4-3 | 8m 8r 1S 1U · 10m 8r 2S 1U · 10m 10r 2S 1U · 10m 10r 3S 1U · 12m 10r 2S 2U | 14.8k · 20.9k · 24.8k · 30.4k · 38.9k | Dark Lucian |

### Pacing (budget from Phase 6: Act 3 70–90 min, Act 4 45–60 min)

**Act 3:**
- The waves hold about 310k HP in total, plus 35k for the two drakes and the dragon.
- Each stage starts at level 1. With Act 3's tree upgrades, Lucian's pack damage is about 80 at the start of a stage and 200+ by its end. That is about 30–35 minutes of pure damage, or about 50 with walking and dodging.
- 21 breaks of about 30 s add about 10 minutes, and a third more for deaths and replays brings it to **75–90 min**.

**Act 4:**
- The waves hold about 313k HP, plus 18k for Dark Lucian.
- Lucian's damage is about 250–350, so about 25–30 minutes of fighting.
- Adding the breaks and replays gives **45–60 min**.

If Act 3 clears in under 60 minutes, raise `EnemyData.ACT_HP` and the boss HP before touching rewards (the Phase 6 rule). The memory notes ask for gentle early stages, so 3-1's first wave is the smallest of the act.

### Maps (drawn in code; walls on `Layers.WORLD`; camps are spawn points)

**Act 3, Jungle (`JungleMap`, 5600 × 3600; `stage` picks the terrain):**
- **Walls:** dense jungle, drawn like Act 1's (dark green, tree blobs, a lighter edge).
- **Open floor:** the union of paths (bands 420 wide) and clearings (circles). Walls are the area minus that, through `Geometry2D.clip_polygons`, as `MidLaneMap` does.
- **No polygon may have a hole.**
  - The jungle's paths form loops. `clip_polygons` and `merge_polygons` return a hole as a separate clockwise polygon, and fed to `CollisionPolygon2D` or `is_walkable` it would turn into solid wall.
  - So every loop's inner jungle is kept as its own wall polygon (the holes of the merged floor become walls). Paths run to the map edge in at least 2 places, so the outer jungle splits into pieces with no hole.
  - `test_maps` checks that no wall polygon is a hole (by `Geometry2D.is_polygon_clockwise`, the way Godot marks holes) and that points inside the loops are walls.

```
┌────────────────────────────────────────────────────────┐
│ RAPTORS ●══════╗        DRAKE PIT ◯        ╔══════● GROMP │
│   ████████     ║  ██████ ═════════ ██████  ║    ████████ │
│ WOLVES ●═══════╬════════ CENTER ◯ ═════════╬═══════● KRUGS│
│   ████   BLUE ●║  ██████  ║ river ║ ██████ ║● RED   ████ │
│                ╚═════════ START ◯ ═════════╝  (scuttle: │
│                                               center top)│
└────────────────────────────────────────────────────────┘
```

- **Points:**
  - Lucian starts in the start clearing, bottom center.
  - The merchant stands at the center clearing's south edge.
  - Camps (`camps` dictionary): `raptors` top-left, `wolves` left, `krugs` right, `gromp` top-right, `blue` mid-left, `red` mid-right, `scuttle` center-top, `drake` (the pit, top center).
  - Every camp opens onto a path.
- **3-1 and 3-3:** normal jungle. The dry riverbed from the pit to the start is drawn only.
- **3-2 (Infernal Drake):**
  - 5 lava pools (`HazardZone` burn, r 140–220) on the paths near the center and the pit.
  - 4 Blast Cones, each beside a jungle clump no more than 500 thick, so the throw crosses it.
- **3-4 (Ocean Drake):**
  - The riverbed is shallow water (`HazardZone` slow) from the pit to the start.
  - 4 Honeyfruit plants on the paths.
- **3-5, the Elder Dragon's pit (`DragonPitMap`, 3600 × 3600):**
  - A round floor (r 1650) with rock walls around the edge. The ring is built from 8 arc pieces so no collision polygon has a hole.
  - 6 rocks (r 80) in a ring of r 900 give cover.
  - Spawn points sit at the N, E, S and W rim; there are no camps, so it uses round robin.
  - Lucian starts at the south. The merchant stands south of center, and the dragon lands at the center.

**Act 4, Dark mid lane (`DarkMidLaneMap extends MidLaneMap`):**
- Act 1's layout. `MidLaneMap`'s color constants become a palette the subclass replaces:
  - lane `#2a2633`
  - jungle `#120f1a`, its edge `#3b2a52`
  - trees `#0c0a12`
  - river `#1d1630` with purple ripples `#7a4fb0`
  - rocks `#3a3742`
- The same points for all 3 stages. Dark Lucian rises from the river at `boss_point`.

**Navigation:** `StageMap._ready` bakes a `NavigationPolygon` (agent radius 36) from the bounds minus every wall polygon and circle, into a `NavigationRegion2D`.

### The stage-end screen (`StageResult`, rebuilt)
```
┌──────────────────────────────────────────────────────┐   full-screen dim 0.85 + a soft
│                    STAGE CLEARED                     │   gold (clear) or dark red
│               Stage 3-2 · The Jungle                 │   (defeat) radial glow
├──────────────────────────┬───────────────────────────┤
│ STATS                    │ REWARDS                   │
│ Time             6:42    │ ◆ +312 blue essence       │
│ Waves            4 / 4   │ ◆ +4 orange essence       │
│ Kills            87      │ ◆ +5 purple essence       │
│ Damage dealt     41.2k   │ +5 purple (Infernal Drake,│
│ Damage taken     6,140   │   first kill)             │
│ Gold earned      3,940   │ Stage 3-3 is open         │
│ Level reached    9       │                           │
├──────────────────────────┴───────────────────────────┤
│      [ Retry ]      [ Next stage ]      [ Main screen ]     │
└──────────────────────────────────────────────────────┘
```

- **Layout:**
  - Panel 1040 wide, built with `UiStyle.panel()`.
  - Title 56 (gold `GOLD_COLOR`, or red `ERROR_COLOR` for DEFEATED and GAME OVER). Stage name 26.
  - Section heads 20 `DIM_COLOR`. Rows 22, with the label left and the value right.
  - Buttons 260 × 60 at size 24. **Main screen** is the lit one.
- **Number format:** commas under 10,000, `41.2k` above.
- **Rewards column:** essence rows use `Stage.ESSENCE_ICONS` and `ESSENCE_COLORS`, "No essences" when there are none, then the reward lines.
- **Buttons by outcome:**
  - Cleared: Retry · Next stage (hidden when there is no next stage to play) · Main screen.
  - Defeated: Retry · Main screen.
  - GAME OVER: Back to title.
- **Behavior:**
  - Layer 42 and `PROCESS_MODE_ALWAYS`, as before. The stage pauses the game, locks ESC and P, and hides the HUD.
  - **Signal:** `chosen(then: StringName)`, one of `&"main"`, `&"retry"`, `&"next"` or `&"title"`.
- **Routing:**
  - `Stage.finished(result, then)`. The menu's Leave emits `(&"left", &"main")`.
  - `Game._on_stage_finished` saves (`finish_stage`), then:
    - title → title screen;
    - retry → `start_stage(StageSetup.for_stage(save, act, stage))`;
    - next → the `Journey.next_stage(act, stage)` stage;
    - else → the main screen on that act.
  - Every route is `call_deferred`, since the press happens inside the stage.
  - **If the save fails,** Retry and Next go to the main screen instead and show its "Could not save" toast. `_report_save_failed` has no Stage case.
  - **Callers to keep working:**
    - `Game._save` reads `result.visible`, `result.cleared` and `result.title`.
    - The ESC menu's Leave emits `(&"left", &"main")`.

### Art (hand-written SVG; top-down, facing +X; a `<!-- Name: description -->` header; `#1a1d24` outline)
| File | Size | Look |
|---|---|---|
| `enemies/raptor.svg`, `raptor_big.svg` | 56 / 80 | Red-crested bird raptors, beaks forward; the big one darker crimson |
| `enemies/murkwolf.svg`, `murkwolf_big.svg` | 64 / 88 | Grey-blue wolves with glowing teal eyes; the big one with a mane |
| `enemies/krug.svg`, `krug_big.svg` | 64 / 104 | Rock golems, mossy, brown-grey; the big one cracked with orange seams |
| `enemies/gromp.svg` | 96 | A fat green-purple toad with spots, mouth forward |
| `enemies/blue_sentinel.svg` | 112 | A blue stone golem with a glowing blue rune crest |
| `enemies/red_brambleback.svg` | 112 | A red thorned beast with a burning crest |
| `enemies/rift_scuttler.svg` | 76 | A purple shelled river crab |
| `enemies/infernal_drake.svg` | 150 | An orange-red drake, wings spread, lava cracks |
| `enemies/ocean_drake.svg` | 150 | A teal drake, fin-like wings, water drops |
| `enemies/elder_dragon.svg` | 180 | A huge purple-black dragon with white-violet flame |
| `enemies/shadow_*.svg` (4) | as the minions | The minions in black-purple with violet glows |
| `enemies/dark_lucian.svg` | 100 | Lucian's silhouette in black and violet, red eyes, two dark guns |
| `stage/blast_cone.svg`, `stage/honeyfruit.svg` | 72 / 56 | A yellow-green bulb plant; a cluster of golden fruit |
| `ui/buff_blue.svg`, `buff_red.svg`, `debuff_slow.svg`, `debuff_burn.svg`, `status_burn.svg`, `elder_mark.svg` | 64 | Buff and status icons |

## Global constraints
- Godot **4.7.2**. Match the GDScript style around it: tabs, typed vars, `##` doc comments on classes and public functions, `&"name"` StringNames, one `class_name` per file.
- **No autoloads.** Pure logic stays in `src/core/` with no scene dependencies. UI is built in code; no new `.tscn`.
- `stage.tscn` run on its own stays the sandbox: Training, with everything unlocked.
- Everything that holds an enemy checks `Lucian.is_target()`. It is now false while the enemy is untargetable, as well as when it is dead. Lucian's ATTACK order and the boss bar are the two exceptions; they check `is_alive()`.
- **No body is added and no physics query runs inside a damage path.** Record the event, then act in `_think`, `_physics_process` or a deferred call. Tests that kill through real shots also assert `assert_engine_error_count(0)`, because GUT fails on engine errors.
- **Test helpers that clear waves** (`test_stage_waves._kill_all` / `_kill_wave`, `screenshot.gd`'s wave loop around line 1571) must cope with untargetable bosses, escaping Scuttlers and splits waiting to spawn. They loop on `runner.alive()` with a frame cap, and kill through `boss_unit` as well as the group.
- New player-facing numbers are constants at the top of their script or exports on `.tres` data, set for the pacing budget.
- Work on `main`, with **one verified commit per task**, never pushed. Each commit needs the GUT suite green. Every commit message ends with `Co-Authored-By: Claude <noreply@anthropic.com>`.
- Docs follow the existing voice: short plain sentences, tables for numbers.

## File map
| File | Change |
|---|---|
| `src/lucian/lucian.gd` | A-click pick (`attack_move_target`), `Order.ATTACK_MOVE` gone; ATTACK survives an untargetable target; slows, burns, stat buffs, `launch`; `on_damage_dealt` skips `over_time`; `enemy_at` also finds plants; `is_target` checks `untargetable`; `_step_toward` uses `PathFollower`; HUD `buffs()` entries |
| `src/stage/path_follower.gd` | **new** |
| `src/lucian/lucian_controller.gd` | unchanged API (calls `command_attack_move`) |
| `src/core/damage_over_time.gd`, `src/core/stage_stats.gd` | **new** |
| `src/core/damage_info.gd`, `unit_stats.gd` | `over_time`; `hp_regen` / `mana_regen` bonus keys |
| `src/core/enemy_data.gd` | new fields; `mini_boss` doesn't scale (the `hp_scale`, `damage_scale` and `reward_scale` checks, and the kind doc comment) |
| `src/core/kill_rewards.gd`, `loot_table.gd` | mini boss, extra essences |
| `src/core/wave_plan.gd` | `PACKS`, Act 3–4 stages and bosses |
| `src/core/journey.gd` | `next_stage(act, stage)` |
| `src/core/save_game.gd` | `BOSS_IDS` + 4 |
| `src/enemies/enemy.gd`, `enemy_unit.gd` | slows, burns (with status entries), untargetable, `hp_lost`, quiet `over_time` hits, on-hit effects, `PathFollower`, mini-boss bar |
| `src/enemies/monster.gd` | **new** |
| `src/enemies/bosses/infernal_drake.gd`, `ocean_drake.gd`, `elder_dragon.gd`, `dark_lucian.gd` | **new** |
| `src/combat/hazard_zone.gd`, `src/combat/elder_mark.gd` | **new** |
| `src/stage/blast_cone.gd`, `src/stage/honeyfruit.gd` | **new** |
| `src/stage/stage_map.gd` | `camps`, navigation bake |
| `src/stage/maps/jungle_map.gd`, `dragon_pit_map.gd`, `dark_mid_lane_map.gd` | **new** |
| `src/stage/maps/mid_lane_map.gd` | palette vars |
| `src/stage/stage_maps.gd` | acts 3–4 |
| `src/stage/stage.gd` | stats, camps, splits, escapes, buffs, mini-boss purple, "Stage X is open", `finished(result, then)`, HUD hidden on the result, new units in `_new_unit`, tip text |
| `src/ui/stage/stage_result.gd` | rebuilt |
| `src/main/game.gd` | Retry / Next / Main / Title routing |
| `src/ui/hud/boss_bar.gd`, `radar.gd` | mini boss; holds an untargetable boss |
| `src/lucian/items/item_actives.gd`, `item_passives.gd` | Gunblade's `add_slow`; Red buff on-hit |
| `src/ui/debug/debug_table.gd` | the spawn list covers every enemy id |
| `data/enemies/*.tres` | +18 files |
| `assets/art/…` | the SVGs above |
| `tests/unit/…` | **New:** `test_attack_move`, `test_stage_stats`, `test_stage_result`, `test_damage_over_time`, `test_status_effects`, `test_enemy_paths`, `test_monsters`, `test_terrain`, `test_drakes`, `test_elder_dragon`, `test_dark_lucian`, `test_act4`. **Extended:** `test_stage_waves`, `test_game`, `test_journey`, `test_journey_section`, `test_kill_rewards`, `test_loot`, `test_stage_hud`, `test_enemy_data_files` (the kind whitelist, mini bosses in `BOSS_IDS`), `test_maps`, `test_wave_runner`, `test_save_game`, `test_stage_debug_waves`, `test_minions` and `test_item_actives` (the slow refactor) |
| `tests/tools/screenshot.gd` | Phase 7 scenarios |
| `docs/…` | `implementation/phase7.md`, `report/phase7.md` (+ png), `act3_the_jungle.md`, `act4_the_darkness.md`, `lucian_game_design.md` (§2, §3, §9, §12, §13), `ui_design.md`, `main_screen.md` |

## Running things
```powershell
$godot = "$env:LOCALAPPDATA\Programs\Godot"
& "$godot\godot_console.exe" --headless --path . --import                       # after adding SVG/.tres files
& "$godot\godot_console.exe" --headless --path . -s res://addons/gut/gut_cmdln.gd  # full suite
& "$godot\godot_console.exe" --headless --path . -s res://addons/gut/gut_cmdln.gd -gconfig= -gtest=res://tests/unit/<file>.gd -gexit
& "$godot\godot.exe" --path . -s res://tests/tools/screenshot.gd -- <scenario> <out_dir>  # needs a window
```

---

## Tasks
Every task follows the same steps: tests first (red), then code (green), then the full suite, then one commit.

### Task 0: Save the plan
- [ ] Copy this file to `docs/implementation/phase7.md` and commit "Add the Phase 7 plan".

### Task 1: A + Left-click picks its target
- [ ] **Tests** (`tests/unit/test_attack_move.gd`, with Lucian and minions in a scene):
  - The hovered enemy wins even when it is out of range and another one is lower or nearer: the order is ATTACK on it, and he walks to it.
  - With no hover, the lowest HP % among enemies in range wins over a nearer, healthier one; on a tie, the nearer one wins.
  - With none in range, he targets the nearest enemy on the map, walks into range and shoots.
  - After that target dies he stops: no new target, order NONE.
  - With no enemy at all, he walks to the point.
  - A dead or untargetable enemy is never picked.
- [ ] **Code:**
  - Add `Lucian.attack_move_target(point) -> Enemy`: `enemy_at` → lowest `hp / max_hp` with `_in_range` → nearest in `&"enemies"` → null.
  - `command_attack_move(point)` calls `command_attack(target)`, or `command_move(point)` when there is no target.
  - Remove `Order.ATTACK_MOVE` and `_nearest_enemy_in_range`. Check every reference in `src/`, `tests/` and `tests/tools/screenshot.gd`; the scenarios that call `command_attack_move` keep working through the new meaning.
  - Walking around jungle walls for the chase comes with Task 5's `PathFollower`.
- [ ] Change the tip in `Stage.TIPS[&"attack_move"]` to "Press %s, then %s: attack the enemy under the cursor, or the weakest one in range."
- [ ] Commit.

### Task 2: The stage-end screen
- [ ] **Tests:**
  - **`test_stage_stats.gd`:** the counters, and the number format (`9,999`, `41.2k`).
  - **`test_stage_result.gd`:**
    - The buttons by outcome.
    - Next is hidden after a defeat and when `can_next` is false.
    - Each button emits `chosen` with its value.
    - The essence rows and the "No essences" text.
  - **`test_journey.gd`:** `next_stage`: 1-1 → 2-1, 2-3 → 3-1, 3-2 → 3-3, 6-5 → none.
  - **`test_stage_waves.gd`:**
    - The stage counts kills, gold earned, damage dealt and damage taken. Damage dealt is capped at the HP lost, and a `&"debug"` kill adds nothing.
    - The HUD is hidden on the result.
    - "Stage 2-2 is open" shows on a first 2-1 clear only.
    - `finished(&"cleared", &"next")` is emitted.
    - Update the existing assertions to the new buttons:
      - the title, Continue and Back to title (`:116-117`, `:129-132`, `:140-143`);
      - the "Time 0:01" label search (`:183-190`), which now finds the Time row's value.
    - Also update `test_game.gd:179,192,206,217`, `test_act1.gd` and `test_loot.gd`.
  - **`test_game.gd`:**
    - Retry starts a new `Stage` of the same id, saved.
    - Next after clearing 2-1 starts 2-2.
    - Main screen opens on the act, as before.
    - The tutorial's game over → title, as before.
    - A failed save on Retry lands on the main screen with the toast.
    - Leave still works.
- [ ] **Code:**
  - `StageStats` (core).
  - `Enemy.hp_lost`.
  - The stage wiring:
    - kills and gold in `_on_enemy_died`;
    - `damage_received` → taken;
    - each spawned unit's `damage_taken` → dealt, when the attacker is Lucian and the source isn't debug.
  - `StageResult` rebuilt (see the layout above). It keeps `title` and `cleared` for `Game._save`. `Stage.show_result` passes its stats rows and `can_next` (`WavePlan.has_stage` of `Journey.next_stage`).
  - `finished(result, then)` everywhere: `stage.gd:11-12,104,117`, the menu's Leave, `game.gd:124`.
  - The deferred `Game` routing.
- [ ] Update the screenshot scenarios `act1_result` and `defeat`, and add a `game_over` one.
- [ ] Commit.

### Task 3: Status effects, untargetable enemies, the throw over walls
- [ ] **Tests** (`test_damage_over_time.gd`, `test_status_effects.gd`):
  - **`DamageOverTime`:** ticks, refresh, `clear`.
  - **Lucian slows:**
    - The strongest of two wins.
    - Speed returns when they expire.
  - **Lucian burns:**
    - A magic burn is lowered by MR.
    - True damage isn't lowered.
    - No hurt sound.
    - Banshee's Veil doesn't eat a tick.
    - Thornmail doesn't proc on one.
    - Death clears it.
  - **Ticks Lucian deals** don't refresh Ardent Blaze's speed.
  - **Stat buffs:**
    - Blue raises `mana_regen` by 10 and `ability_haste` by 20.
    - The buff expires after its time.
    - It shows in `buffs()`.
  - **Enemies:**
    - `add_slow` uses the strongest.
    - Gunblade still slows 40%.
    - An enemy burn kills with Lucian's credit.
  - **Untargetable:**
    - Homing shots in flight fizzle.
    - `enemy_at` and A-click miss it.
    - It takes no damage, burns included.
    - The ATTACK order is kept, and Lucian shoots again once it is back.
    - The boss bar keeps it.
    - A dead enemy stays out of the group after `set_untargetable(false)`.
    - Back to normal afterwards.
  - **`launch`:**
    - It passes a wall and lands on the far side.
    - No acting in flight.
    - Ghost ending mid-flight doesn't reset the mask.
    - `displace` is ignored in flight.
    - No Energize from the throw.
  - Update `test_minions.gd:112-113` and `test_item_actives.gd:74` to the slow API.
  - **On-hit fields:** a melee hit with `hit_slow` slows Lucian; a bolt with `hit_burn` burns him.
- [ ] **Code:** the pieces in **New combat pieces**.
  - HUD icons `debuff_slow`, `debuff_burn`, `buff_blue`, `buff_red`; `status_burn` over enemy bars.
  - `launch`: `collision_mask = 0` for the flight, `visuals` scaled 1 → 1.25 → 1 for height, can't act.
- [ ] Commit.

### Task 4: Mini bosses, packs, camps, splits, escapes, buffs on kill
- [ ] **Tests:**
  - **`test_kill_rewards`:** mini boss 50 / 3; extra blue and orange.
  - **`test_loot`:** the mini-boss row.
  - **`test_stage_hud`:** the 12 px skull; the bar shows a mini boss and prefers a boss.
  - **`test_enemy_data_files`:** every id loads; the kind whitelist (`:16`) adds `mini_boss`; every mini boss and boss is in `BOSS_IDS` (`:49`).
  - **`test_wave_runner` / a `WavePlan` test:** packs expand in order.
  - **`test_stage_waves`:**
    - A `split_into` death spawns 2 units, and the wave waits for them. One test kills through the stage's `_shoot` helper with `assert_engine_error_count(0)`, and one kills the last enemy of the last wave.
    - An escape counts as done, with no reward and no kill, and a shot in flight can't kill the escaping Scuttler.
    - The mini boss's purple is paid once, then the repeat amount, with a line.
    - `buff_on_kill` gives Lucian the buff.
    - Units with a camp spawn at it.
- [ ] **Code:**
  - The `EnemyData` fields and the kind, plus every place that switches on kind: `KillRewards` (`:29`), `LootTable` (`:13`), the `enemy_data` scale functions, the health bar (`enemy_unit.gd:69`), the radar (`:39-45,61`), the boss bar (`:24`).
  - Add the mini bosses to `BOSS_IDS`. The debug "Boss HP 51%" stays boss-only.
  - `Stage._spawn_wave_enemy` uses camps.
  - `Stage._on_enemy_died` runs in this order:
    1. One `runner.enemy_spawned()` per split.
    2. The loot check, now that a split means "not the last enemy".
    3. A deferred spawn of the splits.
    4. The buff.
    5. The mini boss's purple.
  - The stage handles `Monster.escaped` (see Defaults).
  - `WavePlan.PACKS`.
  - The wave-clearing test helpers (see Global constraints).
- [ ] Commit.

### Task 5: Enemies and Lucian find their way around walls
- [ ] **Tests** (`test_enemy_paths.gd`):
  - A melee minion behind a 1200-long wall reaches Lucian within 8 s.
  - Lucian, ordered to move to a point behind it, gets there.
  - An A + Left-click on the nearest enemy behind it chases around the wall.
  - With a clear line both walk straight, so the path is not used.
  - Before the map's first sync, everyone walks straight with no engine error.
  - The Act 1–2 suites stay green.
- [ ] **Code:**
  - `StageMap` bakes navigation:
    - `NavigationMeshSourceGeometryData2D`, with a traversable outline of the bounds and obstruction outlines for the polygons and for circles (as 16-gons).
    - `NavigationServer2D.bake_from_source_geometry_data`.
    - A `NavigationRegion2D` child.
  - `PathFollower` (see New combat pieces). It never calls `map_get_path` while `NavigationServer2D.map_get_iteration_id(map) == 0`.
  - `EnemyUnit.walk_toward` and `Lucian._step_toward` use it.
  - Tests poll `map_get_iteration_id` (with a frame cap) rather than waiting a fixed number of frames. The map may sync on a background thread.
- [ ] Commit.

### Task 6: Act 3 monsters (+ art)
- [ ] **Tests** (`test_monsters.gd`):
  - Swarm raptors spread around Lucian (distinct angles).
  - Wolves come in from a side.
  - Gromp keeps its distance, spits, and poisons.
  - Blue's slam slows.
  - Red's hit burns.
  - The scuttler runs away and escapes at 15 s.
  - A big Krug has `split_into`.
- [ ] **Code:** `Monster`, the 10 `.tres` files and the 10 SVGs. `Stage._new_unit` routes `swarm`, `flank`, `brute`, `spit` and `flee` to `Monster`. Run `--import`.
- [ ] Commit.

### Task 7: The jungle, its terrain, and Act 3's waves (+ art)
- [ ] **Tests:**
  - **`test_maps`:** add 3-1 to 3-5. Every start, merchant, boss, camp and spawn point is walkable. Terrain sits on the floor, and Blast Cone landing spots are walkable.
  - **`test_terrain.gd`:**
    - Lava burns Lucian while he is inside and stops 0.5 s after he leaves.
    - Water slows him by 25% while he is inside.
    - Honeyfruit heals once, then regrows at 30 s.
    - **Blast Cone:**
      - A hit throws Lucian, within 350, over a wall to a walkable spot.
      - It doesn't throw him beyond 350.
      - It regrows at 20 s.
      - It is never in `&"enemies"`, but a left-click on it gives an attack order.
  - **`test_maps`, holes:** no wall polygon is a hole, and points inside each path loop are walls.
  - **`test_journey_section`:** `:136-139` now expects Act 3's cards to start (Act 3 becomes playable as soon as 3-1 exists, through `act_page.gd:32`). Act 4 still reads "comes in a later phase".
- [ ] **Code:**
  - `HazardZone`, `BlastCone` (the throw deferred), `Honeyfruit`, `JungleMap(stage)`, `DragonPitMap`, `StageMaps` (act 3: 1–4 → jungle, 5 → pit).
  - `WavePlan` 3-1 … 3-5 with the normal waves; the drakes and the dragon come in Tasks 8–9.
  - The SVGs.
  - `test_journey.gd:52-57` (the wave plan matches the Journey) grows one act at a time: Act 3 in Task 9, once 3-5 has its boss, and Act 4 in Task 11.
- [ ] Commit.

### Task 8: Infernal Drake and Ocean Drake (+ art)
- [ ] **Tests** (`test_drakes.gd`, driving the skills directly like `test_akshan`):
  - Fire Breath's cone hits and leaves a burning zone for 3 s.
  - Meteor Fall makes 4 circles, one on Lucian, each leaving a burn.
  - The fireball's burn.
  - Tidal Wave pushes back and slows.
  - Soothing Mist heals over 4 s, and waits for 70% HP.
  - 8% damage interrupts it (dazed 1.5 s). The damage is recorded in `_lose_hp` and the interrupt happens in `_think`, so killing shots cause no engine errors.
- [ ] **Code:**
  - `InfernalDrake` and `OceanDrake` extend `Boss`.
  - Their data (`kind = mini_boss`, `camp = drake`) and art.
  - Add the drakes to the last waves of 3-2 and 3-4.
- [ ] Commit.

### Task 9: Elder Dragon (+ art)
- [ ] **Tests** (`test_elder_dragon.gd`):
  - Elder Breath's cone.
  - **Sky Dive:**
    - Untargetable while up (attacks drop it).
    - Its shadow follows Lucian.
    - A circle warning before the landing, then the hit.
    - Targetable again.
    - The boss bar keeps it.
    - It waits for 85% HP.
  - **Elder's Mark:**
    - 130 true damage after 4 s.
    - × 3 under 25% HP.
    - A shield absorbs it.
    - Banshee's Veil blocks it.
- [ ] **Code:** `ElderDragon`, `ElderMark` (a node over Lucian with a countdown ring), its data and art, and `WavePlan.BOSSES["3-5"]`.
- [ ] Extend `test_journey`'s wave-plan check to Act 3.
- [ ] Commit.

### Task 10: Act 4's dark mid lane and shadow minions (+ art)
- [ ] **Tests:**
  - **`test_maps`:** 4-1 to 4-3 on `DarkMidLaneMap`, with the dark palette.
  - **`test_act4.gd`:** shadow minions behave like the Act 1–2 ones (ranged keeps away, siege shell, Empower on shadow minions); Act 4 scaling.
- [ ] **Code:** the `MidLaneMap` palette vars, `DarkMidLaneMap`, 4 `.tres` files, 4 SVGs, and `WavePlan` 4-1 … 4-3.
- [ ] Commit.

### Task 11: Dark Lucian (+ art)
- [ ] **Tests** (`test_dark_lucian.gd`):
  - Two shots per basic attack.
  - Q's line warning, then the laser hit.
  - **E:**
    - It dodges sideways after 6% of max HP in 1.5 s, untargetable for the dash, so a homing shot in flight fizzles. The damage is recorded in `_lose_hp` and the dash starts in `_think`.
    - Lucian's ATTACK order on him survives the dash.
    - It chases beyond 750.
  - **R:**
    - A line warning, then 24 bullets along the fixed line.
    - Stepping sideways avoids them.
    - It waits for 80% HP.
- [ ] **Code:** `DarkLucian`, its data and art, and `WavePlan.BOSSES["4-3"]`.
- [ ] Extend `test_journey`'s wave-plan check to Act 4, and `test_journey_section`'s Act 4 cards to start.
- [ ] Commit.

### Task 12: Debug table and Journey polish
- [ ] The debug Waves tab's four hard-coded spawn buttons (`debug_table.gd:268`) become a list of every enemy id in `data/enemies/`, with a Spawn button. "Boss HP 51%" works on the new bosses.
- [ ] Check that Act 5 still reads "comes in a later phase", and that Endless opens after Act 3 with its Start disabled.
- [ ] Tests: `test_stage_debug_waves`, `test_journey_section`. Commit.

### Task 13: Screenshots, docs, report
- [ ] **New scenarios:**
  - Act 3: a jungle wave with packs, lava and a Blast Cone throw, shallow water and Honeyfruit, the Infernal Drake's Meteor Fall, the Ocean Drake's Tidal Wave and Soothing Mist, the Elder Dragon's Sky Dive shadow and Elder's Mark, the pit.
  - Act 4: the dark lane wave, Dark Lucian's Q and R.
  - The end screens: cleared with rewards, defeated, game over.
  - A + Left-click: a hovered target, and the lowest HP % target.
- [ ] **Docs:**
  - `act3_the_jungle.md` and `act4_the_darkness.md` get "Built in Phase 7" sections with these numbers, maps and waves.
  - `lucian_game_design.md`: §2 A + Left-click, §3 the end screen and its buttons, §9 mini-boss rewards and Scuttler, §12–13 maps built, Act 3–6 map line.
  - `ui_design.md`: "Stage result" becomes the end screen.
  - `main_screen.md`: Retry and Next start stages directly.
- [ ] Write `docs/report/phase7.md` (what was built, with screenshots, deviations and known limits). Add "Implementation notes (Phase 7 done)" to `phase7.md`.
- [ ] Commit.

## Verification
- **Full GUT suite green** after every task (command above). New tests cover each behavior listed in the tasks.
- **`--import` passes** after the SVG and `.tres` tasks with no errors in the log.
- **Manual play** (`godot.exe --path .`), through the debug table (F3 + Q: God mode, Waves tab, skip, boss wave):
  1. **A + Left-click:**
     - On an enemy out of range: Lucian chases it.
     - In a group: he shoots the weakest in range.
     - With nothing in range: he walks to the nearest and shoots it.
     - After the kill: he stops.
  2. **Clear 2-3:** the end screen shows stats, rewards and "Act 3 is open"; Next stage starts 3-1.
  3. **Play 3-1 … 3-5:**
     - Packs come from their camps and path around jungle walls.
     - The Blue and Red buffs show in the HUD.
     - The Scuttler escapes if ignored.
     - Krugs split.
     - Lava, Blast Cones, water and Honeyfruit work on 3-2 and 3-4.
     - The drakes and the dragon use every skill.
     - Purple is paid once.
  4. **Play 4-1 … 4-3:** the dark lane and shadow minions; Dark Lucian dodges with E, lasers with Q and strafes with R.
  5. **Lose a stage:** DEFEATED; Retry restarts it, Main screen returns to that act. **Lose the tutorial:** GAME OVER with only Back to title.
- **Screenshots** for every scenario in Task 13, checked by eye, embedded in the report.
- **Pacing:** each stage's time on the end screen. Compare against the per-act budget; tune `ACT_HP` and boss HP if Act 3 clears in under 60 minutes.
