extends "res://scripts/enemies/EnemyBase.gd"
## Giant Slime mini-boss - splits into 4 regular slimes on death

var slime_scene: PackedScene = preload("res://scenes/enemies/Enemy_Slime.tscn")
var is_mini_boss: bool = true


func _ready():
	super._ready()
	max_hp = 500.0
	current_hp = max_hp
	contact_damage = 20.0
	move_speed = 50.0
	xp_value = 30.0
	chest_drop_chance = 1.0
	death_particle_color = Color(0.2, 0.8, 0.2)
	# Giant size
	scale = Vector2(3.0, 3.0)


func die():
	is_alive = false
	GameState.enemies_killed += 1
	ScreenEffects.register_enemy_kill()
	ScreenEffects.shake(ScreenEffects.SHAKE_LARGE, 0.3)
	ScreenEffects.hitstop(0.05)
	_drop_xp()
	_maybe_drop_chest()
	_spawn_death_particles()
	# Split into 4 regular slimes
	for i in range(4):
		var slime = slime_scene.instantiate()
		var offset = Vector2(30, 0).rotated(i * TAU / 4.0)
		slime.global_position = global_position + offset
		var enemies_node = get_tree().current_scene.get_node_or_null("Enemies")
		if enemies_node:
			enemies_node.add_child(slime)
	queue_free()
