# Phase 7 report: Acts 3 and 4, the stage-end screen, and A + Left-click

**Date:** 2026-10-29 · **Branch:** `main` (commits from `19a423f` to this report, not pushed) · **Plan:** `docs/implementation/phase7.md`

## Summary

All 3 points on your Phase 7 list are built and checked:
- **Acts 3 and 4**, designed and built:
  - **The Jungle:** monster packs from their camps, jungle buffs, lava, Blast Cones, shallow water, Honeyfruit, two drakes, and the Elder Dragon in his pit.
  - **The Darkness:** shadow minions on a dark mid lane, ending with Dark Lucian.
- **A full-screen end screen** when a stage is cleared or lost: stats, rewards, and **Retry**, **Next stage** and **Main screen**.
- **A + Left-click** attacks what you mean: the enemy under the cursor, else the weakest in range, else the nearest, chased.

Under that, the game gained:
- slows and burns, for Lucian and enemies alike;
- enemies that can't be targeted for a moment;
- Lucian thrown over walls;
- mini bosses;
- enemies and Lucian that walk around walls on a baked path.

Acts 1–4 now play: 12 of the 22 stages.

The test suite grew from **765 to 1041 tests**, and all of them pass. Every new fight, map and screen was checked in screenshots from a real game window. The last task's visual pass fixed seven things (see *Visual pass*).

Your choices during planning:

| Topic | Your choice |
|---|---|
| A + Left-click pick | The **hovered** enemy. Else the **lowest HP %** in Lucian's attack range (the nearer on a tie). Else the **nearest enemy on the map**, chased. |
| After that kill | **Stop.** One target per click. |
| End screen | **Full-screen summary:** a banner, a stats column and a rewards column. **No stars.** |
| End-screen buttons | **Retry**, **Next stage** (after a clear, when the next stage can be played) and **Main screen**. The tutorial's GAME OVER keeps **Back to title**. |
| Blast Cones | **Shoot it.** A hit pops it and throws Lucian over walls if he is near. |

## What you asked for → what was built

| # | Request | Built |
|---|---|---|
| 1 | Design the maps and enemies of Acts 3 and 4, and build them | **Act 3, The Jungle** (5 stages): a 5600 × 3600 jungle of 420-wide paths and clearings, with camps for 4 packs (raptors, wolves, Krugs, Gromp) and 3 elites (Blue Sentinel, Red Brambleback, Rift Scuttler). 3-2 adds lava and Blast Cones and ends with the **Infernal Drake**; 3-4 adds shallow water and Honeyfruit and ends with the **Ocean Drake**; 3-5 is the **Elder Dragon**'s round pit. **Act 4, The Darkness** (3 stages): Act 1's lane in black and purple, four shadow minions, and **Dark Lucian** with Q, E and R. Full numbers in `act3_the_jungle.md` and `act4_the_darkness.md`. |
| 2 | The screen shown when a stage is cleared or lost, leading back to the main screen | The **end screen**: STAGE CLEARED, DEFEATED or GAME OVER over a gold or dark red glow; Time, Waves, Kills, Damage dealt, Damage taken, Gold earned and Level reached; each essence with its icon and the reward lines ("+5 purple essence (Infernal Drake, first kill)", "Stage 3-3 is open"). **Retry** and **Next stage** start a stage directly; **Main screen** opens the main screen on that act. Each saves first. |
| 3 | Fix A + Left-click: under the cursor, else lowest HP % in range, else nearest, chased | As asked. The chase walks around walls. After the kill he stops. With no enemy at all he walks to the point. A dead or untargetable enemy is never picked. |

### Under the three points

