extends "res://scripts/enemies/EnemyBase.gd"
## Skeleton Lord mini-boss - ranged bone barrage, summons skeletons

var skeleton_scene: PackedScene = preload("res://scenes/enemies/Enemy_Skeleton.tscn")
var bone_scene: PackedScene = preload("res://scenes/enemies/BoneProjectile.tscn")
var is_mini_boss: bool = true
var barrage_timer: float = 0.0
var barrage_interval: float = 3.0
var summon_timer: float = 0.0
var summon_interval: float = 8.0


func _ready() -> void:
	super._ready()
	max_hp = 600.0
	current_hp = max_hp
	contact_damage = 18.0
	move_speed = 60.0
	xp_value = 40.0
	chest_drop_chance = 1.0
	death_particle_color = Color(0.9, 0.9, 0.8)
	scale = Vector2(2.0, 2.0)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not is_alive or not is_instance_valid(player):
		return
	barrage_timer += delta
	summon_timer += delta
	if barrage_timer >= barrage_interval:
		barrage_timer = 0.0
		_bone_barrage()
	if summon_timer >= summon_interval:
		summon_timer = 0.0
		_summon_skeletons()


func _bone_barrage() -> void:
	if not is_instance_valid(player):
		return
	# Fire 6 bones in a spread toward the player
	var dir_to_player: Vector2 = (player.global_position - global_position).normalized()
	for i: int in range(6):
		var angle_offset: float = (i - 2.5) * 0.2
		var dir: Vector2 = dir_to_player.rotated(angle_offset)
		var bone: Node = bone_scene.instantiate()
		bone.global_position = global_position
		bone.direction = dir
		bone.speed = 220.0
		bone.damage = 12.0
		var proj_node: Node = get_tree().current_scene.get_node_or_null("Projectiles")
		if proj_node:
			proj_node.add_child(bone)


func _summon_skeletons() -> void:
	for i: int in range(3):
		var skel: Node = skeleton_scene.instantiate()
		var offset: Vector2 = Vector2(40, 0).rotated(i * TAU / 3.0)
		skel.global_position = global_position + offset
		var enemies_node: Node = get_tree().current_scene.get_node_or_null("Enemies")
		if enemies_node:
			enemies_node.add_child(skel)


func _on_die() -> void:
	ScreenEffects.shake(ScreenEffects.SHAKE_LARGE, 0.3)
	ScreenEffects.hitstop(0.05)
