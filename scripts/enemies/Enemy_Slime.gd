extends "res://scripts/enemies/EnemyBase.gd"

var hop_timer: float = 0.0
var hop_interval: float = 1.0
var hop_duration: float = 0.35
var hop_speed: float = 200.0
var hop_time_left: float = 0.0
var hop_direction: Vector2 = Vector2.ZERO


func _ready() -> void:
	super._ready()
	move_speed = 0.0  # Movement handled by hop system
	max_hp = 25.0
	current_hp = max_hp
	contact_damage = 8.0
	xp_value = 2.0
	xp_tier = 1  # Blue gem
	gold_min = 1
	gold_max = 2
	hop_timer = randf_range(0.0, 0.5)  # Stagger first hop
	death_particle_color = Color(0.3, 0.85, 0.25)  # Green particles


func _physics_process(delta: float) -> void:
	if not is_alive or not is_instance_valid(player):
		return

	hop_timer += delta

	if hop_timer >= hop_interval and hop_time_left <= 0.0:
		hop_timer = 0.0
		hop_time_left = hop_duration
		hop_direction = (player.global_position - global_position).normalized()
		# Squash down before jumping
		var tween: Tween = create_tween()
		tween.tween_property($Body, "scale", Vector2(1.8, 1.2), 0.08)
		tween.tween_property($Body, "scale", Vector2(1.3, 1.9), 0.1)
		tween.tween_property($Body, "scale", Vector2(1.6, 1.6), 0.17)

	if hop_time_left > 0.0:
		var t: float = hop_time_left / hop_duration
		velocity = hop_direction * hop_speed * t
		hop_time_left -= delta
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# Contact damage (from EnemyBase logic)
	damage_cooldown -= delta
	if damage_cooldown <= 0:
		for i: int in get_slide_collision_count():
			var collision: KinematicCollision2D = get_slide_collision(i)
			var collider: Object = collision.get_collider()
			if collider == player and player.is_alive:
				var dmg: float = contact_damage
				if GameState.damage_taken_mult != 1.0:
					dmg *= GameState.damage_taken_mult
				player.take_damage(dmg)
				damage_cooldown = damage_interval
				break
