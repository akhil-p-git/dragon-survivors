extends Control


func _ready():
	$VBoxContainer/Title.text = "Dragon Survivors"
	$VBoxContainer/KnightButton.pressed.connect(_on_knight_pressed)
	$VBoxContainer/ArcherButton.pressed.connect(_on_archer_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)


func _on_knight_pressed():
	GameState.selected_character = "knight"
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_archer_pressed():
	GameState.selected_character = "archer"
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_quit_pressed():
	get_tree().quit()
