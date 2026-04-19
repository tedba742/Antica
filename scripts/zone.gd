extends Node2D

signal exit_entered(exit_data: Dictionary)
signal exit_reset_requested(exit_data: Dictionary)
signal npc_spawned(npc: Node2D)

const NpcScript := preload("res://scripts/npc.gd")

const GRID_STEP := 64.0
const WALL_THICKNESS := 48.0

const MERCHANT_TEXTURE := preload("res://assets/kenney_tiny-dungeon/Tiles/tile_0088.png")

const ZONE_CONFIGS := {
	"starter": {
		"name": "Wilderness",
		"size": Vector2(3840, 2880),
		"biome": "grass",
		"floor_color": Color(0.22, 0.40, 0.18),
		"accent_color": Color(0.14, 0.28, 0.11),
		"flower_color": Color(0.95, 0.85, 0.45),
		"border_color": Color(0.05, 0.09, 0.04),
		"decor_seed": 1337,
		"monster_count": 10,
		"monster_spawns": [
			{ "type": "brute",  "weight": 3 },
			{ "type": "archer", "weight": 2 },
			{ "type": "mage",   "weight": 1 },
		],
		"exits": [
			{
				"to": "camp",
				"spawn": "west_gate",
				"rect": Rect2(Vector2(3792, 1360), Vector2(48, 200)),
				"label": "To Camp",
				"color": Color(0.35, 0.85, 0.45),
			},
		],
		"entries": {
			"center":    Vector2(240, 2640),
			"east_gate": Vector2(3700, 1460),
		},
		"npcs": [],
		"boss": {
			"name":     "Warlord Grom",
			"position": Vector2(2800, 1460),
			"unlocks":  "camp",
			"quest_id": "kill_grom",
		},
		"gates": [
			{
				"blocks_to": "camp",
				"rect": Rect2(Vector2(3040, 1320), Vector2(80, 280)),
			},
		],
	},
	"camp": {
		"name": "Camp",
		"size": Vector2(1600, 1200),
		"biome": "camp",
		"floor_color": Color(0.26, 0.22, 0.17),
		"accent_color": Color(0.34, 0.28, 0.21),
		"flower_color": Color(0.55, 0.40, 0.25),
		"border_color": Color(0.10, 0.08, 0.06),
		"decor_seed": 4242,
		"monster_count": 0,
		"exits": [
			{
				"to": "starter",
				"spawn": "east_gate",
				"rect": Rect2(Vector2(0, 500), Vector2(48, 200)),
				"label": "To Wilderness",
				"color": Color(0.9, 0.55, 0.25),
			},
		],
		"entries": {
			"center":    Vector2(800, 600),
			"west_gate": Vector2(110, 600),
		},
		"npcs": [
			{
				"name":     "Merchant Bram",
				"role":     "merchant",
				"position": Vector2(1000, 560),
				"texture":  MERCHANT_TEXTURE,
				"tint":     Color(1.0, 0.95, 0.7),
			},
		],
	},
}

var config: Dictionary = {}
var _gate_nodes: Dictionary = {}

func setup(zone_id: String) -> void:
	config = ZONE_CONFIGS[zone_id]
	z_index = -10
	_build_walls()
	_build_exits()
	_build_gates()
	_build_npcs()
	queue_redraw()

func _build_npcs() -> void:
	for npc_data in config.get("npcs", []):
		var npc := Node2D.new()
		npc.set_script(NpcScript)
		add_child(npc)
		npc.setup(npc_data)
		npc_spawned.emit(npc)

func zone_size() -> Vector2:
	return config["size"]

func zone_name() -> String:
	return config.get("name", "")

func monster_count() -> int:
	return int(config.get("monster_count", 0))

func monster_spawns() -> Array:
	return config.get("monster_spawns", [{ "type": "brute", "weight": 1 }])

func has_boss() -> bool:
	return config.has("boss")

func boss_config() -> Dictionary:
	return config.get("boss", {})

func open_gate(dest: String) -> void:
	if not _gate_nodes.has(dest):
		return
	for node in _gate_nodes[dest]:
		if is_instance_valid(node):
			node.queue_free()
	_gate_nodes.erase(dest)

func _build_gates() -> void:
	for gate_data in config.get("gates", []):
		_add_gate(gate_data)

func _add_gate(gate_data: Dictionary) -> void:
	var rect: Rect2 = gate_data["rect"]
	var dest: String = gate_data.get("blocks_to", "")
	var center: Vector2 = rect.position + rect.size * 0.5

	var body := StaticBody2D.new()
	body.position = center
	var col := CollisionShape2D.new()
	var rshape := RectangleShape2D.new()
	rshape.size = rect.size
	col.shape = rshape
	body.add_child(col)
	add_child(body)

	var poly := Polygon2D.new()
	poly.position = center
	var hw: float = rect.size.x * 0.5
	var hh: float = rect.size.y * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh),
	])
	poly.color = Color(0.35, 0.30, 0.25, 0.92)
	add_child(poly)

	var bars := Line2D.new()
	bars.position = center
	bars.points = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh), Vector2(-hw, -hh),
	])
	bars.width = 3.0
	bars.default_color = Color(0.12, 0.10, 0.08)
	add_child(bars)

	var nodes: Array = [body, poly, bars]
	var bar_color := Color(0.55, 0.45, 0.30)
	var step: float = 14.0
	var x: float = -hw + step
	while x < hw:
		var line := Line2D.new()
		line.position = center
		line.points = PackedVector2Array([Vector2(x, -hh), Vector2(x, hh)])
		line.width = 2.0
		line.default_color = bar_color
		add_child(line)
		nodes.append(line)
		x += step

	_gate_nodes[dest] = nodes

