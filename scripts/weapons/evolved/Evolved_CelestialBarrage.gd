extends "res://scripts/weapons/Weapon_Orbiting.gd"
## Celestial Barrage - Evolved Orbiting Orbs + Hollow Heart
## 8 orbs, larger orbit, orbs explode on contact
## Inherits orbit_projectile_scene, orbit state, _update_projectile_positions,
## _despawn_projectiles, _exit_tree from Weapon_Orbiting


func _ready() -> void:
	super._ready()
	weapon_name = "Celestial Barrage"
	base_damage = 22.0
	base_cooldown = 4.0
	orbit_radius = 120.0
	orbit_speed = 3.0
	orbit_duration = 5.0
	level = 5
	max_level = 5


func _process(delta: float) -> void:
	if orbiting:
		orbit_angle += orbit_speed * delta
		orbit_timer -= delta
		_update_projectile_positions()
		# Check hits on a timer
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			cooldown_timer = 0.2
			_check_hits()
		if orbit_timer <= 0:
			_despawn_projectiles()
			orbiting = false
			cooldown_timer = get_cooldown()
	else:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			attack()
			cooldown_timer = get_cooldown()


func _spawn_projectiles() -> void:
	_despawn_projectiles()
	var count: int = 8 + get_extra_projectiles()
	for i in range(count):
		var proj: Node = orbit_projectile_scene.instantiate()
		proj.damage = get_damage()
		proj.scale = Vector2(1.5, 1.5)
		proj.modulate = Color(0.6, 0.8, 1.0, 0.9)
		var angle: float = (float(i) / float(count)) * TAU
		var offset: Vector2 = Vector2(cos(angle), sin(angle)) * orbit_radius
		proj.global_position = player.global_position + offset
		var proj_node: Node = _get_projectiles_node()
		if proj_node:
			proj_node.add_child(proj)
		projectiles.append(proj)
	orbit_angle = 0.0


func _check_hits() -> void:
	var hit_range_sq: float = 30.0 * 30.0
	for proj in projectiles:
		if not is_instance_valid(proj):
			continue
		var proj_pos: Vector2 = proj.global_position
		var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.is_alive:
				if proj_pos.distance_squared_to(enemy.global_position) < hit_range_sq:
					enemy.take_damage(get_damage())
					_explode_at(proj_pos)
					break


func _explode_at(pos: Vector2) -> void:
	var explode_range_sq: float = 60.0 * 60.0
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e.is_alive:
			if pos.distance_squared_to(e.global_position) < explode_range_sq:
				e.take_damage(get_damage() * 0.4)
