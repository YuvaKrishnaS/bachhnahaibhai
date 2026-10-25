extends Node2D

const VIEW_W := 960.0
const VIEW_H := 540.0
const SURVIVE_TIME := 60.0

var mode := 0
var elapsed := 0.0
var best := 0.0
var score := 0
var best_score := 0
var menu_index := 0
var panel_ready := false
var new_best := false
var cause := "SQUISHED!"
var banner_text := ""
var banner_time := 0.0
var has_life := false
var revived := false
var shield_left := 0.0
var shield_frac := 0.0
var touches := {}

var title_tex: Texture2D
var death_tex: Texture2D
var win_tex: Texture2D
var howto_tex: Texture2D
var play_tex: Texture2D
var howto_btn_tex: Texture2D
var score_tex: Texture2D
var controls_tex: Texture2D
var icon_on_tex: Texture2D
var icon_off_tex: Texture2D
var icon_restart_tex: Texture2D
var icon_home_tex: Texture2D
var btn_left_tex: Texture2D
var btn_right_tex: Texture2D
var btn_jump_tex: Texture2D
var font: Font


func _ready() -> void:
	font = Art.get_font()
	title_tex = Art.get_tex("res://assets/title_screen.png")
	death_tex = Art.get_tex("res://assets/death_panel.png")
	win_tex = Art.get_tex("res://assets/win_panel.png")
	howto_tex = Art.get_tex("res://assets/instructions_screen.png")
	play_tex = Art.get_tex("res://assets/txt_play.png")
	howto_btn_tex = Art.get_tex("res://assets/txt_howto.png")
	score_tex = Art.get_tex("res://assets/txt_score.png")
	controls_tex = Art.get_tex("res://assets/hud_controls.png")
	icon_on_tex = Art.get_tex("res://assets/icon_sound_on.png")
	icon_off_tex = Art.get_tex("res://assets/icon_sound_off.png")
	icon_restart_tex = Art.get_tex("res://assets/icon_restart.png")
	icon_home_tex = Art.get_tex("res://assets/icon_home.png")
	btn_left_tex = Art.get_tex("res://assets/btn_left.png")
	btn_right_tex = Art.get_tex("res://assets/btn_right.png")
	btn_jump_tex = Art.get_tex("res://assets/btn_jump.png")

	Ctl.left = false
	Ctl.right = false
	Ctl.jump = false
	if DisplayServer.is_touchscreen_available():
		Ctl.touch_enabled = true


func _process(_delta: float) -> void:
	queue_redraw()


func _input(event: InputEvent) -> void:
	var t := event as InputEventScreenTouch
	if t != null:
		Ctl.touch_enabled = true
		if t.pressed:
			touches[t.index] = t.position
		else:
			touches.erase(t.index)
		refresh_touch()
		return

	var d := event as InputEventScreenDrag
	if d != null:
		touches[d.index] = d.position
		refresh_touch()


func refresh_touch() -> void:
	var l := false
	var r := false
	var j := false
	for item in touches.values():
		var p: Vector2 = item
		if p.distance_to(Layout.LEFT_CENTER) < Layout.HIT_R:
			l = true
		if p.distance_to(Layout.RIGHT_CENTER) < Layout.HIT_R:
			r = true
		if p.distance_to(Layout.JUMP_CENTER) < Layout.HIT_R:
			j = true
	Ctl.left = l
	Ctl.right = r
	Ctl.jump = j


func put(msg: String, pos: Vector2, align: HorizontalAlignment, width: float, size: int, color: Color) -> void:
	draw_string(font, pos, msg, align, width, int(size * Art.FONT_SCALE), color)


func center_text(msg: String, y: float, size: int, color: Color) -> void:
	put(msg, Vector2(0, y), HORIZONTAL_ALIGNMENT_CENTER, VIEW_W, size, color)


func lines(msg: String, x: float, y: float, w: float, size: int, color: Color) -> void:
	draw_multiline_string(font, Vector2(x, y), msg, HORIZONTAL_ALIGNMENT_CENTER, w, int(size * Art.FONT_SCALE), -1, color)


