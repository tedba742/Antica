extends Node

const SETTINGS_PATH := "user://settings.cfg"

const DEFAULT_BINDINGS := {
	"toggle_inventory":    KEY_I,
	"toggle_passive_tree": KEY_T,
	"toggle_options":      KEY_O,
	"toggle_quest_log":    KEY_L,
	"focus_chat":          KEY_ENTER,
	"skill_1": KEY_1,
	"skill_2": KEY_2,
	"skill_3": KEY_3,
	"skill_4": KEY_4,
}

const ACTION_LABELS := {
	"toggle_inventory":    "Toggle Inventory",
	"toggle_passive_tree": "Toggle Passive Tree",
	"toggle_options":      "Toggle Options",
	"toggle_quest_log":    "Toggle Quest Log",
	"focus_chat":          "Focus Chat",
	"skill_1": "Skill 1  ·  Basic Attack",
	"skill_2": "Skill 2  ·  Heavy Strike",
	"skill_3": "Skill 3  ·  Heal Potion",
	"skill_4": "Skill 4  ·  Fireball",
}

const ACTION_ORDER := [
	"skill_1", "skill_2", "skill_3", "skill_4",
	"toggle_inventory", "toggle_passive_tree", "toggle_quest_log",
	"focus_chat", "toggle_options",
]

var current_character_name: String = ""
var pending_save: Dictionary = {}

func _ready() -> void:
	_register_actions()

func _register_actions() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	for action in DEFAULT_BINDINGS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var keycode: int = int(cfg.get_value("bindings", action, DEFAULT_BINDINGS[action]))
		var ev := InputEventKey.new()
		ev.keycode = keycode
		InputMap.action_add_event(action, ev)

func rebind_action(action: String, keycode: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var ev := InputEventKey.new()
	ev.keycode = keycode
	InputMap.action_add_event(action, ev)
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("bindings", action, keycode)
	cfg.save(SETTINGS_PATH)

func reset_bindings() -> void:
	var cfg := ConfigFile.new()
	for action in DEFAULT_BINDINGS.keys():
		rebind_action(action, DEFAULT_BINDINGS[action])
	cfg.save(SETTINGS_PATH)

func current_keycode(action: String) -> int:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			return e.keycode
	return int(DEFAULT_BINDINGS.get(action, 0))

func action_label(action: String) -> String:
	return ACTION_LABELS.get(action, action)

func action_list() -> Array:
	return ACTION_ORDER
