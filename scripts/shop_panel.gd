extends CanvasLayer

const PANEL_W := 420.0
const PANEL_H := 480.0
const PANEL_PAD := 14.0
const TITLE_H := 26.0
const ROW_H := 34.0

var player: Node
var inventory: Inventory

var _root: Panel
var _title: Label
var _gold_label: Label
var _list: VBoxContainer
var _scroll: ScrollContainer
var _tooltip: Panel
var _tooltip_label: RichTextLabel
var _hover_item: Item = null

func _ready() -> void:
	layer = 16
	visible = false
	add_to_group("shop_panel")
	_build()
	get_viewport().size_changed.connect(_relayout)

func bind_player(p: Node) -> void:
	player = p
	inventory = p.inventory
	if inventory != null:
		inventory.changed.connect(_redraw)

func open() -> void:
	visible = true
	_redraw()
	_relayout()

func close() -> void:
	visible = false
	_tooltip.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _build() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.10, 0.96)
	bg.border_color = Color(0.7, 0.55, 0.25)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(6)

	_root = Panel.new()
	_root.add_theme_stylebox_override("panel", bg)
	_root.size = Vector2(PANEL_W, PANEL_H)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_title = Label.new()
	_title.text = "Merchant"
	_title.position = Vector2(PANEL_PAD, 6)
	_title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_title)

	_gold_label = Label.new()
	_gold_label.position = Vector2(PANEL_W - 120, 6)
	_gold_label.size = Vector2(106, 20)
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_gold_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.3))
	_gold_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_gold_label)

	var close_btn := Button.new()
	close_btn.text = "Close (Esc)"
	close_btn.position = Vector2(PANEL_W - 110, PANEL_H - 36)
	close_btn.size = Vector2(96, 24)
	close_btn.pressed.connect(close)
	_root.add_child(close_btn)

	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(PANEL_PAD, PANEL_PAD + TITLE_H)
	_scroll.size = Vector2(PANEL_W - PANEL_PAD * 2, PANEL_H - PANEL_PAD * 2 - TITLE_H - 40)
	_root.add_child(_scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	_scroll.add_child(_list)

	_build_tooltip()

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
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_root.position = ((vp - _root.size) * 0.5).floor()

func _redraw() -> void:
	if not visible:
		return
	for c in _list.get_children():
		c.queue_free()
	_gold_label.text = "Gold: %d" % (player.gold if player != null else 0)
	if inventory == null or inventory.items.is_empty():
		var empty := Label.new()
		empty.text = "(Nothing to sell)"
		empty.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		_list.add_child(empty)
		return
	for i in range(inventory.items.size()):
		_list.add_child(_make_row(i, inventory.items[i]))

func _make_row(index: int, item: Item) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size = Vector2(0, ROW_H)

	var icon := TextureRect.new()
	icon.texture = item.icon
	icon.custom_minimum_size = Vector2(ROW_H - 4, ROW_H - 4)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.modulate = Item.rarity_color(item.rarity)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var name_label := Label.new()
	name_label.text = "%s %s" % [Item.rarity_name(item.rarity), item.base_name]
	name_label.add_theme_color_override("font_color", Item.rarity_color(item.rarity))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.mouse_filter = Control.MOUSE_FILTER_STOP
	name_label.mouse_entered.connect(_on_row_enter.bind(item))
	name_label.mouse_exited.connect(_on_row_exit)
	row.add_child(name_label)

	var value := Label.new()
	value.text = "%d g" % item.sell_value()
	value.add_theme_color_override("font_color", Color(0.95, 0.78, 0.3))
	value.custom_minimum_size = Vector2(60, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(value)

	var sell_btn := Button.new()
	sell_btn.text = "Sell"
	sell_btn.custom_minimum_size = Vector2(60, ROW_H - 6)
	sell_btn.pressed.connect(_on_sell.bind(index))
	row.add_child(sell_btn)

	return row

func _on_sell(index: int) -> void:
	if inventory == null or player == null:
		return
	if index < 0 or index >= inventory.items.size():
		return
	var item: Item = inventory.items[index]
	var value: int = item.sell_value()
	inventory.remove_at(index)
	player.add_gold(value)
	_redraw()

func _on_row_enter(item: Item) -> void:
	_hover_item = item
	_tooltip_label.text = item.to_tooltip_bbcode()
	_tooltip.visible = true
	_update_tooltip_position()

func _on_row_exit() -> void:
	_hover_item = null
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
