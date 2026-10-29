# Act 6 – The Lantern

> Part of the Lucian game design. Numbers are placeholders.

## Overview

| | |
|---|---|
| **Stages** | 5 |
| **Waves** | Stage 1: 6 · Stage 2: 6 · Stage 3: 7 · Stage 4: 7 · Stage 5: 7 + boss wave |
| **Map** | Deep Shadow Isles, Thresh's domain |
| **Mini bosses** | Karthus – revived (stage 2), Hecarim (stage 4), appearing in the last wave |
| **Boss** | Thresh (stage 5) |

## Story

Lucian reaches Thresh for the final fight. When Thresh falls, Lucian shoots through the lantern and frees Senna.

---

## Normal enemies

### Mist Walker
- **Attack:** fast melee ghoul, **AD** damage.

### Lantern Soul
- **Attack:** ranged ghost, **AP** damage.
- Souls trapped by Thresh. When killed, they are **freed** instead of dying.

---

## Elites

### Spectral Rider
- **Special normal attack:** charges in a straight line. The player dodges sideways.

### Chain Warden
- **Special normal attack:** throws a chain (with a line warning) that pulls Lucian a short distance toward it.
- Practice for Thresh's hook.

---

## Mini bosses

### Karthus – revived (stage 2)
- **Normal attack:** ranged, AP damage.

| Skill | Effect |
|---|---|
| **Lay Waste (Q)** | Explosions on circles marked around Lucian. |
| **Defile (E)** | An aura that keeps damaging Lucian when he is close. |

- Unlike the Act 5 fight, the player must keep their distance to avoid Defile.
- **Purple essence:** 5 on first kill, 1 on repeat.

### Hecarim (stage 4)
- **Normal attack:** melee, AD damage.

| Skill | Effect |
|---|---|
| **Devastating Charge** | Speeds up, then charges into Lucian and knocks him back. |
| **Onslaught of Shadows** | Rides in a line with a group of spectral riders. Lucian is feared for 1 second if hit. |

- **Purple essence:** 5 on first kill, 1 on repeat.

---

## Boss

### Thresh (final)
- **Normal attack:** ranged chain whip, AD damage.
- **Phase change:** when Thresh's HP reaches 0 in Phase 1, he revives with **full HP** and starts Phase 2. In Phase 2 his appearance becomes **darker**.

**Phase 1 – Q, E, R**

| Skill | Effect |
|---|---|
| **Death Sentence (Q)** | Hook in a straight line with a line warning. Pulls Lucian in on hit. |
| **Flay (E)** | Pushes Lucian back in a cone in front of Thresh. |
| **The Box (R)** | Walls appear in a ring around Thresh. Crossing a wall slows Lucian heavily and damages him. |

**Phase 2 – Q, W, R**

| Skill | Effect |
|---|---|
| **Death Sentence (Q)** | Same hook, but if Lucian dodges it, Thresh **immediately casts it again**. |
| **Dark Passage (W)** | Throws his lantern to a spot; **3 Lantern Souls** come out of it. |
| **The Box (R)** | Same walls, but **deals more damage**. |

- **Ending:** when Thresh reaches 0 HP in Phase 2, Lucian shoots through the lantern and frees Senna.
- **Purple essence:** 20 on first kill, 4 on repeat.

## Waves

Enemies come in packs. Each wave lists how many of each. w is a mist walker, l a lantern soul, R a rider and C a warden.

| Stage | Waves | Mini boss / boss |
|---|---|---|
| 6-1 | 8w 4l · 8w 6l · 8w 6l 1R · 10w 6l 1C · 10w 8l 1R · 10w 8l 1R 1C | — |
| 6-2 | 8w 6l · 10w 6l 1R · 10w 6l 1C · 10w 8l 1R · 12w 8l 1C · 12w 8l 1R 1C | **Karthus, revived** last in wave 6 |
| 6-3 | 10w 6l · 10w 8l 1R · 10w 8l 1C · 12w 8l 1R · 12w 8l 2C · 12w 10l 1R 1C · 14w 10l 2R 1C | — |
| 6-4 | 10w 8l 1R · 10w 8l 1C · 12w 8l 1R 1C · 12w 10l 2R · 12w 10l 2C · 14w 10l 1R 1C · 14w 10l 2R 1C | **Hecarim** last in wave 7 |
| 6-5 | 10w 8l 1R · 12w 8l 1C · 12w 10l 1R 1C · 14w 10l 2R · 14w 10l 2C · 14w 12l 1R 1C · 16w 12l 2R 2C | boss wave: **Thresh** alone |

---

## Built in Phase 8

