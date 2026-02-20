extends Node

@export var rock_count: int = 50
@export var spawn_range: float = 3000.0
@export var safe_radius: float = 200.0

var rock_scene = preload("res://scenes/environment/Rock.tscn")


func _ready():
	# Defer spawning to avoid "parent busy setting up children" errors
	call_deferred("_spawn_rocks")


func _spawn_rocks():
	var env = get_parent()
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	# Generate cluster centers first
	var cluster_count = rock_count / 3
	var clusters: Array[Vector2] = []
	for i in range(cluster_count):
		var pos = Vector2(
			rng.randf_range(-spawn_range, spawn_range),
			rng.randf_range(-spawn_range, spawn_range)
		)
		# Avoid player start area
		if pos.length() < safe_radius:
			pos = pos.normalized() * (safe_radius + 100)
		clusters.append(pos)

	var spawned = 0
	# Spawn rocks in clusters of 2-4
	for cluster_pos in clusters:
		if spawned >= rock_count:
			break
		var group_size = rng.randi_range(2, 4)
		for j in range(group_size):
			if spawned >= rock_count:
				break
			var offset = Vector2(
				rng.randf_range(-60, 60),
				rng.randf_range(-60, 60)
			)
			var rock_pos = cluster_pos + offset

			# Safety check: don't spawn at origin
			if rock_pos.length() < safe_radius:
				continue

			var rock = rock_scene.instantiate()
			rock.global_position = rock_pos
			# Random scale variation
			var scale_factor = rng.randf_range(0.8, 1.3)
			rock.scale = Vector2(scale_factor, scale_factor)
			# Random rotation
			rock.rotation = rng.randf_range(0, TAU)
			env.add_child(rock)
			spawned += 1
