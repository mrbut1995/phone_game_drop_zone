class_name BalloonObstacle
extends Obstacle

func _ready() -> void:
	super._ready()
	obstacle_category = ObstacleCategory.LETHAL
	hitbox_type = HitboxType.CIRCLE
	hitbox_radius = 32.0 # Hitbox lớn
	speed = 45.0 # Bay chậm, trôi bồng bềnh

func _draw() -> void:
	var bob_y = sin(anim_time * 2.0) * 3.0
	var balloon_center = Vector2(0.0, -10.0 + bob_y)
	
	# 1. Quả khí cầu chính (Balloon envelope)
	draw_circle(balloon_center, 26.0, Color(0.95, 0.45, 0.15)) # Màu cam rực rỡ
	
	# Các sọc màu dọc quả khí cầu
	var stripe_yellow: PackedVector2Array = PackedVector2Array([
		balloon_center + Vector2(-12.0, -22.0),
		balloon_center + Vector2(-6.0, 24.0),
		balloon_center + Vector2(6.0, 24.0),
		balloon_center + Vector2(12.0, -22.0)
	])
	draw_colored_polygon(stripe_yellow, Color(1.0, 0.82, 0.2))
	
	var stripe_teal: PackedVector2Array = PackedVector2Array([
		balloon_center + Vector2(-4.0, -25.0),
		balloon_center + Vector2(-2.0, 25.0),
		balloon_center + Vector2(2.0, 25.0),
		balloon_center + Vector2(4.0, -25.0)
	])
	draw_colored_polygon(stripe_teal, Color(0.15, 0.7, 0.75))
	
	# 2. Ngọn lửa đốt khí nóng bập bùng nhẹ
	var flame_height = 4.0 + sin(anim_time * 12.0) * 2.5
	draw_line(balloon_center + Vector2(0, 25.0), balloon_center + Vector2(0, 25.0 + flame_height), Color(1.0, 0.6, 0.0), 3.0)
	
	# 3. Dây treo giỏ
	var basket_y = balloon_center.y + 36.0
	draw_line(balloon_center + Vector2(-10.0, 23.0), Vector2(-6.0, basket_y), Color(0.3, 0.2, 0.15), 1.2)
	draw_line(balloon_center + Vector2(10.0, 23.0), Vector2(6.0, basket_y), Color(0.3, 0.2, 0.15), 1.2)
	
	# 4. Giỏ mây chở người (Wicker basket)
	draw_rect(Rect2(-7.0, basket_y, 14.0, 10.0), Color(0.65, 0.42, 0.25), true)
	draw_rect(Rect2(-8.0, basket_y - 1.0, 16.0, 2.5), Color(0.5, 0.3, 0.15), true)

func acting(delta: float) -> void:
	super.acting(delta)
	# Trôi bồng bềnh lên xuống nhẹ nhàng
	position.y += sin(anim_time * 1.5) * 8.0 * delta
