class_name SaveGame
extends RefCounted

const SAVE_DIR := "user://saves"

static func _ensure_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

static func _safe_name(name: String) -> String:
	var regex := RegEx.new()
	regex.compile("[^A-Za-z0-9_-]")
	var cleaned := regex.sub(name, "_", true).to_lower()
	if cleaned.is_empty():
		cleaned = "character"
	return cleaned

static func path_for(name: String) -> String:
	return "%s/%s.json" % [SAVE_DIR, _safe_name(name)]

static func snapshot_exists(name: String) -> bool:
	return FileAccess.file_exists(path_for(name))

static func write_snapshot(snapshot: Dictionary) -> bool:
	_ensure_dir()
	var name: String = snapshot.get("name", "")
	if name.is_empty():
		return false
	var f := FileAccess.open(path_for(name), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(snapshot, "\t"))
	return true

static func read_snapshot(name: String) -> Dictionary:
	var path := path_for(name)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

static func delete_snapshot(name: String) -> void:
	var path := path_for(name)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

static func list_snapshots() -> Array:
	_ensure_dir()
	var out: Array = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return out
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.ends_with(".json"):
			var f := FileAccess.open("%s/%s" % [SAVE_DIR, entry], FileAccess.READ)
			if f != null:
				var parsed: Variant = JSON.parse_string(f.get_as_text())
				if typeof(parsed) == TYPE_DICTIONARY:
					out.append(parsed)
		entry = dir.get_next()
	out.sort_custom(func(a, b): return int(a.get("updated_at", 0)) > int(b.get("updated_at", 0)))
	return out
