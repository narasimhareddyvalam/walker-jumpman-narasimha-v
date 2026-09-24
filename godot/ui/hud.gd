extends Control
var game: Node2D
# Minimal readout. The starter's chunky bars were replaced: this chapter tells
# the player what it can through the world, not through the interface.
# The HUD follows the world's palette rather than carrying its own, so the
# readout cannot contradict which world the player is standing in. On COMPLETE
# the card renders dark, because entering the tower means being inverted.
func p() -> Dictionary:
	return game.pal() if is_instance_valid(game) else game.DARK

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func text_at(text: String, position: Vector2, size_px: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)

func centered(text: String, y: float, font_size: int, color: Color) -> void:
	var width := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	text_at(text, Vector2((640 - width) / 2, y), font_size, color)

func _draw() -> void:
	if not is_instance_valid(game):
		return
	var P := p()
	var cold: Color = P.cold
	text_at("THE WORLD IS FALLING", Vector2(22, 26), 13, P.text_dim)
	text_at("CH. 01 / THE FALL", Vector2(500, 26), 11, P.text_faint)
	# The power's state, named and spelled out. Four small pips said nothing to
	# a player who did not already know what they counted, and there is only
	# ever one charge now - what matters is READY, INVERTED or RECHARGING.
	var charges: int = game.feather_charges
	if game.has_feather:
		text_at("FEATHER", Vector2(22, 45), 10, P.text_faint)
		var bar := Rect2(74, 40, 92, 4)
		draw_rect(bar, Color(cold.r, cold.g, cold.b, 0.16))
		if game.reversal_ticks > 0:
			var span: float = float(game.reversal_ticks) / float(game.REVERSAL_TICKS)
			draw_rect(Rect2(bar.position.x, bar.position.y, bar.size.x * span, bar.size.y), cold)
			text_at("INVERTED", Vector2(172, 45), 10, cold)
		elif charges > 0:
			draw_rect(bar, cold)
			text_at("READY   F", Vector2(172, 45), 10, cold)
		else:
			var back: float = 1.0 - clampf(float(game.recharge_ticks) / float(game.RECHARGE_TICKS), 0.0, 1.0)
			draw_rect(Rect2(bar.position.x, bar.position.y, bar.size.x * back, bar.size.y),
				Color(cold.r, cold.g, cold.b, 0.5))
			text_at("RECHARGING", Vector2(172, 45), 10, P.text_faint)
	if not game.logs.is_empty():
		text_at("LOG  %d / %d" % [game.logs_found.size(), game.logs.size()],
			Vector2(500, 44), 10, P.text_faint)

	# Picking up a power and reading a note are different events, so they do not
	# look the same. This one is a card, and it says what the power does.
	if game.unlock_ticks > 0:
		var fade: float = clampf(float(game.unlock_ticks) / 50.0, 0.0, 1.0)
		draw_rect(Rect2(150, 120, 340, 62), Color(P.void.r, P.void.g, P.void.b, 0.93 * fade))
		draw_rect(Rect2(150, 120, 340, 2), Color(cold.r, cold.g, cold.b, 0.85 * fade))
		draw_rect(Rect2(150, 180, 340, 2), Color(cold.r, cold.g, cold.b, 0.85 * fade))
		centered("THE FEATHER", 143, 17, Color(cold.r, cold.g, cold.b, fade))
		centered("You can reverse gravity.", 160, 12, Color(P.text_dim.r, P.text_dim.g, P.text_dim.b, fade))
		centered("Press  F  on a marked pad to fall upward.", 174, 11,
			Color(P.text_faint.r, P.text_faint.g, P.text_faint.b, fade))

	# Standing on a reversal pad with a charge in hand. Playtest finding: "its
	# not clear where to click F and invert and play upside down" - the chapter
	# had no affordance at all, so a player who never guessed F could not finish
	# it. The prompt is deliberately loud, and appears only where pressing F
	# actually does something.
	if game.pad_prompt():
		var pulse: float = 0.74 + 0.26 * sin(float(game.world_tick) * 0.12)
		# A drawn keycap rather than the word "press": the instruction is the key
		# itself, then what it does, then what that will feel like.
		draw_rect(Rect2(178, 292, 284, 36), Color(P.void.r, P.void.g, P.void.b, 0.9))
		draw_rect(Rect2(178, 292, 284, 2), Color(cold.r, cold.g, cold.b, 0.6))
		draw_rect(Rect2(178, 326, 284, 2), Color(cold.r, cold.g, cold.b, 0.6))
		var cap := Rect2(190, 299, 22, 22)
		draw_rect(cap, Color(cold.r, cold.g, cold.b, 0.15 * pulse))
		draw_rect(Rect2(cap.position.x, cap.position.y, cap.size.x, 1), Color(cold.r, cold.g, cold.b, pulse))
		draw_rect(Rect2(cap.position.x, cap.end.y - 1, cap.size.x, 1), Color(cold.r, cold.g, cold.b, pulse))
		draw_rect(Rect2(cap.position.x, cap.position.y, 1, cap.size.y), Color(cold.r, cold.g, cold.b, pulse))
		draw_rect(Rect2(cap.end.x - 1, cap.position.y, 1, cap.size.y), Color(cold.r, cold.g, cold.b, pulse))
		text_at("F", Vector2(197, 316), 15, Color(cold.r, cold.g, cold.b, pulse))
		text_at("REVERSE GRAVITY", Vector2(222, 311), 13, Color(cold.r, cold.g, cold.b, pulse))
		text_at("you will fall upward onto the ceiling", Vector2(222, 323), 9, P.text_faint)

	# A log fragment just picked up. Story arrives as a reward for walking over
	# to it, rather than as signage the player runs past without reading.
	if game.log_banner_ticks > 0 and game.log_banner != "" and game.unlock_ticks <= 0:
		var t: float = clampf(float(game.log_banner_ticks) / 40.0, 0.0, 1.0)
		var w := ThemeDB.fallback_font.get_string_size(game.log_banner,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_rect(Rect2((640 - w) / 2 - 14, 74, w + 28, 22),
			Color(P.void.r, P.void.g, P.void.b, 0.88 * t))
		draw_rect(Rect2((640 - w) / 2 - 14, 74, 2, 22),
			Color(P.text_warn.r, P.text_warn.g, P.text_warn.b, 0.9 * t))
		centered(game.log_banner, 89, 12, Color(P.text_dim.r, P.text_dim.g, P.text_dim.b, t))

	# The rooftops put a grid of windows directly behind the bottom row, and the
	# controls line stopped being readable the moment platforms stopped being
	# flat. A backing band costs nothing and keeps the text legible over any
	# geometry that scrolls past.
	draw_rect(Rect2(0, 338, 640, 22), Color(P.void.r, P.void.g, P.void.b, 0.85))

	var origin: float = float(game.level.spawn[0])
	var span_x: float = maxf(float(game.level.finish[0]) - origin, 1.0)
	var progress: float = clampf((game.player.position.x - origin) / span_x, 0, 1)
	draw_rect(Rect2(22, 331, 596, 1), Color(P.edge.r, P.edge.g, P.edge.b, 0.22))
	draw_rect(Rect2(22, 331, 596 * progress, 1), Color(P.edge.r, P.edge.g, P.edge.b, 0.7))
	text_at("%02d  /  %04.1fs" % [game.deaths, game.elapsed], Vector2(538, 349), 11, P.text_faint)
	text_at("A D  move    SPACE  jump    F  feather    R  retry", Vector2(22, 349), 11, P.text_faint)

	if game.state == game.State.PLAYING:
		return
	if game.state == game.State.DYING:
		centered(game.death_reason, 176, 17, P.hazard)
		return
	# Scrim plus an opaque panel: at 0.72 alpha the level's own signage read
	# straight through the card and collided with it.
	draw_rect(Rect2(0, 0, 640, 360), Color(P.void.r, P.void.g, P.void.b, 0.82))
	draw_rect(Rect2(96, 112, 448, 194), Color(P.void.r, P.void.g, P.void.b, 0.97))
	var title := "THE WORLD IS FALLING"
	var detail := "Everything falls UP now."
	var hint := "Reach the tower.      Chapter One  /  The Fall"
	var button := "ENTER"
	if game.state == game.State.PAUSED:
		title = "HELD"
		detail = "R  restart attempt      M  main menu"
		hint = ""
		button = "ENTER  /  RESUME"
	elif game.state == game.State.COMPLETE:
		# The chapter ends on what the player sees, not on a score.
		title = "YOU BUILT THIS"
		detail = "You made the world fall up."
		hint = "%.1fs      %d retries      chapter one ends" % [game.last_finish_time, game.deaths]
		button = "ENTER  /  AGAIN"
	draw_rect(Rect2(150, 118, 340, 1), Color(cold.r, cold.g, cold.b, 0.35))
	centered(title, 150, 21, P.text_dim)
	centered(detail, 176, 12, P.text_dim)
	if hint != "":
		centered(hint, 196, 11, P.text_faint)
	if game.state == game.State.COMPLETE:
		centered("What was the feather?", 224, 11, P.text_faint)
		centered("Why did it obey you?", 240, 11, P.text_faint)
	draw_rect(Rect2(150, 262, 340, 1), Color(cold.r, cold.g, cold.b, 0.35))
	centered(button, 284, 12, cold)
