extends CanvasLayer

# --- Node references (assigned in _ready via code-built UI) ---
var hp_bar: ProgressBar
var hp_label: Label
var xp_bar: ProgressBar
var xp_label: Label
var level_label: Label
var timer_label: Label
var kill_label: Label
var weapon_container: HBoxContainer
var gold_label: Label

# Cached weapon manager reference for polling weapon data
var _weapon_manager: Node = null
var _player: CharacterBody2D = null
# Track what we last rendered so we only rebuild when weapons change
var _last_weapon_hash: String = ""


func _ready():
	layer = 5
	_build_ui()


func _process(_delta):
	_update_kill_count()
	_update_gold_count()
	_refresh_weapons()


# ---------------------------------------------------------------------------
# PUBLIC API  (called by Game.gd via signals)
# ---------------------------------------------------------------------------

func update_hp(current: float, max_val: float):
	if hp_bar:
		hp_bar.max_value = max_val
		hp_bar.value = current
	if hp_label:
		hp_label.text = "%d / %d" % [int(current), int(max_val)]


func update_xp(current: float, max_val: float):
	if xp_bar:
		xp_bar.max_value = max_val
		xp_bar.value = current
	if xp_label:
		xp_label.text = "XP %d / %d" % [int(current), int(max_val)]


func update_timer(time: float):
	if timer_label:
		var minutes = int(time) / 60
		var seconds = int(time) % 60
		timer_label.text = "%02d:%02d" % [minutes, seconds]


func update_level(level: int):
	if level_label:
		level_label.text = "Lv. %d" % level


func set_player_ref(player: CharacterBody2D):
	_player = player
	_weapon_manager = player.get_node_or_null("WeaponManager")


# ---------------------------------------------------------------------------
# KILL COUNT  (polled every frame from GameState singleton)
# ---------------------------------------------------------------------------

func _update_kill_count():
	if kill_label:
		kill_label.text = "Kills: %d" % GameState.enemies_killed


func _update_gold_count():
	if gold_label:
		gold_label.text = "%d" % GameState.gold_collected


# ---------------------------------------------------------------------------
# WEAPON DISPLAY  (polled from WeaponManager)
# ---------------------------------------------------------------------------

func _refresh_weapons():
	if not _weapon_manager or not is_instance_valid(_weapon_manager):
		# Try to find it again (character swap edge case)
		var p = get_tree().current_scene.get_node_or_null("Player")
		if p:
			_weapon_manager = p.get_node_or_null("WeaponManager")
		if not _weapon_manager:
			return

	# Build a simple hash of current weapon state to avoid rebuilding every frame
	var hash_str = ""
	for w in _weapon_manager.weapons:
		if is_instance_valid(w):
			hash_str += w.weapon_name + str(w.level) + ","
	if hash_str == _last_weapon_hash:
		return
	_last_weapon_hash = hash_str

	# Clear old weapon icons
	for child in weapon_container.get_children():
		child.queue_free()

	# Build weapon icons
	for w in _weapon_manager.weapons:
		if not is_instance_valid(w):
			continue
		var icon_panel = _create_weapon_icon(w.weapon_name, w.level, w.max_level)
		weapon_container.add_child(icon_panel)


func _create_weapon_icon(wname: String, wlevel: int, wmax_level: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(72, 72)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.6)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = _weapon_border_color(wname)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	# Weapon icon sprite (use the matching sprite from assets if available)
	var sprite_path = _weapon_sprite_path(wname)
	if ResourceLoader.exists(sprite_path):
		var tex_rect = TextureRect.new()
		tex_rect.texture = load(sprite_path)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex_rect.custom_minimum_size = Vector2(32, 32)
		tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(tex_rect)
	else:
		# Fallback: colored rect
		var color_rect = ColorRect.new()
		color_rect.color = _weapon_border_color(wname)
		color_rect.custom_minimum_size = Vector2(32, 32)
		color_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(color_rect)

	# Level text
	var lvl_label = Label.new()
	if wlevel >= wmax_level:
		lvl_label.text = "MAX"
		lvl_label.add_theme_color_override("font_color", Color.GOLD)
	else:
		lvl_label.text = "Lv.%d" % wlevel
		lvl_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	lvl_label.add_theme_font_size_override("font_size", 12)
	lvl_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lvl_label)

	return panel


