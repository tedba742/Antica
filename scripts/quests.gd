class_name Quests
extends RefCounted

signal changed

const STATE_ACTIVE := "active"
const STATE_COMPLETED := "completed"

const DEFINITIONS: Dictionary = {
	"kill_grom": {
		"name":        "The Warlord Blocks the Way",
		"giver":       "The road to Camp",
		"description": "A brute named Warlord Grom has seized the pass through the Wilderness and now bars the only road to Camp. None who travel east pass unscathed — the way cannot open until he has fallen.",
		"objective":   "Defeat Warlord Grom in the Wilderness.",
		"reward_text": "Access to Camp  ·  5 Rare items",
	},
}

var states: Dictionary = {}

func accept(id: String) -> bool:
	if not DEFINITIONS.has(id):
		return false
	if states.get(id, "") != "":
		return false
	states[id] = STATE_ACTIVE
	changed.emit()
	return true

func complete(id: String) -> bool:
	if states.get(id, "") != STATE_ACTIVE:
		return false
	states[id] = STATE_COMPLETED
	changed.emit()
	return true

func is_active(id: String) -> bool:
	return states.get(id, "") == STATE_ACTIVE

func is_completed(id: String) -> bool:
	return states.get(id, "") == STATE_COMPLETED

func status(id: String) -> String:
	return states.get(id, "")

func active_ids() -> Array:
	var out: Array = []
	for id in states.keys():
		if states[id] == STATE_ACTIVE:
			out.append(id)
	return out

func completed_ids() -> Array:
	var out: Array = []
	for id in states.keys():
		if states[id] == STATE_COMPLETED:
			out.append(id)
	return out

static func definition(id: String) -> Dictionary:
	return DEFINITIONS.get(id, {})

func to_dict() -> Dictionary:
	return { "states": states.duplicate(true) }

func load_dict(d: Dictionary) -> void:
	states.clear()
	for id in d.get("states", {}).keys():
		states[id] = d["states"][id]
	changed.emit()
