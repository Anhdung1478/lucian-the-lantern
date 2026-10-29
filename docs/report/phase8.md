# Phase 8 report: Acts 5 and 6, and the ending

**Date:** 2026-10-30 · **Branch:** `main` (commits from `c1cb75c` to this report, not pushed) · **Plan:** `docs/implementation/phase8.md`

## Summary

Your Phase 8 request was: "Design map and enemies for act 5, 6 and implement." It is built and checked:
- **Act 5, Shadow Isles:** a dead forest with the Black Mist, exploding saplings, spiderlings, the Maiden of the Mist and the Broodmother (both summon), the mini bosses **Maokai** and **Elise**, and the boss **Karthus**.
- **Act 6, The Lantern:** Thresh's domain (plateaus and bridges over an abyss, Chain Warden ledges, a round final platform), Mist Walkers, Lantern Souls, Spectral Riders and Chain Wardens, the mini bosses **Karthus, revived** and **Hecarim**, and the final boss **Thresh** in two phases.
- **The ending:** a cutscene in which Lucian shoots through the lantern and frees Senna, then the stage-end screen, then (on the first clear only) a **The End** screen with the story time.

**Acts 1–6 now play: all 22 stages.** Only Endless waits.

Under that, the game gained:
- root, stun and fear on Lucian (tenacity shortens them), with icons and a red word under his health bar;
- summons that the wave waits for, enemies that vanish with no rewards, souls that are freed;
- leaps, charges, ring warnings and lasting spectral walls;
- an abyss that blocks walking, dashes, Flash and pulls, but not shots;
- the Black Mist, which hides enemies;
- a break bar and a phase text on the boss bar;
- two debug buttons ("Boss HP 5%", "Jump to the last wave").

The test suite grew from **1041 to 1330 tests**, and all of them pass. Every new fight, map and screen was checked in screenshots from a real game window, and the visual pass fixed four things (see *Verification*).

Your choices during planning:

| Topic | Your choice |
|---|---|
| Phase 7 (Acts 3–4) | **Self-contained:** Phase 8 builds only the shared pieces Phase 7 lacked, and reuses what Phase 7 built. |
| Black Mist (Act 5) | **It hides enemies.** Normal and elite enemies inside a mist bank, more than 350 px from Lucian, are dark silhouettes with no health bar and no radar dot. They can still be hit. Bosses and mini bosses are never hidden. |
| Ending | **A cutscene, then an end screen.** The cutscene when Thresh falls in Phase 2, then the stage-end screen, then on the first clear only a "The End" screen with the slot's play time and short credits. Replays get the cutscene (skippable) and the stage-end screen. |

## What you asked for → what was built

| # | Request | Built |
|---|---|---|
| 1 | Design the map and enemies of Act 5 and build them | **Act 5, Shadow Isles** (5 stages): a 5400 × 3400 dead forest with 10–18 twisted trees, Black Mist banks, a spider nest, and for 5-5 a ruined graveyard. Saplings, spiderlings, the Maiden of the Mist (summons ghouls), the Broodmother (web spit, summons spiderlings). **Maokai** ends 5-2, **Elise** 5-4, **Karthus** is 5-5's boss. Full numbers in `act5_shadow_isles.md`. |
| 2 | Design the map and enemies of Act 6 and build them | **Act 6, The Lantern** (5 stages): a 5600 × 3400 domain of three plateaus over an abyss, bridges that narrow and break, 2–4 ledges for Chain Wardens, and a round final platform. Mist Walkers, Lantern Souls (freed on death), Spectral Riders (charge), Chain Wardens (chain and pull). **Karthus, revived** ends 6-2, **Hecarim** 6-4, **Thresh** is 6-5's boss, in two phases. Full numbers in `act6_the_lantern.md`. |
| 3 | The ending (from the design) | **`SennaFreed`**, the cutscene; the stage-end screen with "Senna is free" and "The story is complete"; **`TheEndScreen`** with the story time and credits. |

### Under the request

