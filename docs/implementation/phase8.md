# Phase 8: Acts 5 and 6 — the Shadow Isles, Thresh's domain, the final fight and the ending

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development (or superpowers:executing-plans). One verified commit per task. Task 0 copies this plan to `docs/implementation/phase8.md`.

## Context

The user's Phase 8 request: "Design map and enemies for act 5, 6 and implement."

This plan was approved on 2026-10-29, then put on hold while Phase 7 (Acts 3–4) ran on `main`. **It is revised here onto Phase 7's real code** (HEAD `9680b70`, 1041 tests). The user's three decisions are unchanged.

Where the game stands after Phase 7:
- **Acts 1–4 are built.** `Journey.ACTS` already describes Acts 5 and 6: waves `[5,5,6,6,6]` and `[6,6,7,7,7]`, with mini bosses at stages 2 and 4. An act's Start button only works once `WavePlan.has_stage("<act>-1")` is true.
- **Phase 7 already built these shared pieces, and Phase 8 reuses them as they are:**

| Piece | Phase 7 API |
|---|---|
| Mini bosses | `kind = &"mini_boss"`: no scaling, 50 blue and 3 orange (`KillRewards`), loot `[1.0, 0.08]`, a boss-size health bar, a radar skull, the boss bar when no boss is out. A mini boss is the **last entry of its stage's last wave** in `WavePlan.STAGES`, comes out of its `camp` (`EnemyData.camp` → `StageMap.camps`), and its purple is **paid on the kill** (`Stage._award_mini_boss`). The stage card reads "N waves + mini boss". |
| Slows and burns on Lucian | `Lucian.add_slow(id, pct, s)` (the strongest counts; **tenacity doesn't shorten slows**), `add_burn(...)`, "Slowed" and "Burning" in `buffs()` with `debuff_*.svg` icons. `EnemyData.hit_slow`/`hit_slow_time`/`hit_burn`/... apply on a landed basic hit. |
| Untargetable | `Enemy.set_untargetable(on)`: out of `&"enemies"` and every hitbox, takes no damage. Lucian's ATTACK order survives it; the boss bar keeps a held boss while `is_alive()`. |
| Leaving with no rewards | `EnemyUnit.escape()`: `has_escaped`, out of the fight, `escaped` signal, fade. `Stage._on_enemy_escaped` shows "Escaped!" and calls `runner.enemy_died()`. |
| Enemies that add enemies | Krug splits: `runner.enemy_spawned()` at once, then the bodies spawn with `call_deferred`. |
| Terrain | `HazardZone.burning(dps, type)` / `slowing(pct)` (circle or polygon; `contains` works in its parent's space). |
| Pathing | `PathFollower` (ray on `Layers.WORLD`, a nav mesh baked by `StageMap`), used by `EnemyUnit.walk_toward` and Lucian's walking. |
| Channel that damage breaks | `OceanDrake`'s Soothing Mist: damage counted in `_lose_hp`, acted on in `_physics_process`, "Interrupted!". |
| Wave fronts | `EnemyProjectile.front_width` (the Tidal Wave). |
| The stage-end screen | `StageResult`: stats, rewards, Retry / Next stage / Main screen; `Stage.finished(result, then)`; `Game._on_stage_finished`. Next after the last stage of the last act goes to the main screen. |
| Debug | The Waves tab spawns any enemy id from a list, "Jump to boss wave", "Boss HP 51%". |
| Boss bar | `BossBar.phase_text` already exists "for Act 6's Thresh". |

**Still missing for Acts 5–6:**
- **Root, stun and fear on Lucian.** Tenacity exists, and nothing reads it.
- **Summons:** enemies that call more enemies during the fight, which the wave waits for.
- **A quiet vanish** (no "Escaped!"), and a "freed" death look.
- **Leaps and charges, lasting spectral walls, ring warnings, and `EnemyProjectile.missed`.**
- **A layer that blocks walking but not shots** (the abyss).
- **The Black Mist.**
- **Act 5–6 maps, enemies, mini bosses and bosses, and the ending.**
- **The Act 1 handoff:** `Thresh` always stops at 50% HP, and `Stage` starts Act 1's cutscene for any `Thresh`.

### Decisions made with the user
| Topic | Decision |
|---|---|
| Phase 7 (Acts 3–4) | **Self-contained.** Phase 8 builds the shared pieces Phase 7 doesn't have. (Phase 7 is now done; Phase 8 reuses what it built.) |
| Black Mist (Act 5) | **It hides enemies.** Mist banks lie on the map. A normal or elite enemy inside one is *veiled* while Lucian is more than 350 px away: a dark silhouette with no health bar and no radar dot. Veiled enemies can still be targeted and hit. Their ground warnings always show. Bosses and mini bosses are never veiled. |
| Ending | **A cutscene, then an end screen.** When Thresh falls in Phase 2: an in-engine cutscene (Lucian shoots through the lantern, the souls go free, Senna comes back). Then the stage-end screen. Then, on the first clear only, a "The End" screen with the slot's total play time and short credits. Replays get the cutscene (skippable) and the stage-end screen. |

### Rulings from the revision onto Phase 7 (each goes into the docs in Task 13)
1. **Mini bosses are Phase 7's.** The old Task 3 (mini bosses) is gone. Maokai, Elise, Karthus revived and Hecarim are the last entry of their stage's last wave, come out of a camp named after them at the map's boss spot, and pay purple on the kill.
2. **Slows are Phase 7's** (`add_slow`; tenacity doesn't shorten them, as in LoL). Tenacity shortens root, stun and fear.
3. **Untargetable is Phase 7's** (`set_untargetable`), for Elise's Rappel and Maokai's leap.
4. **`vanish()` is built on `escape()`:** the same path (no rewards, done for the wave, `escaped` signal), with no "Escaped!" note.
5. **Summons work like Krug splits:** counted in the wave at once, spawned deferred.
6. **The abyss has no holes.** The chasm is several polygons. The Chain Warden ledges are drawn islands *inside* the chasm: for physics they are abyss, so nothing walks, dashes or blinks onto them. Perched enemies are placed there and never move.
7. **Boss HP is raised** so Acts 5–6 top Act 4's Dark Lucian (18000): Karthus 20000, Karthus revived 16000, Hecarim 18000, Thresh 16000 per phase. Maokai 12000 and Elise 13000 stay (over the drakes' 9000–10000). All placeholders, tuned later.
8. **Rappel locks at 1.0 s and Elise drops at 1.9 s.** The old 1.6 s left 0.6 s to leave a 180 circle at Lucian's 335 speed, too tight for the gentle-difficulty note (Phase 7 lengthened Sky Dive's warning for the same reason).
9. **The story's last screen is `TheEndScreen`**, because Phase 7's docs already call `StageResult` "the end screen". It shows after the stage-end screen on the first clear of 6-5, whichever button was chosen, then goes where that button said.
10. **Debug:** the enemy list exists. Phase 8 only adds "Boss HP 5%" and "Jump to the last wave".

