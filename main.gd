extends Node2D

const VIEW_W := 960.0
const VIEW_H := 540.0
const FLOOR_Y := 480.0
const SURVIVE_TIME := 60.0
const PANEL_DELAY := 0.9
const STAGE_LENGTH := 10.0
const SHIELD_TIME := 10.0

const STAGES := [
	{"idle": 1.6, "warn": 0.85, "crushers": 1, "saw": 0.0, "name": "GO!"},
	{"idle": 1.1, "warn": 0.80, "crushers": 1, "saw": 0.0, "name": "FASTER!"},
	{"idle": 1.0, "warn": 0.75, "crushers": 1, "saw": 150.0, "name": "WATCH THE FLOOR!"},
	{"idle": 1.2, "warn": 0.75, "crushers": 2, "saw": 150.0, "name": "DOUBLE TROUBLE!"},
	{"idle": 0.9, "warn": 0.70, "crushers": 2, "saw": 190.0, "name": "NO MERCY!"},
	{"idle": 0.7, "warn": 0.65, "crushers": 2, "saw": 230.0, "name": "FINAL CYCLE!"}
]

enum Mode { TITLE, PLAYING, DEAD, WON, HOWTO }

static var best_time := 0.0
static var best_score := 0
static var skip_title := false
static var loaded := false

var mode := Mode.TITLE
var elapsed := 0.0
var score := 0
var menu_index := 0
var end_msec := 0
var new_best := false
var stage := -1
var banner_time := 0.0
var banner_text := ""
var cause := "SQUISHED!"
var shake := 0.0
var has_life := false
var revived := false
var last_block_msec := 0

var player
var crusher_a
var crusher_b
var crushers: Array = []
var saw
var manager
var ui
var sfx
var fx
var cam
var overlay
var bg_tex: Texture2D
var floor_tex: Texture2D


func _ready() -> void:
	RenderingServer.set_default_clear_color(Pal.NEAR_BLACK)
	DisplayServer.window_set_title("bachhnahaibhai")

	if not loaded:
		loaded = true
		var data := SaveData.load_data()
		best_time = data["time"]
		best_score = data["score"]

	bg_tex = Art.get_tex("res://assets/background.png")
	floor_tex = Art.get_tex("res://assets/floor.png")

	cam = Camera2D.new()
	cam.position = Vector2(VIEW_W / 2.0, VIEW_H / 2.0)
	add_child(cam)

	add_box(Vector2(VIEW_W / 2.0, FLOOR_Y + 30.0), Vector2(VIEW_W, 60.0))
	add_box(Vector2(-20.0, VIEW_H / 2.0), Vector2(40.0, VIEW_H * 2.0))
	add_box(Vector2(VIEW_W + 20.0, VIEW_H / 2.0), Vector2(40.0, VIEW_H * 2.0))
	add_box(Vector2(VIEW_W / 2.0, -20.0), Vector2(VIEW_W, 40.0))

	sfx = Sfx.new()
	add_child(sfx)

	player = CharacterBody2D.new()
	player.set_script(load("res://player.gd"))
	player.position = Vector2(VIEW_W / 2.0, FLOOR_Y - Layout.PLAYER_H / 2.0)
	player.jumped.connect(on_jumped)
	player.landed.connect(on_landed)
	add_child(player)

	crusher_a = make_crusher()
	crusher_b = make_crusher()
	crusher_b.active = false
	crusher_a.other = crusher_b
	crusher_b.other = crusher_a
	crushers = [crusher_a, crusher_b]
	for c in crushers:
		c.slammed.connect(on_slammed.bind(c))
		c.warned.connect(on_warned)

	saw = Node2D.new()
	saw.set_script(load("res://saw.gd"))

	manager = Node2D.new()
	manager.set_script(load("res://samosa_manager.gd"))
	manager.player = player
	manager.crushers = crushers
	manager.saw = saw
	manager.collected.connect(on_collected)
	manager.picked.connect(on_picked)

	add_child(manager)
	add_child(saw)
	add_child(crusher_a)
	add_child(crusher_b)

	fx = Node2D.new()
	fx.set_script(load("res://fx.gd"))
	add_child(fx)

	var env_layer := CanvasLayer.new()
	env_layer.layer = 5
	overlay = Node2D.new()
	overlay.set_script(load("res://overlay.gd"))
	env_layer.add_child(overlay)
	add_child(env_layer)

	var layer := CanvasLayer.new()
	layer.layer = 10
	ui = Node2D.new()
	ui.set_script(load("res://ui.gd"))
	layer.add_child(ui)
	add_child(layer)

	player.set_physics_process(false)
	crusher_a.set_process(false)
	crusher_b.set_process(false)
	manager.set_process(false)
	saw.set_process(false)

	if skip_title:
		start_game()


