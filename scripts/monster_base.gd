extends CharacterBody2D

const GroundItemScript := preload("res://scripts/ground_item.gd")

var player: Node2D
var hp: int = 0
var max_hp: int = 40
var xp_reward: int = 25
var resistances: Dictionary = {
	"physical":  0.0,
	"fire":      0.0,
	"cold":      0.0,
	"lightning": 0.0,
}
var base_tint: Color = Color.WHITE
var _flash_restore: Color = Color.WHITE

func _ready() -> void:
	add_to_group("monsters")
	hp = max_hp
	var body := get_node_or_null("Body") as CanvasItem
	if body != null:
		body.modulate = base_tint
	_flash_restore = base_tint

func take_damage(packet: Dictionary) -> void:
	var total: int = 0
	for type in packet.keys():
		var amt: int = int(packet[type])
		if amt <= 0:
			continue
		var resist: float = resistances.get(type, 0.0)
		var after: int = int(round(float(amt) * (1.0 - resist)))
		total += max(0, after)
	if total <= 0:
		return
	hp = max(0, hp - total)
	_flash_hit()
	if hp == 0:
		_die()

func _die() -> void:
	if player != null and is_instance_valid(player) and player.has_method("gain_xp"):
		player.gain_xp(xp_reward)
	var drop := Item.roll_drop()
	_spawn_ground_item(drop)
	queue_free()

func _spawn_ground_item(it: Item) -> void:
	var gi := Node2D.new()
	gi.set_script(GroundItemScript)
	gi.setup(it)
	gi.position = global_position + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))
	get_tree().current_scene.add_child(gi)

func _flash_hit() -> void:
	var body := get_node_or_null("Body") as CanvasItem
	if body == null:
		return
	var restore := _flash_restore
	body.modulate = Color(3.0, 3.0, 3.0)
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(body):
		body.modulate = restore

func set_telegraph(on: bool, tint: Color = Color(2.0, 2.0, 0.5)) -> void:
	var body := get_node_or_null("Body") as CanvasItem
	if body == null:
		return
	if on:
		body.modulate = tint
		_flash_restore = tint
	else:
		body.modulate = base_tint
		_flash_restore = base_tint
