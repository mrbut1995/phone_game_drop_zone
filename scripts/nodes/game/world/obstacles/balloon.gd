class_name BalloonObstacle
extends Obstacle

func _ready() -> void:
	super._ready()
	obstacle_category = ObstacleCategory.LETHAL
	speed = 45.0 # Bay chậm, trôi bồng bềnh

func acting(delta: float) -> void:
	super.acting(delta)
	# Trôi bồng bềnh lên xuống nhẹ nhàng
	position.y += sin(anim_time * 1.5) * 8.0 * delta
