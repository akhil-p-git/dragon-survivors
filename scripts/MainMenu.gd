extends Control

var _shop_panel: Control = null
var _char_select_panel: Control = null
var _main_vbox: VBoxContainer = null

# Character data for selection
var characters: Array = [
	{"name": "knight", "display": "Knight", "desc": "Balanced fighter. Starts with Sword Arc.", "cost": 0},
	{"name": "archer", "display": "Archer", "desc": "Fast and ranged. Starts with Arrow Shot.", "cost": 0},
	{"name": "mage", "display": "Mage", "desc": "Cooldown bonus every 5 levels. Starts with Fireball.", "cost": 500},
	{"name": "berserker", "display": "Berserker", "desc": "+8% damage/5 levels, -20% HP. Starts with Sword Arc.", "cost": 750},
	{"name": "thief", "display": "Thief", "desc": "+Speed/Luck every 5 levels. Starts with Arrow Shot.", "cost": 1000},
]


func _ready() -> void:
	_main_vbox = $VBoxContainer
	$VBoxContainer/Title.text = "Dragon Survivors"

	# Replace old buttons with new ones
	$VBoxContainer/KnightButton.queue_free()
	$VBoxContainer/ArcherButton.queue_free()
	$VBoxContainer/QuitButton.queue_free()

	# Wait a frame for queue_free to process
	await get_tree().process_frame

	# Gold display
	var gold_label: Label = Label.new()
	gold_label.name = "GoldLabel"
	gold_label.text = "Gold: %d" % SaveData.gold
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 22)
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	_main_vbox.add_child(gold_label)

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	_main_vbox.add_child(spacer)

	# Play button
	var play_btn: Button = _create_menu_button("Play")
	play_btn.pressed.connect(_show_character_select)
	_main_vbox.add_child(play_btn)

	# Shop button
	var shop_btn: Button = _create_menu_button("Upgrades Shop")
	shop_btn.pressed.connect(_show_shop)
	_main_vbox.add_child(shop_btn)

	# Quit button
	var quit_btn: Button = _create_menu_button("Quit")
	quit_btn.pressed.connect(func(): get_tree().quit())
	_main_vbox.add_child(quit_btn)


func _create_menu_button(text: String) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(300, 50)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.25, 0.35, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 20
	style.content_margin_top = 12
	style.content_margin_right = 20
	style.content_margin_bottom = 12
	btn.add_theme_stylebox_override("normal", style)
	var hover: StyleBoxFlat = style.duplicate()
	hover.bg_color = Color(0.3, 0.35, 0.5, 1)
	btn.add_theme_stylebox_override("hover", hover)
	return btn


func _show_character_select() -> void:
	if _char_select_panel:
		_char_select_panel.queue_free()
	_char_select_panel = _build_character_select()
	add_child(_char_select_panel)


func _build_character_select() -> Control:
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -400
	vbox.offset_top = -280
	vbox.offset_right = 400
	vbox.offset_bottom = 280
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	overlay.add_child(vbox)

	var title: Label = Label.new()
	title.text = "SELECT CHARACTER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color.GOLD)
	vbox.add_child(title)

	var grid: HBoxContainer = HBoxContainer.new()
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	grid.add_theme_constant_override("separation", 12)
	vbox.add_child(grid)

	for char_data in characters:
		var card: PanelContainer = _create_char_card(char_data, overlay)
		grid.add_child(card)

	# Back button
	var back_btn: Button = _create_menu_button("Back")
	back_btn.pressed.connect(func(): overlay.queue_free())
	vbox.add_child(back_btn)

	return overlay


