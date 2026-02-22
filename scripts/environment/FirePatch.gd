extends Area2D
## Fire patch hazard — burns player for 10% max HP on contact, then ticks damage.

var _burn_tick_timer: float = 0.0
var _lifetime: float = 0.0
var max_lifetime: float = 12.0
var _player_inside: bool = false
var _burn_interval: float = 1.0
var _flicker_timer: float = 0.0

# Visual nodes
var _glow: Sprite2D
var _particles: Array[ColorRect] = []


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1  # Detect Player
	add_to_group("hazards")

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_setup_visual()
	_setup_collision()


func _setup_visual() -> void:
	_glow = Sprite2D.new()
	var size: int = 80
	var half: float = size / 2.0
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(half, half)
	for x in range(size):
		for y in range(size):
			var dist: float = Vector2(x, y).distance_to(center) / half
			if dist <= 0.6:
				img.set_pixel(x, y, Color(1.0, 0.5, 0.0, 0.7))
			elif dist <= 0.85:
				var alpha: float = (1.0 - dist) * 0.9
				img.set_pixel(x, y, Color(1.0, 0.3, 0.0, alpha))
			elif dist <= 1.0:
				var alpha: float = (1.0 - dist) * 0.5
				img.set_pixel(x, y, Color(0.8, 0.15, 0.0, alpha))
	_glow.texture = ImageTexture.create_from_image(img)
	_glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_glow.z_index = -1
	add_child(_glow)

	# Flame particles
	for i in range(8):
		var flame: ColorRect = ColorRect.new()
		flame.size = Vector2(6, 10)
		flame.color = Color(1.0, randf_range(0.3, 0.7), 0.0, 0.85)
		flame.position = Vector2(randf_range(-22, 22), randf_range(-22, 14))
		flame.z_index = 0
		flame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(flame)
		_particles.append(flame)


func _setup_collision() -> void:
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 36.0
	shape.shape = circle
	add_child(shape)


func _process(delta: float) -> void:
	_lifetime += delta
	if _lifetime >= max_lifetime:
		var tween: Tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)
		set_process(false)
		return

	# Flicker animation
	_flicker_timer += delta
	for i in range(_particles.size()):
		var flame: ColorRect = _particles[i]
		flame.position.y = -14 + sin(_flicker_timer * 4.0 + i * 1.5) * 10.0
		flame.color.a = 0.6 + sin(_flicker_timer * 6.0 + i * 2.0) * 0.3

	# Burn ticking
	if _player_inside:
		_burn_tick_timer += delta
		if _burn_tick_timer >= _burn_interval:
			_burn_tick_timer = 0.0
			_apply_burn()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		_burn_tick_timer = 0.0
		_apply_burn()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false


func _apply_burn() -> void:
	var player: Node = get_tree().current_scene.get_node_or_null("Player")
	if player and player.is_alive:
		var burn_damage: float = player.max_hp * 0.10
		player.take_damage(burn_damage)