func draw_panel(tex: Texture2D) -> void:
	draw_rect(Rect2(0, 0, VIEW_W, VIEW_H), Color(Pal.NEAR_BLACK, 0.55))
	var r := Layout.PANEL_RECT
	if tex:
		draw_texture(tex, r.position)
	else:
		draw_rect(r, Pal.DARK_GRAY)
		draw_rect(r, Pal.SLATE, false, 4.0)


func menu_item(index: int, label: String, tex: Texture2D, y: float) -> void:
	var sel := menu_index == index
	var w := 220.0
	if tex:
		w = tex.get_width()
		draw_texture(tex, Vector2((VIEW_W - w) / 2.0, y), Color(1, 1, 1, 1.0 if sel else 0.5))
	else:
		var c := Pal.YELLOW if sel else Color(Pal.LIGHT_GRAY, 0.55)
		center_text(label, y + 28.0, 28, c)
	if sel:
		var cx := VIEW_W / 2.0 - w / 2.0 - 28.0
		var cy := y + 20.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx, cy - 9.0),
			Vector2(cx + 16.0, cy),
			Vector2(cx, cy + 9.0)
		]), Pal.YELLOW)


func draw_title() -> void:
	if title_tex:
		draw_texture(title_tex, Vector2.ZERO)
	else:
		draw_rect(Rect2(0, 0, VIEW_W, VIEW_H), Color(Pal.NEAR_BLACK, 0.9))
		center_text("bachhnahaibhai", 190, 60, Pal.WHITE)
		center_text("one very small man. one very big machine.", 240, 20, Pal.LIGHT_GRAY)
	menu_item(0, "PLAY", play_tex, 385.0)
	menu_item(1, "HOW TO PLAY", howto_btn_tex, 435.0)
	center_text("W / S choose     ENTER / SPACE select     or just tap", 510, 16, Pal.SKY)


func card(x: float, y: float, w: float, h: float, title: String, color: Color) -> void:
	var r := Rect2(x, y, w, h)
	draw_rect(r, Color(Pal.DARK_GRAY, 0.55))
	draw_rect(r, Pal.SLATE, false, 2.0)
	put(title, Vector2(x, y + 30.0), HORIZONTAL_ALIGNMENT_CENTER, w, 22, color)


func draw_howto() -> void:
	if howto_tex:
		draw_texture(howto_tex, Vector2.ZERO)
		return

	draw_rect(Rect2(0, 0, VIEW_W, VIEW_H), Color(Pal.NEAR_BLACK, 0.97))
	center_text("HOW TO PLAY", 56, 44, Pal.YELLOW)
	center_text("Survive 60 seconds. Grab pick-ups. Don't get flattened!", 88, 18, Pal.LIGHT_GRAY)

	card(40, 108, 280, 176, "CONTROLS", Pal.SKY)
	lines("MOVE:  A / D  or  arrows\nJUMP:  SPACE / W / UP\nRESTART: R    MENU: ESC\nMUTE: M\n(touch: on-screen buttons)", 40, 152, 280, 15, Pal.WHITE)

	card(340, 108, 280, 176, "DANGER", Pal.SALMON)
	lines("Flashing column =\na piston is about to slam.\nRUN OUT OF IT!\n\nSpinning saw =\nJUMP OVER IT!", 340, 152, 280, 15, Pal.WHITE)

	card(640, 108, 280, 176, "GOAL", Pal.GREEN)
	lines("Survive for 60 seconds.\nEat samosas for points.\nRiskier spots = rarer samosas.\nThe machine gets angrier\nevery 10 seconds.", 640, 152, 280, 15, Pal.WHITE)

	center_text("PICK-UPS", 322, 26, Pal.YELLOW)

	var xs := [96.0, 288.0, 480.0, 672.0, 864.0]
	var labels := [
		"+1 point\nEasy to grab",
		"+3 points\nRisky spot",
		"+5 points\nVery risky!",
		"EXTRA LIFE\nAppears once!\nSaves you once",
		"SHIELD (5 sec)\nBlocks the saw\nyou are facing"
	]
	var colors := [Pal.WHITE, Pal.YELLOW, Pal.PINK, Pal.SALMON, Pal.TEAL]
	for i in 5:
		Samosa.draw_icon(self, i, Vector2(xs[i], 376.0))
		lines(labels[i], xs[i] - 94.0, 436.0, 188.0, 15, colors[i])

	center_text("ESC, ENTER or TAP to go back", 524, 16, Pal.SKY)