| Part | Built |
|---|---|
| Status effects | `DamageOverTime` (a tick every 0.5 s). The strongest slow wins, on Lucian and on enemies; tenacity doesn't shorten slows. Burn ticks make no sound or flash and trigger no on-hit effect, Thornmail or Banshee's Veil. They show in the buff row ("Slowed", "Burning") and over enemy bars. Gunblade's slow uses the same system. Death clears them all. |
| Jungle buffs | Blue: 60 s of +10 mana regen and +20 ability haste. Red: 60 s of +5 HP regen; his attacks burn 15 true a second for 3 s, and his attacks and skills slow 15% for 1.5 s. Both show in the buff row. |
| Untargetable | Sky Dive and Dark Lucian's dash: the enemy leaves the enemies group, so shots in flight miss, A + Left-click and the radar drop it, and it takes no damage. Lucian keeps his attack order and shoots again once it is back; the boss bar keeps it. |
| The throw | `Lucian.launch`: over walls, in 0.6 s, no acting and no pushes in flight, landing on walkable ground, no Energize from it. |
| Mini bosses | A new kind: no scaling, a wide health bar, a 12 px skull on the radar, the boss bar while no boss is out. 50 blue, 3 orange and 5 / 1 purple, paid on the kill. A fragment for sure plus 8% a legendary. |
| Packs and camps | A wave lists packs; each comes out of its camp. Big Krugs split in two on death (the wave waits for them). The Scuttler runs and escapes after 15 s: "Escaped!", no rewards, not a kill. |
| Walking around walls | Every map bakes a navigation mesh from its walls. Enemies and Lucian walk straight while the line is clear, else follow the path. Acts 1–2 use it too. |
| Debug | The stage debug table's Waves tab lists every enemy in `data/enemies/` with a Spawn button. Boss HP 51% also works on the new bosses, mid-dive included. |
| Art | 26 new SVGs: 10 monsters, 2 drakes, the Elder Dragon, 4 shadow minions, Dark Lucian, the Blast Cone and Honeyfruit, and 6 buff and status icons. |

### The bosses

| Boss | Where | HP | Skills |
|---|---|---|---|
| Infernal Drake (mini boss) | Last in 3-2's last wave | 9000 | Fire Breath (a 60° cone that burns for 3 s), Meteor Fall (4 circles that burn) |
| Ocean Drake (mini boss) | Last in 3-4's last wave | 10000 | Tidal Wave (a 180-wide wave front: push and slow), Soothing Mist (heals 30%; 8% damage interrupts it) |
| Elder Dragon | 3-5's boss wave | 16000 | Elder Breath (a 90° cone), Sky Dive (unseen, its shadow follows, then lands on a circle), Elder's Mark (130 true after 4 s, × 3 under 25% HP) |
| Dark Lucian | 4-3's boss wave | 18000 | Two-shot basic attack; Piercing Light (a laser on a line), Relentless Pursuit (a dash that dodges or chases), The Culling (24 bullets down a fixed line while he strafes) |

The drakes give 5 purple the first time and 1 after; the Elder Dragon and Dark Lucian 10 and 2.

## Choices made where the request was open

Settled during planning (placeholders, easy to change):
- **A + Left-click with no enemy** walks to the point. The attack-range ring and the cross cursor work as before.
- **Packs** come out of their camp (±90 px), still in groups of 3 every 1.2 s.
- **Pathing:** straight while the line is clear, else a path re-asked every 0.4 s (or when the goal moves 120). The enemies' sidestep stays as a fallback. Lucian's moves, chases, merchant visits and cast walks path too.
- **Mini bosses** pay 50 blue, 3 orange and purple on the kill, not at the clear.
- **The Scuttler** escapes after 15 s with nothing; caught, it adds 45 blue and 4 orange to an elite's rewards.
- **Terrain acts on Lucian only.** Lava burns 40 magic a second (and 0.5 s after he leaves); water slows 25%; Honeyfruit heals 100 + 6% of max HP and regrows after 30 s; a Blast Cone regrows after 20 s.
- **Shadow minions** are their own data files with the Act 1–2 numbers.
- **Endless** opens after Act 3, as before; its Start stays disabled.

Settled while building:
- **Sky Dive's landing warning lasts 1.2 s**, not 0.8. At 0.8 s a Lucian under the shadow couldn't walk out at base speed, against your note that early difficulty should stay gentle. The dragon is up about 3.6 s.
- **The Elder Dragon lands on its own timer**, so a lost warning can't leave it in the air for good.
- **Fire Breath** starts when Lucian is within 580 (the 550 cone plus his body), so a player at attack range can see it.
- **The pit (3-5) sends waves from the north, east and west only.** The plan's south spawn sat 450 px from Lucian's start.
- **The Scuttler's 45 blue** is raised by Essence Drops, like all blue.
- **Red Brambleback's hit is physical and its burn magic.**
- **The Scuttler** runs straight away from Lucian with no path; **Gromp** stands 0.4 s each time it spits.
- **A Blast Cone with no landing spot at least 250 away** pops but throws nobody. Shooting one counts as a basic attack for on-attack item stacks; a ripe cone stops a W missile or an R bullet.
- **A throw cut short** (death, Guardian Angel) lands Lucian at its end, never inside the wall he was flying over.
- **The jungle merchant** stands at the center clearing's south-west rim, out of 3-4's water.
- **Elder's Mark** vanishes if the dragon dies. **Sky Dive's push** drops Lucian's attack order, as Thresh's Flay does.
- **Waves in Act 3:** the plan's text said the waves hold 310k HP; its own wave table adds up to 275k, which is what is built (plus 35k for the drakes and the dragon). See *Pacing*.

