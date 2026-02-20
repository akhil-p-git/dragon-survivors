extends RefCounted
class_name PassiveItemData
## Defines the static data for a single passive item type.
## Each passive item can be leveled from 1 to max_level.

var item_name: String = ""
var description: String = ""
var icon_color: Color = Color.WHITE
var max_level: int = 5

# Per-level bonus values
var damage_mult_per_level: float = 0.0       # Multiplicative damage bonus per level (e.g. 0.10 = +10%)
var armor_per_level: float = 0.0             # Flat armor per level
var move_speed_mult_per_level: float = 0.0   # Multiplicative move speed bonus per level (e.g. 0.08 = +8%)
var max_hp_mult_per_level: float = 0.0       # Multiplicative max HP bonus per level (e.g. 0.10 = +10%)
var extra_projectiles_per_level: int = 0     # Extra projectile count per level
var cooldown_mult_per_level: float = 0.0     # Cooldown reduction per level (e.g. 0.08 = -8%)


static func create(
	p_name: String,
	p_description: String,
	p_icon_color: Color,
	p_damage_mult: float = 0.0,
	p_armor: float = 0.0,
	p_move_speed_mult: float = 0.0,
	p_max_hp_mult: float = 0.0,
	p_extra_projectiles: int = 0,
	p_cooldown_mult: float = 0.0,
) -> PassiveItemData:
	var data = PassiveItemData.new()
	data.item_name = p_name
	data.description = p_description
	data.icon_color = p_icon_color
	data.damage_mult_per_level = p_damage_mult
	data.armor_per_level = p_armor
	data.move_speed_mult_per_level = p_move_speed_mult
	data.max_hp_mult_per_level = p_max_hp_mult
	data.extra_projectiles_per_level = p_extra_projectiles
	data.cooldown_mult_per_level = p_cooldown_mult
	return data


func get_level_description(level: int) -> String:
	## Returns a description string showing the total bonus at a given level.
	var parts: Array[String] = []
	if damage_mult_per_level > 0:
		parts.append("+%d%% damage" % int(damage_mult_per_level * level * 100))
	if armor_per_level > 0:
		parts.append("+%d armor" % int(armor_per_level * level))
	if move_speed_mult_per_level > 0:
		parts.append("+%d%% move speed" % int(move_speed_mult_per_level * level * 100))
	if max_hp_mult_per_level > 0:
		parts.append("+%d%% max HP" % int(max_hp_mult_per_level * level * 100))
	if extra_projectiles_per_level > 0:
		parts.append("+%d projectiles" % (extra_projectiles_per_level * level))
	if cooldown_mult_per_level > 0:
		parts.append("-%d%% cooldown" % int(cooldown_mult_per_level * level * 100))
	if parts.size() == 0:
		return description
	return ", ".join(parts)
