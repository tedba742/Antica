extends CanvasLayer

const SLOT_SIZE := 56.0
const SLOT_SPACING := 6.0
const BOTTOM_MARGIN := 24.0

var player: Node
var skills: Array = []
var _slot_nodes: Array = []
var _style_normal: StyleBoxFlat

func _ready() -> void:
	layer = 10
	_build_styles()
	get_viewport().size_changed.connect(_relayout)

func _build_styles() -> void:
	_style_normal = StyleBoxFlat.new()
	_style_normal.bg_color = Color(0.10, 0.10, 0.12, 0.90)
	_style_normal.border_color = Color(0.55, 0.55, 0.60)
	_style_normal.set_border_width_all(2)
	_style_normal.set_corner_radius_all(4)

func setup(p: Node, skill_defs: Array) -> void:
	player = p
	skills = skill_defs
	for i in range(skills.size()):
		var slot := _make_slot(skills[i], i + 1)
		add_child(slot)
		_slot_nodes.append(slot)
	_relayout()

func _make_slot(skill: Dictionary, key_num: int) -> Control:
	var root := Panel.new()
	root.add_theme_stylebox_override("panel", _style_normal)
	root.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	root.custom_minimum_size = root.size
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if skill.has("icon") and skill["icon"] != null:
		var icon := TextureRect.new()
		icon.texture = skill["icon"]
		icon.position = Vector2(6, 6)
		icon.size = Vector2(SLOT_SIZE - 12, SLOT_SIZE - 12)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(icon)

	var overlay := ColorRect.new()
	overlay.name = "CDOverlay"
	overlay.color = Color(0, 0, 0, 0.55)
	overlay.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay)

	var cd_label := Label.new()
	cd_label.name = "CDLabel"
	cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cd_label.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	cd_label.add_theme_color_override("font_color", Color.WHITE)
	cd_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	cd_label.add_theme_constant_override("shadow_offset_x", 1)
	cd_label.add_theme_constant_override("shadow_offset_y", 1)
	cd_label.visible = false
	cd_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cd_label)

	var key_label := Label.new()
	key_label.text = str(key_num)
	key_label.position = Vector2(4, -2)
	key_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	key_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	key_label.add_theme_constant_override("shadow_offset_x", 1)
	key_label.add_theme_constant_override("shadow_offset_y", 1)
	key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(key_label)

	return root

func _relayout() -> void:
	var vp_size := get_viewport().get_visible_rect().size
	var count := _slot_nodes.size()
	if count == 0:
		return
	var total_w: float = count * SLOT_SIZE + max(0, count - 1) * SLOT_SPACING
	var start_x: float = (vp_size.x - total_w) * 0.5
	var y: float = vp_size.y - SLOT_SIZE - BOTTOM_MARGIN
	for i in range(count):
		var node: Control = _slot_nodes[i]
		node.position = Vector2(start_x + i * (SLOT_SIZE + SLOT_SPACING), y)

func _process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	for i in range(skills.size()):
		var skill := skills[i] as Dictionary
		var id: String = skill.get("id", "")
		var remaining: float = 0.0
		if player.has_method("skill_cooldown_remaining"):
			remaining = player.skill_cooldown_remaining(id)
		var slot := _slot_nodes[i] as Control
		var overlay := slot.get_node_or_null("CDOverlay") as ColorRect
		var cd_label := slot.get_node_or_null("CDLabel") as Label
		if remaining > 0.0:
			if overlay: overlay.visible = true
			if cd_label:
				cd_label.visible = true
				cd_label.text = "%.1f" % remaining
		else:
			if overlay: overlay.visible = false
			if cd_label: cd_label.visible = false
