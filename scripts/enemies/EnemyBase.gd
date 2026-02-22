extends CharacterBody2D

@export var move_speed: float = 80.0
@export var max_hp: float = 30.0
@export var contact_damage: float = 10.0
@export var xp_value: float = 3.0

var chest_drop_chance: float = 0.0  # Override in subclasses
var chest_tier: int = 1  # 1=Bronze, 2=Silver, 3=Gold
var current_hp: float
var is_alive: bool = true
var player: CharacterBody2D
var damage_cooldown: float = 0.0
var damage_interval: float = 0.5  # Contact damage every 0.5s
var death_particle_color: Color = Color(0.7, 0.7, 0.7)  # Override in subclasses

# Critical hit settings
# Preloaded resources (avoid load() on every death)
var _DeathParticlesScript: GDScript = preload("res://scripts/enemies/DeathParticles.gd")
var _GoldCoinScript: GDScript = preload("res://scripts/pickups/GoldCoin.gd")

var crit_chance: float = 0.10  # 10% base crit chance
var crit_multiplier: float = 2.0  # Crits deal double damage

# Elite enemy settings
var is_elite: bool = false
var base_move_speed: float = 0.0

# Gold drop settings
var gold_drop_chance: float = 0.20
var gold_min: int = 1
var gold_max: int = 3

# XP gem tier (1=Blue, 2=Green, 3=Red, 4=Diamond)
var xp_tier: int = 1


func _ready() -> void:
	current_hp = max_hp
	base_move_speed = move_speed
	add_to_group("enemies")
	collision_layer = 2  # Enemies layer (Layer 2)
	collision_mask = 33  # Player (1) + Rocks (32)
	player = get_tree().current_scene.get_node_or_null("Player")
	# Elite is applied deferred so subclass _ready() can set stats first
	if is_elite:
		call_deferred("_apply_elite")


func _apply_elite() -> void:
	max_hp *= 2.5
	current_hp = max_hp
	contact_damage *= 1.4
	scale *= 1.5
	xp_tier = min(xp_tier + 1, 3)
	gold_drop_chance = 1.0
	gold_min *= 2
	gold_max *= 3
	# Gold shimmer
	modulate = Color(1.3, 1.0, 0.5, 1.0)


func _physics_process(delta: float) -> void:
	if not is_alive or not is_instance_valid(player):
		return

	# Chase player
	var direction: Vector2 = (player.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

	# Contact damage
	damage_cooldown -= delta
	if damage_cooldown <= 0:
		for i: int in get_slide_collision_count():
			var collision: KinematicCollision2D = get_slide_collision(i)
			var collider: Object = collision.get_collider()
			if collider == player and player.is_alive:
				var dmg: float = contact_damage
				# Apply damage_taken_mult from arcana
				if GameState.damage_taken_mult != 1.0:
					dmg *= GameState.damage_taken_mult
				player.take_damage(dmg)
				damage_cooldown = damage_interval
				break


func take_damage(amount: float) -> void:
	if not is_alive:
		return
	# Roll for critical hit
	var is_crit: bool = randf() < crit_chance
	var final_damage: float = amount * crit_multiplier if is_crit else amount
	current_hp -= final_damage
	_show_damage_number(final_damage, is_crit)
	_hit_flash(is_crit)
	# Life steal from arcana
	if GameState.life_steal > 0 and is_instance_valid(player) and player.is_alive:
		var heal: float = final_damage * GameState.life_steal
		player.heal(heal)
	# Screen shake + hit stop on big hits (25+ damage) or crits
	if final_damage >= 25.0 or is_crit:
		ScreenEffects.shake(ScreenEffects.SHAKE_SMALL, 0.12)
		ScreenEffects.hitstop(0.03)
	if current_hp <= 0:
		die()


func die() -> void:
	is_alive = false
	GameState.enemies_killed += 1
	# Register kill for multi-kill screen shake tracking
	ScreenEffects.register_enemy_kill()
	_on_die()  # Virtual hook for subclass behavior (shake, split, boss signals, etc.)
	_drop_xp()
	_maybe_drop_gold()
	_maybe_drop_chest()
	_spawn_death_particles()
	_death_animation()


## Override in subclasses for extra die behavior (screen shake, splitting, signals).
func _on_die() -> void:
	pass


## Override in subclasses for custom death animations (e.g. Dragon boss).
## Default is the pop-and-free animation.
func _death_animation() -> void:
	_play_death_pop()


## Brief white flash on the Body sprite when hit.
## Uses the sprite's modulate so it does not conflict with the node's own modulate.
func _hit_flash(is_crit: bool = false) -> void:
	var body: Node2D = get_node_or_null("Body")
	if not body:
		# Fallback: modulate the whole node like before
		var original_modulate: Color = modulate
		modulate = Color(4.0, 4.0, 0.5, 1.0) if is_crit else Color.RED
		get_tree().create_timer(0.08).timeout.connect(func():
			if is_instance_valid(self): modulate = original_modulate
		)
		return

	if is_crit:
		# Crits: bright yellow-white flash + scale punch on the sprite
		body.modulate = Color(4.0, 4.0, 1.5, 1.0)
		var base_scale: Vector2 = body.scale
		var punch_tween: Tween = create_tween()
		punch_tween.tween_property(body, "scale", base_scale * 1.3, 0.04)
		punch_tween.tween_property(body, "scale", base_scale, 0.06)
	else:
		# Normal hit: brief bright white flash
		body.modulate = Color(3.0, 3.0, 3.0, 1.0)

	get_tree().create_timer(0.08).timeout.connect(func():
		if is_instance_valid(self) and is_instance_valid(body):
			body.modulate = Color.WHITE
	)


func _spawn_death_particles() -> void:
	var particles: Node2D = Node2D.new()
	particles.set_script(_DeathParticlesScript)
	particles.particle_color = death_particle_color
	particles.global_position = global_position
	get_tree().current_scene.add_child(particles)


func _play_death_pop() -> void:
	# Quick "pop" scale effect on the Body sprite before freeing
	var body: Node2D = get_node_or_null("Body")
	if not body:
		queue_free()
		return
	# Disable collision so the dying enemy does not block anything
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	# Pop: scale up briefly, then shrink to zero and free
	var tween: Tween = create_tween()
	tween.tween_property(body, "scale", body.scale * 1.4, 0.06).set_ease(Tween.EASE_OUT)
	tween.tween_property(body, "scale", Vector2.ZERO, 0.1).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(queue_free)


func _maybe_drop_chest() -> void:
	if randf() < chest_drop_chance:
		var chest_scene: PackedScene = preload("res://scenes/pickups/Chest.tscn")
		var chest: Node = chest_scene.instantiate()
		chest.global_position = global_position
		chest.chest_tier = chest_tier
		var pickups: Node = get_tree().current_scene.get_node_or_null("Pickups")
		if pickups:
			pickups.add_child(chest)


func _maybe_drop_gold() -> void:
	if randf() < gold_drop_chance:
		var count: int = randi_range(gold_min, gold_max)
		var pickups: Node = get_tree().current_scene.get_node_or_null("Pickups")
		if not pickups:
			return
		for i: int in range(count):
			var coin: Area2D = Area2D.new()
			coin.set_script(_GoldCoinScript)
			coin.gold_value = 1
			coin.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))
			pickups.add_child(coin)


