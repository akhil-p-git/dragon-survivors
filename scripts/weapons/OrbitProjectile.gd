extends Area2D

var damage: float = 10.0
var hit_cooldown: float = 0.3
var hit_timers: Dictionary = {}


func _ready():
	collision_layer = 4  # PlayerWeapons (Layer 3)
	collision_mask = 2   # Enemies (Layer 2)
	body_entered.connect(_on_body_entered)


func _process(delta):
	# Decrement hit cooldown timers for each enemy
	var expired: Array = []
	for id in hit_timers:
		hit_timers[id] -= delta
		if hit_timers[id] <= 0:
			expired.append(id)
	for id in expired:
		hit_timers.erase(id)


func _on_body_entered(body):
	if body.is_in_group("enemies") and body.is_alive:
		var id = body.get_instance_id()
		if not hit_timers.has(id):
			body.take_damage(damage)
			hit_timers[id] = hit_cooldown
