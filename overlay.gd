extends Node2D

const W := 960.0
const H := 540.0

var active := false
var fade := 0.0
var flash := 0.0


func activate() -> void:
	active = true
	flash = 1.0


func _process(delta: float) -> void:
	if active:
		fade = minf(fade + delta * 2.5, 1.0)
	flash = maxf(flash - delta * 3.0, 0.0)
	queue_redraw()


func _draw() -> void:
	if fade > 0.0:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.004)
		draw_rect(Rect2(0, 0, W, H), Color(Pal.SALMON, (0.07 + 0.03 * pulse) * fade))
		for i in 10:
			var inset := float(i) * 5.0
			var a := (0.30 - float(i) * 0.03) * fade
			draw_rect(Rect2(inset, inset, W - inset * 2.0, H - inset * 2.0), Color(Pal.BRICK, a), false, 5.0)
	if flash > 0.0:
		draw_rect(Rect2(0, 0, W, H), Color(Pal.WHITE, flash * 0.45))
