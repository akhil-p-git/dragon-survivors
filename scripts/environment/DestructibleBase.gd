extends Area2D
## Base class for destructible map objects (torches, barrels, crystals)

@export var destructible_type: String = "torch"  # torch, barrel, crystal
@export var hp: float = 10.0
@export var max_hp: float = 10.0

var is_destroyed: bool = false


var _hit_cooldown: float = 0.0

func _ready():
	collision_layer = 0
	collision_mask = 4   # Detect PlayerWeapons (layer 3/bit 4)
	add_to_group("destructibles")
	_setup_visual()
	_setup_collision()
	area_entered.connect(_on_area_entered)


func _process(delta):
	if _hit_cooldown > 0:
		_hit_cooldown -= delta


func _on_area_entered(area: Area2D):
	if is_destroyed or _hit_cooldown > 0:
		return
	# Hit by a weapon projectile
	if area.collision_layer & 4:  # PlayerWeapons layer
		var dmg = 10.0
		if "damage" in area:
			dmg = area.damage
		take_damage(dmg)
		_hit_cooldown = 0.3  # Prevent multi-hits from same projectile


func _setup_visual():
	var sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	match destructible_type:
		"torch":
			hp = 10.0
			max_hp = 10.0
			sprite.texture = _load_or_generate("res://assets/sprites/torch.png", Color(0.9, 0.6, 0.1), 10, 16)
		"barrel":
			hp = 25.0
			max_hp = 25.0
			sprite.texture = _load_or_generate("res://assets/sprites/barrel.png", Color(0.5, 0.3, 0.1), 14, 16)
		"crystal":
			hp = 50.0
			max_hp = 50.0
			sprite.texture = _load_or_generate("res://assets/sprites/crystal.png", Color(0.3, 0.5, 1.0), 12, 18)
	sprite.name = "Sprite"
	add_child(sprite)


func _setup_collision():
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(14, 16)
	shape.shape = rect
	add_child(shape)


func take_damage(amount: float):
	if is_destroyed:
		return
	hp -= amount
	# Hit flash
	var sprite = get_node_or_null("Sprite")
	if sprite:
		sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
		get_tree().create_timer(0.06).timeout.connect(func():
			if is_instance_valid(self) and is_instance_valid(sprite):
				sprite.modulate = Color.WHITE
		)
	if hp <= 0:
		_destroy()


func _destroy():
	is_destroyed = true
	_drop_loot()
	_spawn_break_particles()
	queue_free()


func _drop_loot():
	var pickups_node = get_tree().current_scene.get_node_or_null("Pickups")
	if not pickups_node:
		return
	var luck_bonus = SaveData.get_stat_bonus("luck") if SaveData else 0.0
	var roll = randf()
	match destructible_type:
		"torch":
			if roll < 0.6 + luck_bonus * 0.1:
				_spawn_gold(randi_range(1, 3))
			else:
				_spawn_xp(1)
		"barrel":
			if roll < 0.4:
				_spawn_gold(randi_range(2, 5))
			elif roll < 0.8:
				_spawn_xp(2)
			elif roll < 0.85 + luck_bonus * 0.05:
				_spawn_floor_pickup("chicken")
		"crystal":
			if roll < 0.4:
				_spawn_gold(randi_range(3, 8))
			elif roll < 0.7:
				_spawn_xp(3)
			elif roll < 0.80 + luck_bonus * 0.1:
				_spawn_floor_pickup("magnet")


func _spawn_gold(amount: int):
	var GoldCoinScript = load("res://scripts/pickups/GoldCoin.gd")
	for i in range(amount):
		var coin = Area2D.new()
		coin.set_script(GoldCoinScript)
		coin.gold_value = 1
		coin.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))
		var pickups = get_tree().current_scene.get_node_or_null("Pickups")
		if pickups:
			pickups.add_child(coin)


func _spawn_xp(tier: int):
	var orb_scene = preload("res://scenes/pickups/XPOrb.tscn")
	var orb = orb_scene.instantiate()
	orb.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	orb.xp_tier = tier
	var pickups = get_tree().current_scene.get_node_or_null("Pickups")
	if pickups:
		pickups.add_child(orb)


func _spawn_floor_pickup(pickup_type: String):
	var FloorPickupScript = load("res://scripts/pickups/FloorPickup.gd")
	var pickup = Area2D.new()
	pickup.set_script(FloorPickupScript)
	pickup.pickup_type = pickup_type
	pickup.global_position = global_position
	var pickups = get_tree().current_scene.get_node_or_null("Pickups")
	if pickups:
		pickups.add_child(pickup)


func _spawn_break_particles():
	var color: Color
	match destructible_type:
		"torch": color = Color(0.9, 0.6, 0.1)
		"barrel": color = Color(0.5, 0.3, 0.1)
		"crystal": color = Color(0.3, 0.5, 1.0)
		_: color = Color.GRAY
	var DeathParticlesScript = load("res://scripts/enemies/DeathParticles.gd")
	var particles = Node2D.new()
	particles.set_script(DeathParticlesScript)
	particles.particle_color = color
	particles.global_position = global_position
	get_tree().current_scene.add_child(particles)


func _load_or_generate(path: String, color: Color, w: int, h: int) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var center = Vector2(w / 2.0, h / 2.0)
	for x in range(w):
		for y in range(h):
			var dist = Vector2(x, y).distance_to(center) / (min(w, h) / 2.0)
			if dist <= 1.0:
				var shade = color.darkened(dist * 0.3)
				img.set_pixel(x, y, shade)
			elif dist <= 1.2:
				img.set_pixel(x, y, Color.BLACK)
	return ImageTexture.create_from_image(img)
