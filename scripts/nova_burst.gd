extends Node2D

const FADE_TIME := 0.40

var radius: float = 120.0
var color: Color = Color(1.0, 0.5, 0.15)
var _t: float = 0.0

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= FADE_TIME:
		queue_free()

func _draw() -> void:
	var p: float = clampf(_t / FADE_TIME, 0.0, 1.0)
	var r: float = radius * (0.55 + 0.55 * p)
	var a: float = 1.0 - p
	var fill := color
	fill.a = 0.35 * a
	draw_circle(Vector2.ZERO, r, fill)
	var ring := color
	ring.a = 0.95 * a
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, ring, 3.0)
