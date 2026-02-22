extends "res://scripts/weapons/Weapon_Aura.gd"
## Tempest Aura - Evolved Aura + Wings
## Massive pulsing aura that also pulls enemies inward
## Inherits aura_effect_scene, _spawn_pulse_visual from Weapon_Aura

var pull_force: float = 60.0
var _pull_scan_timer: float = 0.0
var _pull_enemies: Array = []
const PULL_SCAN_INTERVAL: float = 0.25  # Rescan 4x/sec


func _ready() -> void:
	super._ready()
	weapon_name = "Tempest Aura"
	base_damage = 16.0
	base_cooldown = 0.8
	base_radius = 140.0
	level = 5
	max_level = 5


func _process(delta: float) -> void:
	super._process(delta)
	# Continuous pull effect — rescan enemy list periodically, apply pull every frame
	if is_instance_valid(player):
		_pull_scan_timer -= delta
		if _pull_scan_timer <= 0:
			_pull_scan_timer = PULL_SCAN_INTERVAL
			_pull_enemies = get_enemies_in_range(base_radius + 40.0)
		var player_pos: Vector2 = player.global_position
		for enemy in _pull_enemies:
			if is_instance_valid(enemy) and enemy.is_alive:
				var dir: Vector2 = (player_pos - enemy.global_position).normalized()
				enemy.global_position += dir * pull_force * delta


func attack() -> void:
	if not is_instance_valid(player):
		return
	var enemies: Array = get_enemies_in_range(base_radius)
	# Spawn visual pulse (inherited from Aura) with blue tint
	var effect: Node = aura_effect_scene.instantiate()
	effect.pulse_radius = base_radius
	effect.global_position = player.global_position
	effect.modulate = Color(0.4, 0.8, 1.0, 0.8)  # Blue tint
	get_tree().current_scene.add_child(effect)
	# Deal damage with inward knockback
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.is_alive:
			enemy.take_damage(get_damage())
			var dir: Vector2 = (player.global_position - enemy.global_position).normalized()
			enemy.global_position += dir * 25.0
