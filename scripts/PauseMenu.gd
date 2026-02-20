extends CanvasLayer

var is_paused: bool = false

# --- Node references (assigned during _build_ui) ---
var stats_container: VBoxContainer
var weapons_container: VBoxContainer
var passives_container: VBoxContainer
var time_label: Label
var kills_label: Label


func _ready():
	visible = false
	layer = 15  # Above HUD (5), above LevelUp (10), below ResultsScreen (20)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()


func toggle_pause():
	# Don't pause if results screen is showing
	var results = get_tree().current_scene.get_node_or_null("ResultsScreen")
	if results and results.visible:
		return
	# Don't pause if level up UI is showing
	var level_up = get_tree().current_scene.get_node_or_null("LevelUpUI")
	if level_up and level_up.visible:
		return

	is_paused = !is_paused
	visible = is_paused
	get_tree().paused = is_paused

	if is_paused:
		_refresh_stats()


# ---------------------------------------------------------------------------
# BUTTON CALLBACKS
# ---------------------------------------------------------------------------

func _on_resume():
	is_paused = false
	visible = false
	get_tree().paused = false


func _on_main_menu():
	is_paused = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _on_quit():
	get_tree().quit()


# ---------------------------------------------------------------------------
# STATS REFRESH  (called each time the pause menu opens)
# ---------------------------------------------------------------------------

func _refresh_stats():
	_refresh_player_stats()
	_refresh_time_and_kills()
	_refresh_weapons()
	_refresh_passives()


func _refresh_player_stats():
	# Clear old stat labels
	for child in stats_container.get_children():
		child.queue_free()

	var player = get_tree().current_scene.get_node_or_null("Player")
	if not player:
		var no_data = Label.new()
		no_data.text = "No player data"
		no_data.add_theme_font_size_override("font_size", 16)
		no_data.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		stats_container.add_child(no_data)
		return

	# HP
	_add_stat_row(stats_container, "HP", "%d / %d" % [int(player.current_hp), int(player.max_hp)], Color(1.0, 0.4, 0.4))

	# Damage multiplier
	var damage_mult = player.passive_damage_multiplier if "passive_damage_multiplier" in player else 1.0
	_add_stat_row(stats_container, "Damage", "x%.0f%%" % (damage_mult * 100), Color(1.0, 0.7, 0.3))

	# Speed
	var effective_speed = player.move_speed * player.passive_move_speed_multiplier
	_add_stat_row(stats_container, "Speed", "%d" % int(effective_speed), Color(0.5, 0.8, 1.0))

	# Armor
	var total_armor = player.get_total_armor() if player.has_method("get_total_armor") else player.armor
	_add_stat_row(stats_container, "Armor", "%d" % int(total_armor), Color(0.7, 0.7, 0.7))

	# Level
	_add_stat_row(stats_container, "Level", "%d" % GameState.player_level, Color.GOLD)


func _refresh_time_and_kills():
	var minutes = int(GameState.game_time) / 60
	var seconds = int(GameState.game_time) % 60
	if time_label:
		time_label.text = "%02d:%02d" % [minutes, seconds]
	if kills_label:
		kills_label.text = "%d" % GameState.enemies_killed


func _refresh_weapons():
	# Clear old weapon rows
	for child in weapons_container.get_children():
		child.queue_free()

	var player = get_tree().current_scene.get_node_or_null("Player")
	var weapon_manager = player.get_node_or_null("WeaponManager") if player else null

	if not weapon_manager or weapon_manager.weapons.size() == 0:
		var none_label = Label.new()
		none_label.text = "None"
		none_label.add_theme_font_size_override("font_size", 15)
		none_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		weapons_container.add_child(none_label)
		return

	for w in weapon_manager.weapons:
		if not is_instance_valid(w):
			continue
		var row = _create_item_row(
			w.weapon_name,
			w.level,
			w.max_level,
			_weapon_color(w.weapon_name),
		)
		weapons_container.add_child(row)


func _refresh_passives():
	# Clear old passive rows
	for child in passives_container.get_children():
		child.queue_free()

	var player = get_tree().current_scene.get_node_or_null("Player")
	var passive_manager = player.get_node_or_null("PassiveItemManager") if player else null

	if not passive_manager or passive_manager._owned_items.size() == 0:
		var none_label = Label.new()
		none_label.text = "None"
		none_label.add_theme_font_size_override("font_size", 15)
		none_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		passives_container.add_child(none_label)
		return

	for item_name in passive_manager._owned_items:
		var level = passive_manager._owned_items[item_name]
		var data = passive_manager.get_item_data(item_name)
		var max_level = data.max_level if data else 5
		var color = data.icon_color if data else Color.WHITE
		var row = _create_item_row(item_name, level, max_level, color)
		passives_container.add_child(row)


# ---------------------------------------------------------------------------
# UI HELPER FUNCTIONS
# ---------------------------------------------------------------------------

func _add_stat_row(container: VBoxContainer, stat_name: String, stat_value: String, color: Color):
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	container.add_child(hbox)

	var name_label = Label.new()
	name_label.text = stat_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", color)
	name_label.custom_minimum_size = Vector2(90, 0)
	hbox.add_child(name_label)

	var value_label = Label.new()
	value_label.text = stat_value
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	hbox.add_child(value_label)


