extends "res://scripts/weapons/Weapon_ArrowShot.gd"
## Storm of Arrows - Evolved Arrow Shot + Wings
## Rapid-fire barrage of 8 arrows in a spread
## Inherits arrow_scene from Weapon_ArrowShot


func _ready() -> void:
	super._ready()
	weapon_name = "Storm of Arrows"
	base_damage = 18.0
	base_cooldown = 0.6
	level = 5
	max_level = 5


func attack() -> void:
	if not is_instance_valid(player):
		return
	var direction: Vector2 = player.aim_direction
	var extra: int = get_extra_projectiles()
	var total: int = 8 + extra
	for i in range(total):
		var angle_offset: float = (i - (total - 1) / 2.0) * 0.12
		var dir: Vector2 = direction.rotated(angle_offset)
		var arrow: Node = arrow_scene.instantiate()
		arrow.damage = get_damage()
		arrow.direction = dir
		arrow.pierce_count = 8
		arrow.speed = 600.0
		arrow.global_position = player.global_position
		arrow.rotation = dir.angle()
		arrow.modulate = Color(0.5, 1.0, 0.5, 0.9)  # Green tint
		var proj_node: Node = _get_projectiles_node()
		if proj_node:
			proj_node.add_child(arrow)
