extends Control
var game: Node2D
# Minimal readout. The starter's chunky bars were replaced: this chapter tells
# the player what it can through the world, not through the interface.
const TEXT := Color("8fa3ae")
const FAINT := Color("4e5f69")
const COLD := Color("8fe3ff")
const PANEL := Color(0.031, 0.047, 0.067, 0.92)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func text_at(text: String, position: Vector2, size_px: int = 14, color: Color = TEXT) -> void:
	draw_string(ThemeDB.fallback_font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)

func centered(text: String, y: float, font_size: int, color: Color = TEXT) -> void:
	var width := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	text_at(text, Vector2((640 - width) / 2, y), font_size, color)

func _draw() -> void:
	if not is_instance_valid(game):
		return
	text_at("THE WORLD IS FALLING", Vector2(22, 26), 13, TEXT)
	text_at("CH. 01 / THE FALL", Vector2(500, 26), 11, FAINT)
	# Charges are the only persistent readout, because they are the only thing
	# the player cannot see by looking at the world.
	var charges: int = game.feather_charges
	for i in range(4):
		var lit := i < charges
		var box := Rect2(22 + i * 13, 38, 9, 3)
		draw_rect(box, COLD if lit else Color(COLD.r, COLD.g, COLD.b, 0.13))
	if game.reversal_ticks > 0:
		var span: float = float(game.reversal_ticks) / float(game.REVERSAL_TICKS)
		draw_rect(Rect2(22, 45, 76 * span, 1), COLD)
	elif charges > 0:
		text_at("F", Vector2(104, 44), 10, FAINT)

	var origin: float = float(game.level.spawn[0])
	var span_x: float = maxf(float(game.level.finish[0]) - origin, 1.0)
	var progress: float = clampf((game.player.position.x - origin) / span_x, 0, 1)
	draw_rect(Rect2(22, 331, 596, 1), Color(0.31, 0.45, 0.51, 0.22))
	draw_rect(Rect2(22, 331, 596 * progress, 1), Color(0.31, 0.45, 0.51, 0.7))
	text_at("%02d  /  %04.1fs" % [game.deaths, game.elapsed], Vector2(538, 349), 11, FAINT)
	text_at("A D  move    SPACE  jump    F  feather    R  retry", Vector2(22, 349), 11, FAINT)

	if game.state == game.State.PLAYING:
		return
	if game.state == game.State.DYING:
		centered(game.death_reason, 176, 17, Color("b8655c"))
		return
	# Scrim plus an opaque panel: at 0.72 alpha the level's own signage read
	# straight through the card and collided with it.
	draw_rect(Rect2(0, 0, 640, 360), Color(0.031, 0.047, 0.067, 0.82))
	draw_rect(Rect2(96, 112, 448, 194), Color(0.027, 0.039, 0.055, 0.97))
	var title := "THE WORLD IS FALLING"
	var detail := "Something is wrong with the ground."
	var hint := "Chapter One  /  The Fall"
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
	draw_rect(Rect2(150, 118, 340, 1), Color(COLD.r, COLD.g, COLD.b, 0.35))
	centered(title, 150, 21, Color("d8e8f0"))
	centered(detail, 176, 12, TEXT)
	if hint != "":
		centered(hint, 196, 11, FAINT)
	if game.state == game.State.COMPLETE:
		centered("What was the Feather?", 224, 11, FAINT)
		centered("Why could you use it?", 240, 11, FAINT)
	draw_rect(Rect2(150, 262, 340, 1), Color(COLD.r, COLD.g, COLD.b, 0.35))
	centered(button, 284, 12, COLD)
