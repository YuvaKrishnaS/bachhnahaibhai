extends CharacterBody2D

signal jumped
signal landed

const SPEED := 260.0
const ACCEL := 1800.0
const AIR_CONTROL := 0.8
const JUMP_VELOCITY := -440.0
const GRAVITY := 1100.0
const FLOOR_Y := 480.0
const W := Layout.PLAYER_W
const H := Layout.PLAYER_H
const REVIVE_INVULN := 2.0

var alive := true
var facing := 1.0
var squash := Vector2.ONE
var was_on_floor := true
var shield_time := 0.0
var invuln := 0.0
var red := false
var red_pending := 0.0

var tex: Texture2D
var dead_tex: Texture2D
var red_tex: Texture2D
var red_dead_tex: Texture2D
var shield_tex: Texture2D


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(W, H)
	shape.shape = rect
	add_child(shape)
	tex = Art.get_tex("res://assets/player.png")
	dead_tex = Art.get_tex("res://assets/player_dead.png")
	red_tex = Art.get_tex("res://assets/player_red.png")
	red_dead_tex = Art.get_tex("res://assets/player_red_dead.png")
	shield_tex = Art.get_tex("res://assets/shield.png")


func hit_rect() -> Rect2:
	return Rect2(position + Vector2(-W / 2.0 + 3.0, -H / 2.0 + 3.0), Vector2(W - 6.0, H - 6.0))


func shield_active() -> bool:
	return alive and shield_time > 0.0


func shield_rect() -> Rect2:
	var edge := W / 2.0 - 2.0
	var x0 := position.x + edge
	if facing < 0.0:
		x0 = position.x - edge - Layout.SHIELD_W
	var bottom := position.y + H / 2.0
	return Rect2(x0, bottom - Layout.SHIELD_H + 2.0, Layout.SHIELD_W, Layout.SHIELD_H)


func give_shield(seconds: float) -> void:
	shield_time = seconds


func revive() -> void:
	invuln = REVIVE_INVULN
	red_pending = 0.18
	velocity.y = -320.0
	squash = Vector2(0.7, 1.35)


func die() -> void:
	if not alive:
		return
	alive = false
	shield_time = 0.0
	velocity = Vector2.ZERO
	position.y = FLOOR_Y - H / 2.0
	squash = Vector2.ONE
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not alive:
		return

	shield_time = maxf(shield_time - delta, 0.0)
	invuln = maxf(invuln - delta, 0.0)
	if red_pending > 0.0:
		red_pending -= delta
		if red_pending <= 0.0:
			red = true

	var dir := 0.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or Ctl.left:
		dir -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or Ctl.right:
		dir += 1.0

	if dir != 0.0:
		facing = dir

	var accel := ACCEL
	if not is_on_floor():
		accel = ACCEL * AIR_CONTROL
		velocity.y += GRAVITY * delta

	velocity.x = move_toward(velocity.x, dir * SPEED, accel * delta)

	var jump_pressed := Input.is_physical_key_pressed(KEY_SPACE) \
		or Input.is_physical_key_pressed(KEY_UP) \
		or Input.is_physical_key_pressed(KEY_W) \
		or Ctl.jump

	if jump_pressed and is_on_floor():
		velocity.y = JUMP_VELOCITY
		squash = Vector2(0.75, 1.3)
		jumped.emit()

	move_and_slide()

	if is_on_floor() and not was_on_floor:
		squash = Vector2(1.35, 0.65)
		landed.emit()
	was_on_floor = is_on_floor()

	squash = squash.lerp(Vector2.ONE, 12.0 * delta)
	queue_redraw()


func _draw() -> void:
	var feet := Vector2(0, H / 2.0)

	if not alive:
		draw_set_transform(feet, 0.0, Vector2(facing, 1.0))
		var dtex: Texture2D = dead_tex
		if red and red_dead_tex != null:
			dtex = red_dead_tex
		var dr := Rect2(-Layout.DEAD_W / 2.0, -Layout.DEAD_H, Layout.DEAD_W, Layout.DEAD_H)
		if dtex:
			draw_texture_rect(dtex, dr, false)
		else:
			draw_rect(dr, Pal.SALMON if red else Pal.WHITE)
			draw_rect(Rect2(3, -9, 6, 3), Pal.NEAR_BLACK)
			draw_rect(Rect2(13, -9, 6, 3), Pal.NEAR_BLACK)
		return

	var a := 1.0
	if invuln > 0.0 and Time.get_ticks_msec() % 160 < 80:
		a = 0.35
	var mod := Color(1, 1, 1, a)

	draw_set_transform(feet, 0.0, Vector2(squash.x * facing, squash.y))
	var body: Texture2D = tex
	if red and red_tex != null:
		body = red_tex
	if body:
		draw_texture_rect(body, Rect2(-W / 2.0, -H, W, H), false, mod)
	else:
		var low := Pal.SALMON if red else Pal.LIGHT_GRAY
		draw_rect(Rect2(-W / 2.0, -H, W, H), Color(Pal.WHITE, a))
		draw_rect(Rect2(-W / 2.0, -H * 0.3, W, H * 0.3), Color(low, a))
		draw_rect(Rect2(0, -31, 6, 9), Color(Pal.NEAR_BLACK, a))
		draw_rect(Rect2(10, -31, 6, 9), Color(Pal.NEAR_BLACK, a))

	if shield_time > 0.0:
		var visible_now := true
		if shield_time < 1.2:
			visible_now = Time.get_ticks_msec() % 200 < 120
		if visible_now:
			draw_set_transform(feet, 0.0, Vector2(facing, 1.0))
			var sr := Rect2(W / 2.0 - 2.0, -Layout.SHIELD_H + 2.0, Layout.SHIELD_W, Layout.SHIELD_H)
			if shield_tex:
				draw_texture_rect(shield_tex, sr, false)
			else:
				draw_rect(sr, Pal.TEAL)
				draw_rect(Rect2(sr.position.x + 3.0, sr.position.y + 5.0, 4.0, sr.size.y - 10.0), Pal.SKY)
				draw_rect(sr, Pal.NEAR_BLACK, false, 2.0)
