extends "res://scripts/enemies/EnemyBase.gd"

var shoot_timer: float = 0.0
var shoot_interval: float = 2.5
var bone_scene: PackedScene = preload("res://scenes/enemies/BoneProjectile.tscn")


func _ready():
	super._ready()
	move_speed = 50.0
	max_hp = 40.0
	current_hp = max_hp
	contact_damage = 12.0
	xp_value = 5.0
	death_particle_color = Color(0.9, 0.9, 0.85)  # White/bone particles


func _physics_process(delta):
	if not is_alive or not is_instance_valid(player):
		return

	super._physics_process(delta)

	# Shoot bones at player
	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		shoot_timer = 0.0
		_throw_bone()


func _throw_bone():
	if not is_instance_valid(player):
		return
	var bone = bone_scene.instantiate()
	bone.global_position = global_position
	bone.direction = (player.global_position - global_position).normalized()
	get_tree().current_scene.get_node("Projectiles").add_child(bone)
