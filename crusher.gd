extends Node2D

signal slammed
signal warned

enum State { IDLE, WARNING, SLAM, HOLD, RETRACT }

const VIEW_W := 960.0
const HEAD_W := 120.0
const HEAD_H := 60.0
const ROD_W := 24.0
const REST_BOTTOM := 0.0
const DOWN_BOTTOM := 480.0
const FLOOR_Y := 480.0
const MIN_SPACING := 220.0

var active := true
var start_delay := 1.5
var idle_time := 1.6
var warn_time := 0.85
var slam_time := 0.2
var hold_time := 0.35
var retract_time := 0.45
var chase_chance := 0.4

var target
var other
var next_x := 480.0
var state := State.IDLE
var timer := 0.0
var head_bottom := REST_BOTTOM

var head_tex: Texture2D
var rod_tex: Texture2D
var stripe_tex: Texture2D
var light_on_tex: Texture2D
var light_off_tex: Texture2D


func _ready() -> void:
	head_tex = Art.get_tex("res://assets/crusher_head.png")
	rod_tex = Art.get_tex("res://assets/crusher_rod.png")
	stripe_tex = Art.get_tex("res://assets/warning_stripe.png")
	light_on_tex = Art.get_tex("res://assets/light_on.png")
	light_off_tex = Art.get_tex("res://assets/light_off.png")
	timer = start_delay
	next_x = random_x()
	position.x = next_x


func activate(delay: float) -> void:
	active = true
	state = State.IDLE
	head_bottom = REST_BOTTOM
	timer = delay
	next_x = random_x()
	position.x = next_x
	set_process(true)


func is_lethal() -> bool:
	return active and (state == State.SLAM or state == State.HOLD)


func get_head_rect() -> Rect2:
	return Rect2(position.x - HEAD_W / 2.0, head_bottom - HEAD_H, HEAD_W, HEAD_H)


func upcoming() -> Dictionary:
	var t := 0.0
	match state:
		State.IDLE:
			t = timer + warn_time
		State.WARNING:
			t = timer
		State.SLAM:
			t = timer + hold_time + retract_time + idle_time + warn_time
		State.HOLD:
			t = timer + retract_time + idle_time + warn_time
		State.RETRACT:
			t = timer + idle_time + warn_time
	return {"x": next_x, "t": t}


func stop() -> void:
	set_process(false)
	state = State.IDLE
	head_bottom = REST_BOTTOM
	queue_redraw()


func random_x() -> float:
	var half := HEAD_W / 2.0
	var x := half
	for i in 12:
		x = randf_range(half, VIEW_W - half)
		if target != null and randf() < chase_chance:
			x = clampf(target.position.x + randf_range(-90.0, 90.0), half, VIEW_W - half)
		if other == null or not other.active:
			return x
		if absf(x - other.position.x) >= MIN_SPACING and absf(x - other.next_x) >= MIN_SPACING:
			return x
	return x


func _process(delta: float) -> void:
	match state:
		State.IDLE:
			timer -= delta
			if timer <= 0.0:
				position.x = next_x
				state = State.WARNING
				timer = warn_time
				warned.emit()
		State.WARNING:
			timer -= delta
			if timer <= 0.0:
				next_x = random_x()
				state = State.SLAM
				timer = slam_time
		State.SLAM:
			timer -= delta
			var t := 1.0 - clampf(timer / slam_time, 0.0, 1.0)
			head_bottom = lerpf(REST_BOTTOM, DOWN_BOTTOM, t * t)
			if timer <= 0.0:
				head_bottom = DOWN_BOTTOM
				state = State.HOLD
				timer = hold_time
				slammed.emit()
		State.HOLD:
			timer -= delta
			if timer <= 0.0:
				state = State.RETRACT
				timer = retract_time
		State.RETRACT:
			timer -= delta
			var t := 1.0 - clampf(timer / retract_time, 0.0, 1.0)
			head_bottom = lerpf(DOWN_BOTTOM, REST_BOTTOM, t * t * (3.0 - 2.0 * t))
			if timer <= 0.0:
				head_bottom = REST_BOTTOM
				state = State.IDLE
				timer = idle_time
	queue_redraw()


func _draw() -> void:
	if not active:
		return

	var blink := Time.get_ticks_msec() % 200 < 100

	if state == State.WARNING:
		if blink:
			draw_rect(Rect2(-HEAD_W / 2.0, 0, HEAD_W, FLOOR_Y), Color(Pal.SALMON, 0.15))
			if stripe_tex:
				draw_texture_rect(stripe_tex, Rect2(-HEAD_W / 2.0, FLOOR_Y, HEAD_W, 12), true)
			else:
				var sx := -HEAD_W / 2.0
				var flip := true
				while sx < HEAD_W / 2.0:
					var c := Pal.YELLOW if flip else Pal.NEAR_BLACK
					draw_rect(Rect2(sx, FLOOR_Y, 15, 12), c)
					flip = not flip
					sx += 15.0
		var lamp_tex := light_on_tex if blink else light_off_tex
		if lamp_tex:
			draw_texture(lamp_tex, Vector2(-12, 8))
		else:
			draw_circle(Vector2(0, 20), 12.0, Pal.SALMON if blink else Pal.BRICK)
		return

	if state == State.IDLE:
		return

	var top := head_bottom - HEAD_H
	if top > 0.0:
		if rod_tex:
			draw_texture_rect(rod_tex, Rect2(-ROD_W / 2.0, 0, ROD_W, top), true)
		else:
			draw_rect(Rect2(-ROD_W / 2.0, 0, ROD_W, top), Pal.SLATE)

	if head_tex:
		draw_texture_rect(head_tex, Rect2(-HEAD_W / 2.0, top, HEAD_W, HEAD_H), false)
	else:
		draw_rect(Rect2(-HEAD_W / 2.0, top, HEAD_W, HEAD_H), Pal.PURPLE)
		draw_rect(Rect2(-HEAD_W / 2.0, head_bottom - 10.0, HEAD_W, 10), Pal.BRICK)
