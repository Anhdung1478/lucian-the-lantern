class_name BarGhost
extends RefCounted
## The pale chunk a health bar shows where health was just lost: it stays
## for HOLD seconds after the last loss, then drains down to the health. The
## bar tells it every change (follow) and every frame (step), and draws from
## `share` to the health while is_showing. An extra: with Juice off there is
## never a ghost.

## Seconds it waits after a loss, and the share of the bar it drains a second.
const HOLD := 0.3
const DRAIN := 0.5

## Where the ghost ends, as a share of the bar: the health's own share when
## there is none.
var share := 1.0
## It moved since the bar last drew it (the bar clears it in its _draw).
var moved := false

var _hold := 0.0


## The health went from share `before` to share `now`. A loss leaves the
## ghost at `before` (or keeps one that reaches further); a gain past the
## ghost ends it.
func follow(before: float, now: float) -> void:
	if not Juice.on():
		share = now
		return
	share = maxf(share, maxf(before, now))
	if now < before:
		_hold = HOLD


## A frame of `delta` seconds with the health at share `now`: the ghost waits,
## then drains toward it.
func step(delta: float, now: float) -> void:
	if share <= now:
		return
	if _hold > 0.0:
		_hold -= delta
		return
	share = maxf(share - DRAIN * delta, now)
	moved = true


## Some of the ghost shows past the health at share `now`.
func is_showing(now: float) -> bool:
	return share > now
