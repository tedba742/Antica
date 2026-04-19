extends CanvasLayer

const PANEL_W := 640.0
const PANEL_H := 520.0
const PANEL_PAD := 18.0
const TITLE_H := 30.0
const LIST_W := 200.0

var player: Node
var quests: Quests

var _root: Panel
var _list: VBoxContainer
var _detail: RichTextLabel
var _selected_id: String = ""
var _row_buttons: Dictionary = {}

func _ready() -> void:
	layer = 18
	visible = false
	add_to_group("quest_log_panel")
	_build()
	get_viewport().size_changed.connect(_relayout)

func bind_player(p: Node) -> void:
	player = p
	quests = p.quests
	if quests != null:
		quests.changed.connect(_refresh)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_quest_log"):
		visible = not visible
		if visible:
			_refresh()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and visible:
		visible = false
		get_viewport().set_input_as_handled()

func _build() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.11, 0.97)
	bg.border_color = Color(0.55, 0.45, 0.25)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(6)

	_root = Panel.new()
	_root.add_theme_stylebox_override("panel", bg)
	_root.size = Vector2(PANEL_W, PANEL_H)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var title := Label.new()
	title.text = "Quest Log"
	title.position = Vector2(PANEL_PAD, 8)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35))
	title.add_theme_font_size_override("font_size", 20)
	_root.add_child(title)

	var sep := ColorRect.new()
	sep.color = Color(0.25, 0.22, 0.18)
	sep.position = Vector2(PANEL_PAD + LIST_W, PANEL_PAD + TITLE_H)
	sep.size = Vector2(1, PANEL_H - PANEL_PAD * 2 - TITLE_H)
	_root.add_child(sep)

	var list_scroll := ScrollContainer.new()
	list_scroll.position = Vector2(PANEL_PAD, PANEL_PAD + TITLE_H)
	list_scroll.size = Vector2(LIST_W - 8, PANEL_H - PANEL_PAD * 2 - TITLE_H)
	_root.add_child(list_scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	list_scroll.add_child(_list)

	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.fit_content = false
	_detail.scroll_active = true
	_detail.position = Vector2(PANEL_PAD + LIST_W + 16, PANEL_PAD + TITLE_H)
	_detail.size = Vector2(PANEL_W - PANEL_PAD * 2 - LIST_W - 16, PANEL_H - PANEL_PAD * 2 - TITLE_H)
	_root.add_child(_detail)

func _relayout() -> void:
	if _root == null:
		return
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_root.position = ((vp - _root.size) * 0.5).floor()

func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	_row_buttons.clear()
	if quests == null:
		_detail.text = ""
		return

	var active_ids: Array = quests.active_ids()
	var completed_ids: Array = quests.completed_ids()

	if not active_ids.is_empty():
		_list.add_child(_make_section_header("Active"))
		for id in active_ids:
			_list.add_child(_make_row(id, false))
	if not completed_ids.is_empty():
		_list.add_child(_make_section_header("Completed"))
		for id in completed_ids:
			_list.add_child(_make_row(id, true))
	if active_ids.is_empty() and completed_ids.is_empty():
		var empty := Label.new()
		empty.text = "(No quests yet.)"
		empty.add_theme_color_override("font_color", Color(0.55, 0.55, 0.58))
		_list.add_child(empty)

	if _selected_id.is_empty() or quests.status(_selected_id) == "":
		if not active_ids.is_empty():
			_selected_id = active_ids[0]
		elif not completed_ids.is_empty():
			_selected_id = completed_ids[0]
		else:
			_selected_id = ""
	_update_detail()
	_paint_row_selection()

func _make_section_header(text: String) -> Label:
	var l := Label.new()
	l.text = text.to_upper()
	l.add_theme_color_override("font_color", Color(0.70, 0.70, 0.74))
	l.add_theme_font_size_override("font_size", 12)
	return l

func _make_row(id: String, is_completed: bool) -> Button:
	var btn := Button.new()
	var def: Dictionary = Quests.definition(id)
	var prefix: String = "✓  " if is_completed else "•  "
	btn.text = prefix + String(def.get("name", id))
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 28)
	btn.flat = true
	if is_completed:
		btn.add_theme_color_override("font_color", Color(0.60, 0.80, 0.55))
	else:
		btn.add_theme_color_override("font_color", Color(0.95, 0.88, 0.55))
	btn.pressed.connect(_on_select.bind(id))
	_row_buttons[id] = btn
	return btn

func _paint_row_selection() -> void:
	for id in _row_buttons.keys():
		var btn: Button = _row_buttons[id]
		btn.flat = id != _selected_id

func _on_select(id: String) -> void:
	_selected_id = id
	_update_detail()
	_paint_row_selection()

func _update_detail() -> void:
	if _selected_id.is_empty():
		_detail.text = "[color=#888]Select a quest.[/color]"
		return
	var def: Dictionary = Quests.definition(_selected_id)
	var lines: Array = []
	var status_text: String = "Completed" if quests.is_completed(_selected_id) else "Active"
	var status_color: String = "#9fd596" if quests.is_completed(_selected_id) else "#f0c64a"
	lines.append("[color=#f0c64a][b]%s[/b][/color]" % String(def.get("name", _selected_id)))
	lines.append("[color=#8a8a8a]%s[/color]" % String(def.get("giver", "")))
	lines.append("")
	lines.append(String(def.get("description", "")))
	lines.append("")
	lines.append("[color=#c8c8c8][b]Objective[/b][/color]")
	lines.append(String(def.get("objective", "")))
	lines.append("")
	lines.append("[color=#c8c8c8][b]Reward[/b][/color]")
	lines.append(String(def.get("reward_text", "—")))
	lines.append("")
	lines.append("[color=%s]Status: %s[/color]" % [status_color, status_text])
	_detail.text = "\n".join(lines)
