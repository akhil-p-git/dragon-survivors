extends Area2D

var damage: float = 15.0
var lifetime: float = 0.3
var has_hit: Dictionary = {}  # Track which enemies were hit


func _ready():
	collision_layer = 4  # PlayerWeapons layer (Layer 3)
	collision_mask = 2   # Detect Enemies (Layer 2)
	body_entered.connect(_on_body_entered)
	# Auto-free after lifetime
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _on_body_entered(body):
	if body.is_in_group("enemies") and not has_hit.has(body.get_instance_id()):
		has_hit[body.get_instance_id()] = true
		body.take_damage(damage)
