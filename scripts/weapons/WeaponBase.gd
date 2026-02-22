extends Node

@export var weapon_name: String = "Base Weapon"
@export var base_damage: float = 10.0
@export var base_cooldown: float = 1.5
@export var level: int = 1
@export var max_level: int = 5

var cooldown_timer: float = 0.0
var player: CharacterBody2D
var attack_speed_multiplier: float = 1.0


func _ready() -> void:
	# Weapon -> WeaponManager -> Player
	player = get_parent().get_parent()


func _process(delta: float) -> void:
	cooldown_timer -= delta
	if cooldown_timer <= 0:
		attack()
		cooldown_timer = get_cooldown()


func get_damage() -> float:
	var raw: float = base_damage + (level - 1) * (base_damage * 0.3)
	# Apply passive damage multiplier from player (Spinach, etc.)
	if is_instance_valid(player) and "passive_damage_multiplier" in player:
		raw *= player.passive_damage_multiplier
	# Apply meta-progression Might bonus
	if SaveData:
		raw *= (1.0 + SaveData.get_stat_bonus("damage_mult"))
	return raw


func get_cooldown() -> float:
	var cd: float = base_cooldown * (1.0 - (level - 1) * 0.08)
	cd *= attack_speed_multiplier
	# Apply global attack speed buff from level-up buffs
	cd *= GameState.attack_speed_mult
	# Apply passive cooldown multiplier from player (Tome, etc.)
	if is_instance_valid(player) and "passive_cooldown_multiplier" in player:
		cd *= player.passive_cooldown_multiplier
	# Apply meta-progression cooldown bonus
	if SaveData:
		cd *= (1.0 - SaveData.get_stat_bonus("cooldown_mult"))
	return cd


## Returns the number of extra projectiles from passive items (Duplicator, etc.).
## Weapons that support multi-projectile should call this in their attack().
func get_extra_projectiles() -> int:
	if is_instance_valid(player) and "passive_extra_projectiles" in player:
		return player.passive_extra_projectiles
	return 0


func level_up() -> void:
	level = min(level + 1, max_level)


func attack() -> void:
	pass  # Override in subclasses


## Safe accessor for the Projectiles container node.
func _get_projectiles_node() -> Node:
	return get_tree().current_scene.get_node_or_null("Projectiles")


func get_enemies_in_range(range_val: float) -> Array:
	if not is_instance_valid(player):
		return []
	var range_sq: float = range_val * range_val
	var player_pos: Vector2 = player.global_position
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	var in_range: Array = []
	for e in enemies:
		if is_instance_valid(e) and e.is_alive:
			if player_pos.distance_squared_to(e.global_position) <= range_sq:
				in_range.append(e)
	in_range.sort_custom(func(a, b): return player_pos.distance_squared_to(a.global_position) < player_pos.distance_squared_to(b.global_position))
	return in_range


func get_nearest_enemy(range_val: float = 600.0) -> Variant:
	if not is_instance_valid(player):
		return null
	var range_sq: float = range_val * range_val
	var player_pos: Vector2 = player.global_position
	var nearest: Variant = null
	var nearest_dist_sq: float = range_sq
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.is_alive:
			var d_sq: float = player_pos.distance_squared_to(e.global_position)
			if d_sq <= nearest_dist_sq:
				nearest = e
				nearest_dist_sq = d_sq
	return nearest
