# Act 1 – The Loss (Tutorial)

> Part of the Lucian game design. Numbers are placeholders; base stats start from LoL minion values.

## Overview

| | |
|---|---|
| **Stages** | 1 |
| **Waves** | 2 waves + boss wave |
| **Map** | Mid lane (Summoner's Rift style, no turrets) |
| **Lucian** | Only **one gun**, auto attacks only (no skills yet) |
| **Teaches** | Moving, attacking, attack-move, dodging warnings |

## Story

Lucian and Senna fight minion waves together. Thresh appears and attacks. When Thresh reaches 50% HP, a cutscene plays: he kills Senna and traps her soul in his lantern. Lucian takes Senna's gun and learns **E (Relentless Pursuit)** from her.

**Rewards:** Senna's gun (second gun), **E rank 1** for free, first-time purple essence.

## Waves (placeholder)

| Wave | Enemies |
|---|---|
| 1 | 6 melee minions, 4 ranged minions |
| 2 | 6 melee minions, 6 ranged minions, 1 siege minion |
| Boss | Thresh |

---

## Normal enemies

### Melee minion
- **Attack:** melee, **AD** damage
- **HP:** medium
- **Behavior:** walks straight at Lucian

### Ranged minion
- **Attack:** slow magic bolt, **AP** damage
- **HP:** low
- **Behavior:** keeps distance from Lucian

Having one AD and one AP enemy teaches the player early that both Armor and MR matter.

---

## Elite

### Siege minion
- **HP:** high, slow movement
- **Special normal attack – Cannon Shell:** marks a circle on the ground, then the shell lands there after 1 second. Deals **AD** damage.
- **Teaches:** watching for warnings and dodging.

---

## Ally

### Senna
- Follows Lucian and fires long-range shots.
- Cannot die before the cutscene.

---

## Boss

### Thresh (scripted)
Only 2 skills in this act. The full fight happens in Act 6, where these skills are reused.

| Skill | Effect |
|---|---|
| **Death Sentence (Q)** | Hook in a straight line. A line warning appears before it fires. Pulls Lucian in on hit. |
| **Flay (E)** | Pushes Lucian back in a cone in front of Thresh. |

- **Phase end:** at **50% HP**, the fight stops and the cutscene plays.
- **Purple essence:** 10 on first clear only (Thresh does not return on replays).

---

## Replaying Act 1
- Lucian uses his **full kit** (two guns, all bought skills).
- **Thresh does not appear** after the first clear. The stage ends after wave 2.
- No repeat purple essence from this act.

---

## Built in Phase 6

### Enemies
Numbers at wave 1 (`data/enemies/*.tres`). Each later wave adds **+15% HP and damage**. Enemies attack only Lucian.

| Enemy | Kind | HP | Armor / MR | Attack | Range | Every | Speed | Gold | XP |
|---|---|---|---|---|---|---|---|---|---|
| Melee minion | normal | 240 | 10 / 0 | 12 physical, melee | 110 | 1.25 s | 300 | 60 | 30 |
| Ranged minion | normal | 160 | 0 / 10 | 18 magic bolt (450 px/s, aimed where Lucian stands); keeps 420–550 away | 550 | 1.6 s | 300 | 45 | 25 |
| Siege minion | elite | 700 | 20 / 10 | Cannon Shell: a red circle (r 110) on Lucian, 40 physical 1 s later | 700 | 3.0 s | 220 | 120 | 60 |

- Walls stop the ranged bolts. Stepping out of the circle in time dodges the shell.
- Elites have a small gold diamond at the left end of their HP bar.
- A kill gives 1 blue (5 for the siege minion) and a small chance of orange and an item (game design doc §9).

### The tutorial (first play)
Until 1-1 is cleared, Act 1 is the tutorial:
- Lucian fires **one gun**: every shot leaves the left one.
- **No skill ranks, no passive, no summoner spells.** Items, tree stats, equip slots and the skin still apply.
- **Senna** fights beside him.
- **Tips** show under the boss bar, one at a time, 7 s each (only while the game runs). Each shows once; later ones wait their turn. The keys follow the bindings.

| Tip | When |
|---|---|
| "RMB to move. Hold it to keep walking." | At once |
| "LMB on an enemy to attack it." | The first enemy spawns |
| "A red circle marks where a shell will land. Step out of it!" | The first siege minion spawns |
| "Hold A and press LMB to attack the nearest enemy." | The first kill |
| "RMB on the merchant to buy items with your gold." | The first break |
| "Thresh's hook flies along the red line. Move sideways!" | The boss wave starts |

### Senna
| | |
|---|---|
| Place | 150 behind and 90 to the left of Lucian, turned with him. She catches up faster the farther behind she is. |
| Attack | Every 1.5 s, the nearest enemy within 900: a shot for 45 physical |
| Safety | Enemies never target her, and she has no body, so she can't die before the cutscene |

Her kills give gold, XP and essence like Lucian's.

### Thresh (`thresh_1`)
He rises from the river for the boss wave. Bosses don't scale with the wave.

| | |
|---|---|
| HP | 3000. His HP never goes under half: at 50% the fight stops and the cutscene plays. |
| Armor / MR | 30 / 30 |
| Basic attack | A 30 physical bolt (900 px/s), range 450, every 1.8 s. Walks at 300. |
| **Death Sentence (Q)** | A line warning (1000 × 70) for 0.9 s, then the hook at 1400 px/s. On a hit: 80 magic, and Lucian is pulled to 120 in front of Thresh. Cooldown 9 s (first use after 2 s). |
| **Flay (E)** | A cone warning (70°, 400 long) for 0.6 s, then 60 magic and a push of 250 away from Thresh. Cooldown 7 s (first use after 4 s). |
| Rewards | 100 blue, 5 orange and 10 purple (first clear only). No gold, XP or item: he never dies. |

His skill hits count as skills, so Banshee's Veil blocks one (the hook's pull too).

