extends Node2D

signal interact_requested(role: String, npc: Node2D)

const LABEL_OFFSET := Vector2(0, -36)

var npc_name: String = "NPC"
var role: String = ""
var _label: Label

func setup(data: Dictionary) -> void:
	npc_name = data.get("name", "NPC")
	role = data.get("role", "")
	var tex: Texture2D = data.get("texture")
	var pos: Vector2 = data.get("position", Vector2.ZERO)
	var tint: Color = data.get("tint", Color.WHITE)
	position = pos
	add_to_group("npcs")

	if tex != null:
		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.scale = Vector2(2.0, 2.0)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.modulate = tint
		add_child(sprite)

	_label = Label.new()
	_label.text = npc_name
	_label.position = LABEL_OFFSET - Vector2(40, 0)
	_label.size = Vector2(80, 18)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
	_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_label)

func interact(_player: Node) -> void:
	interact_requested.emit(role, self)
