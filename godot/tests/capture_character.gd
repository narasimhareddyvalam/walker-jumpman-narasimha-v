extends SceneTree
## Renders the player in each required readability state at high zoom, with an
## optional collider outline, so visual/collision alignment can be judged from
## real pixels rather than description. Added for walker-jumpman-narasimha-v.
const Game = preload("res://game/session.gd")
var game: Node2D
var output: String
var overlay: Node2D

func step() -> void:
	await physics_frame
	await process_frame

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(output + "/" + label + ".png")
	assert(error == OK)
	print("Captured: " + label)

func freeze_and_frame() -> void:
	# Hold the pose: a disabled player keeps its last velocity and floor state,
	# and a non-PLAYING session stops overwriting the camera.
	game.player.enabled = false
	game.state = Game.State.PAUSED
	game.hud.visible = false
	game.camera.zoom = Vector2(7, 7)
	game.camera.position = game.player.position + Vector2(0, -14)

func run_to_speed(axis: float) -> void:
	# Stage on the third platform (x 784..960): the only stretch with no step or
	# hazard, so the run actually reaches full speed instead of hitting geometry.
	# Run length stops short of the finish trigger at x=916; completing the level
	# would disable the player and zero the velocity the trail reports.
	game.player.position = Vector2(790 if axis > 0 else 900, 320)
	game.player.velocity = Vector2.ZERO
	game.player.enabled = true
	game.state = Game.State.PLAYING
	game.player.test_control = true
	game.player.test_axis = axis
	for i in range(26):
		await step()

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
	if overlay_enabled:
		overlay = Node2D.new()
		overlay.z_index = 10
		var target: Node2D = game.player
		overlay.draw.connect(func() -> void:
			overlay.draw_rect(Rect2(-9, -28, 18, 28), Color(0.85, 0.2, 0.2, 0.9), false, 1.0)
			overlay.draw_line(Vector2(-11, 0), Vector2(11, 0), Color(0.85, 0.2, 0.2, 0.55), 1.0))
		target.add_child(overlay)
		overlay.queue_redraw()

var overlay_enabled: bool = false

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	output = ProjectSettings.globalize_path("res://../evidence/character")
	DirAccess.make_dir_recursive_absolute(output)
	for pass_index in range(2):
		overlay_enabled = pass_index == 1
		var tag := "-collider" if overlay_enabled else ""

		await fresh()
		game.player.test_axis = 0.0
		for i in range(10):
			await step()
		freeze_and_frame()
		await capture("01-standing" + tag)

		await fresh()
		await run_to_speed(1.0)
		freeze_and_frame()
		await capture("02-running-right" + tag)

		await fresh()
		await run_to_speed(-1.0)
		freeze_and_frame()
		await capture("03-running-left" + tag)

		await fresh()
		await run_to_speed(1.0)
		game.player.test_jump_pressed = true
		for i in range(14):
			await step()
		freeze_and_frame()
		await capture("04-jumping-right" + tag)

		await fresh()
		await run_to_speed(-1.0)
		game.player.test_jump_pressed = true
		for i in range(14):
			await step()
		freeze_and_frame()
		await capture("05-jumping-left" + tag)

	print("CHARACTER PREVIEW: complete")
	game.queue_free()
	await process_frame
	quit()
