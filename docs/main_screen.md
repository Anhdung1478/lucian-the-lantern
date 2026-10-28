# Main Screen Design

> Part of the Lucian game design. The main screen is shown outside of stages. Layout ideas are about 70–80% similar to the references used.

## Overview

The main screen has **3 sections**:

| # | Section | Purpose |
|---|---|---|
| 1 | **Evolution Tree** | Spend blue and orange essence on permanent upgrades |
| 2 | **Skin Shop** | Buy and equip skins with purple essence |
| 3 | **Journey** | Choose an act and stage, Training, or Endless |

The player's essences (blue, orange, purple) are shown in the **top-left** corner.

### Navigation
- **Sections** (Evolution Tree, Skin Shop, Journey): switched with a bar at the **bottom** of the screen.
- **Sub-sections** (e.g. Act 1–6, Training, Endless): tabs at the **top** of the screen.

---

## Section 1 – Evolution Tree

Reference: a node-graph tree with icons in square frames connected by lines (see the screenshot the design was based on).

### Layout
- **One big map shown as a forest:** no separate pages for skills, stats, equipment, summoners and economy. Every branch lives on the same canvas, each growing from its own roots.
- Each upgrade is a **square node with an icon**. Lines connect a node to its requirements.
- The player can **drag to move** around the map *(and zoom, proposed)*.
- Essences in the top-left.
- **Reset tree** button (costs 5 purple, refunds all blue and orange).

### Node states *(proposed)*
| State | Look |
|---|---|
| Hidden (requirements not met) | Dark frame with a **"?"** |
| Available, can afford | Normal frame |
| Available, can't afford | **Red** frame |
| Bought (more levels left) | Lit frame, line to it becomes bright |
| Maxed | **Green** frame |

### Node info panel
Clicking a node opens a panel (bottom-right, like the reference):
- **Name** of the upgrade
- **Current value → next value** (e.g. `+40% → +60%`)
- **Short description**
- **Level:** e.g. `LVL 2 / 5`
- **Cost bar:** shows owned essence against the cost, and works as the **buy button**

---

## Section 2 – Skin Shop

A **full-screen** section showing every skin, including **Classic Lucian**.

### Each skin card
- **Big art** of the skin.
- Below the art:
  - **Bonuses** (green) and **weaknesses** (red)
  - A **short description** of its playstyle
  - **Button:**

| Situation | Button |
|---|---|
| Not owned | **Purchase** (shows purple cost) |
| Owned, not equipped | **Equip** |
| Currently equipped | **Equipped** (disabled) |

- Classic Lucian is always owned, so it shows **Equip** or **Equipped**.

### Skins
| Skin | Cost | Bonus | Weakness |
|---|---|---|---|
| Classic | Free | — | — |
| High Noon | 25 purple | +15% AD | −15% Attack Speed |
| PROJECT | 30 purple | +20% Attack Speed, +15% Move Speed | −10% AD |
| Pulsefire | 20 purple | +15% AP, +15 Ability Haste | −10% Attack Speed |
| Vampire | 25 purple | +15% Lifesteal, kills heal 2% max HP | −20% max HP |

---

## Section 3 – Journey

### Tabs at the top
`Act 1` · `Act 2` · `Act 3` · `Act 4` · `Act 5` · `Act 6` · `Training` · `Endless`

### Unlock rules
| Tab | Unlocks when |
|---|---|
| Act 1 | Always open |
| Act 2–6 | The previous act is cleared |
| Endless | **Act 3** is cleared |

- Locked tabs are covered by a **chain lock**.

### Inside an act tab *(proposed)*
- Shows the act's stages in order.
- A stage unlocks when the previous stage is cleared.
- Cleared stages can be replayed.
- Mini boss and boss stages are marked with a **skull** icon.
