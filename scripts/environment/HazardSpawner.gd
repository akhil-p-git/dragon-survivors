extends Node
## Spawns environmental hazards (fire patches, quicksand) around the player.

var _FirePatchScript: GDScript = preload("res://scripts/environment/FirePatch.gd")
var _QuicksandScript: GDScript = preload("res://scripts/environment/QuicksandPatch.gd")

var spawn_timer: float = 0.0
var spawn_interval: float = 4.0
var spawn_distance_min: float = 200.0
var spawn_distance_max: float = 600.0
var max_hazards: int = 12
var despawn_radius: float = 1200.0
var _despawn_timer: float = 0.0


func _process(delta: float) -> void:
	if not GameState.is_game_active:
		return

	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_try_spawn()

	_despawn_timer += delta
	if _despawn_timer >= 2.0:
		_despawn_timer = 0.0
		_despawn_far()


func _try_spawn() -> void:
	var existing: Array[Node] = get_tree().get_nodes_in_group("hazards")
	if existing.size() >= max_hazards:
		return
	var player: Node = get_tree().current_scene.get_node_or_null("Player")
	if not player:
		return

	var angle: float = randf() * TAU
	var dist: float = randf_range(spawn_distance_min, spawn_distance_max)
	var pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * dist

	var hazard: Area2D = Area2D.new()
	if randf() < 0.5:
		hazard.set_script(_FirePatchScript)
	else:
		hazard.set_script(_QuicksandScript)
	hazard.global_position = pos
	get_tree().current_scene.add_child(hazard)


func _despawn_far() -> void:
	var player: Node = get_tree().current_scene.get_node_or_null("Player")
	if not player:
		return
	for h in get_tree().get_nodes_in_group("hazards"):
		if is_instance_valid(h) and h.global_position.distance_squared_to(player.global_position) > despawn_radius * despawn_radius:
			h.queue_free()
