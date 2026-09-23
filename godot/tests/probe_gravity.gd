extends SceneTree
## Proves inverted gravity before any level is built around it: the player must
## rise, settle against a ceiling, register as grounded there, jump downward from
## it, and fall normally again once gravity is restored.
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
	# A ceiling slab above the spawn platform to land on while inverted.
	game._add_solid(Rect2(0, 150, 448, 16))
	await step()

	var p: CharacterBody2D = game.player
	print("normal:   pos=(%.1f, %.1f) floor=%s" % [p.position.x, p.position.y, str(p.is_on_floor())])

	p.gravity_sign = -1.0
	var rose := false
	for i in range(80):
		await step()
		if p.is_on_floor() and p.position.y < 250.0:
			rose = true
			break
	print("inverted: pos=(%.1f, %.1f) floor=%s  (expect y=166, floor=true)" % [
		p.position.x, p.position.y, str(p.is_on_floor())])
	print("  reached ceiling: %s" % str(rose))

	# Jump while inverted should move the player downward, away from the ceiling.
	var before: float = p.position.y
	p.test_jump_pressed = true
	p.require_jump_release = false
	var peak: float = before
	for i in range(25):
		await step()
		peak = maxf(peak, p.position.y)
	print("  inverted jump drop: %.1f px, jumps=%d (expect ~56)" % [peak - before, p.jumps])

	# Wait for the player to settle back on the ceiling, then restore gravity.
	for i in range(40):
		await step()
		if p.is_on_floor():
			break
	p.gravity_sign = 1.0
	for i in range(90):
		await step()
		if p.is_on_floor() and p.position.y > 250.0:
			break
	print("restored: pos=(%.1f, %.1f) floor=%s  (expect y=320, floor=true)" % [
		p.position.x, p.position.y, str(p.is_on_floor())])
	quit()
