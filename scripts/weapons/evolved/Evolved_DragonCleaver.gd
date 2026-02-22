extends "res://scripts/weapons/Weapon_SwordArc.gd"
## Dragon Cleaver - Evolved Sword Arc + Spinach
## Massive AoE slash with 3x damage, huge arc, triple slash
## Inherits sword_arc_scene from Weapon_SwordArc


func _ready() -> void:
	super._ready()
	weapon_name = "Dragon Cleaver"
	base_damage = 45.0  # 3x Sword Arc base
	base_cooldown = 1.0
	level = 5
	max_level = 5


func attack() -> void:
	if not is_instance_valid(player):
		return
	var extra: int = get_extra_projectiles()
	var total: int = 1 + extra
	# Triple slash in a wide arc
	for wave in range(3):
		var delay: float = wave * 0.12
		if wave == 0:
			_spawn_wave(total, 0.0)
		else:
			var offset: float = wave * 0.3
			get_tree().create_timer(delay).timeout.connect(func():
				if is_instance_valid(player):
					_spawn_wave(total, offset)
			)


func _spawn_wave(total: int, angle_shift: float) -> void:
	for i in range(total):
		var angle_offset: float = (i - (total - 1) / 2.0) * 0.5 + angle_shift
		var dir: Vector2 = player.aim_direction.rotated(angle_offset)
		var arc: Node = sword_arc_scene.instantiate()
		arc.damage = get_damage()
		arc.global_position = player.global_position
		arc.rotation = dir.angle() + PI / 2
		arc.scale = Vector2(2.2, 2.2)  # Much larger
		arc.modulate = Color(1.0, 0.4, 0.1, 0.9)  # Orange-red tint
		var proj_node: Node = _get_projectiles_node()
		if proj_node:
			proj_node.add_child(arc)
