extends "res://scripts/enemies/EnemyBase.gd"

var fire_breath_timer: float = 0.0
var fire_breath_interval: float = 4.0
var summon_timer: float = 0.0
var summon_interval: float = 6.0
var is_fire_breathing: bool = false
var slime_scene: PackedScene = preload("res://scenes/enemies/Enemy_Slime.tscn")
var fire_breath_damage: float = 15.0

signal boss_died


func _ready():
	super._ready()
	move_speed = 25.0
	max_hp = 2000.0
	current_hp = max_hp
	contact_damage = 25.0
	xp_value = 100.0
	xp_tier = 4  # Diamond gem
	chest_drop_chance = 1.0  # Always drops a chest
	chest_tier = 3  # Gold chest
	gold_drop_chance = 1.0
	gold_min = 30
	gold_max = 50
	death_particle_color = Color(0.9, 0.35, 0.1)  # Orange/fire particles


func _physics_process(delta):
	if not is_alive or not is_instance_valid(player):
		return

	if not is_fire_breathing:
		super._physics_process(delta)

	fire_breath_timer += delta
	summon_timer += delta

	# Fire breath attack
	var dist = global_position.distance_to(player.global_position)
	if fire_breath_timer >= fire_breath_interval and dist < 400.0:
		fire_breath_timer = 0.0
		_fire_breath()

	# Summon adds
	if summon_timer >= summon_interval:
		summon_timer = 0.0
		_summon_adds()


func _fire_breath():
	is_fire_breathing = true
	# Telegraph: change color briefly
	modulate = Color(1.0, 0.5, 0.0)
	get_tree().create_timer(0.5).timeout.connect(_execute_fire_breath)


func _execute_fire_breath():
	if not is_alive or not is_instance_valid(player):
		is_fire_breathing = false
		modulate = Color.WHITE
		return

	modulate = Color.WHITE
	# Create fire cone Area2D
	var direction = (player.global_position - global_position).normalized()
	var fire = Area2D.new()
	fire.collision_layer = 8   # EnemyProjectiles
	fire.collision_mask = 1    # Player
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(200, 80)
	shape.shape = rect
	shape.position = Vector2(100, 0)
	fire.add_child(shape)
	fire.global_position = global_position
	fire.rotation = direction.angle()
	# Visual
	var poly = Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(0, -20), Vector2(200, -50), Vector2(200, 50), Vector2(0, 20)])
	poly.color = Color(1.0, 0.4, 0.0, 0.7)
	fire.add_child(poly)
	get_tree().current_scene.add_child(fire)

	# Check for player hit after a frame
	fire.body_entered.connect(func(body):
		if body.has_method("take_damage"):
			body.take_damage(fire_breath_damage)
	)

	# Remove fire after duration
	var tween = fire.create_tween()
	tween.tween_property(fire, "modulate:a", 0.0, 0.8)
	tween.tween_callback(fire.queue_free)

	is_fire_breathing = false


func _summon_adds():
	for i in range(4):
		var slime = slime_scene.instantiate()
		var angle = randf() * TAU
		slime.global_position = global_position + Vector2(cos(angle), sin(angle)) * 80.0
		var enemies_node = get_tree().current_scene.get_node_or_null("Enemies")
		if enemies_node:
			enemies_node.add_child(slime)


func die():
	is_alive = false
	GameState.enemies_killed += 1
	ScreenEffects.register_enemy_kill()
	_drop_xp()
	_maybe_drop_chest()
	_spawn_death_particles()
	emit_signal("boss_died")
	# Big screen shake and hit stop for boss death
	ScreenEffects.shake(ScreenEffects.SHAKE_HUGE, 0.4)
	ScreenEffects.hitstop(0.05)
	# Disable collision during death animation
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	# Death effect -- dramatic boss death with particles
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.3)
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.5)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
