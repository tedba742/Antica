extends CanvasLayer

const BAR_WIDTH := 240.0
const HP_BAR_HEIGHT := 14.0
const XP_BAR_HEIGHT := 8.0
const LABEL_HEIGHT := 16.0
const ROW_GAP := 4.0
const PAD := 6.0

var player: Node

var _hp_fill: ColorRect
var _xp_fill: ColorRect
var _hp_label: Label
var _xp_label: Label

func _ready() -> void:
	layer = 10

	var row1_y: float = PAD + LABEL_HEIGHT
	var row2_label_y: float = row1_y + HP_BAR_HEIGHT + ROW_GAP
	var row2_bar_y: float = row2_label_y + LABEL_HEIGHT
	var panel_h: float = row2_bar_y + XP_BAR_HEIGHT + PAD
	var panel_w: float = BAR_WIDTH + PAD * 2

	var panel := ColorRect.new()
	panel.position = Vector2(16, 16)
	panel.size = Vector2(panel_w, panel_h)
	panel.color = Color(0, 0, 0, 0.7)
	add_child(panel)

	_hp_label = _make_label(Vector2(16 + PAD, 16 + PAD - 2), Color.WHITE)
	_hp_label.text = "HP"
	add_child(_hp_label)

	_hp_fill = ColorRect.new()
	_hp_fill.position = Vector2(16 + PAD, 16 + row1_y)
	_hp_fill.size = Vector2(BAR_WIDTH, HP_BAR_HEIGHT)
	_hp_fill.color = Color(0.85, 0.2, 0.2)
	add_child(_hp_fill)

	_xp_label = _make_label(Vector2(16 + PAD, 16 + row2_label_y - 2), Color(0.98, 0.85, 0.35))
	_xp_label.text = "XP"
	add_child(_xp_label)

	_xp_fill = ColorRect.new()
	_xp_fill.position = Vector2(16 + PAD, 16 + row2_bar_y)
	_xp_fill.size = Vector2(0.0, XP_BAR_HEIGHT)
	_xp_fill.color = Color(0.95, 0.78, 0.25)
	add_child(_xp_fill)

func _make_label(pos: Vector2, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color.BLACK)
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	return l

func bind_player(p: Node) -> void:
	player = p

func _process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var hp: int = player.hp
	var max_hp: int = player.max_hp
	if max_hp <= 0:
		return
	var hp_pct: float = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	_hp_fill.size.x = BAR_WIDTH * hp_pct
	_hp_label.text = "HP  %d / %d" % [hp, max_hp]

	var level: int = player.level
	var xp: int = player.xp
	var need: int = player.xp_to_next_level()
	var xp_pct: float = clampf(float(xp) / float(max(1, need)), 0.0, 1.0)
	_xp_fill.size.x = BAR_WIDTH * xp_pct
	_xp_label.text = "Lv %d   XP %d / %d" % [level, xp, need]
