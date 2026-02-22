extends "res://scripts/weapons/WeaponBase.gd"

var arrow_scene: PackedScene = preload("res://scenes/weapons/Arrow.tscn")


func _ready() -> void:
	super._ready()
	weapon_name = "Arrow Shot"
	base_damage = 14.0
	base_cooldown = 0.8


func attack() -> void:
	if not is_instance_valid(player):
		return
	var direction: Vector2 = player.aim_direction
	var extra: int = get_extra_projectiles()

	if level >= 5:
		# Volley - 3 arrows in a spread, plus extras from Duplicator
		var total: int = 3 + extra
		for i in range(total):
			var angle_offset: float = (i - (total - 1) / 2.0) * 0.2
			var dir: Vector2 = direction.rotated(angle_offset)
			_spawn_arrow(dir)
	else:
		# Base arrow plus extras from Duplicator
		var total: int = 1 + extra
		for i in range(total):
			var angle_offset: float = (i - (total - 1) / 2.0) * 0.15
			var dir: Vector2 = direction.rotated(angle_offset)
			_spawn_arrow(dir)


func _spawn_arrow(direction: Vector2) -> void:
	var arrow: Node = arrow_scene.instantiate()
	arrow.damage = get_damage()
	arrow.direction = direction
	arrow.pierce_count = level + 1  # 2 at level 1, up to 6
	arrow.speed = 550.0
	arrow.global_position = player.global_position
	arrow.rotation = direction.angle()
	var proj_node: Node = _get_projectiles_node()
	if proj_node:
		proj_node.add_child(arrow)
