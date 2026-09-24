extends SceneTree
const Game = preload("res://game/session.gd")
const Route = preload("res://tests/route_driver.gd")
var game: Node2D
var results: Array[Dictionary] = []
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func steps(n: int) -> void:
	for i in range(n):
		await physics_frame
		await process_frame

func check(id: String, passed: bool, observation: Dictionary) -> void:
	results.append({"id": id, "status": "PASS" if passed else "FAIL", "observed": observation})
	if not passed:
		failures += 1
	print(JSON.stringify(results.back()))

func has_rect(list: Array, target: Rect2) -> bool:
	for r in list:
		if r is Rect2 and r.position.is_equal_approx(target.position) and r.size.is_equal_approx(target.size):
			return true
	return false

func fresh() -> void:
	if is_instance_valid(game):
		game.queue_free()
		await process_frame
	game = Game.new()
	game.test_mode = true
	root.add_child(game)
	game.start_session()
	game.player.test_control = true
	await steps(3)

func run() -> void:
	await fresh()
	check("launch-grounded", game.player.is_on_floor() and game.state == Game.State.PLAYING, {"position": str(game.player.position), "engine": Engine.get_version_info().string})
	game.player.test_axis = 1
	await steps(8)
	check("speed-cap", is_equal_approx(game.player.velocity.x,160), {"velocity_x": game.player.velocity.x})
	game.player.test_axis = 0
	await steps(5)
	check("neutral-stop", is_zero_approx(game.player.velocity.x), {"velocity_x": game.player.velocity.x})
	game.player.test_control = false
	Input.action_press("move_left")
	Input.action_press("move_right")
	await steps(5)
	check("simultaneous-directions", is_zero_approx(game.player.velocity.x), {"velocity_x": game.player.velocity.x})
	Input.action_release("move_left")
	Input.action_release("move_right")
	game.player.test_control = true
	game.player.test_axis = -1
	await steps(70)
	check("left-wall", game.player.position.x >= 9 and game.player.position.x <= 11, {"x": game.player.position.x})
	await fresh()
	game.player.test_jump_pressed = true
	game.player.test_jump_held = true
	var min_y: float = game.player.position.y
	for i in range(50):
		await steps(1)
		min_y = minf(min_y, game.player.position.y)
		if i == 12:
			game.player.test_jump_pressed = true
	check("fixed-jump-and-no-double", game.player.jumps == 1 and absf((320-min_y)-53.3333) < 5, {"rise_px":320-min_y, "jumps":game.player.jumps})
	await steps(30)
	check("held-jump-no-bounce", game.player.jumps == 1 and game.player.is_on_floor(), {"jumps":game.player.jumps})
	# Actual geometry fixtures at a ledge; tick ages exercise inclusive 6 / expired 7.
	for age in [5,6,7]:
		await fresh()
		game.player.position = Vector2(478, 285)
		await steps(2)
		game.player.last_floor_tick = game.player.tick + 1 - age
		game.player.opportunity_consumed = false
		game.player.test_jump_pressed = true
		await steps(1)
		check("coyote-%d" % age, (game.player.jumps == 1) == (age <= 6), {"age":age, "jumps":game.player.jumps})
	for age in [5,6,7]:
		await fresh()
		game.player.jump_request_tick = game.player.tick + 1 - age
		await steps(1)
		check("buffer-%d" % age, (game.player.jumps == 1) == (age <= 6), {"age":age, "jumps":game.player.jumps})
	await fresh()
	game._add_solid(Rect2(32,260,64,12))
	await steps(2)
	game.player.test_jump_pressed = true
	min_y = 320
	for i in range(45):
		await steps(1)
		min_y = minf(min_y,game.player.position.y)
	check("low-ceiling", min_y >= 300-0.2 and game.player.jumps == 1 and game.player.is_on_floor(), {"minimum_feet_y":min_y,"jumps":game.player.jumps})
	await fresh()
	game.player.test_jump_pressed = true
	await steps(5)
	game.set_paused(true)
	var paused_position: Vector2 = game.player.position
	var paused_time: float = game.elapsed
	await steps(10)
	check("pause-freezes", game.player.position == paused_position and game.elapsed == paused_time, {"position":str(game.player.position),"elapsed":game.elapsed})
	game.set_paused(false)
	game.test_mode = false
	game._on_focus_lost()
	check("focus-loss-pauses", game.state == Game.State.PAUSED, {"state":game.state})
	game.test_mode = true
	await fresh()
	game.player.position = Vector2(330,310)
	await steps(4)
	check("actual-spike-collision", game.state == Game.State.DYING and game.deaths == 1, {"state":game.state,"deaths":game.deaths})
	game.resolve_contacts(true,true)
	check("duplicate-death-ignored", game.deaths == 1, {"deaths":game.deaths})
	await steps(38)
	check("respawn", game.state == Game.State.PLAYING and game.player.position.distance_to(Vector2(64,320)) < 1, {"state":game.state,"position":str(game.player.position)})
	game.restart_attempt()
	check("manual-restart-not-death", game.deaths == 1, {"deaths":game.deaths})
	var largest_retry_ticks: int = 0
	for i in range(20):
		game.resolve_contacts(true,false)
		var waited := 0
		while game.state == Game.State.DYING and waited < 65:
			await steps(1)
			waited += 1
		largest_retry_ticks = maxi(largest_retry_ticks, waited)
	check("twenty-retries", game.deaths == 21 and largest_retry_ticks <= 60, {"deaths":game.deaths,"max_retry_ticks":largest_retry_ticks})
	await fresh()
	game.resolve_contacts(true,true)
	check("death-before-finish", game.state == Game.State.DYING, {"state":game.state})
	await fresh()
	game.player.position = Vector2(415,432)
	await steps(1)
	check("fall-boundary", game.state == Game.State.DYING, {"state":game.state})
	await fresh()
	var route = Route.new()
	var route_ticks := 0
	# Landings added past the original section's x=960 boundary.
	var new_landings: Array[Rect2] = []
	for entry in game.level.solids:
		if float(entry[0]) > 960.0:
			new_landings.append(Rect2(entry[0], entry[1], entry[2], entry[3]))
	for entry in game.level.crumbling:
		new_landings.append(Rect2(entry[0], entry[1], entry[2], entry[3]))
	var stood_on := {}
	# Budget raised from the starter's 900 because the level is now roughly five
	# times longer, and again to 3600 once the Feather became a rechargeable
	# ability - the fixture waits on the spot for a charge rather than walking
	# off an edge, which is what a player does. The observed figure is reported
	# below so the margin stays visible.
	while game.state == Game.State.PLAYING and route_ticks < 3600:
		route.step(game.player, game)
		await steps(1)
		route_ticks += 1
		if game.player.is_on_floor():
			for i in range(new_landings.size()):
				var lr: Rect2 = new_landings[i]
				if absf(game.player.position.y - lr.position.y) < 3.0 \
					and game.player.position.x + 9.0 > lr.position.x \
					and game.player.position.x - 9.0 < lr.end.x:
					stood_on[i] = true
	check("complete-real-route", game.state == Game.State.COMPLETE and game.deaths == 0, {"state":game.state,"deaths":game.deaths,"ticks":route_ticks,"position":str(game.player.position),"jump_marks_used":route.next_jump})
	# The assignment requires at least two new landings reached by jumping.
	check("route-reaches-new-landings", stood_on.size() >= 2,
		{"new_landings_available": new_landings.size(), "landed_on": stood_on.size()})
	check("finish-past-original-section", float(game.level.finish[0]) > 960.0 and float(game.level.width) > 960.0,
		{"finish_x": game.level.finish[0], "width": game.level.width})
	game.start_session()
	game.start_session()
	check("replay-idempotent", game.state == Game.State.PLAYING and game.deaths == 0 and game.player.jumps == 0, {"state":game.state,"deaths":game.deaths,"jumps":game.player.jumps})
	# --- 03 / DON'T STOP: the crumbling-ledge mechanic ---
	await fresh()
	game.player.position = Vector2(1050, 290)
	game.player.velocity = Vector2.ZERO
	# Two ticks to clear the is_on_floor() left over from the spawn platform,
	# otherwise the wait below returns before the player has fallen at all.
	await steps(2)
	var land_ticks := 0
	while not game.player.is_on_floor() and land_ticks < 30:
		await steps(1)
		land_ticks += 1
	await steps(1)
	var ledge: Dictionary = game.crumble_ledges[0]
	check("crumble-supports-then-triggers",
		game.player.is_on_floor() and int(ledge.state) == Game.Crumble.SHAKING,
		{"on_floor": game.player.is_on_floor(), "state": int(ledge.state), "timer": int(ledge.timer)})
	await steps(Game.CRUMBLE_TICKS + 3)
	check("crumble-collapses-after-timer",
		int(ledge.state) == Game.Crumble.COLLAPSED and not game.player.is_on_floor(),
		{"state": int(ledge.state), "on_floor": game.player.is_on_floor(), "y": game.player.position.y})
	var stall_deaths: int = game.deaths
	var stall_ticks := 0
	while game.deaths == stall_deaths and stall_ticks < 150:
		await steps(1)
		stall_ticks += 1
	check("crumble-stall-is-fatal", game.deaths == stall_deaths + 1,
		{"deaths": game.deaths, "ticks_to_death": stall_ticks})
	var back_ticks := 0
	while game.state != Game.State.PLAYING and back_ticks < 90:
		await steps(1)
		back_ticks += 1
	check("crumble-resets-on-retry",
		int(game.crumble_ledges[0].state) == Game.Crumble.INTACT and not game.crumble_ledges[0].shape.disabled,
		{"state": int(game.crumble_ledges[0].state), "shape_disabled": game.crumble_ledges[0].shape.disabled})
	# A ledge untouched this attempt must still be solid: collapse is caused by
	# contact, not by elapsed time.
	await fresh()
	await steps(Game.CRUMBLE_TICKS + 10)
	check("crumble-untouched-stays-solid",
		int(game.crumble_ledges[2].state) == Game.Crumble.INTACT,
		{"state": int(game.crumble_ledges[2].state)})

	# --- The Feather: gravity reversal ---
	await fresh()
	check("feather-starts-empty", game.feather_charges == 0 and game.player.gravity_sign > 0.0,
		{"charges": game.feather_charges, "gravity_sign": game.player.gravity_sign})
	game.test_feather_pressed = true
	await steps(2)
	check("feather-without-charge-does-nothing",
		game.player.gravity_sign > 0.0 and game.feather_charges == 0,
		{"gravity_sign": game.player.gravity_sign, "charges": game.feather_charges})

	# Walking into a Feather grants its charges exactly once.
	await fresh()
	game.player.position = Vector2(game.level.feathers[0][0], game.level.feathers[0][1] + 20)
	await steps(3)
	var granted: int = game.feather_charges
	await steps(5)
	# Design change after playtest: the Feather is a rechargeable ability, not a
	# stock. The first pickup grants the ability and exactly one charge; the
	# level data's third field is now ignored for anything but the first.
	check("feather-grants-the-ability-and-one-charge",
		game.has_feather and granted == 1 and game.feather_charges == 1,
		{"has_feather": game.has_feather, "granted": granted, "after": game.feather_charges})

	# Spending a charge inverts gravity; the player then falls upward onto a ceiling.
	await fresh()
	game.player.position = Vector2(2100, 260)
	game.player.velocity = Vector2.ZERO
	game.has_feather = true
	game.feather_charges = 1
	game.test_feather_pressed = true
	await steps(2)
	check("feather-inverts-and-spends",
		game.player.gravity_sign < 0.0 and game.feather_charges == 0 and game.reversal_ticks > 0,
		{"gravity_sign": game.player.gravity_sign, "charges": game.feather_charges})
	var rise_ticks := 0
	while not game.player.is_on_floor() and rise_ticks < 80:
		await steps(1)
		rise_ticks += 1
	check("inverted-grounds-on-ceiling",
		game.player.is_on_floor() and game.player.position.y < 230.0,
		{"y": game.player.position.y, "ticks": rise_ticks})

	# The jump keeps its magnitude when mirrored: tuning.gd is untouched and only
	# the direction of gravity changed.
	var base_y: float = game.player.position.y
	game.player.require_jump_release = false
	game.player.test_jump_pressed = true
	var far: float = base_y
	for i in range(26):
		await steps(1)
		far = maxf(far, game.player.position.y)
	check("inverted-jump-matches-normal-rise", absf((far - base_y) - 56.0) < 2.0,
		{"inverted_displacement": far - base_y, "normal_rise": 56.0})

	# Cancelling early restores gravity and does not refund the charge.
	await fresh()
	# On the ledge at 1900-2020, not mid-air: the recharge wait below is long
	# enough that a falling player would die and the retry would clear the
	# Feather before the charge came back.
	game.player.position = Vector2(1950, 270)
	game.has_feather = true
	game.feather_charges = 1
	await steps(3)
	game.test_feather_pressed = true
	await steps(2)
	game.test_feather_pressed = true
	await steps(2)
	# Cancelling still costs the charge. What changed is that waiting gets it
	# back, so the skill is when you flip rather than how many you hoarded.
	check("feather-cancel-costs-the-charge",
		game.player.gravity_sign > 0.0 and game.feather_charges == 0 and game.reversal_ticks == 0,
		{"gravity_sign": game.player.gravity_sign, "charges": game.feather_charges})

	# The charge comes back on its own, and never stacks above one.
	var recharge_ticks := 0
	while game.feather_charges == 0 and recharge_ticks < 400:
		await steps(1)
		recharge_ticks += 1
	check("feather-recharges-after-spending",
		game.feather_charges == 1 and recharge_ticks <= Game.RECHARGE_TICKS + 8,
		{"charges": game.feather_charges, "ticks_to_recharge": recharge_ticks,
		 "budget": Game.RECHARGE_TICKS})
	await steps(Game.RECHARGE_TICKS * 2)
	check("feather-never-stacks-above-one", game.feather_charges == 1,
		{"charges": game.feather_charges})

	# Left alone, the reversal expires on its own.
	await fresh()
	game.player.position = Vector2(2100, 260)
	game.has_feather = true
	game.feather_charges = 1
	game.test_feather_pressed = true
	await steps(Game.REVERSAL_TICKS + 4)
	check("reversal-expires-on-its-own",
		game.player.gravity_sign > 0.0 and game.reversal_ticks == 0,
		{"gravity_sign": game.player.gravity_sign})

	# Falling upward out of the level is as fatal as falling into the pit.
	await fresh()
	game.player.position = Vector2(2100, float(game.level.sky_y) - 14)
	await steps(4)
	check("sky-is-fatal", game.state == Game.State.DYING and game.death_reason == "You fell into the sky",
		{"state": game.state, "reason": game.death_reason})

	# A retry restores normal gravity, clears charges, and re-arms the Feathers.
	await fresh()
	game.has_feather = true
	game.feather_charges = 1
	game.test_feather_pressed = true
	await steps(2)
	game.restart_attempt()
	await steps(2)
	check("retry-resets-gravity-and-the-feather",
		game.player.gravity_sign > 0.0 and not game.has_feather and game.feather_charges == 0
		and not game.feathers[0].taken,
		{"gravity_sign": game.player.gravity_sign, "has_feather": game.has_feather,
		 "charges": game.feather_charges, "feather_taken": game.feathers[0].taken})

	# The observatory cannot be entered without the Feather: a normal jump from
	# the floor below never reaches the doorway.
	await fresh()
	# Follows the observatory, which has moved twice: x=2950 became the Void
	# Gap's hidden floor, and x=3800 became the sealed-door corridor. The
	# assertion itself has never changed.
	game.player.position = Vector2(4800, 280)
	await steps(3)
	game.player.require_jump_release = false
	game.player.test_jump_pressed = true
	var reached := false
	for i in range(50):
		await steps(1)
		if game.state == Game.State.COMPLETE:
			reached = true
			break
	check("finish-unreachable-without-feather", not reached,
		{"state": game.state, "highest_y": game.player.position.y})

	# --- INVERSION: hidden floors and phantom platforms ---
	# The law: the world renders what you believe, not what is there. Upright
	# (belief) draws phantoms and omits hidden floors. Inverted (truth) does the
	# exact reverse. Collision never lies - only the drawing does.
	await fresh()
	var hidden_data: Array = game.level.get("hidden", [])
	var phantom_data: Array = game.level.get("phantom", [])
	if hidden_data.is_empty() or phantom_data.is_empty() or not game.has_method("rendered_slabs"):
		var why := {"hidden_entries": hidden_data.size(), "phantom_entries": phantom_data.size(),
			"has_rendered_slabs": game.has_method("rendered_slabs")}
		for id in ["hidden-supports-but-is-not-drawn", "hidden-revealed-when-inverted",
			"phantom-is-drawn", "phantom-is-drawn-but-not-solid",
			"phantom-omitted-when-inverted", "betrayal-gap-is-fatal"]:
			check(id, false, why)
	else:
		var hr := Rect2(hidden_data[0][0], hidden_data[0][1], hidden_data[0][2], hidden_data[0][3])
		# Dropped onto a hidden floor, the player is caught by geometry they cannot see.
		game.player.position = Vector2(hr.position.x + hr.size.x * 0.5, hr.position.y - 24.0)
		game.player.velocity = Vector2.ZERO
		await steps(2)
		var drop_ticks := 0
		while not game.player.is_on_floor() and drop_ticks < 40:
			await steps(1)
			drop_ticks += 1
		check("hidden-supports-but-is-not-drawn",
			game.player.is_on_floor() and not has_rect(game.rendered_slabs(), hr),
			{"on_floor": game.player.is_on_floor(), "drawn_upright": has_rect(game.rendered_slabs(), hr),
			 "y": game.player.position.y, "rect": str(hr)})

		# Truth-vision: the same floor becomes visible the moment gravity inverts.
		game.has_feather = true
		game.feather_charges = 1
		game.test_feather_pressed = true
		await steps(2)
		check("hidden-revealed-when-inverted",
			game.player.gravity_sign < 0.0 and has_rect(game.rendered_slabs(), hr),
			{"gravity_sign": game.player.gravity_sign, "drawn_inverted": has_rect(game.rendered_slabs(), hr)})

		# A phantom is drawn exactly like a slab and holds nothing at all.
		await fresh()
		var pr := Rect2(phantom_data[0][0], phantom_data[0][1], phantom_data[0][2], phantom_data[0][3])
		check("phantom-is-drawn", has_rect(game.rendered_slabs(), pr), {"rect": str(pr)})
		game.player.position = Vector2(pr.position.x + pr.size.x * 0.5, pr.position.y - 24.0)
		game.player.velocity = Vector2.ZERO
		await steps(2)
		# Recorded inside the loop: a player who falls past the phantom keeps
		# falling into the pit, and the respawn would otherwise put them back at
		# y=320 and read as a pass.
		var fell_through := false
		var through_ticks := 0
		while not fell_through and through_ticks < 40:
			await steps(1)
			through_ticks += 1
			if game.state == Game.State.PLAYING and game.player.position.y > pr.end.y + 16.0:
				fell_through = true
		check("phantom-is-drawn-but-not-solid",
			has_rect(game.rendered_slabs(), pr) and fell_through,
			{"drawn": has_rect(game.rendered_slabs(), pr), "fell_through": fell_through,
			 "phantom_bottom": pr.end.y, "ticks": through_ticks})

		# Inverted, the lie stops being rendered.
		await fresh()
		game.player.position = Vector2(2100, 260)
		game.has_feather = true
		game.feather_charges = 1
		game.test_feather_pressed = true
		await steps(2)
		check("phantom-omitted-when-inverted",
			game.player.gravity_sign < 0.0 and not has_rect(game.rendered_slabs(), pr),
			{"gravity_sign": game.player.gravity_sign, "drawn_inverted": has_rect(game.rendered_slabs(), pr)})

		# The Betrayal. The lesson from the first gap - "keep walking, a floor
		# will catch me" - is the wrong lesson, and the level proves it.
		await fresh()
		var betrayal_x: float = float(game.level.get("betrayal_probe_x", 0.0))
		game.player.position = Vector2(betrayal_x, 280.0)
		game.player.velocity = Vector2.ZERO
		await steps(2)
		game.player.test_control = true
		game.player.test_axis = 1.0
		var walk_ticks := 0
		while game.state == Game.State.PLAYING and walk_ticks < 180:
			await steps(1)
			walk_ticks += 1
		game.player.test_axis = 0.0
		check("betrayal-gap-is-fatal",
			betrayal_x > 0.0 and game.state == Game.State.DYING and game.death_reason == "Missed the landing",
			{"probe_x": betrayal_x, "state": game.state, "reason": game.death_reason, "ticks": walk_ticks})

	# --- The palette is the theme: light is the lie, dark is the truth ---
	await fresh()
	if not game.has_method("pal"):
		check("palette-inverts-with-gravity", false, {"has_pal": false})
		check("palette-upright-is-the-lighter-one", false, {"has_pal": false})
	else:
		var up: Dictionary = game.pal().duplicate()
		game.player.position = Vector2(2100, 260)
		game.has_feather = true
		game.feather_charges = 1
		game.test_feather_pressed = true
		await steps(2)
		var down: Dictionary = game.pal().duplicate()
		var every_key_changes := true
		for key in up:
			if up[key] == down[key]:
				every_key_changes = false
		check("palette-inverts-with-gravity",
			game.player.gravity_sign < 0.0 and every_key_changes,
			{"gravity_sign": game.player.gravity_sign, "keys": up.size(),
			 "every_key_changes": every_key_changes})
		# Upright must read as daylight and inverted as near-black, not merely
		# differ: the direction of the change is the whole idea.
		check("palette-upright-is-the-lighter-one",
			up.void.get_luminance() > 0.5 and down.void.get_luminance() < 0.1,
			{"upright_void_luminance": up.void.get_luminance(),
			 "inverted_void_luminance": down.void.get_luminance()})

	# --- Reversal pads: telling the player where F is the answer ---
	# From playtest: "its not clear where to click F and invert and play upside
	# down". A pad marks the floor at every reversal the chapter requires.
	await fresh()
	var pads: Array = game.level.get("pads", [])
	if pads.is_empty() or not game.has_method("pad_prompt"):
		for id in ["pads-mark-every-mandatory-reversal", "pad-prompts-only-with-a-charge",
			"pad-prompt-clears-once-inverted"]:
			check(id, false, {"pads": pads.size(), "has_pad_prompt": game.has_method("pad_prompt")})
	else:
		# Every x the shipped route spends a charge at must be standing on a pad.
		var spend_points: Array[float] = [2000.0, 2320.0, 3120.0, 3500.0, 4020.0, 4440.0, 4773.0]
		var uncovered: Array[float] = []
		for sx in spend_points:
			var covered := false
			for entry in pads:
				if sx + 9.0 > float(entry[0]) and sx - 9.0 < float(entry[0]) + float(entry[2]):
					covered = true
			if not covered:
				uncovered.append(sx)
		check("pads-mark-every-mandatory-reversal", uncovered.is_empty(),
			{"pads": pads.size(), "uncovered_spend_points": uncovered})

		# A prompt that appears without a charge would be a lie.
		var pad0: Array = pads[0]
		game.player.position = Vector2(float(pad0[0]) + float(pad0[2]) * 0.5, float(pad0[1]) - 2.0)
		game.player.velocity = Vector2.ZERO
		game.feather_charges = 0
		await steps(3)
		var without: bool = game.pad_prompt()
		game.has_feather = true
		game.feather_charges = 1
		await steps(1)
		var with_charge: bool = game.pad_prompt()
		check("pad-prompts-only-with-a-charge", with_charge and not without,
			{"on_floor": game.player.is_on_floor(), "prompt_without_charge": without,
			 "prompt_with_charge": with_charge})

		# Once the player has acted on it, the prompt has nothing left to say.
		game.test_feather_pressed = true
		await steps(2)
		check("pad-prompt-clears-once-inverted",
			game.player.gravity_sign < 0.0 and not game.pad_prompt(),
			{"gravity_sign": game.player.gravity_sign, "prompt": game.pad_prompt()})

	# --- Mirror ledges: real only in the other world ---
	await fresh()
	var mirrors: Array = game.level.get("mirror", [])
	if mirrors.is_empty():
		check("mirror-absent-while-upright", false, {"mirror_entries": 0})
		check("mirror-solid-while-inverted", false, {"mirror_entries": 0})
	else:
		var mr := Rect2(mirrors[0][0], mirrors[0][1], mirrors[0][2], mirrors[0][3])
		game.player.position = Vector2(mr.position.x + mr.size.x * 0.5, mr.position.y - 22.0)
		game.player.velocity = Vector2.ZERO
		await steps(2)
		var fell_past := false
		for i in range(45):
			await steps(1)
			if game.state == Game.State.PLAYING and game.player.position.y > mr.end.y + 18.0:
				fell_past = true
				break
		check("mirror-absent-while-upright", fell_past,
			{"rect": str(mr), "fell_past": fell_past})

		# Inverted, the same rect catches a player falling upward onto its underside.
		await fresh()
		game.player.position = Vector2(mr.position.x + mr.size.x * 0.5, mr.end.y + 78.0)
		game.player.velocity = Vector2.ZERO
		game.has_feather = true
		game.feather_charges = 1
		game.test_feather_pressed = true
		await steps(2)
		var caught := false
		for i in range(70):
			await steps(1)
			if game.player.is_on_floor() and absf(game.player.position.y - (mr.end.y + 28.0)) < 5.0:
				caught = true
				break
		check("mirror-solid-while-inverted", caught,
			{"caught": caught, "player_y": game.player.position.y, "expected_y": mr.end.y + 28.0})

	# --- Hazards lie in both directions ---
	await fresh()
	var hidden_hz: Array = game.level.get("hidden_hazards", [])
	var phantom_hz: Array = game.level.get("phantom_hazards", [])
	if hidden_hz.is_empty() or phantom_hz.is_empty() or not game.has_method("rendered_hazards"):
		for id in ["hidden-hazard-is-invisible-but-lethal", "hidden-hazard-shows-when-inverted",
			"phantom-hazard-is-drawn-but-harmless"]:
			check(id, false, {"hidden": hidden_hz.size(), "phantom": phantom_hz.size(),
				"has_rendered_hazards": game.has_method("rendered_hazards")})
	else:
		var hh := Rect2(hidden_hz[0][0], hidden_hz[0][1], hidden_hz[0][2], hidden_hz[0][3])
		var drawn_upright: bool = has_rect(game.rendered_hazards(), hh)
		game.player.position = Vector2(hh.position.x + hh.size.x * 0.5, hh.position.y + 8.0)
		await steps(5)
		check("hidden-hazard-is-invisible-but-lethal",
			not drawn_upright and game.state == Game.State.DYING,
			{"drawn_upright": drawn_upright, "state": game.state})

		await fresh()
		game.player.position = Vector2(2100, 260)
		game.has_feather = true
		game.feather_charges = 1
		game.test_feather_pressed = true
		await steps(2)
		check("hidden-hazard-shows-when-inverted",
			game.player.gravity_sign < 0.0 and has_rect(game.rendered_hazards(), hh),
			{"drawn_inverted": has_rect(game.rendered_hazards(), hh)})

		# The opposite lie: full spikes, drawn in detail, that cannot hurt anyone.
		await fresh()
		var ph := Rect2(phantom_hz[0][0], phantom_hz[0][1], phantom_hz[0][2], phantom_hz[0][3])
		var ph_drawn: bool = has_rect(game.rendered_hazards(), ph)
		# Stood squarely in the middle of them, not hovering above: the point is
		# that these spikes cannot hurt anyone, so contact has to be real.
		game.player.position = Vector2(ph.position.x + ph.size.x * 0.5, ph.position.y + 8.0)
		await steps(8)
		check("phantom-hazard-is-drawn-but-harmless",
			ph_drawn and game.state == Game.State.PLAYING,
			{"drawn": ph_drawn, "state": game.state, "deaths": game.deaths})

	# --- A ceiling can give way under an inverted player ---
	await fresh()
	var ceiling_ledge := -1
	for i in range(game.crumble_ledges.size()):
		if float(game.crumble_ledges[i].rect.position.y) < 200.0:
			ceiling_ledge = i
			break
	if ceiling_ledge < 0:
		check("ceiling-crumble-triggers-when-inverted", false, {"ceiling_crumble_ledges": 0})
	else:
		var cl: Dictionary = game.crumble_ledges[ceiling_ledge]
		var cr: Rect2 = cl.rect
		game.player.position = Vector2(cr.position.x + cr.size.x * 0.5, cr.end.y + 70.0)
		game.player.velocity = Vector2.ZERO
		game.has_feather = true
		game.feather_charges = 1
		game.test_feather_pressed = true
		await steps(2)
		var hung := 0
		while int(cl.state) == Game.Crumble.INTACT and hung < 80:
			await steps(1)
			hung += 1
		check("ceiling-crumble-triggers-when-inverted",
			int(cl.state) == Game.Crumble.SHAKING,
			{"state": int(cl.state), "ticks": hung, "player_y": game.player.position.y})

	# --- Story logs ---
	await fresh()
	var logs: Array = game.level.get("logs", [])
	if logs.size() < 4 or not ("logs_found" in game):
		check("logs-deliver-story-on-pickup", false, {"log_entries": logs.size()})
		check("logs-reset-on-retry", false, {"log_entries": logs.size()})
	else:
		check("logs-start-uncollected", game.logs_found.is_empty(), {"found": game.logs_found.size()})
		game.player.position = Vector2(float(logs[0][0]), float(logs[0][1]) + 18.0)
		await steps(4)
		check("logs-deliver-story-on-pickup",
			game.logs_found.size() == 1 and String(game.logs_found[0]).length() > 0,
			{"found": game.logs_found.size(), "text": str(game.logs_found)})
		game.restart_attempt()
		await steps(2)
		check("logs-reset-on-retry", game.logs_found.is_empty(), {"found": game.logs_found.size()})

	var report := {"scope":"Chapter One: The Fall. Machine checks only; not human playtesting or full GDD acceptance", "engine":Engine.get_version_info().string,"created_at":Time.get_datetime_string_from_system(true),"results":results,"failures":failures}
	var out := ProjectSettings.globalize_path("res://../evidence")
	DirAccess.make_dir_recursive_absolute(out)
	var file := FileAccess.open(out + "/mechanics-" + str(Time.get_unix_time_from_system()) + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("WALKER TESTS: %d checks / %d failures" % [results.size(), failures])
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
