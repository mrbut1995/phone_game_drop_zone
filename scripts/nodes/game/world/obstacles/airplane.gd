class_name AirplaneObstacle
extends Obstacle

var jet_particles: Array[Vector2] = []
var max_particles: int = 10

func _ready() -> void:
	super._ready()
	obstacle_category = ObstacleCategory.LETHAL
	hitbox_type = HitboxType.CIRCLE
	hitbox_radius = 24.0 # Máy bay to hơn chim
	speed = 140.0

func _draw() -> void:
	var facing: float = 1.0 if direction > 0 else -1.0
	
	# 1. Vẽ vệt khói phản lực sau đuôi máy bay
	for p in jet_particles:
		var local_p = p - position
		var alpha = clamp(1.0 - (local_p.length() / 80.0), 0.0, 0.8)
		draw_circle(local_p, 3.5, Color(0.9, 0.9, 0.95, alpha * 0.5))
	
	# 2. Thân máy bay (Fuselage)
	var body_pts: PackedVector2Array = PackedVector2Array([
		Vector2(facing * 30.0, 0.0),    # Mũi nhọn
		Vector2(facing * 18.0, -6.0),
		Vector2(-facing * 24.0, -5.0),
		Vector2(-facing * 30.0, -14.0), # Đuôi lái trên
		Vector2(-facing * 32.0, 0.0),
		Vector2(-facing * 24.0, 5.0),
		Vector2(facing * 18.0, 6.0)
	])
	draw_colored_polygon(body_pts, Color(0.85, 0.22, 0.22)) # Màu đỏ thể thao
	
	# Viền trắng thân
	draw_line(Vector2(facing * 20.0, 0.0), Vector2(-facing * 22.0, 0.0), Color.WHITE, 2.5)
	
	# 3. Kính buồng lái (Cockpit)
	var glass_pts: PackedVector2Array = PackedVector2Array([
		Vector2(facing * 16.0, -4.0),
		Vector2(facing * 24.0, -1.0),
		Vector2(facing * 16.0, 0.0)
	])
	draw_colored_polygon(glass_pts, Color(0.3, 0.8, 1.0, 0.9))
	
	# 4. Cánh máy bay (Wings)
	draw_line(Vector2(facing * 4.0, -18.0), Vector2(facing * 2.0, 18.0), Color(0.7, 0.15, 0.15), 4.0)
	
	# 5. Đèn nhấp nháy ở chóp cánh (Navigation lights)
	var blink: bool = int(anim_time * 6.0) % 2 == 0
	if blink:
		draw_circle(Vector2(facing * 4.0, -18.0), 2.5, Color.GREEN)
		draw_circle(Vector2(facing * 2.0, 18.0), 2.5, Color.RED)

func acting(delta: float) -> void:
	super.acting(delta)
	
	# Tạo hạt khói phản lực
	var facing: float = 1.0 if direction > 0 else -1.0
	var jet_outlet = position + Vector2(-facing * 28.0, 0.0)
	jet_particles.push_front(jet_outlet)
	if jet_particles.size() > max_particles:
		jet_particles.pop_back()
