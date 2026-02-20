extends Area2D

var damage: float = 12.0
var direction: Vector2 = Vector2.RIGHT
var speed: float = 500.0
var pierce_count: int = 1
var lifetime: float = 3.0
var hits: int = 0


func _ready():
	collision_layer = 4  # PlayerWeapons (Layer 3)
	collision_mask = 2   # Enemies (Layer 2)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta):
	position += direction * speed * delta


func _on_body_entered(body):
	if body.is_in_group("enemies") and body.is_alive:
		body.take_damage(damage)
		hits += 1
		if hits >= pierce_count:
			queue_free()