All numbers are placeholders. A mini boss's or boss's skill hit counts as a skill: Banshee's Veil blocks it, and with it the root, fear, pull or slow that comes with it. The elites' own hits (the rider's charge, the warden's chain) are basic hits, so the Veil doesn't block them. Lucian's tenacity shortens root, stun and fear; it doesn't shorten slows.

### Scaling
| | Act 6 |
|---|---|
| HP | × 4.0 |
| Damage | × 2.25 |
| Gold and XP | × 2.25 |
| Blue per kill | 6 (elites 30) |

Each wave after the first also adds **+15% HP and damage**. Mini bosses and the boss don't scale.

### Enemies
Base numbers (the data files). The last column shows wave 1 of Act 6, scaled.

| Enemy | Kind | HP | Armor / MR | Attack | Range | Every | Speed | Radius | Gold / XP | Act 6, wave 1 |
|---|---|---|---|---|---|---|---|---|---|---|
| Mist Walker | normal | 220 | 10 / 10 | Fast ghoul melee, 14 physical | 100 | 0.9 s | 360 | 26 | 55 / 28 | 880 HP, hits for 31 |
| Lantern Soul | normal | 150 | 0 / 20 | A bolt at 500 px/s, 22 magic. Keeps 420–550 away. **Freed** on death | 550 | 1.6 s | 280 | 24 | 45 / 25 | 600 HP, bolt 49 |
| Spectral Rider | elite | 1300 | 40 / 20 | **Charge** (below), 60 physical | 800 | 4.0 s | 280 | 42 | 140 / 80 | 5200 HP, charge 135 |
| Chain Warden | elite | 1200 | 35 / 35 | **Chain** (below), 45 physical. Keeps 500–700 away | 700 | 3.5 s | 220 | 40 | 150 / 90 | 4800 HP, chain 101 |

- **Lantern Soul:** killed, it is **freed** and pays like any kill. It rises and brightens into teal-white light, then fades upward with a soft chime (0.9 s), in place of the grey fade.
- **Spectral Rider:** it walks in until Lucian is within 800 (and keeps 250 away while the charge cools down). When the charge is ready it locks a red line (800 × 90) toward him and stands 0.8 s. Then it charges along the line at 1400 px/s. A hit is 60 physical (× 2.25) and a **push of 150** along the charge, at 1600 px/s. It hits at most once per charge. A wall or the abyss stops it. Step sideways to dodge. A perched rider never charges (it only faces him).
- **Chain Warden:** when the chain is ready and Lucian is within 700, it marks a red line (700 × 60) for 0.8 s, then throws a chain at 1200 px/s. A hit is 45 physical (× 2.25) and a **pull of 300** toward the warden at 1600 px/s. The pull stops in front of the warden (it never pulls him past it) and at the abyss edge: it can't drag him into the abyss. Practice for Thresh's hook.
- **Perched wardens:** a warden spawns on a free **ledge**, the one **nearest Lucian**, and never moves. It turns to face him. With no free ledge (6-5 has none) it spawns at the spawn points and walks, keeping 500–700 away.
- **Summons** work as in Act 5 (`act5_shadow_isles.md`): Thresh's souls count for the wave at once, pay 25% gold and XP, and give no essences or loot.

### Map: Thresh's domain (`ThreshDomainMap`, 5600 × 3400)
The abyss is several polygons (none has a hole) on the `CHASM` physics layer. It stops walking, dashes, Flash, pulls and enemy bodies, and paths go around it. It doesn't stop bolts, chains or Lucian's shots. The abyss is near-black with slow green swirls and chains hanging across it.

**Stages 1–4: three plateaus over the abyss** (dark slate, faint green cracks, corners cut by 150).

| Plateau | x | y | Holds |
|---|---|---|---|
| West | 200–1700 | 950–2450 | Lucian's start (450, 1700) |
| Center | 2300–3300 | 800–2600 | the merchant (2800, 1700) |
| East | 3900–5450 | 900–2500 | the boss spot (4700, 1700) and the east spawn points (5250, 1250) and (5250, 2150) |