func entry_position(entry_name: String) -> Vector2:
	var entries: Dictionary = config.get("entries", {})
	return entries.get(entry_name, config["size"] * 0.5)

func _build_walls() -> void:
	var w: float = config["size"].x
	var h: float = config["size"].y
	var t: float = WALL_THICKNESS
	_add_wall(Vector2(w * 0.5, -t * 0.5), Vector2(w + t * 2.0, t))
	_add_wall(Vector2(w * 0.5, h + t * 0.5), Vector2(w + t * 2.0, t))
	_add_wall(Vector2(-t * 0.5, h * 0.5), Vector2(t, h))
	_add_wall(Vector2(w + t * 0.5, h * 0.5), Vector2(t, h))

func _add_wall(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = center
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)

func _build_exits() -> void:
	for exit_data in config.get("exits", []):
		_add_exit(exit_data)

func _add_exit(exit_data: Dictionary) -> void:
	var rect: Rect2 = exit_data["rect"]
	var center: Vector2 = rect.position + rect.size * 0.5
	var color: Color = exit_data.get("color", Color.WHITE)

	var area := Area2D.new()
	area.position = center
	area.input_pickable = true
	var col := CollisionShape2D.new()
	var rshape := RectangleShape2D.new()
	rshape.size = rect.size
	col.shape = rshape
	area.add_child(col)
	area.body_entered.connect(_on_body_entered_exit.bind(exit_data))
	area.input_event.connect(_on_exit_input_event.bind(exit_data))
	add_child(area)

	var poly := Polygon2D.new()
	poly.position = center
	var hw: float = rect.size.x * 0.5
	var hh: float = rect.size.y * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh),
	])
	var fill := color
	fill.a = 0.35
	poly.color = fill
	add_child(poly)

	var line := Line2D.new()
	line.points = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh), Vector2(-hw, -hh),
	])
	line.position = center
	line.width = 2.0
	line.default_color = color
	add_child(line)

	var label := Label.new()
	label.text = exit_data.get("label", "")
	label.position = Vector2(rect.position.x, rect.position.y - 26)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)

func _on_body_entered_exit(body: Node, exit_data: Dictionary) -> void:
	if body.is_in_group("player"):
		exit_entered.emit(exit_data)

func _on_exit_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, exit_data: Dictionary) -> void:
	if not (event is InputEventMouseButton):
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not event.ctrl_pressed:
		return
	exit_reset_requested.emit(exit_data)
	get_viewport().set_input_as_handled()

func _draw() -> void:
	var size: Vector2 = config["size"]
	draw_rect(Rect2(Vector2.ZERO, size), config["floor_color"])
	var biome: String = config.get("biome", "grid")
	match biome:
		"grass": _draw_grass(size)
		"camp":  _draw_camp(size)
		_:       _draw_grid(size)
	var border_col: Color = config["border_color"]
	var b: float = 6.0
	draw_rect(Rect2(Vector2(-b * 0.5, -b * 0.5), size + Vector2(b, b)), border_col, false, b)

func _draw_grid(size: Vector2) -> void:
	var grid_color: Color = config.get("accent_color", Color(0.2, 0.2, 0.2, 0.5))
	var x: float = GRID_STEP
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 1.0)
		x += GRID_STEP
	var y: float = GRID_STEP
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)
		y += GRID_STEP

func _draw_grass(size: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(config.get("decor_seed", 1))
	var tuft_color: Color = config["accent_color"]
	var flower_color: Color = config["flower_color"]
	var highlight := Color(0.30, 0.55, 0.22, 0.55)
	var area: float = size.x * size.y
	var tuft_count: int = int(area / 1800.0)
	for i in range(tuft_count):
		var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
		var r: float = 3.0 + rng.randf() * 3.5
		draw_circle(p, r, tuft_color)
		draw_circle(p + Vector2(-r * 0.5, -r * 0.45), r * 0.55, highlight)
	var flower_count: int = int(area / 9000.0)
	for i in range(flower_count):
		var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
		var c: Color = flower_color if rng.randf() < 0.65 else Color(0.95, 0.65, 0.85)
		draw_circle(p, 2.2, c)
		draw_circle(p, 0.9, Color(1.0, 1.0, 0.7))

func _draw_camp(size: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(config.get("decor_seed", 1))
	var stone: Color = config["accent_color"]
	var dark := Color(0.18, 0.15, 0.11, 0.7)
	var area: float = size.x * size.y
	var stone_count: int = int(area / 2400.0)
	for i in range(stone_count):
		var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
		var w: float = 6.0 + rng.randf() * 6.0
		var h: float = 4.0 + rng.randf() * 4.0
		draw_rect(Rect2(p - Vector2(w * 0.5, h * 0.5), Vector2(w, h)), stone)
		draw_rect(Rect2(p - Vector2(w * 0.5, h * 0.5), Vector2(w, h)), dark, false, 1.0)
