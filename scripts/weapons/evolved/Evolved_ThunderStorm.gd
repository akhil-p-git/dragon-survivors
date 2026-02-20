extends "res://scripts/weapons/WeaponBase.gd"
## Thunder Storm - Evolved Lightning Strike + Duplicator
## 5 simultaneous lightning bolts that chain to nearby enemies

var lightning_scene: PackedScene = preload("res://scenes/weapons/LightningStrike.tscn")
var strike_range: float = 500.0


func _ready():
	super._ready()
	weapon_name = "Thunder Storm"
	base_damage = 40.0
	base_cooldown = 1.4
	level = 5
	max_level = 5


func attack():
	if not is_instance_valid(player):
		return
	var enemies = get_enemies_in_range(strike_range)
	if enemies.size() == 0:
		return
	var strike_count = 5 + get_extra_projectiles()
	for i in range(min(strike_count, enemies.size())):
		var target = enemies[i]
		if not is_instance_valid(target) or not target.is_alive:
			continue
		var delay = i * 0.06
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


func _strike(enemy):
	if not is_instance_valid(enemy) or not enemy.is_alive:
		return
	enemy.take_damage(get_damage())
	var effect = lightning_scene.instantiate()
	effect.global_position = enemy.global_position
	get_tree().current_scene.add_child(effect)
	enemy.modulate = Color(4.0, 4.0, 4.0, 1.0)
	get_tree().create_timer(0.06).timeout.connect(func():
		if is_instance_valid(enemy): enemy.modulate = Color.WHITE
	)


## Chain: hit one nearby enemy for half damage
func _chain_strike(source_enemy):
	if not is_instance_valid(source_enemy):
		return
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e == source_enemy or not is_instance_valid(e) or not e.is_alive:
			continue
		if source_enemy.global_position.distance_to(e.global_position) <= 120.0:
			e.take_damage(get_damage() * 0.5)
			var effect = lightning_scene.instantiate()
			effect.global_position = e.global_position
			effect.scale = Vector2(0.7, 0.7)
			get_tree().current_scene.add_child(effect)
			break
