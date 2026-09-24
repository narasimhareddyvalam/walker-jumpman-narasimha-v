extends CharacterBody2D

const Tuning = preload("res://features/player/tuning.gd")
var tuning = Tuning.new()
var enabled: bool = false
var tick: int = 0
var last_floor_tick: int = -1000
var jump_request_tick: int = -1000
var opportunity_consumed: bool = false
var require_jump_release: bool = true
var facing: float = 1.0
## +1 normal, -1 while the Feather holds gravity inverted. A world state, not a
## tuning value: nothing in tuning.gd is modified when this flips.
var gravity_sign: float = 1.0
var jumps: int = 0
var test_control: bool = false
var test_axis: float = 0.0
var test_jump_pressed: bool = false
var test_jump_held: bool = false

func _ready() -> void:
	name = "Player"
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 1.0
	var shape := RectangleShape2D.new()
	shape.size = Vector2(18, 28)
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = Vector2(0, -14)
	add_child(collider)

func reset_at(spawn: Vector2) -> void:
	position = spawn
	velocity = Vector2.ZERO
	last_floor_tick = -1000
	jump_request_tick = -1000
	opportunity_consumed = false
	require_jump_release = true
	test_jump_pressed = false
	jumps = 0
	# Gravity always returns to normal on a retry, so no attempt inherits the
	# previous one's world state.
	gravity_sign = 1.0
	up_direction = Vector2.UP
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	tick += 1
	var axis := test_axis if test_control else Input.get_axis("move_left", "move_right")
	var held := test_jump_held if test_control else Input.is_action_pressed("jump")
	var pressed := test_jump_pressed if test_control else Input.is_action_just_pressed("jump")
	test_jump_pressed = false
	if not held:
		require_jump_release = false
	# "Falling" is whichever way gravity currently points, so the coyote window
	# opens on descent in either orientation.
	up_direction = Vector2(0.0, -gravity_sign)
	if is_on_floor() and velocity.y * gravity_sign >= 0.0:
		last_floor_tick = tick
		opportunity_consumed = false
	if pressed and not require_jump_release:
		jump_request_tick = tick
	var rate: float = tuning.acceleration if not is_zero_approx(axis) else tuning.deceleration
	velocity.x = move_toward(velocity.x, axis * tuning.speed, rate * delta)
	if not is_zero_approx(axis):
		facing = signf(axis)
	# Only the direction of gravity changes. Every magnitude below is the
	# unmodified value from tuning.gd: gravity 960, terminal 480, jump -320.
	velocity.y += tuning.gravity * gravity_sign * delta
	if gravity_sign > 0.0:
		velocity.y = minf(velocity.y, tuning.terminal_velocity)
	else:
		velocity.y = maxf(velocity.y, -tuning.terminal_velocity)
	if not opportunity_consumed and tick - last_floor_tick <= tuning.coyote_ticks and tick - jump_request_tick <= tuning.buffer_ticks:
		velocity.y = tuning.jump_velocity * gravity_sign
		opportunity_consumed = true
		jump_request_tick = -1000
		jumps += 1
	move_and_slide()
	position.x = maxf(position.x, 10.0)
	queue_redraw()

func _draw() -> void:
	# The Runner. Original vector drawing; no imported art.
	# Body geometry stays inside the unchanged 18x28 collider (x -9..9, y -28..0).
	# Only the speed trail extends past it: a trailing soft element reads as
	# non-solid, where an overhanging rigid body part would read as a bug.
	# Inverted, the whole figure mirrors about the collider's centre line, so the
	# drawing stays inside the same unchanged 18x28 box while reading upside down.
	if gravity_sign < 0.0:
		draw_set_transform(Vector2(0.0, -28.0), 0.0, Vector2(1.0, -1.0))
	# Lifted off the starter's near-black navy so the figure still reads against
	# the dark facility rather than disappearing into it.
	var ink := Color("3d5568")
	# The trail reports gravity state: warm while normal, cold while inverted.
	# This is the only readout of the Feather's effect; there is no UI for it.
	var amber := Color("ef875f") if gravity_sign > 0.0 else Color("7fd8f0")
	var pale := Color("fff9e9")
	var speed_ratio: float = clampf(absf(velocity.x) / tuning.speed, 0.0, 1.0)
	var grounded := is_on_floor()
	var stride := sin(float(tick) * 0.7) * 3.0 if grounded and absf(velocity.x) > 8 else 0.0
	var lean: float = facing * 2.0 * speed_ratio

	# Speed trail: length reports velocity, so standing still visibly extinguishes
	# the character and sprinting streams it. Drawn first so the body sits over it.
	# One tapered polygon rather than segments, which read as detached slabs.
	if speed_ratio > 0.05:
		var trail_len: float = speed_ratio * 20.0
		var droop: float = clampf(-velocity.y * 0.018, -4.0, 4.0)
		var upper := PackedVector2Array()
		var lower := PackedVector2Array()
		for i in range(6):
			var t: float = float(i) / 5.0
			var px: float = -facing * (4.0 + trail_len * t)
			var py: float = -14.0 + droop * t + sin(float(tick) * 0.45 - t * 1.6) * 1.1 * speed_ratio
			var half: float = lerpf(3.2, 0.3, t)
			upper.append(Vector2(px, py - half))
			lower.insert(0, Vector2(px, py + half))
		upper.append_array(lower)
		draw_colored_polygon(upper, Color(amber.r, amber.g, amber.b, 0.72))

	# Legs: the raised foot lifts off the ground rather than sinking through it.
	draw_rect(Rect2(-6.0 + facing, -5.0, 4.0, 5.0 - maxf(stride, 0.0)), ink)
	draw_rect(Rect2(2.0 + facing, -5.0, 4.0, 5.0 - maxf(-stride, 0.0)), ink)

	# Forward-leaning parallelogram torso: reads as momentum even in a still frame.
	# Every x is mirrored through `facing` so the lean and sash flip with the turn.
	var tilt: float = 2.0 * speed_ratio
	draw_colored_polygon(PackedVector2Array([
		Vector2(facing * (-5.0 + tilt), -20.0), Vector2(facing * (5.0 + tilt), -20.0),
		Vector2(facing * 6.0, -5.0), Vector2(facing * -4.0, -5.0)]), ink)
	draw_line(Vector2(facing * (-3.0 + tilt), -15.0), Vector2(facing * 5.0, -9.0), amber, 2.0)

	# Rounded head breaks the starter's all-rectangle silhouette.
	var head := Vector2(facing * 2.0 + lean * 0.5, -23.0)
	draw_circle(head, 5.0, ink)
	draw_circle(head + Vector2(facing * 2.0, -0.5), 2.2, amber)
	draw_circle(head + Vector2(facing * 2.6, -1.1), 0.9, pale)
