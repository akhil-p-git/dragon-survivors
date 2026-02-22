extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 250.0
var damage: float = 10.0
var lifetime: float = 4.0
var rotation_speed: float = 10.0


func _ready() -> void:
	collision_layer = 8   # EnemyProjectiles (Layer 4)
	collision_mask = 1    # Player (Layer 1)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	rotation += rotation_speed * delta  # Spinning bone


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
