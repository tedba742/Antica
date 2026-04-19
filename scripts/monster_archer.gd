extends "res://scripts/monster_base.gd"

const EnemyProjectileScript := preload("res://scripts/enemy_projectile.gd")

const SPEED := 110.0
const DETECT_RADIUS := 380.0
const KITE_RADIUS_MIN := 190.0
const KITE_RADIUS_MAX := 280.0
const AIM_TIME := 0.45
const COOLDOWN := 1.6
const ARROW_DAMAGE := 9
const ARROW_SPEED := 520.0

enum State { IDLE, APPROACH, KITE, AIM }

var state: int = State.IDLE
var aim_t: float = 0.0
var cooldown_t: float = 0.0
var aim_dir: Vector2 = Vector2.RIGHT

func _ready() -> void:
	max_hp = 28
	xp_reward = 22
	resistances = {
		"physical":  0.0,
		"fire":     -0.10,
		"cold":      0.0,
		"lightning": 0.20,
	}
	base_tint = Color(0.90, 0.80, 1.00)
	super._ready()

func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	cooldown_t = max(0.0, cooldown_t - delta)
	var dist := global_position.distance_to(player.global_position)
	var to_player := (player.global_position - global_position).normalized()

	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			if dist <= DETECT_RADIUS:
				state = State.APPROACH
		State.APPROACH:
			if dist > DETECT_RADIUS * 1.1:
				state = State.IDLE
			elif dist < KITE_RADIUS_MIN:
				state = State.KITE
			elif cooldown_t <= 0.0 and dist <= KITE_RADIUS_MAX:
				_enter_aim(to_player)
			else:
				velocity = to_player * SPEED
				move_and_slide()
		State.KITE:
			if dist >= KITE_RADIUS_MIN + 30.0:
				state = State.APPROACH
			else:
				velocity = -to_player * SPEED * 0.9
				move_and_slide()
				if cooldown_t <= 0.0:
					_enter_aim(to_player)
		State.AIM:
			velocity = Vector2.ZERO
			aim_t -= delta
			if aim_t <= 0.0:
				_fire_arrow()
				set_telegraph(false)
				cooldown_t = COOLDOWN
				state = State.KITE if dist < KITE_RADIUS_MIN + 20.0 else State.APPROACH

func _enter_aim(dir: Vector2) -> void:
	state = State.AIM
	aim_t = AIM_TIME
	aim_dir = dir
	velocity = Vector2.ZERO
	set_telegraph(true, Color(2.0, 1.6, 2.2))

func _fire_arrow() -> void:
	if player == null or not is_instance_valid(player):
		return
	var dir := (player.global_position - global_position).normalized()
	var proj := Node2D.new()
	proj.set_script(EnemyProjectileScript)
	get_tree().current_scene.add_child(proj)
	proj.setup(global_position, dir, { "physical": ARROW_DAMAGE }, {
		"speed": ARROW_SPEED,
		"lifetime": 1.4,
		"hit_radius": 10.0,
		"style": "arrow",
	})
