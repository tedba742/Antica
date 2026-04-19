extends Node2D

var direction: Vector2 = Vector2.RIGHT
var damage_packet: Dictionary = {}
var speed: float = 420.0
var lifetime: float = 1.6
var hit_radius: float = 14.0
var style: String = "arrow"
var _t: float = 0.0
var _pulse: float = 0.0
var _hit: bool = false

func setup(from: Vector2, dir: Vector2, packet: Dictionary, opts: Dictionary = {}) -> void:
	global_position = from
	direction = dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT
	damage_packet = packet
	speed = float(opts.get("speed", speed))
	lifetime = float(opts.get("lifetime", lifetime))
	hit_radius = float(opts.get("hit_radius", hit_radius))
	style = String(opts.get("style", style))
	rotation = direction.angle()

func _process(delta: float) -> void:
	if _hit:
		return
	_t += delta
	_pulse += delta
	queue_redraw()
	if _t >= lifetime:
		_fade_and_free()
		return
	global_position += direction * speed * delta
	_check_hit()

func _check_hit() -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(p):
			continue
		if global_position.distance_to(p.global_position) <= hit_radius + 10.0:
			if p.has_method("take_damage"):
				p.take_damage(damage_packet)
			_hit = true
			_fade_and_free()
			return

func _fade_and_free() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)

func _draw() -> void:
	match style:
		"arrow":    _draw_arrow()
		"firebolt": _draw_firebolt()
		_:          draw_circle(Vector2.ZERO, 4.0, Color.WHITE)

func _draw_arrow() -> void:
	var shaft := Color(0.88, 0.80, 0.55)
	var head_col := Color(0.30, 0.28, 0.22)
	var feather := Color(0.95, 0.88, 0.62)
	draw_line(Vector2(-13, 0), Vector2(9, 0), shaft, 2.0)
	var head := PackedVector2Array([Vector2(13, 0), Vector2(5, -3.5), Vector2(5, 3.5)])
	draw_colored_polygon(head, head_col)
	draw_line(Vector2(-13, 0), Vector2(-17, -3), feather, 1.5)
	draw_line(Vector2(-13, 0), Vector2(-17, 3), feather, 1.5)

func _draw_firebolt() -> void:
	var flicker: float = 1.0 + 0.15 * sin(_pulse * 28.0)
	draw_circle(Vector2.ZERO, 10.0 * flicker, Color(0.95, 0.25, 0.15, 0.35))
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.45, 0.15, 0.95))
	draw_circle(Vector2.ZERO, 2.8, Color(1.0, 0.95, 0.65, 1.0))
