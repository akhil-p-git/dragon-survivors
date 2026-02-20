extends CanvasLayer

var available_weapons: Array = [
	{"name": "Sword Arc", "scene": "res://scenes/weapons/Weapon_SwordArc_pickup.tscn", "script": "res://scripts/weapons/Weapon_SwordArc.gd", "description": "Melee arc attack", "icon_color": Color.STEEL_BLUE},
	{"name": "Arrow Shot", "scene": "res://scenes/weapons/Weapon_ArrowShot_pickup.tscn", "script": "res://scripts/weapons/Weapon_ArrowShot.gd", "description": "Ranged piercing arrows", "icon_color": Color.FOREST_GREEN},
	{"name": "Fireball", "scene": "res://scenes/weapons/Weapon_Fireball_pickup.tscn", "script": "res://scripts/weapons/Weapon_Fireball.gd", "description": "Explosive AoE attack", "icon_color": Color.ORANGE_RED},
	{"name": "Spinning Shield", "script": "res://scripts/weapons/Weapon_SpinningShield.gd", "description": "Orbiting shields damage nearby enemies", "icon_color": Color.SILVER},
	{"name": "Lightning Strike", "script": "res://scripts/weapons/Weapon_LightningStrike.gd", "description": "Strikes nearest enemy with lightning from above", "icon_color": Color.LIGHT_BLUE},
	{"name": "Orbiting Orbs", "script": "res://scripts/weapons/Weapon_Orbiting.gd", "description": "Magical orbs orbit around you", "icon_color": Color.DODGER_BLUE},
	{"name": "Aura", "script": "res://scripts/weapons/Weapon_Aura.gd", "description": "Pulsing damage zone around the player", "icon_color": Color.MEDIUM_SEA_GREEN},
]

var available_buffs: Array = [
	{"name": "Attack Speed", "description": "+10% attack speed", "stat": "attack_speed", "value": 0.1, "icon_color": Color.YELLOW},
	{"name": "Life Steal", "description": "+3% life steal", "stat": "life_steal", "value": 0.03, "icon_color": Color.DARK_RED},
	{"name": "Max Health", "description": "+15 max HP", "stat": "max_health", "value": 15.0, "icon_color": Color.GREEN},
	{"name": "Armor", "description": "+2 armor", "stat": "armor", "value": 2.0, "icon_color": Color.GRAY},
	{"name": "Move Speed", "description": "+20 move speed", "stat": "move_speed", "value": 20.0, "icon_color": Color.CORNFLOWER_BLUE},
	{"name": "Pickup Range", "description": "+25 pickup range", "stat": "pickup_range", "value": 25.0, "icon_color": Color.MEDIUM_PURPLE},
]

# Maps weapon names to sprite file paths for card icons
var _weapon_sprite_map: Dictionary = {
	"Sword Arc": "res://assets/sprites/sword_arc.png",
	"Arrow Shot": "res://assets/sprites/arrow.png",
	"Fireball": "res://assets/sprites/fireball.png",
	"Spinning Shield": "res://assets/sprites/shield.png",
	"Lightning Strike": "res://assets/sprites/lightning.png",
	"Orbiting Orbs": "res://assets/sprites/orbit_projectile.png",
	"Aura": "res://assets/sprites/aura.png",
}

var cards_container: HBoxContainer
var current_offers: Array = []
var _bg_overlay: ColorRect
var _title_label: Label
var _center_vbox: VBoxContainer

signal upgrade_selected


func _ready():
	visible = false
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Full-screen dark overlay
	_bg_overlay = ColorRect.new()
	_bg_overlay.color = Color(0, 0, 0, 0.0)
	_bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg_overlay)

	# Center container for title + cards
	_center_vbox = VBoxContainer.new()
	_center_vbox.set_anchors_preset(Control.PRESET_CENTER)
	_center_vbox.anchor_left = 0.5
	_center_vbox.anchor_top = 0.5
	_center_vbox.anchor_right = 0.5
	_center_vbox.anchor_bottom = 0.5
	_center_vbox.offset_left = -420
	_center_vbox.offset_top = -260
	_center_vbox.offset_right = 420
	_center_vbox.offset_bottom = 260
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

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	_center_vbox.add_child(spacer)

	cards_container = HBoxContainer.new()
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 20)
	_center_vbox.add_child(cards_container)