func make_crusher():
	var c = Node2D.new()
	c.set_script(load("res://crusher.gd"))
	c.position = Vector2(600.0, 0.0)
	c.target = player
	return c


func add_box(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = center
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)


func add_shake(amount: float) -> void:
	shake = maxf(shake, amount)


func feet_pos() -> Vector2:
	return player.position + Vector2(0, Layout.PLAYER_H / 2.0)


func on_jumped() -> void:
	sfx.play("jump", randf_range(0.95, 1.08))
	fx.burst(feet_pos(), 5, 8.0, 90.0, Pal.LIGHT_GRAY)


func on_landed() -> void:
	sfx.play("land", randf_range(0.9, 1.05), -4.0)
	fx.burst(feet_pos(), 6, 10.0, 70.0, Pal.LIGHT_GRAY)


func on_warned() -> void:
	sfx.play("warning")


func on_slammed(c) -> void:
	sfx.play("slam")
	add_shake(8.0)
	fx.burst(Vector2(c.position.x, FLOOR_Y), 14, 55.0, 220.0, Pal.PEACH)


func on_collected(points: int) -> void:
	score += points
	var names := {1: "pickup_1", 3: "pickup_3", 5: "pickup_5"}
	var colors := {1: Pal.WHITE, 3: Pal.YELLOW, 5: Pal.PINK}
	sfx.play(names[points])
	fx.burst(player.position, 8, 10.0, 130.0, colors[points])


func on_picked(kind: String) -> void:
	if kind == "diamond":
		has_life = true
		score += 10
		sfx.play("diamond")
		add_shake(4.0)
		fx.ring(player.position, Pal.SALMON, 140.0, 0.4)
		fx.burst(player.position, 12, 14.0, 160.0, Pal.SALMON)
		banner_text = "EXTRA LIFE!"
		banner_time = 1.6
	elif kind == "shield":
		player.give_shield(SHIELD_TIME)
		sfx.play("shield_get")
		fx.ring(player.position, Pal.TEAL, 100.0, 0.3)
		fx.burst(player.position, 8, 12.0, 120.0, Pal.TEAL)


func on_shield_block() -> void:
	var now := Time.get_ticks_msec()
	if now - last_block_msec < 200:
		return
	last_block_msec = now
	sfx.play("shield_block", randf_range(0.95, 1.1))
	add_shake(4.0)
	fx.burst(player.shield_rect().get_center(), 8, 6.0, 160.0, Pal.SKY)


func use_life() -> void:
	has_life = false
	revived = true
	player.revive()
	overlay.activate()
	sfx.play("revive")
	add_shake(10.0)
	fx.ring(player.position, Pal.SALMON)
	fx.burst(player.position, 16, 14.0, 200.0, Pal.SALMON)
	banner_text = "ONE LAST CHANCE!"
	banner_time = 2.0


func start_game() -> void:
	skip_title = true
	mode = Mode.PLAYING
	elapsed = 0.0
	score = 0
	stage = -1
	player.set_physics_process(true)
	crusher_a.set_process(true)
	manager.set_process(true)
	saw.set_process(true)


func apply_stage(s: int) -> void:
	var cfg: Dictionary = STAGES[s]
	for c in crushers:
		c.idle_time = cfg["idle"]
		c.warn_time = cfg["warn"]

	var wanted: int = cfg["crushers"]
	if wanted >= 2 and not crusher_b.active:
		crusher_b.activate(0.9)

	var saw_speed: float = cfg["saw"]
	if saw_speed > 0.0:
		if saw.active:
			saw.speed = saw_speed
		else:
			saw.activate(saw_speed)
			sfx.play("warning")

	if s > 0:
		sfx.play("stage")

	banner_text = cfg["name"]
	banner_time = 2.0


func end_game(new_mode: Mode) -> void:
	mode = new_mode
	end_msec = Time.get_ticks_msec()
	new_best = elapsed > best_time or score > best_score
	best_time = maxf(best_time, elapsed)
	best_score = maxi(best_score, score)
	SaveData.save_data(best_time, best_score)
	manager.set_process(false)

	if new_mode == Mode.WON:
		sfx.play("win")
		for c in crushers:
			c.stop()
		saw.stop()
	else:
		sfx.play("death")
		add_shake(12.0)


func restart() -> void:
	skip_title = true
	get_tree().reload_current_scene()


func to_title() -> void:
	skip_title = false
	get_tree().reload_current_scene()


func panel_ready() -> bool:
	if mode != Mode.DEAD and mode != Mode.WON:
		return false
	return (Time.get_ticks_msec() - end_msec) / 1000.0 >= PANEL_DELAY


func check_hazards() -> String:
	var r: Rect2 = player.hit_rect()
	for c in crushers:
		if c.is_lethal() and c.get_head_rect().intersects(r):
			return "SQUISHED!"

	if player.shield_active() and saw.hits(player.shield_rect()):
		var d := 1.0 if saw.position.x > player.position.x else -1.0
		saw.deflect(d)
		on_shield_block()
	elif saw.hits(r):
		return "SLICED!"

	return ""


