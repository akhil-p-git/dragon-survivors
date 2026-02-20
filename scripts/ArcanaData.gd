extends RefCounted
class_name ArcanaData
## Defines a single Arcana card (run modifier)

var arcana_name: String = ""
var description: String = ""
var icon_color: Color = Color.PURPLE
var modifiers: Dictionary = {}  # stat_name: float_value
var unlock_condition: String = ""  # Description of how to unlock


static func create(p_name: String, p_desc: String, p_color: Color, p_modifiers: Dictionary, p_unlock: String = "") -> ArcanaData:
	var data = ArcanaData.new()
	data.arcana_name = p_name
	data.description = p_desc
	data.icon_color = p_color
	data.modifiers = p_modifiers
	data.unlock_condition = p_unlock
	return data
