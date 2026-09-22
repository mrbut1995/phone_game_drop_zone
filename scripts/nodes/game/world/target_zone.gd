# Bia hồng tâm mục tiêu (Target Bullseye)
class_name TargetZone
extends WorldActor

const RADIUS_100: float = 22.0
const RADIUS_70: float = 50.0
const RADIUS_40: float = 85.0
const RADIUS_20: float = 125.0
const LANDING_ASSIST_MARGIN: float = 6.0

@export var is_moving: bool = false
@export var move_speed: float = 1.2
@export var move_range: float = 110.0

var base_x: float = 270.0
var move_time: float = 0.0

func _ready() -> void:
	base_x = position.x

func configure(moving: bool, speed: float = 1.2, range_px: float = 110.0) -> void:
	is_moving = moving
	move_speed = speed
	move_range = range_px
	# Vị trí gốc lấy theo node đã đặt sẵn trong Level scene
	base_x = position.x
	move_time = 0.0

func _process(delta: float) -> void:
	if is_moving:
		move_time += delta * move_speed
		position.x = clamp(base_x + sin(move_time) * move_range, 140.0, 400.0)

# Đánh giá điểm số và vòng chạm theo GDD Section 7 & Section 12.6.3 (Landing Assist)
func evaluate_landing(drop_global_x: float) -> Dictionary:
	var target_center_x: float = global_position.x
	var distance: float = abs(drop_global_x - target_center_x)
	
	# Kiểm tra và áp dụng Landing Assist (khoan dung 6px kéo vào vòng trong có lợi cho người chơi)
	var points: int = 0
	var ring_name: String = "TRƯỢT (MISS)"
	var ring_color: Color = Color(0.7, 0.7, 0.7)
	
	# Xét từ tâm ra ngoài
	if distance <= RADIUS_100:
		points = 100
		ring_name = "BULLSEYE!"
		ring_color = Color(1.0, 0.2, 0.3)
	elif distance <= RADIUS_100 + LANDING_ASSIST_MARGIN:
		# Landing Assist kéo vào Bullseye 100đ!
		points = 100
		ring_name = "BULLSEYE! (ASSIST)"
		ring_color = Color(1.0, 0.2, 0.3)
	elif distance <= RADIUS_70:
		points = 70
		ring_name = "TUYỆT VỜI (70Đ)"
		ring_color = Color(1.0, 0.8, 0.1)
	elif distance <= RADIUS_70 + LANDING_ASSIST_MARGIN:
		# Landing Assist kéo vào vòng 70đ!
		points = 70
		ring_name = "TUYỆT VỜI (ASSIST)"
		ring_color = Color(1.0, 0.8, 0.1)
	elif distance <= RADIUS_40:
		points = 40
		ring_name = "TỐT (40Đ)"
		ring_color = Color(0.2, 0.7, 1.0)
	elif distance <= RADIUS_40 + LANDING_ASSIST_MARGIN:
		# Landing Assist kéo vào vòng 40đ!
		points = 40
		ring_name = "TỐT (ASSIST)"
		ring_color = Color(0.2, 0.7, 1.0)
	elif distance <= RADIUS_20:
		points = 20
		ring_name = "RÌA NGOÀI (20Đ)"
		ring_color = Color(0.6, 0.5, 0.8)
	elif distance <= RADIUS_20 + LANDING_ASSIST_MARGIN:
		points = 20
		ring_name = "RÌA NGOÀI (ASSIST)"
		ring_color = Color(0.6, 0.5, 0.8)
		
	return {
		"points": points,
		"distance": distance,
		"ring_name": ring_name,
		"color": ring_color
	}
