# V1.1: Skin effects for Q, W, E and R

**Date:** 2026-10-30
**Version:** 1.1.0 (from 1.0.0)

## Goal

Each Lucian skin gets its own look and its own sounds for Piercing Light (Q), Ardent Blaze (W), Relentless Pursuit (E) and The Culling (R). Basic attacks (Lightslinger's second shot included) and the muzzle flash follow the skin too. The Skin Shop gets a Preview pop-up that plays a skin's effects before you buy it.

**Out of scope**
- Gameplay: no damage, hitbox, cast time, cooldown or range changes. Skins already trade stats.
- Summoner spells and item effects (Flash, Galeforce, Rocketbelt, Runaan's bolts and the rest) keep their own colours.
- Senna's shots and Dark Lucian's Q keep their own looks.
- A Q wind-up effect during the 0.3 s cast (there is none today; none is added).

## Where things stand

- All effects are drawn in code with `_draw()`:
  - **Q:** `PiercingLight._fire` spawns a `LaserBeam`, a gold-white beam that fades in 0.25 s.
  - **W:** `ArdentBlaze._launch` fires a `LinearProjectile` with fireball colours and a `head_radius`. `_explode` spawns a `CrossBlast`, an orange cross that fades in 0.35 s.
  - **E:** `RelentlessPursuit.execute` calls `Lucian.start_dash(dir, distance, speed)`. That makes a light-blue `DashTrail`, which grows behind Lucian and fades in 0.3 s.
  - **R:** `TheCulling._fire` fires 22 white-gold `LinearProjectile` bullets over 3 s and calls `Lucian.flash_muzzle(gun)`.
  - **Basic attacks:** `Lucian.fire_attack_projectile` fires a homing `AttackProjectile` and calls `flash_muzzle`, which plays `shot` and spawns a `MuzzleFlash`.
- Sounds are synthesized in `Sfx._generate`: `cast_q`, `cast_w`, `cast_e`, `shot`. R has no cast sound; each bullet plays `shot`.
- `GameSettings.low_effects()` already turns off the muzzle flash and the dash trail.
- `SkinData` (`data/skins/<id>.tres`) holds art and stats. `Lucian.skin` is the equipped one.
- Shared users that must not change:
  - `LaserBeam`: Dark Lucian sets its own colours.
  - `DashTrail`: Dark Lucian, the Act 1 E-lesson cutscene, and Galeforce and Rocketbelt through `start_dash`'s `trail_color`.
  - `LinearProjectile` and `AttackProjectile`: Senna and the items set `color` and `glow_color`.

## 1. The look of each skin

**Rules for every skin**
- **Hitboxes don't change.** The main shape is drawn to the same size as today: Q's beam rectangle (`length × width`) and W's cross arms (`bar_size`). Particles only spill a little past the edges, never far enough to make a skill look longer or wider than it reaches.
- **Main shapes last as long as today:** Q's beam 0.25 s, W's cross 0.35 s, the trail fades in 0.3 s after the dash. Extra details (scorch marks, embers, bats, afterimages) may stay **at most 0.6 s**, at low alpha, so they never hide an enemy's ground warning.
- **Classic keeps today's effects and sounds exactly.**

| | **High Noon**: hellfire gunslinger | **PROJECT**: hologram | **Pulsefire**: time rift | **Vampire**: blood |
|---|---|---|---|---|
| **Palette** | Ember orange `#ff6a2a`, deep red `#c8300a`, hot white `#fff6e0`, smoke grey | Cyan `#38e8ff`, pale cyan `#7ff4ff`, gunmetal `#1c2029`, magenta for glitches | White core `#f4f8ff`, pale blue `#7fd8ff`, deep blue `#4a5cff` | Crimson `#d01830`, bright red `#ff3a50`, black red `#4a0812` |
| **Q beam** | Red edges, an orange core and a white-hot centre. Embers drift off and a smoke puff hangs at the muzzle. | Bright cyan edge lines over a see-through fill, with scan lines sweeping along. It breaks into pixels instead of fading. | A white core with blue edges. Rings ripple down the beam and a clock-face ring shows at the muzzle. | Black-red edges and a crimson core. Drops spray off and fall, and it drains away from Lucian's end outward. |
| **W missile** | A molten slug with a smoke tail | A spinning diamond "data packet" | An orb with two orbiting rings | A blood orb with a dripping tail |
| **W cross** | Burning arms, a charred ring under it, embers flying out along the 4 arms | Built from grid squares that light up from the centre outward, then flicker off | Comes with a shockwave ring and a ticking clock flash at the centre | A blood splash, with four small bats flying out along the arms |
| **E dash** | A fire streak along the ground and dust kicked up where he started | A glitch: 3 offset copies of Lucian split cyan/magenta, with broken scan-line pieces | 3–4 fading blue afterimages of Lucian's body (like Ghost's), with a ring at both ends | A red mist trail with 5–6 bats flapping along it |
| **R bullets** | Heavy orange tracers | Thin cyan laser bolts | Pale blue pulse bolts with a small ring at the tip | Crimson bullets with a dark drip streak |
| **Basic attack** | Orange tracer | Cyan bolt | Pale blue pulse with a tiny ring | Crimson bullet |
| **Muzzle flash** | Star-shaped, with sparks | Square, with hex sparks | A small blue ring | Red |

**Low effects:** only the main shapes, in the skin's colours: the beam, the missile, the cross and the bullets. No particles, bats, afterimages, rings, scan lines or pixel break-up. As today, the muzzle flash and the dash trail are off.

## 2. Code structure

### `SkinFx`

`src/lucian/skin_fx/skin_fx.gd`: `class_name SkinFx extends Resource`. The base class is Classic and returns today's effects. Each themed skin overrides it.

| Member | Classic returns | Called from |
|---|---|---|
| `q_beam(from: Vector2, direction: Vector2, length: float, width: float) -> Node2D` | a set-up `LaserBeam` | `PiercingLight._fire` |
| `w_missile_look() -> ShotLook` | a `PlainShotLook` with today's W fireball colours, streak 40 × 8, head 11 | `ArdentBlaze._launch` |
| `w_blast(at: Vector2, direction: Vector2, bar: Vector2) -> Node2D` | a set-up `CrossBlast` | `ArdentBlaze._explode` |
| `e_trail(body: Texture2D) -> DashTrail` | a light-blue `DashTrail` | `RelentlessPursuit.execute` |
| `r_bullet_look() -> ShotLook` | a `PlainShotLook` with today's R colours, streak 36 × 5 | `TheCulling._fire` |
| `attack_shot_look() -> ShotLook` | a `PlainShotLook` drawn like today's `AttackProjectile` | `Lucian.fire_attack_projectile` |
| `muzzle_flash() -> Node2D` | `MuzzleFlash` | `Lucian.flash_muzzle` |
| `q_sound`, `w_sound`, `e_sound`, `shot_sound: StringName` | `&"cast_q"`, `&"cast_w"`, `&"cast_e"`, `&"shot"` | the same places |

- **Folders:** each themed skin has one folder holding its set and its drawing classes:
  - `src/lucian/skin_fx/high_noon/` with `high_noon_fx.gd` and its beam, blast, trail and look classes
  - `src/lucian/skin_fx/project/`
  - `src/lucian/skin_fx/pulsefire/`
  - `src/lucian/skin_fx/vampire/`
- **`SkinData`** gets `@export var fx: SkinFx`. Each `data/skins/<id>.tres` sets it as a sub-resource with its set's script; Classic uses `SkinFx` itself.
- **`Lucian.fx() -> SkinFx`** returns `skin.fx`, or a shared Classic `SkinFx` when it is null, so a broken .tres can't crash a cast.

### Bullets: `ShotLook`

- `src/combat/shot_look.gd`: `class_name ShotLook extends Node2D`. It draws one shot facing +x in its own frame, and may animate.
- `ShotLook` gets two static helpers that hold today's drawing code, moved out of the projectiles:
  - `draw_streak(canvas, color, glow_color, streak_length, streak_width, head_radius)`, from `LinearProjectile._draw`
  - `draw_bolt(canvas, color, glow_color)`, from `AttackProjectile._draw`
- `LinearProjectile._draw` and `AttackProjectile._draw` call these helpers, so they look exactly as now.
- `PlainShotLook` (`src/combat/plain_shot_look.gd`) is the `ShotLook` Classic uses. It has the same colour and size fields and calls the same helpers, so Classic's shots look the same as today.
- `LinearProjectile` and `AttackProjectile` get `set_look(look: ShotLook)`:
  - A non-null look is added as a child, and the projectile's own `_draw()` draws nothing.
  - A null look changes nothing.
- Every skin, Classic included, passes a look. The projectiles' own drawing is left for Senna, the items and Dark Lucian, which keep setting `color` and `glow_color`. Hit logic is not touched.

### E trail

- `Lucian.start_dash(direction, distance, speed, trail_color := DashTrail.LIGHT, trail: DashTrail = null)`. When `trail` is given, `_start_dash_trail` uses it instead of a new `DashTrail` and still calls `setup(from, color)`, `reach(to)` and `finish()` on it. If no trail is spawned (Low effects, or a dash of zero length), the given trail is freed.
- Galeforce and Rocketbelt keep passing only their colour.
- Themed trails extend `DashTrail` and override `_draw()`. The ones with afterimages (PROJECT, Pulsefire) record Lucian's position and facing in `reach()` and draw the `body` texture they were given.
- With Low effects, no trail is made, as today.

### Shared helper: `FxSparks`

`src/combat/fx_sparks.gd` is a small particle list: position, velocity, life, size and colour. It has `emit(...)`, `step(delta)` and `draw_on(canvas: CanvasItem, shape)`. The themed classes use it for embers, drops, pixels and sparks instead of each writing their own.

### Animation and lifetime

- Animated pieces (scan lines, rings, bats, sparks) run `_process(delta)`, call `queue_redraw()`, and free themselves once their last part is gone (at most 0.6 s).
- They use the default process mode, so they stop while the game is paused.
- Each piece reads `GameSettings.instance().low_effects()` once in `_ready()` and skips its details when it is true.

### Skill changes

Only these lines change:

- `PiercingLight._fire`: `lucian.spawn(lucian.fx().q_beam(...))`, then `Sfx.play(lucian.fx().q_sound)`.
- `ArdentBlaze._launch`: `missile.set_look(lucian.fx().w_missile_look())` and `Sfx.play(lucian.fx().w_sound)`.
- `ArdentBlaze._explode`: `lucian.spawn(lucian.fx().w_blast(at, _direction, bar.size))`.
- `RelentlessPursuit.execute`: passes `lucian.fx().e_trail(lucian.visuals.body_texture())` to `start_dash` and plays `e_sound`.
- `TheCulling._fire`: `bullet.set_look(lucian.fx().r_bullet_look())`.
- `Lucian.fire_attack_projectile`: `shot.set_look(fx().attack_shot_look())`.
- `Lucian.flash_muzzle`: plays `fx().shot_sound` and spawns `fx().muzzle_flash()`.

Damage, hit queries, cast times and cooldowns are untouched.

## 3. Sounds

- All are synthesized in `Sfx._generate`.
- Each themed skin gets four recipes, 16 in all, named `cast_q_<skin>`, `cast_w_<skin>`, `cast_e_<skin>` and `shot_<skin>`.
- `shot_<skin>` plays for basic attacks, Lightslinger's second shot and every R bullet, so it is R's sound too, as `shot` is for Classic.
- Each is as loud as the Classic sound it replaces: the same `volume_db` at the call site, and a peak level within 10% of the Classic recipe's, which a test checks.

| | Q | W | E | Shot |
|---|---|---|---|---|
| **High Noon** | A roaring fire crackle, noisy and falling | A whoosh and a heavy thump | A dusty whoosh and a two-note spur jingle | A low revolver crack |
| **PROJECT** | A square-wave synth laser with a fast flutter | A quick rising bleep and a pop | A stuttering glitch chirp | A short square blip |
| **Pulsefire** | A shimmering sweep that rises then falls | A deep "whomp" with a bell ring | A rising "rewind" whoosh | A soft high pulse with a flutter |
| **Vampire** | A low, wet, falling zap | A low splash thump | Three quick wing flaps | A muffled low crack |

`Sfx` gets `static func has_recipe(sound: StringName) -> bool`, so a test can check that no skin's sound falls through to the default beep.

## 4. Skin Shop preview

- **Button:** each `SkinCard` gets a small **Preview** button in the empty space above Purchase/Equip. It works for owned and unowned skins.
- **Pop-up:** `SkinPreview` (`src/ui/main/skins/skin_preview.gd`) opens over the Skin Shop. It is about 1200 × 680 px, with a dark panel, the title "<Skin> · Preview" and a ✕ button.
  - Esc closes it: `SkinShop.close_popup()` returns true while it is open, which is how the main screen's Esc already works.
  - Clicks outside the panel are blocked.
- **The stage:** a clipped floor drawn in code. Lucian, as a `Sprite2D` of that skin's `body`, stands on the left facing right. The training dummy (`assets/art/enemies/training_dummy.svg`) stands on the right, about 700 px away. Effects play at game size from the same `SkinFx` calls:
  - **Q:** `q_beam` from Lucian's gun to the dummy, at Q's rank 1 width.
  - **W:** a real `LinearProjectile` with W's speed, its range set to the dummy's distance and the skin's missile look. On `finished` it spawns `w_blast` at the dummy, at rank 1 size.
  - **E:** Lucian's sprite tweens 280 px toward the dummy at E's dash speed, with `e_trail` following through `reach()` and `finish()` (no trail with Low effects). Then he walks back.
  - **R:** 22 `LinearProjectile` bullets over 3 s from both muzzles in turn, with the skin's look and muzzle flash, ranged to stop at the dummy.
  - **Attack:** three `LinearProjectile` shots with `attack_shot_look`, about 0.4 s apart, from alternating guns, ranged to stop at the dummy.
- **Buttons:** Q, W, E, R, Attack and ▶ All. All plays the five in order, with a 0.6 s gap, and loops. It starts by itself when the pop-up opens. Pressing Q/W/E/R/Attack stops the loop and plays that one; ▶ All starts the loop again.
- **Sound:** the skin's sounds play on the SFX bus.
- **Rules:**
  - The preview deals no damage and saves nothing.
  - The projectiles collide only with `Layers.ENEMY_HURTBOX`, and there are no enemies on the main screen.
  - Closing frees every node it spawned.
  - Low effects applies here too.

## 5. Tests, screenshots, docs and version

### GUT tests

*Data and sounds*
- Every `SkinData` in `Skins.ALL` has a non-null `fx`. Classic's is the base `SkinFx`; each other skin's is its own subclass.
- Every `q_sound`, `w_sound`, `e_sound` and `shot_sound` of every skin passes `Sfx.has_recipe`.
- Each themed sound's peak is within 10% of the Classic sound it replaces.

*Effect pieces*
- Each `SkinFx` builds every piece without errors:
  - `q_beam` and `w_blast` keep the size they are given.
  - Every look and trail is non-null.
  - Classic's `PlainShotLook`s carry today's colours and sizes.
- Every spawned piece frees itself within 0.6 s, or within 0.6 s after `finish()` for trails.
- With `quality = low`, themed pieces hold no particles, rings, bats or afterimages.

*Gameplay unchanged*
- With each of the five skins equipped:
  - Q and W hit the same enemies for the same damage.
  - R's bullets deal the same damage.
  - E covers the same distance.

*Wiring*
- With a themed skin equipped:
  - Q spawns that skin's beam and E uses its trail.
  - Basic attacks, Lightslinger shots and R bullets carry its `ShotLook`.
  - `flash_muzzle` spawns its flash and plays its shot sound.
- Galeforce and Rocketbelt trails, Senna's shots and Dark Lucian's Q keep their own looks.

*Preview*
- Each card's Preview button opens it for that card's skin. Esc (through `close_popup`) and ✕ close it.
- Each button spawns its piece, and ▶ All loops.
- Closing leaves no spawned nodes.

### Screenshots

- New scenarios in `tests/tools/screenshot.gd`: Q, W, E and R caught mid-effect in Training for each of the four themed skins, plus the preview pop-up for one skin.
- They are saved in `docs/report/v1.1/` and described in `docs/report/v1.1.md`, like the earlier phase reports.

### Docs

- `docs/lucian_game_design.md` §10 gets a "Built in V1.1: skin effects" part with the look table (Section 1) and the sounds table (Section 3).
- `docs/main_screen.md` Section 2 (Skin Shop) gets a "Built in V1.1" part describing the Preview button and pop-up.
- The README's Skin Shop line mentions that each skin has its own skill effects.
- The implementation plan goes to `docs/implementation/v1.1.md`.

### Version

- `project.godot`: `config/version="1.1.0"`.
- `export_presets.cfg`: `application/file_version` and `application/product_version` become `"1.1.0.0"`.
