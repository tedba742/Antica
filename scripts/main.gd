extends Node2D

const PlayerScript := preload("res://scripts/player.gd")
const MonsterScript := preload("res://scripts/monster.gd")
const MonsterArcherScript := preload("res://scripts/monster_archer.gd")
const MonsterMageScript := preload("res://scripts/monster_mage.gd")
const BossScript := preload("res://scripts/boss.gd")
const HPBarScript := preload("res://scripts/hp_bar.gd")
const HudScript := preload("res://scripts/hud.gd")
const SkillBarScript := preload("res://scripts/skill_bar.gd")
const InventoryPanelScript := preload("res://scripts/inventory_panel.gd")
const WorldTooltipScript := preload("res://scripts/world_tooltip.gd")
const ZoneScript := preload("res://scripts/zone.gd")
const ShopPanelScript := preload("res://scripts/shop_panel.gd")
const PassiveTreePanelScript := preload("res://scripts/passive_tree_panel.gd")
const OptionsPanelScript := preload("res://scripts/options_panel.gd")
const PauseMenuScript := preload("res://scripts/pause_menu.gd")
const QuestLogPanelScript := preload("res://scripts/quest_log_panel.gd")
const GroundItemScript := preload("res://scripts/ground_item.gd")
const ChatPanelScript := preload("res://scripts/chat_panel.gd")

const PLAYER_TEXTURE := preload("res://assets/kenney_tiny-dungeon/Tiles/tile_0085.png")
const MONSTER_TEXTURE := preload("res://assets/kenney_tiny-dungeon/Tiles/tile_0109.png")
const MONSTER_ARCHER_TEXTURE := preload("res://assets/kenney_tiny-dungeon/Tiles/tile_0112.png")
const MONSTER_MAGE_TEXTURE := preload("res://assets/kenney_tiny-dungeon/Tiles/tile_0111.png")

const MONSTER_TYPES := {
	"brute":  { "script": MonsterScript,       "texture": MONSTER_TEXTURE },
	"archer": { "script": MonsterArcherScript, "texture": MONSTER_ARCHER_TEXTURE },
	"mage":   { "script": MonsterMageScript,   "texture": MONSTER_MAGE_TEXTURE },
}
const BOSS_TEXTURE := preload("res://assets/kenney_tiny-dungeon/Tiles/tile_0123.png")
const ICON_BASIC := preload("res://assets/kenney_tiny-dungeon/Tiles/tile_0116.png")
const ICON_HEAVY := preload("res://assets/kenney_tiny-dungeon/Tiles/tile_0117.png")
const ICON_POTION := preload("res://assets/kenney_tiny-dungeon/Tiles/tile_0115.png")
const ICON_FIREBALL := preload("res://assets/kenney_tiny-dungeon/Tiles/tile_0114.png")

const RESPAWN_DELAY := 2.0
const MIN_SPAWN_DIST_FROM_PLAYER := 260.0
const ZONE_MARGIN := 120.0

var player: CharacterBody2D
var zone: Node2D
var _camera: Camera2D
var _shop_panel: CanvasLayer
var _current_zone_id: String = ""
var _bosses_defeated: Dictionary = {}

func _ready() -> void:
	randomize()
	get_tree().set_auto_accept_quit(false)
	player = _spawn_body(PlayerScript, PLAYER_TEXTURE, Vector2.ZERO)
	player.inventory = Inventory.new()
	player.equipment = Equipment.new()
	player.passives = Passives.new()
	player.quests = Quests.new()
	_attach_camera(player)
	_setup_hud(player)
	_setup_skill_bar(player)
	_setup_inventory_panel(player)
	_setup_shop_panel(player)
	_setup_passive_tree_panel(player)
	_setup_quest_log_panel(player)
	_setup_chat_panel()
	_setup_options_panel()
	_setup_pause_menu()
	_setup_world_tooltip()

	var start_zone: String = "starter"
	var start_entry: String = "center"
	var snap: Dictionary = GameState.pending_save
	if not snap.is_empty():
		_apply_snapshot(snap)
		start_zone = snap.get("zone_id", "starter")
		start_entry = "center"
	GameState.pending_save = {}
	_auto_accept_quests()
	_enter_zone(start_zone, start_entry)

func _auto_accept_quests() -> void:
	if player == null or player.quests == null:
		return
	if player.quests.status("kill_grom") == "":
		player.quests.accept("kill_grom")

