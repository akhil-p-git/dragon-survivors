extends "res://scripts/enemies/EnemyBase.gd"

var fireball_timer: float = 0.0
var fireball_interval: float = 3.0
var fire_breath_timer: float = 0.0
var fire_breath_interval: float = 8.0
var summon_timer: float = 0.0
var summon_interval: float = 6.0
var is_fire_breathing: bool = false
var slime_scene: PackedScene = preload("res://scenes/enemies/Enemy_Slime.tscn")
var fireball_damage: float = 12.0
var fire_breath_damage: float = 20.0

signal boss_died


func _ready() -> void:
	super._ready()
	move_speed = 45.0
	max_hp = 2000.0
	current_hp = max_hp
	contact_damage = 25.0
	xp_value = 100.0
	xp_tier = 4  # Diamond gem
	chest_drop_chance = 1.0
	chest_tier = 3  # Gold chest
	gold_drop_chance = 1.0
	gold_min = 30
	gold_max = 50
	death_particle_color = Color(0.9, 0.35, 0.1)


func _physics_process(delta: float) -> void:
	if not is_alive or not is_instance_valid(player):
		return

	if not is_fire_breathing:
		super._physics_process(delta)

	fireball_timer += delta
	fire_breath_timer += delta
	summon_timer += delta

	# Fireball — ranged attack, fires regardless of distance
	if fireball_timer >= fireball_interval:
		fireball_timer = 0.0
		_shoot_fireball()

	# Fire breath — close range cone, devastating
	var dist: float = global_position.distance_to(player.global_position)
	if fire_breath_timer >= fire_breath_interval and dist < 350.0:
		fire_breath_timer = 0.0
		_fire_breath()

	# Summon adds
	if summon_timer >= summon_interval:
		summon_timer = 0.0
		_summon_adds()


func _shoot_fireball() -> void:
	if not is_instance_valid(player):
		return
	var direction: Vector2 = (player.global_position - global_position).normalized()

	# Shoot 3 fireballs in a spread
	var count: int = 3
	for i in range(count):
		var angle_offset: float = (i - (count - 1) / 2.0) * 0.25
		var dir: Vector2 = direction.rotated(angle_offset)
		_spawn_fireball(dir)

	# Visual telegraph — brief orange flash
	modulate = Color(1.3, 0.7, 0.3)
	get_tree().create_timer(0.15).timeout.connect(func():
		if is_instance_valid(self): modulate = Color.WHITE
	)


func _spawn_fireball(direction: Vector2) -> void:
	var fb: Area2D = Area2D.new()
	fb.collision_layer = 0
	fb.collision_mask = 1  # Detect Player
	fb.global_position = global_position

	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	fb.add_child(shape)

	# Visual — orange/red circle
	var sprite: Sprite2D = Sprite2D.new()
	var img: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(8, 8)
	for x in range(16):
		for y in range(16):
			var dist: float = Vector2(x, y).distance_to(center) / 8.0
			if dist <= 0.6:
				img.set_pixel(x, y, Color(1.0, 0.9, 0.3, 1.0))
			elif dist <= 1.0:
				img.set_pixel(x, y, Color(1.0, 0.4, 0.0, 1.0 - dist))
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fb.add_child(sprite)

	# Movement + lifetime via metadata
	var speed: float = 280.0
	var lifetime: float = 3.0
	var elapsed: float = 0.0
	var dmg: float = fireball_damage
	var hit: bool = false

	fb.body_entered.connect(func(body: Node2D):
		if not hit and body.is_in_group("player") and body.is_alive:
			hit = true
			body.take_damage(dmg)
			fb.queue_free()
	)

	fb.set_meta("dir", direction)
	fb.set_meta("speed", speed)
	fb.set_meta("lifetime", lifetime)
	fb.set_meta("elapsed", 0.0)
	fb.set_script(_create_fireball_mover())

	var proj_node: Node = get_tree().current_scene.get_node_or_null("Projectiles")
	if proj_node:
		proj_node.add_child(fb)
	else:
		get_tree().current_scene.add_child(fb)


## Returns a tiny inline script for fireball movement.
func _create_fireball_mover() -> GDScript:
	if not _fb_script_cache:
		_fb_script_cache = GDScript.new()
		_fb_script_cache.source_code = """extends Area2D
var dir: Vector2
var speed: float = 280.0
var lifetime: float = 3.0
var _elapsed: float = 0.0
func _ready():
	dir = get_meta("dir")
	speed = get_meta("speed")
	lifetime = get_meta("lifetime")
func _process(delta):
	position += dir * speed * delta
	_elapsed += delta
	if _elapsed >= lifetime:
		queue_free()
"""
		_fb_script_cache.reload()
	return _fb_script_cache

static var _fb_script_cache: GDScript = null


func _fire_breath() -> void:
	is_fire_breathing = true
	# Telegraph: glow red
	modulate = Color(1.5, 0.3, 0.1)
	get_tree().create_timer(0.5).timeout.connect(func():
		if is_instance_valid(self):
			_execute_fire_breath()
	)


func _execute_fire_breath() -> void:
	if not is_alive or not is_instance_valid(player):
		is_fire_breathing = false
		modulate = Color.WHITE
		return

	modulate = Color.WHITE
	var direction: Vector2 = (player.global_position - global_position).normalized()

	# Fire cone
	var fire: Area2D = Area2D.new()
	fire.collision_layer = 0
	fire.collision_mask = 1
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(220, 100)
	shape.shape = rect
	shape.position = Vector2(110, 0)
	fire.add_child(shape)
	fire.global_position = global_position
	fire.rotation = direction.angle()

	# Visual
	var poly: Polygon2D = Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(0, -25), Vector2(220, -60), Vector2(220, 60), Vector2(0, 25)
	])
	poly.color = Color(1.0, 0.4, 0.0, 0.75)
	fire.add_child(poly)

	get_tree().current_scene.add_child(fire)

	fire.body_entered.connect(func(body: Node2D):
		if body.is_in_group("player") and body.is_alive:
			body.take_damage(fire_breath_damage)
	)

	# Fade and remove
	var tween: Tween = fire.create_tween()
	tween.tween_property(fire, "modulate:a", 0.0, 0.8)
	tween.tween_callback(fire.queue_free)

	is_fire_breathing = false
	ScreenEffects.shake(ScreenEffects.SHAKE_MEDIUM, 0.25)


func _summon_adds() -> void:
	for i: int in range(4):
		var slime: Node = slime_scene.instantiate()
		var angle: float = randf() * TAU
		slime.global_position = global_position + Vector2(cos(angle), sin(angle)) * 80.0
		var enemies_node: Node = get_tree().current_scene.get_node_or_null("Enemies")
		if enemies_node:
			enemies_node.add_child(slime)


func _on_die() -> void:
	emit_signal("boss_died")
	ScreenEffects.shake(ScreenEffects.SHAKE_HUGE, 0.4)
	ScreenEffects.hitstop(0.05)


func _death_animation() -> void:
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.3)
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.5)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
