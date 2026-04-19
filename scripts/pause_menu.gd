extends CanvasLayer

signal resume_requested
signal options_requested
signal quit_to_title_requested
signal quit_game_requested

const PANEL_W := 320.0
const BTN_H := 40.0
const BTN_GAP := 8.0
const PANEL_PAD := 20.0
const TITLE_H := 36.0

const BLOCKING_GROUPS: Array = [
	"shop_panel",
	"inventory_panel",
	"passive_tree_panel",
	"options_panel",
]

var _root: Panel
var _char_label: Label

func _ready() -> void:
	layer = 25
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("pause_menu")
	_build()
	get_viewport().size_changed.connect(_relayout)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if visible:
		_resume()
		get_viewport().set_input_as_handled()
		return
	if _any_blocking_panel_open():
		return
	_open()
	get_viewport().set_input_as_handled()

func _any_blocking_panel_open() -> bool:
	for group in BLOCKING_GROUPS:
		for n in get_tree().get_nodes_in_group(group):
			if "visible" in n and n.visible:
				return true
	return false

func _open() -> void:
	_char_label.text = GameState.current_character_name if not GameState.current_character_name.is_empty() else "—"
	visible = true
	get_tree().paused = true
	_relayout()

func _resume() -> void:
	visible = false
	get_tree().paused = false
	resume_requested.emit()

func _build() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.09, 0.12, 0.97)
	bg.border_color = Color(0.55, 0.45, 0.25)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(6)

	var panel_h: float = PANEL_PAD + TITLE_H + 24 + BTN_H * 4 + BTN_GAP * 3 + PANEL_PAD

	_root = Panel.new()
	_root.add_theme_stylebox_override("panel", bg)
	_root.size = Vector2(PANEL_W, panel_h)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var title := Label.new()
	title.text = "Paused"
	title.position = Vector2(PANEL_PAD, 10)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35))
	title.add_theme_font_size_override("font_size", 22)
	_root.add_child(title)

	_char_label = Label.new()
	_char_label.position = Vector2(PANEL_PAD, 42)
	_char_label.add_theme_color_override("font_color", Color(0.70, 0.70, 0.74))
	_root.add_child(_char_label)

	var btn_y: float = PANEL_PAD + TITLE_H + 24
	var btn_x: float = PANEL_PAD
	var btn_w: float = PANEL_W - PANEL_PAD * 2

	_add_button("Resume (Esc)", Vector2(btn_x, btn_y), Vector2(btn_w, BTN_H), _resume)
	btn_y += BTN_H + BTN_GAP
	_add_button("Options", Vector2(btn_x, btn_y), Vector2(btn_w, BTN_H), _on_options)
	btn_y += BTN_H + BTN_GAP
	_add_button("Save & Return to Title", Vector2(btn_x, btn_y), Vector2(btn_w, BTN_H), _on_quit_to_title)
	btn_y += BTN_H + BTN_GAP
	_add_button("Save & Quit to Desktop", Vector2(btn_x, btn_y), Vector2(btn_w, BTN_H), _on_quit_game)

func _add_button(text: String, pos: Vector2, sz: Vector2, handler: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = sz
	btn.pressed.connect(handler)
	_root.add_child(btn)

func _relayout() -> void:
	if _root == null:
		return
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_root.position = ((vp - _root.size) * 0.5).floor()

func _on_options() -> void:
	options_requested.emit()

func _on_quit_to_title() -> void:
	visible = false
	get_tree().paused = false
	quit_to_title_requested.emit()

func _on_quit_game() -> void:
	visible = false
	get_tree().paused = false
	quit_game_requested.emit()
