extends "res://scripts/weapons/Weapon_Fireball.gd"
## Inferno - Evolved Fireball + Tome
## Triple giant fireballs that leave burning ground
## Inherits fireball_scene from Weapon_Fireball


func _ready() -> void:
	super._ready()
	weapon_name = "Inferno"
	base_damage = 35.0
	base_cooldown = 1.2
	level = 5
	max_level = 5


func attack() -> void:
	if not is_instance_valid(player):
		return
	var direction: Vector2 = player.aim_direction
	var extra: int = get_extra_projectiles()
	var total: int = 3 + extra
	for i in range(total):
		var angle_offset: float = (i - (total - 1) / 2.0) * 0.25
		var dir: Vector2 = direction.rotated(angle_offset)
		var fb: Node = fireball_scene.instantiate()
		fb.damage = get_damage()
		fb.aoe_radius = 100.0  # Giant radius
		fb.direction = dir
		fb.speed = 300.0
		fb.global_position = player.global_position
		fb.rotation = dir.angle()
		fb.scale = Vector2(1.8, 1.8)  # Larger
		fb.modulate = Color(1.0, 0.5, 0.0, 0.95)  # Deep orange
		var proj_node: Node = _get_projectiles_node()
		if proj_node:
			proj_node.add_child(fb)
