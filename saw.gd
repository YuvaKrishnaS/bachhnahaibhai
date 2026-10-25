extends Node2D

const VIEW_W := 960.0
const FLOOR_Y := 480.0
const RADIUS := 28.0
const START_X := -68.0

var active := false
var moving := false
var speed := 150.0
var dir := 1.0
var spin := 0.0
var warn_left := 0.0

var tex: Texture2D
var warn_tex: Texture2D


func _ready() -> void:
	tex = Art.get_tex("res://assets/saw.png")
	warn_tex = Art.get_tex("res://assets/saw_warning.png")
	position = Vector2(START_X, FLOOR_Y - RADIUS + 4.0)


func activate(new_speed: float) -> void:
	active = true
	moving = false
	speed = new_speed
	dir = 1.0
	warn_left = 1.5
	position.x = START_X


func stop() -> void:
	active = false
	moving = false
	set_process(false)
	queue_redraw()
	
func deflect(new_dir: float) -> void:
	dir = new_dir
	position.x += new_dir * 12.0

func predict_x(t: float) -> float:
	var lo := RADIUS
	var hi := VIEW_W - RADIUS
	var span := hi - lo
	var tt := t
	if not moving:
		tt = maxf(t - warn_left, 0.0)
	var cx := clampf(position.x, lo, hi)
	var s := cx - lo
	if dir < 0.0:
		s = span + (hi - cx)
	s = fposmod(s + speed * tt, span * 2.0)
	if s <= span:
		return lo + s
	return lo + span * 2.0 - s


func hits(rect: Rect2) -> bool:
	if not active or not moving:
		return false
	var cx := clampf(position.x, rect.position.x, rect.end.x)
	var cy := clampf(position.y, rect.position.y, rect.end.y)
	return Vector2(cx, cy).distance_to(position) < RADIUS - 4.0


func _process(delta: float) -> void:
	if not active:
		return

	if not moving:
		warn_left -= delta
		if warn_left <= 0.0:
			moving = true
		queue_redraw()
		return

	position.x += dir * speed * delta
	if dir > 0.0 and position.x >= VIEW_W - RADIUS:
		position.x = VIEW_W - RADIUS
		dir = -1.0
	elif dir < 0.0 and position.x <= RADIUS:
		position.x = RADIUS
		dir = 1.0

	spin += dir * (speed / RADIUS) * 1.5 * delta
	queue_redraw()


func _draw() -> void:
	if not active:
		return

	if not moving:
		if Time.get_ticks_msec() % 200 < 100:
			var origin := Vector2(4.0, FLOOR_Y - 56.0) - position
			if warn_tex:
				draw_texture(warn_tex, origin)
			else:
				draw_rect(Rect2(origin, Vector2(24, 56)), Pal.SALMON)
				draw_colored_polygon(PackedVector2Array([
					origin + Vector2(6, 14),
					origin + Vector2(20, 28),
					origin + Vector2(6, 42)
				]), Pal.NEAR_BLACK)
		return

	draw_set_transform(Vector2.ZERO, spin, Vector2.ONE)
	if tex:
		draw_texture(tex, -tex.get_size() / 2.0)
	else:
		var pts := PackedVector2Array()
		for i in 24:
			var a := TAU * float(i) / 24.0
			var r := RADIUS if i % 2 == 0 else RADIUS - 8.0
			pts.append(Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, Pal.LIGHT_GRAY)
		draw_circle(Vector2.ZERO, RADIUS - 14.0, Pal.SLATE)
		draw_circle(Vector2(RADIUS - 18.0, 0), 3.0, Pal.NEAR_BLACK)
		draw_circle(Vector2.ZERO, 5.0, Pal.NEAR_BLACK)
