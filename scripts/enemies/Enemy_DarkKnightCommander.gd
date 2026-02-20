extends "res://scripts/enemies/EnemyBase.gd"
## Dark Knight Commander mini-boss - charge attack, spawns armored knights

var knight_scene: PackedScene = preload("res://scenes/enemies/Enemy_ArmoredKnight.tscn")
var is_mini_boss: bool = true
var charge_timer: float = 0.0
var charge_interval: float = 4.0
var is_charging: bool = false
var charge_speed: float = 400.0
var charge_direction: Vector2 = Vector2.ZERO
var charge_duration: float = 0.5
var charge_elapsed: float = 0.0
var summon_timer: float = 0.0
var summon_interval: float = 8.0


func _ready():
	super._ready()
	max_hp = 800.0
	current_hp = max_hp
	contact_damage = 25.0
	move_speed = 55.0
	xp_value = 50.0
	chest_drop_chance = 1.0
	death_particle_color = Color(0.3, 0.3, 0.4)
	scale = Vector2(2.5, 2.5)


func _physics_process(delta):
	if not is_alive or not is_instance_valid(player):
		return
	if is_charging:
		charge_elapsed += delta
		velocity = charge_direction * charge_speed
		move_and_slide()
		# Contact damage during charge
		damage_cooldown -= delta
		if damage_cooldown <= 0:
			for i in get_slide_collision_count():
				var collision = get_slide_collision(i)
				var collider = collision.get_collider()
				if collider == player and player.is_alive:
					player.take_damage(contact_damage * 1.5)
					damage_cooldown = damage_interval
					ScreenEffects.shake(ScreenEffects.SHAKE_MEDIUM, 0.2)
					break
		if charge_elapsed >= charge_duration:
			is_charging = false
		return
	# Normal movement
	super._physics_process(delta)
	charge_timer += delta
	summon_timer += delta
	if charge_timer >= charge_interval:
		charge_timer = 0.0
		_start_charge()
	if summon_timer >= summon_interval:
		summon_timer = 0.0
		_summon_knights()


func _start_charge():
	if not is_instance_valid(player):
		return
	is_charging = true
	charge_elapsed = 0.0
	charge_direction = (player.global_position - global_position).normalized()
	# Visual indicator: flash red
	modulate = Color(1.5, 0.3, 0.3, 1.0)
	get_tree().create_timer(0.1).timeout.connect(func():
		if is_instance_valid(self): modulate = Color.WHITE
	)


func _summon_knights():
	for i in range(2):
		var knight = knight_scene.instantiate()
		var offset = Vector2(50, 0).rotated(i * PI)
		knight.global_position = global_position + offset
		var enemies_node = get_tree().current_scene.get_node_or_null("Enemies")
		if enemies_node:
			enemies_node.add_child(knight)


func die():
	is_alive = false
	GameState.enemies_killed += 1
	ScreenEffects.register_enemy_kill()
	ScreenEffects.shake(ScreenEffects.SHAKE_LARGE, 0.4)
	ScreenEffects.hitstop(0.06)
	_drop_xp()
	_maybe_drop_chest()
	_spawn_death_particles()
	_play_death_pop()
