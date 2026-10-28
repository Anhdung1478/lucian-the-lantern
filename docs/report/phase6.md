# Phase 6 report: Acts 1 and 2, waves and enemies, the stage HUD, the title screen and the rest of the save system

**Date:** 2026-10-29 · **Branch:** `main` (commits from `be4b9d6` to this report, not pushed) · **Plan:** `docs/implementation/phase6.md`

## Summary

All 5 points on your Phase 6 list are built and checked:
- a wave counter at the top center of the stage, with the break timer and Skip
- a radar at the bottom right
- a title screen: Start new game, Load game, Settings, Exit game
- the rest of the save system: slots picked on the title screen, Leave to main menu, first-time boss purple, play time
- Acts 1 and 2: their maps, minions, Thresh and Akshan, and the whole stage loop

Under that, the game now fights back:
- Enemies hit Lucian, and he can die.
- Enemies die and pay out gold, XP and essences, and sometimes drop items on the ground.
- The 7 defensive items work.
- The Evolution Tree's economy nodes work.

The game is paced for a skilled player to need **at least 5–7 hours** for the story (see *Pacing*).

The test suite grew from **596 to 765 tests**, and all of them pass. Every new screen and fight was checked in screenshots from a real game window. That visual pass fixed eight things (see *Visual pass*).

Your choices during planning:
- **Defensive items:** all 7 work now.
- **Item drops:** loot on the ground, where the enemy died. Lucian walks over it to pick it up.
- **Thresh's cutscene:** in the engine and scripted: black bars, camera pans, captions, Skip.
- **New game:** straight into Act 1 (the tutorial, with tips), then the main screen.
- **Game length:** at least 5–7 hours for a skilled player. Each stage's time shows on its result panel, and each slot's play time shows in the slot lists.

## What you asked for → what was built

| # | Request | Built |
|---|---|---|
| 1 | The wave count UI, top center (`ui_design.md`) | One panel: the stage name, then "Wave 1 in 0:05" with **Skip** before a wave, or "Wave 1/2 · Enemies: 10" during one ("Boss wave" for the last). Under it, a **boss bar** with the boss's name and HP while a boss lives. Collected essences sit next to the stage gold, top right. "FPS N" moved to the top left. |
| 2 | The radar, bottom right | A dark 260 px panel shaped like the map. Lucian is a blue dot, an enemy a red dot (bigger for an elite), a boss a red skull, Senna a pale-blue dot, the merchant a gold dot. It never takes clicks. |
| 3 | A start screen: Start new game, Load game, Settings, Exit game | The **title screen** opens the game: Thresh's lantern, the title and the four buttons. Start new game and Load game show the 3 slots with their play time and save date. A used slot asks "Overwrite slot N? Its progress will be lost." A new game is written at once, then Act 1 starts. Load game is disabled until a slot exists. Exit and the window's X quit at once. |
| 4 | The parts of the save system not done yet | Slots picked on the title screen. **Leave to main menu** works ("Save before leaving?", then the title). The save gains `"bosses"` (first-time purple paid) and `"play_time"`. `"version"` stays 1, and older files still load. |
| 5 | The maps and enemies of Acts 1 and 2, built | **Act 1 – Mid lane:** melee, ranged and siege minions; Senna fights beside Lucian; Thresh's hook and Flay; the cutscene where he takes Senna. **Act 2 – Training ground:** three stages with 6, 8 and 10 pillars; super minions that Empower the small ones; Akshan with Avengerang, Heroic Swing and Comeuppance. Journey starts any open stage of Acts 1–2. |

### Under the five points

