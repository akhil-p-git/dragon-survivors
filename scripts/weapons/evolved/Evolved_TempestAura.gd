extends "res://scripts/weapons/WeaponBase.gd"
## Tempest Aura - Evolved Aura + Wings
## Massive pulsing aura that also pulls enemies inward

var aura_effect_scene: PackedScene = preload("res://scenes/weapons/AuraEffect.tscn")
var base_radius: float = 140.0
var pull_force: float = 60.0


func _ready():
	super._ready()
	weapon_name = "Tempest Aura"
	base_damage = 16.0
	base_cooldown = 0.8
	level = 5
	max_level = 5


func _process(delta):
	super._process(delta)
	# Continuous pull effect
	if is_instance_valid(player):
		var enemies = get_enemies_in_range(base_radius + 40.0)
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.is_alive:
				var dir = (player.global_position - enemy.global_position).normalized()
				enemy.global_position += dir * pull_force * delta


func attack():
	if not is_instance_valid(player):
		return
	var enemies = get_enemies_in_range(base_radius)
	# Spawn visual pulse
	var effect = aura_effect_scene.instantiate()
	effect.pulse_radius = base_radius
	effect.global_position = player.global_position
	effect.modulate = Color(0.4, 0.8, 1.0, 0.8)  # Blue tint
	get_tree().current_scene.add_child(effect)
	# Deal damage
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.is_alive:
			enemy.take_damage(get_damage())
			# Knockback inward (toward player)
			var dir = (player.global_position - enemy.global_position).normalized()
			enemy.global_position += dir * 25.0