func show_choices():
	visible = true
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

	# Animate everything in
	_animate_entrance()


func _animate_entrance():
	# Fade in the background overlay
	var bg_tween = create_tween()
	bg_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	bg_tween.tween_property(_bg_overlay, "color", Color(0, 0, 0, 0.7), 0.2)

	# Fade in the title
	var title_tween = create_tween()
	title_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_title_label.modulate.a = 0.0
	title_tween.tween_property(_title_label, "modulate:a", 1.0, 0.25)

	# Slide each card up from below with a stagger
	var cards = cards_container.get_children()
	for i in range(cards.size()):
		var card = cards[i]
		card.modulate.a = 0.0
		card.position.y = 60.0

		var card_tween = create_tween()
		card_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		card_tween.set_ease(Tween.EASE_OUT)
		card_tween.set_trans(Tween.TRANS_BACK)
		# Stagger: each card starts 0.08s after the previous
		var delay = 0.1 + i * 0.08
		card_tween.tween_interval(delay)
		card_tween.tween_property(card, "position:y", 0.0, 0.35)

		var fade_tween = create_tween()
		fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		fade_tween.tween_interval(delay)
		fade_tween.tween_property(card, "modulate:a", 1.0, 0.2)


func _generate_offers(count: int) -> Array:
	var offers = []
	var player = get_tree().current_scene.get_node_or_null("Player")
	var weapon_manager = player.get_node_or_null("WeaponManager") if player else null

	# Possible: upgrade existing weapons, add new weapons, or buffs
	var pool = []

	# Add weapon upgrades for owned weapons
	if weapon_manager:
		for w in weapon_manager.weapons:
			if w.level < w.max_level:
				var next_level = w.level + 1
				var upgrade_desc = _get_weapon_upgrade_description(w.weapon_name, next_level)
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
			if not weapon_manager.has_weapon(aw.name):
				pool.append({
					"type": "new_weapon",
					"name": aw.name,
					"description": aw.description,
					"icon_color": aw.icon_color,
				})

	# Add buffs (legacy simple buffs)
	for b in available_buffs:
		var current_level = GameState.buffs.get(b.stat, 0)
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
	var passive_manager = player.get_node_or_null("PassiveItemManager") if player else null
	if passive_manager:
		var passive_upgrades = passive_manager.get_available_upgrades()
		pool.append_array(passive_upgrades)

	pool.shuffle()
	for i in range(min(count, pool.size())):
		offers.append(pool[i])

	return offers


func _get_weapon_color(weapon_name: String) -> Color:
	for aw in available_weapons:
		if aw.name == weapon_name:
			return aw.icon_color
	return Color.WHITE


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
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(230, 320)

	# Base style
	var style = StyleBoxFlat.new()
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

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)

	# --- Type tag at top ---
	var type_label = Label.new()
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
	var type_color = _get_type_tag_color(offer.type, offer.get("is_new", false))
	type_label.add_theme_color_override("font_color", type_color)
	vbox.add_child(type_label)

	# --- Icon ---
	var icon_container = CenterContainer.new()
	icon_container.custom_minimum_size = Vector2(0, 64)
	icon_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_container)
	_add_icon_to_container(icon_container, offer)

	# --- Name ---
	var name_label = Label.new()
	name_label.text = offer.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	# --- Level indicator (for upgrades) ---
	var show_level = offer.type in ["weapon_upgrade", "buff", "passive_item"]
	if show_level and offer.has("level"):
		var level_container = HBoxContainer.new()
		level_container.alignment = BoxContainer.ALIGNMENT_CENTER
		level_container.add_theme_constant_override("separation", 4)
		level_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(level_container)

		var max_pips = offer.get("max_level", 5)
		var current_level = offer.get("level", 1)
		# For upgrades, the level shown is what it will become after picking this
		# So filled pips = current_level (the level after upgrade)
		for pip_i in range(max_pips):
			var pip = ColorRect.new()
			pip.custom_minimum_size = Vector2(14, 6)
			pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if pip_i < current_level:
				pip.color = offer.get("icon_color", Color.GOLD)
			else:
				pip.color = Color(0.3, 0.3, 0.4, 0.6)
			level_container.add_child(pip)

		# Level text beside pips
		var lvl_text = Label.new()
		lvl_text.text = " Lv.%d" % current_level
		lvl_text.add_theme_font_size_override("font_size", 13)
		lvl_text.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
		lvl_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		level_container.add_child(lvl_text)

	# --- Description ---
	var desc_label = Label.new()
	desc_label.text = offer.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc_label)

	# --- Bottom spacer to push content up a bit ---
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 4)
	bottom_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bottom_spacer)

	return card


