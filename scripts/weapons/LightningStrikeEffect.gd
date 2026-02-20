extends Node2D

## Visual effect for a single lightning strike.
## Spawned at the enemy's position. Draws a jagged bolt line from
## above the target down to the impact point, shows an impact flash/glow,
## then fades everything out over ~0.2s and self-destructs.

@export var bolt_color_core: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var bolt_color_outer: Color = Color(1.0, 0.95, 0.4, 0.9)
@export var bolt_color_glow: Color = Color(0.6, 0.7, 1.0, 0.35)
@export var impact_color: Color = Color(1.0, 1.0, 0.7, 0.8)
@export var bolt_height: float = 300.0
@export var segment_count: int = 8
@export var jitter_amount: float = 20.0
@export var fade_duration: float = 0.2

var bolt_line_core: Line2D
var bolt_line_outer: Line2D
var bolt_line_glow: Line2D
var impact_flash: Node2D
var bolt_sprite: Sprite2D


func _ready():
	# The node is placed at the enemy's position (impact point).
	# The bolt goes from (offset_x, -bolt_height) down to (0, 0).
	var target_local = Vector2.ZERO
	var x_offset = randf_range(-15, 15)
	var start_local = Vector2(x_offset, -bolt_height)

	# Generate the jagged bolt path
	var path = _generate_bolt_path(start_local, target_local)

	# --- Glow line (widest, faintest) ---
	bolt_line_glow = Line2D.new()
	bolt_line_glow.width = 12.0
	bolt_line_glow.default_color = bolt_color_glow
	bolt_line_glow.joint_mode = Line2D.LINE_JOINT_ROUND
	bolt_line_glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	bolt_line_glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	for p in path:
		bolt_line_glow.add_point(p)
	add_child(bolt_line_glow)

	# --- Outer line (yellow/bright) ---
	bolt_line_outer = Line2D.new()
	bolt_line_outer.width = 5.0
	bolt_line_outer.default_color = bolt_color_outer
	bolt_line_outer.joint_mode = Line2D.LINE_JOINT_ROUND
	bolt_line_outer.begin_cap_mode = Line2D.LINE_CAP_ROUND
	bolt_line_outer.end_cap_mode = Line2D.LINE_CAP_ROUND
	for p in path:
		bolt_line_outer.add_point(p)
	add_child(bolt_line_outer)

	# --- Core line (white hot center) ---
	bolt_line_core = Line2D.new()
	bolt_line_core.width = 2.0
	bolt_line_core.default_color = bolt_color_core
	bolt_line_core.joint_mode = Line2D.LINE_JOINT_ROUND
	bolt_line_core.begin_cap_mode = Line2D.LINE_CAP_ROUND
	bolt_line_core.end_cap_mode = Line2D.LINE_CAP_ROUND
	for p in path:
		bolt_line_core.add_point(p)
	add_child(bolt_line_core)

	# --- Small branch sparks off the main bolt ---
	_add_branch_sparks(path)

	# --- Lightning bolt sprite at impact point ---
	bolt_sprite = Sprite2D.new()
	bolt_sprite.texture = load("res://assets/sprites/lightning.png")
	bolt_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bolt_sprite.position = Vector2(0, -16)
	bolt_sprite.scale = Vector2(2.0, 2.0)
	add_child(bolt_sprite)

	# --- Impact flash (bright circle at strike point) ---
	impact_flash = _create_impact_flash()
	add_child(impact_flash)

	# --- Animate and fade ---
	z_index = 50  # Render above most game objects

	# Initial bright flash: scale up impact, then fade everything
	var tween = create_tween()
	tween.set_parallel(true)

	# Impact flash: quick scale up then down
	tween.tween_property(impact_flash, "scale", Vector2(1.5, 1.5), 0.05)
	tween.chain().tween_property(impact_flash, "scale", Vector2(0.2, 0.2), fade_duration)

	# Fade all lines + sprite
	tween.tween_property(bolt_line_glow, "modulate:a", 0.0, fade_duration).set_delay(0.05)
	tween.tween_property(bolt_line_outer, "modulate:a", 0.0, fade_duration).set_delay(0.03)
	tween.tween_property(bolt_line_core, "modulate:a", 0.0, fade_duration).set_delay(0.06)
	tween.tween_property(bolt_sprite, "modulate:a", 0.0, fade_duration).set_delay(0.03)
	tween.tween_property(impact_flash, "modulate:a", 0.0, fade_duration).set_delay(0.05)

	# Self-destruct after fade completes
	tween.set_parallel(false)
	tween.tween_callback(queue_free)


func _generate_bolt_path(start: Vector2, end: Vector2) -> Array:
	var path: Array = [start]
	for i in range(1, segment_count):
		var t = float(i) / float(segment_count)
		var point = start.lerp(end, t)
		# Add horizontal jitter, decreasing near the endpoints for cleaner look
		var edge_factor = 1.0 - abs(t - 0.5) * 1.2  # Less jitter at ends
		point.x += randf_range(-jitter_amount, jitter_amount) * clampf(edge_factor, 0.3, 1.0)
		path.append(point)
	path.append(end)
	return path


func _add_branch_sparks(main_path: Array):
	# Add 2-3 small branch lines off the main bolt for extra visual energy
	var branch_count = randi_range(2, 3)
	var used_indices: Array = []

	for _b in range(branch_count):
		# Pick a random point along the bolt (not the first or last)
		var idx = randi_range(1, main_path.size() - 2)
		if idx in used_indices:
			continue
		used_indices.append(idx)

		var origin = main_path[idx]
		var branch_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-0.5, 0.5)).normalized()
		var branch_length = randf_range(15.0, 35.0)

		var branch_line = Line2D.new()
		branch_line.width = 2.0
		branch_line.default_color = bolt_color_outer
		branch_line.joint_mode = Line2D.LINE_JOINT_ROUND
		branch_line.add_point(origin)
		# 1-2 segments for the branch
		var mid = origin + branch_dir * branch_length * 0.5 + Vector2(randf_range(-8, 8), randf_range(-5, 5))
		branch_line.add_point(mid)
		branch_line.add_point(origin + branch_dir * branch_length)
		add_child(branch_line)


func _create_impact_flash() -> Node2D:
	# A bright expanding circle/glow at the strike point
	var container = Node2D.new()

	# Outer glow ring
	var glow_outer = _make_glow_circle(24.0, Color(0.5, 0.6, 1.0, 0.25))
	container.add_child(glow_outer)

	# Inner bright flash
	var glow_inner = _make_glow_circle(12.0, impact_color)
	container.add_child(glow_inner)

	# White-hot center
	var glow_core = _make_glow_circle(5.0, Color(1.0, 1.0, 1.0, 0.95))
	container.add_child(glow_core)

	return container


func _make_glow_circle(radius: float, color: Color) -> Sprite2D:
	# Generate a small radial gradient texture for the glow
	var size = int(radius * 2) + 2
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)

	for y in range(size):
		for x in range(size):
			var dist = Vector2(x, y).distance_to(center)
			var t = clampf(dist / radius, 0.0, 1.0)
			var alpha = (1.0 - t * t) * color.a  # Quadratic falloff
			img.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))

	var tex = ImageTexture.create_from_image(img)
	var sprite = Sprite2D.new()
	sprite.texture = tex
	return sprite
