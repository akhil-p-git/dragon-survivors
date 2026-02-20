extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var hud = $HUD

var knight_scene: PackedScene = preload("res://scenes/Player_Knight.tscn")
var archer_scene: PackedScene = preload("res://scenes/Player_Archer.tscn")
var level_up_ui_scene: PackedScene = preload("res://scenes/LevelUpUI.tscn")
var results_screen_scene: PackedScene = preload("res://scenes/ResultsScreen.tscn")
var dragon_scene: PackedScene = preload("res://scenes/enemies/Enemy_Dragon.tscn")
var pause_menu_scene: PackedScene = preload("res://scenes/PauseMenu.tscn")

# Starting weapon scripts
var sword_arc_script: GDScript = preload("res://scripts/weapons/Weapon_SwordArc.gd")
var arrow_shot_script: GDScript = preload("res://scripts/weapons/Weapon_ArrowShot.gd")


func _ready():
	# Handle character selection - swap player if archer was chosen
	if GameState.selected_character == "archer":
		var old_player = player
		var old_pos = old_player.global_position
		# Move Camera2D to temp before removing old player
		var camera = old_player.get_node_or_null("Camera2D")
		var weapon_manager = old_player.get_node_or_null("WeaponManager")
		if camera:
			old_player.remove_child(camera)
		if weapon_manager:
			old_player.remove_child(weapon_manager)
		old_player.queue_free()

		var new_player = archer_scene.instantiate()
		new_player.name = "Player"
		new_player.global_position = old_pos
		add_child(new_player)
		move_child(new_player, 1)
		player = new_player

		# Add camera back
		if camera:
			player.add_child(camera)
		else:
			var cam = Camera2D.new()
			cam.name = "Camera2D"
			cam.position_smoothing_enabled = true
			cam.position_smoothing_speed = 8.0
			cam.zoom = Vector2(1.5, 1.5)
			player.add_child(cam)

		# Add weapon manager back
		if weapon_manager:
			player.add_child(weapon_manager)
		else:
			var wm = Node.new()
			wm.name = "WeaponManager"
			wm.set_script(load("res://scripts/WeaponManager.gd"))
			player.add_child(wm)

	GameState.start_game()

	# Add PassiveItemManager to player
	_setup_passive_item_manager()

	# Connect signals
	player.hp_changed.connect(hud.update_hp)
	GameState.xp_changed.connect(hud.update_xp)
	GameState.game_time_updated.connect(hud.update_timer)
	GameState.level_up.connect(hud.update_level)
	GameState.level_up.connect(player.on_level_up)
	player.player_died.connect(_on_player_died)

	# Give HUD a reference to the player (for weapon display)
	hud.set_player_ref(player)

	# Initial HUD update
	hud.update_hp(player.current_hp, player.max_hp)
	hud.update_xp(0, GameState.xp_to_next_level)
	hud.update_level(1)

	# Give starting weapon based on character
	_give_starting_weapon()

	# Add level up UI
	var level_up_ui = level_up_ui_scene.instantiate()
	add_child(level_up_ui)
	GameState.level_up.connect(func(_level): level_up_ui.show_choices())

	# Add results screen
	var results_screen = results_screen_scene.instantiate()
	results_screen.name = "ResultsScreen"
	add_child(results_screen)

	# Connect player death to defeat screen
	player.player_died.connect(func(): results_screen.show_defeat())

	# Boss timer — 60s for testing, set to 900 for real gameplay
	var boss_timer = Timer.new()
	boss_timer.name = "BossTimer"
	boss_timer.wait_time = 60.0
	boss_timer.one_shot = true
	boss_timer.autostart = true
	boss_timer.timeout.connect(_spawn_boss)
	add_child(boss_timer)

	# Add pause menu
	var pause_menu = pause_menu_scene.instantiate()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)


func _give_starting_weapon():
	var weapon_manager = player.get_node_or_null("WeaponManager")
	if not weapon_manager:
		return

	if GameState.selected_character == "archer":
		var weapon = Node.new()
		weapon.set_script(arrow_shot_script)
		weapon_manager.add_child(weapon)
		weapon_manager.weapons.append(weapon)
	else:
		# Default: knight gets Sword Arc
		var weapon = Node.new()
		weapon.set_script(sword_arc_script)
		weapon_manager.add_child(weapon)
		weapon_manager.weapons.append(weapon)


func _setup_passive_item_manager():
	# Create and attach PassiveItemManager to the player
	var passive_manager = Node.new()
	passive_manager.name = "PassiveItemManager"
	passive_manager.set_script(load("res://scripts/passive_items/PassiveItemManager.gd"))
	player.add_child(passive_manager)


func _on_player_died():
	GameState.is_game_active = false


func _spawn_boss():
	var dragon = dragon_scene.instantiate()
	var offset = Vector2(600, 0).rotated(randf() * TAU)
	dragon.global_position = player.global_position + offset
	dragon.boss_died.connect(func():
		# Small delay before victory screen
		get_tree().create_timer(1.5).timeout.connect(func():
			var rs = get_node_or_null("ResultsScreen")
			if rs: rs.show_victory()
		)
	)
	$Enemies.add_child(dragon)
