extends CharacterBody2D

const ProjectileScript := preload("res://scripts/projectile.gd")

const SPEED := 180.0
const ARRIVAL_EPS := 3.0
const ATTACK_RANGE := 48.0
const MAX_HP := 100
const CLICK_PICK_RADIUS := 22.0
const PICKUP_RANGE := 40.0

const BASIC_ATTACK_DAMAGE := 12
const BASIC_ATTACK_CD := 0.6
const HEAVY_STRIKE_DAMAGE := 30
const HEAVY_STRIKE_CD := 1.5
const HEAVY_STRIKE_RANGE_BONUS := 12.0
const HEAL_POTION_AMOUNT := 40
const HEAL_POTION_CD := 5.0
const FIREBALL_BASE_DAMAGE := 22
const FIREBALL_CD := 1.8
const INTERACT_RANGE := 48.0

const LUNGE_DISTANCE := 10.0
const LUNGE_OUT_TIME := 0.06
const LUNGE_BACK_TIME := 0.14
const HEAVY_LUNGE_DISTANCE := 14.0
const HEAVY_LUNGE_OUT_TIME := 0.08
const HEAVY_LUNGE_BACK_TIME := 0.20
const SLASH_FADE_TIME := 0.18

const XP_PER_LEVEL_BASE := 100
const LEVEL_HP_BONUS := 10

var target_position: Vector2
var attack_target: Node2D = null
var pickup_target: Node2D = null
var interact_target: Node2D = null
var gold: int = 0
var hp: int = MAX_HP
var max_hp: int = MAX_HP
var level: int = 1
var xp: int = 0
var inventory: Inventory
var equipment: Equipment:
	set(value):
		if equipment != null and equipment.changed.is_connected(_on_equipment_changed):
			equipment.changed.disconnect(_on_equipment_changed)
		equipment = value
		if equipment != null:
			equipment.changed.connect(_on_equipment_changed)
		_recompute_stats()
var passives: Passives:
	set(value):
		if passives != null and passives.changed.is_connected(_on_equipment_changed):
			passives.changed.disconnect(_on_equipment_changed)
		passives = value
		if passives != null:
			passives.changed.connect(_on_equipment_changed)
		_recompute_stats()
var quests: Quests
var _spawn_position: Vector2
var _skill_cds: Dictionary = {}

func _ready() -> void:
	target_position = position
	_spawn_position = position
	add_to_group("player")

# ---------- Public ----------

func skill_cooldown_remaining(id: String) -> float:
	return _skill_cds.get(id, 0.0)

func set_spawn_position(pos: Vector2) -> void:
	_spawn_position = pos

func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount

func spend_gold(amount: int) -> bool:
	if amount <= 0 or gold < amount:
		return false
	gold -= amount
	return true

func xp_to_next_level() -> int:
	return XP_PER_LEVEL_BASE * level

func gain_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	while xp >= xp_to_next_level():
		xp -= xp_to_next_level()
		_level_up()

func _level_up() -> void:
	level += 1
	_recompute_stats()
	hp = max_hp
	if passives != null:
		passives.grant_points(1)
	_flash(Color(2.2, 2.2, 0.6))

func pickup_item(item: Item) -> bool:
	if inventory == null:
		return false
	return inventory.add(item)

func equip_inventory_item(index: int) -> bool:
	if inventory == null or equipment == null:
		return false
	if index < 0 or index >= inventory.items.size():
		return false
	var item: Item = inventory.items[index]
	var slot_key := equipment.first_free_slot_for(item)
	if slot_key.is_empty():
		return false
	inventory.remove_at(index)
	var prev := equipment.equip(item, slot_key)
	if prev != null:
		inventory.add(prev)
	return true

func unequip_slot(slot_key: String) -> bool:
	if inventory == null or equipment == null:
		return false
	if inventory.size() >= Inventory.CAPACITY:
		return false
	var it := equipment.unequip(slot_key)
	if it == null:
		return false
	inventory.add(it)
	return true

func total_stat(stat_name: String) -> int:
	var total: int = 0
	if equipment != null:
		for key in equipment.slots.keys():
			var item: Item = equipment.slots[key]
			if item == null:
				continue
			for s in item.stats:
				if s.name == stat_name:
					total += int(s.value)
	if passives != null:
		total += passives.flat_stat(stat_name)
	return total

func passive_increase(tag: String) -> float:
	if passives == null:
		return 0.0
	return passives.increased(tag)

func apply_increased(amount: int, tag: String) -> int:
	return int(round(float(amount) * (1.0 + passive_increase(tag) / 100.0)))

func effective_speed() -> float:
	return SPEED * (1.0 + passive_increase("move_speed") / 100.0)

