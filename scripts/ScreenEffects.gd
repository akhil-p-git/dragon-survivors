extends Node
## Global screen effects singleton (autoload).
## Provides camera shake, hit stop (freeze frame), and multi-kill tracking.

# -- Camera Shake --
var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0
var _shake_elapsed: float = 0.0
var _is_shaking: bool = false

# -- Hit Stop --
var _hitstop_timer: float = 0.0
var _is_stopped: bool = false
var _saved_time_scale: float = 1.0

# -- Multi-kill tracking --
var _recent_kill_times: Array[float] = []
var _kill_window: float = 0.3  # Kills within 300ms count as multi-kill

# Shake intensity presets
const SHAKE_SMALL: float = 3.0    # Player takes minor damage
const SHAKE_MEDIUM: float = 6.0   # Multi-kill (3+ enemies)
const SHAKE_LARGE: float = 10.0   # Boss hit, massive damage
const SHAKE_HUGE: float = 16.0    # Boss death


func _process(delta: float) -> void:
	_process_shake(delta)
	_process_hitstop(delta)


# -- Camera Shake API --

## Trigger screen shake. Larger intensity values override smaller ongoing shakes.
func shake(intensity: float, duration: float = 0.2) -> void:
	# Only override if new shake is stronger than remaining shake
	if intensity > _shake_intensity * (_shake_duration - _shake_elapsed) / max(_shake_duration, 0.001):
		_shake_intensity = intensity
		_shake_duration = duration
		_shake_elapsed = 0.0
		_is_shaking = true


func _process_shake(_delta: float) -> void:
	if not _is_shaking:
		return

	var camera := _get_camera()
	if not camera:
		_is_shaking = false
		return

	_shake_elapsed += _delta
	if _shake_elapsed >= _shake_duration:
		_is_shaking = false
		camera.offset = Vector2.ZERO
		return

	# Decay intensity over time
	var progress := _shake_elapsed / _shake_duration
	var current_intensity := _shake_intensity * (1.0 - progress)
	camera.offset = Vector2(
		randf_range(-current_intensity, current_intensity),
		randf_range(-current_intensity, current_intensity)
	)


# -- Hit Stop API --

## Brief time-scale freeze for impactful hits. Duration in seconds (20-50ms typical).
func hitstop(duration: float = 0.03) -> void:
	if _is_stopped:
		# Extend existing hitstop if requested
		_hitstop_timer = max(_hitstop_timer, duration)
		return
	_saved_time_scale = Engine.time_scale
	Engine.time_scale = 0.05  # Near-freeze, not full stop (avoids physics issues)
	_hitstop_timer = duration
	_is_stopped = true


func _process_hitstop(_delta: float) -> void:
	if not _is_stopped:
		return

	# Use unscaled delta since time_scale is near-zero
	_hitstop_timer -= _delta / max(Engine.time_scale, 0.01)
	if _hitstop_timer <= 0.0:
		Engine.time_scale = _saved_time_scale
		_is_stopped = false


# -- Multi-kill Tracking --

## Call this when an enemy dies. Automatically triggers shake for multi-kills.
func register_enemy_kill() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	_recent_kill_times.append(now)

	# Prune old kills outside the window
	while _recent_kill_times.size() > 0 and now - _recent_kill_times[0] > _kill_window:
		_recent_kill_times.remove_at(0)

	var kill_count := _recent_kill_times.size()
	if kill_count >= 5:
		shake(SHAKE_LARGE, 0.25)
	elif kill_count >= 3:
		shake(SHAKE_MEDIUM, 0.15)


# -- Utility --

func _get_camera() -> Camera2D:
	var player := get_tree().current_scene.get_node_or_null("Player")
	if player:
		var cam := player.get_node_or_null("Camera2D")
		if cam is Camera2D:
			return cam
	return null
