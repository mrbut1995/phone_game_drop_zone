class_name WindController
extends Node

signal wind_updated(total_wind: float, base_wind: float, gust_wind: float)
signal gust_warning(direction: float, duration: float)
signal gust_started(direction: float, force: float)
signal gust_ended

var base_wind: float = 0.0
var gust_wind: float = 0.0
var total_wind: float = 0.0

# Gust timers
var gust_interval: float = 6.0
var gust_timer: float = 0.0
var warning_time: float = 0.8 # Cảnh báo trước 0.8s
var gust_duration: float = 1.6
var is_warning: bool = false
var is_gusting: bool = false
var pending_gust_force: float = 0.0
var gust_time_remaining: float = 0.0

# Turbulence multiplier (GDD 12.4)
var turbulence_multiplier: float = 1.0 # 1.0 bình thường, 0.5 khi có turbulence

func _ready() -> void:
	randomize()
	set_base_wind(randf_range(-60.0, 60.0))

func configure_wind(min_w: float, max_w: float, interval: float = 6.0) -> void:
	base_wind = randf_range(min_w, max_w)
	gust_interval = interval
	gust_timer = 0.0
	is_warning = false
	is_gusting = false
	gust_wind = 0.0

func set_base_wind(val: float) -> void:
	base_wind = val

func trigger_manual_gust(force: float = 0.0) -> void:
	if force == 0.0:
		var dir: float = 1.0 if randf() > 0.5 else -1.0
		pending_gust_force = dir * randf_range(160.0, 280.0)
	else:
		pending_gust_force = force
		
	# Bắt đầu cảnh báo trước 0.8s
	is_warning = true
	var dir_sign: float = 1.0 if pending_gust_force > 0 else -1.0
	gust_warning.emit(dir_sign, warning_time)
	
	var tw = create_tween()
	tw.tween_interval(warning_time)
	tw.tween_callback(_start_active_gust)

func _process(delta: float) -> void:
	# Cập nhật Gust định kỳ
	if not is_warning and not is_gusting:
		gust_timer += delta
		if gust_timer >= gust_interval:
			gust_timer = 0.0
			trigger_manual_gust()
			
	if is_gusting:
		gust_time_remaining -= delta
		if gust_time_remaining <= 0:
			_end_active_gust()
			
	# Tính tổng lực gió
	total_wind = base_wind + gust_wind
	wind_updated.emit(total_wind, base_wind, gust_wind)

func _start_active_gust() -> void:
	is_warning = false
	is_gusting = true
	gust_time_remaining = gust_duration
	gust_wind = pending_gust_force
	var dir_sign: float = 1.0 if pending_gust_force > 0 else -1.0
	gust_started.emit(dir_sign, abs(pending_gust_force))

func _end_active_gust() -> void:
	is_gusting = false
	var tw = create_tween()
	tw.tween_property(self, "gust_wind", 0.0, 0.5)
	tw.tween_callback(func(): gust_ended.emit())

# Lấy lực gió tác động tại độ cao y của nhân vật (có biến thiên nhẹ theo tầng)
func get_wind_at_altitude(y_pos: float, total_height: float) -> float:
	var height_factor: float = 1.0 + (1.0 - clamp(y_pos / max(1.0, total_height), 0.0, 1.0)) * 0.3
	return total_wind * height_factor
