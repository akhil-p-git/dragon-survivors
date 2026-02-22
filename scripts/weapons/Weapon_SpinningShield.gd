extends "res://scripts/weapons/WeaponBase.gd"

var _shield_texture: Texture2D = preload("res://assets/sprites/shield.png")
var shield_count: int = 2
var orbit_radius: float = 80.0
var orbit_speed: float = 3.0
var shields: Array = []
var time_elapsed: float = 0.0


func _ready() -> void:
	super._ready()
	weapon_name = "Spinning Shield"
	base_damage = 8.0
	base_cooldown = 0.3  # Damage tick rate
	_create_shields()


func _process(delta: float) -> void:
	time_elapsed += delta
	_update_shield_positions()
	# Damage enemies touching shields
	cooldown_timer -= delta
	if cooldown_timer <= 0:
		cooldown_timer = get_cooldown()
		_check_shield_hits()


func _create_shields() -> void:
	for s in shields:
		if is_instance_valid(s):
			s.queue_free()
	shields.clear()

	var count: int = shield_count + (level - 1) + get_extra_projectiles()  # More shields per level + Duplicator
	for i in range(count):
		var shield: Area2D = Area2D.new()
		shield.collision_layer = 4  # PlayerWeapons
		shield.collision_mask = 2   # Enemies
		var shape: CollisionShape2D = CollisionShape2D.new()
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = 12.0 + level * 2.0
		shape.shape = circle
		shield.add_child(shape)
		# Visual — shield sprite
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = _shield_texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var scale_factor: float = (12.0 + level * 2.0) / 8.0  # Scale relative to base sprite size
		sprite.scale = Vector2(scale_factor, scale_factor)
		shield.add_child(sprite)
		var proj_node: Node = _get_projectiles_node()
		if proj_node:
			proj_node.add_child(shield)
		shields.append(shield)


func _update_shield_positions() -> void:
	if not is_instance_valid(player):
		return
	var count: int = shields.size()
	for i in range(count):
		if is_instance_valid(shields[i]):
			var angle: float = time_elapsed * orbit_speed + (i * TAU / count)
			var radius: float = orbit_radius + level * 10.0
			shields[i].global_position = player.global_position + Vector2(cos(angle) * radius, sin(angle) * radius)


func _check_shield_hits() -> void:
	for shield in shields:
		if not is_instance_valid(shield):
			continue
		var bodies: Array[Node2D] = shield.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("enemies") and body.is_alive:
				body.take_damage(get_damage())


func level_up() -> void:
	super.level_up()
	_create_shields()  # Recreate shields with new count/size


func _exit_tree() -> void:
	for s in shields:
		if is_instance_valid(s):
			s.queue_free()
	shields.clear()


func attack() -> void:
	pass  # Shields do continuous damage via _check_shield_hits