## Verification

- **Unit and scene tests (GUT):** **1041 of 1041 pass**, up from 765 at the end of Phase 6.
  - New test files: `test_attack_move`, `test_stage_stats`, `test_stage_result`, `test_damage_over_time`, `test_status_effects`, `test_enemy_paths`, `test_monsters`, `test_terrain`, `test_drakes`, `test_elder_dragon`, `test_dark_lucian`, `test_act4`.
  - Extended: `test_stage_waves`, `test_game`, `test_journey`, `test_journey_section`, `test_kill_rewards`, `test_loot`, `test_stage_hud`, `test_enemy_data_files`, `test_maps`, `test_wave_runner`, `test_stage_debug_waves`, `test_minions`, `test_item_actives`, `test_summoner_spells`.
  - Tests that kill through real shots also check for engine errors: nothing adds a body or runs a physics query inside a damage path.
- **Screenshot runs in a real window:**
  - New scenarios: `attack_pick`, `act3_packs`, `act3_elites`, `act3_result`, `act3_jungle`, `act3_water`, `act3_pit`, `infernal_meteor`, `ocean_mist`, `elder_sky_dive`, `elder_mark`, `act4_lane`, `dark_lucian_q`, `dark_lucian_r`, `game_over`. Each prints its expected and actual values, and every check matched.
  - `act1_result`, `defeat` and `game_over` now let Lucian really shoot before the debug kills, so Damage dealt shows a real number (99, 339 and 192).
- <a id="visual-pass"></a>**Visual pass:** looking at every screenshot found seven problems. All are fixed; five have a test:
  - **The Tidal Wave was a round ball.** It is now a wave front 180 wide across its travel: a crest of foam bowing forward, blue water fading behind it, and a faint wake. Its hit is unchanged (within 90 of its middle). *(test)*
  - **Blast Cones read very small.** The art draws at 108 px (was 72), with a soft yellow glow that breathes while it is ripe. Its click radius went from 32 to 36, so a click on a leaf tip still picks it. *(test)*
  - **The dark lane was hard to read:** the shadow minions and Dark Lucian nearly vanished on the river, and the lane barely stood apart from the jungle. The lane, river, ripples, jungle edge and rocks are a step lighter (lane `#37313f`, river `#2a1f45`, ripples `#9467d0`, edge `#5e4285`, rocks `#4a4554`). The jungle and trees keep their near-black. Every color stays darker than Act 1's lane. *(test)*
  - **3-2's pit was crowded:** two lava pools sat beside the drake. They now sit at the back of the pit, behind it, so the floor in front stays open for the fight. *(test)*
  - **3-2 and 3-4's cards said "+ mini boss wave"**, but the drake comes last in the last wave, not in a wave of its own. They now read "4 waves + mini boss" and "5 waves + mini boss". *(test)*
  - **The end-screen shots showed "Damage dealt 0"**, because the harness killed with debug damage. The scenarios now shoot for real first.
  - **Harness framing:** the Dark Lucian scenarios had put Lucian inside a rock, and the drake scenarios spawned the drake 180 px behind where it really comes out. Both now match play.
- **Bugs found and fixed during the phase** (in the task reviews, or while building):
  - Guardian Angel's stasis mid-throw revived Lucian inside the wall he was flying over. *(test)*
  - A walker that jumped (a dash, Flash, a push, a throw) headed back to its old path corner. It now asks for a new path at once. *(test)*
  - The pit's south spawn sat on top of Lucian's start.
  - Sky Dive's landing couldn't be walked out of, and a lost warning could leave the dragon in the air. *(tests)*
  - Boss HP 51% missed a diving Elder Dragon (it is out of the enemies group then). *(test)*
- **Fixed in the final review:**
  - Ranged minions (Acts 1, 2 and 4) backing into a wall or a corner got stuck or twitched: their back-off took a path to a point inside the wall, and stepped past the path's end and back every frame. They and Gromp now back off straight away from Lucian, as the Scuttler flees: they slide along a wall and stand in a corner. A walker within a step of a path's end now stands there. *(tests)*
  - Smite or Gunblade aimed at a Blast Cone walked Lucian to it, then cast at nothing. It now looks for enemies only. *(test)*
  - Next stage after the very last stage now goes to the main screen. *(test)*

