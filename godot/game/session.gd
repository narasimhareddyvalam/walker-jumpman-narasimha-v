extends Node2D

const Player = preload("res://features/player/player.gd")
const Hud = preload("res://ui/hud.gd")
enum State { MENU, PLAYING, PAUSED, DYING, COMPLETE }
## Ticks a crumbling ledge supports the player after first contact. Deliberately
## generous: the section's difficulty is meant to come from the chain of jumps,
## not from an unreadable timer.
const CRUMBLE_TICKS: int = 36
## Ticks of falling debris drawn after a ledge gives way.
const DEBRIS_TICKS: int = 40
enum Crumble { INTACT, SHAKING, COLLAPSED }
## Ticks a single Feather charge holds gravity inverted before it snaps back.
const REVERSAL_TICKS: int = 180
# Palette. The starter's cream-and-teal scheme was replaced outright, and the
# two schemes below are the theme rather than decoration: upright, the facility
# is pale, flat and legible - the comfortable lie the world renders for you.
# Inverted, it is the near-black place the Feather reveals. Gravity chooses,
# so the player never has to be told which world they are standing in.
const LIGHT := {
	"void": Color("e8ecf1"), "slab": Color("9fadbd"), "edge": Color("46586b"),
	"hazard": Color("c0392b"), "cold": Color("17708c"),
	"text_warn": Color("8a5520"), "text_dim": Color("46586b"), "text_faint": Color("8593a1"),
	"strata_far": Color("d2d9e2"), "strata_near": Color("c2ccd7"),
	"fog": Color(0.35, 0.45, 0.55, 0.05), "debris": Color(0.30, 0.40, 0.50, 0.25),
	"crack": Color(0.35, 0.42, 0.50, 0.9), "accent": Color("b5731a"),
	"shard": Color("0d4a5e"), "shard_line": Color("2a8fad"),
}
const DARK := {
	"void": Color("080c11"), "slab": Color("161e28"), "edge": Color("4d7283"),
	"hazard": Color("b8433a"), "cold": Color("8fe3ff"),
	"text_warn": Color("b8894e"), "text_dim": Color("7e929d"), "text_faint": Color("52646e"),
	"strata_far": Color("0f1620"), "strata_near": Color("131d29"),
	"fog": Color(0.42, 0.58, 0.68, 0.035), "debris": Color(0.47, 0.64, 0.73, 0.20),
	"crack": Color(0.10, 0.14, 0.19, 0.9), "accent": Color("e0a04a"),
	"shard": Color("cdefff"), "shard_line": Color("5fa8c4"),
}
var state: State = State.MENU
## Free-running clock for drifting debris and the Feather's idle motion. Not
## gameplay state: it keeps running while paused so the world never looks frozen.
var world_tick: int = 0
var crumble_ledges: Array[Dictionary] = []
var feathers: Array[Dictionary] = []
var feather_charges: int = 0
var reversal_ticks: int = 0
var test_feather_pressed: bool = false
var player: CharacterBody2D
var camera: Camera2D
var hud: Control
var level: Dictionary
var hazard_areas: Array[Area2D] = []
var goal: Area2D
var deaths: int = 0
var elapsed: float = 0.0
var retry_remaining: float = 0.0
var death_reason: String = ""
var last_finish_time: float = 0.0
var test_mode: bool = false
var contact_settle_ticks: int = 0

