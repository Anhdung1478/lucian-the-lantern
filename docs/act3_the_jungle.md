# Act 3 – The Jungle

> Part of the Lucian game design. Numbers are placeholders.

## Overview

| | |
|---|---|
| **Stages** | 5 |
| **Waves** | Stage 1: 3 · Stage 2: 4 · Stage 3: 4 · Stage 4: 5 · Stage 5: 5 + boss wave |
| **Mini bosses** | Infernal Drake (stage 2), Ocean Drake (stage 4), appearing in the last wave |
| **Boss** | Elder Dragon (stage 5) |
| **Teaches** | Fighting packs, using jungle buffs, chasing rewards |

## Story

Lucian crosses the jungle on his way to the Shadow Isles, facing the drakes and finally the Elder Dragon.

## Terrain by stage

| Stage | Terrain |
|---|---|
| 1, 3 | Normal jungle |
| 2 (Infernal Drake) | Lava patches that burn; Blast Cones that launch Lucian over walls |
| 4 (Ocean Drake) | Shallow water that slows; Honeyfruit plants that heal |
| 5 | Elder Dragon's pit |

---

## Normal enemies

Monsters always come in packs, mixing small and big ones (except Gromp).

| Pack | Size | Attack | Notes |
|---|---|---|---|
| **Raptors** | 1 big + 4 small | Fast melee, AD | Swarm Lucian |
| **Murkwolves** | 1 big + 2 small | Melee, AD | Run in to surround Lucian |
| **Krugs** | 1 big + 2 small | Slow, tanky melee, AD | The big Krug **splits into 2 small Krugs** when it dies |
| **Gromp** | 1 (alone, like LoL) | Ranged poison spit, **AP** | The only AP enemy in this act |

---

## Elites

### Blue Sentinel
- **Special normal attack:** a slam that slows Lucian.
- **Trait – Blue buff:** when killed, Lucian gets for **60 seconds**:
  - **+10 mana regen per second**
  - **+20 ability haste**

### Red Brambleback
- **Special normal attack:** burns Lucian.
- **Trait – Red buff:** when killed, Lucian gets for **60 seconds**:
  - **+5 HP regen per second**
  - Attacks burn for **15 true damage per second for 3 seconds**
  - Attacks and skills **slow enemies by 15%**

### Rift Scuttler
- Deals **no damage** and only runs away.
- **Escapes after 15 seconds** if not killed.
- Drops a **large amount of orange essence** if caught.

---

## Mini bosses

### Infernal Drake (stage 2)
High damage, big fire damage over time.

- **Normal attack:** a fireball that leaves a short burn.

| Skill | Effect |
|---|---|
| **Fire Breath** | A cone of fire that leaves burning ground for 3 seconds. |
| **Meteor Fall** | 3–4 fireballs land on circles marked around Lucian. Each leaves a burn. |

- **Purple essence:** 5 on first kill, 1 on repeat.

### Ocean Drake (stage 4)
- **Normal attack:** a water shot.

| Skill | Effect |
|---|---|
| **Tidal Wave** | A wave moves in a line, pushes Lucian back and slows him by 30%. |
| **Soothing Mist** | Stops and heals a large amount over 4 seconds. Enough burst damage interrupts it. |

- **Purple essence:** 5 on first kill, 1 on repeat.

---

## Boss

### Elder Dragon (stage 5)
- **Normal attack:** a shot.

| Skill | Effect |
|---|---|
| **Elder Breath** | A wide cone of AP damage. |
| **Sky Dive** | Flies off screen and can't be hit while its shadow follows Lucian, then lands with a big area attack. |
| **Elder's Mark** | Marks Lucian, then deals damage after 4 seconds. If Lucian is below 25% HP when it hits, the damage is much higher. The player must heal or shield in time. |

- **Purple essence:** 10 on first kill, 2 on repeat.

---

## Built in Phase 7

### Scaling
Monsters scale like Act 1–2 minions (`EnemyData`); mini bosses and the boss don't.

| | Per act after the first | Act 3 |
|---|---|---|
| HP | × (1 + 0.6 · (act − 1)) | × 2.2 |
| Damage | × (1 + 0.25 · (act − 1)) | × 1.5 |
| Gold and XP | × (1 + 0.25 · (act − 1)) | × 1.5 |
| Blue per kill | = act number (elites 5×) | 3 (elites 15) |

