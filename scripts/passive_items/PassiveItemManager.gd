extends Node
class_name PassiveItemManager
## Manages all passive items the player has collected during a run.
## Tracks item levels, computes aggregate bonuses, and applies them to the player.

# Registry of all available passive item definitions keyed by item_name.
var _item_registry: Dictionary = {}

# Currently owned items: { item_name: int(level) }
var _owned_items: Dictionary = {}

# Cached aggregate bonuses (recomputed on any change)
var damage_multiplier: float = 1.0
var armor_bonus: float = 0.0
var move_speed_multiplier: float = 1.0
var max_hp_multiplier: float = 1.0
var extra_projectiles: int = 0
var cooldown_multiplier: float = 1.0

signal passive_items_changed


func _ready() -> void:
	_register_all_items()


func _register_all_items() -> void:
	_register(PassiveItemData.create(
		"Spinach",
		"+10% damage per level",
		Color(0.13, 0.55, 0.13),  # Dark green
		0.10,  # damage_mult_per_level
	))
	_register(PassiveItemData.create(
		"Armor",
		"+1 damage reduction per level",
		Color(0.66, 0.66, 0.66),  # Silver/gray
		0.0, 1.0,  # armor_per_level
	))
	_register(PassiveItemData.create(
		"Wings",
		"+8% move speed per level",
		Color(0.53, 0.81, 0.92),  # Light blue
		0.0, 0.0, 0.08,  # move_speed_mult_per_level
	))
	_register(PassiveItemData.create(
		"Hollow Heart",
		"+10% max HP per level",
		Color(0.86, 0.08, 0.24),  # Crimson red
		0.0, 0.0, 0.0, 0.10,  # max_hp_mult_per_level
	))
	_register(PassiveItemData.create(
		"Duplicator",
		"+1 projectile per level",
		Color(0.93, 0.79, 0.0),  # Gold/yellow
		0.0, 0.0, 0.0, 0.0, 1,  # extra_projectiles_per_level
	))
	_register(PassiveItemData.create(
		"Tome",
		"-8% weapon cooldown per level",
		Color(0.55, 0.27, 0.07),  # Saddle brown
		0.0, 0.0, 0.0, 0.0, 0, 0.08,  # cooldown_mult_per_level
	))


func _register(data: PassiveItemData) -> void:
	_item_registry[data.item_name] = data


## Returns the item data for a registered passive item, or null.
func get_item_data(item_name: String) -> PassiveItemData:
	return _item_registry.get(item_name, null)


## Returns all registered item names.
func get_all_item_names() -> Array:
	return _item_registry.keys()


## Returns the current level of an owned item (0 if not owned).
func get_item_level(item_name: String) -> int:
	return _owned_items.get(item_name, 0)


## Returns true if the item exists and is below max level.
func can_upgrade(item_name: String) -> bool:
	var data = get_item_data(item_name)
	if not data:
		return false
	return get_item_level(item_name) < data.max_level


## Adds or upgrades a passive item by one level. Returns the new level.
func add_or_upgrade_item(item_name: String) -> int:
	var data = get_item_data(item_name)
	if not data:
		push_warning("PassiveItemManager: Unknown item '%s'" % item_name)
		return 0

	var current_level = get_item_level(item_name)
	if current_level >= data.max_level:
		return current_level  # Already maxed

	var new_level = current_level + 1
	_owned_items[item_name] = new_level

	# Sync to GameState for persistence during the run
	GameState.passive_items[item_name] = new_level

	_recalculate_bonuses()
	emit_signal("passive_items_changed")
	return new_level


## Resets all owned items (called at start of a new run).
func reset() -> void:
	_owned_items.clear()
	_recalculate_bonuses()
	emit_signal("passive_items_changed")


## Restores state from GameState (e.g. if PassiveItemManager is recreated mid-run).
func restore_from_game_state() -> void:
	_owned_items = GameState.passive_items.duplicate()
	_recalculate_bonuses()


## Recalculates all aggregate bonuses from owned items.
func _recalculate_bonuses() -> void:
	damage_multiplier = 1.0
	armor_bonus = 0.0
	move_speed_multiplier = 1.0
	max_hp_multiplier = 1.0
	extra_projectiles = 0
	cooldown_multiplier = 1.0

	for item_name in _owned_items:
		var level = _owned_items[item_name]
		var data = get_item_data(item_name)
		if not data or level <= 0:
			continue

		damage_multiplier += data.damage_mult_per_level * level
		armor_bonus += data.armor_per_level * level
		move_speed_multiplier += data.move_speed_mult_per_level * level
		max_hp_multiplier += data.max_hp_mult_per_level * level
		extra_projectiles += data.extra_projectiles_per_level * level
		# Cooldown reduction: each level reduces by a percentage, multiplicatively stacked
		# e.g. Tome level 3 at 8% per level = 1.0 * (1 - 0.08)^3 = ~0.778
		# But for simplicity and matching genre conventions, use additive reduction with a floor
		cooldown_multiplier -= data.cooldown_mult_per_level * level

	# Clamp cooldown multiplier so it never goes below 0.2 (80% max CDR)
	cooldown_multiplier = max(cooldown_multiplier, 0.2)


## Applies all passive bonuses to the player node.
## Should be called after any change, or once per frame if desired.
func apply_to_player(player: CharacterBody2D) -> void:
	if not is_instance_valid(player):
		return

	# Damage multiplier: stored on player for weapons to read
	player.passive_damage_multiplier = damage_multiplier

	# Armor: add passive bonus on top of base
	player.passive_armor_bonus = armor_bonus

	# Move speed: multiply base speed
	player.passive_move_speed_multiplier = move_speed_multiplier

	# Max HP: multiply base max HP and adjust current HP proportionally
	var old_max = player.max_hp
	var new_max = player.base_max_hp * max_hp_multiplier
	if new_max != old_max:
		var hp_ratio = player.current_hp / old_max if old_max > 0 else 1.0
		player.max_hp = new_max
		player.current_hp = min(player.current_hp, new_max)
		# If max increased, heal the difference so the player feels the bonus
		if new_max > old_max:
			player.current_hp = hp_ratio * new_max
		player.emit_signal("hp_changed", player.current_hp, player.max_hp)

	# Extra projectiles: stored on player for weapons to read
	player.passive_extra_projectiles = extra_projectiles

	# Cooldown multiplier: stored on player for weapons to read
	player.passive_cooldown_multiplier = cooldown_multiplier


## Returns an array of dictionaries describing items available for level-up offers.
## Each dict: { "name", "description", "level", "icon_color", "is_new" }
func get_available_upgrades() -> Array:
	var upgrades: Array = []
	for item_name in _item_registry:
		var data = _item_registry[item_name]
		var current_level = get_item_level(item_name)
		if current_level < data.max_level:
			var next_level = current_level + 1
			upgrades.append({
				"type": "passive_item",
				"name": data.item_name,
				"description": data.description + "\n(Lv.%d -> Lv.%d: %s)" % [current_level, next_level, data.get_level_description(next_level)],
				"level": next_level,
				"max_level": data.max_level,
				"icon_color": data.icon_color,
				"is_new": current_level == 0,
			})
	return upgrades