func _ready() -> void:
	process_physics_priority = 10
	level = JSON.parse_string(FileAccess.get_file_as_string("res://levels/first_steps.json"))
	_setup_input()
	for entry in level.solids:
		_add_solid(Rect2(entry[0], entry[1], entry[2], entry[3]))
	# Hidden geometry is built exactly like any other solid. It is only the
	# drawing that withholds it, so collision can never disagree with the world.
	for entry in level.get("hidden", []):
		_add_solid(Rect2(entry[0], entry[1], entry[2], entry[3]))
	# Phantom geometry is deliberately never built. It exists only in _draw().
	_add_solid(Rect2(-32, 0, 32, 430))
	_add_solid(Rect2(level.width, 0, 32, 430))
	for entry in level.get("crumbling", []):
		_add_crumble(Rect2(entry[0], entry[1], entry[2], entry[3]))
	for entry in level.get("feathers", []):
		feathers.append({"pos": Vector2(entry[0], entry[1]), "charges": int(entry[2]), "taken": false})
	for entry in level.hazards:
		hazard_areas.append(_add_area(Rect2(entry[0], entry[1], entry[2], entry[3]), 8, true))
	var f: Array = level.finish
	goal = _add_area(Rect2(f[0], f[1], f[2], f[3]), 16, false)
	player = Player.new()
	add_child(player)
	player.reset_at(Vector2(level.spawn[0], level.spawn[1]))
	camera = Camera2D.new()
	camera.position = Vector2(320, 180)
	add_child(camera)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.game = self
	layer.add_child(hud)
	get_window().focus_exited.connect(_on_focus_lost)
	queue_redraw()

