extends Node2D
## Visual bow attached to the player. Animates drawback and release when shooting.

var _shoot_tween: Tween
var _is_shooting: bool = false
var player: CharacterBody2D
var _string_pull: float = 0.0

const BOW_RADIUS: float = 18.0
const BOW_THICKNESS: float = 2.5
const STRING_COLOR: Color = Color(0.9, 0.85, 0.7)
const BOW_COLOR: Color = Color(0.6, 0.4, 0.15)


func _ready() -> void:
	z_index = 1


func _process(_delta: float) -> void:
	if not _is_shooting and is_instance_valid(player):
		var target: float = player.aim_direction.angle()
		rotation = lerp_angle(rotation, target, 0.15)
	queue_redraw()


func _draw() -> void:
	# Bow arc
	var arc_steps: int = 12
	var bow_pts: PackedVector2Array = PackedVector2Array()
	for i in range(arc_steps + 1):
		var t: float = float(i) / float(arc_steps)
		var angle: float = -0.8 + t * 1.6
		bow_pts.append(Vector2(cos(angle) * BOW_RADIUS, sin(angle) * BOW_RADIUS))
	for i in range(bow_pts.size() - 1):
		draw_line(bow_pts[i], bow_pts[i + 1], BOW_COLOR, BOW_THICKNESS)

	# Bowstring
	var string_top: Vector2 = bow_pts[0]
	var string_bottom: Vector2 = bow_pts[bow_pts.size() - 1]
	var string_mid: Vector2 = (string_top + string_bottom) / 2.0 - Vector2(_string_pull, 0)
	draw_line(string_top, string_mid, STRING_COLOR, 1.5)
	draw_line(string_mid, string_bottom, STRING_COLOR, 1.5)

	# Arrow nocked while pulling
	if _string_pull > 2.0:
		var arrow_tip: Vector2 = Vector2(BOW_RADIUS + 8, 0)
		var arrow_tail: Vector2 = string_mid
		draw_line(arrow_tail, arrow_tip, Color(0.7, 0.55, 0.25), 2.0)
		draw_line(arrow_tip, arrow_tip + Vector2(-4, -3), Color(0.5, 0.5, 0.55), 1.5)
		draw_line(arrow_tip, arrow_tip + Vector2(-4, 3), Color(0.5, 0.5, 0.55), 1.5)


func shoot() -> void:
	if _shoot_tween and _shoot_tween.is_valid():
		_shoot_tween.kill()
	_is_shooting = true
	_string_pull = 0.0

	_shoot_tween = create_tween()
	# Draw string back
	_shoot_tween.tween_property(self, "_string_pull", 12.0, 0.08)
	# Release snap
	_shoot_tween.tween_property(self, "_string_pull", -3.0, 0.04).set_trans(Tween.TRANS_BACK)
	# Settle
	_shoot_tween.tween_property(self, "_string_pull", 0.0, 0.1).set_ease(Tween.EASE_OUT)
	_shoot_tween.tween_callback(func(): _is_shooting = false)
