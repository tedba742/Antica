extends "res://scripts/monster_base.gd"

const SPEED := 90.0
const DETECT_RADIUS := 320.0
const ATTACK_RADIUS := 40.0
const TELEGRAPH_TIME := 0.8
const SLAM_DAMAGE := 10

enum State { IDLE, CHASE, TELEGRAPH }

var telegraph_t: float = 0.0
var state: int = State.IDLE

func _ready() -> void:
	max_hp = 40
	xp_reward = 25
	resistances = {
		"physical":  0.00,
		"fire":     -0.25,
		"cold":      0.00,
		"lightning": 0.15,
	}
	base_tint = Color.WHITE
	super._ready()

func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var dist := global_position.distance_to(player.global_position)

	match state:
		State.IDLE, State.CHASE:
			if dist <= ATTACK_RADIUS:
				state = State.TELEGRAPH
				telegraph_t = TELEGRAPH_TIME
				velocity = Vector2.ZERO
				set_telegraph(true)
			elif dist <= DETECT_RADIUS:
				state = State.CHASE
				var dir := (player.global_position - global_position).normalized()
				velocity = dir * SPEED
				move_and_slide()
			else:
				state = State.IDLE
				velocity = Vector2.ZERO
		State.TELEGRAPH:
			telegraph_t -= delta
			if telegraph_t <= 0.0:
				set_telegraph(false)
				if dist <= ATTACK_RADIUS + 8.0 and player.has_method("take_damage"):
					player.take_damage({ "physical": SLAM_DAMAGE })
				state = State.CHASE
