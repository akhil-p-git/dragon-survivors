extends "res://scripts/weapons/Weapon_SpinningShield.gd"
## Fortress - Evolved Spinning Shield + Armor
## 8 shields, larger orbit, gold-tinted
## Inherits _shield_texture, shields, _check_shield_hits, _exit_tree from Weapon_SpinningShield


func _ready() -> void:
	super._ready()
	weapon_name = "Fortress"
	base_damage = 20.0
	base_cooldown = 0.25
	orbit_radius = 120.0
	orbit_speed = 4.0
	level = 5
	max_level = 5
	_create_shields()


func _create_shields() -> void:
	for s in shields:
		if is_instance_valid(s):
			s.queue_free()
	shields.clear()
	var count: int = 8 + get_extra_projectiles()
	for i in range(count):
		var shield: Area2D = Area2D.new()
		shield.collision_layer = 4
		shield.collision_mask = 2
		var shape: CollisionShape2D = CollisionShape2D.new()
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = 18.0
		shape.shape = circle
		shield.add_child(shape)
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = _shield_texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(2.5, 2.5)
		sprite.modulate = Color(1.0, 0.85, 0.3, 0.9)  # Gold tint
		shield.add_child(sprite)
		var proj_node: Node = _get_projectiles_node()
		if proj_node:
			proj_node.add_child(shield)
		shields.append(shield)


## Override to use fixed orbit_radius (no level-based scaling)
func _update_shield_positions() -> void:
	if not is_instance_valid(player):
		return
	var count: int = shields.size()
	for i in range(count):
		if is_instance_valid(shields[i]):
			var angle: float = time_elapsed * orbit_speed + (i * TAU / count)
			shields[i].global_position = player.global_position + Vector2(cos(angle) * orbit_radius, sin(angle) * orbit_radius)
