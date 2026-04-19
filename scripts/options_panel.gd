extends CanvasLayer

const PANEL_W := 520.0
const ROW_H := 36.0
const PANEL_PAD := 16.0
const TITLE_H := 32.0

var _root: Panel
var _list: VBoxContainer
var _hint: Label
var _capturing_action: String = ""

func _ready() -> void:
	layer = 20
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("options_panel")
	_build()
	get_viewport().size_changed.connect(_relayout)

func _unhandled_input(event: InputEvent) -> void:
	if _capturing_action != "":
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				_capturing_action = ""
				_refresh()
			else:
				GameState.rebind_action(_capturing_action, event.keycode)
				_capturing_action = ""
				_refresh()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_options"):
		visible = not visible
		if visible:
			_refresh()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		visible = false
		get_viewport().set_input_as_handled()

func _build() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.09, 0.10, 0.13, 0.97)
	bg.border_color = Color(0.55, 0.45, 0.25)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(6)

	var actions: Array = GameState.action_list()
	var panel_h: float = PANEL_PAD + TITLE_H + ROW_H * actions.size() + 72

	_root = Panel.new()
	_root.add_theme_stylebox_override("panel", bg)
	_root.size = Vector2(PANEL_W, panel_h)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var title := Label.new()
	title.text = "Options  —  Key Bindings"
	title.position = Vector2(PANEL_PAD, 8)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35))
	title.add_theme_font_size_override("font_size", 18)
	_root.add_child(title)

	_hint = Label.new()
	_hint.text = "Click a binding to rebind. Press the new key (ESC cancels)."
	_hint.position = Vector2(PANEL_PAD, 36)
	_hint.add_theme_color_override("font_color", Color(0.70, 0.70, 0.74))
	_root.add_child(_hint)

	_list = VBoxContainer.new()
	_list.position = Vector2(PANEL_PAD, PANEL_PAD + TITLE_H + 28)
	_list.size = Vector2(PANEL_W - PANEL_PAD * 2, ROW_H * actions.size())
	_list.add_theme_constant_override("separation", 4)
	_root.add_child(_list)

	var reset_btn := Button.new()
	reset_btn.text = "Reset Defaults"
	reset_btn.position = Vector2(PANEL_PAD, panel_h - 40)
	reset_btn.size = Vector2(128, 28)
	reset_btn.pressed.connect(_on_reset)
	_root.add_child(reset_btn)

	var close_btn := Button.new()
	close_btn.text = "Close (Esc)"
	close_btn.position = Vector2(PANEL_W - PANEL_PAD - 128, panel_h - 40)
	close_btn.size = Vector2(128, 28)
	close_btn.pressed.connect(func(): visible = false)
	_root.add_child(close_btn)

	_refresh()
	_relayout()

func _relayout() -> void:
	if _root == null:
		return
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_root.position = ((vp - _root.size) * 0.5).floor()

func _refresh() -> void:
	if _list == null:
		return
	for c in _list.get_children():
		c.queue_free()
	for action in GameState.action_list():
		_list.add_child(_make_row(action))
	if _capturing_action.is_empty():
		_hint.text = "Click a binding to rebind. Press the new key (ESC cancels)."
		_hint.add_theme_color_override("font_color", Color(0.70, 0.70, 0.74))
	else:
		_hint.text = "Press a key for \"%s\"  (ESC cancels)" % GameState.action_label(_capturing_action)
		_hint.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35))

func _make_row(action: String) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, ROW_H)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = GameState.action_label(action)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Color(0.90, 0.90, 0.92))
	row.add_child(label)

	var btn := Button.new()
	var kc: int = GameState.current_keycode(action)
	var is_capturing: bool = (_capturing_action == action)
	btn.text = "…press key…" if is_capturing else OS.get_keycode_string(kc)
	btn.custom_minimum_size = Vector2(160, ROW_H - 4)
	if is_capturing:
		btn.modulate = Color(1.2, 1.0, 0.5)
	btn.pressed.connect(_on_rebind_pressed.bind(action))
	row.add_child(btn)

	return row

func _on_rebind_pressed(action: String) -> void:
	_capturing_action = action
	_refresh()

func _on_reset() -> void:
	GameState.reset_bindings()
	_capturing_action = ""
	_refresh()
