extends Node

var player_level: int = 1
var player_xp: float = 0.0
var xp_to_next_level: float = 10.0
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

signal level_up(new_level: int)
signal xp_changed(current: float, needed: float)
signal game_time_updated(time: float)


func _ready():
	pass


func start_game():
	player_level = 1
	player_xp = 0.0
	xp_to_next_level = 10.0
	game_time = 0.0
	enemies_killed = 0
	is_game_active = true
	weapons.clear()
	buffs.clear()
	passive_items.clear()


func add_xp(amount: float):
	player_xp += amount
	emit_signal("xp_changed", player_xp, xp_to_next_level)
	while player_xp >= xp_to_next_level:
		player_xp -= xp_to_next_level
		player_level += 1
		xp_to_next_level = 10.0 + (player_level * 5.0)
		emit_signal("level_up", player_level)
		emit_signal("xp_changed", player_xp, xp_to_next_level)


func _process(delta):
	if is_game_active:
		game_time += delta
		emit_signal("game_time_updated", game_time)
