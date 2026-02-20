extends Node
## Persistent save data across runs: gold, permanent upgrades, character unlocks, arcana unlocks.

const SAVE_PATH = "user://save_data.json"

# Gold
var gold: int = 0

# Permanent upgrades: { "upgrade_name": rank (0-5) }
var upgrades: Dictionary = {}

# Unlocked characters: { "character_name": true }
var unlocked_characters: Dictionary = {
	"knight": true,
	"archer": true,
}

# Unlocked arcana: { "arcana_name": true }
var unlocked_arcanas: Dictionary = {}

# Upgrade definitions: { name: { "max_rank": int, "costs": [int], "stat": String, "value_per_rank": float } }
var upgrade_defs: Dictionary = {
	"Max Health": {"max_rank": 5, "costs": [100, 200, 300, 400, 500], "stat": "max_hp_mult", "value_per_rank": 0.10},
	"Might": {"max_rank": 5, "costs": [150, 300, 450, 600, 750], "stat": "damage_mult", "value_per_rank": 0.08},
	"Move Speed": {"max_rank": 5, "costs": [100, 200, 300, 400, 500], "stat": "move_speed_mult", "value_per_rank": 0.05},
	"Armor": {"max_rank": 5, "costs": [200, 400, 600, 800, 1000], "stat": "armor_flat", "value_per_rank": 1.0},
	"Cooldown": {"max_rank": 5, "costs": [150, 300, 450, 600, 750], "stat": "cooldown_mult", "value_per_rank": 0.05},
	"Growth": {"max_rank": 5, "costs": [100, 200, 300, 400, 500], "stat": "xp_mult", "value_per_rank": 0.10},
	"Luck": {"max_rank": 5, "costs": [100, 200, 300, 400, 500], "stat": "luck", "value_per_rank": 0.10},
	"Magnet": {"max_rank": 5, "costs": [100, 200, 300, 400, 500], "stat": "magnet_mult", "value_per_rank": 0.15},
}


func _ready():
	load_data()


func get_upgrade_rank(upgrade_name: String) -> int:
	return upgrades.get(upgrade_name, 0)


func get_upgrade_cost(upgrade_name: String) -> int:
	var rank = get_upgrade_rank(upgrade_name)
	var def = upgrade_defs.get(upgrade_name)
	if not def or rank >= def.max_rank:
		return -1
	return def.costs[rank]


func buy_upgrade(upgrade_name: String) -> bool:
	var cost = get_upgrade_cost(upgrade_name)
	if cost < 0 or gold < cost:
		return false
	gold -= cost
	upgrades[upgrade_name] = get_upgrade_rank(upgrade_name) + 1
	save_data()
	return true


func get_stat_bonus(stat_name: String) -> float:
	var total: float = 0.0
	for upgrade_name in upgrade_defs:
		var def = upgrade_defs[upgrade_name]
		if def.stat == stat_name:
			total += get_upgrade_rank(upgrade_name) * def.value_per_rank
	return total


func unlock_character(character_name: String, cost: int) -> bool:
	if unlocked_characters.get(character_name, false):
		return true
	if gold < cost:
		return false
	gold -= cost
	unlocked_characters[character_name] = true
	save_data()
	return true


func is_character_unlocked(character_name: String) -> bool:
	return unlocked_characters.get(character_name, false)


func add_gold(amount: int):
	gold += amount
	save_data()


func save_data():
	var data = {
		"gold": gold,
		"upgrades": upgrades,
		"unlocked_characters": unlocked_characters,
		"unlocked_arcanas": unlocked_arcanas,
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func load_data():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(text) != OK:
		return
	var data = json.get_data()
	if data is Dictionary:
		gold = data.get("gold", 0)
		upgrades = data.get("upgrades", {})
		unlocked_characters = data.get("unlocked_characters", {"knight": true, "archer": true})
		unlocked_arcanas = data.get("unlocked_arcanas", {})
