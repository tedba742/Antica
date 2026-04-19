extends CanvasLayer

const CANVAS_SIZE := Vector2(640, 640)
const SMALL_RADIUS := 11.0
const NOTABLE_RADIUS := 16.0
const ROOT_RADIUS := 18.0

var player: Node
var passives: Passives

var _bg: Panel
var _title: Label
var _points_label: Label
var _canvas: Control
var _node_controls: Dictionary = {}
var _tooltip: Panel
var _tooltip_label: RichTextLabel
var _hover_id: String = ""

func _ready() -> void:
	layer = 17
	visible = false
	add_to_group("passive_tree_panel")
	_build()
	get_viewport().size_changed.connect(_relayout)

func bind_player(p: Node) -> void:
	player = p
	passives = p.passives
	if passives != null:
		passives.changed.connect(_refresh)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_passive_tree"):
		visible = not visible
		if visible:
			_refresh()
		else:
			_tooltip.visible = false
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and visible:
		visible = false
		_tooltip.visible = false
		get_viewport().set_input_as_handled()

func _build() -> void:
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.04, 0.04, 0.06, 0.96)
	bg_style.border_color = Color(0.5, 0.5, 0.6)
	bg_style.set_border_width_all(2)
	bg_style.set_corner_radius_all(4)

	_bg = Panel.new()
	_bg.add_theme_stylebox_override("panel", bg_style)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg)

	_title = Label.new()
	_title.text = "Passives  —  press T to close"
	_title.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	_title.position = Vector2(16, 10)
	_bg.add_child(_title)

	_points_label = Label.new()
	_points_label.add_theme_color_override("font_color", Color(0.98, 0.85, 0.35))
	_points_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_points_label.add_theme_constant_override("shadow_offset_x", 1)
	_points_label.add_theme_constant_override("shadow_offset_y", 1)
	_points_label.position = Vector2(16, 32)
	_bg.add_child(_points_label)

	_canvas = Control.new()
	_canvas.custom_minimum_size = CANVAS_SIZE
	_canvas.size = CANVAS_SIZE
	_canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	_canvas.draw.connect(_draw_edges)
	_bg.add_child(_canvas)

	for node_id in PassiveTree.NODES.keys():
		_node_controls[node_id] = _make_node_control(node_id)

	_build_tooltip()
	_relayout()

func _build_tooltip() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.06, 0.97)
	style.border_color = Color(0.65, 0.65, 0.70)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	_tooltip = Panel.new()
	_tooltip.add_theme_stylebox_override("panel", style)
	_tooltip.size = Vector2(240, 90)
	_tooltip.visible = false
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tooltip)
	_tooltip_label = RichTextLabel.new()
	_tooltip_label.bbcode_enabled = true
	_tooltip_label.fit_content = true
	_tooltip_label.scroll_active = false
	_tooltip_label.position = Vector2(8, 6)
	_tooltip_label.size = Vector2(224, 78)
	_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.add_child(_tooltip_label)

func _make_node_control(node_id: String) -> Control:
	var node: Dictionary = PassiveTree.NODES[node_id]
	var kind: String = node.get("kind", "small")
	var r: float = _radius_for_kind(kind)
	var ctrl := Control.new()
	ctrl.custom_minimum_size = Vector2(r * 2.0, r * 2.0)
	ctrl.size = Vector2(r * 2.0, r * 2.0)
	ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	ctrl.set_meta("node_id", node_id)
	ctrl.set_meta("radius", r)
	ctrl.position = Vector2(node["pos"]) - Vector2(r, r)
	ctrl.draw.connect(_draw_node.bind(ctrl))
	ctrl.gui_input.connect(_on_node_gui_input.bind(ctrl))
	ctrl.mouse_entered.connect(_on_node_enter.bind(node_id))
	ctrl.mouse_exited.connect(_on_node_exit)
	_canvas.add_child(ctrl)
	return ctrl

