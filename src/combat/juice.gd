class_name Juice
## Whether the extras that make units and combat feel alive show: the walk
## sway, lunges and recoils, squashes, bursts, sparks, glows and trails, the
## target ring, the health bars' ghost chunk and the warnings' moving edge.
## Off on Low quality, and off when run headless (the tests, the bots), where
## nothing is seen. Shadows and health bars are no extras: they always show.

## Something is drawn. Tests turn it on to check the extras.
static var renders := DisplayServer.get_name() != "headless"


static func on() -> bool:
	return renders and not GameSettings.instance().low_effects()