func build_attack_packet(base: int) -> Dictionary:
	var phys: int = base + total_stat("Strength") + (level - 1)
	return {
		"physical": apply_increased(phys, "physical"),
		"fire":      apply_increased(total_stat("Fire Damage"), "fire"),
		"cold":      apply_increased(total_stat("Cold Damage"), "cold"),
		"lightning": apply_increased(total_stat("Lightning Damage"), "lightning"),
	}

func take_damage(packet: Dictionary) -> void:
	var total: int = 0
	var armor := total_stat("Armor")
	for type in packet.keys():
		var amt: int = int(packet[type])
		if amt <= 0:
			continue
		if type == "physical" and armor > 0:
			amt = int(round(amt * 50.0 / (50.0 + float(armor))))
		total += max(0, amt)
	if total <= 0:
		return
	hp = max(0, hp - total)
	_flash(Color(2.5, 0.6, 0.6))
	if hp == 0:
		print("Player died — respawning.")
		hp = max_hp
		global_position = _spawn_position
		target_position = _spawn_position
		attack_target = null

# ---------- Input ----------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_engage_at(get_global_mouse_position())
	elif event.is_action_pressed("skill_1"):
		_engage_at(get_global_mouse_position())
	elif event.is_action_pressed("skill_2"):
		_cast_heavy_strike()
	elif event.is_action_pressed("skill_3"):
		_cast_heal_potion()
	elif event.is_action_pressed("skill_4"):
		_cast_fireball()

func _engage_at(cursor: Vector2) -> void:
	var npc := _npc_under_cursor(cursor)
	if npc != null:
		attack_target = null
		pickup_target = null
		interact_target = npc
		target_position = npc.global_position
		return
	var ground := _ground_item_under_cursor(cursor)
	if ground != null:
		attack_target = null
		interact_target = null
		pickup_target = ground
		target_position = ground.global_position
		return
	var picked := _monster_under_cursor(cursor)
	if picked != null:
		pickup_target = null
		interact_target = null
		attack_target = picked
		return
	pickup_target = null
	attack_target = null
	interact_target = null
	target_position = cursor

# ---------- Physics ----------

func _physics_process(delta: float) -> void:
	_tick_cooldowns(delta)

	if interact_target != null and is_instance_valid(interact_target):
		var idist := global_position.distance_to(interact_target.global_position)
		if idist > INTERACT_RANGE:
			target_position = interact_target.global_position
			_move_toward_target()
			return
		velocity = Vector2.ZERO
		move_and_slide()
		if interact_target.has_method("interact"):
			interact_target.interact(self)
		interact_target = null
		return

	if pickup_target != null and is_instance_valid(pickup_target):
		var pdist := global_position.distance_to(pickup_target.global_position)
		if pdist > PICKUP_RANGE:
			target_position = pickup_target.global_position
			_move_toward_target()
			return
		var it: Item = pickup_target.item
		if it != null and pickup_item(it):
			pickup_target.queue_free()
		else:
			print("Cannot pick up — inventory full.")
		pickup_target = null
		velocity = Vector2.ZERO
		move_and_slide()
		return

	pickup_target = null

	if attack_target != null and is_instance_valid(attack_target):
		var dist := global_position.distance_to(attack_target.global_position)
		if dist > ATTACK_RANGE:
			target_position = attack_target.global_position
			_move_toward_target()
		else:
			velocity = Vector2.ZERO
			move_and_slide()
			if skill_cooldown_remaining("basic_attack") == 0.0:
				_do_basic_attack(attack_target)
		return

	attack_target = null
	_move_toward_target()

func _move_toward_target() -> void:
	var to_tgt := target_position - global_position
	if to_tgt.length() <= ARRIVAL_EPS:
		velocity = Vector2.ZERO
	else:
		velocity = to_tgt.normalized() * effective_speed()
	move_and_slide()

# ---------- Skills ----------

func _do_basic_attack(target: Node2D) -> void:
	_set_cd("basic_attack", BASIC_ATTACK_CD)
	var packet := build_attack_packet(BASIC_ATTACK_DAMAGE)
	_perform_melee(target, packet, LUNGE_DISTANCE, LUNGE_OUT_TIME, LUNGE_BACK_TIME)

func _cast_heavy_strike() -> void:
	if skill_cooldown_remaining("heavy_strike") > 0.0:
		return
	var target := _pick_target_for_skill()
	if target == null:
		return
	if global_position.distance_to(target.global_position) > ATTACK_RANGE + HEAVY_STRIKE_RANGE_BONUS:
		return
	_set_cd("heavy_strike", HEAVY_STRIKE_CD)
	var packet := build_attack_packet(HEAVY_STRIKE_DAMAGE)
	_perform_melee(target, packet, HEAVY_LUNGE_DISTANCE, HEAVY_LUNGE_OUT_TIME, HEAVY_LUNGE_BACK_TIME)

