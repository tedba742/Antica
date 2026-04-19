extends CharacterBody2D

signal defeated

const GroundItemScript := preload("res://scripts/ground_item.gd")
const NovaBurstScript := preload("res://scripts/nova_burst.gd")

const MAX_HP := 400
const SPEED := 85.0
const DETECT_RADIUS := 640.0
const MELEE_RADIUS := 56.0

const SLAM_TELEGRAPH := 1.0
const SLAM_DAMAGE := 25
const SLAM_CD := 2.5

const NOVA_TELEGRAPH := 1.4
const NOVA_RADIUS := 160.0
const NOVA_DAMAGE := 30
const NOVA_CD := 8.0

const XP_REWARD := 250
const DROP_COUNT_MIN := 2
const DROP_COUNT_MAX := 4

const ENRAGE_THRESHOLD := 0.5
const ENRAGE_SPEED_MUL := 1.4
const ENRAGE_CD_MUL := 0.7

const RESISTANCES := {
	"physical":   0.20,
	"fire":       0.50,
	"cold":      -0.20,
	"lightning":  0.00,
}

enum State { IDLE, CHASE, SLAM_TELEGRAPH, NOVA_TELEGRAPH, DEAD }

var player: Node2D
var hp: int = MAX_HP
var max_hp: int = MAX_HP
var state: int = State.IDLE
var _telegraph_t: float = 0.0
var _slam_cd: float = 0.0
var _nova_cd: float = 3.0
var _enraged: bool = false

func _ready() -> void:
	add_to_group("monsters")
	add_to_group("bosses")
	z_index = 1

func take_damage(packet: Dictionary) -> void:
	if state == State.DEAD:
		return
	var total: int = 0
	for type in packet.keys():
		var amt: int = int(packet[type])
		if amt <= 0:
			continue
		var resist: float = RESISTANCES.get(type, 0.0)
		var after: int = int(round(float(amt) * (1.0 - resist)))
		total += max(0, after)
	if total <= 0:
		return
	hp = max(0, hp - total)
	_flash_hit()
	if not _enraged and float(hp) / float(max_hp) <= ENRAGE_THRESHOLD:
		_enter_enrage()
	if hp == 0:
		_die()

func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	if player != null and is_instance_valid(player) and player.has_method("gain_xp"):
		player.gain_xp(XP_REWARD)
	var n: int = randi_range(DROP_COUNT_MIN, DROP_COUNT_MAX)
	for i in range(n):
		var drop: Item = Item.roll_drop()
		if drop.rarity < 2 and randf() < 0.45:
			drop.rarity = min(2, drop.rarity + 1)
		_spawn_ground_item(drop)
	defeated.emit()
	queue_free()

func _spawn_ground_item(it: Item) -> void:
	var gi := Node2D.new()
	gi.set_script(GroundItemScript)
	gi.setup(it)
	var offset := Vector2(randf_range(-36.0, 36.0), randf_range(-36.0, 36.0))
	gi.position = global_position + offset
	get_tree().current_scene.add_child(gi)

func _flash_hit() -> void:
	var body := get_node_or_null("Body") as CanvasItem
	if body == null:
		return
	var base := _body_base_color()
	body.modulate = Color(3.0, 3.0, 3.0)
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(body):
		body.modulate = base

func _body_base_color() -> Color:
	if _enraged:
		return Color(1.8, 0.9, 0.9)
	return Color.WHITE

func _enter_enrage() -> void:
	_enraged = true
	var body := get_node_or_null("Body") as CanvasItem
	if body != null:
		body.modulate = _body_base_color()

func _current_speed() -> float:
	return SPEED * (ENRAGE_SPEED_MUL if _enraged else 1.0)

func _current_slam_cd() -> float:
	return SLAM_CD * (ENRAGE_CD_MUL if _enraged else 1.0)