func _setup_input() -> void:
	# "feather" is the one added control. Move, jump, retry, pause, confirm and
	# menu keep the starter's bindings exactly.
	var actions := {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "jump": [KEY_SPACE], "pause": [KEY_ESCAPE, KEY_P], "restart": [KEY_R], "confirm": [KEY_ENTER], "menu": [KEY_M], "feather": [KEY_F, KEY_SHIFT]}
	for action in actions:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in actions[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

func _add_solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size / 2
	body.collision_layer = 1
	body.collision_mask = 2
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _add_crumble(rect: Rect2) -> void:
	# Same static body as any solid, plus the state needed to withdraw it.
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size / 2
	body.collision_layer = 1
	body.collision_mask = 2
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	crumble_ledges.append({"rect": rect, "body": body, "shape": collision,
		"state": Crumble.INTACT, "timer": 0, "debris": 0})

func _player_standing_on(rect: Rect2) -> bool:
	# Feet resting on this ledge's top surface, within the ledge's horizontal span.
	if not player.is_on_floor():
		return false
	if absf(player.position.y - rect.position.y) > 3.0:
		return false
	return player.position.x + 9.0 > rect.position.x and player.position.x - 9.0 < rect.end.x

func _update_crumble() -> void:
	for ledge in crumble_ledges:
		match int(ledge.state):
			Crumble.INTACT:
				if _player_standing_on(ledge.rect):
					ledge.state = Crumble.SHAKING
					ledge.timer = CRUMBLE_TICKS
			Crumble.SHAKING:
				ledge.timer -= 1
				if ledge.timer <= 0:
					ledge.state = Crumble.COLLAPSED
					ledge.debris = 0
					# Deferred: collision state cannot be mutated mid-query.
					ledge.shape.set_deferred("disabled", true)
			Crumble.COLLAPSED:
				ledge.debris += 1

func use_feather() -> void:
	if reversal_ticks > 0:
		# Cancelling early costs the charge anyway. Choosing the moment to flip
		# back is the skill; a refund would make holding it strictly better.
		restore_gravity()
	elif feather_charges > 0:
		feather_charges -= 1
		reversal_ticks = REVERSAL_TICKS
		player.gravity_sign = -1.0

func restore_gravity() -> void:
	reversal_ticks = 0
	if is_instance_valid(player):
		player.gravity_sign = 1.0

func _update_feathers() -> void:
	var body := Rect2(player.position.x - 9.0, player.position.y - 28.0, 18.0, 28.0)
	for f in feathers:
		if f.taken:
			continue
		if body.intersects(Rect2(f.pos.x - 9.0, f.pos.y - 9.0, 18.0, 18.0)):
			f.taken = true
			feather_charges += int(f.charges)

func _reset_feathers() -> void:
	feather_charges = 0
	restore_gravity()
	for f in feathers:
		f.taken = false

func _reset_crumble() -> void:
	for ledge in crumble_ledges:
		ledge.state = Crumble.INTACT
		ledge.timer = 0
		ledge.debris = 0
		ledge.shape.set_deferred("disabled", false)

func _add_area(rect: Rect2, layer: int, spikes: bool) -> Area2D:
	var area := Area2D.new()
	area.position = rect.position
	area.collision_layer = layer
	area.collision_mask = 2
	if spikes:
		# Three exact triangular trigger silhouettes; no oversized invisible box.
		for i in range(3):
			var triangle := CollisionPolygon2D.new()
			var x := float(i) * rect.size.x / 3.0
			triangle.polygon = PackedVector2Array([Vector2(x, rect.size.y), Vector2(x + 4, 0), Vector2(x + 8, rect.size.y)])
			area.add_child(triangle)
	else:
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		collision.shape = shape
		collision.position = rect.size / 2.0
		area.add_child(collision)
	add_child(area)
	return area

func start_session() -> void:
	if state == State.PLAYING:
		return
	deaths = 0
	restart_attempt()

func restart_attempt() -> void:
	state = State.PLAYING
	elapsed = 0.0
	retry_remaining = 0.0
	# Area2D overlaps are physics-step snapshots. Discard pre-teleport contacts
	# until the broadphase has observed the reset, preventing a phantom second death.
	contact_settle_ticks = 2
	_reset_crumble()
	_reset_feathers()
	player.reset_at(Vector2(level.spawn[0], level.spawn[1]))
	player.enabled = true
	camera.position = Vector2(320, 180)

func set_paused(value: bool) -> void:
	if value and state == State.PLAYING:
		state = State.PAUSED
		player.enabled = false
	elif not value and state == State.PAUSED:
		state = State.PLAYING
		player.enabled = true
		player.require_jump_release = true
		player.jump_request_tick = -1000

func _on_focus_lost() -> void:
	if not test_mode:
		set_paused(true)

func resolve_contacts(fatal: bool, finished: bool) -> void:
	if state != State.PLAYING:
		return
	if fatal:
		state = State.DYING
		deaths += 1
		retry_remaining = 0.55
		player.enabled = false
		player.velocity = Vector2.ZERO
	elif finished:
		state = State.COMPLETE
		last_finish_time = elapsed
		player.enabled = false
		player.velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if state == State.DYING:
		retry_remaining -= delta
		if retry_remaining <= 0:
			restart_attempt()
	elif state == State.PLAYING:
		elapsed += delta
		_update_crumble()
		_update_feathers()
		var feather_pressed := Input.is_action_just_pressed("feather") or test_feather_pressed
		test_feather_pressed = false
		if feather_pressed:
			use_feather()
		if reversal_ticks > 0:
			reversal_ticks -= 1
			if reversal_ticks <= 0:
				restore_gravity()
		# Inverted gravity makes the sky lethal too: falling upward out of the
		# level is exactly as fatal as falling into the pit.
		var below := player.position.y > float(level.fall_y)
		var above := player.position.y < float(level.get("sky_y", -400))
		var fatal := below or above
		death_reason = "Watch the spikes"
		if above:
			death_reason = "You fell into the sky"
		elif below:
			death_reason = "Missed the landing"
		for hazard in hazard_areas:
			fatal = fatal or hazard.overlaps_body(player)
		if contact_settle_ticks > 0:
			contact_settle_ticks -= 1
		else:
			resolve_contacts(fatal, goal.overlaps_body(player))
		camera.position.x = clampf(player.position.x + 100, 320, float(level.width) - 320)
	# The starter drew the world once. Parallax, drifting debris and collapsing
	# ledges are camera- and time-dependent, so the world redraws with the HUD.
	world_tick += 1
	queue_redraw()
	if is_instance_valid(hud):
		hud.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("confirm"):
		if state in [State.MENU, State.COMPLETE]:
			start_session()
		elif state == State.PAUSED:
			set_paused(false)
	elif event.is_action_pressed("pause"):
		set_paused(state != State.PAUSED)
	elif event.is_action_pressed("restart") and state in [State.PLAYING, State.PAUSED, State.DYING]:
		restart_attempt()
	elif event.is_action_pressed("menu") and state in [State.PAUSED, State.COMPLETE]:
		state = State.MENU
		player.enabled = false
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Rect2(150, 262, 340, 40).has_point(hud.get_local_mouse_position()):
			if state in [State.MENU, State.COMPLETE]:
				start_session()
			elif state == State.PAUSED:
				set_paused(false)

func _draw() -> void:
	if level.is_empty():
		return
	# All artwork is original Godot vector drawing; no imported or purchased art.
	# Every extent derives from level data - the starter hard-coded 960.
	var font := ThemeDB.fallback_font
	var P := pal()
	var w: float = float(level.width)
	var cam_x: float = camera.position.x if is_instance_valid(camera) else 320.0
	var t := float(world_tick)

	draw_rect(Rect2(-600, -600, w + 1200, 1600), P.void)
	# Two parallax strata. The far layer hangs from the ceiling rather than
	# rising from the ground: the skyline is already inverted before the player
	# is told anything is wrong.
	_draw_strata(cam_x, 0.74, P.strata_far, 142.0, 300.0, true)
	_draw_strata(cam_x, 0.48, P.strata_near, 168.0, 430.0, false)
	_draw_debris(cam_x, t)
	for i in range(3):
		draw_rect(Rect2(cam_x - 380.0, 96.0 + float(i) * 86.0, 760.0, 40.0), P.fog)

	for entry in level.solids:
		_draw_slab(Rect2(entry[0], entry[1], entry[2], entry[3]))
	# A phantom is painted exactly like real ground - that is the whole lie.
	# A revealed hidden floor gets its own treatment so truth reads as truth.
	for r in _belief_slabs():
		if inverted():
			_draw_revealed(r)
		else:
			_draw_slab(r)
	_draw_crumble()
	_draw_feathers(t)

	# Spikes are drawn from the hazard's own rect. The starter drew every spike
	# at a literal y=320/304 while _add_area built the trigger from the real
	# rect, so a raised hazard rendered detached from what actually kills you.
	for entry in level.hazards:
		var hr := Rect2(entry[0], entry[1], entry[2], entry[3])
		for i in range(3):
			var hx: float = hr.position.x + float(i) * hr.size.x / 3.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(hx, hr.end.y), Vector2(hx + 4, hr.position.y), Vector2(hx + 8, hr.end.y)]), P.hazard)

	# The observatory doorway, drawn on its own trigger rect rather than on the
	# ground, so what the player reads is where the level actually ends.
	var fr := Rect2(level.finish[0], level.finish[1], level.finish[2], level.finish[3])
	draw_rect(fr, Color(P.cold.r, P.cold.g, P.cold.b, 0.10))
	draw_rect(Rect2(fr.position.x, fr.end.y - 2.0, fr.size.x, 2.0), Color(P.cold.r, P.cold.g, P.cold.b, 0.65))
	for i in range(5):
		var gx: float = fr.position.x + fr.size.x * (0.1 + 0.2 * float(i))
		var pulse: float = 0.25 + 0.22 * sin(t * 0.05 + float(i))
		draw_line(Vector2(gx, fr.end.y), Vector2(gx, fr.position.y + 6.0), Color(P.cold.r, P.cold.g, P.cold.b, pulse), 1.0)

	_sign(font, Vector2(33, 251), "01 / GET MOVING", 15, P.text_dim)
	_sign(font, Vector2(33, 273), "Read the landing. Then jump.", 13, P.text_faint)
	_sign(font, Vector2(474, 227), "02 / MIND THE GAP", 15, P.text_dim)
	_sign(font, Vector2(958, 196), "SITE 07 / GRAVITATIONAL RESEARCH", 15, P.text_warn)
	_sign(font, Vector2(958, 216), "STRUCTURAL COHESION FAILING", 13, P.text_faint)
	_sign(font, Vector2(1386, 196), "UPPER GANTRY", 13, P.text_warn)
	_sign(font, Vector2(1376, 308), "LOWER DECK", 13, P.text_dim)
	_sign(font, Vector2(1878, 236), "ANOMALY RECOVERED HERE", 12, P.text_faint)
	_sign(font, Vector2(2042, 250), "THE FLOOR IS NOT THE ONLY FLOOR", 13, P.text_faint)
	# The INVERSION corridor. Every warning the player needs is written down:
	# the Betrayal punishes assuming, not reading.
	# Staggered in y as well as x: at 13px these strings run ~7px per character
	# and neighbouring signs overlapped when they shared a baseline.
	_sign(font, Vector2(2806, 236), "WALK. DO NOT JUMP.", 13, P.text_warn)
	_sign(font, Vector2(3002, 212), "YOU WERE NEVER FALLING", 13, P.text_faint)
	_sign(font, Vector2(3160, 236), "IT IS NOT THE SAME GAP", 13, P.text_warn)
	_sign(font, Vector2(3352, 212), "BELIEF RENDERS. TRUTH DOES NOT.", 12, P.text_faint)
	_sign(font, Vector2(3690, 232), "OBSERVATORY", 15, P.text_warn)
	_sign(font, Vector2(3540, 252), "ONLY THOSE WHO CAN FALL UPWARD MAY ENTER", 13, P.cold)

