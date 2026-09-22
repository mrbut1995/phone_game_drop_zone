class_name WindClock
extends Control

# Đồng hồ kim chỉ hướng gió (Wind Clock - Update_Feature.md Section 5)
# Thay thế hoàn toàn cho thông báo dạng chữ/icon cũ bằng giao diện trực quan luôn hiện diện.

@export var max_wind_range: float = 240.0
@export var max_needle_angle_deg: float = 75.0

var current_wind: float = 0.0
var target_wind: float = 0.0
var predicted_wind: float = 0.0
var target_predicted_wind: float = 0.0

var smooth_current_angle: float = 0.0
var smooth_ghost_angle: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(72, 72)
	queue_redraw()

func set_wind_data(p_current: float, p_predicted: float) -> void:
	target_wind = p_current
	target_predicted_wind = p_predicted

func _process(delta: float) -> void:
	# Làm mượt góc quay của kim chính và kim phụ
	var target_main_angle = deg_to_rad(clamp(target_wind / max_wind_range, -1.0, 1.0) * max_needle_angle_deg)
	var target_ghost_angle = deg_to_rad(clamp(target_predicted_wind / max_wind_range, -1.0, 1.0) * max_needle_angle_deg)
	
	smooth_current_angle = lerp_angle(smooth_current_angle, target_main_angle, delta * 9.0)
	smooth_ghost_angle = lerp_angle(smooth_ghost_angle, target_ghost_angle, delta * 12.0)
	
	current_wind = lerp(current_wind, target_wind, delta * 8.0)
	queue_redraw()

func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = min(center.x, center.y) - 4.0
	
	# 1. Mặt đồng hồ tròn nền kính tối màu (Glass dial)
	draw_circle(center, radius, Color(0.1, 0.14, 0.2, 0.85))
	draw_arc(center, radius, 0.0, TAU, 32, Color(0.35, 0.5, 0.65, 0.9), 2.0)
	
	# Các vạch chia độ (Dial ticks)
	var tick_angles = [-PI * 0.5, -PI * 0.25, 0.0, -PI * 0.75, PI * 0.5]
	for a in range(-4, 5):
		var ang = -PI * 0.5 + float(a) * (PI * 0.125)
		var tick_len = 5.0 if a % 2 == 0 else 3.0
		var p1 = center + Vector2(cos(ang), sin(ang)) * (radius - 2.0)
		var p2 = center + Vector2(cos(ang), sin(ang)) * (radius - 2.0 - tick_len)
		var tick_col = Color(0.7, 0.85, 1.0, 0.6 if a % 2 == 0 else 0.3)
		draw_line(p1, p2, tick_col, 1.5 if a % 2 == 0 else 1.0)
		
	# Điểm mốc 12h (Lặng gió)
	var mark_12h = center + Vector2(0, -radius + 4.0)
	draw_circle(mark_12h, 2.0, Color(0.4, 0.9, 1.0, 0.8))

	# 2. Kim phụ mờ (Ghost Needle - Dự báo trước 0.5 - 1s theo Update_Feature.md 5.2)
	# Góc 0 tương ứng hướng 12h (lên trên)
	var ghost_dir = Vector2(sin(smooth_ghost_angle), -cos(smooth_ghost_angle))
	var ghost_len = radius * 0.75
	var ghost_tip = center + ghost_dir * ghost_len
	draw_line(center, ghost_tip, Color(0.3, 0.85, 1.0, 0.45), 2.0)
	draw_circle(ghost_tip, 2.5, Color(0.3, 0.9, 1.0, 0.6))
	
	# 3. Kim chính (Main Needle - Gió hiện tại)
	var main_dir = Vector2(sin(smooth_current_angle), -cos(smooth_current_angle))
	var wind_abs = abs(current_wind)
	var main_len = radius * lerp(0.55, 0.85, clamp(wind_abs / max_wind_range, 0.0, 1.0))
	var main_tip = center + main_dir * main_len
	
	# Màu kim đổi theo cường độ: Xanh lá (<60) -> Vàng (60-140) -> Đỏ (>140)
	var needle_col: Color
	if wind_abs < 60.0:
		needle_col = Color(0.3, 0.95, 0.5)
	elif wind_abs < 140.0:
		var t = (wind_abs - 60.0) / 80.0
		needle_col = Color(0.3, 0.95, 0.5).lerp(Color(1.0, 0.85, 0.2), t)
	else:
		var t = clamp((wind_abs - 140.0) / 100.0, 0.0, 1.0)
		needle_col = Color(1.0, 0.85, 0.2).lerp(Color(1.0, 0.25, 0.25), t)
		
	# Vẽ kim chính hình mũi tên thon nhọn
	var normal_main = Vector2(-main_dir.y, main_dir.x) * 3.0
	var needle_poly: PackedVector2Array = PackedVector2Array([
		center - normal_main,
		main_tip,
		center + normal_main
	])
	draw_colored_polygon(needle_poly, needle_col)
	
	# 4. Trục xoay đồng hồ kim loại ở tâm
	draw_circle(center, 4.0, Color(0.85, 0.9, 0.95))
	draw_circle(center, 2.0, Color(0.15, 0.2, 0.3))
