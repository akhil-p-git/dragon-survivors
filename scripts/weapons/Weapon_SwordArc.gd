extends "res://scripts/weapons/WeaponBase.gd"

var sword_arc_scene: PackedScene = preload("res://scenes/weapons/SwordArc.tscn")


func _ready() -> void:
	super._ready()
	weapon_name = "Sword Arc"
	base_damage = 18.0
	base_cooldown = 1.0


func attack() -> void:
	if not is_instance_valid(player):
		return
	var extra: int = get_extra_projectiles()
	# Spawn base arc plus extra arcs from Duplicator
	var total: int = 1 + extra
	for i in range(total):
		var angle_offset: float = (i - (total - 1) / 2.0) * 0.4
		var dir: Vector2 = player.aim_direction.rotated(angle_offset)
		_spawn_arc(dir)
	if level >= 5:
		# Double slash - second wave slightly delayed
		get_tree().create_timer(0.15).timeout.connect(func():
			if is_instance_valid(player):
				for j in range(total):
					var ao = (j - (total - 1) / 2.0) * 0.4
					var d = player.aim_direction.rotated(ao)
					_spawn_arc(d)
		)


func _spawn_arc(direction: Vector2) -> void:
	var arc: Node = sword_arc_scene.instantiate()
	arc.damage = get_damage()
	arc.global_position = player.global_position
	arc.rotation = direction.angle() + PI / 2
	# Scale with level
	var scale_bonus: float = 1.0 + (level - 1) * 0.20
	arc.scale = Vector2(scale_bonus, scale_bonus)
	var proj_node: Node = _get_projectiles_node()
	if proj_node:
		proj_node.add_child(arc)
