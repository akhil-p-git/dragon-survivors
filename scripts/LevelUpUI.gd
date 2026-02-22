extends CanvasLayer

const WR = preload("res://scripts/WeaponRegistry.gd")

# Build available_weapons from the centralized registry
var available_weapons: Array = []

var available_buffs: Array = [
	{"name": "Attack Speed", "description": "+10% attack speed", "stat": "attack_speed", "value": 0.1, "icon_color": Color.YELLOW},
	{"name": "Life Steal", "description": "+3% life steal", "stat": "life_steal", "value": 0.03, "icon_color": Color.DARK_RED},
	{"name": "Max Health", "description": "+15 max HP", "stat": "max_health", "value": 15.0, "icon_color": Color.GREEN},
	{"name": "Armor", "description": "+2 armor", "stat": "armor", "value": 2.0, "icon_color": Color.GRAY},
	{"name": "Move Speed", "description": "+20 move speed", "stat": "move_speed", "value": 20.0, "icon_color": Color.CORNFLOWER_BLUE},
	{"name": "Pickup Range", "description": "+25 pickup range", "stat": "pickup_range", "value": 25.0, "icon_color": Color.MEDIUM_PURPLE},
]

var cards_container: HBoxContainer
var current_offers: Array = []
var _bg_overlay: ColorRect
var _title_label: Label
var _center_vbox: VBoxContainer
var _buttons_container: HBoxContainer
var _banish_mode: bool = false

signal upgrade_selected


func _ready() -> void:
	visible = false
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Populate available_weapons from the centralized registry
	for wname in WR.WEAPONS:
		var data = WR.WEAPONS[wname]
		available_weapons.append({
			"name": wname,
			"script": data.script,
			"description": data.description,
			"icon_color": data.color,
		})

	# Full-screen dark overlay
	_bg_overlay = ColorRect.new()
	_bg_overlay.color = Color(0, 0, 0, 0.0)
	_bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg_overlay)

	# Center container for title + cards + buttons
	_center_vbox = VBoxContainer.new()
	_center_vbox.set_anchors_preset(Control.PRESET_CENTER)
	_center_vbox.anchor_left = 0.5
	_center_vbox.anchor_top = 0.5
	_center_vbox.anchor_right = 0.5
	_center_vbox.anchor_bottom = 0.5
	_center_vbox.offset_left = -420
	_center_vbox.offset_top = -290
	_center_vbox.offset_right = 420
	_center_vbox.offset_bottom = 290
	_center_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_center_vbox)

	# Title
	_title_label = Label.new()
	_title_label.text = "LEVEL UP!"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 36)
	_title_label.add_theme_color_override("font_color", Color.GOLD)
	_title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_title_label.add_theme_constant_override("shadow_offset_x", 2)
	_title_label.add_theme_constant_override("shadow_offset_y", 2)
	_title_label.modulate.a = 0.0
	_center_vbox.add_child(_title_label)

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	_center_vbox.add_child(spacer)

	cards_container = HBoxContainer.new()
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 20)
	_center_vbox.add_child(cards_container)

	# Spacer before buttons
	var btn_spacer: Control = Control.new()
	btn_spacer.custom_minimum_size = Vector2(0, 16)
	_center_vbox.add_child(btn_spacer)

	# Reroll / Skip / Banish buttons
	_buttons_container = HBoxContainer.new()
	_buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons_container.add_theme_constant_override("separation", 16)
	_center_vbox.add_child(_buttons_container)


func show_choices() -> void:
	visible = true
	_banish_mode = false
	get_tree().paused = true

	# Clear old cards
	for child in cards_container.get_children():
		child.queue_free()

	# Generate 3 random offers
	current_offers = _generate_offers(3)

	for i in range(current_offers.size()):
		var offer = current_offers[i]
		var card = _create_card(offer, i)
		cards_container.add_child(card)

	# Build action buttons
	_build_action_buttons()

	# Animate everything in
	_animate_entrance()