func _setup_quest_log_panel(bound_player: Node) -> void:
	var panel := CanvasLayer.new()
	panel.set_script(QuestLogPanelScript)
	panel.name = "QuestLogPanel"
	add_child(panel)
	panel.bind_player(bound_player)

func _setup_chat_panel() -> void:
	var panel := CanvasLayer.new()
	panel.set_script(ChatPanelScript)
	panel.name = "ChatPanel"
	add_child(panel)
	panel.message_sent.connect(_on_chat_message_sent)

func _on_chat_message_sent(_text: String, _channel: String) -> void:
	# Future multiplayer hook: RPC to server, broadcast to peers.
	pass

func _chat_post_system(text: String) -> void:
	var chat := get_node_or_null("ChatPanel")
	if chat != null:
		chat.post_system(text)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_autosave()
		get_tree().quit()

func _setup_options_panel() -> void:
	var panel := CanvasLayer.new()
	panel.set_script(OptionsPanelScript)
	panel.name = "OptionsPanel"
	add_child(panel)

func _setup_pause_menu() -> void:
	var menu := CanvasLayer.new()
	menu.set_script(PauseMenuScript)
	menu.name = "PauseMenu"
	add_child(menu)
	menu.options_requested.connect(_on_pause_options)
	menu.quit_to_title_requested.connect(_on_pause_quit_to_title)
	menu.quit_game_requested.connect(_on_pause_quit_game)

func _on_pause_options() -> void:
	var panel := get_node_or_null("OptionsPanel")
	if panel != null:
		panel.visible = true
		if panel.has_method("_refresh"):
			panel._refresh()

func _on_pause_quit_to_title() -> void:
	_autosave()
	GameState.pending_save = {}
	GameState.current_character_name = ""
	get_tree().change_scene_to_file("res://scenes/title.tscn")

func _on_pause_quit_game() -> void:
	_autosave()
	get_tree().quit()

func _setup_passive_tree_panel(bound_player: Node) -> void:
	var panel := CanvasLayer.new()
	panel.set_script(PassiveTreePanelScript)
	panel.name = "PassiveTreePanel"
	add_child(panel)
	panel.bind_player(bound_player)

func _setup_shop_panel(bound_player: Node) -> void:
	_shop_panel = CanvasLayer.new()
	_shop_panel.set_script(ShopPanelScript)
	_shop_panel.name = "ShopPanel"
	add_child(_shop_panel)
	_shop_panel.bind_player(bound_player)

func _attach_camera(p: Node2D) -> void:
	_camera = Camera2D.new()
	_camera.name = "Camera"
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 8.0
	p.add_child(_camera)

func _enter_zone(zone_id: String, entry_name: String) -> void:
	for m in get_tree().get_nodes_in_group("monsters"):
		if m.tree_exited.is_connected(_schedule_respawn):
			m.tree_exited.disconnect(_schedule_respawn)
		m.queue_free()
	for g in get_tree().get_nodes_in_group("ground_items"):
		g.queue_free()
	if zone != null:
		zone.queue_free()

	zone = Node2D.new()
	zone.set_script(ZoneScript)
	zone.name = "Zone"
	add_child(zone)
	zone.exit_entered.connect(_on_exit_entered)
	zone.exit_reset_requested.connect(_on_exit_reset_requested)
	zone.npc_spawned.connect(_on_npc_spawned)
	zone.setup(zone_id)
	_current_zone_id = zone_id

	var spawn_pos: Vector2 = zone.entry_position(entry_name)
	player.global_position = spawn_pos
	player.target_position = spawn_pos
	player.attack_target = null
	player.pickup_target = null
	player.set_spawn_position(zone.entry_position("center"))

	_camera.limit_right = int(zone.zone_size().x)
	_camera.limit_bottom = int(zone.zone_size().y)
	_camera.reset_smoothing()

	for i in range(zone.monster_count()):
		_spawn_monster()

	if zone.has_boss():
		var boss_data: Dictionary = zone.boss_config()
		var unlocks: String = boss_data.get("unlocks", "")
		if _bosses_defeated.get(zone_id, false):
			if not unlocks.is_empty():
				zone.open_gate(unlocks)
		else:
			_spawn_boss(boss_data, zone_id)

	_autosave()

