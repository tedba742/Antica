class_name PassiveTree

const START_NODE := "root"

const NODES := {
	"root": {
		"name": "Start",
		"kind": "root",
		"pos": Vector2(320, 320),
		"effects": [],
	},

	"str_s1": { "name": "+8 Strength",  "kind": "small", "pos": Vector2(320, 268),
		"effects": [{ "kind": "flat", "stat": "Strength", "value": 8 }] },
	"str_s2": { "name": "+8 Strength",  "kind": "small", "pos": Vector2(320, 216),
		"effects": [{ "kind": "flat", "stat": "Strength", "value": 8 }] },
	"phys_s": { "name": "+10% Physical Damage", "kind": "small", "pos": Vector2(320, 164),
		"effects": [{ "kind": "increased", "tag": "physical", "value": 10 }] },
	"phys_e": { "name": "+10% Physical Damage", "kind": "small", "pos": Vector2(370, 114),
		"effects": [{ "kind": "increased", "tag": "physical", "value": 10 }] },
	"phys_n": { "name": "+10% Physical Damage", "kind": "small", "pos": Vector2(320, 64),
		"effects": [{ "kind": "increased", "tag": "physical", "value": 10 }] },
	"phys_w": { "name": "+10% Physical Damage", "kind": "small", "pos": Vector2(270, 114),
		"effects": [{ "kind": "increased", "tag": "physical", "value": 10 }] },
	"phys_hub": { "name": "Brute Force", "kind": "notable", "pos": Vector2(320, 114),
		"effects": [
			{ "kind": "increased", "tag": "physical", "value": 25 },
			{ "kind": "flat", "stat": "Strength", "value": 10 },
		] },

	"dex_s1": { "name": "+8 Dexterity", "kind": "small", "pos": Vector2(372, 320),
		"effects": [{ "kind": "flat", "stat": "Dexterity", "value": 8 }] },
	"dex_s2": { "name": "+8 Dexterity", "kind": "small", "pos": Vector2(424, 320),
		"effects": [{ "kind": "flat", "stat": "Dexterity", "value": 8 }] },
	"ms_w":   { "name": "+5% Movement Speed", "kind": "small", "pos": Vector2(476, 320),
		"effects": [{ "kind": "increased", "tag": "move_speed", "value": 5 }] },
	"ms_n":   { "name": "+5% Movement Speed", "kind": "small", "pos": Vector2(526, 270),
		"effects": [{ "kind": "increased", "tag": "move_speed", "value": 5 }] },
	"ms_e":   { "name": "+5% Movement Speed", "kind": "small", "pos": Vector2(576, 320),
		"effects": [{ "kind": "increased", "tag": "move_speed", "value": 5 }] },
	"ms_s":   { "name": "+5% Movement Speed", "kind": "small", "pos": Vector2(526, 370),
		"effects": [{ "kind": "increased", "tag": "move_speed", "value": 5 }] },
	"ms_hub": { "name": "Fleet Footed", "kind": "notable", "pos": Vector2(526, 320),
		"effects": [
			{ "kind": "increased", "tag": "move_speed", "value": 12 },
			{ "kind": "flat", "stat": "Dexterity", "value": 10 },
		] },

	"int_s1":  { "name": "+8 Intelligence", "kind": "small", "pos": Vector2(320, 372),
		"effects": [{ "kind": "flat", "stat": "Intelligence", "value": 8 }] },
	"int_s2":  { "name": "+8 Intelligence", "kind": "small", "pos": Vector2(320, 424),
		"effects": [{ "kind": "flat", "stat": "Intelligence", "value": 8 }] },
	"fire_n":  { "name": "+8% Fire Damage", "kind": "small", "pos": Vector2(320, 476),
		"effects": [{ "kind": "increased", "tag": "fire", "value": 8 }] },
	"fire_e":  { "name": "+8% Fire Damage", "kind": "small", "pos": Vector2(370, 526),
		"effects": [{ "kind": "increased", "tag": "fire", "value": 8 }] },
	"fire_s":  { "name": "+8% Fire Damage", "kind": "small", "pos": Vector2(320, 576),
		"effects": [{ "kind": "increased", "tag": "fire", "value": 8 }] },
	"fire_w":  { "name": "+8% Fire Damage", "kind": "small", "pos": Vector2(270, 526),
		"effects": [{ "kind": "increased", "tag": "fire", "value": 8 }] },
	"fire_hub":{ "name": "Pyromancer", "kind": "notable", "pos": Vector2(320, 526),
		"effects": [
			{ "kind": "increased", "tag": "fire", "value": 25 },
			{ "kind": "flat", "stat": "Intelligence", "value": 10 },
		] },
}

const CONNECTIONS: Array = [
	["root", "str_s1"], ["str_s1", "str_s2"], ["str_s2", "phys_s"],
	["phys_s", "phys_e"], ["phys_e", "phys_n"], ["phys_n", "phys_w"], ["phys_w", "phys_s"],
	["phys_hub", "phys_s"], ["phys_hub", "phys_e"], ["phys_hub", "phys_n"], ["phys_hub", "phys_w"],

	["root", "dex_s1"], ["dex_s1", "dex_s2"], ["dex_s2", "ms_w"],
	["ms_w", "ms_n"], ["ms_n", "ms_e"], ["ms_e", "ms_s"], ["ms_s", "ms_w"],
	["ms_hub", "ms_w"], ["ms_hub", "ms_n"], ["ms_hub", "ms_e"], ["ms_hub", "ms_s"],

	["root", "int_s1"], ["int_s1", "int_s2"], ["int_s2", "fire_n"],
	["fire_n", "fire_e"], ["fire_e", "fire_s"], ["fire_s", "fire_w"], ["fire_w", "fire_n"],
	["fire_hub", "fire_n"], ["fire_hub", "fire_e"], ["fire_hub", "fire_s"], ["fire_hub", "fire_w"],
]

static func adjacent(node_id: String) -> Array:
	var result: Array = []
	for pair in CONNECTIONS:
		if pair[0] == node_id:
			result.append(pair[1])
		elif pair[1] == node_id:
			result.append(pair[0])
	return result

static func node_description(node_id: String) -> String:
	var node: Dictionary = NODES.get(node_id, {})
	var lines: Array = []
	var kind: String = node.get("kind", "small")
	var color_hex := "eaeaea"
	if kind == "notable":
		color_hex = "ff9a2a"
	elif kind == "root":
		color_hex = "6ac6ff"
	lines.append("[color=#%s][b]%s[/b][/color]" % [color_hex, node.get("name", "?")])
	for eff in node.get("effects", []):
		var kd: String = eff.get("kind", "")
		if kd == "flat":
			lines.append("[color=#9fd596]+%d %s[/color]" % [int(eff["value"]), eff["stat"]])
		elif kd == "increased":
			lines.append("[color=#9fd596]%d%% increased %s[/color]" % [int(eff["value"]), _tag_label(eff["tag"])])
	return "\n".join(lines)

static func _tag_label(tag: String) -> String:
	match tag:
		"physical":   return "Physical Damage"
		"fire":       return "Fire Damage"
		"cold":       return "Cold Damage"
		"lightning":  return "Lightning Damage"
		"move_speed": return "Movement Speed"
		_:            return tag
