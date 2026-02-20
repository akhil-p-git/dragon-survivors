extends "res://scripts/weapons/WeaponBase.gd"

# Aura weapon - damages all enemies within a radius around the player
# Pulses periodically, dealing damage and applying slight knockback

var aura_effect_scene: PackedScene = preload("res://scenes/weapons/AuraEffect.tscn")
var aura_instance: Node2D = null

# Level scaling parameters
var base_radius: float = 60.0
var base_knockback: float = 40.0


func _ready():
	super._ready()
	weapon_name = "Aura"
	base_damage = 8.0
	base_cooldown = 1.5


func _process(delta):
	# Keep the aura following the player
	if is_instance_valid(aura_instance) and is_instance_valid(player):
		aura_instance.global_position = player.global_position
	# Run the base cooldown/attack logic
	super._process(delta)


func attack():
	if not is_instance_valid(player):
		return

	var radius = _get_radius()
	var enemies = get_enemies_in_range(radius)

	if enemies.size() == 0 and not is_instance_valid(aura_instance):
		# Still show the pulse even if no enemies are hit
		_spawn_pulse_visual(radius)
		return

	# Spawn the visual pulse
	_spawn_pulse_visual(radius)

	# Deal damage and knockback to all enemies in range
	var knockback_force = _get_knockback()
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.is_alive:
			continue
		enemy.take_damage(get_damage())
		# Apply knockback: push enemy away from player center
		var direction = (enemy.global_position - player.global_position).normalized()
		if direction == Vector2.ZERO:
			direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		enemy.global_position += direction * knockback_force


func _spawn_pulse_visual(radius: float):
	if not is_instance_valid(player):
		return
	var effect = aura_effect_scene.instantiate()
	effect.pulse_radius = radius
	effect.global_position = player.global_position
	get_tree().current_scene.add_child(effect)


func _get_radius() -> float:
	match level:
		1: return base_radius          # 60
		2: return base_radius          # 60
		3: return 80.0                 # 80
		4: return 80.0                 # 80
		5: return 100.0                # 100
		_: return base_radius
	return base_radius


func _get_knockback() -> float:
	if level >= 5:
		return base_knockback * 1.8    # Increased knockback at level 5
	return base_knockback


func get_cooldown() -> float:
	var cd = base_cooldown
	if level >= 4:
		cd = 1.2
	cd *= attack_speed_multiplier
	# Apply passive cooldown multiplier from player (Tome passive item)
	if is_instance_valid(player) and "passive_cooldown_multiplier" in player:
		cd *= player.passive_cooldown_multiplier
	return cd


func get_damage() -> float:
	# Custom damage scaling for aura
	# Level 1: base, Level 2: +damage, Level 5: +damage again
	var dmg = base_damage
	if level >= 2:
		dmg += base_damage * 0.4
	if level >= 5:
		dmg += base_damage * 0.4
	# Apply passive damage multiplier from player (Spinach passive item)
	if is_instance_valid(player) and "passive_damage_multiplier" in player:
		dmg *= player.passive_damage_multiplier
	return dmg