## Pacing

The target is still **at least 5–7 hours** for a skilled player's first pass through the story. Acts 3 and 4 have these budgets (from Phase 6):

| Act | Stages | Waves | Budget |
|---|---|---|---|
| 3 | 5 | 21 + the Elder Dragon's boss wave (the drakes come in the last waves) | 70–90 min |
| 4 | 3 | 14 + Dark Lucian's boss wave | 45–60 min |

How they are meant to hit it (estimates, not measurements):
- **Act 3:** the waves hold about **275k HP**, plus 35k for the two drakes and the dragon. Each stage starts at level 1. With Act 3's tree upgrades, Lucian's damage against a pack is about 80 a second at a stage's start and 200+ by its end: about 27–31 minutes of pure damage, or about 45 with walking and dodging. 21 breaks of about 30 s add about 10, and a third more for deaths and replays brings it to about **70–75 minutes**: the low end of the budget.
- **Act 4:** the waves hold about **313k HP**, plus 18k for Dark Lucian. At about 250–350 damage a second, that is 25–30 minutes of fighting; with breaks and replays, **45–60 minutes**.
- The plan's 75–90 minutes for Act 3 counted 310k HP in the waves, but its own wave table adds up to 275k. So Act 3 may land a little short. If it clears in under 60 minutes, raise `EnemyData.ACT_HP` (now 0.6) and the drakes' and dragon's HP before touching rewards (the Phase 6 rule).

