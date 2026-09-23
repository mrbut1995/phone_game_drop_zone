class_name WindClock
extends Control

# Đồng hồ kim chỉ hướng gió (Wind Clock - Update_Feature.md Section 5)
# Toàn bộ chi tiết đồ hoạ là các node TextureRect khai báo sẵn trong wind_clock.tscn:
#   Dial        - mặt đồng hồ (kính tối + vạch chia độ + mốc 12h lặng gió)
#   GhostNeedle - kim phụ mờ dự báo gió 0.5-1s tới (thay cho cảnh báo gust dạng text)
#   Needle      - kim chính: xoay theo gió hiện tại, dài + đổi màu theo cường độ
#   Hub         - trục xoay kim loại ở tâm
# Script CHỈ cập nhật góc xoay / độ dài / màu kim, KHÔNG vẽ bằng code (_draw) nữa.

@export var max_wind_range: float = 240.0
@export var max_needle_angle_deg: float = 75.0
# SVG vẽ ở 2x nên scale gốc là 0.5 để khớp kích thước thiết kế
@export var art_scale: float = 0.5
@export var needle_min_length: float = 0.6
@export var needle_max_length: float = 1.0
@export var ghost_length_factor: float = 0.7
@export var ghost_color: Color = Color(0.35, 0.9, 1.0, 0.45)
# Khi có gust sắp tới, kim phụ vọt dài ra và đổi sang màu cảnh báo (Update_Feature.md 5.2)
@export var ghost_warning_color: Color = Color(1.0, 0.62, 0.25, 0.8)
@export var gust_alert_threshold: float = 0.10
@export var ghost_jump_speed: float = 0.18

@onready var needle: TextureRect = %Needle
@onready var ghost_needle: TextureRect = %GhostNeedle

var current_wind: float = 0.0
var target_wind: float = 0.0
var predicted_wind: float = 0.0
var target_predicted_wind: float = 0.0

var smooth_current_angle: float = 0.0
var smooth_ghost_angle: float = 0.0
var smooth_ghost_length: float = 0.7

func _ready() -> void:
	_update_needles()

func set_wind_data(p_current: float, p_predicted: float) -> void:
	target_wind = p_current
	target_predicted_wind = p_predicted

func _process(delta: float) -> void:
	# Làm mượt góc quay của kim chính và kim phụ
	var target_main_angle: float = deg_to_rad(clampf(target_wind / max_wind_range, -1.0, 1.0) * max_needle_angle_deg)
	var target_ghost_angle: float = deg_to_rad(clampf(target_predicted_wind / max_wind_range, -1.0, 1.0) * max_needle_angle_deg)

	smooth_current_angle = lerp_angle(smooth_current_angle, target_main_angle, delta * 9.0)
	smooth_ghost_angle = lerp_angle(smooth_ghost_angle, target_ghost_angle, delta * 12.0)
	current_wind = lerp(current_wind, target_wind, delta * 8.0)

	_update_needles(delta)

func _update_needles(delta: float = 0.0) -> void:
	var wind_abs: float = absf(current_wind)
	var intensity: float = clampf(wind_abs / max_wind_range, 0.0, 1.0)

	# Kim chính: xoay + co giãn chiều dài + đổi màu theo cường độ
	if needle != null:
		needle.rotation = smooth_current_angle
		needle.scale = Vector2(art_scale, art_scale * lerpf(needle_min_length, needle_max_length, intensity))
		needle.modulate = needle_color(wind_abs)

	# Kim phụ dự báo (Update_Feature.md 5.2):
	#  - Bình thường: kim phụ mờ, ngắn hơn kim chính
	#  - Sắp có gust / gió đổi mạnh: kim phụ LỆCH khỏi kim chính, VỌT dài ra và đổi màu cảnh báo
	#  - Khi kim chính đuổi kịp (gap nhỏ lại) thì kim phụ co về và mờ đi
	if ghost_needle != null:
		var predicted_intensity: float = clampf(absf(target_predicted_wind) / max_wind_range, 0.0, 1.0)
		var lead_gap: float = clampf(absf(target_predicted_wind - current_wind) / max_wind_range, 0.0, 1.0)
		var target_len: float = lerpf(needle_min_length, needle_max_length, maxf(predicted_intensity, lead_gap * 1.25))
		smooth_ghost_length = lerpf(smooth_ghost_length, target_len, clampf(ghost_jump_speed + delta * 4.0, 0.0, 1.0))

		ghost_needle.rotation = smooth_ghost_angle
		ghost_needle.scale = Vector2(art_scale, art_scale * smooth_ghost_length)
		ghost_needle.modulate = ghost_warning_color if lead_gap > gust_alert_threshold else ghost_color

# Màu kim theo cường độ gió: Xanh lá (<60) -> Vàng (60-140) -> Đỏ (>140)
func needle_color(wind_abs: float) -> Color:
	if wind_abs < 60.0:
		return Color(0.3, 0.95, 0.5)
	elif wind_abs < 140.0:
		return Color(0.3, 0.95, 0.5).lerp(Color(1.0, 0.85, 0.2), (wind_abs - 60.0) / 80.0)
	else:
		return Color(1.0, 0.85, 0.2).lerp(Color(1.0, 0.25, 0.25), clampf((wind_abs - 140.0) / 100.0, 0.0, 1.0))
