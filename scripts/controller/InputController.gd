class_name InputController
extends Node

signal tilt_updated(raw_deg: float, normalized: float, force: float)
signal force_drop_requested
signal restart_requested
signal debug_gust_requested
signal toggle_debug_requested
signal change_mode_requested(mode_idx: int)
signal calibrated(zero_angle: float)

# Hằng số theo GDD Section 12.3
const DEAD_ZONE: float = 4.0          # Vùng chết ±4 độ
const MAX_TILT_ANGLE: float = 35.0     # Góc nghiêng tối đa
const TILT_CURVE_POWER: float = 1.6   # Hệ số đường cong phi tuyến
const TILT_FORCE_MAX: float = 600.0    # Gia tốc ngang tối đa px/s²

var calibrated_zero_angle: float = 0.0
var current_raw_angle: float = 0.0
var normalized_tilt: float = 0.0
var tilt_force: float = 0.0

# Cảm biến nghiêng (Android/iOS).
# LƯU Ý: bắt buộc bật Project Settings > Input Devices > Sensors > Enable Accelerometer
# (input_devices/sensors/enable_accelerometer = true) nếu không Input.get_accelerometer()
# luôn trả về 0 và nghiêng máy sẽ không có tác dụng.
@export var use_accelerometer: bool = true
@export var invert_sensor_tilt: bool = false
# Ngưỡng nhận biết thiết bị có cảm biến (m/s²)
const SENSOR_MIN_MAGNITUDE: float = 1.0

# Tốc độ phản hồi phím giả lập trên Desktop
var key_tilt_speed: float = 85.0       # Độ/giây khi giữ phím
var key_return_speed: float = 120.0    # Độ/giây khi nhả phím về 0

func _ready() -> void:
	process_priority = -10 # Xử lý input trước logic chính
	_warn_if_sensor_disabled()

# Cảnh báo sớm nếu chưa bật cảm biến trong project settings (lỗi rất hay gặp khi build lên máy thật)
func _warn_if_sensor_disabled() -> void:
	if not use_accelerometer:
		return
	var enabled: bool = bool(ProjectSettings.get_setting("input_devices/sensors/enable_accelerometer", false))
	if not enabled:
		push_warning("InputController: nghiêng máy sẽ KHÔNG hoạt động vì thiếu setting \"input_devices/sensors/enable_accelerometer=true\".")

# Kiểm tra thiết bị có cảm biến thật hay không (desktop luôn trả về vector 0)
func _read_sensor_tilt() -> float:
	if not use_accelerometer:
		return 0.0
	var accel: Vector3 = Input.get_accelerometer()
	if accel.length() < SENSOR_MIN_MAGNITUDE:
		return 0.0
	return _tilt_from_accelerometer(accel)

# Công thức thuần: máy dọc (portrait), trục X của gia tốc cho biết độ nghiêng trái/phải
# accel.x > 0: nghiêng trái, accel.x < 0: nghiêng phải (đơn vị m/s², có cả trọng lực)
func _tilt_from_accelerometer(accel: Vector3) -> float:
	var phone_tilt: float = -rad_to_deg(asin(clampf(accel.x / 9.8, -1.0, 1.0)))
	return -phone_tilt if invert_sensor_tilt else phone_tilt

func _has_sensor() -> bool:
	return use_accelerometer and Input.get_accelerometer().length() >= SENSOR_MIN_MAGNITUDE

func _process(delta: float) -> void:
	_handle_input_polling(delta)
	_calculate_effective_tilt()
	tilt_updated.emit(current_raw_angle, normalized_tilt, tilt_force)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
		
	match event.physical_keycode:
		KEY_SPACE:
			force_drop_requested.emit()
		KEY_R:
			restart_requested.emit()
		KEY_C:
			calibrate_zero()
		KEY_G:
			debug_gust_requested.emit()
		KEY_TAB:
			toggle_debug_requested.emit()
		KEY_1:
			change_mode_requested.emit(0) # Campaign
		KEY_2:
			change_mode_requested.emit(1) # Endless
		KEY_3:
			change_mode_requested.emit(2) # Practice

func calibrate_zero() -> void:
	calibrated_zero_angle = current_raw_angle
	calibrated.emit(calibrated_zero_angle)

func _handle_input_polling(delta: float) -> void:
	var has_key_input: bool = false
	var key_target_tilt: float = 0.0
	
	# Đọc phím mô phỏng Tilt trên Desktop (A/D hoặc Mũi tên)
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		key_target_tilt -= 1.0
		has_key_input = true
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		key_target_tilt += 1.0
		has_key_input = true
		
	if has_key_input:
		# Giữ phím: Tăng dần góc nghiêng đến tối đa 35 độ
		current_raw_angle += key_target_tilt * key_tilt_speed * delta
		current_raw_angle = clamp(current_raw_angle, -MAX_TILT_ANGLE, MAX_TILT_ANGLE)
	elif _has_sensor():
		# Có cảm biến phần cứng (điện thoại): bám theo góc nghiêng thực tế
		current_raw_angle = lerp(current_raw_angle, _read_sensor_tilt(), delta * 12.0)
	else:
		# Không có cảm biến và không bấm phím -> Hồi góc về 0 độ mượt mà
		current_raw_angle = move_toward(current_raw_angle, 0.0, key_return_speed * delta)

func _calculate_effective_tilt() -> void:
	# 1. Trừ mốc hiệu chuẩn (GDD 12.3.1)
	var raw: float = current_raw_angle - calibrated_zero_angle
	
	# 2. Vùng chết Deadzone
	var effective_angle: float = 0.0
	if abs(raw) < DEAD_ZONE:
		effective_angle = 0.0
	else:
		var sign_val: float = 1.0 if raw > 0.0 else -1.0
		effective_angle = sign_val * (abs(raw) - DEAD_ZONE)
		
	# 3. Chuẩn hóa về khoảng [-1, 1]
	normalized_tilt = clamp(effective_angle / (MAX_TILT_ANGLE - DEAD_ZONE), -1.0, 1.0)
	
	# 4. Đường cong phi tuyến Response Curve (GDD 12.3.2)
	var sign_norm: float = 1.0 if normalized_tilt >= 0.0 else -1.0
	var curved_tilt: float = sign_norm * pow(abs(normalized_tilt), TILT_CURVE_POWER)
	
	# 5. Lực tilt cuối cùng px/s² (GDD 12.3.3)
	tilt_force = curved_tilt * TILT_FORCE_MAX
