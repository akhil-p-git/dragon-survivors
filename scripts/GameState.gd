extends Node

var player_level: int = 1
var player_xp: float = 0.0
var xp_to_next_level: float = 13.0
var game_time: float = 0.0
var enemies_killed: int = 0
var is_game_active: bool = false
var selected_character: String = "knight"

# Weapon inventory: array of dictionaries {name, level}
var weapons: Array = []
# Buff inventory: dictionary of {buff_name: level}
var buffs: Dictionary = {}
# Passive items: dictionary of {item_name: level} - persists during a run
var passive_items: Dictionary = {}

# Gold collected this run (for display)
var gold_collected: int = 0

# Reroll/Skip/Banish charges
var reroll_charges: int = 3
var skip_charges: int = 2
var banish_charges: int = 3
var banished_items: Array = []  # Items removed from level-up pool this run

# Luck stat (from meta-progression + arcana)
var luck_bonus: float = 0.0

# XP growth multiplier (from meta-progression)
var xp_growth_mult: float = 1.0

# Damage taken multiplier (from arcana)
var damage_taken_mult: float = 1.0

# Life steal percentage (from arcana)
var life_steal: float = 0.0

signal level_up(new_level: int)
signal xp_changed(current: float, needed: float)
signal game_time_updated(time: float)
signal gold_changed(amount: int)


func _ready():
	pass


func start_game():
	player_level = 1
	player_xp = 0.0
	xp_to_next_level = 13.0
	game_time = 0.0
	enemies_killed = 0
	is_game_active = true
	weapons.clear()
	buffs.clear()
	passive_items.clear()
	gold_collected = 0
	reroll_charges = 3
	skip_charges = 2
	banish_charges = 3
	banished_items.clear()
	luck_bonus = SaveData.get_stat_bonus("luck") if SaveData else 0.0
	xp_growth_mult = 1.0 + (SaveData.get_stat_bonus("xp_mult") if SaveData else 0.0)
	damage_taken_mult = 1.0
	life_steal = 0.0


func add_xp(amount: float):
	var boosted = amount * xp_growth_mult
	player_xp += boosted
	emit_signal("xp_changed", player_xp, xp_to_next_level)
	while player_xp >= xp_to_next_level:
		player_xp -= xp_to_next_level
		player_level += 1
		xp_to_next_level = 13.0 + (player_level * 6.5)
		emit_signal("level_up", player_level)
		emit_signal("xp_changed", player_xp, xp_to_next_level)


func _process(delta):
	if is_game_active:
		game_time += delta
		emit_signal("game_time_updated", game_time)
