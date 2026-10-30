class_name SkinFx
extends Resource
## How a skin's Q, W, E, R and shots look and sound. This base is Classic:
## the effects of 1.0. Each skin's .tres holds its set (SkinData.fx), and
## themed skins override the builders. Builders only make nodes: the skills
## keep damage, hit shapes and timing, and spawn what they get.

## Sounds played by the skills and the guns (Sfx recipe names).
var q_sound := &"cast_q"
var w_sound := &"cast_w"
var e_sound := &"cast_e"
var shot_sound := &"shot"


## Q's beam from `from` along `direction`, `length` × `width`.
func q_beam(from: Vector2, direction: Vector2, length: float, width: float) -> Node2D:
	var beam := LaserBeam.new()
	beam.setup(from, direction, length, width)
	return beam


## W's cross at `at`, turned to `direction`; `bar` is one arm (length × width).
func w_blast(at: Vector2, direction: Vector2, bar: Vector2) -> Node2D:
	var blast := CrossBlast.new()
	blast.setup(at, direction, bar)
	return blast


## E's trail. `body` is Lucian's body art, for trails with afterimages.
func e_trail(_body: Texture2D) -> DashTrail:
	return DashTrail.new()


## A shot of `kind`. Classic's are the plain streaks and bolt of 1.0.
func shot_look(kind: ShotLook.Kind) -> ShotLook:
	var look := PlainShotLook.new(kind)
	match kind:
		ShotLook.Kind.MISSILE:
			look.color = Color("ffd27a")
			look.glow_color = Color(1.0, 0.45, 0.1, 0.6)
			look.streak_length = 40.0
			look.streak_width = 8.0
			look.head_radius = 11.0
		ShotLook.Kind.BULLET:
			look.streak_length = 36.0
			look.streak_width = 5.0
	return look


func w_missile_look() -> ShotLook:
	return shot_look(ShotLook.Kind.MISSILE)


func r_bullet_look() -> ShotLook:
	return shot_look(ShotLook.Kind.BULLET)


func attack_shot_look() -> ShotLook:
	return shot_look(ShotLook.Kind.BOLT)


## A flash at a gun's muzzle, facing +x; the caller places and turns it.
func muzzle_flash() -> Node2D:
	return MuzzleFlash.new()