| Part | Built |
|---|---|
| Enemies | `Enemy` → `EnemyUnit` → `Minion` and `Boss` (`Thresh`, `Akshan`), built from `data/enemies/*.tres`. They walk at Lucian, slide along walls, sidestep when stuck, and attack only him. Their bolts stop at walls. Red ground warnings fill up before an attack lands. |
| Lucian takes damage | Armor and MR, then shields in a fixed order, then HP. Hits flash him red, with smaller numbers over him. Thresh's hook pulls and Flay pushes him. He dies at 0 HP: grey, a 1.5 s fade, then DEFEATED. |
| Defensive items | Banshee's Veil, Thornmail, Immortal Shieldbow, Death's Dance, Fimbulwinter's Everlasting, Guardian Angel, Kaenic Rookern. Numbers in `items.md`. |
| Rewards | Gold, XP and essences on every kill (Senna's too). Essences go into the save as they drop. Items drop on the ground. The tree's Stage Gold, Bonus XP and Essence Drops raise them. |
| Stage loop | A 5 s countdown, waves in groups of 3, 20 s breaks with the merchant, Skip with the regen of the time skipped, the boss wave, then the result panel with the stage time. Continue auto-saves and opens Journey on that act. |
| Debug | The stage debug table (F3 + Q) gains a Waves tab: Skip break, Kill all, Jump to boss wave, spawn each minion, Boss HP 51%, God mode. The main one gains Forget boss purple. |
| Art | 9 new SVGs: the four minions, Thresh, Akshan, Senna, the Empower status icon and the title lantern. |

### Enemy numbers (Act 1, wave 1)

Per act after the first: HP × (1 + 0.6 · (act − 1)), damage, gold and XP × (1 + 0.25 · (act − 1)). Each wave after the first: +15% HP and damage. Bosses don't scale.

| Enemy | HP | Armor / MR | Attack | Every | Gold / XP |
|---|---|---|---|---|---|
| Melee minion | 240 | 10 / 0 | 12 physical, melee | 1.25 s | 60 / 30 |
| Ranged minion | 160 | 0 / 10 | 18 magic bolt; keeps 420–550 away | 1.6 s | 45 / 25 |
| Siege minion (elite) | 700 | 20 / 10 | Cannon Shell: a circle (r 110) on Lucian, 40 physical 1 s later | 3.0 s | 120 / 60 |
| Super minion (elite) | 1400 | 40 / 20 | 45 physical, melee; Empower: nearby small minions +15% | 1.4 s | 150 / 90 |
| Thresh | 3000 (stops at half) | 30 / 30 | Hook (80 magic + pull), Flay (60 magic + push) | 9 s / 7 s | — |
| Akshan | 5000 | 35 / 30 | Avengerang (70 ×2), Heroic Swing (25 per bolt), Comeuppance (6 × 40) | 8 / 14 / 20 s | 300 / — |

The full tables are in `act1_the_loss.md` and `act2_the_sentinels.md`.

## Choices made where the request was open

Settled during planning (placeholders, easy to change):
- **Enemies attack only Lucian.** Senna can't be targeted, so she can't die before the cutscene.
- **Act 1's first play** is the tutorial: one gun, no skill ranks, no passive, no summoner spells (items, tree stats and the skin still apply), Senna, Thresh and six tips. **A replay** has the full kit, no Senna, no Thresh: it ends after wave 2, with no purple.
- **Stage flow:** "Wave 1 in 0:05", groups of 3 every 1.2 s, 20 s breaks, one more break before the boss wave. **Skip** gives the HP and mana regen of the time skipped; cooldowns and buffs don't move.
- **The result panel** pauses the game. ESC and P do nothing while it shows.
- **Essences** go into the save as they drop. Leaving, dying or a Yes to "Save before leaving?" keeps them; a No loses them.
- **Ground loot** stays until the stage ends. Lucian picks it up within 60 px. With a full backpack it stays and says "Backpack full", at most every 3 s.
- **Movement:** straight steering and sliding along walls, no navigation mesh.
- **Banshee's Veil** blocks a boss skill hit whole, the hook's pull included. The siege shell counts as a normal attack.
- **Shield order:** Magebane (magic only), Lifeline, Barrier, Everlasting, Ichorshield.
- **The title screen** writes a new game at once, so "Overwrite slot N?" means it. Its Exit and the window's X quit without asking (nothing there is unsaved).
- **Journey:** a click picks a stage card. The default is the first open stage not cleared yet. After a stage, Journey opens on the act just played; otherwise on the first act with a stage to clear, else Training.
- **Pacing numbers:** the scaling (+60% HP per act, +15% per wave) and the boss HP are set for the budget in *Pacing*.

Settled while building:
- **Forced movement** (the hook's pull, Flay's push), stasis and death end a dash in progress, as in LoL.
- **Thornmail** does nothing when its attacker is already gone.
- **The cutscene** runs on its own timers, so Skip stops everything at once and nothing moves afterwards. The black bars sit on screen (120 px each). Senna's soul flies to the lantern where the art has it, on Thresh's right.
- **The boss wave counts as cleared** after the cutscene, so Act 1 reads "Waves cleared: 3 / 3".
- **A death just before Thresh reaches half HP** gives DEFEATED, with no cutscene and no purple. (Thresh gives no repeat purple, so it would otherwise be lost for good.)
- **Tips** count down only while the game runs, and the panel shrinks to a shorter tip.
- **God mode** (debug) survives a cutscene.
- **After clearing Act 1, Journey opens on Act 1** (the act just played), with Act 2's tab open. The plan's checklist said Act 2; the plan's rule ("the act just played") won.
- **Thresh's blue and orange rise where he sank**, like a kill's; the purple rises over Lucian (visual pass).

## Verification

- **Unit and scene tests (GUT):** **765 of 765 pass**, up from 596 at the end of Phase 5.
  - New test files: `test_enemy_death`, `test_shields`, `test_lucian_damage`, `test_item_defense`, `test_ground_warning`, `test_enemy_data_files`, `test_minions`, `test_kill_rewards`, `test_loot`, `test_maps`, `test_wave_runner`, `test_stage_waves`, `test_stage_hud`, `test_act1`, `test_akshan`, `test_title_screen`, `test_stage_debug_waves`.
  - Extended: `test_skins`, `test_save_game`, `test_game`, `test_journey_section`, `test_main_screen`, `test_main_debug`, `test_stage_setup`.
- **Screenshot runs in a real window:**
  - New scenarios: `title`, `title_slots`, `act1_start`, `act1_wave`, `act1_shell`, `act1_break`, `act1_thresh`, `act1_cutscene`, `act1_result`, `act2_pillars`, `act2_super`, `akshan_e`, `akshan_r`, `defeat`, `loot`, `guardian_angel`. Each prints its expected and actual values, and every check matched.
  - The act scenarios build the stage for a Journey stage from a new save, so Act 1 is its first play. They drive it by command: Skip, the debug Kill all, a jump to the boss.
  - The Phase 5 `main_*`, `training_setup` and `skins_stage` scenarios had stopped running when the title screen came first. They run again (`main_gear` and `training_setup` rerun).
- <a id="visual-pass"></a>**Visual pass:** looking at every screenshot found eight problems. All are fixed; six have a test:
  - **The radar was off screen.** Only a sliver showed in the bottom-right corner: its size was set after it was anchored, so it grew past the corner. It now sits 12 px in from the corner. *(test)*
  - **Death lost its grey and Guardian Angel its gold.** A hit just before the last one left a red flash fading back to white, which painted over the tint. Lucian now greys out and fades, or turns gold, whatever hit him just before. *(2 tests)*
  - **The cutscene's hook flew off screen.** The camera framed only Thresh, so at "SENNA!" she wasn't in view, and Lucian sat under the bottom bar. The camera now frames Thresh and Senna for the hook, then follows her in to him. *(test)*
  - **The slot list's text touched its buttons' edges** once play time was added. The slot buttons are 520 px wide now (title screen and Save as copy). *(test)*
  - **"+100" blue and "+10" purple overlapped** over Lucian after a skipped cutscene. Thresh's blue and orange now rise where he sank. *(test)*
  - **Training's stage panel was twice as wide as "Training"**, keeping room for the hidden Skip button. It now always fits what it shows. *(test)*
  - **Grey bands at the map edges.** The camera sees a little past the act maps, and that band was empty. The mid lane's jungle now runs on past the edge, and the training ground has an outer wall.
  - **The title lantern's light rays ended in flat cuts.** They fade out now.
- **Bugs found and fixed:**
  - A pull, stasis or death left a dash running.
  - Thornmail could act on a shooter that was already gone, and the Death's Dance kill test couldn't fail.
  - An edit broke a line of `stage.tscn`.
  - Closing the window on STAGE CLEARED, then Yes, lost the clear. *(test)*
  - A shot that ended a wave added the merchant in the middle of a physics step (engine errors); so did a shot that brought Thresh to half HP. *(3 tests)*
  - Enemy bolts flew on through Lucian after a hit. *(2 tests)*
  - Lucian could gain HP while dead: a level up from Senna's kill, or life steal. *(test)*
  - The cutscene played on under "Save before leaving?". *(test)*
  - The mouse stayed confined to the window after a stage.
  - The kill that ends a stage dropped items nobody could pick up. It drops none now. *(2 tests)*

  Smaller issues left as they are are listed at the end of the plan (*Left as is*).

## Pacing

The target is **at least 5–7 hours** for a skilled player's first pass through the story. The budget per act, in minutes, counts a few deaths, shopping, and the replays needed to afford Evolution Tree nodes:

| Act | Stages | Waves (+ boss / mini boss waves) | Minutes |
|---|---|---|---|
| 1 | 1 | 2 + 1 | 8–10 (tutorial and cutscene) |
| 2 | 3 | 8 + 1 | 30–40 |
| 3 | 5 | 21 + 3 | 70–90 |
| 4 | 3 | 14 + 1 | 45–60 |
| 5 | 5 | 28 + 3 | 80–100 |
| 6 | 5 | 33 + 3 | 90–120 |
| **All** | 22 | 106 + 12 | **323–420 (5.4–7 h)** |

Rules of thumb: about 2 minutes of fighting per wave, 2–3 minutes per boss, about 30 s of shopping per break, and about a third of each act's time in deaths and replays.

How Acts 1 and 2 are meant to hit their share (estimates from the plan, not measurements):
- **Act 1:** waves of 2.1k and 3.4k minion HP against Lucian (~35 damage per second) and Senna (~27): about 1–1.5 minutes each. Thresh's 1,500 HP to the cutscene: about 1.5 minutes. With the countdown, a break, tips and the cutscene: about **8 minutes**. A skilled player will likely be quicker, about 5 minutes of play plus the cutscene, under the 8–10 minute budget. That is intended for the tutorial, and the total budget absorbs it.
- **Act 2:** waves of 4.4k to 11.8k HP, about 1.5–2.5 minutes each; Akshan about 3 minutes. A clean pass is about **27 minutes**; one or two defeats or a replay bring it to 30–40.
- **Economy:** Act 1 gives about 127 blue (Q rank 1); Act 2 about 450 on a first pass (W, the passive, and Q or E rank 2).

**Measured play times: none yet.** The screenshot runs drive the stages by command (Skip, Kill all, a jump to the boss), so their result panels read 0:10–0:11. Those say nothing about real play. Real timings come from the playtest checklist below: each result panel's time, and the slot's play time in the slot list. Both clocks skip paused time, so shopping (the shop pauses the game) isn't in them, while the budget counts about 30 s of shopping per break. If Act 2 clears in under 25 minutes, raise `EnemyData.ACT_HP` and the bosses' HP before changing rewards.

## Screenshots

### Title screen

| | |
|---|---|
| ![Title](phase6/title_0_menu.png) The title screen on a new game | ![Load disabled](phase6/title_1_load_disabled.png) Load game disabled: "No saved games yet" |
| ![New game slots](phase6/title_slots_0_new_game.png) Start new game with slot 2 saved: its play time and date | ![Overwrite](phase6/title_slots_1_overwrite.png) Slot 2 is used: "Overwrite slot 2? Its progress will be lost." |
| ![Load slots](phase6/title_slots_2_load.png) Load game: only slot 2 can be picked | |

### Act 1

| | |
|---|---|
| ![Start](phase6/act1_start_0.png) The first second: the move tip, Senna beside Lucian, "Wave 1 in 0:05", the radar | ![Wave 1](phase6/act1_wave_0.png) Wave 1 on the lane: "Wave 1/2 · Enemies: 10", red dots on the radar, hits over Lucian |
| ![Shell](phase6/act1_shell_0.png) A siege minion's shell circle on Lucian, and its tip | ![Break](phase6/act1_break_0.png) The break: "Wave 2 in 0:17" with Skip, the merchant and his tip |
| ![Thresh](phase6/act1_thresh_0.png) Thresh in the river: the boss bar, the hook's line toward Lucian, the skull on the radar | ![Caption](phase6/act1_cutscene_0_caption.png) The cutscene: Thresh, Senna and Lucian in view, the first caption |
| ![Hook](phase6/act1_cutscene_1_hook.png) The hook reaches Senna: "SENNA!" | ![Soul](phase6/act1_cutscene_2_soul.png) Senna has fallen; her soul rises toward his lantern |
| ![Lantern](phase6/act1_cutscene_3_lantern.png) The lantern glows: "Your light is mine now." | ![Cleared](phase6/act1_result_0.png) STAGE CLEARED: 3 / 3 waves, +127 blue, +6 orange, +10 purple, the E line, "Act 2 is open" (a commanded run, hence 0:11) |

### Act 2

| | |
|---|---|
| ![Pillars](phase6/act2_pillars_0_wave.png) Stage 2-3: wave 1 coming in from three gates, on the radar | ![Ring](phase6/act2_pillars_1_ring.png) Zoomed out: the ring of 10 pillars and the wave at the gates |
| ![Super](phase6/act2_super_0.png) A super minion (gold diamond on its bar) and the minions it Empowers; the far one isn't | ![Empower](phase6/act2_super_1_close.png) Close up: the Empower icon over each near minion |
| ![Swing warning](phase6/akshan_e_0_warning.png) Heroic Swing's circle warning, with Lucian inside | ![Swing](phase6/akshan_e_1_swing.png) Akshan swinging round it, a gold bolt flying outward |
| ![Lock](phase6/akshan_r_0_lock.png) Comeuppance's lock line on Lucian behind a pillar | ![Burst](phase6/akshan_r_1_burst.png) The burst's gold shots hit the pillar; Lucian keeps 600 / 600 |

### Anywhere

| | |
|---|---|
| ![Fading](phase6/defeat_0_fading.png) Lucian killed by minions: grey and fading | ![Defeated](phase6/defeat_1_result.png) DEFEATED: 1 / 2 waves, the 30 blue kept |
| ![Loot](phase6/loot_0_ground.png) A fragment (blue glow) and a legendary (gold glow) on the ground | ![Backpack full](phase6/loot_1_backpack_full.png) Walking onto the fragment with a full backpack: "Backpack full" |
| ![Stasis](phase6/guardian_angel_0_stasis.png) Guardian Angel: Lucian in gold stasis, its 300 s cooldown on the item | ![Revived](phase6/guardian_angel_1_revived.png) Back with half his base HP (300, less the minions' hits since) |

## Known limits

- **Acts 3–6 and Endless still wait.** Their tabs unlock as designed, but Start stays disabled ("Act 3 comes in a later phase"). Clearing Act 2 says "Act 3 is open", and its tab opens with nothing to play yet.
- **No navigation mesh.** Enemies walk straight at Lucian and slide along walls. They can snag on corners, jungle edges, rocks and pillars until their sidestep frees them.
- **Senna floats over walls.** She has no body, so she cuts across the jungle to keep up.
- **Akshan's Heroic Swing can pass through pillars and the map's edge**, since the swing moves him on a circle. It also keeps firing if Lucian dies mid-swing (his other skills stop).
- **Thresh's later fight is Act 6's.** Act 1's Thresh stops at half HP and never dies; his phase text on the boss bar waits for Act 6.
- **The top of the HUD can hide a boss.** The stage info, boss bar and Act 1 tips fill about the top 180 px of the screen's middle. A boss straight above Lucian sits under them; panning the free camera, or standing to his side, shows him.
- **Act 1's card always reads "2 waves + boss wave"**, though a replay has no boss.
- **After a skipped cutscene**, the hook tip can still be showing behind the result panel (tips also count down while the HUD is hidden).
- **Pacing isn't measured yet** (see *Pacing*).
- **Tests:** every test passes, with notes:
  - GUT's one warning is the older `test_lucian_skills`, which leaves 4 shot nodes behind (since Phase 5).
  - One early run had a failure in `test_cast_modes` / `test_game` that never came back.
  - No test uses GUT's deprecated `wait_frames` any more.

## Manual playtest checklist (for you)

Your save and settings live in `%APPDATA%\lucian_the_lantern\`. Delete `save_slot_*.json` there first.

1. Launch: the title screen. Load game is disabled.
2. **Start new game** → slot 1: Act 1 starts, with "RMB to move. Hold it to keep walking."
   - Senna follows and shoots.
   - Lucian fires one gun only and has no skills or summoner spells.
3. **Wave 1** (Skip, or wait 5 s):
   - "Wave 1/2" and "Enemies: 10" at the top center; red dots on the radar.
   - Melee minions walk up and hit (numbers over Lucian). Ranged minions keep away, and their bolts can be dodged.
   - Kills give gold, XP (level ups) and "+1" blue. Sometimes a fragment lies on the ground; walk over it.
4. **The break:**
   - "Wave 2 in 0:20" with Skip. The merchant is on the lane, with his tip.
   - Shopping pauses the timer. Skip starts wave 2, and HP jumps up by the regen skipped.
5. **Wave 2:** a siege minion's red circle. Step out of it.
6. **Thresh** rises from the river:
   - The boss bar shows.
   - His hook's line warning, then the pull. Flay's cone pushes.
   - At half HP, the cutscene: Space moves the captions on. Try Skip with a new game in another slot.
7. **STAGE CLEARED:** "+10 purple essence (first clear)", the E line and "Act 2 is open". Continue → the main screen on Act 1, with Act 2's tab open. E is free in the Evolution Tree.
8. **Act 2**, stages 1–3 in order:
   - Super minions Empower the small ones (an icon over their bars).
   - Akshan's boomerang can hit on the way out and on the way back. Heroic Swing shows a circle first.
   - Comeuppance's lock line: hide behind a pillar and the shots stop.
   - The first clear of 2-3 gives +10 purple; a replay gives +2.
9. **Die** (stand in the minions): DEFEATED. The essences are still there after Continue.
10. **Guardian Angel:** in a stage, F3 + Q → give gold and the item, equip it, then die: gold stasis, then a revive at half base HP.
11. **Gear → Leave to main menu → Yes** → the title. Load game → slot 1, with the same progress.
12. **Close the window** on the title: no question. During a stage: "Save before leaving?".
13. **Save file:** after Act 1, `save_slot_1.json` has `"cleared": ["1-1"]`, `"bosses": ["thresh_1"]` and a `"play_time"`.
14. **Pacing:** note each result panel's time. Act 1 may run under its 8–10 minutes (about 5 of play plus the cutscene, which is fine for the tutorial); Act 2's three stages should take 30–40 in all (the slot list's play time shows the total). Add about 30 s per break: the clocks skip paused time, so shopping isn't in them.

## Feedback and suggestions

- **Play Acts 1 and 2 for time first.** The pacing is the plan's estimate. Your result panel times and the slot's play time will show whether the numbers hold (add about 30 s per break: the clocks don't count shopping). If Act 2 goes much faster than 25 minutes, raise `EnemyData.ACT_HP` (now 0.6) and the bosses' HP before touching rewards.
- **Act 3 (The Jungle) is the natural next step.** Its narrow paths between walls will need better movement than straight steering: a navigation mesh or a flow field toward Lucian. Its mini bosses (the drakes) are the first stages with a grey skull.
- **Endless** opens after Act 3 and reuses the wave runner, the maps and the bosses.
- **The numbers are placeholders:** enemy stats in `data/enemies/*.tres`, scaling in `EnemyData`, rewards in `KillRewards`, loot in `LootTable`, waves in `WavePlan`.
- **Sound and music** are still placeholders (generated effects, no music).
