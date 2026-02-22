extends Node

var slime_scene: PackedScene = preload("res://scenes/enemies/Enemy_Slime.tscn")
var skeleton_scene: PackedScene = preload("res://scenes/enemies/Enemy_Skeleton.tscn")
var knight_scene: PackedScene = preload("res://scenes/enemies/Enemy_ArmoredKnight.tscn")

var spawn_timer: float = 0.0
var base_spawn_interval: float = 1.2
var min_spawn_interval: float = 0.25
var spawn_distance: float = 700.0  # Spawn off-screen
var max_enemies: int = 300  # Performance safety cap

# Mini-boss tracking
var mini_boss_spawned: Dictionary = {}  # time_key: bool
var mini_boss_schedule: Array = [
	{"time": 180.0, "type": "giant_slime"},   # 3 min
	{"time": 360.0, "type": "skeleton_lord"},  # 6 min
	{"time": 540.0, "type": "dark_knight"},    # 9 min
]


func _process(delta):
	if not GameState.is_game_active:
		return

	spawn_timer += delta
	var interval = get_spawn_interval()

	if spawn_timer >= interval:
		spawn_timer = 0.0
		spawn_wave()

	# Check for mini-boss spawns
	_check_mini_boss_spawns()


func get_spawn_interval() -> float:
	# Spawn faster as time goes on
	var time_factor = GameState.game_time / 60.0  # Gets faster every minute
	var interval = base_spawn_interval - (time_factor * 0.07)
	# 12+ minutes: even faster spawn rate
	if GameState.game_time >= 720.0:
		interval *= 0.55
	return max(interval, min_spawn_interval)


func _get_spawn_count() -> int:
	var game_time = GameState.game_time
	if game_time < 120.0:
		# 0-2 min: always singles (onboarding)
		return 1
	elif game_time < 300.0:
		# 2-5 min: 30% chance of 2
		return 2 if randf() < 0.30 else 1
	elif game_time < 600.0:
		# 5-10 min: 40% chance of 2, 15% chance of 3
		var roll = randf()
		if roll < 0.15:
			return 3
		elif roll < 0.55:
			return 2
		else:
			return 1
	else:
		# 10+ min: 40% chance of 2, 30% chance of 3
		var roll = randf()
		if roll < 0.30:
			return 3
		elif roll < 0.70:
			return 2
		else:
			return 1


func spawn_wave():
	var player = get_tree().current_scene.get_node_or_null("Player")
	if not player:
		return

	# Check enemy cap
	var enemy_count = get_tree().get_nodes_in_group("enemies").size()
	if enemy_count >= max_enemies:
		return

	var count = _get_spawn_count()
	var base_angle = randf() * TAU

	for i in range(count):
		# Spread multi-spawns by ~20 degrees so they don't stack
		var spread_offset = (i - (count - 1) / 2.0) * 0.35
		var angle = base_angle + spread_offset
		var pos = player.global_position + Vector2(cos(angle), sin(angle)) * spawn_distance

		var enemy_scene = _pick_enemy_scene()
		var enemy = enemy_scene.instantiate()
		enemy.global_position = pos

		# Elite chance: 8% after 5 minutes
		if GameState.game_time >= 300.0 and randf() < 0.08:
			enemy.is_elite = true

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


func _check_mini_boss_spawns():
	var player = get_tree().current_scene.get_node_or_null("Player")
	if not player:
		return

	for boss_entry in mini_boss_schedule:
		var time_key = str(boss_entry.time)
		if mini_boss_spawned.get(time_key, false):
			continue
		if GameState.game_time >= boss_entry.time:
			mini_boss_spawned[time_key] = true
			_spawn_mini_boss(boss_entry.type, player)


func _spawn_mini_boss(boss_type: String, player: CharacterBody2D):
	var offset = Vector2(500, 0).rotated(randf() * TAU)
	var pos = player.global_position + offset

	var boss: CharacterBody2D
	match boss_type:
		"giant_slime":
			var GiantSlimeScript = load("res://scripts/enemies/Enemy_GiantSlime.gd")
			boss = _create_mini_boss_from_scene(slime_scene, GiantSlimeScript)
		"skeleton_lord":
			var SkeletonLordScript = load("res://scripts/enemies/Enemy_SkeletonLord.gd")
			boss = _create_mini_boss_from_scene(skeleton_scene, SkeletonLordScript)
		"dark_knight":
			var DarkKnightScript = load("res://scripts/enemies/Enemy_DarkKnightCommander.gd")
			boss = _create_mini_boss_from_scene(knight_scene, DarkKnightScript)

	if boss:
		boss.global_position = pos
		get_tree().current_scene.get_node("Enemies").add_child(boss)


func _create_mini_boss_from_scene(base_scene: PackedScene, script: GDScript) -> CharacterBody2D:
	var enemy = base_scene.instantiate()
	enemy.set_script(script)
	return enemy
