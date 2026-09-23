extends RefCounted
## Fixed input route through the real level. No position/velocity edits.
## The first five marks are the starter's, unchanged, and still clear the original
## section. Five more were added for the 03 / DON'T STOP extension: the original
## fixture stopped at the old finish (x=916), which is now open platform.
## This route takes the HIGH / FAST branch, so it also exercises the crumbling
## ledges under their real collapse timer.
var jump_marks: Array[float] = [138.0, 292.0, 424.0, 548.0, 712.0,
	944.0, 1072.0, 1200.0, 1352.0, 1468.0, 1580.0]
var next_jump: int = 0

func step(player: CharacterBody2D) -> void:
	player.test_control = true
	player.test_axis = 1.0
	player.test_jump_held = false
	if next_jump < jump_marks.size() and player.position.x >= jump_marks[next_jump] and player.is_on_floor():
		player.test_jump_pressed = true
		next_jump += 1
