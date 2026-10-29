# Act 1 – The Loss (Tutorial)

> Part of the Lucian game design. Numbers are placeholders; base stats start from LoL minion values.

## Overview

| | |
|---|---|
| **Stages** | 1 |
| **Waves** | 2 waves + boss wave |
| **Map** | Mid lane (Summoner's Rift style, no turrets) |
| **Lucian** | Only **one gun**, auto attacks only; Senna teaches him **E** at the first break |
| **Teaches** | Moving, attacking, attack-move, dashing, dodging warnings |

## Story

Lucian and Senna fight minion waves together. At the first break, Senna teaches him **E (Relentless Pursuit)**. Thresh appears and attacks. When Thresh reaches 50% HP, a cutscene plays: he kills Senna and traps her soul in his lantern. Lucian takes up Senna's gun.

**Rewards:** Senna's gun (second gun), **E level 1** in the Evolution Tree, **Q and W** open in the Evolution Tree, first-time purple essence.

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
| Melee minion | normal | 240 | 10 / 0 | 12 physical, melee | 110 | 1.25 s | 240 | 60 | 30 |
| Ranged minion | normal | 160 | 0 / 10 | 18 magic bolt (450 px/s, aimed where Lucian stands); keeps 420–550 away | 550 | 1.6 s | 240 | 45 | 25 |
| Siege minion | elite | 700 | 20 / 10 | Cannon Shell: a red circle (r 110) on Lucian, 40 physical 1 s later | 700 | 3.0 s | 220 | 120 | 60 |

- In this stage (1-1), melee and ranged minions have **20% less HP**: 192 and 128 at wave 1. Other stages use the table (scaled by act and wave).
- Walls stop the ranged bolts. Stepping out of the circle in time dodges the shell.
- Elites have a small gold diamond at the left end of their HP bar.
- A kill gives 1 blue (5 for the siege minion) and a small chance of orange and an item (game design doc §9).

### The tutorial (first play)
Until 1-1 is cleared, Act 1 is the tutorial:
- Lucian has **one gun**: his body shows only the left pistol (`lucian_body_one_gun.svg`), and every shot leaves it. He shows both guns once he takes up Senna's, in the cutscene.
- **No skill ranks, no passive, no summoner spells** at the start. Items, tree stats, equip slots and the skin still apply.
- **Q and W are locked** until Act 1 is cleared. Hovering their HUD slots says "Locked: clear Act 1 to unlock it in the Evolution Tree."
- **Senna** fights beside him.
- **Senna teaches E at the first break** (before wave 2), in a short scene: the black bars close in, she dashes to the side and back, and says "Dash, then shoot." Lucian learns E at rank 1 for the rest of the stage. The break's countdown waits for the scene; Skip ends it, and he still learns E. Then the tip "E to dash toward the cursor. Your next shot is ready when you land." shows.
- **Tips** show under the boss bar, one at a time, 7 s each (only while the game runs). Each shows once; later ones wait their turn. The keys follow the bindings.
- **Losing it is a game over:** the result panel reads **GAME OVER** and its button **Back to title** returns to the title screen. The essences collected are still saved. Once 1-1 is cleared, losing it is a plain DEFEATED that goes back to the main screen.

| Tip | When |
|---|---|
| "RMB to move. Hold it to keep walking." | At once |
| "LMB on an enemy to attack it." | The first enemy spawns |
| "A red circle marks where a shell will land. Step out of it!" | The first siege minion spawns |
| "Hold A and press LMB to attack the nearest enemy." | The first kill |
| "E to dash toward the cursor. Your next shot is ready when you land." | Senna's lesson ends (the first break) |
| "RMB on the merchant to buy items with your gold." | The first break, after the lesson |
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
8. He picks up her gun (his body now shows two guns): "Lucian takes up Senna's gun."

- A caption stays 3.5 s. Space or a left-click moves on. **Skip** (top right) ends the scene at once; he still gets her gun.
- Then **STAGE CLEARED**, with "Lucian takes Senna's gun: two guns from now on", "E – Relentless Pursuit: level 1 in the Evolution Tree", "Q – Piercing Light and W – Ardent Blaze can now be bought in the Evolution Tree", "+10 purple essence (first clear)" and "Act 2 is open". Thresh's blue and orange rise where he sank.
- The save then has E at level 1 in the Evolution Tree (free, nothing to buy), and Q and W open there.
- If Lucian dies first, it is GAME OVER: no cutscene and no purple.

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
