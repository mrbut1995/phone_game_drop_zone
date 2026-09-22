# Đàn chim bay theo hình chữ V.
# 5 con chim (Sprite + Bird2..Bird5) và 5 hitbox (Collision + Collision2..Collision5)
# được khai báo sẵn trong bird_flock.tscn.
class_name BirdFlockObstacle
extends Obstacle

func _ready() -> void:
	super._ready()
	obstacle_category = ObstacleCategory.LETHAL
	speed = 95.0

func acting(delta: float) -> void:
	super.acting(delta)
	# Đàn chim hơi lượn sóng nhẹ nhàng
	position.y += sin(anim_time * 2.5) * 12.0 * delta
