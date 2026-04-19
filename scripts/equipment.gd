class_name Equipment
extends RefCounted

signal changed

const SLOT_KEYS: Array = ["helmet", "amulet", "armor", "weapon", "ring_left", "ring_right", "boots"]

const SLOT_TYPE := {
	"helmet":     Item.Slot.HELMET,
	"amulet":     Item.Slot.AMULET,
	"armor":      Item.Slot.ARMOR,
	"weapon":     Item.Slot.WEAPON,
	"ring_left":  Item.Slot.RING,
	"ring_right": Item.Slot.RING,
	"boots":      Item.Slot.BOOTS,
}

const SLOT_LABELS := {
	"helmet":     "Helmet",
	"amulet":     "Amulet",
	"armor":      "Armor",
	"weapon":     "Weapon",
	"ring_left":  "Ring",
	"ring_right": "Ring",
	"boots":      "Boots",
}

var slots: Dictionary = {}

func _init() -> void:
	for k in SLOT_KEYS:
		slots[k] = null

func can_equip(item: Item, slot_key: String) -> bool:
	return SLOT_TYPE.get(slot_key, -1) == item.slot

func equip(item: Item, slot_key: String) -> Item:
	if not can_equip(item, slot_key):
		return null
	var prev: Item = slots[slot_key]
	slots[slot_key] = item
	changed.emit()
	return prev

func unequip(slot_key: String) -> Item:
	if not slots.has(slot_key):
		return null
	var prev: Item = slots[slot_key]
	if prev != null:
		slots[slot_key] = null
		changed.emit()
	return prev

func to_dict() -> Dictionary:
	var out: Dictionary = {}
	for k in SLOT_KEYS:
		var it: Item = slots[k]
		out[k] = it.to_dict() if it != null else null
	return out

func load_dict(d: Dictionary) -> void:
	for k in SLOT_KEYS:
		var raw: Variant = d.get(k, null)
		if raw == null:
			slots[k] = null
		else:
			slots[k] = Item.from_dict(raw)
	changed.emit()

func first_free_slot_for(item: Item) -> String:
	for k in SLOT_KEYS:
		if SLOT_TYPE[k] == item.slot and slots[k] == null:
			return k
	for k in SLOT_KEYS:
		if SLOT_TYPE[k] == item.slot:
			return k
	return ""