func _sign(font: Font, at: Vector2, text: String, size: int, tint: Color) -> void:
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, tint)

func inverted() -> bool:
	return is_instance_valid(player) and player.gravity_sign < 0.0

## The active scheme. Reading the world's colour from gravity means the light
## and dark worlds can never disagree with which way up the player is.
func pal() -> Dictionary:
	return DARK if inverted() else LIGHT

## Slabs that exist only as appearance. The chapter's law is that the world
## renders what you believe, not what is there: upright vision draws phantoms
## and withholds hidden floors, and inverted vision does the exact reverse.
## Collision is not consulted either way, which is what makes the rule fair -
## the player can always check by flipping.
func _belief_slabs() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for entry in level.get("hidden" if inverted() else "phantom", []):
		out.append(Rect2(entry[0], entry[1], entry[2], entry[3]))
	return out

## Everything _draw() will paint as a slab this frame. Exposed so the checks
## can assert on what the player can see rather than on a screenshot.
func rendered_slabs() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for entry in level.solids:
		out.append(Rect2(entry[0], entry[1], entry[2], entry[3]))
	out.append_array(_belief_slabs())
	return out

func _draw_revealed(r: Rect2) -> void:
	# Hidden geometry showing through under inverted gravity. Drawn unlike a
	# solid on purpose: this is the world admitting to something that was
	# always there, not a platform arriving.
	var c: Color = pal().cold
	draw_rect(r, Color(c.r, c.g, c.b, 0.05))
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 1.0), Color(c.r, c.g, c.b, 0.5))
	var x: float = r.position.x
	while x < r.end.x:
		draw_line(Vector2(x, r.position.y), Vector2(x + 6.0, r.end.y), Color(c.r, c.g, c.b, 0.22), 1.0)
		x += 16.0