func draw_icon_button(rect: Rect2) -> void:
	draw_rect(rect, Color(Pal.NEAR_BLACK, 0.6))
	draw_rect(rect, Pal.SLATE, false, 2.0)


func draw_mute_icon() -> void:
	var muted := AudioServer.is_bus_mute(0)
	var r := Layout.MUTE_RECT
	var tex := icon_off_tex if muted else icon_on_tex
	if tex:
		draw_texture_rect(tex, r, false)
		return
	draw_icon_button(r)
	var c := r.get_center()
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-12, -5),
		c + Vector2(-5, -5),
		c + Vector2(3, -12),
		c + Vector2(3, 12),
		c + Vector2(-5, 5),
		c + Vector2(-12, 5)
	]), Pal.WHITE)
	if muted:
		draw_line(c + Vector2(8, -8), c + Vector2(16, 8), Pal.SALMON, 3.0)
		draw_line(c + Vector2(16, -8), c + Vector2(8, 8), Pal.SALMON, 3.0)
	else:
		draw_arc(c + Vector2(3, 0), 8.0, -0.9, 0.9, 8, Pal.WHITE, 2.0)
		draw_arc(c + Vector2(3, 0), 14.0, -0.9, 0.9, 8, Pal.WHITE, 2.0)


func draw_restart_icon() -> void:
	var r := Layout.RESTART_RECT
	if icon_restart_tex:
		draw_texture_rect(icon_restart_tex, r, false)
		return
	draw_icon_button(r)
	var c := r.get_center()
	draw_arc(c, 10.0, 0.6, 5.6, 16, Pal.WHITE, 3.0)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(6, -14),
		c + Vector2(16, -6),
		c + Vector2(4, -4)
	]), Pal.WHITE)


func draw_home_icon() -> void:
	var r := Layout.HOME_RECT
	if icon_home_tex:
		draw_texture_rect(icon_home_tex, r, false)
		return
	draw_icon_button(r)
	var c := r.get_center()
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(0, -13),
		c + Vector2(14, -1),
		c + Vector2(-14, -1)
	]), Pal.WHITE)
	draw_rect(Rect2(c + Vector2(-9, -1), Vector2(18, 13)), Pal.WHITE)
	draw_rect(Rect2(c + Vector2(-3, 4), Vector2(6, 8)), Pal.NEAR_BLACK)


func draw_touch_button(center: Vector2, pressed: bool, kind: int, tex: Texture2D) -> void:
	var a := 0.75 if pressed else 0.4
	if tex:
		draw_texture(tex, center - tex.get_size() / 2.0, Color(1, 1, 1, a))
		return
	draw_circle(center, Layout.BTN_R, Color(Pal.NEAR_BLACK, a))
	draw_arc(center, Layout.BTN_R, 0.0, TAU, 32, Color(Pal.LIGHT_GRAY, a), 3.0)
	var pts := PackedVector2Array()
	if kind == 0:
		pts = PackedVector2Array([center + Vector2(10, -16), center + Vector2(-14, 0), center + Vector2(10, 16)])
	elif kind == 1:
		pts = PackedVector2Array([center + Vector2(-10, -16), center + Vector2(14, 0), center + Vector2(-10, 16)])
	else:
		pts = PackedVector2Array([center + Vector2(-16, 10), center + Vector2(0, -14), center + Vector2(16, 10)])
	draw_colored_polygon(pts, Color(Pal.WHITE, a))


