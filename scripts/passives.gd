class_name Passives
extends RefCounted

signal changed

const STARTING_POINTS := 3

var allocated: Dictionary = {}
var unspent_points: int = STARTING_POINTS

func _init() -> void:
	allocated[PassiveTree.START_NODE] = true

func has(node_id: String) -> bool:
	return allocated.has(node_id)

func can_allocate(node_id: String) -> bool:
	if allocated.has(node_id):
		return false
	if unspent_points <= 0:
		return false
	if not PassiveTree.NODES.has(node_id):
		return false
	for neighbor in PassiveTree.adjacent(node_id):
		if allocated.has(neighbor):
			return true
	return false

func allocate(node_id: String) -> bool:
	if not can_allocate(node_id):
		return false
	allocated[node_id] = true
	unspent_points -= 1
	changed.emit()
	return true

func grant_points(n: int) -> void:
	if n <= 0:
		return
	unspent_points += n
	changed.emit()

func flat_stat(stat_name: String) -> int:
	var total: int = 0
	for nid in allocated.keys():
		var node: Dictionary = PassiveTree.NODES[nid]
		for eff in node.get("effects", []):
			if eff.get("kind") == "flat" and eff.get("stat") == stat_name:
				total += int(eff.get("value", 0))
	return total

func to_dict() -> Dictionary:
	return {
		"allocated":      allocated.keys(),
		"unspent_points": unspent_points,
	}

func load_dict(d: Dictionary) -> void:
	allocated.clear()
	for nid in d.get("allocated", []):
		if PassiveTree.NODES.has(nid):
			allocated[nid] = true
	allocated[PassiveTree.START_NODE] = true
	unspent_points = int(d.get("unspent_points", STARTING_POINTS))
	changed.emit()

func increased(tag: String) -> float:
	var total: float = 0.0
	for nid in allocated.keys():
		var node: Dictionary = PassiveTree.NODES[nid]
		for eff in node.get("effects", []):
			if eff.get("kind") == "increased" and eff.get("tag") == tag:
				total += float(eff.get("value", 0))
	return total
