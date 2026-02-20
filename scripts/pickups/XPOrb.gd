extends Area2D

var xp_value: float = 2.0
var attract_speed: float = 300.0
var is_attracted: bool = false
var is_magnetized: bool = false
var magnet_speed: float = 0.0
var player: CharacterBody2D

# Magnet pull parameters
const MAGNET_INITIAL_SPEED: float = 40.0
const MAGNET_ACCELERATION: float = 300.0
const MAGNET_MAX_SPEED: float = 250.0
const ATTRACT_ACCELERATION: float = 400.0


func _ready():
	collision_layer = 16  # Pickups layer (layer 5)
	collision_mask = 1    # Detect Player
	add_to_group("xp_orbs")
	area_entered.connect(_on_area_entered)


func _physics_process(delta):
	if not is_instance_valid(player):
		player = get_tree().current_scene.get_node_or_null("Player")
		return

	var dist = global_position.distance_to(player.global_position)

	# Check if within direct pickup range (close) -- instant strong attract
	if not is_attracted and dist <= player.pickup_range:
		is_attracted = true

	# Check if within magnet radius (farther out) -- gentle pull
	if not is_attracted and not is_magnetized and dist <= player.magnet_range:
		is_magnetized = true
		magnet_speed = MAGNET_INITIAL_SPEED

	if is_attracted:
		# Strong attraction -- close range pickup
		var direction = (player.global_position - global_position).normalized()
		position += direction * attract_speed * delta
		attract_speed += ATTRACT_ACCELERATION * delta

		var new_dist = global_position.distance_to(player.global_position)
		if new_dist < 20.0:
			GameState.add_xp(xp_value)
			queue_free()
	elif is_magnetized:
		# Gentle magnet pull -- accelerates smoothly toward player
		var direction = (player.global_position - global_position).normalized()
		magnet_speed = min(magnet_speed + MAGNET_ACCELERATION * delta, MAGNET_MAX_SPEED)
		position += direction * magnet_speed * delta

		# Transition to full attract once close enough
		var new_dist = global_position.distance_to(player.global_position)
		if new_dist <= player.pickup_range:
			is_attracted = true
		elif new_dist < 20.0:
			GameState.add_xp(xp_value)
			queue_free()


## Force this orb into attracted state (used by magnet pulse on level-up).
func force_attract():
	is_attracted = true


func _on_area_entered(area):
	# Also collect if directly touching player's pickup area
	if area.get_parent() == get_tree().current_scene.get_node_or_null("Player"):
		is_attracted = true