func _build_action_buttons() -> void:
	for child in _buttons_container.get_children():
		child.queue_free()

	# Reroll button
	var reroll_btn: Button = _create_action_button(
		"Reroll (%d)" % GameState.reroll_charges,
		Color(0.3, 0.6, 1.0),
		GameState.reroll_charges > 0,
		_on_reroll_pressed
	)
	_buttons_container.add_child(reroll_btn)

	# Skip button
	var skip_btn: Button = _create_action_button(
		"Skip (%d)" % GameState.skip_charges,
		Color(0.8, 0.8, 0.3),
		GameState.skip_charges > 0,
		_on_skip_pressed
	)
	_buttons_container.add_child(skip_btn)

	# Banish button
	var banish_btn: Button = _create_action_button(
		"Banish (%d)" % GameState.banish_charges,
		Color(1.0, 0.3, 0.3),
		GameState.banish_charges > 0,
		_on_banish_pressed
	)
	_buttons_container.add_child(banish_btn)


func _create_action_button(text: String, color: Color, enabled: bool, callback: Callable) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(140, 40)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color.darkened(0.5) if enabled else Color(0.2, 0.2, 0.2, 0.5)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", style)
	var hover_style: StyleBoxFlat = style.duplicate()
	hover_style.bg_color = color.darkened(0.3) if enabled else Color(0.2, 0.2, 0.2, 0.5)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color.WHITE if enabled else Color(0.5, 0.5, 0.5))
	btn.disabled = not enabled
	if enabled:
		btn.pressed.connect(callback)
	return btn


func _on_reroll_pressed() -> void:
	if GameState.reroll_charges <= 0:
		return
	GameState.reroll_charges -= 1
	show_choices()


func _on_skip_pressed() -> void:
	if GameState.skip_charges <= 0:
		return
	GameState.skip_charges -= 1
	_animate_exit()


func _on_banish_pressed() -> void:
	if GameState.banish_charges <= 0:
		return
	_banish_mode = true
	_title_label.text = "CLICK TO BANISH"
	_title_label.add_theme_color_override("font_color", Color.RED)


func _animate_entrance() -> void:
	# Fade in the background overlay
	var bg_tween: Tween = create_tween()
	bg_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	bg_tween.tween_property(_bg_overlay, "color", Color(0, 0, 0, 0.7), 0.2)

	# Fade in the title
	var title_tween: Tween = create_tween()
	title_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_title_label.modulate.a = 0.0
	title_tween.tween_property(_title_label, "modulate:a", 1.0, 0.25)

	# Slide each card up from below with a stagger
	var cards: Array[Node] = cards_container.get_children()
	for i in range(cards.size()):
		var card = cards[i]
		card.modulate.a = 0.0
		card.position.y = 60.0

		var card_tween: Tween = create_tween()
		card_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		card_tween.set_ease(Tween.EASE_OUT)
		card_tween.set_trans(Tween.TRANS_BACK)
		# Stagger: each card starts 0.08s after the previous
		var delay: float = 0.1 + i * 0.08
		card_tween.tween_interval(delay)
		card_tween.tween_property(card, "position:y", 0.0, 0.35)

		var fade_tween: Tween = create_tween()
		fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		fade_tween.tween_interval(delay)
		fade_tween.tween_property(card, "modulate:a", 1.0, 0.2)


