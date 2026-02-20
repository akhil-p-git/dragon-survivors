extends Node

@export var weapon_name: String = "Base Weapon"
@export var base_damage: float = 10.0
@export var base_cooldown: float = 1.5
@export var level: int = 1
@export var max_level: int = 5

var cooldown_timer: float = 0.0
var player: CharacterBody2D
var attack_speed_multiplier: float = 1.0


func _ready():
	# Weapon -> WeaponManager -> Player
	player = get_parent().get_parent()


func _process(delta):
	cooldown_timer -= delta
	if cooldown_timer <= 0:
		attack()
		cooldown_timer = get_cooldown()


func get_damage() -> float:
	var raw = base_damage + (level - 1) * (base_damage * 0.3)
	# Apply passive damage multiplier from player (Spinach, etc.)
	if is_instance_valid(player) and "passive_damage_multiplier" in player:
		raw *= player.passive_damage_multiplier
	return raw


func get_cooldown() -> float:
	var cd = base_cooldown * (1.0 - (level - 1) * 0.08)
	cd *= attack_speed_multiplier
	# Apply passive cooldown multiplier from player (Tome, etc.)
	if is_instance_valid(player) and "passive_cooldown_multiplier" in player:
		cd *= player.passive_cooldown_multiplier
	return cd


## Returns the number of extra projectiles from passive items (Duplicator, etc.).
## Weapons that support multi-projectile should call this in their attack().
func get_extra_projectiles() -> int:
	if is_instance_valid(player) and "passive_extra_projectiles" in player:
		return player.passive_extra_projectiles
	return 0


func level_up():
	level = min(level + 1, max_level)


func attack():
	pass  # Override in subclasses


func get_enemies_in_range(range_val: float) -> Array:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var in_range: Array = []
	for e in enemies:
		if is_instance_valid(e) and e.is_alive:
			var dist = player.global_position.distance_to(e.global_position)
			if dist <= range_val:
				in_range.append(e)
	in_range.sort_custom(func(a, b): return player.global_position.distance_to(a.global_position) < player.global_position.distance_to(b.global_position))
	return in_range


func get_nearest_enemy(range_val: float = 600.0):
	var enemies = get_enemies_in_range(range_val)
	if enemies.size() > 0:
		return enemies[0]
	return null
