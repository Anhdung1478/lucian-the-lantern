# Act 5 – Shadow Isles

> Part of the Lucian game design. Numbers are placeholders.

## Overview

| | |
|---|---|
| **Stages** | 5 |
| **Waves** | Stage 1: 5 · Stage 2: 5 · Stage 3: 6 · Stage 4: 6 · Stage 5: 6 + boss wave |
| **Map** | Shadow Isles: dead forest, Black Mist |
| **Mini bosses** | Maokai (stage 2), Elise (stage 4), appearing in the last wave |
| **Boss** | Karthus (stage 5) |

## Story

Lucian reaches the Shadow Isles and fights through its corrupted forest to find Thresh.

---

## Normal enemies

### Maokai's sapling
- **Attack:** runs at Lucian and explodes on contact in a small area, **AP** damage.

### Elise's spiderling
- **Attack:** fast melee, **AD** damage.

---

## Elites

### Maiden of the Mist
- Tanky melee ghost, **AD** damage.
- **Trait:** summons 2 small ghouls every few seconds until she is killed.

### Broodmother
- Giant spider.
- **Special normal attack:** ranged web spit, **AP** damage, slows Lucian.
- **Trait:** keeps spawning spiderlings until she is killed.

---

## Mini bosses

### Maokai (stage 2)
- **Normal attack:** melee, AD damage.

| Skill | Effect |
|---|---|
| **Twisted Advance** | Leaps to Lucian and roots him for 1 second. |
| **Nature's Grasp** | A wave of vines moves forward in a line and roots anything it hits. |

- **Purple essence:** 5 on first kill, 1 on repeat.

### Elise (stage 4)
- **Normal attack:** ranged, AP damage.

| Skill | Effect |
|---|---|
| **Cocoon** | A line skillshot that stuns Lucian. |
| **Rappel** | Rises out of reach, then drops onto Lucian's position. |

- **Purple essence:** 5 on first kill, 1 on repeat.

---

## Boss

### Karthus (stage 5)
No passive, no E.

- **Normal attack:** ranged, AP damage.

| Skill | Effect |
|---|---|
| **Lay Waste (Q)** | Many explosions on circles marked around Lucian. |
| **Wall of Pain (W)** | A long wall. Crossing it heavily slows Lucian. |
| **Requiem (R)** | Channels for 3 seconds, then deals huge damage to Lucian. Enough damage during the channel cancels it. |

- **Purple essence:** 10 on first kill, 2 on repeat.

## Waves

Enemies come in packs. Each wave lists how many of each. p is a sapling, s a spiderling, M a Maiden and B a Broodmother.

| Stage | Waves | Mini boss / boss |
|---|---|---|
| 5-1 | 8s 4p · 8s 6p · 8s 6p 1M · 10s 6p 1B · 10s 8p 1M | — |
| 5-2 | 8s 6p · 10s 6p 1M · 10s 6p 1B · 10s 8p 1M · 10s 8p 1M 1B | **Maokai** last in wave 5 |
| 5-3 | 10s 6p · 10s 6p 1M · 10s 8p 1B · 12s 8p 1M · 12s 8p 1B · 12s 8p 1M 1B | — |
| 5-4 | 10s 8p 1M · 10s 8p 1B · 12s 8p 1M · 12s 8p 2B · 12s 10p 1M 1B · 12s 10p 1M 1B | **Elise** last in wave 6 |
| 5-5 | 10s 8p 1M · 12s 8p 1B · 12s 10p 1M · 12s 10p 1M 1B · 14s 10p 2M · 14s 10p 1M 2B | boss wave: **Karthus** alone |

---

## Built in Phase 8

All numbers are placeholders. A mini boss's or boss's skill hit counts as a skill: Banshee's Veil blocks it, and so blocks the root, stun or slow that comes with it. Lucian's tenacity shortens root and stun; it doesn't shorten slows.

### Scaling
| | Act 5 |
|---|---|
| HP | × 3.4 |
| Damage | × 2.0 |
| Gold and XP | × 2.0 |
| Blue per kill | 5 (elites 25) |

Each wave after the first also adds **+15% HP and damage**. Mini bosses and the boss don't scale.

### Enemies
Base numbers (the data files). The last column shows wave 1 of Act 5, scaled.