func _add_icon_to_container(container: CenterContainer, offer: Dictionary):
	# Try to load a sprite texture
	var sprite_path = ""

	if offer.type == "passive_item":
		var sprite_name = offer.name.to_lower().replace(" ", "_")
		sprite_path = "res://assets/sprites/passive_%s.png" % sprite_name
	elif offer.type in ["new_weapon", "weapon_upgrade"]:
		sprite_path = _weapon_sprite_map.get(offer.name, "")

	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		var tex_rect = TextureRect.new()
		tex_rect.texture = load(sprite_path)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex_rect.custom_minimum_size = Vector2(48, 48)
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(tex_rect)
	else:
		# Fallback: colored rect icon
		var icon = ColorRect.new()
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


func _on_card_hover_enter(card: PanelContainer):
	var border_color: Color = card.get_meta("border_color")

	# Brighten border and background on hover
	var hover_style = StyleBoxFlat.new()
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
	# Subtle glow via shadow
	hover_style.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.3)
	hover_style.shadow_size = 8
	card.add_theme_stylebox_override("panel", hover_style)

	# Scale up slightly
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(card, "scale", Vector2(1.05, 1.05), 0.12)


func _on_card_hover_exit(card: PanelContainer):
	# Restore base style
	var base_style: StyleBoxFlat = card.get_meta("base_style")
	card.add_theme_stylebox_override("panel", base_style)

	# Scale back to normal
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.12)


func _on_card_selected(index: int):
	if index < 0 or index >= current_offers.size():
		return

	var offer = current_offers[index]
	var player = get_tree().current_scene.get_node_or_null("Player")
	var weapon_manager = player.get_node_or_null("WeaponManager") if player else null

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


func _animate_exit():
	# Quick fade out
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_bg_overlay, "color", Color(0, 0, 0, 0.0), 0.15)
	tween.parallel().tween_property(_title_label, "modulate:a", 0.0, 0.1)

	var cards = cards_container.get_children()
	for card in cards:
		tween.parallel().tween_property(card, "modulate:a", 0.0, 0.15)

	tween.tween_callback(func():
		visible = false
		get_tree().paused = false
		emit_signal("upgrade_selected")
	)


func _add_new_weapon(weapon_manager, weapon_name: String):
	for aw in available_weapons:
		if aw.name == weapon_name:
			# Load the weapon script and create instance
			var script = load(aw.script)
			var weapon = Node.new()
			weapon.set_script(script)
			weapon_manager.add_child(weapon)
			weapon_manager.weapons.append(weapon)
			return


func _apply_buff(player, offer: Dictionary):
	var stat = offer.stat
	var value = offer.value
	GameState.buffs[stat] = GameState.buffs.get(stat, 0) + 1

	match stat:
		"attack_speed":
			# Apply to all weapons
			var wm = player.get_node_or_null("WeaponManager")
			if wm:
				for w in wm.weapons:
					w.attack_speed_multiplier = max(0.3, 1.0 - GameState.buffs.get("attack_speed", 0) * 0.1)
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
			# Update pickup area collision shape
			var pickup_area = player.get_node_or_null("PickupArea/PickupShape")
			if pickup_area and pickup_area.shape is CircleShape2D:
				pickup_area.shape.radius = player.pickup_range
		"life_steal":
			# Store in GameState, apply in damage dealing
			pass


func _apply_passive_item(player, offer: Dictionary):
	var passive_manager = player.get_node_or_null("PassiveItemManager") if is_instance_valid(player) else null
	if not passive_manager:
		push_warning("LevelUpUI: No PassiveItemManager found on player")
		return
	passive_manager.add_or_upgrade_item(offer.name)
	passive_manager.apply_to_player(player)