- **Gaps** are 600 wide. Flash (400) can't cross one.
- **Bridges** (stone causeways with soul lanterns along both edges) run 60 px onto each plateau: north-west (1700 → 2300, y 1250), south-west (y 2150), north-east (3300 → 3900, y 1200) and south-east (y 2200).
- **Rock spikes** (11, r 55–65; 3 on the west plateau, 4 on each other) are cover. Each keeps 150 from every point and its radius + 100 from the abyss. The east plateau's middle band (y 1500–1900) stays clear for Hecarim's ride.
- **Spawn points:** the two east ones, and the east end of each whole bridge, 60 px out on it: (2240, 1250), (2240, 2150), (3840, 1200), (3840, 2200). Enemies spread ± 50 from them, with a body margin of 45.
- **Ledges** (islands of r 120 in the abyss, each 260 off its plateau's edge, so a warden on one is within Lucian's range from the edge): center north (2800, 540) and center south (2800, 2860), and from 6-3 east north (4700, 640) and east south (4700, 2760). **For physics a ledge is abyss:** nothing walks, dashes or blinks onto it.
- **Camps:** `karthus_revived` (4700, 1700) in 6-2, with a broken altar; `hecarim` (5200, 1700) in 6-4, with hoofprints running in from the edge.

| Stage | Bridges | Ledges | Spawn points | Boss spot |
|---|---|---|---|---|
| 6-1 | 4 × 280 | 2 | 6 | — |
| 6-2 | 4 × 280 | 2 | 6 | camp `karthus_revived` |
| 6-3 | 3 × 200; the north-west one is broken (100 px stubs, a 400 gap) | 4 | 5 | — |
| 6-4 | as 6-3 | 4 | 5 | camp `hecarim` |
| 6-5 | the platform | 0 | 3 | `boss_point` (2800, 1700): Thresh |

**Stage 5: the final platform.**
- A carved stone disc (r 1400) at (2800, 1700) in the abyss, with no walls, rocks or ledges. It has a rim band, carved rings, a rune ring of 32 glowing runes (r 1150), 16 chains rising at the rim, and a **pale dais** at its heart so Thresh reads against it.
- Four bridge stubs (280 wide, broken ends) at north, east, south and west. Lucian starts at the west rim (1650, 1700). Enemies spawn from the **north, east and south stubs only** (2800, 150), (4590, 1700), (2800, 3250); the west stub is behind Lucian's start.
- The merchant stands at (2800, 1950) in the breaks.

### Karthus, revived (`karthus_revived`, mini boss, stage 6-2)
Last in wave 6, at his altar. Ranged bolt, 85 magic (900 px/s), range 600, every 1.5 s. 16000 HP, armor 30, MR 60, speed 250, radius 46. The art is Karthus's with a pale teal tint. Pays as Maokai does (300 gold, 50 blue, 3 orange, 5 purple the first time, 1 after).

| Skill | Numbers |
|---|---|
| **Lay Waste (Q)** | As in Act 5, but **4** circles of 120 magic. Cooldown 6 s, first use 2 s in. |
| **Defile (E)** | An aura of r 350, always on and drawn as a purple ring (`#a45bd6`) with a faint fill: a burn zone on him that deals **80 magic a second**, ticking every 0.5 s, to Lucian inside it. It moves with him and goes when he dies. |

He walks at Lucian (250 px/s) and keeps firing while he walks. He stops at 280, inside his own ring, so Lucian (range 500) has to kite him. No Wall of Pain, no Requiem.

### Hecarim (`hecarim`, mini boss, stage 6-4)
Last in wave 7, from the east end. Melee, 100 physical, range 110, every 1.3 s. 18000 HP, armor 50, MR 40, speed 360, radius 56. Same rewards as Karthus, revived.

| Skill | Numbers |
|---|---|
| **Devastating Charge** | Used only from 300 or more away, so it can be seen. His speed is × 1.8 for 2.5 s, with a glowing teal trail, chasing Lucian. On contact, once per cast: 170 physical and a **300 knockback** (1200 px/s) when the hit lands. Cooldown 13 s, first use 3 s in. |
| **Onslaught of Shadows** | At 80% HP or less. A red band (1100 × 300) for 1.0 s, then he rides along it at 1600 px/s with **four ghost riders** (the rider art at 55% alpha) beside him. Lucian inside the band, at most Hecarim's radius ahead of him along the ride, is hit once: 150 magic and a **fear of 1.0 s**. A wall that stops the ride short means no hit. Cooldown 18 s, first use 2 s in; never during a Charge. |

### Thresh, final (`thresh_final`, boss, stage 6-5)
Boss wave. Chain whip bolt, 85 physical (900 px/s), range 450, every 1.6 s. 16000 HP **per phase**, armor 45, MR 45, speed 320, radius 48. `thresh.svg`. He is Act 1's Thresh with his skill numbers as variables.

**Phase 1 (Q, E, R).**