| Enemy | Kind | HP | Armor / MR | Attack | Range | Every | Speed | Radius | Gold / XP | Act 5, wave 1 |
|---|---|---|---|---|---|---|---|---|---|---|
| Sapling | normal | 110 | 0 / 10 | **Bomber** (below), 30 magic | 80 | — | 340 | 22 | 30 / 15 | 374 HP, blast 60 |
| Spiderling | normal | 130 | 5 / 5 | Fast melee, 8 physical | 90 | 0.9 s | 380 | 20 | 25 / 12 | 442 HP, hits for 16 |
| Ghoul (a summon) | normal | 90 | 0 / 0 | Melee, 8 physical | 90 | 1.0 s | 320 | 20 | 20 / 10, paid at 25% | 306 HP, hits for 16 |
| Maiden of the Mist | elite | 1500 | 35 / 35 | Tanky melee, 40 physical. **Summons 2 ghouls every 7 s, at most 6 alive** | 130 | 1.5 s | 220 | 42 | 140 / 80 | 5100 HP, hits for 80 |
| Broodmother | elite | 1100 | 20 / 40 | **Web spit:** a bolt at 600 px/s, 30 magic, slows Lucian 30% for 1.5 s. Keeps 450–600 away. **Summons 1 spiderling every 3.5 s, at most 5 alive** | 600 | 2.0 s | 200 | 48 | 150 / 90 | 3740 HP, bolt 60 |