### Fairness rules (from the "early difficulty" feedback: length comes from content, not punishing numbers)
- Every root, stun or fear on Lucian comes from a ground warning of at least 0.6 s, or from a projectile he can see.
- Root, stun and fear last 1.5 s at most. Tenacity shortens them.

### Other defaults (placeholders, tuned later; each goes into the docs in Task 13)
- **Summons** (Maiden's ghouls, the Broodmother's spiderlings, Thresh's Lantern Souls):
  - Each summoner has a cap on how many of its summons can be alive.
  - A summon gives 25% gold and XP, no essences and no loot (no farming).
  - When a summoner dies, its summons stay. The wave waits for them.
- **`vanish`:** the enemy leaves with no rewards at all. Used when a sapling explodes, and when Thresh's souls go free at his fall.
- **The abyss (Act 6)** is a new physics layer, `Layers.CHASM`:
  - It blocks walking, dashes, Flash, displacement (a pull stops at the edge) and enemy bodies. Paths go around it.
  - It does **not** block bolts, chains or Lucian's shots.
  - Rock spikes are normal `WORLD` walls and block bolts as cover does today.
- **Lantern Souls are "freed":** when killed (or vanished), they rise and brighten into teal-white light and fade upward with a soft chime, instead of the grey fade. They give normal rewards when killed.
- **Final Thresh never dies.** At 0 HP in Phase 1 he rises with full HP:
  - 2.5 s taking no damage, the warnings cleared, a darker tint and a green aura.
  - The boss bar reads "Phase 2".
  - At 0 HP in Phase 2 he falls: every summoned Lantern Soul is freed (vanish), and the ending cutscene plays.
- **Requiem** is used at 75%, 45% and 15% HP, once each. The boss bar shows a thin "break" bar while he channels.

---

## Design — Act 5: Shadow Isles

### Map: `DeadForestMap` (5400 × 3400; one map, varied by stage like `TrainingGroundMap`)
- **Ground:** a dead forest clearing.
  - The floor is dark grey-teal (`#2a3330`) with dead-grass flecks.
  - The top and bottom 250 px are a ragged wall of dense black trees: convex polygons, like Act 1's jungle.
- **Twisted trees** are the cover, as `wall_circles` (r 45–90):
  - Each tree is drawn as a black-grey trunk with crooked branch strokes.
  - `static trees(stage)` gives a fixed seeded list.
  - Trees stay ≥ 220 px from the start, the merchant, the boss point, the camps and the spawn points, and ≥ 160 px from each other, so walkers don't get stuck.
- **Points:**
  - Lucian starts west at (500, 1700).
  - The merchant stands in a stone-ringed clearing at the center, (2500, 1700).
- **Spawn points** ("saplings come out of trees"): the north tree line at (1800, 420) and (3400, 420), and the south one at (1800, 2980) and (3400, 2980).
- **Spider nest** (from 5-3): camp `&"nest"` in the east, drawn as a white web disc with a dark hole. Spiderlings name camp `nest`. Before 5-3 they come from the spawn points.
- **Black Mist:** `static mist(stage)` gives circles (x, y, r 380–520).
  - They are drawn on the ground, under units: layered pale green-grey blobs (`#9fb8a8`, about 35% alpha) that slowly breathe in alpha.
  - Never over the start, the merchant, the boss point or a camp.

| Stage | Trees | Mist banks | Nest camp | Boss spot |
|---|---|---|---|---|
| 5-1 | 14 | 2 | — | — |
| 5-2 | 16 | 3 | — | camp `maokai` (3900, 1700): Maokai rises from a huge dead tree (a ring of 6 trunk circles with a gap facing west) |
| 5-3 | 18 | 3 | (5000, 900) | — |
| 5-4 | 18 | 4 | (5000, 2500) | camp `elise` (3900, 1400): Elise drops from above |
| 5-5 | 10 west of x 3600 | 2 (far corners) | (5000, 900) | `boss_point` (4300, 1700): **the ruined graveyard** (x > 3600). Flagstones, rows of tombstones (rectangles 40 × 70) and a broken crypt wall (two slabs) behind Karthus. |

### Enemies (base numbers; normals and elites scale with the act: Act 5 HP ×3.4, damage ×2.0, gold and XP ×2.0, and +15% per wave)

| id | Class / behavior | Kind | HP | Arm / MR | Attack | Range | Every | Speed | r | Gold / XP |
|---|---|---|---|---|---|---|---|---|---|---|
| `sapling` | `Specter` / `bomber` | normal | 110 | 0 / 10 | **Bomber:** runs at Lucian. Within 80 it stops and shows a circle warning (r 120, 0.6 s), then explodes for 30 magic and `vanish`es (no rewards). Killing it first gives the rewards. | 80 | — | 340 | 22 | 30 / 15 |
| `spiderling` | `Monster` / `brute` | normal | 130 | 5 / 5 | Fast melee, 8 physical | 90 | 0.9 s | 380 | 20 | 25 / 12 |
| `ghoul` | `Monster` / `brute` | normal (summon) | 90 | 0 / 0 | Melee, 8 physical | 90 | 1.0 s | 320 | 20 | 20 / 10 (×25%) |
| `maiden_of_the_mist` | `Monster` / `brute` + summons | elite | 1500 | 35 / 35 | Tanky melee ghost, 40 physical. **Summons:** every 7 s, 2 `ghoul`s beside her, at most 6 alive. | 130 | 1.5 s | 220 | 42 | 140 / 80 |
| `broodmother` | `Monster` / `spit` + summons | elite | 1100 | 20 / 40 | **Web spit:** a bolt at 600 px/s for 30 magic; `hit_slow` 0.3 for 1.5 s. Keeps 450–600 away. **Summons:** every 3.5 s, 1 `spiderling`, at most 5 alive. | 600 | 2.0 s | 200 | 48 | 150 / 90 |

### Waves (p = sapling, s = spiderling, M = Maiden, B = Broodmother)
| Stage | Waves | Mini boss / boss |
|---|---|---|
| 5-1 | 8s 4p · 8s 6p · 8s 6p 1M · 10s 6p 1B · 10s 8p 1M | — |
| 5-2 | 8s 6p · 10s 6p 1M · 10s 6p 1B · 10s 8p 1M · 10s 8p 1M 1B | **Maokai** last in wave 5 |
| 5-3 | 10s 6p · 10s 6p 1M · 10s 8p 1B · 12s 8p 1M · 12s 8p 1B · 12s 8p 1M 1B | — |
| 5-4 | 10s 8p 1M · 10s 8p 1B · 12s 8p 1M · 12s 8p 2B · 12s 10p 1M 1B · 12s 10p 1M 1B | **Elise** last in wave 6 |
| 5-5 | 10s 8p 1M · 12s 8p 1B · 12s 10p 1M · 12s 10p 1M 1B · 14s 10p 2M · 14s 10p 1M 2B | boss wave: **Karthus** alone |

### Mini bosses and boss (fixed numbers; skill hits are `from_skill`)
| Boss | HP | Arm / MR | Basic | Skills |
|---|---|---|---|---|
| **Maokai** (`maokai`, mini boss, camp `maokai`, purple 5/1) | 12000 | 60 / 40 | Melee, 90 physical, every 1.6 s; speed 300, r 54 | **Twisted Advance:** a circle warning (r 90) on Lucian for 0.8 s, then he leaps there in 0.4 s, untargetable in the air. Inside the circle: 130 magic and a 1.0 s root. Cooldown 10 s, range 700. **Nature's Grasp:** a line warning (900 × 140) for 0.8 s, then a wall of vines travels along it at 700 px/s (a wave front). A hit: 110 magic and a 1.25 s root. Trees stop it. Cooldown 12 s. |
| **Elise** (`elise`, mini boss, camp `elise`, 5/1) | 13000 | 30 / 50 | Ranged bolt, 70 magic, range 550, every 1.4 s; speed 330, r 44 | **Cocoon:** a line warning (950 × 60) for 0.7 s, then a web bolt at 1300 px/s. A hit: 100 magic and a 1.25 s stun. Cooldown 11 s. **Rappel:** she rises and is untargetable for 1.9 s. A circle warning (r 180) follows Lucian for 1.0 s, then locks. She drops at 1.9 s for 160 magic inside it. Cooldown 16 s, first at 85% HP. |
| **Karthus** (`karthus`, boss, 10/2) | 20000 | 30 / 60 | Ranged bolt, 80 magic, range 600, every 1.5 s; speed 280, r 46 | **Lay Waste (Q):** 5 circle warnings (r 110): one on Lucian, four within 300 of him, 0.15 s apart, 0.7 s each. 110 magic per circle. Cooldown 6 s, range 900. **Wall of Pain (W):** a line warning across the way between them (900 long) for 0.6 s, then a spectral wall for 5 s. Touching or crossing it slows Lucian 70% for 2.5 s, once per cast. Cooldown 14 s. **Requiem (R):** at 75%, 45% and 15% HP. He stands and channels for 3 s, with a pulsing ring on Lucian and the break bar under the boss bar. 8% of his max HP in damage during the channel breaks it ("Broken!"). Otherwise Lucian takes 900 magic (`from_skill`, so Banshee's Veil blocks it). |

---

## Design — Act 6: The Lantern

### Map: `ThreshDomainMap` (5600 × 3400; stage 5 is the final platform)
- **Stages 1–4: three plateaus over the abyss.**
  - The abyss (`chasm_polygons`, on `Layers.CHASM`) is near-black with a slow green mist swirl. Decorative chains hang across it from rock spikes. No polygon has holes: the abyss is several polygons.
  - Plateaus are dark slate with faint green-glowing cracks: west (start, x 200–1700), center (merchant at (2800, 1700)) and east (boss spot (4700, 1700)).
  - Bridges are stone causeways with soul lanterns along their edges. Two per gap (north and south), 280 wide. In stages 3–4 they narrow to 200, and the north-west bridge is broken.
  - Rock spikes (`wall_circles` r 50–70) give cover on the plateaus.
- **Ledges:** "Chain Wardens on ledges" (design doc §13).
  - Small islands (r 120), drawn in the abyss with their centers about 260 px off the north and south edges of the center and east plateaus, so a warden on one is within Lucian's attack range from the edge.
  - **For physics a ledge is abyss** (ruling 6). `StageMap.ledge_points` lists them.
  - An enemy whose data has `perch = true` (Chain Warden) spawns on a free ledge and never moves. Its chain crosses the abyss, and Lucian's shots reach it from the edge. With no free ledge it spawns normally and walks.
- **Spawn points:** the east end of the east plateau, at (5250, 1250) and (5250, 2150), and the far ends of the bridges ("souls climb out of the abyss").
- **Stage 5: the final platform** ("a round, open platform with no walls").
  - A carved stone disc (r 1400) at (2800, 1700), with a rune ring and chains rising at its rim, in the abyss.
  - Four bridge stubs at N/E/S/W are the spawn points.
  - Lucian starts at the west rim. Thresh stands at the center (`boss_point`). The merchant stands at (2800, 1950) during breaks.
  - There are no ledges, so Chain Wardens spawn at the stubs and walk.

| Stage | Bridges | Ledges | Boss spot |
|---|---|---|---|
| 6-1 | 4 × 280 | 2 | — |
| 6-2 | 4 × 280 | 2 | camp `karthus_revived`, east plateau: the revived Karthus at a broken altar |
| 6-3 | 3 × 200 | 4 | — |
| 6-4 | 3 × 200 | 4 | camp `hecarim`, east: Hecarim rides in from the east end |
| 6-5 | the platform | 0 | `boss_point`, the center: Thresh |

### Enemies (Act 6 scaling: HP ×4.0, damage ×2.25, gold and XP ×2.25, and +15% per wave)
| id | Class / behavior | Kind | HP | Arm / MR | Attack | Range | Every | Speed | r | Gold / XP |
|---|---|---|---|---|---|---|---|---|---|---|
| `mist_walker` | `Monster` / `brute` | normal | 220 | 10 / 10 | Fast ghoul melee, 14 physical | 100 | 0.9 s | 360 | 26 | 55 / 28 |
| `lantern_soul` | `Monster` / `spit`, `frees` | normal | 150 | 0 / 20 | A bolt at 500 px/s for 22 magic; keeps 420–550 away. **Freed** on death. | 550 | 1.6 s | 280 | 24 | 45 / 25 |
| `spectral_rider` | `Specter` / `charger` | elite | 1300 | 40 / 20 | **Charge:** a line warning (800 × 90) for 0.8 s, then he charges along it at 1400 px/s. A hit: 60 physical and a 150 push along the charge. Walls and the abyss stop him. Dodge sideways. | 800 | 4.0 s | 280 | 42 | 140 / 80 |
| `chain_warden` | `Specter` / `warden`, `perch` | elite | 1200 | 35 / 35 | **Chain:** a line warning (700 × 60) for 0.8 s, then a chain at 1200 px/s. A hit: 45 physical and a pull of 300 toward him (the abyss edge stops it). Practice for Thresh's hook. Off a ledge it keeps 500–700 away. | 700 | 3.5 s | 220 | 40 | 150 / 90 |

### Waves (w = mist walker, l = lantern soul, R = rider, C = warden)
| Stage | Waves | Mini boss / boss |
|---|---|---|
| 6-1 | 8w 4l · 8w 6l · 8w 6l 1R · 10w 6l 1C · 10w 8l 1R · 10w 8l 1R 1C | — |
| 6-2 | 8w 6l · 10w 6l 1R · 10w 6l 1C · 10w 8l 1R · 12w 8l 1C · 12w 8l 1R 1C | **Karthus, revived** last in wave 6 |
| 6-3 | 10w 6l · 10w 8l 1R · 10w 8l 1C · 12w 8l 1R · 12w 8l 2C · 12w 10l 1R 1C · 14w 10l 2R 1C | — |
| 6-4 | 10w 8l 1R · 10w 8l 1C · 12w 8l 1R 1C · 12w 10l 2R · 12w 10l 2C · 14w 10l 1R 1C · 14w 10l 2R 1C | **Hecarim** last in wave 7 |
| 6-5 | 10w 8l 1R · 12w 8l 1C · 12w 10l 1R 1C · 14w 10l 2R · 14w 10l 2C · 14w 12l 1R 1C · 16w 12l 2R 2C | boss wave: **Thresh** alone |

### Mini bosses and final boss
| Boss | HP | Arm / MR | Basic | Skills |
|---|---|---|---|---|
| **Karthus, revived** (`karthus_revived`, mini boss, camp `karthus_revived`, 5/1; `karthus.svg` with a pale teal `tint`) | 16000 | 30 / 60 | Ranged bolt, 85 magic, range 600, every 1.5 s; speed 250 (he walks at Lucian) | **Lay Waste (Q):** 4 circles, 120 magic each; otherwise as in Act 5. **Defile (E):** an aura of r 350, always on and drawn as a purple ring: a `HazardZone` burn (80 magic per second, ticking every 0.5 s) kept on him each frame. Lucian (range 500) has to kite him. |
| **Hecarim** (`hecarim`, mini boss, camp `hecarim`, 5/1) | 18000 | 50 / 40 | Melee, 100 physical, every 1.3 s; speed 360, r 56 | **Devastating Charge:** ×1.8 speed with a glowing trail for 2.5 s, chasing Lucian. Contact: 170 physical and a 300 knockback. Cooldown 13 s. **Onslaught of Shadows:** a line warning (1100 × 300) for 1.0 s, then he rides along it with 4 spectral-rider ghosts beside him. A hit: 150 magic and a 1.0 s fear. Cooldown 18 s, first at 80% HP. |
| **Thresh** (`thresh_final`, boss, 20/4; `thresh.svg`) | 16000 per phase | 45 / 45 | Chain whip bolt, 85 physical, range 450, every 1.6 s; speed 320, r 48 | **Phase 1, Q/E/R:** **Death Sentence:** as in Act 1, but 160 magic, a 0.8 s warning and an 8 s cooldown. **Flay:** 120 magic, a 300 push, cooldown 7 s. **The Box:** used when Lucian is within 450. A ring warning (r 450) for 1.0 s, then 12 wall pieces in a ring for 4 s. A piece Lucian touches or crosses breaks and hits him for 150 magic and an 80% slow for 2 s. Cooldown 22 s. **Phase 2, Q/W/R** (darker): **Death Sentence:** the same, but a miss (it reaches its range or a wall without touching Lucian) is thrown again at once, once, with a 0.45 s warning. A hook Banshee's Veil blocks is not a miss. **Dark Passage:** throws the lantern to a spot within 250 of Lucian (circle warning r 100, 0.6 s). It lies there 6 s, and 3 `lantern_soul`s come out (summons). Cooldown 16 s. **The Box:** 220 magic, cooldown 18 s. |

### The ending
**`SennaFreed` cutscene** (a `Cutscene` subclass, skippable):
1. Thresh sinks to one knee (tint, scale). The lantern drops and glows.
2. Pan to the lantern. Lucian: "It ends here."
3. One bright shot flies from Lucian to the lantern. A flash and a ring burst; the lantern cracks.
4. Soul motes stream up. Senna's soul forms beside it (`senna.svg` fading in with a teal glow). Thresh dissolves into green smoke.
5. Senna: "Lucian… you came." Lucian: "Always."
6. A fade to white.

**After the cutscene** (as `Stage._on_cutscene_done` does for Act 1):
- Thresh's blue and orange are paid where he fell, with the line "Senna is free".
- He leaves the map, then `runner.enemy_died()` and `runner.finish()`.
- `_on_cleared` pays the 20 / 4 purple. On the first clear it adds the line "The story is complete".
- The stage-ending moment drops no loot.

**`TheEndScreen`**, shown by `Game` on the first clear of 6-5 only, after the stage-end screen's button:
- "THE END" with the title lantern art, and "Senna is free."
- "Story time: H:MM:SS", the slot's `play_time`.
- Three credit lines, ending with "A fan game. League of Legends characters belong to Riot Games."
- Continue goes where the stage-end button said (Main screen → the main screen on Act 6; Retry → 6-5 again). ESC does nothing on it.

---

## Architecture

Same layering as Phases 1–7:
- **Pure logic** in `src/core/`, tested first with GUT.
- **Data** as `.tres`.
- **Nodes and UI** built in code, no new `.tscn`.

The new pieces:
- **`CrowdControl`** (`src/core/crowd_control.gd`, RefCounted, pure; Lucian owns one, as he owns `DamageOverTime`):
  - `enum Kind { ROOT, STUN, FEAR }`.
  - `add(kind, seconds, tenacity, from := Vector2.ZERO)`: the time is `seconds × (1 − tenacity)`; the same kind keeps the longer time. `tick(delta)`, `has(kind)`, `time_left(kind)`, `duration(kind)`, `fear_from()`, `clear()`.
- **`Lucian`** gains only: `add_cc(kind, seconds, from := Vector2.ZERO)`, `has_cc(kind)`, `can_move()`, the gates (stun and fear make `can_act()` false; root makes `can_move()` false), the fear walk, the debuffs in `buffs()`, and `CHASM` in `_body_mask()` and `displace()`.
- **Enemy building blocks** (`EnemyUnit`, `EnemyData`):
  - Summons: `EnemyData.summon_id`, `summon_every`, `summon_count`, `summon_cap`; `signal summon_requested(unit, id, at)`; `summoned` (rewards ×25%, no essence, no loot).
  - `vanish()`: `escape()` with no note.
  - `EnemyData.frees`: the freed fade in place of the grey one.
  - `leap_to(point, seconds)`, `charge(direction, distance, speed)`, `signal landed`.
  - `veiled` (the mist).
  - `EnemyData.tint` (a sprite tint) and `perch`.
- **Combat pieces:** `EnemyProjectile.missed`; `GroundWarning.ring(...)`; `SpectralWall` (`src/combat/spectral_wall.gd`).
- **`Specter`** (`src/enemies/specter.gd`, `extends EnemyUnit`): the behaviors `bomber`, `charger` and `warden`. Act 5–6's other enemies are `Monster`'s `brute` and `spit`.
- **Maps:**
  - `StageMap` gains `chasm_polygons` (a second static body on `CHASM`, baked into the nav mesh as obstructions, checked by `is_walkable`), `ledge_points` and `mist: Array[Vector3]`.
  - `PathFollower`'s ray also hits `CHASM`; enemy bodies collide with it.
  - `Stage._use_map` adds a `BlackMist` node under `$World` when `arena.mist` isn't empty, so it freezes with the world.
- **Bosses:** `Maokai`, `Elise`, `Karthus` (with a `revived` mode), `Hecarim`, `ThreshFinal extends Thresh`.
  - `Thresh`'s skill numbers become vars that default to today's constants. Its 50% stop only happens while `stop_share > 0`.
  - `Stage` connects Act 1's `phase_ended` as today (ThreshFinal never emits it) and `ThreshFinal.fell` to the ending.
  - `Boss.channel() -> Dictionary` (`{}` when not channeling, else `{"done": damage so far, "need": damage to break}`) feeds the break bar. Karthus's Requiem follows Ocean Drake's pattern.
- **Ending:** `src/stage/cutscenes/senna_freed.gd`, `src/ui/title/the_end_screen.gd`; `Game` shows `TheEndScreen` between the stage and where the player chose to go.

## Global constraints (as in Phases 6–7)
- **Code style:** Godot 4.7.2 GDScript as around it: tabs, typed vars, `##` doc comments, `&"name"` StringNames, one `class_name` per file. No autoloads, no new `.tscn`.
- **The sandbox:** `stage.tscn` run alone stays the sandbox, and `StageSetup.new()` has `act = 0`.
- **Numbers:** new player-facing numbers are constants at the top of their script or exports on `.tres`.
- **Commits:** work on `main`, one verified commit per task (full GUT suite green), never pushed. Every commit message ends with `Co-Authored-By: Claude <noreply@anthropic.com>`.
- **Docs voice:** short plain sentences, tables for numbers.
- **Physics flush rule (Phase 7):** nothing inside a damage path adds a body or runs a physics query (bullets deal damage inside `area_entered`). Record what happened in `take_damage`, `_lose_hp` or `_die`, then act in `_think`, `_physics_process` or a deferred call. Summons, Thresh's phase change and his fall follow it.
- **Enemy holders:** everything that holds an enemy keeps checking `is_alive()` or `is_target()`, as Phase 7 left it. Don't add new checks for the new states.
- **Stay small:** `lucian.gd` is 1351 lines. CC timers live in `CrowdControl`; Lucian gains only what *Architecture* lists.
- **Reuse, don't fork:** slows through `add_slow`, untargetable through `set_untargetable`, vanish through `escape`, terrain through `HazardZone`, wave fronts through `front_width`.

## Running things
```powershell
$godot = "$env:LOCALAPPDATA\Programs\Godot"
& "$godot\godot_console.exe" --headless --path . --import
& "$godot\godot_console.exe" --headless --path . -s res://addons/gut/gut_cmdln.gd
& "$godot\godot_console.exe" --headless --path . -s res://addons/gut/gut_cmdln.gd -gconfig= -gtest=res://tests/unit/<file>.gd -gexit
& "$godot\godot.exe" --path . -s res://tests/tools/screenshot.gd -- <scenario> <out_dir>
```

---

## Tasks

### Task 0: Save the plan
- [ ] Write the docs
- [ ] Commit

- Copy this plan to `docs/implementation/phase8.md`. Give each task the house checklist: failing tests → run → implement → run → commit. No pre-written code.
- Add "Phase 8: `implementation/phase8.md`" to `lucian_game_design.md` §16.
- Add the wave tables to `act5_shadow_isles.md` and `act6_the_lantern.md`.
- Commit: "Add the Phase 8 plan".

### Task 1: Root, stun and fear on Lucian (+ 3 debuff icons)
- [ ] Write the failing tests
- [ ] Run them: they fail
- [ ] Implement
- [ ] Run the full suite: green
- [ ] Commit

**Files:**
- New: `src/core/crowd_control.gd`; the art `assets/art/ui/debuff_{root,stun,fear}.svg` (in the style of `debuff_slow.svg`).
- Change: `src/lucian/lucian.gd`, `lucian_controller.gd`, `lucian_health_bar.gd`.

**Effects:**

| Kind | Effect |
|---|---|
| Root | `can_move()` is false: no walking (orders keep, he just doesn't step), no E dash, no Flash. Attacks in range, other skills and items still work. |
| Stun | `can_act()` is false. Drops the windup, the queued cast, a dash and R (as a displacement does). |
| Fear | `can_act()` is false. Drops the same as a stun. Lucian walks straight away from the source at 60% of his speed, sliding along walls. |

**Rules:**
- Tenacity (`stats.tenacity`) shortens root, stun and fear. Slows stay as Phase 7 left them.
- Dead, stasis, `invulnerable` and a throw (`is_launched`) refuse CC. Death clears it.
- `add_cc(kind, seconds, from := Vector2.ZERO)` is the only entry point.
- **Skill CC lands only when its hit lands:** callers apply it only if `take_damage` returned true, so Banshee's Veil blocks both.
- **On screen:**
  - `buffs()` lists active CC as debuffs with the new icons ("Rooted", "Stunned", "Feared"), next to Phase 7's "Slowed".
  - A short red word ("Rooted", "Stunned", "Feared") shows under his health bar while it lasts. The strongest wins: stun, fear, then root.

**Tests** (`test_crowd_control.gd`, `test_lucian_cc.gd`):
- The longer time wins; tenacity 0.3 makes 1.0 s last 0.7 s.
- Root: a move order doesn't move him, and E and Flash are refused, but a basic attack in range fires.
- A stun drops R and the queued cast.
- Fear walks him away from the source.
- CC is refused in stasis, while invulnerable and in flight; death clears it.
- The debuffs show in `buffs()`.

**Commit:** "Lucian can be rooted, stunned and feared; tenacity shortens it; the debuffs and a word under his health bar".

### Task 2: Enemy building blocks
- [ ] Write the failing tests
- [ ] Run them: they fail
- [ ] Implement
- [ ] Run the full suite: green
- [ ] Commit

**Files:**
- New: `src/combat/spectral_wall.gd`.
- Change: `src/enemies/enemy_unit.gd`, `src/core/enemy_data.gd`, `src/core/kill_rewards.gd`, `src/combat/enemy_projectile.gd`, `ground_warning.gd`, `src/core/layers.gd`, `src/stage/stage.gd`, `stage_map.gd`, `path_follower.gd`, `src/lucian/lucian.gd`, `project.godot` (the layer name).

**What to build:**
- **`EnemyData`** new exports: `tint`, `perch`, `summon_id`, `summon_every`, `summon_count`, `summon_cap`, `frees`.
- **Summons** (`EnemyUnit`):
  - With `summon_id` set, every `summon_every` seconds of fighting it emits `summon_requested(self, summon_id, at)` up to `summon_count` times, keeping its live summons (requested ones included) at or under `summon_cap`.
  - `Stage` handles it like a Krug split: `runner.enemy_spawned()` at once, then a deferred `spawn_enemy(id, at, unit.wave)`. The summon gets `summoned = true`, and the stage tells the summoner when that summon dies or vanishes.
  - `KillRewards.roll(..., summoned := false)`: 25% gold and XP, no blue, no orange. `Stage._on_enemy_died` drops no loot for a summon.
- **`vanish()`:** `escape()` with no "Escaped!" note (an `escape_note` the stage reads; empty = none).
- **`EnemyData.frees`:** `_fade_out` plays the freed fade (rise, brighten to teal-white, fade up, the `freed` chime in `src/audio/sfx.gd`) in place of the grey one.
- **`leap_to(point, seconds)`:** an arc (scale up and down), untargetable in the air, lands at `point`, emits `landed`.
- **`charge(direction, distance, speed)`:** moves with `move_and_slide` until the distance is done or a wall or the abyss stops it; hits Lucian at most once (a callable the caller gives); emits `landed`.
- **`veiled`:** a dark silhouette on the sprite (not `visuals.modulate`, which the hit flash tweens) and the health bar hidden.
- **`tint`:** the sprite's color.
- **`EnemyProjectile.missed`:** it reached its range or hit a wall without touching Lucian. A hit Banshee's Veil blocks is not a miss.
- **`GroundWarning.ring(at, radius, width, seconds)`**, drawn as a band; `covers` is true on the band.
- **`SpectralWall`:**
  - `line(center, along, length, seconds)` and `ring(center, radius, pieces, seconds)`.
  - Each `_physics_process` it checks Lucian's path since the last frame (segment against segment, with his hit radius), so a dash or a Flash across a piece is caught. No physics queries.
  - `signal touched(piece)`, once per piece per cast. Option `break_on_touch` (the piece goes).
  - Drawn as pale spectral slabs; it fades out at the end.
- **`Layers.CHASM` (32)**, named in `project.godot`:
  - `StageMap.chasm_polygons` builds a second static body on `CHASM`, adds the polygons to the nav bake as obstructions, and `is_walkable` refuses points in or near them. `ledge_points` and `mist` are new empty lists.
  - `PathFollower`'s ray mask is `WORLD | CHASM`. `EnemyUnit` bodies collide with `CHASM`.
  - Lucian: `_body_mask()` adds `CHASM` (a throw's 0 stays), and so does `displace()`'s mask. `fits_at` follows `_body_mask()`, so Flash can't land on the abyss.

**Tests** (`test_enemy_blocks.gd`, `test_spectral_wall.gd`; extend `test_maps.gd`, `test_wave_runner.gd`, `test_kill_rewards.gd`):
- A summon keeps the wave open; it pays 25% gold and no essence; the cap holds; a summoner's death leaves its summons in the wave.
- A vanished enemy pays nothing, shows no note, and the wave still ends.
- A charge stops at a wall; a leap lands where it was aimed.
- A projectile that misses emits `missed`; one Banshee's Veil blocks doesn't.
- A dash across a wall piece is caught; each piece touches once.
- A chasm stops a walk, a displacement and Flash, but not an enemy bolt; a path goes around it.

**Commit:** "Enemy building blocks: summons the wave waits for, vanish, leaps and charges, spectral walls, ring warnings, the chasm layer".

### Task 3: Act 5 map: the dead forest and the Black Mist
- [ ] Write the failing tests
- [ ] Run them: they fail
- [ ] Implement
- [ ] Run the full suite: green
- [ ] Commit

**Files:**
- New: `src/stage/maps/dead_forest_map.gd`, `src/stage/black_mist.gd`.
- Change: `stage_maps.gd` (act 5), `stage.gd` (`_use_map` adds the mist), `src/ui/hud/radar.gd` (skips veiled enemies).
- **`BlackMist`:**
  - Its `_physics_process` sets `veiled` on every normal and elite enemy: inside a bank and more than `REVEAL_RANGE` (350) from Lucian.
  - It draws the banks.

**Tests** (`test_maps.gd` with `[5, 1..5]`, `test_black_mist.gd`):
- The points and camps are walkable, and none is in mist.
- Trees keep their gaps (the static `trees(stage)` is checked).
- An enemy in mist is veiled far away and shown up close.
- A veiled enemy is still hit by an attack.
- The radar skips it.
- A mini boss is never veiled.
- The graveyard only exists in 5-5; the nest camp only from 5-3.

**Commit:** "Act 5 map: a dead forest with twisted trees, a spider nest, Black Mist that hides enemies, Karthus's graveyard".

### Task 4: Act 5 enemies (+ art)
- [ ] Write the failing tests
- [ ] Run them: they fail
- [ ] Implement
- [ ] Run the full suite: green
- [ ] Commit

**Files:**
- New: `src/enemies/specter.gd` (behavior `bomber`; `charger` and `warden` come in Task 8).
- Change: `stage.gd` `_new_unit` (`bomber`, `charger`, `warden` → `Specter`).
- `data/enemies/{sapling,spiderling,ghoul,maiden_of_the_mist,broodmother}.tres`.
- `assets/art/enemies/{sapling,spiderling,ghoul,maiden_of_the_mist,broodmother}.svg` (Phase 7's SVG house style: top-down, facing +X, a `<!-- Name: description -->` header, `#1a1d24` outline).

**Art:**
- Sapling: a little walking dead tree with a glowing green core.
- Spiderling: a small black spider with red eyes.
- Ghoul: a hunched pale ghost.
- Maiden: a tall veiled ghost woman in a teal shroud.
- Broodmother: a huge spider with a bone-white carapace.

**Tests** (`test_act5_enemies.gd`; `test_enemy_data_files.gd` covers the new files):
- A sapling explodes only after its warning, hurts only inside it, and pays nothing.
- Killing a sapling first pays its rewards.
- The Maiden summons 2 ghouls every 7 s, never more than 6.
- The web spit slows Lucian 30%.
- The Broodmother keeps her distance and caps at 5 spiderlings.

**Commit:** "Act 5 enemies: saplings that explode, spiderlings, the Maiden of the Mist and her ghouls, the Broodmother's web".

### Task 5: Maokai and Elise (+ art)
- [ ] Write the failing tests
- [ ] Run them: they fail
- [ ] Implement
- [ ] Run the full suite: green
- [ ] Commit

**Files:**
- `src/enemies/bosses/maokai.gd`, `elise.gd`.
- `data/enemies/maokai.tres`, `elise.tres` (kind `mini_boss`, camps `maokai` and `elise`).
- `assets/art/enemies/maokai.svg` (a huge treant with a twisted bark face) and `elise.svg` (a spider-queen in red and black).
- `stage.gd` `_new_unit`; `save_game.gd` `BOSS_IDS` += `maokai`, `elise`.

**Tests** (`test_maokai.gd`, `test_elise.gd`):
- Twisted Advance roots only inside the circle; Maokai can't be hit in the air.
- The vine wave roots and is stopped by a tree.
- Cocoon stuns, and Banshee's Veil blocks the stun too.
- During Rappel, Elise can't be hit; she lands where the warning locked.
- The skill gates and cooldowns work.

**Commit:** "Act 5 mini bosses: Maokai's Twisted Advance and Nature's Grasp, Elise's Cocoon and Rappel".

### Task 6: Karthus; Act 5 is playable (+ art)
- [ ] Write the failing tests
- [ ] Run them: they fail
- [ ] Implement
- [ ] Run the full suite: green
- [ ] Commit

**Files:**
- `src/enemies/bosses/karthus.gd` (with `revived := false`; the revived mode comes in Task 9).
- `data/enemies/karthus.tres`, `assets/art/enemies/karthus.svg` (a robed lich with a skull staff, pale purple).
- `src/enemies/boss.gd`: `channel()`; `ocean_drake.gd` reports its Soothing Mist through it too.
- `wave_plan.gd`: stages 5-1 … 5-5 (Maokai last in 5-2's last wave, Elise in 5-4's), `BOSSES["5-5"]`, and the new id constants.
- `src/ui/hud/boss_bar.gd`: the break bar from `Boss.channel()`.
- `save_game.gd` `BOSS_IDS` += `karthus`.

**Tests** (`test_karthus.gd`; extend `test_journey.gd` and `test_stage_waves.gd` to Act 5):
- Lay Waste hurts only inside its circles.
- Wall of Pain slows on crossing, once per cast.
- Requiem fires at 75% and not again until 45%.
- 8% of his HP in damage breaks it; a channel that isn't broken does 900 magic.
- The boss bar shows the break bar while he channels (and for the Ocean Drake's mist).
- `WavePlan` wave counts match `Journey`.
- Act 5's Start works once Acts 1–4 are cleared.
- 5-2 pays Maokai's 5 purple on the kill; 5-5 clears and pays 10, then 2.

**Commit:** "Act 5: Karthus with Lay Waste, Wall of Pain and Requiem (break it in time); Act 5's five stages can be played".

### Task 7: Act 6 map: Thresh's domain
- [ ] Write the failing tests
- [ ] Run them: they fail
- [ ] Implement
- [ ] Run the full suite: green
- [ ] Commit

**Files:** new `src/stage/maps/thresh_domain_map.gd`; `stage_maps.gd` (act 6); `stage.gd` (`_spawn_point`: a perched enemy goes to a free ledge, without jitter).

**Tests** (`test_maps.gd` with `[6, 1..5]`):
- The points and camps are walkable; spawn points are on plateaus or bridges.
- The ledges aren't walkable and can't be reached by a path from the start.
- A chasm stops Lucian at the edge; a bolt flies over it.
- 6-5 has no walls inside the platform.
- A perched enemy spawns on a free ledge, never moves, and the next one takes the other ledge.
- Every ledge is within Lucian's attack range (500) of walkable ground.

**Commit:** "Act 6 map: plateaus and bridges over the abyss, Chain Warden ledges, the final round platform".

### Task 8: Act 6 enemies (+ art)
- [ ] Write the failing tests
- [ ] Run them: they fail
- [ ] Implement
- [ ] Run the full suite: green
- [ ] Commit

**Files:**
- `specter.gd`: the behaviors `charger` and `warden`.
- `data/enemies/{mist_walker,lantern_soul,spectral_rider,chain_warden}.tres` and the SVGs.

**Art:**
- Mist Walker: a lean grey ghoul trailing mist.
- Lantern Soul: a teal-green wisp with a sad face.
- Spectral Rider: a ghost knight on a spectral horse.
- Chain Warden: a hooded jailer with a chain and a hook.

**Tests** (`test_act6_enemies.gd`):
- The rider charges along its warning; a sideways step dodges it; a wall stops it.
- The warden's chain pulls 300 and stops at the abyss edge; a perched warden never moves.
- A freed soul pays like a kill and plays the freed fade.

**Commit:** "Act 6 enemies: Mist Walkers, Lantern Souls that go free, Spectral Riders that charge, Chain Wardens that pull".

### Task 9: Karthus revived and Hecarim (+ art)
- [ ] Write the failing tests
- [ ] Run them: they fail
- [ ] Implement
- [ ] Run the full suite: green
- [ ] Commit

**Files:**
- `karthus.gd` (the revived mode: Q and Defile).
- `src/enemies/bosses/hecarim.gd`.
- `data/enemies/karthus_revived.tres` (with a `tint`), `hecarim.tres`.
- `assets/art/enemies/hecarim.svg`: a spectral centaur with a lance, green-blue flame.
- `save_game.gd` `BOSS_IDS` += `karthus_revived`, `hecarim`.

**Tests** (`test_karthus.gd`, `test_hecarim.gd`):
- Defile hurts only inside 350, ticking every 0.5 s, and moves with him; it goes when he dies.
- Devastating Charge knocks back on contact, once.
- Onslaught fears for 1.0 s, only inside its band.
- The skill gates work.

**Commit:** "Act 6 mini bosses: Karthus revived with Defile, Hecarim's Devastating Charge and Onslaught of Shadows".

### Task 10: Final Thresh; Act 6 is playable
- [ ] Write the failing tests
- [ ] Run them: they fail
- [ ] Implement
- [ ] Run the full suite: green
- [ ] Commit

**Files:**
- `src/enemies/bosses/thresh.gd` (vars, `stop_share`).
- New `thresh_final.gd`, `data/enemies/thresh_final.tres`.
- `wave_plan.gd`: stages 6-1 … 6-5 (Karthus revived last in 6-2's last wave, Hecarim in 6-4's), `BOSSES["6-5"]`.
- `stage.gd`: `ThreshFinal.fell` (deferred) → `_on_thresh_fell` (warnings and projectiles cleared, summoned souls vanish; for now it pays and finishes as `_on_cutscene_done` does — Task 11 puts the cutscene between).
- `boss_bar.gd`: Thresh's phase text.
- `save_game.gd` `BOSS_IDS` += `thresh_final`.

**Tests** (`test_thresh_final.gd`; `test_act1.gd` stays green):
- Phase 1 at 0 HP → 2.5 s taking no damage → full HP and "Phase 2".
- Phase 2 swaps E for W.
- A dodged hook is thrown again once; a blocked one isn't.
- The Box hurts and slows once per piece, and a touched piece breaks.
- Dark Passage brings 3 summoned souls, counted in the wave.
- At 0 HP in Phase 2, `fell` fires once and every summoned soul vanishes.
- Act 1's Thresh still stops at 50% and plays its cutscene.
- 6-5 clears and pays 20 purple, then 4.

**Commit:** "Final Thresh: two phases (Q/E/R, then Q/W/R darker), The Box, the second hook, Dark Passage; Act 6's stages can be played".

### Task 11: The ending
- [ ] Write the failing tests
- [ ] Run them: they fail
- [ ] Implement
- [ ] Run the full suite: green
- [ ] Commit

**Files:**
- New: `src/stage/cutscenes/senna_freed.gd`, `src/ui/title/the_end_screen.gd`.
- Change: `stage.gd` (`_on_thresh_fell` plays `SennaFreed`; `_on_ending_done` pays, adds "Senna is free", finishes; `_on_cleared` adds "The story is complete" on the first clear), `src/main/game.gd` (`TheEndScreen` on the first clear of the last stage, then where the button said).

**Tests** (`test_ending.gd`; extend `test_game.gd`):
- Skipping the cutscene still clears 6-5 and pays 20 purple, then 4.
- The first clear shows `TheEndScreen` with the slot's play time, then the main screen on Act 6 (or 6-5 again after Retry).
- A replay goes straight where the button said.
- ESC is locked on `TheEndScreen`.

**Commit:** "The ending: Lucian shoots through the lantern and frees Senna; The End screen with the story time".

### Task 12: Debug
- [ ] Write the failing tests
- [ ] Run them: they fail
- [ ] Implement
- [ ] Run the full suite: green
- [ ] Commit

**File:** `src/ui/debug/debug_table.gd` (and `stage.gd` / `wave_runner.gd` for the jump).
- **Boss HP 5%** beside "Boss HP 51%" (Thresh's phase change and his fall; it also finds a boss out of the group, as 51% does).
- **Jump to the last wave**: every enemy goes (no rewards) and the stage's last wave comes next (a mini boss stage's mini boss wave).

**Tests:** extend `test_stage_debug_waves.gd`.

**Commit:** "Debug: boss to 5%, jump to the last wave".

### Task 13: Screenshots, docs, report
- [ ] Run the scenarios
- [ ] Look at every PNG
- [ ] Fix what doesn't read
- [ ] Write the docs and the report
- [ ] Run the full suite: green
- [ ] Commit

**Scenarios** in `tests/tools/screenshot.gd` (through `ACT_SCENARIOS`):
- `act5_mist`, `act5_sapling`, `act5_brood` (slow, debuff icon), `maokai_grasp` (root word), `elise_rappel`
- `karthus_wall`, `karthus_requiem` (break bar)
- `act6_bridges` (ledges, chain), `act6_rider`, `karthus_defile`, `hecarim_onslaught`
- `thresh_box`, `thresh_phase2`, `thresh_lantern`
- `ending_cutscene`, `the_end`

**Look at every PNG.** Fix what doesn't read, with a test for each fix where one fits.

**Docs:**
- `act5_shadow_isles.md` and `act6_the_lantern.md`: "Built in Phase 8" with every number.
- `lucian_game_design.md`: §3 (CC on Lucian, summons), §9 (summon rewards), §12 and §13 (maps built), §16.
- `ui_design.md`: the debuff icons and word, the break bar, the phase text, `TheEndScreen`.
- `main_screen.md`: Acts 5–6 Start.
- `docs/implementation/phase8.md`: "Implementation notes" (deviations, rulings, fixes from reviews), as Phase 7's.

**Report:** `docs/report/phase8.md` (+ `report/phase8/*.png`) in the Phase 7 layout.

**Commit:** "Phase 8 screenshots, docs and report".

---

## Verification
1. **GUT:** the full suite is green after every task (`gut_cmdln.gd`). The new test files are listed per task.
2. **Screenshots** (Task 13): run every scenario and inspect each PNG:
   - mist silhouettes and their reveal
   - every new telegraph (ring, wall, vine wave, charge line)
   - the CC word and debuff icons
   - the break bar
   - Thresh's darker Phase 2
   - the cutscene and `TheEndScreen`
3. **Manual playtest** (also goes into the report checklist):
   1. Main debug → Acts cleared = 4 → Journey → Act 5 → Start 5-1.
   2. A sapling's warning, then dodge it. Enemies vanish into the mist and show up close.
   3. 5-2: Maokai comes last in wave 5. His vine wave roots ("Rooted" shows). His kill → +5 purple.
   4. 5-4: Elise's Cocoon stuns, and Banshee's Veil blocks it. Rappel: she can't be hit.
   5. 5-5: Wall of Pain slows; break a Requiem; let one land.
   6. Act 6: a Chain Warden on a ledge pulls Lucian to the abyss edge, not into it. A rider's charge is dodged sideways.
   7. 6-2 Defile: kite Karthus. 6-4 Onslaught: a fear.
   8. 6-5: Thresh Phase 1 → the rise → Phase 2. A dodged hook comes again. Dark Passage souls. The Box.
   9. The ending cutscene (also try Skip) → STAGE CLEARED +20 purple, "The story is complete" → Main screen → The End with the play time → the main screen on Act 6.
   10. Replay 6-5: no The End, +4 purple.
4. **Save file:** after 6-5, `"bosses"` holds every new id, and `"cleared"` holds `"6-5"`.
5. **Pacing:** Act 5: 80–100 min, Act 6: 90–120 min. Stage times show on the stage-end screen. The report notes the screenshot times mean nothing for real play.

## Risks to watch
- **Summons and the wave count:** every summon goes through `runner.enemy_spawned()` at the request. Test a wave that ends with a summoner killed while its summons live, and a summon requested on the frame its summoner dies.
- **`CHASM` everywhere a body moves:** Lucian's walk, dash, Flash (`fits_at`) and `displace`, enemy bodies, charges, leaps and paths. A missed mask drops Lucian into the abyss.
- **Thresh's refactor:** Act 1's cutscene must still fire only for `thresh_1`. Keep `test_act1.gd` green at every step.
- **Walking in the forest:** trees are convex and apart; test a walker crossing a tree cluster on a path.
- **The veil and the hit flash** both color the enemy; the veil must not be undone by a flash.