func _generate_offers(count: int) -> Array:
	var offers: Array = []
	var player: Node = get_tree().current_scene.get_node_or_null("Player")
	var weapon_manager: Node = player.get_node_or_null("WeaponManager") if player else null

	# Possible: upgrade existing weapons, add new weapons, or buffs
	var pool: Array = []

	# Add weapon upgrades for owned weapons
	if weapon_manager:
		for w in weapon_manager.weapons:
			if w.level < w.max_level and not w.weapon_name in GameState.banished_items:
				var next_level: int = w.level + 1
				var upgrade_desc: String = _get_weapon_upgrade_description(w.weapon_name, next_level)
				pool.append({
					"type": "weapon_upgrade",
					"name": w.weapon_name,
					"level": next_level,
					"max_level": w.max_level,
					"description": upgrade_desc,
					"icon_color": _get_weapon_color(w.weapon_name),
				})

	# Add new weapons
	if weapon_manager and weapon_manager.weapons.size() < weapon_manager.max_weapons:
		for aw in available_weapons:
			if not weapon_manager.has_weapon(aw.name) and not aw.name in GameState.banished_items:
				pool.append({
					"type": "new_weapon",
					"name": aw.name,
					"description": aw.description,
					"icon_color": aw.icon_color,
				})

	# Add buffs (legacy simple buffs)
	for b in available_buffs:
		if b.name in GameState.banished_items:
			continue
		var current_level: int = GameState.buffs.get(b.stat, 0)
		if current_level < 5:
			pool.append({
				"type": "buff",
				"name": b.name,
				"stat": b.stat,
				"value": b.value,
				"level": current_level + 1,
				"max_level": 5,
				"description": b.description,
				"icon_color": b.icon_color,
			})

	# Add passive items from PassiveItemManager
	var passive_manager: Node = player.get_node_or_null("PassiveItemManager") if player else null
	if passive_manager:
		var passive_upgrades: Array = passive_manager.get_available_upgrades()
		# Filter banished
		for pu in passive_upgrades:
			if not pu.name in GameState.banished_items:
				pool.append(pu)

	pool.shuffle()
	for i in range(min(count, pool.size())):
		offers.append(pool[i])

	return offers


func _get_weapon_color(weapon_name: String) -> Color:
	return WR.get_color(weapon_name)


func _get_weapon_upgrade_description(weapon_name: String, next_level: int) -> String:
	match weapon_name:
		"Sword Arc":
			match next_level:
				2: return "+30% damage, +15% size"
				3: return "+30% damage, +15% size"
				4: return "+30% damage, faster cooldown"
				5: return "Double slash attack"
		"Arrow Shot":
			match next_level:
				2: return "+30% damage, +1 arrow"
				3: return "+30% damage, faster speed"
				4: return "+30% damage, pierce +1"
				5: return "Rapid fire barrage"
		"Fireball":
			match next_level:
				2: return "+30% damage, larger AoE"
				3: return "+30% damage, larger AoE"
				4: return "+30% damage, faster cooldown"
				5: return "Triple fireball volley"
		"Spinning Shield":
			match next_level:
				2: return "+1 shield, wider orbit"
				3: return "+damage, faster spin"
				4: return "+1 shield, wider orbit"
				5: return "Max shields, high damage"
		"Lightning Strike":
			match next_level:
				2: return "+damage per strike"
				3: return "+1 simultaneous strike"
				4: return "+damage, faster cooldown"
				5: return "3 lightning strikes"
		"Orbiting Orbs":
			match next_level:
				2: return "+damage, +1 orb"
				3: return "+damage, wider orbit"
				4: return "+damage, longer duration"
				5: return "Max orbs, high damage"
		"Aura":
			match next_level:
				2: return "+damage, larger radius"
				3: return "+damage, +knockback"
				4: return "+damage, larger radius"
				5: return "Max radius, high damage"
	return "+damage and stats"


