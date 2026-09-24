extends SceneTree
## Captures Chapter One from real play: the anomaly, the Feather, inverted
## traversal, the observatory door, and genuine deaths in both directions.
## Scripted input only - no teleporting, no forced completion, no disabled
## collision. These are NOT human playtest evidence.
const Game = preload("res://game/session.gd")
const Route = preload("res://tests/route_driver.gd")
var game: Node2D
var output: String

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

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	output = ProjectSettings.globalize_path("res://../evidence/extension")
	DirAccess.make_dir_recursive_absolute(output)

	# --- Full chapter on the shipped route fixture ---
	await fresh()
	var route = Route.new()
	# Capture points sit in mid-air or on solid ground, never while the player is
	# stood on a dissolving ledge: writing a PNG costs physics ticks during which
	# the fixture cannot feed inputs, and a lost tick there is a death.
	var shots := {
		# The opening premise and the reversal-pad prompt, both added after the
		# playtest reported the story and the F key were unreadable.
		100.0: "19-the-premise",
		1985.0: "23b-press-f-here",
		1120.0: "20-ground-dissolving",
		1300.0: "21-the-fork",
		1700.0: "22-raised-hazard",
		1935.0: "23-the-feather",
		2100.0: "24-inverted-ceiling",
		2420.0: "25-second-reversal",
		2690.0: "26-second-feather",
		# The INVERSION corridor. 29 is the one that matters: inverted, with the
		# hidden floor rendered behind the player and the Betrayal gap ahead of
		# them still empty.
		2850.0: "27-void-gap-holding",
		3020.0: "28-you-were-never-falling",
		3180.0: "29-truth-vision",
		3400.0: "30-the-phantom",
		3560.0: "31-phantom-omitted",
		3800.0: "32-sector-sealed",
		3995.0: "33-the-hazard-was-a-lie",
		4150.0: "34-inverted-over-the-spikes",
		4350.0: "35-the-gantry-gave-way",
		4470.0: "36-section-clear-was-a-lie",
		4620.0: "37-the-mirror-ledge",
		4760.0: "38-observatory-door",
	}
	var taken := {}
	var deaths_seen: int = 0
	for i in range(3200):
		# A fixture that has already consumed its early marks cannot replay the
		# level, so restart it with the attempt rather than looping forever.
		if game.deaths > deaths_seen:
			deaths_seen = game.deaths
			route = Route.new()
		route.step(game.player, game)
		await step()
		for mark in shots:
			if not taken.has(mark) and game.player.position.x >= mark:
				taken[mark] = true
				await capture(shots[mark])
		if game.state != Game.State.PLAYING:
			break
	assert(game.state == Game.State.COMPLETE, "chapter route did not complete")
	await capture("39-chapter-ends")
	print("CHAPTER: complete, %d deaths, charges left %d" % [game.deaths, game.feather_charges])

	# --- The Reveal, captured on purpose. On the main route the player flips at
	# x=3120, by which point the hidden floor has scrolled off the left of the
	# screen. Here the route is stopped while still standing on it and the
	# Feather is spent there instead, so one frame shows the floor that was
	# underfoot the whole time. The charge is the one the second Feather really
	# granted - nothing is added and nothing is teleported.
	await fresh()
	route = Route.new()
	deaths_seen = game.deaths
	for i in range(3200):
		if game.deaths > deaths_seen:
			deaths_seen = game.deaths
			route = Route.new()
		route.step(game.player, game)
		await step()
		if game.player.position.x > 2890.0 and game.player.is_on_floor():
			break
	game.player.test_axis = 0.0
	await step()
	await capture("43-standing-on-nothing")
	assert(game.feather_charges >= 1, "no charge in hand on the hidden floor")
	game.test_feather_pressed = true
	await step()
	await step()
	await capture("44-the-floor-was-always-there")
	print("REVEAL: x=%.0f gravity_sign=%.1f" % [game.player.position.x, game.player.gravity_sign])

	# --- Falling into the sky: the failure the new mechanic introduces ---
	await fresh()
	route = Route.new()
	deaths_seen = game.deaths
	for i in range(3200):
		if game.deaths > deaths_seen:
			deaths_seen = game.deaths
			route = Route.new()
		route.step(game.player, game)
		await step()
		# Never cancel the first reversal, so the player runs off the end of the
		# ceiling still inverted.
		if route.next_feather >= 1:
			route.feather_marks.clear()
		if game.player.position.x > 2270.0 and game.player.gravity_sign < 0.0:
			break
		if game.state != Game.State.PLAYING:
			break
	await capture("40-rising-off-the-ceiling")
	var sky_deaths: int = game.deaths
	var died := false
	for i in range(240):
		game.player.test_axis = 1.0
		await step()
		if game.state == Game.State.DYING:
			died = true
			await capture("41-fell-into-the-sky")
			break
		if game.deaths > sky_deaths:
			died = true
			break
	assert(died, "running off the ceiling inverted did not kill")
	print("SKY: died as expected, reason=%s" % game.death_reason)

	# --- Standing still on dissolving ground ---
	await fresh()
	route = Route.new()
	deaths_seen = game.deaths
	for i in range(3200):
		if game.deaths > deaths_seen:
			deaths_seen = game.deaths
			route = Route.new()
		route.step(game.player, game)
		await step()
		if game.player.position.x > 1030.0 and game.player.is_on_floor():
			break
	game.player.test_axis = 0.0
	var pit_deaths: int = game.deaths
	var fell := false
	for i in range(300):
		game.player.test_axis = 0.0
		await step()
		if game.state == Game.State.DYING:
			fell = true
			await capture("42-ground-gave-way")
			break
		if game.deaths > pit_deaths:
			fell = true
			break
	assert(fell, "standing on dissolving ground did not kill")
	print("PIT: died as expected, reason=%s" % game.death_reason)

	game.queue_free()
	await process_frame
	quit()