Each wave after the first also adds **+15% HP and damage**. A raptor at wave 1 has 242 HP and bites for 12.

### Monsters (`data/enemies/*.tres`, base numbers)
| Enemy | Behavior | HP | Armor / MR | Attack | Every | Speed | Gold / XP |
|---|---|---|---|---|---|---|---|
| Raptor | swarm | 110 | 10 / 0 | 8 physical, range 90 | 0.9 s | 330 | 20 / 10 |
| Crimson Raptor (big) | swarm | 360 | 20 / 10 | 18 physical, range 100 | 1.0 s | 320 | 55 / 28 |
| Murk Wolf | flank | 190 | 10 / 10 | 12 physical, range 100 | 1.1 s | 340 | 30 / 16 |
| Greater Murk Wolf (big) | flank | 480 | 20 / 15 | 24 physical, range 110 | 1.2 s | 320 | 70 / 36 |
| Krug | brute | 200 | 30 / 10 | 16 physical, range 100 | 1.5 s | 200 | 30 / 16 |
| Ancient Krug (big) | brute | 720 | 40 / 15 | 34 physical, range 120. Splits into 2 Krugs. | 1.8 s | 170 | 80 / 42 |
| Gromp | spit | 650 | 15 / 25 | A 22 magic bolt (500 px/s), range 500. Poisons Lucian: 6 magic a second for 3 s. | 1.7 s | 160 | 80 / 40 |

**How they move (`Monster`):**
- **Swarm:** each raptor runs to its own spot 60 px around Lucian, spread by a golden-angle counter, so a pack wraps him. It bites when in range.
- **Flank:** a wolf aims 160 px to one side of Lucian (picked at spawn) until it is within 250, then closes in.
- **Brute:** walks in and hits.
- **Spit:** Gromp keeps 380–480 px away, stepping back 100 at a time when Lucian comes closer. It stands still for 0.4 s each time it spits.
- **Flee:** the Scuttler runs straight away from Lucian and never attacks.

### Packs and camps
A wave lists packs; each pack comes out of its camp (±90 px). Spawning is still in groups of 3 every 1.2 s.

| Pack | Members | Camp |
|---|---|---|
| Raptors | 1 Crimson Raptor + 4 Raptors | Top left |
| Wolves | 1 Greater Murk Wolf + 2 Murk Wolves | Left edge |
| Krugs | 1 Ancient Krug + 2 Krugs | Right edge |
| Gromp | Gromp | Top right |

Blue's camp is low on the left, Red's low on the right, the Scuttler's on the river under the pit. The drakes come out of the pit. The pit of 3-5 has no camps: its waves come in at the north, east and west rim, in turn.

**Krugs:** an Ancient Krug's death brings 2 Krugs where it died, in its wave. The wave waits for them, so a splitting Krug never ends a stage.

### Elites
| Elite | HP | Armor / MR | Attack | Every | Speed | Gold / XP | On death |
|---|---|---|---|---|---|---|---|
| Blue Sentinel (brute) | 1700 | 35 / 35 | A 42 physical slam, range 150. Slows Lucian 30% for 1.5 s. | 1.6 s | 240 | 160 / 90 | Blue buff |
| Red Brambleback (brute) | 1700 | 35 / 35 | 40 physical, range 150. Burns Lucian: 8 magic a second for 3 s. | 1.5 s | 240 | 160 / 90 | Red buff |
| Rift Scuttler (flee) | 600 | 20 / 20 | None | — | 250 | 120 / 60 | +45 blue and +4 orange on top of an elite's |

**Jungle buffs** (`JungleBuffs`), given when the elite dies, for **60 s**. Each shows in the HUD's buff row with its timer. Death clears them.

| Buff | Gives |
|---|---|
| Blue | +10 mana regen a second, +20 ability haste |
| Red | +5 HP regen a second. His attacks burn their target for 15 true damage a second for 3 s, and his attacks and skills slow it 15% for 1.5 s. |

**Rift Scuttler:** after **15 s** alive it escapes: "Escaped!", it fades, and it counts as done for the wave. No rewards, and it isn't a kill. A shot already in flight can't kill it once it is going.

### Mini bosses (`kind = mini_boss`, no scaling)
Each comes last in its stage's last wave, out of the pit. All skill hits count as skills (Banshee's Veil blocks one). After a skill's warning ends it stands for 0.3 s.

