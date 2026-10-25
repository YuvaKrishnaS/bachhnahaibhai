class_name Samosa
extends Node2D

const POINTS := [1, 3, 5, 0, 0]
const SIZES := [30.0, 42.0, 48.0, 40.0, 40.0]
const LIFETIMES := [7.0, 7.0, 7.0, 9.0, 8.0]
const POPUPS := ["+1", "+3", "+5", "EXTRA LIFE!", "SHIELD!"]
const PATHS := [
	"res://assets/samosa_normal.png",
	"res://assets/samosa_motu.png",
	"res://assets/samosa_tung.png",
	"res://assets/diamond.png",
	"res://assets/shield_item.png"
]
const BLINK_TIME := 1.8

var tier := 0
var age := 0.0
var base_y := 0.0


func setup(t: int, pos: Vector2) -> void:
	tier = t
	position = pos
	base_y = pos.y


func lifetime() -> float:
	var l: float = LIFETIMES[tier]
	return l


func get_rect() -> Rect2:
	var s: float = SIZES[tier]
	return Rect2(position - Vector2(s, s) / 2.0, Vector2(s, s))


func expired() -> bool:
	return age >= lifetime()


func _process(delta: float) -> void:
	age += delta
	position.y = base_y + sin(age * 4.0) * 3.0
	visible = true
	if lifetime() - age < BLINK_TIME:
		visible = Time.get_ticks_msec() % 160 < 100
	queue_redraw()


func _draw() -> void:
	if tier == 3:
		draw_circle(Vector2.ZERO, 30.0, Color(Pal.SALMON, 0.18 + 0.1 * sin(age * 6.0)))
	Samosa.draw_icon(self, tier, Vector2.ZERO)


static func draw_icon(canvas: CanvasItem, t: int, center: Vector2, icon_scale: float = 1.0) -> void:
	var s: float = SIZES[t] * icon_scale
	var texture := Art.get_tex(PATHS[t])
	if texture:
		canvas.draw_texture_rect(texture, Rect2(center - Vector2(s, s) / 2.0, Vector2(s, s)), false)
		return

	var h := s / 2.0

	if t == 3:
		var d := PackedVector2Array([
			center + Vector2(0, -h),
			center + Vector2(h * 0.8, 0),
			center + Vector2(0, h),
			center + Vector2(-h * 0.8, 0)
		])
		canvas.draw_colored_polygon(d, Pal.SALMON)
		canvas.draw_polyline(PackedVector2Array([d[0], d[1], d[2], d[3], d[0]]), Pal.BRICK, 2.0)
		canvas.draw_colored_polygon(PackedVector2Array([
			center + Vector2(0, -h * 0.7),
			center + Vector2(h * 0.3, -h * 0.2),
			center + Vector2(0, -h * 0.1),
			center + Vector2(-h * 0.3, -h * 0.2)
		]), Pal.WHITE)
		return

	if t == 4:
		var sh := PackedVector2Array([
			center + Vector2(-h * 0.75, -h * 0.8),
			center + Vector2(h * 0.75, -h * 0.8),
			center + Vector2(h * 0.75, h * 0.1),
			center + Vector2(0, h),
			center + Vector2(-h * 0.75, h * 0.1)
		])
		canvas.draw_colored_polygon(sh, Pal.TEAL)
		canvas.draw_polyline(PackedVector2Array([sh[0], sh[1], sh[2], sh[3], sh[4], sh[0]]), Pal.NEAR_BLACK, 2.0)
		canvas.draw_colored_polygon(PackedVector2Array([
			center + Vector2(-h * 0.35, -h * 0.4),
			center + Vector2(h * 0.35, -h * 0.4),
			center + Vector2(h * 0.35, 0),
			center + Vector2(0, h * 0.5),
			center + Vector2(-h * 0.35, 0)
		]), Pal.SKY)
		return

	var fills: Array = [Pal.PEACH, Pal.YELLOW, Pal.PINK]
	var edges: Array = [Pal.BRICK, Pal.PEACH, Pal.PURPLE]
	var fill: Color = fills[t]
	var edge: Color = edges[t]
	var pts := PackedVector2Array([
		center + Vector2(0, -h),
		center + Vector2(h, h * 0.8),
		center + Vector2(-h, h * 0.8)
	])
	canvas.draw_colored_polygon(pts, fill)
	canvas.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), edge, 2.0)
	if t == 2:
		canvas.draw_circle(center + Vector2(0, 2), 4.0, Pal.WHITE)