func _create_card(offer: Dictionary, index: int) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(230, 320)

	# Base style
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.22, 0.95)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = offer.get("icon_color", Color.WHITE)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	card.add_theme_stylebox_override("panel", style)

	# Store style and color info on the card for hover effects
	card.set_meta("base_style", style)
	card.set_meta("border_color", offer.get("icon_color", Color.WHITE))
	card.set_meta("card_index", index)

	# Make the entire card clickable + hoverable
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_card_selected(index)
	)
	card.mouse_entered.connect(func(): _on_card_hover_enter(card))
	card.mouse_exited.connect(func(): _on_card_hover_exit(card))

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)

	# --- Type tag at top ---
	var type_label: Label = Label.new()
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match offer.type:
		"weapon_upgrade": type_label.text = "UPGRADE"
		"new_weapon": type_label.text = "NEW WEAPON"
		"buff": type_label.text = "BUFF"
		"passive_item":
			if offer.get("is_new", false):
				type_label.text = "NEW PASSIVE"
			else:
				type_label.text = "PASSIVE UPGRADE"
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 12)
	var type_color: Color = _get_type_tag_color(offer.type, offer.get("is_new", false))
	type_label.add_theme_color_override("font_color", type_color)
	vbox.add_child(type_label)

	# --- Icon ---
	var icon_container: CenterContainer = CenterContainer.new()
	icon_container.custom_minimum_size = Vector2(0, 64)
	icon_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_container)
	_add_icon_to_container(icon_container, offer)

	# --- Name ---
	var name_label: Label = Label.new()
	name_label.text = offer.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	# --- Level indicator (for upgrades) ---
	var show_level: bool = offer.type in ["weapon_upgrade", "buff", "passive_item"]
	if show_level and offer.has("level"):
		var level_container: HBoxContainer = HBoxContainer.new()
		level_container.alignment = BoxContainer.ALIGNMENT_CENTER
		level_container.add_theme_constant_override("separation", 4)
		level_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(level_container)

		var max_pips: int = offer.get("max_level", 5)
		var current_level: int = offer.get("level", 1)
		for pip_i in range(max_pips):
			var pip: ColorRect = ColorRect.new()
			pip.custom_minimum_size = Vector2(14, 6)
			pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if pip_i < current_level:
				pip.color = offer.get("icon_color", Color.GOLD)
			else:
				pip.color = Color(0.3, 0.3, 0.4, 0.6)
			level_container.add_child(pip)

		var lvl_text: Label = Label.new()
		lvl_text.text = " Lv.%d" % current_level
		lvl_text.add_theme_font_size_override("font_size", 13)
		lvl_text.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
		lvl_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		level_container.add_child(lvl_text)

	# --- Description ---
	var desc_label: Label = Label.new()
	desc_label.text = offer.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc_label)

	# --- Bottom spacer ---
	var bottom_spacer: Control = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 4)
	bottom_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bottom_spacer)

	return card


func _add_icon_to_container(container: CenterContainer, offer: Dictionary) -> void:
	var sprite_path: String = ""
	if offer.type == "passive_item":
		var sprite_name: String = offer.name.to_lower().replace(" ", "_")
		sprite_path = "res://assets/sprites/passive_%s.png" % sprite_name
	elif offer.type in ["new_weapon", "weapon_upgrade"]:
		sprite_path = WR.get_sprite_path(offer.name)
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		var tex_rect: TextureRect = TextureRect.new()
		tex_rect.texture = load(sprite_path)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex_rect.custom_minimum_size = Vector2(48, 48)
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(tex_rect)
	else:
		var icon: ColorRect = ColorRect.new()
		icon.color = offer.get("icon_color", Color.WHITE)
		icon.custom_minimum_size = Vector2(48, 48)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(icon)


func _get_type_tag_color(type: String, is_new: bool = false) -> Color:
	match type:
		"new_weapon": return Color(0.3, 1.0, 0.5)
		"weapon_upgrade": return Color(0.5, 0.7, 1.0)
		"buff": return Color(1.0, 1.0, 0.5)
		"passive_item":
			if is_new:
				return Color(0.3, 1.0, 0.5)
			return Color(0.8, 0.6, 1.0)
	return Color(0.7, 0.7, 0.7)


func _on_card_hover_enter(card: PanelContainer) -> void:
	var border_color: Color = card.get_meta("border_color")
	var hover_style: StyleBoxFlat = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.18, 0.18, 0.32, 0.98)
	hover_style.corner_radius_top_left = 12
	hover_style.corner_radius_top_right = 12
	hover_style.corner_radius_bottom_left = 12
	hover_style.corner_radius_bottom_right = 12
	hover_style.border_width_top = 3
	hover_style.border_width_bottom = 3
	hover_style.border_width_left = 3
	hover_style.border_width_right = 3
	hover_style.border_color = border_color.lightened(0.3)
	hover_style.content_margin_left = 15
	hover_style.content_margin_right = 15
	hover_style.content_margin_top = 15
	hover_style.content_margin_bottom = 15
	hover_style.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.3)
	hover_style.shadow_size = 8
	card.add_theme_stylebox_override("panel", hover_style)
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(card, "scale", Vector2(1.05, 1.05), 0.12)


