# Lucian: The Lantern — Game Design Document (Draft v1)

> Personal project, not for public release. All numbers are placeholders to be tuned during playtesting.

---

## 1. Overview

| | |
|---|---|
| **Genre** | 2D top-down roguelite wave shooter |
| **Inspiration** | League of Legends (champion, items, stats, controls) |
| **Engine** | Godot 4 |
| **Team** | Solo developer |
| **Platform** | PC (mouse + keyboard) |
| **Graphics** | Top-down view like LoL, simpler and less detailed |
| **Character** | Lucian (more champions could be added later) |
| **Target length** | A skilled player needs at least 5–7 hours to beat the story *(V2.0: a skilled player wins the story in about 4–5 hours, a novice in about 7–10. Measured with the bots on Normal: skilled 3 h 56 and 4 h 22 of stage time, about 4 h 13 and 4 h 40 of play; average 4 h 56, about 5 h 32; novice: see the report.)* |

**Design rule:** this is not LoL. Everything taken from LoL (stats, items, skills, UI, enemies) should stay only about **70–80% similar**, adapted to fit this game.

**Core loop:** Clear waves of enemies in a stage → earn stage gold, XP and essences → buy and craft items between waves → finish the stage → spend essences on permanent upgrades in the Evolution Tree → push into harder stages.

### Pacing
Minutes for a skilled player's first clear of each act, counting a few deaths, shopping, and the replays needed to afford Evolution Tree nodes.

| Act | Stages | Waves (+ boss / mini boss waves) | Minutes |
|---|---|---|---|
| 1 | 1 | 2 + 1 | 8–10 (tutorial and cutscene) |
| 2 | 3 | 8 + 1 | 30–40 |
| 3 | 5 | 21 + 3 | 70–90 |
| 4 | 3 | 14 + 1 | 45–60 |
| 5 | 5 | 28 + 3 | 80–100 |
| 6 | 5 | 33 + 3 | 90–120 |
| **All** | 22 | 106 + 12 | **323–420 (5.4–7 h)** |

**Pacing in V2.0** (before V2.0: the table above). Waves are `WavePlan.STAGES` (143 + 12 boss and mini boss waves). Minutes are the skilled bots' stage time on Normal, the range of two runs; Act 1 was not timed apart.

| Act | Stages | Waves (+ boss / mini boss waves) | Minutes (stage time, skilled bots) |
|---|---|---|---|
| 1 | 1 | 2 + 1 | not measured apart |
| 2 | 3 | 14 + 1 | 23–25 |
| 3 | 5 | 31 + 3 | 39–60 |
| 4 | 3 | 20 + 1 | 32–34 |
| 5 | 5 | 33 + 3 | 73–82 |
| 6 | 5 | 43 + 3 | 62–66 |
| **All** | 22 | 143 + 12 | **236–262 (3 h 56 to 4 h 22) of stage time; about 4 h 13 to 4 h 40 of play** |

**Rules of thumb:**
- A wave should take a skilled player **about 2 minutes** of fighting.
- A boss should take **2–3 minutes**.
- A break is used, on average, for about 30 s of shopping.
- About a third of each act's time is deaths and replays: farming essence for the tree (see the balance goal in §11).

**Measuring it:** each stage's end screen shows its time, and the slot lists (title screen, Save as copy) show each slot's total play time. Both clocks skip paused time, so shopping (the shop pauses the game) isn't in them, while the budget counts about 30 s of shopping per break. If Act 2 clears in under 25 minutes, or Act 3 in under 60, raise `EnemyData.ACT_HP` and the bosses' HP before changing rewards. *(V2.0: those two limits belong to the 5–7 hour target. The 4–5 hour target is measured with the bots, in the V2.0 table above.)*