- **Sapling (Bomber):** it runs at Lucian. Within 80 (plus Lucian's 30 radius) it stops and marks a red circle (r 120) on its own spot for 0.6 s, then blasts everyone inside for 30 magic (× 2.0) and **vanishes**: no gold, no XP, no essence, no loot and no "Escaped!" note. Killed first, it pays like any normal enemy and its mark goes with it.
- **Spiderlings** come out of the **nest** from 5-3 (the `nest` camp). In 5-1 and 5-2 they come from the spawn points.
- **Summons** (the ghouls and the Broodmother's spiderlings):
  - The wave counts a summon the moment it is asked for and waits for it. When a summoner dies, its summons stay.
  - A summon pays **25%** of its gold and XP, and no blue, orange or loot (no farming).
  - It appears beside its summoner, spread round it. If that spot is in a wall, the abyss or off the map, it appears on the summoner instead.
  - A summoner's cap counts its summons that are alive or still coming.
  - **Maiden:** the first two ghouls come 7 s into her fight. **Broodmother:** the first spiderling comes after 3.5 s.
- **Web:** the slow shows in Lucian's buff row ("Slowed", 30%) and follows Phase 7's slow rule.

### The Black Mist
- Mist banks lie on the ground. A **normal or elite** enemy that is **inside a bank** and **more than 350 from Lucian** is **veiled**:
  - its art turns into a dark silhouette (the sprite color times (0.08, 0.09, 0.12)), its health bar hides, and the radar skips it;
  - it can still be targeted and hit (a click, A + Left-click, shots and skills all work), and it still counts for the wave;
  - its ground warnings always show.
- It shows again when Lucian comes within 350, or when it leaves the bank, and veils again when either changes back.
- **Bosses and mini bosses are never veiled.** The Maiden and the Broodmother are elites, so they are.
- The hit flash and the veil don't fight: the flash tweens the unit's visuals, the veil lives on the sprite.
- The banks are drawn under the units: three layered blobs of `#9fb8a8` at about 35% alpha, breathing slowly.

### Map: the dead forest (`DeadForestMap`, 5400 × 3400, all five stages)
- **Ground:** `#2a3330` with dead-grass flecks. A ragged wall of black trees (2 × 18 convex pieces, about 250 deep, ± 40) runs along the top and bottom.
- **Points:** Lucian starts at (500, 1700) in the west. The merchant stands at (2500, 1700), in a stone-ringed clearing. Spawn points: (1800, 420), (3400, 420), (1800, 2980) and (3400, 2980).
- **Twisted trees** are the cover (`wall_circles`, r 45–90): a fixed seeded list per stage. Each keeps 220 from every point (start, merchant, boss spot, spawn points, camps) and 160 from every other tree, so walkers don't get stuck.

| Stage | Trees | Mist banks | Camps | Boss spot |
|---|---|---|---|---|
| 5-1 | 14 | 2 | — | — |
| 5-2 | 16 | 3 | `maokai` (3900, 1700) | Maokai's ring of trunks |
| 5-3 | 18 | 3 | `nest` (5000, 900) | — |
| 5-4 | 18 | 4 | `elise` (3900, 1400), `nest` (5000, 2500) | — |
| 5-5 | 10, all west of x 3450 | 2 (far corners) | `nest` (5000, 900) | `boss_point` (4300, 1700): the graveyard |

- **Mist banks:** r 420–500. None covers the start, the merchant, the boss spot or a camp.
- **Maokai's trunks (5-2):** a ring of 6 trunks (r 85, ring radius 260) with a gap on the west side, where Lucian comes from.
- **Nest:** a white web disc with a dark hole.
- **The graveyard (5-5 only, x > 3600):** flagstones, 8 tombstones (40 × 70, two columns of four, 250–300 apart) and two slabs of a broken crypt wall behind Karthus, with a gap between them. They are real walls: they stop bolts and walkers.

### Maokai (`maokai`, mini boss, stage 5-2)
Last in wave 5, out of his camp. Melee, 90 physical, range 110, every 1.6 s. 12000 HP, armor 60, MR 40, speed 300, radius 54. Pays 300 gold, 50 blue, 3 orange and **5 purple the first time, 1 after**, on the kill.

| Skill | Numbers |
|---|---|
| **Twisted Advance** | Used when Lucian is within 700. A circle (r 90) marks where he will land, on walkable ground near Lucian, for 0.8 s. Then he leaps there in 0.4 s: **untargetable** in the air, drawn 1.35× bigger, off the radar. A Lucian inside the circle takes 130 magic and is **rooted 1.0 s**. Cooldown 10 s, first use 3 s into the fight. |
| **Nature's Grasp** | A red line (900 × 140) for 0.8 s, then a wave of vines (a 140-wide front) runs along it at 700 px/s. A hit: 110 magic and a **root of 1.25 s**. Trees and the trunk ring stop it. Cooldown 12 s, first use 2 s in. |

He stands 0.3 s after each skill.

### Elise (`elise`, mini boss, stage 5-4)
Last in wave 6, out of her camp. Ranged bolt, 70 magic (900 px/s), range 550, every 1.4 s. 13000 HP, armor 30, MR 50, speed 330, radius 44. Same rewards as Maokai.

| Skill | Numbers |
|---|---|
| **Cocoon** | A red line (950 × 60) for 0.7 s, then a web bolt at 1300 px/s. A hit: 100 magic and a **stun of 1.25 s**. Cooldown 11 s, first use 3 s in. |
| **Rappel** | Used at 85% HP or less. She rises and is **untargetable** for 1.9 s; her art and bar fade out in 0.3 s, and her name stays on the boss bar. A circle (r 180) follows Lucian for 1.0 s, then locks on a walkable spot. At 1.9 s she drops there for 160 magic. Cooldown 16 s. Lucian has 0.9 s after the lock to step out. |

### Karthus (`karthus`, boss, stage 5-5)
Boss wave. Ranged bolt, 80 magic (900 px/s), range 600, every 1.5 s. 20000 HP, armor 30, MR 60, speed 280, radius 46. Pays 300 gold, 100 blue, 5 orange and **10 purple the first time, 2 after**. No passive, no E.

| Skill | Numbers |
|---|---|
| **Lay Waste (Q)** | 5 circles (r 110): one on Lucian, four within 300 of him, laid 0.15 s apart. Each fills for 0.7 s and deals 110 magic. Reach 900. Cooldown 6 s, first use 2 s in. |
| **Wall of Pain (W)** | A red line (900 × 60) across the way between them for 0.6 s, then a spectral wall for 5 s. Touching or crossing it **slows Lucian 70% for 2.5 s**, once per cast (a dash or Flash across it counts). Cooldown 14 s, first use 5 s in. |
| **Requiem (R)** | At 75%, 45% and 15% HP, once each. He stands and channels for 3 s: a pulsing purple ring on Lucian, a filling ring round him, and a thin **break bar** under the boss bar. **8% of his max HP (1600)** of damage during the channel breaks it ("Broken!"). Otherwise Lucian takes **900 magic**. One Requiem per burst: thresholds his HP has already passed (in a burst, or by the break itself) are spent. |

### The waves
The letters are the ones above (p sapling, s spiderling, M Maiden, B Broodmother). HP is each wave's total after scaling, summons not counted.

| Stage | Waves | HP per wave | Total |
|---|---|---|---|
| 5-1 | 5 | 5.0k · 6.6k · 14.1k · 15.1k · 20.0k | 61k |
| 5-2 | 5 | 5.8k · 13.5k · 13.5k · 18.1k · 26.0k | 77k |
| 5-3 | 6 | 6.7k · 13.5k · 14.5k · 19.4k · 19.3k · 30.0k | 103k |
| 5-4 | 6 | 12.5k · 12.8k · 17.4k · 22.9k · 28.6k · 31.3k | 126k |
| 5-5 | 6 + Karthus | 12.5k · 13.8k · 18.4k · 25.9k · 32.2k · 39.4k | 142k |

The waves hold about **509k HP**, plus 45k for the three bosses.

### Art
Hand-written SVGs, as Phase 7's: the sapling (a walking dead tree with a glowing green core), the spiderling (a dark spider with bone-pale legs and a pale mark, so it shows on the forest floor), the ghoul, the Maiden (a veiled ghost woman in a teal shroud), the Broodmother (a huge spider with a bone-white carapace), Maokai (a treant, 116 px), Elise (a spider-queen in red and black, 96 px) and Karthus (a robed lich with a skull staff, 100 px).