func draw_hud() -> void:
	if score_tex:
		draw_texture(score_tex, Vector2(20, 12))
		put(str(score), Vector2(30.0 + score_tex.get_width(), 32), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Pal.YELLOW)
	else:
		put("SCORE  " + str(score), Vector2(20, 32), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Pal.YELLOW)

	if has_life:
		Samosa.draw_icon(self, 3, Vector2(32, 56), 0.6)
		put("EXTRA LIFE", Vector2(54, 62), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Pal.SALMON)
	elif revived and Time.get_ticks_msec() % 800 < 500:
		put("LAST LIFE!", Vector2(20, 62), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Pal.SALMON)

	if shield_left > 0.0:
		draw_rect(Rect2(20, 74, 120, 10), Color(Pal.NEAR_BLACK, 0.7))
		draw_rect(Rect2(20, 74, 120.0 * shield_frac, 10), Pal.TEAL)
		draw_rect(Rect2(20, 74, 120, 10), Pal.SKY, false, 1.0)
		put("SHIELD %.1f" % shield_left, Vector2(148, 84), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Pal.SKY)

	center_text("%.1f / %d" % [elapsed, int(SURVIVE_TIME)], 48, 34, Pal.WHITE)

	if best > 0.0:
		put("BEST TIME %.1f" % best, Vector2(0, 28), HORIZONTAL_ALIGNMENT_RIGHT, VIEW_W - 180.0, 16, Pal.LIGHT_GRAY)
	if best_score > 0:
		put("BEST SCORE %d" % best_score, Vector2(0, 48), HORIZONTAL_ALIGNMENT_RIGHT, VIEW_W - 180.0, 16, Pal.LIGHT_GRAY)

	draw_home_icon()
	draw_restart_icon()

	if Ctl.touch_enabled:
		if mode == 1:
			draw_touch_button(Layout.LEFT_CENTER, Ctl.left, 0, btn_left_tex)
			draw_touch_button(Layout.RIGHT_CENTER, Ctl.right, 1, btn_right_tex)
			draw_touch_button(Layout.JUMP_CENTER, Ctl.jump, 2, btn_jump_tex)
	elif controls_tex:
		draw_texture(controls_tex, Vector2((VIEW_W - controls_tex.get_width()) / 2.0, 504))
	else:
		center_text("A / D move   |   SPACE jump   |   R restart   |   ESC menu   |   M mute", 520, 16, Pal.LIGHT_GRAY)

	if mode == 1 and banner_time > 0.0:
		var a := clampf(banner_time / 0.5, 0.0, 1.0)
		center_text(banner_text, 150, 44, Color(Pal.YELLOW, a))


func draw_screens() -> void:
	var blink := Time.get_ticks_msec() % 1000 < 600

	if mode == 0:
		draw_title()
		return

	if mode == 4:
		draw_howto()
		return

	draw_hud()

	if not panel_ready:
		return

	var again := "TAP TO TRY AGAIN" if Ctl.touch_enabled else "PRESS SPACE TO TRY AGAIN"
	var again_win := "TAP TO GO AGAIN" if Ctl.touch_enabled else "PRESS SPACE TO GO AGAIN"
	var menu_hint := "tap the home icon for the menu" if Ctl.touch_enabled else "R retry     ESC / H menu"

	if mode == 2:
		draw_panel(death_tex)
		center_text(cause, 225, 44, Pal.SALMON)
		center_text("You lasted %.1f seconds" % elapsed, 272, 22, Pal.WHITE)
		center_text("Score: %d" % score, 302, 22, Pal.YELLOW)
		if new_best:
			center_text("NEW BEST!", 332, 20, Pal.GREEN)
		else:
			center_text("Best: %.1fs  /  %d pts" % [best, best_score], 332, 18, Pal.LIGHT_GRAY)
		if blink:
			center_text(again, 364, 18, Pal.SKY)
		center_text(menu_hint, 408, 16, Pal.LIGHT_GRAY)
	elif mode == 3:
		draw_panel(win_tex)
		center_text("SURVIVED!", 225, 44, Pal.GREEN)
		center_text("The machine has scheduled another cycle.", 272, 20, Pal.WHITE)
		center_text("Score: %d" % score, 302, 22, Pal.YELLOW)
		if new_best:
			center_text("NEW BEST!", 332, 20, Pal.GREEN)
		else:
			center_text("Best: %.1fs  /  %d pts" % [best, best_score], 332, 18, Pal.LIGHT_GRAY)
		if blink:
			center_text(again_win, 364, 18, Pal.SKY)
		center_text(menu_hint, 408, 16, Pal.LIGHT_GRAY)


func _draw() -> void:
	draw_screens()
	draw_mute_icon()