| | Infernal Drake (3-2) | Ocean Drake (3-4) |
|---|---|---|
| HP | 9000 | 10000 |
| Armor / MR | 40 / 40 | 40 / 50 |
| Basic attack | A fireball, 50 magic (700 px/s), that burns 10 magic a second for 2 s. Range 600, every 1.6 s. | A water shot, 55 magic (800 px/s). Range 600, every 1.5 s. |
| Speed / radius | 260 / 70 | 260 / 70 |
| Skill 1 | **Fire Breath:** when Lucian is within 580, a cone warning (60°, 550 long) for 0.8 s, then 100 magic. The cone then burns for 3 s (30 magic a second). Cooldown 9 s, first after 3 s. | **Tidal Wave:** a line warning (1100 × 180) for 0.8 s, then a wave front, 180 wide, rolls along it at 900 px/s. A hit: 90 magic, a push of 300 along the line (walls stop it), and a 30% slow for 2 s. Cooldown 10 s, first after 3 s. |
| Skill 2 | **Meteor Fall:** within 900, 4 circle warnings (r 120): one on Lucian, 3 within 280 of him, all on walkable ground. 1.2 s later each lands for 80 magic and burns for 3 s (25 magic a second). Cooldown 13 s, first after 6 s. | **Soothing Mist:** at or below 70% HP, it stands still and heals 30% of its max HP over 4 s, a mist ring round it. 8% of its max HP in damage during that time **interrupts** it: "Interrupted!", and it stands dazed for 1.5 s (stars over its head). Cooldown 18 s. |

**Rewards, paid on the kill:** 300 gold, 50 blue, 3 orange, and **5 purple the first time, 1 after**, with a line on the end screen ("+5 purple essence (Infernal Drake, first kill)"). Its loot: a fragment for sure, and 8% a legendary. The kill that ends the stage drops nothing.

A mini boss has a wide health bar, a 12 px skull on the radar, and the boss bar while no boss is out.

### Boss: Elder Dragon (`elder_dragon`, 3-5)
It comes in the boss wave, after waves 1–5, in the middle of the pit.

| | |
|---|---|
| HP | 16000 |
| Armor / MR | 50 / 50 |
| Basic attack | A violet shot, 70 magic (900 px/s), range 650, every 1.5 s. Walks at 280; radius 84. |
| **Elder Breath** | When Lucian is within 730: a cone warning (90°, 700 long) for 1.0 s, then 160 magic. Cooldown 8 s, first after 2 s. |
| **Sky Dive** | At or below 85% HP. It takes off (fading out in 0.3 s), untargetable and unseen. Its shadow follows Lucian at 300 px/s for 2.4 s, over walls and rocks. Then the shadow stops, a circle warning (r 260) fills for **1.2 s**, and it lands: 240 magic and a 200 push from the circle's middle. It is up about 3.6 s. Cooldown 18 s. |
| **Elder's Mark** | It stands 0.3 s and marks Lucian: a sigil over his head and a ring that empties over **4 s**. Then 130 true damage, or **× 3 (390)** if he is under 25% of his max HP as it lands; the ring turns red while he is that low. Shields absorb it; Banshee's Veil blocks it. It goes away harmless if Lucian dies or the dragon does. Cooldown 16 s, first after 8 s. |
| Rewards | 300 gold, 100 blue, 5 orange, and 10 purple the first time, 2 on a replay |

- While it is up, the boss bar keeps it, and Lucian keeps his attack order on it: he shoots again once it lands. Shots already in flight miss.
- It lands on its own fall timer; the circle only shows where.
- A landing spot in a rock or the rim moves toward the pit's middle until its body fits.

### Waves (`WavePlan`)
Packs: **R** raptors, **W** wolves, **K** Krugs, **G** Gromp. Elites: **B** Blue, **D** Red (Brambleback), **S** Scuttler. HP is the wave's total after scaling, with the split Krugs counted.

