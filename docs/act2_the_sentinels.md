# Act 2 – The Sentinels

> Part of the Lucian game design. Numbers are placeholders.

## Overview

| | |
|---|---|
| **Stages** | 3 (short act) |
| **Waves** | Stage 1: 2 · Stage 2: 3 · Stage 3: 3 + boss wave |
| **Map** | Sentinels of Light training ground |
| **Teaches** | Target priority, dodging boss patterns |

## Waves (placeholder)

m = melee, r = ranged, S = siege, U = super minion.

| Stage | Waves | Boss wave |
|---|---|---|
| 1 | 6m 4r 1S · 6m 6r 1S 1U | — |
| 2 | 6m 6r 1S · 6m 6r 2S · 6m 6r 1S 1U | — |
| 3 | 6m 6r 2S · 6m 6r 1S 1U · 8m 6r 2S 1U | Akshan, alone |

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
Minions use the Act 1 numbers (`act1_the_loss.md`), scaled. Bosses don't scale.

| | Per act after the first | Act 2 |
|---|---|---|
| HP | × (1 + 0.6 · (act − 1)) | × 1.6 |
| Damage | × (1 + 0.25 · (act − 1)) | × 1.25 |
| Gold and XP | × (1 + 0.25 · (act − 1)) | × 1.25 |
| Blue per kill | = act number (elites 5×) | 2 (elites 10) |

Each wave after the first also adds **+15% HP and damage**. Act 2's melee minion at wave 1 has 384 HP and hits for 15.

### Super minion
| | Base (Act 1) | Act 2, wave 1 |
|---|---|---|
| HP | 1400 | 2240 |
| Armor / MR | 40 / 20 | 40 / 20 |
| Attack | 45 physical, melee, range 130, every 1.4 s | 56 |
| Speed | 260 | 260 |
| Gold / XP | 150 / 90 | 188 / 113 |

**Empower:** every 0.25 s, melee and ranged minions within 500 deal **+15% damage** for 0.5 s. A small icon (a red chevron over a fist) shows over their HP bars. Siege and super minions are never empowered.

### Akshan (`akshan`)
He enters from the top gate in stage 3's boss wave, alone.

| | |
|---|---|
| HP | 5000 |
| Armor / MR | 35 / 30 |
| Basic attack | A 28 physical bolt, range 550, every 1.4 s. Speed 320. |
| **Avengerang (Q)** | A line warning (900 long) for 0.8 s. Then the boomerang flies out 900 at 1000 px/s and comes back to him: 70 physical, at most once each way. Cooldown 8 s (first use after 2 s). |
| **Heroic Swing (E)** | When Lucian is within 800: a circle warning (r 300) on a point 150 from Lucian, toward Akshan, for 1.2 s. Then he swings once around it in 2.5 s, firing a gold bolt outward every 0.3 s (25 physical, reach 600). Cooldown 14 s (first use after 5 s). |
| **Comeuppance (R)** | Only once he is down to 75% HP. A thin lock line follows Lucian for 2.0 s, then 6 shots 0.12 s apart at him (40 physical each, reach 1200). Walls and pillars stop them. Cooldown 20 s. |
| Rewards | 300 gold, 100 blue, 5 orange, a fragment (15%: a legendary too), and 10 purple the first time, 2 on a replay |

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
