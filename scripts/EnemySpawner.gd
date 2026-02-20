extends Node

var slime_scene: PackedScene = preload("res://scenes/enemies/Enemy_Slime.tscn")
var skeleton_scene: PackedScene = preload("res://scenes/enemies/Enemy_Skeleton.tscn")
var knight_scene: PackedScene = preload("res://scenes/enemies/Enemy_ArmoredKnight.tscn")

var spawn_timer: float = 0.0
var base_spawn_interval: float = 2.0
var min_spawn_interval: float = 0.3
var spawn_distance: float = 700.0  # Spawn off-screen


func _process(delta):
	if not GameState.is_game_active:
		return

	spawn_timer += delta
	var interval = get_spawn_interval()

	if spawn_timer >= interval:
		spawn_timer = 0.0
		spawn_enemy()


func get_spawn_interval() -> float:
	# Spawn faster as time goes on
	var time_factor = GameState.game_time / 60.0  # Gets faster every minute
	var interval = base_spawn_interval - (time_factor * 0.15)
	# 12+ minutes: even faster spawn rate
	if GameState.game_time >= 720.0:
		interval *= 0.6
	return max(interval, min_spawn_interval)


func spawn_enemy():
	var player = get_tree().current_scene.get_node_or_null("Player")
	if not player:
		return

	# Random position around player, off-screen
	var angle = randf() * TAU
	var pos = player.global_position + Vector2(cos(angle), sin(angle)) * spawn_distance

	var enemy_scene = _pick_enemy_scene()
	var enemy = enemy_scene.instantiate()
	enemy.global_position = pos
	get_tree().current_scene.get_node("Enemies").add_child(enemy)


func _pick_enemy_scene() -> PackedScene:
	var game_time = GameState.game_time
	var roll = randf()

	if game_time < 180.0:
		# 0-3 min: slimes only
		return slime_scene
	elif game_time < 420.0:
		# 3-7 min: slimes + skeletons
		if roll < 0.6:
			return slime_scene
		else:
			return skeleton_scene
	elif game_time < 720.0:
		# 7-12 min: slimes + skeletons + armored knights
		if roll < 0.4:
			return slime_scene
		elif roll < 0.75:
			return skeleton_scene
		else:
			return knight_scene
	else:
		# 12+ min: dense mix of everything
		if roll < 0.3:
			return slime_scene
		elif roll < 0.6:
			return skeleton_scene
		else:
			return knight_scene
