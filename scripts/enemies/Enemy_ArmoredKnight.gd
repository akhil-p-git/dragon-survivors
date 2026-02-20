extends "res://scripts/enemies/EnemyBase.gd"

var attack_timer: float = 0.0
var attack_interval: float = 3.0
var attack_range: float = 60.0
var is_attacking: bool = false
var telegraph_time: float = 0.8


func _ready():
	super._ready()
	move_speed = 35.0
	max_hp = 120.0
	current_hp = max_hp
	contact_damage = 20.0
	xp_value = 10.0
	xp_tier = 2  # Green gem
	gold_min = 3
	gold_max = 6
	gold_drop_chance = 0.35
	death_particle_color = Color(0.55, 0.55, 0.6)  # Steel/gray particles


func _physics_process(delta):
	if not is_alive or not is_instance_valid(player):
		return

	if is_attacking:
		return  # Don't move during attack

	super._physics_process(delta)

	# Heavy slash attack
	var dist = global_position.distance_to(player.global_position)
	attack_timer += delta
	if dist <= attack_range and attack_timer >= attack_interval:
		attack_timer = 0.0
		_telegraph_attack()


func _telegraph_attack():
	is_attacking = true
	# Visual telegraph — flash red
	modulate = Color(1.0, 0.3, 0.3)
	get_tree().create_timer(telegraph_time).timeout.connect(_execute_attack)


func _execute_attack():
	if not is_alive or not is_instance_valid(player):
		is_attacking = false
		modulate = Color.WHITE
		return

	modulate = Color.WHITE
	var dist = global_position.distance_to(player.global_position)
	if dist <= attack_range * 1.5 and player.is_alive:
		player.take_damage(contact_damage * 2.0)  # Heavy hit
	is_attacking = false
