extends Node2D

const PANEL_W := 560.0
const PANEL_H := 560.0
const PANEL_PAD := 18.0
const ROW_H := 44.0

var _root: Panel
var _list: VBoxContainer
var _name_edit: LineEdit
var _new_btn: Button
var _error_label: Label

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.08)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var layer := CanvasLayer.new()
	add_child(layer)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.09, 0.10, 0.13, 0.98)
	bg_style.border_color = Color(0.55, 0.45, 0.25)
	bg_style.set_border_width_all(2)
	bg_style.set_corner_radius_all(6)

	_root = Panel.new()
	_root.add_theme_stylebox_override("panel", bg_style)
	_root.size = Vector2(PANEL_W, PANEL_H)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(_root)

	var title := Label.new()
	title.text = "ANTICA"
	title.position = Vector2(PANEL_PAD, 10)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35))
	title.add_theme_font_size_override("font_size", 28)
	_root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose a character"
	subtitle.position = Vector2(PANEL_PAD, 48)
	subtitle.add_theme_color_override("font_color", Color(0.75, 0.75, 0.78))
	_root.add_child(subtitle)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(PANEL_PAD, 78)
	scroll.size = Vector2(PANEL_W - PANEL_PAD * 2, 340)
	_root.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)

	var sep := ColorRect.new()
	sep.color = Color(0.25, 0.22, 0.18)
	sep.position = Vector2(PANEL_PAD, 432)
	sep.size = Vector2(PANEL_W - PANEL_PAD * 2, 1)
	_root.add_child(sep)

	var new_label := Label.new()
	new_label.text = "New character"
	new_label.position = Vector2(PANEL_PAD, 444)
	new_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.88))
	_root.add_child(new_label)

	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Name"
	_name_edit.position = Vector2(PANEL_PAD, 470)
	_name_edit.size = Vector2(340, 32)
	_name_edit.max_length = 24
	_name_edit.text_submitted.connect(_on_name_submitted)
	_root.add_child(_name_edit)

	_new_btn = Button.new()
	_new_btn.text = "Create"
	_new_btn.position = Vector2(PANEL_PAD + 352, 470)
	_new_btn.size = Vector2(96, 32)
	_new_btn.pressed.connect(_on_create_pressed)
	_root.add_child(_new_btn)

	_error_label = Label.new()
	_error_label.position = Vector2(PANEL_PAD, 510)
	_error_label.add_theme_color_override("font_color", Color(0.95, 0.45, 0.40))
	_root.add_child(_error_label)

	var quit_btn := Button.new()
	quit_btn.text = "Quit"
	quit_btn.position = Vector2(PANEL_W - PANEL_PAD - 72, 510)
	quit_btn.size = Vector2(72, 28)
	quit_btn.pressed.connect(func(): get_tree().quit())
	_root.add_child(quit_btn)

	get_viewport().size_changed.connect(_relayout)
	_relayout()
	_refresh()

func _relayout() -> void:
	var vp := get_viewport().get_visible_rect().size
	_root.position = ((vp - _root.size) * 0.5).floor()

func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	var saves: Array = SaveGame.list_snapshots()
	if saves.is_empty():
		var empty := Label.new()
		empty.text = "(No saved characters yet.)"
		empty.add_theme_color_override("font_color", Color(0.55, 0.55, 0.58))
		_list.add_child(empty)
		return
	for snap in saves:
		_list.add_child(_make_row(snap))

func _make_row(snap: Dictionary) -> Control:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.14, 0.17, 0.95)
	style.border_color = Color(0.35, 0.32, 0.28)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)

	var row := Panel.new()
	row.add_theme_stylebox_override("panel", style)
	row.custom_minimum_size = Vector2(0, ROW_H)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name := Label.new()
	name.text = snap.get("name", "?")
	name.position = Vector2(12, 6)
	name.add_theme_color_override("font_color", Color(0.95, 0.90, 0.75))
	name.add_theme_font_size_override("font_size", 18)
	row.add_child(name)

	var meta := Label.new()
	meta.text = "Lv %d  ·  %d xp  ·  %d g  ·  %s" % [
		int(snap.get("level", 1)),
		int(snap.get("xp", 0)),
		int(snap.get("gold", 0)),
		snap.get("zone_id", "starter"),
	]
	meta.position = Vector2(12, 24)
	meta.add_theme_color_override("font_color", Color(0.70, 0.70, 0.72))
	row.add_child(meta)

	var load_btn := Button.new()
	load_btn.text = "Load"
	load_btn.position = Vector2(row.custom_minimum_size.x, 0)
	load_btn.size = Vector2(72, ROW_H)
	load_btn.anchor_left = 1.0
	load_btn.anchor_right = 1.0
	load_btn.offset_left = -160
	load_btn.offset_right = -88
	load_btn.offset_bottom = ROW_H
	load_btn.pressed.connect(_on_load_pressed.bind(snap.get("name", "")))
	row.add_child(load_btn)

	var del_btn := Button.new()
	del_btn.text = "Delete"
	del_btn.anchor_left = 1.0
	del_btn.anchor_right = 1.0
	del_btn.offset_left = -80
	del_btn.offset_right = -8
	del_btn.offset_top = 0
	del_btn.offset_bottom = ROW_H
	del_btn.add_theme_color_override("font_color", Color(0.95, 0.55, 0.50))
	del_btn.pressed.connect(_on_delete_pressed.bind(snap.get("name", "")))
	row.add_child(del_btn)

	return row

func _on_load_pressed(name: String) -> void:
	if name.is_empty():
		return
	var snap: Dictionary = SaveGame.read_snapshot(name)
	if snap.is_empty():
		_error_label.text = "Could not read save."
		return
	GameState.current_character_name = name
	GameState.pending_save = snap
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_delete_pressed(name: String) -> void:
	if name.is_empty():
		return
	SaveGame.delete_snapshot(name)
	_refresh()

func _on_name_submitted(_text: String) -> void:
	_on_create_pressed()

func _on_create_pressed() -> void:
	var chosen: String = _name_edit.text.strip_edges()
	if chosen.is_empty():
		_error_label.text = "Enter a name."
		return
	if SaveGame.snapshot_exists(chosen):
		_error_label.text = "Name already in use."
		return
	GameState.current_character_name = chosen
	GameState.pending_save = {}
	get_tree().change_scene_to_file("res://scenes/main.tscn")
