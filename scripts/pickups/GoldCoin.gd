extends Area2D
## Gold coin pickup - collected on contact with player, persists between runs.

var gold_value: int = 1
var attract_speed: float = 250.0
var is_attracted: bool = false
var player: CharacterBody2D


func _ready():
	collision_layer = 16
	collision_mask = 1
	add_to_group("gold_coins")
	# Visual
	var sprite = Sprite2D.new()
	sprite.texture = _get_gold_texture()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	# Collision
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	add_child(shape)
	# Bob animation
	var tween = create_tween().set_loops()
	tween.tween_property(self, "position:y", position.y - 4, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", position.y + 4, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _physics_process(delta):
	if not is_instance_valid(player):
		player = get_tree().current_scene.get_node_or_null("Player")
		return
	var dist = global_position.distance_to(player.global_position)
	if not is_attracted and dist <= player.pickup_range + 30.0:
		is_attracted = true
	if is_attracted:
		var direction = (player.global_position - global_position).normalized()
		position += direction * attract_speed * delta
		attract_speed += 300.0 * delta
		if global_position.distance_to(player.global_position) < 20.0:
			_collect()


func force_attract():
	is_attracted = true


func _collect():
	SaveData.add_gold(gold_value)
	GameState.gold_collected += gold_value
	_show_gold_text()
	queue_free()


func _show_gold_text():
	var label = Label.new()
	label.text = "+%d" % gold_value
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.global_position = global_position + Vector2(-10, -30)
	label.z_index = 100
	get_tree().current_scene.add_child(label)
	var tween = label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 30, 0.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)


func _get_gold_texture() -> Texture2D:
	var path = "res://assets/sprites/gold_coin.png"
	if ResourceLoader.exists(path):
		return load(path)
	# Fallback: generate a simple gold circle
	var img = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	var center = Vector2(6, 6)
	for x in range(12):
		for y in range(12):
			if Vector2(x, y).distance_to(center) <= 5:
				img.set_pixel(x, y, Color(1.0, 0.85, 0.0))
			elif Vector2(x, y).distance_to(center) <= 6:
				img.set_pixel(x, y, Color(0.7, 0.5, 0.0))
	return ImageTexture.create_from_image(img)
