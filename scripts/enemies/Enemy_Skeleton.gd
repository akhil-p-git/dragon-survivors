extends "res://scripts/enemies/EnemyBase.gd"

var shoot_timer: float = 0.0
var shoot_interval: float = 3.0
var bone_scene: PackedScene = preload("res://scenes/enemies/BoneProjectile.tscn")


func _ready() -> void:
	super._ready()
	move_speed = 50.0
	max_hp = 32.0
	current_hp = max_hp
	contact_damage = 10.0
	xp_value = 3.5
	xp_tier = 2  # Green gem
	gold_min = 2
	gold_max = 4
	death_particle_color = Color(0.9, 0.9, 0.85)  # White/bone particles


func _physics_process(delta: float) -> void:
	if not is_alive or not is_instance_valid(player):
		return

	super._physics_process(delta)

	# Shoot bones at player
	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		shoot_timer = 0.0
		_throw_bone()


func _throw_bone() -> void:
	if not is_instance_valid(player):
		return
	var bone: Node = bone_scene.instantiate()
	bone.global_position = global_position
	bone.direction = (player.global_position - global_position).normalized()
	var proj_node: Node = get_tree().current_scene.get_node_or_null("Projectiles")
	if proj_node:
		proj_node.add_child(bone)
