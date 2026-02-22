extends Area2D
## Quicksand patch — slows player by 50% while they stand in it.

var _lifetime: float = 0.0
var max_lifetime: float = 15.0
var _player_inside: bool = false
var _slow_applied: bool = false
var _pulse_timer: float = 0.0
var _swirl_dots: Array[ColorRect] = []

const SLOW_MULTIPLIER: float = 0.5

var _glow: Sprite2D


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
	var size: int = 72
	var half: float = size / 2.0
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(half, half)
	for x in range(size):
		for y in range(size):
			var dist: float = Vector2(x, y).distance_to(center) / half
			if dist <= 0.7:
				img.set_pixel(x, y, Color(0.6, 0.5, 0.2, 0.75))
			elif dist <= 0.9:
				var alpha: float = (1.0 - dist) * 1.5
				img.set_pixel(x, y, Color(0.55, 0.45, 0.18, alpha))
			elif dist <= 1.0:
				var alpha: float = (1.0 - dist) * 2.0
				img.set_pixel(x, y, Color(0.45, 0.38, 0.15, alpha))
	_glow.texture = ImageTexture.create_from_image(img)
	_glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_glow.z_index = -1
	add_child(_glow)

	# Dark swirl dots that rotate
	for i in range(6):
		var dot: ColorRect = ColorRect.new()
		dot.size = Vector2(5, 5)
		dot.color = Color(0.4, 0.3, 0.1, 0.8)
		dot.z_index = 0
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dot)
		_swirl_dots.append(dot)


func _setup_collision() -> void:
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 32.0
	shape.shape = circle
	add_child(shape)


func _process(delta: float) -> void:
	_lifetime += delta
	if _lifetime >= max_lifetime:
		if _slow_applied:
			_remove_slow()
		var tween: Tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)
		set_process(false)
		return

	# Swirling dot animation
	_pulse_timer += delta
	for i in range(_swirl_dots.size()):
		var angle: float = _pulse_timer * 1.5 + i * TAU / _swirl_dots.size()
		var radius: float = 12.0 + sin(_pulse_timer * 0.8 + i) * 4.0
		_swirl_dots[i].position = Vector2(cos(angle) * radius, sin(angle) * radius)

	# Subtle pulse on the glow
	var pulse: float = 1.0 + sin(_pulse_timer * 2.0) * 0.04
	_glow.scale = Vector2(pulse, pulse)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		_apply_slow(body)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		_remove_slow()


func _apply_slow(player: Node2D = null) -> void:
	if _slow_applied:
		return
	if not player:
		player = get_tree().current_scene.get_node_or_null("Player")
	if player and "move_speed" in player:
		player.move_speed *= SLOW_MULTIPLIER
		_slow_applied = true


func _remove_slow() -> void:
	if not _slow_applied:
		return
	var player: Node = get_tree().current_scene.get_node_or_null("Player")
	if player and "move_speed" in player:
		player.move_speed /= SLOW_MULTIPLIER
	_slow_applied = false


func _exit_tree() -> void:
	if _slow_applied:
		_remove_slow()
