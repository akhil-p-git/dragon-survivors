extends Node
## Manages arcana cards: registration, selection, application

var all_arcanas: Array = []  # Array of ArcanaData
var active_arcanas: Array = []  # Array of ArcanaData selected this run
var selection_times: Array = [0.0, 600.0, 1200.0]  # Game time triggers
var selections_done: int = 0

signal arcana_selection_ready(choices: Array)


func _ready() -> void:
	_register_all()


func _register_all() -> void:
	all_arcanas = [
		ArcanaData.create(
			"Fury of the Dragon",
			"+30% weapon damage, but take +20% more damage",
			Color(1.0, 0.3, 0.1),
			{"damage_mult": 0.30, "damage_taken_mult": 0.20},
			"Kill 500 enemies total"
		),
		ArcanaData.create(
			"Swiftness",
			"+40% move and attack speed, -20% weapon damage",
			Color(0.3, 0.8, 1.0),
			{"move_speed_mult": 0.40, "cooldown_mult": -0.40, "damage_mult": -0.20},
			"Reach level 15 in a single run"
		),
		ArcanaData.create(
			"Vampirism",
			"1% of damage dealt returned as HP",
			Color(0.8, 0.1, 0.1),
			{"life_steal": 0.01},
			"Survive 10 minutes"
		),
		ArcanaData.create(
			"Lucky Star",
			"+50% luck, better chest drops",
			Color(1.0, 0.9, 0.2),
			{"luck": 0.50},
			"Open 20 chests total"
		),
		ArcanaData.create(
			"Army of One",
			"+1 projectile to all weapons, -15% damage",
			Color(0.5, 0.3, 1.0),
			{"extra_projectiles": 1, "damage_mult": -0.15},
			"Own 5 weapons in a single run"
		),
		ArcanaData.create(
			"Glass Cannon",
			"+100% damage, max HP capped at 50",
			Color(1.0, 0.5, 0.5),
			{"damage_mult": 1.0, "max_hp_cap": 50.0},
			"Kill a boss"
		),
	]


func get_unlocked_arcanas() -> Array:
	var unlocked: Array = []
	for arcana in all_arcanas:
		if SaveData.unlocked_arcanas.get(arcana.arcana_name, false):
			unlocked.append(arcana)
	# Default: first 3 are always available
	if unlocked.size() < 3:
		unlocked = all_arcanas.slice(0, 3)
	return unlocked


func get_random_choices(count: int = 3) -> Array:
	var pool = get_unlocked_arcanas()
	# Remove already active arcanas
	var filtered: Array = []
	for a in pool:
		var already_active = false
		for active in active_arcanas:
			if active.arcana_name == a.arcana_name:
				already_active = true
				break
		if not already_active:
			filtered.append(a)
	filtered.shuffle()
	return filtered.slice(0, min(count, filtered.size()))


func select_arcana(arcana: ArcanaData) -> void:
	active_arcanas.append(arcana)
	selections_done += 1


func check_selection_trigger(game_time: float) -> bool:
	if selections_done >= selection_times.size():
		return false
	if game_time >= selection_times[selections_done]:
		return true
	return false


## Apply only the most recently selected arcana's modifiers (call after select_arcana).
func apply_latest_arcana_modifiers(player: CharacterBody2D) -> void:
	if not is_instance_valid(player):
		return
	if active_arcanas.is_empty():
		return
	var arcana: ArcanaData = active_arcanas.back()
	_apply_single_arcana(player, arcana)


func _apply_single_arcana(player: CharacterBody2D, arcana: ArcanaData) -> void:
	for stat in arcana.modifiers:
		var value = arcana.modifiers[stat]
		match stat:
			"damage_mult":
				player.passive_damage_multiplier += value
			"move_speed_mult":
				player.passive_move_speed_multiplier += value
			"cooldown_mult":
				player.passive_cooldown_multiplier += value
			"extra_projectiles":
				player.passive_extra_projectiles += int(value)
			"damage_taken_mult":
				GameState.damage_taken_mult += value
			"life_steal":
				GameState.life_steal += value
			"luck":
				GameState.luck_bonus += value
			"max_hp_cap":
				if player.max_hp > value:
					player.max_hp = value
					player.current_hp = min(player.current_hp, value)
					player.emit_signal("hp_changed", player.current_hp, player.max_hp)


func reset() -> void:
	active_arcanas.clear()
	selections_done = 0