func _create_char_card(char_data: Dictionary, overlay: Control) -> PanelContainer:
	var unlocked: bool = SaveData.is_character_unlocked(char_data.name)
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(150, 200)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.25, 0.95) if unlocked else Color(0.1, 0.1, 0.1, 0.8)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color.GOLD if unlocked else Color.DIM_GRAY
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", style)
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)

	# Character sprite
	var sprite_path: String = "res://assets/sprites/%s.png" % char_data.name
	if ResourceLoader.exists(sprite_path):
		var tex: TextureRect = TextureRect.new()
		tex.texture = load(sprite_path)
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex.custom_minimum_size = Vector2(48, 48)
		tex.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not unlocked:
			tex.modulate = Color(0.3, 0.3, 0.3)
		vbox.add_child(tex)

	var name_label: Label = Label.new()
	name_label.text = char_data.display
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE if unlocked else Color.DIM_GRAY)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	var desc_label: Label = Label.new()
	desc_label.text = char_data.desc
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7) if unlocked else Color(0.4, 0.4, 0.4))
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc_label)

	if unlocked:
		card.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				GameState.selected_character = char_data.name
				get_tree().change_scene_to_file("res://scenes/Game.tscn")
		)
	else:
		var cost_label: Label = Label.new()
		cost_label.text = "%dG to unlock" % char_data.cost
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_label.add_theme_font_size_override("font_size", 12)
		cost_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(cost_label)

		card.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				if SaveData.unlock_character(char_data.name, char_data.cost):
					overlay.queue_free()
					_show_character_select()  # Refresh
		)

	return card


func _show_shop() -> void:
	if _shop_panel:
		_shop_panel.queue_free()
	_shop_panel = _build_shop()
	add_child(_shop_panel)


func _build_shop() -> Control:
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -450
	vbox.offset_top = -300
	vbox.offset_right = 450
	vbox.offset_bottom = 300
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 15)
	overlay.add_child(vbox)

	var title: Label = Label.new()
	title.text = "UPGRADES SHOP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color.GOLD)
	vbox.add_child(title)

	var gold_label: Label = Label.new()
	gold_label.name = "ShopGold"
	gold_label.text = "Gold: %d" % SaveData.gold
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 20)
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	vbox.add_child(gold_label)

	var grid: GridContainer = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(grid)

	for upgrade_name in SaveData.upgrade_defs:
		var card: PanelContainer = _create_shop_card(upgrade_name, overlay, gold_label, grid)
		grid.add_child(card)

	# Back button
	var back_btn: Button = _create_menu_button("Back")
	back_btn.pressed.connect(func():
		overlay.queue_free()
		# Refresh gold display on main menu
		var gl = _main_vbox.get_node_or_null("GoldLabel")
		if gl: gl.text = "Gold: %d" % SaveData.gold
	)
	vbox.add_child(back_btn)

	return overlay


func _create_shop_card(upgrade_name: String, overlay: Control, gold_label: Label, grid: GridContainer) -> PanelContainer:
	var def: Dictionary = SaveData.upgrade_defs[upgrade_name]
	var rank: int = SaveData.get_upgrade_rank(upgrade_name)
	var max_rank: int = def.max_rank
	var cost: int = SaveData.get_upgrade_cost(upgrade_name)
	var maxed: bool = rank >= max_rank

	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(200, 120)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.2, 0.95)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color.GOLD if maxed else Color(0.4, 0.4, 0.5)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)

	var name_lbl: Label = Label.new()
	name_lbl.text = upgrade_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	# Level pips
	var pips: HBoxContainer = HBoxContainer.new()
	pips.alignment = BoxContainer.ALIGNMENT_CENTER
	pips.add_theme_constant_override("separation", 3)
	pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(max_rank):
		var pip: ColorRect = ColorRect.new()
		pip.custom_minimum_size = Vector2(20, 6)
		pip.color = Color.GOLD if i < rank else Color(0.3, 0.3, 0.4, 0.6)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips.add_child(pip)
	vbox.add_child(pips)

	var cost_lbl: Label = Label.new()
	if maxed:
		cost_lbl.text = "MAXED"
		cost_lbl.add_theme_color_override("font_color", Color.GOLD)
	else:
		cost_lbl.text = "Cost: %d" % cost
		var can_afford: bool = SaveData.gold >= cost
		cost_lbl.add_theme_color_override("font_color", Color.WHITE if can_afford else Color.RED)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.add_theme_font_size_override("font_size", 13)
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(cost_lbl)

	if not maxed:
		card.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				if SaveData.buy_upgrade(upgrade_name):
					# Refresh shop
					overlay.queue_free()
					_shop_panel = _build_shop()
					add_child(_shop_panel)
		)

	return card