| Stage | Waves | Enemies | HP per wave | Mini boss / boss |
|---|---|---|---|---|
| 3-1 | R W · R R G B · W K G D S | 8 · 12 · 9 | 3.7k · 10.0k · 15.2k | — |
| 3-2 | R W G · R K W B · W K G D S · R W K G + drake | 9 · 12 · 9 · 13 | 5.1k · 12.3k · 15.2k · 12.2k + 9k | Infernal Drake, last in wave 4 |
| 3-3 | R R W G · K W G B · R W K D S · R R W K G B | 14 · 8 · 13 · 18 | 6.8k · 12.0k · 15.7k · 20.2k | — |
| 3-4 | R W G K · R W K B · W K G D S · R R K G B · R W K G D + drake | 12 · 12 · 9 · 15 · 14 | 8.4k · 12.3k · 15.2k · 17.4k · 19.5k + 10k | Ocean Drake, last in wave 5 |
| 3-5 | R W K G · R R W B · W K G D S · R W K G B · R R W K D S | 12 · 14 · 9 · 13 · 18 | 8.4k · 10.5k · 15.2k · 17.6k · 22.1k | Elder Dragon (boss wave) |

The waves hold about **275k HP**, plus 35k for the two drakes and the dragon. 3-1's first wave is the act's smallest, so the act starts gently.

### The jungle (`JungleMap`, stages 3-1 to 3-4)
| | |
|---|---|
| Size | 5600 × 3600 |
| Floor | Paths 420 wide and round clearings, cut out of dense jungle (drawn like Act 1's: dark green, tree blobs, a lighter edge) |
| Paths | The middle path runs edge to edge (y 1850). Side paths at x 1500 and 4100 run from the top (y 700) down to the low path (y 2750). The river path runs from the pit down to the start. |
| Clearings | The pit (r 460, top center), the center (r 450), the start (r 380, bottom center), each camp (r 300) and the Scuttler's (r 260) |
| Lucian | Starts at (2800, 2950), in the start clearing |
| Merchant | (2610, 2160), at the center clearing's south-west rim |
| Riverbed | Winds from the pit to the start, 280 wide. Dry, drawn only, in 3-1 to 3-3. |

The paths make two loops. Each loop's inner jungle is a wall of its own, so no wall polygon has a hole (a hole would collide as solid wall).

**Terrain by stage** (it acts on Lucian only):

| Stage | Terrain |
|---|---|
| 3-1, 3-3 | None |
| 3-2 | **5 lava pools** (r 140–150): two at the back of the pit, behind the drake, one on the river path, two by the center. Inside one, Lucian burns for **40 magic a second**, and for 0.5 s after he leaves. **4 Blast Cones** on the middle and low paths, each beside a loop's jungle. |
| 3-4 | **Shallow water** fills the riverbed: a **25% slow** while he is in it. **4 Honeyfruit** on the side and low paths. |

- **Blast Cone:** shoot it (a basic attack or a skill; a burn tick doesn't count). It pops, and if Lucian is within **350**, he is thrown **800** straight away from it in **0.6 s**, over walls. He lands on the farthest spot at least 250 away and 40 from any wall; with no such spot there is no throw. He can't act in flight, and lava doesn't burn him in the air. The plant regrows after **20 s**. It is never an enemy (waves, the radar and A + Left-click's fallbacks ignore it), but a click on it attacks it. It draws 108 px wide, with a soft yellow glow while ripe.
- **Honeyfruit:** walking over it (within 50 of his edge) heals **100 + 6% of his max HP**. It is an empty stalk for **30 s**, then grows back.

### The Elder Dragon's pit (`DragonPitMap`, 3-5)
| | |
|---|---|
| Size | 3600 × 3600 |
| Floor | Round stone, r 1650, with rock all round it in 8 arc pieces (so no wall has a hole) |
| Cover | 6 rocks (r 80) in a ring of r 900 |
| Spawns | The north, east and west rim (never the south, where Lucian starts) |
| Lucian | Starts 1000 south of the middle |
| Merchant | 450 south of the middle |
| Dragon | The middle |

### Walking around walls
Enemies and Lucian walk straight while nothing blocks the line to their goal. When a wall does, they follow a path baked from the map's walls (agent radius 36), asked again every 0.4 s or when the goal moves 120. Lucian's moves, chases, merchant visits and cast walks use it too, on every map. A click inside a wall walks to the closest reachable point.

### Art
Hand-written SVGs, top-down, facing right: the 10 monsters (red-crested raptors, grey-blue wolves with teal eyes, mossy rock Krugs, a green-purple toad, a blue stone golem, a red thorned beast, a purple shelled crab), the two drakes (150 px), the Elder Dragon (180 px), the Blast Cone (108 px) and Honeyfruit (56 px), the Blue and Red buff icons, the slow and burn icons, and Elder's Mark.
