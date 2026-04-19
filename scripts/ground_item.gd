extends Node2D

const GLOW_RADIUS := 14.0
const ICON_SCALE := 1.5
const LABEL_WIDTH := 110.0
const LABEL_OFFSET_Y := -28.0

var item: Item

func _ready() -> void:
	add_to_group("ground_items")
	z_index = -1

func setup(it: Item) -> void:
	item = it

	var glow := Polygon2D.new()
	var pts: PackedVector2Array = []
	var segments := 20
	for i in range(segments):
		var a := TAU * i / segments
		pts.append(Vector2(cos(a), sin(a)) * GLOW_RADIUS)
	glow.polygon = pts
	var glow_color := Item.rarity_color(it.rarity)
	glow_color.a = 0.35
	glow.color = glow_color
	add_child(glow)

	var sprite := Sprite2D.new()
	sprite.texture = it.icon
	sprite.scale = Vector2(ICON_SCALE, ICON_SCALE)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.modulate = Item.rarity_color(it.rarity)
	add_child(sprite)

	var label := Label.new()
	label.text = "%s %s" % [Item.rarity_name(it.rarity), it.base_name]
	label.size = Vector2(LABEL_WIDTH, 14)
	label.position = Vector2(-LABEL_WIDTH * 0.5, LABEL_OFFSET_Y)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Item.rarity_color(it.rarity))
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