func _draw_slab(r: Rect2) -> void:
	# Cold light on the surface the player can stand on. Anything high enough to
	# be a ceiling is lit underneath instead, so lighting reads as orientation.
	var P := pal()
	draw_rect(r, P.slab)
	var ceiling := r.position.y < 200.0
	var surface: float = r.end.y - 2.0 if ceiling else r.position.y
	draw_rect(Rect2(r.position.x, surface, r.size.x, 2.0), P.edge)
	var far_edge: float = r.position.y if ceiling else r.end.y - 1.0
	draw_rect(Rect2(r.position.x, far_edge, r.size.x, 1.0), Color(P.edge.r, P.edge.g, P.edge.b, 0.22))
	# Short ticks hugging the standing surface, so a 64px ground block does not
	# get the same long streaks as a 14px ledge.
	var dir: float = -1.0 if ceiling else 1.0
	for x in range(int(r.position.x) + 12, int(r.end.x) - 6, 24):
		draw_line(Vector2(x, surface + dir * 4.0), Vector2(x + 4.0, surface + dir * 9.0),
			Color(P.edge.r, P.edge.g, P.edge.b, 0.35), 1.0)

func _draw_strata(cam_x: float, depth: float, tint: Color, peak_y: float, spacing: float, hanging: bool) -> void:
	# A layer drawn at base + camera.x * depth scrolls at (1 - depth), so a
	# larger depth reads as further away.
	var shift: float = cam_x * depth
	var lo: int = int(floor((cam_x - 540.0 - shift) / spacing))
	var hi: int = int(ceil((cam_x + 540.0 - shift) / spacing))
	for i in range(lo, hi + 1):
		var x: float = float(i) * spacing + shift
		var base_y: float = 70.0 if hanging else 344.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 155.0, base_y), Vector2(x, peak_y), Vector2(x + 155.0, base_y)]), tint)