func _radius_for_kind(kind: String) -> float:
	match kind:
		"root":    return ROOT_RADIUS
		"notable": return NOTABLE_RADIUS
		_:         return SMALL_RADIUS

func _state_for(node_id: String) -> String:
	if passives == null:
		return "locked"
	if passives.has(node_id):
		return "allocated"
	if passives.can_allocate(node_id):
		return "allocatable"
	return "locked"

func _fill_color(node_id: String) -> Color:
	var node: Dictionary = PassiveTree.NODES[node_id]
	var kind: String = node.get("kind", "small")
	var state := _state_for(node_id)
	var base: Color
	match kind:
		"root":    base = Color(0.35, 0.65, 0.95)
		"notable": base = Color(0.95, 0.55, 0.20)
		_:         base = Color(0.75, 0.75, 0.78)
	match state:
		"allocated":   return base
		"allocatable": return base.lerp(Color(0.15, 0.15, 0.17), 0.55)
		_:             return base.lerp(Color(0.08, 0.08, 0.09), 0.80)

func _border_color(node_id: String) -> Color:
	match _state_for(node_id):
		"allocated":   return Color(1.0, 0.95, 0.6)
		"allocatable": return Color(0.95, 0.85, 0.35)
		_:             return Color(0.25, 0.25, 0.28)

func _draw_node(ctrl: Control) -> void:
	var node_id: String = ctrl.get_meta("node_id", "")
	var r: float = float(ctrl.get_meta("radius", SMALL_RADIUS))
	var center := Vector2(r, r)
	ctrl.draw_circle(center, r, _fill_color(node_id))
	ctrl.draw_arc(center, r, 0.0, TAU, 32, _border_color(node_id), 2.0)

func _draw_edges() -> void:
	for pair in PassiveTree.CONNECTIONS:
		var a_id: String = pair[0]
		var b_id: String = pair[1]
		var a_pos: Vector2 = PassiveTree.NODES[a_id]["pos"]
		var b_pos: Vector2 = PassiveTree.NODES[b_id]["pos"]
		var both_allocated: bool = passives != null and passives.has(a_id) and passives.has(b_id)
		var color: Color = Color(0.95, 0.78, 0.25, 0.90) if both_allocated else Color(0.35, 0.35, 0.40, 0.75)
		var width: float = 3.0 if both_allocated else 2.0
		_canvas.draw_line(a_pos, b_pos, color, width)

func _on_node_gui_input(event: InputEvent, ctrl: Control) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var node_id: String = ctrl.get_meta("node_id", "")
	if passives != null and passives.allocate(node_id):
		_refresh()

func _on_node_enter(node_id: String) -> void:
	_hover_id = node_id
	_tooltip_label.text = PassiveTree.node_description(node_id)
	_tooltip.visible = true
	_update_tooltip_position()

func _on_node_exit() -> void:
	_hover_id = ""
	_tooltip.visible = false

func _process(_delta: float) -> void:
	if _tooltip.visible:
		_update_tooltip_position()

func _update_tooltip_position() -> void:
	var mouse := get_viewport().get_mouse_position()
	var pos := mouse + Vector2(16, 16)
	var vp: Vector2 = get_viewport().get_visible_rect().size
	pos.x = min(pos.x, vp.x - _tooltip.size.x - 4)
	pos.y = min(pos.y, vp.y - _tooltip.size.y - 4)
	_tooltip.position = pos

func _refresh() -> void:
	if passives != null:
		_points_label.text = "Unspent Points: %d" % passives.unspent_points
	else:
		_points_label.text = ""
	_canvas.queue_redraw()
	for ctrl in _node_controls.values():
		ctrl.queue_redraw()

func _relayout() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_bg.size = vp
	_bg.position = Vector2.ZERO
	_canvas.position = ((vp - CANVAS_SIZE) * 0.5).floor() + Vector2(0, 16)