func _apply_snapshot(snap: Dictionary) -> void:
	player.level = int(snap.get("level", 1))
	player.xp    = int(snap.get("xp", 0))
	player.gold  = int(snap.get("gold", 0))
	if snap.has("inventory"):
		player.inventory.load_dict(snap["inventory"])
	if snap.has("equipment"):
		player.equipment.load_dict(snap["equipment"])
	if snap.has("passives"):
		player.passives.load_dict(snap["passives"])
	if snap.has("quests"):
		player.quests.load_dict(snap["quests"])
	_bosses_defeated.clear()
	for zid in snap.get("bosses_defeated", []):
		_bosses_defeated[zid] = true
	player._recompute_stats()
	player.hp = max(1, min(player.max_hp, int(snap.get("hp", player.max_hp))))

func _build_snapshot() -> Dictionary:
	return {
		"name":        GameState.current_character_name,
		"version":     1,
		"updated_at":  int(Time.get_unix_time_from_system()),
		"zone_id":     _current_zone_id,
		"level":       player.level,
		"xp":          player.xp,
		"gold":        player.gold,
		"hp":          player.hp,
		"bosses_defeated": _bosses_defeated.keys(),
		"inventory":   player.inventory.to_dict(),
		"equipment":   player.equipment.to_dict(),
		"passives":    player.passives.to_dict(),
		"quests":      player.quests.to_dict(),
	}

func _autosave() -> void:
	if GameState.current_character_name.is_empty():
		return
	if player == null or player.inventory == null:
		return
	SaveGame.write_snapshot(_build_snapshot())

func _on_exit_entered(exit_data: Dictionary) -> void:
	var dest: String = exit_data.get("to", "")
	if dest.is_empty():
		return
	var spawn_name: String = exit_data.get("spawn", "center")
	call_deferred("_enter_zone", dest, spawn_name)

func _on_exit_reset_requested(exit_data: Dictionary) -> void:
	var dest: String = exit_data.get("to", "")
	if dest.is_empty():
		return
	_bosses_defeated.erase(dest)
	var spawn_name: String = exit_data.get("spawn", "center")
	call_deferred("_enter_zone", dest, spawn_name)

func _on_npc_spawned(npc: Node2D) -> void:
	if npc.has_signal("interact_requested"):
		npc.interact_requested.connect(_on_npc_interact)

func _on_npc_interact(role: String, _npc: Node2D) -> void:
	match role:
		"merchant":
			if _shop_panel != null:
				_shop_panel.open()

func _spawn_body(script: Script, texture: Texture2D, pos: Vector2) -> CharacterBody2D:
	var body := CharacterBody2D.new()
	body.set_script(script)
	body.position = pos

	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(2.0, 2.0)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.name = "Body"
	body.add_child(sprite)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	shape.shape = circle
	body.add_child(shape)

	var hp_bar := HPBarScript.new()
	hp_bar.name = "HPBar"
	body.add_child(hp_bar)

	add_child(body)
	return body

