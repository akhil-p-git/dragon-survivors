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
var fireball_script: GDScript = preload("res://scripts/weapons/Weapon_Fireball.gd")

# Character scenes for new characters
var character_scenes: Dictionary = {
	"knight": "res://scenes/Player_Knight.tscn",
	"archer": "res://scenes/Player_Archer.tscn",
	"mage": "res://scenes/Player_Knight.tscn",       # Reuse knight scene with different script
	"berserker": "res://scenes/Player_Knight.tscn",
	"thief": "res://scenes/Player_Archer.tscn",       # Reuse archer scene
}

# Character starting weapons
var character_weapons: Dictionary = {
	"knight": "res://scripts/weapons/Weapon_SwordArc.gd",
	"archer": "res://scripts/weapons/Weapon_ArrowShot.gd",
	"mage": "res://scripts/weapons/Weapon_Fireball.gd",
	"berserker": "res://scripts/weapons/Weapon_SwordArc.gd",
	"thief": "res://scripts/weapons/Weapon_ArrowShot.gd",
}

# Arcana tracking
var arcana_manager: Node = null
var arcana_ui_shown_at: Dictionary = {}  # game_time -> bool


func _ready() -> void:
	get_tree().paused = false
	# Handle character selection
	var selected: String = GameState.selected_character
	if selected != "knight":
		var scene_path: String = character_scenes.get(selected, "res://scenes/Player_Knight.tscn")
		_swap_player(load(scene_path))

	# Apply character-specific stat modifications
	_apply_character_bonuses()

	GameState.start_game()

	# Add PassiveItemManager to player
	_setup_passive_item_manager()

	# Add EvolutionManager to player
	_setup_evolution_manager()

	# Connect signals
	player.hp_changed.connect(hud.update_hp)
	GameState.xp_changed.connect(hud.update_xp)
	GameState.game_time_updated.connect(hud.update_timer)
	GameState.level_up.connect(hud.update_level)
	GameState.level_up.connect(player.on_level_up)
	GameState.level_up.connect(_on_player_level_up)
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
	var level_up_ui: Node = level_up_ui_scene.instantiate()
	add_child(level_up_ui)
	GameState.level_up.connect(func(_level): level_up_ui.show_choices())

	# Add results screen
	var results_screen: Node = results_screen_scene.instantiate()
	results_screen.name = "ResultsScreen"
	add_child(results_screen)

	# Connect player death to defeat screen
	player.player_died.connect(func(): results_screen.show_defeat())

	# Boss timer -- 60s for testing, set to 900 for real gameplay
	var boss_timer: Timer = Timer.new()
	boss_timer.name = "BossTimer"
	boss_timer.wait_time = 60.0
	boss_timer.one_shot = true
	boss_timer.autostart = true
	boss_timer.timeout.connect(_spawn_boss)
	add_child(boss_timer)

	# Add pause menu
	var pause_menu: Node = pause_menu_scene.instantiate()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)

	# Add destructible spawner
	var destr_spawner: Node = Node.new()
	destr_spawner.name = "DestructibleSpawner"
	destr_spawner.set_script(load("res://scripts/environment/DestructibleSpawner.gd"))
	add_child(destr_spawner)

	# Add hazard spawner (fire + quicksand)
	var hazard_spawner: Node = Node.new()
	hazard_spawner.name = "HazardSpawner"
	hazard_spawner.set_script(load("res://scripts/environment/HazardSpawner.gd"))
	add_child(hazard_spawner)

	# Setup arcana manager
	_setup_arcana_manager()


func _process(_delta: float) -> void:
	# Check arcana selection triggers
	if arcana_manager and GameState.is_game_active:
		if arcana_manager.check_selection_trigger(GameState.game_time):
			_show_arcana_selection()


func _swap_player(scene: PackedScene) -> void:
	var old_player: CharacterBody2D = player
	var old_pos: Vector2 = old_player.global_position
	var camera: Node = old_player.get_node_or_null("Camera2D")
	var weapon_manager: Node = old_player.get_node_or_null("WeaponManager")
	if camera:
		old_player.remove_child(camera)
	if weapon_manager:
		old_player.remove_child(weapon_manager)
	remove_child(old_player)
	old_player.queue_free()

	var new_player: CharacterBody2D = scene.instantiate()
	new_player.name = "Player"
	new_player.global_position = old_pos
	add_child(new_player)
	move_child(new_player, 1)
	player = new_player

	if camera:
		player.add_child(camera)
	else:
		var cam: Camera2D = Camera2D.new()
		cam.name = "Camera2D"
		cam.position_smoothing_enabled = true
		cam.position_smoothing_speed = 8.0
		cam.zoom = Vector2(1.5, 1.5)
		player.add_child(cam)

	if weapon_manager:
		player.add_child(weapon_manager)
	else:
		var wm: Node = Node.new()
		wm.name = "WeaponManager"
		wm.set_script(load("res://scripts/WeaponManager.gd"))
		player.add_child(wm)


