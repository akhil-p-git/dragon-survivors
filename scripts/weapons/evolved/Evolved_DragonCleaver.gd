extends "res://scripts/weapons/WeaponBase.gd"
## Dragon Cleaver - Evolved Sword Arc + Spinach
## Massive AoE slash with 3x damage, huge arc, triple slash

var sword_arc_scene: PackedScene = preload("res://scenes/weapons/SwordArc.tscn")


func _ready():
	super._ready()
	weapon_name = "Dragon Cleaver"
	base_damage = 45.0  # 3x Sword Arc base
	base_cooldown = 1.0
	level = 5
	max_level = 5


func attack():
	if not is_instance_valid(player):
		return
	var extra = get_extra_projectiles()
	var total = 1 + extra
	# Triple slash in a wide arc
	for wave in range(3):
		var delay = wave * 0.12
		if wave == 0:
			_spawn_wave(total, 0.0)
		else:
			var offset = wave * 0.3
			get_tree().create_timer(delay).timeout.connect(func():
				if is_instance_valid(player):
					_spawn_wave(total, offset)
			)


func _spawn_wave(total: int, angle_shift: float):
	for i in range(total):
		var angle_offset = (i - (total - 1) / 2.0) * 0.5 + angle_shift
		var dir = player.facing_direction.rotated(angle_offset)
		var arc = sword_arc_scene.instantiate()
		arc.damage = get_damage()
		arc.global_position = player.global_position
		arc.rotation = dir.angle() + PI / 2
		arc.scale = Vector2(2.2, 2.2)  # Much larger
		arc.modulate = Color(1.0, 0.4, 0.1, 0.9)  # Orange-red tint
		get_tree().current_scene.get_node("Projectiles").add_child(arc)