**As built (Phase 7):** Act 3's waves hold about 275k HP, plus 35k for the two drakes and the dragon; Act 4's about 313k, plus 18k for Dark Lucian. The drakes come last in their stage's last wave, not in a wave of their own, so Act 3 has 21 waves plus the Elder Dragon's boss wave. *(V1.5.0: Act 3's waves hold about 128k and its drakes and dragon 27.5k; Act 4's waves about 164k. See the act files.)* *(V2.0: Act 3's waves hold about 278k and its drakes and dragon 35.5k; Act 4's waves about 332k and Dark Lucian 25k. Act 3 has 31 waves plus the Elder Dragon's boss wave. See the act files.)*

---

## 2. Controls

| Input | Action |
|---|---|
| Right-click | Move (hold to keep following the cursor). A dash (E, Galeforce, Rocketbelt) or Flash drops a move or merchant visit ordered before it, even with the button still held: right-click again, during the dash or after it, to walk on. |
| Left-click on enemy | Attack (a Blast Cone too) |
| A + left-click | Attack what the player means: the enemy under the cursor, else the weakest in range, else the nearest (see below) |
| Q / W / E / R | Skills |
| D / F | Summoner spells |
| 1–6 | Item actives and potions in equip slots 1–6 |
| P | Open backpack (pauses the game) |
| ESC | Open menu: resume, settings, leave stage, exit (pauses the game) |
| Ctrl + C | Toggle the stats panel |
| Hold C | Show the extra stats (health / mana regen, heal & shield power, penetration, life steal, omnivamp, range, tenacity) |
| Y | Toggle camera between free-cam and Lucian cam (follows Lucian). Default: free-cam |
| Space | Move the camera back over Lucian; hold it to keep the camera on him (free-cam stays free once let go) |

**Cast modes (Settings → Controls, one per key):** for Q / W / E / R, D / F and item keys 1–6.
- **Quick cast** (default): casts toward the cursor on press.
- **Quick cast with indicator:** holding the key shows the range toward the cursor; releasing it casts. Left-click does nothing meanwhile. *(V1.4.3: let go during crowd control, the aim stays on screen and fires where the cursor is once Lucian can act. A left-click meanwhile gives its order, as any click during crowd control does. Right-click or ESC cancels it, and death drops any aim.)*
- **Normal cast:** pressing the key shows the range; left-click casts. Pressing the same key again keeps aiming; another cast key switches to it.

Right-click or ESC cancels an aim in either mode (right-click doesn't move Lucian, ESC doesn't open the menu).

Casts with no aim (potions, Ghost, Barrier, Heal, Clarity) and casts that aren't ready (cooldown, mana, Q / W during R) always go on press. Pressing R while it fires still stops it.

**Range indicators:** a ray for Q, W (ending in the cross it bursts into), E and the item dashes (with a ring where Lucian lands), two dashed rays for R, a circle for Gunblade (700), Smite (500) and Flash (400; a blink, so a circle, with the landing ring while aiming). They show while aiming (toward the cursor), and while a learned skill, an item active or Flash / Smite is hovered on the HUD (where Lucian faces).

**Dashes** (E, Galeforce, Rocketbelt) go as far as the cursor, up to their range, so a cursor right on Lucian dashes 0.

**Targeted casts** (Gunblade, Smite) hit the enemy nearest the cursor within range. Aimed at an enemy out of range, Lucian walks over and casts once it is in range; any new order (move, attack) drops it, a dash or Flash doesn't. *(V1.3.1: the enemy under the cursor comes first, even with another one in range: out of range, he walks to it.)* *(V1.4.3: with Cast queue off, not when pressed during a cast time or a dash; see below.)*

**Key bindings** can be changed in Settings → Controls (all but ESC and the debug F3 + Q). *(V1.5.0: F3 + Q opens the debug tables only in a debug build, the editor's or the tests'. In the released game it does nothing, and Q casts as usual.)*

**Cast queue (setting, on by default; called Skill queue before V1.4.2):** a skill, an item active (Gunblade, Galeforce, Rocketbelt…) or a summoner spell pressed during a cast time or the E dash is cast as soon as it ends, aimed where the key was pressed. All three share **one slot** and only the latest press is kept. The only cast times are Q's 0.3 s and W's 0.2 s: R is a channel, not a lock, so nothing waits through it, and Q / W pressed during R are still refused. Potions stay instant. A rooted Flash or item dash is refused, not queued. A stun, a displacement or death drops the queued press. With the setting **off**, a summoner spell pressed during Q's or W's cast time is refused, as a skill is. *(V1.4.2.)* *(V1.4.3: with it off, a Gunblade or Smite pressed during a cast time or a dash at an enemy out of reach is refused too: he no longer walks into reach afterwards, and his attack order is kept.)*

**A + Left-click (built in Phase 7).** A arms it: Lucian's attack range shows as a ring and the cursor turns to a cross. The left-click then picks one target, in this order:
1. The enemy (or Blast Cone) under the cursor, even out of range.
2. Else the enemy with the **lowest HP %** within his attack range; on a tie, the nearer one.
3. Else the **nearest enemy on the map**: he walks to it (around walls) and shoots once in range.
4. With no enemy at all, he walks to the clicked point.

It is one target: after that kill Lucian stops and idles. A dead or untargetable enemy is never picked. Act 1's tip reads "Press A, then LMB: attack the enemy under the cursor, or the weakest one in range." (the keys follow the bindings).

---

## 3. Stage Rules

- Every stage starts with an **empty backpack** and **0 stage gold**. Lucian starts at **level 1** in Act 1, Training and Endless; from V1.3 a story stage starts him at its act's level (Act 2: 2, Act 3: 5, Act 4: 5, Act 5: 7, Act 6: 9), with that many skill points to spend (§17).
- A stage is made of **waves**. The stage ends when **all enemies are cleared**.
- The last stage of each act has **1 extra wave**, in which the boss appears.
- Waves per stage increase across the game (boss wave not included):

| Act | Waves per stage |
|---|---|
| 1 | 2 |
| 2 | 2 · 3 · 3 |
| 3 | 3 · 4 · 4 · 5 · 5 |
| 4 | 4 · 5 · 5 |
| 5 | 5 · 5 · 6 · 6 · 6 |
| 6 | 6 · 6 · 7 · 7 · 7 |

*(V2.0: the waves per stage, 143 in all (was 106). Bosses and mini bosses are as before.)*

| Act | Waves per stage, V2.0 |
|---|---|
| 1 | 2 |
| 2 | 4 · 5 · 5 |
| 3 | 5 · 6 · 6 · 7 · 7 |
| 4 | 6 · 7 · 7 |
| 5 | 6 · 6 · 7 · 7 · 7 |
| 6 | 8 · 8 · 9 · 9 · 9 |

- Mini bosses appear in the last wave of their stage.

### Break between waves
- After a wave is cleared, the next wave starts in **20 seconds**.
- The **merchant** appears on the map during this break. Lucian walks to him to buy or sell. When the break ends, he disappears.
- A **Skip** button (top center) starts the next wave right away.
  - Skipping counts as if the remaining time has passed for **HP and mana regeneration** (Lucian gets the regen he would have gotten).
  - **Skill cooldowns, summoner spell cooldowns and buff timers do not advance** from the skipped time.
- Opening the merchant's shop **pauses the game** (including the break timer), like the backpack.
- While the backpack or merchant's shop is open, the player **cannot use skills or items**.
- Dying or quitting a stage: the player **keeps all essences** collected.
- Cleared stages **can be replayed** to farm essences.

### Enemy rules
| Type | Skills | Notes |
|---|---|---|
| Normal enemy | None | Melee or ranged, AD or AP damage |
| Elite | None | Can have a **special normal attack** (e.g. siege minion's shell) or a **special trait** |
| Mini boss | 2 skills | |
| Boss | At least 3 skills | Exception: Thresh in Act 1 has only 2 |

### Built in Phase 6
Acts 1 and 2 play this way. Training keeps its dummies and has no waves.

**Stage flow:**
1. **"Wave 1 in 0:05"** at the top center, with Skip.
2. A wave spawns in **groups of 3 every 1.2 s**, taking turns over the map's spawn points.
3. Once every enemy of the wave is dead, a **20 s break**: the merchant comes at its start and leaves at its end.
4. After the last wave, one more break, then the **boss wave** (if the stage has a boss).
5. The **result panel**.

- **Skip** starts the next wave now and gives Lucian the HP and mana regen of the time skipped, at once. Cooldowns and buffs don't move.
- **Enemies** attack only Lucian. They walk straight at him, sliding along walls; one that gets stuck sidesteps for a moment. They bump into each other and into Lucian. There is no navigation mesh. *(Phase 7: they path around walls; see below.)*
- **Enemy bolts** are stopped by walls and pillars. Lucian's homing shots still fly over walls.
- **Enemy hits** reach Lucian within his radius (30) of his center. Red ground warnings (circle, line, cone, lock line) fill up before an attack lands. *(V1.4.3: a cone counts his 30 px body at its sides too, as circles, lines and rings do, so a body reaching over a side edge is hit.)* *(V1.3.1: a warning dies with its caster. Once the enemy that cast it is dead, it goes at once with no hit: the Infernal Drake's meteors and Fire Breath, Karthus's Lay Waste, Elder Breath, a siege minion's shell.)*
- **Scaling** (bosses don't scale): per act after the first, HP × (1 + 0.6 · (act − 1)), damage and rewards × (1 + 0.25 · (act − 1)). Each wave after the first adds +15% HP and damage. A stage can also lower some enemies' HP on its own: in Act 1 (1-1), melee and ranged minions have 20% less HP. *(V1.3: HP × (1 + 0.25 · (act − 1)), damage × (1 + 0.15 · (act − 1)), +10% a wave; the first stage of every act is gentler, and the tutorial's minions hit 25% softer. See §17.)* *(V2.0: HP × (1 + 0.35 · (act − 1)), so ×1.35 in Act 2, ×1.70 in Act 3, ×2.05 in Act 4, ×2.40 in Act 5 and ×2.75 in Act 6 (`EnemyData.ACT_HP`). Damage per act, the 10% a wave and the shares below are as in V1.3 and V1.5.0.)* *(V1.5.0: the second stage of every act (2-2, 3-2, 4-2, 5-2, 6-2) is a little gentler too: its normal enemies have 10% less HP. Elites, mini bosses and bosses keep theirs. `WavePlan.HP_SHARES`.)*
- **Death:** Lucian turns grey and fades for 1.5 s, then DEFEATED shows. Enemies stand still while he is dead or in stasis. Guardian Angel's stasis comes first. *(V1.4.3: in stasis his skill, summoner spell and item cooldowns and his attack timer keep counting down; only his buff timers and regen stop (`items.md`, Guardian Angel).)*
- **Game over:** losing Act 1 before its first clear (the tutorial) shows **GAME OVER** instead, and **Back to title** returns to the title screen. It still auto-saves, so the essences collected are kept.
- **Result panel** (pauses the game; ESC and P do nothing): **STAGE CLEARED**, **DEFEATED** or **GAME OVER**, the stage name, "Waves cleared: 2 / 3 · Time 4:32", the essences collected and any first-clear lines. **Continue** auto-saves and opens the main screen on that act (Back to title after a game over). *(Phase 7: the end screen replaces it; see below.)*
- **The stage time** only runs while the game does: the backpack, the shop, the ESC menu and the result panel stop it.

### Built in Phase 7
Acts 3 and 4 play this way too (`act3_the_jungle.md`, `act4_the_darkness.md`): packs from their camps, jungle buffs, terrain, two mini bosses, the Elder Dragon, the dark lane and Dark Lucian.

**The end screen** (`StageResult`) replaces the result panel. It covers the whole screen; the game pauses, the HUD hides, and ESC and P do nothing.
- A banner: **STAGE CLEARED** in gold, or **DEFEATED** / **GAME OVER** in red, over a soft gold or dark red glow. The stage's name under it.
- **Stats:** Time, Waves, Kills, Damage dealt, Damage taken, Gold earned, Level reached.
  - Kills count every enemy death in the stage; an escaped Scuttler isn't one.
  - Damage dealt is the HP Lucian's hits really took (capped at the HP left). Debug kills add nothing.
  - Damage taken is after armor and MR, before shields, as the numbers over Lucian show.
  - Numbers have commas under 10,000 ("9,999") and read "41.2k" above.
- **Rewards:** each essence collected with its icon ("No essences" when there are none), then the green lines: first-clear and first-kill purple, Act 1's lines, and **"Stage 3-3 is open"** or **"Act 4 is open"** on a first clear.
- **Buttons** (Main screen is the lit one; each auto-saves first):

| Outcome | Buttons |
|---|---|
| Cleared | **Retry** · **Next stage** (only when the next stage can be played) · **Main screen** |
| Defeated | **Retry** · **Main screen** |
| Game over (the tutorial) | **Back to title** |

- **Retry** starts the same stage again, built fresh from the save. **Next stage** starts the next one (after 2-3, it is 3-1). **Main screen** opens the main screen on that act. If the save fails, Retry and Next go to the main screen instead, with its "Could not save" toast. *(V1.5.0: the Journey opens on the latest open stage, the first open one not yet cleared, or on Training once every stage is cleared, whatever was played; after the tutorial that is 2-1. `main_screen.md`, "Which place opens".)*

**Walking around walls:** enemies and Lucian walk straight while nothing blocks the line to their goal. When a wall does, they follow a path baked from the map's walls (agent radius 36), asked again every 0.4 s or when the goal moves 120. Lucian's moves, attack chases, merchant visits and cast walks use it; a click inside a wall walks to the closest reachable point. The enemies' sidestep stays as a fallback. Until the map's navigation is ready, and whenever a path comes back empty, everyone walks straight. Acts 1–2 benefit too.

**Status effects:**
- **Slows** work on Lucian and on enemies. The strongest one wins; tenacity doesn't shorten them. Gunblade's 40% uses the same rule. *(Since V1.4, Lucian's slow resist from boots weakens the slow: × (1 − slow resist).)*
- **Overlapping burns** with the same id: **the strongest wins** (V1.4.2). A weaker one can't lower a stronger one that still has time left, and it takes over once the stronger one runs out. A zone re-applies its burn every frame, so a weaker zone takes over 0.5 s after Lucian leaves the stronger one. An equal or stronger burn replaces the current one, as before.
- **Burns** deal damage every 0.5 s for their time, physical, magic or true (armor and MR lower them as usual). A tick makes no hit sound and no flash. It isn't a basic attack or a skill, so it triggers no on-hit effect, no Thornmail, and Banshee's Veil doesn't spend itself on one.
- On Lucian they show in the buff row ("Slowed", "Burning", the strongest slow); on an enemy, as icons over its HP bar.
- **Timed stat buffs** (the jungle buffs) raise HP regen, mana regen and ability haste for their time.
- Death clears them all.

**Untargetable enemies** (the Elder Dragon's Sky Dive, Dark Lucian's E): they leave the enemies, so attacks, homing shots in flight, A + Left-click, Senna and the radar drop them, and they take no damage, burns included. Lucian keeps an attack order on one and shoots again once it is back; the boss bar keeps it too.

**Thrown over walls:** a Blast Cone throws Lucian. He can't act in flight, nothing pushes him then, and he lands on walkable ground. The throw builds no Energize.

**Mini bosses** come last in their stage's last wave (`kind = mini_boss`). They don't scale. Their purple is paid on the kill.

### Built in Phase 8
Acts 5 and 6 play this way too (`act5_shadow_isles.md`, `act6_the_lantern.md`). **All 22 stages can be played.** Only Endless waits. *(Phase 9: Endless plays too; see §14.)*

**Crowd control on Lucian.** Root, stun and fear come from Maokai, Elise, Hecarim and nothing else. One entry point, `Lucian.add_cc`; the timers live in `CrowdControl`.

| Kind | Effect |
|---|---|
| Root | He can't walk, use E, Flash or an item dash (Galeforce, Rocketbelt). A move order waits and runs when the root ends. Attacks in range, Q, W, R and items that don't move him still work. |
| Stun | He can't act. It drops the windup, the queued cast, a dash and R, as a displacement does. **His last move, attack or merchant order is kept** (V1.4.2, see below). *(V1.3.1: it also drops a shot still waiting to fire: Q's beam or W's missile in their cast time, the passive's second shot, Galeforce's missiles. Death and Guardian Angel's stasis drop them too. Mana and cooldowns stay spent; a shot already flying still lands.)* |
| Fear | He can't act. It drops the same, and he runs straight away from the source at 60% of his speed, sliding along walls. Walls and the abyss stop him; enemy bodies don't, so nothing can push him along. It builds no Energize. With a root at the same time, the fear still walks him (the fear wins). |

- **Tenacity** shortens root, stun and fear (a time × (1 − tenacity)); the same kind keeps the longer time. **Slows are not shortened**, as before.
- A stun or fear during a pull lets the pull finish and holds him after it. A **root ends a dash already under way** (V1.4.2): he stops where he is. Galeforce's missiles still fire, since a root doesn't stop attacks.
- **Orders through crowd control (V1.4.2, like LoL):** a stun, fear, displacement, throw or Guardian Angel's stasis drops what is in flight (the windup, a queued cast, a walk to a cast) but **keeps a MOVE, ATTACK or merchant-visit order**. The order doesn't run during the CC and runs again when it ends. Right-clicks and left-clicks (and A + Left-click) are accepted while he is stunned, so a click given during the CC replaces the old order and runs after it; the attack target is resolved at the click. A held right-click keeps steering afterwards. A merchant clicked during CC opens once it ends. Skill, item, summoner and potion keys stay ignored during CC. *(V1.4.3: an aim already on screen waits the CC out. A quick cast with indicator let go during it fires where the cursor is once it ends; a normal cast still needs its left-click.)* Death clears everything.
- Dead, in stasis, `invulnerable` or thrown over a wall: he refuses CC. Death clears it.
- **A skill's CC lands only when its hit lands:** Banshee's Veil blocks the damage and the CC with it.
- **Fairness:** every root, stun or fear comes from a warning of 0.7 s or more, or from a bolt or wave he can see, and lasts 1.5 s at most (1.0, 1.25 and 1.25 s are the built values). It shows in the buff row ("Rooted", "Stunned", "Feared", with icons) and as a short red word under his health bar (the strongest: stun, then fear, then root).

**Summons** (the Maiden's ghouls, the Broodmother's spiderlings, Thresh's Lantern Souls): the wave counts one the moment it is asked for and waits for it. Each summoner has a cap on its live summons. A summoner's death leaves them. A summon pays 25% (§9). *(V1.5.0: the Maiden heals 5% of her max HP each time she calls ghouls, and the final Thresh heals 3% when one of his souls is killed within 400 of him, 10 times a fight at most.)* *(V2.0: a summoner also has a total (`EnemyData.summon_total`): the Maiden of the Mist calls 12 ghouls in all and the Broodmother 10 spiderlings, then no more. Before, only the cap on live summons limited them.)*

**Vanishing:** a sapling that explodes and Thresh's souls at his fall leave with no rewards at all, no note and no kill. It is the Scuttler's escape without "Escaped!". **Freed:** a Lantern Soul that dies (or vanishes) rises and fades as teal-white light with a soft chime, and pays like any kill.

**The Black Mist** (Act 5): a normal or elite enemy in a mist bank, more than 350 from Lucian, is veiled: a dark silhouette with no health bar and no radar dot. It can still be targeted and hit, and its warnings show. Bosses and mini bosses are never veiled. *(V1.5.0: a hurt normal or elite enemy in a bank also regenerates 1% of its max HP a second while it is veiled; once Lucian is close enough to see it, it stops. It is the same in Endless on the Dead forest. Bosses and mini bosses don't.)*

**Enemy heals (V1.5.0).** Only the Ocean Drake healed before. Now the Black Mist heals (above), the Maiden of the Mist heals 25% of the damage her basic attacks deal and 2% of her max HP when she calls ghouls (`act5_shadow_isles.md`), and the final Thresh harvests his Lantern Souls (`act6_the_lantern.md`). Every enemy heal goes through `Enemy.heal`, so Grievous Wounds cuts it by 40%. A heal shows as a green "+N" over the enemy, gathered over 0.4 s, the Ocean Drake's too; none shows while the enemy is veiled.

**The abyss** (Act 6) blocks walking, dashes, Flash, pulls and enemy bodies, but not bolts, chains or Lucian's shots. A pull stops at its edge. Chain Warden ledges are abyss for physics.

**Final Thresh** never dies at 0 HP in Phase 1: he rises (2.5 s, no damage, full HP, darker, "Phase 2"). At 0 HP in Phase 2 the ending plays. **Karthus's Requiem** shows a break bar under the boss bar; 8% of his max HP in damage breaks it.

**The ending:** the cutscene (skippable), STAGE CLEARED with "Senna is free" and "The story is complete", then, on the first clear only, `TheEndScreen` with the slot's story time. Replays skip it.

**Debug:** the stage debug table gains "Boss HP 5%" and "Jump to the last wave" (every enemy goes, no rewards, and the last wave comes next). Since V1.4.2 the jump also removes untargetable bosses (one mid-dash, mid-Rappel or mid-Sky Dive). Since V1.4.3 a Dark Lucian removed mid-dash leaves no violet trail behind (it fades as at a dash's end), and a Thresh spawned from the debug list (not the stage's boss) leaves at 50% HP with his blue and orange, with no cutscene, and the fight goes on.

### Built in V2.0
**Resolve.** A story stage that beats Lucian gets a little easier each time, so every player gets through in the end.
- Each **defeat** on a story stage **not yet cleared** adds one stack of Resolve for that stage, up to **5**. Leaving a stage is no defeat.
- A stack gives **+10% damage dealt and -10% damage taken** on Easy and Normal, **5%** on Hard and **none** on Extreme (`Difficulty.RESOLVE_STEPS`, §17). Damage dealt covers attacks, skills, items and Lucian's burns, and is multiplied before the enemy's armor and magic resist. Damage taken is multiplied on top of the difficulty's scale, before armor and magic resist.
- **Clearing the stage clears its stacks.** A cleared stage replayed, Training and Endless have none.
- The save keeps the defeats per stage (`"defeats"`, §15). The stacks of a try are read when the stage starts.
- The Gameplay setting **Resolve** (on by default) turns the effect off. The defeats are still counted, so the stacks come back when it is turned on.
- It shows as a **buff icon** with the stacks, a green line on the DEFEATED screen ("Resolve 3 / 5: +30% damage, -30% damage taken on your next try"), a line in the Journey's side panel and a second line in each difficulty's hover text (`ui_design.md` §1, §5, §7; `main_screen.md`).
- Code: `Resolve` (`src/core/resolve.gd`), `Lucian.set_resolve`.

**The next-wave preview.** Before wave 1 and in every break, a plate under the stage info shows **NEXT** and each enemy of the next wave as an icon with its count; a boss or mini boss has a gold rim and its name. Endless only says "Mini boss wave" or "Boss wave". It is hidden in a wave, on the end screen, during the modifier pick and in Training (`ui_design.md` §1; `WaveRunner.next_ids()`).

**The death recap.** On DEFEATED, GAME OVER and RUN OVER, a block **WHAT HIT YOU** names the enemy that struck the last blow, the three sources that did the most damage as shares, one tip for the top source and, when the save can buy a node, "You can afford an upgrade in the Evolution Tree." (`DeathRecap`, `StageStats.record_hit`; the tip table is in `ui_design.md` §1).

**Summon totals.** The Maiden of the Mist calls 12 ghouls and the Broodmother 10 spiderlings in all (see "Summons" above).

---

## 4. Stats & Leveling

**Stats (like LoL):** AD, AP, Attack Speed, Crit Chance, Armor, Magic Resist, HP, Mana, Lifesteal, Omnivamp, Ability Haste, Move Speed, Armor Penetration, Magic Penetration, Heal & Shield Power, Tenacity.

*Lethality is not used (no item gives it).*

- **Base stats:** based on Lucian in LoL as a starting point, then adjusted (about 70–80% similar).
- **Damage formulas:** based on LoL's Armor / MR formulas *(proposed)*.
- **Levels:** 1 → 18 within each stage. Gain XP by killing enemies. *(V1.3: a story stage starts at its act's level, §3; the next level needs 100 + 60 × level XP, was 180 + 100 × level.)*
- Each level gives **bonus stats** and **1 skill point**.

---

## 5. Lucian's Skills

| Skill | Effect |
|---|---|
| **Passive – Lightslinger** | After using a skill, the next attack shoots twice. Lucian's shots (basic attacks, this second shot, R's bullets) take turns between his guns, left first. *(V1.4.3: if the next double-shot attack comes while the last second shot is still waiting to fire, that shot fires at once, so neither is lost.)* |
| **Q – Piercing Light** | Laser through a target, hitting every enemy in a line. |
| **W – Ardent Blaze** | Missile that explodes in a cross and marks enemies (magic damage, AP scaling). Hitting a marked enemy gives movement speed. |
| **E – Relentless Pursuit** | Short dash toward the cursor (up to 280, as far as the cursor). Passive hits lower its cooldown. |
| **R – The Culling** | Fires a stream of bullets in one direction while Lucian can move. |

**Story start:**
- In Act 1, Lucian has **only one gun** (his body art shows one pistol).
- At Act 1's first break, Senna **teaches him E**: he can use it (rank 1) for the rest of the stage.
- After Senna is killed, Lucian takes up her gun (two guns from then on).
- Clearing Act 1 puts **E at level 1** in the Evolution Tree for free, and opens **Q and W** there. Until then Q and W are locked.

**How skills work:**
- Skill ranks must first be **bought in the Evolution Tree**.
- In a stage, skill points can only be spent on ranks that have been bought.
- Skill points that can't be spent are **wasted** (they are not saved or converted).
- R can only be ranked at **level 6, 11 and 16**, like LoL.
- Q / W / E rank *r* needs level 2*r* − 1 (rank 2 at level 3, rank 3 at 5, rank 4 at 7, rank 5 at 9), like LoL.
- Q / W / E have 5 ranks. R has 3 ranks.
- Normal ranks add damage and lower cooldown.

**Max rank bonuses:**

| Skill | Bonus |
|---|---|
| Q (rank 5) | Laser becomes wider and longer |
| W (rank 5) | Bigger explosion area |
| E (rank 5) | A kill lowers E cooldown by 1 second |
| R (rank 3) | Bullets pierce; damage drops 15% per enemy hit, minimum 30% |

---

## 6. Items

### Backpack & equipment
- **Backpack:** 49 slots (7 × 7). *(Since Phase 10: 54 cells (9 × 6), and only 5 are open at the start. The Evolution Tree's Backpack Slots opens the rest (§11).)*
- **Equip slots:** start with 1, unlock up to 6 in the Evolution Tree. *(Since Phase 10, slots 3–4 need Act 2 cleared and slots 5–6 need Act 4 (§11).)*
- **Full backpack (V1.4.2):** a fragment or legendary that finds the backpack full goes to an **empty, unlocked equip slot** that takes it, and applies its stats at once. Shop buys and loot pickup both do this. The backpack comes first, and potions never go to equip slots. *(Removed in V1.5.0: buys and pickups go only into the backpack, and a potion into its potion cell. With the backpack full, a buy is declined with "Your backpack is full.", unless the item is dragged onto a free equip slot, and loot stays on the ground with "Backpack full".)*
- **One penetration item (V1.5.0):** only one of Lord Dominik's Regards, Mortal Reminder and Void Staff can be equipped at a time. A move, swap, buy or craft that would equip a second one is refused, with a pop-up naming the one equipped (`items.md`). Shadowflame now gives 15 flat magic penetration (was 10%), so it isn't one of them.
- **Potion cells** *(since V1.4)*: one for Health potions on key 7 and one for Mana potions on key 8, never locked, 9 each. Bought potions fill them first; the player refills them by hand. Potions can't go in equip slots.
- **Boots cell** *(since V1.4)*: the boots bought in the Evolution Tree, worn on every map. They give stats and passives, have no key and never leave the cell. The merchant's Boots tab (the Craft tab since V1.4.1) upgrades them with a fragment and a gold fee (`items.md`, Boots).
- Items can be **sold** to the merchant for **70%** of their buy price (**Guardian Angel: 40%**). Legendary items **cannot be broken** back into fragments. **Undo sale** (V1.4.2): the merchant buys back your sales, last first, for the gold you got, until you leave him.
- **Crafting:** ~~drag one fragment onto another that forms a recipe and hold for a short time~~. Since V1.4.1, only at the merchant's **Craft** tab: two fragments and a fee of the legendary's cost minus the fragments' costs, so crafting then selling never makes gold (see `ui_design.md` §3 and `items.md`). *(V1.4.3: an item in a Craft input leaves the backpack view until it comes back, Craft asks "Craft X from Y and Z for N gold?" first, and a craft empties both inputs.)* *(V1.5.0: the fragments cost 650–1100 (were 400–1300), so the fees run 900–1600 (were 800–2100). The legendaries' prices are unchanged.)*
- **Shared item cooldowns:** every copy of the same item shares **one cooldown** (e.g. all Galeforces, all Guardian Angels). Selling an item on cooldown and getting another copy does **not** reset it.
- **Duplicates allowed.** Stats stack, but each **unique effect only counts once**.
- **Energized attacks** work like LoL (moving and attacking build stacks; at 100 the next attack is energized).
- A **crafting recipe table** is shown in game so players can plan builds (beside the backpack, and since V1.4.1 at the merchant too).
- Stats, costs and passive / active text of every item: `items.md`.

### Sources
- Enemies drop **fragments**, and very rarely a **legendary item**.
- The merchant sells fragments and, at a lower chance, legendary items.

### Fragments (8)
| Code | Fragment | Stat |
|---|---|---|
| AD | B.F. Sword | Attack Damage |
| AS | Recurve Bow | Attack Speed |
| AP | Needlessly Large Rod | Ability Power |
| AR | Chain Vest | Armor |
| CR | Cloak of Agility | Crit Chance |
| HP | Giant's Belt | Health |
| MP | Tear of the Goddess | Mana |
| MR | Negatron Cloak | Magic Resist |

### Recipes
Only these pairs combine. **Stats and unique passives/actives are based on LoL** and adapted to this game (about 70–80% similar).

| Recipe | Legendary |
|---|---|
| AD + AD | Infinity Edge |
| AD + AP | Hextech Gunblade |
| AD + AS | Kraken Slayer |
| AD + AR | Mortal Reminder |
| AD + CR | Stormrazor |
| AD + HP | Black Cleaver |
| AD + MP | Spear of Shojin |
| AD + MR | Bloodthirster |
| AS + AP | Statikk Shiv |
| AS + AR | Lord Dominik's Regards |
| AS + AS | Runaan's Hurricane |
| AS + CR | Navori Flickerblade |
| AS + HP | Nashor's Tooth |
| AS + MP | Void Staff |
| AP + AP | Rabadon's Deathcap |
| AP + AR | Malignance |
| AP + CR | Shadowflame |
| AP + HP | Morellonomicon |
| AP + MP | Archangel's Staff |
| AP + MR | Banshee's Veil |
| AR + AR | Thornmail |
| AR + CR | Immortal Shieldbow |
| AR + HP | Death's Dance |
| AR + MP | Fimbulwinter |
| AR + MR | Guardian Angel |
| CR + CR | Rapid Firecannon |
| CR + HP | Galeforce |
| CR + MP | Essence Reaver |
| HP + MP | Hextech Rocketbelt |
| HP + MR | Spirit Visage |
| MP + MP | Muramana |
| MP + MR | Jak'Sho, The Protean |
| MR + MR | Kaenic Rookern |

**33 of 36 pairs used.** Still free (left for later): **AS + MR**, **CR + MR**, **HP + HP**.

---

## 7. Merchant

- Appears on the map during the **20-second break between waves**, and disappears when the break ends or is skipped.
- Opening the shop **pauses the game**.
- Has **2 shops** (tabs):

### Items shop
- Sells **2 items** (upgradeable to 4 in the Evolution Tree). Locked slots are shown with a chain. *(V1.4.3: right-clicking one says "That slot is locked", not "Already sold"; hovering it says "Buy Merchant Stock in the Evolution Tree".)*
- Sells fragments and, at a lower chance, legendary items.
- **Refresh** costs stage gold.
- A slot that was bought from **stays empty** for that merchant visit, even after a refresh. Only unbought slots get new items.

### Potions shop
- Sells **HP potions** and **MP potions** for stage gold.
- Potions stack up to **9** per slot.

### Potions
- **HP potion** restores HP, **MP potion** restores mana, **gradually** over a few seconds (not instantly).
  - Placeholders: Health Potion 200 HP over 5 s, Mana Potion 150 mana over 5 s, 50 gold each.
- Use: keys 7 and 8 (V1.4.1; the backpack's Use button is gone). A potion in an equip slot also works with that slot's key.
- Works during waves and during the break.
- Does **not** heal while the game is paused (backpack, shop or menu open).
- Like all items, potions are lost when the stage ends.

---

## 8. Summoner Spells

| Spell | Effect |
|---|---|
| Flash | Instant short blink toward the mouse |
| Ghost | Big move speed for a few seconds, pass through enemies |
| Heal | Restore HP and gain a short burst of move speed |
| Barrier | Shield that absorbs damage for a short time |
| Smite | True damage to one enemy, and heals Lucian if it kills. No bonus vs elites or bosses. Killing an elite with Smite raises its orange essence drop chance (×3, since V1.5.0). |
| Clarity | Restore a large amount of mana |

- Cooldowns: **30–90 seconds**. They do **not** reset between waves.
- **1st slot is free**, the **2nd slot** is bought in the Evolution Tree.
- **Every spell must be bought** in the Evolution Tree.
- Upgrades: shorter cooldown, more heal, more mana, more damage, bigger shield.

### Built in Phase 4

Placeholder numbers. Ability haste doesn't shorten them, and each spell keeps its own cooldown, also when moved to the other key.

| Spell | Cooldown | Effect |
|---|---|---|
| Flash | 90 s | Blink up to 400 toward the cursor. If that spot is inside a wall or an enemy, land just short of it (so Flash can cross them). A blink leaves no trail: yellow sparks ring the spot Lucian left. Like a dash, it drops a move ordered before it. |
| Ghost | 60 s | +40% move speed and pass through enemies for 6 s. Pale afterimages trail behind Lucian as he runs. |
| Barrier | 60 s | Shield of 95 + 18 × level for 2.5 s; heal and shield power makes it stronger. A golden bubble shows around Lucian while it lasts. |
| Heal | 60 s | Heal 80 + 15 × level, +30% move speed fading over 1 s. A green ring spreads out and crosses rise around Lucian. |
| Clarity | 45 s | Restore 50% of max mana. Blue motes spiral into Lucian. |
| Smite | 30 s | 450 true damage to the enemy under the cursor (walking into reach), else the one nearest the cursor within 500. If it kills, heal 2.5% of max HP, and an elite it kills has 3× the orange chance (§9). *(Since V1.5.0. Before, it healed 10% of max HP on every cast.)* |

### Built in Phase 5
- **Every spell is bought in the Evolution Tree** (its own node, 150B). A new game has none.
- **D is open from the start. F is chained** until the **Second Summoner Slot** node is bought (400B + 5O, needs any 2 spells).
- **D and F are picked in Journey's loadout panel**, among the bought spells (or None). Picking the spell already on the other key swaps them. The pick is saved with the progress.
- **Upgrades:** one node per spell, 3 levels, bought after the spell:

| Spell | Per level | At level 3 |
|---|---|---|
| Flash | −10% cooldown | 63 s |
| Ghost | −10% cooldown | 42 s |
| Barrier | +15% shield | ×1.45 |
| Heal | +15% healing | ×1.45 |
| Clarity | +15% mana restored | ×1.45 |
| Smite | +15% damage (not its heal) | ×1.45 |

- An upgraded spell's card adds a green line: "Upgraded: 30% shorter cooldown" or "Upgraded: 45% stronger".
- On the HUD, an empty D shows only its frame, and a locked F shows a chain; each has a hover card saying why.
- `stage.tscn` run on its own (F6, tests) keeps the Phase 4 sandbox: both slots open, Flash on D and Heal on F, swapped in the debug table (which now also offers None).

---

## 9. Currencies

| Currency | Source | Use | Resets? |
|---|---|---|---|
| **Stage gold** | Enemies | Merchant, refresh | Yes, every stage |
| **Blue essence** | All enemies | Evolution Tree | No |
| **Orange essence** | Rare from enemies, more from elites | Evolution Tree (better upgrades need blue + orange) | No |
| **Purple essence** | Mini bosses and bosses | Skins, Evolution Tree reset | No |

### Drop rates (placeholder)

| Source | Blue | Orange | Purple (first kill / repeat) |
|---|---|---|---|
| Normal enemy | = act number (Act 1 = 1 … Act 6 = 6) | 1% chance of 1, × (1 + 0.2 · (act − 1)) | — |
| Elite | 5× normal | 10% chance of 1, × (1 + 0.2 · (act − 1)); × 3 when Smite kills it | — |
| Rift Scuttler (elite) | High | High (escapes if not killed quickly) | — |
| Mini boss | 50 | 3 | 5 / 1 |
| Act boss (Acts 1–5) | 100 | 5 | 10 / 2 |
| Thresh (final) | 100 | 5 | 20 / 4 |

Act 1's Thresh appears only on the first clear, so he gives no repeat purple.

*(V1.5.0: the orange chance of normal and elite kills grows with the act: ×1.0 in Act 1, ×1.2 in Act 2, up to ×2.0 in Act 6, so a normal kill in Act 6 has 2% and an elite 20%. Endless uses the act its kills pay as (§14). An elite killed by Smite has 3× its chance. Hard and Extreme raise both the chance and the sure orange (§17).)*

**First-time purple total:** 100 (6 mini bosses × 5 + 5 act bosses × 10 + final Thresh × 20).

### Built in Phase 6
Every kill pays out at once, Senna's kills too:
- **Stage gold and XP:** the enemy's own amounts (in the act files), × (1 + 0.25 · (act − 1)). *(V1.5.0: a stage can also raise some enemies' gold, `WavePlan.GOLD_SHARES`. In 3-1 to 3-5, Act 3's normal and elite monsters pay ×1.7 gold, so an Act 3 stage pays about 6.4k gold on average (was 3.9k; Act 2 3.0k, Act 4 10.6k), and 3-1's first break about 675. XP, Endless and the other acts are unchanged.)*
- **Blue and orange:** as in the table above. A boss gives 100 blue and 5 orange.
- **Purple:** only from bosses, through the save's list of bosses already beaten (`"bosses"`, §15): the first-time amount once, the repeat amount after.
- **Essences go into the save as they drop.** Leaving the stage, dying, or a Yes to "Save before leaving?" keeps them; a No loses them. They rise over the kill as "+1" with their icon, and the HUD counts them next to the stage gold.

**The Evolution Tree's economy nodes** (§11) raise them, +10% per level:

| Node | Raises |
|---|---|
| Stage Gold | Gold per kill |
| Bonus XP | XP per kill |
| Essence Drops | Blue per kill (rounded), and the chance of orange |

**Item loot:** a kill can drop an item on the ground, where the enemy died.

| Enemy | Drop |
|---|---|
| Normal | 0.3% a legendary; else 4% a fragment |
| Elite | 3% a legendary; else 25% a fragment |
| Boss | A fragment for sure, plus 15% a legendary |

- The kill that ends a stage (the boss, or the last enemy of the last wave) drops nothing: the result comes up at once, and items don't carry over. The boss row waits for Endless. *(Phase 9: Endless uses it, since every Endless kill drops loot; see §14.)*
- Loot stays until the stage ends. It shows as the item's icon over a bobbing glow (gold for a legendary).
- Lucian picks it up by walking within 60 of it, into the backpack.
- With no room it stays, and "Backpack full" shows at most once every 3 s.

### Built in Phase 7
- **Blue per kill:** 3 in Act 3 and 4 in Act 4 (elites 15 and 20), as the table says.
- **Mini bosses** (the Infernal and Ocean Drakes) pay on the kill: 300 gold, **50 blue, 3 orange**, and **5 purple the first time, 1 after**. The purple rises over Lucian and adds a line to the end screen ("+5 purple essence (Infernal Drake, first kill)", or "repeat"). They are in the save's `"bosses"` list with the bosses.
- **Rift Scuttler:** caught, it pays an elite's rewards plus **45 blue** (raised by Essence Drops like all blue) and **4 orange** for sure. After 15 s alive it escapes with nothing: no gold, no XP, no essence, and not a kill.
- **Jungle buffs:** the Blue Sentinel and the Red Brambleback leave Lucian their buff (60 s) when they die (`act3_the_jungle.md`).
- **Item loot**, the mini-boss row:

| Enemy | Drop |
|---|---|
| Mini boss | A fragment for sure, plus 8% a legendary |

- As before, the kill that ends the stage drops nothing.

### Built in Phase 8
- **Blue per kill:** 5 in Act 5 and 6 in Act 6 (elites 25 and 30), as the table says.
- **Summons pay 25% of their gold and XP, and no blue, no orange and no loot** (so they can't be farmed). The ghouls, the Broodmother's spiderlings and Thresh's Lantern Souls are summons when a summoner calls them; a Lantern Soul that comes from a wave pays in full.
- **Vanished enemies pay nothing** (a sapling that explodes, Thresh's souls at his fall).
- **Mini bosses and bosses of Acts 5–6** (all in the save's `"bosses"` list):

| Boss | Where | Gold | Blue | Orange | Purple (first / repeat) |
|---|---|---|---|---|---|
| Maokai (mini boss) | 5-2 | 300 | 50 | 3 | 5 / 1 |
| Elise (mini boss) | 5-4 | 300 | 50 | 3 | 5 / 1 |
| Karthus (boss) | 5-5 | 300 | 100 | 5 | 10 / 2 |
| Karthus, revived (mini boss) | 6-2 | 300 | 50 | 3 | 5 / 1 |
| Hecarim (mini boss) | 6-4 | 300 | 50 | 3 | 5 / 1 |
| Thresh (boss) | 6-5 | — (his fall pays essences only, as in Act 1) | 100 | 5 | 20 / 4 |

- A mini boss's purple is paid on the kill; a boss's at the stage's clear. Thresh's blue and orange are paid where he fell, as his fall ends the fight; his clear adds "Senna is free" and, the first time, "The story is complete".
- Mini bosses drop a fragment for sure plus 8% a legendary. The kill that ends the stage (Thresh's fall) drops nothing.

---

## 10. Skins

Skins can only be changed **outside stages**.

| Skin | Cost (purple) | Bonus | Weakness | Playstyle |
|---|---|---|---|---|
| Classic | Free | — | — | Balanced |
| High Noon | 25 | +15% AD | −15% Attack Speed | Slow, heavy shots |
| PROJECT | 30 | +20% Attack Speed, +8% Move Speed | −10% AD | Fast, always moving, faster energized stacks |
| Pulsefire | 20 | +30% W Damage, +25 Ability Haste | −10% Attack Speed | Skill-focused, W and R as main damage |
| Vampire *(custom)* | 25 | +15% Lifesteal, kills heal 2% max HP | −20% max HP | Risky but sustainable |

*(V1.5.0: PROJECT's move speed is +8% (was +15%). Pulsefire gives +30% W damage and +25 ability haste (was +15% AP and +15 ability haste); its −10% attack speed stays. The W bonus multiplies Ardent Blaze's cross damage.)*

**Built in Phase 5:**
- Bought and equipped in the Skin Shop (`main_screen.md`). Lucian's body sprite and the HUD portrait follow the equipped skin.
- Attack speed, move speed, ability haste and lifesteal are added like item stats. The AD, AP and max HP percentages multiply the final stats, after item passives.
- Vampire's kill heal works on real kills; training dummies never die, so only the tests show it for now.

**Built in Phase 10: Lucian's second gun is Senna's.** On all five bodies, the left-hand gun stays his own slim pistol. The right-hand gun is that skin's take on Senna's relic gun: a chunkier, darker body with a heavy stock, two glowing ring bands, a muzzle cap and a muzzle light in the ring colour. The muzzles didn't move, so the shots leave from the same points. The one-gun body of Act 1's first play is unchanged.

| Skin | Lucian's gun | Senna's gun |
|---|---|---|
| Classic | Slim silver-gold | Gunmetal, teal rings |
| High Noon | Bronze revolver | Dark iron, ember-orange rings |
| PROJECT | Chrome | Boxy gunmetal with a dim neon rim, cyan rings |
| Pulsefire | White | Blue and white, pale blue rings, a glowing core between them |
| Vampire | Silver with a red gem | Black iron with a crimson rim, crimson rings |

**Built in V1.1: skin effects.** Each skin has its own look and sounds for Q, W, E, R, basic attacks and the muzzle flash. Classic keeps 1.0's. Hitboxes, damage and timing don't change.

| | **High Noon**: hellfire gunslinger | **PROJECT**: hologram | **Pulsefire**: time rift | **Vampire**: blood |
|---|---|---|---|---|
| **Palette** | Ember orange `#ff6a2a`, deep red `#c8300a`, hot white `#fff6e0`, smoke grey | Cyan `#38e8ff`, pale cyan `#7ff4ff`, gunmetal `#1c2029`, magenta for glitches | White core `#f4f8ff`, pale blue `#7fd8ff`, deep blue `#4a5cff` | Crimson `#d01830`, bright red `#ff3a50`, black red `#4a0812` |
| **Q beam** | Red edges, an orange core and a white-hot centre. Embers drift off and a smoke puff hangs at the muzzle. | Bright cyan edge lines over a see-through fill, with scan lines sweeping along. It breaks into pixels instead of fading. | A white core with blue edges. Rings ripple down the beam and a clock-face ring shows at the muzzle. | Black-red edges and a crimson core. Drops spray off and fall, and it drains away from Lucian's end outward. |
| **W missile** | A molten slug with a smoke tail | A spinning diamond "data packet" | An orb with two orbiting rings | A blood orb with a dripping tail |
| **W cross** | Burning arms, a charred ring under it, embers flying out along the 4 arms | Built from grid squares that light up from the centre outward, then flicker off | Comes with a shockwave ring and a ticking clock flash at the centre | A blood splash, with four small bats flying out along the arms |
| **E dash** | A fire streak along the ground and dust kicked up where he started | A glitch: 3 offset copies of Lucian split cyan/magenta, with broken scan-line pieces | 3-4 fading blue afterimages of Lucian's body, with a ring at both ends | A red mist trail with 5-6 bats flapping along it |
| **R bullets** | Heavy orange tracers | Thin cyan laser bolts | Pale blue pulse bolts with a small ring at the tip | Crimson bullets with a dark drip streak |
| **Basic attack** | Orange tracer | Cyan bolt | Pale blue pulse with a tiny ring | Crimson bullet |
| **Muzzle flash** | Star-shaped, with sparks | Square, with hex sparks | A small blue ring | Red |

Rules for every skin:
- **The main shapes match the hitboxes.** Q's beam is drawn `length x width` and W's cross arms are drawn `bar` size. Small details may reach a little past the edge.
- **The main shapes last as long as Classic's:** Q's beam 0.25 s, W's cross 0.35 s, the muzzle flash 0.08 s, and the dash trail fades in 0.3 s.
- **Details stay at most 0.6 s** (embers, drops, bats, afterimages, rings), at low alpha.
- **Low effects:** only the main shapes, in the skin's colours: the beam, the missile, the cross and the bullets. No particles, rings, bats, afterimages, scan lines or pixel break-up. The muzzle flash and the dash trail are off, as in 1.0.
- **Others keep their looks:** Senna's shots, item effects (Galeforce, Rocketbelt, Runaan's), Dark Lucian's Q and trail, and the Act 1 E-lesson trail.

Sounds are synthesized, four per themed skin (`cast_q_<skin>`, `cast_w_<skin>`, `cast_e_<skin>`, `shot_<skin>`). The shot sound plays for basic attacks, Lightslinger's second shot and every R bullet. Each is as loud as the Classic sound it replaces.

| | Q | W | E | Shot |
|---|---|---|---|---|
| **High Noon** | A roaring fire crackle, noisy and falling | A whoosh and a heavy thump | A dusty whoosh and a two-note spur jingle | A low revolver crack |
| **PROJECT** | A square-wave synth laser with a fast flutter | A quick rising bleep and a pop | A stuttering glitch chirp | A short square blip |
| **Pulsefire** | A shimmering sweep that rises then falls | A deep "whomp" with a bell ring | A rising "rewind" whoosh | A soft high pulse with a flutter |
| **Vampire** | A low, wet, falling zap | A low splash thump | Three quick wing flaps | A muffled low crack |

The Skin Shop's Preview button plays these before you buy (`main_screen.md`, Section 2).

---

## 11. Evolution Tree

A node opens once **all of its requirements** are bought (or any 1 / any 2 of them, where the table says so). B = blue essence, O = orange essence.

**Reset:** costs **5 purple** and refunds all blue and orange essence.

**Nodes have levels** (built in Phase 5; 31 nodes, laid out in `main_screen.md`). *(34 since Phase 10: Health Regen, Mana Regen and Backpack Slots are new. 35 since V1.4: Boots.)*
- Q, W and E are one node each with 5 levels, R one node with 3. Equip slots are one node with 5 levels (slots 2–6), Merchant stock one node with 2 (3 and 4 items). Each level costs what the tables below say for that rank, slot or step.
- A node opens once its requirements have level 1; its later levels need nothing more. *(Since Phase 10 a level can have rules of its own: R's ranks need 5, 9 and 13 levels in Q + W + E, and equip slots 3–4 and 5–6 need Act 2 and Act 4 cleared. A level opens only when all of its rules are met.)*
- **Q, W and E** stay hidden until Act 1 is cleared. Clearing it puts **E at level 1** for free (Senna taught it). A reset takes it back like any level, and it is free to buy again.
- In a stage, skill points only go into bought ranks, and the passive only works once bought.

### Skills
| Node | Cost | Requires |
|---|---|---|
| Q / W rank 1 | 100B each | Clear Act 1 |
| E rank 1 | Free, given when Act 1 is cleared | Clear Act 1 |
| Passive | 150B | Any 1 of Q, W, E rank 1 |
| R rank 1 | Free, claimed in the tree | Clear Act 2, the passive, and 5 levels in Q + W + E |
| Q / W / E rank 2 | 150B | Previous rank |
| Q / W / E rank 3 | 250B | Previous rank |
| Q / W / E rank 4 | 500B + 5O | Previous rank |
| Q / W / E rank 5 | 800B + 10O | Previous rank |
| R rank 2 | 1200B + 20O | R rank 1, and 9 levels in Q + W + E |
| R rank 3 | 2000B + 30O | R rank 2, and 13 levels in Q + W + E |

*(Since Phase 10. Before, R rank 1 needed Q, W and E each at rank 1 plus the passive, and ranks 2–3 only the rank before. Q + W + E is the sum of the three ranks bought, 15 at most: Q 4 + E 1 opens R once the passive is bought.)*

*(V1.5.0: Q, W and E ranks 2 and 3 cost 150B and 250B (were 200B and 350B). R's rank 1 costs nothing (was 600B + 10O) and opens only once Act 2 is cleared, on top of its old rules, so it is a free claim like Ghost, with a FREE badge. It isn't given: the player clicks it. A save that already bought it keeps it, and a tree reset refunds at today's prices, so a rank 1 bought for 600B + 10O gives nothing back.)*

### Backpack
*(Called Equipment before Phase 10.)*

| Node | Cost | Requires |
|---|---|---|
| Equip slot 2 | 150B | — |
| Equip slot 3 | 300B | Clear Act 2 |
| Equip slot 4 | 600B + 5O | Clear Act 2 |
| Equip slot 5 | 1000B + 15O | Clear Act 4 |
| Equip slot 6 | 1500B + 30O | Clear Act 4 |

*(The act rules since Phase 10.)*

**Boots** (since V1.4): two levels, bought once and kept forever. Lucian starts every map in them (story stages, the tutorial, Training, Endless). The node must never cost nothing: the FREE badge tests count on it.

| Level | Boots | Cost |
|---|---|---|
| 1 | Boots of Speed (+25 move speed) | 300B |
| 2 | Slightly Magical Boots (+25 move speed, +10 kept through every upgrade) | 800B + 10O |

**Backpack Slots** (since Phase 10): the backpack has 54 cells, and a new game opens 5. Each level opens more. The equip slots don't count. No act rule.

| Level | Open cells | Added | Cost |
|---|---|---|---|
| 0 (start) | 5 | — | — |
| 1 | 10 | +5 | 50B |
| 2 | 16 | +6 | 100B |
| 3 | 22 | +6 | 200B |
| 4 | 29 | +7 | 350B + 3O |
| 5 | 37 | +8 | 740B + 4O |
| 6 | 45 | +8 | 1280B + 7O |
| 7 | 54 | +9 | 2000B + 12O |

*(V1.5.0: levels 5–7 cost less orange and more blue, about 60 blue for each orange taken off. They were 500B + 8O, 800B + 15O and 1200B + 25O.)*

### Stats
AD, AP, HP, Armor, MR, Attack Speed, Mana, Health Regen, Mana Regen — 5 levels each. *(The two regen nodes since Phase 10.)*
Costs: 50B → 100B → 200B → 350B + 3O → 500B + 8O.

| Stat | Per level | At level 5 |
|---|---|---|
| AD | +4 | +20 |
| AP | +8 | +40 |
| HP | +40 | +200 |
| Armor | +4 | +20 |
| MR | +4 | +20 |
| Attack Speed | +3% | +15% |
| Mana | +40 | +200 |
| Health Regen | +0.5/s | +2.5/s |
| Mana Regen | +0.6/s | +3/s |

They count as **bonus** stats (yellow in the stats panel) from the start of every stage. The regen bonuses show in the "+x/s" on the HUD's health and mana bars.

### Summoners
| Node | Cost | Requires |
|---|---|---|
| Unlock Flash, Barrier, Heal, Clarity or Smite | 150B | — |
| Unlock Ghost | Free, claimed in the tree | Clear Act 1 (stage 1-1) |
| 2nd summoner slot | 400B + 5O | 2 spells unlocked |
| Spell upgrades (3 levels each) | 150B → 300B → 400B + 5O | That spell unlocked |

*(Ghost since Phase 10. Before, it cost 150B with no requirement. It is not given automatically, unlike E: the player clicks it in the tree, where a FREE badge points to it.)*

### Economy
| Node | Cost |
|---|---|
| Stage gold +10% (3 levels) | 100B → 250B → 500B + 5O |
| Bonus XP +10% (3 levels) | 100B → 250B → 500B + 5O |
| Essence drop rate +10% (3 levels) | 100B → 250B → 500B + 5O |
| Merchant 3 items | 300B |
| Merchant 4 items | 800B + 10O |
| Refresh cost −25 gold (2 levels: 100 → 75 → 50 gold) | 200B → 500B + 5O |

Stage gold, bonus XP and essence drops work since Phase 6: +10% gold, XP or blue per kill for each level, and the essence node also raises the chance of orange (§9).

**Balance goal:** in 5–7 hours a skilled player can afford all skills, R, 4–5 equip slots and some stats, but not the full tree. The rest is a goal for Endless mode. *(V2.0: the story takes a skilled player about 4–5 hours (§1).)*

### Built in Phase 10
- **Rules per level.** A level opens when enough acts are cleared, the node's requirements have level 1, and the node's level sum is high enough. The act needed is the larger of the node's act and the level's own act. R's level sum is Q + W + E (5, 9, 13).
- **What a level still needs** shows in red in the tree's info column. Only what is missing is listed:

| Case | Text |
|---|---|
| R on a new save | "Requires: Passive – Lightslinger and Clear Act 2 and 5 levels in Q + W + E (now 0)" *(V1.5.0; "Clear Act 2" is new)* |
| R at rank 1 | "Requires: 9 levels in Q + W + E (now 7)" |
| Equip Slots at level 1 | "Requires: Clear Act 2" |
| Ghost before 1-1 | "Requires: Clear Act 1" |

- **Free upgrades** are levels whose rules are met and that cost nothing. After 1-1 that is Ghost (E's first level is still put in the tree for free, as before). After a reset it is E and Ghost. A FREE badge marks them on the main screen (`main_screen.md`). *(V1.5.0: also R's rank 1, once Act 2 is cleared, the passive is bought and Q + W + E reach 5.)*
- **Old saves keep their levels**, even above the new rules: an R at rank 2 with fewer than 13 Q + W + E levels, or equip slots past the acts cleared. Such a node shows as bought, with a small lock, and its next level reads LOCKED. A reset refunds from today's tables, so a Ghost bought for 150B gives back nothing. *(V1.5.0: nor does an R rank 1 bought for 600B + 10O, and Q, W and E ranks 2 and 3 give back 150B and 250B, whatever they cost.)*
- **Backpack Slots** sets how many backpack cells are open in a stage: 5 on a new save, 16 after two levels. Items only go into open cells. With them full, loot stays on the ground ("Backpack full"). A locked cell shows a chain; hovering it says "Buy Backpack Slots in the Evolution Tree". A stage run on its own opens all 54, and the stage debug table has a "Backpack slots" spinner (`ui_design.md` §2).
- **Health Regen and Mana Regen** add to Lucian's regen per second from the start of every stage.
- **Boots** put Boots of Speed (level 1) or Slightly Magical Boots (level 2) in the boots cell at the start of every stage. The node sits on the Backpack page's trunk, between the Equip Slots and Backpack plaques, with a plaque of its own.
- **35 nodes, 116 levels:**

| Branch | Nodes | Levels |
|---|---|---|
| Skills | 5 | 19 |
| Stats | 9 | 45 |
| Backpack | 3 | 14 |
| Economy | 5 | 13 |
| Summoners | 13 | 25 |

- **The numbers are placeholders.** The R sums, the act rules, the Backpack Slots table and the regen per level are from the Phase 10 plan, not from play.

---

## 12. Story & Acts

**22 stages total.**

| Act | Name | Stages | Enemies | Elites | Mini bosses | Boss |
|---|---|---|---|---|---|---|
| 1 | The Loss | 1 | Melee & ranged minions | Siege minions | — | Thresh (scripted) |
| 2 | The Sentinels | 3 | Melee & ranged minions | Siege & super minions | — | Akshan (weakened) |
| 3 | The Jungle | 5 | Raptors, Krugs, Murkwolves (packs), Gromp (alone) | Blue Sentinel, Red Brambleback, Rift Scuttler | Infernal Drake (stage 2), Ocean Drake (stage 4) | Elder Dragon |
| 4 | The Darkness | 3 | Shadow minions (melee & ranged) | Shadow siege & super minions | — | Dark Lucian |
| 5 | Shadow Isles | 5 | Maokai's saplings, Elise's spiderlings | Maiden of the Mist, Broodmother | Maokai (stage 2), Elise (stage 4) | Karthus |
| 6 | The Lantern | 5 | Mist Walkers, Lantern Souls | Spectral Riders, Chain Wardens | Karthus – revived (stage 2), Hecarim (stage 4) | Thresh (2 phases) |

**Built so far:** Acts 1–2 (Phase 6), Acts 3–4 (Phase 7) and Acts 5–6 (Phase 8) can be played: **all 22 stages**. Endless plays since Phase 9 (§14).

### Story summary
- **Act 1 – The Loss:** Lucian and Senna fight together until Thresh kills Senna and traps her soul in his lantern.
- **Act 2 – The Sentinels:** Lucian trains with Akshan to prove he's ready to hunt Thresh.
- **Act 3 – The Jungle:** Lucian crosses the jungle, facing the drakes and the Elder Dragon.
- **Act 4 – The Darkness:** Lucian faces his own fear and grief as Dark Lucian.
- **Act 5 – Shadow Isles:** Lucian fights through Maokai, Elise and Karthus.
- **Act 6 – The Lantern:** Lucian defeats Thresh, shoots through the lantern and frees Senna.

### Enemy & boss design files
Detailed enemy, elite, mini boss and boss designs for each act live in separate files:
- `enemies/act1_the_loss.md`
- `enemies/act2_the_sentinels.md`
- `enemies/act3_the_jungle.md`
- `enemies/act4_the_darkness.md`
- `enemies/act5_shadow_isles.md`
- `enemies/act6_the_lantern.md`

---

## 13. Maps

### General rules
- **Size:** about 2–3 screens wide (camera follow and free-cam both matter).
- **One map per act.** Stages in the same act share the map with small changes (spawn points, obstacles, hazards).
- **Spawn points:** fixed places that fit the theme (lane end, jungle camps, mist).
- **Cover:** every map has walls or pillars to dodge behind.
- **No brush** (no bushes to hide in).
- **Merchant:** appears near the center of the map between waves. *(Phase 3: on the training map he stands at the center from the start; the debug table adds or removes him. Phase 6: on the act maps he comes at the start of each break and stands at the map's merchant point.)*

### Maps by act
| Act | Map | Layout |
|---|---|---|
| 1 | Mid lane | Long diagonal lane with the river crossing the middle. Lucian and Senna start bottom-left; minions come from top-right. Few walls. Thresh rises from the river for the boss wave. |
| 2 | Training ground | Open arena with stone pillars (cover from Akshan's Comeuppance). Training dummies as decoration. |
| 3 | Jungle | Narrow paths between walls; monsters come from their camps. Stage 2 adds lava and Blast Cones, stage 4 adds shallow water and Honeyfruit, stage 5 is the Elder Dragon's pit (round arena with walls around the edge). |
| 4 | Dark mid lane | Act 1 layout in dark colors. Normal vision. |
| 5 | Dead forest | Twisted trees as obstacles. Saplings come out of trees, spider nests spawn spiderlings. Karthus fights in a ruined graveyard. |
| 6 | Thresh's domain | Cliffs with chains and narrow paths; Chain Wardens on ledges. Final fight on a round, open platform with no walls. |

### Built in Phase 6
Maps are drawn in code. Walls (jungle, rocks, pillars, the border) block Lucian, enemies and enemy bolts.

| Act | Map | Size | Details |
|---|---|---|---|
| 1 | Mid lane | 5200 × 3200 | A 900-wide diagonal lane, jungle walls on both sides, the river across its middle (walkable), 3 rocks. See `act1_the_loss.md`. |
| 2 | Training ground | 4600 × 2800 | Stone tiles, three gates, 6 decorative dummies by the walls, and 6, 8 or 10 pillars by stage (a ring of 10 in stage 3). See `act2_the_sentinels.md`. |
| — | Training | 4800 × 2700 | The Phase 3 test arena, with its dummy and no waves |

The radar takes the map's shape. Acts 5–6 have no map yet. *(Phase 6 said Acts 3–6; Acts 3 and 4 came in Phase 7, Acts 5 and 6 in Phase 8.)*

### Built in Phase 7
Every map now bakes a navigation mesh from its walls (agent radius 36), so enemies and Lucian walk around them (§3).

| Act | Map | Size | Details |
|---|---|---|---|
| 3, stages 1–4 | Jungle | 5600 × 3600 | Paths 420 wide and round clearings in dense jungle: the pit at the top, the center, the start at the bottom, and a clearing for each camp (raptors and Gromp in the top corners, wolves and Krugs at the side edges, Blue and Red low on each side, the Scuttler on the river). The paths make two loops. A riverbed runs from the pit to the start: dry in 3-1 and 3-3, lava pools and Blast Cones in 3-2, shallow water and Honeyfruit in 3-4. |
| 3, stage 5 | The Elder Dragon's pit | 3600 × 3600 | A round stone floor (r 1650) with rock all round it, 6 rocks for cover, waves from the north, east and west rim. |
| 4 | Dark mid lane | 5200 × 3200 | Act 1's layout in black and purple. Dark Lucian rises from the river. |

No wall polygon has a hole: a hole would collide as solid wall. The jungle keeps each loop's inner jungle as a wall of its own, and the pit's rock is 8 arc pieces. Maps draw under the units, at `StageMap.FLOOR_Z`. Details and terrain numbers are in `act3_the_jungle.md` and `act4_the_darkness.md`.

### Built in Phase 8
| Act | Map | Size | Details |
|---|---|---|---|
| 5 | Dead forest (`DeadForestMap`) | 5400 × 3400 | A dark grey-teal clearing between two ragged walls of black trees. 14, 16, 18, 18 and 10 twisted trees (r 45–90) as cover, 2 to 4 Black Mist banks (r 420–500) that veil enemies, a spider nest in the east from 5-3, Maokai's ring of six trunks in 5-2 and Elise's camp in 5-4. 5-5 keeps its trees west of x 3450 and ends in Karthus's ruined graveyard (flagstones, 8 tombstones, a broken crypt wall). The start is in the west, the merchant at the center, and four spawn points in the tree lines. |
| 6, stages 1–4 | Thresh's domain (`ThreshDomainMap`) | 5600 × 3400 | Three slate plateaus (west, center, east) over an abyss, joined by stone bridges with soul lanterns: 4 × 280 wide in 6-1 and 6-2, 3 × 200 wide in 6-3 and 6-4 (the north-west bridge broken). 11 rock spikes as cover. 2 ledges for Chain Wardens (4 from 6-3). The revived Karthus's altar in 6-2 and Hecarim's east end in 6-4. |
| 6, stage 5 | The final platform | 5600 × 3400 | A round carved disc (r 1400) with a rune ring, no walls, a pale dais at its heart for Thresh, and four bridge stubs; waves come from the north, east and south stubs. |

The abyss is several polygons on its own physics layer (no polygon has a hole). Details and numbers are in `act5_shadow_isles.md` and `act6_the_lantern.md`.

### Built in V2.0
Every map is redrawn with `MapArt` (`src/stage/maps/map_art.gd`), the drawing kit of the maps' `_draw`, and gets slow ambient lights from `MapAmbience` (`map_ambience.gd`). **No wall, path, spawn point or size changed**: only what is drawn. The light comes from the top-left, walls cast soft shadows to the bottom-right, and nothing on the ground is strong enough to hide a unit or a red warning. A map is drawn once; its cost is about 0.2 to 1.2 ms of CPU and 0.1 to 0.3 ms of GPU with 40 enemies in view. The ambience (fireflies, glints, dust) is off on Low quality.

| Act | Map | Look now |
|---|---|---|
| 1 | Mid lane | Cobbled lane, shaded rocks, jungle crowns with highlights, a river with banks and a current. |
| 2 | Training ground | Flagstones, a brass ring with the Sentinels' star, a block wall with braziers, gates with towers, sandstone pillars. |
| — | Training | Slate slabs lit by the lantern's teal light. |
| 3 | Jungle | Worn paths, camp details, a dry riverbed; scorch marks round the lava in 3-2, clear water in 3-4, fireflies. |
| 3 | Dragon's pit | Rings of stone, claw marks on the floor and an elder glow. |
| 4 | Dark mid lane | Act 1's layout in black and violet, with wisps and a haze. |
| 5 | Dead forest | Cold grey-teal earth, black leafless tree lines, gnarled trees, Maokai's ring, the spider nest, Elise's camp. Karthus's graveyard has flagstones and tombstones (`MapArt.limbs`). |
| 6 | Thresh's domain | Slate flagstone plateaus with lit lips and cliff faces over a layered abyss with far chains and souls; stone bridges with lantern light; the altar and Hecarim's camp. |
| 6 | Final platform | Slab courses, 32 glowing runes and a pale dais. |

**Terrain pieces:** Black Mist banks are layered mist with a darker heart and wisps (the drift only with `Juice.on()`). Lava, every burning `HazardZone`, is a dark crust with glowing cracks, a hot core and a slow pulse. Shallow water has deeper steps, ripples and glints. The Blast Cone and the Honeyfruit are drawn in code (`MapArt.leaf`): their SVGs in `assets/art/stage/` are no longer used. Units have shadows and the battlefield has glows, sparks and numbers that pop: `ui_design.md` §1, "On the battlefield".

---

## 14. Endless Mode

- **Unlocks** once **Act 3** is cleared.
- **Map:** random from all acts, or chosen by the player.
- Waves never end; enemies get stronger every wave.
- **Mini boss every 5 waves**, **act boss every 10 waves** (random, stronger than in story).
- Merchant between waves as usual.
- Level cap stays at 18.
- Gives **blue and orange essences** (a farming mode). Bosses and mini bosses give the **repeat** purple amount.
- **Best wave** is saved as a personal record.

### Modifiers
Every 10 waves, the player picks 1 of 3 choices:
- **2 random modifiers** rolled from #1–5.
- **"Nothing"** (#6) is always shown.

A new pick **replaces** the previous modifier (they do not stack).

| # | Downside | Reward |
|---|---|---|
| 1 | Enemies move 20% faster | +30% gold |
| 2 | Elites appear twice as often | ×1.5 orange essence drop rate |
| 3 | −10% max HP | +15% blue essence |
| 4 | −5% AD | +10% gold |
| 5 | Bosses and mini bosses +25% max HP | ×1.5 purple essence |
| 6 | Nothing | Nothing |

### Built in Phase 9
Endless plays. Every number is a placeholder: the constants sit at the top of `src/core/endless_plan.gd` and `endless_modifiers.gd`.

**A run:**
- **Start** from the Journey's Endless portal (`main_screen.md`). It opens once Act 3 is cleared. The side panel picks the map: **Random** or one of six. Random rolls a map at Start, and again on Retry.
- The map changes only the ground. Every map has the same enemies and the same ramp. *(V1.5.0: the enemies come from the acts the save has cleared, whatever the map; see the pools below. The Dead forest's mist banks also heal hurt, veiled normal and elite enemies 1% a second, as in Act 5.)*

| Map choice | Built from | Why |
|---|---|---|
| Mid lane | Act 1, stage 1 | |
| Training ground | Act 2, stage 3 | The ring of 10 pillars |
| Jungle | Act 3, stage 4 | Water and Honeyfruit: sustain for long runs |
| Dark mid lane | Act 4, stage 1 | |
| Dead forest | Act 5, stage 3 | 3 mist banks and the spider nest |
| Thresh's domain | Act 6, stage 1 | 4 wide bridges, 2 ledges |

- The stage is named "Endless · Jungle". It starts like a story stage: empty backpack, level 1, 0 gold, and the tree, skin and spells from the save. Wave 1 comes after 5 s.
- **Waves never end.** Every wave is followed by the 20 s break with the merchant. The level cap stays at 18.
- **A run ends** when Lucian dies (RUN OVER) or the player leaves (Leave this run, or Yes / No when quitting). There is nothing to clear.

**Waves** (w = the wave number):

| Wave | What comes |
|---|---|
| w % 10 = 0 | **One boss, alone**, at the map's boss point. Never the boss of the last boss wave. |
| w % 5 = 0 (not 10) | A normal wave with **a mini boss** as its last enemy. Never the last mini boss. |
| Any other | A normal wave |

- **A normal wave:** min(8 + w, 30) normal enemies of **2 kinds** from the normal pool, then min(w / 4, 4) elites, each drawn from the elite pool (repeats allowed). Modifier #2 doubles the elites, up to 8.
  - A pack counts as its size (raptors 5, Murkwolves 3, Krugs 3) and comes whole. When both kinds are packs, the wave can be up to 2 short of the count; it never goes over it.
- The enemies come as in the story: groups of 3 every 1.2 s from the spawn points. Camp enemies, perched Chain Wardens and the nest fall back to the spawn points on maps that lack them.

| Pool | Enemies |
|---|---|
| Normal (12) | Melee, ranged, shadow melee and shadow ranged minions; Raptors, Murkwolves and Krugs (packs); Gromp; sapling; spiderling; Mist Walker; Lantern Soul |
| Elite (11) | Siege, super, shadow siege and shadow super minions; Blue Sentinel; Red Brambleback; Rift Scuttler; Maiden of the Mist; Broodmother; Spectral Rider; Chain Warden |
| Mini boss (6) | Infernal Drake, Ocean Drake, Maokai, Elise, Karthus (revived), Hecarim |
| Boss (5) | Akshan, Elder Dragon, Dark Lucian, Karthus, Thresh (final). Act 1's Thresh never comes: his fight needs Senna. |

*(V1.5.0: every pool draws only from the acts the save had cleared when the run started, and at least Acts 1–3, since Endless opens after Act 3. Each id's act is the act whose story brings it first (`EndlessPlan.act_of`). With Acts 1–3 that leaves 6 normals (melee and ranged minions, Raptors, Murkwolves, Krugs and Gromp), 5 elites (siege and super minions, Blue, Red and the Scuttler), 2 mini bosses (the Infernal and Ocean Drakes) and 2 bosses (Akshan and the Elder Dragon), which take turns, since neither comes twice in a row. Clearing Act 4 adds the shadow minions and Dark Lucian, and so on.)*

**Strength.** It replaces the act and wave scaling. n = w − 1; k is the boss's tier.

| Who | Formula | Wave 1 | Wave 10 | Wave 20 | Wave 35 | Wave 50 |
|---|---|---|---|---|---|---|
| Normal and elite HP | base × (1 + 0.06n) × (1 + 0.05n) | ×1 | ×2.23 | ×4.17 | ×8.21 | ×13.59 |
| Normal and elite damage | base × (1 + 0.025n) × (1 + 0.05n) | ×1 | ×1.78 | ×2.88 | ×5.0 | ×7.68 |

| Who | Formula | Values |
|---|---|---|
| Boss HP (each phase, for Thresh) | max(15000 × (1 + 0.3(k − 1)), 0.6 × the planned HP of wave w − 1), k = w / 10 | All six acts cleared: wave 10: 15000 · 20: 24,119 · 30: 41,714 · 50: 85,554. Acts 1–3: wave 20: 26,381 |
| Mini boss HP | 9000 × (1 + 0.3(k − 1)), k = (w + 5) / 10 | Wave 5: 9000 · 15: 11700 · 25: 14400 · 45: 19800 |
| Boss and mini boss damage | basic damage and every skill hit × max(1 + 0.15(k − 1), √(damage_scale(w) / damage_scale(f))), f = 10 for a boss, 5 for a mini boss; × 0.8 at tier 1 and × 0.9 at tier 2 for one from Acts 5–6 | Bosses, waves 10–50: ×1.0, ×1.27, ×1.54, ×1.81, ×2.08. Mini bosses, waves 5–45: ×1.0, ×1.32, ×1.63, ×1.95, ×2.26 (before the Acts 5–6 share) |

*(V1.5.0: so the bosses keep up with the waves. Before: boss HP 15000 × (1 + 0.3(k − 1)) (wave 20: 19500, 30: 24000, 50: 33000), and damage × (1 + 0.15(k − 1)) (×1, ×1.15, ×1.3, …). The planned HP of a wave is `EndlessPlan.wave_hp`: its normal and elite counts at their pools' mean HP (the pools of the acts cleared), × the wave's HP scale, before the difficulty and modifier #5. It is the same every run. damage_scale is the normal and elite damage row above, so the first boss and the first mini boss hit ×1.0. The Act 5–6 share softens Karthus, Thresh, Maokai, Elise, Karthus revived and Hecarim at their first two tiers.)*

- Wave 1 is as easy as Act 1. The HP passes Act 6's last story wave (×7.6) at wave 34. *(V2.0: Act 6's last story wave is wave 9, so its scale is ×2.75 × 1.8 = ×4.95. The Endless HP passes it at wave 24: ×4.87 at wave 23, ×5.12 at wave 24. The ×7.6 was already out of date after V1.3.)*
- A boss's HP is fixed by its wave, whoever comes, so the random pick doesn't swing the run. *(V1.5.0: by its wave and the acts cleared.)*
- *(V1.4.2)* An Endless boss's power also reaches the burns it makes: Karthus's Defile, the Infernal Drake's breath and meteor burns, and the on-hit burn of its basic shots are multiplied by the boss's `skill_scale` (×1.3 at tier 3). It is 1.0 for everything else, so the story doesn't change. Other ground hazards are not scaled. *(V1.5.0: `skill_scale` is the power in the table above, Acts 5–6's share included, so ×1.54 at wave 30.)*
- *(V1.4.3)* The on-hit burns of normal and elite enemies (Gromp, the Red Brambleback) grow with their hits too: `burn_scale` = the unit's damage / its `data.damage`, set by `EndlessDirector.scale`. For a boss or mini boss that ratio is its power, the same `skill_scale`, so its burn isn't scaled twice. Story burns are unchanged.
- Bosses come at the boss point, mini bosses from their camp or the spawn points. An Endless boss is never the stage's boss, so its kill ends nothing. Final Thresh still rises into Phase 2 at full HP. His fall in Phase 2 has no cutscene: he leaves, and the run goes on.

**Rewards:**
- **Gold, XP and blue** use the story's rules with the act a = 1 + (w − 1) / 10 (whole numbers): waves 1–10 pay like Act 1, waves 11–20 like Act 2, and so on, with no cap. A normal kill gives a blue, an elite 5a. The orange chances are the story's (1% and 10%). *(V1.5.0: a = max(1 + (w − 1) / 10, the acts the save had cleared when the run started), capped at 6. A save with Act 5 cleared is paid like Act 5 from wave 1. The orange chances are the story's for that act, so they grow with it too (§9).)*
- **Bosses and mini bosses** pay the story's essences (a boss 100 blue and 5 orange, a mini boss 50 and 3), **scaled with the tier** since V1.4.2: the same factor as their HP, 1 + 0.3(k − 1), applied to the base blue and the sure orange and rounded. A boss pays 100 blue and 5 orange at tier 1, **130 and 7** at tier 2, **160 and 8** at tier 3. Gold, XP, loot and the repeat purple stay as they are. They always pay their **repeat purple, on the kill**: 2 for Akshan, the Elder Dragon, Dark Lucian and Karthus, 4 for Thresh, 1 for a mini boss. The save's `"bosses"` list is never touched, and the end screen gets no purple line. *(V1.5.0: the factor is the tier's only, not the HP floor above. Hard and Extreme raise the sure orange too, ×1.2 and ×1.5 (§17).)*
- **Final Thresh's fall counts as a kill:** 300 gold, XP, a loot roll and his 4 purple.
- **Loot drops on every kill,** a boss's too (§9: a fragment for sure, plus 15% a legendary). There is no last kill in Endless.
- The tree's economy nodes work as in the story. A modifier's reward multiplies on top of them.

**Milestones (V1.5.0):** the first time a save wins wave 10, 20, 30 and 40, it is paid once:

| Wave won | Blue | Orange |
|---|---|---|
| 10 | 300 | 5 |
| 20 | 600 | 10 |
| 30 | 900 | 15 |
| 40 | 1,200 | 20 |

- A milestone wave is "won" as the best wave counts it: its break starts. Waves skipped by a debug jump don't count.
- The essence rises over Lucian as a kill's does. A banner under the stage info reads "Wave 10 won for the first time: +300 blue and +5 orange essence", and the same line is on the RUN OVER screen's rewards.
- The amounts are fixed: the tree's Essence Drops, a modifier and the difficulty don't raise them.
- The save keeps the waves already paid (`endless_milestones`, §15). They are written with the run's other essences when the run ends, even when Lucian falls.

**Modifiers** (the table above):
- After each boss wave (10, 20, …) the break **waits**. A **"Choose a modifier"** panel shows **3 cards**: 2 of #1–5 at random (never the current one), then Nothing. The game pauses, the backpack and the menu close, and ESC and P do nothing. A click picks, with the `buff` sound. Then the full 20 s break counts down.
- The pick **replaces** the old modifier; Nothing clears it.

| # | Card (downside / reward) | How it works |
|---|---|---|
| 1 | Enemies move 20% faster / +30% gold | Every enemy's move speed × 1.2 at spawn, summons and splits too. Gold × 1.3. |
| 2 | Elites twice as often / ×1.5 orange drop rate | Elites per wave × 2 (up to 8). The orange chance × 1.5; a boss's sure orange is not. |
| 3 | −10% max HP / +15% blue | Lucian's max HP × 0.9, applied like a skin's scale (his HP share is kept). Blue × 1.15, a boss's too. |
| 4 | −5% AD / +10% gold | Lucian's AD × 0.95. Gold × 1.1. |
| 5 | Bosses and mini bosses +25% max HP / ×1.5 purple | Their max HP × 1.25 at spawn. Purple = round(repeat × 1.5): 3 for a boss, 6 for Thresh, 2 for a mini boss. |
| 6 | Nothing / Nothing | No modifier |

- The enemy speed and boss HP apply from the next spawn; the rest at once. XP has no multiplier.
- The modifier is the first icon in the buff row, with no timer: `stats/move_speed`, `ui/essence_orange`, `stats/max_hp`, `stats/ad` or `ui/skull`. Its hover card is "Endless modifier" with both lines (`ui_design.md`).

**The HUD's stage info:**
- During a wave: "Endless · Jungle  Wave 23  Enemies: 12", or "Mini boss wave" / "Boss wave". There is no "/ N".
- In a break: "Wave 24 in 0:12" (or "Mini boss wave in …", "Boss wave in …") and Skip. While the pick is open, the countdown and Skip hide.
- A dim "Best 22" line under it, read live. The boss bar sits under that line.

**Best wave:**
- It is the most waves cleared in one run: dying in wave 23 records 22. Waves skipped by a debug jump don't count.
- It is kept in memory each time a wave is won (`SaveGame.record_endless`). The run's end-of-stage save (death or Leave) or a Yes when quitting writes it.
- `"cleared"` never gets `"endless"`, and `"bosses"` is unchanged by Endless.

**The end of a run** (the end screen, on death):
- **RUN OVER** in red, then "Endless · Jungle". The `defeat` sound plays.
- **Stats:** Waves cleared, Time, Kills, Damage dealt, Damage taken, Gold earned, Level reached, Modifier (its downside, or "None").
- **Rewards:** the essences, plus a green **"New best: 22 waves!"** ("1 wave" for one) when the run beat the best it started with. *(V1.5.0: and a green line for each milestone the run paid.)*
- **Retry** starts a new run on the same map choice (Random rolls again). **Main screen** opens the Journey on Endless, with the run's map still chosen. There is no Next.
- Leaving a run shows no end screen: it saves and opens the Journey on Endless the same way.
- *(V1.5.0: the Journey now opens on the latest open stage, or on Training once every stage is cleared, after an Endless run too (`main_screen.md`, "Which place opens"). The run's map choice is still saved, so the Endless portal shows it when picked.)*

**Debug:** "Jump to boss wave" jumps to the next tenth wave (from wave 3 to 10, from 10 to 20) and closes an open pick first. "Jump to the last wave" is hidden. The wave line reads "Wave 7 (Endless)".

---

## 15. Save System

### Slots
- **3 save slots.** The player picks a slot on the **title screen**. That is the **current slot**: every save writes to it.
  - **Start new game** lists the 3 slots. A used slot asks "Overwrite slot N? Its progress will be lost." Then the player picks the **difficulty** (Easy, Normal, Hard or Extreme; see §17). The new game is **written at once** (`SaveGame.start_new`), so the overwrite is real. Then Act 1 starts.
  - **Load game** lists the same slots, with the empty ones disabled. The button itself is disabled ("No saved games yet") when no slot exists. It opens the main screen.
  - Each used slot shows its play time and when it was saved: "Slot 2 · 1h 02m · saved 2026-10-29 03:10".
- **Save as copy:** the current progress can be copied into another slot (asks for confirmation before overwriting).
- **Leave to main menu** (gear menu) asks "Save before leaving?" (Yes / No / Cancel), then goes back to the title screen.
- Files: `user://save_slot_1.json`, `save_slot_2.json`, `save_slot_3.json`, each with its own `_backup.json`.
- Settings are saved separately in `user://settings.json` and shared by all slots. *(V1.4.3: they are written to `settings.json.tmp` and renamed. A failed rename keeps the `.tmp`, and loading falls back to it when `settings.json` is missing or broken; a `.tmp` that loads is renamed back to `settings.json` at once.)*

### What is saved (permanent progress only)
- Blue, orange and purple essences
- Bought Evolution Tree nodes (summoner spells included)
- The spells picked for D and F
- Owned skins, equipped skin
- Cleared stages, and which bosses / mini bosses already gave first-time purple
- Resolve's defeats: how many times Lucian fell on each story stage not yet cleared (`"defeats"`, V2.0, §3)
- Endless best wave (the most waves cleared in one run)
- The Endless milestone waves already paid (V1.5.0, §14)
- Play time: every second outside the title screen, pauses not counted
- The difficulty (V1.3)

The slot's JSON is still `VERSION` 1: V2.0 only adds the `"defeats"` key, a dictionary of stage id to count (`{"2-1": 3}`). A stage leaves it when it is cleared. A save from before V2.0 has none and loads with no defeats; an entry that is not a positive whole count, names no story stage or names a cleared stage is skipped on load.

Nothing inside a stage is saved (items, gold, level, enemies), since stages always reset.

### When to save
- **Auto-save only when a stage is done:** cleared, left (ESC → Leave this stage) or failed (Lucian dies). Nothing is saved between waves.
  - An Endless run is done when Lucian dies or the run is left. Its best wave is kept in memory each time a wave is won, so that save writes it (§14). *(V1.5.0: a milestone paid in the run, with its essence, is written the same way.)*
- **Little on the main screen auto-saves.** Evolution Tree purchases and resets, skin purchases and skin changes, and the Endless map choice are kept only by the next auto-save, the **Save** button in the gear menu, a **Yes** when leaving, or **pressing Start** (V1.4.2). A Start saves first; if the save fails, the stage doesn't start and a red toast says so. The difficulty can't change after a new game.
- **Every exit can be cancelled** (since Phase 9). Cancel, or ESC, closes the question and nothing else happens.

| Exit | Question | Cancel / ESC |
|---|---|---|
| Gear menu → Leave to main menu | **"Save before leaving?"** Yes / No / **Cancel** | The gear menu is still open |
| Exit the game (ESC menu or gear menu); the window's close button anywhere but the title | **"Save before leaving?"** Yes / No / **Cancel** | The game goes on, paused only if it was paused before; an open ESC menu or gear menu stays open |
| ESC menu → Leave this stage | **"Leave this stage? Essences collected so far are kept."** Leave / **Cancel**. In Endless: **"Leave this run? Your best wave is kept."** | Back in the ESC menu, still paused |
| Title screen → Exit game; the window's close button on the title | **"Exit the game?"** Exit / **Cancel** | Stays on the title |

- **"Save before leaving?"**
  - **Yes:** saves to the current slot right away, then leaves. Inside a stage, this keeps the essences collected so far, as leaving the stage would. In Endless it keeps the best wave too. *(V1.4.3: during a boss cutscene, Act 1's or 6-5's Senna scene, the scene is skipped first, as Skip would. The clear and the boss's rewards then run, and the stage is saved as a clear. The End still shows on the next clear of 6-5 if it hasn't been seen.)*
  - **No:** leaves without saving. Everything since the last save is lost.
  - If the save fails, it asks **"Could not save. Quit anyway?"** (Leave to main menu: "Could not save. Leave anyway?"): Yes leaves, No goes back to the game. These two keep Yes / No, and ESC does nothing on them. A failed auto-save after a stage shows a red "Could not save" on the main screen.
- **Leave this stage:** Leave ends the stage as left: the auto-save, then the main screen. A stage run on its own keeps Leave disabled.
- The title screen has nothing unsaved, so its **Exit game** and the window's close button only ask **"Exit the game?"**. Exit quits. *(Before Phase 9 they quit at once.)*
- The other Yes / No questions stay as they were: Overwrite slot, Reset tree. ESC answers No on them.
- *Phase 5 built "Save before leaving?" with Yes / No and no Cancel, as the user asked then. In Phase 9 the user asked for a Cancel on every exit, which replaces that decision.*
- Settings are not part of the save: they are written to `user://settings.json` on every change. *(V1.4.3: a volume slider applies live while it is dragged and is written once, when let go; a wheel or key step is written at once.)*

### Implementation notes (Godot 4)
- **`SaveGame`** (`src/core/save_game.gd`) is **not an autoload**. Like `GameSettings`, it is a class with a static `instance()` that loads slot 1 on first use, so GUT tests and `-s` scripts can point it at scratch files.
- One JSON file per slot, with a `"version"` field for future changes:

| Key | Holds |
|---|---|
| `version` | 1 |
| `saved_at` | Local date and time of the save, e.g. `"2026-10-28 14:03:12"` (Save as copy's slot list shows it) |
| `essences` | `{"blue": 1200, "orange": 5, "purple": 0}` |
| `tree` | Node id → level, for bought nodes only: `{"skill_q": 2, "stat_ad": 3}` |
| `skins` | `{"owned": ["classic", "vampire"], "equipped": "vampire"}` |
| `loadout` | The spells on D and F: `["flash", "heal"]` (`""` for none) |
| `cleared` | Cleared stage ids: `["1-1", "2-1"]` |
| `bosses` | Bosses that already gave their first-time purple: `["thresh_1", "akshan"]` |
| `defeats` | Resolve's defeats: stage id → how many times Lucian fell there, for story stages not yet cleared: `{"2-1": 3}` (V2.0). A stage's entry goes when it is cleared |
| `endless_best` | Best Endless wave: the most waves cleared in one run (dying in wave 23 records 22) |
| `endless_milestones` | The Endless milestone waves already paid, in the order won: `[10, 20]` (V1.5.0). Only 10, 20, 30 and 40 load, each once |
| `play_time` | Whole seconds played in this slot: `3720` |
| `endless_map` | The Endless map choice (V1.4.2): 0 is Random, 1–6 the maps in act order, 1 Mid lane to 6 Thresh's domain (`Journey.ENDLESS_MAPS`). Anything else loads as Random |
| `difficulty` | `"easy"`, `"normal"`, `"hard"` or `"extreme"` (V1.3) |
| `ending_seen` | `true` once The End has shown (V1.4.1). The score uses it too: Senna's voice comes back (`ui_design.md` §8) |

- Numbers are converted back with `int()` when loading (JSON numbers load as floats). Unknown keys, node ids, skins, spell ids and stage ids are dropped, so an old or edited file still loads.
- IDs are saved, not display names.
- A save is written to a temp file first. Then the old save becomes the backup (only if it still reads, so a broken file never replaces a good backup) and the temp file replaces it. If anything fails, the old file and backup stay as they were. The backup loads if the main file is broken. With both broken, it's a new game.
- `"version"` stays 1: Phase 6 and V1.3 only added keys. A file without `"bosses"` or `"play_time"` loads with none; one without `"difficulty"` (or with an unknown word) plays on Normal. *(V1.5.0 only adds `"endless_milestones"` too: a file without it loads with none paid.)* *(V2.0 only adds `"defeats"`: a file without it loads with none.)*
- `SaveGame.start_new(slot, difficulty)` makes that slot current, resets the progress, sets the difficulty and writes it at once. If the write fails, the old data and slot are put back and the title screen shows a red notice (V1.4.2). The difficulty is chosen only here: `set_difficulty` was removed in V1.4.2. `award_boss(id, first, repeat)` returns the purple due and records the boss; the stage adds the essence.
- The main screen's debug table (F3 + Q) gives essences, sets the acts cleared, maxes or clears the tree, resets the progress, and forgets the bosses' first-time purple. *(V1.5.0: only in a debug build. `DebugPanel.allowed` is `OS.is_debug_build()`, so the released game never opens it or the stage's table; a test sets it false to check the release case.)*

---

## 16. Open Topics

- [x] Enemy & boss designs for each act (separate files)
- [x] Map layouts for each act
- [x] Full Endless modifier list
- [x] Unspent skill points: wasted
- [x] Wave count per stage across the 22 stages
- [x] Implementation / MVP plan (Phase 1: `implementation/phase1.md`, Phase 2: `implementation/phase2.md`, Phase 3: `implementation/phase3.md`, Phase 4: `implementation/phase4.md`, Phase 5: `implementation/phase5.md`, Phase 6: `implementation/phase6.md`, Phase 7: `implementation/phase7.md`, Phase 8: `implementation/phase8.md`, Phase 9: `implementation/phase9.md`, Phase 10: `implementation/phase10.md`, V1.1: `implementation/v1.1.md`)
- [x] Item stats and effects (`items.md`)
- [x] UI (see `ui_design.md` and `main_screen.md`): HUD (with the stage info, boss bar and radar), backpack, crafting, recipe table, ESC menu, merchant's shop, Settings, the main screen (Journey, Evolution Tree, Skin Shop), and the title screen with save slot selection
- [x] Save system
- [ ] Art style, sound (Phase 3 has generated placeholder sound effects and audio buses; Phase 9 adds 11 more, 24 in all, listed in `ui_design.md` §8; no music yet) *(V1.5.0: a synthesized score, made in code like the sounds: a theme and one piece per act, in layers that follow the fight. `ui_design.md` §8, Music.)*

---

## 17. Balance pass (V1.3)

A playtest bot (`tests/tools/autoplay.gd`) played the story headless at three skill tiers. On 1.2's numbers the novice could not finish the tutorial, the average player was stuck at 2-1, and the skilled player needed 7 tries for 2-1 and was stuck at 3-1 (`docs/report/v1.3.md`). The causes, and what changed:

| Cause | Change |
|---|---|
| Lucian restarted every stage at level 1 while enemies grew per act, so each act's first wave was the hardest moment of the game. Skill ranks bought in the tree could not be used: rank 3 needs level 5, R needs level 6, and Act 2 ended at level 3–5. | A story stage starts Lucian at its act's level: 1, 2, 5, 5, 7, 9 (`StageSetup.ACT_START_LEVELS`: the user's numbers, with Act 3 raised from 4 to 5 after Hard's playtest), with that many skill points. The XP to the next level is 100 + 60 × level (was 180 + 100 × level). Act 1, Training and Endless start at level 1. |
| Enemy HP grew ×1.6 to ×4.0 by act while Lucian's damage grew far less. | `EnemyData`: HP per act 0.6 → **0.25**, damage per act 0.25 → **0.15**, growth per wave 15% → **10%**. Rewards per act are unchanged. *(V2.0: HP per act 0.25 → **0.35**, with more waves and stronger bosses; §1, §3 and the act files.)* |
| 1-1 → 2-1 was a cliff: 2.7× the tutorial's HP and no Senna. | The first stage of every act (2-1, 3-1, 4-1, 5-1, 6-1) gives its normal enemies 20% less HP (in 2-1 the elites too); 3-1's wave 2 brings one raptor pack (was two). |
| The tutorial killed a player who doesn't kite in 26 s. | 1-1's wave 1 is 4 melee and 2 ranged (was 6 and 4), wave 2 has 4 ranged (was 6), and its minions hit 25% softer (`WavePlan.DAMAGE_SHARES`). |
| Swarm enemies outran Lucian (345), so kiting, his whole kit, did nothing. | Raptors 300 / 295, wolves 310 / 300, spiderlings 330, saplings 320, Mist Walkers 320. |
| Act 3's packs of 12+ melee monsters at once. | The small monsters have about 22% less HP and 25% less damage; the Blue Sentinel and Red Brambleback 1400 HP (was 1700) and 30 / 34 damage (was 42 / 40; the Sentinel's 36 became 30 after Hard's playtest, where it was the wall). A drake's wave brings 2 packs, not 4. |
| Sticky elites: the Blue Sentinel's 30% slow made Lucian as slow as it; super minions were the top killer in Act 2. | Blue's slow is 20% for 1.0 s (was 30% for 1.5 s); super minions 1150 HP and 36 damage (was 1400 and 45). |
| A soft-lock: below ~200 damage a second the Ocean Drake healed more than it took (bots fought it for 35 and 40 minutes). | Soothing Mist heals 20% (was 30%); 5% of its max HP interrupts it (was 8%); at most 3 channels a fight (`OceanDrake.MIST_USES`). |
| Mana ran dry every fight at low levels. | Lucian's base mana regen 14 → 20 per 5 s. |

Bosses and mini bosses don't scale and keep their numbers (except the Ocean Drake's mist). Endless keeps its own scaling (`EndlessPlan`).

**Tools:** `tests/tools/autoplay.gd` plays the story at a tier (skilled, average, novice), retries a lost stage, farms the last cleared one after 3 losses, and prints each try (kills, damage taken by enemy, what killed him). `AUTOPLAY_DIFFICULTY=hard` plays it on a difficulty. `tests/tools/stage_budget.gd` prints every stage's HP per wave, XP, gold, blue and the level Lucian ends at. Both run headless only. *(V1.5.0: between stages the bot buys skins with purple, through the Skin Shop's own call: every one it can afford, in Skin Shop order. It wears the last one bought, or with `AUTOPLAY_SKIN=<id>` (`classic` for none) it saves up for that one first and wears it once owned. Each try's line names the skin worn. The bot also follows the new item rules: it buys onto a free equip slot when its backpack is full, equips to make room for loot, and keeps one penetration item. `stage_budget.gd` counts an Ancient Krug's splits in the XP, gold and blue too, applies each stage's gold share, and after the stages prints each boss's and mini boss's wall, its HP ÷ the gold earned in its stage before its wave, and each act's average gold per stage, the boss's own gold included.)* *(V2.0: the bot plays more like a player and measures how long the story takes. It walks to the merchant in each break, and waits its tier's `idle` seconds before pressing Skip. It goes for summoners first (`focus`, the share of the time it does), fumbles some actions (`fumble`) and backs away from a melee enemy when its health is below the tier's `panic` share. `AUTOPLAY_RUN=<name>` gives a run its own save and settings files, so runs can go side by side. `AUTOPLAY_TIER="panic=0.2,react=0.4"` plays a tier with some numbers changed. `AUTOPLAY_RESOLVE=off` plays with the Resolve setting off. Each try prints its Resolve. A run ends with a per-stage summary and an **estimate of the play time**: the stage time, plus `between` seconds for each stage or farm run and `retry` seconds for each failed try. The tiers' numbers are in the table below.)*

| Tier | react | kite | panic | warn | bolt | focus | fumble | idle | between | retry |
|---|---|---|---|---|---|---|---|---|---|---|
| Skilled | 0.15 | 90 | 0 | 1.0 | 0.5 | 1.0 | 0 | 1 | 45 | 10 |
| Average | 0.25 | 40 | 0 | 0.8 | 0.2 | 0.5 | 0.08 | 3 | 75 | 15 |
| Novice | 0.35 | never | 0.25 | 0.5 | 0 | 0 | 0.25 | 6 | 120 | 20 |

`react` is the reaction time in seconds, `kite` the distance at which it steps back from a melee enemy, `warn` and `bolt` the share of ground warnings and enemy bolts it dodges, `idle` the seconds it waits in a break, `between` and `retry` the seconds the estimate adds per stage and per failed try. The measured play time is left to the V2.0 report (`docs/report/v2.0.0.md`).

### Difficulty (V1.3)

The pass above makes Normal fit a new player. The difficulty lets the player make the game easier or harder, with one number (`Difficulty.SCALES`), and pays more blue and orange essence on the harder levels (`Difficulty.ESSENCE_SCALES`; `BLUE_SCALES` before V1.5.0):

| Difficulty | Enemy HP | Damage Lucian takes | Blue and orange essence |
|---|---|---|---|
| Easy | ×0.8 | ×0.8 | ×1.0 |
| **Normal** | ×1.0 | ×1.0 | ×1.0 |
| Hard | ×1.1 | ×1.1 | ×1.2 |
| Extreme | ×1.3 | ×1.3 | ×1.5 |

*(V1.5.0: the last column was blue only. It now scales orange too: see below.)*

*The user first picked Hard ×1.2 and Extreme ×1.5 with no extra blue. On those numbers both bots were stuck at the start of Act 3 on Hard and Extreme, so the user chose four changes at once: the smaller steps above, more blue on Hard and Extreme, Act 3 starting at level 5, and the Blue Sentinel's slam 36 → 30.*

- **Where it is picked:** after the slot in **Start new game** (a page titled CHOOSE DIFFICULTY, noted "Enemy HP and damage. It can't be changed later."; Normal is gold; hovering a level shows "Enemies have 110% HP and deal 110% damage. Blue and orange essence ×1.2."; "Blue essence ×1.2." before V1.5.0). Back or ESC returns to the slots.
- **Fixed for the save (V1.4.2):** the level is chosen only here, at a new game, and nothing changes it afterwards. *(V1.3 let you change it from the gear menu; saves keep the level they have. V1.4.2 showed it there as a greyed row, "Difficulty · Normal"; since V1.4.3 the gear menu has no Difficulty row, and the game never shows the level after the new-game page.)*
- **What it scales:** the HP of every enemy, bosses and mini bosses included (`Stage.spawn_unit`), and every hit Lucian takes before armor and magic resist (`Lucian.damage_taken_scale`), so boss skills, ground hazards and burns count too. The damage is on Lucian's side because boss skills have their own numbers.
- **Blue essence:** every kill's blue × 1.2 on Hard and × 1.5 on Extreme (`KillRewards`), on top of the tree's Essence Drops and an Endless modifier, so replays pay for the tree.
- **Orange essence (V1.5.0):** the same × 1.2 and × 1.5, on the orange drop chance of normal and elite kills and on the sure orange of bosses and mini bosses and the Rift Scuttler, rounded. A boss pays 6 orange on Hard and 8 on Extreme (5 on Normal), a mini boss 4 and 5 (3), the Scuttler 5 and 6 on top of its chance (4).
- **What it doesn't:** gold, XP, ~~orange~~ and purple essence, enemy speed, timings, and the boss break bars (they are shares of the boss's HP, so they grow with it). It applies in the story and Endless; Training's dummies keep their HP. *(Orange since V1.5.0, above. Endless's milestones aren't raised.)*

### Resolve (V2.0)

A stage that has beaten Lucian gets easier (§3, "Built in V2.0"). What one stack is worth depends on the difficulty (`Difficulty.RESOLVE_STEPS`):

| Difficulty | One stack | Five stacks (the most) |
|---|---|---|
| Easy | +10% damage dealt, -10% damage taken | +50% dealt, -50% taken |
| **Normal** | +10% damage dealt, -10% damage taken | +50% dealt, -50% taken |
| Hard | +5% damage dealt, -5% damage taken | +25% dealt, -25% taken |
| Extreme | none | none |

- The damage taken is multiplied by 1 - 0.1 × stacks (so five stacks halve it on Normal), on top of the difficulty's own scale.
- Training, Endless and a cleared stage never have it.
- The pass behind it: the novice bot could not leave 2-1 (25 tries, dead in about 25 s), so a player who dies a lot needs a way through that does not change the stage for everyone else (`docs/implementation/v2.0.0.md`).
