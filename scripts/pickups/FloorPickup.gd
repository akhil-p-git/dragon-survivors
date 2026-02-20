extends Area2D
## Floor pickups: chicken (heal), magnet (vacuum), rosary (kill all), hourglass (freeze)

var pickup_type: String = "chicken"  # chicken, magnet, rosary, hourglass
var is_collected: bool = false
var bob_offset: float = 0.0


func _ready():
	collision_layer = 16
	collision_mask = 1
	add_to_group("floor_pickups")
	body_entered.connect(_on_body_entered)
	_setup_visual()
	_setup_collision()
	bob_offset = randf() * TAU


func _process(delta):
	bob_offset += delta * 3.0
	position.y += sin(bob_offset) * 0.3


func _setup_visual():
	var sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var color: Color
	match pickup_type:
		"chicken": color = Color(0.9, 0.7, 0.3)
		"magnet": color = Color(0.8, 0.2, 0.2)
		"rosary": color = Color(1.0, 1.0, 0.8)
		"hourglass": color = Color(0.3, 0.7, 1.0)
		_: color = Color.WHITE
	# Try loading sprite, fallback to generated
	var path = "res://assets/sprites/pickup_%s.png" % pickup_type
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
	else:
		sprite.texture = _generate_pickup_texture(color)
	sprite.name = "Sprite"
	add_child(sprite)


func _setup_collision():
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 14.0
	shape.shape = circle
	add_child(shape)


func _on_body_entered(body):
	if is_collected:
		return
	if body.is_in_group("player"):
		is_collected = true
		_apply_effect(body)
		_show_pickup_text()
		queue_free()


func _apply_effect(player):
	match pickup_type:
		"chicken":
			var heal_amount = player.max_hp * 0.30
			player.heal(heal_amount)
		"magnet":
			# Vacuum all XP and gold on the map
			var orbs = get_tree().get_nodes_in_group("xp_orbs")
			for orb in orbs:
				if is_instance_valid(orb) and orb.has_method("force_attract"):
					orb.force_attract()
			var coins = get_tree().get_nodes_in_group("gold_coins")
			for coin in coins:
				if is_instance_valid(coin) and coin.has_method("force_attract"):
					coin.force_attract()
		"rosary":
			# Kill all enemies on screen
			var enemies = get_tree().get_nodes_in_group("enemies")
			for enemy in enemies:
				if is_instance_valid(enemy) and enemy.is_alive:
					enemy.take_damage(99999.0)
			# Screen flash
			ScreenEffects.shake(ScreenEffects.SHAKE_LARGE, 0.3)
		"hourglass":
			# Freeze all enemies for 5 seconds
			var enemies = get_tree().get_nodes_in_group("enemies")
			for enemy in enemies:
				if is_instance_valid(enemy):
					var original_speed = enemy.move_speed
					enemy.move_speed = 0.0
					enemy.modulate = Color(0.5, 0.7, 1.0, 0.8)
					get_tree().create_timer(5.0).timeout.connect(func():
						if is_instance_valid(enemy):
							enemy.move_speed = original_speed
							enemy.modulate = Color.WHITE
					)


func _show_pickup_text():
	var text: String
	var color: Color
	match pickup_type:
		"chicken":
			text = "HEAL!"
			color = Color.GREEN
		"magnet":
			text = "MAGNET!"
			color = Color.RED
		"rosary":
			text = "ROSARY!"
			color = Color.GOLD
		"hourglass":
			text = "FREEZE!"
			color = Color.LIGHT_BLUE
		_:
			text = "PICKUP!"
			color = Color.WHITE
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.global_position = global_position + Vector2(-30, -40)
	label.z_index = 100
	get_tree().current_scene.add_child(label)
	var tween = label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 50, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)


func _generate_pickup_texture(color: Color) -> Texture2D:
	var img = Image.create(14, 14, false, Image.FORMAT_RGBA8)
	var center = Vector2(7, 7)
	for x in range(14):
		for y in range(14):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= 5.0:
				img.set_pixel(x, y, color)
			elif dist <= 6.0:
				img.set_pixel(x, y, color.darkened(0.4))
			elif dist <= 7.0:
				img.set_pixel(x, y, Color.BLACK)
	return ImageTexture.create_from_image(img)