func _spawn_boss(data: Dictionary, zone_id: String) -> void:
	var boss := CharacterBody2D.new()
	boss.set_script(BossScript)
	boss.position = data["position"]

	var sprite := Sprite2D.new()
	sprite.texture = BOSS_TEXTURE
	sprite.scale = Vector2(3.5, 3.5)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.modulate = Color(1.15, 0.85, 0.85)
	sprite.name = "Body"
	boss.add_child(sprite)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 24.0
	shape.shape = circle
	boss.add_child(shape)

	var hp_bar := HPBarScript.new()
	hp_bar.name = "HPBar"
	boss.add_child(hp_bar)

	var label := Label.new()
	label.text = data.get("name", "Boss")
	label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.6))
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.position = Vector2(-56, -64)
	label.size = Vector2(112, 18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss.add_child(label)

	boss.player = player
	boss.set_meta("zone_id", zone_id)
	boss.set_meta("unlocks", data.get("unlocks", ""))
	boss.set_meta("quest_id", data.get("quest_id", ""))
	boss.defeated.connect(_on_boss_defeated.bind(boss))
	add_child(boss)

func _on_boss_defeated(boss: Node) -> void:
	var zone_id: String = boss.get_meta("zone_id", "")
	var unlocks: String = boss.get_meta("unlocks", "")
	var quest_id: String = boss.get_meta("quest_id", "")
	if zone_id.is_empty():
		return
	_bosses_defeated[zone_id] = true
	var boss_name: String = _boss_display_name(zone_id)
	if not boss_name.is_empty():
		_chat_post_system("%s has fallen." % boss_name)
	if zone != null and is_instance_valid(zone) and _current_zone_id == zone_id and not unlocks.is_empty():
		zone.open_gate(unlocks)
	if not quest_id.is_empty() and player != null and player.quests != null and player.quests.is_active(quest_id):
		_grant_quest_reward(quest_id, boss.global_position)
		player.quests.complete(quest_id)
		var def: Dictionary = Quests.definition(quest_id)
		var qname: String = def.get("name", quest_id)
		_chat_post_system("Quest complete: %s" % qname)

func _boss_display_name(zone_id: String) -> String:
	if zone == null or not is_instance_valid(zone):
		return ""
	if _current_zone_id != zone_id:
		return ""
	var cfg: Dictionary = zone.boss_config()
	return cfg.get("name", "")

func _grant_quest_reward(quest_id: String, at: Vector2) -> void:
	if quest_id == "kill_grom":
		for i in range(5):
			var drop := Item.roll_rare()
			var offset := Vector2(randf_range(-48.0, 48.0), randf_range(-48.0, 48.0))
			_spawn_ground_item_at(drop, at + offset)

func _spawn_ground_item_at(it: Item, pos: Vector2) -> void:
	var gi := Node2D.new()
	gi.set_script(GroundItemScript)
	gi.setup(it)
	gi.position = pos
	add_child(gi)

func _spawn_monster() -> void:
	if zone == null or zone.monster_count() <= 0:
		return
	var zs: Vector2 = zone.zone_size()
	var pos: Vector2
	for attempt in range(20):
		pos = Vector2(
			randf_range(ZONE_MARGIN, zs.x - ZONE_MARGIN),
			randf_range(ZONE_MARGIN, zs.y - ZONE_MARGIN)
		)
		if pos.distance_to(player.global_position) > MIN_SPAWN_DIST_FROM_PLAYER:
			break
	var type_id: String = _pick_monster_type()
	var entry: Dictionary = MONSTER_TYPES.get(type_id, MONSTER_TYPES["brute"])
	var monster := _spawn_body(entry["script"], entry["texture"], pos)
	monster.player = player
	monster.tree_exited.connect(_schedule_respawn)

func _pick_monster_type() -> String:
	var spawns: Array = zone.monster_spawns()
	var total: int = 0
	for s in spawns:
		total += int(s.get("weight", 1))
	if total <= 0:
		return "brute"
	var roll: int = randi() % total
	for s in spawns:
		roll -= int(s.get("weight", 1))
		if roll < 0:
			return String(s.get("type", "brute"))
	return "brute"

func _schedule_respawn() -> void:
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	if not is_inside_tree() or not is_instance_valid(player) or zone == null:
		return
	if zone.monster_count() <= 0:
		return
	_spawn_monster()

func _setup_hud(bound_player: Node) -> void:
	var hud := CanvasLayer.new()
	hud.set_script(HudScript)
	hud.name = "HUD"
	add_child(hud)
	hud.bind_player(bound_player)

func _setup_skill_bar(bound_player: Node) -> void:
	var bar := CanvasLayer.new()
	bar.set_script(SkillBarScript)
	bar.name = "SkillBar"
	add_child(bar)
	var skills := [
		{ "id": "basic_attack", "name": "Basic Attack", "icon": ICON_BASIC },
		{ "id": "heavy_strike", "name": "Heavy Strike", "icon": ICON_HEAVY },
		{ "id": "heal_potion",  "name": "Heal Potion",  "icon": ICON_POTION },
		{ "id": "fireball",     "name": "Fireball",     "icon": ICON_FIREBALL },
	]
	bar.setup(bound_player, skills)

func _setup_inventory_panel(bound_player: Node) -> void:
	var panel := CanvasLayer.new()
	panel.set_script(InventoryPanelScript)
	panel.name = "InventoryPanel"
	add_child(panel)
	panel.bind_data(bound_player, bound_player.inventory, bound_player.equipment)

func _setup_world_tooltip() -> void:
	var tip := CanvasLayer.new()
	tip.set_script(WorldTooltipScript)
	tip.name = "WorldTooltip"
	add_child(tip)