func _on_card_hover_exit(card: PanelContainer) -> void:
	var base_style: StyleBoxFlat = card.get_meta("base_style")
	card.add_theme_stylebox_override("panel", base_style)
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.12)


func _on_card_selected(index: int) -> void:
	if index < 0 or index >= current_offers.size():
		return

	# Banish mode: remove item from pool instead of selecting
	if _banish_mode:
		GameState.banish_charges -= 1
		var offer = current_offers[index]
		GameState.banished_items.append(offer.name)
		_banish_mode = false
		# Regenerate offers without the banished item
		show_choices()
		return

	var offer: Dictionary = current_offers[index]
	var player: Node = get_tree().current_scene.get_node_or_null("Player")
	var weapon_manager: Node = player.get_node_or_null("WeaponManager") if player else null

	match offer.type:
		"weapon_upgrade":
			if weapon_manager:
				weapon_manager.upgrade_weapon(offer.name)
		"new_weapon":
			if weapon_manager:
				_add_new_weapon(weapon_manager, offer.name)
		"buff":
			_apply_buff(player, offer)
		"passive_item":
			_apply_passive_item(player, offer)

	# Animate out then unpause
	_animate_exit()


func _animate_exit() -> void:
	# Quick fade out
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_bg_overlay, "color", Color(0, 0, 0, 0.0), 0.15)
	tween.parallel().tween_property(_title_label, "modulate:a", 0.0, 0.1)

	var cards: Array[Node] = cards_container.get_children()
	for card in cards:
		tween.parallel().tween_property(card, "modulate:a", 0.0, 0.15)

	tween.tween_callback(func():
		visible = false
		get_tree().paused = false
		# Reset title
		_title_label.text = "LEVEL UP!"
		_title_label.add_theme_color_override("font_color", Color.GOLD)
		emit_signal("upgrade_selected")
	)


func _add_new_weapon(weapon_manager: Node, weapon_name: String) -> void:
	for aw in available_weapons:
		if aw.name == weapon_name:
			var script: GDScript = load(aw.script)
			var weapon: Node = Node.new()
			weapon.set_script(script)
			weapon_manager.add_child(weapon)
			weapon_manager.weapons.append(weapon)
			return


func _apply_buff(player: CharacterBody2D, offer: Dictionary) -> void:
	var stat: String = offer.stat
	var value: float = offer.value
	GameState.buffs[stat] = GameState.buffs.get(stat, 0) + 1

	match stat:
		"attack_speed":
			GameState.attack_speed_mult = max(0.3, 1.0 - GameState.buffs.get("attack_speed", 0) * 0.1)
		"max_health":
			player.max_hp += value
			player.current_hp += value
			player.emit_signal("hp_changed", player.current_hp, player.max_hp)
		"armor":
			player.armor += value
		"move_speed":
			player.move_speed += value
		"pickup_range":
			player.pickup_range += value
			var pickup_area = player.get_node_or_null("PickupArea/PickupShape")
			if pickup_area and pickup_area.shape is CircleShape2D:
				pickup_area.shape.radius = player.pickup_range
		"life_steal":
			GameState.life_steal += value


func _apply_passive_item(player: CharacterBody2D, offer: Dictionary) -> void:
	var passive_manager: Node = player.get_node_or_null("PassiveItemManager") if is_instance_valid(player) else null
	if not passive_manager:
		push_warning("LevelUpUI: No PassiveItemManager found on player")
		return
	passive_manager.add_or_upgrade_item(offer.name)
	passive_manager.apply_to_player(player)
