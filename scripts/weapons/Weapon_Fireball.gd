extends "res://scripts/weapons/WeaponBase.gd"

var fireball_scene: PackedScene = preload("res://scenes/weapons/Fireball.tscn")


func _ready():
	super._ready()
	weapon_name = "Fireball"
	base_damage = 20.0
	base_cooldown = 2.0


func attack():
	if not is_instance_valid(player):
		return
	var direction = player.facing_direction
	var extra = get_extra_projectiles()

	if level >= 5:
		# Triple fireball plus extras from Duplicator
		var total = 3 + extra
		for i in range(total):
			var angle_offset = (i - (total - 1) / 2.0) * 0.3
			var dir = direction.rotated(angle_offset)
			_spawn_fireball(dir)
	else:
		# Base fireball plus extras from Duplicator
		var total = 1 + extra
		for i in range(total):
			var angle_offset = (i - (total - 1) / 2.0) * 0.25
			var dir = direction.rotated(angle_offset)
			_spawn_fireball(dir)


func _spawn_fireball(direction: Vector2):
	var fb = fireball_scene.instantiate()
	fb.damage = get_damage()
	fb.aoe_radius = 60.0 + (level - 1) * 10.0
	fb.direction = direction
	fb.speed = 350.0
	fb.global_position = player.global_position
	fb.rotation = direction.angle()
	get_tree().current_scene.get_node("Projectiles").add_child(fb)