func _create_item_row(item_name: String, level: int, max_level: int, color: Color) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	# Color indicator
	var indicator = ColorRect.new()
	indicator.color = color
	indicator.custom_minimum_size = Vector2(6, 20)
	indicator.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(indicator)

	# Name
	var name_label = Label.new()
	name_label.text = item_name
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	name_label.custom_minimum_size = Vector2(150, 0)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)

	# Level
	var level_label = Label.new()
	if level >= max_level:
		level_label.text = "MAX"
		level_label.add_theme_color_override("font_color", Color.GOLD)
	else:
		level_label.text = "Lv.%d/%d" % [level, max_level]
		level_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	level_label.add_theme_font_size_override("font_size", 15)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(level_label)

	return hbox


func _weapon_color(wname: String) -> Color:
	match wname:
		"Sword Arc": return Color.STEEL_BLUE
		"Arrow Shot": return Color.FOREST_GREEN
		"Fireball": return Color.ORANGE_RED
		"Spinning Shield": return Color.SILVER
		"Lightning Strike": return Color.LIGHT_BLUE
		"Orbiting Orbs": return Color.DODGER_BLUE
		"Aura": return Color.MEDIUM_SEA_GREEN
	return Color.WHITE


func _create_section_title(text: String, color: Color) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label


func _create_separator() -> HSeparator:
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 6)
	var sep_style = StyleBoxFlat.new()
	sep_style.bg_color = Color(1, 1, 1, 0.1)
	sep_style.content_margin_top = 1
	sep_style.content_margin_bottom = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	return sep


func _create_styled_button(text: String, callback: Callable, color: Color = Color(0.2, 0.2, 0.35)) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(180, 42)

	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color
	normal_style.corner_radius_top_left = 6
	normal_style.corner_radius_top_right = 6
	normal_style.corner_radius_bottom_left = 6
	normal_style.corner_radius_bottom_right = 6
	normal_style.content_margin_left = 16
	normal_style.content_margin_right = 16
	normal_style.content_margin_top = 8
	normal_style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style = normal_style.duplicate()
	hover_style.bg_color = color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = color.darkened(0.1)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(callback)
	return btn


# ---------------------------------------------------------------------------
# UI CONSTRUCTION  (built entirely in code for consistency with HUD.gd)
# ---------------------------------------------------------------------------

func _build_ui():
	# --- Semi-transparent dark background overlay ---
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.65)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# --- Centered panel ---
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -320
	panel.offset_top = -300
	panel.offset_right = 320
	panel.offset_bottom = 300

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.14, 0.95)
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_color = Color(0.4, 0.4, 0.6, 0.8)
	panel_style.content_margin_left = 30
	panel_style.content_margin_right = 30
	panel_style.content_margin_top = 24
	panel_style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	# --- Main VBox inside the panel ---
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	panel.add_child(main_vbox)

	# ===== TITLE =====
	var title = Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	main_vbox.add_child(title)

	# ===== TIME & KILLS ROW =====
	var time_kills_hbox = HBoxContainer.new()
	time_kills_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	time_kills_hbox.add_theme_constant_override("separation", 40)
	main_vbox.add_child(time_kills_hbox)

	# Time
	var time_hbox = HBoxContainer.new()
	time_hbox.add_theme_constant_override("separation", 6)
	time_kills_hbox.add_child(time_hbox)

	var time_icon = Label.new()
	time_icon.text = "Time:"
	time_icon.add_theme_font_size_override("font_size", 18)
	time_icon.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	time_hbox.add_child(time_icon)

	time_label = Label.new()
	time_label.text = "00:00"
	time_label.add_theme_font_size_override("font_size", 18)
	time_label.add_theme_color_override("font_color", Color.WHITE)
	time_hbox.add_child(time_label)

	# Kills
	var kills_hbox = HBoxContainer.new()
	kills_hbox.add_theme_constant_override("separation", 6)
	time_kills_hbox.add_child(kills_hbox)

	var kills_icon = Label.new()
	kills_icon.text = "Kills:"
	kills_icon.add_theme_font_size_override("font_size", 18)
	kills_icon.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	kills_hbox.add_child(kills_icon)

	kills_label = Label.new()
	kills_label.text = "0"
	kills_label.add_theme_font_size_override("font_size", 18)
	kills_label.add_theme_color_override("font_color", Color.WHITE)
	kills_hbox.add_child(kills_label)

	main_vbox.add_child(_create_separator())

	# ===== SCROLLABLE CONTENT AREA =====
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 320)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)

	var scroll_vbox = VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(scroll_vbox)

	# ----- Player Stats Section -----
	scroll_vbox.add_child(_create_section_title("Player Stats", Color(0.6, 0.85, 1.0)))

	stats_container = VBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 4)
	scroll_vbox.add_child(stats_container)

	scroll_vbox.add_child(_create_separator())

	# ----- Weapons Section -----
	scroll_vbox.add_child(_create_section_title("Weapons", Color(1.0, 0.8, 0.4)))

	weapons_container = VBoxContainer.new()
	weapons_container.add_theme_constant_override("separation", 4)
	scroll_vbox.add_child(weapons_container)

	scroll_vbox.add_child(_create_separator())

	# ----- Passive Items Section -----
	scroll_vbox.add_child(_create_section_title("Passive Items", Color(0.6, 1.0, 0.6)))

	passives_container = VBoxContainer.new()
	passives_container.add_theme_constant_override("separation", 4)
	scroll_vbox.add_child(passives_container)

	# ===== BUTTONS =====
	main_vbox.add_child(_create_separator())

	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 16)
	main_vbox.add_child(btn_hbox)

	btn_hbox.add_child(_create_styled_button("Resume", _on_resume, Color(0.15, 0.4, 0.2)))
	btn_hbox.add_child(_create_styled_button("Main Menu", _on_main_menu, Color(0.3, 0.25, 0.15)))
	btn_hbox.add_child(_create_styled_button("Quit", _on_quit, Color(0.4, 0.15, 0.15)))
