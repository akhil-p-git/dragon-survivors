extends Node

var weapons: Array = []  # Array of weapon scene instances
var max_weapons: int = 6


func _ready() -> void:
	pass


func add_weapon(weapon_scene: PackedScene) -> bool:
	if weapons.size() >= max_weapons:
		return false
	var weapon: Node = weapon_scene.instantiate()
	add_child(weapon)
	weapons.append(weapon)
	return true


func has_weapon(weapon_name: String) -> bool:
	for w in weapons:
		if w.weapon_name == weapon_name:
			return true
	return false


func get_weapon(weapon_name: String) -> Variant:
	for w in weapons:
		if w.weapon_name == weapon_name:
			return w
	return null


func upgrade_weapon(weapon_name: String) -> bool:
	var w: Variant = get_weapon(weapon_name)
	if w and w.level < w.max_level:
		w.level_up()
		return true
	return false
