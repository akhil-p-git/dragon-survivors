extends "res://scripts/weapons/WeaponBase.gd"

var fireball_scene: PackedScene = preload("res://scenes/weapons/Fireball.tscn")


func _ready() -> void:
	super._ready()
	weapon_name = "Fireball"
	base_damage = 22.0
	base_cooldown = 1.6


func attack() -> void:
	if not is_instance_valid(player):
		return
	var direction: Vector2 = player.aim_direction
	var extra: int = get_extra_projectiles()

	if level >= 5:
		# Triple fireball plus extras from Duplicator
		var total: int = 3 + extra
		for i in range(total):
			var angle_offset: float = (i - (total - 1) / 2.0) * 0.3
			var dir: Vector2 = direction.rotated(angle_offset)
			_spawn_fireball(dir)
	else:
		# Base fireball plus extras from Duplicator
		var total: int = 1 + extra
		for i in range(total):
			var angle_offset: float = (i - (total - 1) / 2.0) * 0.25
			var dir: Vector2 = direction.rotated(angle_offset)
			_spawn_fireball(dir)


func _spawn_fireball(direction: Vector2) -> void:
	var fb: Node = fireball_scene.instantiate()
	fb.damage = get_damage()
	fb.aoe_radius = 75.0 + (level - 1) * 12.0
	fb.direction = direction
	fb.speed = 350.0
	fb.global_position = player.global_position
	fb.rotation = direction.angle()
	var proj_node: Node = _get_projectiles_node()
	if proj_node:
		proj_node.add_child(fb)
