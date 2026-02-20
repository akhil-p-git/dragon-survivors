extends "res://scripts/weapons/WeaponBase.gd"
## Celestial Barrage - Evolved Orbiting Orbs + Hollow Heart
## 8 orbs, larger orbit, orbs explode on contact

var orbit_projectile_scene: PackedScene = preload("res://scenes/weapons/OrbitProjectile.tscn")
var orbit_radius: float = 120.0
var orbit_speed: float = 3.0
var orbit_duration: float = 5.0
var projectiles: Array = []
var orbit_angle: float = 0.0
var orbiting: bool = false
var orbit_timer: float = 0.0


func _ready():
	super._ready()
	weapon_name = "Celestial Barrage"
	base_damage = 22.0
	base_cooldown = 4.0
	level = 5
	max_level = 5


func _process(delta):
	if orbiting:
		orbit_angle += orbit_speed * delta
		orbit_timer -= delta
		_update_projectile_positions()
		# Check hits
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


func attack():
	if not is_instance_valid(player):
		return
	_spawn_projectiles()
	orbiting = true
	orbit_timer = orbit_duration


func _spawn_projectiles():
	_despawn_projectiles()
	var count = 8 + get_extra_projectiles()
	for i in range(count):
		var proj = orbit_projectile_scene.instantiate()
		proj.damage = get_damage()
		proj.scale = Vector2(1.5, 1.5)
		proj.modulate = Color(0.6, 0.8, 1.0, 0.9)
		var angle = (float(i) / float(count)) * TAU
		var offset = Vector2(cos(angle), sin(angle)) * orbit_radius
		proj.global_position = player.global_position + offset
		get_tree().current_scene.get_node("Projectiles").add_child(proj)
		projectiles.append(proj)
	orbit_angle = 0.0


func _update_projectile_positions():
	if not is_instance_valid(player):
		return
	var count = projectiles.size()
	for i in range(count):
		if is_instance_valid(projectiles[i]):
			var angle = orbit_angle + (float(i) / float(count)) * TAU
			var offset = Vector2(cos(angle), sin(angle)) * orbit_radius
			projectiles[i].global_position = player.global_position + offset


func _check_hits():
	for proj in projectiles:
		if not is_instance_valid(proj):
			continue
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.is_alive:
				if proj.global_position.distance_to(enemy.global_position) < 30.0:
					enemy.take_damage(get_damage())
					# Explosion effect: damage nearby enemies
					_explode_at(proj.global_position)
					break


func _explode_at(pos: Vector2):
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e.is_alive:
			if pos.distance_to(e.global_position) < 60.0:
				e.take_damage(get_damage() * 0.4)


func _despawn_projectiles():
	for proj in projectiles:
		if is_instance_valid(proj):
			var tween = proj.create_tween()
			tween.tween_property(proj, "modulate:a", 0.0, 0.2)
			tween.tween_callback(proj.queue_free)
	projectiles.clear()
