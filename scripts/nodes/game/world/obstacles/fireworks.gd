class_name FireworksObstacle
extends Obstacle

enum Stage { WARNING, RISING, BURSTING, FINISHED }
var current_stage: Stage = Stage.WARNING

var rise_speed: float = 320.0
var target_burst_y: float = 400.0
var burst_time: float = 0.0
var burst_duration: float = 1.2
var max_burst_radius: float = 36.0

# Shape riêng của từng instance để có thể phồng to khi nổ (tránh dùng chung resource)
var _burst_shape: CircleShape2D = null

func _ready() -> void:
	has_warning = true
	warning_lead_time = 0.7
	super._ready()
	obstacle_category = ObstacleCategory.LETHAL
	auto_wrap_x = false
	current_stage = Stage.WARNING

	var col := get_collision()
	if col != null and col.shape is CircleShape2D:
		_burst_shape = (col.shape as CircleShape2D).duplicate()
		col.shape = _burst_shape

func on_setup(params: Dictionary) -> void:
	if params.has("burst_y"):
		target_burst_y = params["burst_y"]

func on_warning_finished() -> void:
	play_animation(&"rise")

func acting(delta: float) -> void:
	match current_stage:
		Stage.WARNING:
			# Đã được Obstacle base class xử lý timer
			if is_ready_to_act:
				current_stage = Stage.RISING

		Stage.RISING:
			position.y -= rise_speed * delta
			if position.y <= target_burst_y:
				position.y = target_burst_y
				current_stage = Stage.BURSTING
				burst_time = 0.0
				play_animation(&"burst")

		Stage.BURSTING:
			burst_time += delta
			var p: float = clamp(burst_time / burst_duration, 0.0, 1.0)
			if _burst_shape != null:
				_burst_shape.radius = lerp(8.0, max_burst_radius * 0.8, p)
			if burst_time >= burst_duration:
				current_stage = Stage.FINISHED
				queue_free()
