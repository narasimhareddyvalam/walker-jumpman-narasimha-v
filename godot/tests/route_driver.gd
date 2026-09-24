extends RefCounted
## Fixed input route through the real level. No position/velocity edits, no
## forced completion, no disabled collision - only the inputs a player has.
##
## The first five jump marks are the starter's, unchanged, and still clear the
## original section. The rest were added for Chapter One: the starter's fixture
## stopped at the old finish (x=916), which is now open platform.
## The jump at x=2780 was removed when the Void Gap was added: the hidden floor
## is meant to catch a player who simply keeps walking, and the route has to
## demonstrate that rather than jump over the question.
var jump_marks: Array[float] = [138.0, 292.0, 424.0, 548.0, 712.0,
	944.0, 1072.0, 1200.0, 1352.0, 1468.0, 1580.0, 1810.0]
## Where the route spends or cancels a Feather charge, in order. Spends are
## 2000, 2320, 3120, 3500 and 3800; the rest are cancels, which cost nothing but
## decide where the player lands. The three corridor reversals are mandatory -
## the Betrayal, the Phantom and the tower door cannot be passed any other
## way - and they are funded by the third Feather at x=3060.
var feather_marks: Array[float] = [2000.0, 2240.0, 2320.0, 2620.0,
	3120.0, 3360.0, 3500.0, 3700.0, 4020.0, 4360.0, 4440.0, 4620.0, 4773.0]
var next_jump: int = 0
var next_feather: int = 0

func step(player: CharacterBody2D, game: Node2D = null) -> void:
	player.test_control = true
	player.test_axis = 1.0
	player.test_jump_held = false
	if next_jump < jump_marks.size() and player.position.x >= jump_marks[next_jump] and player.is_on_floor():
		player.test_jump_pressed = true
		next_jump += 1
	if game == null:
		return
	# Grounded gate keeps each reversal deterministic: inverted, "grounded"
	# means standing on a ceiling.
	if next_feather < feather_marks.size() and player.position.x >= feather_marks[next_feather] \
		and player.is_on_floor():
		# The Feather recharges now rather than being stockpiled, so a mark can
		# be reached before the charge is back. Wait on the spot instead of
		# walking off the edge - which is what a player would do.
		if game.reversal_ticks > 0 or game.feather_charges > 0:
			game.test_feather_pressed = true
			next_feather += 1
		else:
			player.test_axis = 0.0
