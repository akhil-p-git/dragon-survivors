extends Node2D


func _draw() -> void:
	# Dark cavern stone floor base
	var base_color: Color = Color(0.157, 0.137, 0.176)  # RGB ~40,35,45
	draw_rect(Rect2(-5000, -5000, 10000, 10000), base_color)

	# Stone tile grid (every 64px) with darker grout lines
	var grout_color: Color = Color(0.086, 0.071, 0.098, 0.6)
	var grout_highlight: Color = Color(0.22, 0.20, 0.25, 0.3)

	for x in range(-5000, 5001, 64):
		# Grout lines (dark)
		draw_line(Vector2(x, -5000), Vector2(x, 5000), grout_color, 1.0)
		# Subtle highlight next to grout (top-left light source)
		draw_line(Vector2(x + 1, -5000), Vector2(x + 1, 5000), grout_highlight, 1.0)
	for y in range(-5000, 5001, 64):
		draw_line(Vector2(-5000, y), Vector2(5000, y), grout_color, 1.0)
		draw_line(Vector2(-5000, y + 1), Vector2(5000, y + 1), grout_highlight, 1.0)

	# Scattered darker patches for depth variation
	var dark_patch: Color = Color(0.10, 0.09, 0.12, 0.35)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12345  # Deterministic
	for i in range(200):
		var px: float = rng.randf_range(-4500, 4500)
		var py: float = rng.randf_range(-4500, 4500)
		var size: float = rng.randf_range(30, 80)
		draw_rect(Rect2(px, py, size, size), dark_patch)

	# Occasional lighter stone highlights
	var light_patch: Color = Color(0.22, 0.20, 0.24, 0.2)
	for i in range(80):
		var px: float = rng.randf_range(-4500, 4500)
		var py: float = rng.randf_range(-4500, 4500)
		var size: float = rng.randf_range(10, 30)
		draw_rect(Rect2(px, py, size, size), light_patch)
