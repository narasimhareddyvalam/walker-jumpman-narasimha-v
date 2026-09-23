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
var state: State = State.MENU
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
	# The starter drew the world once. Parallax scenery and collapsing ledges are
	# both camera- and time-dependent, so the world now redraws with the HUD.
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
		if Rect2(220, 215, 200, 34).has_point(hud.get_local_mouse_position()):
			if state in [State.MENU, State.COMPLETE]:
				start_session()
			elif state == State.PAUSED:
				set_paused(false)

func _draw() -> void:
	if level.is_empty():
		return
	var font := ThemeDB.fallback_font
	var ink := Color("25354a")
	# All visual assets are original Godot vector drawing, not recovered art.
	# Every extent below is derived from level data; the starter hard-coded 960.
	var w: float = float(level.width)
	draw_rect(Rect2(-400, -200, w + 800, 900), Color("f6f3ec"))
	var cam_x: float = camera.position.x if is_instance_valid(camera) else 320.0
	_draw_ridges(cam_x, 0.70, Color("edefea"), 148.0, 260.0)
	_draw_ridges(cam_x, 0.42, Color("e4e8e3"), 180.0, 370.0)
	for x in range(0, int(w) + 1, 32):
		draw_line(Vector2(x, 80), Vector2(x, 320), Color("e7e5df"), 1)
	for y in range(96, 321, 32):
		draw_line(Vector2(0, y), Vector2(w, y), Color("e7e5df"), 1)
	for entry in level.solids:
		var r := Rect2(entry[0], entry[1], entry[2], entry[3])
		draw_rect(r, ink)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 4)), Color("438e7d"))
		for x in range(int(r.position.x)+12, int(r.end.x), 24):
			draw_line(Vector2(x, r.position.y+12), Vector2(x+7, r.position.y+19), Color("405166"), 1)
	_draw_crumble(ink)
	# Spikes are drawn from the hazard's own rect. The starter drew every spike at
	# a literal y=320/304 while _add_area built the trigger from the real rect, so
	# any raised hazard rendered detached from the thing that actually kills you.
	for entry in level.hazards:
		var hr := Rect2(entry[0], entry[1], entry[2], entry[3])
		for i in range(3):
			var x: float = hr.position.x + float(i) * hr.size.x / 3.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(x, hr.end.y), Vector2(x + 4, hr.position.y), Vector2(x + 8, hr.end.y)]), Color("d24e42"))
	# The finish pole likewise follows its own trigger rect instead of the ground.
	var fr := Rect2(level.finish[0], level.finish[1], level.finish[2], level.finish[3])
	draw_line(Vector2(fr.position.x + 3, fr.end.y), Vector2(fr.position.x + 3, fr.position.y - 14), ink, 3)
	draw_colored_polygon(PackedVector2Array([
		Vector2(fr.position.x + 5, fr.position.y - 14),
		Vector2(fr.position.x + 32, fr.position.y - 4),
		Vector2(fr.position.x + 5, fr.position.y + 10)]), Color("287c68"))
	draw_string(font, Vector2(33, 251), "01 / GET MOVING", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ink)
	draw_string(font, Vector2(33, 273), "Read the landing. Then jump.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ink)
	draw_string(font, Vector2(474, 227), "02 / MIND THE GAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ink)
	draw_string(font, Vector2(975, 202), "03 / DON'T STOP", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ink)
	draw_string(font, Vector2(975, 222), "Cracked ledges do not wait.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ink)
	draw_string(font, Vector2(1396, 196), "HIGH / FAST", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("a2542f"))
	draw_string(font, Vector2(1386, 308), "LOW / SAFE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("2f6a5c"))
	draw_string(font, Vector2(fr.position.x - 48, fr.position.y - 22), "FINISH", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ink)

func _draw_ridges(cam_x: float, depth: float, tint: Color, peak_y: float, spacing: float) -> void:
	# A layer drawn at base + camera.x * depth scrolls on screen at (1 - depth),
	# so a larger depth reads as further away.
	var shift: float = cam_x * depth
	var lo: int = int(floor((cam_x - 520.0 - shift) / spacing))
	var hi: int = int(ceil((cam_x + 520.0 - shift) / spacing))
	for i in range(lo, hi + 1):
		var x: float = float(i) * spacing + shift
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 150.0, 320.0), Vector2(x, peak_y), Vector2(x + 150.0, 320.0)]), tint)

func _draw_crumble(ink: Color) -> void:
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
					Color(0.145, 0.208, 0.290, 1.0 - f / float(DEBRIS_TICKS)))
			continue
		var shake: float = sin(float(ledge.timer) * 1.1) * 1.6 if int(ledge.state) == Crumble.SHAKING else 0.0
		var dr := Rect2(r.position + Vector2(shake, 0.0), r.size)
		draw_rect(dr, ink)
		# A broken cap, where solid ground gets an unbroken one, marks these as
		# unreliable before the player ever touches them.
		var accent := Color("438e7d")
		if int(ledge.state) == Crumble.SHAKING:
			accent = Color("d24e42").lerp(Color("ef875f"), float(ledge.timer) / float(CRUMBLE_TICKS))
		var seg: float = dr.size.x / 5.0
		for i in range(3):
			draw_rect(Rect2(dr.position.x + float(i) * seg * 2.0, dr.position.y, seg, 3.0), accent)
		for i in range(2):
			var cx: float = dr.position.x + dr.size.x * (0.34 + 0.32 * float(i))
			draw_line(Vector2(cx, dr.position.y + 3.0), Vector2(cx + 2.0, dr.end.y), Color("405166"), 1.0)
