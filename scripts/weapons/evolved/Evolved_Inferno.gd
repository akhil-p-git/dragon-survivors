extends "res://scripts/weapons/WeaponBase.gd"
## Inferno - Evolved Fireball + Tome
## Triple giant fireballs that leave burning ground

var fireball_scene: PackedScene = preload("res://scenes/weapons/Fireball.tscn")


func _ready():
	super._ready()
	weapon_name = "Inferno"
	base_damage = 35.0
	base_cooldown = 1.2
	level = 5
	max_level = 5


func attack():
	if not is_instance_valid(player):
		return
	var direction = player.facing_direction
	var extra = get_extra_projectiles()
	var total = 3 + extra
	for i in range(total):
		var angle_offset = (i - (total - 1) / 2.0) * 0.25
		var dir = direction.rotated(angle_offset)
		var fb = fireball_scene.instantiate()
		fb.damage = get_damage()
		fb.aoe_radius = 100.0  # Giant radius
		fb.direction = dir
		fb.speed = 300.0
		fb.global_position = player.global_position
		fb.rotation = dir.angle()
		fb.scale = Vector2(1.8, 1.8)  # Larger
		fb.modulate = Color(1.0, 0.5, 0.0, 0.95)  # Deep orange
		get_tree().current_scene.get_node("Projectiles").add_child(fb)
