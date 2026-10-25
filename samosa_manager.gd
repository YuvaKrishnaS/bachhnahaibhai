extends Node2D

signal collected(points: int)
signal picked(kind: String)

const VIEW_W := 960.0
const FLOOR_Y := 480.0
const PLAYER_SPEED := 260.0
const COLUMN_HALF := 70.0
const MIN_SLACK := 0.2
const CANDIDATES := 14
const MAX_ACTIVE := 3
const SPAWN_GAP := 2.0
const TARGET_DIFFICULTY := [0.08, 0.5, 0.85]
const WEIGHTS := [0.6, 0.28, 0.12]
const DIAMOND_TARGET := 0.95
const SHIELD_TARGET := 0.3
const DIAMOND_TIME_MIN := 12.0
const DIAMOND_TIME_MAX := 32.0

var player
var crushers: Array = []
var saw
var spawn_timer := 1.2
var play_time := 0.0
var diamond_time := 0.0
var diamond_done := false
var shield_cooldown := 21.0
var samosas: Array = []
var popups: Array = []
var font: Font


func _ready() -> void:
	font = Art.get_font()
	diamond_time = randf_range(DIAMOND_TIME_MIN, DIAMOND_TIME_MAX)


func pick_tier() -> int:
	var r := randf()
	var acc := 0.0
	for i in WEIGHTS.size():
		acc += WEIGHTS[i]
		if r <= acc:
			return i
	return 0


func evaluate(x: float, h: float, threats: Array) -> float:
	var reach := absf(x - player.position.x) / PLAYER_SPEED
	if h > 10.0:
		reach += 0.25

	var worst := 0.0
	for threat in threats:
		var tx: float = threat["x"]
		var tt: float = threat["t"]
		var dist_edge := absf(x - tx) - COLUMN_HALF
		var d := 0.0
		if dist_edge < 0.0:
			var exit_time := (-dist_edge) / PLAYER_SPEED + 0.15
			var slack := tt - (reach + exit_time)
			if slack < MIN_SLACK:
				return -1.0
			d = 0.35 + 0.55 * (1.0 - clampf(slack / 1.4, 0.0, 1.0))
		else:
			d = 0.25 * (1.0 - clampf(dist_edge / 120.0, 0.0, 1.0))
		worst = maxf(worst, d)

	var difficulty := worst

	if saw != null and saw.active:
		var px: float = saw.predict_x(reach)
		var prox := 1.0 - clampf(absf(px - x) / 140.0, 0.0, 1.0)
		difficulty += prox * (0.3 if h < 60.0 else 0.1)

	difficulty += clampf(reach / 2.5, 0.0, 1.0) * 0.1
	if h > 10.0:
		difficulty += 0.1

	return clampf(difficulty, 0.0, 1.0)


func count_normal() -> int:
	var n := 0
	for s in samosas:
		if s.tier < 3:
			n += 1
	return n


func has_tier(t: int) -> bool:
	for s in samosas:
		if s.tier == t:
			return true
	return false


func find_spot(target: float, count: int) -> Dictionary:
	var threats: Array = []
	for c in crushers:
		if c.active:
			threats.append(c.upcoming())

	var best := {"x": randf_range(60.0, VIEW_W - 60.0), "h": 0.0, "d": 0.0}
	var best_err := 999.0

	for i in count:
		var x := randf_range(50.0, VIEW_W - 50.0)
		var h := 0.0
		if randf() < 0.5:
			h = randf_range(25.0, 75.0)

		var blocked := false
		for s in samosas:
			if absf(s.position.x - x) < 70.0:
				blocked = true
		if saw != null and saw.active and h < 60.0 and absf(saw.position.x - x) < 70.0:
			blocked = true
		if blocked:
			continue

		var d := evaluate(x, h, threats)
		if d < 0.0:
			continue

		var err := absf(d - target)
		if err < best_err:
			best_err = err
			best = {"x": x, "h": h, "d": d}

	return best


func place(tier: int, spot: Dictionary) -> void:
	var size: float = Samosa.SIZES[tier]
	var x: float = spot["x"]
	var h: float = spot["h"]
	var s := Samosa.new()
	s.setup(tier, Vector2(x, FLOOR_Y - size / 2.0 - h))
	add_child(s)
	samosas.append(s)
	print("pickup tier ", tier, " difficulty ", snappedf(float(spot["d"]), 0.01))


func spawn_samosa() -> void:
	var tier := pick_tier()
	var target: float = TARGET_DIFFICULTY[tier]
	place(tier, find_spot(target, CANDIDATES))


func spawn_special(tier: int, target: float, count: int) -> void:
	place(tier, find_spot(target, count))


func _process(delta: float) -> void:
	play_time += delta
	shield_cooldown = maxf(shield_cooldown - delta, 0.0)

	spawn_timer -= delta
	if spawn_timer <= 0.0 and count_normal() < MAX_ACTIVE:
		spawn_samosa()
		spawn_timer = SPAWN_GAP + randf()

	if not diamond_done and play_time >= diamond_time:
		diamond_done = true
		spawn_special(3, DIAMOND_TARGET, 40)

	if saw != null and saw.active and shield_cooldown <= 0.0:
		if not has_tier(4) and player.shield_time <= 0.0:
			spawn_special(4, SHIELD_TARGET, 20)
			shield_cooldown = randf_range(20.0, 25.0)

	for i in range(samosas.size() - 1, -1, -1):
		var s = samosas[i]
		if s.expired():
			s.queue_free()
			samosas.remove_at(i)
		elif player.alive and s.get_rect().intersects(player.hit_rect()):
			var colors: Array = [Pal.WHITE, Pal.YELLOW, Pal.PINK, Pal.SALMON, Pal.TEAL]
			popups.append({
				"pos": s.position + Vector2(0, -34),
				"text": Samosa.POPUPS[s.tier],
				"age": 0.0,
				"color": colors[s.tier]
			})
			if s.tier < 3:
				var pts: int = Samosa.POINTS[s.tier]
				collected.emit(pts)
			elif s.tier == 3:
				picked.emit("diamond")
			else:
				picked.emit("shield")
			s.queue_free()
			samosas.remove_at(i)

	for i in range(popups.size() - 1, -1, -1):
		popups[i]["age"] += delta
		popups[i]["pos"] += Vector2(0, -40.0 * delta)
		if popups[i]["age"] > 0.9:
			popups.remove_at(i)

	queue_redraw()


func _draw() -> void:
	for p in popups:
		var c: Color = p["color"]
		var a := 1.0 - float(p["age"]) / 0.9
		var pos: Vector2 = p["pos"]
		draw_string(font, pos - Vector2(100, 0), p["text"], HORIZONTAL_ALIGNMENT_CENTER, 200.0, 24, Color(c, a))