| Part | Built |
|---|---|
| Crowd control on Lucian | `CrowdControl` (root, stun, fear) through `Lucian.add_cc`. Root: no walking, E, Flash or item dashes (attacks, Q, W, R and other items work). Stun and fear: he can't act; fear also runs him away at 60% speed. Tenacity shortens them; slows aren't shortened. Banshee's Veil blocks a skill's CC with its damage. Shown as "Rooted", "Stunned", "Feared" in the buff row (three new icons) and as a red word under his health bar. |
| Summons | Maiden (2 ghouls every 7 s, 6 alive), Broodmother (1 spiderling every 3.5 s, 5 alive), Thresh's Dark Passage (3 souls, no more than 6 alive). Counted by the wave at once; they stay if the summoner dies; they pay 25% gold and XP, and no essences or loot. |
| Vanish and freed | `vanish()`: leave with no rewards and no note (the exploding sapling, Thresh's souls at his fall). Lantern Souls that die rise and fade as light with a chime. |
| Leaps and charges | `leap_to` (untargetable in the air; Maokai), `charge` (stopped by walls and the abyss; riders, Hecarim's Onslaught). |
| Warnings and walls | Ring warnings, `EnemyProjectile.missed`, `SpectralWall` (a line or a ring of pieces; a dash across a piece is caught; Wall of Pain, The Box). |
| The abyss | A new physics layer, `CHASM`: stops Lucian's walk, dash, Flash and pulls, and enemy bodies; paths go around it; bolts, chains and shots cross it. Ledges are abyss for physics; perched wardens stand there and never move. |
| The Black Mist | Banks lie on the map; `BlackMist` veils enemies by the rule above; the radar skips them. |
| Boss bar | A break bar under it while a boss channels what damage breaks (Karthus's Requiem; Ocean Drake's mist reports through it too) and the phase text ("Thresh   Phase 2"). |
| Debug | "Boss HP 5%" (Thresh's phase change and fall) and "Jump to the last wave". |
| Art | 16 new SVGs: 5 Act 5 enemies, Maokai, Elise, Karthus, 4 Act 6 enemies, Hecarim, and the three debuff icons. The map art is drawn in code. |

### The bosses

| Boss | Where | HP | Skills |
|---|---|---|---|
| Maokai (mini boss) | Last in 5-2's last wave | 12000 | Twisted Advance (a leap onto a marked circle: 130 magic, root 1.0 s), Nature's Grasp (a vine wave: 110 magic, root 1.25 s) |
| Elise (mini boss) | Last in 5-4's last wave | 13000 | Cocoon (a web bolt: 100 magic, stun 1.25 s), Rappel (she rises, unseen, then drops on a locked circle: 160 magic) |
| Karthus | 5-5's boss wave | 20000 | Lay Waste (5 circles), Wall of Pain (a wall that slows 70%), Requiem (3 s channel at 75/45/15% HP; 8% of his HP in damage breaks it; else 900 magic) |
| Karthus, revived (mini boss) | Last in 6-2's last wave | 16000 | Lay Waste (4 circles), Defile (a purple 350 aura: 80 magic a second; he walks at Lucian) |
| Hecarim (mini boss) | Last in 6-4's last wave | 18000 | Devastating Charge (× 1.8 speed, 170 and a 300 knockback), Onslaught of Shadows (a 300-wide ride with four ghost riders: 150 magic and a 1.0 s fear) |
| Thresh | 6-5's boss wave | 16000 per phase | Phase 1: Death Sentence, Flay, The Box (12 pieces, 150 magic and an 80% slow per piece). Rise. Phase 2 (darker): Death Sentence thrown again once if it misses, Dark Passage (3 Lantern Souls), The Box (220) |

The mini bosses give 5 purple the first time and 1 after; Karthus 10 and 2; Thresh 20 and 4.

## Choices made where the request was open

Settled during planning (placeholders, easy to change):
- **Mini bosses, slows and untargetable are Phase 7's;** Phase 8 reuses them. Maokai, Elise, Karthus revived and Hecarim are the last entry of their stage's last wave and pay their purple on the kill.
- **Boss HP is raised** so Acts 5–6 top Act 4's Dark Lucian (18000): Karthus 20000, Karthus revived 16000, Hecarim 18000, Thresh 16000 per phase. Maokai (12000) and Elise (13000) stay over the drakes'.
- **Rappel locks at 1.0 s and Elise drops at 1.9 s,** not 1.6 s: the shorter drop left 0.6 s to leave a 180 circle, too tight for your early-difficulty note.
- **Fairness rules:** every root, stun or fear comes from a warning of 0.7 s or more (or a bolt or wave you can see), and lasts 1.5 s at most.
- **The last screen is `TheEndScreen`,** because Phase 7's docs already call `StageResult` "the end screen". It shows after the stage-end screen on the first clear of 6-5, whichever button was pressed, then goes where that button said. ESC does nothing on it.
- **Requiem** is used at 75%, 45% and 15% HP, once each.
- **The abyss has no holes:** it is several polygons. Ledges are drawn islands inside it that nothing can walk or blink onto.

Settled while building (rulings that change what you see):
- **A root stops item dashes** (Galeforce, Rocketbelt) too, not just E and Flash: a root an item dash escapes isn't a root.
- **One Requiem per crossing:** if a burst passes several thresholds, or a break leaves his HP past the next one, the skipped thresholds are spent. Two 900-magic Requiems back to back would break the fairness rule.
- **Wardens take the ledge nearest Lucian,** so the east ledges in 6-3 and 6-4 are used and the fight moves with you.
- **6-5 spawns from three stubs** (north, east, south), not the west one behind Lucian's start.
- **Dark Passage stops at 6 souls alive:** an uncapped 3 souls every 16 s could swamp a slow player.
- **Banshee's Veil doesn't block the elites' charge and chain** (basic hits), but does block every mini boss and boss skill, with their CC.
- **Hecarim's charge starts only from 300 or more away,** so you can see it coming, and his knockback lands only with its hit.
- **A sapling that explodes pays nothing;** killed first, it pays in full.
- **Flash can cross an abyss strip narrower than its range,** since it can't land on the abyss.
- **First-use delays** (Maokai 3 s and 2 s, Cocoon 3 s, Thresh's Box 6 s, Phase 2's skills 1, 3 and 6 s after the rise) are mine: the plan gave none, and gentle starts fit your note.
- **Look changes from the visual pass:** the spiderling is a dark spider with pale legs and a pale mark, and 6-5's heart is a pale dais rather than a dark pit. Both were needed to read on their ground.

## Verification

- **Unit and scene tests (GUT):** **1330 of 1330 pass**, up from 1041 at the end of Phase 7.
  - New test files: `test_crowd_control`, `test_lucian_cc`, `test_enemy_blocks`, `test_spectral_wall`, `test_black_mist`, `test_act5_enemies`, `test_maokai`, `test_elise`, `test_karthus`, `test_act6_enemies`, `test_hecarim`, `test_thresh_final`, `test_ending`.
  - Extended: `test_maps`, `test_wave_runner`, `test_kill_rewards`, `test_enemy_data_files`, `test_journey`, `test_journey_section`, `test_stage_waves`, `test_game`, `test_stage_debug_waves`.
  - Tests that kill through real shots also check for engine errors: nothing adds a body or runs a physics query inside a damage path.
  - The Task 1 and Task 10 implementers mutation-checked the tests for the CC gates and the Thresh states.
- **Screenshot runs in a real window:** 17 scenarios, 52 PNGs. Each prints its expected and actual values, and every check matched; no script or engine errors.
  - Mist silhouettes and their reveal, the sapling's ring, the web slow, the vine wave and the root word, Cocoon and the stun word, Rappel, Wall of Pain, Lay Waste, the Requiem and its break bar, the ledges and the chain, the rider's line and charge, Defile, Onslaught and the fear, The Box, Thresh's rise and darker Phase 2, Dark Passage, the cutscene and `TheEndScreen`.
- <a id="visual-pass"></a>**Visual pass:** looking at every screenshot found four problems. All are fixed, each with a test:
  - **The CC word was a dark smudge** under Lucian's bar. It is 18 px (was 14) with a thick black outline.
  - **Thresh was a dark smudge on 6-5's dark heart.** The heart is a pale dais, and the tests pin Thresh's contrast against it in both phases.
  - **Spiderlings were nearly invisible on the forest floor.** They have bone-pale legs and a pale mark.
  - **Thresh's aura and boss bar stayed** over the kneeling Thresh in the ending. They fade with him now.
  - Harness framing fixes (not game bugs): bosses now face Lucian, Maokai's and Elise's scenarios no longer stand Lucian on a tree or under Elise's drop, and a free camera clamps as play clamps it and ignores the mouse, so a shared machine can't move it.
- **Bugs found and fixed during the phase** (in the task reviews):
  - An item dash escaped a root. *(test)*
  - Karthus's Requiems could chain on a burst. *(tests)*
  - Some Chain Warden ledges were never used; the 6-5 west stub could spawn enemies behind Lucian's start.
  - The Chain Warden's hook was clipped by its art canvas; its pull could carry Lucian past the warden.
  - A debug-spawned Thresh could sit at 0 HP for good.
- **The final whole-branch review follows this report;** its fixes are added to `docs/implementation/phase8.md`.

## Pacing

The target is still **at least 5–7 hours** for a skilled player's first pass through the story. Acts 5 and 6 have these budgets (from the plan):

| Act | Stages | Waves | Budget |
|---|---|---|---|
| 5 | 5 | 28 + Karthus's boss wave (the mini bosses come in the last waves) | 80–100 min |
| 6 | 5 | 33 + Thresh's boss wave | 90–120 min |

How they are meant to hit it (estimates, not measurements):
- **Act 5:** the waves hold about **509k HP**, plus 45k for Maokai, Elise and Karthus (summons not counted). At about 250–350 damage a second that is 26–37 minutes of pure damage; with walking and dodging about 45, 28 breaks of about 30 s add about 14, and a third more for deaths and replays brings it to about **75–90 minutes**: the low end of the budget.
- **Act 6:** the waves hold about **1,094k HP**, plus 66k for the two mini bosses and Thresh's two phases. That is 55–75 minutes of pure damage, and about 85–110 with walking, dodging, 33 breaks and the bosses' phases; with a third more for deaths and replays, **100–130 minutes**: the top of the budget, and the hardest stages are the last two.
- Together the two acts add up to roughly 3 to 3.5 hours, on top of Acts 1–4. If Act 5 clears in under 70 minutes, raise `EnemyData.ACT_HP` (now 0.6) and the bosses' HP before touching rewards (the Phase 6 rule).

**Measured play times: none yet.** The screenshot runs drive the stages by command and jump to the last wave, so their end screens read 0:12–0:20, and the ending shot's "Waves 1 / 8" and 6:23:41 story time are set by the harness. They mean nothing for real play. Real timings come from the playtest checklist below: each end screen's Time, and the slot's play time (which `TheEndScreen` shows at the end). Both clocks skip paused time (shopping isn't in them).

## Screenshots

The stage info in some shots reads "Wave 1 in 16:38": those scenarios hold wave 1 back so the fight they show has the map to itself. In play the countdown is 5 s.

### Act 5: the Black Mist and its enemies

| | |
|---|---|
| ![Map](phase8/act5_mist_0_map.png) 5-1's whole forest: tree lines, twisted trees, the two pale mist banks, the merchant's stone ring | ![Veiled](phase8/act5_mist_1_veiled.png) A Maiden and two spiderlings in the bank, 800 off: black silhouettes with no bars and no radar dots. A spiderling outside the bank shows as any enemy does |
| ![Revealed](phase8/act5_mist_2_revealed.png) Lucian walks up: the two within 350 show (the teal Maiden, the pale-legged spider); the far one stays black | ![Sapling](phase8/act5_sapling_0_warning.png) A sapling has run in: the red circle (r 120) is on its own spot, and Lucian is walking out |
| ![Dodged](phase8/act5_sapling_1_dodged.png) It blasts nobody and is gone; Lucian unhurt (600) | ![Web](phase8/act5_brood_0_slowed.png) The Broodmother's web: Lucian slowed, speed 235, the slow icon in his buff row, a spiderling summoned beside her |
| ![Tooltip](phase8/act5_brood_1_tooltip.png) The icon hovered: "Slowed · −30% move speed" | |

### Act 5: Maokai and Elise

| | |
|---|---|
| ![Grasp line](phase8/maokai_grasp_0_warning.png) Maokai in his trunk ring, Lucian west through the gap: Nature's Grasp's line (900 × 140) | ![Vines](phase8/maokai_grasp_1_vines.png) The vine wave, a green crescent, mid-flight |
| ![Rooted](phase8/maokai_grasp_2_rooted.png) "Rooted" under Lucian's bar and the root icon in his buff row | ![Advance](phase8/maokai_grasp_3_advance.png) Twisted Advance: the landing circle (r 90) on Lucian |
| ![Leap](phase8/maokai_grasp_4_leap.png) Maokai in the air, 1.35× bigger, off the radar | ![Stunned](phase8/elise_rappel_0_stunned.png) Cocoon lands: "Stunned" and the stun icon |
| ![Up](phase8/elise_rappel_1_up.png) Rappel: Elise is gone, her name stays on the boss bar, and the circle follows Lucian | ![Dropped](phase8/elise_rappel_2_dropped.png) Locked, he steps out; she drops on the empty circle |

### Act 5: Karthus

| | |
|---|---|
| ![Wall line](phase8/karthus_wall_0_warning.png) Wall of Pain's line across the way | ![Wall](phase8/karthus_wall_1_wall.png) The spectral wall, pale slabs |
| ![Slowed](phase8/karthus_wall_2_slowed.png) Lucian walked through it: the slow icon, speed 101 | ![Lay Waste](phase8/karthus_wall_3_lay_waste.png) Lay Waste's five circles round him |
| ![Requiem](phase8/karthus_requiem_0_channel.png) Requiem: a purple ring on Lucian, a filling ring round Karthus, and the yellow break bar under the boss bar (686 / 1600 so far) | ![Broken](phase8/karthus_requiem_1_broken.png) A big hit: "Broken!" over him, the break bar gone |

### Act 6: the domain, the enemies and the mini bosses

| | |
|---|---|
| ![6-3 map](phase8/act6_bridges_0_map.png) 6-3's whole map: three plateaus over the abyss, three bridges and the broken one, four ledges, chains | ![Ledge](phase8/act6_bridges_1_ledge.png) The center plateau's north edge, Lucian on it, an empty ledge 260 px out in the abyss |
| ![Broken bridge](phase8/act6_bridges_2_broken.png) The broken north-west bridge: two stubs and a gap with fallen blocks | ![Chain line](phase8/act6_bridges_3_chain_line.png) A Chain Warden on the ledge: its chain's line (700 × 60) on Lucian |
| ![Pulled](phase8/act6_bridges_4_pulled.png) The chain landed (79 after armor): Lucian is pulled 270 and stops at the plateau's edge, not in the abyss | ![Platform](phase8/act6_platform_0_map.png) 6-5's whole map: the round platform, its rune ring, the pale dais, four stubs and the chains at the rim |
| ![Start](phase8/act6_platform_1_start.png) Lucian at the west rim | ![Rider line](phase8/act6_rider_0_line.png) A Spectral Rider's charge line (800 × 90) on Lucian |
| ![Rider charge](phase8/act6_rider_1_charge.png) He stepped aside; the rider ran past, and his HP is unchanged | ![Defile](phase8/karthus_defile_0_ring.png) The revived Karthus on his altar: Defile's purple ring (r 350), Lucian outside |
| ![Burning](phase8/karthus_defile_1_burning.png) Lucian inside: the burn icon and 80 a second | ![Defile Lay Waste](phase8/karthus_defile_2_lay_waste.png) The revived Karthus's four circles |
| ![Onslaught line](phase8/hecarim_onslaught_0_warning.png) Hecarim at 70%: Onslaught's band (1100 × 300) | ![Ride](phase8/hecarim_onslaught_1_ride.png) The ride, four ghost riders beside him |
| ![Feared](phase8/hecarim_onslaught_2_feared.png) Lucian hit at the band's edge: "Feared" and the fear icon, clear of Hecarim | ![Charge](phase8/hecarim_onslaught_3_charge.png) Devastating Charge: the teal trail behind him |

### Act 6: Thresh and the ending

| | |
|---|---|
| ![Box ring](phase8/thresh_box_0_warning.png) The Box's ring warning (r 450, band 60) | ![Box](phase8/thresh_box_1_box.png) Twelve pale wall pieces round Thresh |
| ![Box broken](phase8/thresh_box_2_broken.png) Lucian walked out through one piece: it broke, he took 115 and is slowed | ![Phase 1](phase8/thresh_phase2_0_phase1.png) "Thresh   Phase 1", Thresh on the pale dais |
| ![Rising](phase8/thresh_phase2_1_rising.png) At 0 HP the rise: full HP, the aura swelling, "Phase 2" | ![Risen](phase8/thresh_phase2_2_risen.png) Risen: darker, with a green aura |
| ![Re-hook](phase8/thresh_phase2_3_rehook.png) A dodged hook comes again, behind a 0.45 s line | ![Passage](phase8/thresh_lantern_0_warning.png) Dark Passage's circle near Lucian |
| ![Souls](phase8/thresh_lantern_1_souls.png) The lantern on the ground and three Lantern Souls round it | ![Cutscene 1](phase8/ending_cutscene_0_lantern.png) The ending: Thresh on one knee, the lantern dropped. "It ends here." |
| ![Shot](phase8/ending_cutscene_1_shot.png) One bright shot flies to the lantern | ![Freed](phase8/ending_cutscene_2_freed.png) The flash and ring; the lantern cracks and the souls rise |
| ![Senna](phase8/ending_cutscene_3_senna.png) Senna forms beside the lantern as Thresh dissolves: "Lucian… you came." | ![Result](phase8/ending_cutscene_4_result.png) STAGE CLEARED: +20 purple, "Senna is free", "The story is complete" |
| ![The End](phase8/the_end_0.png) **THE END**: the lantern, "Senna is free.", the story time (6:23:41 here, set by the harness), the credits, Continue | |

## Known limits

- **Two gameplay problems the visual pass found, not fixed** (they need a ruling and are queued for the final review's fix wave):
  - **A feared Lucian is carried along Hecarim's Onslaught.** The fear runs him away from Hecarim, along the ride, and his own walk keeps pushing him out of Hecarim's overlapping body, so he is shoved at ride speed until the ride ends (about 490 px in one shot). The abyss and walls still stop him. A charge through a walking Lucian does the same.
  - **The Box can hit twice at a joint.** Crossing within Lucian's hit radius (30) of a joint between two pieces touches both: two hits (150 or 220 magic each) and both pieces break. With 12 pieces about a quarter of straight crossings are near a joint.
- **Onslaught still hits a Lucian who steps into the band behind Hecarim** mid-ride, with no cue after the warning fired (from Task 9's review). It is a fairness question for the final review.
- **Pacing isn't measured yet,** and Act 5 may land at the low end of its budget (see *Pacing*). The estimates leave out summons' HP.
- **Placeholder numbers:** every number in `act5_shadow_isles.md` and `act6_the_lantern.md` is a placeholder, as are the first-use delays, `CHARGE_CLOSE` (250) and the push and pull speed (1600). The credits' first two lines ("Lucian: The Lantern", "Made with Godot 4") are placeholders.
- **Looked at and left:** the mist banks have hard edges (so the veil's reach is exact); the veiled silhouette hides identity and HP, not presence; the break bar is unlabeled; the sapling is small and muddy under its own red circle; Maokai's leap has no ground shadow.
- **Mini-detail fixes deferred** (the full list is in `phase8.md`, *Left as is*): Elise's art could stay at alpha 0 if she is killed out of band while up (not reachable in play); a debug Thresh's fall clears every warning on the stage; `TheEndScreen`'s time isn't live; some tests wait on real time.
- **Endless still waits.** It opens after Act 3, and its Start stays disabled.
- **Sound and music** are still placeholders; the freed chime is one more generated effect.
- **Tests:** every test passes, with notes:
  - GUT's 2 warnings are test scripts that leave a node or two unfreed (`test_act4`, `test_lucian_skills`).
  - Several Phase 8 tests wait on real time; on a slow machine they could be flaky.
  - The full suite takes about 9 minutes.

## Manual playtest checklist (for you)

Your save and settings live in `%APPDATA%\lucian_the_lantern\`. F3 + Q opens the stage debug table (God mode, the Waves tab: skip, boss wave, last wave, Boss HP 51% and 5%, spawn any enemy).

1. **Main debug → Acts cleared = 4 → Journey → Act 5 → Start 5-1.**
2. **5-1:** a sapling's warning, then dodge it. Enemies vanish into the mist and show up when you come within 350. Spiderlings from the nest from 5-3.
3. **5-2:** Maokai comes last in wave 5. His vine wave roots ("Rooted" shows, in the buff row and under the bar). His kill pays +5 purple.
4. **5-4:** Elise's Cocoon stuns, and Banshee's Veil blocks it. During Rappel she can't be hit; step out of the circle after it locks.
5. **5-5:** Wall of Pain slows. Break a Requiem (the yellow bar fills); let one land (900).
6. **Act 6:** a Chain Warden on a ledge pulls Lucian to the abyss edge, not into it. A rider's charge is dodged sideways. Flash can't land on a ledge.
7. **6-2 Defile:** kite Karthus out of the purple ring. **6-4 Onslaught:** a fear. Try standing behind Hecarim mid-ride (a known limit).
8. **6-5:** Thresh Phase 1, then the rise (you can't hurt him for 2.5 s), then the darker Phase 2. A dodged hook comes again once. Dark Passage's souls (no more than 6 at once). The Box: walk out through a piece, and try near a joint.
9. **The ending** (also try Skip): STAGE CLEARED, +20 purple, "Senna is free", "The story is complete" → Main screen → **The End** with the play time → the main screen on Act 6.
10. **Replay 6-5:** no The End, +4 purple.
11. **The save file:** after 6-5, `"bosses"` holds `maokai`, `elise`, `karthus`, `karthus_revived`, `hecarim` and `thresh_final`, and `"cleared"` holds `"6-5"`.
12. **Pacing:** note each end screen's Time. Act 5's five stages should take 80–100 minutes in all, Act 6's five 90–120 (the slot list's play time shows the total). Add about 30 s per break: the clocks don't count shopping.

## Feedback and suggestions

- **Play Act 5 for time first.** Its waves hold 509k HP, which may clear on the short side. If it takes under 70 minutes, raise `EnemyData.ACT_HP` and the bosses' HP before touching rewards.
- **Decide the two fairness items** in the final review: Hecarim's ride carrying a feared Lucian, and a Box joint hitting twice. Both are small fixes (don't let a fear run along the ride; let one crossing touch one piece).
- **Endless** is the natural next step. It can reuse the wave runner, all six maps, the bosses, and the summon, mist and abyss pieces.
- **The numbers are placeholders:** enemy stats in `data/enemies/*.tres`, scaling in `EnemyData`, rewards in `KillRewards`, loot in `LootTable`, waves in `WavePlan`, boss skills at the top of each boss script, the Act 6 map in `ThreshDomainMap`, the mist's range in `BlackMist.REVEAL_RANGE`.
- **Sound, music and the credits** are still placeholders.