| Skill | Numbers |
|---|---|
| **Death Sentence (Q)** | Act 1's hook: a red line, then a hook that pulls Lucian in. 160 magic, a 0.8 s warning, cooldown 8 s, first use 2 s in. |
| **Flay (E)** | 120 magic and a push of 300, cooldown 7 s, first use 4 s in. |
| **The Box (R)** | Used when Lucian is within 450. A ring warning (r 450, a band 60 wide) for 1.0 s, then a ring of **12 wall pieces** for 4 s. A piece Lucian touches or crosses (a dash or Flash too) breaks, and he takes **150 magic and an 80% slow for 2 s**. Cooldown 22 s, first use 6 s in. |

**The rise.** At 0 HP in Phase 1 he doesn't die. For **2.5 s** he takes no damage and thinks of nothing; his warnings, wall pieces, hooks and lanterns are cleared; he gets **full HP**, a darker tint (× (0.5, 0.56, 0.54)) and a green aura (`#4dff9a`) that swells to 1.6× and settles. The boss bar reads "Thresh   Phase 2".

**Phase 2 (Q, W, R)**, first uses 1, 3 and 6 s after the rise.

| Skill | Numbers |
|---|---|
| **Death Sentence (Q)** | As above, but a hook that **misses** (reaches its range or a wall without touching Lucian) is thrown again at once, **once**, with a 0.45 s warning, aimed where Lucian is now. A hook that landed, or that Banshee's Veil blocked, is not a miss. |
| **Dark Passage (W)** | Throws his lantern to a spot within 250 of Lucian (a circle warning r 100, 0.6 s; the spot has room for the circle). The lantern lies there 6 s and **3 Lantern Souls** come out at once, 60 px round it. Used within 1000. Cooldown 16 s. **Only while fewer than 6 of his souls are alive.** |
| **The Box (R)** | As in Phase 1, but **220 magic**, cooldown 18 s. |

**The fall.** At 0 HP in Phase 2 he never dies in the usual way: the fight clears every warning and shot, every summoned Lantern Soul **vanishes** (freed, no pay), and the ending cutscene plays. His blue (100) and orange (5) are paid where he stood, with the line "Senna is free". Clearing 6-5 pays **20 purple the first time, 4 after**.

### The ending
**`SennaFreed`** (a cutscene, skippable with its Skip button; every wait ends when skipped):
1. The camera pans to Thresh. He sinks to one knee in 0.9 s (squashed, darker). The lantern drops 50 px and glows (0.5 s).
2. Pan to the lantern. Lucian: "It ends here."
3. One bright shot flies from Lucian to the lantern (0.5 s). A flash, a ring burst and a crack; the lantern dims.
4. 12 soul motes rise (160 px over 1.4 s). Senna's soul forms beside the lantern (`senna.svg` with a teal glow, 1.2 s) while Thresh dissolves into green smoke (1.4 s; his aura and boss bar fade with him).
5. Senna: "Lucian… you came." Lucian: "Always."
6. A fade to white (1.5 s), and the stage-end screen comes up as the white drops away.

**After the cutscene:** STAGE CLEARED with the first-clear lines (+20 purple, "Senna is free", "The story is complete"). The stage-ending moment drops no loot. On the **first clear only**, the button chosen on the stage-end screen leads to **`TheEndScreen`** first (`ui_design.md`), then where the button said: Main screen opens the main screen on Act 6, Retry starts 6-5 again. A replay of 6-5 has the cutscene (skippable), +4 purple, and goes straight where the button said.

### The waves
The letters are the ones above (w mist walker, l lantern soul, R rider, C warden). HP is each wave's total after scaling, summons not counted.

| Stage | Waves | HP per wave | Total |
|---|---|---|---|
| 6-1 | 6 | 9.4k · 12.2k · 20.6k · 24.9k · 30.1k · 41.3k | 139k |
| 6-2 | 6 | 10.6k · 20.2k · 22.4k · 27.3k · 32.3k · 44.4k | 157k |
| 6-3 | 7 | 12.4k · 21.6k · 23.9k · 29.8k · 39.9k · 46.5k · 63.7k | 238k |
| 6-4 | 7 | 18.8k · 21.2k · 33.0k · 39.1k · 41.9k · 49.6k · 63.7k | 267k |
| 6-5 | 7 + Thresh | 18.8k · 23.2k · 34.5k · 41.6k · 44.7k · 51.7k · 78.4k | 293k |

The waves hold about **1,094k HP**, plus 66k for the two mini bosses and Thresh (two phases).

### Art
Hand-written SVGs: the Mist Walker (a lean grey ghoul trailing mist), the Lantern Soul (a teal-green wisp with a sad face), the Spectral Rider (a ghost knight on a spectral horse), the Chain Warden (a hooded jailer with a chain and a hook), and Hecarim (a spectral centaur with a lance and green-blue flame, 136 × 112). Karthus, revived reuses Karthus's art, tinted; Thresh reuses Act 1's.