func _apply_character_bonuses() -> void:
	var selected: String = GameState.selected_character
	match selected:
		"mage":
			# Mage: cooldown bonus applied via passive
			pass
		"berserker":
			# Berserker: -20% max HP
			player.max_hp *= 0.80
			player.current_hp = player.max_hp
			player.base_max_hp = player.max_hp
		"thief":
			# Thief: base luck and speed bonuses
			player.move_speed *= 1.10
			player.base_move_speed = player.move_speed


func _give_starting_weapon() -> void:
	var weapon_manager: Node = player.get_node_or_null("WeaponManager")
	if not weapon_manager:
		return
	var selected: String = GameState.selected_character
	var weapon_script_path: String = character_weapons.get(selected, "res://scripts/weapons/Weapon_SwordArc.gd")
	var weapon_script: Variant = load(weapon_script_path)
	var weapon: Node = Node.new()
	weapon.set_script(weapon_script)
	weapon_manager.add_child(weapon)
	weapon_manager.weapons.append(weapon)


func _setup_passive_item_manager() -> void:
	var passive_manager: Node = Node.new()
	passive_manager.name = "PassiveItemManager"
	passive_manager.set_script(load("res://scripts/passive_items/PassiveItemManager.gd"))
	player.add_child(passive_manager)


func _setup_evolution_manager() -> void:
	var evo_manager: Node = Node.new()
	evo_manager.name = "EvolutionManager"
	evo_manager.set_script(load("res://scripts/EvolutionManager.gd"))
	player.add_child(evo_manager)


func _setup_arcana_manager() -> void:
	arcana_manager = Node.new()
	arcana_manager.name = "ArcanaManager"
	arcana_manager.set_script(load("res://scripts/ArcanaManager.gd"))
	add_child(arcana_manager)


func _on_player_level_up(new_level: int) -> void:
	# Character-specific level bonuses
	var selected: String = GameState.selected_character
	if new_level % 5 == 0:
		match selected:
			"mage":
				# -5% cooldown every 5 levels (up to -25%)
				player.passive_cooldown_multiplier = max(0.75, player.passive_cooldown_multiplier - 0.05)
			"berserker":
				# +8% damage every 5 levels
				player.passive_damage_multiplier += 0.08
			"thief":
				# +10% move speed and luck every 5 levels
				player.passive_move_speed_multiplier += 0.10
				GameState.luck_bonus += 0.10


func _on_player_died() -> void:
	GameState.is_game_active = false


func _spawn_boss() -> void:
	var dragon: CharacterBody2D = dragon_scene.instantiate()
	var offset: Vector2 = Vector2(600, 0).rotated(randf() * TAU)
	dragon.global_position = player.global_position + offset
	dragon.boss_died.connect(func():
		get_tree().create_timer(1.5).timeout.connect(func():
			var rs = get_node_or_null("ResultsScreen")
			if rs: rs.show_victory()
		)
	)
	$Enemies.add_child(dragon)


func _show_arcana_selection() -> void:
	var choices: Array = arcana_manager.get_random_choices(3)
	if choices.size() == 0:
		arcana_manager.selections_done += 1
		return

	# Create arcana selection UI
	var arcana_ui: CanvasLayer = CanvasLayer.new()
	arcana_ui.layer = 12
	arcana_ui.process_mode = Node.PROCESS_MODE_ALWAYS

	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	arcana_ui.add_child(bg)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -400
	vbox.offset_top = -250
	vbox.offset_right = 400
	vbox.offset_bottom = 250
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	arcana_ui.add_child(vbox)

	var title: Label = Label.new()
	title.text = "CHOOSE AN ARCANA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.MEDIUM_PURPLE)
	vbox.add_child(title)

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	var cards_hbox: HBoxContainer = HBoxContainer.new()
	cards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(cards_hbox)

	for arcana in choices:
		var card: PanelContainer = _create_arcana_card(arcana, arcana_ui)
		cards_hbox.add_child(card)

	get_tree().paused = true
	add_child(arcana_ui)


func _create_arcana_card(arcana: Variant, arcana_ui: CanvasLayer) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(220, 280)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.25, 0.95)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = arcana.icon_color
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	card.add_theme_stylebox_override("panel", style)
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			arcana_manager.select_arcana(arcana)
			arcana_manager.apply_latest_arcana_modifiers(player)
			arcana_ui.queue_free()
			get_tree().paused = false
	)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)

	var type_label: Label = Label.new()
	type_label.text = "ARCANA"
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 12)
	type_label.add_theme_color_override("font_color", Color.MEDIUM_PURPLE)
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(type_label)

	var icon: ColorRect = ColorRect.new()
	icon.color = arcana.icon_color
	icon.custom_minimum_size = Vector2(48, 48)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon)

	var name_label: Label = Label.new()
	name_label.text = arcana.arcana_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	var desc_label: Label = Label.new()
	desc_label.text = arcana.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc_label)

	return card