func _physics_process(delta: float) -> void:
	if mode != Mode.PLAYING:
		return

	elapsed += delta

	var s := mini(int(elapsed / STAGE_LENGTH), STAGES.size() - 1)
	if s != stage:
		stage = s
		apply_stage(s)

	if player.alive and player.invuln <= 0.0:
		var hit := check_hazards()
		if hit != "":
			if has_life:
				use_life()
			else:
				cause = hit
				player.die()
				end_game(Mode.DEAD)
				return

	if elapsed >= SURVIVE_TIME:
		elapsed = SURVIVE_TIME
		end_game(Mode.WON)


func _process(delta: float) -> void:
	banner_time = maxf(banner_time - delta, 0.0)

	shake = move_toward(shake, 0.0, 30.0 * delta)
	cam.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake

	ui.mode = int(mode)
	ui.elapsed = elapsed
	ui.best = best_time
	ui.score = score
	ui.best_score = best_score
	ui.menu_index = menu_index
	ui.new_best = new_best
	ui.cause = cause
	ui.banner_text = banner_text
	ui.banner_time = banner_time
	ui.has_life = has_life
	ui.revived = revived
	ui.shield_left = player.shield_time
	ui.shield_frac = player.shield_time / SHIELD_TIME
	ui.panel_ready = panel_ready()


func toggle_mute() -> void:
	var m := not AudioServer.is_bus_mute(0)
	AudioServer.set_bus_mute(0, m)
	if not m:
		sfx.play("menu_select")


func handle_tap(pos: Vector2) -> void:
	if Layout.MUTE_RECT.grow(8.0).has_point(pos):
		toggle_mute()
		return

	if mode == Mode.TITLE:
		if Layout.PLAY_RECT.has_point(pos):
			menu_index = 0
			sfx.play("menu_select")
			start_game()
		elif Layout.HOWTO_RECT.has_point(pos):
			menu_index = 1
			sfx.play("menu_select")
			mode = Mode.HOWTO
	elif mode == Mode.HOWTO:
		sfx.play("menu_select")
		mode = Mode.TITLE
	else:
		if Layout.HOME_RECT.grow(8.0).has_point(pos):
			to_title()
			return
		if mode == Mode.PLAYING:
			if Layout.RESTART_RECT.grow(8.0).has_point(pos):
				restart()
		elif panel_ready():
			if Layout.PANEL_RECT.has_point(pos) or Layout.RESTART_RECT.grow(8.0).has_point(pos):
				restart()


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null:
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			handle_tap(mb.position)
		return

	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return

	var k := key.physical_keycode
	var go := k == KEY_SPACE or k == KEY_ENTER or k == KEY_KP_ENTER
	var nav := k == KEY_UP or k == KEY_DOWN or k == KEY_W or k == KEY_S
	var home := k == KEY_ESCAPE or k == KEY_H

	if k == KEY_M:
		toggle_mute()
		return

	if k == KEY_T:
		Ctl.touch_enabled = not Ctl.touch_enabled
		return

	if mode == Mode.TITLE:
		if nav:
			menu_index = (menu_index + 1) % 2
			sfx.play("menu_move")
		elif go:
			sfx.play("menu_select")
			if menu_index == 0:
				start_game()
			else:
				mode = Mode.HOWTO
	elif mode == Mode.HOWTO:
		if go or k == KEY_ESCAPE or k == KEY_BACKSPACE:
			sfx.play("menu_select")
			mode = Mode.TITLE
	elif mode == Mode.PLAYING:
		if home:
			to_title()
		elif k == KEY_R:
			restart()
	else:
		if home:
			to_title()
		elif (go or k == KEY_R) and panel_ready():
			restart()


func _draw() -> void:
	if bg_tex:
		draw_texture(bg_tex, Vector2.ZERO)
	else:
		draw_rect(Rect2(0, 0, VIEW_W, VIEW_H), Pal.NEAR_BLACK)
		var x := 0.0
		while x <= VIEW_W:
			draw_line(Vector2(x, 0), Vector2(x, FLOOR_Y), Pal.DARK_GRAY, 1.0)
			x += 80.0
		var y := 0.0
		while y <= FLOOR_Y:
			draw_line(Vector2(0, y), Vector2(VIEW_W, y), Pal.DARK_GRAY, 1.0)
			y += 80.0

	if floor_tex:
		draw_texture(floor_tex, Vector2(0, FLOOR_Y))
	else:
		draw_rect(Rect2(0, FLOOR_Y, VIEW_W, VIEW_H - FLOOR_Y), Pal.DARK_GRAY)
		draw_rect(Rect2(0, FLOOR_Y, VIEW_W, 6), Pal.LIGHT_GRAY)
