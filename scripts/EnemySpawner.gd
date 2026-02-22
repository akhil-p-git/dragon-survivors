extends Node

# Difficulty phase thresholds (in seconds)
const PHASE_SKELETONS: float = 180.0   # 3 min — skeletons start spawning
const PHASE_KNIGHTS: float = 420.0     # 7 min — armored knights join
const PHASE_ENDGAME: float = 720.0     # 12 min — dense mix, faster spawns
const ELITE_THRESHOLD: float = 300.0   # 5 min — elites can appear
const ELITE_CHANCE: float = 0.10

var slime_scene: PackedScene = preload("res://scenes/enemies/Enemy_Slime.tscn")
var skeleton_scene: PackedScene = preload("res://scenes/enemies/Enemy_Skeleton.tscn")
var knight_scene: PackedScene = preload("res://scenes/enemies/Enemy_ArmoredKnight.tscn")

# Preload mini-boss scripts (avoid load() at spawn time)
var _giant_slime_script: GDScript = preload("res://scripts/enemies/Enemy_GiantSlime.gd")
var _skeleton_lord_script: GDScript = preload("res://scripts/enemies/Enemy_SkeletonLord.gd")
var _dark_knight_script: GDScript = preload("res://scripts/enemies/Enemy_DarkKnightCommander.gd")

var spawn_timer: float = 0.0
var base_spawn_interval: float = 2.0
var min_spawn_interval: float = 0.3
var spawn_distance: float = 700.0  # Spawn off-screen

# Mini-boss tracking
var mini_boss_spawned: Dictionary = {}  # time_key: bool
var mini_boss_schedule: Array = [
	{"time": 180.0, "type": "giant_slime"},   # 3 min
	{"time": 360.0, "type": "skeleton_lord"},  # 6 min
	{"time": 540.0, "type": "dark_knight"},    # 9 min
]


func _process(delta: float) -> void:
	if not GameState.is_game_active:
		return

	spawn_timer += delta
	var interval: float = get_spawn_interval()

	if spawn_timer >= interval:
		spawn_timer = 0.0
		spawn_enemy()

	# Check for mini-boss spawns
	_check_mini_boss_spawns()


func get_spawn_interval() -> float:
	# Spawn faster as time goes on
	var time_factor: float = GameState.game_time / 60.0  # Gets faster every minute
	var interval: float = base_spawn_interval - (time_factor * 0.15)
	if GameState.game_time >= PHASE_ENDGAME:
		interval *= 0.6
	return max(interval, min_spawn_interval)


func spawn_enemy() -> void:
	var player: CharacterBody2D = get_tree().current_scene.get_node_or_null("Player")
	if not player:
		return

	# Random position around player, off-screen
	var angle: float = randf() * TAU
	var pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * spawn_distance

	var enemy_scene: PackedScene = _pick_enemy_scene()
	var enemy: CharacterBody2D = enemy_scene.instantiate()
	enemy.global_position = pos

	if GameState.game_time >= ELITE_THRESHOLD and randf() < ELITE_CHANCE:
		enemy.is_elite = true

	var enemies_node: Node = get_tree().current_scene.get_node_or_null("Enemies")
	if enemies_node:
		enemies_node.add_child(enemy)


func _pick_enemy_scene() -> PackedScene:
	var game_time: float = GameState.game_time
	var roll: float = randf()

	if game_time < PHASE_SKELETONS:
		return slime_scene
	elif game_time < PHASE_KNIGHTS:
		if roll < 0.6:
			return slime_scene
		else:
			return skeleton_scene
	elif game_time < PHASE_ENDGAME:
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


func _check_mini_boss_spawns() -> void:
	var player: CharacterBody2D = get_tree().current_scene.get_node_or_null("Player")
	if not player:
		return

	for boss_entry in mini_boss_schedule:
		var time_key: String = str(boss_entry.time)
		if mini_boss_spawned.get(time_key, false):
			continue
		if GameState.game_time >= boss_entry.time:
			mini_boss_spawned[time_key] = true
			_spawn_mini_boss(boss_entry.type, player)


func _spawn_mini_boss(boss_type: String, player: CharacterBody2D) -> void:
	var offset: Vector2 = Vector2(500, 0).rotated(randf() * TAU)
	var pos: Vector2 = player.global_position + offset

	var boss: CharacterBody2D
	match boss_type:
		"giant_slime":
			boss = _create_mini_boss_from_scene(slime_scene, _giant_slime_script)
		"skeleton_lord":
			boss = _create_mini_boss_from_scene(skeleton_scene, _skeleton_lord_script)
		"dark_knight":
			boss = _create_mini_boss_from_scene(knight_scene, _dark_knight_script)

	if boss:
		boss.global_position = pos
		var enemies_node: Node = get_tree().current_scene.get_node_or_null("Enemies")
		if enemies_node:
			enemies_node.add_child(boss)


func _create_mini_boss_from_scene(base_scene: PackedScene, script: GDScript) -> CharacterBody2D:
	var enemy: CharacterBody2D = base_scene.instantiate()
	enemy.set_script(script)
	return enemy