func _current_nova_cd() -> float:
	return NOVA_CD * (ENRAGE_CD_MUL if _enraged else 1.0)

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if player == null or not is_instance_valid(player):
		velocity = Vector2.ZERO
		return

	_slam_cd = max(0.0, _slam_cd - delta)
	_nova_cd = max(0.0, _nova_cd - delta)

	var dist: float = global_position.distance_to(player.global_position)

	match state:
		State.IDLE, State.CHASE:
			if dist <= NOVA_RADIUS * 1.1 and _nova_cd <= 0.0:
				_begin_nova_telegraph()
			elif dist <= MELEE_RADIUS and _slam_cd <= 0.0:
				_begin_slam_telegraph()
			elif dist <= DETECT_RADIUS:
				state = State.CHASE
				var dir := (player.global_position - global_position).normalized()
				velocity = dir * _current_speed()
				move_and_slide()
			else:
				state = State.IDLE
				velocity = Vector2.ZERO
		State.SLAM_TELEGRAPH:
			velocity = Vector2.ZERO
			_telegraph_t -= delta
			queue_redraw()
			if _telegraph_t <= 0.0:
				_resolve_slam()
		State.NOVA_TELEGRAPH:
			velocity = Vector2.ZERO
			_telegraph_t -= delta
			queue_redraw()
			if _telegraph_t <= 0.0:
				_resolve_nova()

func _begin_slam_telegraph() -> void:
	state = State.SLAM_TELEGRAPH
	_telegraph_t = SLAM_TELEGRAPH
	velocity = Vector2.ZERO
	_set_slam_visual(true)

func _resolve_slam() -> void:
	_set_slam_visual(false)
	if player != null and is_instance_valid(player):
		var d: float = global_position.distance_to(player.global_position)
		if d <= MELEE_RADIUS + 12.0 and player.has_method("take_damage"):
			player.take_damage({ "physical": SLAM_DAMAGE })
	_slam_cd = _current_slam_cd()
	state = State.CHASE
	queue_redraw()

func _set_slam_visual(on: bool) -> void:
	var body := get_node_or_null("Body") as CanvasItem
	if body == null:
		return
	if on:
		body.modulate = Color(2.4, 2.0, 0.6)
	else:
		body.modulate = _body_base_color()

func _begin_nova_telegraph() -> void:
	state = State.NOVA_TELEGRAPH
	_telegraph_t = NOVA_TELEGRAPH
	velocity = Vector2.ZERO
	queue_redraw()

func _resolve_nova() -> void:
	if player != null and is_instance_valid(player):
		var d: float = global_position.distance_to(player.global_position)
		if d <= NOVA_RADIUS and player.has_method("take_damage"):
			player.take_damage({ "fire": NOVA_DAMAGE })
	_spawn_nova_burst()
	_nova_cd = _current_nova_cd()
	state = State.CHASE
	queue_redraw()

func _spawn_nova_burst() -> void:
	var burst := Node2D.new()
	burst.set_script(NovaBurstScript)
	burst.global_position = global_position
	burst.radius = NOVA_RADIUS
	burst.color = Color(1.0, 0.5, 0.15)
	get_tree().current_scene.add_child(burst)

func _draw() -> void:
	match state:
		State.NOVA_TELEGRAPH:
			var p: float = 1.0 - clampf(_telegraph_t / NOVA_TELEGRAPH, 0.0, 1.0)
			var r: float = NOVA_RADIUS * (0.35 + 0.65 * p)
			var a_fill: float = 0.15 + 0.25 * p
			var a_ring: float = 0.55 + 0.40 * p
			var fill := Color(1.0, 0.45, 0.12, a_fill)
			var ring := Color(1.0, 0.75, 0.25, a_ring)
			draw_circle(Vector2.ZERO, r, fill)
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, ring, 3.0)
			draw_arc(Vector2.ZERO, NOVA_RADIUS, 0.0, TAU, 64, Color(1.0, 0.9, 0.4, 0.45), 2.0)
		State.SLAM_TELEGRAPH:
			var p2: float = 1.0 - clampf(_telegraph_t / SLAM_TELEGRAPH, 0.0, 1.0)
			var a: float = 0.25 + 0.45 * p2
			draw_arc(Vector2.ZERO, MELEE_RADIUS, 0.0, TAU, 48, Color(1.0, 0.95, 0.4, a), 2.5)
