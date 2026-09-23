extends SceneTree
## Captures the 03 / DON'T STOP extension from real play: both branches of the
## fork, a ledge mid-collapse, the raised hazard, and an actual fall death.
## Scripted input only - these are not human playtest evidence.
## Added for walker-jumpman-narasimha-v.
const Game = preload("res://game/session.gd")
var game: Node2D
var output: String

# HIGH / FAST branch: the shipped route fixture.
const UPPER := [138.0, 292.0, 424.0, 548.0, 712.0, 944.0, 1072.0, 1200.0, 1352.0, 1468.0, 1580.0]
# LOW / SAFE branch: no jump at the junction, so the player walks off into the drop.
const LOWER := [138.0, 292.0, 424.0, 548.0, 712.0, 944.0, 1072.0, 1200.0, 1490.0, 1640.0]

func step() -> void:
	await physics_frame
	await process_frame

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(output + "/" + label + ".png")
	assert(error == OK)
	print("Captured: " + label)

func fresh() -> void:
	if is_instance_valid(game):
		game.queue_free()
		await process_frame
	game = Game.new()
	game.test_mode = true
	root.add_child(game)
	game.start_session()
	game.player.test_control = true
	await step()
	await step()

func drive(marks: Array, next: int) -> int:
	# One tick of forward input, jumping at the next mark once grounded.
	var p: CharacterBody2D = game.player
	p.test_control = true
	p.test_axis = 1.0
	p.test_jump_held = false
	if next < marks.size() and p.position.x >= marks[next] and p.is_on_floor():
		p.test_jump_pressed = true
		next += 1
	return next

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	output = ProjectSettings.globalize_path("res://../evidence/extension")
	DirAccess.make_dir_recursive_absolute(output)

	# --- HIGH / FAST branch ---
	await fresh()
	var next := 0
	var shots := {1035.0: "20-crumble-shaking", 1180.0: "21-second-ledge",
		1300.0: "22-the-fork", 1440.0: "23-high-road", 1590.0: "24-raised-hazard"}
	var taken := {}
	for i in range(900):
		next = drive(UPPER, next)
		await step()
		for mark in shots:
			if not taken.has(mark) and game.player.position.x >= mark:
				taken[mark] = true
				await capture(shots[mark])
		if game.state != Game.State.PLAYING:
			break
	assert(game.state == Game.State.COMPLETE, "upper branch did not complete")
	await capture("25-upper-complete")
	print("UPPER: complete, %d deaths" % game.deaths)

	# --- LOW / SAFE branch ---
	await fresh()
	next = 0
	var low_taken := false
	for i in range(900):
		next = drive(LOWER, next)
		await step()
		if not low_taken and game.player.position.x >= 1430.0:
			low_taken = true
			await capture("26-low-road")
		if game.state != Game.State.PLAYING:
			break
	assert(game.state == Game.State.COMPLETE, "lower branch did not complete")
	await capture("27-lower-complete")
	print("LOWER: complete, %d deaths" % game.deaths)

	# --- Standing still on a crumbling ledge: the failure the section is about ---
	await fresh()
	next = 0
	for i in range(900):
		next = drive(UPPER, next)
		await step()
		if game.player.position.x > 1030.0 and game.player.is_on_floor():
			break
	assert(game.player.is_on_floor(), "never landed on the first crumbling ledge")
	await capture("28-standing-on-cracks")
	game.player.test_axis = 0.0
	for i in range(28):
		await step()
	await capture("29-about-to-give-way")
	# Count deaths rather than sampling for the DYING state: writing a PNG can
	# outlast the ~34-tick retry window and miss it entirely.
	var deaths_before: int = game.deaths
	var fell := false
	var died := false
	for i in range(300):
		game.player.test_axis = 0.0
		await step()
		if not fell and game.player.position.y > 340.0:
			fell = true
			print("  falling at i=%d y=%.1f" % [i, game.player.position.y])
			await capture("30-ledge-gave-way")
		if game.state == Game.State.DYING:
			died = true
			await capture("31-death-and-retry")
			break
		if game.deaths > deaths_before:
			died = true
			break
		if i % 40 == 0:
			print("  i=%d pos=(%.1f,%.1f) state=%d ledge0=%d/%d" % [
				i, game.player.position.x, game.player.position.y, game.state,
				int(game.crumble_ledges[0].state), int(game.crumble_ledges[0].timer)])
	assert(died, "standing on a crumbling ledge did not kill")
	print("STALL: died as expected, deaths=%d" % game.deaths)

	game.queue_free()
	await process_frame
	quit()
