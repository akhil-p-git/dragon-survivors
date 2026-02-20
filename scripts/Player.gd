extends CharacterBody2D

@export var move_speed: float = 300.0
@export var max_hp: float = 100.0
@export var armor: float = 0.0
@export var pickup_range: float = 100.0

# XP magnet radius -- orbs within this range drift toward the player
@export var base_magnet_range: float = 100.0
## Extra magnet range gained per player level.
@export var magnet_range_per_level: float = 8.0
var magnet_range: float = 100.0

var current_hp: float
var is_alive: bool = true
var facing_direction: Vector2 = Vector2.RIGHT

# Base stats (saved at _ready so passive multipliers can reference them)
var base_move_speed: float
var base_max_hp: float
var base_armor: float

# Passive item bonus properties (written by PassiveItemManager.apply_to_player)
var passive_damage_multiplier: float = 1.0
var passive_armor_bonus: float = 0.0
var passive_move_speed_multiplier: float = 1.0
var passive_extra_projectiles: int = 0
var passive_cooldown_multiplier: float = 1.0

signal hp_changed(current_hp: float, max_hp: float)
signal player_died


func _ready():
	# Store base stats before any passive bonuses are applied
	base_move_speed = move_speed
	base_max_hp = max_hp
	base_armor = armor

	magnet_range = base_magnet_range

	current_hp = max_hp
	add_to_group("player")
	collision_layer = 1
	collision_mask = 34  # Enemies (2) + Rocks (32)
	emit_signal("hp_changed", current_hp, max_hp)


func _physics_process(_delta):
	if not is_alive:
		return

	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		facing_direction = input_dir

	# Apply passive move speed multiplier on top of current move_speed
	var effective_speed = move_speed * passive_move_speed_multiplier
	velocity = input_dir * effective_speed
	move_and_slide()


## Returns the total effective armor (base + buff + passive).
func get_total_armor() -> float:
	return armor + passive_armor_bonus


func take_damage(amount: float):
	if not is_alive:
		return
	var actual_damage = max(amount - get_total_armor(), 1.0)
	current_hp -= actual_damage
	emit_signal("hp_changed", current_hp, max_hp)
	# Hit flash on the Body sprite (red tint)
	_hit_flash()
	# Screen shake -- always a small shake, bigger shake for heavy hits
	ScreenEffects.shake(ScreenEffects.SHAKE_SMALL, 0.15)
	if actual_damage >= 15.0:
		ScreenEffects.shake(ScreenEffects.SHAKE_MEDIUM, 0.2)
		ScreenEffects.hitstop(0.02)
	if current_hp <= 0:
		current_hp = 0
		is_alive = false
		emit_signal("player_died")


func heal(amount: float):
	current_hp = min(current_hp + amount, max_hp)
	emit_signal("hp_changed", current_hp, max_hp)


## Brief red flash on the Body sprite when the player takes damage.
func _hit_flash():
	var body = get_node_or_null("Body")
	if not body:
		# Fallback: tint the whole node
		modulate = Color.RED
		get_tree().create_timer(0.1).timeout.connect(func(): modulate = Color.WHITE)
		return
	body.modulate = Color(2.5, 0.4, 0.4, 1.0)
	get_tree().create_timer(0.1).timeout.connect(func():
		if is_instance_valid(self) and is_instance_valid(body):
			body.modulate = Color.WHITE
	)


## Called when the player levels up.  Grows the magnet radius and triggers a
## brief pulse that pulls every XP orb on screen toward the player.
func on_level_up(new_level: int):
	# Grow magnet range with level
	magnet_range = base_magnet_range + magnet_range_per_level * (new_level - 1)
	# Trigger magnet pulse -- attract ALL existing XP orbs instantly
	_magnet_pulse()


## Force-attract every XP orb currently in the scene tree.
func _magnet_pulse():
	var orbs = get_tree().get_nodes_in_group("xp_orbs")
	for orb in orbs:
		if is_instance_valid(orb) and orb.has_method("force_attract"):
			orb.force_attract()
