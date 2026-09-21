class_name UfoObstacle
extends Obstacle

var light_count: int = 6

func _ready() -> void:
	super._ready()
	obstacle_category = ObstacleCategory.LETHAL
	hitbox_type = HitboxType.CIRCLE
	hitbox_radius = 22.0
	speed = 110.0

func _draw() -> void:
	# 1. Chùm sáng quét xuống phía dưới (Tractor beam)
	var beam_pts: PackedVector2Array = PackedVector2Array([
		Vector2(-10.0, 4.0),
		Vector2(10.0, 4.0),
		Vector2(24.0, 40.0),
		Vector2(-24.0, 40.0)
	])
	var beam_alpha = 0.15 + sin(anim_time * 8.0) * 0.08
	draw_colored_polygon(beam_pts, Color(0.2, 1.0, 0.4, beam_alpha))
	
	# 2. Đĩa kim loại chính (Metallic saucer)
	# Vành ngoài elip
	draw_circle(Vector2(0, 0), 22.0, Color(0.3, 0.35, 0.45))
	draw_line(Vector2(-24.0, 0), Vector2(24.0, 0), Color(0.5, 0.58, 0.7), 6.0)
	
	# 3. Vòm kính buồng lái màu ngọc lam (Glass dome)
	draw_circle(Vector2(0, -6.0), 10.0, Color(0.2, 0.9, 0.9, 0.85))
	draw_circle(Vector2(-2.0, -8.0), 3.0, Color(1.0, 1.0, 1.0, 0.7)) # Điểm phản quang
	
	# 4. Dàn đèn xoay quanh đĩa (Rotating UFO lights)
	for i in range(light_count):
		var angle = (float(i) / float(light_count)) * TAU + anim_time * 5.0
		var lx = cos(angle) * 18.0
		var ly = sin(angle) * 5.0
		var col = Color.YELLOW if i % 2 == 0 else Color(1.0, 0.2, 0.6)
		draw_circle(Vector2(lx, ly), 2.2, col)

func acting(delta: float) -> void:
	super.acting(delta)
	# Chuyển động lượn sóng zíc zắc đặc trưng của UFO
	position.y += cos(anim_time * 4.0) * 25.0 * delta
