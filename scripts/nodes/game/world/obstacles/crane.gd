class_name CraneObstacle
extends Obstacle

@export var jib_length: float = 200.0
@export var cable_length: float = 75.0
@export var is_facing_right: bool = true

var hook_angle: float = 0.0

func _ready() -> void:
	super._ready()
	obstacle_category = ObstacleCategory.STRUCTURAL
	hitbox_type = HitboxType.CUSTOM
	auto_wrap_x = false
	speed = 0.0

func on_setup(params: Dictionary) -> void:
	if params.has("jib_length"):
		jib_length = params["jib_length"]
	if params.has("cable_length"):
		cable_length = params["cable_length"]
	if params.has("is_facing_right"):
		is_facing_right = params["is_facing_right"]

func _get_hook_pos() -> Vector2:
	var dir_sign: float = 1.0 if is_facing_right else -1.0
	var trolley_x = dir_sign * (jib_length * 0.75)
	var hx = trolley_x + sin(hook_angle) * cable_length
	var hy = cos(hook_angle) * cable_length
	return Vector2(hx, hy)

func custom_collision_check(troop_pos: Vector2) -> bool:
	var dir_sign: float = 1.0 if is_facing_right else -1.0
	
	# 1. Va chạm với cần cẩu ngang (Jib boom)
	var jib_start = position
	var jib_end = position + Vector2(dir_sign * jib_length, 0.0)
	if _distance_to_segment(troop_pos, jib_start, jib_end) <= 8.0:
		return true
		
	# 2. Va chạm với móc cẩu / quả nặng đung đưa
	var hook_world_pos = position + _get_hook_pos()
	if hook_world_pos.distance_to(troop_pos) <= 14.0:
		return true
		
	# 3. Va chạm với dây cáp treo
	var trolley_world_pos = position + Vector2(dir_sign * (jib_length * 0.75), 0.0)
	if _distance_to_segment(troop_pos, trolley_world_pos, hook_world_pos) <= 5.0:
		return true
		
	return false

func _draw() -> void:
	var dir_sign: float = 1.0 if is_facing_right else -1.0
	var col_yellow = Color(0.95, 0.75, 0.1) # Màu vàng công trình
	var col_dark = Color(0.2, 0.2, 0.22)
	
	# 1. Trụ tháp thẳng đứng (Tower mast)
	draw_line(Vector2(0, -20.0), Vector2(0, 120.0), col_yellow, 6.0)
	draw_line(Vector2(-dir_sign * 10.0, -20.0), Vector2(-dir_sign * 10.0, 120.0), col_yellow, 4.0)
	
	# 2. Cần cẩu ngang dạng giàn thép (Jib truss)
	var jib_end_x = dir_sign * jib_length
	draw_line(Vector2(0, 0), Vector2(jib_end_x, 0), col_yellow, 5.0)
	draw_line(Vector2(0, -12.0), Vector2(jib_end_x, 0), col_yellow, 2.5)
	
	# Các thanh giằng chéo của cần cẩu
	var steps = int(jib_length / 25.0)
	for i in range(steps):
		var x1 = dir_sign * (float(i) * 25.0)
		var x2 = dir_sign * (float(i + 1) * 25.0)
		draw_line(Vector2(x1, 0), Vector2(x2, -12.0 * (1.0 - float(i)/float(steps))), col_dark, 1.5)
	
	# Cục đối trọng phía sau (Counterweight)
	draw_rect(Rect2(-dir_sign * 35.0, -8.0, 25.0, 16.0), Color(0.4, 0.42, 0.45), true)
	
	# 3. Xe con chạy trên cần (Trolley)
	var trolley_x = dir_sign * (jib_length * 0.75)
	draw_rect(Rect2(trolley_x - 6.0, -3.0, 12.0, 6.0), col_dark, true)
	
	# 4. Dây cáp và Móc cẩu đung đưa
	var hook_p = _get_hook_pos()
	draw_line(Vector2(trolley_x, 0), hook_p, Color(0.2, 0.2, 0.2), 1.8)
	
	# Quả nặng / móc cẩu (Heavy hook)
	draw_circle(hook_p, 8.0, Color(0.3, 0.35, 0.4))
	# Móc cong kim loại
	draw_arc(hook_p + Vector2(0, 7.0), 6.0, 0.0, PI, 12, Color(0.8, 0.8, 0.8), 2.5)

func acting(delta: float) -> void:
	anim_time += delta
	# Dao động con lắc đơn của móc cẩu
	hook_angle = sin(anim_time * 2.2) * 0.35
