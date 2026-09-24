extends SceneTree
## Captures Chapter One from real play: the anomaly, the Feather, inverted
## traversal, the tower door, and genuine deaths in both directions.
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
		1968.0: "23a-the-power-unlocked",
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
		3800.0: "32-the-locked-door",
		3995.0: "33-the-hazard-was-a-lie",
		4150.0: "34-inverted-over-the-spikes",
		4350.0: "35-the-gantry-gave-way",
		4470.0: "36-section-clear-was-a-lie",
		4620.0: "37-the-mirror-ledge",
		4760.0: "38-the-tower-door",
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
	# Withhold the flip-back at the end of the 2300-2640 ceiling, so the route
	# plays normally and then runs off that ceiling still inverted. That ceiling
	# has the most open sky after it - the next is at 3100, 460px away - which
	# leaves the widest margin before the reversal expires.
	#
	# Note for anyone reading the history: two earlier commits blamed the choice
	# of ledge for this sequence failing. That was wrong. probe_sky.gd showed the
	# original ledge killed the player perfectly well; the failure was the
	# harness sampling the death count after a blocking capture. The ledge here
	# is a margin improvement, not the fix.
	route.feather_marks = route.feather_marks.filter(func(m): return m < 2600.0)
	var sky_shot := false
	for i in range(3600):
		if game.deaths > deaths_seen:
			deaths_seen = game.deaths
			route = Route.new()
			route.feather_marks = route.feather_marks.filter(func(m): return m < 2600.0)
		route.step(game.player, game)
		await step()
		# Taken while still ON the ceiling, with open sky past its end. Every
		# previous version took it after the break, which put a ~33-tick render
		# call directly in front of a death that arrives in ~30 - the death kept
		# landing inside the screenshot.
		if not sky_shot and game.player.gravity_sign < 0.0 and game.player.is_on_floor() \
			and game.player.position.x > 2560.0:
			sky_shot = true
			await capture("40-inverted-at-the-edge")
		if game.player.position.x > 2650.0 and game.player.gravity_sign < 0.0:
			break
		if game.state != Game.State.PLAYING:
			break
	assert(sky_shot, "never captured the inverted run before the ceiling ended")
	# Sampled BEFORE the capture. capture() awaits a render frame and the engine
	# keeps stepping physics through it - measured at roughly 30 ticks, which is
	# exactly how long this player takes to reach the sky bound. Sampling after
	# the shot meant the death landed inside the PNG write and the count below
	# could never see it. The route was right all along; the harness was eating
	# the event.
	# No screenshot is attempted between here and the death. A capture costs
	# about 33 physics ticks - measured - and the player reaches the sky bound in
	# about 30, so any shot in this window swallows the event it is meant to
	# record. Shot 40 above is the evidence of the setup; the death itself is
	# proved by the count below and by sky-is-fatal in the mechanics suite.
	# Photographing it is simply not possible at this capture cost, and claiming
	# otherwise is how this file produced a mislabelled image once already.
	var sky_deaths: int = game.deaths
	var died := false
	var sky_reason := ""
	for i in range(240):
		game.player.test_axis = 1.0
		await step()
		if game.state == Game.State.DYING:
			died = true
			sky_reason = game.death_reason
			break
		if game.deaths > sky_deaths:
			died = true
			sky_reason = "(counted)"
			break
	assert(died, "running off the ceiling inverted did not kill")
	print("SKY: died as expected, reason=%s" % sky_reason)

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
	var pit_reason := ""
	var pit_shot := false
	for i in range(300):
		game.player.test_axis = 0.0
		await step()
		# The interesting frame is the ledge already gone and the player falling
		# through the hole, which is well before the death. Taking it at DYING
		# produced a picture of the spawn point.
		if not pit_shot and game.state == Game.State.PLAYING and not game.player.is_on_floor():
			for ledge in game.crumble_ledges:
				if int(ledge.state) == Game.Crumble.COLLAPSED \
					and absf(game.player.position.x - (ledge.rect.position.x + ledge.rect.size.x * 0.5)) < 90.0:
					pit_shot = true
					break
			if pit_shot:
				await capture("42-ground-gave-way")
		if game.state == Game.State.DYING:
			fell = true
			pit_reason = game.death_reason
			break
		if game.deaths > pit_deaths:
			fell = true
			pit_reason = "(counted; death landed inside a capture)"
			break
	assert(fell, "standing on dissolving ground did not kill")
	assert(pit_shot, "never saw the ledge collapse under the player")
	print("PIT: died as expected, reason=%s" % pit_reason)

	game.queue_free()
	await process_frame
	quit()
