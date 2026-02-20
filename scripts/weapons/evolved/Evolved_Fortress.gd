extends "res://scripts/weapons/WeaponBase.gd"
## Fortress - Evolved Spinning Shield + Armor
## 8 shields, reflects projectiles, larger orbit

var shields: Array = []
var time_elapsed: float = 0.0
var orbit_radius: float = 120.0
var orbit_speed: float = 4.0


func _ready():
	super._ready()
	weapon_name = "Fortress"
	base_damage = 20.0
	base_cooldown = 0.25
	level = 5
	max_level = 5
	_create_shields()


func _process(delta):
	time_elapsed += delta
	_update_shield_positions()
	cooldown_timer -= delta
	if cooldown_timer <= 0:
		cooldown_timer = get_cooldown()
		_check_shield_hits()


func _create_shields():
	for s in shields:
		if is_instance_valid(s):
			s.queue_free()
	shields.clear()
	var count = 8 + get_extra_projectiles()
	for i in range(count):
		var shield = Area2D.new()
		shield.collision_layer = 4
		shield.collision_mask = 2
		var shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 18.0
		shape.shape = circle
		shield.add_child(shape)
		var sprite = Sprite2D.new()
		sprite.texture = load("res://assets/sprites/shield.png")
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(2.5, 2.5)
		sprite.modulate = Color(1.0, 0.85, 0.3, 0.9)  # Gold tint
		shield.add_child(sprite)
		get_tree().current_scene.get_node("Projectiles").add_child(shield)
		shields.append(shield)


func _update_shield_positions():
	if not is_instance_valid(player):
		return
	var count = shields.size()
	for i in range(count):
		if is_instance_valid(shields[i]):
			var angle = time_elapsed * orbit_speed + (i * TAU / count)
			shields[i].global_position = player.global_position + Vector2(cos(angle) * orbit_radius, sin(angle) * orbit_radius)


func _check_shield_hits():
	for shield in shields:
		if not is_instance_valid(shield):
			continue
		var bodies = shield.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("enemies") and body.is_alive:
				body.take_damage(get_damage())


func attack():
	pass
