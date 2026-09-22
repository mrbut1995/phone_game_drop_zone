class_name UfoObstacle
extends Obstacle

func _ready() -> void:
	super._ready()
	obstacle_category = ObstacleCategory.LETHAL
	speed = 110.0

func acting(delta: float) -> void:
	super.acting(delta)
	# Chuyển động lượn sóng zíc zắc đặc trưng của UFO
	position.y += cos(anim_time * 4.0) * 25.0 * delta
