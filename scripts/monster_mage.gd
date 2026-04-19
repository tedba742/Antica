extends "res://scripts/monster_base.gd"

const EnemyProjectileScript := preload("res://scripts/enemy_projectile.gd")

const SPEED := 65.0
const DETECT_RADIUS := 420.0
const PREFERRED_RANGE := 300.0
const CAST_TIME := 0.9
const COOLDOWN := 2.0
const BOLT_DAMAGE := 14
const BOLT_SPEED := 360.0

enum State { IDLE, REPOSITION, CAST }

var state: int = State.IDLE
var cast_t: float = 0.0
var cooldown_t: float = 0.0

func _ready() -> void:
	max_hp = 34
	xp_reward = 30
	resistances = {
		"physical":  0.10,
		"fire":      0.50,
		"cold":      0.0,
		"lightning": 0.0,
	}
	base_tint = Color(1.0, 0.78, 0.78)
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
				state = State.REPOSITION
		State.REPOSITION:
			if dist > DETECT_RADIUS * 1.15:
				state = State.IDLE
			elif cooldown_t <= 0.0 and dist <= DETECT_RADIUS:
				_enter_cast()
			else:
				var delta_r: float = dist - PREFERRED_RANGE
				if absf(delta_r) > 40.0:
					var dir := to_player if delta_r > 0.0 else -to_player
					velocity = dir * SPEED
					move_and_slide()
				else:
					velocity = Vector2.ZERO
		State.CAST:
			velocity = Vector2.ZERO
			cast_t -= delta
			if cast_t <= 0.0:
				_fire_bolt()
				set_telegraph(false)
				cooldown_t = COOLDOWN
				state = State.REPOSITION

func _enter_cast() -> void:
	state = State.CAST
	cast_t = CAST_TIME
	velocity = Vector2.ZERO
	set_telegraph(true, Color(2.4, 1.0, 0.6))

func _fire_bolt() -> void:
	if player == null or not is_instance_valid(player):
		return
	var dir := (player.global_position - global_position).normalized()
	var proj := Node2D.new()
	proj.set_script(EnemyProjectileScript)
	get_tree().current_scene.add_child(proj)
	proj.setup(global_position, dir, { "fire": BOLT_DAMAGE }, {
		"speed": BOLT_SPEED,
		"lifetime": 2.0,
		"hit_radius": 14.0,
		"style": "firebolt",
	})
