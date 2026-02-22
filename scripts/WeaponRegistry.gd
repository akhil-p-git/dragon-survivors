## Centralized weapon data registry.
## All weapon metadata (sprites, colors, scripts, descriptions) lives here
## so HUD, PauseMenu, and LevelUpUI reference a single source of truth.

const WEAPONS: Dictionary = {
	"Sword Arc": {
		"script": "res://scripts/weapons/Weapon_SwordArc.gd",
		"sprite": "res://assets/sprites/sword_arc.png",
		"color": Color.STEEL_BLUE,
		"description": "Melee arc attack",
	},
	"Arrow Shot": {
		"script": "res://scripts/weapons/Weapon_ArrowShot.gd",
		"sprite": "res://assets/sprites/arrow.png",
		"color": Color.FOREST_GREEN,
		"description": "Ranged piercing arrows",
	},
	"Fireball": {
		"script": "res://scripts/weapons/Weapon_Fireball.gd",
		"sprite": "res://assets/sprites/fireball.png",
		"color": Color.ORANGE_RED,
		"description": "Explosive AoE attack",
	},
	"Spinning Shield": {
		"script": "res://scripts/weapons/Weapon_SpinningShield.gd",
		"sprite": "res://assets/sprites/shield.png",
		"color": Color.SILVER,
		"description": "Orbiting shields damage nearby enemies",
	},
	"Lightning Strike": {
		"script": "res://scripts/weapons/Weapon_LightningStrike.gd",
		"sprite": "res://assets/sprites/lightning.png",
		"color": Color.LIGHT_BLUE,
		"description": "Strikes nearest enemy with lightning from above",
	},
	"Orbiting Orbs": {
		"script": "res://scripts/weapons/Weapon_Orbiting.gd",
		"sprite": "res://assets/sprites/orbit_projectile.png",
		"color": Color.DODGER_BLUE,
		"description": "Magical orbs orbit around you",
	},
	"Aura": {
		"script": "res://scripts/weapons/Weapon_Aura.gd",
		"sprite": "res://assets/sprites/aura.png",
		"color": Color.MEDIUM_SEA_GREEN,
		"description": "Pulsing damage zone around the player",
	},
}

# Evolved weapon visual data — separate so base weapons remain the canonical list
const EVOLVED: Dictionary = {
	"Dragon Cleaver": {"sprite": "res://assets/sprites/sword_arc.png", "color": Color(1.0, 0.5, 0.2)},
	"Storm of Arrows": {"sprite": "res://assets/sprites/arrow.png", "color": Color(0.5, 1.0, 0.5)},
	"Inferno": {"sprite": "res://assets/sprites/fireball.png", "color": Color(1.0, 0.4, 0.0)},
	"Fortress": {"sprite": "res://assets/sprites/shield.png", "color": Color(1.0, 0.85, 0.3)},
	"Thunder Storm": {"sprite": "res://assets/sprites/lightning.png", "color": Color(0.6, 0.4, 1.0)},
	"Celestial Barrage": {"sprite": "res://assets/sprites/orbit_projectile.png", "color": Color(0.6, 0.8, 1.0)},
	"Tempest Aura": {"sprite": "res://assets/sprites/aura.png", "color": Color(0.4, 0.8, 1.0)},
}


static func get_sprite_path(weapon_name: String) -> String:
	if weapon_name in WEAPONS:
		return WEAPONS[weapon_name].sprite
	if weapon_name in EVOLVED:
		return EVOLVED[weapon_name].sprite
	return ""


static func get_color(weapon_name: String) -> Color:
	if weapon_name in WEAPONS:
		return WEAPONS[weapon_name].color
	if weapon_name in EVOLVED:
		return EVOLVED[weapon_name].color
	return Color.WHITE