func _weapon_sprite_path(wname: String) -> String:
	match wname:
		"Sword Arc": return "res://assets/sprites/sword_arc.png"
		"Arrow Shot": return "res://assets/sprites/arrow.png"
		"Fireball": return "res://assets/sprites/fireball.png"
		"Spinning Shield": return "res://assets/sprites/shield.png"
		"Lightning Strike": return "res://assets/sprites/lightning.png"
		"Orbiting Orbs": return "res://assets/sprites/orbit_projectile.png"
		"Aura": return "res://assets/sprites/aura.png"
		# Evolved weapons use the base sprite
		"Dragon Cleaver": return "res://assets/sprites/sword_arc.png"
		"Storm of Arrows": return "res://assets/sprites/arrow.png"
		"Inferno": return "res://assets/sprites/fireball.png"
		"Fortress": return "res://assets/sprites/shield.png"
		"Thunder Storm": return "res://assets/sprites/lightning.png"
		"Celestial Barrage": return "res://assets/sprites/orbit_projectile.png"
		"Tempest Aura": return "res://assets/sprites/aura.png"
	return ""


func _weapon_border_color(wname: String) -> Color:
	match wname:
		"Sword Arc": return Color.STEEL_BLUE
		"Arrow Shot": return Color.FOREST_GREEN
		"Fireball": return Color.ORANGE_RED
		"Spinning Shield": return Color.SILVER
		"Lightning Strike": return Color.LIGHT_BLUE
		"Orbiting Orbs": return Color.DODGER_BLUE
		"Aura": return Color.MEDIUM_SEA_GREEN
		# Evolved weapons get purple/gold borders
		"Dragon Cleaver": return Color(1.0, 0.5, 0.2)
		"Storm of Arrows": return Color(0.5, 1.0, 0.5)
		"Inferno": return Color(1.0, 0.4, 0.0)
		"Fortress": return Color(1.0, 0.85, 0.3)
		"Thunder Storm": return Color(0.6, 0.4, 1.0)
		"Celestial Barrage": return Color(0.6, 0.8, 1.0)
		"Tempest Aura": return Color(0.4, 0.8, 1.0)
	return Color.WHITE


# ---------------------------------------------------------------------------
# UI CONSTRUCTION  (built entirely in code so the .tscn stays minimal)
# ---------------------------------------------------------------------------

