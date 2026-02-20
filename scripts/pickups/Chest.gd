extends Area2D

var is_opened: bool = false
var chest_tier: int = 1  # 1=Bronze, 2=Silver, 3=Gold

# Tier colors for visual
const TIER_COLORS = {
	1: Color(0.7, 0.5, 0.2),    # Bronze
	2: Color(0.75, 0.75, 0.8),  # Silver
	3: Color(1.0, 0.85, 0.2),   # Gold
}
const TIER_ITEMS = {1: 1, 2: 3, 3: 5}


func _ready():
	collision_layer = 16  # Pickups
	collision_mask = 1    # Player
	body_entered.connect(_on_body_entered)
	# Apply tier tint
	var body = get_node_or_null("Body")
	if body:
		body.modulate = TIER_COLORS.get(chest_tier, Color.WHITE)


func _on_body_entered(body):
	if is_opened:
		return
	if body.name == "Player" or body.is_in_group("player"):
		_open()


func _open():
	is_opened = true
	var player = get_tree().current_scene.get_node_or_null("Player")
	var weapon_manager = player.get_node_or_null("WeaponManager") if player else null
	var passive_manager = player.get_node_or_null("PassiveItemManager") if player else null
	var evolution_manager = player.get_node_or_null("EvolutionManager") if player else null

	var items_to_give = TIER_ITEMS.get(chest_tier, 1)
	var evolved = false

	# Check for weapon evolution (Silver+ chests, after 5 minutes)
	if chest_tier >= 2 and GameState.game_time >= 300.0 and evolution_manager and weapon_manager and passive_manager:
		var evo = evolution_manager.get_eligible_evolution(weapon_manager, passive_manager)
		if not evo.is_empty():
			var evolved_weapon = evolution_manager.evolve_weapon(weapon_manager, evo.weapon, evo.data)
			if evolved_weapon:
				_show_evolution_text(evo.data.evolved_name)
				evolved = true
				items_to_give -= 1
	# Gold chest: guaranteed evolution attempt
	elif chest_tier >= 3 and GameState.game_time >= 300.0 and evolution_manager and weapon_manager and passive_manager:
		var evo = evolution_manager.get_eligible_evolution(weapon_manager, passive_manager)
		if not evo.is_empty():
			var evolved_weapon = evolution_manager.evolve_weapon(weapon_manager, evo.weapon, evo.data)
			if evolved_weapon:
				_show_evolution_text(evo.data.evolved_name)
				evolved = true
				items_to_give -= 1

	# Give remaining item upgrades
	if weapon_manager:
		for i in range(items_to_give):
			var upgradeable = []
			for w in weapon_manager.weapons:
				if w.level < w.max_level:
					upgradeable.append(w)
			if upgradeable.size() > 0:
				var w = upgradeable[randi() % upgradeable.size()]
				w.level_up()
				if i == 0 and not evolved:
					_show_upgrade_text(w.weapon_name + " Lv." + str(w.level))
			else:
				if i == 0 and not evolved:
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
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.global_position = global_position + Vector2(-40, -50)
	label.z_index = 100
	get_tree().current_scene.add_child(label)
	var tween = label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 60, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)


func _show_evolution_text(weapon_name: String):
	var label = Label.new()
	label.text = "EVOLVED: " + weapon_name + "!"
	label.add_theme_color_override("font_color", Color(1.0, 0.5, 1.0))
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.global_position = global_position + Vector2(-80, -70)
	label.z_index = 100
	label.scale = Vector2(0.5, 0.5)
	get_tree().current_scene.add_child(label)
	var tween = label.create_tween()
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_property(label, "position:y", label.position.y - 80, 1.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.5)
	tween.tween_callback(label.queue_free)
	ScreenEffects.shake(ScreenEffects.SHAKE_MEDIUM, 0.3)
