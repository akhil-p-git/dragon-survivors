extends Area2D

var damage: float = 20.0
var direction: Vector2 = Vector2.RIGHT
var speed: float = 350.0
var aoe_radius: float = 60.0
var lifetime: float = 2.5


func _ready():
	collision_layer = 4  # PlayerWeapons (Layer 3)
	collision_mask = 2   # Enemies (Layer 2)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta):
	position += direction * speed * delta


func _on_body_entered(body):
	if body.is_in_group("enemies"):
		_explode()


func _explode():
	# AoE damage to all enemies in radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e.is_alive:
			var dist = global_position.distance_to(e.global_position)
			if dist <= aoe_radius:
				e.take_damage(damage)
	# Visual explosion effect - scale up then free
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(3, 3), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)
	# Disable further collisions
	collision_layer = 0
	collision_mask = 0