**Measured play times: none yet.** The screenshot runs drive the stages by command, so their end screens read 0:12–0:20. Real timings come from the playtest checklist below: each end screen's Time, and the slot's play time. Both clocks skip paused time (shopping isn't in them).

## Screenshots

The stage info in some shots reads "Wave 1 in 16:38": those scenarios hold wave 1 back so the fight they show has the map to itself. In play the countdown is 5 s.

### A + Left-click

| | |
|---|---|
| ![Armed](phase7/attack_pick_0_armed.png) A pressed: the attack-range ring. Three minions are in range (100%, 40% and 70% HP); the cursor is on the fourth, beyond the ring (the cursor itself isn't captured) | ![Hovered](phase7/attack_pick_1_hovered.png) The click: Lucian walks past the nearer, weaker minions and shoots the hovered one (86% now); the others are untouched |
| ![Weakest](phase7/attack_pick_2_weakest.png) A + Left-click on open ground: he shoots the 40% minion (now 26%), not the nearer full one | |

### Act 3: the jungle

| | |
|---|---|
| ![Packs](phase7/act3_packs_0_camps.png) 3-1's first wave: the raptors come down from their camp at the top left, the wolves along the middle path from theirs, to Lucian at the crossing | ![Wrap](phase7/act3_packs_1_wrap.png) The raptors wrap round him; the wolves come in from his side |
| ![Buffs](phase7/act3_elites_0_buffs.png) Blue and Red down: both buffs in the HUD's buff row. Lucian's shots with Red burn and slow a big raptor (the icons over its bar) | ![Split](phase7/act3_elites_1_split.png) An Ancient Krug dies and two Krugs stand where it fell |
| ![Scuttler](phase7/act3_elites_2_scuttler.png) The Rift Scuttler runs from Lucian, up the river path | ![Escaped](phase7/act3_elites_3_escaped.png) 15 s later, stopped at the pit's far rim: "Escaped!", fading out |
| ![3-2](phase7/act3_jungle_0_map.png) 3-2's whole map: the paths and loops, the camps' clearings, the riverbed, 5 lava pools (two at the back of the pit) and 4 Blast Cones | ![Cone](phase7/act3_jungle_1_cone.png) A Blast Cone beside a loop's jungle, glowing while ripe, Lucian below it |
| ![Thrown](phase7/act3_jungle_2_thrown.png) He shoots it: thrown over the jungle, drawn bigger at the top of his arc | ![Landed](phase7/act3_jungle_3_landed.png) Landed on the low path, on walkable ground, near two more ripe cones |
| ![3-4](phase7/act3_water_0_map.png) 3-4's whole map: the riverbed full of shallow water and 4 Honeyfruit | ![Wading](phase7/act3_water_1_wading.png) Lucian in the water: the slow icon in his buff row, 251 move speed (25% off) |
| ![Honeyfruit](phase7/act3_water_2_honeyfruit.png) Hurt (210 / 600), beside a Honeyfruit | ![Eaten](phase7/act3_water_3_eaten.png) Walked over it: +137 HP (100 + 6%), the heal ring, the empty stalk behind him |
| ![Pit](phase7/act3_pit_0_map.png) 3-5, the Elder Dragon's pit: the round floor, its rock rim and 6 rocks | ![Pit start](phase7/act3_pit_1_start.png) Lucian at the pit's start |

### Act 3: the drakes and the Elder Dragon

| | |
|---|---|
| ![Meteors](phase7/infernal_meteor_0_warnings.png) The Infernal Drake where it comes out, mid-pit, the lava behind it. Meteor Fall: four circles, one on Lucian | ![Burning](phase7/infernal_meteor_1_burning.png) The meteors land; each circle burns. "Burning" in his buff row |
| ![Breath](phase7/infernal_meteor_2_breath.png) Fire Breath's cone warning | ![Fire](phase7/infernal_meteor_3_fire.png) The cone burns for 3 s |
| ![Wave warning](phase7/ocean_mist_0_wave_warning.png) The Ocean Drake: Tidal Wave's wide line on Lucian | ![Wave](phase7/ocean_mist_1_wave.png) The wave front rolls down the line (visual pass); it pushed him 300 and slowed him 30% |
| ![Mist](phase7/ocean_mist_2_channel.png) Soothing Mist: the mist ring, its arc filling; 60% → 72% HP so far | ![Interrupted](phase7/ocean_mist_3_interrupted.png) 9% of its HP in one hit: "Interrupted!", stars over its head |
| ![Up](phase7/elder_sky_dive_0_up.png) Sky Dive: the Elder Dragon is up, unseen; only its shadow shows, and the boss bar keeps it | ![Shadow](phase7/elder_sky_dive_1_shadow.png) Lucian walks; the shadow follows him |
| ![Landing](phase7/elder_sky_dive_2_landing.png) The shadow stops and the landing circle (r 260) fills for 1.2 s | ![Landed](phase7/elder_sky_dive_3_landed.png) Down: a hit and a push out of the circle; targetable again |
| ![Mark](phase7/elder_mark_0_ring.png) Elder's Mark: the sigil over Lucian and the ring emptying | ![Low](phase7/elder_mark_1_low.png) Under 25% HP: the ring turns red (the hit will be × 3) |
| ![Shielded](phase7/elder_mark_2_landed.png) A Barrier takes the tripled hit (390); his HP is kept | |

### Act 4

| | |
|---|---|
| ![Dark lane](phase7/act4_lane_0_map.png) 4-1's dark mid lane, whole: Act 1's layout in black and purple, after the visual pass | ![Wave](phase7/act4_lane_1_wave.png) Wave 1's shadow minions reach Lucian halfway up the lane |
| ![Q warning](phase7/dark_lucian_q_0_warning.png) Dark Lucian at the river: Piercing Light's line on Lucian | ![Laser](phase7/dark_lucian_q_1_laser.png) The dark laser: 133 after armor |
| ![Close](phase7/dark_lucian_q_2_close.png) Close up: black and violet, red eyes, two dark guns | ![R warning](phase7/dark_lucian_r_0_warning.png) The Culling's wide line; Lucian steps out of it |
| ![Stream](phase7/dark_lucian_r_1_stream.png) The bullets go down the fixed line while he strafes; none hit Lucian | ![Dash](phase7/dark_lucian_r_2_dash.png) 1100 damage in a burst: Relentless Pursuit takes him aside, half seen, a violet trail behind him, untargetable |

### The end screens

| | |
|---|---|
| ![3-2 cleared](phase7/act3_result_0.png) 3-2 cleared: 4 / 4 waves, 49 kills, real damage dealt and taken; +275 blue, +7 orange, +5 purple; "+5 purple essence (Infernal Drake, first kill)", "Stage 3-3 is open"; Retry · Next stage · Main screen | ![Act 1 cleared](phase7/act1_result_0.png) Act 1 cleared: the first-clear lines, "Act 2 is open", Next stage (to 2-1) |
| ![Fading](phase7/defeat_0_fading.png) 2-1: Lucian dies to minions, shooting back: grey and fading | ![Defeated](phase7/defeat_1_result.png) DEFEATED: 1 / 2 waves, the 30 blue kept; Retry · Main screen |
| ![Game over](phase7/game_over_0.png) Losing the tutorial: GAME OVER, only Back to title | ![Act 3 cards](phase7/main_acts_1_act3.png) Journey's Act 3 page: "4 waves + mini boss" on the drake stages, grey skulls for the drakes, red for the dragon |

## Known limits

- **Acts 5–6 and Endless still wait.** Clearing Act 4 says "Act 5 is open", and its tab opens with Start disabled ("Act 5 comes in a later phase"). Endless opens after Act 3 with its Start disabled.
- **Pacing isn't measured yet,** and Act 3 may land at the low end of its budget (see *Pacing*).
- **Blast Cones and item procs:** shooting a cone spends Lucian's charged on-attack effects (Energize, Spellblade, Essence Reaver's cooldown, Kraken Slayer's count) for nothing.
- **Big bodies can catch on corners.** The navigation mesh is baked for a 36 px body; the drakes (70) and the Elder Dragon (84) can snag on a jungle corner until their sidestep frees them.
- **A ranged minion or Gromp backed into a corner** stands there and shoots from too close.
- **Dark Lucian's dodge** waits out his Q, so a burst during the laser may not make him dodge.
- **Skip** gives the jungle buffs' regen for the time skipped, but doesn't shorten the buffs.
- **Red's true burn** gets Lucian's damage boosts (a design call; easy to change).
- **The radar shows no terrain**, by design: a jungle wall doesn't show on it.
- **Act 1's card** still reads "2 waves + boss wave" on replays (from Phase 6).
- **Tests:** every test passes, with notes:
  - GUT's 2 warnings are test scripts that leave a node or two unfreed (`test_lucian_skills`, `test_act4`).
  - Several Phase 7 tests wait on real time; on a slow machine they could be flaky.
  - Run alone, `test_status_effects` prints harmless ObjectDB leak lines at load.

## Manual playtest checklist (for you)

Your save and settings live in `%APPDATA%\lucian_the_lantern\`. F3 + Q opens the stage debug table (God mode, the Waves tab: skip, boss wave, spawn any enemy).

1. **A + Left-click** (any stage):
   - On an enemy out of range: Lucian chases it, around walls.
   - In a group, on open ground: he shoots the weakest in range.
   - With nothing in range: he walks to the nearest and shoots it.
   - After the kill: he stops.
2. **Clear 2-3:** the end screen shows the stats, the rewards and "Act 3 is open". **Next stage** starts 3-1.
3. **Play 3-1 … 3-5:**
   - Packs come out of their camps and walk the paths around the jungle.
   - The Blue and Red buffs show in the HUD's buff row; with Red, enemies you hit burn and slow.
   - The Scuttler escapes if you ignore it for 15 s ("Escaped!").
   - Big Krugs split in two.
   - 3-2: lava burns; shoot a Blast Cone standing near it and you fly over the jungle. 3-4: the water slows; Honeyfruit heals.
   - The drakes and the dragon use every skill. Sky Dive's circle can be walked out of.
   - A drake's purple is paid once (5), then 1.
4. **Play 4-1 … 4-3:** the dark lane and shadow minions; Dark Lucian dodges with E after a burst, lasers with Q, and strafes with R (step out of its line).
5. **Lose a stage:** DEFEATED. **Retry** restarts it; **Main screen** returns to that act. **Lose the tutorial** (a new game): GAME OVER with only Back to title.
6. **Pacing:** note each end screen's Time. Act 3's five stages should take 70–90 minutes in all, Act 4's three 45–60 (the slot list's play time shows the total). Add about 30 s per break: the clocks don't count shopping.

## Feedback and suggestions

- **Play Act 3 for time first.** Its waves hold a little less HP than the plan's estimate, so it may clear on the short side. If it takes under 60 minutes, raise `EnemyData.ACT_HP` and the drakes' and dragon's HP before touching rewards.
- **One flagged item** is worth a decision before Act 5: Blast Cones spending item procs. It is a small fix.
- **Act 5 (Shadow Isles)** is the natural next step. It can reuse the camps, packs, mini-boss kind, terrain zones and pathing built here.
- **Endless** opens after Act 3 and can reuse the wave runner, the six maps and every boss.
- **The numbers are placeholders:** enemy stats in `data/enemies/*.tres`, scaling in `EnemyData`, rewards in `KillRewards`, loot in `LootTable`, waves and packs in `WavePlan`, terrain in `HazardZone`, `BlastCone` and `Honeyfruit`, boss skills at the top of each boss script.
- **Sound and music** are still placeholders.
