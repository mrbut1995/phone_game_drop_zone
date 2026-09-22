class_name BirdObstacle
extends Obstacle

func _ready() -> void:
	super._ready()
	obstacle_category = ObstacleCategory.LETHAL
	speed = 80.0

func acting(delta: float) -> void:
	anim_time += delta
	position.x += speed * direction * delta

	# Bay nhấp nhô nhẹ theo sóng sin
	position.y += sin(anim_time * 3.0) * 15.0 * delta

	# Xoay vòng màn hình
	if direction > 0 and position.x > bounds_right:
		position.x = bounds_left
	elif direction < 0 and position.x < bounds_left:
		position.x = bounds_right
