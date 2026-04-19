class_name Inventory
extends RefCounted

signal changed

const CAPACITY := 32

var items: Array = []  # Array[Item]

func add(item: Item) -> bool:
	if items.size() >= CAPACITY:
		return false
	items.append(item)
	changed.emit()
	return true

func remove_at(index: int) -> Item:
	if index < 0 or index >= items.size():
		return null
	var it: Item = items[index]
	items.remove_at(index)
	changed.emit()
	return it

func size() -> int:
	return items.size()

func to_dict() -> Dictionary:
	var arr: Array = []
	for it in items:
		arr.append(it.to_dict())
	return { "items": arr }

func load_dict(d: Dictionary) -> void:
	items.clear()
	for raw in d.get("items", []):
		items.append(Item.from_dict(raw))
	changed.emit()
