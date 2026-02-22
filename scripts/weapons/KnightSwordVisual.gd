extends Node2D
## Visual sword attached to the player. Swings in an arc and damages enemies via hitbox.

var _hitbox: Area2D
var _collision: CollisionShape2D
var _swing_tween: Tween
var _is_swinging: bool = false
var _current_damage: float = 0.0
var _hit_enemies: Dictionary = {}
var player: CharacterBody2D

# Sword dimensions (large, as requested)
const BLADE_LENGTH: float = 48.0
const BLADE_WIDTH: float = 12.0
const HANDLE_LENGTH: float = 10.0
const HITBOX_WIDTH: float = 30.0

# Swing arc (radians from center)
const SWING_HALF_ARC: float = 1.3
const SWING_DURATION: float = 0.22


func _ready() -> void:
	z_index = 1
	# Hitbox Area2D — enabled only during swings
	_hitbox = Area2D.new()
	_hitbox.collision_layer = 4   # PlayerWeapons
	_hitbox.collision_mask = 2    # Enemies
	_hitbox.monitoring = false
	add_child(_hitbox)

	_collision = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(BLADE_LENGTH, HITBOX_WIDTH)
	_collision.shape = shape
	_collision.position = Vector2(HANDLE_LENGTH + BLADE_LENGTH / 2.0, 0)
	_hitbox.add_child(_collision)

	_hitbox.body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	if not _is_swinging and is_instance_valid(player):
		var target: float = player.aim_direction.angle()
		rotation = lerp_angle(rotation, target, 0.15)


func _draw() -> void:
	# Handle
	draw_rect(Rect2(0, -4, HANDLE_LENGTH, 8), Color(0.55, 0.35, 0.15))
	# Cross guard
	draw_rect(Rect2(HANDLE_LENGTH - 2, -9, 4, 18), Color(0.85, 0.7, 0.2))
	# Blade (tapered polygon)
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(HANDLE_LENGTH + 2, -BLADE_WIDTH / 2.0),
		Vector2(HANDLE_LENGTH + BLADE_LENGTH * 0.85, -3),
		Vector2(HANDLE_LENGTH + BLADE_LENGTH, 0),
		Vector2(HANDLE_LENGTH + BLADE_LENGTH * 0.85, 3),
		Vector2(HANDLE_LENGTH + 2, BLADE_WIDTH / 2.0),
	])
	draw_colored_polygon(pts, Color(0.78, 0.82, 0.9))
	# Edge highlight
	draw_line(
		Vector2(HANDLE_LENGTH + 2, -BLADE_WIDTH / 2.0),
		Vector2(HANDLE_LENGTH + BLADE_LENGTH, 0),
		Color(1.0, 1.0, 1.0, 0.5), 1.5
	)


func swing(damage: float, direction: Vector2, scale_bonus: float = 1.0, arc_bonus: float = 0.0) -> void:
	_current_damage = damage
	_hit_enemies.clear()
	_is_swinging = true
	_hitbox.monitoring = true

	if _swing_tween and _swing_tween.is_valid():
		_swing_tween.kill()

	scale = Vector2(scale_bonus, scale_bonus)

	var half_arc: float = SWING_HALF_ARC + arc_bonus * 0.25
	var base_angle: float = direction.angle()
	rotation = base_angle - half_arc

	_swing_tween = create_tween()
	_swing_tween.tween_property(self, "rotation", base_angle + half_arc, SWING_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_swing_tween.tween_callback(_end_swing)


func _end_swing() -> void:
	_hitbox.set_deferred("monitoring", false)
	_is_swinging = false


func _on_body_entered(body: Node2D) -> void:
	if _is_swinging and body.is_in_group("enemies") and not _hit_enemies.has(body.get_instance_id()):
		_hit_enemies[body.get_instance_id()] = true
		# Defer to avoid "flushing queries" error from physics callback
		body.call_deferred("take_damage", _current_damage)
