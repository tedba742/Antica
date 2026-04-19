class_name Affixes
extends RefCounted

const POOL: Array = [
	{ "name": "Fire Damage",  "min": 5,  "max": 15 },
	{ "name": "Cold Damage",  "min": 3,  "max": 12 },
	{ "name": "Lightning Damage", "min": 1, "max": 20 },
	{ "name": "Strength",     "min": 1,  "max": 8 },
	{ "name": "Dexterity",    "min": 1,  "max": 8 },
	{ "name": "Armor",        "min": 5,  "max": 30 },
	{ "name": "Life",         "min": 10, "max": 50 },
]

static func roll(count: int) -> Array:
	var chosen: Array = []
	var pool: Array = POOL.duplicate()
	pool.shuffle()
	var n: int = min(count, pool.size())
	for i in range(n):
		var entry: Dictionary = pool[i]
		var value: int = randi_range(entry.min, entry.max)
		chosen.append({ "name": entry.name, "value": value })
	return chosen
