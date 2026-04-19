extends Node2D

const WIDTH := 26.0
const HEIGHT := 3.0
const OFFSET_Y := -22.0

func _ready() -> void:
	position.y = OFFSET_Y

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var hp: int = parent.hp
	var max_hp: int = parent.max_hp
	if max_hp <= 0:
		return
	var pct: float = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	var bg := Rect2(-WIDTH * 0.5, 0.0, WIDTH, HEIGHT)
	draw_rect(bg, Color(0, 0, 0, 0.85), true)
	var fg := Rect2(-WIDTH * 0.5, 0.0, WIDTH * pct, HEIGHT)
	draw_rect(fg, Color(0.9, 0.2, 0.2), true)
	draw_rect(bg, Color(0, 0, 0, 1.0), false)
