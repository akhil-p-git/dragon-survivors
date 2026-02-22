extends "res://scripts/weapons/Weapon_LightningStrike.gd"
## Thunder Storm - Evolved Lightning Strike + Duplicator
## 5 simultaneous lightning bolts that chain to nearby enemies
## Inherits lightning_scene, _strike, _spawn_lightning_effect, _flash_enemy from Weapon_LightningStrike


func _ready() -> void:
	super._ready()
	weapon_name = "Thunder Storm"
	base_damage = 40.0
	base_cooldown = 1.4
	strike_range = 500.0
	level = 5
	max_level = 5


func attack() -> void:
	if not is_instance_valid(player):
		return
	var enemies: Array = get_enemies_in_range(strike_range)
	if enemies.size() == 0:
		return
	var strike_count: int = 5 + get_extra_projectiles()
	for i in range(min(strike_count, enemies.size())):
		var target = enemies[i]
		if not is_instance_valid(target) or not target.is_alive:
			continue
		var delay: float = i * 0.06
		var enemy_ref = target
		if delay == 0:
			_strike(enemy_ref)
			_chain_strike(enemy_ref)
		else:
			get_tree().create_timer(delay).timeout.connect(func():
				if is_instance_valid(enemy_ref) and enemy_ref.is_alive:
					_strike(enemy_ref)
					_chain_strike(enemy_ref)
			)


## Chain: hit one nearby enemy for half damage
func _chain_strike(source_enemy: CharacterBody2D) -> void:
	if not is_instance_valid(source_enemy):
		return
	var chain_range_sq: float = 120.0 * 120.0
	var source_pos: Vector2 = source_enemy.global_position
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e == source_enemy or not is_instance_valid(e) or not e.is_alive:
			continue
		if source_pos.distance_squared_to(e.global_position) <= chain_range_sq:
			e.take_damage(get_damage() * 0.5)
			_spawn_lightning_effect(e.global_position)
			break
