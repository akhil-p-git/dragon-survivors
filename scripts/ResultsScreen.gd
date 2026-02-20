extends CanvasLayer

var title_label: Label
var stats_label: Label
var play_again_btn: Button
var main_menu_btn: Button


func _ready():
	visible = false
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -300
	vbox.offset_top = -250
	vbox.offset_right = 300
	vbox.offset_bottom = 250
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	add_child(vbox)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	vbox.add_child(title_label)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	stats_label = Label.new()
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(stats_label)

	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer2)

	play_again_btn = Button.new()
	play_again_btn.text = "Play Again"
	play_again_btn.custom_minimum_size = Vector2(200, 50)
	play_again_btn.pressed.connect(_on_play_again)
	vbox.add_child(play_again_btn)

	main_menu_btn = Button.new()
	main_menu_btn.text = "Main Menu"
	main_menu_btn.custom_minimum_size = Vector2(200, 50)
	main_menu_btn.pressed.connect(_on_main_menu)
	vbox.add_child(main_menu_btn)


func show_victory():
	visible = true
	get_tree().paused = true
	title_label.text = "VICTORY!"
	title_label.add_theme_color_override("font_color", Color.GOLD)
	_update_stats()


func show_defeat():
	visible = true
	get_tree().paused = true
	title_label.text = "DEFEATED"
	title_label.add_theme_color_override("font_color", Color.RED)
	_update_stats()


func _update_stats():
	var minutes = int(GameState.game_time) / 60
	var seconds = int(GameState.game_time) % 60
	stats_label.text = "Time Survived: %02d:%02d\nLevel Reached: %d\nEnemies Killed: %d" % [minutes, seconds, GameState.player_level, GameState.enemies_killed]


func _on_play_again():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_main_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
