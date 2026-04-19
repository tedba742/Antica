extends CanvasLayer

const INV_COLS := 8
const INV_ROWS := 4
const EQUIP_COLS := 2
const EQUIP_ROWS := 4
const CELL_SIZE := 48.0
const CELL_PAD := 4.0
const PANEL_PAD := 16.0
const TITLE_HEIGHT := 28.0
const SECTION_LABEL_HEIGHT := 20.0
const SECTION_GAP := 24.0
const STATS_HEIGHT := 96.0

const EQUIP_LAYOUT: Array = [
	"helmet",    "amulet",
	"armor",     "weapon",
	"ring_left", "ring_right",
	"boots",     "",
]

var inventory: Inventory
var equipment: Equipment
var player: Node

var _root: Panel
var _inv_slots: Array = []
var _equip_slots: Dictionary = {}
var _tooltip: Panel
var _tooltip_label: RichTextLabel
var _stats_label: RichTextLabel

func _ready() -> void:
	layer = 15
	visible = false
	add_to_group("inventory_panel")
	_build()
	get_viewport().size_changed.connect(_relayout)

func bind_data(p: Node, inv: Inventory, eq: Equipment) -> void:
	player = p
	inventory = inv
	equipment = eq
	if inventory != null:
		inventory.changed.connect(_redraw)
	if equipment != null:
		equipment.changed.connect(_redraw)
	if p != null and p.passives != null:
		p.passives.changed.connect(_redraw)
	_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		visible = not visible
		if visible:
			_redraw()
		else:
			_tooltip.visible = false
		get_viewport().set_input_as_handled()

func _build() -> void:
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.08, 0.10, 0.95)
	bg_style.border_color = Color(0.55, 0.55, 0.60)
	bg_style.set_border_width_all(2)
	bg_style.set_corner_radius_all(6)

	var equip_w: float = EQUIP_COLS * CELL_SIZE + (EQUIP_COLS - 1) * CELL_PAD
	var equip_h: float = EQUIP_ROWS * CELL_SIZE + (EQUIP_ROWS - 1) * CELL_PAD
	var inv_w: float = INV_COLS * CELL_SIZE + (INV_COLS - 1) * CELL_PAD
	var inv_h: float = INV_ROWS * CELL_SIZE + (INV_ROWS - 1) * CELL_PAD
	var body_h: float = max(equip_h, inv_h) + SECTION_LABEL_HEIGHT
	var panel_w: float = PANEL_PAD * 2 + equip_w + SECTION_GAP + inv_w
	var panel_h: float = PANEL_PAD + TITLE_HEIGHT + body_h + STATS_HEIGHT + 8 + PANEL_PAD

	_root = Panel.new()
	_root.add_theme_stylebox_override("panel", bg_style)
	_root.size = Vector2(panel_w, panel_h)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var title := Label.new()
	title.text = "Inventory  —  press I to close"
	title.position = Vector2(PANEL_PAD, 6)
	title.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(title)

	var section_y: float = PANEL_PAD + TITLE_HEIGHT
	var equip_x: float = PANEL_PAD

	var eq_label := _make_section_label("Equipment", Vector2(equip_x, section_y))
	_root.add_child(eq_label)

	var grid_y: float = section_y + SECTION_LABEL_HEIGHT
	for i in range(EQUIP_LAYOUT.size()):
		var slot_key: String = EQUIP_LAYOUT[i]
		if slot_key.is_empty():
			continue
		var col := i % EQUIP_COLS
		var row := i / EQUIP_COLS
		var slot := _make_equip_slot(slot_key)
		slot.position = Vector2(
			equip_x + col * (CELL_SIZE + CELL_PAD),
			grid_y + row * (CELL_SIZE + CELL_PAD)
		)
		_root.add_child(slot)
		_equip_slots[slot_key] = slot

	var inv_x: float = equip_x + equip_w + SECTION_GAP
	var inv_label := _make_section_label("Bag", Vector2(inv_x, section_y))
	_root.add_child(inv_label)

	for i in range(INV_COLS * INV_ROWS):
		var col := i % INV_COLS
		var row := i / INV_COLS
		var slot := _make_inv_slot(i)
		slot.position = Vector2(
			inv_x + col * (CELL_SIZE + CELL_PAD),
			grid_y + row * (CELL_SIZE + CELL_PAD)
		)
		_root.add_child(slot)
		_inv_slots.append(slot)

	var stats_y: float = grid_y + max(equip_h, inv_h) + 8
	_stats_label = RichTextLabel.new()
	_stats_label.bbcode_enabled = true
	_stats_label.fit_content = true
	_stats_label.scroll_active = false
	_stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_label.position = Vector2(PANEL_PAD, stats_y)
	_stats_label.size = Vector2(panel_w - PANEL_PAD * 2, STATS_HEIGHT)
	_root.add_child(_stats_label)

	_build_tooltip()
	_relayout()

