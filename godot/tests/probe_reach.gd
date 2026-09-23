extends SceneTree
## Measures the real jump envelope from the unmodified tuning, so level geometry
## can be designed against measured reach instead of arithmetic. Reports, for a
## range of landing heights, the furthest horizontal distance a full-speed jump
## still arrives at. Added for walker-jumpman-narasimha-v.
const Game = preload("res://game/session.gd")
var game: Node2D

func _initialize() -> void:
	call_deferred("run")

func step() -> void:
	await physics_frame
	await process_frame

func run() -> void:
	game = Game.new()
	game.test_mode = true
	root.add_child(game)
	game.start_session()
	game.player.test_control = true
	await step()
	await step()

	# Launch from well above the level so nothing is struck during the arc;
	# the recorded flight is then the pure jump envelope.
	var p: CharacterBody2D = game.player
	p.position = Vector2(200, -200)
	p.velocity = Vector2(160, 0)
	p.test_axis = 1.0
	p.require_jump_release = false
	p.opportunity_consumed = false
	p.last_floor_tick = p.tick
	p.test_jump_pressed = true
	var origin := p.position
	var trajectory: Array[Vector2] = []
	for i in range(90):
		await step()
		trajectory.append(p.position - origin)
		if p.is_on_floor():
			break

	var peak: float = 0.0
	for d in trajectory:
		peak = maxf(peak, -d.y)
	print("measured peak rise: %.2f px over %d recorded ticks" % [peak, trajectory.size()])
	print("landing_dy  max_dx  (dy>0 = landing BELOW takeoff)")
	for dy in [-48, -40, -32, -24, -16, -8, 0, 8, 16, 24, 32, 48, 64, 84, 100]:
		var best: float = -1.0
		for d in trajectory:
			if d.y <= float(dy):
				best = maxf(best, d.x)
		if best >= 0.0:
			print("  %+5d     %6.1f" % [dy, best])
		else:
			print("  %+5d     unreachable" % dy)
	game.queue_free()
	await process_frame
	quit()