func _cast_fireball() -> void:
	if skill_cooldown_remaining("fireball") > 0.0:
		return
	var cursor := get_global_mouse_position()
	var dir := cursor - global_position
	if dir.length() < 0.01:
		return
	_set_cd("fireball", FIREBALL_CD)
	var raw: int = FIREBALL_BASE_DAMAGE + total_stat("Fire Damage") + (level - 1)
	var packet := { "fire": apply_increased(raw, "fire") }
	var proj := Node2D.new()
	proj.set_script(ProjectileScript)
	get_tree().current_scene.add_child(proj)
	proj.setup(global_position, dir, packet)

func _cast_heal_potion() -> void:
	if skill_cooldown_remaining("heal_potion") > 0.0:
		return
	if hp >= max_hp:
		return
	_set_cd("heal_potion", HEAL_POTION_CD)
	hp = min(max_hp, hp + HEAL_POTION_AMOUNT)
	_flash(Color(0.6, 2.2, 0.6))

# ---------- Helpers ----------

func _pick_target_for_skill() -> Node2D:
	if attack_target != null and is_instance_valid(attack_target):
		return attack_target
	return _monster_under_cursor(get_global_mouse_position())

func _npc_under_cursor(cursor_pos: Vector2) -> Node2D:
	var closest: Node2D = null
	var closest_d: float = CLICK_PICK_RADIUS
	for n in get_tree().get_nodes_in_group("npcs"):
		var d: float = cursor_pos.distance_to(n.global_position)
		if d < closest_d:
			closest_d = d
			closest = n
	return closest

func _monster_under_cursor(cursor_pos: Vector2) -> Node2D:
	var closest: Node2D = null
	var closest_d: float = CLICK_PICK_RADIUS
	for m in get_tree().get_nodes_in_group("monsters"):
		var d: float = cursor_pos.distance_to(m.global_position)
		if d < closest_d:
			closest_d = d
			closest = m
	return closest

func _ground_item_under_cursor(cursor_pos: Vector2) -> Node2D:
	var closest: Node2D = null
	var closest_d: float = CLICK_PICK_RADIUS
	for gi in get_tree().get_nodes_in_group("ground_items"):
		var d: float = cursor_pos.distance_to(gi.global_position)
		if d < closest_d:
			closest_d = d
			closest = gi
	return closest

func _perform_melee(target: Node2D, packet: Dictionary, lunge_dist: float, out_t: float, back_t: float) -> void:
	var body := get_node_or_null("Body") as Node2D
	var dir := (target.global_position - global_position).normalized()
	var hit_pos := global_position + dir * 26.0
	if body == null:
		_resolve_hit(target, packet, hit_pos, dir)
		return
	var tween := create_tween()
	tween.tween_property(body, "position", dir * lunge_dist, out_t)
	tween.tween_callback(_resolve_hit.bind(target, packet, hit_pos, dir))
	tween.tween_property(body, "position", Vector2.ZERO, back_t)

func _resolve_hit(target: Node2D, packet: Dictionary, hit_pos: Vector2, dir: Vector2) -> void:
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(packet)
	_spawn_slash(hit_pos, dir)

func _spawn_slash(at: Vector2, dir: Vector2) -> void:
	var slash := Line2D.new()
	slash.global_position = at
	var perp := Vector2(-dir.y, dir.x)
	slash.points = PackedVector2Array([perp * -14.0, perp * 14.0])
	slash.default_color = Color(1, 1, 1, 0.95)
	slash.width = 3.0
	get_tree().current_scene.add_child(slash)
	var tween := create_tween()
	tween.tween_property(slash, "modulate:a", 0.0, SLASH_FADE_TIME)
	tween.tween_callback(slash.queue_free)

func _flash(tint: Color) -> void:
	var body := get_node_or_null("Body") as CanvasItem
	if body == null:
		return
	var original := body.modulate
	body.modulate = tint
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(body):
		body.modulate = original

func _set_cd(id: String, t: float) -> void:
	_skill_cds[id] = t

func _tick_cooldowns(delta: float) -> void:
	for k in _skill_cds.keys():
		_skill_cds[k] = max(0.0, _skill_cds[k] - delta)

func _on_equipment_changed() -> void:
	_recompute_stats()

func _recompute_stats() -> void:
	var new_max := MAX_HP + total_stat("Life") + (level - 1) * LEVEL_HP_BONUS
	max_hp = new_max
	if hp > max_hp:
		hp = max_hp