func _make_section_label(text: String, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_color_override("font_color", Color(0.85, 0.85, 0.90))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _make_slot_panel() -> Panel:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.18, 0.22, 0.95)
	style.border_color = Color(0.42, 0.42, 0.48)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", style)
	p.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
	p.size = Vector2(CELL_SIZE, CELL_SIZE)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	return p

func _make_inv_slot(index: int) -> Panel:
	var p := _make_slot_panel()
	p.set_meta("kind", "inv")
	p.set_meta("index", index)
	p.gui_input.connect(_on_slot_gui_input.bind(p))
	p.mouse_entered.connect(_on_slot_enter.bind(p))
	p.mouse_exited.connect(_on_slot_exit)
	return p

func _make_equip_slot(slot_key: String) -> Panel:
	var p := _make_slot_panel()
	p.set_meta("kind", "equip")
	p.set_meta("slot_key", slot_key)
	p.gui_input.connect(_on_slot_gui_input.bind(p))
	p.mouse_entered.connect(_on_slot_enter.bind(p))
	p.mouse_exited.connect(_on_slot_exit)
	return p

func _build_tooltip() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.06, 0.97)
	style.border_color = Color(0.65, 0.65, 0.70)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	_tooltip = Panel.new()
	_tooltip.add_theme_stylebox_override("panel", style)
	_tooltip.size = Vector2(240, 140)
	_tooltip.visible = false
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tooltip)
	_tooltip_label = RichTextLabel.new()
	_tooltip_label.bbcode_enabled = true
	_tooltip_label.fit_content = true
	_tooltip_label.scroll_active = false
	_tooltip_label.position = Vector2(8, 6)
	_tooltip_label.size = Vector2(224, 128)
	_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.add_child(_tooltip_label)

func _relayout() -> void:
	if _root == null:
		return
	var vp_size := get_viewport().get_visible_rect().size
	_root.position = ((vp_size - _root.size) * 0.5).floor()

func _item_in_slot(panel: Panel) -> Item:
	var kind: String = panel.get_meta("kind", "")
	if kind == "inv":
		var idx: int = panel.get_meta("index", -1)
		if inventory != null and idx >= 0 and idx < inventory.items.size():
			return inventory.items[idx]
	elif kind == "equip":
		var key: String = panel.get_meta("slot_key", "")
		if equipment != null and equipment.slots.has(key):
			return equipment.slots[key]
	return null

func _redraw() -> void:
	for i in range(_inv_slots.size()):
		var slot: Panel = _inv_slots[i]
		for c in slot.get_children():
			c.queue_free()
		if inventory != null and i < inventory.items.size():
			_paint_slot_icon(slot, inventory.items[i])

	for key in _equip_slots.keys():
		var eq_slot: Panel = _equip_slots[key]
		for c in eq_slot.get_children():
			c.queue_free()
		var item: Item = null
		if equipment != null and equipment.slots.has(key):
			item = equipment.slots[key]
		if item != null:
			_paint_slot_icon(eq_slot, item)
		else:
			_paint_slot_placeholder(eq_slot, Equipment.SLOT_LABELS.get(key, ""))

	_refresh_stats()

