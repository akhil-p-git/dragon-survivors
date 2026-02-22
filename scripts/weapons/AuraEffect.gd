extends Node2D

# Visual pulse effect for the Aura weapon.
# Spawned each time the aura pulses. Scales up a translucent circle
# and fades it out over a short duration, then frees itself.

var pulse_radius: float = 60.0
var pulse_duration: float = 0.35

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	# Start small and transparent, then scale up and fade
	var texture_size: Vector2 = sprite.texture.get_size()
	# We want the sprite to reach pulse_radius * 2 in diameter
	var target_diameter: float = pulse_radius * 2.0
	var target_scale: float = target_diameter / texture_size.x

	# Start at 60% of target scale, expand to full
	var start_scale: float = target_scale * 0.6
	sprite.scale = Vector2(start_scale, start_scale)
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.5)

	# Tween: scale up and fade out
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(target_scale, target_scale), pulse_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "modulate:a", 0.0, pulse_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