func _drop_xp() -> void:
	var orb_scene: PackedScene = preload("res://scenes/pickups/XPOrb.tscn")
	var orb: Node = orb_scene.instantiate()
	orb.global_position = global_position
	orb.xp_tier = xp_tier
	orb.xp_value = xp_value
	var pickups: Node = get_tree().current_scene.get_node_or_null("Pickups")
	if pickups:
		pickups.add_child(orb)
	else:
		GameState.add_xp(xp_value)  # Fallback


func _show_damage_number(amount: float, is_crit: bool = false) -> void:
	var label: Label = Label.new()
	label.text = str(int(amount))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 100

	# Random offset so numbers don't stack
	var offset_x: float = randf_range(-18, 18)
	var offset_y: float = randf_range(-35, -25)

	if is_crit:
		# Critical hit: yellow, larger font, bolder
		label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.1))  # Bright yellow
		label.add_theme_font_size_override("font_size", 28)
		label.global_position = global_position + Vector2(offset_x, offset_y)

		# Also show "CRIT!" text above the damage number
		_show_crit_label()
	else:
		# Normal hit: white, standard size
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_font_size_override("font_size", 18)
		label.global_position = global_position + Vector2(offset_x, offset_y)

	# Add outline for readability
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)

	get_tree().current_scene.add_child(label)

	# Float up and fade out
	var duration: float = 0.7 if is_crit else 0.6
	var float_distance: float = 50.0 if is_crit else 40.0
	var tween: Tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - float_distance, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "modulate:a", 0.0, duration).set_delay(duration * 0.3)
	if is_crit:
		# Crits start slightly scaled up and settle down for a punch effect
		label.scale = Vector2(1.4, 1.4)
		tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)


func _show_crit_label() -> void:
	var crit_label: Label = Label.new()
	crit_label.text = "CRIT!"
	crit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crit_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.1))  # Red-orange
	crit_label.add_theme_font_size_override("font_size", 14)
	crit_label.add_theme_color_override("font_outline_color", Color.BLACK)
	crit_label.add_theme_constant_override("outline_size", 2)
	crit_label.global_position = global_position + Vector2(randf_range(-8, 8), -50)
	crit_label.z_index = 101
	get_tree().current_scene.add_child(crit_label)

	# Quick pop in, float up, and fade out
	crit_label.scale = Vector2(0.5, 0.5)
	var tween: Tween = crit_label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(crit_label, "scale", Vector2(1.2, 1.2), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(crit_label, "position:y", crit_label.position.y - 30, 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_property(crit_label, "modulate:a", 0.0, 0.5).set_delay(0.15)
	tween.set_parallel(false)
	tween.tween_callback(crit_label.queue_free)
