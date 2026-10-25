extends Node2D

var particles: Array = []
var rings: Array = []
var tex: Texture2D


func _ready() -> void:
	tex = Art.get_tex("res://assets/dust.png")


func burst(pos: Vector2, count: int, spread: float, up: float, color: Color) -> void:
	for i in count:
		particles.append({
			"pos": pos + Vector2(randf_range(-spread, spread), 0.0),
			"vel": Vector2(randf_range(-90.0, 90.0), -randf_range(up * 0.4, up)),
			"life": 0.0,
			"max": randf_range(0.25, 0.55),
			"color": color
		})


func ring(pos: Vector2, color: Color, max_radius: float = 420.0, duration: float = 0.5) -> void:
	rings.append({
		"pos": pos,
		"color": color,
		"radius": max_radius,
		"life": 0.0,
		"max": duration
	})


func _process(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var p = particles[i]
		p["life"] += delta
		var v: Vector2 = p["vel"]
		v.y += 450.0 * delta
		p["vel"] = v
		p["pos"] += v * delta
		if p["life"] >= p["max"]:
			particles.remove_at(i)

	for i in range(rings.size() - 1, -1, -1):
		rings[i]["life"] += delta
		if rings[i]["life"] >= rings[i]["max"]:
			rings.remove_at(i)

	queue_redraw()


func _draw() -> void:
	for p in particles:
		var a := 1.0 - float(p["life"]) / float(p["max"])
		var pos: Vector2 = p["pos"]
		if tex:
			draw_texture(tex, pos - tex.get_size() / 2.0, Color(1, 1, 1, a))
		else:
			var c: Color = p["color"]
			draw_rect(Rect2(pos - Vector2(2, 2), Vector2(4, 4)), Color(c, a))

	for r in rings:
		var t := float(r["life"]) / float(r["max"])
		var eased := 1.0 - (1.0 - t) * (1.0 - t)
		var radius: float = float(r["radius"]) * eased
		var c: Color = r["color"]
		draw_arc(r["pos"], radius, 0.0, TAU, 64, Color(c, 1.0 - t), lerpf(10.0, 1.0, t))
