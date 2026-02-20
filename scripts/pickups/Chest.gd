extends Area2D

var is_opened: bool = false


func _ready():
	collision_layer = 16  # Pickups
	collision_mask = 1    # Player
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if is_opened:
		return
	if body.name == "Player" or body.is_in_group("player"):
		_open()


func _open():
	is_opened = true
	# Give a random weapon upgrade
	var player = get_tree().current_scene.get_node_or_null("Player")
	var weapon_manager = player.get_node_or_null("WeaponManager") if player else null
	if weapon_manager:
		# Try upgrading a random weapon
		var upgradeable = []
		for w in weapon_manager.weapons:
			if w.level < w.max_level:
				upgradeable.append(w)
		if upgradeable.size() > 0:
			var w = upgradeable[randi() % upgradeable.size()]
			w.level_up()
			_show_upgrade_text(w.weapon_name + " Lv." + str(w.level))
		else:
			_show_upgrade_text("Max Level!")
	# Open animation and free
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.3)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


func _show_upgrade_text(text: String):
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color.GOLD)
	label.add_theme_font_size_override("font_size", 24)
	label.global_position = global_position + Vector2(-40, -50)
	label.z_index = 100
	get_tree().current_scene.add_child(label)
	var tween = label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 60, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)
