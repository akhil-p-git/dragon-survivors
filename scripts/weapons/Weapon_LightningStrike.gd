extends "res://scripts/weapons/WeaponBase.gd"

## Lightning Strike weapon - strikes nearest enemies with a bolt from above.
## Level scaling:
##   L1: 1 strike, base damage, 2.0s cooldown
##   L2: +damage (via get_damage())
##   L3: 2 strikes per activation
##   L4: +damage, cooldown reduced to 1.6s
##   L5: 3 strikes, +damage

var lightning_scene: PackedScene = preload("res://scenes/weapons/LightningStrike.tscn")
var strike_range: float = 350.0


func _ready() -> void:
	super._ready()
	weapon_name = "Lightning Strike"
	base_damage = 28.0
	base_cooldown = 1.7


func get_cooldown() -> float:
	# Level 4+ reduces base cooldown to 1.6s
	var cd: float = base_cooldown
	if level >= 4:
		cd = 1.3
	# Apply the per-level scaling and attack speed multiplier from base
	cd *= (1.0 - (level - 1) * 0.08)
	cd *= attack_speed_multiplier
	# Apply global attack speed buff from level-up buffs
	cd *= GameState.attack_speed_mult
	# Apply passive cooldown multiplier from player (Tome passive item)
	if is_instance_valid(player) and "passive_cooldown_multiplier" in player:
		cd *= player.passive_cooldown_multiplier
	# Apply meta-progression cooldown bonus
	if SaveData:
		cd *= (1.0 - SaveData.get_stat_bonus("cooldown_mult"))
	return cd


func _get_strike_count() -> int:
	var base_count: int = 1
	if level >= 5:
		base_count = 4
	elif level >= 3:
		base_count = 2
	# Add extra strikes from Duplicator passive item
	return base_count + get_extra_projectiles()


func attack() -> void:
	if not is_instance_valid(player):
		return

	var enemies: Array = get_enemies_in_range(strike_range)
	if enemies.size() == 0:
		return

	var strike_count: int = _get_strike_count()
	var hit_enemies: Array = []

	for i in range(strike_count):
		if i >= enemies.size():
			break

		var target = enemies[i]
		if not is_instance_valid(target) or not target.is_alive:
			continue

		# Stagger strikes slightly for multi-hit visual impact
		if i == 0:
			_strike(target)
		else:
			var delay: float = i * 0.08
			var enemy_ref = target
			get_tree().create_timer(delay).timeout.connect(func():
				if is_instance_valid(enemy_ref) and enemy_ref.is_alive:
					_strike(enemy_ref)
			)
		hit_enemies.append(target)


func _strike(enemy: CharacterBody2D) -> void:
	if not is_instance_valid(enemy) or not enemy.is_alive:
		return

	# Deal damage
	enemy.take_damage(get_damage())

	# Spawn the lightning bolt visual effect at the enemy position
	_spawn_lightning_effect(enemy.global_position)

	# Brief white flash on the struck enemy for impact feel
	_flash_enemy(enemy)


func _spawn_lightning_effect(target_pos: Vector2) -> void:
	var effect: Node = lightning_scene.instantiate()
	effect.global_position = target_pos
	# Add to the scene tree root so it stays at the world position
	get_tree().current_scene.add_child(effect)


func _flash_enemy(enemy: CharacterBody2D) -> void:
	if not is_instance_valid(enemy):
		return
	# Bright white flash before returning to normal (overrides the red damage flash)
	var original_modulate: Color = enemy.modulate
	enemy.modulate = Color(4.0, 4.0, 4.0, 1.0)  # HDR white for glow
	get_tree().create_timer(0.06).timeout.connect(func():
		if is_instance_valid(enemy):
			enemy.modulate = original_modulate
	)
