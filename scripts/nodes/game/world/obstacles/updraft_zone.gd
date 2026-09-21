class_name UpdraftZoneObstacle
extends Obstacle

var zone_size: Vector2 = Vector2(160.0, 140.0)
var particle_offsets: Array[Vector2] = []
var num_particles: int = 14

func _ready() -> void:
	super._ready()
	obstacle_category = ObstacleCategory.ZONE_MODIFIER
	zone_effect = ZoneEffect.UPDRAFT
	hitbox_type = HitboxType.RECTANGLE
	hitbox_rect = Rect2(-zone_size.x * 0.5, -zone_size.y * 0.5, zone_size.x, zone_size.y)
	zone_force = 480.0 # Lực đẩy lên (px/s² chống lại trọng lực 800)
	speed = 20.0 # Cột khí có thể trôi ngang rất chậm
	auto_wrap_x = true
	
	# Khởi tạo hạt khí nóng
	for i in range(num_particles):
		particle_offsets.append(Vector2(
			randf_range(-zone_size.x * 0.45, zone_size.x * 0.45),
			randf_range(-zone_size.y * 0.45, zone_size.y * 0.45)
		))

func on_setup(params: Dictionary) -> void:
	if params.has("size"):
		zone_size = params["size"]
		hitbox_rect = Rect2(-zone_size.x * 0.5, -zone_size.y * 0.5, zone_size.x, zone_size.y)
	if params.has("lift_force"):
		zone_force = params["lift_force"]

func _draw() -> void:
	var half_w = zone_size.x * 0.5
	var half_h = zone_size.y * 0.5
	
	# 1. Nền vùng khí nóng màu vàng cam trong suốt
	var bg_col = Color(1.0, 0.55, 0.1, 0.12 + sin(anim_time * 3.0) * 0.04)
	draw_rect(Rect2(-half_w, -half_h, zone_size.x, zone_size.y), bg_col, true)
	draw_rect(Rect2(-half_w, -half_h, zone_size.x, zone_size.y), Color(1.0, 0.6, 0.15, 0.35), false, 1.5)
	
	# 2. Các hạt nhiệt và mũi tên bay lên
	for offset in particle_offsets:
		var norm_y = (offset.y + half_h) / zone_size.y # 0 to 1
		var alpha = sin(norm_y * PI) * 0.8
		var col = Color(1.0, 0.7, 0.2, alpha)
		# Mũi tên hướng lên nhỏ
		draw_line(offset, offset + Vector2(0, -8.0), col, 2.0)
		draw_line(offset + Vector2(0, -8.0), offset + Vector2(-3.0, -5.0), col, 1.5)
		draw_line(offset + Vector2(0, -8.0), offset + Vector2(3.0, -5.0), col, 1.5)

func acting(delta: float) -> void:
	super.acting(delta)
	var half_h = zone_size.y * 0.5
	# Cho các hạt khí nóng cuộn lên trên
	for i in range(particle_offsets.size()):
		particle_offsets[i].y -= 60.0 * delta
		if particle_offsets[i].y < -half_h:
			particle_offsets[i].y = half_h
			particle_offsets[i].x = randf_range(-zone_size.x * 0.45, zone_size.x * 0.45)