func _refresh_stats() -> void:
	if _stats_label == null or player == null:
		return
	var lines: Array = ["[b]Stats[/b]"]
	lines.append("Level %d   XP %d / %d   [color=#f4c74d]Gold: %d[/color]" % [
		player.level, player.xp, player.xp_to_next_level(), int(player.gold)
	])
	lines.append("Max HP: %d   Armor: %d" % [player.max_hp, player.total_stat("Armor")])
	var pkt: Dictionary = player.build_attack_packet(player.BASIC_ATTACK_DAMAGE)
	var parts: Array = ["[color=#eaeaea]Phys %d[/color]" % int(pkt.physical)]
	if int(pkt.fire) > 0:      parts.append("[color=#ff7a3a]Fire %d[/color]" % int(pkt.fire))
	if int(pkt.cold) > 0:      parts.append("[color=#6ac6ff]Cold %d[/color]" % int(pkt.cold))
	if int(pkt.lightning) > 0: parts.append("[color=#ffd95a]Light %d[/color]" % int(pkt.lightning))
	lines.append("Basic hit: " + "  ".join(parts))
	lines.append("[color=#8a8a8a]STR %d · DEX %d · INT %d · +Life %d[/color]" % [
		player.total_stat("Strength"),
		player.total_stat("Dexterity"),
		player.total_stat("Intelligence"),
		player.total_stat("Life"),
	])
	var phys_pct: int = int(player.passive_increase("physical"))
	var fire_pct: int = int(player.passive_increase("fire"))
	var ms_pct: int = int(player.passive_increase("move_speed"))
	if phys_pct > 0 or fire_pct > 0 or ms_pct > 0:
		var bits: Array = []
		if phys_pct > 0: bits.append("+%d%% Phys" % phys_pct)
		if fire_pct > 0: bits.append("+%d%% Fire" % fire_pct)
		if ms_pct > 0:   bits.append("+%d%% Move" % ms_pct)
		lines.append("[color=#ffd95a]%s[/color]" % "  ·  ".join(bits))
	_stats_label.text = "\n".join(lines)

func _paint_slot_icon(slot: Panel, item: Item) -> void:
	var icon := TextureRect.new()
	icon.texture = item.icon
	icon.position = Vector2(4, 4)
	icon.size = Vector2(CELL_SIZE - 8, CELL_SIZE - 8)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.modulate = Item.rarity_color(item.rarity)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)

func _paint_slot_placeholder(slot: Panel, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.position = Vector2(0, CELL_SIZE * 0.5 - 10)
	l.size = Vector2(CELL_SIZE, 20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", Color(0.45, 0.45, 0.50))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(l)

func _on_slot_gui_input(event: InputEvent, panel: Panel) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if player == null:
		return
	var kind: String = panel.get_meta("kind", "")
	if kind == "inv":
		var idx: int = panel.get_meta("index", -1)
		if player.has_method("equip_inventory_item"):
			player.equip_inventory_item(idx)
	elif kind == "equip":
		var key: String = panel.get_meta("slot_key", "")
		if player.has_method("unequip_slot"):
			player.unequip_slot(key)

func _on_slot_enter(panel: Panel) -> void:
	var item := _item_in_slot(panel)
	if item == null:
		_tooltip.visible = false
		return
	_tooltip_label.text = item.to_tooltip_bbcode()
	_tooltip.visible = true
	_update_tooltip_position()

func _on_slot_exit() -> void:
	_tooltip.visible = false

func _process(_delta: float) -> void:
	if _tooltip != null and _tooltip.visible:
		_update_tooltip_position()

func _update_tooltip_position() -> void:
	var mouse := get_viewport().get_mouse_position()
	var pos := mouse + Vector2(16, 16)
	var vp_size := get_viewport().get_visible_rect().size
	pos.x = min(pos.x, vp_size.x - _tooltip.size.x - 4)
	pos.y = min(pos.y, vp_size.y - _tooltip.size.y - 4)
	_tooltip.position = pos