func _build_ui():
	# Root full-screen MarginContainer
	var root_margin = MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.anchor_right = 1.0
	root_margin.anchor_bottom = 1.0
	root_margin.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root_margin.grow_vertical = Control.GROW_DIRECTION_BOTH
	root_margin.add_theme_constant_override("margin_left", 20)
	root_margin.add_theme_constant_override("margin_top", 12)
	root_margin.add_theme_constant_override("margin_right", 20)
	root_margin.add_theme_constant_override("margin_bottom", 16)
	root_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_margin)

	# Main VBox that fills the whole screen (top content + spacer + bottom)
	var main_vbox = VBoxContainer.new()
	main_vbox.layout_mode = 2
	main_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_margin.add_child(main_vbox)

	# ========== TOP ROW ==========
	var top_row = HBoxContainer.new()
	top_row.layout_mode = 2
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(top_row)

	# --- Left column: HP bar, XP bar, Level ---
	var left_col = VBoxContainer.new()
	left_col.layout_mode = 2
	left_col.add_theme_constant_override("separation", 4)
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(left_col)

	# Level label
	level_label = Label.new()
	level_label.text = "Lv. 1"
	level_label.add_theme_font_size_override("font_size", 18)
	level_label.add_theme_color_override("font_color", Color.GOLD)
	level_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	level_label.add_theme_constant_override("shadow_offset_x", 1)
	level_label.add_theme_constant_override("shadow_offset_y", 1)
	left_col.add_child(level_label)

	# HP bar with panel background
	var hp_panel = _create_bar_panel()
	left_col.add_child(hp_panel)
	var hp_hbox = HBoxContainer.new()
	hp_hbox.add_theme_constant_override("separation", 6)
	hp_panel.add_child(hp_hbox)

	var hp_icon_label = Label.new()
	hp_icon_label.text = "HP"
	hp_icon_label.add_theme_font_size_override("font_size", 14)
	hp_icon_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	hp_hbox.add_child(hp_icon_label)

	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(200, 20)
	hp_bar.max_value = 100.0
	hp_bar.value = 100.0
	hp_bar.show_percentage = false
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hp_bg_style = StyleBoxFlat.new()
	hp_bg_style.bg_color = Color(0.3, 0.08, 0.08, 0.9)
	hp_bg_style.corner_radius_top_left = 3
	hp_bg_style.corner_radius_top_right = 3
	hp_bg_style.corner_radius_bottom_left = 3
	hp_bg_style.corner_radius_bottom_right = 3
	var hp_fill_style = StyleBoxFlat.new()
	hp_fill_style.bg_color = Color(0.85, 0.12, 0.12, 1.0)
	hp_fill_style.corner_radius_top_left = 3
	hp_fill_style.corner_radius_top_right = 3
	hp_fill_style.corner_radius_bottom_left = 3
	hp_fill_style.corner_radius_bottom_right = 3
	hp_bar.add_theme_stylebox_override("background", hp_bg_style)
	hp_bar.add_theme_stylebox_override("fill", hp_fill_style)
	hp_hbox.add_child(hp_bar)

	hp_label = Label.new()
	hp_label.text = "100 / 100"
	hp_label.add_theme_font_size_override("font_size", 13)
	hp_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	hp_hbox.add_child(hp_label)

	# XP bar with panel background
	var xp_panel = _create_bar_panel()
	left_col.add_child(xp_panel)
	var xp_hbox = HBoxContainer.new()
	xp_hbox.add_theme_constant_override("separation", 6)
	xp_panel.add_child(xp_hbox)

	var xp_icon_label = Label.new()
	xp_icon_label.text = "XP"
	xp_icon_label.add_theme_font_size_override("font_size", 14)
	xp_icon_label.add_theme_color_override("font_color", Color(0.5, 0.5, 1.0))
	xp_hbox.add_child(xp_icon_label)

	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(200, 20)
	xp_bar.max_value = 10.0
	xp_bar.value = 0.0
	xp_bar.show_percentage = false
	xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var xp_bg_style = StyleBoxFlat.new()
	xp_bg_style.bg_color = Color(0.08, 0.08, 0.3, 0.9)
	xp_bg_style.corner_radius_top_left = 3
	xp_bg_style.corner_radius_top_right = 3
	xp_bg_style.corner_radius_bottom_left = 3
	xp_bg_style.corner_radius_bottom_right = 3
	var xp_fill_style = StyleBoxFlat.new()
	xp_fill_style.bg_color = Color(0.25, 0.45, 0.95, 1.0)
	xp_fill_style.corner_radius_top_left = 3
	xp_fill_style.corner_radius_top_right = 3
	xp_fill_style.corner_radius_bottom_left = 3
	xp_fill_style.corner_radius_bottom_right = 3
	xp_bar.add_theme_stylebox_override("background", xp_bg_style)
	xp_bar.add_theme_stylebox_override("fill", xp_fill_style)
	xp_hbox.add_child(xp_bar)

	xp_label = Label.new()
	xp_label.text = "XP 0 / 10"
	xp_label.add_theme_font_size_override("font_size", 13)
	xp_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	xp_hbox.add_child(xp_label)

	# --- Center column: Timer ---
	var center_col = VBoxContainer.new()
	center_col.layout_mode = 2
	center_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_col.alignment = BoxContainer.ALIGNMENT_BEGIN
	center_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(center_col)

	var timer_panel = PanelContainer.new()
	timer_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var timer_style = StyleBoxFlat.new()
	timer_style.bg_color = Color(0.0, 0.0, 0.0, 0.5)
	timer_style.corner_radius_top_left = 6
	timer_style.corner_radius_top_right = 6
	timer_style.corner_radius_bottom_left = 6
	timer_style.corner_radius_bottom_right = 6
	timer_style.content_margin_left = 16
	timer_style.content_margin_right = 16
	timer_style.content_margin_top = 6
	timer_style.content_margin_bottom = 6
	timer_panel.add_theme_stylebox_override("panel", timer_style)
	center_col.add_child(timer_panel)

	timer_label = Label.new()
	timer_label.text = "00:00"
	timer_label.add_theme_font_size_override("font_size", 28)
	timer_label.add_theme_color_override("font_color", Color.WHITE)
	timer_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	timer_label.add_theme_constant_override("shadow_offset_x", 2)
	timer_label.add_theme_constant_override("shadow_offset_y", 2)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_panel.add_child(timer_label)

	# --- Right column: Kill counter ---
	var right_col = VBoxContainer.new()
	right_col.layout_mode = 2
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.alignment = BoxContainer.ALIGNMENT_BEGIN
	right_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(right_col)

	var kill_panel = PanelContainer.new()
	kill_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	var kill_style = StyleBoxFlat.new()
	kill_style.bg_color = Color(0.0, 0.0, 0.0, 0.5)
	kill_style.corner_radius_top_left = 6
	kill_style.corner_radius_top_right = 6
	kill_style.corner_radius_bottom_left = 6
	kill_style.corner_radius_bottom_right = 6
	kill_style.content_margin_left = 12
	kill_style.content_margin_right = 12
	kill_style.content_margin_top = 6
	kill_style.content_margin_bottom = 6
	kill_panel.add_theme_stylebox_override("panel", kill_style)
	right_col.add_child(kill_panel)

	kill_label = Label.new()
	kill_label.text = "Kills: 0"
	kill_label.add_theme_font_size_override("font_size", 20)
	kill_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.85))
	kill_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	kill_label.add_theme_constant_override("shadow_offset_x", 1)
	kill_label.add_theme_constant_override("shadow_offset_y", 1)
	kill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	kill_panel.add_child(kill_label)

	# Gold display
	var gold_panel = PanelContainer.new()
	gold_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	var gold_style = StyleBoxFlat.new()
	gold_style.bg_color = Color(0.0, 0.0, 0.0, 0.5)
	gold_style.corner_radius_top_left = 6
	gold_style.corner_radius_top_right = 6
	gold_style.corner_radius_bottom_left = 6
	gold_style.corner_radius_bottom_right = 6
	gold_style.content_margin_left = 12
	gold_style.content_margin_right = 12
	gold_style.content_margin_top = 6
	gold_style.content_margin_bottom = 6
	gold_panel.add_theme_stylebox_override("panel", gold_style)
	right_col.add_child(gold_panel)

	var gold_hbox = HBoxContainer.new()
	gold_hbox.add_theme_constant_override("separation", 6)
	gold_panel.add_child(gold_hbox)

	var gold_icon = Label.new()
	gold_icon.text = "G"
	gold_icon.add_theme_font_size_override("font_size", 18)
	gold_icon.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	gold_hbox.add_child(gold_icon)

	gold_label = Label.new()
	gold_label.text = "0"
	gold_label.add_theme_font_size_override("font_size", 18)
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	gold_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	gold_label.add_theme_constant_override("shadow_offset_x", 1)
	gold_label.add_theme_constant_override("shadow_offset_y", 1)
	gold_hbox.add_child(gold_label)

	# ========== SPACER (pushes weapon bar to bottom) ==========
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(spacer)

	# ========== BOTTOM ROW: Weapon icons ==========
	var bottom_row = HBoxContainer.new()
	bottom_row.layout_mode = 2
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(bottom_row)

	weapon_container = HBoxContainer.new()
	weapon_container.alignment = BoxContainer.ALIGNMENT_CENTER
	weapon_container.add_theme_constant_override("separation", 8)
	weapon_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_row.add_child(weapon_container)


func _create_bar_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.4)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)
	return panel
