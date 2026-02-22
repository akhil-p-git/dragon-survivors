extends CharacterBody2D

@export var move_speed: float = 310.0
@export var max_hp: float = 120.0
@export var armor: float = 0.0
@export var pickup_range: float = 100.0

# XP magnet radius -- orbs within this range drift toward the player
@export var base_magnet_range: float = 120.0
## Extra magnet range gained per player level.
@export var magnet_range_per_level: float = 10.0
var magnet_range: float = 100.0

var current_hp: float
var is_alive: bool = true
var facing_direction: Vector2 = Vector2.RIGHT
var aim_direction: Vector2 = Vector2.RIGHT

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

var _attack_tween: Tween = null

signal hp_changed(current_hp: float, max_hp: float)
signal player_died


func _ready() -> void:
	# Apply meta-progression permanent upgrades from SaveData
	if SaveData:
		max_hp *= (1.0 + SaveData.get_stat_bonus("max_hp_mult"))
		move_speed *= (1.0 + SaveData.get_stat_bonus("move_speed_mult"))
		armor += SaveData.get_stat_bonus("armor_flat")
		base_magnet_range *= (1.0 + SaveData.get_stat_bonus("magnet_mult"))

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


func _physics_process(_delta: float) -> void:
	if not is_alive:
		return

	var input_dir: Vector2 = Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		facing_direction = input_dir

	# Aim direction follows the mouse cursor
	var mouse_pos: Vector2 = get_global_mouse_position()
	var to_mouse: Vector2 = (mouse_pos - global_position)
	if to_mouse.length_squared() > 1.0:
		aim_direction = to_mouse.normalized()

	# Apply passive move speed multiplier on top of current move_speed
	var effective_speed: float = move_speed * passive_move_speed_multiplier
	velocity = input_dir * effective_speed
	move_and_slide()


## Returns the total effective armor (base + buff + passive).
func get_total_armor() -> float:
	return armor + passive_armor_bonus


func take_damage(amount: float) -> void:
	if not is_alive:
		return
	var actual_damage: float = max(amount - get_total_armor(), 1.0)
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


func heal(amount: float) -> void:
	current_hp = min(current_hp + amount, max_hp)
	emit_signal("hp_changed", current_hp, max_hp)


## Brief red flash on the Body sprite when the player takes damage.
func _hit_flash() -> void:
	var body: Node = get_node_or_null("Body")
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
func on_level_up(new_level: int) -> void:
	# Grow magnet range with level
	magnet_range = base_magnet_range + magnet_range_per_level * (new_level - 1)
	# Trigger magnet pulse -- attract ALL existing XP orbs instantly
	_magnet_pulse()


## Force-attract every XP orb currently in the scene tree.
func _magnet_pulse() -> void:
	var orbs: Array[Node] = get_tree().get_nodes_in_group("xp_orbs")
	for orb in orbs:
		if is_instance_valid(orb) and orb.has_method("force_attract"):
			orb.force_attract()


## Play a procedural attack animation on the Body sprite.
func play_attack_animation(anim_type: String) -> void:
	var body: Node2D = get_node_or_null("Body")
	if not body:
		return
	if _attack_tween and _attack_tween.is_valid():
		_attack_tween.kill()
		body.scale = Vector2.ONE
		body.rotation = 0.0
		body.position = Vector2.ZERO

	match anim_type:
		"bow_shoot":
			_play_bow_animation(body)
		"sword_swing":
			_play_sword_animation(body)


func _play_bow_animation(body: Node2D) -> void:
	_attack_tween = create_tween()
	# Draw back: squish horizontally, stretch vertically
	_attack_tween.tween_property(body, "scale", Vector2(0.75, 1.2), 0.06)
	# Release: snap forward with overshoot
	_attack_tween.tween_property(body, "scale", Vector2(1.15, 0.85), 0.05).set_trans(Tween.TRANS_BACK)
	# Settle to normal
	_attack_tween.tween_property(body, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_OUT)


func _play_sword_animation(body: Node2D) -> void:
	var dir_sign: float = 1.0 if aim_direction.x >= 0 else -1.0
	_attack_tween = create_tween()
	# Wind up: lean back
	_attack_tween.tween_property(body, "rotation", -0.3 * dir_sign, 0.05)
	# Slash through: swing forward
	_attack_tween.tween_property(body, "rotation", 0.4 * dir_sign, 0.08).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Lunge forward slightly
	_attack_tween.parallel().tween_property(body, "position", aim_direction * 6.0, 0.08).set_ease(Tween.EASE_OUT)
	# Settle back
	_attack_tween.tween_property(body, "rotation", 0.0, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_attack_tween.parallel().tween_property(body, "position", Vector2.ZERO, 0.12).set_ease(Tween.EASE_OUT)
