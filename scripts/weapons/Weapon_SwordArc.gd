extends "res://scripts/weapons/WeaponBase.gd"

# Keep for evolved weapon (DragonCleaver) compatibility
var sword_arc_scene: PackedScene = preload("res://scenes/weapons/SwordArc.tscn")

var _SwordVisualScript: GDScript = preload("res://scripts/weapons/KnightSwordVisual.gd")
var sword_visual: Node2D = null


func _ready() -> void:
	super._ready()
	weapon_name = "Sword Arc"
	base_damage = 18.0
	base_cooldown = 1.0
	_create_sword_visual()


func _create_sword_visual() -> void:
	if not is_instance_valid(player):
		return
	sword_visual = Node2D.new()
	sword_visual.set_script(_SwordVisualScript)
	sword_visual.player = player
	player.add_child(sword_visual)


func attack() -> void:
	if not is_instance_valid(player):
		return
	if not is_instance_valid(sword_visual):
		_create_sword_visual()
	if not is_instance_valid(sword_visual):
		return

	var direction: Vector2 = player.aim_direction
	var scale_bonus: float = 1.0 + (level - 1) * 0.15
	var damage: float = get_damage()
	var extra: int = get_extra_projectiles()
	var arc_bonus: float = float(extra)

	# Trigger the body lunge animation
	if player.has_method("play_attack_animation"):
		player.play_attack_animation("sword_swing")

	sword_visual.swing(damage, direction, scale_bonus, arc_bonus)

	if level >= 5:
		# Double slash — second swing after a short delay
		get_tree().create_timer(0.25).timeout.connect(func():
			if is_instance_valid(player) and is_instance_valid(sword_visual):
				sword_visual.swing(damage, player.aim_direction, scale_bonus, arc_bonus)
		)


func _exit_tree() -> void:
	if is_instance_valid(sword_visual):
		sword_visual.queue_free()
