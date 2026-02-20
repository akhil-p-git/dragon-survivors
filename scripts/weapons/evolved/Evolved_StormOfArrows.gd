extends "res://scripts/weapons/WeaponBase.gd"
## Storm of Arrows - Evolved Arrow Shot + Wings
## Rapid-fire barrage of 8 arrows in a spread

var arrow_scene: PackedScene = preload("res://scenes/weapons/Arrow.tscn")


func _ready():
	super._ready()
	weapon_name = "Storm of Arrows"
	base_damage = 18.0
	base_cooldown = 0.6
	level = 5
	max_level = 5


func attack():
	if not is_instance_valid(player):
		return
	var direction = player.facing_direction
	var extra = get_extra_projectiles()
	var total = 8 + extra
	for i in range(total):
		var angle_offset = (i - (total - 1) / 2.0) * 0.12
		var dir = direction.rotated(angle_offset)
		var arrow = arrow_scene.instantiate()
		arrow.damage = get_damage()
		arrow.direction = dir
		arrow.pierce_count = 8
		arrow.speed = 600.0
		arrow.global_position = player.global_position
		arrow.rotation = dir.angle()
		arrow.modulate = Color(0.5, 1.0, 0.5, 0.9)  # Green tint
		get_tree().current_scene.get_node("Projectiles").add_child(arrow)
