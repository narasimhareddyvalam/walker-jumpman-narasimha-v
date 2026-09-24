extends Control
var game: Node2D
# Minimal readout. The starter's chunky bars were replaced: this chapter tells
# the player what it can through the world, not through the interface.
# The HUD follows the world's palette rather than carrying its own, so the
# readout cannot contradict which world the player is standing in. On COMPLETE
# the card renders dark, because entering the observatory means being inverted.
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
	# Charges are the only persistent readout, because they are the only thing
	# the player cannot see by looking at the world.
	var charges: int = game.feather_charges
	for i in range(4):
		var lit := i < charges
		var box := Rect2(22 + i * 13, 38, 9, 3)
		draw_rect(box, cold if lit else Color(cold.r, cold.g, cold.b, 0.13))
	if game.reversal_ticks > 0:
		var span: float = float(game.reversal_ticks) / float(game.REVERSAL_TICKS)
		draw_rect(Rect2(22, 45, 76 * span, 1), cold)
	elif game.has_feather:
		text_at("F", Vector2(104, 44), 10, P.text_faint)
	if not game.logs.is_empty():
		text_at("LOG  %d / %d" % [game.logs_found.size(), game.logs.size()],
			Vector2(500, 44), 10, P.text_faint)

	# Standing on a reversal pad with a charge in hand. Playtest finding: "its
	# not clear where to click F and invert and play upside down" - the chapter
	# had no affordance at all, so a player who never guessed F could not finish
	# it. The prompt is deliberately loud, and appears only where pressing F
	# actually does something.
	if game.pad_prompt():
		var pulse: float = 0.72 + 0.28 * sin(float(game.world_tick) * 0.12)
		draw_rect(Rect2(196, 296, 248, 22), Color(P.void.r, P.void.g, P.void.b, 0.86))
		draw_rect(Rect2(196, 296, 248, 1), Color(cold.r, cold.g, cold.b, 0.55))
		draw_rect(Rect2(196, 317, 248, 1), Color(cold.r, cold.g, cold.b, 0.55))
		centered("PRESS  F  TO FALL UPWARD", 312, 14, Color(cold.r, cold.g, cold.b, pulse))

	# A log fragment just picked up. Story arrives as a reward for walking over
	# to it, rather than as signage the player runs past without reading.
	if game.log_banner_ticks > 0 and game.log_banner != "":
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
	var detail := "The debris is falling upward. Nobody knows why."
	var hint := "Reach the observatory.      Chapter One  /  The Fall"
	var button := "ENTER"
	if game.state == game.State.PAUSED:
		title = "HELD"
		detail = "R  restart attempt      M  main menu"
		hint = ""
		button = "ENTER  /  RESUME"
	elif game.state == game.State.COMPLETE:
		# The chapter ends on what the player sees, not on a score.
		title = "THE LANDSCAPE IS FLOATING"
		detail = "GRAVITATIONAL FAILURE  /  SPREADING"
		hint = "%.1fs      %d retries      chapter one ends" % [game.last_finish_time, game.deaths]
		button = "ENTER  /  AGAIN"
	draw_rect(Rect2(150, 118, 340, 1), Color(cold.r, cold.g, cold.b, 0.35))
	centered(title, 150, 21, P.text_dim)
	centered(detail, 176, 12, P.text_dim)
	if hint != "":
		centered(hint, 196, 11, P.text_faint)
	if game.state == game.State.COMPLETE:
		centered("What was the Feather?", 224, 11, P.text_faint)
		centered("Why could you use it?", 240, 11, P.text_faint)
	draw_rect(Rect2(150, 262, 340, 1), Color(cold.r, cold.g, cold.b, 0.35))
	centered(button, 284, 12, cold)
