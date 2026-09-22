class_name RocketObstacle
extends Obstacle

var launch_speed: float = 260.0

func _ready() -> void:
	has_warning = true
	warning_lead_time = 0.8
	super._ready()
	obstacle_category = ObstacleCategory.LETHAL
	auto_wrap_x = false
	auto_despawn_offscreen = true

# Sprite tự chạy animation "warning" (autoplay trong scene), đổi sang "launch" khi hết cảnh báo
func on_warning_finished() -> void:
	play_animation(&"launch")

func acting(delta: float) -> void:
	anim_time += delta
	# Bắn thẳng lên trên với tốc độ cao
	position.y -= launch_speed * delta

	# Vượt khỏi đỉnh màn hình thì dọn dẹp
	if position.y < bounds_top:
		queue_free()
