class_name BirdObstacle
extends Obstacle

func _ready() -> void:
	super._ready()
	obstacle_category = ObstacleCategory.LETHAL
	hitbox_type = HitboxType.CIRCLE
	hitbox_radius = 16.0 # COLLISION_HITBOX_SCALE 0.75 theo GDD Section 12.6.1

func _draw() -> void:
	# Vẽ chim bay với nhịp đập cánh
	var wing_flap: float = sin(anim_time * 6.0) * 12.0
	
	# Thân chim
	draw_circle(Vector2.ZERO, 6.0, Color(0.2, 0.25, 0.35))
	
	# Mỏ chim
	var beak_dir: float = 1.0 if direction > 0 else -1.0
	var beak_pts: PackedVector2Array = PackedVector2Array([
		Vector2(beak_dir * 5, -2),
		Vector2(beak_dir * 12, 0),
		Vector2(beak_dir * 5, 2)
	])
	draw_colored_polygon(beak_pts, Color(1.0, 0.7, 0.1))
	
	# Mắt chim
	draw_circle(Vector2(beak_dir * 3, -2), 1.5, Color.WHITE)
	draw_circle(Vector2(beak_dir * 3.5, -2), 0.8, Color.BLACK)
	
	# Cánh chim đập theo nhịp
	draw_line(Vector2(-2, 0), Vector2(-12, wing_flap), Color(0.3, 0.4, 0.55), 2.5)
	draw_line(Vector2(2, 0), Vector2(12, wing_flap), Color(0.3, 0.4, 0.55), 2.5)

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
