extends CanvasLayer

const HOVER_RADIUS := 22.0

var _tooltip: Panel
var _label: RichTextLabel

func _ready() -> void:
	layer = 12
	_build()

func _build() -> void:
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

	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.position = Vector2(8, 6)
	_label.size = Vector2(224, 128)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.add_child(_label)

func _process(_delta: float) -> void:
	if _inventory_open():
		_tooltip.visible = false
		return
	var world_mouse := _world_mouse_position()
	var hover := _find_hovered_item(world_mouse)
	if hover == null or hover.item == null:
		_tooltip.visible = false
		return
	_label.text = hover.item.to_tooltip_bbcode()
	_tooltip.visible = true
	_place_tooltip(get_viewport().get_mouse_position())

func _inventory_open() -> bool:
	for p in get_tree().get_nodes_in_group("inventory_panel"):
		if p.visible:
			return true
	for p in get_tree().get_nodes_in_group("shop_panel"):
		if p.visible:
			return true
	for p in get_tree().get_nodes_in_group("passive_tree_panel"):
		if p.visible:
			return true
	return false

func _world_mouse_position() -> Vector2:
	var xf := get_viewport().get_canvas_transform()
	return xf.affine_inverse() * get_viewport().get_mouse_position()

func _find_hovered_item(world_pos: Vector2) -> Node2D:
	var closest: Node2D = null
	var closest_d: float = HOVER_RADIUS
	for gi in get_tree().get_nodes_in_group("ground_items"):
		var d: float = world_pos.distance_to(gi.global_position)
		if d < closest_d:
			closest_d = d
			closest = gi
	return closest

func _place_tooltip(mouse_screen: Vector2) -> void:
	var pos := mouse_screen + Vector2(16, 16)
	var vp := get_viewport().get_visible_rect().size
	pos.x = min(pos.x, vp.x - _tooltip.size.x - 4)
	pos.y = min(pos.y, vp.y - _tooltip.size.y - 4)
	_tooltip.position = pos
