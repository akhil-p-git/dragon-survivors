extends "res://scripts/weapons/WeaponBase.gd"

var orbit_projectile_scene: PackedScene = preload("res://scenes/weapons/OrbitProjectile.tscn")

var orbit_radius: float = 90.0
var orbit_speed: float = 2.5  # radians per second
var orbit_duration: float = 4.5  # how long projectiles stay active
var projectiles: Array = []
var orbit_angle: float = 0.0
var orbiting: bool = false
var orbit_timer: float = 0.0


func _ready():
	super._ready()
	weapon_name = "Orbiting Orbs"
	base_damage = 14.0
	base_cooldown = 4.0  # cooldown between orbit cycles


func _process(delta):
	if orbiting:
		orbit_angle += _get_orbit_speed() * delta
		orbit_timer -= delta
		_update_projectile_positions()
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


func _get_projectile_count() -> int:
	# Level 1: 3, Level 2: 3, Level 3: 4, Level 4: 4, Level 5: 5
	var base_count: int
	match level:
		1: base_count = 3
		2: base_count = 3
		3: base_count = 4
		4: base_count = 4
		_: base_count = 5
	# Add extra projectiles from Duplicator passive item
	return base_count + get_extra_projectiles()


func _get_orbit_speed() -> float:
	# Level 5 gets faster rotation
	if level >= 5:
		return orbit_speed * 1.5
	return orbit_speed


func _spawn_projectiles():
	_despawn_projectiles()
	var count = _get_projectile_count()
	for i in range(count):
		var proj = orbit_projectile_scene.instantiate()
		proj.damage = get_damage()
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


func _despawn_projectiles():
	for proj in projectiles:
		if is_instance_valid(proj):
			# Fade out before freeing
			var tween = proj.create_tween()
			tween.tween_property(proj, "modulate:a", 0.0, 0.2)
			tween.tween_callback(proj.queue_free)
	projectiles.clear()


func level_up():
	super.level_up()
	# If currently orbiting, respawn with new count
	if orbiting:
		_spawn_projectiles()
		orbiting = true
		orbit_timer = orbit_duration
