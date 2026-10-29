# Act 4 – The Darkness

> Part of the Lucian game design. Numbers are placeholders.

## Overview

| | |
|---|---|
| **Stages** | 3 (short act) |
| **Waves** | Stage 1: 4 · Stage 2: 5 · Stage 3: 5 + boss wave |
| **Map** | A dark version of the Act 1 mid lane, where Senna was taken |
| **Mini bosses** | None |
| **Boss** | Dark Lucian |

## Story

Before heading to the Shadow Isles, Lucian faces his own fear and grief. He has to beat himself to move on.

---

## Normal enemies

Shadow versions of the Act 1 minions (same behavior, dark recolored art):
- **Shadow melee minion:** melee, AD damage, medium HP, walks straight at Lucian.
- **Shadow ranged minion:** slow magic bolt, AP damage, low HP, keeps distance.

---

## Elites

### Shadow siege minion
Same as Act 1. **Special normal attack – Cannon Shell:** marks a circle, the shell lands after 1 second.

### Shadow super minion
Same as Act 2. **Trait – Empower:** nearby melee and ranged minions deal +15% damage.

---

## Boss

### Dark Lucian
A mirror of the player. He has **no Passive and no W**, and always uses his skills no matter what the player has unlocked.

- **Normal attack:** two-gun shots.

| Skill | Effect |
|---|---|
| **Piercing Light (Q)** | A laser in a line, with a line warning first. |
| **Relentless Pursuit (E)** | A dash, used to dodge Lucian's attacks or to chase him. |
| **The Culling (R)** | Fires a stream of bullets in one direction while moving. The player dodges sideways. |

- **Purple essence:** 10 on first kill, 2 on repeat.

---

## Built in Phase 7

### Scaling
| | Per act after the first | Act 4 |
|---|---|---|
| HP | × (1 + 0.6 · (act − 1)) | × 2.8 |
| Damage | × (1 + 0.25 · (act − 1)) | × 1.75 |
| Gold and XP | × (1 + 0.25 · (act − 1)) | × 1.75 |
| Blue per kill | = act number (elites 5×) | 4 (elites 20) |

Each wave after the first also adds **+15% HP and damage**. Dark Lucian doesn't scale.

### Shadow minions
Their own data files (`shadow_*_minion.tres`) with the Act 1–2 minions' numbers, behaviors and kinds; only the id, the name and the art change. Empower works on them as on the light ones.

| Enemy | Base HP | Armor / MR | Attack | Every | Speed | Act 4, wave 1 |
|---|---|---|---|---|---|---|
| Shadow melee minion | 240 | 10 / 0 | 12 physical, melee | 1.25 s | 240 | 672 HP, hits for 21 |
| Shadow ranged minion | 160 | 0 / 10 | An 18 magic bolt (450 px/s); keeps 420–550 away | 1.6 s | 240 | 448 HP, 31.5 a bolt |
| Shadow siege minion (elite) | 700 | 20 / 10 | Cannon Shell: a circle (r 110) on Lucian, 40 physical 1 s later; range 700 | 3.0 s | 220 | 1960 HP, 70 a shell |
| Shadow super minion (elite) | 1400 | 40 / 20 | 45 physical, melee; Empower within 500 | 1.4 s | 260 | 3920 HP, hits for 79 |

### Waves (`WavePlan`)
**m** melee, **r** ranged, **S** siege, **U** super. HP is the wave's total after scaling.

| Stage | Waves | Enemies | HP per wave | Boss |
|---|---|---|---|---|
| 4-1 | 8m 6r 1S · 8m 6r 2S · 8m 8r 1S 1U · 10m 8r 2S 1U | 15 · 16 · 18 · 21 | 10.0k · 13.8k · 19.3k · 26.3k | — |
| 4-2 | 8m 6r 2S · 8m 8r 1S 1U · 10m 8r 2S 1U · 10m 10r 2S 1U · 10m 10r 3S 1U | 16 · 18 · 21 · 23 · 24 | 12.0k · 17.1k · 23.6k · 27.6k · 33.6k | — |
| 4-3 | 8m 8r 1S 1U · 10m 8r 2S 1U · 10m 10r 2S 1U · 10m 10r 3S 1U · 12m 10r 2S 2U | 18 · 21 · 23 · 24 · 26 | 14.8k · 20.9k · 24.8k · 30.4k · 38.9k | Dark Lucian (boss wave) |

The waves hold about **313k HP**, plus 18k for Dark Lucian.

### Dark Lucian (`dark_lucian`, 4-3)
He rises from the river in the boss wave. He uses one skill at a time; while busy with one he neither walks nor attacks, and he stands 0.3 s after a skill's warning ends. All skill hits count as skills.

| | |
|---|---|
| HP | 18000 |
| Armor / MR | 45 / 45 |
| Basic attack | Two dark shots 0.15 s apart, one from each gun, 40 physical each (1400 px/s). Range 550, every 1.3 s. Walks at 330; radius 40. |
| **Piercing Light (Q)** | A line warning (1100 × 70) at Lucian for 0.7 s, then a dark violet laser along it: 170 physical. Cooldown 7 s, first after 3 s. |
| **Relentless Pursuit (E)** | A 400 px dash in 0.2 s, untargetable on the way: shots in flight miss, and he is half seen, with a violet trail. **Dodge:** sideways, once he has taken 6% of his max HP (1080) within 1.5 s. **Chase:** at Lucian, when Lucian is more than 750 away. Cooldown 6 s. |
| **The Culling (R)** | At or below 80% HP. A line warning (1200 × 120) at Lucian for 0.8 s. Then for 3 s he fires 24 bullets along that fixed line (±4° spread, 30 physical each, 1400 px/s, reach 1200) while he strafes sideways at 150 px/s. A step out of the line dodges them all. Cooldown 20 s. |
| Rewards | 300 gold, 100 blue, 5 orange, and 10 purple the first time, 2 on a replay |

Lucian keeps his attack order on him through the dash and shoots again once he is back.

### The dark mid lane (`DarkMidLaneMap`, all 3 stages)
Act 1's map (5200 × 3200) with the same layout and points: the diagonal lane, the river across it, 3 rocks, the start at the bottom left and the spawns at the top right. Dark Lucian rises from the river at Thresh's point.

| Part | Color |
|---|---|
| Lane | `#37313f` |
| Jungle, its edge | `#120f1a`, `#5e4285` |
| Trees | `#0c0a12` |
| River, its ripples | `#2a1f45`, `#9467d0` |
| Rocks | `#4a4554` |

The plan's palette (lane `#2a2633`, edge `#3b2a52`, river `#1d1630`, ripples `#7a4fb0`, rocks `#3a3742`) was a step lighter in the visual pass: the shadow minions and Dark Lucian were hard to see on it. It stays dark and purple; each color is still darker than Act 1's lane.

### Art
Hand-written SVGs: the four shadow minions (the minions in black-purple with violet glows) and Dark Lucian (Lucian's silhouette in black and violet, red eyes, two dark guns).
