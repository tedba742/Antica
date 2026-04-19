extends Node2D

const SPEED := 380.0
const LIFETIME := 1.4
const HIT_RADIUS := 20.0

var direction: Vector2 = Vector2.RIGHT
var damage_packet: Dictionary = {}
var _t: float = 0.0
var _hit: bool = false
var _pulse: float = 0.0

func setup(from: Vector2, dir: Vector2, packet: Dictionary) -> void:
	global_position = from
	direction = dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT
	damage_packet = packet
	rotation = direction.angle()

func _process(delta: float) -> void:
	if _hit:
		return
	_t += delta
	_pulse += delta
	queue_redraw()
	if _t >= LIFETIME:
		_fade_and_free()
		return
	global_position += direction * SPEED * delta
	_check_hit()

func _check_hit() -> void:
	for m in get_tree().get_nodes_in_group("monsters"):
		if not is_instance_valid(m):
			continue
		if global_position.distance_to(m.global_position) <= HIT_RADIUS:
			if m.has_method("take_damage"):
				m.take_damage(damage_packet)
			_hit = true
			_explode()
			return

func _explode() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(2.2, 2.2), 0.10)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.14)
	tween.tween_callback(queue_free)

func _fade_and_free() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)

func _draw() -> void:
	var flicker: float = 1.0 + 0.15 * sin(_pulse * 30.0)
	draw_circle(Vector2.ZERO, 11.0 * flicker, Color(1.0, 0.35, 0.05, 0.35))
	draw_circle(Vector2.ZERO, 7.0, Color(1.0, 0.55, 0.15, 0.95))
	draw_circle(Vector2.ZERO, 3.5, Color(1.0, 0.95, 0.6, 1.0))
