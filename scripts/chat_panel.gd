extends CanvasLayer

signal message_sent(text: String, channel: String)

const CHAT_W := 440.0
const LOG_H := 180.0
const INPUT_H := 28.0
const MARGIN := 14.0
const MAX_MESSAGES := 120

const CHANNEL_COLORS := {
	"local":  Color(0.70, 0.95, 0.78),
	"global": Color(0.85, 0.88, 0.95),
	"emote":  Color(0.80, 0.70, 0.95),
	"system": Color(0.95, 0.82, 0.35),
}

var _root: Control
var _log: RichTextLabel
var _input: LineEdit
var _input_bg: Panel
var _messages: Array = []

func _ready() -> void:
	layer = 12
	_build()
	get_viewport().size_changed.connect(_relayout)
	post_system("Welcome to Antica.")
	post_system("Press Enter to chat.  /me  ·  /g  ·  /s")

func post_system(text: String) -> void:
	post("", text, "system")

func post(sender: String, text: String, channel: String = "local") -> void:
	var ts: String = Time.get_time_string_from_system().substr(0, 5)
	_messages.append(_format_line(ts, sender, text, channel))
	if _messages.size() > MAX_MESSAGES:
		_messages.pop_front()
	_refresh_log()

func _format_line(ts: String, sender: String, text: String, channel: String) -> String:
	var color: Color = CHANNEL_COLORS.get(channel, Color.WHITE)
	var hex: String = color.to_html(false)
	if sender.is_empty():
		return "[color=#808080]%s[/color]  [color=#%s]%s[/color]" % [ts, hex, text]
	return "[color=#808080]%s[/color]  [color=#%s][b]%s[/b]: %s[/color]" % [ts, hex, sender, text]

func _refresh_log() -> void:
	_log.text = "\n".join(_messages)
	await get_tree().process_frame
	if is_instance_valid(_log):
		_log.scroll_to_line(max(0, _log.get_line_count() - 1))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("focus_chat") and not _input.has_focus():
		_focus_input()
		get_viewport().set_input_as_handled()
	elif _input.has_focus() and event.is_action_pressed("ui_cancel"):
		_cancel_input()
		get_viewport().set_input_as_handled()

func _focus_input() -> void:
	_input_bg.visible = true
	_input.visible = true
	_input.grab_focus()

func _cancel_input() -> void:
	_input.text = ""
	_input.release_focus()
	_input_bg.visible = false
	_input.visible = false

func _on_submitted(text: String) -> void:
	_input.text = ""
	_input.release_focus()
	_input_bg.visible = false
	_input.visible = false
	_handle_submit(text)

func _handle_submit(raw: String) -> void:
	var t: String = raw.strip_edges()
	if t.is_empty():
		return
	var channel: String = "local"
	var body: String = t
	if t.begins_with("/me "):
		channel = "emote"
		body = t.substr(4)
	elif t.begins_with("/g "):
		channel = "global"
		body = t.substr(3)
	elif t.begins_with("/s "):
		channel = "system"
		body = t.substr(3)
	var sender: String = GameState.current_character_name
	if sender.is_empty():
		sender = "Player"
	# Local echo — in multiplayer this path would be driven by server broadcasts.
	if channel == "emote":
		post("", "* %s %s" % [sender, body], channel)
	else:
		post(sender, body, channel)
	message_sent.emit(body, channel)

func _build() -> void:
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.anchor_right = 1.0
	_root.anchor_bottom = 1.0
	add_child(_root)

	var log_bg := Panel.new()
	var log_style := StyleBoxFlat.new()
	log_style.bg_color = Color(0.04, 0.05, 0.07, 0.55)
	log_style.border_color = Color(0.22, 0.22, 0.28, 0.6)
	log_style.set_border_width_all(1)
	log_style.set_corner_radius_all(4)
	log_bg.add_theme_stylebox_override("panel", log_style)
	log_bg.size = Vector2(CHAT_W, LOG_H)
	log_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(log_bg)

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.fit_content = false
	_log.scroll_active = true
	_log.scroll_following = true
	_log.position = Vector2(8, 6)
	_log.size = Vector2(CHAT_W - 16, LOG_H - 12)
	_log.mouse_filter = Control.MOUSE_FILTER_PASS
	log_bg.add_child(_log)

	_input_bg = Panel.new()
	var in_style := StyleBoxFlat.new()
	in_style.bg_color = Color(0.08, 0.09, 0.12, 0.95)
	in_style.border_color = Color(0.55, 0.45, 0.25)
	in_style.set_border_width_all(1)
	in_style.set_corner_radius_all(4)
	_input_bg.add_theme_stylebox_override("panel", in_style)
	_input_bg.size = Vector2(CHAT_W, INPUT_H)
	_input_bg.visible = false
	_input_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_input_bg)

	_input = LineEdit.new()
	_input.placeholder_text = "Say something…"
	_input.position = Vector2(6, 2)
	_input.size = Vector2(CHAT_W - 12, INPUT_H - 4)
	_input.max_length = 240
	_input.visible = false
	_input.text_submitted.connect(_on_submitted)
	_input_bg.add_child(_input)

	_relayout()

func _relayout() -> void:
	if _root == null:
		return
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var log_bg: Control = _log.get_parent() as Control
	log_bg.position = Vector2(MARGIN, vp.y - MARGIN - INPUT_H - 4 - LOG_H)
	_input_bg.position = Vector2(MARGIN, vp.y - MARGIN - INPUT_H)
