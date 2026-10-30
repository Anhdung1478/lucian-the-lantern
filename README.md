# Lucian: The Lantern

A free, top-down action game about Lucian, the Purifier. Thresh has taken Senna's soul into his lantern. Lucian fights through six acts, from the Sentinels' ruins to the Shadow Isles, to shoot through the lantern and set her free.

Made with Godot 4.7. A fan project, not affiliated with Riot Games (see [Legal](#legal)).

![Title screen](docs/report/phase10/title_0_menu.png)

## Download and play

1. Open the [latest release](https://github.com/Anhdung1478/lucian-the-lantern/releases/latest).
2. Download `LucianTheLantern-v1.0.0-windows-x64.zip`.
3. Unzip it anywhere and run `LucianTheLantern.exe`.

- Needs Windows 10 or 11, 64-bit.
- The game is not code-signed, so Windows SmartScreen may warn the first time. Choose **More info → Run anyway**.
- Saves and settings live in `%APPDATA%\lucian_the_lantern`.

## The game

- **Story:** 22 stages in 6 acts, each with its own map, enemies and boss.

  | Act | Name | Boss |
  |---|---|---|
  | 1 | The Loss | Thresh (scripted) |
  | 2 | The Sentinels | Akshan |
  | 3 | The Jungle | Elder Dragon |
  | 4 | The Darkness | Dark Lucian |
  | 5 | Shadow Isles | Karthus |
  | 6 | The Lantern | Thresh, in two phases |

- **Lucian's kit:** Piercing Light (Q), Ardent Blaze (W), Relentless Pursuit (E), The Culling (R) and Lightslinger (passive). He fires his own pistol and Senna's relic gun in turn.
- **In a stage:** waves, a merchant between waves, items you craft in your backpack, and level-ups that put skill points into ranks you bought.
- **Evolution Tree:** spend the essences you earn on skill ranks, stats, backpack and equip slots, a better economy, and summoner spells. The spells are Flash, Ghost, Barrier, Heal, Clarity and Smite.
- **Skin Shop:** five skins, Classic, High Noon, PROJECT, Pulsefire and Vampire, each with its own strengths and weaknesses.
- **Endless mode:** opens after Act 3. Waves keep getting stronger, with a mini boss every 5 waves, a boss every 10, and a modifier pick after each boss.
- **Other:** three save slots, rebindable keys, and three cast modes for each key.

| | |
|---|---|
| ![A fight in Endless](docs/report/phase9/endless_wave_0_fight.png) | ![The Journey map](docs/report/phase10/journey_map_1_mid_game.png) |
| ![The Evolution Tree](docs/report/phase10/main_tree_4_skills.png) | ![The Skin Shop](docs/report/phase10/main_skins_1_vampire.png) |

## Controls

Every key can be changed in **Settings → Controls**.

| Action | Default |
|---|---|
| Move | Right mouse button |
| Attack | Left mouse button |
| Attack-move | A |
| Skills | Q, W, E, R |
| Summoner spells | D, F |
| Item slots | 1–6 |
| Backpack | P |
| Stats panel | C (Ctrl + C toggles, hold for more) |
| Camera mode | Y |
| Center camera on Lucian | Space |
| Menu | Esc |

## Run from source

1. Install [Godot 4.7.2](https://godotengine.org/download) (standard, not .NET).
2. Open `project.godot` in Godot and press **F5**. The game is GDScript only, so it needs no build step.

**Tests** use [GUT](https://github.com/bitwes/Gut) (in `addons/gut`):

```powershell
godot --headless --path . -s res://addons/gut/gut_cmdln.gd
```

**Windows build:** install the Godot 4.7.2 export templates, then run:

```powershell
godot --headless --path . --export-release "Windows Desktop" build/windows/LucianTheLantern.exe
```

## Project layout

| Folder | What is in it |
|---|---|
| `src/` | Game code: core rules, Lucian, enemies and bosses, stages, UI |
| `data/` | Resources: enemies, items, skins, Evolution Tree nodes, waves |
| `assets/` | SVG art |
| `tests/` | Unit tests and the screenshot tool |
| `docs/` | Design docs, per-phase plans and reports with screenshots |

## Legal

Lucian: The Lantern isn't endorsed by Riot Games and doesn't reflect the views or opinions of Riot Games or anyone officially involved in producing or managing Riot Games properties. Riot Games, and all associated properties are trademarks or registered trademarks of Riot Games, Inc.

- **Free:** this is a non-commercial fan game. It is not for sale.
- **No license (all rights reserved):** you may download and play it, and read the source here. No permission is given to copy, modify or redistribute the code or art. The League of Legends characters, names and story belong to Riot Games.
