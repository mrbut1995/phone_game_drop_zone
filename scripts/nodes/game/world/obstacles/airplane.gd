class_name AirplaneObstacle
extends Obstacle

func _ready() -> void:
	super._ready()
	obstacle_category = ObstacleCategory.LETHAL
	speed = 140.0

# Di chuyển ngang mặc định của Obstacle; hoạt ảnh (đèn cánh, lửa phản lực) do Sprite đảm nhiệm
