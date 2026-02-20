extends Node2D

## Lightweight code-based death particle effect.
## Spawns small colored squares that burst outward, decelerate, and fade.
## Add as a child of the scene tree at the enemy's death position.

const PARTICLE_COUNT: int = 8
const PARTICLE_SIZE: float = 3.0
const MIN_SPEED: float = 40.0
const MAX_SPEED: float = 120.0
const LIFETIME: float = 0.45
const SPREAD_ANGLE: float = TAU  # Full 360-degree burst

var particle_color: Color = Color(0.4, 0.9, 0.3)  # Default green (slime)


func _ready():
	z_index = 50
	_spawn_particles()


func _spawn_particles():
	for i in range(PARTICLE_COUNT):
		var particle = _create_particle()
		add_child(particle)

		# Random direction in a full circle
		var angle = randf() * SPREAD_ANGLE
		var direction = Vector2(cos(angle), sin(angle))
		var speed = randf_range(MIN_SPEED, MAX_SPEED)
		var target_offset = direction * speed * LIFETIME * 0.6

		# Slight size variation
		var size_scale = randf_range(0.6, 1.4)
		particle.scale = Vector2(size_scale, size_scale)

		# Tween: move outward (decelerating), shrink, and fade
		var tween = particle.create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)

		# Move outward with deceleration
		tween.tween_property(particle, "position", target_offset, LIFETIME)

		# Fade out (starts after a brief delay so particles are visible initially)
		tween.tween_property(particle, "modulate:a", 0.0, LIFETIME * 0.7).set_delay(LIFETIME * 0.3)

		# Shrink toward end of life
		tween.tween_property(particle, "scale", Vector2.ZERO, LIFETIME * 0.5).set_delay(LIFETIME * 0.5)

	# Self-destruct after all particles have faded
	var cleanup_tween = create_tween()
	cleanup_tween.tween_callback(queue_free).set_delay(LIFETIME + 0.05)


func _create_particle() -> Node2D:
	# Create a small colored square using a Polygon2D for pixel-art consistency
	var particle = Polygon2D.new()
	var half = PARTICLE_SIZE / 2.0
	particle.polygon = PackedVector2Array([
		Vector2(-half, -half),
		Vector2(half, -half),
		Vector2(half, half),
		Vector2(-half, half),
	])

	# Slight color variation for visual interest
	var hue_shift = randf_range(-0.05, 0.05)
	var brightness_shift = randf_range(-0.1, 0.15)
	var varied_color = particle_color
	varied_color.h = fmod(varied_color.h + hue_shift, 1.0)
	varied_color.v = clampf(varied_color.v + brightness_shift, 0.2, 1.0)
	particle.color = varied_color

	return particle