func _draw_debris(cam_x: float, t: float) -> void:
	# Rubble drifting upward. The first thing the player should notice is that
	# loose matter is leaving the ground.
	for i in range(34):
		var bx: float = cam_x - 400.0 + fmod(float(i) * 211.0, 820.0)
		var rate: float = 0.22 + fmod(float(i) * 0.41, 0.55)
		var by: float = fposmod(340.0 - t * rate + float(i) * 47.0, 300.0) + 52.0
		var s: float = 2.0 + fmod(float(i), 3.0)
		draw_rect(Rect2(bx, by, s, s), pal().debris)

func _draw_feathers(t: float) -> void:
	var P := pal()
	for f in feathers:
		if f.taken:
			continue
		var c: Vector2 = Vector2(f.pos.x, f.pos.y + sin(t * 0.05) * 2.5)
		draw_circle(c, 10.0, Color(P.cold.r, P.cold.g, P.cold.b, 0.07))
		draw_circle(c, 5.5, Color(P.cold.r, P.cold.g, P.cold.b, 0.13))
		# A machined shard, not a plume: this object belongs to the facility.
		draw_colored_polygon(PackedVector2Array([
			Vector2(c.x, c.y - 8.0), Vector2(c.x + 3.0, c.y - 2.0),
			Vector2(c.x + 2.0, c.y + 7.0), Vector2(c.x - 2.0, c.y + 7.0),
			Vector2(c.x - 3.0, c.y - 2.0)]), P.shard)
		draw_line(Vector2(c.x, c.y - 6.0), Vector2(c.x, c.y + 5.0), P.shard_line, 1.0)
		# It falls upward in place, which is the only hint of what it does.
		for k in range(3):
			var m: float = fposmod(t * 0.7 + float(k) * 9.0, 27.0)
			draw_rect(Rect2(c.x - 1.0, c.y + 9.0 - m, 2.0, 2.0),
				Color(P.cold.r, P.cold.g, P.cold.b, 0.30 * (1.0 - m / 27.0)))

func _draw_crumble() -> void:
	var P := pal()
	for ledge in crumble_ledges:
		var r: Rect2 = ledge.rect
		if int(ledge.state) == Crumble.COLLAPSED:
			var f: float = float(ledge.debris)
			if f >= float(DEBRIS_TICKS):
				continue
			for i in range(3):
				var cw: float = r.size.x / 3.0
				draw_rect(Rect2(r.position.x + float(i) * cw + (float(i) - 1.0) * f * 0.35,
					r.position.y + f * f * 0.11, cw - 2.0, r.size.y),
					Color(P.slab.r, P.slab.g, P.slab.b, 1.0 - f / float(DEBRIS_TICKS)))
			continue
		var shake: float = sin(float(ledge.timer) * 1.1) * 1.6 if int(ledge.state) == Crumble.SHAKING else 0.0
		var dr := Rect2(r.position + Vector2(shake, 0.0), r.size)
		draw_rect(dr, P.slab)
		# A broken cap, where solid ground gets an unbroken one, marks these as
		# unreliable before the player ever touches them.
		var accent := Color(P.edge.r, P.edge.g, P.edge.b, 0.55)
		if int(ledge.state) == Crumble.SHAKING:
			accent = P.hazard.lerp(P.accent, float(ledge.timer) / float(CRUMBLE_TICKS))
		var seg: float = dr.size.x / 5.0
		for i in range(3):
			draw_rect(Rect2(dr.position.x + float(i) * seg * 2.0, dr.position.y, seg, 2.0), accent)
		for i in range(2):
			var cx: float = dr.position.x + dr.size.x * (0.34 + 0.32 * float(i))
			draw_line(Vector2(cx, dr.position.y + 2.0), Vector2(cx + 2.0, dr.end.y), P.crack, 1.0)