### The cutscene
1. The fight stops. Black bars close in, the HUD hides, Lucian can't be hurt, and ESC and P do nothing.
2. The camera pans to show Thresh and Senna. Thresh: "Such a bright soul... it will make a fine light."
3. His hook flies to Senna. Lucian: "SENNA!"
4. The chain pulls her in and she falls, grey. The camera follows her to Thresh.
5. Her soul rises and flies into his lantern, which glows green. Thresh: "Your light is mine now."
6. He sinks into the river, in a widening ring.
7. The camera goes back to Lucian. He walks to where she fell, and her body fades.
8. "Lucian takes up Senna's gun. Relentless Pursuit (E) is now free in the Evolution Tree."

- A caption stays 3.5 s. Space or a left-click moves on. **Skip** (top right) ends the scene at once.
- Then **STAGE CLEARED**, with "Lucian takes Senna's gun: two guns from now on", "E – Relentless Pursuit is free in the Evolution Tree", "+10 purple essence (first clear)" and "Act 2 is open". Thresh's blue and orange rise where he sank.
- If Lucian dies first, it is DEFEATED: no cutscene and no purple.

### Replay
After the first clear: the full kit, no Senna, no Thresh and no tips. The stage ends after wave 2 and gives no purple.

### The mid lane map
| | |
|---|---|
| Size | 5200 × 3200 |
| Lane | A diagonal 900 wide, from the bottom-left (500, 2700) to the top-right (4700, 500) |
| Jungle | Both sides of the lane are wall: dark green, with trees drawn on it |
| River | Crosses the lane's middle at a right angle. Walkable shallow water, 520 wide, reaching 1100 from the lane's center each way. |
| Rocks | 3 (r 70) for cover: two on the lane by the river, one in the river |
| Lucian and Senna | Start at the bottom-left end |
| Minions | Come from two points at the top-right end, taking turns |
| Thresh | Rises in the river, 300 from its center on the top-left side |
| Merchant | On the lane, 700 before the river's center, during breaks |
