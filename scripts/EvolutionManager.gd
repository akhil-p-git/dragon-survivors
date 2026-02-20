extends Node
class_name EvolutionManager
## Tracks weapon evolution eligibility and handles evolving weapons.

# Evolution registry: weapon_name -> { passive_item, evolved_name, evolved_script }
var evolution_pairs: Dictionary = {
	"Sword Arc": {"passive": "Spinach", "evolved_name": "Dragon Cleaver", "evolved_script": "res://scripts/weapons/evolved/Evolved_DragonCleaver.gd"},
	"Arrow Shot": {"passive": "Wings", "evolved_name": "Storm of Arrows", "evolved_script": "res://scripts/weapons/evolved/Evolved_StormOfArrows.gd"},
	"Fireball": {"passive": "Tome", "evolved_name": "Inferno", "evolved_script": "res://scripts/weapons/evolved/Evolved_Inferno.gd"},
	"Spinning Shield": {"passive": "Armor", "evolved_name": "Fortress", "evolved_script": "res://scripts/weapons/evolved/Evolved_Fortress.gd"},
	"Lightning Strike": {"passive": "Duplicator", "evolved_name": "Thunder Storm", "evolved_script": "res://scripts/weapons/evolved/Evolved_ThunderStorm.gd"},
	"Orbiting Orbs": {"passive": "Hollow Heart", "evolved_name": "Celestial Barrage", "evolved_script": "res://scripts/weapons/evolved/Evolved_CelestialBarrage.gd"},
	"Aura": {"passive": "Wings", "evolved_name": "Tempest Aura", "evolved_script": "res://scripts/weapons/evolved/Evolved_TempestAura.gd"},
}

# Already evolved weapons (can't evolve twice)
var evolved_weapons: Array = []


## Check if any weapon is eligible for evolution.
## Returns the evolution data dict or null.
func get_eligible_evolution(weapon_manager, passive_manager) -> Dictionary:
	if not weapon_manager or not passive_manager:
		return {}
	for weapon in weapon_manager.weapons:
		if not is_instance_valid(weapon):
			continue
		if weapon.weapon_name in evolved_weapons:
			continue
		if weapon.level < weapon.max_level:
			continue
		var evo_data = evolution_pairs.get(weapon.weapon_name, {})
		if evo_data.is_empty():
			continue
		var required_passive = evo_data.passive
		if passive_manager.get_item_level(required_passive) > 0:
			return {"weapon": weapon, "data": evo_data}
	return {}


## Perform the evolution: replace the base weapon with the evolved version.
func evolve_weapon(weapon_manager, weapon, evo_data: Dictionary) -> Node:
	var script_path = evo_data.evolved_script
	var evolved_script = load(script_path)
	if not evolved_script:
		push_warning("EvolutionManager: Could not load evolved script: %s" % script_path)
		return null

	# Create evolved weapon
	var evolved = Node.new()
	evolved.set_script(evolved_script)

	# Replace in weapon manager
	var idx = weapon_manager.weapons.find(weapon)
	weapon.queue_free()
	weapon_manager.add_child(evolved)
	if idx >= 0:
		weapon_manager.weapons[idx] = evolved
	else:
		weapon_manager.weapons.append(evolved)

	evolved_weapons.append(evo_data.evolved_name)
	return evolved
