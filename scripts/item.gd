class_name Item
extends RefCounted

enum Rarity { COMMON, RARE, ARTIFACT }
enum Slot { WEAPON, ARMOR, HELMET, BOOTS, RING, AMULET }

const RARITY_NAMES := ["Common", "Rare", "Artifact"]
const RARITY_COLORS := [
	Color(0.85, 0.85, 0.85),
	Color(1.00, 0.90, 0.20),
	Color(1.00, 0.45, 0.15),
]

const SLOT_NAMES := {
	Slot.WEAPON: "Weapon",
	Slot.ARMOR:  "Armor",
	Slot.HELMET: "Helmet",
	Slot.BOOTS:  "Boots",
	Slot.RING:   "Ring",
	Slot.AMULET: "Amulet",
}

const BASES: Array = [
	{ "name": "Sword",     "slot": Slot.WEAPON, "icon": "res://assets/kenney_tiny-dungeon/Tiles/tile_0116.png" },
	{ "name": "Battleaxe", "slot": Slot.WEAPON, "icon": "res://assets/kenney_tiny-dungeon/Tiles/tile_0117.png" },
	{ "name": "Bow",       "slot": Slot.WEAPON, "icon": "res://assets/kenney_tiny-dungeon/Tiles/tile_0118.png" },
	{ "name": "Staff",     "slot": Slot.WEAPON, "icon": "res://assets/kenney_tiny-dungeon/Tiles/tile_0119.png" },
	{ "name": "Helm",      "slot": Slot.HELMET, "icon": "res://assets/kenney_tiny-dungeon/Tiles/tile_0123.png" },
	{ "name": "Plate",     "slot": Slot.ARMOR,  "icon": "res://assets/kenney_tiny-dungeon/Tiles/tile_0100.png" },
	{ "name": "Boots",     "slot": Slot.BOOTS,  "icon": "res://assets/kenney_tiny-dungeon/Tiles/tile_0130.png" },
	{ "name": "Ring",      "slot": Slot.RING,   "icon": "res://assets/kenney_tiny-dungeon/Tiles/tile_0125.png" },
	{ "name": "Amulet",    "slot": Slot.AMULET, "icon": "res://assets/kenney_tiny-dungeon/Tiles/tile_0129.png" },
]

var id: String
var base_name: String
var rarity: int
var stats: Array  # [{ name: String, value: int }]
var icon: Texture2D
var slot: int

static func rarity_color(r: int) -> Color:
	return RARITY_COLORS[clampi(r, 0, RARITY_COLORS.size() - 1)]

static func rarity_name(r: int) -> String:
	return RARITY_NAMES[clampi(r, 0, RARITY_NAMES.size() - 1)]

static func slot_name(s: int) -> String:
	return SLOT_NAMES.get(s, "?")

static func roll_drop() -> Item:
	var it := Item.new()
	it.id = "itm_%08x" % randi()
	var base: Dictionary = BASES[randi() % BASES.size()]
	it.base_name = base["name"]
	it.slot = base["slot"]
	it.icon = load(base["icon"])
	var r := randf()
	if r < 0.05:
		it.rarity = Rarity.ARTIFACT
		it.stats = Affixes.roll(4)
	elif r < 0.30:
		it.rarity = Rarity.RARE
		it.stats = Affixes.roll(3)
	else:
		it.rarity = Rarity.COMMON
		it.stats = Affixes.roll(1)
	return it

static func roll_rare() -> Item:
	var it := Item.new()
	it.id = "itm_%08x" % randi()
	var base: Dictionary = BASES[randi() % BASES.size()]
	it.base_name = base["name"]
	it.slot = base["slot"]
	it.icon = load(base["icon"])
	it.rarity = Rarity.RARE
	it.stats = Affixes.roll(3)
	return it

func sell_value() -> int:
	var base: int = [5, 30, 120][clampi(rarity, 0, 2)]
	var per_affix: int = [3, 12, 30][clampi(rarity, 0, 2)]
	return base + stats.size() * per_affix

func describe() -> String:
	var lines: Array = ["%s %s (%s)" % [RARITY_NAMES[rarity], base_name, id]]
	for s in stats:
		lines.append("  +%d %s" % [s.value, s.name])
	return "\n".join(lines)

func to_dict() -> Dictionary:
	return {
		"id":        id,
		"base_name": base_name,
		"rarity":    rarity,
		"slot":      slot,
		"stats":     stats.duplicate(true),
		"icon_path": icon.resource_path if icon != null else "",
	}

static func from_dict(d: Dictionary) -> Item:
	var it := Item.new()
	it.id = d.get("id", "itm_0")
	it.base_name = d.get("base_name", "")
	it.rarity = int(d.get("rarity", 0))
	it.slot = int(d.get("slot", Slot.WEAPON))
	it.stats = (d.get("stats", []) as Array).duplicate(true)
	var icon_path: String = d.get("icon_path", "")
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		it.icon = load(icon_path)
	return it

func to_tooltip_bbcode() -> String:
	var hex: String = Item.rarity_color(rarity).to_html(false)
	var lines: Array = []
	lines.append("[color=#%s][b]%s %s[/b][/color]" % [hex, Item.rarity_name(rarity), base_name])
	lines.append("[color=#8a8a8a]%s[/color]" % Item.slot_name(slot))
	for s in stats:
		lines.append("[color=#9fd596]+%d %s[/color]" % [s.value, s.name])
	lines.append("[color=#c8a24a]Value: %d g[/color]" % sell_value())
	return "\n".join(lines)
