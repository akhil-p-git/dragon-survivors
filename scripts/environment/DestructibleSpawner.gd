extends Node
## Spawns destructible objects around the player as they move.

var DestructibleScript = preload("res://scripts/environment/DestructibleBase.gd")
var spawn_radius: float = 800.0
var despawn_radius: float = 1200.0
var max_destructibles: int = 15
var spawn_timer: float = 0.0
var spawn_interval: float = 1.5
var types: Array = ["torch", "torch", "torch", "barrel", "barrel", "crystal"]


func _process(delta):
	if not GameState.is_game_active:
		return
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_try_spawn()
	_despawn_far()


func _try_spawn():
	var existing = get_tree().get_nodes_in_group("destructibles")
	if existing.size() >= max_destructibles:
		return
	var player = get_tree().current_scene.get_node_or_null("Player")
	if not player:
		return
	var angle = randf() * TAU
	var dist = randf_range(400.0, spawn_radius)
	var pos = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	var destructible = Area2D.new()
	destructible.set_script(DestructibleScript)
	destructible.destructible_type = types[randi() % types.size()]
	destructible.global_position = pos
	get_tree().current_scene.add_child(destructible)


func _despawn_far():
	var player = get_tree().current_scene.get_node_or_null("Player")
	if not player:
		return
	var destructibles = get_tree().get_nodes_in_group("destructibles")
	for d in destructibles:
		if is_instance_valid(d) and d.global_position.distance_to(player.global_position) > despawn_radius:
			d.queue_free()
