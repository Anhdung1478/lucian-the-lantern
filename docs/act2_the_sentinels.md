# Act 2 – The Sentinels

> Part of the Lucian game design. Numbers are placeholders.

## Overview

| | |
|---|---|
| **Stages** | 3 (short act) |
| **Waves** | Stage 1: 2 · Stage 2: 3 · Stage 3: 3 + boss wave *(V2.0: stage 1: 4 · stage 2: 5 · stage 3: 5 + boss wave)* |
| **Map** | Sentinels of Light training ground |
| **Teaches** | Target priority, dodging boss patterns |

## Waves (placeholder)

m = melee, r = ranged, S = siege, U = super minion.

| Stage | Waves | Boss wave |
|---|---|---|
| 1 | 6m 4r 1S · 6m 6r 1S 1U (the act's gentle stage: minions and elites have 20% less HP, V1.3) | — |
| 2 | 6m 6r 1S · 6m 6r 2S · 6m 6r 1S 1U (melee and ranged minions have 10% less HP, V1.5.0) | — |
| 3 | 6m 6r 2S · 6m 6r 1S 1U · 8m 6r 2S 1U | Akshan, alone |

**V2.0 waves** (before V2.0: the table above; `WavePlan.STAGES`). The same minion and elite rules apply to each stage as above.

| Stage | Waves | Boss wave |
|---|---|---|
| 1 | 6m 4r 1S · 6m 6r 1S · 6m 6r 1S 1U · 8m 6r 2S | — |
| 2 | 6m 6r 1S · 6m 6r 2S · 6m 6r 1S 1U · 8m 6r 2S · 8m 6r 2S 1U | — |
| 3 | 6m 6r 2S · 6m 6r 1S 1U · 8m 6r 2S 1U · 8m 8r 2S 1U · 10m 8r 2S 1U | Akshan, alone |

## Story

Lucian trains with Akshan, a fellow Sentinel of Light, to prove he's ready to go after Thresh and rescue Senna.

---

## Normal enemies

Same as Act 1:
- **Melee minion:** melee, AD damage, medium HP, walks straight at Lucian.
- **Ranged minion:** slow magic bolt, AP damage, low HP, keeps distance.

---

## Elites

### Siege minion
Same as Act 1. **Special normal attack – Cannon Shell:** marks a circle, the shell lands after 1 second.

### Super minion
- **HP:** very high, melee, AD damage
- **Trait – Empower:** nearby **melee and ranged minions** deal **+15% damage**. Does not affect other elites.
- **Teaches:** deciding whether to kill the elite first or clear the small minions.

---

## Boss

### Akshan (weakened)
Lower damage, slower attacks and longer warnings than a full-strength boss, since this is an early act.

- **Normal attack:** ranged, AD damage.

| Skill | Effect |
|---|---|
| **Avengerang (Q)** | Throws a boomerang that flies out and comes back. The player must dodge it twice. |
| **Heroic Swing (E)** | Throws his grapple to a point on the ground (no terrain needed), then swings in a circle around it while shooting outward. A circle warning shows the swing area. |
| **Comeuppance (R)** | Locks onto Lucian, charges for a short time, then fires a burst of shots. Lucian can dodge behind walls or move out of range during the charge. |

- **Purple essence:** 10 on first clear, 2 on repeat.

---

## Built in Phase 6

### Scaling
Minions use the Act 1 numbers (`act1_the_loss.md`), scaled. Bosses don't scale. *(V1.3 balance pass: the numbers here are the new ones; see `lucian_game_design.md` §17.)*

| | Per act after the first | Act 2 |
|---|---|---|
| HP | × (1 + 0.25 · (act − 1)) *(V2.0: 0.35)* | × 1.25 *(V2.0: × 1.35)* |
| Damage | × (1 + 0.15 · (act − 1)) | × 1.15 |
| Gold and XP | × (1 + 0.25 · (act − 1)) | × 1.25 |
| Blue per kill | = act number (elites 5×) | 2 (elites 10) |

Each wave after the first also adds **+10% HP and damage**. Act 2's melee minion at wave 1 has 300 HP and hits for 13.8 (in 2-1: 240 HP; in 2-2: 270 HP since V1.5.0, whose melee and ranged minions have 10% less HP). *(V2.0: 324 HP, 259 in 2-1 and 292 in 2-2; the damage is the same. The 10% a wave and the shares of 2-1 and 2-2 are unchanged.)*

**Wave health in V2.0** (the stage budget tool: the summed health of the waves, the largest wave, Lucian's level at the end, gold and XP of the stage).

| Stage | Waves | Sum of wave HP | Largest wave | Boss HP | XP | Level at the end | Gold |
|---|---|---|---|---|---|---|---|
| 2-1 | 4 | 18,202 | 6,009 | — | 2,150 | 7 | 4,125 |
| 2-2 | 5 | 32,368 | 9,718 | — | 3,037 | 9 | 5,812 |
| 2-3 | 5 | 42,103 | 11,774 | 7,500 | 3,612 | 10 | 6,862 |

Health of each wave, in thousands: 2-1 3.0 · 3.7 · 5.5 · 6.0; 2-2 3.9 · 5.3 · 6.5 · 7.0 · 9.7; 2-3 5.1 · 6.3 · 8.8 · 10.1 · 11.8. Act 2 pays 5,700 gold a stage on average, the boss's included. Lucian starts every Act 2 stage at **level 2**.

### Super minion
| | Base (Act 1) | Act 2, wave 1 |
|---|---|---|
| HP | 1150 *(1400 before V1.3)* | 1438 *(V2.0: 1553)* |
| Armor / MR | 40 / 20 | 40 / 20 |
| Attack | 36 physical *(45 before V1.3)*, melee, range 130, every 1.4 s | 41.4 |
| Speed | 260 | 260 |
| Gold / XP | 150 / 90 | 188 / 113 |

**Empower:** every 0.25 s, melee and ranged minions within 500 deal **+15% damage** for 0.5 s. A small icon (a red chevron over a fist) shows over their HP bars. Siege and super minions are never empowered.

### Akshan (`akshan`)
He enters from the top gate in stage 3's boss wave, alone.

| | |
|---|---|
| HP | 5000 *(V2.0: 7500)* |
| Armor / MR | 35 / 30 |
| Basic attack | A 28 physical bolt (1200 px/s), range 550, every 1.4 s. Walks at 320. |
| **Avengerang (Q)** | A line warning (900 long) for 0.8 s. Then the boomerang flies out 900 at 1000 px/s and comes back to him: 70 physical, at most once each way. Cooldown 8 s (first use after 2 s). |
| **Heroic Swing (E)** | When Lucian is within 800: a circle warning (r 300) on a point 150 from Lucian, toward Akshan, for 1.2 s. Then he swings once around it in 2.5 s, firing a gold bolt outward every 0.3 s (25 physical, reach 600). Cooldown 14 s (first use after 5 s). *(V1.3.1: he keeps to open ground: where the circle crosses a wall or a pillar, he slides along its edge.)* |
| **Comeuppance (R)** | Only once he is down to 75% HP. A thin lock line follows Lucian for 2.0 s, then 6 shots 0.12 s apart at him (40 physical each, reach 1200). Walls and pillars stop them. Cooldown 20 s. |
| Rewards | 300 gold, 100 blue, 5 orange, and 10 purple the first time, 2 on a replay. No item: his death ends the stage. |

- He uses one skill at a time; while busy with one he neither walks nor attacks.
- His skill hits count as skills, so Banshee's Veil blocks one.
- A defeat in the boss wave gives no purple.

### The training ground
| | |
|---|---|
| Size | 4600 × 2800 |
| Floor | Stone tiles |
| Gates | Left (150, 1400), top (2300, 150) and right (4450, 1400), drawn in gold |
| Dummies | 6 along the top and bottom walls. Decoration: they block movement but aren't enemies. |
| Lucian | Starts at (2300, 2550), near the bottom |
| Merchant | (1700, 2350), during breaks |

| Stage | Pillars (r 70) | Spawn gates |
|---|---|---|
| 2-1 | 6: two rows of three across the middle | Top, right |
| 2-2 | 8: the same 6, plus one in line with each side gate | Left, top, right |
| 2-3 | 10 in a ring (r 650) around the center | Left, top, right |

Minions take turns over the open gates, in groups of 3.

*(V2.0: the "stone tiles" are flagstones. A brass ring with the Sentinels' star lies on the floor, the walls are blocks with braziers, the gates have towers and the pillars are sandstone. The Training arena (Phase 3) is slate slabs under the lantern's teal light. Positions and counts are as above. Game design doc §13, "Built in V2.0".)*
